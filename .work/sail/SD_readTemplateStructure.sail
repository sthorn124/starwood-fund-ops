/* Draw approval (Phase 5): the structure of a draw budget workbook, read without AI (Excel Tools readexcelsheet, first sheet).
   Returns a map:
     ok            — the budget table was found (a column-A cell reading "Budget Category")
     headerLabels  — column A between the title block (up to the first blank row) and the table
     columns       — the table's heading row, left to right, blank cells dropped
     rows          — column A below the heading row, down to the first blank or TOTAL row
     totalLabel    — the TOTAL row's label, if any
     investmentName, drawNumber — column B beside those labels (as text)
     rowCount      — rows read from the sheet
   Labels only: no values from the budget table are returned, so a comparison built on this cannot talk about amounts. */
a!localVariables(
  /* readexcelsheet returns {success, result: <one map per row, cells in "values">} */
  local!read: if(
    a!isNullOrEmpty(ri!document),
    null,
    readexcelsheet(excelDocument: ri!document, sheetNumber: 0, startRow: 0, numberOfColumns: 20)
  ),
  /* rebuilt with a!forEach: length() of the plug-in's list as returned reads 1 (measured) */
  local!sheet: if(
    a!defaultValue(index(local!read, "success", false), false),
    a!forEach(items: index(local!read, "result", {}), expression: fv!item),
    {}
  ),
  local!n: length(local!sheet),
  local!colA: if(
    local!n = 0,
    {},
    a!forEach(items: local!sheet, expression: trim(tostring(index(index(fv!item, "values", {}), 1, ""))))
  ),
  local!colB: if(
    local!n = 0,
    {},
    a!forEach(items: local!sheet, expression: trim(tostring(index(index(fv!item, "values", {}), 2, ""))))
  ),
  local!colALower: if(local!n = 0, {}, lower(local!colA)),
  local!tableRow: if(local!n = 0, 0, index(wherecontains("budget category", local!colALower), 1, 0)),
  local!headingCells: if(
    local!tableRow = 0,
    {},
    a!forEach(
      items: index(index(local!sheet, local!tableRow, null), "values", {}),
      expression: trim(tostring(fv!item))
    )
  ),
  local!columns: if(
    local!tableRow = 0,
    {},
    index(local!headingCells, where(len(local!headingCells) > 0), {})
  ),
  /* slice sizes come from row positions, never length(): length() skips the null cells of blank rows (measured) */
  local!belowCount: if(local!tableRow = 0, 0, max(0, local!n - local!tableRow)),
  local!below: if(
    local!belowCount = 0,
    {},
    index(local!colA, local!tableRow + enumerate(local!belowCount) + 1, {})
  ),
  local!stopFlags: if(
    local!belowCount = 0,
    {},
    a!forEach(items: local!below, expression: or(fv!item = "", left(lower(fv!item), 5) = "total"))
  ),
  local!stop: if(local!belowCount = 0, 1, index(where(local!stopFlags), 1, local!belowCount + 1)),
  local!rows: if(local!stop <= 1, {}, index(local!below, enumerate(local!stop - 1) + 1, {})),
  local!totalLabel: index(local!below, local!stop, ""),
  local!aboveCount: max(0, local!tableRow - 1),
  local!above: if(local!aboveCount = 0, {}, index(local!colA, enumerate(local!aboveCount) + 1, {})),
  local!firstBlank: if(local!aboveCount = 0, 0, index(where(len(local!above) = 0), 1, 0)),
  local!headerSlice: if(
    or(local!firstBlank = 0, local!firstBlank >= local!aboveCount),
    {},
    index(local!above, local!firstBlank + enumerate(local!aboveCount - local!firstBlank) + 1, {})
  ),
  local!headerLabels: if(
    or(local!firstBlank = 0, local!firstBlank >= local!aboveCount),
    {},
    index(local!headerSlice, where(len(local!headerSlice) > 0), {})
  ),
  local!investmentRow: if(local!n = 0, 0, index(wherecontains("investment name", local!colALower), 1, 0)),
  local!drawNumberRow: if(local!n = 0, 0, index(wherecontains("draw number", local!colALower), 1, 0)),
  a!map(
    ok: local!tableRow > 0,
    readOk: a!defaultValue(index(local!read, "success", false), false),
    rowCount: local!n,
    tableRow: local!tableRow,
    headerLabels: local!headerLabels,
    columns: local!columns,
    rows: local!rows,
    totalLabel: local!totalLabel,
    investmentName: index(local!colB, local!investmentRow, ""),
    drawNumber: index(local!colB, local!drawNumberRow, "")
  )
)

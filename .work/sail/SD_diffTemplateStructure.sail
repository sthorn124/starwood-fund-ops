/* Draw approval (Phase 5): the label differences between two workbook structures (maps from SD_readTemplateStructure,
   or the standard template built from the SD_DRAW_TEMPLATE_* constants). Compared trimmed and lower-cased.
   Returns a map: columnsRemoved / columnsAdded, rowsRemoved / rowsAdded, fieldsRemoved / fieldsAdded (header labels),
   count (all six together), and both sides' full label lists (baselineColumns … receivedFields) for the position check
   the comparison gate applies to renames. "Removed" = in the baseline, not in the received file; "Added" = the reverse.
   Pairing a removal with an addition as a rename is a judgement this rule does not make. */
a!localVariables(
  local!bCols: a!defaultValue(index(ri!baseline, "columns", {}), {}),
  local!rCols: a!defaultValue(index(ri!received, "columns", {}), {}),
  local!bRows: a!defaultValue(index(ri!baseline, "rows", {}), {}),
  local!rRows: a!defaultValue(index(ri!received, "rows", {}), {}),
  local!bFields: a!defaultValue(index(ri!baseline, "headerLabels", {}), {}),
  local!rFields: a!defaultValue(index(ri!received, "headerLabels", {}), {}),
  local!columnsRemoved: rule!SD_listMinus(a: local!bCols, b: local!rCols),
  local!columnsAdded: rule!SD_listMinus(a: local!rCols, b: local!bCols),
  local!rowsRemoved: rule!SD_listMinus(a: local!bRows, b: local!rRows),
  local!rowsAdded: rule!SD_listMinus(a: local!rRows, b: local!bRows),
  local!fieldsRemoved: rule!SD_listMinus(a: local!bFields, b: local!rFields),
  local!fieldsAdded: rule!SD_listMinus(a: local!rFields, b: local!bFields),
  a!map(
    columnsRemoved: local!columnsRemoved,
    columnsAdded: local!columnsAdded,
    rowsRemoved: local!rowsRemoved,
    rowsAdded: local!rowsAdded,
    fieldsRemoved: local!fieldsRemoved,
    fieldsAdded: local!fieldsAdded,
    baselineColumns: local!bCols, receivedColumns: local!rCols,
    baselineRows: local!bRows, receivedRows: local!rRows,
    baselineFields: local!bFields, receivedFields: local!rFields,
    count: length(local!columnsRemoved) + length(local!columnsAdded) + length(local!rowsRemoved)
      + length(local!rowsAdded) + length(local!fieldsRemoved) + length(local!fieldsAdded)
  )
)

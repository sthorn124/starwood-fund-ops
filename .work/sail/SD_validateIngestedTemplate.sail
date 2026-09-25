/* Draw approval (Phase 5): the deterministic gate between Doc Center extraction and the reconciliation task.
   A received budget template fails when
     - Doc Center returned no extraction instance (the workbook could not be read), or
     - the budget table cannot be found, or is missing any standard column (SD_DRAW_TEMPLATE_COLUMNS) or any standard
       budget category row (SD_DRAW_TEMPLATE_CATEGORIES) — read from the workbook itself, not from the AI extraction, or
     - a required header value (Investment Name, Draw Number, Funding Date, Draw Amount) came back blank from extraction.
   Returns a map: ok, problems (plain-English lines), reason (the text stored on the draw), structure (the workbook's
   structure, for the comparison), investmentName and drawNumber (from the workbook), documentName.
   Never throws: every check returns a value. */
a!localVariables(
  local!structure: rule!SD_readTemplateStructure(document: ri!document),
  local!documentName: if(
    a!isNullOrEmpty(ri!document),
    "the budget template",
    document(ri!document, "name") & "." & document(ri!document, "extension")
  ),
  local!extracted: not(a!isNullOrEmpty(ri!extractionInstanceId)),
  local!header: if(
    or(not(local!extracted), a!isNullOrEmpty(ri!headerJson)),
    {},
    a!fromJson(ri!headerJson)
  ),
  local!headerKeys: if(
    a!isNullOrEmpty(local!header),
    {},
    a!forEach(items: local!header, expression: tostring(index(fv!item, "key", "")))
  ),
  local!requiredKeys: {"investmentName", "drawNumber", "fundingDate", "drawAmount"},
  local!requiredLabels: {"Investment Name", "Draw Number", "Funding Date", "Draw Amount"},
  local!blankFlags: a!forEach(
    items: local!requiredKeys,
    expression: a!localVariables(
      local!pos: if(
        a!isNullOrEmpty(local!headerKeys),
        0,
        index(wherecontains(fv!item, local!headerKeys), 1, 0)
      ),
      trim(tostring(index(index(local!header, local!pos, null), "value", ""))) = ""
    )
  ),
  local!missingHeader: if(
    not(local!extracted),
    {},
    index(local!requiredLabels, where(local!blankFlags), {})
  ),
  local!tableFound: a!defaultValue(index(local!structure, "ok", false), false),
  local!missingColumns: if(
    local!tableFound,
    rule!SD_listMinus(a: cons!SD_DRAW_TEMPLATE_COLUMNS, b: index(local!structure, "columns", {})),
    {}
  ),
  local!missingRows: if(
    local!tableFound,
    rule!SD_listMinus(a: cons!SD_DRAW_TEMPLATE_CATEGORIES, b: index(local!structure, "rows", {})),
    {}
  ),
  local!investmentName: trim(tostring(a!defaultValue(index(local!structure, "investmentName", ""), ""))),
  local!drawNumber: trim(tostring(a!defaultValue(index(local!structure, "drawNumber", ""), ""))),
  local!problems: {
    if(local!extracted, {}, "Doc Center could not read the workbook, so none of its values were extracted."),
    if(
      local!tableFound,
      {},
      "The budget table could not be found: there is no row whose first cell reads “Budget Category”."
    ),
    if(
      length(local!missingColumns) = 0,
      {},
      "The budget table is missing the standard " & if(length(local!missingColumns) = 1, "column ", "columns ")
        & rule!SD_joinQuoted(items: local!missingColumns) & "."
    ),
    if(
      length(local!missingRows) = 0,
      {},
      "The budget table is missing the standard budget " & if(length(local!missingRows) = 1, "line ", "lines ")
        & rule!SD_joinQuoted(items: local!missingRows) & "."
    ),
    if(
      length(local!missingHeader) = 0,
      {},
      "These required header fields came back blank: " & joinarray(local!missingHeader, ", ") & "."
    )
  },
  local!ok: length(local!problems) = 0,
  local!subject: "The budget template " & local!documentName
    & if(local!investmentName = "", "", " for " & local!investmentName)
    & if(local!drawNumber = "", "", " (Draw #" & local!drawNumber & ")"),
  a!map(
    ok: local!ok,
    problems: local!problems,
    reason: if(
      local!ok,
      "",
      local!subject & " could not be loaded"
        & if(
          or(not(local!tableFound), length(local!missingColumns) > 0, length(local!missingRows) > 0),
          " because it does not match the standard draw budget template",
          ""
        ) & ":"
        & char(10) & joinarray(a!forEach(items: local!problems, expression: "• " & fv!item), char(10))
        & char(10) & "Nothing from this file was loaded, and no reconciliation task was created."
    ),
    structure: local!structure,
    extracted: local!extracted,
    missingColumns: local!missingColumns,
    missingRows: local!missingRows,
    missingHeader: local!missingHeader,
    investmentName: local!investmentName,
    drawNumber: local!drawNumber,
    documentName: local!documentName
  )
)

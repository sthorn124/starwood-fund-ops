/* Draw approval (Phase 5): everything the one AI call of a failed ingestion needs, built without AI.
   Baseline: the last template that loaded for the investment (SD_getLastGoodTemplate), read with SD_readTemplateStructure;
   when there is none (or it cannot be read), the standard template from the SD_DRAW_TEMPLATE_* constants.
   Returns a map: investmentId (the investment matched by name, or null), usedLastGood, baselineLabel, baseline (structure), diff (SD_diffTemplateStructure: the ground truth the
   AI's answer is checked against), prompt (the Runtime Prompt), inputText (the Input Text: both structures, labels only —
   no amounts, so the answer cannot talk about values). */
a!localVariables(
  local!last: rule!SD_getLastGoodTemplate(investmentName: ri!investmentName, excludeDrawId: ri!excludeDrawId),
  local!lastFound: a!defaultValue(index(local!last, "found", false), false),
  local!lastStructure: if(
    local!lastFound,
    rule!SD_readTemplateStructure(document: todocument(index(local!last, "documentId", null))),
    null
  ),
  local!usedLastGood: and(local!lastFound, a!defaultValue(index(local!lastStructure, "ok", false), false)),
  local!standard: a!map(
    ok: true,
    headerLabels: cons!SD_DRAW_TEMPLATE_HEADER_LABELS,
    columns: cons!SD_DRAW_TEMPLATE_COLUMNS,
    rows: cons!SD_DRAW_TEMPLATE_CATEGORIES,
    totalLabel: "TOTAL BUDGET"
  ),
  local!baseline: if(local!usedLastGood, local!lastStructure, local!standard),
  local!baselineLabel: if(
    local!usedLastGood,
    index(local!last, "documentName", "the last template") & " (Draw #" & index(local!last, "drawNumber", "?")
      & ", received " & text(index(local!last, "receivedDate", null), "MM/DD/YYYY") & ")",
    "the standard draw budget template"
  ),
  local!diff: rule!SD_diffTemplateStructure(baseline: local!baseline, received: ri!received),
  local!describe: a!forEach(
    items: {local!baseline, ri!received},
    expression: a!localVariables(
      local!s: fv!item,
      local!sections: {
        a!map(title: "Header fields, top to bottom:", items: index(local!s, "headerLabels", {})),
        a!map(title: "Budget table column headings, left to right:", items: index(local!s, "columns", {})),
        a!map(title: "Budget category rows, top to bottom:", items: index(local!s, "rows", {}))
      },
      joinarray(
        a!forEach(
          items: local!sections,
          expression: fv!item.title & char(10) & if(
            a!isNullOrEmpty(fv!item.items),
            "(none found)",
            joinarray(a!forEach(items: fv!item.items, expression: fv!index & ". " & fv!item), char(10))
          )
        ),
        char(10) & char(10)
      )
    )
  ),
  a!map(
    investmentId: index(local!last, "investmentId", null),
    usedLastGood: local!usedLastGood,
    baselineLabel: local!baselineLabel,
    baseline: local!baseline,
    diff: local!diff,
    prompt: "You compare two versions of a construction draw budget workbook (Excel) for the accounting team of a real-estate investment fund. You are given only the STRUCTURE of each workbook: its header field labels, its budget table's column headings (left to right) and its budget category rows (top to bottom). BASELINE is the last version that loaded successfully. RECEIVED is a new file that failed to load."
      & char(10) & char(10)
      & "Find every difference in labels between BASELINE and RECEIVED:" & char(10)
      & "- A column heading in BASELINE that is not in RECEIVED was RENAMED if a RECEIVED heading that is not in BASELINE sits in the same place and plausibly means the same thing; otherwise it was REMOVED." & char(10)
      & "- A column heading in RECEIVED that is not in BASELINE and is not the new name of a renamed column was ADDED." & char(10)
      & "- Apply the same reasoning to budget category rows and to header fields." & char(10)
      & "Labels that differ only in upper or lower case or in spacing are the same label. Report only differences you can see in the lists. Do not report amounts, formatting, formulas or anything else you cannot see. Never report a difference that is not there."
      & char(10) & char(10)
      & "Answer with plain text lines only: no Markdown, no code fences, no other text." & char(10)
      & "First line:" & char(10)
      & "OVERVIEW|<two sentences in plain English for an accountant. First: which parts of the received file are laid out differently from the last template that loaded — only the parts that really differ, from: the header fields, the budget table columns, the budget category rows — and what that means for loading it. Second: what the sender should do. Keep it on the one OVERVIEW line and separate the sentences with a space, never with |. It is a summary, not a list: no labels, no quotation marks, no numbers or number words, and none of the words renamed, removed, added, missing, dropped or deleted (the CHANGE lines give the details).>" & char(10)
      & "Then one line per difference:" & char(10)
      & "CHANGE|<KIND>|<baseline label, or nothing>|<received label, or nothing>|<one plain-English sentence for the accountant that names the label or labels in double quotes and names no other label>" & char(10)
      & "KIND is one of COLUMN_RENAMED, COLUMN_REMOVED, COLUMN_ADDED, ROW_RENAMED, ROW_REMOVED, ROW_ADDED, FIELD_RENAMED, FIELD_REMOVED, FIELD_ADDED. Copy each label exactly as it appears in the lists. For a REMOVED line leave the received label empty; for an ADDED line leave the baseline label empty. Never put the | character inside a sentence. If there are no differences, write only the OVERVIEW line."
      & char(10) & char(10)
      & "Example of the format (for two other workbooks):" & char(10)
      & "OVERVIEW|The budget table columns and budget category rows in the new file are laid out differently from the last template that loaded, so its figures cannot be matched to the right columns and budget lines of the draw. The sender should restore the standard layout and resend the file." & char(10)
      & "CHANGE|COLUMN_RENAMED|Retainage|Retainage Held|The " & char(34) & "Retainage" & char(34) & " column is now headed " & char(34) & "Retainage Held" & char(34) & "." & char(10)
      & "CHANGE|ROW_REMOVED|Utilities||The " & char(34) & "Utilities" & char(34) & " budget line is missing.",
    inputText: "BASELINE — the last budget template for this investment that loaded successfully: "
      & if(local!usedLastGood, local!baselineLabel, "the standard draw budget template")
      & char(10) & char(10) & index(local!describe, 1, "")
      & char(10) & char(10) & "RECEIVED — the file that failed to load: " & a!defaultValue(ri!receivedName, "the received file")
      & char(10) & char(10) & index(local!describe, 2, "")
  )
)

/* Draw approval (Phase 3): the accountant's reconciliation task for a Doc Center extraction. Everything shown comes
   from the process (ri!headerJson / ri!linesJson, built by rule!SD_getExtractionForReconcile as text), never from a
   Doc Center read under the persona's identity. The accountant reviews or corrects the header facts and the budget
   lines beside the source workbook, which DocCenter's component plug-in renders inline (rule!AIA_UTIL_displayInlineDocument
   → fn!documentViewer through the AIA Reconcile Connected System; SD Draw Approvers holds Viewer on it), then confirms.
   On confirm the corrected values go back to the process as JSON (ri!confirmedHeaderJson / ri!confirmedLinesJson) with
   the confirming account (ri!confirmedBy); the process commits them. Doc Center's spreadsheet path reports no per-field
   confidence, so the form says so rather than inventing one.
   Layout (fix session 2026-09-22, a rendering fix with no mockup): one a!paneLayout inside the form, so the form is full
   width. Left pane: verdict strip, header facts in two columns, the three paragraph fields full width, the editable
   16-line grid with its tie-out total pinned beneath. Right pane: the workbook name as a download link above the inline
   viewer. Chips on exactly two fields — Investment Name (matches a record on file?) and Draw Number (next in the
   investment's sequence?).
   Draw-number collision (ruled 2026-09-22): the draw number is business data extracted from the template and is never
   replaced silently; a collision is resolved here, at reconciliation. When the extracted number already exists for the
   extracted investment, the field is prefilled with the next available number for that investment and an amber chip
   says so ("Submitted as #<extracted>, already on file — renumbered to next in sequence"); the accountant can override,
   and whatever is confirmed commits. When the extracted number is genuinely next in sequence the chip is green. */
a!localVariables(
  local!headerIn: if(a!isNullOrEmpty(ri!headerJson), {}, a!fromJson(ri!headerJson)),
  local!hmap: if(
    a!isNullOrEmpty(local!headerIn),
    a!map(),
    a!update(
      a!map(),
      a!forEach(items: local!headerIn, expression: tostring(fv!item.key)),
      a!forEach(items: local!headerIn, expression: tostring(a!defaultValue(fv!item.value, "")))
    )
  ),
  local!confidences: a!forEach(items: local!headerIn, expression: fv!item.confidence),
  local!hasConfidence: if(a!isNullOrEmpty(local!confidences), false, not(a!isNullOrEmpty(reject(fn!isnull, local!confidences)))),
  local!extractedDrawNumber: a!localVariables(local!n: rule!SD_parseExtractedNumber(text: index(local!hmap, "drawNumber", "")), if(local!n = 0, null, tointeger(local!n))),
  local!investmentName: trim(index(local!hmap, "investmentName", "")),
  local!fund: trim(index(local!hmap, "fund", "")),
  local!drawType: trim(index(local!hmap, "drawType", "")),
  local!fundingDate: rule!SD_parseExtractedDate(text: index(local!hmap, "fundingDate", "")),
  local!drawAmount: a!localVariables(local!n: rule!SD_parseExtractedNumber(text: index(local!hmap, "drawAmount", "")), if(local!n = 0, null, local!n)),
  local!cashEquityNeeded: trim(index(local!hmap, "cashEquityNeeded", "")),
  local!budgetStatus: trim(index(local!hmap, "budgetStatus", "")),
  local!overBudgetReason: trim(index(local!hmap, "overBudgetReason", "")),
  local!purpose: trim(index(local!hmap, "purpose", "")),
  local!contingencyExplanation: trim(index(local!hmap, "contingencyExplanation", "")),
  local!generalComments: trim(index(local!hmap, "generalComments", "")),
  local!submittedBy: a!localVariables(
    local!raw: trim(index(local!hmap, "submittedBy", "")),
    if(lower(left(local!raw, 13)) = "submitted by ", trim(right(local!raw, len(local!raw) - 13)), local!raw)
  ),
  local!linesIn: if(a!isNullOrEmpty(ri!linesJson), {}, a!fromJson(ri!linesJson)),
  local!lines: a!forEach(
    items: local!linesIn,
    expression: a!map(
      lineOrder: fv!index,
      budgetCategory: tostring(a!defaultValue(fv!item.budgetCategory, "")),
      initialBudget: rule!SD_parseExtractedNumber(text: fv!item.initialBudget),
      revisedApprovedBudget: rule!SD_parseExtractedNumber(text: fv!item.revisedApprovedBudget),
      proposedAdjustmentsThisDraw: rule!SD_parseExtractedNumber(text: fv!item.proposedAdjustmentsThisDraw),
      proposedBudget: rule!SD_parseExtractedNumber(text: fv!item.proposedBudget),
      currentDraw: rule!SD_parseExtractedNumber(text: fv!item.currentDraw),
      totalPtdIncThisDrawAmount: rule!SD_parseExtractedNumber(text: fv!item.totalPtdIncThisDrawAmount),
      totalPtdIncThisDrawPct: rule!SD_parseExtractedNumber(text: fv!item.totalPtdIncThisDrawPct),
      balanceToComplete: rule!SD_parseExtractedNumber(text: fv!item.balanceToComplete)
    )
  ),
  /* Investment match: exact name, case-insensitive, against every SD Investment on file. */
  local!investments: a!queryRecordType(
    recordType: 'recordType!{f285a98c-746c-40e7-899e-65d8d20f766b}SD Investment',
    fields: {
      'recordType!{f285a98c-746c-40e7-899e-65d8d20f766b}SD Investment.fields.{5739486c-cd04-4774-a878-17ca0b9933c4}id',
      'recordType!{f285a98c-746c-40e7-899e-65d8d20f766b}SD Investment.fields.{e79c63ed-a43c-4951-b679-e2578ed5cbf6}investmentName'
    },
    pagingInfo: a!pagingInfo(startIndex: 1, batchSize: 200)
  ).data,
  local!investmentNames: a!forEach(items: local!investments, expression: lower(trim(tostring(a!defaultValue(fv!item['recordType!{f285a98c-746c-40e7-899e-65d8d20f766b}SD Investment.fields.{e79c63ed-a43c-4951-b679-e2578ed5cbf6}investmentName'], ""))))),
  local!matchIdx: if(or(a!isNullOrEmpty(local!investmentNames), local!investmentName = ""), {}, wherecontains(lower(local!investmentName), local!investmentNames)),
  local!matchedInvestment: if(a!isNullOrEmpty(local!matchIdx), null, index(local!investments, local!matchIdx[1], null)),
  local!matchedInvestmentId: if(a!isNullOrEmpty(local!matchedInvestment), null, local!matchedInvestment['recordType!{f285a98c-746c-40e7-899e-65d8d20f766b}SD Investment.fields.{5739486c-cd04-4774-a878-17ca0b9933c4}id']),
  local!matchedInvestmentName: if(a!isNullOrEmpty(local!matchedInvestment), "", tostring(local!matchedInvestment['recordType!{f285a98c-746c-40e7-899e-65d8d20f766b}SD Investment.fields.{e79c63ed-a43c-4951-b679-e2578ed5cbf6}investmentName'])),
  /* Draw sequence: the highest draw number already on file for the matched investment, this draw's own row excluded. */
  local!priorDrawNumbers: if(
    a!isNullOrEmpty(local!matchedInvestmentId),
    {},
    a!forEach(
      items: a!queryRecordType(
        recordType: 'recordType!{c9d3a947-71aa-4024-879e-363873a12860}SD Draw',
        fields: {'recordType!{c9d3a947-71aa-4024-879e-363873a12860}SD Draw.fields.{9aa1030b-f76b-49aa-bef6-99eb90327804}drawNumber'},
        filters: a!queryLogicalExpression(
          operator: "AND",
          filters: {
            a!queryFilter(field: 'recordType!{c9d3a947-71aa-4024-879e-363873a12860}SD Draw.fields.{09edf0b2-28a3-4a7f-b9dc-ae2afefa24d0}investmentId', operator: "=", value: local!matchedInvestmentId),
            a!queryFilter(field: 'recordType!{c9d3a947-71aa-4024-879e-363873a12860}SD Draw.fields.{443829ca-5971-4d31-8fac-ab7a317e509b}id', operator: "<>", value: ri!drawId, applyWhen: not(a!isNullOrEmpty(ri!drawId)))
          },
          ignoreFiltersWithEmptyValues: true
        ),
        pagingInfo: a!pagingInfo(startIndex: 1, batchSize: 500)
      ).data,
      expression: a!defaultValue(fv!item['recordType!{c9d3a947-71aa-4024-879e-363873a12860}SD Draw.fields.{9aa1030b-f76b-49aa-bef6-99eb90327804}drawNumber'], 0)
    )
  ),
  local!lastDrawNumber: if(a!isNullOrEmpty(local!priorDrawNumbers), 0, max(local!priorDrawNumbers)),
  local!nextAvailable: local!lastDrawNumber + 1,
  /* Collision: the extracted number is already on file for the matched investment. */
  local!collision: and(
    not(a!isNullOrEmpty(local!extractedDrawNumber)),
    not(a!isNullOrEmpty(local!priorDrawNumbers)),
    contains(tointeger(local!priorDrawNumbers), tointeger(local!extractedDrawNumber))
  ),
  /* The editable draw number: prefilled once, at load, with the next available number on a collision, else the
     extracted number. Refresh on referenced-variable change is off so the accountant's override survives edits to
     the other fields (a dependent local would otherwise be recomputed and overwrite it). */
  local!drawNumber: a!refreshVariable(
    value: if(local!collision, local!nextAvailable, local!extractedDrawNumber),
    refreshOnReferencedVarChange: false
  ),
  local!drawNumberOnFile: and(
    not(a!isNullOrEmpty(local!drawNumber)),
    not(a!isNullOrEmpty(local!priorDrawNumbers)),
    contains(tointeger(local!priorDrawNumbers), tointeger(local!drawNumber))
  ),
  local!nextInSequence: and(not(a!isNullOrEmpty(local!drawNumber)), local!drawNumber = local!nextAvailable),
  /* Chip state for the Draw Number field, from the current value: RENUMBERED (collision resolved by the prefill and
     still on the next available number), NEXT (genuinely next in sequence), ON_FILE (the current value collides — an
     override back onto a used number), else GAP (neither; kept as typed). */
  local!drawNumberChip: if(
    and(local!collision, local!nextInSequence),
    "RENUMBERED",
    if(local!nextInSequence, "NEXT", if(local!drawNumberOnFile, "ON_FILE", "GAP"))
  ),
  /* Tie-out: the current-draw lines against the header's draw amount, recomputed on every edit. */
  local!linesTotal: if(a!isNullOrEmpty(local!lines), 0, sum(a!forEach(items: local!lines, expression: a!defaultValue(fv!item.currentDraw, 0)))),
  local!difference: local!linesTotal - a!defaultValue(local!drawAmount, 0),
  local!ties: and(not(a!isNullOrEmpty(local!drawAmount)), abs(local!difference) < 0.005),
  local!green: a!map(bg: "#E6F4EC", fg: "#1E7E46"),
  local!amber: a!map(bg: "#FDF3E0", fg: "#92600A"),
  local!red: a!map(bg: "#FDECEC", fg: "#B42318"),
  a!formLayout(
    titleBar: a!headerTemplateFull(
      title: "Reconcile extracted draw" & if(a!isNullOrEmpty(local!extractedDrawNumber), "", " #" & local!extractedDrawNumber),
      secondaryText: "Doc Center extraction of " & a!defaultValue(ri!documentName, "the budget template") & " · confirm or correct against the workbook on the right, then the draw is assembled",
      backgroundColor: "#16294D"
    ),
    showTitleBarDivider: true,
    contents: {
      a!paneLayout(
        panes: {
          /* Left pane: what was extracted, editable. */
          a!pane(
            contents: {
              /* Verdict strip: one line of facts, the tie-out chip beside it. */
              a!sideBySideLayout(
                items: {
                  a!sideBySideItem(
                    item: a!richTextDisplayField(
                      labelPosition: "COLLAPSED",
                      value: {
                        a!richTextItem(text: "EXTRACTION", color: "#6B7280", size: "SMALL", style: "STRONG"),
                        a!richTextItem(text: "  instance #" & a!defaultValue(ri!instanceId, "—") & " · " & count(local!headerIn) & " header fields · " & count(local!lines) & " budget lines", color: "#374151", size: "SMALL"),
                        char(10),
                        if(
                          local!hasConfidence,
                          a!richTextItem(text: "Doc Center confidence is shown beside each field.", color: "#6B7280", size: "SMALL"),
                          a!richTextItem(text: "Doc Center reports no per-field confidence for spreadsheet extraction; every value is presented for review.", color: "#6B7280", size: "SMALL")
                        )
                      }
                    ),
                    width: "AUTO"
                  ),
                  a!sideBySideItem(
                    item: a!tagField(
                      labelPosition: "COLLAPSED",
                      tags: a!tagItem(
                        text: if(
                          local!ties,
                          "Ties ✓ " & rule!SD_fmtMoney(value: local!linesTotal, showCents: true),
                          "Does not tie · lines " & rule!SD_fmtMoney(value: local!linesTotal, showCents: true) & " vs draw " & if(a!isNullOrEmpty(local!drawAmount), "—", rule!SD_fmtMoney(value: local!drawAmount, showCents: true))
                        ),
                        backgroundColor: if(local!ties, local!green.bg, local!red.bg),
                        textColor: if(local!ties, local!green.fg, local!red.fg)
                      ),
                      size: "SMALL",
                      align: "END"
                    ),
                    width: "MINIMIZE"
                  )
                },
                alignVertical: "TOP",
                spacing: "STANDARD",
                marginBelow: "STANDARD"
              ),
              /* Header facts, two columns. */
              a!richTextDisplayField(
                labelPosition: "COLLAPSED",
                value: a!richTextItem(text: "DRAW HEADER · EXTRACTED", color: "#6B7280", size: "SMALL", style: "STRONG"),
                marginBelow: "LESS"
              ),
              a!columnsLayout(
                columns: {
                  a!columnLayout(
                    contents: {
                      a!integerField(label: "Draw Number", value: local!drawNumber, saveInto: local!drawNumber, required: true, requiredMessage: "The draw number is required.", marginBelow: "EVEN_LESS"),
                      a!tagField(
                        labelPosition: "COLLAPSED",
                        tags: a!tagItem(
                          text: a!match(
                            value: local!drawNumberChip,
                            equals: "RENUMBERED", then: "Submitted as #" & local!extractedDrawNumber & ", already on file — renumbered to next in sequence",
                            equals: "NEXT", then: "Next in sequence",
                            equals: "ON_FILE", then: "#" & local!drawNumber & " is already on file for this investment",
                            default: "Out of sequence: last draw is " & if(local!lastDrawNumber = 0, "none on file", "#" & local!lastDrawNumber)
                          ),
                          backgroundColor: if(local!drawNumberChip = "NEXT", local!green.bg, local!amber.bg),
                          textColor: if(local!drawNumberChip = "NEXT", local!green.fg, local!amber.fg)
                        ),
                        size: "SMALL",
                        showWhen: not(a!isNullOrEmpty(local!matchedInvestmentId)),
                        marginBelow: "STANDARD"
                      ),
                      a!textField(label: "Fund", value: local!fund, saveInto: local!fund),
                      a!dateField(label: "Funding Date", value: local!fundingDate, saveInto: local!fundingDate, required: true, requiredMessage: "The funding date is required."),
                      a!textField(label: "Cash/Equity Needed from the Fund?", value: local!cashEquityNeeded, saveInto: local!cashEquityNeeded),
                      a!textField(label: "Over Budget Reason", value: local!overBudgetReason, saveInto: local!overBudgetReason)
                    },
                    width: "AUTO"
                  ),
                  a!columnLayout(
                    contents: {
                      a!textField(label: "Investment Name", value: local!investmentName, saveInto: local!investmentName, required: true, marginBelow: "EVEN_LESS"),
                      a!tagField(
                        labelPosition: "COLLAPSED",
                        tags: a!tagItem(
                          text: if(
                            a!isNullOrEmpty(local!matchedInvestmentId),
                            "No matching investment",
                            "Matches " & local!matchedInvestmentName & " on file"
                          ),
                          backgroundColor: if(a!isNullOrEmpty(local!matchedInvestmentId), local!amber.bg, local!green.bg),
                          textColor: if(a!isNullOrEmpty(local!matchedInvestmentId), local!amber.fg, local!green.fg)
                        ),
                        size: "SMALL",
                        marginBelow: "STANDARD"
                      ),
                      a!textField(label: "Draw Type", value: local!drawType, saveInto: local!drawType, required: true),
                      a!floatingPointField(label: "Draw Amount", value: local!drawAmount, saveInto: local!drawAmount, required: true, requiredMessage: "The draw amount is required.", align: "RIGHT"),
                      a!textField(label: "On / Under / Over Budget", value: local!budgetStatus, saveInto: local!budgetStatus),
                      a!textField(label: "Submitted By", value: local!submittedBy, saveInto: local!submittedBy)
                    },
                    width: "AUTO"
                  )
                },
                stackWhen: {"PHONE"},
                marginBelow: "NONE"
              ),
              a!paragraphField(label: "Purpose", value: local!purpose, saveInto: local!purpose, height: "SHORT"),
              a!paragraphField(label: "Budget and Contingency Explanation", value: local!contingencyExplanation, saveInto: local!contingencyExplanation, height: "SHORT"),
              a!paragraphField(label: "General Comments", value: local!generalComments, saveInto: local!generalComments, height: "SHORT", instructions: "Not extracted from the template; add anything the approvers should read."),
              /* Budget lines, editable, with the tie-out total pinned beneath. */
              a!richTextDisplayField(
                labelPosition: "COLLAPSED",
                value: {
                  a!richTextItem(text: "BUDGET LINES · EXTRACTED", color: "#6B7280", size: "SMALL", style: "STRONG"),
                  a!richTextItem(text: "  " & count(local!lines) & " budget categories in sheet order · USD · PTD % as a percent", color: "#6B7280", size: "SMALL")
                },
                marginBelow: "LESS"
              ),
              a!gridLayout(
                labelPosition: "COLLAPSED",
                headerCells: {
                  a!gridLayoutHeaderCell(label: "Budget Category"),
                  a!gridLayoutHeaderCell(label: "Initial", align: "RIGHT"),
                  a!gridLayoutHeaderCell(label: "Revised", align: "RIGHT"),
                  a!gridLayoutHeaderCell(label: "Adj.", align: "RIGHT"),
                  a!gridLayoutHeaderCell(label: "Proposed", align: "RIGHT"),
                  a!gridLayoutHeaderCell(label: "Current Draw", align: "RIGHT"),
                  a!gridLayoutHeaderCell(label: "PTD $", align: "RIGHT"),
                  a!gridLayoutHeaderCell(label: "PTD %", align: "RIGHT"),
                  a!gridLayoutHeaderCell(label: "Balance", align: "RIGHT")
                },
                columnConfigs: {
                  a!gridLayoutColumnConfig(width: "DISTRIBUTE", weight: 4),
                  a!gridLayoutColumnConfig(width: "DISTRIBUTE", weight: 3),
                  a!gridLayoutColumnConfig(width: "DISTRIBUTE", weight: 3),
                  a!gridLayoutColumnConfig(width: "DISTRIBUTE", weight: 2),
                  a!gridLayoutColumnConfig(width: "DISTRIBUTE", weight: 3),
                  a!gridLayoutColumnConfig(width: "DISTRIBUTE", weight: 3),
                  a!gridLayoutColumnConfig(width: "DISTRIBUTE", weight: 3),
                  a!gridLayoutColumnConfig(width: "DISTRIBUTE", weight: 2),
                  a!gridLayoutColumnConfig(width: "DISTRIBUTE", weight: 3)
                },
                rows: a!forEach(
                  items: local!lines,
                  expression: a!gridRowLayout(
                    id: fv!index,
                    contents: {
                      a!textField(value: fv!item.budgetCategory, saveInto: fv!item.budgetCategory, required: true),
                      a!floatingPointField(value: fv!item.initialBudget, saveInto: fv!item.initialBudget, align: "RIGHT"),
                      a!floatingPointField(value: fv!item.revisedApprovedBudget, saveInto: fv!item.revisedApprovedBudget, align: "RIGHT"),
                      a!floatingPointField(value: fv!item.proposedAdjustmentsThisDraw, saveInto: fv!item.proposedAdjustmentsThisDraw, align: "RIGHT"),
                      a!floatingPointField(value: fv!item.proposedBudget, saveInto: fv!item.proposedBudget, align: "RIGHT"),
                      a!floatingPointField(value: fv!item.currentDraw, saveInto: fv!item.currentDraw, align: "RIGHT"),
                      a!floatingPointField(value: fv!item.totalPtdIncThisDrawAmount, saveInto: fv!item.totalPtdIncThisDrawAmount, align: "RIGHT"),
                      a!floatingPointField(value: fv!item.totalPtdIncThisDrawPct, saveInto: fv!item.totalPtdIncThisDrawPct, align: "RIGHT"),
                      a!floatingPointField(value: fv!item.balanceToComplete, saveInto: fv!item.balanceToComplete, align: "RIGHT")
                    }
                  )
                ),
                validations: if(a!isNullOrEmpty(local!lines), "Doc Center returned no budget lines; the template cannot be confirmed without them.", null),
                spacing: "DENSE",
                shadeAlternateRows: true,
                emptyGridMessage: "No budget lines were extracted"
              ),
              a!richTextDisplayField(
                labelPosition: "COLLAPSED",
                align: "RIGHT",
                value: {
                  a!richTextItem(text: "Current Draw total  ", color: "#6B7280", size: "SMALL"),
                  a!richTextItem(text: rule!SD_fmtMoney(value: local!linesTotal, showCents: true), color: "#16294D", size: "MEDIUM", style: "STRONG"),
                  a!richTextItem(text: "   vs draw amount " & if(a!isNullOrEmpty(local!drawAmount), "—", rule!SD_fmtMoney(value: local!drawAmount, showCents: true)), color: "#6B7280", size: "SMALL"),
                  a!richTextItem(
                    text: if(local!ties, "   Ties ✓", "   off by " & rule!SD_fmtMoney(value: local!difference, showCents: true)),
                    color: if(local!ties, local!green.fg, local!red.fg),
                    size: "SMALL",
                    style: "STRONG"
                  )
                },
                marginBelow: "STANDARD"
              )
            },
            width: "AUTO",
            padding: "STANDARD"
          ),
          /* Right pane: the source workbook, inline. */
          a!pane(
            contents: {
              a!richTextDisplayField(
                labelPosition: "COLLAPSED",
                value: {
                  a!richTextItem(text: "SOURCE DOCUMENT", color: "#6B7280", size: "SMALL", style: "STRONG"),
                  char(10),
                  if(
                    a!isNullOrEmpty(ri!documentId),
                    a!richTextItem(text: a!defaultValue(ri!documentName, "—"), style: "STRONG"),
                    a!richTextItem(
                      text: a!defaultValue(ri!documentName, "Budget template"),
                      link: a!documentDownloadLink(document: todocument(ri!documentId)),
                      linkStyle: "STANDALONE",
                      style: "STRONG"
                    )
                  ),
                  a!richTextItem(text: "  download", color: "#6B7280", size: "SMALL")
                },
                marginBelow: "LESS"
              ),
              if(
                a!isNullOrEmpty(ri!documentId),
                a!richTextDisplayField(labelPosition: "COLLAPSED", value: a!richTextItem(text: "No source document is attached to this extraction.", color: "#6B7280", size: "SMALL")),
                rule!AIA_UTIL_displayInlineDocument(
                  documentId: ri!documentId,
                  sourceDocumentId: ri!documentId,
                  height: "TALL"
                )
              )
            },
            width: "AUTO",
            padding: "LESS",
            backgroundColor: "#F5F6F8"
          )
        },
        showPaneDividers: true
      )
    },
    buttons: a!buttonLayout(
      primaryButtons: a!buttonWidget(
        label: "Confirm & Assemble Draw",
        submit: true,
        style: "SOLID",
        loadingIndicator: true,
        validate: true,
        saveInto: {
          a!save(
            ri!confirmedHeaderJson,
            a!toJson(
              a!map(
                drawNumber: tostring(a!defaultValue(local!drawNumber, "")),
                investmentName: a!defaultValue(local!investmentName, ""),
                investmentId: tostring(a!defaultValue(local!matchedInvestmentId, "")),
                fund: a!defaultValue(local!fund, ""),
                drawType: a!defaultValue(local!drawType, ""),
                fundingDate: if(a!isNullOrEmpty(local!fundingDate), "", text(local!fundingDate, "yyyy-MM-dd")),
                drawAmount: if(a!isNullOrEmpty(local!drawAmount), "", fixed(local!drawAmount, 4, true)),
                cashEquityNeeded: a!defaultValue(local!cashEquityNeeded, ""),
                budgetStatus: a!defaultValue(local!budgetStatus, ""),
                overBudgetReason: a!defaultValue(local!overBudgetReason, ""),
                purpose: a!defaultValue(local!purpose, ""),
                contingencyExplanation: a!defaultValue(local!contingencyExplanation, ""),
                generalComments: a!defaultValue(local!generalComments, ""),
                submittedBy: a!defaultValue(local!submittedBy, "")
              )
            )
          ),
          a!save(
            ri!confirmedLinesJson,
            if(
              a!isNullOrEmpty(local!lines),
              "[]",
              a!toJson(
                a!forEach(
                  items: local!lines,
                  expression: a!map(
                    lineOrder: fv!index,
                    budgetCategory: a!defaultValue(fv!item.budgetCategory, ""),
                    initialBudget: fixed(a!defaultValue(fv!item.initialBudget, 0), 4, true),
                    revisedApprovedBudget: fixed(a!defaultValue(fv!item.revisedApprovedBudget, 0), 4, true),
                    proposedAdjustmentsThisDraw: fixed(a!defaultValue(fv!item.proposedAdjustmentsThisDraw, 0), 4, true),
                    proposedBudget: fixed(a!defaultValue(fv!item.proposedBudget, 0), 4, true),
                    currentDraw: fixed(a!defaultValue(fv!item.currentDraw, 0), 4, true),
                    totalPtdIncThisDrawAmount: fixed(a!defaultValue(fv!item.totalPtdIncThisDrawAmount, 0), 4, true),
                    totalPtdIncThisDrawPct: fixed(a!defaultValue(fv!item.totalPtdIncThisDrawPct, 0), 4, true),
                    balanceToComplete: fixed(a!defaultValue(fv!item.balanceToComplete, 0), 4, true)
                  )
                )
              )
            )
          ),
          a!save(ri!confirmedBy, loggedInUser())
        }
      )
    ),
    showButtonDivider: true,
    validations: if(a!isNullOrEmpty(local!lines), "At least one budget line is required.", null)
  )
)

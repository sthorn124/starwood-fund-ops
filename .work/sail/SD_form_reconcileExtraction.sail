/* Draw approval (Phase 3): the accountant's reconciliation task for a Doc Center extraction. Everything shown comes
   from the process (ri!headerJson / ri!linesJson, built by rule!SD_getExtractionForReconcile as text), never from a
   Doc Center read under the persona's identity. The accountant reviews or corrects the header facts and the budget
   lines beside a link to the source workbook, then confirms. On confirm the corrected values go back to the process
   as JSON (ri!confirmedHeaderJson / ri!confirmedLinesJson) with the confirming account (ri!confirmedBy); the process
   commits them. Doc Center's spreadsheet path reports no per-field confidence, so the form says so rather than
   inventing one. */
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
  local!drawNumber: a!localVariables(local!n: rule!SD_parseExtractedNumber(text: index(local!hmap, "drawNumber", "")), if(local!n = 0, null, tointeger(local!n))),
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
  local!matchedInvestmentId: if(a!isNullOrEmpty(local!matchIdx), null, index(local!investments, local!matchIdx[1], null)['recordType!{f285a98c-746c-40e7-899e-65d8d20f766b}SD Investment.fields.{5739486c-cd04-4774-a878-17ca0b9933c4}id']),
  local!linesTotal: if(a!isNullOrEmpty(local!lines), 0, sum(a!forEach(items: local!lines, expression: a!defaultValue(fv!item.currentDraw, 0)))),
  local!ties: and(not(a!isNullOrEmpty(local!drawAmount)), abs(local!linesTotal - a!defaultValue(local!drawAmount, 0)) < 0.005),
  a!formLayout(
    titleBar: a!headerTemplateFull(
      title: "Reconcile extracted draw" & if(a!isNullOrEmpty(local!drawNumber), "", " #" & local!drawNumber),
      secondaryText: "Doc Center extraction of " & a!defaultValue(ri!documentName, "the budget template") & " · confirm or correct, then the draw is assembled",
      backgroundColor: "#16294D"
    ),
    contents: {
      a!columnsLayout(
        columns: {
          a!columnLayout(
            contents: {
              a!cardLayout(
                contents: {
                  a!richTextDisplayField(
                    labelPosition: "COLLAPSED",
                    value: {
                      a!richTextItem(text: "DRAW HEADER · EXTRACTED", color: "#6B7280", size: "SMALL"),
                      char(10),
                      a!richTextItem(text: "Every value below was read from the workbook. Correct anything that is wrong; the corrected values are what the draw records.", color: "#374151", size: "SMALL")
                    },
                    marginBelow: "STANDARD"
                  ),
                  a!columnsLayout(
                    columns: {
                      a!columnLayout(
                        contents: {
                          a!integerField(label: "Draw Number", value: local!drawNumber, saveInto: local!drawNumber, required: true, requiredMessage: "The draw number is required."),
                          a!textField(
                            label: "Investment Name",
                            value: local!investmentName,
                            saveInto: local!investmentName,
                            required: true,
                            instructions: if(
                              a!isNullOrEmpty(local!matchedInvestmentId),
                              "No investment on file with this exact name — the draw will be created without an investment link until it is corrected.",
                              "Matches investment #" & local!matchedInvestmentId & " on file."
                            )
                          ),
                          a!textField(label: "Fund", value: local!fund, saveInto: local!fund),
                          a!textField(label: "Draw Type", value: local!drawType, saveInto: local!drawType, required: true),
                          a!dateField(label: "Funding Date", value: local!fundingDate, saveInto: local!fundingDate, required: true, requiredMessage: "The funding date is required."),
                          a!floatingPointField(label: "Draw Amount", value: local!drawAmount, saveInto: local!drawAmount, required: true, requiredMessage: "The draw amount is required.", align: "RIGHT")
                        }
                      ),
                      a!columnLayout(
                        contents: {
                          a!textField(label: "Cash/Equity Needed from the Fund?", value: local!cashEquityNeeded, saveInto: local!cashEquityNeeded),
                          a!textField(label: "On / Under / Over Budget", value: local!budgetStatus, saveInto: local!budgetStatus),
                          a!textField(label: "Over Budget Reason", value: local!overBudgetReason, saveInto: local!overBudgetReason),
                          a!textField(label: "Submitted By", value: local!submittedBy, saveInto: local!submittedBy),
                          a!paragraphField(label: "Purpose", value: local!purpose, saveInto: local!purpose, height: "SHORT")
                        }
                      )
                    }
                  ),
                  a!paragraphField(label: "Budget and Contingency Explanation", value: local!contingencyExplanation, saveInto: local!contingencyExplanation, height: "SHORT"),
                  a!paragraphField(label: "General Comments", value: local!generalComments, saveInto: local!generalComments, height: "SHORT")
                },
                style: "NONE",
                shape: "SEMI_ROUNDED",
                padding: "STANDARD",
                showBorder: true,
                showShadow: false,
                marginBelow: "STANDARD"
              ),
              a!cardLayout(
                contents: {
                  a!richTextDisplayField(
                    labelPosition: "COLLAPSED",
                    value: {
                      a!richTextItem(text: "BUDGET LINES · EXTRACTED", color: "#6B7280", size: "SMALL"),
                      char(10),
                      a!richTextItem(text: count(local!lines) & " budget categories in sheet order. Amounts in USD; PTD % as a percent.", color: "#374151", size: "SMALL")
                    },
                    marginBelow: "STANDARD"
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
                  )
                },
                style: "NONE",
                shape: "SEMI_ROUNDED",
                padding: "STANDARD",
                showBorder: true,
                showShadow: false,
                marginBelow: "STANDARD"
              )
            },
            width: "AUTO"
          ),
          a!columnLayout(
            contents: {
              a!cardLayout(
                contents: {
                  a!richTextDisplayField(
                    labelPosition: "COLLAPSED",
                    value: {
                      a!richTextItem(text: "SOURCE DOCUMENT", color: "#6B7280", size: "SMALL"),
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
                      char(10),
                      a!richTextItem(text: "Doc Center extraction instance #" & a!defaultValue(ri!instanceId, "—") & " · " & count(local!headerIn) & " header fields · " & count(local!lines) & " budget lines", color: "#6B7280", size: "SMALL")
                    },
                    marginBelow: "STANDARD"
                  ),
                  a!richTextDisplayField(
                    labelPosition: "COLLAPSED",
                    value: {
                      a!richTextItem(text: "CONFIDENCE", color: "#6B7280", size: "SMALL"),
                      char(10),
                      if(
                        local!hasConfidence,
                        a!richTextItem(text: "Doc Center confidence is shown beside each field.", color: "#374151", size: "SMALL"),
                        a!richTextItem(text: "Doc Center reports no per-field confidence for spreadsheet extraction; every value is presented for review.", color: "#374151", size: "SMALL")
                      )
                    },
                    marginBelow: "STANDARD"
                  ),
                  a!richTextDisplayField(
                    labelPosition: "COLLAPSED",
                    value: {
                      a!richTextItem(text: "AMOUNT VERIFICATION", color: "#6B7280", size: "SMALL"),
                      char(10),
                      a!richTextItem(
                        text: "Current draw lines " & rule!SD_fmtMoney(value: local!linesTotal, showCents: true) & " vs draw amount " & if(a!isNullOrEmpty(local!drawAmount), "—", rule!SD_fmtMoney(value: local!drawAmount, showCents: true)),
                        color: "#374151",
                        size: "SMALL"
                      )
                    },
                    marginBelow: "LESS"
                  ),
                  a!tagField(
                    labelPosition: "COLLAPSED",
                    tags: a!tagItem(
                      text: if(local!ties, "Ties ✓", "Does not tie"),
                      backgroundColor: if(local!ties, "#E6F4EC", "#FDECEC"),
                      textColor: if(local!ties, "#1E7E46", "#B42318")
                    ),
                    size: "SMALL"
                  )
                },
                style: "NONE",
                shape: "SEMI_ROUNDED",
                padding: "STANDARD",
                showBorder: true,
                showShadow: false,
                marginBelow: "STANDARD"
              )
            },
            width: "MEDIUM"
          )
        },
        stackWhen: {"PHONE", "TABLET_PORTRAIT"}
      )
    },
    buttons: a!buttonLayout(
      primaryButtons: a!buttonWidget(
        label: "Confirm & assemble draw",
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
    validations: if(a!isNullOrEmpty(local!lines), "At least one budget line is required.", null)
  )
)

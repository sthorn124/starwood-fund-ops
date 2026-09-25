from refs import *
L = lambda n: fld(LINE, n)
Q = lambda n: fld(QIU, n)
Dc = lambda n: fld(DOC, n)
Dr = lambda n: fld(DRAW, n)

line_fields = ["id","lineOrder","budgetCategory","categoryGroup","inThisDraw","initialBudget","revisedApprovedBudget",
               "proposedAdjustmentsThisDraw","proposedBudget","currentDraw","totalPtdIncThisDrawAmount","totalPtdIncThisDrawPct","balanceToComplete"]
qiu_fields = ["id","metricOrder","metric","modelAsOfDate","currentModelValue","currentProjection","variance","notes"]
doc_fields = ["id","document","documentName","documentType","uploadedBy","uploadedAt","status","notes","receivedDate"]
hist_fields = ["id","drawNumber","fundingDate","amount","drawType","purpose","status"]

def query(rt_, fields, filters, sortf, batch=100, desc=False):
    return f"""a!queryRecordType(
      recordType: {rt(rt_)},
      fields: {{
        {", ".join(fld(rt_, f) for f in fields)}
      }},
      filters: {filters},
      pagingInfo: a!pagingInfo(startIndex: 1, batchSize: {batch}, sort: a!sortInfo(field: {fld(rt_, sortf)}, ascending: {"false" if desc else "true"}))
    ).data"""

def tomaps(rt_, fields):
    return "a!forEach(items: local!raw, expression: a!map(" + ", ".join(f"{f}: fv!item[{fld(rt_, f)}]" for f in fields) + "))"

money = lambda e: f"rule!SD_fmtMoney(value: {e}, showCents: false)"
money_dash = lambda e: f"if(a!defaultValue({e}, 0) = 0, \"—\", {money(e)})"

def group_row(name):
    return f"""a!map(
      group: "{name}",
      revised: sum(a!forEach(items: local!lines, expression: if(fv!item.categoryGroup = "{name}", a!defaultValue(fv!item.revisedApprovedBudget, 0), 0))),
      adj: sum(a!forEach(items: local!lines, expression: if(fv!item.categoryGroup = "{name}", a!defaultValue(fv!item.proposedAdjustmentsThisDraw, 0), 0))),
      proposed: sum(a!forEach(items: local!lines, expression: if(fv!item.categoryGroup = "{name}", a!defaultValue(fv!item.proposedBudget, 0), 0))),
      current: sum(a!forEach(items: local!lines, expression: if(fv!item.categoryGroup = "{name}", a!defaultValue(fv!item.currentDraw, 0), 0)))
    )"""

card_open = lambda: 'a!cardLayout(\n    contents: {'
card_close = '''},
    style: "NONE",
    shape: "SEMI_ROUNDED",
    padding: "STANDARD",
    showBorder: true,
    showShadow: false,
    marginBelow: "STANDARD"
  )'''

card_close_hide = card_close.replace('style: "NONE",', 'style: "NONE",\n    showWhen: not(local!failed),')

def heading(text_expr, src_expr=None):
    h = f'''a!richTextDisplayField(
        labelPosition: "COLLAPSED",
        value: a!richTextItem(text: {text_expr}, size: "MEDIUM", style: "STRONG", color: "#16294D"),
        marginBelow: {"\"EVEN_LESS\"" if src_expr else "\"STANDARD\""}
      )'''
    if src_expr:
        h += f",\n      rule!SD_cmp_sourceLine(text: {src_expr})"
    return h

sail = f"""/* Draw approval: the Summary view of a draw record, built against mockups/draw-summary.html (the UI contract).
   Section order: fact strip · action strip (current step's assignee group only) · ingestion-failed state card (Phase 5,
   failed draws only, which then show just the fact strip, the card and Draw Origin) · approval progress · Draw Origin ·
   Draw Funding Detail · Budget Summary + Remaining Contingency · Funding History · QIU Detail.
   Every figure is computed from the draw's rows: roll-ups from the budget lines, tie-out of the current draw lines
   against the header amount, PTD from the lines, aging from today(). Nothing is typed in from the sample. */
a!localVariables(
  local!d: rule!SD_getDrawDetail(drawId: ri!drawId),
  local!found: a!defaultValue(index(local!d, "found", false), false),
  local!lines: if(
    not(local!found),
    {{}},
    a!localVariables(
      local!raw: {query(LINE, line_fields, f'a!queryFilter(field: {L("drawId")}, operator: "=", value: ri!drawId)', "lineOrder")},
      {tomaps(LINE, line_fields)}
    )
  ),
  local!qiu: if(
    not(local!found),
    {{}},
    a!localVariables(
      local!raw: {query(QIU, qiu_fields, f'a!queryFilter(field: {Q("drawId")}, operator: "=", value: ri!drawId)', "metricOrder")},
      {tomaps(QIU, qiu_fields)}
    )
  ),
  local!docs: if(
    not(local!found),
    {{}},
    a!localVariables(
      local!raw: {query(DOC, doc_fields, f'a!queryFilter(field: {Dc("drawId")}, operator: "=", value: ri!drawId)', "id")},
      {tomaps(DOC, doc_fields)}
    )
  ),
  local!history: if(
    or(not(local!found), a!isNullOrEmpty(index(local!d, "investmentId", null))),
    {{}},
    a!localVariables(
      local!raw: {query(DRAW, hist_fields, f'''a!queryLogicalExpression(
        operator: "AND",
        filters: {{
          a!queryFilter(field: {Dr("investmentId")}, operator: "=", value: index(local!d, "investmentId", null)),
          a!queryFilter(field: {Dr("drawNumber")}, operator: "<", value: a!defaultValue(index(local!d, "drawNumber", 0), 0)),
          a!queryFilter(field: {Dr("status")}, operator: "=", value: "Approved")
        }}
      )''', "drawNumber", batch=3, desc=True)},
      {tomaps(DRAW, hist_fields)}
    )
  ),
  /* Tie-out: the current-draw lines against the header amount, to the cent */
  local!linesSum: sum(a!forEach(items: local!lines, expression: a!defaultValue(fv!item.currentDraw, 0))),
  local!amount: a!defaultValue(index(local!d, "amount", 0), 0),
  local!noLines: a!isNullOrEmpty(local!lines),
  local!ties: abs(local!linesSum - local!amount) < 0.005,
  /* Budget Summary roll-ups by category group, plus the total row */
  local!groups: {{
    {group_row("Land")},
    {group_row("Soft")},
    {group_row("Hard")}
  }},
  local!totals: a!map(
    group: "Total",
    revised: sum(local!groups.revised),
    adj: sum(local!groups.adj),
    proposed: sum(local!groups.proposed),
    current: sum(local!groups.current)
  ),
  local!summaryRows: if(local!noLines, {{}}, {{local!groups, local!totals}}),
  /* Remaining contingency, from the contingency budget line over the total balance to complete */
  /* guarded: an empty a!forEach result keeps the record list's type, and wherecontains refuses a Boolean against it */
  local!contIdx: if(local!noLines, {{}}, wherecontains(true, a!forEach(items: local!lines, expression: find("contingency", lower(a!defaultValue(fv!item.budgetCategory, ""))) > 0))),
  local!cont: if(a!isNullOrEmpty(local!contIdx), null, index(local!lines, local!contIdx[1], null)),
  local!totalBalance: sum(a!forEach(items: local!lines, expression: a!defaultValue(fv!item.balanceToComplete, 0))),
  local!contRows: if(
    a!isNullOrEmpty(local!cont),
    {{}},
    {{
      a!map(
        label: "Remaining Contingency ($)",
        revised: {money("local!cont.revisedApprovedBudget")},
        adj: {money_dash("local!cont.proposedAdjustmentsThisDraw")},
        proposed: {money("local!cont.balanceToComplete")}
      ),
      a!map(
        label: "Remaining Contingency (%)",
        revised: if(local!totalBalance = 0, "—", text(a!defaultValue(local!cont.revisedApprovedBudget, 0) / local!totalBalance, "0.0%")),
        adj: "—",
        proposed: if(local!totalBalance = 0, "—", text(a!defaultValue(local!cont.balanceToComplete, 0) / local!totalBalance, "0.0%"))
      )
    }}
  ),
  /* Funding history: PTD from the lines, funded to date = PTD less this draw */
  local!ptdTotal: sum(a!forEach(items: local!lines, expression: a!defaultValue(fv!item.totalPtdIncThisDrawAmount, 0))),
  local!proposedTotal: local!totals.proposed,
  local!fundedToDate: local!ptdTotal - local!amount,
  local!historyRows: {{
    if(
      local!found,
      a!map(
        drawNumber: index(local!d, "drawNumber", null),
        fundingDate: index(local!d, "fundingDate", null),
        amount: local!amount,
        drawType: index(local!d, "drawType", null),
        purpose: if(tostring(a!defaultValue(index(local!d, "status", ""), "")) = "In Progress", "This draw — in approval", "This draw"),
        isThis: true
      ),
      {{}}
    ),
    a!forEach(
      items: local!history,
      expression: a!map(
        drawNumber: fv!item.drawNumber,
        fundingDate: fv!item.fundingDate,
        amount: fv!item.amount,
        drawType: fv!item.drawType,
        purpose: fv!item.purpose,
        isThis: false
      )
    )
  }},
  /* Approval progress */
  local!approvals: a!defaultValue(index(local!d, "approvals", {{}}), {{}}),
  local!approvedCount: a!defaultValue(index(local!d, "approvedCount", 0), 0),
  local!totalSteps: a!defaultValue(index(local!d, "totalSteps", 0), 0),
  local!currentStep: index(local!d, "currentStep", null),
  local!started: a!localVariables(
    local!first: if(a!isNullOrEmpty(local!approvals), null, index(index(local!approvals, 1, null), "activatedAt", null)),
    if(a!isNullOrEmpty(local!first), index(local!d, "createdAt", null), local!first)
  ),
  local!approvedRows: if(
    a!isNullOrEmpty(local!approvals),
    {{}},
    index(
      local!approvals,
      wherecontains("Approved", a!forEach(items: local!approvals, expression: tostring(a!defaultValue(fv!item.status, "")))),
      {{}}
    )
  ),
  local!approvedLine: if(
    a!isNullOrEmpty(local!approvedRows),
    "",
    joinarray(
      a!forEach(
        items: local!approvedRows,
        expression: fv!item.role & " ✓ " & if(a!isNullOrEmpty(fv!item.decisionDate), "", text(todate(fv!item.decisionDate), "MM/DD"))
      ),
      " · "
    )
  ),
  local!qiuAsOf: if(a!isNullOrEmpty(local!qiu), null, index(index(local!qiu, 1, null), "modelAsOfDate", null)),
  local!sourceDoc: a!localVariables(
    local!idx: if(a!isNullOrEmpty(local!docs), {{}}, wherecontains("Budget Template", a!forEach(items: local!docs, expression: tostring(a!defaultValue(fv!item.documentType, ""))))),
    if(a!isNullOrEmpty(local!idx), if(a!isNullOrEmpty(local!docs), null, index(local!docs, 1, null)), index(local!docs, local!idx[1], null))
  ),
  /* Phase 5: a draw whose budget template failed the ingestion checks. The state card below takes the action strip's
     slot; the sections that describe a loaded draw (progress, funding detail, budget, history, QIU) are hidden. */
  local!failed: a!defaultValue(index(local!d, "ingestionFailed", false), false),
  local!reason: if(local!failed, rule!SD_splitIngestionText(text: index(local!d, "ingestionFailureReason", "")), null),
  local!comparison: if(local!failed, rule!SD_splitIngestionText(text: index(local!d, "ingestionComparison", "")), null),
  {{
    a!richTextDisplayField(
      labelPosition: "COLLAPSED",
      value: a!richTextItem(text: "Draw not found.", color: "NEGATIVE"),
      showWhen: not(local!found)
    ),
    rule!SD_cmp_drawFactStrip(detail: local!d),
    /* Action strip: only the current step's assignee group sees it, and only while a task is open; the button opens that task */
    a!cardLayout(
      contents: {{
        a!columnsLayout(
          columns: {{
            a!columnLayout(
              contents: a!richTextDisplayField(
                labelPosition: "COLLAPSED",
                value: {{
                  a!richTextItem(
                    text: if(
                      a!defaultValue(index(local!d, "ingesting", false), false),
                      "Doc Center extraction is ready for your reconciliation — confirm the header and budget lines to assemble the draw",
                      "Your approval is pending — " & a!defaultValue(index(local!d, "currentRole", ""), "") & ", step " & a!defaultValue(local!currentStep, "?") & " of " & local!totalSteps
                    ),
                    style: "STRONG",
                    color: "#16294D"
                  ),
                  char(10),
                  a!richTextItem(
                    text: {{
                      if(a!defaultValue(index(local!d, "ingesting", false), false), "Received ", "With you since ") & if(a!isNullOrEmpty(index(local!d, "currentActivatedAt", null)), "—", text(todate(index(local!d, "currentActivatedAt", null)), "MMM D")),
                      if(a!isNullOrEmpty(index(local!d, "daysToFunding", null)), "", " · funds scheduled " & rule!SD_fmtRelativeDays(days: index(local!d, "daysToFunding", null)))
                    }},
                    color: "#6B7280",
                    size: "SMALL"
                  )
                }},
                marginBelow: "NONE"
              ),
              width: "AUTO"
            ),
            a!columnLayout(
              contents: {{
                a!cardLayout(
                  contents: a!richTextDisplayField(
                    labelPosition: "COLLAPSED",
                    value: a!richTextItem(text: if(a!defaultValue(index(local!d, "ingesting", false), false), "Reconcile Extraction", "Review & Approve"), color: "#FFFFFF", style: "STRONG"),
                    align: "CENTER",
                    marginBelow: "NONE"
                  ),
                  link: a!processTaskLink(task: index(local!d, "openTaskId", null)),
                  showWhen: not(a!isNullOrEmpty(index(local!d, "openTaskId", null))),
                  style: "#1D5BBF",
                  shape: "SEMI_ROUNDED",
                  padding: "LESS",
                  showBorder: false,
                  showShadow: false,
                  marginBelow: "NONE"
                ),
                a!richTextDisplayField(
                  labelPosition: "COLLAPSED",
                  value: a!richTextItem(text: "Task not yet issued", color: "#6B7280", size: "SMALL"),
                  align: "RIGHT",
                  showWhen: a!isNullOrEmpty(index(local!d, "openTaskId", null)),
                  marginBelow: "NONE"
                )
              }},
              width: "NARROW_PLUS"
            )
          }},
          alignVertical: "MIDDLE",
          stackWhen: {{"PHONE"}},
          marginBelow: "NONE"
        )
      }},
      showWhen: and(local!found, a!defaultValue(index(local!d, "awaitingViewer", false), false)),
      style: "#E8F0FC",
      decorativeBarPosition: "START",
      decorativeBarColor: "#1D5BBF",
      shape: "SEMI_ROUNDED",
      padding: "STANDARD",
      showBorder: false,
      showShadow: false,
      marginBelow: "STANDARD"
    ),
    /* Ingestion failed: plain state card, red, in the action strip's slot. No task, no action — resubmission happens
       on the Receive Capital Call page. */
    a!cardLayout(
      contents: {{
        a!richTextDisplayField(
          labelPosition: "COLLAPSED",
          value: {{
            a!richTextIcon(icon: "exclamation-circle", color: "#B42318"),
            " ",
            a!richTextItem(text: "Ingestion failed — this budget template could not be loaded", size: "MEDIUM", style: "STRONG", color: "#B42318"),
            char(10),
            a!richTextItem(
              text: "Received " & if(a!isNullOrEmpty(index(local!d, "receivedDate", null)), "—", text(index(local!d, "receivedDate", null), "MMMM D, YYYY"))
                & if(a!isNullOrEmpty(local!sourceDoc), "", " · " & a!defaultValue(local!sourceDoc.documentName, ""))
                & " · nothing was loaded and no reconciliation task was created",
              color: "#6B7280",
              size: "SMALL"
            )
          }},
          marginBelow: "STANDARD"
        ),
        a!richTextDisplayField(
          labelPosition: "COLLAPSED",
          value: {{
            a!richTextItem(text: "WHY IT COULD NOT BE LOADED", color: "#6B7280", size: "SMALL", style: "STRONG"),
            char(10),
            a!richTextItem(text: a!defaultValue(index(local!reason, "lead", ""), "No reason was recorded."), color: "#1F2937"),
            a!richTextBulletedList(items: index(local!reason, "bullets", {{}})),
            a!richTextItem(text: index(local!reason, "tail", ""), color: "#1F2937")
          }},
          marginBelow: "STANDARD"
        ),
        a!richTextDisplayField(
          labelPosition: "COLLAPSED",
          value: {{
            a!richTextItem(text: "WHAT CHANGED SINCE THE LAST TEMPLATE THAT LOADED", color: "#6B7280", size: "SMALL", style: "STRONG"),
            char(10),
            a!richTextItem(text: a!defaultValue(index(local!comparison, "lead", ""), "No comparison was recorded for this file."), color: "#1F2937"),
            a!richTextBulletedList(items: index(local!comparison, "bullets", {{}})),
            a!richTextItem(text: index(local!comparison, "tail", ""), color: "#6B7280", size: "SMALL", style: "EMPHASIS")
          }},
          marginBelow: "STANDARD"
        ),
        a!richTextDisplayField(
          labelPosition: "COLLAPSED",
          value: {{
            a!richTextItem(text: "WHAT HAPPENS NEXT", color: "#6B7280", size: "SMALL", style: "STRONG"),
            char(10),
            "Correct the workbook and resubmit it through ",
            a!richTextItem(
              text: "Receive Capital Call",
              link: a!safeLink(
                uri: a!urlForSite(sitePage: 'site!{{ffae752f-b3d1-44d5-a9ba-c408b66bdb65}}SASite.pages.{{cec364e7-214a-43ee-bdf5-22aeb0979522}}receive-capital-call'),
                openLinkIn: "SAME_TAB"
              ),
              linkStyle: "INLINE"
            ),
            ". This draw stays on the Draws list as Ingestion Failed, as a record of what was received; it will not be approved or funded."
          }},
          marginBelow: "NONE"
        )
      }},
      showWhen: and(local!found, local!failed),
      style: "#FDECEC",
      decorativeBarPosition: "START",
      decorativeBarColor: "#B42318",
      shape: "SEMI_ROUNDED",
      padding: "STANDARD",
      showBorder: false,
      showShadow: false,
      marginBelow: "STANDARD"
    ),
    /* Approval progress */
    {card_open()}
      a!columnsLayout(
        columns: {{
          a!columnLayout(
            contents: a!richTextDisplayField(
              labelPosition: "COLLAPSED",
              value: {{
                a!richTextItem(
                  text: if(
                    tostring(a!defaultValue(index(local!d, "status", ""), "")) = "In Progress",
                    "Step " & a!defaultValue(local!currentStep, "?") & " of " & local!totalSteps & " · " & a!defaultValue(index(local!d, "currentRole", ""), "") & " · " & a!defaultValue(index(local!d, "currentApprover", ""), ""),
                    tostring(a!defaultValue(index(local!d, "status", ""), ""))
                  ),
                  size: "MEDIUM",
                  style: "STRONG",
                  color: "#16294D"
                ),
                char(10),
                a!richTextItem(
                  text: local!approvedCount & " of " & local!totalSteps & " approved · started " & if(a!isNullOrEmpty(local!started), "—", text(todate(local!started), "MM/DD")),
                  color: "#6B7280",
                  size: "SMALL"
                )
              }},
              marginBelow: "LESS"
            ),
            width: "AUTO"
          ),
          a!columnLayout(
            contents: a!richTextDisplayField(
              labelPosition: "COLLAPSED",
              value: a!richTextItem(
                text: if(
                  a!isNullOrEmpty(index(local!d, "daysAtStep", null)),
                  "",
                  "At this step " & if(index(local!d, "daysAtStep", 0) = 0, "since today", index(local!d, "daysAtStep", 0) & if(index(local!d, "daysAtStep", 0) = 1, " day", " days"))
                ),
                color: "#6B7280",
                size: "SMALL"
              ),
              align: "RIGHT",
              showWhen: tostring(a!defaultValue(index(local!d, "status", ""), "")) = "In Progress",
              marginBelow: "LESS"
            ),
            width: "NARROW_PLUS"
          )
        }},
        alignVertical: "MIDDLE",
        marginBelow: "NONE"
      ),
      a!progressBarField(
        labelPosition: "COLLAPSED",
        percentage: if(local!totalSteps = 0, 0, tointeger(round(100 * local!approvedCount / local!totalSteps, 0))),
        color: "POSITIVE",
        style: "THIN",
        showPercentage: false,
        marginBelow: "LESS"
      ),
      a!richTextDisplayField(
        labelPosition: "COLLAPSED",
        value: a!forEach(
          items: local!approvals,
          expression: {{
            a!richTextIcon(
              icon: a!match(
                value: tostring(a!defaultValue(fv!item.status, "")),
                equals: "Approved", then: "check-circle",
                equals: "In Progress", then: "dot-circle-o",
                equals: "Rejected", then: "times-circle",
                default: "circle-o"
              ),
              color: a!match(
                value: tostring(a!defaultValue(fv!item.status, "")),
                equals: "Approved", then: "#1E7E46",
                equals: "In Progress", then: "#1D5BBF",
                equals: "Rejected", then: "#B42318",
                default: "#9CA3AF"
              ),
              altText: fv!item.role & " " & tostring(a!defaultValue(fv!item.status, ""))
            ),
            " "
          }}
        ),
        marginBelow: "LESS"
      ),
      a!sideBySideLayout(
        items: {{
          a!sideBySideItem(
            item: a!richTextDisplayField(
              labelPosition: "COLLAPSED",
              value: a!richTextItem(text: if(local!approvedLine = "", "No approvals recorded yet", local!approvedLine), color: "#6B7280", size: "SMALL"),
              marginBelow: "NONE"
            ),
            width: "AUTO"
          ),
          a!sideBySideItem(
            item: a!richTextDisplayField(
              labelPosition: "COLLAPSED",
              value: a!richTextItem(
                text: "Full approval detail",
                /* the Approvals view's url stub, read back from listRecordTypeViews after the view was added */
                link: a!recordLink(recordType: {rt(DRAW)}, identifier: ri!drawId, dashboard: "_HP07OQ"),
                linkStyle: "STANDALONE",
                size: "SMALL"
              ),
              align: "RIGHT",
              marginBelow: "NONE"
            ),
            width: "MINIMIZE"
          )
        }},
        alignVertical: "MIDDLE",
        marginBelow: "NONE"
      )
    {card_close_hide},
    /* Draw Origin */
    {card_open()}
      {heading('"Draw Origin"', '"Capital call request received via EY data feed · budget extracted by Doc Center"')},
      a!columnsLayout(
        columns: {{
          a!columnLayout(
            contents: {{
              rule!SD_cmp_labelValue(label: "Received", value: if(a!isNullOrEmpty(index(local!d, "receivedDate", null)), null, text(index(local!d, "receivedDate", null), "MMMM D, YYYY"))),
              rule!SD_cmp_labelValue(label: "Submitted By", value: index(local!d, "submittedBy", null), marginBelow: "NONE")
            }},
            width: "AUTO"
          ),
          a!columnLayout(
            contents: {{
              a!richTextDisplayField(
                labelPosition: "COLLAPSED",
                value: {{
                  a!richTextItem(text: "SOURCE DOCUMENT", color: "#6B7280", size: "SMALL"),
                  char(10),
                  if(
                    a!isNullOrEmpty(local!sourceDoc),
                    a!richTextItem(text: "—", color: "#16294D"),
                    {{
                      a!richTextIcon(icon: "file-excel-o", color: "#1E7E46"),
                      " ",
                      if(
                        a!isNullOrEmpty(local!sourceDoc.document),
                        a!richTextItem(text: a!defaultValue(local!sourceDoc.documentName, "—"), color: "#16294D"),
                        a!richTextItem(
                          text: a!defaultValue(local!sourceDoc.documentName, "document"),
                          link: a!documentDownloadLink(document: local!sourceDoc.document),
                          linkStyle: "STANDALONE"
                        )
                      )
                    }}
                  )
                }},
                marginBelow: "STANDARD"
              ),
              a!richTextDisplayField(
                labelPosition: "COLLAPSED",
                value: a!richTextItem(text: "INGESTION", color: "#6B7280", size: "SMALL"),
                marginBelow: "EVEN_LESS"
              ),
              a!sideBySideLayout(
                items: {{
                  a!sideBySideItem(
                    item: rule!SD_cmp_statusTag(status: if(a!isNullOrEmpty(local!sourceDoc), "", a!defaultValue(local!sourceDoc.status, ""))),
                    width: "MINIMIZE"
                  ),
                  a!sideBySideItem(
                    item: a!richTextDisplayField(
                      labelPosition: "COLLAPSED",
                      value: a!richTextItem(text: if(a!isNullOrEmpty(local!sourceDoc), "", a!defaultValue(local!sourceDoc.notes, "")), color: "#6B7280", size: "SMALL"),
                      marginBelow: "NONE"
                    ),
                    width: "AUTO"
                  )
                }},
                alignVertical: "MIDDLE",
                spacing: "DENSE",
                marginBelow: "NONE"
              )
            }},
            width: "AUTO"
          ),
          a!columnLayout(
            contents: {{
              a!richTextDisplayField(
                labelPosition: "COLLAPSED",
                value: a!richTextItem(text: "AMOUNT VERIFICATION", color: "#6B7280", size: "SMALL"),
                marginBelow: "EVEN_LESS"
              ),
              a!sideBySideLayout(
                items: {{
                  a!sideBySideItem(
                    item: a!tagField(
                      labelPosition: "COLLAPSED",
                      tags: a!tagItem(
                        text: if(local!noLines, "No budget lines", if(local!ties, "Ties ✓", "Does not tie")),
                        backgroundColor: if(local!noLines, "#EEF1F5", if(local!ties, "#E6F4EC", "#FDECEC")),
                        textColor: if(local!noLines, "#64748B", if(local!ties, "#1E7E46", "#B42318"))
                      ),
                      size: "SMALL"
                    ),
                    width: "MINIMIZE"
                  ),
                  a!sideBySideItem(
                    item: a!richTextDisplayField(
                      labelPosition: "COLLAPSED",
                      value: a!richTextItem(
                        text: if(
                          local!noLines,
                          "budget detail not yet extracted for this draw",
                          "current draw lines sum to " & rule!SD_fmtMoney(value: local!linesSum, showCents: true) & if(local!ties, "", " against " & rule!SD_fmtMoney(value: local!amount, showCents: true))
                        ),
                        color: "#6B7280",
                        size: "SMALL"
                      ),
                      marginBelow: "NONE"
                    ),
                    width: "AUTO"
                  )
                }},
                alignVertical: "MIDDLE",
                spacing: "DENSE",
                marginBelow: "NONE"
              )
            }},
            width: "AUTO"
          )
        }},
        stackWhen: {{"PHONE", "TABLET_PORTRAIT"}},
        marginBelow: "NONE"
      )
    {card_close},
    /* Draw Funding Detail */
    {card_open()}
      {heading('"Draw Funding Detail"', '"Header fields from the capital call request · investment profile from DealCloud"')},
      a!columnsLayout(
        columns: {{
          a!columnLayout(
            contents: {{
              rule!SD_cmp_labelValue(label: "Cash/Equity Needed from the Fund?", value: if(a!isNullOrEmpty(index(local!d, "cashEquityNeeded", null)), null, if(index(local!d, "cashEquityNeeded", false), "Yes", "No"))),
              rule!SD_cmp_labelValue(label: "Investment Description", value: index(local!d, "investmentDescription", null)),
              rule!SD_cmp_labelValue(label: "Budget and Contingency Explanation", value: index(local!d, "contingencyExplanation", null)),
              rule!SD_cmp_labelValue(label: "General Comments", value: index(local!d, "generalComments", null), marginBelow: "NONE")
            }},
            width: "AUTO"
          ),
          a!columnLayout(
            contents: {{
              rule!SD_cmp_labelValue(label: "On / Under / Over Budget", value: index(local!d, "budgetStatus", null)),
              rule!SD_cmp_labelValue(label: "Purpose", value: index(local!d, "purpose", null)),
              rule!SD_cmp_labelValue(label: "Over Budget Reason", value: index(local!d, "overBudgetReason", null), marginBelow: "NONE")
            }},
            width: "AUTO"
          )
        }},
        stackWhen: {{"PHONE"}},
        marginBelow: "NONE"
      )
    {card_close_hide},
    /* Budget Summary and Remaining Contingency, side by side */
    a!columnsLayout(
      columns: {{
        a!columnLayout(
          contents: {card_open()}
            {heading('"Budget Summary"', '"Roll-up of budget detail by category group"')},
            a!gridField(
              labelPosition: "COLLAPSED",
              data: local!summaryRows,
              columns: {{
                a!gridColumn(label: "Category Group", value: a!richTextDisplayField(value: a!richTextItem(text: fv!row.group, style: if(fv!row.group = "Total", "STRONG", "PLAIN"))), width: "NARROW_PLUS"),
                a!gridColumn(label: "Revised Approved", value: a!richTextDisplayField(value: a!richTextItem(text: {money("fv!row.revised")}, style: if(fv!row.group = "Total", "STRONG", "PLAIN"))), align: "END"),
                a!gridColumn(label: "Adjustments This Draw", value: a!richTextDisplayField(value: a!richTextItem(text: {money_dash("fv!row.adj")}, style: if(fv!row.group = "Total", "STRONG", "PLAIN"))), align: "END"),
                a!gridColumn(label: "Proposed Budget", value: a!richTextDisplayField(value: a!richTextItem(text: {money("fv!row.proposed")}, style: if(fv!row.group = "Total", "STRONG", "PLAIN"))), align: "END"),
                a!gridColumn(label: "Current Draw", value: a!richTextDisplayField(value: a!richTextItem(text: {money_dash("fv!row.current")}, style: if(fv!row.group = "Total", "STRONG", "PLAIN"))), align: "END")
              }},
              pageSize: 4,
              spacing: "DENSE",
              borderStyle: "LIGHT",
              rowHeader: 1,
              emptyGridMessage: "No budget lines on this draw"
            ),
            rule!SD_cmp_sourceLine(text: "Land: site & acquisition. Hard: construction & FF&E. Soft: fees, taxes, insurance, financing, marketing, contingency.")
          {card_close},
          width: "AUTO"
        ),
        a!columnLayout(
          contents: {card_open()}
            {heading('"Remaining Contingency"', '"From the All Project Contingency budget line"')},
            a!gridField(
              labelPosition: "COLLAPSED",
              data: local!contRows,
              columns: {{
                a!gridColumn(label: "", value: fv!row.label, width: "NARROW_PLUS"),
                a!gridColumn(label: "Revised Approved", value: fv!row.revised, align: "END"),
                a!gridColumn(label: "Adjustments This Draw", value: fv!row.adj, align: "END"),
                a!gridColumn(label: "Proposed", value: fv!row.proposed, align: "END")
              }},
              pageSize: 2,
              spacing: "DENSE",
              borderStyle: "LIGHT",
              rowHeader: 1,
              emptyGridMessage: "No contingency line on this draw"
            ),
            rule!SD_cmp_sourceLine(text: "Percent is contingency over total balance to complete (" & rule!SD_fmtMoney(value: local!totalBalance, showCents: false) & "). Utilization this draw covered by the explanation above.")
          {card_close},
          width: "MEDIUM_PLUS"
        )
      }},
      stackWhen: {{"PHONE", "TABLET_PORTRAIT"}},
      showWhen: not(local!failed),
      marginBelow: "NONE"
    ),
    /* Funding History */
    {card_open()}
      {heading('"Funding History"', '"Prior approved draws on this investment"')},
      a!richTextDisplayField(
        labelPosition: "COLLAPSED",
        value: a!richTextItem(text: "Funded to date is computed from the budget detail, which has not been extracted for this draw yet.", color: "#6B7280"),
        showWhen: local!noLines,
        marginBelow: "STANDARD"
      ),
      a!richTextDisplayField(
        labelPosition: "COLLAPSED",
        showWhen: not(local!noLines),
        value: {{
          a!richTextItem(text: "Funded to date: ", color: "#6B7280"),
          a!richTextItem(text: rule!SD_fmtMoney(value: local!fundedToDate, showCents: false), style: "STRONG", color: "#16294D"),
          a!richTextItem(text: " of " & rule!SD_fmtMoney(value: local!proposedTotal, showCents: false) & " proposed budget (", color: "#6B7280"),
          a!richTextItem(text: if(local!proposedTotal = 0, "—", text(local!fundedToDate / local!proposedTotal, "0.0%")), style: "STRONG", color: "#16294D"),
          a!richTextItem(text: ")", color: "#6B7280"),
          char(10),
          a!richTextItem(text: "This draw brings PTD to " & if(local!proposedTotal = 0, "—", text(local!ptdTotal / local!proposedTotal, "0.0%")), color: "#1D5BBF", size: "SMALL")
        }},
        marginBelow: "STANDARD"
      ),
      a!gridField(
        labelPosition: "COLLAPSED",
        data: local!historyRows,
        columns: {{
          a!gridColumn(label: "Draw", value: a!richTextDisplayField(value: a!richTextItem(text: "#" & fv!row.drawNumber, style: if(fv!row.isThis, "STRONG", "PLAIN"), color: if(fv!row.isThis, "#1D5BBF", "#16294D"))), width: "NARROW"),
          a!gridColumn(label: "Funded", value: if(a!isNullOrEmpty(fv!row.fundingDate), "—", text(fv!row.fundingDate, "MM/DD/YYYY")), width: "NARROW_PLUS"),
          a!gridColumn(label: "Amount", value: {money("fv!row.amount")}, align: "END", width: "NARROW_PLUS"),
          a!gridColumn(label: "Type", value: a!defaultValue(fv!row.drawType, "—"), width: "NARROW_PLUS"),
          a!gridColumn(label: "Purpose", value: a!defaultValue(fv!row.purpose, "—"))
        }},
        pageSize: 4,
        spacing: "DENSE",
        borderStyle: "LIGHT",
        rowHeader: 1,
        emptyGridMessage: "No prior draws on this investment"
      ),
      rule!SD_cmp_sourceLine(text: "Showing the last 3 funded draws. Full history on the investment record.")
    {card_close_hide},
    /* QIU Detail */
    {card_open()}
      {heading('"QIU Detail — " & a!defaultValue(index(local!d, "investmentName", ""), "")', '"Aggregated from the QIU model for this investment" & if(a!isNullOrEmpty(local!qiuAsOf), "", " · model as of " & text(local!qiuAsOf, "MM/DD/YYYY"))')},
      a!gridField(
        labelPosition: "COLLAPSED",
        data: local!qiu,
        columns: {{
          a!gridColumn(label: "Metric", value: fv!row.metric, width: "MEDIUM_PLUS"),
          a!gridColumn(label: "Current QIU Model" & if(a!isNullOrEmpty(local!qiuAsOf), "", " (" & text(local!qiuAsOf, "MM/DD/YYYY") & ")"), value: a!defaultValue(fv!row.currentModelValue, "—"), align: "END"),
          a!gridColumn(label: "Current Projection", value: a!defaultValue(fv!row.currentProjection, "—"), align: "END"),
          a!gridColumn(label: "Variance of Current Projection", value: a!defaultValue(fv!row.variance, "—"), align: "END"),
          a!gridColumn(label: "Notes", value: if(a!isNullOrEmpty(fv!row.notes), "—", fv!row.notes))
        }},
        pageSize: 12,
        spacing: "DENSE",
        borderStyle: "LIGHT",
        rowHeader: 1,
        emptyGridMessage: "No QIU metrics on this draw"
      )
    {card_close_hide}
  }}
)
"""
open("SD_view_drawSummary.sail","w").write(sail)
print("written", len(sail))

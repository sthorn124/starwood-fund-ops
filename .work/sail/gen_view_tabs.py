from refs import *
L = lambda n: fld(LINE, n)
A = lambda n: fld(APPR, n)
Dc = lambda n: fld(DOC, n)

def query(rt_, fields, filters, sortf, batch=100):
    return f"""a!queryRecordType(
      recordType: {rt(rt_)},
      fields: {{
        {", ".join(fld(rt_, f) for f in fields)}
      }},
      filters: {filters},
      pagingInfo: a!pagingInfo(startIndex: 1, batchSize: {batch}, sort: a!sortInfo(field: {fld(rt_, sortf)}, ascending: true))
    ).data"""
def tomaps(rt_, fields):
    return "a!forEach(items: local!raw, expression: a!map(" + ", ".join(f"{f}: fv!item[{fld(rt_, f)}]" for f in fields) + "))"

card_close = '''},
    style: "NONE",
    shape: "SEMI_ROUNDED",
    padding: "STANDARD",
    showBorder: true,
    showShadow: false,
    marginBelow: "STANDARD"
  )'''
def heading(text_expr, src_expr):
    return f'''a!richTextDisplayField(
        labelPosition: "COLLAPSED",
        value: a!richTextItem(text: {text_expr}, size: "MEDIUM", style: "STRONG", color: "#16294D"),
        marginBelow: "EVEN_LESS"
      ),
      rule!SD_cmp_sourceLine(text: {src_expr})'''

money = lambda e: f"rule!SD_fmtMoney(value: {e}, showCents: false)"
money_dash = lambda e: f"if(a!defaultValue({e}, 0) = 0, \"—\", {money(e)})"

# ---------- Budget Detail ----------
line_fields = ["id","lineOrder","budgetCategory","categoryGroup","inThisDraw","initialBudget","revisedApprovedBudget",
               "proposedAdjustmentsThisDraw","proposedBudget","currentDraw","totalPtdIncThisDrawAmount","totalPtdIncThisDrawPct","balanceToComplete"]
def cell(expr, kind_bold="fv!row.kind = \"total\""):
    return f'a!richTextDisplayField(value: a!richTextItem(text: if(fv!row.kind = "section", "", {expr}), style: if({kind_bold}, "STRONG", "PLAIN")))'
budget = f"""/* Draw approval: the Budget Detail view of a draw record (mockups/draw-summary.html, Budget Detail tab).
   One table, categories funded by this draw first ("In this Draw"), then "All Other Budget Categories", then a
   BUDGET total row computed from the lines. Percent PTD on the total row is PTD over proposed budget. */
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
  /* guarded: an empty a!forEach result keeps the record list's type, and wherecontains refuses a Boolean against it */
  local!flags: a!forEach(items: local!lines, expression: a!defaultValue(fv!item.inThisDraw, false)),
  local!inDraw: if(a!isNullOrEmpty(local!lines), {{}}, a!forEach(items: index(local!lines, wherecontains(true, local!flags), {{}}), expression: a!update(fv!item, "kind", "line"))),
  local!others: if(a!isNullOrEmpty(local!lines), {{}}, a!forEach(items: index(local!lines, wherecontains(false, local!flags), {{}}), expression: a!update(fv!item, "kind", "line"))),
  local!sum: a!localVariables(
    local!proposed: sum(a!forEach(items: local!lines, expression: a!defaultValue(fv!item.proposedBudget, 0))),
    local!ptd: sum(a!forEach(items: local!lines, expression: a!defaultValue(fv!item.totalPtdIncThisDrawAmount, 0))),
    a!map(
      kind: "total",
      budgetCategory: "BUDGET",
      initialBudget: sum(a!forEach(items: local!lines, expression: a!defaultValue(fv!item.initialBudget, 0))),
      revisedApprovedBudget: sum(a!forEach(items: local!lines, expression: a!defaultValue(fv!item.revisedApprovedBudget, 0))),
      proposedAdjustmentsThisDraw: sum(a!forEach(items: local!lines, expression: a!defaultValue(fv!item.proposedAdjustmentsThisDraw, 0))),
      proposedBudget: local!proposed,
      currentDraw: sum(a!forEach(items: local!lines, expression: a!defaultValue(fv!item.currentDraw, 0))),
      totalPtdIncThisDrawAmount: local!ptd,
      totalPtdIncThisDrawPct: if(local!proposed = 0, null, 100 * local!ptd / local!proposed),
      balanceToComplete: sum(a!forEach(items: local!lines, expression: a!defaultValue(fv!item.balanceToComplete, 0)))
    )
  ),
  local!rows: if(
    a!isNullOrEmpty(local!lines),
    {{}},
    {{
      if(a!isNullOrEmpty(local!inDraw), {{}}, a!map(kind: "section", budgetCategory: "In this Draw")),
      local!inDraw,
      if(a!isNullOrEmpty(local!others), {{}}, a!map(kind: "section", budgetCategory: "All Other Budget Categories")),
      local!others,
      local!sum
    }}
  ),
  local!sourceDoc: a!localVariables(
    local!raw: if(
      not(local!found),
      {{}},
      {query(DOC, ["id","documentName","documentType","status","notes"], f'a!queryFilter(field: {Dc("drawId")}, operator: "=", value: ri!drawId)', "id")}
    ),
    local!maps: {tomaps(DOC, ["id","documentName","documentType","status","notes"])},
    local!idx: if(a!isNullOrEmpty(local!maps), {{}}, wherecontains("Budget Template", a!forEach(items: local!maps, expression: tostring(a!defaultValue(fv!item.documentType, ""))))),
    if(a!isNullOrEmpty(local!idx), null, index(local!maps, local!idx[1], null))
  ),
  {{
    a!richTextDisplayField(labelPosition: "COLLAPSED", value: a!richTextItem(text: "Draw not found.", color: "NEGATIVE"), showWhen: not(local!found)),
    rule!SD_cmp_drawFactStrip(detail: local!d),
    a!cardLayout(
    contents: {{
      {heading('"Draw Detail by Budget Category"', '''if(
        a!isNullOrEmpty(local!sourceDoc),
        "Budget lines for Draw #" & a!defaultValue(index(local!d, "drawNumber", ""), ""),
        "Extracted from " & a!defaultValue(local!sourceDoc.documentName, "the budget template") & " via Doc Center" & if(a!isNullOrEmpty(local!sourceDoc.notes), "", " · " & local!sourceDoc.notes)
      )''')},
      a!gridField(
        labelPosition: "COLLAPSED",
        data: local!rows,
        columns: {{
          a!gridColumn(
            label: "Budget Category",
            value: a!richTextDisplayField(
              value: a!richTextItem(
                text: fv!row.budgetCategory,
                style: if(or(fv!row.kind = "section", fv!row.kind = "total"), "STRONG", "PLAIN"),
                color: if(fv!row.kind = "section", "#6B7280", "#16294D"),
                size: if(fv!row.kind = "section", "SMALL", "STANDARD")
              )
            ),
            width: "MEDIUM_PLUS"
          ),
          a!gridColumn(label: "Initial Budget", value: {cell(money_dash("fv!row.initialBudget"))}, align: "END"),
          a!gridColumn(label: "Revised Approved Budget", value: {cell(money("fv!row.revisedApprovedBudget"))}, align: "END"),
          a!gridColumn(label: "Proposed Adjustments This Draw", value: {cell(money_dash("fv!row.proposedAdjustmentsThisDraw"))}, align: "END"),
          a!gridColumn(label: "Proposed Budget", value: {cell(money("fv!row.proposedBudget"))}, align: "END"),
          a!gridColumn(label: "Current Draw", value: {cell(money_dash("fv!row.currentDraw"))}, align: "END"),
          a!gridColumn(label: "Total PTD inc. This Draw ($)", value: {cell(money_dash("fv!row.totalPtdIncThisDrawAmount"))}, align: "END"),
          a!gridColumn(label: "Total PTD inc. This Draw (%)", value: {cell('if(a!defaultValue(fv!row.totalPtdIncThisDrawAmount, 0) = 0, "—", text(a!defaultValue(fv!row.totalPtdIncThisDrawPct, 0), "0.0") & "%")')}, align: "END"),
          a!gridColumn(label: "Balance To Complete", value: {cell(money_dash("fv!row.balanceToComplete"))}, align: "END")
        }},
        pageSize: 60,
        spacing: "DENSE",
        borderStyle: "LIGHT",
        rowHeader: 1,
        emptyGridMessage: "No budget lines on this draw"
      ),
      rule!SD_cmp_sourceLine(
        text: "Categories funded by Draw #" & a!defaultValue(index(local!d, "drawNumber", ""), "") & " listed first, per the approval email layout. Net proposed adjustments this draw are " & rule!SD_fmtMoney(value: local!sum.proposedAdjustmentsThisDraw, showCents: false) & ". The total row is computed from the category lines."
      )
    {card_close}
  }}
)
"""
open("SD_view_drawBudgetDetail.sail","w").write(budget)

# ---------- Approvals: the email exchange (Phase 6a) ----------
# Every approval email, reply and response on the draw (SD Draw Email Message via SD_getDrawEmailMessages), oldest
# first. Widths (docs 26.6, a!gridColumn): fixed columns keep their width and AUTO takes what they leave, so the
# message text gets the AUTO column. Outcome tags are 40 characters or fewer (a tag displays at most 40).
email_card = """    a!cardLayout(
    contents: {
      a!richTextDisplayField(
        labelPosition: "COLLAPSED",
        value: a!richTextItem(text: "Email Exchange", size: "MEDIUM", style: "STRONG", color: "#16294D"),
        marginBelow: "EVEN_LESS"
      ),
      rule!SD_cmp_sourceLine(text: "Every approval email, reply and response on this draw, oldest first · a reply is read by one AI call, checked by fixed rules, and applied only from an authorized sender at the step awaiting a decision · draws above " & rule!SD_fmtMoney(value: cons!SD_EMAIL_APPROVAL_MAX, showCents: false) & " are decided in the system, not by email"),
      a!gridField(
        labelPosition: "COLLAPSED",
        data: local!emails,
        columns: {
          a!gridColumn(
            label: "When",
            value: a!richTextDisplayField(
              value: if(
                a!isNullOrEmpty(fv!row.messageAt),
                a!richTextItem(text: "—"),
                {
                  a!richTextItem(text: text(fv!row.messageAt, "MM/DD/YYYY")),
                  char(10),
                  a!richTextItem(text: text(fv!row.messageAt, "h:mm a"), color: "#6B7280", size: "SMALL")
                }
              )
            ),
            width: "NARROW_PLUS"
          ),
          a!gridColumn(
            label: "Message",
            value: a!localVariables(
              local!k: fv!row.kind,
              local!dir: a!match(value: fv!row.direction, equals: "INBOUND", then: "Inbound", equals: "OUTBOUND", then: "Outbound", equals: "INTERNAL", then: "Internal", default: fv!row.direction),
              local!body: trim(a!defaultValue(fv!row.body, "")),
              a!richTextDisplayField(
                value: {
                  a!richTextItem(
                    text: a!match(
                      value: local!k,
                      equals: "STEP_EMAIL", then: "Approval email to " & fv!row.toAddress,
                      equals: "REPLY", then: "Reply from " & fv!row.fromAddress,
                      equals: "CLARIFICATION", then: "Clarification to " & fv!row.toAddress,
                      equals: "GUARDRAIL_REFUSAL", then: "Email approval refused, to " & fv!row.toAddress,
                      equals: "EXCEPTION_REVIEW", then: "Exception reviewed by " & fv!row.fromAddress,
                      default: local!k & " · " & fv!row.fromAddress
                    ),
                    style: "STRONG"
                  ),
                  char(10),
                  a!richTextItem(
                    text: local!dir & " · source " & lower(fv!row.source) & if(a!isNullOrEmpty(fv!row.stepOrder), "", " · step " & fv!row.stepOrder),
                    color: "#6B7280",
                    size: "SMALL"
                  ),
                  char(10),
                  a!richTextItem(
                    text: if(
                      local!body = "",
                      "(no text)",
                      if(len(local!body) > 700, left(local!body, 700) & "…", local!body)
                    ),
                    color: if(local!body = "", "#6B7280", "STANDARD")
                  )
                }
              )
            )
          ),
          a!gridColumn(
            label: "Reading",
            value: a!richTextDisplayField(
              value: {
                if(
                  fv!row.interpretation = "",
                  "",
                  {a!richTextItem(text: fv!row.interpretation, size: "SMALL"), char(10)}
                ),
                a!richTextItem(text: if(fv!row.notes = "", "—", fv!row.notes), color: "#6B7280", size: "SMALL")
              }
            ),
            width: "MEDIUM"
          ),
          a!gridColumn(
            label: "Outcome",
            value: a!localVariables(
              local!o: fv!row.outcome,
              local!tone: a!match(
                value: local!o,
                equals: "APPROVE", then: "G",
                equals: "REJECT", then: "R",
                equals: "SENT", then: "N",
                equals: "RECEIVED", then: "N",
                equals: "REVIEWED", then: "N",
                default: "A"
              ),
              a!tagField(
                labelPosition: "COLLAPSED",
                tags: a!tagItem(
                  text: a!match(
                    value: local!o,
                    equals: "APPROVE", then: "Approved by email",
                    equals: "REJECT", then: "Rejected by email",
                    equals: "AMBIGUOUS", then: "Unclear · clarification sent",
                    equals: "EXCEPTION", then: "Sent to exception queue",
                    equals: "GUARDRAIL", then: "Over the email limit",
                    equals: "UNAUTHORIZED", then: "Sender not authorized",
                    equals: "NOT_AWAITING", then: "Step not awaiting a decision",
                    equals: "UNMATCHED", then: "No draw reference",
                    equals: "SENT", then: "Sent",
                    equals: "RECEIVED", then: "Received",
                    equals: "REVIEWED", then: "Reviewed",
                    default: if(local!o = "", "—", left(local!o, 40))
                  ),
                  backgroundColor: a!match(value: local!tone, equals: "G", then: "#E6F4EC", equals: "R", then: "#FDECEC", equals: "A", then: "#FDF3E0", default: "#EEF1F5"),
                  textColor: a!match(value: local!tone, equals: "G", then: "#1E7E46", equals: "R", then: "#B42318", equals: "A", then: "#92600A", default: "#64748B")
                ),
                size: "SMALL"
              )
            ),
            width: "NARROW_PLUS"
          )
        },
        pageSize: 20,
        spacing: "DENSE",
        borderStyle: "LIGHT",
        emptyGridMessage: "No approval emails on this draw yet"
      )
""" + card_close.replace("{{", "{").replace("}}", "}")

# ---------- Approvals ----------
appr_fields = ["id","approvalOrder","role","approverName","status","activatedAt","decisionDate","comments","actedBy","decisionSource"]
approvals = f"""/* Draw approval: the Approvals view of a draw record (mockups/draw-summary.html, Approvals tab).
   The nine-row chain as data: order, role, approver, status, decision date, time at step (computed), comments.
   The row in progress is highlighted. Time at step: decided rows count whole days from activation to decision
   (at least 1); the open row counts from activation to today.
   Phase 6a: an Email Exchange card below the chain lists every approval email, reply and response on the draw
   (SD Draw Email Message), with its direction, source, the AI reading and the outcome. */
a!localVariables(
  local!d: rule!SD_getDrawDetail(drawId: ri!drawId),
  local!found: a!defaultValue(index(local!d, "found", false), false),
  local!rows: if(
    not(local!found),
    {{}},
    a!localVariables(
      local!raw: {query(APPR, appr_fields, f'a!queryFilter(field: {A("drawId")}, operator: "=", value: ri!drawId)', "approvalOrder")},
      {tomaps(APPR, appr_fields)}
    )
  ),
  local!started: if(a!isNullOrEmpty(local!rows), index(local!d, "createdAt", null), a!defaultValue(index(local!rows, 1, null).activatedAt, index(local!d, "createdAt", null))),
  local!emails: if(local!found, rule!SD_getDrawEmailMessages(drawId: ri!drawId), {{}}),
  {{
    a!richTextDisplayField(labelPosition: "COLLAPSED", value: a!richTextItem(text: "Draw not found.", color: "NEGATIVE"), showWhen: not(local!found)),
    rule!SD_cmp_drawFactStrip(detail: local!d),
    a!cardLayout(
    contents: {{
      {heading('"Approval Detail"', '"Sequential chain of " & count(local!rows) & " · drives routing and the summary progress" & if(a!isNullOrEmpty(local!started), "", " · started " & text(todate(local!started), "MM/DD/YYYY"))')},
      a!gridField(
        labelPosition: "COLLAPSED",
        data: local!rows,
        columns: {{
          a!gridColumn(label: "Order", value: fv!row.approvalOrder, align: "CENTER", width: "ICON_PLUS", backgroundColor: if(tostring(a!defaultValue(fv!row.status, "")) = "In Progress", "#E8F0FC", "NONE")),
          a!gridColumn(label: "Role", value: a!richTextDisplayField(value: a!richTextItem(text: fv!row.role, style: if(tostring(a!defaultValue(fv!row.status, "")) = "In Progress", "STRONG", "PLAIN"))), width: "MEDIUM", backgroundColor: if(tostring(a!defaultValue(fv!row.status, "")) = "In Progress", "#E8F0FC", "NONE")),
          a!gridColumn(label: "Approver", value: a!defaultValue(fv!row.approverName, "—"), width: "MEDIUM", backgroundColor: if(tostring(a!defaultValue(fv!row.status, "")) = "In Progress", "#E8F0FC", "NONE")),
          a!gridColumn(label: "Status", value: rule!SD_cmp_statusTag(status: fv!row.status), width: "NARROW_PLUS", backgroundColor: if(tostring(a!defaultValue(fv!row.status, "")) = "In Progress", "#E8F0FC", "NONE")),
          a!gridColumn(
            label: "Decision On",
            value: a!richTextDisplayField(
              value: if(
                a!isNullOrEmpty(fv!row.decisionDate),
                a!richTextItem(text: "—"),
                {{
                  a!richTextItem(text: text(todate(fv!row.decisionDate), "MM/DD/YYYY")),
                  /* seeded rows carry source "seed"; only real decisions (task, email, system) show their source and actor */
                  if(
                    or(a!isNullOrEmpty(fv!row.decisionSource), lower(fv!row.decisionSource) = "seed"),
                    "",
                    {{char(10), a!richTextItem(text: lower(fv!row.decisionSource) & if(or(a!isNullOrEmpty(fv!row.actedBy), lower(fv!row.actedBy) = "seed"), "", " · " & fv!row.actedBy), color: "#6B7280", size: "SMALL")}}
                  )
                }}
              )
            ),
            width: "NARROW_PLUS",
            backgroundColor: if(tostring(a!defaultValue(fv!row.status, "")) = "In Progress", "#E8F0FC", "NONE")
          ),
          a!gridColumn(
            label: "Time at Step",
            value: a!localVariables(
              local!s: tostring(a!defaultValue(fv!row.status, "")),
              if(
                a!isNullOrEmpty(fv!row.activatedAt),
                "—",
                if(
                  or(local!s = "Approved", local!s = "Rejected"),
                  if(
                    a!isNullOrEmpty(fv!row.decisionDate),
                    "—",
                    a!localVariables(
                      local!days: max(1, tointeger(ceiling(todecimal(todatetime(fv!row.decisionDate) - todatetime(fv!row.activatedAt))))),
                      local!days & if(local!days = 1, " day", " days")
                    )
                  ),
                  if(
                    local!s = "In Progress",
                    a!localVariables(
                      local!days: max(0, tointeger(today() - todate(fv!row.activatedAt))),
                      if(local!days = 0, "< 1 day", local!days & if(local!days = 1, " day", " days"))
                    ),
                    "—"
                  )
                )
              )
            ),
            width: "NARROW_PLUS",
            backgroundColor: if(tostring(a!defaultValue(fv!row.status, "")) = "In Progress", "#E8F0FC", "NONE")
          ),
          a!gridColumn(label: "Comments", value: if(a!isNullOrEmpty(fv!row.comments), "—", if(or(trim(fv!row.comments) = "", upper(trim(fv!row.comments)) = "N/A"), "—", fv!row.comments)), backgroundColor: if(tostring(a!defaultValue(fv!row.status, "")) = "In Progress", "#E8F0FC", "NONE"))
        }},
        pageSize: 20,
        spacing: "DENSE",
        borderStyle: "LIGHT",
        rowHeader: 2,
        emptyGridMessage: "No approval chain on this draw"
      ),
      rule!SD_cmp_sourceLine(text: "The CEO approves by email reply. All decisions are recorded with actor, source (task, email, or system), and timestamp. On final approval, Treasury is notified to execute the cash payment.")
    {card_close},
{email_card}
  }}
)
"""
open("SD_view_drawApprovals.sail","w").write(approvals)

# ---------- Documents ----------
doc_fields = ["id","document","documentName","documentType","uploadedBy","uploadedAt","status","notes","receivedDate"]
documents = f"""/* Draw approval: the Documents view of a draw record (mockups/draw-summary.html, Documents tab).
   Source template and backup rows: name (a download link when the file is attached), type, status chip, received, notes.
   Rows seeded without a file render the name as text; Phase 3 ingestion attaches the real documents. */
a!localVariables(
  local!d: rule!SD_getDrawDetail(drawId: ri!drawId),
  local!found: a!defaultValue(index(local!d, "found", false), false),
  local!docs: if(
    not(local!found),
    {{}},
    a!localVariables(
      local!raw: {query(DOC, doc_fields, f'a!queryFilter(field: {Dc("drawId")}, operator: "=", value: ri!drawId)', "id")},
      {tomaps(DOC, doc_fields)}
    )
  ),
  local!firstReceived: if(a!isNullOrEmpty(local!docs), null, index(local!docs, 1, null).receivedDate),
  local!feed: if(a!isNullOrEmpty(local!docs), null, index(local!docs, 1, null).uploadedBy),
  {{
    a!richTextDisplayField(labelPosition: "COLLAPSED", value: a!richTextItem(text: "Draw not found.", color: "NEGATIVE"), showWhen: not(local!found)),
    rule!SD_cmp_drawFactStrip(detail: local!d),
    a!cardLayout(
    contents: {{
      {heading('"Draw Documents"', '"Source template and backup for Draw #" & a!defaultValue(index(local!d, "drawNumber", ""), "") & if(a!isNullOrEmpty(local!feed), "", " · received via " & local!feed) & if(a!isNullOrEmpty(local!firstReceived), "", " " & text(local!firstReceived, "MM/DD/YYYY"))')},
      a!gridField(
        labelPosition: "COLLAPSED",
        data: local!docs,
        columns: {{
          a!gridColumn(
            label: "Document",
            value: a!richTextDisplayField(
              value: {{
                a!richTextIcon(
                  icon: if(find(".xls", lower(a!defaultValue(fv!row.documentName, ""))) > 0, "file-excel-o", if(find(".pdf", lower(a!defaultValue(fv!row.documentName, ""))) > 0, "file-pdf-o", "file-o")),
                  color: if(find(".xls", lower(a!defaultValue(fv!row.documentName, ""))) > 0, "#1E7E46", if(find(".pdf", lower(a!defaultValue(fv!row.documentName, ""))) > 0, "#B42318", "#6B7280"))
                ),
                " ",
                if(
                  a!isNullOrEmpty(fv!row.document),
                  a!richTextItem(text: a!defaultValue(fv!row.documentName, "—")),
                  a!richTextItem(text: a!defaultValue(fv!row.documentName, "document"), link: a!documentDownloadLink(document: fv!row.document), linkStyle: "STANDALONE")
                )
              }}
            ),
            width: "WIDE"
          ),
          a!gridColumn(label: "Type", value: a!defaultValue(fv!row.documentType, "—"), width: "NARROW_PLUS"),
          a!gridColumn(label: "Status", value: rule!SD_cmp_statusTag(status: fv!row.status), width: "NARROW_PLUS"),
          a!gridColumn(label: "Received", value: if(a!isNullOrEmpty(fv!row.receivedDate), "—", text(fv!row.receivedDate, "MM/DD/YYYY")), width: "NARROW_PLUS"),
          a!gridColumn(label: "Notes", value: if(a!isNullOrEmpty(fv!row.notes), "—", fv!row.notes))
        }},
        pageSize: 20,
        spacing: "DENSE",
        borderStyle: "LIGHT",
        rowHeader: 1,
        emptyGridMessage: "No documents on this draw yet"
      )
    {card_close}
  }}
)
"""
open("SD_view_drawDocuments.sail","w").write(documents)
print("written")

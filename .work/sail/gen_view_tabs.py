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

# ---------- Approvals: pointer to the Emails tab (Phase 6b; the 6a Email Exchange card moved to the Emails tab) ----------
EMAILS_STUB = "_ivHayg"   # SD Draw view "Emails" (SD_view_drawEmails), added 2026-09-26
email_card = """    a!richTextDisplayField(
      labelPosition: "COLLAPSED",
      value: {
        a!richTextIcon(icon: "envelope", color: "#6B7280"),
        " ",
        a!richTextItem(
          text: count(local!emails) & if(count(local!emails) = 1, " approval email", " approval emails") & " on this draw · ",
          color: "#6B7280",
          size: "SMALL"
        ),
        a!richTextItem(
          text: "View the email exchange",
          link: a!recordLink(recordType: """ + rt(DRAW) + """, identifier: ri!drawId, dashboard: \"""" + EMAILS_STUB + """\"),
          linkStyle: "STANDALONE",
          size: "SMALL"
        ),
        if(
          a!defaultValue(index(local!pending, "pending", false), false),
          a!richTextItem(text: " · a question from the " & index(local!pending, "role", "approver") & " awaits an answer", color: "#92600A", size: "SMALL", style: "STRONG"),
          ""
        )
      },
      marginBelow: "STANDARD"
    )"""

# ---------- Approvals ----------
appr_fields = ["id","approvalOrder","role","approverName","status","activatedAt","decisionDate","comments","actedBy","decisionSource"]
approvals = f"""/* Draw approval: the Approvals view of a draw record (mockups/draw-summary.html, Approvals tab).
   The nine-row chain as data: order, role, approver, status, decision date, time at step (computed), comments.
   The row in progress is highlighted. Time at step: decided rows count whole days from activation to decision
   (at least 1); the open row counts from activation to today.
   Phase 6b: the email exchange lives on its own Emails tab (SD_view_drawEmails); a one-line pointer below the chain
   links to it, with the message count and a pending question when there is one. */
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
  local!pending: if(local!found, rule!SD_getPendingQuestion(drawId: ri!drawId), a!map(pending: false)),
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

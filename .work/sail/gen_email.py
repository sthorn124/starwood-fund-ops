"""Phase 4: generates SD_buildApprovalEmail.sail — the approval step email (subject + HTML body) built from the draw's
records at send time, matched to `New approval email sample blacklined.pdf` (section order) and the recorded rulings:
Budget Summary as roll-ups of the lines, nine contiguous approval rows, nothing typed in from the sample.
Email-client constraints: table layout, every style inline, no <style>, no images, plain HTML only, lean for Gmail."""
from refs import *
L = lambda n: fld(LINE, n)
Q = lambda n: fld(QIU, n)
A = lambda n: fld(APPR, n)

line_fields = ["id","lineOrder","budgetCategory","categoryGroup","inThisDraw","initialBudget","revisedApprovedBudget",
               "proposedAdjustmentsThisDraw","proposedBudget","currentDraw","totalPtdIncThisDrawAmount","totalPtdIncThisDrawPct","balanceToComplete"]
qiu_fields = ["id","metricOrder","metric","modelAsOfDate","currentModelValue","currentProjection","variance","notes"]
appr_fields = ["id","approvalOrder","role","approverName","status","decisionDate","comments"]

def query(rt_, fields, filt, sortf, batch=100):
    return f"""a!queryRecordType(
        recordType: {rt(rt_)},
        fields: {{ {", ".join(fld(rt_, f) for f in fields)} }},
        filters: {filt},
        pagingInfo: a!pagingInfo(startIndex: 1, batchSize: {batch}, sort: a!sortInfo(field: {fld(rt_, sortf)}, ascending: true))
      ).data"""

def tomaps(rt_, fields):
    return "a!forEach(items: local!raw, expression: a!map(" + ", ".join(f"{f}: fv!item[{fld(rt_, f)}]" for f in fields) + "))"

def group_row(name):
    agg = lambda f: f'sum(a!forEach(items: local!lines, expression: if(fv!item.categoryGroup = "{name}", a!defaultValue(fv!item.{f}, 0), 0)))'
    return f"""a!map(
      budgetCategory: "{name}",
      initialBudget: {agg("initialBudget")}, revisedApprovedBudget: {agg("revisedApprovedBudget")},
      proposedAdjustmentsThisDraw: {agg("proposedAdjustmentsThisDraw")}, proposedBudget: {agg("proposedBudget")},
      currentDraw: {agg("currentDraw")}, totalPtdIncThisDrawAmount: {agg("totalPtdIncThisDrawAmount")},
      balanceToComplete: {agg("balanceToComplete")}
    )"""

# One budget-line row (line, group or total): nine cells; numbers right-aligned; zero/null as an em dash;
# PTD % from the row's own amount over its proposed budget for group/total rows, the stored percent for lines.
def line_row(item="fv!item", bold="false", pct_expr=None, cd_bg='""'):
    pct = pct_expr or f'if(a!defaultValue({item}.totalPtdIncThisDrawAmount, 0) = 0, "—", text(a!defaultValue({item}.totalPtdIncThisDrawPct, 0), "0.0") & "%")'
    return f"""rule!SD_emailRow(
        cells: {{
          rule!SD_htmlEscape(text: {item}.budgetCategory),
          rule!SD_fmtMoneyDash(value: {item}.initialBudget), rule!SD_fmtMoneyDash(value: {item}.revisedApprovedBudget),
          rule!SD_fmtMoneyDash(value: {item}.proposedAdjustmentsThisDraw), rule!SD_fmtMoneyDash(value: {item}.proposedBudget),
          rule!SD_fmtMoneyDash(value: {item}.currentDraw), rule!SD_fmtMoneyDash(value: {item}.totalPtdIncThisDrawAmount),
          {pct}, rule!SD_fmtMoneyDash(value: {item}.balanceToComplete)
        }},
        aligns: {{"left", "right", "right", "right", "right", "right", "right", "right", "right"}},
        bold: {bold},
        cellStyles: {{"", "", "", "", "", {cd_bg}, "", "", ""}}
      )"""

CD = '"background:#EEF4FF;"'
GROUP_PCT = 'if(a!defaultValue(fv!item.proposedBudget, 0) = 0, "—", text(100 * a!defaultValue(fv!item.totalPtdIncThisDrawAmount, 0) / fv!item.proposedBudget, "0.0") & "%")'
sail = f'''/* Draw approval (Phase 4): the approval step email — subject and HTML body — built from the draw's records at send
   time, for every step, matched to the new approval email sample's section order: navy header (investment, fund, draw
   type, funding date, amount) · greeting and reply instruction · Draw Funding Detail · Draw Detail by Budget Category
   (In this Draw, All Other Budget Categories, BUDGET total) · Budget Summary (Land / Soft / Hard / Total, rolled up from
   the lines — ruled, never copied from the sample) · Remaining Contingency · QIU Detail · Approval Status (nine
   contiguous rows, the current step marked) · reply footer. Money as in the app (SD_fmtMoney; cents only on the header
   amount), percents as 0.0%, dashes for empty. Table layout, every style inline, no stylesheet, no images — Gmail is
   the target. Returns a!map(subject, html, bytes). Nothing here is typed in from the sample. */
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
  local!appr: if(
    not(local!found),
    {{}},
    a!localVariables(
      local!raw: {query(APPR, appr_fields, f'a!queryFilter(field: {A("drawId")}, operator: "=", value: ri!drawId)', "approvalOrder")},
      {tomaps(APPR, appr_fields)}
    )
  ),
  /* The step this email is for: its approval row (name for the greeting) */
  local!stepIdx: if(a!isNullOrEmpty(local!appr), {{}}, wherecontains(tointeger(ri!stepOrder), tointeger(a!forEach(items: local!appr, expression: a!defaultValue(fv!item.approvalOrder, 0))))),
  local!step: if(a!isNullOrEmpty(local!stepIdx), null, index(local!appr, local!stepIdx[1], null)),
  local!approverName: if(a!isNullOrEmpty(local!step), "", a!defaultValue(local!step.approverName, "")),
  local!stepRole: if(a!isNullOrEmpty(local!step), a!defaultValue(index(local!d, "currentRole", ""), ""), a!defaultValue(local!step.role, "")),
  local!totalSteps: a!defaultValue(index(local!d, "totalSteps", cons!SD_DRAW_FINAL_APPROVAL_ORDER), cons!SD_DRAW_FINAL_APPROVAL_ORDER),
  /* Header facts */
  local!investment: a!defaultValue(index(local!d, "investmentName", ""), ""),
  local!fund: a!defaultValue(index(local!d, "fundName", ""), ""),
  local!drawNumber: index(local!d, "drawNumber", null),
  local!amount: index(local!d, "amount", null),
  local!fundingDate: index(local!d, "fundingDate", null),
  local!drawType: a!defaultValue(index(local!d, "drawType", ""), ""),
  local!budgetStatus: a!defaultValue(index(local!d, "budgetStatus", ""), ""),
  local!amountText: if(a!isNullOrEmpty(local!amount), "—", rule!SD_fmtMoney(value: local!amount, showCents: true)),
  local!fundingText: if(a!isNullOrEmpty(local!fundingDate), "—", text(todate(local!fundingDate), "MMMM D, YYYY")),
  /* Lines split as the Budget Detail view does; the total row and the group roll-ups computed from the lines */
  local!flags: a!forEach(items: local!lines, expression: a!defaultValue(fv!item.inThisDraw, false)),
  local!inDraw: if(a!isNullOrEmpty(local!lines), {{}}, index(local!lines, wherecontains(true, local!flags), {{}})),
  local!others: if(a!isNullOrEmpty(local!lines), {{}}, index(local!lines, wherecontains(false, local!flags), {{}})),
  local!total: a!localVariables(
    local!proposed: sum(a!forEach(items: local!lines, expression: a!defaultValue(fv!item.proposedBudget, 0))),
    local!ptd: sum(a!forEach(items: local!lines, expression: a!defaultValue(fv!item.totalPtdIncThisDrawAmount, 0))),
    a!map(
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
  local!groups: {{ {group_row("Land")}, {group_row("Soft")}, {group_row("Hard")} }},
  /* Remaining contingency: the contingency line over the total balance to complete (as the Summary view) */
  local!contIdx: if(a!isNullOrEmpty(local!lines), {{}}, wherecontains(true, a!forEach(items: local!lines, expression: find("contingency", lower(a!defaultValue(fv!item.budgetCategory, ""))) > 0))),
  local!cont: if(a!isNullOrEmpty(local!contIdx), null, index(local!lines, local!contIdx[1], null)),
  local!totalBalance: sum(a!forEach(items: local!lines, expression: a!defaultValue(fv!item.balanceToComplete, 0))),
  local!qiuAsOf: if(a!isNullOrEmpty(local!qiu), null, index(local!qiu, 1, null).modelAsOfDate),
  /* Styles, kept short: they repeat on every cell */
  local!band: "background:#16294D;color:#FFFFFF;padding:6px 12px;font-size:11px;font-weight:bold;letter-spacing:0.5px;",
  local!th: "background:#E8EEF7;color:#16294D;padding:5px 6px;border-bottom:1px solid #C9D4EF;font-size:10px;font-weight:bold;",
  local!label: "background:#EEF1F5;color:#6B7280;padding:4px 8px;border-bottom:1px solid #E5E7EB;width:34%;",
  local!value: "padding:4px 8px;border-bottom:1px solid #E5E7EB;",
  local!tableOpen: "<table role=""presentation"" width=""100%"" cellpadding=""0"" cellspacing=""0"" border=""0"" style=""border-collapse:collapse;font-family:Arial,Helvetica,sans-serif;font-size:11px;color:#1F2937;"">",
  /* Section band as a full-width row of the outer table */
  local!lineHeader: "<tr>" & rule!SD_emailCells(texts: {{"Budget Category", "Initial Budget", "Revised Approved Budget", "Proposed Adjustments This Draw", "Proposed Budget", "Current Draw", "Total PTD inc. This Draw ($)", "Total PTD inc. This Draw (%)", "Balance To Complete"}}, aligns: {{"left", "right", "right", "right", "right", "right", "right", "right", "right"}}, style: local!th, tag: "th") & "</tr>",
  local!groupRow: "<tr><td colspan=""9"" style=""padding:5px 6px;font-size:10px;font-weight:bold;color:#16294D;background:#F5F6F8;"">",
  local!lineRows: if(
    a!isNullOrEmpty(local!lines),
    "<tr><td colspan=""9"" style=""" & local!value & """>No budget lines on this draw</td></tr>",
    concat(
      if(a!isNullOrEmpty(local!inDraw), local!groupRow & "In this Draw</td></tr><tr><td colspan=""9"" style=""" & local!value & "color:#6B7280;"">No budget categories are funded by this draw</td></tr>", local!groupRow & "In this Draw</td></tr>" & concat(a!forEach(items: local!inDraw, expression: {line_row(cd_bg=CD)}))),
      if(a!isNullOrEmpty(local!others), "", local!groupRow & "All Other Budget Categories</td></tr>" & concat(a!forEach(items: local!others, expression: {line_row(cd_bg=CD)}))),
      {line_row("local!total", bold="true", cd_bg=CD)}
    )
  ),
  local!summaryRows: if(
    a!isNullOrEmpty(local!lines),
    "<tr><td colspan=""9"" style=""" & local!value & """>No budget lines on this draw</td></tr>",
    concat(
      concat(a!forEach(items: local!groups, expression: {line_row(pct_expr=GROUP_PCT)})),
      {line_row("local!total", bold="true")}
    )
  ),
  local!contRows: if(
    a!isNullOrEmpty(local!cont),
    "<tr><td colspan=""7"" style=""" & local!value & """>No contingency line on this draw</td></tr>",
    rule!SD_emailRow(
      cells: {{"Remaining Contingency ($)", rule!SD_fmtMoneyDash(value: local!cont.initialBudget), rule!SD_fmtMoneyDash(value: local!cont.revisedApprovedBudget), rule!SD_fmtMoneyDash(value: local!cont.proposedAdjustmentsThisDraw), rule!SD_fmtMoneyDash(value: local!cont.balanceToComplete), rule!SD_fmtMoneyDash(value: a!defaultValue(local!cont.balanceToComplete, 0) - a!defaultValue(local!cont.revisedApprovedBudget, 0)), "—"}},
      aligns: {{"left", "right", "right", "right", "right", "right", "left"}}, bold: false, cellStyles: {{"", "", "", "", "", "", ""}}
    ) & rule!SD_emailRow(
      cells: {{"Remaining Contingency (%)", "—", if(local!totalBalance = 0, "—", text(a!defaultValue(local!cont.revisedApprovedBudget, 0) / local!totalBalance, "0.0%")), "—", if(local!totalBalance = 0, "—", text(a!defaultValue(local!cont.balanceToComplete, 0) / local!totalBalance, "0.0%")), "—", "Percent is contingency over total balance to complete (" & rule!SD_fmtMoney(value: local!totalBalance, showCents: false) & ")"}},
      aligns: {{"left", "right", "right", "right", "right", "right", "left"}}, bold: false, cellStyles: {{"", "", "", "", "", "", ""}}
    )
  ),
  local!qiuRows: if(
    a!isNullOrEmpty(local!qiu),
    "<tr><td colspan=""5"" style=""" & local!value & """>No QIU metrics on this draw</td></tr>",
    concat(a!forEach(items: local!qiu, expression: rule!SD_emailRow(
      cells: {{rule!SD_htmlEscape(text: fv!item.metric), rule!SD_htmlEscape(text: a!defaultValue(fv!item.currentModelValue, "—")), rule!SD_htmlEscape(text: a!defaultValue(fv!item.currentProjection, "—")), rule!SD_htmlEscape(text: a!defaultValue(fv!item.variance, "—")), if(a!isNullOrEmpty(fv!item.notes), "—", rule!SD_htmlEscape(text: fv!item.notes))}},
      aligns: {{"left", "right", "right", "right", "left"}}, bold: false, cellStyles: {{"", "", "", "", ""}}
    )))
  ),
  local!apprRows: if(
    a!isNullOrEmpty(local!appr),
    "<tr><td colspan=""6"" style=""" & local!value & """>No approval chain on this draw</td></tr>",
    concat(a!forEach(items: local!appr, expression: a!localVariables(
      local!isCurrent: tointeger(a!defaultValue(fv!item.approvalOrder, 0)) = tointeger(ri!stepOrder),
      local!status: a!defaultValue(fv!item.status, ""),
      local!chipBg: a!match(value: local!status, equals: "Approved", then: "#E6F4EC", equals: "In Progress", then: "#E8F0FC", equals: "Rejected", then: "#FDECEC", default: "#EEF1F5"),
      local!chipFg: a!match(value: local!status, equals: "Approved", then: "#1E7E46", equals: "In Progress", then: "#1D5BBF", equals: "Rejected", then: "#B42318", default: "#64748B"),
      local!rowBg: if(local!isCurrent, "background:#FFF8E6;", ""),
      rule!SD_emailRow(
        cells: {{
          if(local!isCurrent, "&#9654; " & fv!item.approvalOrder, tostring(fv!item.approvalOrder)),
          rule!SD_htmlEscape(text: fv!item.role),
          rule!SD_htmlEscape(text: fv!item.approverName),
          "<span style=""display:inline-block;padding:2px 8px;border-radius:10px;background:" & local!chipBg & ";color:" & local!chipFg & ";font-size:10px;font-weight:bold;"">" & rule!SD_htmlEscape(text: local!status) & "</span>",
          if(a!isNullOrEmpty(fv!item.decisionDate), "—", text(fv!item.decisionDate, "MM/DD/YYYY")),
          if(local!isCurrent, "<b>&#9664; Current step — your approval is requested</b>", if(a!isNullOrEmpty(fv!item.comments), "—", rule!SD_htmlEscape(text: fv!item.comments)))
        }},
        aligns: {{"center", "left", "left", "left", "left", "left"}},
        bold: local!isCurrent,
        cellStyles: {{local!rowBg, local!rowBg, local!rowBg, local!rowBg, local!rowBg, local!rowBg}}
      )
    )))
  ),
  local!detailRows: concat(a!forEach(
    items: {{
      a!map(l: "Investment Name", v: local!investment),
      a!map(l: "Investment Description", v: a!defaultValue(index(local!d, "investmentDescription", ""), "")),
      a!map(l: "Fund", v: local!fund),
      a!map(l: "Amount", v: local!amountText),
      a!map(l: "Cash/Equity Needed from the Fund?", v: if(a!isNullOrEmpty(index(local!d, "cashEquityNeeded", null)), "—", if(index(local!d, "cashEquityNeeded", false), "Yes", "No"))),
      a!map(l: "Funding Date", v: local!fundingText),
      a!map(l: "Draw Type", v: local!drawType),
      a!map(l: "Purpose", v: a!defaultValue(index(local!d, "purpose", ""), "")),
      a!map(l: "On / Under / Over Budget", v: local!budgetStatus),
      a!map(l: "Over Budget Reason", v: a!defaultValue(index(local!d, "overBudgetReason", ""), "")),
      a!map(l: "General Comments", v: a!defaultValue(index(local!d, "generalComments", ""), "")),
      a!map(l: "Budget and Contingency Explanation", v: a!defaultValue(index(local!d, "contingencyExplanation", ""), ""))
    }},
    expression: "<tr><td style=""" & local!label & """>" & fv!item.l & "</td><td style=""" & local!value & """>" & if(a!defaultValue(fv!item.v, "") = "", "—", rule!SD_htmlEscape(text: fv!item.v)) & "</td></tr>"
  )),
  /* Phase 6a: the reference token [SD-DRAW-<drawId>-S<step>] ends the subject, so a reply's "Re: …" names its draw and
     step; the email approval limit decides which reply instruction the email carries */
  local!subject: "Draw Funding Approval: Draw #" & a!defaultValue(local!drawNumber, ri!drawId) & " · " & local!investment & " · " & local!amountText & " · Step " & ri!stepOrder & " of " & local!totalSteps & " (" & local!stepRole & ") [SD-DRAW-" & ri!drawId & "-S" & ri!stepOrder & "]",
  local!emailDecidable: todecimal(a!defaultValue(local!amount, 0)) <= todecimal(cons!SD_EMAIL_APPROVAL_MAX),
  local!html: concat(
    "<div style=""margin:0;padding:0;background:#F5F6F8;"">",
    "<table role=""presentation"" width=""100%"" cellpadding=""0"" cellspacing=""0"" border=""0"" style=""background:#F5F6F8;""><tr><td align=""center"" style=""padding:12px;"">",
    "<table role=""presentation"" width=""100%"" cellpadding=""0"" cellspacing=""0"" border=""0"" style=""max-width:1040px;background:#FFFFFF;border:1px solid #D9DEE7;font-family:Arial,Helvetica,sans-serif;color:#1F2937;"">",
    /* Header band */
    "<tr><td style=""background:#16294D;color:#FFFFFF;padding:14px 18px 6px 18px;font-size:16px;font-weight:bold;font-family:Arial,Helvetica,sans-serif;"">DRAW FUNDING APPROVAL &nbsp;|&nbsp; " & rule!SD_htmlEscape(text: local!investment) & "</td></tr>",
    "<tr><td style=""background:#16294D;color:#C7D2E5;padding:0 18px 12px 18px;font-size:11px;font-family:Arial,Helvetica,sans-serif;"">Draw #" & a!defaultValue(local!drawNumber, "—") & " &nbsp;&middot;&nbsp; Fund: " & rule!SD_htmlEscape(text: local!fund) & " &nbsp;&middot;&nbsp; Draw Type: " & rule!SD_htmlEscape(text: local!drawType) & " &nbsp;&middot;&nbsp; Funding Date: " & local!fundingText & " &nbsp;&middot;&nbsp; Amount: " & local!amountText & " &nbsp;&middot;&nbsp; " & rule!SD_htmlEscape(text: if(local!budgetStatus = "", "—", local!budgetStatus)) & "</td></tr>",
    /* Greeting and reply instruction */
    "<tr><td style=""padding:14px 18px 10px 18px;font-size:13px;line-height:18px;font-family:Arial,Helvetica,sans-serif;"">Hello " & rule!SD_htmlEscape(text: if(local!approverName = "", "approver", local!approverName)) & ",<br>This draw is ready for your approval (step " & ri!stepOrder & " of " & local!totalSteps & ", " & rule!SD_htmlEscape(text: local!stepRole) & "). " & if(local!emailDecidable, "Reply to this email with your decision in your own words &mdash; for example &quot;Approved&quot;, or &quot;Rejected, hold until the lender signs off&quot;. Your reply is read and recorded on the draw; if it is not a clear approval or rejection, you will be asked to confirm and nothing changes until you do.", "<span style=""color:#92600A;font-weight:bold;"">Email approval is not available for this draw: its amount is above the " & rule!SD_fmtMoney(value: cons!SD_EMAIL_APPROVAL_MAX, showCents: false) & " limit for decisions by email. Please record your decision in the system.</span>") & "</td></tr>",
    /* Draw Funding Detail */
    "<tr><td style=""padding:0 12px;"">" & local!tableOpen & "<tr><td colspan=""2"" style=""" & local!band & """>DRAW FUNDING DETAIL</td></tr>" & local!detailRows & "</table></td></tr>",
    "<tr><td style=""height:12px;font-size:1px;line-height:12px;"">&nbsp;</td></tr>",
    /* Draw Detail by Budget Category */
    "<tr><td style=""padding:0 12px;"">" & local!tableOpen & "<tr><td colspan=""9"" style=""" & local!band & """>DRAW DETAIL BY BUDGET CATEGORY</td></tr>" & local!lineHeader & local!lineRows & "</table></td></tr>",
    "<tr><td style=""height:12px;font-size:1px;line-height:12px;"">&nbsp;</td></tr>",
    /* Budget Summary */
    "<tr><td style=""padding:0 12px;"">" & local!tableOpen & "<tr><td colspan=""9"" style=""" & local!band & """>BUDGET SUMMARY</td></tr>" & local!lineHeader & local!summaryRows & "<tr><td colspan=""9"" style=""padding:4px 6px;font-size:10px;color:#6B7280;"">Roll-up of the budget lines by category group. Land: site &amp; acquisition. Hard: construction &amp; FF&amp;E. Soft: fees, taxes, insurance, financing, marketing, contingency.</td></tr></table></td></tr>",
    "<tr><td style=""height:12px;font-size:1px;line-height:12px;"">&nbsp;</td></tr>",
    /* Remaining Contingency */
    "<tr><td style=""padding:0 12px;"">" & local!tableOpen & "<tr><td colspan=""7"" style=""" & local!band & """>REMAINING CONTINGENCY</td></tr><tr>" & rule!SD_emailCells(texts: {{"Costs", "Original Budget", "Revised Approved Budget", "Proposed Adjustments This Draw", "Proposed Budget", "Variance", "Reason"}}, aligns: {{"left", "right", "right", "right", "right", "right", "left"}}, style: local!th, tag: "th") & "</tr>" & local!contRows & "</table></td></tr>",
    "<tr><td style=""height:12px;font-size:1px;line-height:12px;"">&nbsp;</td></tr>",
    /* QIU Detail */
    "<tr><td style=""padding:0 12px;"">" & local!tableOpen & "<tr><td colspan=""5"" style=""" & local!band & """>QIU DETAIL &mdash; " & rule!SD_htmlEscape(text: local!investment) & "</td></tr><tr>" & rule!SD_emailCells(texts: {{"Metric", "Current QIU Model" & if(a!isNullOrEmpty(local!qiuAsOf), "", " (" & text(todate(local!qiuAsOf), "MM/DD/YYYY") & ")"), "Current Projection", "Variance of Current Projection", "Notes"}}, aligns: {{"left", "right", "right", "right", "left"}}, style: local!th, tag: "th") & "</tr>" & local!qiuRows & "</table></td></tr>",
    "<tr><td style=""height:12px;font-size:1px;line-height:12px;"">&nbsp;</td></tr>",
    /* Approval Status */
    "<tr><td style=""padding:0 12px;"">" & local!tableOpen & "<tr><td colspan=""6"" style=""" & local!band & """>APPROVAL STATUS</td></tr><tr>" & rule!SD_emailCells(texts: {{"Order", "Role", "Approver", "Status", "Decision Date", "Comments"}}, aligns: {{"center", "left", "left", "left", "left", "left"}}, style: local!th, tag: "th") & "</tr>" & local!apprRows & "</table></td></tr>",
    "<tr><td style=""height:12px;font-size:1px;line-height:12px;"">&nbsp;</td></tr>",
    /* Footer */
    "<tr><td style=""background:#16294D;color:#FFFFFF;padding:10px 18px;font-size:12px;font-style:italic;font-family:Arial,Helvetica,sans-serif;"">" & if(local!emailDecidable, "Reply to this email with your decision. Replies are read and recorded on the draw.", "Decide this draw in the system; email replies cannot approve it.") & "</td></tr>",
    "</table></td></tr></table></div>"
  ),
  a!map(subject: local!subject, html: local!html, bytes: len(local!html))
)
'''
open("SD_buildApprovalEmail.sail", "w").write(sail)
print("wrote SD_buildApprovalEmail.sail", len(sail))

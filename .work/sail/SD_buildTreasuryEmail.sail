/* Draw approval (Phase 6c): the treasury notification sent when a draw's final approval is recorded (SD Apply Draw
   Approval Decision, after the Approved write succeeds; same recipient as before, cons!SD_DRAW_TREASURY_RECIPIENT).
   Framed for the wire desk: approved for funding, execute payment. It carries the draw, investment, fund, amount and
   funding date, the approval completion summary (N of N, the final approver, when and through which channel), the
   chain as a compact table, and a link to the draw. No bank or payment instructions travel in email: the wire desk uses
   the instructions on file. Built from the records at send time. Returns a map: subject, html, text, bytes. */
a!localVariables(
  local!d: rule!SD_getDrawDetail(drawId: ri!drawId),
  local!drawNo: a!defaultValue(index(local!d, "drawNumber", null), ri!drawId),
  local!investment: a!defaultValue(index(local!d, "investmentName", ""), ""),
  local!fund: a!defaultValue(index(local!d, "fundName", ""), ""),
  local!amountText: rule!SD_fmtMoney(value: index(local!d, "amount", 0), showCents: true),
  local!fundingDate: index(local!d, "fundingDate", null),
  local!fundingText: if(a!isNullOrEmpty(local!fundingDate), "the scheduled funding date", text(todate(local!fundingDate), "MMMM D, YYYY")),
  local!approvals: a!defaultValue(index(local!d, "approvals", {}), {}),
  local!total: count(local!approvals),
  local!approvedCount: a!defaultValue(index(local!d, "approvedCount", 0), 0),
  /* the final approval: the approved row with the highest order */
  local!orders: if(a!isNullOrEmpty(local!approvals), {}, a!forEach(items: local!approvals, expression: if(tostring(a!defaultValue(fv!item.status, "")) = "Approved", tointeger(fv!item.approvalOrder), 0))),
  local!finalRow: if(
    a!isNullOrEmpty(local!orders),
    null,
    index(local!approvals, wherecontains(tointeger(max(local!orders)), a!forEach(items: local!approvals, expression: tointeger(fv!item.approvalOrder))), null)
  ),
  local!final: if(a!isNullOrEmpty(local!finalRow), null, index(local!finalRow, 1, null)),
  local!finalSource: a!localVariables(
    local!raw: rule!SD_getDrawApprovalRowSource(drawId: ri!drawId, approvalOrder: if(a!isNullOrEmpty(local!final), null, local!final.approvalOrder)),
    a!match(value: local!raw, equals: "EMAIL", then: "by email reply", equals: "TASK", then: "in Starwood Draw Approvals", default: "")
  ),
  local!url: tostring(a!urlForRecord(recordType: 'recordType!{c9d3a947-71aa-4024-879e-363873a12860}SD Draw', targetLocation: 'site!{ffae752f-b3d1-44d5-a9ba-c408b66bdb65}SASite.pages.{76fd3289-c3d8-4c52-ad60-8342f924d6d6}draws', identifier: ri!drawId)),
  local!subject: "Approved for funding · Draw #" & local!drawNo & " · " & local!investment & " · " & local!amountText & " · fund by " & if(a!isNullOrEmpty(local!fundingDate), "—", text(todate(local!fundingDate), "MMM D")),
  local!lead: "Draw #" & local!drawNo & " for " & local!investment & " has completed its approval chain and is approved for funding. Execute the payment of " & local!amountText & " from " & local!fund & " on or before " & local!fundingText & ".",
  local!completion: local!approvedCount & " of " & local!total & " approvals complete" & if(
    a!isNullOrEmpty(local!final),
    "",
    " · final approval by " & local!final.approverName & " (" & local!final.role & ") on " & if(a!isNullOrEmpty(local!final.decisionDate), "—", text(todate(local(local!final.decisionDate, cons!SD_BUSINESS_TIMEZONE)), "MMMM D, YYYY")) & if(local!finalSource = "", "", " " & local!finalSource)
  ),
  local!band: "background:#16294D;color:#FFFFFF;padding:6px 12px;font-size:11px;font-weight:bold;letter-spacing:0.5px;",
  local!th: "background:#E8EEF7;color:#16294D;padding:5px 8px;border-bottom:1px solid #C9D4EF;font-size:10px;font-weight:bold;text-align:left;",
  local!label: "background:#EEF1F5;color:#6B7280;padding:5px 8px;border-bottom:1px solid #E5E7EB;width:34%;font-size:12px;",
  local!value: "padding:5px 8px;border-bottom:1px solid #E5E7EB;font-size:12px;",
  local!tableOpen: "<table role=""presentation"" width=""100%"" cellpadding=""0"" cellspacing=""0"" border=""0"" style=""border-collapse:collapse;font-family:Arial,Helvetica,sans-serif;color:#1F2937;"">",
  local!detailRows: concat(a!forEach(
    items: {
      a!map(l: "Amount to pay", v: local!amountText, strong: true),
      a!map(l: "Pay on or before", v: local!fundingText, strong: true),
      a!map(l: "From fund", v: local!fund, strong: false),
      a!map(l: "Investment", v: local!investment, strong: false),
      a!map(l: "Draw", v: "Draw #" & local!drawNo & " · " & a!defaultValue(index(local!d, "drawType", ""), ""), strong: false),
      a!map(l: "Cash/Equity needed from the fund?", v: if(a!isNullOrEmpty(index(local!d, "cashEquityNeeded", null)), "—", if(index(local!d, "cashEquityNeeded", false), "Yes", "No")), strong: false),
      a!map(l: "Purpose", v: a!defaultValue(index(local!d, "purpose", ""), ""), strong: false),
      a!map(l: "Submitted by", v: a!defaultValue(index(local!d, "submittedBy", ""), ""), strong: false)
    },
    expression: "<tr><td style=""" & local!label & """>" & fv!item.l & "</td><td style=""" & local!value & if(fv!item.strong, "font-weight:bold;color:#16294D;", "") & """>" & if(a!defaultValue(fv!item.v, "") = "", "—", rule!SD_htmlEscape(text: fv!item.v)) & "</td></tr>"
  )),
  local!chainRows: if(
    a!isNullOrEmpty(local!approvals),
    "<tr><td colspan=""4"" style=""" & local!value & """>No approval chain on this draw</td></tr>",
    concat(a!forEach(
      items: local!approvals,
      expression: "<tr><td style=""" & local!value & "text-align:center;width:44px;"">" & fv!item.approvalOrder & "</td><td style=""" & local!value & """>" & rule!SD_htmlEscape(text: fv!item.role) & "</td><td style=""" & local!value & """>" & rule!SD_htmlEscape(text: fv!item.approverName) & "</td><td style=""" & local!value & if(tostring(a!defaultValue(fv!item.status, "")) = "Approved", "color:#1E7E46;", "color:#6B7280;") & """>" & rule!SD_htmlEscape(text: a!defaultValue(fv!item.status, "")) & if(a!isNullOrEmpty(fv!item.decisionDate), "", " " & text(todate(local(fv!item.decisionDate, cons!SD_BUSINESS_TIMEZONE)), "MM/DD/YYYY")) & "</td></tr>"
    ))
  ),
  local!html: concat(
    "<div style=""margin:0;padding:0;background:#F5F6F8;"">",
    "<table role=""presentation"" width=""100%"" cellpadding=""0"" cellspacing=""0"" border=""0"" style=""background:#F5F6F8;""><tr><td align=""center"" style=""padding:12px;"">",
    "<table role=""presentation"" width=""100%"" cellpadding=""0"" cellspacing=""0"" border=""0"" style=""max-width:720px;background:#FFFFFF;border:1px solid #D9DEE7;font-family:Arial,Helvetica,sans-serif;color:#1F2937;"">",
    "<tr><td style=""background:#16294D;color:#FFFFFF;padding:14px 18px 6px 18px;font-size:16px;font-weight:bold;"">TREASURY &nbsp;|&nbsp; APPROVED FOR FUNDING</td></tr>",
    "<tr><td style=""background:#16294D;color:#C7D2E5;padding:0 18px 12px 18px;font-size:11px;"">Draw #" & local!drawNo & " &nbsp;&middot;&nbsp; " & rule!SD_htmlEscape(text: local!investment) & " &nbsp;&middot;&nbsp; " & rule!SD_htmlEscape(text: local!fund) & " &nbsp;&middot;&nbsp; " & local!amountText & "</td></tr>",
    "<tr><td style=""background:#E6F4EC;color:#1E7E46;padding:12px 18px;font-size:14px;line-height:20px;font-weight:bold;border-bottom:1px solid #BFE3CC;"">Approved for funding &mdash; execute payment of " & local!amountText & " on or before " & local!fundingText & ".</td></tr>",
    "<tr><td style=""padding:14px 18px 10px 18px;font-size:13px;line-height:19px;"">" & rule!SD_htmlEscape(text: local!lead) & "</td></tr>",
    "<tr><td style=""padding:0 12px;"">" & local!tableOpen & "<tr><td colspan=""2"" style=""" & local!band & """>PAYMENT</td></tr>" & local!detailRows & "</table></td></tr>",
    "<tr><td style=""height:12px;font-size:1px;line-height:12px;"">&nbsp;</td></tr>",
    "<tr><td style=""padding:0 12px;"">" & local!tableOpen & "<tr><td colspan=""4"" style=""" & local!band & """>APPROVAL CHAIN &mdash; " & upper(rule!SD_htmlEscape(text: local!approvedCount & " of " & local!total & " complete")) & "</td></tr>" &
      "<tr><td colspan=""4"" style=""padding:8px 8px;font-size:12px;color:#1F2937;border-bottom:1px solid #E5E7EB;"">" & rule!SD_htmlEscape(text: local!completion) & "</td></tr>" &
      "<tr><th style=""" & local!th & "text-align:center;"">Order</th><th style=""" & local!th & """>Role</th><th style=""" & local!th & """>Approver</th><th style=""" & local!th & """>Decision</th></tr>" & local!chainRows & "</table></td></tr>",
    "<tr><td style=""padding:14px 18px 6px 18px;font-size:13px;""><a href=""" & local!url & """ style=""color:#1D5BBF;font-weight:bold;text-decoration:none;"">Open Draw #" & local!drawNo & " in Starwood Draw Approvals &rarr;</a></td></tr>",
    "<tr><td style=""height:8px;font-size:1px;line-height:8px;"">&nbsp;</td></tr>",
    "<tr><td style=""background:#16294D;color:#FFFFFF;padding:10px 18px;font-size:12px;font-style:italic;"">Wire desk: execute against the payment instructions on file for the fund. This notification carries no bank details and replies are not monitored.</td></tr>",
    "</table></td></tr></table></div>"
  ),
  a!map(subject: local!subject, html: local!html, text: local!lead & " " & local!completion, bytes: len(local!html))
)

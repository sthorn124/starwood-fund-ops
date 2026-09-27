/* Draw approval (Phase 6c): the daily chase digest for the draw approval team — one summary email built from
   rule!SD_getChaseRows (the same query as the Draws page's Needs chasing view): every step waiting SD_CHASE_AGE_DAYS or
   more and every email reply waiting for review, ranked by amount then days to funding, each with who holds it, how to
   reach them, when it was last chased, and a link to the draw. The Phase 4 visual language: navy bands, table layout,
   inline styles, no images. Returns a map: subject, html, text, count, bytes. */
a!localVariables(
  local!rows: rule!SD_getChaseRows(rows: ri!rows),
  local!n: count(local!rows),
  local!total: if(local!n = 0, 0, sum(a!forEach(items: local!rows, expression: a!defaultValue(fv!item.amount, 0)))),
  local!subject: if(
    local!n = 0,
    "Draw approvals · nothing needs chasing · " & text(today(), "MMM D"),
    "Draw approvals needing a chase · " & local!n & if(local!n = 1, " draw", " draws") & " · " & rule!SD_fmtMoney(value: local!total, showCents: false) & " · " & text(today(), "MMM D")
  ),
  local!th: "background:#E8EEF7;color:#16294D;padding:6px 8px;border-bottom:1px solid #C9D4EF;font-size:10px;font-weight:bold;text-align:left;",
  local!td: "padding:6px 8px;border-bottom:1px solid #E5E7EB;font-size:11px;vertical-align:top;",
  local!rowsHtml: if(
    local!n = 0,
    "<tr><td colspan=""7"" style=""" & local!td & "color:#6B7280;"">No approval step has waited " & cons!SD_CHASE_AGE_DAYS & " days or more, and no email reply is waiting for review.</td></tr>",
    concat(
      a!forEach(
        items: local!rows,
        expression: a!localVariables(
          /* a!urlForRecord with one identifier returns one string (index(…, 1) would take its first character): tostring it */
          local!url: tostring(a!urlForRecord(recordType: 'recordType!{c9d3a947-71aa-4024-879e-363873a12860}SD Draw', targetLocation: 'site!{ffae752f-b3d1-44d5-a9ba-c408b66bdb65}SASite.pages.{76fd3289-c3d8-4c52-ad60-8342f924d6d6}draws', identifier: fv!item.drawId)),
          local!hot: a!defaultValue(fv!item.smsDue, false),
          "<tr>" &
          "<td style=""" & local!td & "text-align:center;font-weight:bold;color:#16294D;"">" & fv!index & "</td>" &
          "<td style=""" & local!td & """><a href=""" & local!url & """ style=""color:#1D5BBF;font-weight:bold;text-decoration:none;"">Draw #" & a!defaultValue(fv!item.drawNumber, fv!item.drawId) & "</a><br><span style=""color:#6B7280;"">" & rule!SD_htmlEscape(text: fv!item.investmentName) & "</span></td>" &
          "<td style=""" & local!td & "text-align:right;font-weight:bold;"">" & rule!SD_fmtMoney(value: fv!item.amount, showCents: false) & "</td>" &
          "<td style=""" & local!td & """>" & if(a!isNullOrEmpty(fv!item.fundingDate), "—", text(todate(fv!item.fundingDate), "MMM D") & "<br><span style=""color:#6B7280;"">" & rule!SD_fmtRelativeDays(days: fv!item.daysToFunding) & "</span>") & "</td>" &
          "<td style=""" & local!td & """>" & if(fv!item.role = "", "The draw approval team", rule!SD_htmlEscape(text: fv!item.approverName) & "<br><span style=""color:#6B7280;"">" & rule!SD_htmlEscape(text: fv!item.role) & " · step " & fv!item.currentStep & " of " & fv!item.totalSteps & "</span>") & "</td>" &
          "<td style=""" & local!td & if(local!hot, "color:#92600A;font-weight:bold;", "") & """>" & rule!SD_htmlEscape(text: fv!item.reason) & if(fv!item.lastChaseLabel = "", "", "<br><span style=""color:#6B7280;font-weight:normal;"">" & fv!item.lastChaseLabel & " " & text(fv!item.lastChaseAt, "MMM D") & "</span>") & "</td>" &
          "<td style=""" & local!td & """>" & if(fv!item.contact = "", "—", "<a href=""mailto:" & fv!item.contact & """ style=""color:#1D5BBF;text-decoration:none;"">" & rule!SD_htmlEscape(text: fv!item.contact) & "</a>") & if(fv!item.groupName = "", "", "<br><span style=""color:#6B7280;"">task: " & rule!SD_htmlEscape(text: fv!item.groupName) & "</span>") & "</td>" &
          "</tr>"
        )
      )
    )
  ),
  local!html: concat(
    "<div style=""margin:0;padding:0;background:#F5F6F8;"">",
    "<table role=""presentation"" width=""100%"" cellpadding=""0"" cellspacing=""0"" border=""0"" style=""background:#F5F6F8;""><tr><td align=""center"" style=""padding:12px;"">",
    "<table role=""presentation"" width=""100%"" cellpadding=""0"" cellspacing=""0"" border=""0"" style=""max-width:1040px;background:#FFFFFF;border:1px solid #D9DEE7;font-family:Arial,Helvetica,sans-serif;color:#1F2937;"">",
    "<tr><td style=""background:#16294D;color:#FFFFFF;padding:14px 18px 6px 18px;font-size:16px;font-weight:bold;"">DRAW APPROVALS &nbsp;|&nbsp; NEEDS CHASING</td></tr>",
    "<tr><td style=""background:#16294D;color:#C7D2E5;padding:0 18px 12px 18px;font-size:11px;"">" & text(today(), "dddd, MMMM D, YYYY") & " &nbsp;&middot;&nbsp; " & local!n & if(local!n = 1, " draw", " draws") & " &nbsp;&middot;&nbsp; " & rule!SD_fmtMoney(value: local!total, showCents: false) & " waiting</td></tr>",
    "<tr><td style=""padding:14px 18px 10px 18px;font-size:13px;line-height:18px;"">These approval steps have waited " & cons!SD_CHASE_AGE_DAYS & " days or more, or have an email reply waiting for the team's review. They are ranked by amount, then by days to funding. Steps waiting " & cons!SD_SMS_AGE_DAYS & " days or more are in amber: that is when the escalation texts the approver.</td></tr>",
    "<tr><td style=""padding:0 12px;""><table role=""presentation"" width=""100%"" cellpadding=""0"" cellspacing=""0"" border=""0"" style=""border-collapse:collapse;font-family:Arial,Helvetica,sans-serif;color:#1F2937;"">",
    "<tr><td colspan=""7"" style=""background:#16294D;color:#FFFFFF;padding:6px 12px;font-size:11px;font-weight:bold;letter-spacing:0.5px;"">WAITING, RANKED</td></tr>",
    "<tr><th style=""" & local!th & "text-align:center;"">#</th><th style=""" & local!th & """>Draw</th><th style=""" & local!th & "text-align:right;"">Amount</th><th style=""" & local!th & """>Funding</th><th style=""" & local!th & """>Waiting on</th><th style=""" & local!th & """>Why</th><th style=""" & local!th & """>Contact</th></tr>",
    local!rowsHtml,
    "</table></td></tr>",
    "<tr><td style=""height:12px;font-size:1px;line-height:12px;"">&nbsp;</td></tr>",
    "<tr><td style=""background:#16294D;color:#FFFFFF;padding:10px 18px;font-size:12px;font-style:italic;"">Sent daily to the draw approval team. The live list is the Draws page's Needs chasing view.</td></tr>",
    "</table></td></tr></table></div>"
  ),
  a!map(
    subject: local!subject,
    html: local!html,
    text: local!subject,
    count: local!n,
    bytes: len(local!html)
  )
)

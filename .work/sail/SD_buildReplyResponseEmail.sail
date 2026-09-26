/* Draw approval (Phase 6a): what the flow sends back on the reply thread, in the step email's visual language
   (navy band, plain table, inline styles). kind CLARIFICATION: the reply did not clearly approve or reject; ask for a
   clear answer, nothing changed. kind GUARDRAIL: the draw is above the email approval limit; the decision must be made
   in the system, nothing changed. Subject "Re: <step email subject>" (the token rides along), so the thread holds.
   Returns a map: subject, html, text (a short plain summary for the Approvals tab). */
a!localVariables(
  local!c: a!defaultValue(ri!context, a!map()),
  local!kind: upper(a!defaultValue(ri!kind, "")),
  local!name: a!defaultValue(index(local!c, "approverName", ""), ""),
  local!drawLabel: "Draw #" & a!defaultValue(index(local!c, "drawNumber", ""), "") & " · " & a!defaultValue(index(local!c, "investmentName", ""), ""),
  local!stepSubject: a!defaultValue(index(local!c, "stepSubject", ""), ""),
  local!subject: if(left(upper(local!stepSubject), 3) = "RE:", local!stepSubject, "Re: " & local!stepSubject),
  local!lead: if(
    local!kind = "GUARDRAIL",
    "Email approval is not available for this draw. Its amount, " & rule!SD_fmtMoney(value: index(local!c, "amount", 0), showCents: true) & ", is above the " & rule!SD_fmtMoney(value: cons!SD_EMAIL_APPROVAL_MAX, showCents: false) & " limit for decisions by email, so the decision must be made in the system. Your reply has not changed the draw.",
    "We could not tell from your reply whether you approve or reject this draw, so nothing has been changed. Please reply to this email with a clear decision, for example ""Approved"" or ""Rejected"", and add any comment you want recorded with it."
  ),
  local!quoted: rule!SD_htmlEscape(text: left(a!defaultValue(ri!replyText, ""), 600)),
  local!html:
    "<table role=""presentation"" width=""100%"" cellpadding=""0"" cellspacing=""0"" style=""max-width:640px;border-collapse:collapse;font-family:Arial,Helvetica,sans-serif;"">" &
    "<tr><td style=""background:#16294D;color:#FFFFFF;padding:12px 18px;font-size:15px;font-weight:bold;"">" & rule!SD_htmlEscape(text: local!drawLabel) & "</td></tr>" &
    "<tr><td style=""padding:14px 18px 6px 18px;font-size:13px;line-height:19px;color:#1F2937;"">Hello " & rule!SD_htmlEscape(text: if(local!name = "", "approver", local!name)) & ",</td></tr>" &
    "<tr><td style=""padding:6px 18px 10px 18px;font-size:13px;line-height:19px;color:#1F2937;"">" & rule!SD_htmlEscape(text: local!lead) & "</td></tr>" &
    if(local!quoted = "", "", "<tr><td style=""padding:4px 18px 12px 18px;""><table role=""presentation"" cellpadding=""0"" cellspacing=""0"" style=""border-left:3px solid #CBD5E1;""><tr><td style=""padding:4px 10px;font-size:12px;line-height:17px;color:#475569;font-style:italic;"">Your reply: " & local!quoted & "</td></tr></table></td></tr>") &
    "<tr><td style=""background:#16294D;color:#FFFFFF;padding:10px 18px;font-size:12px;font-style:italic;"">" & if(local!kind = "GUARDRAIL", "Open the draw in Starwood Draw Approvals to record your decision.", "Reply to this email to answer. Your reply is recorded on the draw.") & "</td></tr>" &
    "</table>",
  a!map(
    subject: local!subject,
    html: local!html,
    text: left(local!lead, 1000)
  )
)

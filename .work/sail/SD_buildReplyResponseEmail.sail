/* Draw approval (Phase 6a; Phase 6b adds ANSWER and RECEIPT): what the flow sends on the reply thread, in the step
   email's visual language (navy band, plain table, inline styles). Subject "Re: <step email subject>" (the token rides
   along), so the thread holds and the next reply still reaches the right draw and step.
     CLARIFICATION  the reply did not clearly approve or reject; ask for a clear answer; nothing changed
     GUARDRAIL      the draw is above the email approval limit; decide in the system; nothing changed
     ANSWER         the draw approval team's answer to the approver's question (answeredBy, questionText, answerText);
                    the approver can then decide, or ask again, by reply
     RECEIPT        a decision by email was applied (decision APPROVE / REJECT, outcome = the transition's outcome);
                    no action requested, no reply expected
   Returns a map: subject, html, text (the short plain text logged on the draw; for ANSWER the answer itself). */
a!localVariables(
  local!c: a!defaultValue(ri!context, a!map()),
  local!kind: upper(a!defaultValue(ri!kind, "")),
  local!name: a!defaultValue(index(local!c, "approverName", ""), ""),
  local!drawNo: a!defaultValue(index(local!c, "drawNumber", ""), ""),
  local!drawLabel: "Draw #" & local!drawNo & " · " & a!defaultValue(index(local!c, "investmentName", ""), ""),
  local!amount: rule!SD_fmtMoney(value: index(local!c, "amount", 0), showCents: true),
  local!stepSubject: a!defaultValue(index(local!c, "stepSubject", ""), ""),
  local!subject: if(left(upper(local!stepSubject), 3) = "RE:", local!stepSubject, "Re: " & local!stepSubject),
  local!isFinal: left(upper(a!defaultValue(ri!outcome, "")), 8) = "APPROVED",
  local!lead: a!match(
    value: local!kind,
    equals: "GUARDRAIL", then: "Email approval is not available for this draw. Its amount, " & local!amount & ", is above the " & rule!SD_fmtMoney(value: cons!SD_EMAIL_APPROVAL_MAX, showCents: false) & " limit for decisions by email, so the decision must be made in the system. Your reply has not changed the draw.",
    equals: "ANSWER", then: a!defaultValue(ri!answeredBy, "The draw approval team") & " answered your question on this draw.",
    equals: "RECEIPT", then: if(
      upper(a!defaultValue(ri!decision, "")) = "REJECT",
      "Recorded as your rejection of Draw #" & local!drawNo & ", " & local!amount & ". The draw will not proceed.",
      "Recorded as your approval of Draw #" & local!drawNo & ", " & local!amount & ". The chain has advanced." & if(local!isFinal, " This was the final approval.", "")
    ),
    default: "We could not tell from your reply whether you approve or reject this draw, so nothing has been changed. Please reply to this email with a clear decision, for example ""Approved"" or ""Rejected"", and add any comment you want recorded with it."
  ),
  local!quoted: rule!SD_htmlEscape(text: left(a!defaultValue(ri!replyText, ""), 600)),
  local!questionHtml: rule!SD_htmlEscape(text: left(a!defaultValue(ri!questionText, ""), 1000)),
  local!answerHtml: substitute(rule!SD_htmlEscape(text: a!defaultValue(ri!answerText, "")), char(10), "<br>"),
  local!quoteBlock: "<tr><td style=""padding:4px 18px 12px 18px;""><table role=""presentation"" cellpadding=""0"" cellspacing=""0"" style=""border-left:3px solid #CBD5E1;""><tr><td style=""padding:4px 10px;font-size:12px;line-height:17px;color:#475569;font-style:italic;"">",
  local!body: a!match(
    value: local!kind,
    equals: "ANSWER", then:
      if(local!questionHtml = "", "", local!quoteBlock & "Your question: " & local!questionHtml & "</td></tr></table></td></tr>") &
      "<tr><td style=""padding:4px 18px 14px 18px;font-size:13px;line-height:20px;color:#1F2937;"">" & local!answerHtml & "</td></tr>",
    equals: "RECEIPT", then: "",
    default: if(local!quoted = "", "", local!quoteBlock & "Your reply: " & local!quoted & "</td></tr></table></td></tr>")
  ),
  local!footer: a!match(
    value: local!kind,
    equals: "GUARDRAIL", then: "Open the draw in Starwood Draw Approvals to record your decision.",
    equals: "ANSWER", then: "Reply to this email to approve or reject, or to ask another question. Your reply is recorded on the draw.",
    equals: "RECEIPT", then: "No reply is needed.",
    default: "Reply to this email to answer. Your reply is recorded on the draw."
  ),
  local!html:
    "<table role=""presentation"" width=""100%"" cellpadding=""0"" cellspacing=""0"" style=""max-width:640px;border-collapse:collapse;font-family:Arial,Helvetica,sans-serif;"">" &
    "<tr><td style=""background:#16294D;color:#FFFFFF;padding:12px 18px;font-size:15px;font-weight:bold;"">" & rule!SD_htmlEscape(text: local!drawLabel) & "</td></tr>" &
    "<tr><td style=""padding:14px 18px 6px 18px;font-size:13px;line-height:19px;color:#1F2937;"">Hello " & rule!SD_htmlEscape(text: if(local!name = "", "approver", local!name)) & ",</td></tr>" &
    "<tr><td style=""padding:6px 18px 10px 18px;font-size:13px;line-height:19px;color:#1F2937;"">" & rule!SD_htmlEscape(text: local!lead) & "</td></tr>" &
    local!body &
    "<tr><td style=""background:#16294D;color:#FFFFFF;padding:10px 18px;font-size:12px;font-style:italic;"">" & local!footer & "</td></tr>" &
    "</table>",
  a!map(
    subject: local!subject,
    html: local!html,
    text: if(local!kind = "ANSWER", a!defaultValue(ri!answerText, ""), left(local!lead, 1000))
  )
)

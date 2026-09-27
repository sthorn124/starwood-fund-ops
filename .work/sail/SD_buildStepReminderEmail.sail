/* Draw approval (Phase 6c): the escalation reminder for a step that has waited. It is the step email itself
   (rule!SD_buildApprovalEmail, the draw as it stands now) under an amber banner saying how long the step has waited and
   when the draw funds. Subject "Reminder · Draw #<n> · funding in <d> days · awaiting your approval", ending with the
   reply token [SD-DRAW-<id>-S<step>] so a reply is read like any other. Sent, like the step email, to the step's group,
   from and reply-to the receiver address. Returns a map: subject, html, text (the line logged on the draw), bytes,
   daysWaiting, daysToFunding. */
a!localVariables(
  local!base: rule!SD_buildApprovalEmail(drawId: ri!drawId, stepOrder: ri!stepOrder),
  local!d: rule!SD_getDrawDetail(drawId: ri!drawId),
  local!drawNo: a!defaultValue(index(local!d, "drawNumber", null), ri!drawId),
  local!waiting: a!defaultValue(index(local!d, "daysAtStep", 0), 0),
  local!toFunding: index(local!d, "daysToFunding", null),
  local!fundingText: if(a!isNullOrEmpty(local!toFunding), "funding date not set", "funding " & rule!SD_fmtRelativeDays(days: local!toFunding)),
  local!overLimit: todecimal(a!defaultValue(index(local!d, "amount", 0), 0)) > todecimal(cons!SD_EMAIL_APPROVAL_MAX),
  local!subject: "Reminder · Draw #" & local!drawNo & " · " & local!fundingText & " · awaiting your approval [SD-DRAW-" & ri!drawId & "-S" & ri!stepOrder & "]",
  local!lead: "Reminder: this approval " & if(local!waiting < 1, "is still waiting", "has waited " & local!waiting & if(local!waiting = 1, " day", " days")) & " and the draw is " & local!fundingText & ". " &
    if(local!overLimit, "The approval request is repeated below; please record your decision in the system.", "The approval request is repeated below; reply to this email with your decision."),
  local!banner: "<tr><td style=""background:#FDF3E0;color:#92600A;padding:10px 18px;font-size:13px;line-height:18px;font-weight:bold;border-bottom:1px solid #F3D9A4;font-family:Arial,Helvetica,sans-serif;"">" & rule!SD_htmlEscape(text: local!lead) & "</td></tr>",
  local!anchor: "<tr><td style=""background:#16294D;color:#FFFFFF;padding:14px 18px 6px 18px;",
  local!html: substitute(tostring(index(local!base, "html", "")), local!anchor, local!banner & local!anchor),
  a!map(
    subject: local!subject,
    html: local!html,
    text: local!lead,
    bytes: len(local!html),
    daysWaiting: local!waiting,
    daysToFunding: local!toFunding
  )
)

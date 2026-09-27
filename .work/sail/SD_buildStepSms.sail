/* Draw approval (Phase 6c): the SMS rung's text for a step that has waited SD_SMS_AGE_DAYS. One short line, no link:
   "Draw #<n> · $<amount> · funding in <d> days · awaiting your approval · reply by email" (on a draw above the email
   limit the close is "decide in Starwood Draw Approvals"). Returns a map: text, length. */
a!localVariables(
  local!d: rule!SD_getDrawDetail(drawId: ri!drawId),
  local!drawNo: a!defaultValue(index(local!d, "drawNumber", null), ri!drawId),
  local!toFunding: index(local!d, "daysToFunding", null),
  local!overLimit: todecimal(a!defaultValue(index(local!d, "amount", 0), 0)) > todecimal(cons!SD_EMAIL_APPROVAL_MAX),
  local!text: "Draw #" & local!drawNo & " · " & rule!SD_fmtMoney(value: index(local!d, "amount", 0), showCents: false) & " · " &
    if(a!isNullOrEmpty(local!toFunding), "funding date not set", "funding " & rule!SD_fmtRelativeDays(days: local!toFunding)) &
    " · awaiting your approval · " & if(local!overLimit, "decide in Starwood Draw Approvals", "reply by email"),
  a!map(text: local!text, length: len(local!text))
)

/* Draw approval (Phase 6b): the draw's pending approver question, derived from the message log (no stored flag).
   A question is an INBOUND reply the gate read as QUESTION. The latest one is pending while no ANSWER has been sent
   after it (message ids only grow) and the step it was asked at is still the one awaiting a decision (a decision by
   email or by task ends it; the question stays on the thread). Returns a map: pending, messageId, approvalId, stepOrder,
   role, question, askedAt, fromAddress, approverAddress (the step role's authorized reply address, where an answer
   goes), unanswered (questions since the last answer), messageCount. */
a!localVariables(
  local!msgs: rule!SD_getDrawEmailMessages(drawId: ri!drawId),
  local!isQuestion: if(a!isNullOrEmpty(local!msgs), {}, a!forEach(items: local!msgs, expression: and(fv!item.direction = "INBOUND", fv!item.outcome = "QUESTION"))),
  local!isAnswer: if(a!isNullOrEmpty(local!msgs), {}, a!forEach(items: local!msgs, expression: fv!item.kind = "ANSWER")),
  local!qPos: if(a!isNullOrEmpty(local!isQuestion), {}, where(local!isQuestion)),
  local!aPos: if(a!isNullOrEmpty(local!isAnswer), {}, where(local!isAnswer)),
  local!last: if(a!isNullOrEmpty(local!qPos), null, index(local!msgs, index(local!qPos, count(local!qPos), null), null)),
  local!lastAnswerId: if(a!isNullOrEmpty(local!aPos), 0, max(a!forEach(items: local!aPos, expression: tointeger(index(local!msgs, fv!item, null).id)))),
  local!unanswered: if(a!isNullOrEmpty(local!qPos), 0, sum(a!forEach(items: local!qPos, expression: if(tointeger(index(local!msgs, fv!item, null).id) > local!lastAnswerId, 1, 0)))),
  local!state: if(a!isNullOrEmpty(local!last), null, rule!SD_getDrawState(ri!drawId)),
  local!current: if(a!isNullOrEmpty(local!state), null, index(local!state, "current", null)),
  local!awaiting: and(
    not(a!isNullOrEmpty(local!last)),
    not(a!isNullOrEmpty(local!current)),
    tostring(a!defaultValue(index(local!state, "drawStatus", ""), "")) = "In Progress",
    tointeger(a!defaultValue(index(local!state, "currentStep", -1), -1)) = tointeger(a!defaultValue(index(local!last, "stepOrder", -2), -2)),
    tostring(a!defaultValue(index(local!current, "status", ""), "")) = "In Progress"
  ),
  local!answered: and(not(a!isNullOrEmpty(local!last)), local!lastAnswerId > tointeger(a!defaultValue(index(local!last, "id", 0), 0))),
  local!role: if(a!isNullOrEmpty(local!current), "", tostring(a!defaultValue(index(local!current, "role", ""), ""))),
  local!roleIndex: if(local!role = "", {}, wherecontains(local!role, cons!SD_EMAIL_REPLY_ROLES)),
  a!map(
    pending: and(local!awaiting, not(local!answered)),
    messageId: if(a!isNullOrEmpty(local!last), null, index(local!last, "id", null)),
    approvalId: if(a!isNullOrEmpty(local!last), null, index(local!last, "approvalId", null)),
    stepOrder: if(a!isNullOrEmpty(local!last), null, index(local!last, "stepOrder", null)),
    role: local!role,
    question: if(
      a!isNullOrEmpty(local!last),
      "",
      if(a!defaultValue(index(local!last, "decisivePhrase", ""), "") = "", a!defaultValue(index(local!last, "body", ""), ""), index(local!last, "decisivePhrase", ""))
    ),
    askedAt: if(a!isNullOrEmpty(local!last), null, index(local!last, "messageAt", null)),
    fromAddress: if(a!isNullOrEmpty(local!last), "", a!defaultValue(index(local!last, "fromAddress", ""), "")),
    approverAddress: if(a!isNullOrEmpty(local!roleIndex), "", tostring(index(cons!SD_EMAIL_REPLY_ADDRESSES, local!roleIndex[1], ""))),
    unanswered: local!unanswered,
    messageCount: count(local!msgs)
  )
)

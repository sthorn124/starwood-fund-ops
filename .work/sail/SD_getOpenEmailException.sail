/* Draw approval (Phase 6c): the draw's open email-exception review, derived from the message log (no stored flag).
   An exception is an INBOUND reply logged with outcome EXCEPTION (the handler's node 60 sends it to the "Review email reply"
   task for SD Draw Demo Approvers); a review is the INTERNAL EXCEPTION_REVIEW row the task writes when it is completed
   (node 62). The latest exception is open while no review has been logged after it (message ids only grow). From Phase 6c
   the exception row carries the handler's process id, so the open task is found through the platform's "Current Tasks
   for Process" report (rule!SD_getOpenTaskId) when withTask is true; rows written before 6c have no process id and show
   the state without a task link. Returns a map: open, messageId, stepOrder, replyText, reason, receivedAt, fromAddress,
   senderName, processId, taskId, unreviewed (exceptions since the last review). */
a!localVariables(
  local!msgs: rule!SD_getDrawEmailMessages(drawId: ri!drawId),
  local!isExc: if(a!isNullOrEmpty(local!msgs), {}, a!forEach(items: local!msgs, expression: and(fv!item.direction = "INBOUND", fv!item.outcome = "EXCEPTION"))),
  local!isRev: if(a!isNullOrEmpty(local!msgs), {}, a!forEach(items: local!msgs, expression: fv!item.kind = "EXCEPTION_REVIEW")),
  local!ePos: if(a!isNullOrEmpty(local!isExc), {}, where(local!isExc)),
  local!rPos: if(a!isNullOrEmpty(local!isRev), {}, where(local!isRev)),
  local!last: if(a!isNullOrEmpty(local!ePos), null, index(local!msgs, index(local!ePos, count(local!ePos), null), null)),
  local!lastReviewId: if(a!isNullOrEmpty(local!rPos), 0, max(a!forEach(items: local!rPos, expression: tointeger(index(local!msgs, fv!item, null).id)))),
  local!unreviewed: if(a!isNullOrEmpty(local!ePos), 0, sum(a!forEach(items: local!ePos, expression: if(tointeger(index(local!msgs, fv!item, null).id) > local!lastReviewId, 1, 0)))),
  local!open: and(not(a!isNullOrEmpty(local!last)), local!unreviewed > 0),
  local!processId: if(local!open, index(local!last, "processId", null), null),
  local!taskId: if(
    and(local!open, a!defaultValue(ri!withTask, false), not(a!isNullOrEmpty(local!processId))),
    rule!SD_getOpenTaskId(processId: tointeger(local!processId)),
    null
  ),
  local!notes: if(local!open, tostring(a!defaultValue(index(local!last, "notes", ""), "")), ""),
  local!cut: if(local!notes = "", 0, search(" Sent to the exception queue", local!notes)),
  a!map(
    open: local!open,
    messageId: if(local!open, index(local!last, "id", null), null),
    stepOrder: if(local!open, index(local!last, "stepOrder", null), null),
    replyText: if(local!open, tostring(a!defaultValue(index(local!last, "body", ""), "")), ""),
    reason: if(local!cut > 1, left(local!notes, local!cut - 1), local!notes),
    receivedAt: if(local!open, index(local!last, "messageAt", null), null),
    fromAddress: if(local!open, tostring(a!defaultValue(index(local!last, "fromAddress", ""), "")), ""),
    senderName: if(local!open, tostring(a!defaultValue(index(local!last, "senderName", ""), "")), ""),
    processId: local!processId,
    taskId: local!taskId,
    unreviewed: local!unreviewed
  )
)

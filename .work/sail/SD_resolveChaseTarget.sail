/* Draw approval (Phase 6c): what an escalation of a step task is about. The step task's escalations send a
   process-to-process message to SD Chase Approval Step with no custom properties, so the only thing the chase process
   receives is msg!properties.OriginProcessID: the SD Draw Approval Step process that escalated. That process registers
   itself on its draw (SD Draw.activeStepProcessId), so the draw is the one whose activeStepProcessId is that id; the step
   is the draw's current step. The rung comes from the log, not from the message: no reminder logged yet for this
   approval row means level 1 (REMINDER), otherwise level 2 (SMS). found is false when no draw holds that process (the
   step was decided and the next step registered, so nothing is chased). */
a!localVariables(
  local!rows: if(
    a!isNullOrEmpty(ri!originProcessId),
    {},
    a!queryRecordType(
      recordType: 'recordType!{c9d3a947-71aa-4024-879e-363873a12860}SD Draw',
      fields: {'recordType!{c9d3a947-71aa-4024-879e-363873a12860}SD Draw.fields.{443829ca-5971-4d31-8fac-ab7a317e509b}id'},
      filters: a!queryFilter(field: 'recordType!{c9d3a947-71aa-4024-879e-363873a12860}SD Draw.fields.{a132be23-f941-4d59-a22c-b57e29900ea6}activeStepProcessId', operator: "=", value: tointeger(ri!originProcessId)),
      pagingInfo: a!pagingInfo(startIndex: 1, batchSize: 1)
    ).data
  ),
  local!drawId: if(a!isNullOrEmpty(local!rows), null, tointeger(index(index(local!rows, 1, null), 'recordType!{c9d3a947-71aa-4024-879e-363873a12860}SD Draw.fields.{443829ca-5971-4d31-8fac-ab7a317e509b}id', null))),
  local!state: if(a!isNullOrEmpty(local!drawId), null, rule!SD_getDrawState(local!drawId)),
  local!current: if(a!isNullOrEmpty(local!state), null, index(local!state, "current", null)),
  local!approvalId: if(a!isNullOrEmpty(local!current), null, tointeger(index(local!current, "id", null))),
  local!msgs: if(a!isNullOrEmpty(local!drawId), {}, rule!SD_getDrawEmailMessages(drawId: local!drawId)),
  local!reminded: if(
    or(a!isNullOrEmpty(local!msgs), a!isNullOrEmpty(local!approvalId)),
    false,
    contains(
      a!forEach(
        items: local!msgs,
        expression: and(fv!item.kind = "REMINDER", tointeger(a!defaultValue(fv!item.approvalId, 0)) = local!approvalId)
      ),
      true
    )
  ),
  a!map(
    found: not(a!isNullOrEmpty(local!drawId)),
    drawId: local!drawId,
    stepOrder: if(a!isNullOrEmpty(local!state), null, tointeger(index(local!state, "currentStep", null))),
    approvalId: local!approvalId,
    rung: if(local!reminded, "SMS", "REMINDER")
  )
)

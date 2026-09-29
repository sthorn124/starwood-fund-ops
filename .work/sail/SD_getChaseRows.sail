/* Draw approval (Phase 6c): the "Needs chasing" rows — the one query behind the Draws page's Needs chasing view and the
   daily chase digest. A draw is listed when its current approval step has waited SD_CHASE_AGE_DAYS or more (days since
   the step was activated, from today), or when an email reply on it is waiting for the draw approval team's review
   (an open exception with its review task still open; fix 2026-09-28), or — second fix session 2026-09-28 — when a
   reminder or a text has been logged at its current step, whatever its age (a manual "Send reminder now" lists the
   step at once; its Why reads e.g. "Reminder sent today · text staged"). Aging rows read as before ("Step 6 waiting
   9 days", with the last chase beneath). Ranked by amount, largest first, then by days to funding, soonest first: the money at stake
   before the calendar. Each row says who is sitting on what: the step's role and named approver, the group the task
   is assigned to, the role's authorized email address (SD_EMAIL_REPLY_ADDRESSES) and when the step was last chased
   (the latest REMINDER or SMS logged at that step). ri!rows takes the Draws page's rows (rule!SD_getDrawListRows) so
   the page does not read twice; empty, the rule reads them itself. */
a!localVariables(
  local!all: if(a!isNullOrEmpty(ri!rows), rule!SD_getDrawListRows(), ri!rows),
  local!threshold: tointeger(cons!SD_CHASE_AGE_DAYS),
  /* every REMINDER and SMS row, read once (oldest first); a draw's chases at its current step are picked from here */
  local!chaseMsgs: a!forEach(
    items: a!queryRecordType(
      recordType: 'recordType!{3686a81f-86e2-498e-a4d1-ce40236c824a}SD Draw Email Message',
      fields: {'recordType!{3686a81f-86e2-498e-a4d1-ce40236c824a}SD Draw Email Message.fields.{163bd929-1a5c-4862-a6b4-e64a7af2e463}drawId', 'recordType!{3686a81f-86e2-498e-a4d1-ce40236c824a}SD Draw Email Message.fields.{eec43b21-b977-4527-9343-f4a9f0b2b915}stepOrder', 'recordType!{3686a81f-86e2-498e-a4d1-ce40236c824a}SD Draw Email Message.fields.{e12b21b7-9fcd-4f26-9371-74db2e074a1c}kind', 'recordType!{3686a81f-86e2-498e-a4d1-ce40236c824a}SD Draw Email Message.fields.{ae349a0e-1ad6-4f39-ab7f-f531937147d1}outcome', 'recordType!{3686a81f-86e2-498e-a4d1-ce40236c824a}SD Draw Email Message.fields.{13756bd6-152a-4c93-aba0-84269d1d5ade}messageAt'},
      filters: a!queryFilter(field: 'recordType!{3686a81f-86e2-498e-a4d1-ce40236c824a}SD Draw Email Message.fields.{e12b21b7-9fcd-4f26-9371-74db2e074a1c}kind', operator: "in", value: {"REMINDER", "SMS"}),
      pagingInfo: a!pagingInfo(startIndex: 1, batchSize: 1000, sort: a!sortInfo(field: 'recordType!{3686a81f-86e2-498e-a4d1-ce40236c824a}SD Draw Email Message.fields.{13756bd6-152a-4c93-aba0-84269d1d5ade}messageAt', ascending: true))
    ).data,
    expression: a!map(
      drawId: tointeger(fv!item['recordType!{3686a81f-86e2-498e-a4d1-ce40236c824a}SD Draw Email Message.fields.{163bd929-1a5c-4862-a6b4-e64a7af2e463}drawId']),
      stepOrder: tointeger(a!defaultValue(fv!item['recordType!{3686a81f-86e2-498e-a4d1-ce40236c824a}SD Draw Email Message.fields.{eec43b21-b977-4527-9343-f4a9f0b2b915}stepOrder'], 0)),
      kind: tostring(fv!item['recordType!{3686a81f-86e2-498e-a4d1-ce40236c824a}SD Draw Email Message.fields.{e12b21b7-9fcd-4f26-9371-74db2e074a1c}kind']),
      outcome: tostring(a!defaultValue(fv!item['recordType!{3686a81f-86e2-498e-a4d1-ce40236c824a}SD Draw Email Message.fields.{ae349a0e-1ad6-4f39-ab7f-f531937147d1}outcome'], "")),
      messageAt: fv!item['recordType!{3686a81f-86e2-498e-a4d1-ce40236c824a}SD Draw Email Message.fields.{13756bd6-152a-4c93-aba0-84269d1d5ade}messageAt']
    )
  ),
  local!chaseKeys: if(
    a!isNullOrEmpty(local!chaseMsgs),
    {},
    a!forEach(items: local!chaseMsgs, expression: fv!item.drawId & ":" & fv!item.stepOrder)
  ),
  local!flags: if(
    a!isNullOrEmpty(local!all),
    {},
    a!forEach(
      items: local!all,
      expression: or(
        and(a!defaultValue(fv!item.inProgress, false), a!defaultValue(fv!item.daysAtStep, 0) >= local!threshold),
        /* second fix session 2026-09-28: a step already chased is listed whatever its age */
        and(
          a!defaultValue(fv!item.inProgress, false),
          not(a!isNullOrEmpty(local!chaseKeys)),
          contains(local!chaseKeys, tointeger(fv!item.id) & ":" & tointeger(a!defaultValue(fv!item.currentStep, 0)))
        ),
        /* fix 2026-09-28: an email reply counts only while its review task is open (as on the Summary) */
        and(a!defaultValue(fv!item.exceptionOpen, false), not(a!isNullOrEmpty(fv!item.exceptionTaskId)))
      )
    )
  ),
  local!picked: if(a!isNullOrEmpty(local!flags), {}, index(local!all, wherecontains(true, local!flags), {})),
  local!mapped: if(
    a!isNullOrEmpty(local!picked),
    {},
    a!forEach(
      items: local!picked,
      expression: a!localVariables(
        local!inProgress: a!defaultValue(fv!item.inProgress, false),
        local!role: if(local!inProgress, tostring(a!defaultValue(fv!item.currentRole, "")), ""),
        local!roleIdx: if(local!role = "", {}, wherecontains(local!role, cons!SD_EMAIL_REPLY_ROLES)),
        local!group: if(local!role = "", null, rule!SD_getDrawApprovalGroup(role: local!role)),
        local!aging: and(local!inProgress, a!defaultValue(fv!item.daysAtStep, 0) >= local!threshold),
        local!exception: and(a!defaultValue(fv!item.exceptionOpen, false), not(a!isNullOrEmpty(fv!item.exceptionTaskId))),
        local!step: tointeger(a!defaultValue(fv!item.currentStep, 0)),
        local!key: tointeger(fv!item.id) & ":" & local!step,
        local!chases: if(
          or(not(local!inProgress), a!isNullOrEmpty(local!chaseKeys)),
          {},
          index(local!chaseMsgs, wherecontains(local!key, local!chaseKeys), {})
        ),
        local!lastChase: if(a!isNullOrEmpty(local!chases), null, index(local!chases, count(local!chases), null)),
        /* the latest reminder and the latest text at this step, and the day each went ("today", "yesterday", "Sep 28") */
        local!rems: if(a!isNullOrEmpty(local!chases), {}, index(local!chases, wherecontains("REMINDER", a!forEach(items: local!chases, expression: fv!item.kind)), {})),
        local!smss: if(a!isNullOrEmpty(local!chases), {}, index(local!chases, wherecontains("SMS", a!forEach(items: local!chases, expression: fv!item.kind)), {})),
        local!rem: if(a!isNullOrEmpty(local!rems), null, index(local!rems, count(local!rems), null)),
        local!sms: if(a!isNullOrEmpty(local!smss), null, index(local!smss, count(local!smss), null)),
        local!remDay: if(
          a!isNullOrEmpty(local!rem),
          "",
          a!localVariables(
            local!d: text(local!rem.messageAt, "yyyymmdd"),
            if(local!d = text(now(), "yyyymmdd"), "today", if(local!d = text(now() - 1, "yyyymmdd"), "yesterday", text(local!rem.messageAt, "MMM D")))
          )
        ),
        local!smsDay: if(
          a!isNullOrEmpty(local!sms),
          "",
          a!localVariables(
            local!d: text(local!sms.messageAt, "yyyymmdd"),
            if(local!d = text(now(), "yyyymmdd"), "today", if(local!d = text(now() - 1, "yyyymmdd"), "yesterday", text(local!sms.messageAt, "MMM D")))
          )
        ),
        local!smsWord: if(a!isNullOrEmpty(local!sms), "", displayvalue(local!sms.outcome, {"STAGED", "FAILED"}, {"staged", "failed"}, "sent")),
        local!chaseSummary: if(
          a!isNullOrEmpty(local!chases),
          "",
          if(
            a!isNullOrEmpty(local!rem),
            "Text " & local!smsWord & " " & local!smsDay,
            "Reminder " & if(local!rem.outcome = "FAILED", "failed", "sent") & " " & local!remDay &
            if(a!isNullOrEmpty(local!sms), "", " · text " & local!smsWord & if(local!smsDay = local!remDay, "", " " & local!smsDay))
          )
        ),
        a!map(
          drawId: fv!item.id,
          drawNumber: fv!item.drawNumber,
          investmentName: a!defaultValue(fv!item.investmentName, ""),
          amount: todecimal(a!defaultValue(fv!item.amount, 0)),
          fundingDate: fv!item.fundingDate,
          daysToFunding: a!defaultValue(fv!item.daysToFunding, 99999),
          status: tostring(a!defaultValue(fv!item.status, "")),
          currentStep: local!step,
          totalSteps: a!defaultValue(fv!item.totalSteps, 9),
          role: local!role,
          approverName: if(local!inProgress, a!defaultValue(fv!item.currentApprover, ""), ""),
          /* the step group's name from the three step-group constants: group() needs view rights on the group, which
             a persona may not have (measured: "Insufficient permission" rendering the Draws page as sd.accountant) */
          groupName: if(
            a!isNullOrEmpty(local!group),
            "",
            displayvalue(
              tointeger(local!group),
              {tointeger(cons!SD_DRAW_ASSET_MANAGER_GROUP), tointeger(cons!SD_DRAW_CEO_GROUP), tointeger(cons!SD_DRAW_DEMO_APPROVERS_GROUP)},
              {"SD Draw Asset Managers", "SD Draw CEO", "SD Draw Demo Approvers"},
              "the step's group"
            )
          ),
          contact: if(a!isNullOrEmpty(local!roleIdx), "", tostring(index(cons!SD_EMAIL_REPLY_ADDRESSES, local!roleIdx[1], ""))),
          daysAtStep: if(local!inProgress, a!defaultValue(fv!item.daysAtStep, 0), null),
          aging: local!aging,
          smsDue: and(local!aging, a!defaultValue(fv!item.daysAtStep, 0) >= tointeger(cons!SD_SMS_AGE_DAYS)),
          exceptionOpen: local!exception,
          reason: if(
            local!aging,
            "Step " & local!step & " waiting " & fv!item.daysAtStep & " days" & if(local!exception, " · email reply to review", ""),
            if(
              local!chaseSummary <> "",
              local!chaseSummary & if(local!exception, " · email reply to review", ""),
              "Email reply to review"
            )
          ),
          /* what the last chase did, as a phrase: a staged or failed text never reads as sent */
          /* a chased-only row states its chases in the reason, so the last-chase line is kept for aging rows */
          lastChaseLabel: if(
            or(a!isNullOrEmpty(local!lastChase), not(local!aging)),
            "",
            if(index(local!lastChase, "kind", "") = "SMS", "Text", "Reminder") & " " &
            displayvalue(tostring(index(local!lastChase, "outcome", "")), {"STAGED", "FAILED"}, {"staged, not sent", "failed"}, "sent")
          ),
          lastChaseAt: if(a!isNullOrEmpty(local!lastChase), null, index(local!lastChase, "messageAt", null))
        )
      )
    )
  ),
  if(
    a!isNullOrEmpty(local!mapped),
    {},
    todatasubset(
      local!mapped,
      a!pagingInfo(startIndex: 1, batchSize: -1, sort: {a!sortInfo(field: "amount", ascending: false), a!sortInfo(field: "daysToFunding", ascending: true)})
    ).data
  )
)

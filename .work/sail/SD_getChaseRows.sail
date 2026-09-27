/* Draw approval (Phase 6c): the "Needs chasing" rows — the one query behind the Draws page's Needs chasing view and the
   daily chase digest. A draw is listed when its current approval step has waited SD_CHASE_AGE_DAYS or more (days since
   the step was activated, from today), or when an email reply on it is waiting for the draw approval team's review
   (an open exception). Ranked by amount, largest first, then by days to funding, soonest first: the money at stake
   before the calendar. Each row says who is sitting on what: the step's role and named approver, the group the task
   is assigned to, the role's authorized email address (SD_EMAIL_REPLY_ADDRESSES) and when the step was last chased
   (the latest REMINDER or SMS logged at that step). ri!rows takes the Draws page's rows (rule!SD_getDrawListRows) so
   the page does not read twice; empty, the rule reads them itself. */
a!localVariables(
  local!all: if(a!isNullOrEmpty(ri!rows), rule!SD_getDrawListRows(), ri!rows),
  local!threshold: tointeger(cons!SD_CHASE_AGE_DAYS),
  local!flags: if(
    a!isNullOrEmpty(local!all),
    {},
    a!forEach(
      items: local!all,
      expression: or(
        and(a!defaultValue(fv!item.inProgress, false), a!defaultValue(fv!item.daysAtStep, 0) >= local!threshold),
        a!defaultValue(fv!item.exceptionOpen, false)
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
        local!exception: a!defaultValue(fv!item.exceptionOpen, false),
        local!step: tointeger(a!defaultValue(fv!item.currentStep, 0)),
        local!chases: a!localVariables(
          local!msgs: rule!SD_getDrawEmailMessages(drawId: fv!item.id),
          if(
            a!isNullOrEmpty(local!msgs),
            {},
            index(
              local!msgs,
              wherecontains(
                true,
                a!forEach(items: local!msgs, expression: and(or(fv!item.kind = "REMINDER", fv!item.kind = "SMS"), tointeger(a!defaultValue(fv!item.stepOrder, 0)) = local!step))
              ),
              {}
            )
          )
        ),
        local!lastChase: if(a!isNullOrEmpty(local!chases), null, index(local!chases, count(local!chases), null)),
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
            "Email reply to review"
          ),
          /* what the last chase did, as a phrase: a staged or failed text never reads as sent */
          lastChaseLabel: if(
            a!isNullOrEmpty(local!lastChase),
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

/* Draw approval (Phase 6a): everything the reply handler decides before any AI call, from the records at the time
   of the reply. Checks run in this order, and the first that fails names the verdict:
     UNMATCHED     no token, or the token names a draw or step that does not exist
     UNAUTHORIZED  the sender is not the authorized reply address for the step's role (SD_EMAIL_REPLY_ROLES /
                   SD_EMAIL_REPLY_ADDRESSES); no reply is ever sent to an unauthorized sender
     GUARDRAIL     the draw amount is above SD_EMAIL_APPROVAL_MAX: email cannot decide it at any step
     NOT_AWAITING  the draw is not In Progress at this step, or the step's row is not In Progress
     OK            the reply may be interpreted
   Also returns the approval row id, role, approver name, draw number, investment, amount, the number of earlier
   ambiguous replies on this approval row (a second one goes to the exception queue) and the step email's subject
   (for "Re:" on anything sent back). */
a!localVariables(
  local!state: if(a!isNullOrEmpty(ri!drawId), null, rule!SD_getDrawState(ri!drawId)),
  local!found: and(not(a!isNullOrEmpty(local!state)), a!defaultValue(index(local!state, "found", false), false)),
  local!rows: if(
    or(not(local!found), a!isNullOrEmpty(ri!stepOrder)),
    {},
    a!queryRecordType(
      recordType: 'recordType!{02c207d5-c725-4d11-bf40-b33573e87ffa}SD Draw Approval',
      fields: {'recordType!{02c207d5-c725-4d11-bf40-b33573e87ffa}SD Draw Approval.fields.{69abcdf2-55da-48dc-8cc4-794b5d5e0042}id', 'recordType!{02c207d5-c725-4d11-bf40-b33573e87ffa}SD Draw Approval.fields.{44b8ee63-1230-4abd-ae83-ca2cddf182b6}approvalOrder', 'recordType!{02c207d5-c725-4d11-bf40-b33573e87ffa}SD Draw Approval.fields.{30524217-4621-4b41-9af4-490d2f082bdd}role', 'recordType!{02c207d5-c725-4d11-bf40-b33573e87ffa}SD Draw Approval.fields.{983be1c0-67e4-464f-b7c2-1e3a1c735458}approverName', 'recordType!{02c207d5-c725-4d11-bf40-b33573e87ffa}SD Draw Approval.fields.{4c1bf7fb-0736-4c9a-946e-99f6989ac83a}status'},
      filters: {
        a!queryFilter(field: 'recordType!{02c207d5-c725-4d11-bf40-b33573e87ffa}SD Draw Approval.fields.{5dacd7ec-3f3f-4645-9d08-684793b0b54b}drawId', operator: "=", value: ri!drawId),
        a!queryFilter(field: 'recordType!{02c207d5-c725-4d11-bf40-b33573e87ffa}SD Draw Approval.fields.{44b8ee63-1230-4abd-ae83-ca2cddf182b6}approvalOrder', operator: "=", value: ri!stepOrder)
      },
      pagingInfo: a!pagingInfo(startIndex: 1, batchSize: 5)
    ).data
  ),
  local!row: if(a!isNullOrEmpty(local!rows), null, index(local!rows, 1, null)),
  local!approvalId: if(a!isNullOrEmpty(local!row), null, local!row['recordType!{02c207d5-c725-4d11-bf40-b33573e87ffa}SD Draw Approval.fields.{69abcdf2-55da-48dc-8cc4-794b5d5e0042}id']),
  local!role: if(a!isNullOrEmpty(local!row), "", tostring(local!row['recordType!{02c207d5-c725-4d11-bf40-b33573e87ffa}SD Draw Approval.fields.{30524217-4621-4b41-9af4-490d2f082bdd}role'])),
  local!approverName: if(a!isNullOrEmpty(local!row), "", tostring(local!row['recordType!{02c207d5-c725-4d11-bf40-b33573e87ffa}SD Draw Approval.fields.{983be1c0-67e4-464f-b7c2-1e3a1c735458}approverName'])),
  local!rowStatus: if(a!isNullOrEmpty(local!row), "", tostring(local!row['recordType!{02c207d5-c725-4d11-bf40-b33573e87ffa}SD Draw Approval.fields.{4c1bf7fb-0736-4c9a-946e-99f6989ac83a}status'])),
  local!from: lower(trim(a!defaultValue(ri!fromAddress, ""))),
  local!roleIndex: if(local!role = "", {}, wherecontains(local!role, cons!SD_EMAIL_REPLY_ROLES)),
  local!authorizedAddress: if(a!isNullOrEmpty(local!roleIndex), "", lower(trim(index(cons!SD_EMAIL_REPLY_ADDRESSES, local!roleIndex[1], "")))),
  local!authorized: and(local!authorizedAddress <> "", local!from = local!authorizedAddress),
  local!amount: if(local!found, todecimal(a!defaultValue(index(local!state, "amount", 0), 0)), 0),
  local!overLimit: local!amount > todecimal(cons!SD_EMAIL_APPROVAL_MAX),
  local!drawStatus: if(local!found, tostring(a!defaultValue(index(local!state, "drawStatus", ""), "")), ""),
  local!currentStep: if(local!found, tointeger(a!defaultValue(index(local!state, "currentStep", -1), -1)), -1),
  local!awaiting: and(local!drawStatus = "In Progress", local!currentStep = tointeger(ri!stepOrder), local!rowStatus = "In Progress"),
  local!priorAmbiguous: if(
    a!isNullOrEmpty(local!approvalId),
    0,
    a!queryRecordType(
      recordType: 'recordType!{3686a81f-86e2-498e-a4d1-ce40236c824a}SD Draw Email Message',
      fields: {'recordType!{3686a81f-86e2-498e-a4d1-ce40236c824a}SD Draw Email Message.fields.{7d692543-d14a-44a7-b2eb-2aba819cea1f}id'},
      filters: {
        a!queryFilter(field: 'recordType!{3686a81f-86e2-498e-a4d1-ce40236c824a}SD Draw Email Message.fields.{2bc241c2-0f50-4ca7-aad2-5f2065c28e3e}approvalId', operator: "=", value: local!approvalId),
        a!queryFilter(field: 'recordType!{3686a81f-86e2-498e-a4d1-ce40236c824a}SD Draw Email Message.fields.{7bc67c6f-53fd-4bd1-99a1-0748c73ae443}direction', operator: "=", value: "INBOUND"),
        a!queryFilter(field: 'recordType!{3686a81f-86e2-498e-a4d1-ce40236c824a}SD Draw Email Message.fields.{ae349a0e-1ad6-4f39-ab7f-f531937147d1}outcome', operator: "=", value: "AMBIGUOUS")
      },
      pagingInfo: a!pagingInfo(startIndex: 1, batchSize: 1),
      fetchTotalCount: true
    ).totalCount
  ),
  local!verdict: if(
    or(not(local!found), a!isNullOrEmpty(local!row)),
    "UNMATCHED",
    if(not(local!authorized), "UNAUTHORIZED", if(local!overLimit, "GUARDRAIL", if(not(local!awaiting), "NOT_AWAITING", "OK")))
  ),
  a!map(
    verdict: local!verdict,
    reason: a!match(
      value: local!verdict,
      equals: "UNMATCHED", then: if(a!isNullOrEmpty(ri!drawId), "No draw reference token in the subject.", "The subject names draw " & ri!drawId & " step " & a!defaultValue(ri!stepOrder, "?") & ", which does not exist."),
      equals: "UNAUTHORIZED", then: "Sender " & a!defaultValue(ri!fromAddress, "(none)") & " is not the authorized reply address for the " & local!role & " step.",
      equals: "GUARDRAIL", then: "Draw amount " & rule!SD_fmtMoney(value: local!amount, showCents: true) & " is above the email approval limit of " & rule!SD_fmtMoney(value: cons!SD_EMAIL_APPROVAL_MAX, showCents: false) & ".",
      equals: "NOT_AWAITING", then: "The draw is " & local!drawStatus & " at step " & local!currentStep & "; step " & ri!stepOrder & " (" & local!role & ") is " & if(local!rowStatus = "", "not active", local!rowStatus) & ".",
      default: "Awaiting the " & local!role & " decision."
    ),
    drawId: ri!drawId,
    stepOrder: ri!stepOrder,
    approvalId: local!approvalId,
    role: local!role,
    approverName: local!approverName,
    drawNumber: if(local!found, index(local!state, "drawNumber", null), null),
    investmentName: if(local!found, tostring(a!defaultValue(index(local!state, "investmentName", ""), "")), ""),
    amount: local!amount,
    drawStatus: local!drawStatus,
    currentStep: local!currentStep,
    authorized: local!authorized,
    overLimit: local!overLimit,
    awaiting: local!awaiting,
    priorAmbiguous: local!priorAmbiguous,
    stepSubject: if(or(not(local!found), a!isNullOrEmpty(ri!stepOrder)), "", index(rule!SD_buildApprovalEmail(drawId: ri!drawId, stepOrder: ri!stepOrder), "subject", ""))
  )
)

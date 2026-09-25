/* Draw approval: everything a draw view or list row needs about one draw, in one read.
   Header fields, investment and fund names, the routing state (rule!SD_getDrawState), the viewer's
   relationship to the current step (viewerIsAssignee: in the step's group; awaitingViewer: and a task is
   open for it, which is what "Awaiting My Action" and the action strip mean), and the day counts the mockups show as "in N days" / "N days".
   Day counts are computed from today() and clamp at 0; nothing here is hard-coded to the demo dates. */
a!localVariables(
  local!hasId: not(a!isNullOrEmpty(ri!drawId)),
  local!draw: if(
    not(local!hasId),
    null,
    index(
      a!queryRecordType(
        recordType: 'recordType!{c9d3a947-71aa-4024-879e-363873a12860}SD Draw',
        fields: {
          'recordType!{c9d3a947-71aa-4024-879e-363873a12860}SD Draw.fields.{443829ca-5971-4d31-8fac-ab7a317e509b}id',
          'recordType!{c9d3a947-71aa-4024-879e-363873a12860}SD Draw.fields.{9aa1030b-f76b-49aa-bef6-99eb90327804}drawNumber',
          'recordType!{c9d3a947-71aa-4024-879e-363873a12860}SD Draw.fields.{58586ee5-5a93-4670-a8ee-cd1c88cdb903}amount',
          'recordType!{c9d3a947-71aa-4024-879e-363873a12860}SD Draw.fields.{4cf33493-ff2d-4c80-a647-869913a054ee}cashEquityNeeded',
          'recordType!{c9d3a947-71aa-4024-879e-363873a12860}SD Draw.fields.{d3bf793a-2b28-4d8c-81d4-8b05cb63f5a6}fundingDate',
          'recordType!{c9d3a947-71aa-4024-879e-363873a12860}SD Draw.fields.{5e39494a-0995-4196-828b-ab809cf187db}drawType',
          'recordType!{c9d3a947-71aa-4024-879e-363873a12860}SD Draw.fields.{0420a7a0-6645-4d31-9c0b-4c19ff7d88da}purpose',
          'recordType!{c9d3a947-71aa-4024-879e-363873a12860}SD Draw.fields.{23929877-d10e-4cff-a967-6bb3b0f61eac}budgetStatus',
          'recordType!{c9d3a947-71aa-4024-879e-363873a12860}SD Draw.fields.{d05fa5d6-60fa-4e20-be49-1ce42ff1e7d9}overBudgetReason',
          'recordType!{c9d3a947-71aa-4024-879e-363873a12860}SD Draw.fields.{c9513036-39a7-4877-9e18-852a36d7dc23}generalComments',
          'recordType!{c9d3a947-71aa-4024-879e-363873a12860}SD Draw.fields.{3a000d1d-0179-488f-87a9-1dc3b87ec048}contingencyExplanation',
          'recordType!{c9d3a947-71aa-4024-879e-363873a12860}SD Draw.fields.{e63818ec-ea02-40a0-bfdd-2c14b760dc2c}status',
          'recordType!{c9d3a947-71aa-4024-879e-363873a12860}SD Draw.fields.{51d3ea43-572b-4052-a36d-369d39f8d05d}currentStep',
          'recordType!{c9d3a947-71aa-4024-879e-363873a12860}SD Draw.fields.{a132be23-f941-4d59-a22c-b57e29900ea6}activeStepProcessId',
          'recordType!{c9d3a947-71aa-4024-879e-363873a12860}SD Draw.fields.{bafcfa5d-b988-4c12-a134-cd826184f0b7}createdAt',
          'recordType!{c9d3a947-71aa-4024-879e-363873a12860}SD Draw.fields.{9b41d47b-ef3a-4ea7-bf7e-0935b9c83393}updatedAt',
          'recordType!{c9d3a947-71aa-4024-879e-363873a12860}SD Draw.fields.{f98054f6-7140-4046-b3d0-2be2f78e6873}treasuryNotifiedAt',
          'recordType!{c9d3a947-71aa-4024-879e-363873a12860}SD Draw.fields.{039b9281-34a3-468c-881e-20a4ce03d900}receivedDate',
          'recordType!{c9d3a947-71aa-4024-879e-363873a12860}SD Draw.fields.{18a40650-1ce5-4cc4-8132-6018cd1064a9}submittedBy',
          'recordType!{c9d3a947-71aa-4024-879e-363873a12860}SD Draw.fields.{09edf0b2-28a3-4a7f-b9dc-ae2afefa24d0}investmentId',
          'recordType!{c9d3a947-71aa-4024-879e-363873a12860}SD Draw.fields.{1c798a00-4519-49c1-9c04-27e7fb78a9d3}extractionInstanceId',
          'recordType!{c9d3a947-71aa-4024-879e-363873a12860}SD Draw.fields.{e418c5aa-c0db-4e02-8fb9-a4ce72ccdcef}ingestionProcessId',
          'recordType!{c9d3a947-71aa-4024-879e-363873a12860}SD Draw.fields.{3139df20-a318-49b1-a9e7-13f6317880ef}ingestionFailureReason',
          'recordType!{c9d3a947-71aa-4024-879e-363873a12860}SD Draw.fields.{74b593a2-ffea-4eb9-90af-49729fcdcb25}ingestionComparison',
          'recordType!{c9d3a947-71aa-4024-879e-363873a12860}SD Draw.fields.{37d76e51-3aa8-4ab0-a2fb-26eec0bebf51}corroborationSummary',
          'recordType!{c9d3a947-71aa-4024-879e-363873a12860}SD Draw.fields.{8d2c7d6c-f7c0-4845-b49d-f1278f9b09bc}corroborationState',
          'recordType!{c9d3a947-71aa-4024-879e-363873a12860}SD Draw.relationships.{58a1018a-d85c-42b9-94ed-b51a9f0ef3d2}investment.fields.{e79c63ed-a43c-4951-b679-e2578ed5cbf6}investmentName',
          'recordType!{c9d3a947-71aa-4024-879e-363873a12860}SD Draw.relationships.{58a1018a-d85c-42b9-94ed-b51a9f0ef3d2}investment.fields.{fc86153c-eedd-41de-a0dd-a20def74fd2d}investmentDescription',
          'recordType!{c9d3a947-71aa-4024-879e-363873a12860}SD Draw.relationships.{58a1018a-d85c-42b9-94ed-b51a9f0ef3d2}investment.relationships.{1b588a74-afbc-4756-aacf-69483491d566}fund.fields.{fb775e5a-1ed9-4ce9-85ca-bb1b43767475}fundName'
        },
        filters: a!queryFilter(
          field: 'recordType!{c9d3a947-71aa-4024-879e-363873a12860}SD Draw.fields.{443829ca-5971-4d31-8fac-ab7a317e509b}id',
          operator: "=",
          value: ri!drawId
        ),
        pagingInfo: a!pagingInfo(startIndex: 1, batchSize: 1)
      ).data,
      1,
      null
    )
  ),
  local!found: not(a!isNullOrEmpty(local!draw)),
  local!state: if(local!found, rule!SD_getDrawState(drawId: ri!drawId), null),
  local!approvals: if(local!found, a!defaultValue(index(local!state, "approvals", {}), {}), {}),
  local!current: if(local!found, index(local!state, "current", null), null),
  local!next: if(local!found, index(local!state, "next", null), null),
  local!statusText: if(local!found, tostring(a!defaultValue(local!draw['recordType!{c9d3a947-71aa-4024-879e-363873a12860}SD Draw.fields.{e63818ec-ea02-40a0-bfdd-2c14b760dc2c}status'], "")), ""),
  local!inProgress: and(
    local!statusText = "In Progress",
    not(a!isNullOrEmpty(local!current)),
    tostring(a!defaultValue(index(local!current, "status", ""), "")) = "In Progress"
  ),
  /* an Ingesting draw (Phase 3) is the accountant group's: its reconciliation task is open on the ingestion process,
     whose id the shell carries in ingestionProcessId (activeStepProcessId stays free for the approval steps) */
  local!ingesting: and(local!found, local!statusText = "Ingesting"),
  /* an Ingestion Failed draw (Phase 5) has no step and no task: nobody's to act on, whatever process ids it carries */
  local!ingestionFailed: and(local!found, local!statusText = "Ingestion Failed"),
  local!currentGroup: if(
    local!inProgress,
    rule!SD_getDrawApprovalGroup(role: index(local!current, "role", "")),
    if(local!ingesting, cons!SD_DRAW_DEMO_APPROVERS_GROUP, null)
  ),
  local!viewerIsAssignee: if(
    or(local!ingestionFailed, a!isNullOrEmpty(local!currentGroup)),
    false,
    a!defaultValue(a!isUserMemberOfGroup(username: loggedInUser(), groups: local!currentGroup), false)
  ),
  local!activeProcess: if(local!found, if(local!ingesting, local!draw['recordType!{c9d3a947-71aa-4024-879e-363873a12860}SD Draw.fields.{e418c5aa-c0db-4e02-8fb9-a4ce72ccdcef}ingestionProcessId'], local!draw['recordType!{c9d3a947-71aa-4024-879e-363873a12860}SD Draw.fields.{a132be23-f941-4d59-a22c-b57e29900ea6}activeStepProcessId']), null),
  local!openTaskId: if(
    and(local!viewerIsAssignee, not(a!isNullOrEmpty(local!activeProcess))),
    rule!SD_getOpenTaskId(processId: tointeger(local!activeProcess)),
    null
  ),
  local!fundingDate: if(local!found, local!draw['recordType!{c9d3a947-71aa-4024-879e-363873a12860}SD Draw.fields.{d3bf793a-2b28-4d8c-81d4-8b05cb63f5a6}fundingDate'], null),
  local!activatedAt: if(a!isNullOrEmpty(local!current), null, index(local!current, "activatedAt", null)),
  /* counted with wherecontains: an a!forEach that returns {} for skipped items yields N nulls when every item is skipped */
  local!approvedCount: if(
    a!isNullOrEmpty(local!approvals),
    0,
    count(
      wherecontains(
        "Approved",
        a!forEach(items: local!approvals, expression: tostring(a!defaultValue(index(fv!item, "status", ""), "")))
      )
    )
  ),
  a!map(
    found: local!found,
    drawId: ri!drawId,
    id: if(local!found, local!draw['recordType!{c9d3a947-71aa-4024-879e-363873a12860}SD Draw.fields.{443829ca-5971-4d31-8fac-ab7a317e509b}id'], null),
    drawNumber: if(local!found, local!draw['recordType!{c9d3a947-71aa-4024-879e-363873a12860}SD Draw.fields.{9aa1030b-f76b-49aa-bef6-99eb90327804}drawNumber'], null),
    amount: if(local!found, local!draw['recordType!{c9d3a947-71aa-4024-879e-363873a12860}SD Draw.fields.{58586ee5-5a93-4670-a8ee-cd1c88cdb903}amount'], null),
    cashEquityNeeded: if(local!found, local!draw['recordType!{c9d3a947-71aa-4024-879e-363873a12860}SD Draw.fields.{4cf33493-ff2d-4c80-a647-869913a054ee}cashEquityNeeded'], null),
    fundingDate: if(local!found, local!draw['recordType!{c9d3a947-71aa-4024-879e-363873a12860}SD Draw.fields.{d3bf793a-2b28-4d8c-81d4-8b05cb63f5a6}fundingDate'], null),
    drawType: if(local!found, local!draw['recordType!{c9d3a947-71aa-4024-879e-363873a12860}SD Draw.fields.{5e39494a-0995-4196-828b-ab809cf187db}drawType'], null),
    purpose: if(local!found, local!draw['recordType!{c9d3a947-71aa-4024-879e-363873a12860}SD Draw.fields.{0420a7a0-6645-4d31-9c0b-4c19ff7d88da}purpose'], null),
    budgetStatus: if(local!found, local!draw['recordType!{c9d3a947-71aa-4024-879e-363873a12860}SD Draw.fields.{23929877-d10e-4cff-a967-6bb3b0f61eac}budgetStatus'], null),
    overBudgetReason: if(local!found, local!draw['recordType!{c9d3a947-71aa-4024-879e-363873a12860}SD Draw.fields.{d05fa5d6-60fa-4e20-be49-1ce42ff1e7d9}overBudgetReason'], null),
    generalComments: if(local!found, local!draw['recordType!{c9d3a947-71aa-4024-879e-363873a12860}SD Draw.fields.{c9513036-39a7-4877-9e18-852a36d7dc23}generalComments'], null),
    contingencyExplanation: if(local!found, local!draw['recordType!{c9d3a947-71aa-4024-879e-363873a12860}SD Draw.fields.{3a000d1d-0179-488f-87a9-1dc3b87ec048}contingencyExplanation'], null),
    status: if(local!found, local!draw['recordType!{c9d3a947-71aa-4024-879e-363873a12860}SD Draw.fields.{e63818ec-ea02-40a0-bfdd-2c14b760dc2c}status'], null),
    currentStep: if(local!found, local!draw['recordType!{c9d3a947-71aa-4024-879e-363873a12860}SD Draw.fields.{51d3ea43-572b-4052-a36d-369d39f8d05d}currentStep'], null),
    activeStepProcessId: if(local!found, local!draw['recordType!{c9d3a947-71aa-4024-879e-363873a12860}SD Draw.fields.{a132be23-f941-4d59-a22c-b57e29900ea6}activeStepProcessId'], null),
    createdAt: if(local!found, local!draw['recordType!{c9d3a947-71aa-4024-879e-363873a12860}SD Draw.fields.{bafcfa5d-b988-4c12-a134-cd826184f0b7}createdAt'], null),
    updatedAt: if(local!found, local!draw['recordType!{c9d3a947-71aa-4024-879e-363873a12860}SD Draw.fields.{9b41d47b-ef3a-4ea7-bf7e-0935b9c83393}updatedAt'], null),
    treasuryNotifiedAt: if(local!found, local!draw['recordType!{c9d3a947-71aa-4024-879e-363873a12860}SD Draw.fields.{f98054f6-7140-4046-b3d0-2be2f78e6873}treasuryNotifiedAt'], null),
    receivedDate: if(local!found, local!draw['recordType!{c9d3a947-71aa-4024-879e-363873a12860}SD Draw.fields.{039b9281-34a3-468c-881e-20a4ce03d900}receivedDate'], null),
    submittedBy: if(local!found, local!draw['recordType!{c9d3a947-71aa-4024-879e-363873a12860}SD Draw.fields.{18a40650-1ce5-4cc4-8132-6018cd1064a9}submittedBy'], null),
    investmentId: if(local!found, local!draw['recordType!{c9d3a947-71aa-4024-879e-363873a12860}SD Draw.fields.{09edf0b2-28a3-4a7f-b9dc-ae2afefa24d0}investmentId'], null),
    extractionInstanceId: if(local!found, local!draw['recordType!{c9d3a947-71aa-4024-879e-363873a12860}SD Draw.fields.{1c798a00-4519-49c1-9c04-27e7fb78a9d3}extractionInstanceId'], null),
    ingestionProcessId: if(local!found, local!draw['recordType!{c9d3a947-71aa-4024-879e-363873a12860}SD Draw.fields.{e418c5aa-c0db-4e02-8fb9-a4ce72ccdcef}ingestionProcessId'], null),
    ingestionFailureReason: if(local!found, local!draw['recordType!{c9d3a947-71aa-4024-879e-363873a12860}SD Draw.fields.{3139df20-a318-49b1-a9e7-13f6317880ef}ingestionFailureReason'], null),
    ingestionComparison: if(local!found, local!draw['recordType!{c9d3a947-71aa-4024-879e-363873a12860}SD Draw.fields.{74b593a2-ffea-4eb9-90af-49729fcdcb25}ingestionComparison'], null),
    corroborationSummary: if(local!found, local!draw['recordType!{c9d3a947-71aa-4024-879e-363873a12860}SD Draw.fields.{37d76e51-3aa8-4ab0-a2fb-26eec0bebf51}corroborationSummary'], null),
    corroborationState: if(local!found, local!draw['recordType!{c9d3a947-71aa-4024-879e-363873a12860}SD Draw.fields.{8d2c7d6c-f7c0-4845-b49d-f1278f9b09bc}corroborationState'], null),
    investmentName: if(local!found, local!draw['recordType!{c9d3a947-71aa-4024-879e-363873a12860}SD Draw.relationships.{58a1018a-d85c-42b9-94ed-b51a9f0ef3d2}investment.fields.{e79c63ed-a43c-4951-b679-e2578ed5cbf6}investmentName'], null),
    investmentDescription: if(local!found, local!draw['recordType!{c9d3a947-71aa-4024-879e-363873a12860}SD Draw.relationships.{58a1018a-d85c-42b9-94ed-b51a9f0ef3d2}investment.fields.{fc86153c-eedd-41de-a0dd-a20def74fd2d}investmentDescription'], null),
    fundName: if(local!found, local!draw['recordType!{c9d3a947-71aa-4024-879e-363873a12860}SD Draw.relationships.{58a1018a-d85c-42b9-94ed-b51a9f0ef3d2}investment.relationships.{1b588a74-afbc-4756-aacf-69483491d566}fund.fields.{fb775e5a-1ed9-4ce9-85ca-bb1b43767475}fundName'], null),
    approvals: local!approvals,
    current: local!current,
    next: local!next,
    totalSteps: count(local!approvals),
    approvedCount: local!approvedCount,
    inProgress: local!inProgress,
    ingesting: local!ingesting,
    ingestionFailed: local!ingestionFailed,
    currentRole: if(local!ingesting, "Accountant reconciliation", if(a!isNullOrEmpty(local!current), null, index(local!current, "role", null))),
    currentApprover: if(a!isNullOrEmpty(local!current), null, index(local!current, "approverName", null)),
    currentActivatedAt: if(local!ingesting, local!draw['recordType!{c9d3a947-71aa-4024-879e-363873a12860}SD Draw.fields.{039b9281-34a3-468c-881e-20a4ce03d900}receivedDate'], local!activatedAt),
    currentGroup: local!currentGroup,
    viewerIsAssignee: local!viewerIsAssignee,
    openTaskId: local!openTaskId,
    awaitingViewer: and(local!viewerIsAssignee, not(a!isNullOrEmpty(local!openTaskId))),
    daysToFunding: if(a!isNullOrEmpty(local!fundingDate), null, tointeger(todate(local!fundingDate) - today())),
    daysAtStep: if(
      local!ingesting,
      if(a!isNullOrEmpty(local!draw['recordType!{c9d3a947-71aa-4024-879e-363873a12860}SD Draw.fields.{039b9281-34a3-468c-881e-20a4ce03d900}receivedDate']), 0, max(0, tointeger(today() - todate(local!draw['recordType!{c9d3a947-71aa-4024-879e-363873a12860}SD Draw.fields.{039b9281-34a3-468c-881e-20a4ce03d900}receivedDate'])))),
      if(a!isNullOrEmpty(local!activatedAt), null, max(0, tointeger(today() - todate(local!activatedAt))))
    )
  )
)

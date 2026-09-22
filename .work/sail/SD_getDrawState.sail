/* Draw approval: routing state of one draw, read once by every process that decides or advances a step.
   Returns a map: found, drawId, drawNumber, drawStatus, currentStep, activeStepProcessId, amount,
   investmentName, fundName, current (approval row at currentStep), next (row at currentStep + 1, or null),
   approvals (all rows, ordered). Rows are maps of id, approvalOrder, role, approverName, status, decisionDate, activatedAt. */
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
          'recordType!{c9d3a947-71aa-4024-879e-363873a12860}SD Draw.fields.{e63818ec-ea02-40a0-bfdd-2c14b760dc2c}status',
          'recordType!{c9d3a947-71aa-4024-879e-363873a12860}SD Draw.fields.{51d3ea43-572b-4052-a36d-369d39f8d05d}currentStep',
          'recordType!{c9d3a947-71aa-4024-879e-363873a12860}SD Draw.fields.{a132be23-f941-4d59-a22c-b57e29900ea6}activeStepProcessId',
          'recordType!{c9d3a947-71aa-4024-879e-363873a12860}SD Draw.fields.{58586ee5-5a93-4670-a8ee-cd1c88cdb903}amount',
          'recordType!{c9d3a947-71aa-4024-879e-363873a12860}SD Draw.relationships.{58a1018a-d85c-42b9-94ed-b51a9f0ef3d2}investment.fields.{e79c63ed-a43c-4951-b679-e2578ed5cbf6}investmentName',
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
  local!rows: if(
    not(local!found),
    {},
    a!queryRecordType(
      recordType: 'recordType!{02c207d5-c725-4d11-bf40-b33573e87ffa}SD Draw Approval',
      fields: {
        'recordType!{02c207d5-c725-4d11-bf40-b33573e87ffa}SD Draw Approval.fields.{69abcdf2-55da-48dc-8cc4-794b5d5e0042}id',
        'recordType!{02c207d5-c725-4d11-bf40-b33573e87ffa}SD Draw Approval.fields.{44b8ee63-1230-4abd-ae83-ca2cddf182b6}approvalOrder',
        'recordType!{02c207d5-c725-4d11-bf40-b33573e87ffa}SD Draw Approval.fields.{30524217-4621-4b41-9af4-490d2f082bdd}role',
        'recordType!{02c207d5-c725-4d11-bf40-b33573e87ffa}SD Draw Approval.fields.{983be1c0-67e4-464f-b7c2-1e3a1c735458}approverName',
        'recordType!{02c207d5-c725-4d11-bf40-b33573e87ffa}SD Draw Approval.fields.{4c1bf7fb-0736-4c9a-946e-99f6989ac83a}status',
        'recordType!{02c207d5-c725-4d11-bf40-b33573e87ffa}SD Draw Approval.fields.{a6a03063-3b14-4f00-8cab-b5d10602405e}decisionDate',
        'recordType!{02c207d5-c725-4d11-bf40-b33573e87ffa}SD Draw Approval.fields.{e6597b65-664d-4ccc-9dd0-f3e508ecdcc5}activatedAt'
      },
      filters: a!queryFilter(
        field: 'recordType!{02c207d5-c725-4d11-bf40-b33573e87ffa}SD Draw Approval.fields.{5dacd7ec-3f3f-4645-9d08-684793b0b54b}drawId',
        operator: "=",
        value: ri!drawId
      ),
      pagingInfo: a!pagingInfo(
        startIndex: 1,
        batchSize: 50,
        sort: a!sortInfo(
          field: 'recordType!{02c207d5-c725-4d11-bf40-b33573e87ffa}SD Draw Approval.fields.{44b8ee63-1230-4abd-ae83-ca2cddf182b6}approvalOrder',
          ascending: true
        )
      )
    ).data
  ),
  local!approvals: a!forEach(
    items: local!rows,
    expression: a!map(
      id: fv!item['recordType!{02c207d5-c725-4d11-bf40-b33573e87ffa}SD Draw Approval.fields.{69abcdf2-55da-48dc-8cc4-794b5d5e0042}id'],
      approvalOrder: fv!item['recordType!{02c207d5-c725-4d11-bf40-b33573e87ffa}SD Draw Approval.fields.{44b8ee63-1230-4abd-ae83-ca2cddf182b6}approvalOrder'],
      role: fv!item['recordType!{02c207d5-c725-4d11-bf40-b33573e87ffa}SD Draw Approval.fields.{30524217-4621-4b41-9af4-490d2f082bdd}role'],
      approverName: fv!item['recordType!{02c207d5-c725-4d11-bf40-b33573e87ffa}SD Draw Approval.fields.{983be1c0-67e4-464f-b7c2-1e3a1c735458}approverName'],
      status: fv!item['recordType!{02c207d5-c725-4d11-bf40-b33573e87ffa}SD Draw Approval.fields.{4c1bf7fb-0736-4c9a-946e-99f6989ac83a}status'],
      decisionDate: fv!item['recordType!{02c207d5-c725-4d11-bf40-b33573e87ffa}SD Draw Approval.fields.{a6a03063-3b14-4f00-8cab-b5d10602405e}decisionDate'],
      activatedAt: fv!item['recordType!{02c207d5-c725-4d11-bf40-b33573e87ffa}SD Draw Approval.fields.{e6597b65-664d-4ccc-9dd0-f3e508ecdcc5}activatedAt']
    )
  ),
  local!currentStep: if(local!found, local!draw['recordType!{c9d3a947-71aa-4024-879e-363873a12860}SD Draw.fields.{51d3ea43-572b-4052-a36d-369d39f8d05d}currentStep'], null),
  local!orders: a!forEach(items: local!approvals, expression: tointeger(fv!item.approvalOrder)),
  local!currentIdx: if(
    or(a!isNullOrEmpty(local!orders), a!isNullOrEmpty(local!currentStep)),
    {},
    wherecontains(tointeger(local!currentStep), local!orders)
  ),
  local!nextIdx: if(
    or(a!isNullOrEmpty(local!orders), a!isNullOrEmpty(local!currentStep)),
    {},
    wherecontains(tointeger(local!currentStep) + 1, local!orders)
  ),
  a!map(
    found: local!found,
    drawId: ri!drawId,
    drawNumber: if(local!found, local!draw['recordType!{c9d3a947-71aa-4024-879e-363873a12860}SD Draw.fields.{9aa1030b-f76b-49aa-bef6-99eb90327804}drawNumber'], null),
    drawStatus: if(local!found, local!draw['recordType!{c9d3a947-71aa-4024-879e-363873a12860}SD Draw.fields.{e63818ec-ea02-40a0-bfdd-2c14b760dc2c}status'], null),
    currentStep: local!currentStep,
    activeStepProcessId: if(local!found, local!draw['recordType!{c9d3a947-71aa-4024-879e-363873a12860}SD Draw.fields.{a132be23-f941-4d59-a22c-b57e29900ea6}activeStepProcessId'], null),
    amount: if(local!found, local!draw['recordType!{c9d3a947-71aa-4024-879e-363873a12860}SD Draw.fields.{58586ee5-5a93-4670-a8ee-cd1c88cdb903}amount'], null),
    investmentName: if(local!found, local!draw['recordType!{c9d3a947-71aa-4024-879e-363873a12860}SD Draw.relationships.{58a1018a-d85c-42b9-94ed-b51a9f0ef3d2}investment.fields.{e79c63ed-a43c-4951-b679-e2578ed5cbf6}investmentName'], null),
    fundName: if(local!found, local!draw['recordType!{c9d3a947-71aa-4024-879e-363873a12860}SD Draw.relationships.{58a1018a-d85c-42b9-94ed-b51a9f0ef3d2}investment.relationships.{1b588a74-afbc-4756-aacf-69483491d566}fund.fields.{fb775e5a-1ed9-4ce9-85ca-bb1b43767475}fundName'], null),
    current: if(a!isNullOrEmpty(local!currentIdx), null, index(local!approvals, local!currentIdx[1], null)),
    next: if(a!isNullOrEmpty(local!nextIdx), null, index(local!approvals, local!nextIdx[1], null)),
    previousDecisionDate: a!localVariables(
      local!prevIdx: if(or(a!isNullOrEmpty(local!orders), a!isNullOrEmpty(local!currentStep)), {}, wherecontains(tointeger(local!currentStep) - 1, local!orders)),
      if(a!isNullOrEmpty(local!prevIdx), null, index(index(local!approvals, local!prevIdx[1], null), "decisionDate", null))
    ),
    approvals: local!approvals
  )
)

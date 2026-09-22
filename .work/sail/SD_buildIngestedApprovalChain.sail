/* Draw approval (Phase 3): the nine SD Draw Approval rows for an ingested draw. Roles and named approvers are copied
   from the investment's most recent prior draw (by funding date, then id) — the chain of record for that property —
   and fall back to the canon roles with no named approver when the investment has no prior chain. Order 1 starts
   In Progress (activated now) so SD Draw Approval Process can issue the Accountant task; orders 2–9 are Pending. */
a!localVariables(
  local!priorDraws: if(
    a!isNullOrEmpty(ri!investmentId),
    {},
    a!queryRecordType(
      recordType: 'recordType!{c9d3a947-71aa-4024-879e-363873a12860}SD Draw',
      fields: { 'recordType!{c9d3a947-71aa-4024-879e-363873a12860}SD Draw.fields.{443829ca-5971-4d31-8fac-ab7a317e509b}id', 'recordType!{c9d3a947-71aa-4024-879e-363873a12860}SD Draw.fields.{d3bf793a-2b28-4d8c-81d4-8b05cb63f5a6}fundingDate' },
      filters: a!queryLogicalExpression(
        operator: "AND",
        filters: {
          a!queryFilter(field: 'recordType!{c9d3a947-71aa-4024-879e-363873a12860}SD Draw.fields.{09edf0b2-28a3-4a7f-b9dc-ae2afefa24d0}investmentId', operator: "=", value: ri!investmentId),
          a!queryFilter(field: 'recordType!{c9d3a947-71aa-4024-879e-363873a12860}SD Draw.fields.{443829ca-5971-4d31-8fac-ab7a317e509b}id', operator: "<>", value: ri!drawId)
        }
      ),
      pagingInfo: a!pagingInfo(
        startIndex: 1,
        batchSize: 10,
        sort: {
          a!sortInfo(field: 'recordType!{c9d3a947-71aa-4024-879e-363873a12860}SD Draw.fields.{d3bf793a-2b28-4d8c-81d4-8b05cb63f5a6}fundingDate', ascending: false),
          a!sortInfo(field: 'recordType!{c9d3a947-71aa-4024-879e-363873a12860}SD Draw.fields.{443829ca-5971-4d31-8fac-ab7a317e509b}id', ascending: false)
        }
      )
    ).data
  ),
  local!priorIds: a!forEach(items: local!priorDraws, expression: fv!item['recordType!{c9d3a947-71aa-4024-879e-363873a12860}SD Draw.fields.{443829ca-5971-4d31-8fac-ab7a317e509b}id']),
  local!sourceRows: if(
    a!isNullOrEmpty(local!priorIds),
    {},
    a!queryRecordType(
      recordType: 'recordType!{02c207d5-c725-4d11-bf40-b33573e87ffa}SD Draw Approval',
      fields: { 'recordType!{02c207d5-c725-4d11-bf40-b33573e87ffa}SD Draw Approval.fields.{5dacd7ec-3f3f-4645-9d08-684793b0b54b}drawId', 'recordType!{02c207d5-c725-4d11-bf40-b33573e87ffa}SD Draw Approval.fields.{44b8ee63-1230-4abd-ae83-ca2cddf182b6}approvalOrder', 'recordType!{02c207d5-c725-4d11-bf40-b33573e87ffa}SD Draw Approval.fields.{30524217-4621-4b41-9af4-490d2f082bdd}role', 'recordType!{02c207d5-c725-4d11-bf40-b33573e87ffa}SD Draw Approval.fields.{983be1c0-67e4-464f-b7c2-1e3a1c735458}approverName' },
      filters: a!queryFilter(field: 'recordType!{02c207d5-c725-4d11-bf40-b33573e87ffa}SD Draw Approval.fields.{5dacd7ec-3f3f-4645-9d08-684793b0b54b}drawId', operator: "in", value: local!priorIds),
      pagingInfo: a!pagingInfo(startIndex: 1, batchSize: 200, sort: a!sortInfo(field: 'recordType!{02c207d5-c725-4d11-bf40-b33573e87ffa}SD Draw Approval.fields.{44b8ee63-1230-4abd-ae83-ca2cddf182b6}approvalOrder', ascending: true))
    ).data
  ),
  /* the first prior draw (most recent) that actually carries a chain */
  local!sourceDrawId: a!localVariables(
    local!withRows: if(
      a!isNullOrEmpty(local!sourceRows),
      {},
      a!forEach(items: local!priorIds, expression: if(contains(a!forEach(items: local!sourceRows, expression: tointeger(fv!item['recordType!{02c207d5-c725-4d11-bf40-b33573e87ffa}SD Draw Approval.fields.{5dacd7ec-3f3f-4645-9d08-684793b0b54b}drawId'])), tointeger(fv!item)), fv!item, 0))
    ),
    local!kept: if(a!isNullOrEmpty(local!withRows), {}, index(local!withRows, wherecontains(false, a!forEach(items: local!withRows, expression: fv!item = 0)), {})),
    if(a!isNullOrEmpty(local!kept), null, local!kept[1])
  ),
  local!template: if(
    a!isNullOrEmpty(local!sourceDrawId),
    {},
    index(local!sourceRows, wherecontains(tointeger(local!sourceDrawId), a!forEach(items: local!sourceRows, expression: tointeger(fv!item['recordType!{02c207d5-c725-4d11-bf40-b33573e87ffa}SD Draw Approval.fields.{5dacd7ec-3f3f-4645-9d08-684793b0b54b}drawId']))), {})
  ),
  local!canonRoles: {"Accountant", "Accounting Controller", "Asset Manager", "AM SVP", "Executive", "Chief Accounting Officer", "CFO of Funds", "President", "CEO"},
  a!forEach(
    items: enumerate(9) + 1,
    expression: a!localVariables(
      local!order: fv!item,
      local!idx: if(a!isNullOrEmpty(local!template), {}, wherecontains(local!order, a!forEach(items: local!template, expression: tointeger(fv!item['recordType!{02c207d5-c725-4d11-bf40-b33573e87ffa}SD Draw Approval.fields.{44b8ee63-1230-4abd-ae83-ca2cddf182b6}approvalOrder'])))),
      local!src: if(a!isNullOrEmpty(local!idx), null, index(local!template, local!idx[1], null)),
      'recordType!{02c207d5-c725-4d11-bf40-b33573e87ffa}SD Draw Approval'(
        'recordType!{02c207d5-c725-4d11-bf40-b33573e87ffa}SD Draw Approval.fields.{5dacd7ec-3f3f-4645-9d08-684793b0b54b}drawId': ri!drawId,
        'recordType!{02c207d5-c725-4d11-bf40-b33573e87ffa}SD Draw Approval.fields.{44b8ee63-1230-4abd-ae83-ca2cddf182b6}approvalOrder': local!order,
        'recordType!{02c207d5-c725-4d11-bf40-b33573e87ffa}SD Draw Approval.fields.{30524217-4621-4b41-9af4-490d2f082bdd}role': if(a!isNullOrEmpty(local!src), local!canonRoles[local!order], local!src['recordType!{02c207d5-c725-4d11-bf40-b33573e87ffa}SD Draw Approval.fields.{30524217-4621-4b41-9af4-490d2f082bdd}role']),
        'recordType!{02c207d5-c725-4d11-bf40-b33573e87ffa}SD Draw Approval.fields.{983be1c0-67e4-464f-b7c2-1e3a1c735458}approverName': if(a!isNullOrEmpty(local!src), null, local!src['recordType!{02c207d5-c725-4d11-bf40-b33573e87ffa}SD Draw Approval.fields.{983be1c0-67e4-464f-b7c2-1e3a1c735458}approverName']),
        'recordType!{02c207d5-c725-4d11-bf40-b33573e87ffa}SD Draw Approval.fields.{4c1bf7fb-0736-4c9a-946e-99f6989ac83a}status': if(local!order = 1, "In Progress", "Pending"),
        'recordType!{02c207d5-c725-4d11-bf40-b33573e87ffa}SD Draw Approval.fields.{e6597b65-664d-4ccc-9dd0-f3e508ecdcc5}activatedAt': if(local!order = 1, now(), null)
      )
    )
  )
)

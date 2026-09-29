/* Draw approval: the nine SD Draw Approval rows for an ingested draw, built when the accountant confirms the
   reconciliation. Second fix session 2026-09-28 (ruled): roles come from cons!SD_DRAW_CHAIN_ROLES in its order
   (1 Accountant, 2 Asset Manager, 3 Accounting Controller, 4 AM SVP, 5 Executive, 6 Chief Accounting Officer, 7 CFO of
   Funds, 8 President, 9 CEO), never from a prior draw's order. Named approvers still come from the investment's most
   recent prior draw that carries a chain (by funding date, then id), matched by ROLE; a role not on it has no name.
   Order 1 is the accountant's confirmation: Approved at ri!confirmedAt, acted by ri!confirmedBy, source RECONCILIATION,
   activated when the draw was received; its named approver is the prior chain's Accountant, else the confirming user's
   display name. Order 2 (Asset Manager) is In Progress, activated at ri!confirmedAt, so SD Draw Approval Process issues
   the Asset Manager's task at once; orders 3-9 are Pending. Existing draws are never rebuilt: this runs only when a new
   draw is assembled, and every other part of the flow reads whatever the draw's rows say. */
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
  local!roles: cons!SD_DRAW_CHAIN_ROLES,
  local!templateRoles: if(a!isNullOrEmpty(local!template), {}, a!forEach(items: local!template, expression: tostring(fv!item['recordType!{02c207d5-c725-4d11-bf40-b33573e87ffa}SD Draw Approval.fields.{30524217-4621-4b41-9af4-490d2f082bdd}role']))),
  /* the prior chain's named approver for each canonical role, "" when the role is not on it */
  local!names: a!forEach(
    items: local!roles,
    expression: a!localVariables(
      local!hit: if(a!isNullOrEmpty(local!templateRoles), {}, wherecontains(tostring(fv!item), local!templateRoles)),
      if(a!isNullOrEmpty(local!hit), "", tostring(a!defaultValue(index(local!template, local!hit[1], null)['recordType!{02c207d5-c725-4d11-bf40-b33573e87ffa}SD Draw Approval.fields.{983be1c0-67e4-464f-b7c2-1e3a1c735458}approverName'], "")))
    )
  ),
  local!confirmedAt: a!defaultValue(ri!confirmedAt, now()),
  local!confirmer: if(or(a!isNullOrEmpty(ri!confirmedBy), ri!confirmedBy = "-"), "", tostring(ri!confirmedBy)),
  local!confirmerName: if(local!confirmer = "", "", tostring(a!defaultValue(rule!SD_getUserDisplayName(username: local!confirmer), local!confirmer))),
  local!receivedAt: a!localVariables(
    local!r: if(
      a!isNullOrEmpty(ri!drawId),
      {},
      a!queryRecordType(
        recordType: 'recordType!{c9d3a947-71aa-4024-879e-363873a12860}SD Draw',
        fields: { 'recordType!{c9d3a947-71aa-4024-879e-363873a12860}SD Draw.fields.{bafcfa5d-b988-4c12-a134-cd826184f0b7}createdAt' },
        filters: a!queryFilter(field: 'recordType!{c9d3a947-71aa-4024-879e-363873a12860}SD Draw.fields.{443829ca-5971-4d31-8fac-ab7a317e509b}id', operator: "=", value: ri!drawId),
        pagingInfo: a!pagingInfo(startIndex: 1, batchSize: 1)
      ).data
    ),
    local!row: index(local!r, 1, null),
    if(a!isNullOrEmpty(local!row), null, local!row['recordType!{c9d3a947-71aa-4024-879e-363873a12860}SD Draw.fields.{bafcfa5d-b988-4c12-a134-cd826184f0b7}createdAt'])
  ),
  a!forEach(
    items: enumerate(count(local!roles)) + 1,
    expression: a!localVariables(
      local!order: fv!item,
      local!first: local!order = 1,
      local!named: tostring(index(local!names, local!order, "")),
      'recordType!{02c207d5-c725-4d11-bf40-b33573e87ffa}SD Draw Approval'(
        'recordType!{02c207d5-c725-4d11-bf40-b33573e87ffa}SD Draw Approval.fields.{5dacd7ec-3f3f-4645-9d08-684793b0b54b}drawId': ri!drawId,
        'recordType!{02c207d5-c725-4d11-bf40-b33573e87ffa}SD Draw Approval.fields.{44b8ee63-1230-4abd-ae83-ca2cddf182b6}approvalOrder': local!order,
        'recordType!{02c207d5-c725-4d11-bf40-b33573e87ffa}SD Draw Approval.fields.{30524217-4621-4b41-9af4-490d2f082bdd}role': tostring(local!roles[local!order]),
        'recordType!{02c207d5-c725-4d11-bf40-b33573e87ffa}SD Draw Approval.fields.{983be1c0-67e4-464f-b7c2-1e3a1c735458}approverName': if(local!named <> "", local!named, if(and(local!first, local!confirmerName <> ""), local!confirmerName, null)),
        'recordType!{02c207d5-c725-4d11-bf40-b33573e87ffa}SD Draw Approval.fields.{4c1bf7fb-0736-4c9a-946e-99f6989ac83a}status': if(local!first, "Approved", if(local!order = 2, "In Progress", "Pending")),
        'recordType!{02c207d5-c725-4d11-bf40-b33573e87ffa}SD Draw Approval.fields.{e6597b65-664d-4ccc-9dd0-f3e508ecdcc5}activatedAt': if(local!first, a!defaultValue(local!receivedAt, local!confirmedAt), if(local!order = 2, local!confirmedAt, null)),
        'recordType!{02c207d5-c725-4d11-bf40-b33573e87ffa}SD Draw Approval.fields.{a6a03063-3b14-4f00-8cab-b5d10602405e}decisionDate': if(local!first, local!confirmedAt, null),
        'recordType!{02c207d5-c725-4d11-bf40-b33573e87ffa}SD Draw Approval.fields.{2e6ad17e-66f3-4ab2-97b6-c21ee10dd203}actedBy': if(and(local!first, local!confirmer <> ""), local!confirmer, null),
        'recordType!{02c207d5-c725-4d11-bf40-b33573e87ffa}SD Draw Approval.fields.{6597627c-af44-4119-9b92-286179df119d}decisionSource': if(local!first, "RECONCILIATION", null),
        'recordType!{02c207d5-c725-4d11-bf40-b33573e87ffa}SD Draw Approval.fields.{3c1aae42-13a1-4c13-894a-9fdef20f7fce}comments': if(local!first, "Confirmed the Doc Center extraction at reconciliation; the draw was assembled and sent to the Asset Manager.", null)
      )
    )
  )
)

/* Draw approval (fix session 2026-09-27): the plan SD Clean Up Old Runs executes for an explicit list of draw ids.
   Re-applies the exclusion (never a seeded draw, never a named specimen) whatever the caller sent, reads every child row
   by type, and lists the open processes holding tasks on those draws — the ingestion pipeline (a reconciliation task),
   the registered step process (an approval task) and any email-reply review (the handler process on an EXCEPTION row) —
   so they are cancelled before the rows go. A process with no open task is left alone. Returns a map: drawIds, refused,
   drawLabels, lineIds, approvalIds, qiuIds, docIds, msgIds, eventIds, processIds. */
a!localVariables(
  local!req: if(a!isNullOrEmpty(ri!drawIds), {}, tointeger(ri!drawIds)),
  local!allowed: if(
    a!isNullOrEmpty(local!req),
    {},
    index(
      local!req,
      wherecontains(
        true,
        a!forEach(
          items: local!req,
          expression: and(
            not(a!isNullOrEmpty(fv!item)),
            not(contains(tointeger(cons!SD_SEED_DRAW_IDS), fv!item)),
            not(contains(tointeger(cons!SD_DEMO_KEEP_DRAW_IDS), fv!item))
          )
        )
      ),
      {}
    )
  ),
  local!draws: if(
    a!isNullOrEmpty(local!allowed),
    {},
    a!queryRecordType(
      recordType: 'recordType!{c9d3a947-71aa-4024-879e-363873a12860}SD Draw',
      fields: {'recordType!{c9d3a947-71aa-4024-879e-363873a12860}SD Draw.fields.{443829ca-5971-4d31-8fac-ab7a317e509b}id', 'recordType!{c9d3a947-71aa-4024-879e-363873a12860}SD Draw.fields.{9aa1030b-f76b-49aa-bef6-99eb90327804}drawNumber', 'recordType!{c9d3a947-71aa-4024-879e-363873a12860}SD Draw.fields.{e63818ec-ea02-40a0-bfdd-2c14b760dc2c}status', 'recordType!{c9d3a947-71aa-4024-879e-363873a12860}SD Draw.fields.{e418c5aa-c0db-4e02-8fb9-a4ce72ccdcef}ingestionProcessId', 'recordType!{c9d3a947-71aa-4024-879e-363873a12860}SD Draw.fields.{a132be23-f941-4d59-a22c-b57e29900ea6}activeStepProcessId'},
      filters: a!queryFilter(field: 'recordType!{c9d3a947-71aa-4024-879e-363873a12860}SD Draw.fields.{443829ca-5971-4d31-8fac-ab7a317e509b}id', operator: "in", value: local!allowed),
      pagingInfo: a!pagingInfo(startIndex: 1, batchSize: 500)
    ).data
  ),
  local!found: if(a!isNullOrEmpty(local!draws), {}, tointeger(a!forEach(items: local!draws, expression: fv!item['recordType!{c9d3a947-71aa-4024-879e-363873a12860}SD Draw.fields.{443829ca-5971-4d31-8fac-ab7a317e509b}id']))),
  local!lines: if(
    a!isNullOrEmpty(local!found),
    {},
    a!queryRecordType(
      recordType: 'recordType!{ddc4073e-6372-49e2-80de-a088b424abcd}SD Draw Budget Line',
      fields: {'recordType!{ddc4073e-6372-49e2-80de-a088b424abcd}SD Draw Budget Line.fields.{14803371-b715-43a4-bc3a-94e314f16f8a}id'},
      filters: a!queryFilter(field: 'recordType!{ddc4073e-6372-49e2-80de-a088b424abcd}SD Draw Budget Line.fields.{830216a5-8980-4ac0-a8f9-7baa33bbea6b}drawId', operator: "in", value: local!found),
      pagingInfo: a!pagingInfo(startIndex: 1, batchSize: 5000)
    ).data
  ),
  local!lineIds: if(a!isNullOrEmpty(local!lines), {}, tointeger(a!forEach(items: local!lines, expression: fv!item['recordType!{ddc4073e-6372-49e2-80de-a088b424abcd}SD Draw Budget Line.fields.{14803371-b715-43a4-bc3a-94e314f16f8a}id']))),
  local!approvals: if(
    a!isNullOrEmpty(local!found),
    {},
    a!queryRecordType(
      recordType: 'recordType!{02c207d5-c725-4d11-bf40-b33573e87ffa}SD Draw Approval',
      fields: {'recordType!{02c207d5-c725-4d11-bf40-b33573e87ffa}SD Draw Approval.fields.{69abcdf2-55da-48dc-8cc4-794b5d5e0042}id'},
      filters: a!queryFilter(field: 'recordType!{02c207d5-c725-4d11-bf40-b33573e87ffa}SD Draw Approval.fields.{5dacd7ec-3f3f-4645-9d08-684793b0b54b}drawId', operator: "in", value: local!found),
      pagingInfo: a!pagingInfo(startIndex: 1, batchSize: 5000)
    ).data
  ),
  local!qius: if(
    a!isNullOrEmpty(local!found),
    {},
    a!queryRecordType(
      recordType: 'recordType!{a0920e4c-0c76-4494-a61a-6e38d5db390a}SD QIU Metric',
      fields: {'recordType!{a0920e4c-0c76-4494-a61a-6e38d5db390a}SD QIU Metric.fields.{f3d5f8f7-3ecf-4749-b749-78f2836cd65d}id'},
      filters: a!queryFilter(field: 'recordType!{a0920e4c-0c76-4494-a61a-6e38d5db390a}SD QIU Metric.fields.{5fbabfd8-3d5f-4593-a48b-191b529eb267}drawId', operator: "in", value: local!found),
      pagingInfo: a!pagingInfo(startIndex: 1, batchSize: 5000)
    ).data
  ),
  local!docs: if(
    a!isNullOrEmpty(local!found),
    {},
    a!queryRecordType(
      recordType: 'recordType!{f3e0033f-2047-4c68-8f6f-cf32166091e9}SD Draw Document',
      fields: {'recordType!{f3e0033f-2047-4c68-8f6f-cf32166091e9}SD Draw Document.fields.{a0e2e466-e3fb-4f48-9744-481735a1ba8f}id'},
      filters: a!queryFilter(field: 'recordType!{f3e0033f-2047-4c68-8f6f-cf32166091e9}SD Draw Document.fields.{75e7a282-935e-488c-8f72-2b32468edbfc}drawId', operator: "in", value: local!found),
      pagingInfo: a!pagingInfo(startIndex: 1, batchSize: 5000)
    ).data
  ),
  local!msgs: if(
    a!isNullOrEmpty(local!found),
    {},
    a!queryRecordType(
      recordType: 'recordType!{3686a81f-86e2-498e-a4d1-ce40236c824a}SD Draw Email Message',
      fields: {'recordType!{3686a81f-86e2-498e-a4d1-ce40236c824a}SD Draw Email Message.fields.{7d692543-d14a-44a7-b2eb-2aba819cea1f}id', 'recordType!{3686a81f-86e2-498e-a4d1-ce40236c824a}SD Draw Email Message.fields.{e9c9c4c7-9917-4689-bbd9-834dfeed71d4}processId'},
      filters: a!queryFilter(field: 'recordType!{3686a81f-86e2-498e-a4d1-ce40236c824a}SD Draw Email Message.fields.{163bd929-1a5c-4862-a6b4-e64a7af2e463}drawId', operator: "in", value: local!found),
      pagingInfo: a!pagingInfo(startIndex: 1, batchSize: 5000)
    ).data
  ),
  local!events: if(
    a!isNullOrEmpty(local!lineIds),
    {},
    a!queryRecordType(
      recordType: 'recordType!{ee493a87-e51b-4148-8893-26de1e924ffb}SD Draw Budget Line Event History',
      fields: {'recordType!{ee493a87-e51b-4148-8893-26de1e924ffb}SD Draw Budget Line Event History.fields.{cbefa248-a552-4bbb-9733-d4dd1d291a99}id'},
      filters: a!queryFilter(field: 'recordType!{ee493a87-e51b-4148-8893-26de1e924ffb}SD Draw Budget Line Event History.fields.{7e9a52d1-8566-4199-b6b9-167488e2383e}recordId', operator: "in", value: local!lineIds),
      pagingInfo: a!pagingInfo(startIndex: 1, batchSize: 5000)
    ).data
  ),
  /* candidate processes: each draw's pipeline and registered step process, and the handler behind any message row */
  local!procCandidates: reject(
    a!isNullOrEmpty,
    a!flatten({
      if(a!isNullOrEmpty(local!draws), {}, a!forEach(items: local!draws, expression: tointeger(fv!item['recordType!{c9d3a947-71aa-4024-879e-363873a12860}SD Draw.fields.{e418c5aa-c0db-4e02-8fb9-a4ce72ccdcef}ingestionProcessId']))),
      if(a!isNullOrEmpty(local!draws), {}, a!forEach(items: local!draws, expression: tointeger(fv!item['recordType!{c9d3a947-71aa-4024-879e-363873a12860}SD Draw.fields.{a132be23-f941-4d59-a22c-b57e29900ea6}activeStepProcessId']))),
      if(a!isNullOrEmpty(local!msgs), {}, a!forEach(items: local!msgs, expression: tointeger(fv!item['recordType!{3686a81f-86e2-498e-a4d1-ce40236c824a}SD Draw Email Message.fields.{e9c9c4c7-9917-4689-bbd9-834dfeed71d4}processId'])))
    })
  ),
  local!procDistinct: if(a!isNullOrEmpty(local!procCandidates), {}, union(tointeger(local!procCandidates), tointeger(local!procCandidates))),
  /* only processes that still hold an open task are cancelled (the task report finds it) */
  local!procOpen: if(
    a!isNullOrEmpty(local!procDistinct),
    {},
    reject(
      a!isNullOrEmpty,
      a!forEach(
        items: local!procDistinct,
        expression: if(a!isNullOrEmpty(rule!SD_getOpenTaskId(processId: fv!item)), null, fv!item)
      )
    )
  ),
  a!map(
    drawIds: local!found,
    refused: if(
      a!isNullOrEmpty(local!req),
      {},
      if(
        a!isNullOrEmpty(local!found),
        local!req,
        reject(a!isNullOrEmpty, a!forEach(items: local!req, expression: if(contains(local!found, fv!item), null, fv!item)))
      )
    ),
    drawLabels: if(
      a!isNullOrEmpty(local!draws),
      {},
      a!forEach(
        items: local!draws,
        expression: if(
          a!isNullOrEmpty(fv!item['recordType!{c9d3a947-71aa-4024-879e-363873a12860}SD Draw.fields.{9aa1030b-f76b-49aa-bef6-99eb90327804}drawNumber']),
          "draw " & fv!item['recordType!{c9d3a947-71aa-4024-879e-363873a12860}SD Draw.fields.{443829ca-5971-4d31-8fac-ab7a317e509b}id'] & " (" & fv!item['recordType!{c9d3a947-71aa-4024-879e-363873a12860}SD Draw.fields.{e63818ec-ea02-40a0-bfdd-2c14b760dc2c}status'] & ")",
          "#" & fv!item['recordType!{c9d3a947-71aa-4024-879e-363873a12860}SD Draw.fields.{9aa1030b-f76b-49aa-bef6-99eb90327804}drawNumber'] & " (draw " & fv!item['recordType!{c9d3a947-71aa-4024-879e-363873a12860}SD Draw.fields.{443829ca-5971-4d31-8fac-ab7a317e509b}id'] & ")"
        )
      )
    ),
    lineIds: local!lineIds,
    approvalIds: if(a!isNullOrEmpty(local!approvals), {}, tointeger(a!forEach(items: local!approvals, expression: fv!item['recordType!{02c207d5-c725-4d11-bf40-b33573e87ffa}SD Draw Approval.fields.{69abcdf2-55da-48dc-8cc4-794b5d5e0042}id']))),
    qiuIds: if(a!isNullOrEmpty(local!qius), {}, tointeger(a!forEach(items: local!qius, expression: fv!item['recordType!{a0920e4c-0c76-4494-a61a-6e38d5db390a}SD QIU Metric.fields.{f3d5f8f7-3ecf-4749-b749-78f2836cd65d}id']))),
    docIds: if(a!isNullOrEmpty(local!docs), {}, tointeger(a!forEach(items: local!docs, expression: fv!item['recordType!{f3e0033f-2047-4c68-8f6f-cf32166091e9}SD Draw Document.fields.{a0e2e466-e3fb-4f48-9744-481735a1ba8f}id']))),
    msgIds: if(a!isNullOrEmpty(local!msgs), {}, tointeger(a!forEach(items: local!msgs, expression: fv!item['recordType!{3686a81f-86e2-498e-a4d1-ce40236c824a}SD Draw Email Message.fields.{7d692543-d14a-44a7-b2eb-2aba819cea1f}id']))),
    eventIds: if(a!isNullOrEmpty(local!events), {}, tointeger(a!forEach(items: local!events, expression: fv!item['recordType!{ee493a87-e51b-4148-8893-26de1e924ffb}SD Draw Budget Line Event History.fields.{cbefa248-a552-4bbb-9733-d4dd1d291a99}id']))),
    processIds: if(a!isNullOrEmpty(local!procOpen), {}, tointeger(local!procOpen))
  )
)

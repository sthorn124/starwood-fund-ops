/* Draw approval (Phase 6c): the draw's budget line history — every "Edited at Approval" event on its lines, newest
   first, as maps (id, lineId, budgetCategory, account, userName, at, comment; map keys are case-insensitive, so the account is not "username") for the Budget Detail view's line history
   and its "edited by … at approval" marks. */
a!localVariables(
  local!lines: if(
    a!isNullOrEmpty(ri!drawId),
    {},
    a!queryRecordType(
      recordType: 'recordType!{ddc4073e-6372-49e2-80de-a088b424abcd}SD Draw Budget Line',
      fields: {'recordType!{ddc4073e-6372-49e2-80de-a088b424abcd}SD Draw Budget Line.fields.{14803371-b715-43a4-bc3a-94e314f16f8a}id', 'recordType!{ddc4073e-6372-49e2-80de-a088b424abcd}SD Draw Budget Line.fields.{4b8934ab-ad8e-4fc0-ac4e-86a762018dee}budgetCategory'},
      filters: a!queryFilter(field: 'recordType!{ddc4073e-6372-49e2-80de-a088b424abcd}SD Draw Budget Line.fields.{830216a5-8980-4ac0-a8f9-7baa33bbea6b}drawId', operator: "=", value: ri!drawId),
      pagingInfo: a!pagingInfo(startIndex: 1, batchSize: 100)
    ).data
  ),
  local!ids: if(a!isNullOrEmpty(local!lines), {}, a!forEach(items: local!lines, expression: tointeger(fv!item['recordType!{ddc4073e-6372-49e2-80de-a088b424abcd}SD Draw Budget Line.fields.{14803371-b715-43a4-bc3a-94e314f16f8a}id']))),
  local!events: if(
    a!isNullOrEmpty(local!ids),
    {},
    a!queryRecordType(
      recordType: 'recordType!{ee493a87-e51b-4148-8893-26de1e924ffb}SD Draw Budget Line Event History',
      fields: {'recordType!{ee493a87-e51b-4148-8893-26de1e924ffb}SD Draw Budget Line Event History.fields.{cbefa248-a552-4bbb-9733-d4dd1d291a99}id', 'recordType!{ee493a87-e51b-4148-8893-26de1e924ffb}SD Draw Budget Line Event History.fields.{7e9a52d1-8566-4199-b6b9-167488e2383e}recordId', 'recordType!{ee493a87-e51b-4148-8893-26de1e924ffb}SD Draw Budget Line Event History.fields.{61330b88-d4ce-46ea-9fe7-6a6b41eceed6}user', 'recordType!{ee493a87-e51b-4148-8893-26de1e924ffb}SD Draw Budget Line Event History.fields.{f4ee5141-fec8-4e43-bdc5-1517fd82e679}timestamp', 'recordType!{ee493a87-e51b-4148-8893-26de1e924ffb}SD Draw Budget Line Event History.fields.{b34057f7-f0af-4b64-a149-67e0a0992ee0}comment', 'recordType!{ee493a87-e51b-4148-8893-26de1e924ffb}SD Draw Budget Line Event History.fields.{ea2dea0a-3312-4fbb-bcb2-b7ab0e2994c8}eventTypeId'},
      filters: {
        a!queryFilter(field: 'recordType!{ee493a87-e51b-4148-8893-26de1e924ffb}SD Draw Budget Line Event History.fields.{7e9a52d1-8566-4199-b6b9-167488e2383e}recordId', operator: "in", value: local!ids),
        a!queryFilter(field: 'recordType!{ee493a87-e51b-4148-8893-26de1e924ffb}SD Draw Budget Line Event History.fields.{ea2dea0a-3312-4fbb-bcb2-b7ab0e2994c8}eventTypeId', operator: "=", value: cons!SD_BUDGET_EDIT_EVENT_TYPE_ID)
      },
      pagingInfo: a!pagingInfo(startIndex: 1, batchSize: 200, sort: {a!sortInfo(field: 'recordType!{ee493a87-e51b-4148-8893-26de1e924ffb}SD Draw Budget Line Event History.fields.{f4ee5141-fec8-4e43-bdc5-1517fd82e679}timestamp', ascending: false), a!sortInfo(field: 'recordType!{ee493a87-e51b-4148-8893-26de1e924ffb}SD Draw Budget Line Event History.fields.{cbefa248-a552-4bbb-9733-d4dd1d291a99}id', ascending: false)})
    ).data
  ),
  if(
    a!isNullOrEmpty(local!events),
    {},
    a!forEach(
      items: local!events,
      expression: a!localVariables(
        local!pos: wherecontains(tointeger(fv!item['recordType!{ee493a87-e51b-4148-8893-26de1e924ffb}SD Draw Budget Line Event History.fields.{7e9a52d1-8566-4199-b6b9-167488e2383e}recordId']), local!ids),
        a!map(
          id: fv!item['recordType!{ee493a87-e51b-4148-8893-26de1e924ffb}SD Draw Budget Line Event History.fields.{cbefa248-a552-4bbb-9733-d4dd1d291a99}id'],
          lineId: tointeger(fv!item['recordType!{ee493a87-e51b-4148-8893-26de1e924ffb}SD Draw Budget Line Event History.fields.{7e9a52d1-8566-4199-b6b9-167488e2383e}recordId']),
          budgetCategory: if(a!isNullOrEmpty(local!pos), "", tostring(index(local!lines, local!pos[1], null)['recordType!{ddc4073e-6372-49e2-80de-a088b424abcd}SD Draw Budget Line.fields.{4b8934ab-ad8e-4fc0-ac4e-86a762018dee}budgetCategory'])),
          account: tostring(fv!item['recordType!{ee493a87-e51b-4148-8893-26de1e924ffb}SD Draw Budget Line Event History.fields.{61330b88-d4ce-46ea-9fe7-6a6b41eceed6}user']),
          userName: rule!SD_getUserDisplayName(username: tostring(fv!item['recordType!{ee493a87-e51b-4148-8893-26de1e924ffb}SD Draw Budget Line Event History.fields.{61330b88-d4ce-46ea-9fe7-6a6b41eceed6}user'])),
          at: fv!item['recordType!{ee493a87-e51b-4148-8893-26de1e924ffb}SD Draw Budget Line Event History.fields.{f4ee5141-fec8-4e43-bdc5-1517fd82e679}timestamp'],
          comment: tostring(a!defaultValue(fv!item['recordType!{ee493a87-e51b-4148-8893-26de1e924ffb}SD Draw Budget Line Event History.fields.{b34057f7-f0af-4b64-a149-67e0a0992ee0}comment'], ""))
        )
      )
    )
  )
)

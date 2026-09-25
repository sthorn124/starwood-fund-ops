/* Draw approval (Phase 5): the last budget template that loaded successfully for an investment — the comparison baseline
   for a failed ingestion. The investment is matched by name (trimmed, case-insensitive, as the commit step matches it);
   its draws that got past ingestion (status neither Ingesting nor Ingestion Failed, the failed draw itself excluded);
   their Budget Template document rows that hold a document; the most recent (highest id) wins.
   Returns a map: found, investmentId, documentId, documentName, drawId, drawNumber, receivedDate. */
a!localVariables(
  local!name: lower(trim(a!defaultValue(ri!investmentName, ""))),
  local!investments: if(
    local!name = "",
    {},
    a!queryRecordType(
      recordType: 'recordType!{f285a98c-746c-40e7-899e-65d8d20f766b}SD Investment',
      fields: {'recordType!{f285a98c-746c-40e7-899e-65d8d20f766b}SD Investment.fields.{5739486c-cd04-4774-a878-17ca0b9933c4}id', 'recordType!{f285a98c-746c-40e7-899e-65d8d20f766b}SD Investment.fields.{e79c63ed-a43c-4951-b679-e2578ed5cbf6}investmentName'},
      pagingInfo: a!pagingInfo(startIndex: 1, batchSize: 500)
    ).data
  ),
  local!invNames: if(
    a!isNullOrEmpty(local!investments),
    {},
    a!forEach(items: local!investments, expression: lower(trim(tostring(fv!item['recordType!{f285a98c-746c-40e7-899e-65d8d20f766b}SD Investment.fields.{e79c63ed-a43c-4951-b679-e2578ed5cbf6}investmentName']))))
  ),
  local!invPos: if(a!isNullOrEmpty(local!invNames), 0, index(wherecontains(local!name, local!invNames), 1, 0)),
  local!investmentId: if(local!invPos = 0, null, index(local!investments, local!invPos, null)['recordType!{f285a98c-746c-40e7-899e-65d8d20f766b}SD Investment.fields.{5739486c-cd04-4774-a878-17ca0b9933c4}id']),
  local!draws: if(
    a!isNullOrEmpty(local!investmentId),
    {},
    a!queryRecordType(
      recordType: 'recordType!{c9d3a947-71aa-4024-879e-363873a12860}SD Draw',
      fields: {'recordType!{c9d3a947-71aa-4024-879e-363873a12860}SD Draw.fields.{443829ca-5971-4d31-8fac-ab7a317e509b}id', 'recordType!{c9d3a947-71aa-4024-879e-363873a12860}SD Draw.fields.{9aa1030b-f76b-49aa-bef6-99eb90327804}drawNumber'},
      filters: a!queryLogicalExpression(
        operator: "AND",
        filters: {
          a!queryFilter(field: 'recordType!{c9d3a947-71aa-4024-879e-363873a12860}SD Draw.fields.{09edf0b2-28a3-4a7f-b9dc-ae2afefa24d0}investmentId', operator: "=", value: local!investmentId),
          a!queryFilter(field: 'recordType!{c9d3a947-71aa-4024-879e-363873a12860}SD Draw.fields.{e63818ec-ea02-40a0-bfdd-2c14b760dc2c}status', operator: "not in", value: {"Ingesting", "Ingestion Failed"}),
          a!queryFilter(field: 'recordType!{c9d3a947-71aa-4024-879e-363873a12860}SD Draw.fields.{443829ca-5971-4d31-8fac-ab7a317e509b}id', operator: "<>", value: a!defaultValue(ri!excludeDrawId, -1))
        },
        ignoreFiltersWithEmptyValues: true
      ),
      pagingInfo: a!pagingInfo(startIndex: 1, batchSize: 500)
    ).data
  ),
  local!drawIds: if(
    a!isNullOrEmpty(local!draws),
    {},
    a!forEach(items: local!draws, expression: fv!item['recordType!{c9d3a947-71aa-4024-879e-363873a12860}SD Draw.fields.{443829ca-5971-4d31-8fac-ab7a317e509b}id'])
  ),
  local!doc: if(
    a!isNullOrEmpty(local!drawIds),
    null,
    index(
      a!queryRecordType(
        recordType: 'recordType!{f3e0033f-2047-4c68-8f6f-cf32166091e9}SD Draw Document',
        fields: {'recordType!{f3e0033f-2047-4c68-8f6f-cf32166091e9}SD Draw Document.fields.{a0e2e466-e3fb-4f48-9744-481735a1ba8f}id', 'recordType!{f3e0033f-2047-4c68-8f6f-cf32166091e9}SD Draw Document.fields.{75e7a282-935e-488c-8f72-2b32468edbfc}drawId', 'recordType!{f3e0033f-2047-4c68-8f6f-cf32166091e9}SD Draw Document.fields.{2be78aec-5184-4fd9-8c89-5eabf2bf45ad}document', 'recordType!{f3e0033f-2047-4c68-8f6f-cf32166091e9}SD Draw Document.fields.{fbdf2e7f-9289-4130-82a5-bda409cccf85}documentName', 'recordType!{f3e0033f-2047-4c68-8f6f-cf32166091e9}SD Draw Document.fields.{2e8183a8-cc80-4093-92c3-f77c04777ac5}receivedDate', 'recordType!{f3e0033f-2047-4c68-8f6f-cf32166091e9}SD Draw Document.fields.{5e348596-a740-4af9-82ac-423ed4f15b63}uploadedAt'},
        filters: a!queryLogicalExpression(
          operator: "AND",
          filters: {
            a!queryFilter(field: 'recordType!{f3e0033f-2047-4c68-8f6f-cf32166091e9}SD Draw Document.fields.{75e7a282-935e-488c-8f72-2b32468edbfc}drawId', operator: "in", value: local!drawIds),
            a!queryFilter(field: 'recordType!{f3e0033f-2047-4c68-8f6f-cf32166091e9}SD Draw Document.fields.{154ca280-0c9e-4ee5-aed2-111e441a035c}documentType', operator: "=", value: "Budget Template"),
            a!queryFilter(field: 'recordType!{f3e0033f-2047-4c68-8f6f-cf32166091e9}SD Draw Document.fields.{2be78aec-5184-4fd9-8c89-5eabf2bf45ad}document', operator: "not null")
          }
        ),
        pagingInfo: a!pagingInfo(startIndex: 1, batchSize: 1, sort: a!sortInfo(field: 'recordType!{f3e0033f-2047-4c68-8f6f-cf32166091e9}SD Draw Document.fields.{a0e2e466-e3fb-4f48-9744-481735a1ba8f}id', ascending: false))
      ).data,
      1,
      null
    )
  ),
  local!docDrawId: if(a!isNullOrEmpty(local!doc), null, local!doc['recordType!{f3e0033f-2047-4c68-8f6f-cf32166091e9}SD Draw Document.fields.{75e7a282-935e-488c-8f72-2b32468edbfc}drawId']),
  local!drawPos: if(a!isNullOrEmpty(local!docDrawId), 0, index(wherecontains(local!docDrawId, local!drawIds), 1, 0)),
  a!map(
    found: not(a!isNullOrEmpty(local!doc)),
    investmentId: local!investmentId,
    documentId: if(a!isNullOrEmpty(local!doc), null, tointeger(local!doc['recordType!{f3e0033f-2047-4c68-8f6f-cf32166091e9}SD Draw Document.fields.{2be78aec-5184-4fd9-8c89-5eabf2bf45ad}document'])),
    documentName: if(a!isNullOrEmpty(local!doc), null, local!doc['recordType!{f3e0033f-2047-4c68-8f6f-cf32166091e9}SD Draw Document.fields.{fbdf2e7f-9289-4130-82a5-bda409cccf85}documentName']),
    drawId: local!docDrawId,
    drawNumber: if(local!drawPos = 0, null, index(local!draws, local!drawPos, null)['recordType!{c9d3a947-71aa-4024-879e-363873a12860}SD Draw.fields.{9aa1030b-f76b-49aa-bef6-99eb90327804}drawNumber']),
    receivedDate: if(a!isNullOrEmpty(local!doc), null, a!defaultValue(local!doc['recordType!{f3e0033f-2047-4c68-8f6f-cf32166091e9}SD Draw Document.fields.{2e8183a8-cc80-4093-92c3-f77c04777ac5}receivedDate'], todate(local!doc['recordType!{f3e0033f-2047-4c68-8f6f-cf32166091e9}SD Draw Document.fields.{5e348596-a740-4af9-82ac-423ed4f15b63}uploadedAt'])))
  )
)

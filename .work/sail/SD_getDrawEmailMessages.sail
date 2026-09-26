/* Draw approval (Phase 6a; 6b adds decisivePhrase and senderName): a draw's email exchange, oldest first (by time,
   then id), as maps for the Emails tab and the pending-question rule. */
a!localVariables(
  local!rows: if(
    a!isNullOrEmpty(ri!drawId),
    {},
    a!queryRecordType(
      recordType: 'recordType!{3686a81f-86e2-498e-a4d1-ce40236c824a}SD Draw Email Message',
      fields: {'recordType!{3686a81f-86e2-498e-a4d1-ce40236c824a}SD Draw Email Message.fields.{7d692543-d14a-44a7-b2eb-2aba819cea1f}id', 'recordType!{3686a81f-86e2-498e-a4d1-ce40236c824a}SD Draw Email Message.fields.{2bc241c2-0f50-4ca7-aad2-5f2065c28e3e}approvalId', 'recordType!{3686a81f-86e2-498e-a4d1-ce40236c824a}SD Draw Email Message.fields.{eec43b21-b977-4527-9343-f4a9f0b2b915}stepOrder', 'recordType!{3686a81f-86e2-498e-a4d1-ce40236c824a}SD Draw Email Message.fields.{7bc67c6f-53fd-4bd1-99a1-0748c73ae443}direction', 'recordType!{3686a81f-86e2-498e-a4d1-ce40236c824a}SD Draw Email Message.fields.{e12b21b7-9fcd-4f26-9371-74db2e074a1c}kind', 'recordType!{3686a81f-86e2-498e-a4d1-ce40236c824a}SD Draw Email Message.fields.{ec1d6acb-41e9-49b5-a4df-eb40ec25a181}fromAddress', 'recordType!{3686a81f-86e2-498e-a4d1-ce40236c824a}SD Draw Email Message.fields.{add14594-0467-46b4-ac85-ad853f0dd3e0}toAddress', 'recordType!{3686a81f-86e2-498e-a4d1-ce40236c824a}SD Draw Email Message.fields.{8a51f991-924b-415f-b810-3f5452f7ea83}subject', 'recordType!{3686a81f-86e2-498e-a4d1-ce40236c824a}SD Draw Email Message.fields.{a73467a6-901c-42cd-87c2-e6f52a81dcd1}body', 'recordType!{3686a81f-86e2-498e-a4d1-ce40236c824a}SD Draw Email Message.fields.{13756bd6-152a-4c93-aba0-84269d1d5ade}messageAt', 'recordType!{3686a81f-86e2-498e-a4d1-ce40236c824a}SD Draw Email Message.fields.{ae349a0e-1ad6-4f39-ab7f-f531937147d1}outcome', 'recordType!{3686a81f-86e2-498e-a4d1-ce40236c824a}SD Draw Email Message.fields.{0aef50c3-deb5-4704-ac28-a9a3a35ae650}interpretation', 'recordType!{3686a81f-86e2-498e-a4d1-ce40236c824a}SD Draw Email Message.fields.{4c41085b-ca45-480a-bb74-ebc8e9b58299}source', 'recordType!{3686a81f-86e2-498e-a4d1-ce40236c824a}SD Draw Email Message.fields.{26ebc1a1-f628-4e0f-8e50-67a18fdd3fa4}notes', 'recordType!{3686a81f-86e2-498e-a4d1-ce40236c824a}SD Draw Email Message.fields.{9a40d4fd-6882-49ff-acf3-cf887b1bc545}decisivePhrase', 'recordType!{3686a81f-86e2-498e-a4d1-ce40236c824a}SD Draw Email Message.fields.{e014b841-d300-4065-859e-25eabb721ec7}senderName'},
      filters: a!queryFilter(field: 'recordType!{3686a81f-86e2-498e-a4d1-ce40236c824a}SD Draw Email Message.fields.{163bd929-1a5c-4862-a6b4-e64a7af2e463}drawId', operator: "=", value: ri!drawId),
      pagingInfo: a!pagingInfo(startIndex: 1, batchSize: 200, sort: {a!sortInfo(field: 'recordType!{3686a81f-86e2-498e-a4d1-ce40236c824a}SD Draw Email Message.fields.{13756bd6-152a-4c93-aba0-84269d1d5ade}messageAt', ascending: true), a!sortInfo(field: 'recordType!{3686a81f-86e2-498e-a4d1-ce40236c824a}SD Draw Email Message.fields.{7d692543-d14a-44a7-b2eb-2aba819cea1f}id', ascending: true)})
    ).data
  ),
  if(
    a!isNullOrEmpty(local!rows),
    {},
    a!forEach(
      items: local!rows,
      expression: a!map(
        id: fv!item['recordType!{3686a81f-86e2-498e-a4d1-ce40236c824a}SD Draw Email Message.fields.{7d692543-d14a-44a7-b2eb-2aba819cea1f}id'],
        approvalId: fv!item['recordType!{3686a81f-86e2-498e-a4d1-ce40236c824a}SD Draw Email Message.fields.{2bc241c2-0f50-4ca7-aad2-5f2065c28e3e}approvalId'],
        stepOrder: fv!item['recordType!{3686a81f-86e2-498e-a4d1-ce40236c824a}SD Draw Email Message.fields.{eec43b21-b977-4527-9343-f4a9f0b2b915}stepOrder'],
        direction: tostring(a!defaultValue(fv!item['recordType!{3686a81f-86e2-498e-a4d1-ce40236c824a}SD Draw Email Message.fields.{7bc67c6f-53fd-4bd1-99a1-0748c73ae443}direction'], "")),
        kind: tostring(a!defaultValue(fv!item['recordType!{3686a81f-86e2-498e-a4d1-ce40236c824a}SD Draw Email Message.fields.{e12b21b7-9fcd-4f26-9371-74db2e074a1c}kind'], "")),
        fromAddress: tostring(a!defaultValue(fv!item['recordType!{3686a81f-86e2-498e-a4d1-ce40236c824a}SD Draw Email Message.fields.{ec1d6acb-41e9-49b5-a4df-eb40ec25a181}fromAddress'], "")),
        toAddress: tostring(a!defaultValue(fv!item['recordType!{3686a81f-86e2-498e-a4d1-ce40236c824a}SD Draw Email Message.fields.{add14594-0467-46b4-ac85-ad853f0dd3e0}toAddress'], "")),
        subject: tostring(a!defaultValue(fv!item['recordType!{3686a81f-86e2-498e-a4d1-ce40236c824a}SD Draw Email Message.fields.{8a51f991-924b-415f-b810-3f5452f7ea83}subject'], "")),
        body: tostring(a!defaultValue(fv!item['recordType!{3686a81f-86e2-498e-a4d1-ce40236c824a}SD Draw Email Message.fields.{a73467a6-901c-42cd-87c2-e6f52a81dcd1}body'], "")),
        messageAt: fv!item['recordType!{3686a81f-86e2-498e-a4d1-ce40236c824a}SD Draw Email Message.fields.{13756bd6-152a-4c93-aba0-84269d1d5ade}messageAt'],
        outcome: tostring(a!defaultValue(fv!item['recordType!{3686a81f-86e2-498e-a4d1-ce40236c824a}SD Draw Email Message.fields.{ae349a0e-1ad6-4f39-ab7f-f531937147d1}outcome'], "")),
        interpretation: tostring(a!defaultValue(fv!item['recordType!{3686a81f-86e2-498e-a4d1-ce40236c824a}SD Draw Email Message.fields.{0aef50c3-deb5-4704-ac28-a9a3a35ae650}interpretation'], "")),
        source: tostring(a!defaultValue(fv!item['recordType!{3686a81f-86e2-498e-a4d1-ce40236c824a}SD Draw Email Message.fields.{4c41085b-ca45-480a-bb74-ebc8e9b58299}source'], "")),
        notes: tostring(a!defaultValue(fv!item['recordType!{3686a81f-86e2-498e-a4d1-ce40236c824a}SD Draw Email Message.fields.{26ebc1a1-f628-4e0f-8e50-67a18fdd3fa4}notes'], "")),
        decisivePhrase: tostring(a!defaultValue(fv!item['recordType!{3686a81f-86e2-498e-a4d1-ce40236c824a}SD Draw Email Message.fields.{9a40d4fd-6882-49ff-acf3-cf887b1bc545}decisivePhrase'], "")),
        senderName: tostring(a!defaultValue(fv!item['recordType!{3686a81f-86e2-498e-a4d1-ce40236c824a}SD Draw Email Message.fields.{e014b841-d300-4065-859e-25eabb721ec7}senderName'], ""))
      )
    )
  )
)

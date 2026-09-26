/* Draw approval (Phase 6a; Phase 6b adds decisivePhrase and senderName): one SD Draw Email Message row, for a Write
   Records node. Lengths are cut to the columns (from 255, subject/to/interpretation/notes/decisivePhrase 1,000,
   body 4,000, senderName 255; measured through a real Write Records node) so a long email never fails the write. */
'recordType!{3686a81f-86e2-498e-a4d1-ce40236c824a}SD Draw Email Message'(
  'recordType!{3686a81f-86e2-498e-a4d1-ce40236c824a}SD Draw Email Message.fields.{163bd929-1a5c-4862-a6b4-e64a7af2e463}drawId': ri!drawId,
  'recordType!{3686a81f-86e2-498e-a4d1-ce40236c824a}SD Draw Email Message.fields.{2bc241c2-0f50-4ca7-aad2-5f2065c28e3e}approvalId': ri!approvalId,
  'recordType!{3686a81f-86e2-498e-a4d1-ce40236c824a}SD Draw Email Message.fields.{eec43b21-b977-4527-9343-f4a9f0b2b915}stepOrder': ri!stepOrder,
  'recordType!{3686a81f-86e2-498e-a4d1-ce40236c824a}SD Draw Email Message.fields.{7bc67c6f-53fd-4bd1-99a1-0748c73ae443}direction': ri!direction,
  'recordType!{3686a81f-86e2-498e-a4d1-ce40236c824a}SD Draw Email Message.fields.{e12b21b7-9fcd-4f26-9371-74db2e074a1c}kind': ri!kind,
  'recordType!{3686a81f-86e2-498e-a4d1-ce40236c824a}SD Draw Email Message.fields.{ec1d6acb-41e9-49b5-a4df-eb40ec25a181}fromAddress': left(a!defaultValue(ri!fromAddress, ""), 255),
  'recordType!{3686a81f-86e2-498e-a4d1-ce40236c824a}SD Draw Email Message.fields.{add14594-0467-46b4-ac85-ad853f0dd3e0}toAddress': left(a!defaultValue(ri!toAddress, ""), 1000),
  'recordType!{3686a81f-86e2-498e-a4d1-ce40236c824a}SD Draw Email Message.fields.{8a51f991-924b-415f-b810-3f5452f7ea83}subject': left(a!defaultValue(ri!subject, ""), 1000),
  'recordType!{3686a81f-86e2-498e-a4d1-ce40236c824a}SD Draw Email Message.fields.{a73467a6-901c-42cd-87c2-e6f52a81dcd1}body': left(a!defaultValue(ri!body, ""), 4000),
  'recordType!{3686a81f-86e2-498e-a4d1-ce40236c824a}SD Draw Email Message.fields.{13756bd6-152a-4c93-aba0-84269d1d5ade}messageAt': a!defaultValue(ri!messageAt, now()),
  'recordType!{3686a81f-86e2-498e-a4d1-ce40236c824a}SD Draw Email Message.fields.{ae349a0e-1ad6-4f39-ab7f-f531937147d1}outcome': ri!outcome,
  'recordType!{3686a81f-86e2-498e-a4d1-ce40236c824a}SD Draw Email Message.fields.{0aef50c3-deb5-4704-ac28-a9a3a35ae650}interpretation': left(a!defaultValue(ri!interpretation, ""), 1000),
  'recordType!{3686a81f-86e2-498e-a4d1-ce40236c824a}SD Draw Email Message.fields.{4c41085b-ca45-480a-bb74-ebc8e9b58299}source': a!defaultValue(ri!source, "EMAIL"),
  'recordType!{3686a81f-86e2-498e-a4d1-ce40236c824a}SD Draw Email Message.fields.{26ebc1a1-f628-4e0f-8e50-67a18fdd3fa4}notes': left(a!defaultValue(ri!notes, ""), 1000),
  'recordType!{3686a81f-86e2-498e-a4d1-ce40236c824a}SD Draw Email Message.fields.{9a40d4fd-6882-49ff-acf3-cf887b1bc545}decisivePhrase': left(a!defaultValue(ri!decisivePhrase, ""), 1000),
  'recordType!{3686a81f-86e2-498e-a4d1-ce40236c824a}SD Draw Email Message.fields.{e014b841-d300-4065-859e-25eabb721ec7}senderName': left(a!defaultValue(ri!senderName, ""), 255)
)

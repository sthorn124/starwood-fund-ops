/* Draw approval (Phase 5.5): a draw's supporting documents (every SD Draw Document row except the Budget Template),
   oldest first, as maps: rowId, document, name, type, status, amount, party, reference, notes. */
if(
  a!isNullOrEmpty(ri!drawId),
  {},
  a!localVariables(
    local!raw: a!queryRecordType(
      recordType: 'recordType!{f3e0033f-2047-4c68-8f6f-cf32166091e9}SD Draw Document',
      fields: {'recordType!{f3e0033f-2047-4c68-8f6f-cf32166091e9}SD Draw Document.fields.{a0e2e466-e3fb-4f48-9744-481735a1ba8f}id', 'recordType!{f3e0033f-2047-4c68-8f6f-cf32166091e9}SD Draw Document.fields.{2be78aec-5184-4fd9-8c89-5eabf2bf45ad}document', 'recordType!{f3e0033f-2047-4c68-8f6f-cf32166091e9}SD Draw Document.fields.{fbdf2e7f-9289-4130-82a5-bda409cccf85}documentName', 'recordType!{f3e0033f-2047-4c68-8f6f-cf32166091e9}SD Draw Document.fields.{154ca280-0c9e-4ee5-aed2-111e441a035c}documentType', 'recordType!{f3e0033f-2047-4c68-8f6f-cf32166091e9}SD Draw Document.fields.{2863739f-c94b-4f6c-804a-b0fcef1572f7}status', 'recordType!{f3e0033f-2047-4c68-8f6f-cf32166091e9}SD Draw Document.fields.{bdb3e5b5-4258-4f86-b966-c93ecc1bdc74}extractedAmount', 'recordType!{f3e0033f-2047-4c68-8f6f-cf32166091e9}SD Draw Document.fields.{2d16e3e7-0168-4871-8914-27372cd42cae}extractedParty', 'recordType!{f3e0033f-2047-4c68-8f6f-cf32166091e9}SD Draw Document.fields.{3f4fdc48-d009-425e-a793-b5a4e83f2a76}extractedReference', 'recordType!{f3e0033f-2047-4c68-8f6f-cf32166091e9}SD Draw Document.fields.{2b7e89b7-8344-41ad-a71f-9bfb117a9e0c}notes'},
      filters: a!queryLogicalExpression(
        operator: "AND",
        filters: {
          a!queryFilter(field: 'recordType!{f3e0033f-2047-4c68-8f6f-cf32166091e9}SD Draw Document.fields.{75e7a282-935e-488c-8f72-2b32468edbfc}drawId', operator: "=", value: ri!drawId),
          a!queryFilter(field: 'recordType!{f3e0033f-2047-4c68-8f6f-cf32166091e9}SD Draw Document.fields.{154ca280-0c9e-4ee5-aed2-111e441a035c}documentType', operator: "<>", value: "Budget Template")
        }
      ),
      pagingInfo: a!pagingInfo(startIndex: 1, batchSize: 50, sort: a!sortInfo(field: 'recordType!{f3e0033f-2047-4c68-8f6f-cf32166091e9}SD Draw Document.fields.{a0e2e466-e3fb-4f48-9744-481735a1ba8f}id', ascending: true))
    ).data,
    if(
      a!isNullOrEmpty(local!raw),
      {},
      a!forEach(
        items: local!raw,
        expression: a!map(
          rowId: fv!item['recordType!{f3e0033f-2047-4c68-8f6f-cf32166091e9}SD Draw Document.fields.{a0e2e466-e3fb-4f48-9744-481735a1ba8f}id'],
          document: fv!item['recordType!{f3e0033f-2047-4c68-8f6f-cf32166091e9}SD Draw Document.fields.{2be78aec-5184-4fd9-8c89-5eabf2bf45ad}document'],
          name: tostring(a!defaultValue(fv!item['recordType!{f3e0033f-2047-4c68-8f6f-cf32166091e9}SD Draw Document.fields.{fbdf2e7f-9289-4130-82a5-bda409cccf85}documentName'], "")),
          type: tostring(a!defaultValue(fv!item['recordType!{f3e0033f-2047-4c68-8f6f-cf32166091e9}SD Draw Document.fields.{154ca280-0c9e-4ee5-aed2-111e441a035c}documentType'], "Backup")),
          status: tostring(a!defaultValue(fv!item['recordType!{f3e0033f-2047-4c68-8f6f-cf32166091e9}SD Draw Document.fields.{2863739f-c94b-4f6c-804a-b0fcef1572f7}status'], "")),
          amount: fv!item['recordType!{f3e0033f-2047-4c68-8f6f-cf32166091e9}SD Draw Document.fields.{bdb3e5b5-4258-4f86-b966-c93ecc1bdc74}extractedAmount'],
          party: tostring(a!defaultValue(fv!item['recordType!{f3e0033f-2047-4c68-8f6f-cf32166091e9}SD Draw Document.fields.{2d16e3e7-0168-4871-8914-27372cd42cae}extractedParty'], "")),
          reference: tostring(a!defaultValue(fv!item['recordType!{f3e0033f-2047-4c68-8f6f-cf32166091e9}SD Draw Document.fields.{3f4fdc48-d009-425e-a793-b5a4e83f2a76}extractedReference'], "")),
          notes: tostring(a!defaultValue(fv!item['recordType!{f3e0033f-2047-4c68-8f6f-cf32166091e9}SD Draw Document.fields.{2b7e89b7-8344-41ad-a71f-9bfb117a9e0c}notes'], ""))
        )
      )
    )
  )
)

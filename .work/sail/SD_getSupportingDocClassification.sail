/* Draw approval (Phase 5.6): the Doc Center classification of one supporting document — the newest AIA Classification
   Instance whose documentId or sourceDocumentId is the document (read right after the synchronous run of
   AIA Classification Run Model Version, whose instance is not an output that can be mapped over the Dev MCP).
   Returns a map: found, instanceId, modelVersionId, classification, confidence (null on this instance's Generative AI
   path, measured 2026-09-25), reasoning, statusId, aiActions, createdOn, modifiedOn, validationErrors. */
a!localVariables(
  local!docId: if(a!isNullOrEmpty(ri!document), null, tointeger(ri!document)),
  local!row: if(
    a!isNullOrEmpty(local!docId),
    null,
    index(
      a!queryRecordType(
        recordType: 'recordType!{bba819fb-55a0-47e1-bb74-e385f32b6916}AIA Classification Instance',
        fields: {'recordType!{bba819fb-55a0-47e1-bb74-e385f32b6916}AIA Classification Instance.fields.{c37dcf0a-9121-412d-815c-9cf8ab808987}id', 'recordType!{bba819fb-55a0-47e1-bb74-e385f32b6916}AIA Classification Instance.fields.{e2128500-29b6-4143-8739-a1fb810aa4b4}modelVersionId', 'recordType!{bba819fb-55a0-47e1-bb74-e385f32b6916}AIA Classification Instance.fields.{309857f9-08b4-4e1f-8f58-7056d45924cb}documentId', 'recordType!{bba819fb-55a0-47e1-bb74-e385f32b6916}AIA Classification Instance.fields.{3664ec70-c5b8-41fa-94a3-54992698d10c}sourceDocumentId', 'recordType!{bba819fb-55a0-47e1-bb74-e385f32b6916}AIA Classification Instance.fields.{eafba38c-479c-41cc-8401-9a7780c56ef0}statusId', 'recordType!{bba819fb-55a0-47e1-bb74-e385f32b6916}AIA Classification Instance.fields.{498f9d66-55b7-4ce7-962e-0d095106af90}confidence', 'recordType!{bba819fb-55a0-47e1-bb74-e385f32b6916}AIA Classification Instance.fields.{ae0890a9-a317-4434-a2b3-4027d6a656a2}classification', 'recordType!{bba819fb-55a0-47e1-bb74-e385f32b6916}AIA Classification Instance.fields.{16671b78-1d60-4ca6-b194-760009222ccc}reasoning', 'recordType!{bba819fb-55a0-47e1-bb74-e385f32b6916}AIA Classification Instance.fields.{7d9c4763-62fe-46fa-8099-ef08097412b4}aiActions', 'recordType!{bba819fb-55a0-47e1-bb74-e385f32b6916}AIA Classification Instance.fields.{de53ac81-f96e-4387-8313-5367745dd474}createdOn', 'recordType!{bba819fb-55a0-47e1-bb74-e385f32b6916}AIA Classification Instance.fields.{892e8449-13f0-4e4c-b3ce-ab062ced1b4c}modifiedOn', 'recordType!{bba819fb-55a0-47e1-bb74-e385f32b6916}AIA Classification Instance.fields.{1ae570c0-eff6-4684-a33d-fd2902f3faa5}validationErrors'},
        filters: a!queryLogicalExpression(
          operator: "OR",
          filters: {
            a!queryFilter(field: 'recordType!{bba819fb-55a0-47e1-bb74-e385f32b6916}AIA Classification Instance.fields.{309857f9-08b4-4e1f-8f58-7056d45924cb}documentId', operator: "=", value: local!docId),
            a!queryFilter(field: 'recordType!{bba819fb-55a0-47e1-bb74-e385f32b6916}AIA Classification Instance.fields.{3664ec70-c5b8-41fa-94a3-54992698d10c}sourceDocumentId', operator: "=", value: local!docId)
          }
        ),
        pagingInfo: a!pagingInfo(startIndex: 1, batchSize: 1, sort: a!sortInfo(field: 'recordType!{bba819fb-55a0-47e1-bb74-e385f32b6916}AIA Classification Instance.fields.{c37dcf0a-9121-412d-815c-9cf8ab808987}id', ascending: false))
      ).data,
      1,
      null
    )
  ),
  if(
    a!isNullOrEmpty(local!row),
    a!map(found: false),
    a!map(
      found: true,
      instanceId: local!row['recordType!{bba819fb-55a0-47e1-bb74-e385f32b6916}AIA Classification Instance.fields.{c37dcf0a-9121-412d-815c-9cf8ab808987}id'],
      modelVersionId: local!row['recordType!{bba819fb-55a0-47e1-bb74-e385f32b6916}AIA Classification Instance.fields.{e2128500-29b6-4143-8739-a1fb810aa4b4}modelVersionId'],
      classification: tostring(a!defaultValue(local!row['recordType!{bba819fb-55a0-47e1-bb74-e385f32b6916}AIA Classification Instance.fields.{ae0890a9-a317-4434-a2b3-4027d6a656a2}classification'], "")),
      confidence: local!row['recordType!{bba819fb-55a0-47e1-bb74-e385f32b6916}AIA Classification Instance.fields.{498f9d66-55b7-4ce7-962e-0d095106af90}confidence'],
      reasoning: tostring(a!defaultValue(local!row['recordType!{bba819fb-55a0-47e1-bb74-e385f32b6916}AIA Classification Instance.fields.{16671b78-1d60-4ca6-b194-760009222ccc}reasoning'], "")),
      statusId: local!row['recordType!{bba819fb-55a0-47e1-bb74-e385f32b6916}AIA Classification Instance.fields.{eafba38c-479c-41cc-8401-9a7780c56ef0}statusId'],
      aiActions: a!defaultValue(local!row['recordType!{bba819fb-55a0-47e1-bb74-e385f32b6916}AIA Classification Instance.fields.{7d9c4763-62fe-46fa-8099-ef08097412b4}aiActions'], 0),
      createdOn: local!row['recordType!{bba819fb-55a0-47e1-bb74-e385f32b6916}AIA Classification Instance.fields.{de53ac81-f96e-4387-8313-5367745dd474}createdOn'],
      modifiedOn: local!row['recordType!{bba819fb-55a0-47e1-bb74-e385f32b6916}AIA Classification Instance.fields.{892e8449-13f0-4e4c-b3ce-ab062ced1b4c}modifiedOn'],
      validationErrors: tostring(a!defaultValue(local!row['recordType!{bba819fb-55a0-47e1-bb74-e385f32b6916}AIA Classification Instance.fields.{1ae570c0-eff6-4684-a33d-fd2902f3faa5}validationErrors'], ""))
    )
  )
)

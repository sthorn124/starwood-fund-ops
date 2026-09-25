/* Draw approval (Phase 5.6): Doc Center's extraction of one pay application — the newest AIA Extraction Instance for
   the document (rule!SD_getExtractionInstanceIdForDocument) with its status, AI actions and timestamps, and the values
   through DocCenter's public rule AIA_API_Extraction_ConvertInstanceIdToMap (model sdPayApplication: contractorName,
   applicationNumber, currentPaymentDue, each as printed).
   Returns a map: found, instanceId, statusId, aiActions, createdOn, modifiedOn, validationErrors, contractorName,
   applicationNumber, currentPaymentDue. */
a!localVariables(
  local!instanceId: rule!SD_getExtractionInstanceIdForDocument(document: ri!document),
  local!row: if(
    a!isNullOrEmpty(local!instanceId),
    null,
    index(
      a!queryRecordType(
        recordType: 'recordType!{64322398-e457-4695-87d5-09794164cf77}AIA Extraction Instance',
        fields: {'recordType!{64322398-e457-4695-87d5-09794164cf77}AIA Extraction Instance.fields.{7a1970b4-ae29-4d49-96d5-3659721cff16}id', 'recordType!{64322398-e457-4695-87d5-09794164cf77}AIA Extraction Instance.fields.{d0b39390-3147-451b-b49e-f4256e466577}statusId', 'recordType!{64322398-e457-4695-87d5-09794164cf77}AIA Extraction Instance.fields.{4905bbe8-7240-4898-b52b-0badf6c3540f}aiActions', 'recordType!{64322398-e457-4695-87d5-09794164cf77}AIA Extraction Instance.fields.{c821645a-28b5-41c7-821b-85af4119c6be}createdOn', 'recordType!{64322398-e457-4695-87d5-09794164cf77}AIA Extraction Instance.fields.{90898700-0cd9-41db-bf2c-ece3656b815c}modifiedOn', 'recordType!{64322398-e457-4695-87d5-09794164cf77}AIA Extraction Instance.fields.{b597f1b0-ea3e-4f5c-8a7f-ae999e66f407}modelVersionId', 'recordType!{64322398-e457-4695-87d5-09794164cf77}AIA Extraction Instance.fields.{34d54369-4e12-400c-aad0-f4c538673a07}validationErrors'},
        filters: a!queryFilter(field: 'recordType!{64322398-e457-4695-87d5-09794164cf77}AIA Extraction Instance.fields.{7a1970b4-ae29-4d49-96d5-3659721cff16}id', operator: "=", value: local!instanceId),
        pagingInfo: a!pagingInfo(startIndex: 1, batchSize: 1)
      ).data,
      1,
      null
    )
  ),
  local!values: if(a!isNullOrEmpty(local!instanceId), a!map(), rule!AIA_API_Extraction_ConvertInstanceIdToMap(instanceId: local!instanceId)),
  if(
    a!isNullOrEmpty(local!row),
    a!map(found: false),
    a!map(
      found: true,
      instanceId: local!instanceId,
      statusId: local!row['recordType!{64322398-e457-4695-87d5-09794164cf77}AIA Extraction Instance.fields.{d0b39390-3147-451b-b49e-f4256e466577}statusId'],
      aiActions: a!defaultValue(local!row['recordType!{64322398-e457-4695-87d5-09794164cf77}AIA Extraction Instance.fields.{4905bbe8-7240-4898-b52b-0badf6c3540f}aiActions'], 0),
      createdOn: local!row['recordType!{64322398-e457-4695-87d5-09794164cf77}AIA Extraction Instance.fields.{c821645a-28b5-41c7-821b-85af4119c6be}createdOn'],
      modifiedOn: local!row['recordType!{64322398-e457-4695-87d5-09794164cf77}AIA Extraction Instance.fields.{90898700-0cd9-41db-bf2c-ece3656b815c}modifiedOn'],
      validationErrors: tostring(a!defaultValue(local!row['recordType!{64322398-e457-4695-87d5-09794164cf77}AIA Extraction Instance.fields.{34d54369-4e12-400c-aad0-f4c538673a07}validationErrors'], "")),
      contractorName: trim(tostring(a!defaultValue(index(local!values, "contractorName", ""), ""))),
      applicationNumber: trim(tostring(a!defaultValue(index(local!values, "applicationNumber", ""), ""))),
      currentPaymentDue: trim(tostring(a!defaultValue(index(local!values, "currentPaymentDue", ""), "")))
    )
  )
)

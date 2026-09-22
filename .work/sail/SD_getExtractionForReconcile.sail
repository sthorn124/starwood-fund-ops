/* Draw approval (Phase 3): what the accountant's reconciliation task needs from one Doc Center extraction instance.
   Values come from Doc Center's own API rule (AIA_API_Extraction_ConvertInstanceIdToMap: override-or-extracted, typed
   per model field, table rows as maps keyed by column key); confidence comes from the AIA Extraction Instance Field rows
   (0-100 per header field) and the row-level minimum for the budget table. Everything is returned as text so it can
   travel through process variables and JSON without type loss; the commit rules parse it back.
   Returns a map: found, instanceId, documentId, header (list of {key, label, value, confidence}), lines (list of maps,
   one per budget row, the nine column keys as text plus lineOrder and confidence), headerJson, linesJson. */
a!localVariables(
  local!hasId: not(a!isNullOrEmpty(ri!instanceId)),
  local!instance: if(
    not(local!hasId),
    null,
    index(
      a!queryRecordType(
        recordType: 'recordType!{64322398-e457-4695-87d5-09794164cf77}AIA Extraction Instance',
        fields: {
          'recordType!{64322398-e457-4695-87d5-09794164cf77}AIA Extraction Instance.fields.{7a1970b4-ae29-4d49-96d5-3659721cff16}id',
          'recordType!{64322398-e457-4695-87d5-09794164cf77}AIA Extraction Instance.fields.{507e0674-64d1-4f82-9bed-13d283c9d410}documentId',
          'recordType!{64322398-e457-4695-87d5-09794164cf77}AIA Extraction Instance.fields.{b597f1b0-ea3e-4f5c-8a7f-ae999e66f407}modelVersionId',
          'recordType!{64322398-e457-4695-87d5-09794164cf77}AIA Extraction Instance.fields.{d0b39390-3147-451b-b49e-f4256e466577}statusId'
        },
        filters: a!queryFilter(
          field: 'recordType!{64322398-e457-4695-87d5-09794164cf77}AIA Extraction Instance.fields.{7a1970b4-ae29-4d49-96d5-3659721cff16}id',
          operator: "=",
          value: ri!instanceId
        ),
        pagingInfo: a!pagingInfo(startIndex: 1, batchSize: 1)
      ).data,
      1,
      null
    )
  ),
  local!found: not(a!isNullOrEmpty(local!instance)),
  local!values: if(local!found, rule!AIA_API_Extraction_ConvertInstanceIdToMap(instanceId: ri!instanceId), a!map()),
  local!instFields: if(
    not(local!found),
    {},
    a!queryRecordType(
      recordType: 'recordType!{7c86b423-dc7a-4a37-980a-5600d4d9e298}AIA Extraction Instance Field',
      fields: {
        'recordType!{7c86b423-dc7a-4a37-980a-5600d4d9e298}AIA Extraction Instance Field.fields.{dc571a64-df39-4441-ac02-863e0984713f}id',
        'recordType!{7c86b423-dc7a-4a37-980a-5600d4d9e298}AIA Extraction Instance Field.fields.{1c3af4ab-31d8-4a80-b499-2c4c7b19aaba}confidence',
        'recordType!{7c86b423-dc7a-4a37-980a-5600d4d9e298}AIA Extraction Instance Field.relationships.{c0e1e855-dc32-4468-ba94-97b027839510}modelVersionField.fields.{ed32edda-9ac0-476c-b19c-ec552b6452c4}key',
        'recordType!{7c86b423-dc7a-4a37-980a-5600d4d9e298}AIA Extraction Instance Field.relationships.{c0e1e855-dc32-4468-ba94-97b027839510}modelVersionField.fields.{f08edd42-4368-4328-9b0e-90b0dc25b9b1}label',
        'recordType!{7c86b423-dc7a-4a37-980a-5600d4d9e298}AIA Extraction Instance Field.relationships.{c0e1e855-dc32-4468-ba94-97b027839510}modelVersionField.fields.{b7f55314-b6cd-432d-8772-3ce35eef1547}type'
      },
      filters: a!queryFilter(
        field: 'recordType!{7c86b423-dc7a-4a37-980a-5600d4d9e298}AIA Extraction Instance Field.fields.{576d727d-66ff-436a-a6d9-9ff8ed1a4e4b}instanceId',
        operator: "=",
        value: ri!instanceId
      ),
      pagingInfo: a!pagingInfo(
        startIndex: 1,
        batchSize: 200,
        sort: a!sortInfo(
          field: 'recordType!{7c86b423-dc7a-4a37-980a-5600d4d9e298}AIA Extraction Instance Field.fields.{dc571a64-df39-4441-ac02-863e0984713f}id',
          ascending: true
        )
      )
    ).data
  ),
  local!fieldKeys: a!forEach(
    items: local!instFields,
    expression: tostring(a!defaultValue(fv!item['recordType!{7c86b423-dc7a-4a37-980a-5600d4d9e298}AIA Extraction Instance Field.relationships.{c0e1e855-dc32-4468-ba94-97b027839510}modelVersionField.fields.{ed32edda-9ac0-476c-b19c-ec552b6452c4}key'], ""))
  ),
  local!headerKeys: {
    "drawNumber", "investmentName", "fund", "drawType", "fundingDate", "drawAmount", "cashEquityNeeded",
    "budgetStatus", "overBudgetReason", "purpose", "contingencyExplanation", "generalComments", "submittedBy"
  },
  local!lineKeys: {
    "budgetCategory", "initialBudget", "revisedApprovedBudget", "proposedAdjustmentsThisDraw", "proposedBudget",
    "currentDraw", "totalPtdIncThisDrawAmount", "totalPtdIncThisDrawPct", "balanceToComplete"
  },
  local!header: a!forEach(
    items: local!headerKeys,
    expression: a!localVariables(
      local!key: fv!item,
      local!idx: if(a!isNullOrEmpty(local!fieldKeys), {}, wherecontains(local!key, local!fieldKeys)),
      local!field: if(a!isNullOrEmpty(local!idx), null, index(local!instFields, local!idx[1], null)),
      local!raw: index(local!values, local!key, null),
      a!map(
        key: local!key,
        label: if(
          a!isNullOrEmpty(local!field),
          local!key,
          tostring(a!defaultValue(local!field['recordType!{7c86b423-dc7a-4a37-980a-5600d4d9e298}AIA Extraction Instance Field.relationships.{c0e1e855-dc32-4468-ba94-97b027839510}modelVersionField.fields.{f08edd42-4368-4328-9b0e-90b0dc25b9b1}label'], local!key))
        ),
        value: rule!SD_extractedValueToText(value: local!raw),
        confidence: if(
          a!isNullOrEmpty(local!field),
          null,
          local!field['recordType!{7c86b423-dc7a-4a37-980a-5600d4d9e298}AIA Extraction Instance Field.fields.{1c3af4ab-31d8-4a80-b499-2c4c7b19aaba}confidence']
        )
      )
    )
  ),
  local!tableIdx: if(a!isNullOrEmpty(local!fieldKeys), {}, wherecontains("budgetLines", local!fieldKeys)),
  local!tableFieldId: if(
    a!isNullOrEmpty(local!tableIdx),
    null,
    index(local!instFields, local!tableIdx[1], null)['recordType!{7c86b423-dc7a-4a37-980a-5600d4d9e298}AIA Extraction Instance Field.fields.{dc571a64-df39-4441-ac02-863e0984713f}id']
  ),
  local!rowRecords: if(
    a!isNullOrEmpty(local!tableFieldId),
    {},
    a!queryRecordType(
      recordType: 'recordType!{5255751a-b246-4369-98dd-e8e244f707e5}AIA Extraction Instance Field Row',
      fields: {
        'recordType!{5255751a-b246-4369-98dd-e8e244f707e5}AIA Extraction Instance Field Row.fields.{417f6cda-5109-485f-a028-2a9306a94688}id',
        'recordType!{5255751a-b246-4369-98dd-e8e244f707e5}AIA Extraction Instance Field Row.fields.{3704b788-459f-4c26-ab5a-acd68ef00d31}overrideValue',
        'recordType!{5255751a-b246-4369-98dd-e8e244f707e5}AIA Extraction Instance Field Row.fields.{1a581151-dc03-4927-83df-8e851191cbcd}confidenceMin'
      },
      filters: a!queryFilter(
        field: 'recordType!{5255751a-b246-4369-98dd-e8e244f707e5}AIA Extraction Instance Field Row.fields.{55a77fa6-1226-459e-a982-afe253a62637}instanceFieldId',
        operator: "=",
        value: local!tableFieldId
      ),
      pagingInfo: a!pagingInfo(
        startIndex: 1,
        batchSize: 500,
        sort: a!sortInfo(
          field: 'recordType!{5255751a-b246-4369-98dd-e8e244f707e5}AIA Extraction Instance Field Row.fields.{417f6cda-5109-485f-a028-2a9306a94688}id',
          ascending: true
        )
      )
    ).data
  ),
  local!rowConfidences: a!forEach(
    items: local!rowRecords,
    expression: fv!item['recordType!{5255751a-b246-4369-98dd-e8e244f707e5}AIA Extraction Instance Field Row.fields.{1a581151-dc03-4927-83df-8e851191cbcd}confidenceMin']
  ),
  local!rawRows: a!defaultValue(index(local!values, "budgetLines", {}), {}),
  local!lines: a!forEach(
    items: local!rawRows,
    expression: a!localVariables(
      local!row: fv!item,
      local!pos: fv!index,
      reduce(
        a!update(_, _, _),
        a!map(lineOrder: local!pos, confidence: index(local!rowConfidences, local!pos, null)),
        merge(
          local!lineKeys,
          a!forEach(items: local!lineKeys, expression: rule!SD_extractedValueToText(value: index(local!row, fv!item, null)))
        )
      )
    )
  ),
  a!map(
    found: local!found,
    instanceId: ri!instanceId,
    documentId: if(local!found, local!instance['recordType!{64322398-e457-4695-87d5-09794164cf77}AIA Extraction Instance.fields.{507e0674-64d1-4f82-9bed-13d283c9d410}documentId'], null),
    statusId: if(local!found, local!instance['recordType!{64322398-e457-4695-87d5-09794164cf77}AIA Extraction Instance.fields.{d0b39390-3147-451b-b49e-f4256e466577}statusId'], null),
    header: local!header,
    lines: local!lines,
    headerJson: a!toJson(local!header),
    linesJson: if(a!isNullOrEmpty(local!lines), "[]", a!toJson(local!lines))
  )
)

/* Draw approval (Phase 5.5): corroboration for a draw as committed — its supporting documents against its committed
   budget lines. Used by SD Receive Capital Call after confirm (node 44) to write the result onto the draw. */
a!localVariables(
  local!lines: if(
    a!isNullOrEmpty(ri!drawId),
    {},
    a!queryRecordType(
      recordType: 'recordType!{ddc4073e-6372-49e2-80de-a088b424abcd}SD Draw Budget Line',
      fields: {'recordType!{ddc4073e-6372-49e2-80de-a088b424abcd}SD Draw Budget Line.fields.{4b8934ab-ad8e-4fc0-ac4e-86a762018dee}budgetCategory', 'recordType!{ddc4073e-6372-49e2-80de-a088b424abcd}SD Draw Budget Line.fields.{5242c9d6-c607-43c9-900c-756163dcbae5}currentDraw', 'recordType!{ddc4073e-6372-49e2-80de-a088b424abcd}SD Draw Budget Line.fields.{2dd34362-59f3-46ad-bb7b-12f44273015e}lineOrder'},
      filters: a!queryFilter(field: 'recordType!{ddc4073e-6372-49e2-80de-a088b424abcd}SD Draw Budget Line.fields.{830216a5-8980-4ac0-a8f9-7baa33bbea6b}drawId', operator: "=", value: ri!drawId),
      pagingInfo: a!pagingInfo(startIndex: 1, batchSize: 100, sort: a!sortInfo(field: 'recordType!{ddc4073e-6372-49e2-80de-a088b424abcd}SD Draw Budget Line.fields.{2dd34362-59f3-46ad-bb7b-12f44273015e}lineOrder', ascending: true))
    ).data
  ),
  rule!SD_corroborateDocuments(
    documents: rule!SD_getSupportingDocuments(drawId: ri!drawId),
    lineCategories: if(a!isNullOrEmpty(local!lines), {}, a!forEach(items: local!lines, expression: tostring(fv!item['recordType!{ddc4073e-6372-49e2-80de-a088b424abcd}SD Draw Budget Line.fields.{4b8934ab-ad8e-4fc0-ac4e-86a762018dee}budgetCategory']))),
    lineCurrentDraws: if(a!isNullOrEmpty(local!lines), {}, a!forEach(items: local!lines, expression: a!defaultValue(fv!item['recordType!{ddc4073e-6372-49e2-80de-a088b424abcd}SD Draw Budget Line.fields.{5242c9d6-c607-43c9-900c-756163dcbae5}currentDraw'], 0)))
  )
)

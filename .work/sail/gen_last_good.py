from refs import *
d = lambda n: fld(DRAW, n)
c = lambda n: fld(DOC, n)
i = lambda n: fld(INV, n)
T = r'''/* Draw approval (Phase 5): the last budget template that loaded successfully for an investment — the comparison baseline
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
      recordType: @INV@,
      fields: {@INV_ID@, @INV_NAME@},
      pagingInfo: a!pagingInfo(startIndex: 1, batchSize: 500)
    ).data
  ),
  local!invNames: if(
    a!isNullOrEmpty(local!investments),
    {},
    a!forEach(items: local!investments, expression: lower(trim(tostring(fv!item[@INV_NAME@]))))
  ),
  local!invPos: if(a!isNullOrEmpty(local!invNames), 0, index(wherecontains(local!name, local!invNames), 1, 0)),
  local!investmentId: if(local!invPos = 0, null, index(local!investments, local!invPos, null)[@INV_ID@]),
  local!draws: if(
    a!isNullOrEmpty(local!investmentId),
    {},
    a!queryRecordType(
      recordType: @DRAW@,
      fields: {@D_ID@, @D_NUM@},
      filters: a!queryLogicalExpression(
        operator: "AND",
        filters: {
          a!queryFilter(field: @D_INV@, operator: "=", value: local!investmentId),
          a!queryFilter(field: @D_STATUS@, operator: "not in", value: {"Ingesting", "Ingestion Failed"}),
          a!queryFilter(field: @D_ID@, operator: "<>", value: a!defaultValue(ri!excludeDrawId, -1))
        },
        ignoreFiltersWithEmptyValues: true
      ),
      pagingInfo: a!pagingInfo(startIndex: 1, batchSize: 500)
    ).data
  ),
  local!drawIds: if(
    a!isNullOrEmpty(local!draws),
    {},
    a!forEach(items: local!draws, expression: fv!item[@D_ID@])
  ),
  local!doc: if(
    a!isNullOrEmpty(local!drawIds),
    null,
    index(
      a!queryRecordType(
        recordType: @DOC@,
        fields: {@C_ID@, @C_DRAW@, @C_DOCUMENT@, @C_NAME@, @C_RECEIVED@, @C_UPLOADED@},
        filters: a!queryLogicalExpression(
          operator: "AND",
          filters: {
            a!queryFilter(field: @C_DRAW@, operator: "in", value: local!drawIds),
            a!queryFilter(field: @C_TYPE@, operator: "=", value: "Budget Template"),
            a!queryFilter(field: @C_DOCUMENT@, operator: "not null")
          }
        ),
        pagingInfo: a!pagingInfo(startIndex: 1, batchSize: 1, sort: a!sortInfo(field: @C_ID@, ascending: false))
      ).data,
      1,
      null
    )
  ),
  local!docDrawId: if(a!isNullOrEmpty(local!doc), null, local!doc[@C_DRAW@]),
  local!drawPos: if(a!isNullOrEmpty(local!docDrawId), 0, index(wherecontains(local!docDrawId, local!drawIds), 1, 0)),
  a!map(
    found: not(a!isNullOrEmpty(local!doc)),
    investmentId: local!investmentId,
    documentId: if(a!isNullOrEmpty(local!doc), null, tointeger(local!doc[@C_DOCUMENT@])),
    documentName: if(a!isNullOrEmpty(local!doc), null, local!doc[@C_NAME@]),
    drawId: local!docDrawId,
    drawNumber: if(local!drawPos = 0, null, index(local!draws, local!drawPos, null)[@D_NUM@]),
    receivedDate: if(a!isNullOrEmpty(local!doc), null, a!defaultValue(local!doc[@C_RECEIVED@], todate(local!doc[@C_UPLOADED@])))
  )
)
'''
subs = {"@INV@": rt(INV), "@INV_ID@": i("id"), "@INV_NAME@": i("investmentName"),
        "@DRAW@": rt(DRAW), "@D_ID@": d("id"), "@D_NUM@": d("drawNumber"), "@D_INV@": d("investmentId"), "@D_STATUS@": d("status"),
        "@DOC@": rt(DOC), "@C_ID@": c("id"), "@C_DRAW@": c("drawId"), "@C_DOCUMENT@": c("document"), "@C_NAME@": c("documentName"),
        "@C_RECEIVED@": c("receivedDate"), "@C_UPLOADED@": c("uploadedAt"), "@C_TYPE@": c("documentType")}
for k, v in subs.items():
    T = T.replace(k, v)
assert "@" not in T.replace("@appian", "")
open("SD_getLastGoodTemplate.sail", "w").write(T)
print("written", len(T))

/* Draw approval (Phase 3): the newest Doc Center extraction instance for a document (matched on documentId or
   sourceDocumentId), or null. Used right after the synchronous AIA Extraction Run Model Version call, whose
   ExtractionInstance output is not mappable over the Dev MCP (it is not a parameter of that model). */
a!localVariables(
  local!docId: if(a!isNullOrEmpty(ri!document), null, tointeger(ri!document)),
  local!rows: if(
    a!isNullOrEmpty(local!docId),
    {},
    a!queryRecordType(
      recordType: 'recordType!{64322398-e457-4695-87d5-09794164cf77}AIA Extraction Instance',
      fields: {
        'recordType!{64322398-e457-4695-87d5-09794164cf77}AIA Extraction Instance.fields.{7a1970b4-ae29-4d49-96d5-3659721cff16}id'
      },
      filters: a!queryLogicalExpression(
        operator: "OR",
        filters: {
          a!queryFilter(
            field: 'recordType!{64322398-e457-4695-87d5-09794164cf77}AIA Extraction Instance.fields.{507e0674-64d1-4f82-9bed-13d283c9d410}documentId',
            operator: "=",
            value: local!docId
          ),
          a!queryFilter(
            field: 'recordType!{64322398-e457-4695-87d5-09794164cf77}AIA Extraction Instance.fields.{7fd35d67-9a78-4cf1-b78d-6ee582af1222}sourceDocumentId',
            operator: "=",
            value: local!docId
          )
        }
      ),
      pagingInfo: a!pagingInfo(
        startIndex: 1,
        batchSize: 1,
        sort: a!sortInfo(
          field: 'recordType!{64322398-e457-4695-87d5-09794164cf77}AIA Extraction Instance.fields.{7a1970b4-ae29-4d49-96d5-3659721cff16}id',
          ascending: false
        )
      )
    ).data
  ),
  if(
    a!isNullOrEmpty(local!rows),
    null,
    index(local!rows, 1, null)['recordType!{64322398-e457-4695-87d5-09794164cf77}AIA Extraction Instance.fields.{7a1970b4-ae29-4d49-96d5-3659721cff16}id']
  )
)

/* Draw approval: the Documents view of a draw record (mockups/draw-summary.html, Documents tab).
   Source template and backup rows: name (a download link when the file is attached), type, status chip, received, notes.
   Rows seeded without a file render the name as text; Phase 3 ingestion attaches the real documents. */
a!localVariables(
  local!d: rule!SD_getDrawDetail(drawId: ri!drawId),
  local!found: a!defaultValue(index(local!d, "found", false), false),
  local!docs: if(
    not(local!found),
    {},
    a!localVariables(
      local!raw: a!queryRecordType(
      recordType: 'recordType!{f3e0033f-2047-4c68-8f6f-cf32166091e9}SD Draw Document',
      fields: {
        'recordType!{f3e0033f-2047-4c68-8f6f-cf32166091e9}SD Draw Document.fields.{a0e2e466-e3fb-4f48-9744-481735a1ba8f}id', 'recordType!{f3e0033f-2047-4c68-8f6f-cf32166091e9}SD Draw Document.fields.{2be78aec-5184-4fd9-8c89-5eabf2bf45ad}document', 'recordType!{f3e0033f-2047-4c68-8f6f-cf32166091e9}SD Draw Document.fields.{fbdf2e7f-9289-4130-82a5-bda409cccf85}documentName', 'recordType!{f3e0033f-2047-4c68-8f6f-cf32166091e9}SD Draw Document.fields.{154ca280-0c9e-4ee5-aed2-111e441a035c}documentType', 'recordType!{f3e0033f-2047-4c68-8f6f-cf32166091e9}SD Draw Document.fields.{b05f8b67-228d-4c39-aa07-519e3f448bb8}uploadedBy', 'recordType!{f3e0033f-2047-4c68-8f6f-cf32166091e9}SD Draw Document.fields.{5e348596-a740-4af9-82ac-423ed4f15b63}uploadedAt', 'recordType!{f3e0033f-2047-4c68-8f6f-cf32166091e9}SD Draw Document.fields.{2863739f-c94b-4f6c-804a-b0fcef1572f7}status', 'recordType!{f3e0033f-2047-4c68-8f6f-cf32166091e9}SD Draw Document.fields.{2b7e89b7-8344-41ad-a71f-9bfb117a9e0c}notes', 'recordType!{f3e0033f-2047-4c68-8f6f-cf32166091e9}SD Draw Document.fields.{2e8183a8-cc80-4093-92c3-f77c04777ac5}receivedDate'
      },
      filters: a!queryFilter(field: 'recordType!{f3e0033f-2047-4c68-8f6f-cf32166091e9}SD Draw Document.fields.{75e7a282-935e-488c-8f72-2b32468edbfc}drawId', operator: "=", value: ri!drawId),
      pagingInfo: a!pagingInfo(startIndex: 1, batchSize: 100, sort: a!sortInfo(field: 'recordType!{f3e0033f-2047-4c68-8f6f-cf32166091e9}SD Draw Document.fields.{a0e2e466-e3fb-4f48-9744-481735a1ba8f}id', ascending: true))
    ).data,
      a!forEach(items: local!raw, expression: a!map(id: fv!item['recordType!{f3e0033f-2047-4c68-8f6f-cf32166091e9}SD Draw Document.fields.{a0e2e466-e3fb-4f48-9744-481735a1ba8f}id'], document: fv!item['recordType!{f3e0033f-2047-4c68-8f6f-cf32166091e9}SD Draw Document.fields.{2be78aec-5184-4fd9-8c89-5eabf2bf45ad}document'], documentName: fv!item['recordType!{f3e0033f-2047-4c68-8f6f-cf32166091e9}SD Draw Document.fields.{fbdf2e7f-9289-4130-82a5-bda409cccf85}documentName'], documentType: fv!item['recordType!{f3e0033f-2047-4c68-8f6f-cf32166091e9}SD Draw Document.fields.{154ca280-0c9e-4ee5-aed2-111e441a035c}documentType'], uploadedBy: fv!item['recordType!{f3e0033f-2047-4c68-8f6f-cf32166091e9}SD Draw Document.fields.{b05f8b67-228d-4c39-aa07-519e3f448bb8}uploadedBy'], uploadedAt: fv!item['recordType!{f3e0033f-2047-4c68-8f6f-cf32166091e9}SD Draw Document.fields.{5e348596-a740-4af9-82ac-423ed4f15b63}uploadedAt'], status: fv!item['recordType!{f3e0033f-2047-4c68-8f6f-cf32166091e9}SD Draw Document.fields.{2863739f-c94b-4f6c-804a-b0fcef1572f7}status'], notes: fv!item['recordType!{f3e0033f-2047-4c68-8f6f-cf32166091e9}SD Draw Document.fields.{2b7e89b7-8344-41ad-a71f-9bfb117a9e0c}notes'], receivedDate: fv!item['recordType!{f3e0033f-2047-4c68-8f6f-cf32166091e9}SD Draw Document.fields.{2e8183a8-cc80-4093-92c3-f77c04777ac5}receivedDate']))
    )
  ),
  local!firstReceived: if(a!isNullOrEmpty(local!docs), null, index(local!docs, 1, null).receivedDate),
  local!feed: if(a!isNullOrEmpty(local!docs), null, index(local!docs, 1, null).uploadedBy),
  {
    a!richTextDisplayField(labelPosition: "COLLAPSED", value: a!richTextItem(text: "Draw not found.", color: "NEGATIVE"), showWhen: not(local!found)),
    rule!SD_cmp_drawFactStrip(detail: local!d),
    a!cardLayout(
    contents: {
      a!richTextDisplayField(
        labelPosition: "COLLAPSED",
        value: a!richTextItem(text: "Draw Documents", size: "MEDIUM", style: "STRONG", color: "#16294D"),
        marginBelow: "EVEN_LESS"
      ),
      rule!SD_cmp_sourceLine(text: "Source template and backup for Draw #" & a!defaultValue(index(local!d, "drawNumber", ""), "") & if(a!isNullOrEmpty(local!feed), "", " · received via " & local!feed) & if(a!isNullOrEmpty(local!firstReceived), "", " " & text(local!firstReceived, "MM/DD/YYYY"))),
      a!gridField(
        labelPosition: "COLLAPSED",
        data: local!docs,
        columns: {
          a!gridColumn(
            label: "Document",
            value: a!richTextDisplayField(
              value: {
                a!richTextIcon(
                  icon: if(find(".xls", lower(a!defaultValue(fv!row.documentName, ""))) > 0, "file-excel-o", if(find(".pdf", lower(a!defaultValue(fv!row.documentName, ""))) > 0, "file-pdf-o", "file-o")),
                  color: if(find(".xls", lower(a!defaultValue(fv!row.documentName, ""))) > 0, "#1E7E46", if(find(".pdf", lower(a!defaultValue(fv!row.documentName, ""))) > 0, "#B42318", "#6B7280"))
                ),
                " ",
                if(
                  a!isNullOrEmpty(fv!row.document),
                  a!richTextItem(text: a!defaultValue(fv!row.documentName, "—")),
                  a!richTextItem(text: a!defaultValue(fv!row.documentName, "document"), link: a!documentDownloadLink(document: fv!row.document), linkStyle: "STANDALONE")
                )
              }
            ),
            width: "WIDE"
          ),
          a!gridColumn(label: "Type", value: a!defaultValue(fv!row.documentType, "—"), width: "NARROW_PLUS"),
          a!gridColumn(label: "Status", value: rule!SD_cmp_statusTag(status: fv!row.status), width: "NARROW_PLUS"),
          a!gridColumn(label: "Received", value: if(a!isNullOrEmpty(fv!row.receivedDate), "—", text(fv!row.receivedDate, "MM/DD/YYYY")), width: "NARROW_PLUS"),
          a!gridColumn(label: "Notes", value: if(a!isNullOrEmpty(fv!row.notes), "—", fv!row.notes))
        },
        pageSize: 20,
        spacing: "DENSE",
        borderStyle: "LIGHT",
        rowHeader: 1,
        emptyGridMessage: "No documents on this draw yet"
      )
    },
    style: "NONE",
    shape: "SEMI_ROUNDED",
    padding: "STANDARD",
    showBorder: true,
    showShadow: false,
    marginBelow: "STANDARD"
  )
  }
)

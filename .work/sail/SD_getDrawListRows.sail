/* Draw approval: the Draws list rows for the viewer, one map per draw, already sorted the way the
   Draws page shows them: draws awaiting the viewer's action first, then in-approval draws by funding date
   ascending, then completed draws by funding date descending. Each row is rule!SD_getDrawDetail's map plus
   a sort bucket, so the KPIs, the YOUR ACTION tag and the row highlight all come from the same read.
   Second fix session 2026-09-28: every row also carries rowLabel (the Draw column's link text: "#n" once confirmed;
   "New draw · 6:44 PM" / "Not loaded · 6:03 PM" before, the received time, with the date when not today) and
   packageLabel (unconfirmed rows only: the template file name plus the supporting files — one named, several counted),
   read from the draws' SD Draw Document rows in one query, so a staged mismatch and a live ingest are told apart on
   stage and by sail, which refuses two identical link labels. */
a!localVariables(
  local!ids: a!queryRecordType(
    recordType: 'recordType!{c9d3a947-71aa-4024-879e-363873a12860}SD Draw',
    fields: { 'recordType!{c9d3a947-71aa-4024-879e-363873a12860}SD Draw.fields.{443829ca-5971-4d31-8fac-ab7a317e509b}id' },
    pagingInfo: a!pagingInfo(startIndex: 1, batchSize: 200, sort: a!sortInfo(field: 'recordType!{c9d3a947-71aa-4024-879e-363873a12860}SD Draw.fields.{9aa1030b-f76b-49aa-bef6-99eb90327804}drawNumber', ascending: false))
  ).data['recordType!{c9d3a947-71aa-4024-879e-363873a12860}SD Draw.fields.{443829ca-5971-4d31-8fac-ab7a317e509b}id'],
  local!rows: a!forEach(
    items: local!ids,
    expression: a!localVariables(
      local!d: rule!SD_getDrawDetail(drawId: fv!item),
      local!status: tostring(a!defaultValue(index(local!d, "status", ""), "")),
      local!fd: index(local!d, "fundingDate", null),
      a!update(
        local!d,
        {"bucket", "sortAll"},
        a!localVariables(
          /* 6c: actionForViewer = a step or reconciliation task, or an email-exception review, open for the viewer */
          local!bucket: if(a!defaultValue(index(local!d, "actionForViewer", false), false), 1, if(local!status = "In Progress", 2, 3)),
          /* days since 2000-01-01; negated for completed draws so ascending order puts the latest funding first */
          local!key: if(
            a!isNullOrEmpty(local!fd),
            0,
            if(local!bucket = 3, -tointeger(todate(local!fd) - date(2000, 1, 1)), tointeger(todate(local!fd) - date(2000, 1, 1)))
          ),
          {local!bucket, local!bucket * 100000 + local!key + 50000}
        )
      )
    )
  ),
  local!unconfirmedIds: a!forEach(
    items: local!rows,
    expression: if(
      or(tostring(a!defaultValue(fv!item.status, "")) = "Ingesting", tostring(a!defaultValue(fv!item.status, "")) = "Ingestion Failed"),
      tointeger(fv!item.id),
      null
    )
  ),
  local!ingestIds: if(a!isNullOrEmpty(local!unconfirmedIds), {}, reject(a!isNullOrEmpty, local!unconfirmedIds)),
  local!docs: if(
    a!isNullOrEmpty(local!ingestIds),
    {},
    a!forEach(
      items: a!queryRecordType(
        recordType: 'recordType!{f3e0033f-2047-4c68-8f6f-cf32166091e9}SD Draw Document',
        fields: { 'recordType!{f3e0033f-2047-4c68-8f6f-cf32166091e9}SD Draw Document.fields.{a0e2e466-e3fb-4f48-9744-481735a1ba8f}id', 'recordType!{f3e0033f-2047-4c68-8f6f-cf32166091e9}SD Draw Document.fields.{75e7a282-935e-488c-8f72-2b32468edbfc}drawId', 'recordType!{f3e0033f-2047-4c68-8f6f-cf32166091e9}SD Draw Document.fields.{fbdf2e7f-9289-4130-82a5-bda409cccf85}documentName', 'recordType!{f3e0033f-2047-4c68-8f6f-cf32166091e9}SD Draw Document.fields.{154ca280-0c9e-4ee5-aed2-111e441a035c}documentType' },
        filters: a!queryFilter(field: 'recordType!{f3e0033f-2047-4c68-8f6f-cf32166091e9}SD Draw Document.fields.{75e7a282-935e-488c-8f72-2b32468edbfc}drawId', operator: "in", value: local!ingestIds),
        pagingInfo: a!pagingInfo(startIndex: 1, batchSize: 500, sort: a!sortInfo(field: 'recordType!{f3e0033f-2047-4c68-8f6f-cf32166091e9}SD Draw Document.fields.{a0e2e466-e3fb-4f48-9744-481735a1ba8f}id', ascending: true))
      ).data,
      expression: a!map(
        drawId: tointeger(fv!item['recordType!{f3e0033f-2047-4c68-8f6f-cf32166091e9}SD Draw Document.fields.{75e7a282-935e-488c-8f72-2b32468edbfc}drawId']),
        name: tostring(a!defaultValue(fv!item['recordType!{f3e0033f-2047-4c68-8f6f-cf32166091e9}SD Draw Document.fields.{fbdf2e7f-9289-4130-82a5-bda409cccf85}documentName'], "")),
        isTemplate: tostring(a!defaultValue(fv!item['recordType!{f3e0033f-2047-4c68-8f6f-cf32166091e9}SD Draw Document.fields.{154ca280-0c9e-4ee5-aed2-111e441a035c}documentType'], "")) = "Budget Template"
      )
    )
  ),
  local!docDrawIds: if(a!isNullOrEmpty(local!docs), {}, a!forEach(items: local!docs, expression: fv!item.drawId)),
  local!labelled: a!forEach(
    items: local!rows,
    expression: a!localVariables(
      local!status: tostring(a!defaultValue(fv!item.status, "")),
      local!unconfirmed: or(local!status = "Ingesting", local!status = "Ingestion Failed"),
      local!at: fv!item.createdAt,
      local!when: if(
        a!isNullOrEmpty(local!at),
        "",
        if(text(local!at, "yyyymmdd") = text(now(), "yyyymmdd"), text(local!at, "h:mm a"), text(local!at, "MMM D, h:mm a"))
      ),
      local!mine: if(
        or(not(local!unconfirmed), a!isNullOrEmpty(local!docDrawIds)),
        {},
        index(local!docs, wherecontains(tointeger(fv!item.id), local!docDrawIds), {})
      ),
      local!templates: if(a!isNullOrEmpty(local!mine), {}, index(local!mine, wherecontains(true, a!forEach(items: local!mine, expression: fv!item.isTemplate)), {})),
      local!others: if(a!isNullOrEmpty(local!mine), {}, index(local!mine, wherecontains(false, a!forEach(items: local!mine, expression: fv!item.isTemplate)), {})),
      local!templateName: if(a!isNullOrEmpty(local!templates), "budget template", tostring(index(local!templates, 1, null).name)),
      a!update(
        fv!item,
        {"rowLabel", "packageLabel"},
        {
          if(
            local!unconfirmed,
            if(local!status = "Ingestion Failed", "Not loaded", "New draw") & if(local!when = "", "", " · " & local!when),
            "#" & a!defaultValue(fv!item.drawNumber, fv!item.id)
          ),
          if(
            not(local!unconfirmed),
            "",
            local!templateName & if(
              a!isNullOrEmpty(local!others),
              "",
              if(count(local!others) = 1, " + " & tostring(index(local!others, 1, null).name), " + " & count(local!others) & " supporting files")
            )
          )
        }
      )
    )
  ),
  /* one ascending sort on the composite key: bucket first, then funding date in the direction the bucket wants */
  todatasubset(local!labelled, a!pagingInfo(startIndex: 1, batchSize: -1, sort: a!sortInfo(field: "sortAll", ascending: true))).data
)

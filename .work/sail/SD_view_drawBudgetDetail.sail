/* Draw approval: the Budget Detail view of a draw record (mockups/draw-summary.html, Budget Detail tab).
   One table, categories funded by this draw first ("In this Draw"), then "All Other Budget Categories", then a
   BUDGET total row computed from the lines. Percent PTD on the total row is PTD over proposed budget. */
a!localVariables(
  local!d: rule!SD_getDrawDetail(drawId: ri!drawId),
  local!found: a!defaultValue(index(local!d, "found", false), false),
  local!lines: if(
    not(local!found),
    {},
    a!localVariables(
      local!raw: a!queryRecordType(
      recordType: 'recordType!{ddc4073e-6372-49e2-80de-a088b424abcd}SD Draw Budget Line',
      fields: {
        'recordType!{ddc4073e-6372-49e2-80de-a088b424abcd}SD Draw Budget Line.fields.{14803371-b715-43a4-bc3a-94e314f16f8a}id', 'recordType!{ddc4073e-6372-49e2-80de-a088b424abcd}SD Draw Budget Line.fields.{2dd34362-59f3-46ad-bb7b-12f44273015e}lineOrder', 'recordType!{ddc4073e-6372-49e2-80de-a088b424abcd}SD Draw Budget Line.fields.{4b8934ab-ad8e-4fc0-ac4e-86a762018dee}budgetCategory', 'recordType!{ddc4073e-6372-49e2-80de-a088b424abcd}SD Draw Budget Line.fields.{2bb6dc6b-76ba-4c39-ba45-837acbf905c1}categoryGroup', 'recordType!{ddc4073e-6372-49e2-80de-a088b424abcd}SD Draw Budget Line.fields.{afd91132-85fa-48aa-a534-0c6a2818b0c3}inThisDraw', 'recordType!{ddc4073e-6372-49e2-80de-a088b424abcd}SD Draw Budget Line.fields.{037ae530-9352-430e-a9b8-9d8b11b8450d}initialBudget', 'recordType!{ddc4073e-6372-49e2-80de-a088b424abcd}SD Draw Budget Line.fields.{eb2ed1b0-6417-4468-a2a2-a0e7f643e931}revisedApprovedBudget', 'recordType!{ddc4073e-6372-49e2-80de-a088b424abcd}SD Draw Budget Line.fields.{497f7abe-c453-4b00-97ad-1f5da03f5cd2}proposedAdjustmentsThisDraw', 'recordType!{ddc4073e-6372-49e2-80de-a088b424abcd}SD Draw Budget Line.fields.{eb2590fe-db09-40e0-8711-a0a044141fe6}proposedBudget', 'recordType!{ddc4073e-6372-49e2-80de-a088b424abcd}SD Draw Budget Line.fields.{5242c9d6-c607-43c9-900c-756163dcbae5}currentDraw', 'recordType!{ddc4073e-6372-49e2-80de-a088b424abcd}SD Draw Budget Line.fields.{aab45d4c-cd07-43ce-87e6-21d485c77827}totalPtdIncThisDrawAmount', 'recordType!{ddc4073e-6372-49e2-80de-a088b424abcd}SD Draw Budget Line.fields.{69bde771-7a23-4f20-9c2a-4303372651cd}totalPtdIncThisDrawPct', 'recordType!{ddc4073e-6372-49e2-80de-a088b424abcd}SD Draw Budget Line.fields.{88da0de6-2ef3-428e-9e04-9edc085fe9b1}balanceToComplete'
      },
      filters: a!queryFilter(field: 'recordType!{ddc4073e-6372-49e2-80de-a088b424abcd}SD Draw Budget Line.fields.{830216a5-8980-4ac0-a8f9-7baa33bbea6b}drawId', operator: "=", value: ri!drawId),
      pagingInfo: a!pagingInfo(startIndex: 1, batchSize: 100, sort: a!sortInfo(field: 'recordType!{ddc4073e-6372-49e2-80de-a088b424abcd}SD Draw Budget Line.fields.{2dd34362-59f3-46ad-bb7b-12f44273015e}lineOrder', ascending: true))
    ).data,
      a!forEach(items: local!raw, expression: a!map(id: fv!item['recordType!{ddc4073e-6372-49e2-80de-a088b424abcd}SD Draw Budget Line.fields.{14803371-b715-43a4-bc3a-94e314f16f8a}id'], lineOrder: fv!item['recordType!{ddc4073e-6372-49e2-80de-a088b424abcd}SD Draw Budget Line.fields.{2dd34362-59f3-46ad-bb7b-12f44273015e}lineOrder'], budgetCategory: fv!item['recordType!{ddc4073e-6372-49e2-80de-a088b424abcd}SD Draw Budget Line.fields.{4b8934ab-ad8e-4fc0-ac4e-86a762018dee}budgetCategory'], categoryGroup: fv!item['recordType!{ddc4073e-6372-49e2-80de-a088b424abcd}SD Draw Budget Line.fields.{2bb6dc6b-76ba-4c39-ba45-837acbf905c1}categoryGroup'], inThisDraw: fv!item['recordType!{ddc4073e-6372-49e2-80de-a088b424abcd}SD Draw Budget Line.fields.{afd91132-85fa-48aa-a534-0c6a2818b0c3}inThisDraw'], initialBudget: fv!item['recordType!{ddc4073e-6372-49e2-80de-a088b424abcd}SD Draw Budget Line.fields.{037ae530-9352-430e-a9b8-9d8b11b8450d}initialBudget'], revisedApprovedBudget: fv!item['recordType!{ddc4073e-6372-49e2-80de-a088b424abcd}SD Draw Budget Line.fields.{eb2ed1b0-6417-4468-a2a2-a0e7f643e931}revisedApprovedBudget'], proposedAdjustmentsThisDraw: fv!item['recordType!{ddc4073e-6372-49e2-80de-a088b424abcd}SD Draw Budget Line.fields.{497f7abe-c453-4b00-97ad-1f5da03f5cd2}proposedAdjustmentsThisDraw'], proposedBudget: fv!item['recordType!{ddc4073e-6372-49e2-80de-a088b424abcd}SD Draw Budget Line.fields.{eb2590fe-db09-40e0-8711-a0a044141fe6}proposedBudget'], currentDraw: fv!item['recordType!{ddc4073e-6372-49e2-80de-a088b424abcd}SD Draw Budget Line.fields.{5242c9d6-c607-43c9-900c-756163dcbae5}currentDraw'], totalPtdIncThisDrawAmount: fv!item['recordType!{ddc4073e-6372-49e2-80de-a088b424abcd}SD Draw Budget Line.fields.{aab45d4c-cd07-43ce-87e6-21d485c77827}totalPtdIncThisDrawAmount'], totalPtdIncThisDrawPct: fv!item['recordType!{ddc4073e-6372-49e2-80de-a088b424abcd}SD Draw Budget Line.fields.{69bde771-7a23-4f20-9c2a-4303372651cd}totalPtdIncThisDrawPct'], balanceToComplete: fv!item['recordType!{ddc4073e-6372-49e2-80de-a088b424abcd}SD Draw Budget Line.fields.{88da0de6-2ef3-428e-9e04-9edc085fe9b1}balanceToComplete']))
    )
  ),
  /* guarded: an empty a!forEach result keeps the record list's type, and wherecontains refuses a Boolean against it */
  local!flags: a!forEach(items: local!lines, expression: a!defaultValue(fv!item.inThisDraw, false)),
  local!inDraw: if(a!isNullOrEmpty(local!lines), {}, a!forEach(items: index(local!lines, wherecontains(true, local!flags), {}), expression: a!update(fv!item, "kind", "line"))),
  local!others: if(a!isNullOrEmpty(local!lines), {}, a!forEach(items: index(local!lines, wherecontains(false, local!flags), {}), expression: a!update(fv!item, "kind", "line"))),
  local!sum: a!localVariables(
    local!proposed: sum(a!forEach(items: local!lines, expression: a!defaultValue(fv!item.proposedBudget, 0))),
    local!ptd: sum(a!forEach(items: local!lines, expression: a!defaultValue(fv!item.totalPtdIncThisDrawAmount, 0))),
    a!map(
      kind: "total",
      budgetCategory: "BUDGET",
      initialBudget: sum(a!forEach(items: local!lines, expression: a!defaultValue(fv!item.initialBudget, 0))),
      revisedApprovedBudget: sum(a!forEach(items: local!lines, expression: a!defaultValue(fv!item.revisedApprovedBudget, 0))),
      proposedAdjustmentsThisDraw: sum(a!forEach(items: local!lines, expression: a!defaultValue(fv!item.proposedAdjustmentsThisDraw, 0))),
      proposedBudget: local!proposed,
      currentDraw: sum(a!forEach(items: local!lines, expression: a!defaultValue(fv!item.currentDraw, 0))),
      totalPtdIncThisDrawAmount: local!ptd,
      totalPtdIncThisDrawPct: if(local!proposed = 0, null, 100 * local!ptd / local!proposed),
      balanceToComplete: sum(a!forEach(items: local!lines, expression: a!defaultValue(fv!item.balanceToComplete, 0)))
    )
  ),
  local!rows: if(
    a!isNullOrEmpty(local!lines),
    {},
    {
      if(a!isNullOrEmpty(local!inDraw), {}, a!map(kind: "section", budgetCategory: "In this Draw")),
      local!inDraw,
      if(a!isNullOrEmpty(local!others), {}, a!map(kind: "section", budgetCategory: "All Other Budget Categories")),
      local!others,
      local!sum
    }
  ),
  local!sourceDoc: a!localVariables(
    local!raw: if(
      not(local!found),
      {},
      a!queryRecordType(
      recordType: 'recordType!{f3e0033f-2047-4c68-8f6f-cf32166091e9}SD Draw Document',
      fields: {
        'recordType!{f3e0033f-2047-4c68-8f6f-cf32166091e9}SD Draw Document.fields.{a0e2e466-e3fb-4f48-9744-481735a1ba8f}id', 'recordType!{f3e0033f-2047-4c68-8f6f-cf32166091e9}SD Draw Document.fields.{fbdf2e7f-9289-4130-82a5-bda409cccf85}documentName', 'recordType!{f3e0033f-2047-4c68-8f6f-cf32166091e9}SD Draw Document.fields.{154ca280-0c9e-4ee5-aed2-111e441a035c}documentType', 'recordType!{f3e0033f-2047-4c68-8f6f-cf32166091e9}SD Draw Document.fields.{2863739f-c94b-4f6c-804a-b0fcef1572f7}status', 'recordType!{f3e0033f-2047-4c68-8f6f-cf32166091e9}SD Draw Document.fields.{2b7e89b7-8344-41ad-a71f-9bfb117a9e0c}notes'
      },
      filters: a!queryFilter(field: 'recordType!{f3e0033f-2047-4c68-8f6f-cf32166091e9}SD Draw Document.fields.{75e7a282-935e-488c-8f72-2b32468edbfc}drawId', operator: "=", value: ri!drawId),
      pagingInfo: a!pagingInfo(startIndex: 1, batchSize: 100, sort: a!sortInfo(field: 'recordType!{f3e0033f-2047-4c68-8f6f-cf32166091e9}SD Draw Document.fields.{a0e2e466-e3fb-4f48-9744-481735a1ba8f}id', ascending: true))
    ).data
    ),
    local!maps: a!forEach(items: local!raw, expression: a!map(id: fv!item['recordType!{f3e0033f-2047-4c68-8f6f-cf32166091e9}SD Draw Document.fields.{a0e2e466-e3fb-4f48-9744-481735a1ba8f}id'], documentName: fv!item['recordType!{f3e0033f-2047-4c68-8f6f-cf32166091e9}SD Draw Document.fields.{fbdf2e7f-9289-4130-82a5-bda409cccf85}documentName'], documentType: fv!item['recordType!{f3e0033f-2047-4c68-8f6f-cf32166091e9}SD Draw Document.fields.{154ca280-0c9e-4ee5-aed2-111e441a035c}documentType'], status: fv!item['recordType!{f3e0033f-2047-4c68-8f6f-cf32166091e9}SD Draw Document.fields.{2863739f-c94b-4f6c-804a-b0fcef1572f7}status'], notes: fv!item['recordType!{f3e0033f-2047-4c68-8f6f-cf32166091e9}SD Draw Document.fields.{2b7e89b7-8344-41ad-a71f-9bfb117a9e0c}notes'])),
    local!idx: if(a!isNullOrEmpty(local!maps), {}, wherecontains("Budget Template", a!forEach(items: local!maps, expression: tostring(a!defaultValue(fv!item.documentType, ""))))),
    if(a!isNullOrEmpty(local!idx), null, index(local!maps, local!idx[1], null))
  ),
  {
    a!richTextDisplayField(labelPosition: "COLLAPSED", value: a!richTextItem(text: "Draw not found.", color: "NEGATIVE"), showWhen: not(local!found)),
    rule!SD_cmp_drawFactStrip(detail: local!d),
    a!cardLayout(
    contents: {
      a!richTextDisplayField(
        labelPosition: "COLLAPSED",
        value: a!richTextItem(text: "Draw Detail by Budget Category", size: "MEDIUM", style: "STRONG", color: "#16294D"),
        marginBelow: "EVEN_LESS"
      ),
      rule!SD_cmp_sourceLine(text: if(
        a!isNullOrEmpty(local!sourceDoc),
        "Budget lines for Draw #" & a!defaultValue(index(local!d, "drawNumber", ""), ""),
        "Extracted from " & a!defaultValue(local!sourceDoc.documentName, "the budget template") & " via Doc Center" & if(a!isNullOrEmpty(local!sourceDoc.notes), "", " · " & local!sourceDoc.notes)
      )),
      a!gridField(
        labelPosition: "COLLAPSED",
        data: local!rows,
        columns: {
          a!gridColumn(
            label: "Budget Category",
            value: a!richTextDisplayField(
              value: a!richTextItem(
                text: fv!row.budgetCategory,
                style: if(or(fv!row.kind = "section", fv!row.kind = "total"), "STRONG", "PLAIN"),
                color: if(fv!row.kind = "section", "#6B7280", "#16294D"),
                size: if(fv!row.kind = "section", "SMALL", "STANDARD")
              )
            ),
            width: "MEDIUM_PLUS"
          ),
          a!gridColumn(label: "Initial Budget", value: a!richTextDisplayField(value: a!richTextItem(text: if(fv!row.kind = "section", "", if(a!defaultValue(fv!row.initialBudget, 0) = 0, "—", rule!SD_fmtMoney(value: fv!row.initialBudget, showCents: false))), style: if(fv!row.kind = "total", "STRONG", "PLAIN"))), align: "END"),
          a!gridColumn(label: "Revised Approved Budget", value: a!richTextDisplayField(value: a!richTextItem(text: if(fv!row.kind = "section", "", rule!SD_fmtMoney(value: fv!row.revisedApprovedBudget, showCents: false)), style: if(fv!row.kind = "total", "STRONG", "PLAIN"))), align: "END"),
          a!gridColumn(label: "Proposed Adjustments This Draw", value: a!richTextDisplayField(value: a!richTextItem(text: if(fv!row.kind = "section", "", if(a!defaultValue(fv!row.proposedAdjustmentsThisDraw, 0) = 0, "—", rule!SD_fmtMoney(value: fv!row.proposedAdjustmentsThisDraw, showCents: false))), style: if(fv!row.kind = "total", "STRONG", "PLAIN"))), align: "END"),
          a!gridColumn(label: "Proposed Budget", value: a!richTextDisplayField(value: a!richTextItem(text: if(fv!row.kind = "section", "", rule!SD_fmtMoney(value: fv!row.proposedBudget, showCents: false)), style: if(fv!row.kind = "total", "STRONG", "PLAIN"))), align: "END"),
          a!gridColumn(label: "Current Draw", value: a!richTextDisplayField(value: a!richTextItem(text: if(fv!row.kind = "section", "", if(a!defaultValue(fv!row.currentDraw, 0) = 0, "—", rule!SD_fmtMoney(value: fv!row.currentDraw, showCents: false))), style: if(fv!row.kind = "total", "STRONG", "PLAIN"))), align: "END"),
          a!gridColumn(label: "Total PTD inc. This Draw ($)", value: a!richTextDisplayField(value: a!richTextItem(text: if(fv!row.kind = "section", "", if(a!defaultValue(fv!row.totalPtdIncThisDrawAmount, 0) = 0, "—", rule!SD_fmtMoney(value: fv!row.totalPtdIncThisDrawAmount, showCents: false))), style: if(fv!row.kind = "total", "STRONG", "PLAIN"))), align: "END"),
          a!gridColumn(label: "Total PTD inc. This Draw (%)", value: a!richTextDisplayField(value: a!richTextItem(text: if(fv!row.kind = "section", "", if(a!defaultValue(fv!row.totalPtdIncThisDrawAmount, 0) = 0, "—", text(a!defaultValue(fv!row.totalPtdIncThisDrawPct, 0), "0.0") & "%")), style: if(fv!row.kind = "total", "STRONG", "PLAIN"))), align: "END"),
          a!gridColumn(label: "Balance To Complete", value: a!richTextDisplayField(value: a!richTextItem(text: if(fv!row.kind = "section", "", if(a!defaultValue(fv!row.balanceToComplete, 0) = 0, "—", rule!SD_fmtMoney(value: fv!row.balanceToComplete, showCents: false))), style: if(fv!row.kind = "total", "STRONG", "PLAIN"))), align: "END")
        },
        pageSize: 60,
        spacing: "DENSE",
        borderStyle: "LIGHT",
        rowHeader: 1,
        emptyGridMessage: "No budget lines on this draw"
      ),
      rule!SD_cmp_sourceLine(
        text: "Categories funded by Draw #" & a!defaultValue(index(local!d, "drawNumber", ""), "") & " listed first, per the approval email layout. Net proposed adjustments this draw are " & rule!SD_fmtMoney(value: local!sum.proposedAdjustmentsThisDraw, showCents: false) & ". The total row is computed from the category lines."
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

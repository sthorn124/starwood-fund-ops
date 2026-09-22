/* Draw approval (Phase 4): the approval step email — subject and HTML body — built from the draw's records at send
   time, for every step, matched to the new approval email sample's section order: navy header (investment, fund, draw
   type, funding date, amount) · greeting and reply instruction · Draw Funding Detail · Draw Detail by Budget Category
   (In this Draw, All Other Budget Categories, BUDGET total) · Budget Summary (Land / Soft / Hard / Total, rolled up from
   the lines — ruled, never copied from the sample) · Remaining Contingency · QIU Detail · Approval Status (nine
   contiguous rows, the current step marked) · reply footer. Money as in the app (SD_fmtMoney; cents only on the header
   amount), percents as 0.0%, dashes for empty. Table layout, every style inline, no stylesheet, no images — Gmail is
   the target. Returns a!map(subject, html, bytes). Nothing here is typed in from the sample. */
a!localVariables(
  local!d: rule!SD_getDrawDetail(drawId: ri!drawId),
  local!found: a!defaultValue(index(local!d, "found", false), false),
  local!lines: if(
    not(local!found),
    {},
    a!localVariables(
      local!raw: a!queryRecordType(
        recordType: 'recordType!{ddc4073e-6372-49e2-80de-a088b424abcd}SD Draw Budget Line',
        fields: { 'recordType!{ddc4073e-6372-49e2-80de-a088b424abcd}SD Draw Budget Line.fields.{14803371-b715-43a4-bc3a-94e314f16f8a}id', 'recordType!{ddc4073e-6372-49e2-80de-a088b424abcd}SD Draw Budget Line.fields.{2dd34362-59f3-46ad-bb7b-12f44273015e}lineOrder', 'recordType!{ddc4073e-6372-49e2-80de-a088b424abcd}SD Draw Budget Line.fields.{4b8934ab-ad8e-4fc0-ac4e-86a762018dee}budgetCategory', 'recordType!{ddc4073e-6372-49e2-80de-a088b424abcd}SD Draw Budget Line.fields.{2bb6dc6b-76ba-4c39-ba45-837acbf905c1}categoryGroup', 'recordType!{ddc4073e-6372-49e2-80de-a088b424abcd}SD Draw Budget Line.fields.{afd91132-85fa-48aa-a534-0c6a2818b0c3}inThisDraw', 'recordType!{ddc4073e-6372-49e2-80de-a088b424abcd}SD Draw Budget Line.fields.{037ae530-9352-430e-a9b8-9d8b11b8450d}initialBudget', 'recordType!{ddc4073e-6372-49e2-80de-a088b424abcd}SD Draw Budget Line.fields.{eb2ed1b0-6417-4468-a2a2-a0e7f643e931}revisedApprovedBudget', 'recordType!{ddc4073e-6372-49e2-80de-a088b424abcd}SD Draw Budget Line.fields.{497f7abe-c453-4b00-97ad-1f5da03f5cd2}proposedAdjustmentsThisDraw', 'recordType!{ddc4073e-6372-49e2-80de-a088b424abcd}SD Draw Budget Line.fields.{eb2590fe-db09-40e0-8711-a0a044141fe6}proposedBudget', 'recordType!{ddc4073e-6372-49e2-80de-a088b424abcd}SD Draw Budget Line.fields.{5242c9d6-c607-43c9-900c-756163dcbae5}currentDraw', 'recordType!{ddc4073e-6372-49e2-80de-a088b424abcd}SD Draw Budget Line.fields.{aab45d4c-cd07-43ce-87e6-21d485c77827}totalPtdIncThisDrawAmount', 'recordType!{ddc4073e-6372-49e2-80de-a088b424abcd}SD Draw Budget Line.fields.{69bde771-7a23-4f20-9c2a-4303372651cd}totalPtdIncThisDrawPct', 'recordType!{ddc4073e-6372-49e2-80de-a088b424abcd}SD Draw Budget Line.fields.{88da0de6-2ef3-428e-9e04-9edc085fe9b1}balanceToComplete' },
        filters: a!queryFilter(field: 'recordType!{ddc4073e-6372-49e2-80de-a088b424abcd}SD Draw Budget Line.fields.{830216a5-8980-4ac0-a8f9-7baa33bbea6b}drawId', operator: "=", value: ri!drawId),
        pagingInfo: a!pagingInfo(startIndex: 1, batchSize: 100, sort: a!sortInfo(field: 'recordType!{ddc4073e-6372-49e2-80de-a088b424abcd}SD Draw Budget Line.fields.{2dd34362-59f3-46ad-bb7b-12f44273015e}lineOrder', ascending: true))
      ).data,
      a!forEach(items: local!raw, expression: a!map(id: fv!item['recordType!{ddc4073e-6372-49e2-80de-a088b424abcd}SD Draw Budget Line.fields.{14803371-b715-43a4-bc3a-94e314f16f8a}id'], lineOrder: fv!item['recordType!{ddc4073e-6372-49e2-80de-a088b424abcd}SD Draw Budget Line.fields.{2dd34362-59f3-46ad-bb7b-12f44273015e}lineOrder'], budgetCategory: fv!item['recordType!{ddc4073e-6372-49e2-80de-a088b424abcd}SD Draw Budget Line.fields.{4b8934ab-ad8e-4fc0-ac4e-86a762018dee}budgetCategory'], categoryGroup: fv!item['recordType!{ddc4073e-6372-49e2-80de-a088b424abcd}SD Draw Budget Line.fields.{2bb6dc6b-76ba-4c39-ba45-837acbf905c1}categoryGroup'], inThisDraw: fv!item['recordType!{ddc4073e-6372-49e2-80de-a088b424abcd}SD Draw Budget Line.fields.{afd91132-85fa-48aa-a534-0c6a2818b0c3}inThisDraw'], initialBudget: fv!item['recordType!{ddc4073e-6372-49e2-80de-a088b424abcd}SD Draw Budget Line.fields.{037ae530-9352-430e-a9b8-9d8b11b8450d}initialBudget'], revisedApprovedBudget: fv!item['recordType!{ddc4073e-6372-49e2-80de-a088b424abcd}SD Draw Budget Line.fields.{eb2ed1b0-6417-4468-a2a2-a0e7f643e931}revisedApprovedBudget'], proposedAdjustmentsThisDraw: fv!item['recordType!{ddc4073e-6372-49e2-80de-a088b424abcd}SD Draw Budget Line.fields.{497f7abe-c453-4b00-97ad-1f5da03f5cd2}proposedAdjustmentsThisDraw'], proposedBudget: fv!item['recordType!{ddc4073e-6372-49e2-80de-a088b424abcd}SD Draw Budget Line.fields.{eb2590fe-db09-40e0-8711-a0a044141fe6}proposedBudget'], currentDraw: fv!item['recordType!{ddc4073e-6372-49e2-80de-a088b424abcd}SD Draw Budget Line.fields.{5242c9d6-c607-43c9-900c-756163dcbae5}currentDraw'], totalPtdIncThisDrawAmount: fv!item['recordType!{ddc4073e-6372-49e2-80de-a088b424abcd}SD Draw Budget Line.fields.{aab45d4c-cd07-43ce-87e6-21d485c77827}totalPtdIncThisDrawAmount'], totalPtdIncThisDrawPct: fv!item['recordType!{ddc4073e-6372-49e2-80de-a088b424abcd}SD Draw Budget Line.fields.{69bde771-7a23-4f20-9c2a-4303372651cd}totalPtdIncThisDrawPct'], balanceToComplete: fv!item['recordType!{ddc4073e-6372-49e2-80de-a088b424abcd}SD Draw Budget Line.fields.{88da0de6-2ef3-428e-9e04-9edc085fe9b1}balanceToComplete']))
    )
  ),
  local!qiu: if(
    not(local!found),
    {},
    a!localVariables(
      local!raw: a!queryRecordType(
        recordType: 'recordType!{a0920e4c-0c76-4494-a61a-6e38d5db390a}SD QIU Metric',
        fields: { 'recordType!{a0920e4c-0c76-4494-a61a-6e38d5db390a}SD QIU Metric.fields.{f3d5f8f7-3ecf-4749-b749-78f2836cd65d}id', 'recordType!{a0920e4c-0c76-4494-a61a-6e38d5db390a}SD QIU Metric.fields.{ecef76a6-01a5-4d0d-8941-a02394945e7e}metricOrder', 'recordType!{a0920e4c-0c76-4494-a61a-6e38d5db390a}SD QIU Metric.fields.{75d24b80-5a71-4593-9726-440e6253e421}metric', 'recordType!{a0920e4c-0c76-4494-a61a-6e38d5db390a}SD QIU Metric.fields.{276dbba0-0b4b-460c-ba32-0f12a1ec51ce}modelAsOfDate', 'recordType!{a0920e4c-0c76-4494-a61a-6e38d5db390a}SD QIU Metric.fields.{1db4ed90-8f43-447c-8c7c-aca831ccf178}currentModelValue', 'recordType!{a0920e4c-0c76-4494-a61a-6e38d5db390a}SD QIU Metric.fields.{212e37e2-434d-4337-bb4b-ea129a230f25}currentProjection', 'recordType!{a0920e4c-0c76-4494-a61a-6e38d5db390a}SD QIU Metric.fields.{b135520a-cbed-4cd7-8a3c-0bbaa699b1ba}variance', 'recordType!{a0920e4c-0c76-4494-a61a-6e38d5db390a}SD QIU Metric.fields.{125838c4-1335-43ca-be24-7633c09662e0}notes' },
        filters: a!queryFilter(field: 'recordType!{a0920e4c-0c76-4494-a61a-6e38d5db390a}SD QIU Metric.fields.{5fbabfd8-3d5f-4593-a48b-191b529eb267}drawId', operator: "=", value: ri!drawId),
        pagingInfo: a!pagingInfo(startIndex: 1, batchSize: 100, sort: a!sortInfo(field: 'recordType!{a0920e4c-0c76-4494-a61a-6e38d5db390a}SD QIU Metric.fields.{ecef76a6-01a5-4d0d-8941-a02394945e7e}metricOrder', ascending: true))
      ).data,
      a!forEach(items: local!raw, expression: a!map(id: fv!item['recordType!{a0920e4c-0c76-4494-a61a-6e38d5db390a}SD QIU Metric.fields.{f3d5f8f7-3ecf-4749-b749-78f2836cd65d}id'], metricOrder: fv!item['recordType!{a0920e4c-0c76-4494-a61a-6e38d5db390a}SD QIU Metric.fields.{ecef76a6-01a5-4d0d-8941-a02394945e7e}metricOrder'], metric: fv!item['recordType!{a0920e4c-0c76-4494-a61a-6e38d5db390a}SD QIU Metric.fields.{75d24b80-5a71-4593-9726-440e6253e421}metric'], modelAsOfDate: fv!item['recordType!{a0920e4c-0c76-4494-a61a-6e38d5db390a}SD QIU Metric.fields.{276dbba0-0b4b-460c-ba32-0f12a1ec51ce}modelAsOfDate'], currentModelValue: fv!item['recordType!{a0920e4c-0c76-4494-a61a-6e38d5db390a}SD QIU Metric.fields.{1db4ed90-8f43-447c-8c7c-aca831ccf178}currentModelValue'], currentProjection: fv!item['recordType!{a0920e4c-0c76-4494-a61a-6e38d5db390a}SD QIU Metric.fields.{212e37e2-434d-4337-bb4b-ea129a230f25}currentProjection'], variance: fv!item['recordType!{a0920e4c-0c76-4494-a61a-6e38d5db390a}SD QIU Metric.fields.{b135520a-cbed-4cd7-8a3c-0bbaa699b1ba}variance'], notes: fv!item['recordType!{a0920e4c-0c76-4494-a61a-6e38d5db390a}SD QIU Metric.fields.{125838c4-1335-43ca-be24-7633c09662e0}notes']))
    )
  ),
  local!appr: if(
    not(local!found),
    {},
    a!localVariables(
      local!raw: a!queryRecordType(
        recordType: 'recordType!{02c207d5-c725-4d11-bf40-b33573e87ffa}SD Draw Approval',
        fields: { 'recordType!{02c207d5-c725-4d11-bf40-b33573e87ffa}SD Draw Approval.fields.{69abcdf2-55da-48dc-8cc4-794b5d5e0042}id', 'recordType!{02c207d5-c725-4d11-bf40-b33573e87ffa}SD Draw Approval.fields.{44b8ee63-1230-4abd-ae83-ca2cddf182b6}approvalOrder', 'recordType!{02c207d5-c725-4d11-bf40-b33573e87ffa}SD Draw Approval.fields.{30524217-4621-4b41-9af4-490d2f082bdd}role', 'recordType!{02c207d5-c725-4d11-bf40-b33573e87ffa}SD Draw Approval.fields.{983be1c0-67e4-464f-b7c2-1e3a1c735458}approverName', 'recordType!{02c207d5-c725-4d11-bf40-b33573e87ffa}SD Draw Approval.fields.{4c1bf7fb-0736-4c9a-946e-99f6989ac83a}status', 'recordType!{02c207d5-c725-4d11-bf40-b33573e87ffa}SD Draw Approval.fields.{a6a03063-3b14-4f00-8cab-b5d10602405e}decisionDate', 'recordType!{02c207d5-c725-4d11-bf40-b33573e87ffa}SD Draw Approval.fields.{3c1aae42-13a1-4c13-894a-9fdef20f7fce}comments' },
        filters: a!queryFilter(field: 'recordType!{02c207d5-c725-4d11-bf40-b33573e87ffa}SD Draw Approval.fields.{5dacd7ec-3f3f-4645-9d08-684793b0b54b}drawId', operator: "=", value: ri!drawId),
        pagingInfo: a!pagingInfo(startIndex: 1, batchSize: 100, sort: a!sortInfo(field: 'recordType!{02c207d5-c725-4d11-bf40-b33573e87ffa}SD Draw Approval.fields.{44b8ee63-1230-4abd-ae83-ca2cddf182b6}approvalOrder', ascending: true))
      ).data,
      a!forEach(items: local!raw, expression: a!map(id: fv!item['recordType!{02c207d5-c725-4d11-bf40-b33573e87ffa}SD Draw Approval.fields.{69abcdf2-55da-48dc-8cc4-794b5d5e0042}id'], approvalOrder: fv!item['recordType!{02c207d5-c725-4d11-bf40-b33573e87ffa}SD Draw Approval.fields.{44b8ee63-1230-4abd-ae83-ca2cddf182b6}approvalOrder'], role: fv!item['recordType!{02c207d5-c725-4d11-bf40-b33573e87ffa}SD Draw Approval.fields.{30524217-4621-4b41-9af4-490d2f082bdd}role'], approverName: fv!item['recordType!{02c207d5-c725-4d11-bf40-b33573e87ffa}SD Draw Approval.fields.{983be1c0-67e4-464f-b7c2-1e3a1c735458}approverName'], status: fv!item['recordType!{02c207d5-c725-4d11-bf40-b33573e87ffa}SD Draw Approval.fields.{4c1bf7fb-0736-4c9a-946e-99f6989ac83a}status'], decisionDate: fv!item['recordType!{02c207d5-c725-4d11-bf40-b33573e87ffa}SD Draw Approval.fields.{a6a03063-3b14-4f00-8cab-b5d10602405e}decisionDate'], comments: fv!item['recordType!{02c207d5-c725-4d11-bf40-b33573e87ffa}SD Draw Approval.fields.{3c1aae42-13a1-4c13-894a-9fdef20f7fce}comments']))
    )
  ),
  /* The step this email is for: its approval row (name for the greeting) */
  local!stepIdx: if(a!isNullOrEmpty(local!appr), {}, wherecontains(tointeger(ri!stepOrder), tointeger(a!forEach(items: local!appr, expression: a!defaultValue(fv!item.approvalOrder, 0))))),
  local!step: if(a!isNullOrEmpty(local!stepIdx), null, index(local!appr, local!stepIdx[1], null)),
  local!approverName: if(a!isNullOrEmpty(local!step), "", a!defaultValue(local!step.approverName, "")),
  local!stepRole: if(a!isNullOrEmpty(local!step), a!defaultValue(index(local!d, "currentRole", ""), ""), a!defaultValue(local!step.role, "")),
  local!totalSteps: a!defaultValue(index(local!d, "totalSteps", cons!SD_DRAW_FINAL_APPROVAL_ORDER), cons!SD_DRAW_FINAL_APPROVAL_ORDER),
  /* Header facts */
  local!investment: a!defaultValue(index(local!d, "investmentName", ""), ""),
  local!fund: a!defaultValue(index(local!d, "fundName", ""), ""),
  local!drawNumber: index(local!d, "drawNumber", null),
  local!amount: index(local!d, "amount", null),
  local!fundingDate: index(local!d, "fundingDate", null),
  local!drawType: a!defaultValue(index(local!d, "drawType", ""), ""),
  local!budgetStatus: a!defaultValue(index(local!d, "budgetStatus", ""), ""),
  local!amountText: if(a!isNullOrEmpty(local!amount), "—", rule!SD_fmtMoney(value: local!amount, showCents: true)),
  local!fundingText: if(a!isNullOrEmpty(local!fundingDate), "—", text(todate(local!fundingDate), "MMMM D, YYYY")),
  /* Lines split as the Budget Detail view does; the total row and the group roll-ups computed from the lines */
  local!flags: a!forEach(items: local!lines, expression: a!defaultValue(fv!item.inThisDraw, false)),
  local!inDraw: if(a!isNullOrEmpty(local!lines), {}, index(local!lines, wherecontains(true, local!flags), {})),
  local!others: if(a!isNullOrEmpty(local!lines), {}, index(local!lines, wherecontains(false, local!flags), {})),
  local!total: a!localVariables(
    local!proposed: sum(a!forEach(items: local!lines, expression: a!defaultValue(fv!item.proposedBudget, 0))),
    local!ptd: sum(a!forEach(items: local!lines, expression: a!defaultValue(fv!item.totalPtdIncThisDrawAmount, 0))),
    a!map(
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
  local!groups: { a!map(
      budgetCategory: "Land",
      initialBudget: sum(a!forEach(items: local!lines, expression: if(fv!item.categoryGroup = "Land", a!defaultValue(fv!item.initialBudget, 0), 0))), revisedApprovedBudget: sum(a!forEach(items: local!lines, expression: if(fv!item.categoryGroup = "Land", a!defaultValue(fv!item.revisedApprovedBudget, 0), 0))),
      proposedAdjustmentsThisDraw: sum(a!forEach(items: local!lines, expression: if(fv!item.categoryGroup = "Land", a!defaultValue(fv!item.proposedAdjustmentsThisDraw, 0), 0))), proposedBudget: sum(a!forEach(items: local!lines, expression: if(fv!item.categoryGroup = "Land", a!defaultValue(fv!item.proposedBudget, 0), 0))),
      currentDraw: sum(a!forEach(items: local!lines, expression: if(fv!item.categoryGroup = "Land", a!defaultValue(fv!item.currentDraw, 0), 0))), totalPtdIncThisDrawAmount: sum(a!forEach(items: local!lines, expression: if(fv!item.categoryGroup = "Land", a!defaultValue(fv!item.totalPtdIncThisDrawAmount, 0), 0))),
      balanceToComplete: sum(a!forEach(items: local!lines, expression: if(fv!item.categoryGroup = "Land", a!defaultValue(fv!item.balanceToComplete, 0), 0)))
    ), a!map(
      budgetCategory: "Soft",
      initialBudget: sum(a!forEach(items: local!lines, expression: if(fv!item.categoryGroup = "Soft", a!defaultValue(fv!item.initialBudget, 0), 0))), revisedApprovedBudget: sum(a!forEach(items: local!lines, expression: if(fv!item.categoryGroup = "Soft", a!defaultValue(fv!item.revisedApprovedBudget, 0), 0))),
      proposedAdjustmentsThisDraw: sum(a!forEach(items: local!lines, expression: if(fv!item.categoryGroup = "Soft", a!defaultValue(fv!item.proposedAdjustmentsThisDraw, 0), 0))), proposedBudget: sum(a!forEach(items: local!lines, expression: if(fv!item.categoryGroup = "Soft", a!defaultValue(fv!item.proposedBudget, 0), 0))),
      currentDraw: sum(a!forEach(items: local!lines, expression: if(fv!item.categoryGroup = "Soft", a!defaultValue(fv!item.currentDraw, 0), 0))), totalPtdIncThisDrawAmount: sum(a!forEach(items: local!lines, expression: if(fv!item.categoryGroup = "Soft", a!defaultValue(fv!item.totalPtdIncThisDrawAmount, 0), 0))),
      balanceToComplete: sum(a!forEach(items: local!lines, expression: if(fv!item.categoryGroup = "Soft", a!defaultValue(fv!item.balanceToComplete, 0), 0)))
    ), a!map(
      budgetCategory: "Hard",
      initialBudget: sum(a!forEach(items: local!lines, expression: if(fv!item.categoryGroup = "Hard", a!defaultValue(fv!item.initialBudget, 0), 0))), revisedApprovedBudget: sum(a!forEach(items: local!lines, expression: if(fv!item.categoryGroup = "Hard", a!defaultValue(fv!item.revisedApprovedBudget, 0), 0))),
      proposedAdjustmentsThisDraw: sum(a!forEach(items: local!lines, expression: if(fv!item.categoryGroup = "Hard", a!defaultValue(fv!item.proposedAdjustmentsThisDraw, 0), 0))), proposedBudget: sum(a!forEach(items: local!lines, expression: if(fv!item.categoryGroup = "Hard", a!defaultValue(fv!item.proposedBudget, 0), 0))),
      currentDraw: sum(a!forEach(items: local!lines, expression: if(fv!item.categoryGroup = "Hard", a!defaultValue(fv!item.currentDraw, 0), 0))), totalPtdIncThisDrawAmount: sum(a!forEach(items: local!lines, expression: if(fv!item.categoryGroup = "Hard", a!defaultValue(fv!item.totalPtdIncThisDrawAmount, 0), 0))),
      balanceToComplete: sum(a!forEach(items: local!lines, expression: if(fv!item.categoryGroup = "Hard", a!defaultValue(fv!item.balanceToComplete, 0), 0)))
    ) },
  /* Remaining contingency: the contingency line over the total balance to complete (as the Summary view) */
  local!contIdx: if(a!isNullOrEmpty(local!lines), {}, wherecontains(true, a!forEach(items: local!lines, expression: find("contingency", lower(a!defaultValue(fv!item.budgetCategory, ""))) > 0))),
  local!cont: if(a!isNullOrEmpty(local!contIdx), null, index(local!lines, local!contIdx[1], null)),
  local!totalBalance: sum(a!forEach(items: local!lines, expression: a!defaultValue(fv!item.balanceToComplete, 0))),
  local!qiuAsOf: if(a!isNullOrEmpty(local!qiu), null, index(local!qiu, 1, null).modelAsOfDate),
  /* Styles, kept short: they repeat on every cell */
  local!band: "background:#16294D;color:#FFFFFF;padding:6px 12px;font-size:11px;font-weight:bold;letter-spacing:0.5px;",
  local!th: "background:#E8EEF7;color:#16294D;padding:5px 6px;border-bottom:1px solid #C9D4EF;font-size:10px;font-weight:bold;",
  local!label: "background:#EEF1F5;color:#6B7280;padding:4px 8px;border-bottom:1px solid #E5E7EB;width:34%;",
  local!value: "padding:4px 8px;border-bottom:1px solid #E5E7EB;",
  local!tableOpen: "<table role=""presentation"" width=""100%"" cellpadding=""0"" cellspacing=""0"" border=""0"" style=""border-collapse:collapse;font-family:Arial,Helvetica,sans-serif;font-size:11px;color:#1F2937;"">",
  /* Section band as a full-width row of the outer table */
  local!lineHeader: "<tr>" & rule!SD_emailCells(texts: {"Budget Category", "Initial Budget", "Revised Approved Budget", "Proposed Adjustments This Draw", "Proposed Budget", "Current Draw", "Total PTD inc. This Draw ($)", "Total PTD inc. This Draw (%)", "Balance To Complete"}, aligns: {"left", "right", "right", "right", "right", "right", "right", "right", "right"}, style: local!th, tag: "th") & "</tr>",
  local!groupRow: "<tr><td colspan=""9"" style=""padding:5px 6px;font-size:10px;font-weight:bold;color:#16294D;background:#F5F6F8;"">",
  local!lineRows: if(
    a!isNullOrEmpty(local!lines),
    "<tr><td colspan=""9"" style=""" & local!value & """>No budget lines on this draw</td></tr>",
    concat(
      if(a!isNullOrEmpty(local!inDraw), local!groupRow & "In this Draw</td></tr><tr><td colspan=""9"" style=""" & local!value & "color:#6B7280;"">No budget categories are funded by this draw</td></tr>", local!groupRow & "In this Draw</td></tr>" & concat(a!forEach(items: local!inDraw, expression: rule!SD_emailRow(
        cells: {
          rule!SD_htmlEscape(text: fv!item.budgetCategory),
          rule!SD_fmtMoneyDash(value: fv!item.initialBudget), rule!SD_fmtMoneyDash(value: fv!item.revisedApprovedBudget),
          rule!SD_fmtMoneyDash(value: fv!item.proposedAdjustmentsThisDraw), rule!SD_fmtMoneyDash(value: fv!item.proposedBudget),
          rule!SD_fmtMoneyDash(value: fv!item.currentDraw), rule!SD_fmtMoneyDash(value: fv!item.totalPtdIncThisDrawAmount),
          if(a!defaultValue(fv!item.totalPtdIncThisDrawAmount, 0) = 0, "—", text(a!defaultValue(fv!item.totalPtdIncThisDrawPct, 0), "0.0") & "%"), rule!SD_fmtMoneyDash(value: fv!item.balanceToComplete)
        },
        aligns: {"left", "right", "right", "right", "right", "right", "right", "right", "right"},
        bold: false,
        cellStyles: {"", "", "", "", "", "background:#EEF4FF;", "", "", ""}
      )))),
      if(a!isNullOrEmpty(local!others), "", local!groupRow & "All Other Budget Categories</td></tr>" & concat(a!forEach(items: local!others, expression: rule!SD_emailRow(
        cells: {
          rule!SD_htmlEscape(text: fv!item.budgetCategory),
          rule!SD_fmtMoneyDash(value: fv!item.initialBudget), rule!SD_fmtMoneyDash(value: fv!item.revisedApprovedBudget),
          rule!SD_fmtMoneyDash(value: fv!item.proposedAdjustmentsThisDraw), rule!SD_fmtMoneyDash(value: fv!item.proposedBudget),
          rule!SD_fmtMoneyDash(value: fv!item.currentDraw), rule!SD_fmtMoneyDash(value: fv!item.totalPtdIncThisDrawAmount),
          if(a!defaultValue(fv!item.totalPtdIncThisDrawAmount, 0) = 0, "—", text(a!defaultValue(fv!item.totalPtdIncThisDrawPct, 0), "0.0") & "%"), rule!SD_fmtMoneyDash(value: fv!item.balanceToComplete)
        },
        aligns: {"left", "right", "right", "right", "right", "right", "right", "right", "right"},
        bold: false,
        cellStyles: {"", "", "", "", "", "background:#EEF4FF;", "", "", ""}
      )))),
      rule!SD_emailRow(
        cells: {
          rule!SD_htmlEscape(text: local!total.budgetCategory),
          rule!SD_fmtMoneyDash(value: local!total.initialBudget), rule!SD_fmtMoneyDash(value: local!total.revisedApprovedBudget),
          rule!SD_fmtMoneyDash(value: local!total.proposedAdjustmentsThisDraw), rule!SD_fmtMoneyDash(value: local!total.proposedBudget),
          rule!SD_fmtMoneyDash(value: local!total.currentDraw), rule!SD_fmtMoneyDash(value: local!total.totalPtdIncThisDrawAmount),
          if(a!defaultValue(local!total.totalPtdIncThisDrawAmount, 0) = 0, "—", text(a!defaultValue(local!total.totalPtdIncThisDrawPct, 0), "0.0") & "%"), rule!SD_fmtMoneyDash(value: local!total.balanceToComplete)
        },
        aligns: {"left", "right", "right", "right", "right", "right", "right", "right", "right"},
        bold: true,
        cellStyles: {"", "", "", "", "", "background:#EEF4FF;", "", "", ""}
      )
    )
  ),
  local!summaryRows: if(
    a!isNullOrEmpty(local!lines),
    "<tr><td colspan=""9"" style=""" & local!value & """>No budget lines on this draw</td></tr>",
    concat(
      concat(a!forEach(items: local!groups, expression: rule!SD_emailRow(
        cells: {
          rule!SD_htmlEscape(text: fv!item.budgetCategory),
          rule!SD_fmtMoneyDash(value: fv!item.initialBudget), rule!SD_fmtMoneyDash(value: fv!item.revisedApprovedBudget),
          rule!SD_fmtMoneyDash(value: fv!item.proposedAdjustmentsThisDraw), rule!SD_fmtMoneyDash(value: fv!item.proposedBudget),
          rule!SD_fmtMoneyDash(value: fv!item.currentDraw), rule!SD_fmtMoneyDash(value: fv!item.totalPtdIncThisDrawAmount),
          if(a!defaultValue(fv!item.proposedBudget, 0) = 0, "—", text(100 * a!defaultValue(fv!item.totalPtdIncThisDrawAmount, 0) / fv!item.proposedBudget, "0.0") & "%"), rule!SD_fmtMoneyDash(value: fv!item.balanceToComplete)
        },
        aligns: {"left", "right", "right", "right", "right", "right", "right", "right", "right"},
        bold: false,
        cellStyles: {"", "", "", "", "", "", "", "", ""}
      ))),
      rule!SD_emailRow(
        cells: {
          rule!SD_htmlEscape(text: local!total.budgetCategory),
          rule!SD_fmtMoneyDash(value: local!total.initialBudget), rule!SD_fmtMoneyDash(value: local!total.revisedApprovedBudget),
          rule!SD_fmtMoneyDash(value: local!total.proposedAdjustmentsThisDraw), rule!SD_fmtMoneyDash(value: local!total.proposedBudget),
          rule!SD_fmtMoneyDash(value: local!total.currentDraw), rule!SD_fmtMoneyDash(value: local!total.totalPtdIncThisDrawAmount),
          if(a!defaultValue(local!total.totalPtdIncThisDrawAmount, 0) = 0, "—", text(a!defaultValue(local!total.totalPtdIncThisDrawPct, 0), "0.0") & "%"), rule!SD_fmtMoneyDash(value: local!total.balanceToComplete)
        },
        aligns: {"left", "right", "right", "right", "right", "right", "right", "right", "right"},
        bold: true,
        cellStyles: {"", "", "", "", "", "", "", "", ""}
      )
    )
  ),
  local!contRows: if(
    a!isNullOrEmpty(local!cont),
    "<tr><td colspan=""7"" style=""" & local!value & """>No contingency line on this draw</td></tr>",
    rule!SD_emailRow(
      cells: {"Remaining Contingency ($)", rule!SD_fmtMoneyDash(value: local!cont.initialBudget), rule!SD_fmtMoneyDash(value: local!cont.revisedApprovedBudget), rule!SD_fmtMoneyDash(value: local!cont.proposedAdjustmentsThisDraw), rule!SD_fmtMoneyDash(value: local!cont.balanceToComplete), rule!SD_fmtMoneyDash(value: a!defaultValue(local!cont.balanceToComplete, 0) - a!defaultValue(local!cont.revisedApprovedBudget, 0)), "—"},
      aligns: {"left", "right", "right", "right", "right", "right", "left"}, bold: false, cellStyles: {"", "", "", "", "", "", ""}
    ) & rule!SD_emailRow(
      cells: {"Remaining Contingency (%)", "—", if(local!totalBalance = 0, "—", text(a!defaultValue(local!cont.revisedApprovedBudget, 0) / local!totalBalance, "0.0%")), "—", if(local!totalBalance = 0, "—", text(a!defaultValue(local!cont.balanceToComplete, 0) / local!totalBalance, "0.0%")), "—", "Percent is contingency over total balance to complete (" & rule!SD_fmtMoney(value: local!totalBalance, showCents: false) & ")"},
      aligns: {"left", "right", "right", "right", "right", "right", "left"}, bold: false, cellStyles: {"", "", "", "", "", "", ""}
    )
  ),
  local!qiuRows: if(
    a!isNullOrEmpty(local!qiu),
    "<tr><td colspan=""5"" style=""" & local!value & """>No QIU metrics on this draw</td></tr>",
    concat(a!forEach(items: local!qiu, expression: rule!SD_emailRow(
      cells: {rule!SD_htmlEscape(text: fv!item.metric), rule!SD_htmlEscape(text: a!defaultValue(fv!item.currentModelValue, "—")), rule!SD_htmlEscape(text: a!defaultValue(fv!item.currentProjection, "—")), rule!SD_htmlEscape(text: a!defaultValue(fv!item.variance, "—")), if(a!isNullOrEmpty(fv!item.notes), "—", rule!SD_htmlEscape(text: fv!item.notes))},
      aligns: {"left", "right", "right", "right", "left"}, bold: false, cellStyles: {"", "", "", "", ""}
    )))
  ),
  local!apprRows: if(
    a!isNullOrEmpty(local!appr),
    "<tr><td colspan=""6"" style=""" & local!value & """>No approval chain on this draw</td></tr>",
    concat(a!forEach(items: local!appr, expression: a!localVariables(
      local!isCurrent: tointeger(a!defaultValue(fv!item.approvalOrder, 0)) = tointeger(ri!stepOrder),
      local!status: a!defaultValue(fv!item.status, ""),
      local!chipBg: a!match(value: local!status, equals: "Approved", then: "#E6F4EC", equals: "In Progress", then: "#E8F0FC", equals: "Rejected", then: "#FDECEC", default: "#EEF1F5"),
      local!chipFg: a!match(value: local!status, equals: "Approved", then: "#1E7E46", equals: "In Progress", then: "#1D5BBF", equals: "Rejected", then: "#B42318", default: "#64748B"),
      local!rowBg: if(local!isCurrent, "background:#FFF8E6;", ""),
      rule!SD_emailRow(
        cells: {
          if(local!isCurrent, "&#9654; " & fv!item.approvalOrder, tostring(fv!item.approvalOrder)),
          rule!SD_htmlEscape(text: fv!item.role),
          rule!SD_htmlEscape(text: fv!item.approverName),
          "<span style=""display:inline-block;padding:2px 8px;border-radius:10px;background:" & local!chipBg & ";color:" & local!chipFg & ";font-size:10px;font-weight:bold;"">" & rule!SD_htmlEscape(text: local!status) & "</span>",
          if(a!isNullOrEmpty(fv!item.decisionDate), "—", text(fv!item.decisionDate, "MM/DD/YYYY")),
          if(local!isCurrent, "<b>&#9664; Current step — your approval is requested</b>", if(a!isNullOrEmpty(fv!item.comments), "—", rule!SD_htmlEscape(text: fv!item.comments)))
        },
        aligns: {"center", "left", "left", "left", "left", "left"},
        bold: local!isCurrent,
        cellStyles: {local!rowBg, local!rowBg, local!rowBg, local!rowBg, local!rowBg, local!rowBg}
      )
    )))
  ),
  local!detailRows: concat(a!forEach(
    items: {
      a!map(l: "Investment Name", v: local!investment),
      a!map(l: "Investment Description", v: a!defaultValue(index(local!d, "investmentDescription", ""), "")),
      a!map(l: "Fund", v: local!fund),
      a!map(l: "Amount", v: local!amountText),
      a!map(l: "Cash/Equity Needed from the Fund?", v: if(a!isNullOrEmpty(index(local!d, "cashEquityNeeded", null)), "—", if(index(local!d, "cashEquityNeeded", false), "Yes", "No"))),
      a!map(l: "Funding Date", v: local!fundingText),
      a!map(l: "Draw Type", v: local!drawType),
      a!map(l: "Purpose", v: a!defaultValue(index(local!d, "purpose", ""), "")),
      a!map(l: "On / Under / Over Budget", v: local!budgetStatus),
      a!map(l: "Over Budget Reason", v: a!defaultValue(index(local!d, "overBudgetReason", ""), "")),
      a!map(l: "General Comments", v: a!defaultValue(index(local!d, "generalComments", ""), "")),
      a!map(l: "Budget and Contingency Explanation", v: a!defaultValue(index(local!d, "contingencyExplanation", ""), ""))
    },
    expression: "<tr><td style=""" & local!label & """>" & fv!item.l & "</td><td style=""" & local!value & """>" & if(a!defaultValue(fv!item.v, "") = "", "—", rule!SD_htmlEscape(text: fv!item.v)) & "</td></tr>"
  )),
  local!subject: "Draw Funding Approval: Draw #" & a!defaultValue(local!drawNumber, ri!drawId) & " · " & local!investment & " · " & local!amountText & " · Step " & ri!stepOrder & " of " & local!totalSteps & " (" & local!stepRole & ")",
  local!html: concat(
    "<div style=""margin:0;padding:0;background:#F5F6F8;"">",
    "<table role=""presentation"" width=""100%"" cellpadding=""0"" cellspacing=""0"" border=""0"" style=""background:#F5F6F8;""><tr><td align=""center"" style=""padding:12px;"">",
    "<table role=""presentation"" width=""100%"" cellpadding=""0"" cellspacing=""0"" border=""0"" style=""max-width:1040px;background:#FFFFFF;border:1px solid #D9DEE7;font-family:Arial,Helvetica,sans-serif;color:#1F2937;"">",
    /* Header band */
    "<tr><td style=""background:#16294D;color:#FFFFFF;padding:14px 18px 6px 18px;font-size:16px;font-weight:bold;font-family:Arial,Helvetica,sans-serif;"">DRAW FUNDING APPROVAL &nbsp;|&nbsp; " & rule!SD_htmlEscape(text: local!investment) & "</td></tr>",
    "<tr><td style=""background:#16294D;color:#C7D2E5;padding:0 18px 12px 18px;font-size:11px;font-family:Arial,Helvetica,sans-serif;"">Draw #" & a!defaultValue(local!drawNumber, "—") & " &nbsp;&middot;&nbsp; Fund: " & rule!SD_htmlEscape(text: local!fund) & " &nbsp;&middot;&nbsp; Draw Type: " & rule!SD_htmlEscape(text: local!drawType) & " &nbsp;&middot;&nbsp; Funding Date: " & local!fundingText & " &nbsp;&middot;&nbsp; Amount: " & local!amountText & " &nbsp;&middot;&nbsp; " & rule!SD_htmlEscape(text: if(local!budgetStatus = "", "—", local!budgetStatus)) & "</td></tr>",
    /* Greeting and reply instruction */
    "<tr><td style=""padding:14px 18px 10px 18px;font-size:13px;line-height:18px;font-family:Arial,Helvetica,sans-serif;"">Hello " & rule!SD_htmlEscape(text: if(local!approverName = "", "approver", local!approverName)) & ",<br>This draw is ready for your approval (step " & ri!stepOrder & " of " & local!totalSteps & ", " & rule!SD_htmlEscape(text: local!stepRole) & "). Please reply either &quot;Approve&quot; or &quot;Reject&quot; to this email.<br><span style=""color:#B42318;font-style:italic;font-weight:bold;"">***Please note anything other than Approve or Reject will result in the system&#39;s failure to recognize your response.***</span></td></tr>",
    /* Draw Funding Detail */
    "<tr><td style=""padding:0 12px;"">" & local!tableOpen & "<tr><td colspan=""2"" style=""" & local!band & """>DRAW FUNDING DETAIL</td></tr>" & local!detailRows & "</table></td></tr>",
    "<tr><td style=""height:12px;font-size:1px;line-height:12px;"">&nbsp;</td></tr>",
    /* Draw Detail by Budget Category */
    "<tr><td style=""padding:0 12px;"">" & local!tableOpen & "<tr><td colspan=""9"" style=""" & local!band & """>DRAW DETAIL BY BUDGET CATEGORY</td></tr>" & local!lineHeader & local!lineRows & "</table></td></tr>",
    "<tr><td style=""height:12px;font-size:1px;line-height:12px;"">&nbsp;</td></tr>",
    /* Budget Summary */
    "<tr><td style=""padding:0 12px;"">" & local!tableOpen & "<tr><td colspan=""9"" style=""" & local!band & """>BUDGET SUMMARY</td></tr>" & local!lineHeader & local!summaryRows & "<tr><td colspan=""9"" style=""padding:4px 6px;font-size:10px;color:#6B7280;"">Roll-up of the budget lines by category group. Land: site &amp; acquisition. Hard: construction &amp; FF&amp;E. Soft: fees, taxes, insurance, financing, marketing, contingency.</td></tr></table></td></tr>",
    "<tr><td style=""height:12px;font-size:1px;line-height:12px;"">&nbsp;</td></tr>",
    /* Remaining Contingency */
    "<tr><td style=""padding:0 12px;"">" & local!tableOpen & "<tr><td colspan=""7"" style=""" & local!band & """>REMAINING CONTINGENCY</td></tr><tr>" & rule!SD_emailCells(texts: {"Costs", "Original Budget", "Revised Approved Budget", "Proposed Adjustments This Draw", "Proposed Budget", "Variance", "Reason"}, aligns: {"left", "right", "right", "right", "right", "right", "left"}, style: local!th, tag: "th") & "</tr>" & local!contRows & "</table></td></tr>",
    "<tr><td style=""height:12px;font-size:1px;line-height:12px;"">&nbsp;</td></tr>",
    /* QIU Detail */
    "<tr><td style=""padding:0 12px;"">" & local!tableOpen & "<tr><td colspan=""5"" style=""" & local!band & """>QIU DETAIL &mdash; " & rule!SD_htmlEscape(text: local!investment) & "</td></tr><tr>" & rule!SD_emailCells(texts: {"Metric", "Current QIU Model" & if(a!isNullOrEmpty(local!qiuAsOf), "", " (" & text(todate(local!qiuAsOf), "MM/DD/YYYY") & ")"), "Current Projection", "Variance of Current Projection", "Notes"}, aligns: {"left", "right", "right", "right", "left"}, style: local!th, tag: "th") & "</tr>" & local!qiuRows & "</table></td></tr>",
    "<tr><td style=""height:12px;font-size:1px;line-height:12px;"">&nbsp;</td></tr>",
    /* Approval Status */
    "<tr><td style=""padding:0 12px;"">" & local!tableOpen & "<tr><td colspan=""6"" style=""" & local!band & """>APPROVAL STATUS</td></tr><tr>" & rule!SD_emailCells(texts: {"Order", "Role", "Approver", "Status", "Decision Date", "Comments"}, aligns: {"center", "left", "left", "left", "left", "left"}, style: local!th, tag: "th") & "</tr>" & local!apprRows & "</table></td></tr>",
    "<tr><td style=""height:12px;font-size:1px;line-height:12px;"">&nbsp;</td></tr>",
    /* Footer */
    "<tr><td style=""background:#16294D;color:#FFFFFF;padding:10px 18px;font-size:12px;font-style:italic;font-family:Arial,Helvetica,sans-serif;"">Reply &quot;Approve&quot; or &quot;Reject&quot; to this email.</td></tr>",
    "</table></td></tr></table></div>"
  ),
  a!map(subject: local!subject, html: local!html, bytes: len(local!html))
)

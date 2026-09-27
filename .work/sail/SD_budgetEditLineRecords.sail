/* Draw approval (Phase 6c): the SD Draw Budget Line updates for an Asset Manager's edit plan (rule!SD_planBudgetEdit),
   for one Write Records node. Only the edited columns and the columns derived from them are written; every other
   field of the line is left as it is. */
if(
  a!isNullOrEmpty(index(ri!plan, "lines", {})),
  {},
  a!forEach(
    items: index(ri!plan, "lines", {}),
    expression: 'recordType!{ddc4073e-6372-49e2-80de-a088b424abcd}SD Draw Budget Line'(
      'recordType!{ddc4073e-6372-49e2-80de-a088b424abcd}SD Draw Budget Line.fields.{14803371-b715-43a4-bc3a-94e314f16f8a}id': tointeger(fv!item.id),
      'recordType!{ddc4073e-6372-49e2-80de-a088b424abcd}SD Draw Budget Line.fields.{497f7abe-c453-4b00-97ad-1f5da03f5cd2}proposedAdjustmentsThisDraw': fv!item.toAdj,
      'recordType!{ddc4073e-6372-49e2-80de-a088b424abcd}SD Draw Budget Line.fields.{eb2590fe-db09-40e0-8711-a0a044141fe6}proposedBudget': fv!item.proposedBudget,
      'recordType!{ddc4073e-6372-49e2-80de-a088b424abcd}SD Draw Budget Line.fields.{5242c9d6-c607-43c9-900c-756163dcbae5}currentDraw': fv!item.toCurrent,
      'recordType!{ddc4073e-6372-49e2-80de-a088b424abcd}SD Draw Budget Line.fields.{aab45d4c-cd07-43ce-87e6-21d485c77827}totalPtdIncThisDrawAmount': fv!item.totalPtd,
      'recordType!{ddc4073e-6372-49e2-80de-a088b424abcd}SD Draw Budget Line.fields.{69bde771-7a23-4f20-9c2a-4303372651cd}totalPtdIncThisDrawPct': fv!item.totalPtdPct,
      'recordType!{ddc4073e-6372-49e2-80de-a088b424abcd}SD Draw Budget Line.fields.{88da0de6-2ef3-428e-9e04-9edc085fe9b1}balanceToComplete': fv!item.balanceToComplete,
      'recordType!{ddc4073e-6372-49e2-80de-a088b424abcd}SD Draw Budget Line.fields.{afd91132-85fa-48aa-a534-0c6a2818b0c3}inThisDraw': fv!item.inThisDraw
    )
  )
)

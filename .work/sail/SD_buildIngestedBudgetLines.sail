/* Draw approval (Phase 3): the SD Draw Budget Line rows for an ingested draw, from the accountant-confirmed lines JSON
   (rule!SD_form_reconcileExtraction's confirmedLinesJson: lineOrder, budgetCategory, nine amounts as fixed(…, 4) text).
   categoryGroup follows the Budget Summary roll-up (Hard: Hard Costs, FF&E; Land: Land, Acquisition Costs; else Soft);
   inThisDraw is true when the line draws or adjusts this period, which is what separates the email's "In this Draw"
   rows from "All Other Budget Categories". Returns {} when there are no lines. */
a!localVariables(
  local!rows: if(a!isNullOrEmpty(ri!linesJson), {}, a!fromJson(ri!linesJson)),
  if(
    a!isNullOrEmpty(local!rows),
    {},
    a!forEach(
      items: local!rows,
      expression: a!localVariables(
        local!cat: trim(tostring(a!defaultValue(fv!item.budgetCategory, ""))),
        local!catKey: lower(local!cat),
        local!group: if(
          or(local!catKey = "hard costs", local!catKey = "ff&e"),
          "Hard",
          if(or(local!catKey = "land", local!catKey = "acquisition costs"), "Land", "Soft")
        ),
        local!current: todecimal(a!defaultValue(fv!item.currentDraw, "0")),
        local!adj: todecimal(a!defaultValue(fv!item.proposedAdjustmentsThisDraw, "0")),
        'recordType!{ddc4073e-6372-49e2-80de-a088b424abcd}SD Draw Budget Line'(
          'recordType!{ddc4073e-6372-49e2-80de-a088b424abcd}SD Draw Budget Line.fields.{830216a5-8980-4ac0-a8f9-7baa33bbea6b}drawId': ri!drawId,
          'recordType!{ddc4073e-6372-49e2-80de-a088b424abcd}SD Draw Budget Line.fields.{2dd34362-59f3-46ad-bb7b-12f44273015e}lineOrder': tointeger(a!defaultValue(fv!item.lineOrder, fv!index)),
          'recordType!{ddc4073e-6372-49e2-80de-a088b424abcd}SD Draw Budget Line.fields.{4b8934ab-ad8e-4fc0-ac4e-86a762018dee}budgetCategory': local!cat,
          'recordType!{ddc4073e-6372-49e2-80de-a088b424abcd}SD Draw Budget Line.fields.{2bb6dc6b-76ba-4c39-ba45-837acbf905c1}categoryGroup': local!group,
          'recordType!{ddc4073e-6372-49e2-80de-a088b424abcd}SD Draw Budget Line.fields.{afd91132-85fa-48aa-a534-0c6a2818b0c3}inThisDraw': or(local!current <> 0, local!adj <> 0),
          'recordType!{ddc4073e-6372-49e2-80de-a088b424abcd}SD Draw Budget Line.fields.{037ae530-9352-430e-a9b8-9d8b11b8450d}initialBudget': todecimal(a!defaultValue(fv!item.initialBudget, "0")),
          'recordType!{ddc4073e-6372-49e2-80de-a088b424abcd}SD Draw Budget Line.fields.{eb2ed1b0-6417-4468-a2a2-a0e7f643e931}revisedApprovedBudget': todecimal(a!defaultValue(fv!item.revisedApprovedBudget, "0")),
          'recordType!{ddc4073e-6372-49e2-80de-a088b424abcd}SD Draw Budget Line.fields.{497f7abe-c453-4b00-97ad-1f5da03f5cd2}proposedAdjustmentsThisDraw': local!adj,
          'recordType!{ddc4073e-6372-49e2-80de-a088b424abcd}SD Draw Budget Line.fields.{eb2590fe-db09-40e0-8711-a0a044141fe6}proposedBudget': todecimal(a!defaultValue(fv!item.proposedBudget, "0")),
          'recordType!{ddc4073e-6372-49e2-80de-a088b424abcd}SD Draw Budget Line.fields.{5242c9d6-c607-43c9-900c-756163dcbae5}currentDraw': local!current,
          'recordType!{ddc4073e-6372-49e2-80de-a088b424abcd}SD Draw Budget Line.fields.{aab45d4c-cd07-43ce-87e6-21d485c77827}totalPtdIncThisDrawAmount': todecimal(a!defaultValue(fv!item.totalPtdIncThisDrawAmount, "0")),
          'recordType!{ddc4073e-6372-49e2-80de-a088b424abcd}SD Draw Budget Line.fields.{69bde771-7a23-4f20-9c2a-4303372651cd}totalPtdIncThisDrawPct': todecimal(a!defaultValue(fv!item.totalPtdIncThisDrawPct, "0")),
          'recordType!{ddc4073e-6372-49e2-80de-a088b424abcd}SD Draw Budget Line.fields.{88da0de6-2ef3-428e-9e04-9edc085fe9b1}balanceToComplete': todecimal(a!defaultValue(fv!item.balanceToComplete, "0"))
        )
      )
    )
  )
)

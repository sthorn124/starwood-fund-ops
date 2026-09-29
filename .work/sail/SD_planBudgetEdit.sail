/* Draw approval (Phase 6c): the Asset Manager's edits to the budget lines at their approval step, as the process will
   write them. ri!editsJson is what the task form sends: a list of {id, toAdj, toCurrent} for the lines the Asset Manager
   changed. Nothing is taken on trust from the form: the step must be the Asset Manager's (the approval row at
   ri!stepOrder has role "Asset Manager"), each id must be a line of this draw, and a line counts only if its adjustment
   or current draw differs from the stored value by a cent or more. Derived columns are recomputed from the stored line:
   proposed budget = revised approved budget + adjustment; PTD = stored PTD - stored current draw + new current draw;
   PTD % = PTD / proposed budget x 100; balance to complete = proposed budget - PTD; the line is "in this draw" when its
   current draw or adjustment is not zero. The attribution sentence is composed here, once, and frozen in the event
   (at most 250 characters: the event comment column is VARCHAR(255)). Returns a map: hasEdits, count, lines, summary. */
a!localVariables(
  local!state: if(a!isNullOrEmpty(ri!drawId), null, rule!SD_getDrawState(ri!drawId)),
  local!approvals: if(a!isNullOrEmpty(local!state), {}, a!defaultValue(index(local!state, "approvals", {}), {})),
  local!rowIdx: if(or(a!isNullOrEmpty(local!approvals), a!isNullOrEmpty(ri!stepOrder)), {}, wherecontains(tointeger(ri!stepOrder), a!forEach(items: local!approvals, expression: tointeger(index(fv!item, "approvalOrder", 0))))),
  local!role: if(a!isNullOrEmpty(local!rowIdx), "", tostring(a!defaultValue(index(index(local!approvals, local!rowIdx[1], null), "role", ""), ""))),
  local!isAmStep: local!role = "Asset Manager",
  local!json: trim(a!defaultValue(ri!editsJson, "")),
  local!edits: if(or(not(local!isAmStep), local!json = "", local!json = "[]", left(local!json, 1) <> "["), {}, a!fromJson(local!json)),
  local!lines: if(
    or(a!isNullOrEmpty(local!edits), a!isNullOrEmpty(ri!drawId)),
    {},
    a!forEach(
      items: a!queryRecordType(
        recordType: 'recordType!{ddc4073e-6372-49e2-80de-a088b424abcd}SD Draw Budget Line',
        fields: {'recordType!{ddc4073e-6372-49e2-80de-a088b424abcd}SD Draw Budget Line.fields.{14803371-b715-43a4-bc3a-94e314f16f8a}id', 'recordType!{ddc4073e-6372-49e2-80de-a088b424abcd}SD Draw Budget Line.fields.{4b8934ab-ad8e-4fc0-ac4e-86a762018dee}budgetCategory', 'recordType!{ddc4073e-6372-49e2-80de-a088b424abcd}SD Draw Budget Line.fields.{eb2ed1b0-6417-4468-a2a2-a0e7f643e931}revisedApprovedBudget', 'recordType!{ddc4073e-6372-49e2-80de-a088b424abcd}SD Draw Budget Line.fields.{497f7abe-c453-4b00-97ad-1f5da03f5cd2}proposedAdjustmentsThisDraw', 'recordType!{ddc4073e-6372-49e2-80de-a088b424abcd}SD Draw Budget Line.fields.{5242c9d6-c607-43c9-900c-756163dcbae5}currentDraw', 'recordType!{ddc4073e-6372-49e2-80de-a088b424abcd}SD Draw Budget Line.fields.{aab45d4c-cd07-43ce-87e6-21d485c77827}totalPtdIncThisDrawAmount'},
        filters: a!queryFilter(field: 'recordType!{ddc4073e-6372-49e2-80de-a088b424abcd}SD Draw Budget Line.fields.{830216a5-8980-4ac0-a8f9-7baa33bbea6b}drawId', operator: "=", value: ri!drawId),
        pagingInfo: a!pagingInfo(startIndex: 1, batchSize: 100)
      ).data,
      expression: a!map(
        id: fv!item['recordType!{ddc4073e-6372-49e2-80de-a088b424abcd}SD Draw Budget Line.fields.{14803371-b715-43a4-bc3a-94e314f16f8a}id'],
        category: tostring(a!defaultValue(fv!item['recordType!{ddc4073e-6372-49e2-80de-a088b424abcd}SD Draw Budget Line.fields.{4b8934ab-ad8e-4fc0-ac4e-86a762018dee}budgetCategory'], "")),
        revised: todecimal(a!defaultValue(fv!item['recordType!{ddc4073e-6372-49e2-80de-a088b424abcd}SD Draw Budget Line.fields.{eb2ed1b0-6417-4468-a2a2-a0e7f643e931}revisedApprovedBudget'], 0)),
        adj: todecimal(a!defaultValue(fv!item['recordType!{ddc4073e-6372-49e2-80de-a088b424abcd}SD Draw Budget Line.fields.{497f7abe-c453-4b00-97ad-1f5da03f5cd2}proposedAdjustmentsThisDraw'], 0)),
        current: todecimal(a!defaultValue(fv!item['recordType!{ddc4073e-6372-49e2-80de-a088b424abcd}SD Draw Budget Line.fields.{5242c9d6-c607-43c9-900c-756163dcbae5}currentDraw'], 0)),
        ptd: todecimal(a!defaultValue(fv!item['recordType!{ddc4073e-6372-49e2-80de-a088b424abcd}SD Draw Budget Line.fields.{aab45d4c-cd07-43ce-87e6-21d485c77827}totalPtdIncThisDrawAmount'], 0))
      )
    )
  ),
  local!ids: if(a!isNullOrEmpty(local!lines), {}, a!forEach(items: local!lines, expression: tointeger(fv!item.id))),
  local!name: rule!SD_getUserDisplayName(username: ri!actor),
  local!today: text(todate(local(now(), cons!SD_BUSINESS_TIMEZONE)), "MMM D, YYYY"),
  local!candidates: if(
    or(a!isNullOrEmpty(local!edits), a!isNullOrEmpty(local!ids)),
    {},
    a!forEach(
      items: local!edits,
      expression: a!localVariables(
        local!id: tointeger(index(fv!item, "id", null)),
        local!pos: if(a!isNullOrEmpty(local!id), {}, wherecontains(local!id, local!ids)),
        local!line: if(a!isNullOrEmpty(local!pos), null, index(local!lines, local!pos[1], null)),
        local!fromAdj: if(a!isNullOrEmpty(local!line), 0, local!line.adj),
        local!fromCur: if(a!isNullOrEmpty(local!line), 0, local!line.current),
        local!toAdj: round(todecimal(a!defaultValue(index(fv!item, "toAdj", null), local!fromAdj)), 2),
        local!toCur: round(todecimal(a!defaultValue(index(fv!item, "toCurrent", null), local!fromCur)), 2),
        local!adjChanged: abs(local!toAdj - local!fromAdj) >= 0.005,
        local!curChanged: abs(local!toCur - local!fromCur) >= 0.005,
        local!proposed: if(a!isNullOrEmpty(local!line), 0, local!line.revised + local!toAdj),
        local!ptd: if(a!isNullOrEmpty(local!line), 0, local!line.ptd - local!fromCur + local!toCur),
        local!fmt: a!forEach(
          items: {local!fromAdj, local!toAdj, local!fromCur, local!toCur},
          expression: rule!SD_fmtMoney(value: fv!item, showCents: abs(fv!item - round(fv!item, 0)) >= 0.005)
        ),
        a!map(
          keep: and(not(a!isNullOrEmpty(local!line)), or(local!adjChanged, local!curChanged)),
          id: local!id,
          budgetCategory: if(a!isNullOrEmpty(local!line), "", local!line.category),
          fromAdj: local!fromAdj,
          toAdj: local!toAdj,
          fromCurrent: local!fromCur,
          toCurrent: local!toCur,
          proposedBudget: local!proposed,
          totalPtd: local!ptd,
          totalPtdPct: if(local!proposed = 0, null, round(100 * local!ptd / local!proposed, 4)),
          balanceToComplete: local!proposed - local!ptd,
          inThisDraw: or(local!toCur <> 0, local!toAdj <> 0),
          comment: left(
            local!name & " edited " & if(a!isNullOrEmpty(local!line), "a line", local!line.category) & " at approval (step " & ri!stepOrder & ", " & local!today & "): " &
            joinarray(
              reject(
                fn!isnull,
                {
                  if(local!adjChanged, "adjustment " & local!fmt[1] & " → " & local!fmt[2], null),
                  if(local!curChanged, "current draw " & local!fmt[3] & " → " & local!fmt[4], null)
                }
              ),
              "; "
            ),
            250
          )
        )
      )
    )
  ),
  local!keepFlags: if(a!isNullOrEmpty(local!candidates), {}, a!forEach(items: local!candidates, expression: a!defaultValue(fv!item.keep, false))),
  local!kept: if(a!isNullOrEmpty(local!keepFlags), {}, index(local!candidates, wherecontains(true, local!keepFlags), {})),
  local!n: if(a!isNullOrEmpty(local!keepFlags), 0, count(wherecontains(true, local!keepFlags))),
  a!map(
    hasEdits: local!n > 0,
    count: local!n,
    isAmStep: local!isAmStep,
    lines: local!kept,
    summary: if(
      local!n = 0,
      if(local!isAmStep, "No budget lines edited at approval", "Budget edits are allowed only at the Asset Manager's step"),
      local!n & if(local!n = 1, " budget line", " budget lines") & " edited at approval by " & local!name
    )
  )
)

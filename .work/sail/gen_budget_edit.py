"""Phase 6c: the Asset Manager's budget edit at approval (the client spreadsheet's step-5 enhancement). No f-strings in
the SAIL bodies.

  SD_planBudgetEdit(drawId, editsJson, actor, stepOrder)
        what the task form's edits mean, recomputed from the stored lines: only at the Asset Manager's step (the business
        rule: the Asset Manager may modify budget lines only at their own approval step), only lines of this draw, only
        lines that actually changed. Per line: the before and after adjustment and current draw, the derived proposed
        budget, PTD, PTD % and balance to complete, and the attribution sentence composed now (frozen in the event).
  SD_budgetEditLineRecords(plan)          the SD Draw Budget Line updates for the plan (one Write Records node)
  SD_budgetEditEventRecords(plan, actor)  one "Edited at Approval" event per edited line (SD Draw Budget Line Event
                                          History, written directly: user = the Asset Manager, automation NONE)
  SD_getBudgetLineEdits(drawId)           the draw's line history, newest first, for the Budget Detail view
"""
from refs import *

LN = lambda n: fld(LINE, n)
EVH = ("ee493a87-e51b-4148-8893-26de1e924ffb", "SD Draw Budget Line Event History")
EV = {"id": "cbefa248-a552-4bbb-9733-d4dd1d291a99", "timestamp": "f4ee5141-fec8-4e43-bdc5-1517fd82e679",
      "user": "61330b88-d4ce-46ea-9fe7-6a6b41eceed6", "eventTypeId": "ea2dea0a-3312-4fbb-bcb2-b7ab0e2994c8",
      "automationTypeId": "41f484ce-15f9-4537-9965-ad31088a0d0e", "comment": "b34057f7-f0af-4b64-a149-67e0a0992ee0",
      "recordId": "7e9a52d1-8566-4199-b6b9-167488e2383e"}
ev = lambda n: "'recordType!{" + EVH[0] + "}" + EVH[1] + ".fields.{" + EV[n] + "}" + n + "'"
EVRT = "'recordType!{" + EVH[0] + "}" + EVH[1] + "'"

PLAN = r'''/* Draw approval (Phase 6c): the Asset Manager's edits to the budget lines at their approval step, as the process will
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
        recordType: @LINE@,
        fields: {@L_ID@, @L_CATEGORY@, @L_REVISED@, @L_ADJ@, @L_CURRENT@, @L_PTD@},
        filters: a!queryFilter(field: @L_DRAW@, operator: "=", value: ri!drawId),
        pagingInfo: a!pagingInfo(startIndex: 1, batchSize: 100)
      ).data,
      expression: a!map(
        id: fv!item[@L_ID@],
        category: tostring(a!defaultValue(fv!item[@L_CATEGORY@], "")),
        revised: todecimal(a!defaultValue(fv!item[@L_REVISED@], 0)),
        adj: todecimal(a!defaultValue(fv!item[@L_ADJ@], 0)),
        current: todecimal(a!defaultValue(fv!item[@L_CURRENT@], 0)),
        ptd: todecimal(a!defaultValue(fv!item[@L_PTD@], 0))
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
'''

LINE_RECS = r'''/* Draw approval (Phase 6c): the SD Draw Budget Line updates for an Asset Manager's edit plan (rule!SD_planBudgetEdit),
   for one Write Records node. Only the edited columns and the columns derived from them are written; every other
   field of the line is left as it is. */
if(
  a!isNullOrEmpty(index(ri!plan, "lines", {})),
  {},
  a!forEach(
    items: index(ri!plan, "lines", {}),
    expression: @LINE@(
      @L_ID@: tointeger(fv!item.id),
      @L_ADJ@: fv!item.toAdj,
      @L_PROPOSED@: fv!item.proposedBudget,
      @L_CURRENT@: fv!item.toCurrent,
      @L_PTD@: fv!item.totalPtd,
      @L_PCT@: fv!item.totalPtdPct,
      @L_BALANCE@: fv!item.balanceToComplete,
      @L_INDRAW@: fv!item.inThisDraw
    )
  )
)
'''

EVENT_RECS = r'''/* Draw approval (Phase 6c): one "Edited at Approval" event per line of an Asset Manager's edit plan, written straight into
   SD Draw Budget Line Event History (a plain Write Records node, CaptureEvents off: the supplemental's working form for a
   worded event). User = the Asset Manager who submitted the task; automation NONE (1: done by a person); the comment is
   the attribution sentence the plan composed, cut to 250 characters for the VARCHAR(255) column. */
if(
  a!isNullOrEmpty(index(ri!plan, "lines", {})),
  {},
  a!forEach(
    items: index(ri!plan, "lines", {}),
    expression: @EVRT@(
      @E_RECORD@: tointeger(fv!item.id),
      @E_TYPE@: cons!SD_BUDGET_EDIT_EVENT_TYPE_ID,
      @E_USER@: touser(ri!actor),
      @E_TIME@: now(),
      @E_AUTO@: 1,
      @E_COMMENT@: left(tostring(fv!item.comment), 250)
    )
  )
)
'''

HISTORY = r'''/* Draw approval (Phase 6c): the draw's budget line history — every "Edited at Approval" event on its lines, newest
   first, as maps (id, lineId, budgetCategory, account, userName, at, comment; map keys are case-insensitive, so the account is not "username") for the Budget Detail view's line history
   and its "edited by … at approval" marks. */
a!localVariables(
  local!lines: if(
    a!isNullOrEmpty(ri!drawId),
    {},
    a!queryRecordType(
      recordType: @LINE@,
      fields: {@L_ID@, @L_CATEGORY@},
      filters: a!queryFilter(field: @L_DRAW@, operator: "=", value: ri!drawId),
      pagingInfo: a!pagingInfo(startIndex: 1, batchSize: 100)
    ).data
  ),
  local!ids: if(a!isNullOrEmpty(local!lines), {}, a!forEach(items: local!lines, expression: tointeger(fv!item[@L_ID@]))),
  local!events: if(
    a!isNullOrEmpty(local!ids),
    {},
    a!queryRecordType(
      recordType: @EVRT@,
      fields: {@E_ID@, @E_RECORD@, @E_USER@, @E_TIME@, @E_COMMENT@, @E_TYPE@},
      filters: {
        a!queryFilter(field: @E_RECORD@, operator: "in", value: local!ids),
        a!queryFilter(field: @E_TYPE@, operator: "=", value: cons!SD_BUDGET_EDIT_EVENT_TYPE_ID)
      },
      pagingInfo: a!pagingInfo(startIndex: 1, batchSize: 200, sort: {a!sortInfo(field: @E_TIME@, ascending: false), a!sortInfo(field: @E_ID@, ascending: false)})
    ).data
  ),
  if(
    a!isNullOrEmpty(local!events),
    {},
    a!forEach(
      items: local!events,
      expression: a!localVariables(
        local!pos: wherecontains(tointeger(fv!item[@E_RECORD@]), local!ids),
        a!map(
          id: fv!item[@E_ID@],
          lineId: tointeger(fv!item[@E_RECORD@]),
          budgetCategory: if(a!isNullOrEmpty(local!pos), "", tostring(index(local!lines, local!pos[1], null)[@L_CATEGORY@])),
          account: tostring(fv!item[@E_USER@]),
          userName: rule!SD_getUserDisplayName(username: tostring(fv!item[@E_USER@])),
          at: fv!item[@E_TIME@],
          comment: tostring(a!defaultValue(fv!item[@E_COMMENT@], ""))
        )
      )
    )
  )
)
'''

subs = {"@LINE@": rt(LINE), "@L_ID@": LN("id"), "@L_CATEGORY@": LN("budgetCategory"), "@L_REVISED@": LN("revisedApprovedBudget"),
        "@L_ADJ@": LN("proposedAdjustmentsThisDraw"), "@L_CURRENT@": LN("currentDraw"), "@L_PTD@": LN("totalPtdIncThisDrawAmount"),
        "@L_PCT@": LN("totalPtdIncThisDrawPct"), "@L_BALANCE@": LN("balanceToComplete"), "@L_PROPOSED@": LN("proposedBudget"),
        "@L_INDRAW@": LN("inThisDraw"), "@L_DRAW@": LN("drawId"),
        "@EVRT@": EVRT, "@E_ID@": ev("id"), "@E_RECORD@": ev("recordId"), "@E_TYPE@": ev("eventTypeId"), "@E_USER@": ev("user"),
        "@E_TIME@": ev("timestamp"), "@E_AUTO@": ev("automationTypeId"), "@E_COMMENT@": ev("comment")}
for name, text in [("SD_planBudgetEdit", PLAN), ("SD_budgetEditLineRecords", LINE_RECS),
                   ("SD_budgetEditEventRecords", EVENT_RECS), ("SD_getBudgetLineEdits", HISTORY)]:
    for k, v in subs.items():
        text = text.replace(k, v)
    assert "@L_" not in text and "@E_" not in text and "@LINE@" not in text and "@EVRT@" not in text, name
    open(name + ".sail", "w").write(text)
    print("wrote", name, len(text))

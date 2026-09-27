"""Fix session 2026-09-27: demo prep from the Draws page's staging card, with no resets and no scripts.

Rules (one .sail file each):
  SD_isStageForApprovalEligible(detail)   the one eligibility test for Stage for Approval, over an SD_getDrawDetail map:
                                          an ingested draw (not seeded, not a named specimen), In Progress at step 1 or 2,
                                          with a live chain (a registered step process holding an open task). A draw in
                                          mid-acceleration has no registered step process, so it is refused.
  SD_getStageForApprovalCandidates(rows)  the eligible draws, most recent first, with a picker label
  SD_getCleanupCandidates(rows)           every draw that is neither seeded (SD_SEED_DRAW_IDS) nor a named demo specimen
                                          (SD_DEMO_KEEP_DRAW_IDS), oldest first
  SD_planCleanup(drawIds)                 what Clean Up Old Runs will remove for an explicit id list: the draws that pass
                                          the same exclusion, every child row by type (budget lines, approvals, QIU,
                                          documents, email messages, budget-line events) and the open processes holding
                                          tasks on them (the pipeline, the step process, an email-reply review)
  SD_cleanupRecords(kind, ids)            the record values a Delete Records node takes, for one type

Process payloads:
  stage_approval_payload.json   SD Stage Draw for Approval (drawId): guard → the accelerator with stopAtStep 3 and
                                seed attribution (sync) → read back → outcome
  cleanup_payload.json          SD Clean Up Old Runs (drawIds): plan → cancel the open processes (explicit loop) →
                                delete children first, one Delete Records node per type, each guarded → report
"""
import json
from refs import *

EVH = ("ee493a87-e51b-4148-8893-26de1e924ffb", "SD Draw Budget Line Event History")
EV_ID = "'recordType!{ee493a87-e51b-4148-8893-26de1e924ffb}SD Draw Budget Line Event History.fields.{cbefa248-a552-4bbb-9733-d4dd1d291a99}id'"
EV_REC = "'recordType!{ee493a87-e51b-4148-8893-26de1e924ffb}SD Draw Budget Line Event History.fields.{7e9a52d1-8566-4199-b6b9-167488e2383e}recordId'"
EV_RT = "'recordType!{ee493a87-e51b-4148-8893-26de1e924ffb}SD Draw Budget Line Event History'"

ELIGIBLE = r'''/* Draw approval (fix session 2026-09-27): may this draw be staged for approval? One test, used by the Draws page's
   picker and re-checked by SD Stage Draw for Approval before it writes anything. ri!detail is an SD_getDrawDetail map.
   Eligible: an ingested draw (not a seeded draw, not a named demo specimen), In Progress at step 1 or 2, with a live chain:
   a registered step process that holds an open task. The accelerator clears activeStepProcessId while it runs and only
   the launcher sets it again, so a draw in mid-acceleration has none and is refused; a draw past step 2 is refused. */
a!localVariables(
  local!id: tointeger(a!defaultValue(index(ri!detail, "id", null), 0)),
  local!step: tointeger(a!defaultValue(index(ri!detail, "currentStep", null), 0)),
  and(
    a!defaultValue(index(ri!detail, "found", false), false),
    local!id > 0,
    not(contains(tointeger(cons!SD_SEED_DRAW_IDS), local!id)),
    not(contains(tointeger(cons!SD_DEMO_KEEP_DRAW_IDS), local!id)),
    tostring(a!defaultValue(index(ri!detail, "status", ""), "")) = "In Progress",
    or(local!step = 1, local!step = 2),
    not(a!isNullOrEmpty(index(ri!detail, "activeStepProcessId", null))),
    /* the open task is read from the task report directly: the detail map's openTaskId is viewer-aware (filled only
       for members of the step's group), and this test must not depend on who is looking (measured: inside a process
       the detail's openTaskId read null for a live task) */
    not(a!isNullOrEmpty(rule!SD_getOpenTaskId(processId: index(ri!detail, "activeStepProcessId", null))))
  )
)
'''

CANDIDATES = r'''/* Draw approval (fix session 2026-09-27): the draws Stage for Approval can take, most recent first (the picker's default
   is the first). ri!rows takes the Draws page's rows (rule!SD_getDrawListRows) so the page does not read twice; empty,
   the rule reads them itself. Each item: drawId, drawNumber, currentStep, currentRole, currentApprover, investmentName,
   label ("#81 · step 1 of 9 · Accountant · received Sep 26"). */
a!localVariables(
  local!all: if(a!isNullOrEmpty(ri!rows), rule!SD_getDrawListRows(), ri!rows),
  local!flags: if(
    a!isNullOrEmpty(local!all),
    {},
    a!forEach(items: local!all, expression: rule!SD_isStageForApprovalEligible(detail: fv!item))
  ),
  local!picked: if(
    or(a!isNullOrEmpty(local!flags), not(contains(local!flags, true))),
    {},
    index(local!all, wherecontains(true, local!flags), {})
  ),
  local!mapped: if(
    a!isNullOrEmpty(local!picked),
    {},
    a!forEach(
      items: local!picked,
      expression: a!map(
        drawId: tointeger(fv!item.id),
        drawNumber: fv!item.drawNumber,
        currentStep: tointeger(fv!item.currentStep),
        currentRole: tostring(a!defaultValue(fv!item.currentRole, "")),
        currentApprover: tostring(a!defaultValue(fv!item.currentApprover, "")),
        investmentName: tostring(a!defaultValue(fv!item.investmentName, "")),
        label: "#" & a!defaultValue(fv!item.drawNumber, fv!item.id) & " · step " & fv!item.currentStep & " of 9 · " &
          a!defaultValue(fv!item.currentRole, "") &
          if(a!isNullOrEmpty(fv!item.receivedDate), "", " · received " & text(todate(fv!item.receivedDate), "MMM D"))
      )
    )
  ),
  if(
    a!isNullOrEmpty(local!mapped),
    {},
    todatasubset(local!mapped, a!pagingInfo(startIndex: 1, batchSize: -1, sort: a!sortInfo(field: "drawId", ascending: false))).data
  )
)
'''

CLEANUP_CANDIDATES = r'''/* Draw approval (fix session 2026-09-27): what Clean Up Old Runs would remove — every draw that is neither seeded
   (SD_SEED_DRAW_IDS: the seeded list history and its world) nor a named demo specimen (SD_DEMO_KEEP_DRAW_IDS), oldest
   first. Each item: drawId, drawNumber, status, label ("#81 · In Progress", "Not loaded (Ingestion Failed)", "New draw
   (Ingesting)"). ri!rows takes the Draws page's rows; empty, the rule reads them itself. */
a!localVariables(
  local!all: if(a!isNullOrEmpty(ri!rows), rule!SD_getDrawListRows(), ri!rows),
  local!flags: if(
    a!isNullOrEmpty(local!all),
    {},
    a!forEach(
      items: local!all,
      expression: a!localVariables(
        local!id: tointeger(a!defaultValue(fv!item.id, 0)),
        and(
          local!id > 0,
          not(contains(tointeger(cons!SD_SEED_DRAW_IDS), local!id)),
          not(contains(tointeger(cons!SD_DEMO_KEEP_DRAW_IDS), local!id))
        )
      )
    )
  ),
  local!picked: if(
    or(a!isNullOrEmpty(local!flags), not(contains(local!flags, true))),
    {},
    index(local!all, wherecontains(true, local!flags), {})
  ),
  local!mapped: if(
    a!isNullOrEmpty(local!picked),
    {},
    a!forEach(
      items: local!picked,
      expression: a!localVariables(
        local!status: tostring(a!defaultValue(fv!item.status, "")),
        a!map(
          drawId: tointeger(fv!item.id),
          drawNumber: fv!item.drawNumber,
          status: local!status,
          label: if(
            a!isNullOrEmpty(fv!item.drawNumber),
            if(local!status = "Ingestion Failed", "Not loaded", "New draw") & " (draw " & fv!item.id & ", " & local!status & ")",
            "#" & fv!item.drawNumber & " (" & local!status & ")"
          )
        )
      )
    )
  ),
  if(
    a!isNullOrEmpty(local!mapped),
    {},
    todatasubset(local!mapped, a!pagingInfo(startIndex: 1, batchSize: -1, sort: a!sortInfo(field: "drawId", ascending: true))).data
  )
)
'''

PLAN = r'''/* Draw approval (fix session 2026-09-27): the plan SD Clean Up Old Runs executes for an explicit list of draw ids.
   Re-applies the exclusion (never a seeded draw, never a named specimen) whatever the caller sent, reads every child row
   by type, and lists the open processes holding tasks on those draws — the ingestion pipeline (a reconciliation task),
   the registered step process (an approval task) and any email-reply review (the handler process on an EXCEPTION row) —
   so they are cancelled before the rows go. A process with no open task is left alone. Returns a map: drawIds, refused,
   drawLabels, lineIds, approvalIds, qiuIds, docIds, msgIds, eventIds, processIds. */
a!localVariables(
  local!req: if(a!isNullOrEmpty(ri!drawIds), {}, tointeger(ri!drawIds)),
  local!allowed: if(
    a!isNullOrEmpty(local!req),
    {},
    index(
      local!req,
      wherecontains(
        true,
        a!forEach(
          items: local!req,
          expression: and(
            not(a!isNullOrEmpty(fv!item)),
            not(contains(tointeger(cons!SD_SEED_DRAW_IDS), fv!item)),
            not(contains(tointeger(cons!SD_DEMO_KEEP_DRAW_IDS), fv!item))
          )
        )
      ),
      {}
    )
  ),
  local!draws: if(
    a!isNullOrEmpty(local!allowed),
    {},
    a!queryRecordType(
      recordType: @DRAW@,
      fields: {@D_ID@, @D_NUM@, @D_STATUS@, @D_ING@, @D_ASP@},
      filters: a!queryFilter(field: @D_ID@, operator: "in", value: local!allowed),
      pagingInfo: a!pagingInfo(startIndex: 1, batchSize: 500)
    ).data
  ),
  local!found: if(a!isNullOrEmpty(local!draws), {}, tointeger(a!forEach(items: local!draws, expression: fv!item[@D_ID@]))),
  local!idsOf: a!localVariables(
    {}
  ),
  local!lines: if(
    a!isNullOrEmpty(local!found),
    {},
    a!queryRecordType(
      recordType: @LINE@,
      fields: {@L_ID@},
      filters: a!queryFilter(field: @L_DRAW@, operator: "in", value: local!found),
      pagingInfo: a!pagingInfo(startIndex: 1, batchSize: 5000)
    ).data
  ),
  local!lineIds: if(a!isNullOrEmpty(local!lines), {}, tointeger(a!forEach(items: local!lines, expression: fv!item[@L_ID@]))),
  local!approvals: if(
    a!isNullOrEmpty(local!found),
    {},
    a!queryRecordType(
      recordType: @APPR@,
      fields: {@A_ID@},
      filters: a!queryFilter(field: @A_DRAW@, operator: "in", value: local!found),
      pagingInfo: a!pagingInfo(startIndex: 1, batchSize: 5000)
    ).data
  ),
  local!qius: if(
    a!isNullOrEmpty(local!found),
    {},
    a!queryRecordType(
      recordType: @QIU@,
      fields: {@Q_ID@},
      filters: a!queryFilter(field: @Q_DRAW@, operator: "in", value: local!found),
      pagingInfo: a!pagingInfo(startIndex: 1, batchSize: 5000)
    ).data
  ),
  local!docs: if(
    a!isNullOrEmpty(local!found),
    {},
    a!queryRecordType(
      recordType: @DOC@,
      fields: {@O_ID@},
      filters: a!queryFilter(field: @O_DRAW@, operator: "in", value: local!found),
      pagingInfo: a!pagingInfo(startIndex: 1, batchSize: 5000)
    ).data
  ),
  local!msgs: if(
    a!isNullOrEmpty(local!found),
    {},
    a!queryRecordType(
      recordType: @MSG@,
      fields: {@M_ID@, @M_PROC@},
      filters: a!queryFilter(field: @M_DRAW@, operator: "in", value: local!found),
      pagingInfo: a!pagingInfo(startIndex: 1, batchSize: 5000)
    ).data
  ),
  local!events: if(
    a!isNullOrEmpty(local!lineIds),
    {},
    a!queryRecordType(
      recordType: @EV_RT@,
      fields: {@EV_ID@},
      filters: a!queryFilter(field: @EV_REC@, operator: "in", value: local!lineIds),
      pagingInfo: a!pagingInfo(startIndex: 1, batchSize: 5000)
    ).data
  ),
  /* candidate processes: each draw's pipeline and registered step process, and the handler behind any message row */
  local!procCandidates: reject(
    a!isNullOrEmpty,
    a!flatten({
      if(a!isNullOrEmpty(local!draws), {}, a!forEach(items: local!draws, expression: tointeger(fv!item[@D_ING@]))),
      if(a!isNullOrEmpty(local!draws), {}, a!forEach(items: local!draws, expression: tointeger(fv!item[@D_ASP@]))),
      if(a!isNullOrEmpty(local!msgs), {}, a!forEach(items: local!msgs, expression: tointeger(fv!item[@M_PROC@])))
    })
  ),
  local!procDistinct: if(a!isNullOrEmpty(local!procCandidates), {}, union(tointeger(local!procCandidates), tointeger(local!procCandidates))),
  /* only processes that still hold an open task are cancelled (the task report finds it) */
  local!procOpen: if(
    a!isNullOrEmpty(local!procDistinct),
    {},
    reject(
      a!isNullOrEmpty,
      a!forEach(
        items: local!procDistinct,
        expression: if(a!isNullOrEmpty(rule!SD_getOpenTaskId(processId: fv!item)), null, fv!item)
      )
    )
  ),
  a!map(
    drawIds: local!found,
    refused: if(
      a!isNullOrEmpty(local!req),
      {},
      if(
        a!isNullOrEmpty(local!found),
        local!req,
        reject(a!isNullOrEmpty, a!forEach(items: local!req, expression: if(contains(local!found, fv!item), null, fv!item)))
      )
    ),
    drawLabels: if(
      a!isNullOrEmpty(local!draws),
      {},
      a!forEach(
        items: local!draws,
        expression: if(
          a!isNullOrEmpty(fv!item[@D_NUM@]),
          "draw " & fv!item[@D_ID@] & " (" & fv!item[@D_STATUS@] & ")",
          "#" & fv!item[@D_NUM@] & " (draw " & fv!item[@D_ID@] & ")"
        )
      )
    ),
    lineIds: local!lineIds,
    approvalIds: if(a!isNullOrEmpty(local!approvals), {}, tointeger(a!forEach(items: local!approvals, expression: fv!item[@A_ID@]))),
    qiuIds: if(a!isNullOrEmpty(local!qius), {}, tointeger(a!forEach(items: local!qius, expression: fv!item[@Q_ID@]))),
    docIds: if(a!isNullOrEmpty(local!docs), {}, tointeger(a!forEach(items: local!docs, expression: fv!item[@O_ID@]))),
    msgIds: if(a!isNullOrEmpty(local!msgs), {}, tointeger(a!forEach(items: local!msgs, expression: fv!item[@M_ID@]))),
    eventIds: if(a!isNullOrEmpty(local!events), {}, tointeger(a!forEach(items: local!events, expression: fv!item[@EV_ID@]))),
    processIds: if(a!isNullOrEmpty(local!procOpen), {}, tointeger(local!procOpen))
  )
)
'''

RECORDS = r'''/* Draw approval (fix session 2026-09-27): the record values a Delete Records node takes for one type, identified by
   primary key only. ri!kind: EVENT, MESSAGE, DOCUMENT, QIU, APPROVAL, LINE or DRAW; ri!ids: the explicit id list from
   SD_planCleanup. An unknown kind or an empty list returns an empty list. */
if(
  a!isNullOrEmpty(ri!ids),
  {},
  a!forEach(
    items: tointeger(ri!ids),
    expression: a!match(
      value: upper(a!defaultValue(ri!kind, "")),
      equals: "EVENT", then: @EV_RT@(@EV_ID@: fv!item),
      equals: "MESSAGE", then: @MSG@(@M_ID@: fv!item),
      equals: "DOCUMENT", then: @DOC@(@O_ID@: fv!item),
      equals: "QIU", then: @QIU@(@Q_ID@: fv!item),
      equals: "APPROVAL", then: @APPR@(@A_ID@: fv!item),
      equals: "LINE", then: @LINE@(@L_ID@: fv!item),
      equals: "DRAW", then: @DRAW@(@D_ID@: fv!item),
      default: null
    )
  )
)
'''

SUBS = {
    "@DRAW@": rt(DRAW), "@D_ID@": fld(DRAW, "id"), "@D_NUM@": fld(DRAW, "drawNumber"), "@D_STATUS@": fld(DRAW, "status"),
    "@D_ING@": fld(DRAW, "ingestionProcessId"), "@D_ASP@": fld(DRAW, "activeStepProcessId"),
    "@LINE@": rt(LINE), "@L_ID@": fld(LINE, "id"), "@L_DRAW@": fld(LINE, "drawId"),
    "@APPR@": rt(APPR), "@A_ID@": fld(APPR, "id"), "@A_DRAW@": fld(APPR, "drawId"),
    "@QIU@": rt(QIU), "@Q_ID@": fld(QIU, "id"), "@Q_DRAW@": fld(QIU, "drawId"),
    "@DOC@": rt(DOC), "@O_ID@": fld(DOC, "id"), "@O_DRAW@": fld(DOC, "drawId"),
    "@MSG@": rt(MSG), "@M_ID@": fld(MSG, "id"), "@M_DRAW@": fld(MSG, "drawId"), "@M_PROC@": fld(MSG, "processId"),
    "@EV_RT@": EV_RT, "@EV_ID@": EV_ID, "@EV_REC@": EV_REC,
}
def sub(t):
    for k in sorted(SUBS, key=len, reverse=True):
        t = t.replace(k, SUBS[k])
    assert "@" not in t.replace("@appian", ""), t[:200]
    return t

PLAN = PLAN.replace("""  local!idsOf: a!localVariables(
    {}
  ),
""", "")

RULES = [("SD_isStageForApprovalEligible", ELIGIBLE), ("SD_getStageForApprovalCandidates", CANDIDATES),
         ("SD_getCleanupCandidates", CLEANUP_CANDIDATES), ("SD_planCleanup", sub(PLAN)), ("SD_cleanupRecords", sub(RECORDS))]

# ---------------------------------------------------------------- process payloads
def conn(*ts): return [{"targetNodeId": t, "activityChained": False} for t in ts]
def script(i, name, xy, outs, to):
    return {"id": i, "type": "internal.16", "name": name, "coordinates": xy, "connections": conn(to),
            "data": {"customOutputs": [{"expression": e, "saveInto": s} for e, s in outs]},
            "assignment": {"attended": False, "runAs": "DESIGNER"}}
def xor(i, name, xy, conds, default):
    return {"id": i, "type": "core.4", "name": name, "coordinates": xy,
            "connections": conn(*([c[1] for c in conds] + [default])),
            "decision": {"conditions": [{"expression": e, "targetNodeId": t, "label": l} for e, t, l in conds], "defaultPath": default}}

ACCEL_PM = "0000f06e-a54d-8000-24cf-7f0000014e7a"

stage_pvs = [
    {"name": "drawId", "type": "Number (Integer)", "isParameter": True, "isRequired": True},
    {"name": "before", "type": "Map"}, {"name": "eligible", "type": "Boolean"},
    {"name": "accelOutcome", "type": "Text"}, {"name": "after", "type": "Map"},
    {"name": "outcome", "type": "Text", "isParameter": True},
    {"name": "stopAtStep", "type": "Number (Integer)", "value": "3"},
    {"name": "attribution", "type": "Text", "value": "\"SEED\""},
]
STAGE_OUTCOME = ('a!localVariables(local!a: pv!after, local!n: a!defaultValue(index(local!a, "drawNumber", null), pv!drawId), '
                 'if(and(tostring(a!defaultValue(index(local!a, "status", ""), "")) = "In Progress", tointeger(a!defaultValue(index(local!a, "currentStep", 0), 0)) = 3), '
                 '"STAGED: draw #" & local!n & " approved at steps 1-2 as the chain\'s named approvers and advanced to step 3 (Asset Manager); the step task goes to SD Draw Asset Managers. Accelerator: " & a!defaultValue(pv!accelOutcome, "(no outcome)"), '
                 '"NOT STAGED: draw #" & local!n & " is " & a!defaultValue(index(local!a, "status", "?"), "?") & " at step " & a!defaultValue(index(local!a, "currentStep", "?"), "?") & ". Accelerator: " & a!defaultValue(pv!accelOutcome, "(no outcome)")))')
stage_nodes = [
    {"id": 1, "type": "core.0", "name": "Start", "coordinates": [40, 200], "connections": conn(3)},
    script(3, "Check the draw (rules)", [160, 200], [
        ("rule!SD_getDrawDetail(drawId: pv!drawId)", "pv!before"),
        ("rule!SD_isStageForApprovalEligible(detail: rule!SD_getDrawDetail(drawId: pv!drawId))", "pv!eligible")], 4),
    xor(4, "Eligible?", [290, 200], [("=not(a!defaultValue(pv!eligible, false))", 9, "refused")], 5),
    script(9, "Refused (nothing written)", [290, 360], [
        ('"REFUSED: draw " & pv!drawId & " is " & a!defaultValue(index(pv!before, "status", "?"), "?") & " at step " & '
         'a!defaultValue(index(pv!before, "currentStep", "?"), "?") & if(a!isNullOrEmpty(index(pv!before, "activeStepProcessId", null)), '
         '" with no live step task (in mid-acceleration or not yet assembled)", "") & "; staging takes an ingested draw In Progress at step 1 or 2 with a live task, '
         'not a seeded draw or a named specimen. Nothing was written."', "pv!outcome")], 2),
    {"id": 5, "type": "internal.38", "name": "Advance to the Asset Manager step (accelerator, sync)", "coordinates": [440, 200],
     "connections": conn(6),
     "data": {"inputs": [
         {"name": "drawId", "expression": "pv!drawId"},
         {"name": "stopAtStep", "expression": "pv!stopAtStep"},
         {"name": "attribution", "expression": "pv!attribution"},
         {"name": "pmUUID", "value": ACCEL_PM},
         {"name": "isAsynchronous", "value": 0}, {"name": "isTransparent", "value": 1},
         {"name": "inheritSecurity", "value": 0}, {"name": "chainsInto", "value": 0}],
         "outputs": [{"name": "outcome", "saveInto": "pv!accelOutcome"}]},
     "assignment": {"attended": False, "runAs": "DESIGNER"}},
    script(6, "Read the draw back (rules)", [590, 200], [("rule!SD_getDrawDetail(drawId: pv!drawId)", "pv!after")], 7),
    script(7, "Outcome", [740, 200], [(STAGE_OUTCOME, "pv!outcome")], 2),
    {"id": 2, "type": "core.1", "name": "End", "coordinates": [900, 200]},
]

KINDS = [("EVENT", "eventIds", "budget-line events"), ("MESSAGE", "msgIds", "email messages"), ("DOCUMENT", "docIds", "documents"),
         ("QIU", "qiuIds", "QIU rows"), ("APPROVAL", "approvalIds", "approval rows"), ("LINE", "lineIds", "budget lines"),
         ("DRAW", "drawIds", "draws")]
cleanup_pvs = [
    {"name": "drawIds", "type": "Number (Integer)", "isParameter": True, "multiple": True},
    {"name": "plan", "type": "Map"}, {"name": "idx", "type": "Number (Integer)", "value": "1"},
    {"name": "current", "type": "Number (Integer)"}, {"name": "alreadyClosed", "type": "Boolean"},
    {"name": "cancelled", "type": "Number (Integer)", "value": "0"}, {"name": "wasClosed", "type": "Number (Integer)", "value": "0"},
    {"name": "report", "type": "Text", "isParameter": True},
]
for k, _, _ in KINDS:
    cleanup_pvs += [{"name": "n" + k.title(), "type": "Number (Integer)", "value": "0"},
                    {"name": "err" + k.title(), "type": "Text"}]

def count_of(key): return 'count(a!defaultValue(index(pv!plan, "%s", {}), {}))' % key

cleanup_nodes = [
    {"id": 1, "type": "core.0", "name": "Start", "coordinates": [40, 240], "connections": conn(3)},
    script(3, "Plan (rules)", [150, 240], [("rule!SD_planCleanup(drawIds: pv!drawIds)", "pv!plan")], 4),
    xor(4, "Anything to remove?", [260, 240], [
        ("=" + count_of("drawIds") + " = 0", 90, "nothing"),
        ("=" + count_of("processIds") + " > 0", 5, "open processes")], 10),
    script(90, "Nothing to remove", [260, 420], [
        ('"NOTHING REMOVED: none of the " & count(a!defaultValue(pv!drawIds, {})) & " requested draws can be cleaned up (seeded draws and named specimens are never removed)."', "pv!report")], 2),
    # cancel loop (hand-built: loop back to the take-item script; every gateway has one incoming flow)
    script(5, "Take the next process", [370, 100], [("index(index(pv!plan, \"processIds\", {}), pv!idx, null)", "pv!current")], 6),
    {"id": 6, "type": "appian.system.smart-services.cancel-process-2", "name": "Cancel its open task's process", "coordinates": [480, 100],
     "connections": conn(7),
     "data": {"inputs": [{"name": "ProcessId", "expression": "=pv!current"}],
              "outputs": [{"name": "alreadyClosed", "saveInto": "pv!alreadyClosed"}]},
     "assignment": {"attended": False, "runAs": "DESIGNER"}},
    script(7, "Count", [590, 100], [
        ("a!defaultValue(pv!idx, 1) + 1", "pv!idx"),
        ("a!defaultValue(pv!cancelled, 0) + if(a!defaultValue(pv!alreadyClosed, false), 0, 1)", "pv!cancelled"),
        ("a!defaultValue(pv!wasClosed, 0) + if(a!defaultValue(pv!alreadyClosed, false), 1, 0)", "pv!wasClosed")], 8),
    xor(8, "Another process?", [700, 100], [
        ("=and(a!defaultValue(pv!idx, 1) <= " + count_of("processIds") + ", a!defaultValue(pv!idx, 1) <= 100)", 5, "next")], 10),
]
x = 370
nid = 10
for k, key, _ in KINDS:
    guard, node = nid, nid + 1
    nxt = nid + 2 if k != "DRAW" else 80
    if k == "DRAW":
        # the draws go only when every child delete succeeded, so a failed child delete never leaves orphans
        cond = "=and(" + count_of(key) + " > 0, " + ", ".join("a!isNullOrEmpty(pv!err%s)" % c.title() for c, _, _ in KINDS if c != "DRAW") + ")"
        cleanup_nodes.append(xor(guard, "Draws, if every child delete succeeded?", [x, 240], [(cond, node, "delete")], nxt))
    else:
        cleanup_nodes.append(xor(guard, "Any " + k.lower() + " rows?", [x, 240], [("=" + count_of(key) + " > 0", node, "delete")], nxt))
    cleanup_nodes.append({
        "id": node, "type": "internal3.delete_records_from_source_23r4", "name": "Delete " + k.lower() + " rows", "coordinates": [x, 380],
        "connections": conn(nxt),
        "data": {"inputs": [
            {"name": "Records", "expression": '=rule!SD_cleanupRecords(kind: "%s", ids: index(pv!plan, "%s", {}))' % (k, key)},
            {"name": "PauseOnError", "value": 0}],
            "outputs": [{"name": "CountOfRecordsDeleted", "saveInto": "pv!n" + k.title()},
                        {"name": "Error", "saveInto": "pv!err" + k.title()}]},
        "assignment": {"attended": False, "runAs": "DESIGNER"}})
    nid += 2
    x += 110
REPORT = ('a!localVariables(local!p: pv!plan, local!errs: reject(a!isNullOrEmpty, {' +
          ", ".join('if(a!isNullOrEmpty(pv!err%s), null, "%s: " & pv!err%s)' % (k.title(), lbl, k.title()) for k, _, lbl in KINDS) + '}), '
          '"REMOVED " & a!defaultValue(pv!nDraw, 0) & " of " & ' + count_of("drawIds").replace("pv!plan", "local!p") + ' & " draws" & '
          'if(a!isNullOrEmpty(index(local!p, "drawLabels", {})), "", " (" & joinarray(index(local!p, "drawLabels", {}), ", ") & ")") & '
          '": " & ' + " & \", \" & ".join('a!defaultValue(pv!n%s, 0) & " %s"' % (k.title(), lbl) for k, _, lbl in KINDS if k != "DRAW") + ' & '
          '". Cancelled " & a!defaultValue(pv!cancelled, 0) & " open process" & if(a!defaultValue(pv!cancelled, 0) = 1, "", "es") & '
          'if(a!defaultValue(pv!wasClosed, 0) > 0, "; " & pv!wasClosed & " had already closed", "") & ". " & '
          'if(a!isNullOrEmpty(index(local!p, "refused", {})), "", "Not removed (seeded or a named specimen): draws " & joinarray(index(local!p, "refused", {}), ", ") & ". ") & '
          'if(a!isNullOrEmpty(local!errs), "No errors.", "Errors: " & joinarray(local!errs, "; ")))')
cleanup_nodes.append(script(80, "Report", [x, 240], [(REPORT, "pv!report")], 2))
cleanup_nodes.append({"id": 2, "type": "core.1", "name": "End", "coordinates": [x + 120, 240]})

if __name__ == "__main__":
    for name, text in RULES:
        open(name + ".sail", "w").write(text)
        print("wrote", name, len(text))
    json.dump({"processVariables": stage_pvs, "nodes": stage_nodes}, open("stage_approval_payload.json", "w"), indent=1)
    json.dump({"processVariables": cleanup_pvs, "nodes": cleanup_nodes}, open("cleanup_payload.json", "w"), indent=1)
    print("stage:", len(stage_nodes), "nodes; cleanup:", len(cleanup_nodes), "nodes,", len(cleanup_pvs), "PVs")

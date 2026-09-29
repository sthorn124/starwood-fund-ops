"""Second fix session 2026-09-28: SD Send Reminder Now (the staging card's manual reminder).
Writes reminder_now_payload.json: the process variables and nodes sent with updateProcessModel to
0000f077-f3d0-8000-26a3-7f0000014e7a. It runs the existing chase mechanism (SD Chase Approval Step) twice, synchronously,
for the draw's current waiting step: rung REMINDER, then rung SMS. No waiting-days threshold. Every node as DESIGNER.
Subprocess inputs are PV-name mappings, so the two rung literals are PVs with defaults (supplemental §9)."""
import json

CHASE_PM = "0000f075-2b51-8000-2614-7f0000014e7a"

def conn(t): return dict(targetNodeId=t, activityChained=False)
def designer(): return dict(attended=False, runAs="DESIGNER")
def script(id_, name, xy, outs, to):
    return dict(id=id_, type="internal.16", name=name, coordinates=xy, connections=[conn(to)],
                data=dict(customOutputs=[dict(expression=e, saveInto=s) for e, s in outs]), assignment=designer())
def chase(id_, name, xy, rung_pv, to):
    return dict(id=id_, type="internal.38", name=name, coordinates=xy, connections=[conn(to)],
                data=dict(inputs=[dict(name="drawId", expression="pv!drawId"),
                                  dict(name="stepOrder", expression="pv!stepOrder"),
                                  dict(name="rung", expression=rung_pv),
                                  dict(name="pmUUID", value=CHASE_PM),
                                  dict(name="isAsynchronous", value=0),
                                  dict(name="isTransparent", value=1),
                                  dict(name="inheritSecurity", value=0),
                                  dict(name="chainsInto", value=0)]),
                assignment=designer())

pvs = [
    dict(name="drawId", type="Number (Integer)", isParameter=True, isRequired=True),
    dict(name="outcome", type="Text", isParameter=True),
    dict(name="state", type="Map"),
    dict(name="stepOrder", type="Number (Integer)"),
    dict(name="canSend", type="Boolean"),
    dict(name="drawLabel", type="Text"),
    dict(name="stepLabel", type="Text"),
    dict(name="rungReminder", type="Text", value='"REMINDER"'),
    dict(name="rungSms", type="Text", value='"SMS"'),
]

S = 'pv!state'
nodes = [
    dict(id=1, type="core.0", name="Start", coordinates=[50, 200], connections=[conn(3)]),
    script(3, "Read the draw (rules)", [180, 200], [("rule!SD_getDrawState(pv!drawId)", "pv!state")], 4),
    # reads pv!state, set by node 3 (a script task's outputs see the PVs as they stood when the node started)
    script(4, "The waiting step (rules)", [320, 200], [
        ('tointeger(a!defaultValue(index(%s, "currentStep", null), null))' % S, "pv!stepOrder"),
        ('and(a!defaultValue(index(%s, "found", false), false), tostring(a!defaultValue(index(%s, "drawStatus", ""), "")) = "In Progress", '
         'tostring(a!defaultValue(index(index(%s, "current", null), "status", ""), "")) = "In Progress", '
         'not(a!isNullOrEmpty(index(%s, "currentStep", null))))' % (S, S, S, S), "pv!canSend"),
        ('"#" & a!defaultValue(index(%s, "drawNumber", null), "draw " & pv!drawId)' % S, "pv!drawLabel"),
        ('"step " & a!defaultValue(index(%s, "currentStep", "?"), "?") & " · " & a!defaultValue(index(index(%s, "current", null), "role", ""), "")' % (S, S), "pv!stepLabel"),
    ], 5),
    dict(id=5, type="core.4", name="A step is waiting?", coordinates=[460, 200], connections=[conn(6), conn(9)],
         decision=dict(conditions=[dict(expression="=not(a!defaultValue(pv!canSend, false))", targetNodeId=9)], defaultPath=6)),
    chase(6, "Reminder (chase, sync)", [600, 200], "pv!rungReminder", 7),
    chase(7, "Text (chase, sync)", [740, 200], "pv!rungSms", 8),
    # the chase process's outcome is not a parameter (a subprocess cannot map it), so the outcome is read from what the two
    # runs logged on the draw at this step since this process started
    script(8, "Outcome (from the logged rows)", [880, 200], [(
        'a!localVariables(local!msgs: rule!SD_getDrawEmailMessages(drawId: pv!drawId), '
        'local!mine: if(a!isNullOrEmpty(local!msgs), {}, index(local!msgs, wherecontains(true, a!forEach(items: local!msgs, expression: and(or(fv!item.kind = "REMINDER", fv!item.kind = "SMS"), tointeger(a!defaultValue(fv!item.stepOrder, 0)) = pv!stepOrder, fv!item.messageAt >= pp!starttime))), {})), '
        'local!kinds: if(a!isNullOrEmpty(local!mine), {}, a!forEach(items: local!mine, expression: fv!item.kind)), '
        'local!rem: if(a!isNullOrEmpty(local!kinds), null, index(local!mine, index(wherecontains("REMINDER", local!kinds), 1, 0), null)), '
        'local!sms: if(a!isNullOrEmpty(local!kinds), null, index(local!mine, index(wherecontains("SMS", local!kinds), 1, 0), null)), '
        '"SENT: draw " & pv!drawLabel & " (" & pv!stepLabel & "): reminder " & if(a!isNullOrEmpty(local!rem), "not logged", lower(index(local!rem, "outcome", "?")) & " to " & index(local!rem, "toAddress", "?")) & '
        '" · text " & if(a!isNullOrEmpty(local!sms), "not logged", lower(index(local!sms, "outcome", "?")) & " to " & index(local!sms, "toAddress", "?")))',
        "pv!outcome")], 2),
    script(9, "Refused", [460, 360], [(
        '"REFUSED: draw " & a!defaultValue(pv!drawLabel, pv!drawId) & " has no step waiting for a decision (status " & a!defaultValue(index(pv!state, "drawStatus", "?"), "?") & "). Nothing was sent."',
        "pv!outcome")], 2),
    dict(id=2, type="core.1", name="End", coordinates=[1020, 200], connections=[]),
]

json.dump(dict(processVariables=pvs, nodes=nodes), open("reminder_now_payload.json", "w"), indent=1)
print("wrote reminder_now_payload.json", len(nodes), "nodes", len(pvs), "pvs")

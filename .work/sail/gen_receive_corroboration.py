"""Phase 5.5: SD Receive Capital Call additions — PV supportingDocuments (Document, multiple, parameter) and corroboration
(Map) on top of Phase 5's 46 (receive_failure_payloads.json); nodes 42 (XOR supporting documents?), 43 (async subprocess
SD Read Supporting Documents), 44 (corroboration after confirm), 45 (write it onto the draw); node 8 → 42, node 22 → 44.
Writes receive_corroboration_payloads.json. Placeholders from refs; no f-strings."""
import json
from refs import *
d = lambda n: fld(DRAW, n)
base = json.load(open("receive_failure_payloads.json"))["processVariables"]
pvs = base + [{"name": "supportingDocuments", "type": "Document", "isParameter": True, "multiple": True},
              {"name": "corroboration", "type": "Map", "isParameter": False, "multiple": False}]
READ_PM = "0000f073-a7ee-8000-25b1-7f0000014e7a"
nodes = {
  42: {"id": 42, "type": "core.4", "name": "Supporting documents?", "coordinates": [900, 360],
       "connections": [{"targetNodeId": 43, "activityChained": False}, {"targetNodeId": 9, "activityChained": False}],
       "decision": {"conditions": [{"expression": "=not(a!isNullOrEmpty(pv!supportingDocuments))", "targetNodeId": 43, "label": "yes"}],
                    "defaultPath": 9}},
  43: {"id": 43, "type": "internal.38", "name": "Read supporting documents (async)", "coordinates": [1050, 360],
       "connections": [{"targetNodeId": 9, "activityChained": False}],
       "data": {"inputs": [{"name": "Instructions", "value": ""}, {"name": "drawId", "expression": "drawId"},
                           {"name": "documents", "expression": "supportingDocuments"},
                           {"name": "pmUUID", "value": READ_PM}, {"name": "isAsynchronous", "value": 1},
                           {"name": "isTransparent", "value": 1}, {"name": "inheritSecurity", "value": 0},
                           {"name": "chainsInto", "value": 0}]},
       "assignment": {"attended": False, "runAs": "DESIGNER"}},
  44: {"id": 44, "type": "internal.16", "name": "Corroboration (rules)", "coordinates": [2680, 360],
       "connections": [{"targetNodeId": 45, "activityChained": False}],
       "data": {"customOutputs": [{"expression": "rule!SD_getDrawCorroboration(drawId: pv!drawId)", "saveInto": "pv!corroboration"}]},
       "assignment": {"attended": False, "runAs": "DESIGNER"}},
  45: {"id": 45, "type": "internal3.write_records_to_source_23r3", "name": "Draw corroboration", "coordinates": [2830, 360],
       "connections": [{"targetNodeId": 23, "activityChained": False}],
       "data": {"inputs": [{"name": "Records", "expression": "={ @DRAW@(@D_ID@: pv!drawId, @D_SUM@: left(a!defaultValue(index(pv!corroboration, \"summary\", null), \"No supporting documents received\"), 250), @D_STATE@: a!defaultValue(index(pv!corroboration, \"state\", null), \"NONE\"), @D_UPD@: now()) }"},
                           {"name": "PauseOnError", "value": 0}, {"name": "CaptureEvents", "value": 0}],
                "outputs": []},
       "assignment": {"attended": False, "runAs": "DESIGNER"}},
}
subs = {"@DRAW@": rt(DRAW), "@D_ID@": d("id"), "@D_SUM@": d("corroborationSummary"), "@D_STATE@": d("corroborationState"),
        "@D_UPD@": d("updatedAt")}
out = json.dumps({"processVariables": pvs, "nodes": [nodes[k] for k in sorted(nodes)]})
for k, v in subs.items():
    out = out.replace(k, v.replace('"', '\\"'))
assert "@D_" not in out and "@DRAW@" not in out
json.loads(out)
open("receive_corroboration_payloads.json", "w").write(out)
print(len(pvs), "PVs;", len(nodes), "nodes")

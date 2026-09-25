"""Phase 5.5: payload for SD Read Supporting Documents (0000f073-a7ee-8000-25b1-7f0000014e7a) — PVs and nodes, the
measured loop (supplemental §9): seed → XOR any? → take-item script → register write → XOR registered? → read id → AI →
check → write → next script → XOR another? → back to the take-item script. Every gateway has exactly one incoming flow.
Writes read_supporting_payload.json. Placeholders from refs; no f-strings."""
import json
from refs import *
c = lambda n: fld(DOC, n)
DOCT = "{urn:com:appian:recordtype:datatype}f3e0033f-2047-4c68-8f6f-cf32166091e9"
pvs = [
  {"name": "drawId", "type": "Number (Integer)", "isParameter": True},
  {"name": "documents", "type": "Document", "isParameter": True, "multiple": True},
  {"name": "count", "type": "Number (Integer)"}, {"name": "idx", "type": "Number (Integer)"},
  {"name": "doc", "type": "Document"}, {"name": "docRows", "type": DOCT, "multiple": True},
  {"name": "docRowId", "type": "Number (Integer)"},
  {"name": "aiSuccess", "type": "Boolean"}, {"name": "aiResponse", "type": "Text"}, {"name": "aiError", "type": "Text"},
  {"name": "aiActions", "type": "Number (Decimal)"}, {"name": "aiModel", "type": "Text"},
  {"name": "startedAt", "type": "Date and Time"}, {"name": "endedAt", "type": "Date and Time"},
  {"name": "reading", "type": "Map"}, {"name": "writeError", "type": "Boolean"}, {"name": "writeErrorText", "type": "Text"},
  {"name": "totalActions", "type": "Number (Decimal)"}, {"name": "trace", "type": "Text"},
]
def conn(*ts): return [{"targetNodeId": t, "activityChained": False} for t in ts]
def script(i, name, xy, outs, to):
    return {"id": i, "type": "internal.16", "name": name, "coordinates": xy, "connections": conn(to),
            "data": {"customOutputs": [{"expression": e, "saveInto": s} for e, s in outs]},
            "assignment": {"attended": False, "runAs": "DESIGNER"}}
def xor(i, name, xy, cond, yes, no, label):
    return {"id": i, "type": "core.4", "name": name, "coordinates": xy, "connections": conn(yes, no),
            "decision": {"conditions": [{"expression": cond, "targetNodeId": yes, "label": label}], "defaultPath": no}}
def write(i, name, xy, records, to, outs):
    return {"id": i, "type": "internal3.write_records_to_source_23r3", "name": name, "coordinates": xy, "connections": conn(to),
            "data": {"inputs": [{"name": "Records", "expression": records}, {"name": "PauseOnError", "value": 0},
                                {"name": "CaptureEvents", "value": 0}], "outputs": outs},
            "assignment": {"attended": False, "runAs": "DESIGNER"}}
MODELNAME = 'a!localVariables(local!m: a!genAiModels(), index(index(local!m, "name", {}), index(wherecontains(tostring(cons!SD_DOCUMENT_READING_MODEL), touniformstring(index(local!m, "id", {}))), 1, 0), "AI"))'
nodes = [
  {"id": 1, "type": "core.0", "name": "Start", "coordinates": [60, 200], "connections": conn(3)},
  script(3, "Seed", [180, 200],
    [("if(a!isNullOrEmpty(pv!documents), 0, count(pv!documents))", "pv!count"), ("1", "pv!idx"),
     ("0", "pv!totalActions"), ('"seed=" & if(a!isNullOrEmpty(pv!documents), 0, count(pv!documents)) & ";"', "pv!trace")], 4),
  xor(4, "Any documents?", [300, 200], "=a!defaultValue(pv!count, 0) >= 1", 5, 2, "yes"),
  script(5, "Take document", [420, 200],
    [("index(pv!documents, pv!idx, null)", "pv!doc"), ("null", "pv!aiSuccess"), ("null", "pv!aiResponse"),
     ("null", "pv!aiError"), ("null", "pv!aiActions"), ("null", "pv!docRowId"), ("false", "pv!writeError"),
     ("now()", "pv!startedAt"), ('pv!trace & "take" & pv!idx & ";"', "pv!trace")], 6),
  write(6, "Register supporting document (Received)", [560, 200],
    "={ @DOC@(@C_DRAW@: pv!drawId, @C_DOCUMENT@: pv!doc, @C_NAME@: document(pv!doc, \"name\") & \".\" & document(pv!doc, \"extension\"), @C_TYPE@: \"Backup\", @C_STATUS@: \"Received\", @C_RECEIVED@: today(), @C_UPLOADED@: now(), @C_UPLOADEDBY@: \"EY data feed\", @C_NOTES@: \"Being read by AI\") }",
    7, [{"name": "RecordsUpdated", "saveInto": "pv!docRows"}, {"name": "ErrorOccurred", "saveInto": "pv!writeError"},
        {"name": "Error", "saveInto": "pv!writeErrorText"}]),
  xor(7, "Registered?", [700, 200], "=a!defaultValue(pv!writeError, false)", 12, 8, "no"),
  script(8, "Read row id", [820, 200],
    [("index(pv!docRows, 1, null)[@C_ID@]", "pv!docRowId")], 9),
  {"id": 9, "type": "internal3.rs2_ai_skill_generative_ai5", "name": "AI: classify and read the document",
   "coordinates": [960, 200], "connections": conn(10),
   "data": {"inputs": [{"name": "AiSkill", "value": 267}, {"name": "RemoteServiceKey", "value": "ai_skill_generative_ai"}],
            "customInputs": [{"name": "Input Document", "type": "DOCUMENT", "expression": "=pv!doc"},
                             {"name": "Runtime Prompt", "type": "TEXT", "expression": "=rule!SD_supportingDocumentPrompt()"},
                             {"name": "Runtime Model", "type": "TEXT", "expression": "=cons!SD_DOCUMENT_READING_MODEL"},
                             {"name": "Enable Extended Thinking", "type": "BOOLEAN", "value": 0}],
            "outputs": [{"name": "Success", "saveInto": "pv!aiSuccess"}, {"name": "Response", "saveInto": "pv!aiResponse"},
                        {"name": "ErrorMessage", "saveInto": "pv!aiError"}, {"name": "AiActions", "saveInto": "pv!aiActions"},
                        {"name": "Model", "saveInto": "pv!aiModel"}]},
   "assignment": {"attended": False, "runAs": "DESIGNER"}},
  script(10, "Check reading (rules)", [1100, 200],
    [("rule!SD_parseSupportingDocReading(response: pv!aiResponse, success: pv!aiSuccess, errorMessage: pv!aiError, modelName: " + MODELNAME + ")", "pv!reading"),
     ("now()", "pv!endedAt"), ("a!defaultValue(pv!totalActions, 0) + a!defaultValue(pv!aiActions, 0)", "pv!totalActions")], 11),
  write(11, "Supporting document read", [1240, 200],
    "={ @DOC@(@C_ID@: pv!docRowId, @C_TYPE@: index(pv!reading, \"documentType\", \"Backup\"), @C_STATUS@: index(pv!reading, \"status\", \"Not read\"), @C_AMOUNT@: index(pv!reading, \"amount\", null), @C_PARTY@: if(a!defaultValue(index(pv!reading, \"party\", \"\"), \"\") = \"\", null, index(pv!reading, \"party\", null)), @C_REF@: if(a!defaultValue(index(pv!reading, \"reference\", \"\"), \"\") = \"\", null, index(pv!reading, \"reference\", null)), @C_NOTES@: left(a!defaultValue(index(pv!reading, \"notes\", null), \"Read\") & \" (AI \" & tostring(pv!endedAt - pv!startedAt) & \", \" & a!defaultValue(pv!aiActions, 0) & \" AI actions)\", 1000)) }",
    12, [{"name": "ErrorOccurred", "saveInto": "pv!writeError"}, {"name": "Error", "saveInto": "pv!writeErrorText"}]),
  script(12, "Next document", [1380, 200],
    [("pv!idx + 1", "pv!idx"), ('pv!trace & "done" & pv!idx & ";"', "pv!trace")], 13),
  xor(13, "Another document?", [1500, 200], "=and(pv!idx <= a!defaultValue(pv!count, 0), pv!idx <= 20)", 5, 2, "yes"),
  {"id": 2, "type": "core.1", "name": "End", "coordinates": [1640, 200]},
]
subs = {"@DOC@": rt(DOC), "@C_ID@": c("id"), "@C_DRAW@": c("drawId"), "@C_DOCUMENT@": c("document"),
        "@C_NAME@": c("documentName"), "@C_TYPE@": c("documentType"), "@C_STATUS@": c("status"),
        "@C_RECEIVED@": c("receivedDate"), "@C_UPLOADED@": c("uploadedAt"), "@C_UPLOADEDBY@": c("uploadedBy"),
        "@C_NOTES@": c("notes"), "@C_AMOUNT@": c("extractedAmount"), "@C_PARTY@": c("extractedParty"),
        "@C_REF@": c("extractedReference")}
out = json.dumps({"processVariables": pvs, "nodes": nodes})
for k, v in subs.items():
    out = out.replace(k, v.replace('"', '\\"'))
assert "@C_" not in out and "@DOC@" not in out
json.loads(out)
open("read_supporting_payload.json", "w").write(out)
print(len(pvs), "PVs;", len(nodes), "nodes;", len(out), "bytes")

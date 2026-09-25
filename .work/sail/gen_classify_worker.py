"""Phase 5.6: payloads for the supporting-document path.

1. SD Classify Supporting Document (new): the per-document worker, started asynchronously by the dispatcher, one
   instance per document so documents are classified in parallel.
     start -> prepare -> Doc Center: classify (sync subprocess, AIA Classification Run Model Version)
           -> classification verdict (rules) -> XOR pay application?
              yes -> Doc Center: extract pay application (sync subprocess, AIA Extraction Run Model Version)
                  -> pay application figures (rules) -> write "Classified and read" -> end
              no  -> write "Classified only" / "Not classified" -> end
   Every node runs as the designer, so no persona identity reaches the AIA tables.
2. SD Read Supporting Documents (existing, 0000f073-...): becomes the dispatcher. Nodes 9-11 (the 5.5 AI call, its
   check and its write) are removed; node 8 -> new node 14 (async subprocess to the worker) -> node 12.

Writes classify_worker_payload.json (worker PVs + nodes) and read_supporting_dispatch.json (dispatcher PVs, node 5,
node 6 and node 14). No f-strings."""
import json
from refs import *

c = lambda n: fld(DOC, n)
CLASSIFY_PM = "5c825cfa-d291-4cf3-8c6b-4de803ee6781"   # AIA Classification Run Model Version (DocCenter)
EXTRACT_PM = "dad961d1-ef89-4f6b-9fcc-384ab2e78755"    # AIA Extraction Run Model Version (DocCenter)
WORKER_PM = "0000f073-d1d7-8000-25be-7f0000014e7a"                               # filled in after createProcessModel


def conn(*ts):
    return [{"targetNodeId": t, "activityChained": False} for t in ts]


def script(i, name, xy, outs, to):
    return {"id": i, "type": "internal.16", "name": name, "coordinates": xy, "connections": conn(to),
            "data": {"customOutputs": [{"expression": e, "saveInto": s} for e, s in outs]},
            "assignment": {"attended": False, "runAs": "DESIGNER"}}


def xor(i, name, xy, cond, yes, no, label):
    return {"id": i, "type": "core.4", "name": name, "coordinates": xy, "connections": conn(yes, no),
            "decision": {"conditions": [{"expression": cond, "targetNodeId": yes, "label": label}], "defaultPath": no}}


def write(i, name, xy, records, to):
    return {"id": i, "type": "internal3.write_records_to_source_23r3", "name": name, "coordinates": xy,
            "connections": conn(to),
            "data": {"inputs": [{"name": "Records", "expression": records}, {"name": "PauseOnError", "value": 0},
                                {"name": "CaptureEvents", "value": 0}],
                     "outputs": [{"name": "ErrorOccurred", "saveInto": "pv!writeError"},
                                 {"name": "Error", "saveInto": "pv!writeErrorText"}]},
            "assignment": {"attended": False, "runAs": "DESIGNER"}}


def subprocess(i, name, xy, pm, mapping, asynchronous, to):
    inputs = [{"name": "Instructions", "value": ""}]
    inputs += [{"name": k, "expression": v} for k, v in mapping]
    inputs += [{"name": "pmUUID", "value": pm}, {"name": "isAsynchronous", "value": 1 if asynchronous else 0},
               {"name": "isTransparent", "value": 1}, {"name": "inheritSecurity", "value": 0},
               {"name": "chainsInto", "value": 0}]
    return {"id": i, "type": "internal.38", "name": name, "coordinates": xy, "connections": conn(to),
            "data": {"inputs": inputs}, "assignment": {"attended": False, "runAs": "DESIGNER"}}


# ------------------------------------------------------------------ worker ------------------------------------------
worker_pvs = [
    {"name": "drawId", "type": "Number (Integer)", "isParameter": True},
    {"name": "doc", "type": "Document", "isParameter": True},
    {"name": "docRowId", "type": "Number (Integer)", "isParameter": True},
    {"name": "classificationModelKey", "type": "Text", "value": "cons!SD_SUPPORTING_DOC_CLASSIFICATION_MODEL_KEY"},
    {"name": "extractionModelKey", "type": "Text", "value": "cons!SD_PAY_APPLICATION_EXTRACTION_MODEL_KEY"},
    {"name": "startedAt", "type": "Date and Time"}, {"name": "classifiedAt", "type": "Date and Time"},
    {"name": "extractedAt", "type": "Date and Time"},
    {"name": "classification", "type": "Map"}, {"name": "verdict", "type": "Map"},
    {"name": "extraction", "type": "Map"}, {"name": "payApp", "type": "Map"},
    {"name": "writeError", "type": "Boolean"}, {"name": "writeErrorText", "type": "Text"},
]
CLASSIFY_SECONDS = "todecimal(pv!classifiedAt - pv!startedAt) * 86400"
EXTRACT_SECONDS = "todecimal(pv!extractedAt - pv!classifiedAt) * 86400"
NOTES_READ = ("rule!SD_supportingDocNotes(verdict: pv!verdict, classification: pv!classification, classifySeconds: "
              + CLASSIFY_SECONDS + ", payApp: pv!payApp, extraction: pv!extraction, extractSeconds: " + EXTRACT_SECONDS
              + ", classificationModelKey: pv!classificationModelKey, extractionModelKey: pv!extractionModelKey)")
NOTES_ONLY = ("rule!SD_supportingDocNotes(verdict: pv!verdict, classification: pv!classification, classifySeconds: "
              + CLASSIFY_SECONDS + ", payApp: null, extraction: null, extractSeconds: null, classificationModelKey: "
              "pv!classificationModelKey, extractionModelKey: pv!extractionModelKey)")
worker_nodes = [
    {"id": 1, "type": "core.0", "name": "Start", "coordinates": [60, 200], "connections": conn(3)},
    script(3, "Prepare", [180, 200], [("now()", "pv!startedAt")], 4),
    subprocess(4, "Doc Center: classify", [320, 200], CLASSIFY_PM,
               [("document", "pv!doc"), ("modelKey", "pv!classificationModelKey")], False, 5),
    script(5, "Classification verdict (rules)", [460, 200], [
        ("now()", "pv!classifiedAt"),
        ("rule!SD_getSupportingDocClassification(document: pv!doc)", "pv!classification"),
        ("rule!SD_gateSupportingDocClassification(classification: rule!SD_getSupportingDocClassification(document: pv!doc), "
         "minConfidence: cons!SD_CLASSIFICATION_MIN_CONFIDENCE)", "pv!verdict")], 6),
    xor(6, "Pay application?", [600, 200], '=index(pv!verdict, "typeKey", "") = "PAY_APPLICATION"', 7, 10, "yes"),
    subprocess(7, "Doc Center: extract pay application", [740, 120], EXTRACT_PM,
               [("document", "pv!doc"), ("modelKey", "pv!extractionModelKey")], False, 8),
    script(8, "Pay application figures (rules)", [880, 120], [
        ("now()", "pv!extractedAt"),
        ("rule!SD_getPayApplicationExtraction(document: pv!doc)", "pv!extraction"),
        ("rule!SD_gatePayApplicationExtraction(extraction: rule!SD_getPayApplicationExtraction(document: pv!doc))",
         "pv!payApp")], 9),
    write(9, "Classified and read", [1020, 120],
          "={ @DOC@(@C_ID@: pv!docRowId, @C_TYPE@: \"Pay Application\", @C_STATUS@: \"Classified and read\", "
          "@C_AMOUNT@: index(pv!payApp, \"amount\", null), "
          "@C_PARTY@: if(a!defaultValue(index(pv!payApp, \"party\", \"\"), \"\") = \"\", null, index(pv!payApp, \"party\", null)), "
          "@C_REF@: if(a!defaultValue(index(pv!payApp, \"reference\", \"\"), \"\") = \"\", null, index(pv!payApp, \"reference\", null)), "
          "@C_NOTES@: " + NOTES_READ + ") }", 2),
    write(10, "Classified only (or not classified)", [740, 280],
          "={ @DOC@(@C_ID@: pv!docRowId, @C_TYPE@: index(pv!verdict, \"documentType\", \"Backup\"), "
          "@C_STATUS@: if(a!defaultValue(index(pv!verdict, \"ok\", false), false), \"Classified only\", \"Not classified\"), "
          "@C_AMOUNT@: null, @C_PARTY@: null, @C_REF@: null, @C_NOTES@: " + NOTES_ONLY + ") }", 2),
    {"id": 2, "type": "core.1", "name": "End", "coordinates": [1160, 200]},
]

# ------------------------------------------------------------------ dispatcher --------------------------------------
dispatch_pvs = [
    {"name": "drawId", "type": "Number (Integer)", "isParameter": True},
    {"name": "documents", "type": "Document", "isParameter": True, "multiple": True},
    {"name": "count", "type": "Number (Integer)"}, {"name": "idx", "type": "Number (Integer)"},
    {"name": "doc", "type": "Document"},
    {"name": "docRows", "type": "{urn:com:appian:recordtype:datatype}f3e0033f-2047-4c68-8f6f-cf32166091e9",
     "multiple": True},
    {"name": "docRowId", "type": "Number (Integer)"},
    {"name": "writeError", "type": "Boolean"}, {"name": "writeErrorText", "type": "Text"},
    {"name": "trace", "type": "Text"},
]
node5_outputs = [("index(pv!documents, pv!idx, null)", "pv!doc"), ("null", "pv!docRowId"), ("false", "pv!writeError"),
                 ('pv!trace & "take" & pv!idx & ";"', "pv!trace")]
node6_records = ("={ @DOC@(@C_DRAW@: pv!drawId, @C_DOCUMENT@: pv!doc, @C_NAME@: document(pv!doc, \"name\") & \".\" & "
                 "document(pv!doc, \"extension\"), @C_TYPE@: \"Backup\", @C_STATUS@: \"Received\", @C_RECEIVED@: today(), "
                 "@C_UPLOADED@: now(), @C_UPLOADEDBY@: \"EY data feed\", @C_NOTES@: \"Being classified by Doc Center\") }")
node14 = subprocess(14, "Classify supporting document (async)", [960, 200], WORKER_PM,
                    [("drawId", "pv!drawId"), ("doc", "pv!doc"), ("docRowId", "pv!docRowId")], True, 12)

subs = {"@DOC@": rt(DOC), "@C_ID@": c("id"), "@C_DRAW@": c("drawId"), "@C_DOCUMENT@": c("document"),
        "@C_NAME@": c("documentName"), "@C_TYPE@": c("documentType"), "@C_STATUS@": c("status"),
        "@C_RECEIVED@": c("receivedDate"), "@C_UPLOADED@": c("uploadedAt"), "@C_UPLOADEDBY@": c("uploadedBy"),
        "@C_NOTES@": c("notes"), "@C_AMOUNT@": c("extractedAmount"), "@C_PARTY@": c("extractedParty"),
        "@C_REF@": c("extractedReference")}


def render(obj):
    out = json.dumps(obj)
    for k, v in subs.items():
        out = out.replace(k, v.replace('"', '\\"'))
    assert "@C_" not in out and "@DOC@" not in out
    json.loads(out)
    return out


worker = render({"processVariables": worker_pvs, "nodes": worker_nodes})
open("classify_worker_payload.json", "w").write(worker)
dispatch = render({"processVariables": dispatch_pvs,
                   "node5": {"customOutputs": [{"expression": e, "saveInto": s} for e, s in node5_outputs]},
                   "node6_records": node6_records, "node14": node14})
open("read_supporting_dispatch.json", "w").write(dispatch)
print("worker:", len(worker_pvs), "PVs,", len(worker_nodes), "nodes; dispatcher:", len(dispatch_pvs), "PVs")

"""Phase 5: the failure branch of SD Receive Capital Call (0000f06f-5661-8000-24e9-7f0000014e7a), as payloads for
updateProcessModel (process variables: the existing 34 re-sent unchanged + the Phase 5 ones) and createProcessModelNode /
updateProcessModelNode (nodes 31-41; nodes 11 and 13 rewired). Writes .work/sail/receive_failure_payloads.json.
Placeholders (@...@) from refs; no f-strings."""
import json
from refs import *
d = lambda n: fld(DRAW, n)
c = lambda n: fld(DOC, n)
DRAWT = "{urn:com:appian:recordtype:datatype}c9d3a947-71aa-4024-879e-363873a12860"
DOCT = "{urn:com:appian:recordtype:datatype}f3e0033f-2047-4c68-8f6f-cf32166091e9"
EXT = "{urn:com:appian:recordtype:datatype}64322398-e457-4695-87d5-09794164cf77"
QIUT = "{urn:com:appian:recordtype:datatype}a0920e4c-0c76-4494-a61a-6e38d5db390a"
APPRT = "{urn:com:appian:recordtype:datatype}02c207d5-c725-4d11-bf40-b33573e87ffa"
existing = [
  ("document","Document",True,False,None),("cancel","Boolean",True,False,None),("modelKey","Text",False,False,'"drawBudgetTemplate"'),
  ("drawShell",DRAWT,False,True,None),("drawId","Number (Integer)",False,False,None),("docRows",DOCT,False,True,None),
  ("docRowId","Number (Integer)",False,False,None),("extractionInstance",EXT,False,False,None),
  ("extractionInstanceId","Number (Integer)",False,False,None),("headerJson","Text",False,False,None),("linesJson","Text",False,False,None),
  ("confirmedHeaderJson","Text",False,False,None),("confirmedLinesJson","Text",False,False,None),("confirmedBy","Text",False,False,None),
  ("investmentId","Number (Integer)",False,False,None),("drawNumber","Number (Integer)",False,False,None),
  ("amount","Number (Decimal)",False,False,None),("fundingDate","Date",False,False,None),("drawType","Text",False,False,None),
  ("cashEquityNeeded","Text",False,False,None),("budgetStatus","Text",False,False,None),("overBudgetReason","Text",False,False,None),
  ("purpose","Text",False,False,None),("contingencyExplanation","Text",False,False,None),("generalComments","Text",False,False,None),
  ("submittedBy","Text",False,False,None),("investmentName","Text",False,False,None),("fundName","Text",False,False,None),
  ("writeError","Boolean",False,False,None),("writeErrorText","Text",False,False,None),("outcome","Text",False,False,None),
  ("qiuRows",QIUT,False,True,None),("chainRows",APPRT,False,True,None),("confirmedHeader","Map",False,False,None),
]
new = [
  ("templateCheck","Map",False,False,None),("comparisonRequest","Map",False,False,None),
  ("aiSuccess","Boolean",False,False,None),("aiResponse","Text",False,False,None),("aiError","Text",False,False,None),
  ("aiActions","Number (Decimal)",False,False,None),("aiModel","Text",False,False,None),
  ("aiStartedAt","Date and Time",False,False,None),("aiEndedAt","Date and Time",False,False,None),
  ("comparison","Map",False,False,None),("alertEmail","Map",False,False,None),("alertRecipientCount","Number (Integer)",False,False,None),
]
def pv(t):
    n, ty, param, mult, val = t
    o = {"name": n, "type": ty, "isParameter": param, "multiple": mult}
    if val is not None: o["value"] = val
    return o
pvs = [pv(t) for t in existing + new]

def script(i, name, xy, outs, to, runAs="DESIGNER"):
    return {"id": i, "type": "internal.16", "name": name, "coordinates": xy,
            "connections": [{"targetNodeId": to, "activityChained": False}],
            "data": {"customOutputs": [{"expression": e, "saveInto": s} for e, s in outs]},
            "assignment": {"attended": False, "runAs": runAs}}
def xor(i, name, xy, conds, default):
    return {"id": i, "type": "core.4", "name": name, "coordinates": xy,
            "connections": [{"targetNodeId": t, "activityChained": False} for t in sorted({c_[1] for c_ in conds} | {default})],
            "decision": {"conditions": [{"expression": e, "targetNodeId": t, "label": l} for e, t, l in conds], "defaultPath": default}}
def write(i, name, xy, records, to, runAs="INITIATOR", saveErr=True):
    outs = [{"name": "ErrorOccurred", "saveInto": "pv!writeError"}, {"name": "Error", "saveInto": "pv!writeErrorText"}] if saveErr else []
    return {"id": i, "type": "internal3.write_records_to_source_23r3", "name": name, "coordinates": xy,
            "connections": [{"targetNodeId": to, "activityChained": False}],
            "data": {"inputs": [{"name": "Records", "expression": records}, {"name": "PauseOnError", "value": 0}, {"name": "CaptureEvents", "value": 0}],
                     "outputs": outs},
            "assignment": {"attended": False, "runAs": runAs}}

Y = 560
nodes = [
  script(31, "Check template (rules)", [1620, 380],
    [("rule!SD_validateIngestedTemplate(document: pv!document, extractionInstanceId: pv!extractionInstanceId, headerJson: pv!headerJson)", "pv!templateCheck")], 32),
  xor(32, "Template OK?", [1780, 380],
    [("=a!defaultValue(index(pv!templateCheck, \"ok\", false), false)", 14, "yes")], 33),
  script(33, "Prepare template comparison", [1780, Y],
    [("rule!SD_buildTemplateComparisonRequest(received: index(pv!templateCheck, \"structure\", null), receivedName: index(pv!templateCheck, \"documentName\", null), investmentName: index(pv!templateCheck, \"investmentName\", null), excludeDrawId: pv!drawId)", "pv!comparisonRequest"),
     ("now()", "pv!aiStartedAt"),
     ("\"FAILED: template check - \" & joinarray(index(pv!templateCheck, \"problems\", {}), \" \")", "pv!outcome")], 34),
  xor(34, "Differences to explain?", [1930, Y],
    [("=a!defaultValue(index(index(pv!comparisonRequest, \"diff\", null), \"count\", 0), 0) > 0", 35, "yes")], 36),
  {"id": 35, "type": "internal3.rs2_ai_skill_generative_ai5", "name": "AI: compare with last good template", "coordinates": [2080, Y + 120],
   "connections": [{"targetNodeId": 36, "activityChained": False}],
   "data": {"inputs": [{"name": "AiSkill", "value": 148}, {"name": "RemoteServiceKey", "value": "ai_skill_generative_ai"}],
            "customInputs": [{"name": "Input Text", "type": "TEXT", "expression": "=index(pv!comparisonRequest, \"inputText\", \"\")"},
                             {"name": "Runtime Prompt", "type": "TEXT", "expression": "=index(pv!comparisonRequest, \"prompt\", \"\")"},
                             {"name": "Runtime Model", "type": "TEXT", "expression": "=cons!SD_TEMPLATE_COMPARISON_MODEL"},
                             {"name": "Enable Extended Thinking", "type": "BOOLEAN", "value": 0}],
            "outputs": [{"name": "Success", "saveInto": "pv!aiSuccess"}, {"name": "Response", "saveInto": "pv!aiResponse"},
                        {"name": "ErrorMessage", "saveInto": "pv!aiError"}, {"name": "AiActions", "saveInto": "pv!aiActions"},
                        {"name": "Model", "saveInto": "pv!aiModel"}]},
   "assignment": {"attended": False, "runAs": "DESIGNER"}},
  script(36, "Check AI comparison (rules)", [2230, Y],
    [("rule!SD_checkTemplateComparison(response: pv!aiResponse, success: pv!aiSuccess, errorMessage: pv!aiError, aiAttempted: not(isnull(pv!aiSuccess)), diff: index(pv!comparisonRequest, \"diff\", null), baselineLabel: index(pv!comparisonRequest, \"baselineLabel\", null))", "pv!comparison"),
     ("now()", "pv!aiEndedAt")], 37),
  write(37, "Draw Ingestion Failed (reason, comparison)", [2380, Y],
    "={ @DRAW@(@D_ID@: pv!drawId, @D_STATUS@: \"Ingestion Failed\", @D_REASON@: left(a!defaultValue(index(pv!templateCheck, \"reason\", null), \"The budget template could not be loaded.\"), 4000), @D_COMP@: index(pv!comparison, \"text\", null), @D_INV@: index(pv!comparisonRequest, \"investmentId\", null), @D_UPD@: now()) }", 38),
  xor(38, "Failure recorded?", [2530, Y],
    [("=a!defaultValue(pv!writeError, false)", 20, "no")], 39),
  script(39, "Build alert email", [2680, Y],
    [("rule!SD_buildIngestionFailureEmail(drawId: pv!drawId, fileInvestmentName: index(pv!templateCheck, \"investmentName\", null), fileDrawNumber: index(pv!templateCheck, \"drawNumber\", null))", "pv!alertEmail")], 40),
  {"id": 40, "type": "internal3.sendemail3", "name": "Ingestion failure alert (email)", "coordinates": [2830, Y],
   "connections": [{"targetNodeId": 41, "activityChained": False}],
   "data": {"inputs": [{"name": "From", "value": "Process Model"},
                       {"name": "To", "expression": "={cons!SD_DRAW_DEMO_APPROVERS_GROUP, cons!SD_DRAW_ASSET_MANAGER_GROUP}"},
                       {"name": "Subject", "expression": "=a!defaultValue(index(pv!alertEmail, \"subject\", null), \"Draw template could not be loaded\")"},
                       {"name": "Priority", "value": 3}, {"name": "IsHTML", "value": 1},
                       {"name": "BodyHTML", "expression": "=a!defaultValue(index(pv!alertEmail, \"html\", null), \"<p>A draw budget template could not be loaded. Open the Draws list for the reason and the comparison.</p>\")"}],
            "customOutputs": [{"expression": "count(ac!ToValidAddresses)", "saveInto": "pv!alertRecipientCount"}]},
   # DESIGNER, not INITIATOR: run as the persona who received the file (sd.accountant) the node stopped the first live
   # run (instance 38992); the identical node run as the designer completed (control zz_probeAlertSend). 2026-09-25.
   "assignment": {"attended": False, "runAs": "DESIGNER"}},
  write(41, "Template document Ingestion Failed", [2980, Y],
    "={ @DOC@(@C_ID@: pv!docRowId, @C_STATUS@: \"Ingestion Failed\", @C_NOTES@: left(\"Template check failed \" & text(now(), \"MM/DD/YYYY h:mm AM/PM\") & \". Comparison: \" & if(a!defaultValue(index(pv!comparison, \"aiUsed\", false), false), \"AI (\" & a!localVariables(local!m: a!genAiModels(), index(index(local!m, \"name\", {}), index(wherecontains(tostring(pv!aiModel), touniformstring(index(local!m, \"id\", {}))), 1, 0), a!defaultValue(pv!aiModel, \"model?\"))) & \")\" & if(a!defaultValue(index(pv!comparison, \"overviewByAi\", false), false), \"\", \", summary in standard wording\"), \"rules\" & if(isnull(pv!aiSuccess), \" (no AI call)\", \" (AI answer not used: \" & index(index(pv!comparison, \"failures\", {}), 1, \"\") & \")\")) & if(isnull(pv!aiSuccess), \"\", \"; AI call \" & tostring(pv!aiEndedAt - pv!aiStartedAt) & \", \" & a!defaultValue(pv!aiActions, 0) & \" AI actions\") & \"; alert email sent to the accountant and asset manager groups.\", 1000)) }", 2,
    saveErr=False),
]
subs = {"@DRAW@": rt(DRAW), "@D_ID@": d("id"), "@D_STATUS@": d("status"), "@D_REASON@": d("ingestionFailureReason"),
        "@D_COMP@": d("ingestionComparison"), "@D_INV@": d("investmentId"), "@D_UPD@": d("updatedAt"),
        "@DOC@": rt(DOC), "@C_ID@": c("id"), "@C_STATUS@": c("status"), "@C_NOTES@": c("notes")}
out = json.dumps({"processVariables": pvs, "nodes": nodes}, indent=1)
for k, v in subs.items():
    out = out.replace(k, v.replace('"', '\\"'))
assert "@D_" not in out and "@C_" not in out
open("receive_failure_payloads.json", "w").write(out)
print(len(pvs), "PVs;", len(nodes), "nodes")

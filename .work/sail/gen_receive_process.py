"""Generates the node/PV payload for SD Receive Capital Call (updateProcessModel). Stage A: intake + extraction + prep."""
import json, sys
from refs import *
d = lambda n: fld(DRAW, n)
doc = lambda n: fld(DOC, n)
DRAW_TYPE = "{urn:com:appian:recordtype:datatype}c9d3a947-71aa-4024-879e-363873a12860"
DOC_TYPE = "{urn:com:appian:recordtype:datatype}f3e0033f-2047-4c68-8f6f-cf32166091e9"
AIA_TYPE = "{urn:com:appian:recordtype:datatype}64322398-e457-4695-87d5-09794164cf77"
AIA_ID = "'recordType!{64322398-e457-4695-87d5-09794164cf77}AIA Extraction Instance.fields.{7a1970b4-ae29-4d49-96d5-3659721cff16}id'"
EXTRACTION_ID = "'recordType!{c9d3a947-71aa-4024-879e-363873a12860}SD Draw.fields.{1c798a00-4519-49c1-9c04-27e7fb78a9d3}extractionInstanceId'"

def pv(name, type_, **kw):
    v = dict(name=name, type=type_); v.update(kw); return v

pvs = [
  pv("document", "Document", isParameter=True, isRequired=False),
  pv("cancel", "Boolean", isParameter=True, isRequired=False),
  pv("modelKey", "Text", value='"drawBudgetTemplate"'),
  pv("drawShell", DRAW_TYPE, multiple=True),
  pv("drawId", "Number (Integer)"),
  pv("docRows", DOC_TYPE, multiple=True),
  pv("docRowId", "Number (Integer)"),
  pv("extractionInstance", AIA_TYPE),
  pv("extractionInstanceId", "Number (Integer)"),
  pv("headerJson", "Text"), pv("linesJson", "Text"),
  pv("confirmedHeaderJson", "Text"), pv("confirmedLinesJson", "Text"), pv("confirmedBy", "Text"),
  pv("investmentId", "Number (Integer)"), pv("drawNumber", "Number (Integer)"), pv("amount", "Number (Decimal)"),
  pv("fundingDate", "Date"), pv("drawType", "Text"), pv("cashEquityNeeded", "Text"), pv("budgetStatus", "Text"),
  pv("overBudgetReason", "Text"), pv("purpose", "Text"), pv("contingencyExplanation", "Text"), pv("generalComments", "Text"),
  pv("submittedBy", "Text"), pv("investmentName", "Text"), pv("fundName", "Text"),
  pv("writeError", "Boolean"), pv("writeErrorText", "Text"), pv("outcome", "Text"),
  pv("qiuRows", "{urn:com:appian:recordtype:datatype}a0920e4c-0c76-4494-a61a-6e38d5db390a", multiple=True),
  pv("chainRows", "{urn:com:appian:recordtype:datatype}02c207d5-c725-4d11-bf40-b33573e87ffa", multiple=True),
  pv("confirmedHeader", "Map"),
]

def conn(t, chained=False): return dict(targetNodeId=t, activityChained=chained)
def unattended(run_as="INITIATOR"): return dict(attended=False, runAs=run_as)
def script(id_, name, xy, outputs, targets, run_as="INITIATOR"):
    return dict(id=id_, type="internal.16", name=name, coordinates=xy,
                connections=[conn(t) for t in targets],
                data=dict(customOutputs=[dict(expression=e, saveInto=s) for e, s in outputs]),
                assignment=unattended(run_as))
def write(id_, name, xy, records_expr, targets, updated_pv=None, run_as="INITIATOR"):
    outs = [dict(name="ErrorOccurred", saveInto="pv!writeError"), dict(name="Error", saveInto="pv!writeErrorText")]
    if updated_pv: outs.insert(0, dict(name="RecordsUpdated", saveInto=updated_pv))
    return dict(id=id_, type="internal3.write_records_to_source_23r3", name=name, coordinates=xy,
                connections=[conn(t) for t in targets],
                data=dict(inputs=[dict(name="Records", expression="=" + records_expr),
                                  dict(name="PauseOnError", value=False),
                                  dict(name="CaptureEvents", value=False)],
                          outputs=outs),
                assignment=unattended(run_as))
def xor(id_, name, xy, cond, when_true, default):
    return dict(id=id_, type="core.4", name=name, coordinates=xy,
                connections=[conn(when_true), conn(default)],
                decision=dict(conditions=[dict(expression="=" + cond, targetNodeId=when_true, label="yes")], defaultPath=default))

shell = f"""{{ {rt(DRAW)}({d('status')}: "Ingesting", {d('receivedDate')}: today(), {d('submittedBy')}: "EY data feed", {d('createdAt')}: now(), {d('updatedAt')}: now()) }}"""
docrow = f"""{{ {rt(DOC)}({doc('drawId')}: pv!drawId, {doc('document')}: pv!document, {doc('documentName')}: document(pv!document, "name") & "." & document(pv!document, "extension"), {doc('documentType')}: "Budget Template", {doc('status')}: "Received", {doc('receivedDate')}: today(), {doc('uploadedAt')}: now(), {doc('uploadedBy')}: "EY data feed") }}"""
store_ext = f"""{{ {rt(DRAW)}({d('id')}: pv!drawId, {EXTRACTION_ID}: pv!extractionInstanceId, {d('updatedAt')}: now()) }}"""
failed = f"""{{ {rt(DRAW)}({d('id')}: pv!drawId, {d('status')}: "Ingestion Failed", {d('updatedAt')}: now()) }}"""

nodes = [
  dict(id=1, type="core.0", name="Start", coordinates=[50,200], connections=[conn(3)]),
  dict(id=2, type="core.1", name="End", coordinates=[1900,200], connections=[]),
  xor(3, "Cancelled?", [180,200], "a!defaultValue(pv!cancel, false)", 2, 4),
  write(4, "Create draw shell (Ingesting)", [320,200], shell, [5], updated_pv="pv!drawShell"),
  xor(5, "Shell written?", [470,200], "a!defaultValue(pv!writeError, false)", 20, 6),
  script(6, "Read draw id", [600,200], [(f"index(pv!drawShell, 1, null)[{d('id')}]", "pv!drawId")], [7]),
  write(7, "Register template document (Received)", [740,200], docrow, [8], updated_pv="pv!docRows"),
  script(8, "Read document row id", [900,200], [(f"index(pv!docRows, 1, null)[{doc('id')}]", "pv!docRowId")], [9]),
  dict(id=9, type="internal.38", name="Doc Center: extract budget template", coordinates=[1050,200],
       connections=[conn(10)],
       data=dict(customInputs=[dict(name="document", expression="document"),
                               dict(name="modelKey", expression="modelKey")],
                 inputs=[dict(name="pmUUID", value="dad961d1-ef89-4f6b-9fcc-384ab2e78755"),
                         dict(name="isAsynchronous", value=False),
                         dict(name="isTransparent", value=True),
                         dict(name="inheritSecurity", value=False),
                         dict(name="chainsInto", value=False)]),
       assignment=unattended("DESIGNER")),
  script(10, "Find extraction instance", [1200,200], [("rule!SD_getExtractionInstanceIdForDocument(document: pv!document)", "pv!extractionInstanceId")], [11], run_as="DESIGNER"),
  xor(11, "Extracted?", [1330,200], "a!isNullOrEmpty(pv!extractionInstanceId)", 20, 12),
  write(12, "Store extraction id on draw", [1460,200], store_ext, [13]),
  script(13, "Prepare reconciliation", [1620,200],
         [("rule!SD_getExtractionForReconcile(instanceId: pv!extractionInstanceId).headerJson", "pv!headerJson"),
          ("rule!SD_getExtractionForReconcile(instanceId: pv!extractionInstanceId).linesJson", "pv!linesJson"),
          ('"EXTRACTED: instance " & pv!extractionInstanceId', "pv!outcome")], [14], run_as="DESIGNER"),
  script(20, "Mark ingestion failed", [470,400],
         [('"FAILED: " & a!defaultValue(pv!writeErrorText, "Doc Center returned no extraction instance")', "pv!outcome")], [21]),
  write(21, "Draw status Ingestion Failed", [740,400], failed, [2]),
]

# ---- stage B: reconciliation task, commits, assembly ----
H = "index(pv!confirmedHeader, %s, null)"
def hv(key): return 'tostring(a!defaultValue(index(pv!confirmedHeader, "%s", ""), ""))' % key
def acp(name, type_, expr): return dict(name=name, type=type_, expression="=" + expr)
task = dict(id=14, type="internal.17", name="Reconcile extracted draw", coordinates=[1780,200],
  connections=[conn(15)],
  data=dict(customInputs=[
      acp("drawId", "Number (Integer)", "pv!drawId"),
      acp("documentId", "Number (Integer)", "tointeger(pv!document)"),
      acp("documentName", "Text", 'a!defaultValue(document(pv!document, "name") & "." & document(pv!document, "extension"), "budget template")'),
      acp("instanceId", "Number (Integer)", "pv!extractionInstanceId"),
      acp("headerJson", "Text", 'a!defaultValue(pv!headerJson, "[]")'),
      acp("linesJson", "Text", 'a!defaultValue(pv!linesJson, "[]")'),
      acp("confirmedHeaderJson", "Text", 'a!defaultValue(pv!confirmedHeaderJson, "-")'),
      acp("confirmedLinesJson", "Text", 'a!defaultValue(pv!confirmedLinesJson, "-")'),
      acp("confirmedBy", "Text", 'a!defaultValue(pv!confirmedBy, "-")')],
    customOutputs=[dict(expression="ac!confirmedHeaderJson", saveInto="pv!confirmedHeaderJson"),
                   dict(expression="ac!confirmedLinesJson", saveInto="pv!confirmedLinesJson"),
                   dict(expression="ac!confirmedBy", saveInto="pv!confirmedBy")]),
  forms=dict(interfaceUuid="_a-0000f060-57b9-8000-9c4d-011c48011c48_571183",
             inputMap=dict(drawId="drawId", documentId="documentId", documentName="documentName", instanceId="instanceId",
                           headerJson="headerJson", linesJson="linesJson", confirmedHeaderJson="confirmedHeaderJson",
                           confirmedLinesJson="confirmedLinesJson", confirmedBy="confirmedBy")),
  assignment=dict(attended=True, assignTo="=cons!SD_DRAW_DEMO_APPROVERS_GROUP", reassignPrivileges="REASSIGN_TO_ANY"))

parse_header = script(15, "Parse confirmed header", [1930,200],
  [('if(or(a!isNullOrEmpty(pv!confirmedHeaderJson), pv!confirmedHeaderJson = "-"), a!map(), a!fromJson(pv!confirmedHeaderJson))', "pv!confirmedHeader")], [16], run_as="DESIGNER")
parse_fields = script(16, "Read header fields", [2080,200], [
  ('a!localVariables(local!v: %s, if(local!v = "", null, tointeger(local!v)))' % hv("drawNumber"), "pv!drawNumber"),
  ('a!localVariables(local!v: %s, if(local!v = "", null, tointeger(local!v)))' % hv("investmentId"), "pv!investmentId"),
  ('a!localVariables(local!v: %s, if(local!v = "", null, todecimal(local!v)))' % hv("drawAmount"), "pv!amount"),
  ('rule!SD_parseExtractedDate(text: %s)' % hv("fundingDate"), "pv!fundingDate"),
  (hv("drawType"), "pv!drawType"), (hv("cashEquityNeeded"), "pv!cashEquityNeeded"), (hv("budgetStatus"), "pv!budgetStatus"),
  (hv("overBudgetReason"), "pv!overBudgetReason"), (hv("purpose"), "pv!purpose"),
  (hv("contingencyExplanation"), "pv!contingencyExplanation"), (hv("generalComments"), "pv!generalComments"),
  (hv("submittedBy"), "pv!submittedBy"), (hv("investmentName"), "pv!investmentName"), (hv("fund"), "pv!fundName"),
], [17], run_as="DESIGNER")

commit_header = f"""{{ {rt(DRAW)}({d('id')}: pv!drawId, {d('drawNumber')}: pv!drawNumber, {d('investmentId')}: pv!investmentId, {d('amount')}: pv!amount, {d('fundingDate')}: pv!fundingDate, {d('drawType')}: pv!drawType, {d('cashEquityNeeded')}: or(lower(a!defaultValue(pv!cashEquityNeeded, "")) = "yes", lower(a!defaultValue(pv!cashEquityNeeded, "")) = "y", lower(a!defaultValue(pv!cashEquityNeeded, "")) = "true"), {d('budgetStatus')}: pv!budgetStatus, {d('overBudgetReason')}: pv!overBudgetReason, {d('purpose')}: pv!purpose, {d('contingencyExplanation')}: pv!contingencyExplanation, {d('generalComments')}: if(a!defaultValue(pv!generalComments, "") = "", null, pv!generalComments), {d('submittedBy')}: pv!submittedBy, {d('updatedAt')}: now()) }}"""
doc_confirmed = f"""{{ {rt(DOC)}({doc('id')}: pv!docRowId, {doc('status')}: "Extracted & Confirmed", {doc('notes')}: "Doc Center extraction confirmed by " & rule!SD_getUserDisplayName(username: pv!confirmedBy) & " " & text(today(), "MM/DD/YYYY")) }}"""
activate = f"""{{ {rt(DRAW)}({d('id')}: pv!drawId, {d('status')}: "In Progress", {d('currentStep')}: 1, {d('updatedAt')}: now()) }}"""

nodes += [
  task, parse_header, parse_fields,
  write(17, "Commit header facts", [2230,200], commit_header, [18], run_as="DESIGNER"),
  xor(18, "Header committed?", [2380,200], "a!defaultValue(pv!writeError, false)", 20, 19),
  write(19, "Commit budget lines", [2530,200], "rule!SD_buildIngestedBudgetLines(drawId: pv!drawId, linesJson: pv!confirmedLinesJson)", [22], run_as="DESIGNER"),
  write(22, "Template Extracted & Confirmed", [2680,200], doc_confirmed, [23], run_as="DESIGNER"),
  script(23, "Assemble QIU and chain", [2830,200],
         [("rule!SD_buildIngestedQiu(drawId: pv!drawId, investmentId: pv!investmentId, asOfDate: today())", "pv!qiuRows"),
          ("rule!SD_buildIngestedApprovalChain(drawId: pv!drawId, investmentId: pv!investmentId)", "pv!chainRows")], [24], run_as="DESIGNER"),
  xor(24, "QIU available?", [2980,200], "a!isNullOrEmpty(pv!qiuRows)", 26, 25),
  write(25, "Aggregate QIU rows", [3130,200], "pv!qiuRows", [26], run_as="DESIGNER"),
  write(26, "Create approval chain", [3280,200], "pv!chainRows", [27], run_as="DESIGNER"),
  xor(27, "Chain written?", [3430,200], "a!defaultValue(pv!writeError, false)", 20, 28),
  write(28, "Activate draw (In Progress, step 1)", [3580,200], activate, [29], run_as="DESIGNER"),
  dict(id=29, type="internal.38", name="Start SD Draw Approval Process", coordinates=[3730,200],
       connections=[conn(30)],
       data=dict(inputs=[dict(name="drawId", expression="pv!drawId"),
                         dict(name="pmUUID", value="0000f06e-a54a-8000-24cd-7f0000014e7a"),
                         dict(name="isAsynchronous", value=True),
                         dict(name="isTransparent", value=True),
                         dict(name="inheritSecurity", value=False),
                         dict(name="chainsInto", value=False)]),
       assignment=unattended("DESIGNER")),
  script(30, "Mark assembled", [3880,200], [('"ASSEMBLED: draw " & pv!drawId & " (#" & a!defaultValue(pv!drawNumber, "?") & ") at step 1"', "pv!outcome")], [2]),
]
for n in nodes:
    if n["id"] == 2: n["coordinates"] = [4030, 200]

payload = dict(uuid="0000f06f-5661-8000-24e9-7f0000014e7a", processVariables=pvs, nodes=nodes)
json.dump(payload, open(sys.argv[1], "w"), indent=1)
print("wrote", sys.argv[1], len(nodes), "nodes")

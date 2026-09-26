"""Phase 6a: payload for SD Handle Approval Reply (the email-reply handler) and the step-email changes to
SD Draw Approval Step. Writes reply_handler_payload.json (PVs + nodes) and step_email_payload.json (node 8 data + the new
node 13). No f-strings.

Phase 6b: QUESTION route, decision receipts, the decisive phrase and the sender's name on every row.

Handler flow (every node as the designer):
  3 read the reply (token, reply text)  ->  5 checks (SD_getReplyContext)  ->  4 XOR on the verdict
     OK          -> 10 AI request -> 11 AI (DocCenter Text Input skill, Runtime Prompt) -> 12 gate -> 14 route -> 13 XOR
                      APPLY   -> 40 SD Apply Draw Approval Decision (sync, source EMAIL) -> 41 log the reply
                                 -> 42 recorded? -> 43 receipt (rules) -> 44 send the receipt on the thread -> 45 log it -> end
                      QUESTION (6b) -> 70 log the question (outcome QUESTION; no reply to the approver) -> end
                      CLARIFY -> 50 build clarification -> 51 log the reply -> 52 send on the thread -> 53 log it -> end
                      else    -> 60 log the reply -> 61 exception task (SD Draw Demo Approvers) -> 62 log the review -> end
     GUARDRAIL   -> 20 build refusal -> 21 log the reply -> 22 send on the thread -> 23 log it -> end
     otherwise   -> 30 log the reply (UNMATCHED / UNAUTHORIZED / NOT_AWAITING; nothing sent) -> end
"""
import json
from refs import *

m = lambda n: fld(MSG, n)
HANDLER = "0000f074-9a9b-8000-25ce-7f0000014e7a"
APPLY_PM = "0000f06e-a53d-8000-24ca-7f0000014e7a"
AI_SKILL = 148                       # DocCenter's Text Input skill (as Phase 5's comparison node)
EXC_FORM = "_a-0000f060-57b9-8000-9c4d-011c48011c48_575621"


def conn(*ts):
    return [{"targetNodeId": t, "activityChained": False} for t in ts]


def script(i, name, xy, outs, to):
    return {"id": i, "type": "internal.16", "name": name, "coordinates": xy, "connections": conn(to),
            "data": {"customOutputs": [{"expression": e, "saveInto": s} for e, s in outs]},
            "assignment": {"attended": False, "runAs": "DESIGNER"}}


def xor(i, name, xy, conds, default):
    targets = [t for _, t, _ in conds] + [default]
    return {"id": i, "type": "core.4", "name": name, "coordinates": xy, "connections": conn(*targets),
            "decision": {"conditions": [{"expression": e, "targetNodeId": t, "label": l} for e, t, l in conds],
                         "defaultPath": default}}


def write(i, name, xy, records, to):
    return {"id": i, "type": "internal3.write_records_to_source_23r3", "name": name, "coordinates": xy,
            "connections": conn(to),
            "data": {"inputs": [{"name": "Records", "expression": records}, {"name": "PauseOnError", "value": 0},
                                {"name": "CaptureEvents", "value": 0}],
                     "outputs": [{"name": "ErrorOccurred", "saveInto": "pv!writeError"},
                                 {"name": "Error", "saveInto": "pv!writeErrorText"}]},
            "assignment": {"attended": False, "runAs": "DESIGNER"}}


def send(i, name, xy, to_expr, to):
    # Send E-Mail text inputs are wrapped (tostring / toemailaddress): a bare "=pv!x" fails the save (measured)
    return {"id": i, "type": "internal3.sendemail3", "name": name, "coordinates": xy, "connections": conn(to),
            "data": {"inputs": [
                {"name": "From", "value": "Custom Sender"},
                {"name": "FromEmailValue", "expression": "=toemailaddress(cons!SD_EMAIL_REPLY_ADDRESS)"},
                {"name": "Email Sender Display Name", "expression": "=tostring(cons!SD_EMAIL_SENDER_NAME)"},
                {"name": "To", "expression": to_expr},
                {"name": "ReplyTo", "expression": "=toemailaddress(cons!SD_EMAIL_REPLY_ADDRESS)"},
                {"name": "Subject", "expression": "=tostring(index(pv!response, \"subject\", \"\"))"},
                {"name": "Priority", "value": 3},
                {"name": "IsHTML", "value": 1},
                {"name": "BodyHTML", "expression": "=tostring(index(pv!response, \"html\", \"\"))"}]},
            "assignment": {"attended": False, "runAs": "DESIGNER"}}


# one inbound row: the reply itself, with its outcome (SD_newEmailMessage cuts every text to its column)
CTX = "drawId: tointeger(index(pv!context, \"drawId\", null)), approvalId: tointeger(index(pv!context, \"approvalId\", null)), stepOrder: tointeger(index(pv!context, \"stepOrder\", null))"


# the approver's name and role once the sender is authorized (6b); an unknown sender shows as its address only
SENDER = ("if(a!defaultValue(index(pv!context, \"authorized\", false), false), index(pv!context, \"approverName\", \"\") & \" (\" & "
          "index(pv!context, \"role\", \"\") & \")\", \"\")")
PHRASE = "tostring(index(pv!reading, \"phrase\", \"\"))"


def inbound(outcome_expr, interp_expr, notes_expr, phrase_expr="\"\""):
    return ("={ rule!SD_newEmailMessage(" + CTX + ", direction: \"INBOUND\", kind: \"REPLY\", fromAddress: pv!fromAddress, "
            "toAddress: cons!SD_EMAIL_REPLY_ADDRESS, subject: pv!subject, body: pv!replyText, messageAt: pv!receivedAt, "
            "outcome: " + outcome_expr + ", interpretation: " + interp_expr + ", source: \"EMAIL\", notes: " + notes_expr + ", "
            "decisivePhrase: " + phrase_expr + ", senderName: " + SENDER + ") }")


# one outbound row: what the flow sent back on the thread
def outbound(kind, notes="Sent on the reply thread (Re: the step email), from and reply-to the receiver address"):
    return ("={ rule!SD_newEmailMessage(" + CTX + ", direction: \"OUTBOUND\", kind: \"" + kind + "\", "
            "fromAddress: cons!SD_EMAIL_REPLY_ADDRESS, toAddress: pv!fromAddress, subject: tostring(index(pv!response, \"subject\", \"\")), "
            "body: tostring(index(pv!response, \"text\", \"\")), messageAt: now(), outcome: \"SENT\", interpretation: \"\", source: \"EMAIL\", "
            "notes: \"" + notes + "\", senderName: cons!SD_EMAIL_SENDER_NAME) }")


REVIEW = ("={ rule!SD_newEmailMessage(" + CTX + ", direction: \"INTERNAL\", kind: \"EXCEPTION_REVIEW\", fromAddress: pv!reviewedBy, "
          "toAddress: \"\", subject: pv!subject, body: pv!reviewNote, messageAt: now(), outcome: \"REVIEWED\", interpretation: \"\", "
          "source: \"EXCEPTION_QUEUE\", notes: \"Exception queue task reviewed by \" & a!defaultValue(pv!reviewedBy, \"(unknown)\") & \"; the draw was not changed by the queue\", "
          "senderName: rule!SD_getUserDisplayName(username: pv!reviewedBy)) }")

pvs = [
    {"name": "fromAddress", "type": "Text", "isParameter": True},
    {"name": "subject", "type": "Text", "isParameter": True},
    {"name": "body", "type": "Text", "isParameter": True},
    {"name": "receivedAt", "type": "Date and Time"},
    {"name": "token", "type": "Map"}, {"name": "replyText", "type": "Text"}, {"name": "context", "type": "Map"},
    {"name": "aiRequest", "type": "Map"}, {"name": "aiSuccess", "type": "Boolean"}, {"name": "aiResponse", "type": "Text"},
    {"name": "aiError", "type": "Text"}, {"name": "aiActions", "type": "Number (Decimal)"}, {"name": "aiModel", "type": "Text"},
    {"name": "aiStartedAt", "type": "Date and Time"}, {"name": "aiEndedAt", "type": "Date and Time"},
    {"name": "reading", "type": "Map"}, {"name": "route", "type": "Text"}, {"name": "exceptionReason", "type": "Text"},
    {"name": "interpretationText", "type": "Text"},
    {"name": "applyDrawId", "type": "Number (Integer)"}, {"name": "applyStep", "type": "Number (Integer)"},
    {"name": "applyDecision", "type": "Text"}, {"name": "applyComment", "type": "Text"}, {"name": "applyActor", "type": "Text"},
    {"name": "applySource", "type": "Text", "value": "\"EMAIL\""}, {"name": "applyStartNext", "type": "Boolean", "value": "true()"},
    {"name": "applyDate", "type": "Date and Time"}, {"name": "transitionOutcome", "type": "Text"},
    {"name": "response", "type": "Map"},
    {"name": "reviewNote", "type": "Text"}, {"name": "reviewedBy", "type": "Text"},
    {"name": "stepLabel", "type": "Text"},
    {"name": "writeError", "type": "Boolean"}, {"name": "writeErrorText", "type": "Text"},
]

VERDICT = "index(pv!context, \"verdict\", \"UNMATCHED\")"
nodes = [
    {"id": 1, "type": "core.0", "name": "Start", "coordinates": [40, 300], "connections": conn(3)},
    script(3, "Read the reply (rules)", [150, 300], [
        ("now()", "pv!receivedAt"),
        ("rule!SD_parseReplyToken(subject: pv!subject)", "pv!token"),
        ("rule!SD_extractReplyText(body: pv!body)", "pv!replyText")], 5),
    script(5, "Checks: draw, sender, limit, step (rules)", [270, 300], [
        ("rule!SD_getReplyContext(drawId: index(pv!token, \"drawId\", null), stepOrder: index(pv!token, \"stepOrder\", null), fromAddress: pv!fromAddress)",
         "pv!context")], 6),
    # node 6, not 4: stage 0 had a Write Records node as 4, and a node's type cannot change on update (measured)
    xor(6, "Checks pass?", [390, 300], [
        ("=" + VERDICT + " = \"OK\"", 10, "ok"),
        ("=" + VERDICT + " = \"GUARDRAIL\"", 20, "over the email limit")], 30),
    # refused: logged on the draw, nothing sent, nothing changed
    write(30, "Log reply (not acted on)", [390, 520],
          inbound(VERDICT, "\"\"", "index(pv!context, \"reason\", \"\") & \" Nothing changed.\""), 2),
    # guardrail: logged, refusal on the thread
    script(20, "Guardrail refusal (rules)", [520, 440], [
        ("rule!SD_buildReplyResponseEmail(kind: \"GUARDRAIL\", context: pv!context, replyText: pv!replyText)", "pv!response")], 21),
    write(21, "Log reply (guardrail)", [640, 440],
          inbound("\"GUARDRAIL\"", "\"\"", "index(pv!context, \"reason\", \"\") & \" Email approval refused; nothing changed.\""), 22),
    send(22, "Send guardrail refusal on the thread", [760, 440], "=toemailaddress(pv!fromAddress)", 23),
    write(23, "Log refusal sent", [880, 440], outbound("GUARDRAIL_REFUSAL"), 2),
    # interpretation
    script(10, "Prepare the AI request (rules)", [520, 300], [
        ("rule!SD_buildReplyInterpretationRequest(replyText: pv!replyText, context: pv!context)", "pv!aiRequest"),
        ("now()", "pv!aiStartedAt")], 11),
    {"id": 11, "type": "internal3.rs2_ai_skill_generative_ai5", "name": "AI: read the reply", "coordinates": [640, 300],
     "connections": conn(12),
     "data": {"inputs": [{"name": "AiSkill", "value": AI_SKILL}, {"name": "RemoteServiceKey", "value": "ai_skill_generative_ai"}],
              "customInputs": [
                  {"name": "Input Text", "type": "TEXT", "expression": "=index(pv!aiRequest, \"inputText\", \"\")"},
                  {"name": "Runtime Prompt", "type": "TEXT", "expression": "=index(pv!aiRequest, \"prompt\", \"\")"},
                  {"name": "Runtime Model", "type": "TEXT", "expression": "=cons!SD_EMAIL_INTERPRETATION_MODEL"},
                  {"name": "Enable Extended Thinking", "type": "BOOLEAN", "value": 0}],
              "outputs": [{"name": "Success", "saveInto": "pv!aiSuccess"}, {"name": "Response", "saveInto": "pv!aiResponse"},
                          {"name": "ErrorMessage", "saveInto": "pv!aiError"}, {"name": "AiActions", "saveInto": "pv!aiActions"},
                          {"name": "Model", "saveInto": "pv!aiModel"}]},
     "assignment": {"attended": False, "runAs": "DESIGNER"}},
    script(12, "Gate the reading (rules)", [760, 300], [
        ("now()", "pv!aiEndedAt"),
        ("rule!SD_gateReplyInterpretation(success: pv!aiSuccess, response: pv!aiResponse, errorMessage: pv!aiError, replyText: pv!replyText)",
         "pv!reading")], 14),
    script(14, "Route (rules)", [880, 300], [
        ("a!localVariables(local!r: pv!reading, local!c: a!defaultValue(index(local!r, \"classified\", false), false), local!d: index(local!r, \"decision\", \"AMBIGUOUS\"), "
         "if(and(local!c, or(local!d = \"APPROVE\", local!d = \"REJECT\")), \"APPLY\", if(and(local!c, local!d = \"QUESTION\"), \"QUESTION\", "
         "if(and(local!c, local!d = \"AMBIGUOUS\", a!defaultValue(index(pv!context, \"priorAmbiguous\", 0), 0) = 0), \"CLARIFY\", \"EXCEPTION\"))))",
         "pv!route"),
        ("if(a!defaultValue(index(pv!reading, \"classified\", false), false), \"A second reply on this step that is not a clear approval or rejection.\", "
         "\"The reply could not be classified: \" & index(pv!reading, \"reason\", \"\"))", "pv!exceptionReason"),
        ("\"Read as \" & index(pv!reading, \"decision\", \"AMBIGUOUS\") & if(a!defaultValue(index(pv!reading, \"phrase\", \"\"), \"\") = \"\", \"\", \" · decisive phrase: \"\"\" & index(pv!reading, \"phrase\", \"\") & \"\"\"\") & if(a!defaultValue(index(pv!reading, \"comment\", \"\"), \"\") = \"\", \"\", \" · comment: \" & index(pv!reading, \"comment\", \"\")) & "
         "\" · \" & index(pv!reading, \"reason\", \"\") & \" · \" & a!defaultValue(pv!aiModel, \"model?\") & \", \" & fixed(todecimal(pv!aiEndedAt - pv!aiStartedAt) * 86400, 1) & \" s, \" & a!defaultValue(pv!aiActions, 0) & \" AI actions\"",
         "pv!interpretationText"),
        ("tointeger(index(pv!context, \"drawId\", null))", "pv!applyDrawId"),
        ("tointeger(index(pv!context, \"stepOrder\", null))", "pv!applyStep"),
        ("index(pv!reading, \"decision\", \"\")", "pv!applyDecision"),
        ("left(\"Email reply from \" & pv!fromAddress & \": \"\"\" & left(pv!replyText, 600) & \"\"\" · read as \" & index(pv!reading, \"decision\", \"\") & "
         "\" on \"\"\" & index(pv!reading, \"phrase\", \"\") & \"\"\"\" & "
         "if(a!defaultValue(index(pv!reading, \"comment\", \"\"), \"\") = \"\", \"\", \" (comment: \" & index(pv!reading, \"comment\", \"\") & \")\"), 1000)", "pv!applyComment"),
        ("pv!fromAddress", "pv!applyActor"),
        ("pv!receivedAt", "pv!applyDate"),
        ("\"Step \" & index(pv!context, \"stepOrder\", \"?\") & \" · \" & index(pv!context, \"role\", \"\")", "pv!stepLabel")], 13),
    xor(13, "Route?", [1000, 300], [
        ("=pv!route = \"APPLY\"", 40, "approve or reject"),
        ("=pv!route = \"QUESTION\"", 70, "a question"),
        ("=pv!route = \"CLARIFY\"", 50, "first ambiguous")], 60),
    # a question (6b): logged on the draw, the step keeps awaiting its decision, nothing is sent to the approver; the draw
    # approval team answers from the draw record (SD Answer Draw Question)
    write(70, "Log the question", [1120, 60],
          inbound("\"QUESTION\"", "pv!interpretationText", "\"A question for the draw approval team; answered from the draw record. Nothing changed; the step still awaits its decision.\"", PHRASE), 2),
    # apply through the one transition, exactly as a UI decision
    {"id": 40, "type": "internal.38", "name": "Apply the decision (sync, source EMAIL)", "coordinates": [1120, 180],
     "connections": conn(41),
     "data": {"inputs": [
         {"name": "Instructions", "value": ""},
         {"name": "drawId", "expression": "pv!applyDrawId"}, {"name": "stepOrder", "expression": "pv!applyStep"},
         {"name": "decision", "expression": "pv!applyDecision"}, {"name": "comment", "expression": "pv!applyComment"},
         {"name": "actor", "expression": "pv!applyActor"}, {"name": "source", "expression": "pv!applySource"},
         {"name": "decisionDate", "expression": "pv!applyDate"},
         {"name": "startNextStepTask", "expression": "pv!applyStartNext"},
         {"name": "pmUUID", "value": APPLY_PM}, {"name": "isAsynchronous", "value": 0}, {"name": "isTransparent", "value": 1},
         {"name": "inheritSecurity", "value": 0}, {"name": "chainsInto", "value": 0}],
         "outputs": [{"name": "outcome", "saveInto": "pv!transitionOutcome"}]},
     "assignment": {"attended": False, "runAs": "DESIGNER"}},
    write(41, "Log reply (decision applied)", [1240, 180],
          inbound("pv!applyDecision", "pv!interpretationText", "\"Applied through SD Apply Draw Approval Decision (source EMAIL): \" & a!defaultValue(pv!transitionOutcome, \"(no outcome)\")", PHRASE), 42),
    # decision receipt (6b): only when the transition recorded the decision (not STALE / ERROR); no reply expected
    xor(42, "Decision recorded?", [1360, 180], [
        ("=or(left(upper(a!defaultValue(pv!transitionOutcome, \"\")), 8) = \"ADVANCED\", left(upper(a!defaultValue(pv!transitionOutcome, \"\")), 8) = \"APPROVED\", "
         "left(upper(a!defaultValue(pv!transitionOutcome, \"\")), 8) = \"REJECTED\")", 43, "recorded")], 2),
    script(43, "Decision receipt (rules)", [1480, 180], [
        ("rule!SD_buildReplyResponseEmail(kind: \"RECEIPT\", context: pv!context, replyText: pv!replyText, decision: pv!applyDecision, outcome: pv!transitionOutcome)",
         "pv!response")], 44),
    send(44, "Send the receipt on the thread", [1600, 180], "=toemailaddress(pv!fromAddress)", 45),
    write(45, "Log receipt sent", [1720, 180], outbound("RECEIPT", "Decision receipt on the reply thread; no reply expected"), 2),
    # first ambiguous reply: clarification on the thread, nothing changed
    script(50, "Clarification (rules)", [1120, 300], [
        ("rule!SD_buildReplyResponseEmail(kind: \"CLARIFICATION\", context: pv!context, replyText: pv!replyText)", "pv!response")], 51),
    write(51, "Log reply (ambiguous)", [1240, 300],
          inbound("\"AMBIGUOUS\"", "pv!interpretationText", "\"Not a clear approval or rejection; clarification requested on the thread. Nothing changed.\"", PHRASE), 52),
    send(52, "Send clarification on the thread", [1360, 300], "=toemailaddress(pv!fromAddress)", 53),
    write(53, "Log clarification sent", [1480, 300], outbound("CLARIFICATION"), 2),
    # exception queue: a person reviews; nothing changes until a human decides in the UI
    write(60, "Log reply (to the exception queue)", [1120, 440],
          inbound("\"EXCEPTION\"", "pv!interpretationText", "pv!exceptionReason & \" Sent to the exception queue (SD Draw Demo Approvers). Nothing changed.\"", PHRASE), 61),
    {"id": 61, "type": "internal.17", "name": "Review email reply", "coordinates": [1240, 440], "connections": conn(62),
     "data": {"customInputs": [
         {"name": "drawId", "type": "INTEGER", "expression": "=pv!applyDrawId"},
         {"name": "stepOrder", "type": "INTEGER", "expression": "=pv!applyStep"},
         {"name": "stepLabel", "type": "TEXT", "expression": "=tostring(pv!stepLabel)"},
         {"name": "fromAddress", "type": "TEXT", "expression": "=tostring(pv!fromAddress)"},
         {"name": "replyText", "type": "TEXT", "expression": "=tostring(pv!replyText)"},
         {"name": "reason", "type": "TEXT", "expression": "=tostring(pv!exceptionReason)"},
         {"name": "reviewNote", "type": "TEXT", "expression": "=a!defaultValue(pv!reviewNote, \"\")"},
         {"name": "reviewedBy", "type": "TEXT", "expression": "=a!defaultValue(pv!reviewedBy, \"\")"}],
         "customOutputs": [{"expression": "ac!reviewNote", "saveInto": "pv!reviewNote"},
                           {"expression": "ac!reviewedBy", "saveInto": "pv!reviewedBy"}]},
     "forms": {"interfaceUuid": EXC_FORM,
               "inputMap": {"drawId": "drawId", "stepOrder": "stepOrder", "stepLabel": "stepLabel", "fromAddress": "fromAddress",
                            "replyText": "replyText", "reason": "reason", "reviewNote": "reviewNote", "reviewedBy": "reviewedBy"}},
     "assignment": {"attended": True, "assignTo": "=cons!SD_DRAW_DEMO_APPROVERS_GROUP", "reassignPrivileges": "REASSIGN_TO_ANY"}},
    write(62, "Log the review", [1360, 440], REVIEW, 2),
    {"id": 2, "type": "core.1", "name": "End", "coordinates": [1860, 300]},
]

# ---------------------------------------------------------------- SD Draw Approval Step: node 8 and the new node 13
step_node8 = {"inputs": [
    {"name": "From", "value": "Custom Sender"},
    {"name": "FromEmailValue", "expression": "=toemailaddress(cons!SD_EMAIL_REPLY_ADDRESS)"},
    {"name": "Email Sender Display Name", "expression": "=tostring(cons!SD_EMAIL_SENDER_NAME)"},
    {"name": "To", "expression": "=pv!assignGroup"},
    {"name": "ReplyTo", "expression": "=toemailaddress(cons!SD_EMAIL_REPLY_ADDRESS)"},
    {"name": "Subject", "expression": "=a!defaultValue(index(pv!email, \"subject\", null), \"Draw approval requested: \" & a!defaultValue(pv!stepLabel, \"step\"))"},
    {"name": "Priority", "value": 3},
    {"name": "IsHTML", "value": 1},
    {"name": "BodyHTML", "expression": "=a!defaultValue(index(pv!email, \"html\", null),\"<p>\" & substitute(a!defaultValue(pv!drawSummary, \"Draw approval requested\"), \"&\", \"&amp;\") & \"<br>\" & a!defaultValue(pv!stepLabel, \"\") & \" is ready for your decision. Open your Appian task list to approve or reject.</p>\")"}]}
STEP_ROW = ("={ rule!SD_newEmailMessage(drawId: pv!drawId, approvalId: tointeger(index(index(pv!state, \"current\", null), \"id\", null)), "
            "stepOrder: pv!stepOrder, direction: \"OUTBOUND\", kind: \"STEP_EMAIL\", fromAddress: cons!SD_EMAIL_REPLY_ADDRESS, "
            "toAddress: tostring(group(pv!assignGroup, \"groupName\")), subject: tostring(index(pv!email, \"subject\", \"\")), "
            "body: \"Approval email for \" & a!defaultValue(pv!stepLabel, \"this step\") & \": the draw's funding detail, budget lines, budget summary, contingency, QIU and approval status (\" & round(a!defaultValue(index(pv!email, \"bytes\", 0), 0) / 1024, 0) & \" KB of HTML). Replies go to the reply address and are read and recorded here.\", "
            "messageAt: now(), outcome: \"SENT\", interpretation: \"\", source: \"EMAIL\", "
            "notes: \"Sent to the step's group from and reply-to the receiver address (process \" & pp!id & \")\", senderName: cons!SD_EMAIL_SENDER_NAME) }")
step_node13 = write(13, "Record step email on the draw", [950, 80], STEP_ROW, 10)
step_node13["name"] = "Record step email on the draw"

subs = {"@MSG@": rt(MSG), "@M_DRAW@": m("drawId"), "@M_APPROVAL@": m("approvalId"), "@M_STEP@": m("stepOrder"),
        "@M_DIRECTION@": m("direction"), "@M_KIND@": m("kind"), "@M_FROM@": m("fromAddress"), "@M_TO@": m("toAddress"),
        "@M_SUBJECT@": m("subject"), "@M_BODY@": m("body"), "@M_AT@": m("messageAt"), "@M_OUTCOME@": m("outcome"),
        "@M_INTERP@": m("interpretation"), "@M_SOURCE@": m("source"), "@M_NOTES@": m("notes")}


def render(obj):
    out = json.dumps(obj)
    for k, v in subs.items():
        out = out.replace(k, v.replace('"', '\\"'))
    assert "@M_" not in out and "@MSG@" not in out
    json.loads(out)
    return out


open("reply_handler_payload.json", "w").write(render({"processVariables": pvs, "nodes": nodes}))
open("step_email_payload.json", "w").write(render({"node8": step_node8, "node13": step_node13}))
print("handler:", len(pvs), "PVs,", len(nodes), "nodes; step email: node 8 data + node 13")

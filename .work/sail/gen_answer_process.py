"""Phase 6b: payload for SD Answer Draw Question — the draw approval team's answer to an approver's pending question,
sent from the draw record (the Emails tab's reply box starts it with a!startProcess). Writes answer_process_payload.json.
No f-strings.

Flow (every unattended node as the designer; the initiator is the specialist, used only for the name on the answer):
  3 pending question + answeredBy (rules) -> 4 checks (SD_getReplyContext for the question's step and the role's
  authorized address) -> 5 the answer email (SD_buildReplyResponseEmail kind ANSWER) -> 6 XOR send?
     yes -> 7 send on the thread to the approver address -> 8 log the ANSWER row (outbound, sender = the specialist)
            -> 10 outcome -> end
     no  -> 9 outcome NOT_SENT (no pending question, the step is no longer awaiting a decision, or an empty answer) -> end
Answering clears the pending state by itself: SD_getPendingQuestion reads an ANSWER row after the question.
"""
import json

pvs = [
    {"name": "drawId", "type": "Number (Integer)", "isParameter": True, "isRequired": True},
    {"name": "answerText", "type": "Text", "isParameter": True},
    {"name": "pending", "type": "Map"}, {"name": "context", "type": "Map"}, {"name": "answeredBy", "type": "Text"},
    {"name": "response", "type": "Map"}, {"name": "outcome", "type": "Text"},
    {"name": "writeError", "type": "Boolean"}, {"name": "writeErrorText", "type": "Text"},
]


def conn(*ts):
    return [{"targetNodeId": t, "activityChained": False} for t in ts]


def script(i, name, xy, outs, to):
    return {"id": i, "type": "internal.16", "name": name, "coordinates": xy, "connections": conn(to),
            "data": {"customOutputs": [{"expression": e, "saveInto": s} for e, s in outs]},
            "assignment": {"attended": False, "runAs": "DESIGNER"}}


SEND_OK = ("=and(a!defaultValue(index(pv!pending, \"pending\", false), false), index(pv!context, \"verdict\", \"\") = \"OK\", "
           "trim(a!defaultValue(pv!answerText, \"\")) <> \"\", a!defaultValue(index(pv!pending, \"approverAddress\", \"\"), \"\") <> \"\")")
ROW = ("={ rule!SD_newEmailMessage(drawId: pv!drawId, approvalId: tointeger(index(pv!pending, \"approvalId\", null)), "
       "stepOrder: tointeger(index(pv!pending, \"stepOrder\", null)), direction: \"OUTBOUND\", kind: \"ANSWER\", "
       "fromAddress: cons!SD_EMAIL_REPLY_ADDRESS, toAddress: tostring(index(pv!pending, \"approverAddress\", \"\")), "
       "subject: tostring(index(pv!response, \"subject\", \"\")), body: tostring(pv!answerText), messageAt: now(), outcome: \"SENT\", "
       "interpretation: \"\", source: \"EMAIL\", "
       "notes: \"Answered from the draw record by \" & pv!answeredBy & \" (\" & tostring(pp!initiator) & \"); sent on the reply thread to the \" & "
       "index(pv!pending, \"role\", \"\") & \"'s address. The approver can decide or ask again by reply.\", senderName: pv!answeredBy) }")

nodes = [
    {"id": 1, "type": "core.0", "name": "Start", "coordinates": [40, 200], "connections": conn(3)},
    script(3, "Pending question (rules)", [160, 200], [
        ("rule!SD_getPendingQuestion(drawId: pv!drawId)", "pv!pending"),
        ("rule!SD_getUserDisplayName(username: tostring(pp!initiator))", "pv!answeredBy")], 4),
    script(4, "Checks (rules)", [280, 200], [
        ("if(a!defaultValue(index(pv!pending, \"pending\", false), false), rule!SD_getReplyContext(drawId: pv!drawId, "
         "stepOrder: index(pv!pending, \"stepOrder\", null), fromAddress: index(pv!pending, \"approverAddress\", \"\")), a!map(verdict: \"NO_QUESTION\"))",
         "pv!context")], 5),
    script(5, "Answer email (rules)", [400, 200], [
        ("rule!SD_buildReplyResponseEmail(kind: \"ANSWER\", context: pv!context, answerText: pv!answerText, answeredBy: pv!answeredBy, "
         "questionText: index(pv!pending, \"question\", \"\"))", "pv!response")], 6),
    {"id": 6, "type": "core.4", "name": "Send?", "coordinates": [520, 200], "connections": conn(7, 9),
     "decision": {"conditions": [{"expression": SEND_OK, "targetNodeId": 7, "label": "a pending question and an answer"}],
                  "defaultPath": 9}},
    {"id": 7, "type": "internal3.sendemail3", "name": "Send the answer on the thread", "coordinates": [640, 120],
     "connections": conn(8),
     "data": {"inputs": [
         {"name": "From", "value": "Custom Sender"},
         {"name": "FromEmailValue", "expression": "=toemailaddress(cons!SD_EMAIL_REPLY_ADDRESS)"},
         {"name": "Email Sender Display Name", "expression": "=tostring(cons!SD_EMAIL_SENDER_NAME)"},
         {"name": "To", "expression": "=toemailaddress(tostring(index(pv!pending, \"approverAddress\", \"\")))"},
         {"name": "ReplyTo", "expression": "=toemailaddress(cons!SD_EMAIL_REPLY_ADDRESS)"},
         {"name": "Subject", "expression": "=tostring(index(pv!response, \"subject\", \"\"))"},
         {"name": "Priority", "value": 3},
         {"name": "IsHTML", "value": 1},
         {"name": "BodyHTML", "expression": "=tostring(index(pv!response, \"html\", \"\"))"}]},
     "assignment": {"attended": False, "runAs": "DESIGNER"}},
    {"id": 8, "type": "internal3.write_records_to_source_23r3", "name": "Log the answer", "coordinates": [760, 120],
     "connections": conn(10),
     "data": {"inputs": [{"name": "Records", "expression": ROW}, {"name": "PauseOnError", "value": 0},
                         {"name": "CaptureEvents", "value": 0}],
              "outputs": [{"name": "ErrorOccurred", "saveInto": "pv!writeError"},
                          {"name": "Error", "saveInto": "pv!writeErrorText"}]},
     "assignment": {"attended": False, "runAs": "DESIGNER"}},
    script(10, "Outcome: sent", [880, 120], [
        ("\"SENT to \" & index(pv!pending, \"approverAddress\", \"\") & if(a!defaultValue(pv!writeError, false), \" (the log write failed: \" & pv!writeErrorText & \")\", \"\")",
         "pv!outcome")], 2),
    script(9, "Outcome: not sent", [640, 300], [
        ("\"NOT_SENT: \" & if(not(a!defaultValue(index(pv!pending, \"pending\", false), false)), \"no pending question on the draw\", "
         "if(index(pv!context, \"verdict\", \"\") <> \"OK\", \"the question's step is \" & index(pv!context, \"verdict\", \"\"), "
         "if(trim(a!defaultValue(pv!answerText, \"\")) = \"\", \"the answer is empty\", \"no approver address for the step\")))", "pv!outcome")], 2),
    {"id": 2, "type": "core.1", "name": "End", "coordinates": [1000, 200]},
]

open("answer_process_payload.json", "w").write(json.dumps({"processVariables": pvs, "nodes": nodes}))
print("answer process:", len(pvs), "PVs,", len(nodes), "nodes")

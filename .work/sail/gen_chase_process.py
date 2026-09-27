"""Phase 6c: payloads for the two velocity process models. No f-strings.

SD Chase Approval Step (params drawId, stepOrder, rung) — started by the step task's escalations (a Send Message Event on
"Approve or reject draw" in SD Draw Approval Step; configured in Designer, the Dev MCP exposes no escalations), or directly
for a test. Every node as the designer.
  3 read the step -> 4 still waiting? no -> 9 stale (nothing sent)
                                    rung SMS -> 20 compose -> 21 live? yes -> 22 Twilio (SD_sendTwilioSms) -> 23 result -> 24 log
                                                                      no  -> 25 log STAGED
                                    else (REMINDER) -> 10 compose -> 11 send to the step's group on the thread -> 12 log
SD Send Chase Digest (no params) — the daily digest to the draw approval team; recurrence is set on its start event in
Designer (the Dev MCP exposes none).
  3 build (SD_buildChaseDigestEmail) -> 4 anything? yes -> 5 send -> 6 done ; no -> 7 nothing to chase
Writes chase_process_payload.json and digest_process_payload.json.
"""
import json

TWILIO_INTEGRATION = "4e3f86a0-edcb-447f-b72f-4690dc2f196b"


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


def send(i, name, xy, to_expr, subject_expr, body_expr, to, reply=True, outs=None):
    # text inputs wrapped (tostring / toemailaddress): a bare "=pv!x" fails the save (supplemental §9)
    inputs = [
        {"name": "From", "value": "Custom Sender"},
        {"name": "FromEmailValue", "expression": "=toemailaddress(cons!SD_EMAIL_REPLY_ADDRESS)"},
        {"name": "Email Sender Display Name", "expression": "=tostring(cons!SD_EMAIL_SENDER_NAME)"},
        {"name": "To", "expression": to_expr},
        {"name": "Subject", "expression": subject_expr},
        {"name": "Priority", "value": 3},
        {"name": "IsHTML", "value": 1},
        {"name": "BodyHTML", "expression": body_expr}]
    if reply:
        inputs.append({"name": "ReplyTo", "expression": "=toemailaddress(cons!SD_EMAIL_REPLY_ADDRESS)"})
    node = {"id": i, "type": "internal3.sendemail3", "name": name, "coordinates": xy, "connections": conn(to),
            "data": {"inputs": inputs}, "assignment": {"attended": False, "runAs": "DESIGNER"}}
    if outs:
        node["data"]["outputs"] = outs
    return node


# ---------------------------------------------------------------- SD Chase Approval Step
CUR = "index(pv!state, \"current\", null)"
LOG = ("={ rule!SD_newEmailMessage(drawId: pv!drawId, approvalId: pv!approvalId, stepOrder: pv!stepOrder, direction: \"OUTBOUND\", "
       "kind: @KIND@, fromAddress: @FROM@, toAddress: @TO@, subject: @SUBJECT@, body: @BODY@, messageAt: now(), outcome: @OUTCOME@, "
       "interpretation: \"\", source: \"ESCALATION\", notes: @NOTES@, senderName: cons!SD_EMAIL_SENDER_NAME, channel: @CHANNEL@, processId: pp!id) }")


def log(kind, frm, to, subject, body, outcome, notes, channel):
    return (LOG.replace("@KIND@", kind).replace("@FROM@", frm).replace("@TO@", to).replace("@SUBJECT@", subject)
            .replace("@BODY@", body).replace("@OUTCOME@", outcome).replace("@NOTES@", notes).replace("@CHANNEL@", channel))


chase_pvs = [
    {"name": "drawId", "type": "Number (Integer)", "isParameter": True},
    {"name": "stepOrder", "type": "Number (Integer)", "isParameter": True},
    {"name": "rung", "type": "Text", "isParameter": True},
    # set by the step task's escalation (Designer: Start event -> Receive Message, process to process, one mapping
    # msg!properties.OriginProcessID -> originProcessId); drawId, stepOrder and rung are then resolved from it (node 6)
    {"name": "originProcessId", "type": "Number (Integer)", "isParameter": True},
    {"name": "state", "type": "Map"}, {"name": "isCurrent", "type": "Boolean"}, {"name": "role", "type": "Text"},
    {"name": "approvalId", "type": "Number (Integer)"}, {"name": "assignGroup", "type": "Group"},
    {"name": "email", "type": "Map"}, {"name": "sms", "type": "Map"}, {"name": "smsLive", "type": "Boolean"},
    {"name": "toMasked", "type": "Text"}, {"name": "smsSuccess", "type": "Boolean"},
    {"name": "smsResult", "type": "Any Type"}, {"name": "smsError", "type": "Any Type"},
    {"name": "smsOutcome", "type": "Text"}, {"name": "smsNotes", "type": "Text"},
    {"name": "outcome", "type": "Text"},
    {"name": "writeError", "type": "Boolean"}, {"name": "writeErrorText", "type": "Text"},
]

REMINDER_NOTES = ("\"Escalation level 1 on the step task: the step email re-sent as a reminder after \" & a!defaultValue(index(pv!email, \"daysWaiting\", 0), 0) & "
                  "\" days waiting (SD_CHASE_AGE_DAYS \" & cons!SD_CHASE_AGE_DAYS & \"); to the step's group, from and reply-to the receiver address, reply token kept\"")
chase_nodes = [
    {"id": 1, "type": "core.0", "name": "Start", "coordinates": [40, 240], "connections": conn(6)},
    # an escalation sends only its origin process id: resolve the draw, the step and the rung from it (a direct start
    # passes drawId, stepOrder and rung and skips the lookup); each output calls the rule itself, because outputs in one
    # script node all see the PVs as they were when the node started
    script(6, "Resolve the escalation (rules)", [100, 360], [
        ("if(a!isNullOrEmpty(pv!drawId), index(rule!SD_resolveChaseTarget(originProcessId: pv!originProcessId), \"drawId\", null), pv!drawId)", "pv!drawId"),
        ("if(a!isNullOrEmpty(pv!stepOrder), index(rule!SD_resolveChaseTarget(originProcessId: pv!originProcessId), \"stepOrder\", null), pv!stepOrder)", "pv!stepOrder"),
        ("if(a!isNullOrEmpty(pv!rung), index(rule!SD_resolveChaseTarget(originProcessId: pv!originProcessId), \"rung\", \"REMINDER\"), pv!rung)", "pv!rung")], 3),
    # a script node's outputs are evaluated against the PV values at node start, so the state is read in node 3 and
    # derived in node 5 (measured 2026-09-26: one node read pv!state as null and every run came back STALE)
    script(3, "Read the step (rules)", [160, 240], [("rule!SD_getDrawState(pv!drawId)", "pv!state")], 5),
    script(5, "Derive the step (rules)", [220, 360], [
        ("and(a!defaultValue(index(pv!state, \"found\", false), false), tostring(a!defaultValue(index(pv!state, \"drawStatus\", \"\"), \"\")) = \"In Progress\", "
         "tointeger(a!defaultValue(index(pv!state, \"currentStep\", -1), -1)) = tointeger(pv!stepOrder), not(a!isNullOrEmpty(" + CUR + ")), "
         "tostring(a!defaultValue(index(" + CUR + ", \"status\", \"\"), \"\")) = \"In Progress\")", "pv!isCurrent"),
        ("tostring(a!defaultValue(index(" + CUR + ", \"role\", \"\"), \"\"))", "pv!role"),
        ("tointeger(index(" + CUR + ", \"id\", null))", "pv!approvalId"),
        ("rule!SD_getDrawApprovalGroup(tostring(a!defaultValue(index(" + CUR + ", \"role\", \"\"), \"\")))", "pv!assignGroup")], 4),
    xor(4, "Still waiting?", [290, 240], [
        ("=not(a!defaultValue(pv!isCurrent, false))", 9, "decided or moved on"),
        ("=upper(a!defaultValue(pv!rung, \"\")) = \"SMS\"", 20, "SMS rung")], 10),
    script(9, "Stale (nothing sent)", [290, 420], [
        ("\"STALE: step \" & pv!stepOrder & \" of draw \" & pv!drawId & \" is no longer awaiting a decision; nothing sent\"", "pv!outcome")], 2),
    # rung 1: the reminder email on the thread
    script(10, "Reminder (rules)", [420, 120], [
        ("rule!SD_buildStepReminderEmail(drawId: pv!drawId, stepOrder: pv!stepOrder)", "pv!email"),
        ("\"REMINDER sent to \" & tostring(group(pv!assignGroup, \"groupName\"))", "pv!outcome")], 11),
    send(11, "Send the reminder on the thread", [550, 120], "=pv!assignGroup",
         "=tostring(index(pv!email, \"subject\", \"\"))", "=tostring(index(pv!email, \"html\", \"\"))", 12),
    write(12, "Log the reminder", [680, 120],
          log("\"REMINDER\"", "cons!SD_EMAIL_REPLY_ADDRESS", "tostring(group(pv!assignGroup, \"groupName\"))",
              "tostring(index(pv!email, \"subject\", \"\"))", "tostring(index(pv!email, \"text\", \"\"))", "\"SENT\"",
              REMINDER_NOTES, "\"EMAIL\""), 2),
    # rung 2: the SMS
    script(20, "SMS (rules)", [420, 360], [
        ("rule!SD_buildStepSms(drawId: pv!drawId, stepOrder: pv!stepOrder)", "pv!sms"),
        ("and(upper(a!defaultValue(cons!SD_SMS_MODE, \"\")) = \"LIVE\", len(stripwith(a!defaultValue(cons!SD_SMS_RECIPIENT, \"\"), \" +-().\")) >= 10, "
         "len(stripwith(a!defaultValue(cons!SD_SMS_RECIPIENT, \"\"), \" +-().0123456789\")) = 0, len(stripwith(a!defaultValue(cons!SD_TWILIO_FROM_NUMBER, \"\"), \" +-().\")) >= 10, "
         "len(stripwith(a!defaultValue(cons!SD_TWILIO_FROM_NUMBER, \"\"), \" +-().0123456789\")) = 0)", "pv!smsLive"),
        ("rule!SD_maskPhone(number: cons!SD_SMS_RECIPIENT)", "pv!toMasked")], 21),
    xor(21, "Send live?", [550, 360], [
        ("=a!defaultValue(pv!smsLive, false)", 22, "Twilio configured and LIVE")], 25),
    {"id": 22, "type": "internal3.integration", "name": "Send the SMS (Twilio)", "coordinates": [680, 300], "connections": conn(23),
     "data": {"inputs": [{"name": "Integration", "value": TWILIO_INTEGRATION},
                         {"name": "to", "expression": "=tostring(cons!SD_SMS_RECIPIENT)"},
                         {"name": "from", "expression": "=tostring(cons!SD_TWILIO_FROM_NUMBER)"},
                         {"name": "body", "expression": "=tostring(index(pv!sms, \"text\", \"\"))"}],
              "outputs": [{"name": "Success", "saveInto": "pv!smsSuccess"}, {"name": "Result", "saveInto": "pv!smsResult"},
                          {"name": "Error", "saveInto": "pv!smsError"}]},
     "assignment": {"attended": False, "runAs": "DESIGNER"}},
    script(23, "SMS result (rules)", [810, 300], [
        ("if(a!defaultValue(pv!smsSuccess, false), \"SENT\", \"FAILED\")", "pv!smsOutcome"),
        ("left(if(a!defaultValue(pv!smsSuccess, false), "
         "\"Escalation level 2 (SMS) sent through Twilio: message \" & tostring(index(index(pv!smsResult, \"body\", null), \"sid\", \"(no sid)\")) & \", status \" & tostring(index(index(pv!smsResult, \"body\", null), \"status\", \"?\")) & \" (HTTP \" & tostring(index(pv!smsResult, \"statusCode\", \"?\")) & \")\", "
         "\"Escalation level 2 (SMS) failed at Twilio: \" & a!defaultValue(tostring(index(index(pv!smsResult, \"body\", null), \"message\", null)), \"\") & if(a!isNullOrEmpty(index(index(pv!smsResult, \"body\", null), \"code\", null)), \"\", \" (Twilio error \" & tostring(index(index(pv!smsResult, \"body\", null), \"code\", null)) & \")\") & \" · \" & tostring(index(pv!smsError, \"detail\", \"\"))), 1000)",
         "pv!smsNotes"),
        ("\"SMS \" & if(a!defaultValue(pv!smsSuccess, false), \"SENT\", \"FAILED\")", "pv!outcome")], 24),
    write(24, "Log the SMS", [940, 300],
          log("\"SMS\"", "tostring(cons!SD_TWILIO_FROM_NUMBER)", "pv!toMasked", "\"Text message\"", "tostring(index(pv!sms, \"text\", \"\"))",
              "pv!smsOutcome", "pv!smsNotes", "\"SMS\""), 2),
    write(25, "Log the SMS (staged)", [680, 460],
          log("\"SMS\"", "\"Twilio (staged)\"", "pv!toMasked", "\"Text message\"", "tostring(index(pv!sms, \"text\", \"\"))", "\"STAGED\"",
              "\"Escalation level 2 (SMS) staged: the text was composed and queued but not sent (SD_SMS_MODE \" & cons!SD_SMS_MODE & if(upper(a!defaultValue(cons!SD_SMS_MODE, \"\")) = \"LIVE\", \"; the Twilio number or the recipient is not set\", \"\") & \")\"",
              "\"SMS\""), 26),
    script(26, "Staged", [810, 460], [("\"SMS STAGED\"", "pv!outcome")], 2),
    {"id": 2, "type": "core.1", "name": "End", "coordinates": [1080, 240]},
]

# ---------------------------------------------------------------- SD Send Chase Digest
digest_pvs = [
    {"name": "digest", "type": "Map"}, {"name": "sentTo", "type": "Text", "multiple": True}, {"name": "outcome", "type": "Text"},
]
digest_nodes = [
    {"id": 1, "type": "core.0", "name": "Start", "coordinates": [40, 200], "connections": conn(3)},
    script(3, "Build the digest (rules)", [160, 200], [("rule!SD_buildChaseDigestEmail(rows: null)", "pv!digest")], 4),
    xor(4, "Anything to chase?", [290, 200], [("=a!defaultValue(index(pv!digest, \"count\", 0), 0) > 0", 5, "yes")], 7),
    send(5, "Send the digest to the draw approval team", [420, 120], "=cons!SD_DRAW_DEMO_APPROVERS_GROUP",
         "=tostring(index(pv!digest, \"subject\", \"\"))", "=tostring(index(pv!digest, \"html\", \"\"))", 6, reply=False,
         outs=[{"name": "ToValidAddresses", "saveInto": "pv!sentTo"}]),
    # Send E-Mail lists no ToValidAddresses for a group recipient (measured 2026-09-26): name the group instead
    script(6, "Sent", [550, 120], [("\"SENT: \" & index(pv!digest, \"count\", 0) & \" draws to the group \" & tostring(group(cons!SD_DRAW_DEMO_APPROVERS_GROUP, \"groupName\")) & \" (Send E-Mail lists no ToValidAddresses for a group recipient)\"", "pv!outcome")], 2),
    script(7, "Nothing to chase", [420, 300], [("\"NOTHING TO CHASE: no email sent\"", "pv!outcome")], 2),
    {"id": 2, "type": "core.1", "name": "End", "coordinates": [700, 200]},
]

json.dump({"processVariables": chase_pvs, "nodes": chase_nodes}, open("chase_process_payload.json", "w"))
json.dump({"processVariables": digest_pvs, "nodes": digest_nodes}, open("digest_process_payload.json", "w"))
print("chase:", len(chase_pvs), "PVs,", len(chase_nodes), "nodes; digest:", len(digest_pvs), "PVs,", len(digest_nodes), "nodes")

import json
RTD="'recordType!{c9d3a947-71aa-4024-879e-363873a12860}SD Draw'"
FD=lambda u,n: f"'recordType!{{c9d3a947-71aa-4024-879e-363873a12860}}SD Draw.fields.{{{u}}}{n}'"
D_id=FD("443829ca-5971-4d31-8fac-ab7a317e509b","id"); D_active=FD("a132be23-f941-4d59-a22c-b57e29900ea6","activeStepProcessId"); D_updated=FD("9b41d47b-ef3a-4ea7-bf7e-0935b9c83393","updatedAt")
DEC_PM="0000f06e-a53d-8000-24ca-7f0000014e7a"; FORM="_a-0000f060-57b9-8000-9c4d-011c48011c48_570715"
cur=lambda k: f"index(index(pv!state, \"current\", null), \"{k}\", \"\")"
nodes=[
 {"id":1,"type":"core.0","name":"Start","coordinates":[50,200],"connections":[{"targetNodeId":3,"activityChained":False}]},
 {"id":2,"type":"core.1","name":"End","coordinates":[1400,200],"connections":[]},
 {"id":3,"type":"internal.16","name":"Read state","coordinates":[200,200],"connections":[{"targetNodeId":4,"activityChained":False}],"assignment":{"attended":False},
  "data":{"customOutputs":[{"expression":"rule!SD_getDrawState(pv!drawId)","saveInto":"pv!state"},{"expression":"pp!id","saveInto":"pv!callerStepProcessId"}]}},
 {"id":4,"type":"internal.16","name":"Derive step","coordinates":[350,200],"connections":[{"targetNodeId":5,"activityChained":False}],"assignment":{"attended":False},
  "data":{"customOutputs":[
   {"expression":"and(a!defaultValue(index(pv!state, \"found\", false), false), tostring(a!defaultValue(index(pv!state, \"drawStatus\", \"\"), \"\")) = \"In Progress\", tointeger(a!defaultValue(index(pv!state, \"currentStep\", -1), -1)) = tointeger(pv!stepOrder), not(a!isNullOrEmpty(index(pv!state, \"current\", null))), tostring(a!defaultValue("+cur("status")+", \"\")) = \"In Progress\")","saveInto":"pv!isCurrent"},
   {"expression":"tostring(a!defaultValue("+cur("role")+", \"\"))","saveInto":"pv!role"},
   {"expression":"tostring(a!defaultValue("+cur("approverName")+", \"\"))","saveInto":"pv!approverName"},
   {"expression":"\"Step \" & pv!stepOrder & \" of \" & cons!SD_DRAW_FINAL_APPROVAL_ORDER & \" - \" & tostring(a!defaultValue("+cur("role")+", \"\")) & \" (\" & tostring(a!defaultValue("+cur("approverName")+", \"\")) & \")\"","saveInto":"pv!stepLabel"},
   {"expression":"\"Draw #\" & a!defaultValue(index(pv!state, \"drawNumber\", pv!drawId), pv!drawId) & \" - \" & a!defaultValue(index(pv!state, \"investmentName\", \"\"), \"\") & \" - \" & a!defaultValue(index(pv!state, \"fundName\", \"\"), \"\") & \" - \" & text(round(todecimal(a!defaultValue(index(pv!state, \"amount\", 0), 0)), 2), \"$#,###,###,##0.00\")","saveInto":"pv!drawSummary"},
   {"expression":"rule!SD_getDrawApprovalGroup(tostring(a!defaultValue("+cur("role")+", \"\")))","saveInto":"pv!assignGroup"}]}},
 {"id":5,"type":"core.4","name":"Step is current?","coordinates":[500,200],"connections":[{"targetNodeId":6,"activityChained":False},{"targetNodeId":7,"activityChained":False}],
  "decision":{"conditions":[{"expression":"=not(a!defaultValue(pv!isCurrent, false))","targetNodeId":6}],"defaultPath":7}},
 {"id":6,"type":"internal.16","name":"Mark stale","coordinates":[500,380],"connections":[{"targetNodeId":2,"activityChained":False}],"assignment":{"attended":False},
  "data":{"customOutputs":[{"expression":"\"STALE: step \" & pv!stepOrder & \" is not the current step of draw \" & pv!drawId","saveInto":"pv!outcome"}]}},
 {"id":7,"type":"internal3.write_records_to_source_23r3","name":"Register step task on draw","coordinates":[650,200],"connections":[{"targetNodeId":8,"activityChained":False},{"targetNodeId":9,"activityChained":False}],"assignment":{"attended":False},
  "data":{"inputs":[{"name":"Records","expression":f"={{ {RTD}({D_id}: pv!drawId, {D_active}: pp!id, {D_updated}: now()) }}"},{"name":"PauseOnError","value":False},{"name":"CaptureEvents","value":False}],
          "outputs":[{"name":"ErrorOccurred","saveInto":"pv!registerError"}]}},
 {"id":8,"type":"internal3.sendemail3","name":"Step notification (placeholder)","coordinates":[800,80],"connections":[{"targetNodeId":10,"activityChained":False}],"assignment":{"attended":False},
  "data":{"inputs":[{"name":"From","value":"Process Model"},{"name":"To","expression":"=pv!assignGroup"},
   {"name":"Subject","expression":"=\"[Placeholder] Draw approval requested: \" & a!defaultValue(pv!stepLabel, \"step\")"},
   {"name":"Priority","value":3},{"name":"IsHTML","value":True},
   {"name":"BodyHTML","expression":"=a!defaultValue(\"PLACEHOLDER - the real approval email layout is Phase 4.<br>\" & substitute(a!defaultValue(pv!drawSummary, \"\"), \"&\", \"&amp;\") & \"<br>\" & a!defaultValue(pv!stepLabel, \"\") & \" is ready for your decision. Open your Appian task list to approve or reject.\", \"Draw approval requested.\")"}]}},
 {"id":10,"type":"core.1","name":"Notified","coordinates":[950,80],"connections":[]},
 {"id":9,"type":"internal.17","name":"Approve or reject draw","coordinates":[800,200],"connections":[{"targetNodeId":11,"activityChained":False}],
  "assignment":{"attended":True,"assignTo":"pv!assignGroup"},
  "forms":{"interfaceUuid":FORM,"inputMap":{"drawSummary":"drawSummary","stepLabel":"stepLabel","decision":"decision","decisionComment":"decisionComment","actor":"actor"}},
  "data":{"customInputs":[
    {"name":"drawSummary","type":"Text","expression":"=pv!drawSummary"},
    {"name":"stepLabel","type":"Text","expression":"=pv!stepLabel"},
    {"name":"decision","type":"Text","expression":"=a!defaultValue(pv!decision, \"NONE\")"},
    {"name":"decisionComment","type":"Text","expression":"=a!defaultValue(pv!decisionComment, \"-\")"},
    {"name":"actor","type":"Text","expression":"=a!defaultValue(pv!actor, \"-\")"}],
   "customOutputs":[{"expression":"ac!decision","saveInto":"pv!decision"},{"expression":"ac!decisionComment","saveInto":"pv!decisionComment"},{"expression":"ac!actor","saveInto":"pv!actor"}]}},
 {"id":11,"type":"internal.38","name":"Apply decision (sync)","coordinates":[950,200],"connections":[{"targetNodeId":12,"activityChained":False}],"assignment":{"attended":False},
  "data":{"inputs":[{"name":"pmUUID","value":DEC_PM},{"name":"isAsynchronous","value":False},{"name":"isTransparent","value":True},{"name":"inheritSecurity","value":False},{"name":"chainsInto","value":False},
   {"name":"drawId","expression":"pv!drawId"},{"name":"stepOrder","expression":"pv!stepOrder"},{"name":"decision","expression":"pv!decision"},{"name":"comment","expression":"pv!decisionComment"},
   {"name":"actor","expression":"pv!actor"},{"name":"source","expression":"pv!source"},{"name":"callerStepProcessId","expression":"pv!callerStepProcessId"},{"name":"startNextStepTask","expression":"pv!startNextStepTask"}],
   "outputs":[{"name":"outcome","saveInto":"pv!decisionOutcome"}]}},
 {"id":12,"type":"internal.16","name":"Mark decided","coordinates":[1100,200],"connections":[{"targetNodeId":2,"activityChained":False}],"assignment":{"attended":False},
  "data":{"customOutputs":[{"expression":"\"DECIDED \" & a!defaultValue(pv!decision, \"?\") & \" -> \" & a!defaultValue(pv!decisionOutcome, \"(no outcome)\")","saveInto":"pv!outcome"}]}},
]
ids={n["id"] for n in nodes}
for n in nodes:
    for c in n["connections"]: assert c["targetNodeId"] in ids
def bal(s):
    p=b=0
    for ch in s:
        p+= ch=="("; p-= ch==")"; b+= ch=="{"; b-= ch=="}"; assert p>=0 and b>=0, s[:60]
    assert p==0 and b==0, s[:60]
for n in nodes:
    for blk in ("inputs","customInputs","customOutputs"):
        for i in n.get("data",{}).get(blk,[]) or []:
            if i.get("expression"): bal(i["expression"])
    for c in n.get("decision",{}).get("conditions",[]): bal(c["expression"])
print(json.dumps(nodes,separators=(",",":")))

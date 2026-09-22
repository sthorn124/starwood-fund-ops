import json
RTA="'recordType!{02c207d5-c725-4d11-bf40-b33573e87ffa}SD Draw Approval'"
FA=lambda u,n: f"'recordType!{{02c207d5-c725-4d11-bf40-b33573e87ffa}}SD Draw Approval.fields.{{{u}}}{n}'"
RTD="'recordType!{c9d3a947-71aa-4024-879e-363873a12860}SD Draw'"
FD=lambda u,n: f"'recordType!{{c9d3a947-71aa-4024-879e-363873a12860}}SD Draw.fields.{{{u}}}{n}'"
A_id=FA("69abcdf2-55da-48dc-8cc4-794b5d5e0042","id"); A_status=FA("4c1bf7fb-0736-4c9a-946e-99f6989ac83a","status")
A_date=FA("a6a03063-3b14-4f00-8cab-b5d10602405e","decisionDate"); A_comments=FA("3c1aae42-13a1-4c13-894a-9fdef20f7fce","comments")
A_actedBy=FA("2e6ad17e-66f3-4ab2-97b6-c21ee10dd203","actedBy"); A_source=FA("6597627c-af44-4119-9b92-286179df119d","decisionSource")
D_id=FD("443829ca-5971-4d31-8fac-ab7a317e509b","id"); D_status=FD("e63818ec-ea02-40a0-bfdd-2c14b760dc2c","status")
D_step=FD("51d3ea43-572b-4052-a36d-369d39f8d05d","currentStep"); D_active=FD("a132be23-f941-4d59-a22c-b57e29900ea6","activeStepProcessId")
D_updated=FD("9b41d47b-ef3a-4ea7-bf7e-0935b9c83393","updatedAt"); D_treasury=FD("f98054f6-7140-4046-b3d0-2be2f78e6873","treasuryNotifiedAt")
STEP_PM="0000f06e-a547-8000-24cc-7f0000014e7a"

def wr(id_,name,xy,records,errFlag,conn):
    return {"id":id_,"type":"internal3.write_records_to_source_23r3","name":name,"coordinates":xy,
     "connections":[{"targetNodeId":conn,"activityChained":False}],"assignment":{"attended":False},
     "data":{"inputs":[{"name":"Records","expression":"="+records},{"name":"PauseOnError","value":False},{"name":"CaptureEvents","value":False}],
             "outputs":[{"name":"ErrorOccurred","saveInto":"pv!"+errFlag},{"name":"Error","saveInto":"pv!errorText"}]}}
def script(id_,name,xy,outs,conn):
    return {"id":id_,"type":"internal.16","name":name,"coordinates":xy,"connections":[{"targetNodeId":conn,"activityChained":False}],
     "assignment":{"attended":False},"data":{"customOutputs":[{"expression":e,"saveInto":s} for e,s in outs]}}
def xor(id_,name,xy,conds,default):
    return {"id":id_,"type":"core.4","name":name,"coordinates":xy,
     "connections":[{"targetNodeId":t,"activityChained":False} for t in sorted({c[1] for c in conds}|{default})],
     "decision":{"conditions":[{"expression":e,"targetNodeId":t} for e,t in conds],"defaultPath":default}}

stepRow=(f"{{ {RTA}({A_id}: pv!currentApprovalId, {A_status}: if(a!defaultValue(pv!isApprove, false), \"Approved\", \"Rejected\"), "
         f"{A_date}: pv!effectiveDate, {A_comments}: a!defaultValue(pv!comment, \"\"), {A_actedBy}: a!defaultValue(pv!actor, \"\"), {A_source}: a!defaultValue(pv!source, \"\")) }}")
rejectDraw=f"{{ {RTD}({D_id}: pv!drawId, {D_status}: \"Rejected\", {D_active}: null, {D_updated}: now()) }}"
approveDraw=f"{{ {RTD}({D_id}: pv!drawId, {D_status}: \"Approved\", {D_active}: null, {D_updated}: now()) }}"
nextRow=f"{{ {RTA}({A_id}: pv!nextApprovalId, {A_status}: \"In Progress\") }}"
advanceDraw=f"{{ {RTD}({D_id}: pv!drawId, {D_step}: pv!nextOrder, {D_active}: null, {D_updated}: now()) }}"
treasuryDraw=f"{{ {RTD}({D_id}: pv!drawId, {D_treasury}: now()) }}"

nodes=[
 {"id":1,"type":"core.0","name":"Start","coordinates":[50,200],"connections":[{"targetNodeId":3,"activityChained":False}]},
 {"id":2,"type":"core.1","name":"End","coordinates":[2450,200],"connections":[]},
 script(3,"Read draw state",[200,200],[("rule!SD_getDrawState(pv!drawId)","pv!state")],4),
 script(4,"Derive routing",[350,200],[
   ("and(a!defaultValue(index(pv!state, \"found\", false), false), tostring(a!defaultValue(index(pv!state, \"drawStatus\", \"\"), \"\")) = \"In Progress\", tointeger(a!defaultValue(index(pv!state, \"currentStep\", -1), -1)) = tointeger(pv!stepOrder), not(a!isNullOrEmpty(index(pv!state, \"current\", null))), tostring(a!defaultValue(index(index(pv!state, \"current\", null), \"status\", \"\"), \"\")) = \"In Progress\", or(upper(a!defaultValue(pv!decision, \"\")) = \"APPROVE\", upper(a!defaultValue(pv!decision, \"\")) = \"REJECT\"))","pv!isValid"),
   ("tointeger(index(index(pv!state, \"current\", null), \"id\", null))","pv!currentApprovalId"),
   ("tointeger(index(index(pv!state, \"next\", null), \"id\", null))","pv!nextApprovalId"),
   ("tointeger(index(index(pv!state, \"next\", null), \"approvalOrder\", null))","pv!nextOrder"),
   ("or(tointeger(pv!stepOrder) >= cons!SD_DRAW_FINAL_APPROVAL_ORDER, a!isNullOrEmpty(index(pv!state, \"next\", null)))","pv!isFinal"),
   ("tointeger(index(pv!state, \"activeStepProcessId\", null))","pv!activeStepProcessId"),
   ("a!localVariables(local!active: tointeger(index(pv!state, \"activeStepProcessId\", null)), and(not(a!isNullOrEmpty(local!active)), or(a!isNullOrEmpty(pv!callerStepProcessId), tointeger(pv!callerStepProcessId) <> local!active)))","pv!supersede"),
   ("upper(a!defaultValue(pv!decision, \"\")) = \"APPROVE\"","pv!isApprove"),
   ("a!defaultValue(pv!decisionDate, now())","pv!effectiveDate")],5),
 xor(5,"Valid decision?",[500,200],[("=not(a!defaultValue(pv!isValid, false))",6)],7),
 script(6,"Mark stale",[500,380],[("\"STALE: draw \" & pv!drawId & \" is \" & a!defaultValue(index(pv!state, \"drawStatus\", \"?\"), \"?\") & \" at step \" & a!defaultValue(index(pv!state, \"currentStep\", \"?\"), \"?\") & \"; decision asked for step \" & pv!stepOrder","pv!outcome")],2),
 xor(7,"Supersede open step task?",[650,200],[("=a!defaultValue(pv!supersede, false)",8)],9),
 {"id":8,"type":"appian.system.smart-services.cancel-process-2","name":"Cancel superseded step task","coordinates":[650,80],"connections":[{"targetNodeId":9,"activityChained":False}],
  "assignment":{"attended":False},"data":{"inputs":[{"name":"ProcessId","expression":"=pv!activeStepProcessId"}],"outputs":[{"name":"alreadyClosed","saveInto":"pv!supersededAlreadyClosed"}]}},
 wr(9,"Write step decision",[800,200],stepRow,"stepWriteError",10),
 xor(10,"Step write OK?",[950,200],[("=a!defaultValue(pv!stepWriteError, false)",11)],12),
 script(11,"Mark error",[950,380],[("\"ERROR: \" & a!defaultValue(pv!errorText, \"(no detail)\")","pv!outcome")],2),
 xor(12,"Approve or reject?",[1100,200],[("=not(a!defaultValue(pv!isApprove, false))",13)],16),
 wr(13,"Reject draw",[1100,380],rejectDraw,"drawWriteError",14),
 xor(14,"Reject write OK?",[1250,380],[("=a!defaultValue(pv!drawWriteError, false)",11)],15),
 script(15,"Mark rejected",[1400,380],[("\"REJECTED at step \" & pv!stepOrder","pv!outcome")],2),
 xor(16,"Final step?",[1250,200],[("=a!defaultValue(pv!isFinal, false)",17)],22),
 wr(17,"Approve draw",[1250,80],approveDraw,"drawWriteError",18),
 xor(18,"Approve write OK?",[1400,80],[("=a!defaultValue(pv!drawWriteError, false)",11)],19),
 script(19,"Mark approved",[1550,80],[("\"APPROVED\"","pv!outcome"),
   ("\"PLACEHOLDER - real notification content is Phase 6.<br>Draw #\" & a!defaultValue(index(pv!state, \"drawNumber\", pv!drawId), pv!drawId) & \" (\" & substitute(a!defaultValue(index(pv!state, \"investmentName\", \"\"), \"\"), \"&\", \"&amp;\") & \", \" & substitute(a!defaultValue(index(pv!state, \"fundName\", \"\"), \"\"), \"&\", \"&amp;\") & \") is fully approved.<br>Amount: \" & text(round(todecimal(a!defaultValue(index(pv!state, \"amount\", 0), 0)), 2), \"$#,###,###,##0.00\") & \"<br>Please execute the cash payment.<br>Final approval recorded by \" & a!defaultValue(pv!actor, \"(unknown)\") & \" via \" & a!defaultValue(pv!source, \"(unknown)\") & \" at \" & text(pv!effectiveDate, \"yyyy-MM-dd HH:mm\") & \".\"","pv!treasuryBody")],20),
 {"id":20,"type":"internal3.sendemail3","name":"Treasury notification (placeholder)","coordinates":[1700,80],"connections":[{"targetNodeId":21,"activityChained":False}],
  "assignment":{"attended":False},"data":{"inputs":[{"name":"From","value":"Process Model"},{"name":"To","expression":"=cons!SD_DRAW_TREASURY_RECIPIENT"},
   {"name":"Subject","expression":"=\"[Placeholder] Draw #\" & a!defaultValue(index(pv!state, \"drawNumber\", pv!drawId), pv!drawId) & \" approved - execute cash payment\""},
   {"name":"Priority","value":3},{"name":"IsHTML","value":True},{"name":"BodyHTML","expression":"=a!defaultValue(pv!treasuryBody, \"Draw approved. Execute cash payment.\")"}]}},
 wr(21,"Record treasury notification",[1850,80],treasuryDraw,"drawWriteError",2),
 wr(22,"Activate next step",[1400,200],nextRow,"nextWriteError",23),
 xor(23,"Next write OK?",[1550,200],[("=a!defaultValue(pv!nextWriteError, false)",11)],24),
 wr(24,"Advance draw",[1700,200],advanceDraw,"drawWriteError",25),
 xor(25,"Advance write OK?",[1850,200],[("=a!defaultValue(pv!drawWriteError, false)",11)],26),
 xor(26,"Start next step task?",[2000,200],[("=a!defaultValue(pv!startNextStepTask, true)",27)],28),
 {"id":27,"type":"internal.38","name":"Start next step task (async)","coordinates":[2000,80],"connections":[{"targetNodeId":28,"activityChained":False}],
  "assignment":{"attended":False},"data":{"inputs":[{"name":"pmUUID","value":STEP_PM},{"name":"isAsynchronous","value":True},{"name":"isTransparent","value":True},{"name":"inheritSecurity","value":False},{"name":"chainsInto","value":False},
   {"name":"drawId","expression":"pv!drawId"},{"name":"stepOrder","expression":"pv!nextOrder"}]}},
 script(28,"Mark advanced",[2150,200],[("\"ADVANCED to step \" & pv!nextOrder","pv!outcome")],2),
]
# sanity: every connection target exists, every SAIL string has balanced brackets
ids={n["id"] for n in nodes}
for n in nodes:
    for c in n["connections"]: assert c["targetNodeId"] in ids,(n["id"],c)
    if "decision" in n:
        for c in n["decision"]["conditions"]: assert c["targetNodeId"] in ids
        assert n["decision"]["defaultPath"] in ids
def bal(s):
    d={"(":0,"{":0}; 
    for ch in s:
        if ch=="(": d["("]+=1
        if ch==")": d["("]-=1
        if ch=="{": d["{"]+=1
        if ch=="}": d["{"]-=1
        assert d["("]>=0 and d["{"]>=0, s[:80]
    assert d["("]==0 and d["{"]==0, s[:80]
for s in json.dumps(nodes).split('"'):
    pass
import re
for n in nodes:
    for blk in ("inputs","customOutputs","outputs"):
        for i in n.get("data",{}).get(blk,[]) or []:
            if i.get("expression"): bal(i["expression"])
    for c in n.get("decision",{}).get("conditions",[]): bal(c["expression"])
json.dump(nodes,open("decision_nodes.json","w"),indent=1)
print("nodes:",len(nodes),"ok")

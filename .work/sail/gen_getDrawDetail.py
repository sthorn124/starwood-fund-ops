from refs import *
d = lambda n: fld(DRAW, n)
fields = ["id","drawNumber","amount","cashEquityNeeded","fundingDate","drawType","purpose","budgetStatus",
          "overBudgetReason","generalComments","contingencyExplanation","status","currentStep","activeStepProcessId",
          "createdAt","updatedAt","treasuryNotifiedAt","receivedDate","submittedBy","investmentId","extractionInstanceId","ingestionProcessId",
          "ingestionFailureReason","ingestionComparison","corroborationSummary","corroborationState"]
sel = ",\n          ".join(d(n) for n in fields)
sel += ",\n          " + rel_fld(DRAW,"investment",INV,"investmentName")
sel += ",\n          " + rel_fld(DRAW,"investment",INV,"investmentDescription")
sel += ",\n          " + rel2_fld(DRAW,"investment","fund",FUND,"fundName")
out = ",\n    ".join(f"{n}: if(local!found, local!draw[{d(n)}], null)" for n in fields)
sail = f"""/* Draw approval: everything a draw view or list row needs about one draw, in one read.
   Header fields, investment and fund names, the routing state (rule!SD_getDrawState), the viewer's
   relationship to the current step (viewerIsAssignee: in the step's group; awaitingViewer: and a task is
   open for it, which is what "Awaiting My Action" and the action strip mean), and the day counts the mockups show as "in N days" / "N days".
   Day counts are computed from today() and clamp at 0; nothing here is hard-coded to the demo dates. */
a!localVariables(
  local!hasId: not(a!isNullOrEmpty(ri!drawId)),
  local!draw: if(
    not(local!hasId),
    null,
    index(
      a!queryRecordType(
        recordType: {rt(DRAW)},
        fields: {{
          {sel}
        }},
        filters: a!queryFilter(
          field: {d("id")},
          operator: "=",
          value: ri!drawId
        ),
        pagingInfo: a!pagingInfo(startIndex: 1, batchSize: 1)
      ).data,
      1,
      null
    )
  ),
  local!found: not(a!isNullOrEmpty(local!draw)),
  local!state: if(local!found, rule!SD_getDrawState(drawId: ri!drawId), null),
  local!approvals: if(local!found, a!defaultValue(index(local!state, "approvals", {{}}), {{}}), {{}}),
  local!current: if(local!found, index(local!state, "current", null), null),
  local!next: if(local!found, index(local!state, "next", null), null),
  local!statusText: if(local!found, tostring(a!defaultValue(local!draw[{d("status")}], "")), ""),
  local!inProgress: and(
    local!statusText = "In Progress",
    not(a!isNullOrEmpty(local!current)),
    tostring(a!defaultValue(index(local!current, "status", ""), "")) = "In Progress"
  ),
  /* an Ingesting draw (Phase 3) is the accountant group's: its reconciliation task is open on the ingestion process,
     whose id the shell carries in ingestionProcessId (activeStepProcessId stays free for the approval steps) */
  local!ingesting: and(local!found, local!statusText = "Ingesting"),
  /* an Ingestion Failed draw (Phase 5) has no step and no task: nobody's to act on, whatever process ids it carries */
  local!ingestionFailed: and(local!found, local!statusText = "Ingestion Failed"),
  local!currentGroup: if(
    local!inProgress,
    rule!SD_getDrawApprovalGroup(role: index(local!current, "role", "")),
    if(local!ingesting, cons!SD_DRAW_DEMO_APPROVERS_GROUP, null)
  ),
  local!viewerIsAssignee: if(
    or(local!ingestionFailed, a!isNullOrEmpty(local!currentGroup)),
    false,
    a!defaultValue(a!isUserMemberOfGroup(username: loggedInUser(), groups: local!currentGroup), false)
  ),
  local!activeProcess: if(local!found, if(local!ingesting, local!draw[{d("ingestionProcessId")}], local!draw[{d("activeStepProcessId")}]), null),
  local!openTaskId: if(
    and(local!viewerIsAssignee, not(a!isNullOrEmpty(local!activeProcess))),
    rule!SD_getOpenTaskId(processId: tointeger(local!activeProcess)),
    null
  ),
  local!fundingDate: if(local!found, local!draw[{d("fundingDate")}], null),
  local!activatedAt: if(a!isNullOrEmpty(local!current), null, index(local!current, "activatedAt", null)),
  /* counted with wherecontains: an a!forEach that returns {{}} for skipped items yields N nulls when every item is skipped */
  local!approvedCount: if(
    a!isNullOrEmpty(local!approvals),
    0,
    count(
      wherecontains(
        "Approved",
        a!forEach(items: local!approvals, expression: tostring(a!defaultValue(index(fv!item, "status", ""), "")))
      )
    )
  ),
  a!map(
    found: local!found,
    drawId: ri!drawId,
    {out},
    investmentName: if(local!found, local!draw[{rel_fld(DRAW,"investment",INV,"investmentName")}], null),
    investmentDescription: if(local!found, local!draw[{rel_fld(DRAW,"investment",INV,"investmentDescription")}], null),
    fundName: if(local!found, local!draw[{rel2_fld(DRAW,"investment","fund",FUND,"fundName")}], null),
    approvals: local!approvals,
    current: local!current,
    next: local!next,
    totalSteps: count(local!approvals),
    approvedCount: local!approvedCount,
    inProgress: local!inProgress,
    ingesting: local!ingesting,
    ingestionFailed: local!ingestionFailed,
    currentRole: if(local!ingesting, "Accountant reconciliation", if(a!isNullOrEmpty(local!current), null, index(local!current, "role", null))),
    currentApprover: if(a!isNullOrEmpty(local!current), null, index(local!current, "approverName", null)),
    currentActivatedAt: if(local!ingesting, local!draw[{d("receivedDate")}], local!activatedAt),
    currentGroup: local!currentGroup,
    viewerIsAssignee: local!viewerIsAssignee,
    openTaskId: local!openTaskId,
    awaitingViewer: and(local!viewerIsAssignee, not(a!isNullOrEmpty(local!openTaskId))),
    daysToFunding: if(a!isNullOrEmpty(local!fundingDate), null, tointeger(todate(local!fundingDate) - today())),
    daysAtStep: if(
      local!ingesting,
      if(a!isNullOrEmpty(local!draw[{d("receivedDate")}]), 0, max(0, tointeger(today() - todate(local!draw[{d("receivedDate")}])))),
      if(a!isNullOrEmpty(local!activatedAt), null, max(0, tointeger(today() - todate(local!activatedAt))))
    )
  )
)
"""
open("SD_getDrawDetail.sail","w").write(sail)
print("written", len(sail))

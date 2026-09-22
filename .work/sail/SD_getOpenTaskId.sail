/* Draw approval: id of the open task in a step process, for a!processTaskLink.
   Reads the platform's "Current Tasks for Process" system report (System Reports > Task Reports),
   whose document id is held in cons!SD_CURRENT_TASKS_FOR_PROCESS_REPORT_ID (re-verify per instance).
   Column dp0 is the task id; column c2 is the task status. Only a live task counts — status 0 (Assigned) or
   1 (Accepted): the report also returns a cancelled step's task to an administrator, as 7 (Aborted) with no
   assignees (measured 2026-09-22), and that must never read as actionable. Returns null when the process id is
   null or no live task is open. */
if(
  a!isNullOrEmpty(ri!processId),
  null,
  a!localVariables(
    local!rows: a!queryProcessAnalytics(
      report: todocument(cons!SD_CURRENT_TASKS_FOR_PROCESS_REPORT_ID),
      query: a!query(pagingInfo: a!pagingInfo(startIndex: 1, batchSize: 10)),
      contextProcessIds: {tointeger(ri!processId)}
    ).data,
    local!live: if(
      a!isNullOrEmpty(local!rows),
      {},
      index(
        local!rows,
        wherecontains(true, a!forEach(items: local!rows, expression: contains({0, 1}, tointeger(a!defaultValue(index(fv!item, "c2", -1), -1))))),
        {}
      )
    ),
    if(
      a!isNullOrEmpty(local!live),
      null,
      tointeger(index(index(local!live, 1, null), "dp0", null))
    )
  )
)

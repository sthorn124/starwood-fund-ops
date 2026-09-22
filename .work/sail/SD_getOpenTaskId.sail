/* Draw approval: id of the open task in a step process, for a!processTaskLink.
   Reads the platform's "Current Tasks for Process" system report (System Reports > Task Reports),
   whose document id is held in cons!SD_CURRENT_TASKS_FOR_PROCESS_REPORT_ID (re-verify per instance).
   Column dp0 is the task id. Returns null when the process id is null or no task is open. */
if(
  a!isNullOrEmpty(ri!processId),
  null,
  a!localVariables(
    local!rows: a!queryProcessAnalytics(
      report: todocument(cons!SD_CURRENT_TASKS_FOR_PROCESS_REPORT_ID),
      query: a!query(pagingInfo: a!pagingInfo(startIndex: 1, batchSize: 1)),
      contextProcessIds: {tointeger(ri!processId)}
    ).data,
    if(
      a!isNullOrEmpty(local!rows),
      null,
      tointeger(index(index(local!rows, 1, null), "dp0", null))
    )
  )
)

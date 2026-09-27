/* Draw approval (fix session 2026-09-27): may this draw be staged for approval? One test, used by the Draws page's
   picker and re-checked by SD Stage Draw for Approval before it writes anything. ri!detail is an SD_getDrawDetail map.
   Eligible: an ingested draw (not a seeded draw, not a named demo specimen), In Progress at step 1 or 2, with a live chain:
   a registered step process that holds an open task. The accelerator clears activeStepProcessId while it runs and only
   the launcher sets it again, so a draw in mid-acceleration has none and is refused; a draw past step 2 is refused. */
a!localVariables(
  local!id: tointeger(a!defaultValue(index(ri!detail, "id", null), 0)),
  local!step: tointeger(a!defaultValue(index(ri!detail, "currentStep", null), 0)),
  and(
    a!defaultValue(index(ri!detail, "found", false), false),
    local!id > 0,
    not(contains(tointeger(cons!SD_SEED_DRAW_IDS), local!id)),
    not(contains(tointeger(cons!SD_DEMO_KEEP_DRAW_IDS), local!id)),
    tostring(a!defaultValue(index(ri!detail, "status", ""), "")) = "In Progress",
    or(local!step = 1, local!step = 2),
    not(a!isNullOrEmpty(index(ri!detail, "activeStepProcessId", null))),
    /* the open task is read from the task report directly: the detail map's openTaskId is viewer-aware (filled only
       for members of the step's group), and this test must not depend on who is looking (measured: inside a process
       the detail's openTaskId read null for a live task) */
    not(a!isNullOrEmpty(rule!SD_getOpenTaskId(processId: index(ri!detail, "activeStepProcessId", null))))
  )
)

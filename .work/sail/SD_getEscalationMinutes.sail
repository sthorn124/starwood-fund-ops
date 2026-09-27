/* Draw approval (Phase 6c): minutes until an escalation level on the step task fires. The step task (SD Draw Approval
   Step, "Approve or reject draw") carries two escalation levels, configured in Designer (the Dev MCP exposes no
   escalations): level 1 re-sends the step email as a reminder once the step has waited SD_CHASE_AGE_DAYS; level 2 is the
   SMS rung at SD_SMS_AGE_DAYS. Appian starts a level's timer when the level before it fires, so level 2 waits the
   difference. SD_ESCALATION_TEST_MINUTES above 0 replaces both waits (a test on a throwaway draw; restore it to 0). */
a!localVariables(
  local!test: tointeger(a!defaultValue(cons!SD_ESCALATION_TEST_MINUTES, 0)),
  local!level: tointeger(a!defaultValue(ri!level, 1)),
  if(
    local!test > 0,
    local!test,
    if(
      local!level = 2,
      tointeger(max(1, cons!SD_SMS_AGE_DAYS - cons!SD_CHASE_AGE_DAYS)) * 1440,
      tointeger(max(1, cons!SD_CHASE_AGE_DAYS)) * 1440
    )
  )
)

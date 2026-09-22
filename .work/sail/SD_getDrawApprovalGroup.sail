/* Draw approval: the group that receives the task for a chain role.
   Asset Manager and CEO have dedicated groups; every other role goes to the demo catch-all. */
a!match(
  value: trim(a!defaultValue(ri!role, "")),
  equals: "Asset Manager",
  then: cons!SD_DRAW_ASSET_MANAGER_GROUP,
  equals: "CEO",
  then: cons!SD_DRAW_CEO_GROUP,
  default: cons!SD_DRAW_DEMO_APPROVERS_GROUP
)

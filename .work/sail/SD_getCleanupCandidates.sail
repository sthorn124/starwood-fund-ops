/* Draw approval (fix session 2026-09-27): what Clean Up Old Runs would remove — every draw that is neither seeded
   (SD_SEED_DRAW_IDS: the seeded list history and its world) nor a named demo specimen (SD_DEMO_KEEP_DRAW_IDS), oldest
   first. Each item: drawId, drawNumber, status, label ("#81 · In Progress", "Not loaded (Ingestion Failed)", "New draw
   (Ingesting)"). ri!rows takes the Draws page's rows; empty, the rule reads them itself. */
a!localVariables(
  local!all: if(a!isNullOrEmpty(ri!rows), rule!SD_getDrawListRows(), ri!rows),
  local!flags: if(
    a!isNullOrEmpty(local!all),
    {},
    a!forEach(
      items: local!all,
      expression: a!localVariables(
        local!id: tointeger(a!defaultValue(fv!item.id, 0)),
        and(
          local!id > 0,
          not(contains(tointeger(cons!SD_SEED_DRAW_IDS), local!id)),
          not(contains(tointeger(cons!SD_DEMO_KEEP_DRAW_IDS), local!id))
        )
      )
    )
  ),
  local!picked: if(
    or(a!isNullOrEmpty(local!flags), not(contains(local!flags, true))),
    {},
    index(local!all, wherecontains(true, local!flags), {})
  ),
  local!mapped: if(
    a!isNullOrEmpty(local!picked),
    {},
    a!forEach(
      items: local!picked,
      expression: a!localVariables(
        local!status: tostring(a!defaultValue(fv!item.status, "")),
        a!map(
          drawId: tointeger(fv!item.id),
          drawNumber: fv!item.drawNumber,
          status: local!status,
          label: if(
            a!isNullOrEmpty(fv!item.drawNumber),
            if(local!status = "Ingestion Failed", "Not loaded", "New draw") & " (draw " & fv!item.id & ", " & local!status & ")",
            "#" & fv!item.drawNumber & " (" & local!status & ")"
          )
        )
      )
    )
  ),
  if(
    a!isNullOrEmpty(local!mapped),
    {},
    todatasubset(local!mapped, a!pagingInfo(startIndex: 1, batchSize: -1, sort: a!sortInfo(field: "drawId", ascending: true))).data
  )
)

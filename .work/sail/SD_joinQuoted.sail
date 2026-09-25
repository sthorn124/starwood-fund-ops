/* Draw approval (Phase 5): a plain-English list of labels in curly quotes — “A”, “A” and “B”, “A”, “B” and “C”. */
a!localVariables(
  local!q: if(
    a!isNullOrEmpty(ri!items),
    {},
    a!forEach(items: ri!items, expression: "“" & trim(tostring(fv!item)) & "”")
  ),
  local!n: length(local!q),
  if(
    local!n = 0,
    "",
    if(
      local!n = 1,
      index(local!q, 1, ""),
      joinarray(index(local!q, enumerate(local!n - 1) + 1, {}), ", ") & " and " & index(local!q, local!n, "")
    )
  )
)

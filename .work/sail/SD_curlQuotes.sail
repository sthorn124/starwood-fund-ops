/* Draw approval (Phase 5): straight double quotes → curly pairs (“…”) for display. Counts split parts with count():
   length() skips empty and null items (measured), split() keeps them in place. */
a!localVariables(
  local!text: a!defaultValue(ri!text, ""),
  local!parts: if(local!text = "", {}, split(local!text, char(34))),
  local!n: count(local!parts),
  if(
    local!n <= 1,
    local!text,
    joinarray(
      a!forEach(
        items: local!parts,
        expression: a!defaultValue(fv!item, "") & if(fv!index < local!n, if(mod(fv!index, 2) = 1, "“", "”"), "")
      ),
      ""
    )
  )
)

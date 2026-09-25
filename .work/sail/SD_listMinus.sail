/* Draw approval (Phase 5): the items of ri!a that are not in ri!b, compared trimmed and lower-cased (so a change of case
   or spacing is not a difference); ri!a's order and spelling are kept. Used to diff workbook structures. */
a!localVariables(
  local!a: if(a!isNullOrEmpty(ri!a), {}, ri!a),
  local!bNorm: if(
    a!isNullOrEmpty(ri!b),
    {},
    a!forEach(items: ri!b, expression: lower(trim(tostring(fv!item))))
  ),
  if(
    length(local!a) = 0,
    {},
    if(
      length(local!bNorm) = 0,
      local!a,
      index(
        local!a,
        where(
          a!forEach(
            items: local!a,
            expression: not(contains(local!bNorm, lower(trim(tostring(fv!item)))))
          )
        ),
        {}
      )
    )
  )
)

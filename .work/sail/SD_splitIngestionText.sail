/* Draw approval (Phase 5): the stored failure reason / comparison texts are plain lines — a lead line, "• " bullet
   lines, closing lines. Returns a!map(lead, bullets, tail) for the Summary card and the alert email. */
a!localVariables(
  local!lines: if(
    a!isNullOrEmpty(ri!text),
    {},
    a!forEach(items: split(ri!text, char(10)), expression: trim(a!defaultValue(fv!item, "")))
  ),
  local!n: count(local!lines),
  local!isBullet: if(local!n = 0, {}, a!forEach(items: local!lines, expression: left(fv!item, 2) = "• ")),
  local!rest: if(local!n <= 1, {}, index(local!lines, enumerate(local!n - 1) + 2, {})),
  local!restIsBullet: if(local!n <= 1, {}, index(local!isBullet, enumerate(local!n - 1) + 2, {})),
  a!map(
    lead: if(local!n = 0, "", index(local!lines, 1, "")),
    bullets: if(
      local!n <= 1,
      {},
      a!forEach(items: index(local!rest, where(local!restIsBullet), {}), expression: mid(fv!item, 3, 2000))
    ),
    tail: if(
      local!n <= 1,
      "",
      joinarray(index(local!rest, where(a!forEach(items: local!restIsBullet, expression: not(fv!item))), {}), " ")
    )
  )
)

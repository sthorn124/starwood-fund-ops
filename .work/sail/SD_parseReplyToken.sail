/* Draw approval (Phase 6a): the reference token in a step email's subject, "[SD-DRAW-<drawId>-S<stepOrder>]".
   Mail clients keep the subject on a reply or forward and only prefix it (Re:, RE:, Fwd:, AW:, …), so the token is found
   anywhere in the subject, case-insensitive. Returns a map: found, drawId, stepOrder, token. */
a!localVariables(
  local!s: a!defaultValue(ri!subject, ""),
  local!start: search("[SD-DRAW-", local!s),
  local!rest: if(local!start = 0, "", mid(local!s, local!start + 9, 40)),
  local!close: if(local!rest = "", 0, search("]", local!rest)),
  local!inner: if(local!close = 0, "", left(local!rest, local!close - 1)),
  local!parts: if(local!inner = "", {}, split(local!inner, "-")),
  local!drawText: if(count(local!parts) <> 2, "", index(local!parts, 1, "")),
  local!stepText: if(count(local!parts) <> 2, "", index(local!parts, 2, "")),
  local!isDigits: a!forEach(
    items: {local!drawText, if(upper(left(local!stepText, 1)) = "S", right(local!stepText, len(local!stepText) - 1), "")},
    expression: and(len(fv!item) > 0, len(fv!item) <= 9, len(stripwith(fv!item, "0123456789")) = 0)
  ),
  local!ok: and(local!isDigits),
  a!map(
    found: local!ok,
    drawId: if(local!ok, tointeger(local!drawText), null),
    stepOrder: if(local!ok, tointeger(right(local!stepText, len(local!stepText) - 1)), null),
    token: if(local!ok, "[SD-DRAW-" & local!inner & "]", "")
  )
)

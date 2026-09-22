/* Draw approval (Phase 3): a date as Doc Center's spreadsheet extraction prints it, as a Date, or null.
   Accepts M/D/YYYY (the workbook's display format) and YYYY-MM-DD (the form's own serialisation). Anything
   else returns null so the accountant sees an empty date field rather than a wrong one. */
a!localVariables(
  local!raw: trim(tostring(a!defaultValue(ri!text, ""))),
  if(
    local!raw = "",
    null,
    if(
      and(len(local!raw) = 10, mid(local!raw, 5, 1) = "-", mid(local!raw, 8, 1) = "-"),
      date(tointeger(left(local!raw, 4)), tointeger(mid(local!raw, 6, 2)), tointeger(right(local!raw, 2))),
      a!localVariables(
        local!parts: split(local!raw, "/"),
        if(
          length(local!parts) = 3,
          date(tointeger(local!parts[3]), tointeger(local!parts[1]), tointeger(local!parts[2])),
          null
        )
      )
    )
  )
)

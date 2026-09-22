/* Draw approval (Phase 3): a number as Doc Center's spreadsheet extraction prints it, as a Decimal.
   Accepts "106,664,345", "2,604,252.23", "(21,509)" (accounting negative), "-57,753", "91.9%" (returns 91.9 —
   a percent stays a percent, matching the seed's totalPtdIncThisDrawPct), "$1,200", "0.919" and blanks
   ("", "-", "—", "N/A" → 0). Text that carries no digits returns 0. */
a!localVariables(
  local!raw: trim(tostring(a!defaultValue(ri!text, ""))),
  local!negative: or(find("(", local!raw) > 0, left(local!raw, 1) = "-"),
  local!digits: a!localVariables(
    local!s1: substitute(substitute(substitute(substitute(substitute(local!raw, ",", ""), "$", ""), "(", ""), ")", ""), "%", ""),
    trim(substitute(substitute(local!s1, "-", ""), " ", ""))
  ),
  local!hasDigit: or(a!forEach(items: enumerate(10), expression: find(tostring(fv!item), local!digits) > 0)),
  if(
    not(local!hasDigit),
    0,
    a!localVariables(
      local!value: todecimal(local!digits),
      if(local!negative, 0 - local!value, local!value)
    )
  )
)

/* Draw approval: currency display. text() truncates unless every thousands group is spelled out,
   so the pattern carries four groups, and it truncates rather than rounds, so the value is rounded first. Nulls render as an em dash; negatives render in parentheses, as the approval email does. */
if(
  a!isNullOrEmpty(ri!value),
  "—",
  if(
    a!defaultValue(ri!showCents, false),
    text(round(ri!value, 2), "$#,###,###,###,##0.00;($#,###,###,###,##0.00)"),
    text(round(ri!value, 0), "$#,###,###,###,##0;($#,###,###,###,##0)")
  )
)

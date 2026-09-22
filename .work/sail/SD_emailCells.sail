/* Draw approval (Phase 4): one run of email table cells (th or td) with the given inline style and per-cell alignment,
   returned as one HTML string. texts are already HTML-safe. */
concat(
  a!forEach(
    items: ri!texts,
    expression: "<" & ri!tag & " style=""" & ri!style & "text-align:" & a!defaultValue(index(ri!aligns, fv!index, "left"), "left") & ";"">" & fv!item & "</" & ri!tag & ">"
  )
)

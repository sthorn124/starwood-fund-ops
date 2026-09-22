/* Draw approval (Phase 4): one body row of an email table: <tr> + cells with the standard td style, per-cell alignment,
   optional bold, and per-cell extra style (e.g. a highlighted column or row). cells are already HTML-safe. */
"<tr>" & concat(
  a!forEach(
    items: ri!cells,
    expression: "<td style=""padding:4px 6px;border-bottom:1px solid #E5E7EB;text-align:" & a!defaultValue(index(ri!aligns, fv!index, "left"), "left") & ";" & if(a!defaultValue(ri!bold, false), "font-weight:bold;", "") & a!defaultValue(index(ri!cellStyles, fv!index, ""), "") & """>" & fv!item & "</td>"
  )
) & "</tr>"

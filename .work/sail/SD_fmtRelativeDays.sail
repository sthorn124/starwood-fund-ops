/* Draw approval: "in N days" / "today" / "N days ago" from a signed day count, or "" for null.
   Every aging and "in N days" string in the draw UI comes through here; nothing is hard-coded. */
if(
  a!isNullOrEmpty(ri!days),
  "",
  if(
    ri!days = 0,
    "today",
    if(
      ri!days > 0,
      "in " & ri!days & if(ri!days = 1, " day", " days"),
      abs(ri!days) & if(abs(ri!days) = 1, " day ago", " days ago")
    )
  )
)

/* Draw approval: a small upper-case label over its value, the field pattern the mockups use in every card.
   Nulls and blanks render as an em dash so a missing field never collapses the row. */
a!richTextDisplayField(
  labelPosition: "COLLAPSED",
  value: {
    a!richTextItem(text: upper(a!defaultValue(ri!label, "")), color: "#6B7280", size: "SMALL"),
    char(10),
    a!richTextItem(
      text: if(a!isNullOrEmpty(ri!value), "—", if(trim(tostring(ri!value)) = "", "—", tostring(ri!value))),
      size: if(a!defaultValue(ri!emphasize, false), "MEDIUM", "STANDARD"),
      style: if(a!defaultValue(ri!emphasize, false), "STRONG", "PLAIN"),
      color: "#16294D"
    )
  },
  marginBelow: a!defaultValue(ri!marginBelow, "STANDARD")
)

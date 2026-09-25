/* Draw approval: one status chip, coloured by the vocabulary canon.
   Approved / Extracted & Confirmed / Funded / Read → green; In Progress → blue; Not read → amber; Rejected, Ingestion Failed → red;
   everything else (Pending, Attached, Received, …) → grey. Read / Not read are a supporting document's AI reading (Phase 5.5). */
a!localVariables(
  local!s: trim(a!defaultValue(ri!status, "")),
  local!bg: a!match(
    value: local!s,
    equals: "Approved", then: "#E6F4EC",
    equals: "Extracted & Confirmed", then: "#E6F4EC",
    equals: "Funded", then: "#E6F4EC",
    equals: "Read", then: "#E6F4EC",
    equals: "In Progress", then: "#E8F0FC",
    equals: "Not read", then: "#FDF3E0",
    equals: "Rejected", then: "#FDECEC",
    equals: "Ingestion Failed", then: "#FDECEC",
    default: "#EEF1F5"
  ),
  local!fg: a!match(
    value: local!s,
    equals: "Approved", then: "#1E7E46",
    equals: "Extracted & Confirmed", then: "#1E7E46",
    equals: "Funded", then: "#1E7E46",
    equals: "Read", then: "#1E7E46",
    equals: "In Progress", then: "#1D5BBF",
    equals: "Not read", then: "#92600A",
    equals: "Rejected", then: "#B42318",
    equals: "Ingestion Failed", then: "#B42318",
    default: "#64748B"
  ),
  a!tagField(
    labelPosition: "COLLAPSED",
    tags: a!tagItem(
      text: if(local!s = "", "—", local!s),
      backgroundColor: local!bg,
      textColor: local!fg
    ),
    size: "SMALL",
    align: a!defaultValue(ri!align, "START")
  )
)

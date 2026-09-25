/* Phase 5.6 gauntlet: the two deterministic gates on Doc Center output. Each specimen states its expected result; the
   run returns one "PASS"/"FAIL <id>: <got>" line per specimen. Re-run after any change to either gate. */
a!localVariables(
  local!g: a!forEach(
    items: {
      a!map(id: "G1 lien waiver, classified", c: a!map(found: true, classification: "Lien Waiver", statusId: 3, confidence: null), want: "LIEN_WAIVER|true"),
      a!map(id: "G2 Other", c: a!map(found: true, classification: "Other", statusId: 3, confidence: null), want: "BACKUP|false"),
      a!map(id: "G3 no instance", c: a!map(found: false), want: "BACKUP|false"),
      a!map(id: "G4 instance error", c: a!map(found: true, classification: "Invoice", statusId: 9, confidence: null), want: "BACKUP|false"),
      a!map(id: "G5 low confidence", c: a!map(found: true, classification: "Invoice", statusId: 3, confidence: 55), want: "BACKUP|false"),
      a!map(id: "G6 high confidence", c: a!map(found: true, classification: "Pay Application", statusId: 3, confidence: 95), want: "PAY_APPLICATION|true"),
      a!map(id: "G7 trailing space", c: a!map(found: true, classification: "Invoice ", statusId: 3, confidence: null), want: "INVOICE|true"),
      a!map(id: "G8 unknown label", c: a!map(found: true, classification: "Receipt", statusId: 3, confidence: null), want: "BACKUP|false"),
      a!map(id: "G9 reconciled", c: a!map(found: true, classification: "Pay Application", statusId: 4, confidence: null), want: "PAY_APPLICATION|true"),
      a!map(id: "G10 classified with errors", c: a!map(found: true, classification: "Lien Waiver", statusId: 8, confidence: null), want: "BACKUP|false")
    },
    expression: a!localVariables(
      local!r: rule!SD_gateSupportingDocClassification(classification: fv!item.c, minConfidence: 80),
      local!got: local!r.typeKey & "|" & local!r.ok,
      if(local!got = fv!item.want, "PASS " & fv!item.id, "FAIL " & fv!item.id & ": " & local!got & " (" & local!r.reason & ")")
    )
  ),
  local!e: a!forEach(
    items: {
      a!map(id: "E1 printed with $", x: a!map(found: true, statusId: 2, currentPaymentDue: "$2,490,296.23", contractorName: "Stonebridge Construction Group", applicationNumber: "14"), want: "2490296.23"),
      a!map(id: "E2 no $", x: a!map(found: true, statusId: 2, currentPaymentDue: "2,527,796.23"), want: "2527796.23"),
      a!map(id: "E3 negative", x: a!map(found: true, statusId: 2, currentPaymentDue: "($1,000.00)"), want: "none"),
      a!map(id: "E4 blank", x: a!map(found: true, statusId: 2, currentPaymentDue: ""), want: "none"),
      a!map(id: "E5 extracted with errors", x: a!map(found: true, statusId: 5, currentPaymentDue: "$873,905.00"), want: "none"),
      a!map(id: "E6 one decimal", x: a!map(found: true, statusId: 2, currentPaymentDue: "$1,184,320.5"), want: "1184320.50"),
      a!map(id: "E7 two points", x: a!map(found: true, statusId: 2, currentPaymentDue: "1.234.56"), want: "none"),
      a!map(id: "E8 no instance", x: a!map(found: false), want: "none"),
      a!map(id: "E9 zero", x: a!map(found: true, statusId: 2, currentPaymentDue: "$0.00"), want: "none"),
      a!map(id: "E10 words", x: a!map(found: true, statusId: 2, currentPaymentDue: "see attached"), want: "none")
    },
    expression: a!localVariables(
      local!r: rule!SD_gatePayApplicationExtraction(extraction: fv!item.x),
      local!got: if(a!isNullOrEmpty(local!r.amount), "none", fixed(local!r.amount, 2, true)), /* fixed(): tostring() of a Decimal keeps 7 significant digits */
      if(local!got = fv!item.want, "PASS " & fv!item.id, "FAIL " & fv!item.id & ": " & local!got & " (" & joinarray(local!r.failures, "; ") & ")")
    )
  ),
  a!flatten({local!g, local!e})
)

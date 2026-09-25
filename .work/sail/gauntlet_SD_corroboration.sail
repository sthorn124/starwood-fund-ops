/* Phase 5.6 gauntlet for SD_corroborateDocuments (the 5.5 parse specimens P1-P9 retired with SD_parseSupportingDocReading).
   Each specimen states its expected state, summary and chips; the run returns "PASS <id>" or "FAIL <id>: <got>".
   Re-run after any change to the corroboration rule.
   C1 clean package; C2 mismatch, no waiver; C3 clean + unclassified junk (no warning); C4 none; C5 still classifying;
   C6 invoice only (filed, nothing to tie); C7 pay application figure unread; C8 legacy backup row (5.5 / seed). */
a!localVariables(
  local!cats: {"Hard Costs", "A&E - Architectural"},
  local!draws: {2490296.23, 59582},
  local!pay: a!map(rowId: 1, name: "PayApp.pdf", type: "Pay Application", status: "Classified and read", amount: 2490296.23, party: "Stonebridge Construction Group", reference: "14"),
  local!inv: a!map(rowId: 2, name: "Invoice.pdf", type: "Invoice", status: "Classified only", amount: 59582, party: "", reference: ""),
  local!lw: a!map(rowId: 3, name: "Waiver.pdf", type: "Lien Waiver", status: "Classified only", amount: null, party: "", reference: ""),
  local!junk: a!map(rowId: 4, name: "Notice.pdf", type: "Backup", status: "Not classified", amount: null, party: "", reference: ""),
  local!cases: {
    a!map(id: "C1", docs: {local!pay, local!inv, local!lw},
      want: "TIES|3 supporting documents · pay application ties · invoice filed · lien waiver received|Ties;Received · filed as Invoice;Lien waiver received"),
    a!map(id: "C2", docs: {a!update(local!pay, "amount", 2527796.23)},
      want: "ATTENTION|1 supporting document · pay application does not tie ($2,527,796.23 vs $2,490,296.23) · no lien waiver with the pay application|Does not tie: $2,527,796.23 vs $2,490,296.23"),
    a!map(id: "C3", docs: {local!pay, local!inv, local!lw, local!junk},
      want: "TIES|4 supporting documents · pay application ties · invoice filed · lien waiver received · 1 not classified|Ties;Received · filed as Invoice;Lien waiver received;Received · not classified"),
    a!map(id: "C4", docs: null, want: "NONE|No supporting documents received|"),
    a!map(id: "C5", docs: {a!map(rowId: 6, name: "Pending.pdf", type: "Backup", status: "Received", amount: null, party: "", reference: "")},
      want: "ATTENTION|1 supporting document · 1 still being classified|Being classified"),
    a!map(id: "C6", docs: {local!inv}, want: "RECEIVED|1 supporting document · invoice filed|Received · filed as Invoice"),
    a!map(id: "C7", docs: {a!update(local!pay, "amount", null), local!lw},
      want: "ATTENTION|2 supporting documents · pay application figure not read · lien waiver received|Figure could not be read;Lien waiver received"),
    a!map(id: "C8", docs: {a!map(rowId: 5, name: "Legacy.pdf", type: "Backup", status: "Attached", amount: null, party: "", reference: "")},
      want: "RECEIVED|1 supporting document · 1 backup|Received")
  },
  a!forEach(
    items: local!cases,
    expression: a!localVariables(
      local!r: rule!SD_corroborateDocuments(documents: fv!item.docs, lineCategories: local!cats, lineCurrentDraws: local!draws),
      local!chips: if(a!defaultValue(local!r.count, 0) = 0, "", joinarray(a!forEach(items: local!r.items, expression: fv!item.chip), ";")),
      /* counted with sum() of 1/0: an a!forEach that returns {} for skipped items yields [[]], which is not "empty" */
      local!invoiceFigures: if(a!defaultValue(local!r.count, 0) = 0, 0, sum(a!forEach(items: local!r.items, expression: if(and(fv!item.type = "Invoice", not(isnull(fv!item.figure))), 1, 0)))),
      local!got: local!r.state & "|" & local!r.summary & "|" & local!chips,
      if(
        and(local!got = fv!item.want, local!invoiceFigures = 0),
        "PASS " & fv!item.id,
        "FAIL " & fv!item.id & ": " & local!got & if(local!invoiceFigures = 0, "", " (invoice carries a figure)")
      )
    )
  )
)

/* Phase 5.6 gauntlet for SD_corroborateDocuments (the 5.5 parse specimens P1-P9 retired with SD_parseSupportingDocReading).
   Each specimen states its expected state, summary, chips and details; the run returns "PASS <id>" or "FAIL <id>: <got>".
   Every chip must also be at most 40 characters (the tag's display limit; fix session 2026-09-25).
   Re-run after any change to the corroboration rule.
   C1 clean package; C2 mismatch, no waiver; C3 clean + unclassified junk (no warning); C4 none; C5 still classifying;
   C6 invoice only (filed, nothing to tie); C7 pay application figure unread; C8 legacy backup row (5.5 / seed);
   C9 pay application with no budget lines at all ("No line to tie to"); C10 pay application with lines but none for
   Hard Costs — pins the pre-existing behaviour (ties against $0.00, "Does not tie", off by the full figure), which is
   flagged for a ruling in TODO.md (fix session 2026-09-25). An empty detail is shown as "-" (joinarray drops "").
   */
a!localVariables(
  local!cats: {"Hard Costs", "A&E - Architectural"},
  local!draws: {2490296.23, 59582},
  local!pay: a!map(rowId: 1, name: "PayApp.pdf", type: "Pay Application", status: "Classified and read", amount: 2490296.23, party: "Stonebridge Construction Group", reference: "14"),
  local!inv: a!map(rowId: 2, name: "Invoice.pdf", type: "Invoice", status: "Classified only", amount: 59582, party: "", reference: ""),
  local!lw: a!map(rowId: 3, name: "Waiver.pdf", type: "Lien Waiver", status: "Classified only", amount: null, party: "", reference: ""),
  local!junk: a!map(rowId: 4, name: "Notice.pdf", type: "Backup", status: "Not classified", amount: null, party: "", reference: ""),
  local!cases: {
    a!map(id: "C1", docs: {local!pay, local!inv, local!lw},
      want: "TIES|3 supporting documents · pay application ties · invoice filed · lien waiver received|Ties;Received · filed as Invoice;Lien waiver received|-;-;-"),
    a!map(id: "C2", docs: {a!update(local!pay, "amount", 2527796.23)},
      want: "ATTENTION|1 supporting document · pay application does not tie ($2,527,796.23 vs $2,490,296.23) · no lien waiver with the pay application|Does not tie|off by $37,500.00"),
    a!map(id: "C3", docs: {local!pay, local!inv, local!lw, local!junk},
      want: "TIES|4 supporting documents · pay application ties · invoice filed · lien waiver received · 1 not classified|Ties;Received · filed as Invoice;Lien waiver received;Received · not classified|-;-;-;-"),
    a!map(id: "C4", docs: null, want: "NONE|No supporting documents received||"),
    a!map(id: "C5", docs: {a!map(rowId: 6, name: "Pending.pdf", type: "Backup", status: "Received", amount: null, party: "", reference: "")},
      want: "ATTENTION|1 supporting document · 1 still being classified|Being classified|-"),
    a!map(id: "C6", docs: {local!inv}, want: "RECEIVED|1 supporting document · invoice filed|Received · filed as Invoice|-"),
    a!map(id: "C7", docs: {a!update(local!pay, "amount", null), local!lw},
      want: "ATTENTION|2 supporting documents · pay application figure not read · lien waiver received|Figure could not be read;Lien waiver received|-;-"),
    a!map(id: "C8", docs: {a!map(rowId: 5, name: "Legacy.pdf", type: "Backup", status: "Attached", amount: null, party: "", reference: "")},
      want: "RECEIVED|1 supporting document · 1 backup|Received|-"),
    a!map(id: "C9", docs: {local!pay, local!lw}, noLines: true,
      want: "ATTENTION|2 supporting documents · pay application does not tie ($2,490,296.23 vs —) · lien waiver received|No line to tie to;Lien waiver received|no Hard Costs line in the template;-"),
    a!map(id: "C10", docs: {local!pay, local!lw}, cats: {"A&E - Architectural"}, draws: {59582},
      want: "ATTENTION|2 supporting documents · pay application does not tie ($2,490,296.23 vs $0.00) · lien waiver received|Does not tie;Lien waiver received|off by $2,490,296.23;-")
  },
  a!forEach(
    items: local!cases,
    expression: a!localVariables(
      local!r: rule!SD_corroborateDocuments(
        documents: fv!item.docs,
        lineCategories: if(a!defaultValue(index(fv!item, "noLines", false), false), {}, a!defaultValue(index(fv!item, "cats", null), local!cats)),
        lineCurrentDraws: if(a!defaultValue(index(fv!item, "noLines", false), false), {}, a!defaultValue(index(fv!item, "draws", null), local!draws))
      ),
      local!chips: if(a!defaultValue(local!r.count, 0) = 0, "", joinarray(a!forEach(items: local!r.items, expression: fv!item.chip), ";")),
      local!details: if(a!defaultValue(local!r.count, 0) = 0, "", joinarray(a!forEach(items: local!r.items, expression: if(fv!item.detail = "", "-", fv!item.detail)), ";")),
      /* the tag's display limit: no chip over 40 characters (sum of 1/0, not an emptiness test on a filtered forEach) */
      local!longChips: if(a!defaultValue(local!r.count, 0) = 0, 0, sum(a!forEach(items: local!r.items, expression: if(len(fv!item.chip) > 40, 1, 0)))),
      /* counted with sum() of 1/0: an a!forEach that returns {} for skipped items yields [[]], which is not "empty" */
      local!invoiceFigures: if(a!defaultValue(local!r.count, 0) = 0, 0, sum(a!forEach(items: local!r.items, expression: if(and(fv!item.type = "Invoice", not(isnull(fv!item.figure))), 1, 0)))),
      local!got: local!r.state & "|" & local!r.summary & "|" & local!chips & "|" & local!details,
      if(
        and(local!got = fv!item.want, local!invoiceFigures = 0, local!longChips = 0),
        "PASS " & fv!item.id,
        "FAIL " & fv!item.id & ": " & local!got & if(local!invoiceFigures = 0, "", " (invoice carries a figure)") & if(local!longChips = 0, "", " (a chip is over 40 characters)")
      )
    )
  )
)

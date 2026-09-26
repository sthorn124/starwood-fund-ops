/* Draw approval (Phase 5.5; Phase 5.6 document handling): corroboration of a draw package, with no model involved.
   ri!documents are SD_getSupportingDocuments maps (typed by the Doc Center classification model since Phase 5.6);
   ri!lineCategories / ri!lineCurrentDraws are the budget lines (the reconciliation form passes its live, editable
   lines; after confirm SD_getDrawCorroboration passes the committed ones).
   - Pay Application: the only document read (Doc Center extraction). Its Current Payment Due against the
     SD_PAY_APP_TIE_CATEGORY line's current draw (summed if the category repeats); ties when equal to the cent.
   - Invoice: typed and filed, never read — "Received · filed as Invoice", no figure, no tie (Phase 5.6 ruling).
   - Lien Waiver: presence only — "Lien waiver received". A Pay Application without any Lien Waiver adds the waiver line.
   - Backup: "Received · not classified" when Doc Center could not type it, else "Received"; neither is a warning.
   - A row still "Received" (the worker has not finished) is "Being classified".
   Chip text stays under the tag's 40-character display limit (fix session 2026-09-25): figures never go in a chip;
   they go in the item's detail, which the form shows as wrapping text beside the chip ("Does not tie" + "off by $X").
   Returns a map: count, items (rowId, document, name, type, party, reference, figure, figureLabel, templateFigure,
   templateLabel, state TIES / ATTENTION / RECEIVED / PENDING, chip, chipBg, chipFg, detail), hasPayApplication, waiverMissing,
   pendingCount, state (NONE / TIES / RECEIVED / ATTENTION: TIES when a pay application tied and nothing needs
   attention, RECEIVED when the documents are filed and there is nothing to tie), summary (≤ 250 characters). */
a!localVariables(
  local!docs: if(a!isNullOrEmpty(ri!documents), {}, ri!documents),
  local!n: if(a!isNullOrEmpty(local!docs), 0, length(a!forEach(items: local!docs, expression: 1))),
  local!cats: if(a!isNullOrEmpty(ri!lineCategories), {}, a!forEach(items: ri!lineCategories, expression: lower(trim(tostring(fv!item))))),
  local!draws: if(a!isNullOrEmpty(ri!lineCurrentDraws), {}, a!forEach(items: ri!lineCurrentDraws, expression: a!defaultValue(fv!item, 0))),
  local!lineCount: count(local!cats),
  local!payCategory: tostring(cons!SD_PAY_APP_TIE_CATEGORY),
  local!payTarget: if(
    local!lineCount = 0,
    null,
    sum(a!forEach(items: enumerate(local!lineCount) + 1, expression: if(index(local!cats, fv!item, "") = lower(local!payCategory), todecimal(index(local!draws, fv!item, 0)), 0)))
  ),
  local!green: a!map(bg: "#E6F4EC", fg: "#1E7E46"),
  local!amber: a!map(bg: "#FDF3E0", fg: "#92600A"),
  local!grey: a!map(bg: "#EEF1F5", fg: "#64748B"),
  local!items: if(
    local!n = 0,
    {},
    a!forEach(
      items: local!docs,
      expression: a!localVariables(
        local!doc: fv!item,
        local!type: tostring(a!defaultValue(index(local!doc, "type", ""), "Backup")),
        local!status: tostring(a!defaultValue(index(local!doc, "status", ""), "")),
        local!pending: local!status = "Received",
        local!amount: if(local!type = "Pay Application", index(local!doc, "amount", null), null),
        local!result: if(
          local!pending,
          a!map(state: "PENDING", chip: "Being classified", colors: local!grey, templateFigure: null, templateLabel: ""),
          if(
            local!type = "Pay Application",
            if(
              a!isNullOrEmpty(local!amount),
              a!map(state: "ATTENTION", chip: "Figure could not be read", colors: local!amber, templateFigure: local!payTarget, templateLabel: local!payCategory & " · current draw"),
              if(
                a!isNullOrEmpty(local!payTarget),
                a!map(state: "ATTENTION", chip: "No line to tie to", detail: "no " & local!payCategory & " line in the template", colors: local!amber, templateFigure: null, templateLabel: ""),
                if(
                  abs(todecimal(local!amount) - todecimal(local!payTarget)) < 0.005,
                  a!map(state: "TIES", chip: "Ties", colors: local!green, templateFigure: local!payTarget, templateLabel: local!payCategory & " · current draw"),
                  a!map(
                    state: "ATTENTION",
                    chip: "Does not tie",
                    detail: "off by " & rule!SD_fmtMoney(value: abs(todecimal(local!amount) - todecimal(local!payTarget)), showCents: true),
                    colors: local!amber,
                    templateFigure: local!payTarget,
                    templateLabel: local!payCategory & " · current draw"
                  )
                )
              )
            ),
            if(
              local!type = "Invoice",
              a!map(state: "RECEIVED", chip: "Received · filed as Invoice", colors: local!grey, templateFigure: null, templateLabel: ""),
              if(
                local!type = "Lien Waiver",
                a!map(state: "RECEIVED", chip: "Lien waiver received", colors: local!green, templateFigure: null, templateLabel: ""),
                a!map(state: "RECEIVED", chip: if(local!status = "Not classified", "Received · not classified", "Received"), colors: local!grey, templateFigure: null, templateLabel: "")
              )
            )
          )
        ),
        a!map(
          rowId: index(local!doc, "rowId", null),
          document: index(local!doc, "document", null),
          name: tostring(a!defaultValue(index(local!doc, "name", ""), "")),
          type: local!type,
          status: local!status,
          party: tostring(a!defaultValue(index(local!doc, "party", ""), "")),
          reference: tostring(a!defaultValue(index(local!doc, "reference", ""), "")),
          figure: local!amount,
          figureLabel: if(local!type = "Pay Application", "Current payment due", ""),
          templateFigure: local!result.templateFigure,
          templateLabel: local!result.templateLabel,
          state: local!result.state,
          chip: local!result.chip,
          chipBg: local!result.colors.bg,
          chipFg: local!result.colors.fg,
          detail: tostring(a!defaultValue(index(local!result, "detail", ""), ""))
        )
      )
    )
  ),
  local!types: if(local!n = 0, {}, a!forEach(items: local!items, expression: fv!item.type)),
  local!states: if(local!n = 0, {}, a!forEach(items: local!items, expression: fv!item.state)),
  local!statuses: if(local!n = 0, {}, a!forEach(items: local!items, expression: fv!item.status)),
  local!hasPayApplication: if(local!n = 0, false, contains(local!types, "Pay Application")),
  local!hasWaiver: if(local!n = 0, false, contains(local!types, "Lien Waiver")),
  local!waiverMissing: and(local!hasPayApplication, not(local!hasWaiver)),
  local!pendingCount: if(local!n = 0, 0, count(wherecontains("PENDING", local!states))),
  local!attention: if(local!n = 0, false, or(contains(local!states, "ATTENTION"), local!waiverMissing, local!pendingCount > 0)),
  /* type counts over settled rows only: a row still being classified is registered as Backup / Received */
  local!settledTypes: if(local!n = 0, {}, a!forEach(items: local!items, expression: if(fv!item.state = "PENDING", "", fv!item.type))),
  local!invoices: if(local!n = 0, 0, count(wherecontains("Invoice", local!settledTypes))),
  local!waivers: if(local!n = 0, 0, count(wherecontains("Lien Waiver", local!settledTypes))),
  local!notClassified: if(local!n = 0, 0, count(wherecontains("Not classified", local!statuses))),
  local!otherBackups: if(local!n = 0, 0, count(wherecontains("Backup", local!settledTypes)) - local!notClassified),
  local!parts: if(
    local!n = 0,
    {},
    {
      a!forEach(
        items: local!items,
        expression: if(
          fv!item.state = "PENDING",
          {},
          if(
            fv!item.type = "Pay Application",
            if(fv!item.state = "TIES", "pay application ties", if(a!isNullOrEmpty(fv!item.figure), "pay application figure not read", "pay application does not tie (" & rule!SD_fmtMoney(value: fv!item.figure, showCents: true) & " vs " & rule!SD_fmtMoney(value: fv!item.templateFigure, showCents: true) & ")")),
            {}
          )
        )
      ),
      if(local!invoices = 0, {}, if(local!invoices = 1, "invoice filed", local!invoices & " invoices filed")),
      if(local!waivers = 0, {}, if(local!waivers = 1, "lien waiver received", local!waivers & " lien waivers received")),
      if(local!waiverMissing, "no lien waiver with the pay application", {}),
      if(local!pendingCount > 0, local!pendingCount & " still being classified", {}),
      if(local!notClassified > 0, local!notClassified & " not classified", {}),
      if(local!otherBackups > 0, local!otherBackups & " backup", {})
    }
  ),
  /* an a!forEach whose every item is skipped yields [[]]; inside a list that empty element is counted by count() but
     skipped by len(), so where(len(list) > 0) points at the wrong items (measured). Lengths are taken per item. */
  local!partsClean: if(
    a!isNullOrEmpty(local!parts),
    {},
    index(local!parts, where(a!forEach(items: local!parts, expression: len(tostring(a!defaultValue(fv!item, ""))) > 0)), {})
  ),
  a!map(
    count: local!n,
    items: local!items,
    hasPayApplication: local!hasPayApplication,
    waiverMissing: local!waiverMissing,
    pendingCount: local!pendingCount,
    state: if(local!n = 0, "NONE", if(local!attention, "ATTENTION", if(local!hasPayApplication, "TIES", "RECEIVED"))),
    summary: left(
      if(
        local!n = 0,
        "No supporting documents received",
        local!n & if(local!n = 1, " supporting document", " supporting documents")
          & if(a!isNullOrEmpty(local!partsClean), "", " · " & joinarray(local!partsClean, " · "))
      ),
      250
    )
  )
)

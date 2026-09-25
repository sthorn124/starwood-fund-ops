/* Draw approval (Phase 5.5): corroboration of a draw package — each supporting document tied out against the
   template, with no model involved. ri!documents are SD_getSupportingDocuments maps; ri!lineCategories /
   ri!lineCurrentDraws are the budget lines (the reconciliation form passes its live, editable lines; after confirm
   SD_getDrawCorroboration passes the committed ones).
   - Pay Application: its current payment due against the SD_PAY_APP_TIE_CATEGORY line's current draw (summed if the
     category repeats); ties when equal to the cent.
   - Invoice: its total against the budget line whose current draw equals it (matched by amount, to the cent); no match
     is "no matching budget line".
   - Lien Waiver: listed as received. A Pay Application without any Lien Waiver adds the waiver warning.
   - Backup: listed as received. A row still "Received" (not read yet) is "Being read".
   Returns a map: count, items (rowId, document, name, type, party, reference, figure, figureLabel, templateFigure,
   templateLabel, state TIES / ATTENTION / RECEIVED / PENDING, chip, chipBg, chipFg), hasPayApplication, waiverMissing,
   pendingCount, state (NONE / TIES / ATTENTION), summary (≤ 250 characters, the line stored on the draw). */
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
        local!pending: tostring(a!defaultValue(index(local!doc, "status", ""), "")) = "Received",
        local!amount: index(local!doc, "amount", null),
        local!matchPos: if(
          or(local!pending, local!type <> "Invoice", a!isNullOrEmpty(local!amount), local!lineCount = 0),
          0,
          index(where(a!forEach(items: local!draws, expression: abs(todecimal(fv!item) - todecimal(local!amount)) < 0.005)), 1, 0)
        ),
        local!result: if(
          local!pending,
          a!map(state: "PENDING", chip: "Being read", colors: local!grey, templateFigure: null, templateLabel: ""),
          if(
            local!type = "Pay Application",
            if(
              a!isNullOrEmpty(local!amount),
              a!map(state: "ATTENTION", chip: "Figure could not be read", colors: local!amber, templateFigure: local!payTarget, templateLabel: local!payCategory & " · current draw"),
              if(
                a!isNullOrEmpty(local!payTarget),
                a!map(state: "ATTENTION", chip: "No " & local!payCategory & " line to tie to", colors: local!amber, templateFigure: null, templateLabel: ""),
                if(
                  abs(todecimal(local!amount) - todecimal(local!payTarget)) < 0.005,
                  a!map(state: "TIES", chip: "Ties", colors: local!green, templateFigure: local!payTarget, templateLabel: local!payCategory & " · current draw"),
                  a!map(
                    state: "ATTENTION",
                    chip: "Does not tie: " & rule!SD_fmtMoney(value: local!amount, showCents: true) & " vs " & rule!SD_fmtMoney(value: local!payTarget, showCents: true),
                    colors: local!amber,
                    templateFigure: local!payTarget,
                    templateLabel: local!payCategory & " · current draw"
                  )
                )
              )
            ),
            if(
              local!type = "Invoice",
              if(
                a!isNullOrEmpty(local!amount),
                a!map(state: "ATTENTION", chip: "Figure could not be read", colors: local!amber, templateFigure: null, templateLabel: ""),
                if(
                  local!matchPos > 0,
                  a!map(state: "TIES", chip: "Ties", colors: local!green, templateFigure: index(local!draws, local!matchPos, null), templateLabel: index(ri!lineCategories, local!matchPos, "") & " · current draw"),
                  a!map(
                    state: "ATTENTION",
                    chip: "Does not tie: " & rule!SD_fmtMoney(value: local!amount, showCents: true) & " · no matching budget line",
                    colors: local!amber,
                    templateFigure: null,
                    templateLabel: "no matching budget line"
                  )
                )
              ),
              if(
                local!type = "Lien Waiver",
                a!map(state: "RECEIVED", chip: "Lien waiver received", colors: local!green, templateFigure: null, templateLabel: ""),
                a!map(state: "RECEIVED", chip: "Received", colors: local!grey, templateFigure: null, templateLabel: "")
              )
            )
          )
        ),
        a!map(
          rowId: index(local!doc, "rowId", null),
          document: index(local!doc, "document", null),
          name: tostring(a!defaultValue(index(local!doc, "name", ""), "")),
          type: local!type,
          party: tostring(a!defaultValue(index(local!doc, "party", ""), "")),
          reference: tostring(a!defaultValue(index(local!doc, "reference", ""), "")),
          figure: local!amount,
          figureLabel: if(local!type = "Pay Application", "Current payment due", if(local!type = "Invoice", "Invoice total", "")),
          templateFigure: local!result.templateFigure,
          templateLabel: local!result.templateLabel,
          state: local!result.state,
          chip: local!result.chip,
          chipBg: local!result.colors.bg,
          chipFg: local!result.colors.fg
        )
      )
    )
  ),
  local!types: if(local!n = 0, {}, a!forEach(items: local!items, expression: fv!item.type)),
  local!states: if(local!n = 0, {}, a!forEach(items: local!items, expression: fv!item.state)),
  local!hasPayApplication: if(local!n = 0, false, contains(local!types, "Pay Application")),
  local!hasWaiver: if(local!n = 0, false, contains(local!types, "Lien Waiver")),
  local!waiverMissing: and(local!hasPayApplication, not(local!hasWaiver)),
  local!pendingCount: if(local!n = 0, 0, count(wherecontains("PENDING", local!states))),
  local!attention: if(local!n = 0, false, or(contains(local!states, "ATTENTION"), local!waiverMissing, local!pendingCount > 0)),
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
            if(
              fv!item.type = "Invoice",
              if(fv!item.state = "TIES", "invoice ties", if(a!isNullOrEmpty(fv!item.figure), "invoice figure not read", "invoice does not tie (" & rule!SD_fmtMoney(value: fv!item.figure, showCents: true) & ", no matching line)")),
              if(fv!item.type = "Lien Waiver", "lien waiver received", {})
            )
          )
        )
      ),
      if(local!waiverMissing, "no lien waiver with the pay application", {}),
      if(local!pendingCount > 0, local!pendingCount & " still being read", {}),
      a!localVariables(
        local!backups: count(wherecontains("Backup", local!types)),
        if(local!backups = 0, {}, local!backups & " backup")
      )
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
    state: if(local!n = 0, "NONE", if(local!attention, "ATTENTION", "TIES")),
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

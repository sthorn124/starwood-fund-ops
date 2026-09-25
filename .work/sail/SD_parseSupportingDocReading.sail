/* Draw approval (Phase 5.5): the deterministic gate on the AI's reading of one supporting document.
   Expects the four lines SD_supportingDocumentPrompt asks for (TYPE|, PARTY|, REFERENCE|, AMOUNT|), parsed by position.
   - TYPE must be one of PAY_APPLICATION, INVOICE, LIEN_WAIVER, BACKUP; anything else (or a failed call) → Backup,
     status "Not read".
   - AMOUNT is kept only for a pay application or an invoice, and only when it is digits with at most one decimal point
     and at most two decimals (commas and a $ tolerated) and greater than zero; otherwise it is null and the note says
     the figure could not be read. A lien waiver's or backup's amount is ignored even if the model gave one.
   - PARTY and REFERENCE are trimmed to 200 characters.
   Returns a map: ok, typeKey, documentType, status ("Read" / "Not read"), party, reference, amount, figureLabel,
   failures, notes (the Documents tab line). Never throws. */
a!localVariables(
  local!raw: substitute(a!defaultValue(ri!response, ""), char(13), ""),
  local!lines: if(
    local!raw = "",
    {},
    a!forEach(items: split(local!raw, char(10)), expression: trim(a!defaultValue(fv!item, "")))
  ),
  local!lineCount: count(local!lines),
  local!field: a!forEach(
    items: {"TYPE", "PARTY", "REFERENCE", "AMOUNT"},
    expression: a!localVariables(
      local!key: fv!item & "|",
      local!pos: if(
        local!lineCount = 0,
        0,
        index(where(a!forEach(items: local!lines, expression: upper(left(fv!item, len(local!key))) = local!key)), 1, 0)
      ),
      if(local!pos = 0, "", trim(mid(tostring(index(local!lines, local!pos, "")), len(local!key) + 1, 2000)))
    )
  ),
  local!typeRaw: upper(substitute(index(local!field, 1, ""), " ", "_")),
  local!keys: {"PAY_APPLICATION", "INVOICE", "LIEN_WAIVER", "BACKUP"},
  local!labels: {"Pay Application", "Invoice", "Lien Waiver", "Backup"},
  local!typeKnown: contains(local!keys, local!typeRaw),
  local!callOk: a!defaultValue(ri!success, false),
  local!ok: and(local!callOk, local!typeKnown),
  local!typeKey: if(local!ok, local!typeRaw, "BACKUP"),
  local!documentType: index(local!labels, index(wherecontains(local!typeKey, local!keys), 1, 4), "Backup"),
  local!needsAmount: or(local!typeKey = "PAY_APPLICATION", local!typeKey = "INVOICE"),
  local!amountText: substitute(substitute(substitute(index(local!field, 4, ""), ",", ""), "$", ""), " ", ""),
  local!amountShapeOk: if(
    len(local!amountText) = 0,
    false,
    and(
      and(a!forEach(items: enumerate(len(local!amountText)) + 1, expression: find(mid(local!amountText, fv!item, 1), "0123456789.") > 0)),
      len(local!amountText) - len(substitute(local!amountText, ".", "")) <= 1,
      if(
        find(".", local!amountText) = 0,
        true,
        len(local!amountText) - find(".", local!amountText) <= 2
      )
    )
  ),
  local!amountValue: if(local!amountShapeOk, round(todecimal(local!amountText), 2), null),
  local!amount: if(
    and(local!ok, local!needsAmount, not(a!isNullOrEmpty(local!amountValue))),
    if(local!amountValue > 0, local!amountValue, null),
    null
  ),
  local!party: left(index(local!field, 2, ""), 200),
  local!reference: left(index(local!field, 3, ""), 200),
  local!figureLabel: if(local!typeKey = "PAY_APPLICATION", "current payment due", if(local!typeKey = "INVOICE", "total", "")),
  local!failures: {
    if(local!callOk, {}, "the AI call did not succeed" & if(a!isNullOrEmpty(ri!errorMessage), "", ": " & left(ri!errorMessage, 200))),
    if(or(not(local!callOk), local!typeKnown), {}, "the answer named no known document type"),
    if(and(local!ok, local!needsAmount, a!isNullOrEmpty(local!amount)), "the " & local!figureLabel & " could not be read", {})
  },
  a!map(
    ok: local!ok,
    typeKey: local!typeKey,
    documentType: local!documentType,
    status: if(local!ok, "Read", "Not read"),
    party: local!party,
    reference: local!reference,
    amount: local!amount,
    figureLabel: local!figureLabel,
    failures: local!failures,
    notes: if(
      local!ok,
      "Read by AI (" & a!defaultValue(ri!modelName, "AI") & ") as " & local!documentType
        & if(local!party = "", "", " · " & local!party)
        & if(local!reference = "", "", " · " & local!reference)
        & if(
          local!needsAmount,
          if(a!isNullOrEmpty(local!amount), " · the " & local!figureLabel & " could not be read", " · " & local!figureLabel & " " & rule!SD_fmtMoney(value: local!amount, showCents: true)),
          ""
        ),
      "Could not be read by AI (" & joinarray(local!failures, "; ") & "); kept as Backup"
    )
  )
)

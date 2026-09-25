"""Phase 5.5: the supporting-document rules. Placeholders (@...@) are replaced from refs — no f-strings, so SAIL's
doubled quotes pass through untouched. Writes SD_supportingDocumentPrompt.sail, SD_parseSupportingDocReading.sail,
SD_getSupportingDocuments.sail, SD_corroborateDocuments.sail, SD_getDrawCorroboration.sail."""
from refs import *
c = lambda n: fld(DOC, n)
l = lambda n: fld(LINE, n)

PROMPT = r'''/* Draw approval (Phase 5.5): the Runtime Prompt for reading one supporting document of a draw package (Execute
   Generative AI Skill, DocCenter's Doc Input skill, in SD Read Supporting Documents). The model classifies the document
   and copies its key facts; it is never given the budget template, so a figure that ties was read, not guessed.
   The answer is four pipe-delimited lines, parsed by SD_parseSupportingDocReading (split by position, never
   a!fromJson — a malformed answer cannot throw). */
"You read one document that arrived with a construction draw request for a hotel renovation, for the accounting team of a real-estate investment fund. Decide what kind of document it is and copy its key facts."
  & char(10) & char(10)
  & "Kinds:" & char(10)
  & "- PAY_APPLICATION: a contractor's application and certificate for payment (for example a G702-style application) requesting a progress payment." & char(10)
  & "- INVOICE: a vendor's or consultant's invoice or bill for goods or services." & char(10)
  & "- LIEN_WAIVER: a waiver and release of lien rights, conditional or unconditional." & char(10)
  & "- BACKUP: anything else, or any document you are not sure about."
  & char(10) & char(10)
  & "Answer with exactly these four plain text lines and nothing else: no Markdown, no code fences, no explanation." & char(10)
  & "TYPE|<PAY_APPLICATION, INVOICE, LIEN_WAIVER or BACKUP>" & char(10)
  & "PARTY|<for a pay application or a lien waiver: the contractor or claimant; for an invoice: the vendor; otherwise nothing>" & char(10)
  & "REFERENCE|<the application number or the invoice number exactly as printed; otherwise nothing>" & char(10)
  & "AMOUNT|<for a pay application: the current payment due; for an invoice: the total due; otherwise nothing. Digits and one decimal point only - no currency symbol, no commas - for example 1234567.89>" & char(10)
  & "Copy names and numbers exactly as printed. Never compute, total or guess a figure: if the figure is not printed, leave AMOUNT empty. Never put the | character inside a value."
'''

PARSE = r'''/* Draw approval (Phase 5.5): the deterministic gate on the AI's reading of one supporting document.
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
'''

GETDOCS = r'''/* Draw approval (Phase 5.5): a draw's supporting documents (every SD Draw Document row except the Budget Template),
   oldest first, as maps: rowId, document, name, type, status, amount, party, reference, notes. */
if(
  a!isNullOrEmpty(ri!drawId),
  {},
  a!localVariables(
    local!raw: a!queryRecordType(
      recordType: @DOC@,
      fields: {@C_ID@, @C_DOCUMENT@, @C_NAME@, @C_TYPE@, @C_STATUS@, @C_AMOUNT@, @C_PARTY@, @C_REF@, @C_NOTES@},
      filters: a!queryLogicalExpression(
        operator: "AND",
        filters: {
          a!queryFilter(field: @C_DRAW@, operator: "=", value: ri!drawId),
          a!queryFilter(field: @C_TYPE@, operator: "<>", value: "Budget Template")
        }
      ),
      pagingInfo: a!pagingInfo(startIndex: 1, batchSize: 50, sort: a!sortInfo(field: @C_ID@, ascending: true))
    ).data,
    if(
      a!isNullOrEmpty(local!raw),
      {},
      a!forEach(
        items: local!raw,
        expression: a!map(
          rowId: fv!item[@C_ID@],
          document: fv!item[@C_DOCUMENT@],
          name: tostring(a!defaultValue(fv!item[@C_NAME@], "")),
          type: tostring(a!defaultValue(fv!item[@C_TYPE@], "Backup")),
          status: tostring(a!defaultValue(fv!item[@C_STATUS@], "")),
          amount: fv!item[@C_AMOUNT@],
          party: tostring(a!defaultValue(fv!item[@C_PARTY@], "")),
          reference: tostring(a!defaultValue(fv!item[@C_REF@], "")),
          notes: tostring(a!defaultValue(fv!item[@C_NOTES@], ""))
        )
      )
    )
  )
)
'''

CORRO = r'''/* Draw approval (Phase 5.5): corroboration of a draw package — each supporting document tied out against the
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
'''

DRAWCORRO = r'''/* Draw approval (Phase 5.5): corroboration for a draw as committed — its supporting documents against its committed
   budget lines. Used by SD Receive Capital Call after confirm (node 44) to write the result onto the draw. */
a!localVariables(
  local!lines: if(
    a!isNullOrEmpty(ri!drawId),
    {},
    a!queryRecordType(
      recordType: @LINE@,
      fields: {@L_CAT@, @L_CD@, @L_ORDER@},
      filters: a!queryFilter(field: @L_DRAW@, operator: "=", value: ri!drawId),
      pagingInfo: a!pagingInfo(startIndex: 1, batchSize: 100, sort: a!sortInfo(field: @L_ORDER@, ascending: true))
    ).data
  ),
  rule!SD_corroborateDocuments(
    documents: rule!SD_getSupportingDocuments(drawId: ri!drawId),
    lineCategories: if(a!isNullOrEmpty(local!lines), {}, a!forEach(items: local!lines, expression: tostring(fv!item[@L_CAT@]))),
    lineCurrentDraws: if(a!isNullOrEmpty(local!lines), {}, a!forEach(items: local!lines, expression: a!defaultValue(fv!item[@L_CD@], 0)))
  )
)
'''

subs = {"@DOC@": rt(DOC), "@C_ID@": c("id"), "@C_DOCUMENT@": c("document"), "@C_NAME@": c("documentName"),
        "@C_TYPE@": c("documentType"), "@C_STATUS@": c("status"), "@C_AMOUNT@": c("extractedAmount"),
        "@C_PARTY@": c("extractedParty"), "@C_REF@": c("extractedReference"), "@C_NOTES@": c("notes"),
        "@C_DRAW@": c("drawId"), "@LINE@": rt(LINE), "@L_CAT@": l("budgetCategory"), "@L_CD@": l("currentDraw"),
        "@L_ORDER@": l("lineOrder"), "@L_DRAW@": l("drawId")}
for name, text in [("SD_supportingDocumentPrompt", PROMPT), ("SD_parseSupportingDocReading", PARSE),
                   ("SD_getSupportingDocuments", GETDOCS), ("SD_corroborateDocuments", CORRO),
                   ("SD_getDrawCorroboration", DRAWCORRO)]:
    for k, v in subs.items():
        text = text.replace(k, v)
    assert "@C_" not in text and "@L_" not in text and "@DOC@" not in text and "@LINE@" not in text
    open(name + ".sail", "w").write(text)
    print("wrote", name, len(text))

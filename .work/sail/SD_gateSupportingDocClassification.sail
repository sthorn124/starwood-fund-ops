/* Draw approval (Phase 5.6): the deterministic gate on a Doc Center classification verdict. The model's verdict is
   used only when every check passes; anything else files the document as Backup, "Not classified".
   - an instance must exist, with statusId 3 (Classified) or 4 / 6 (reconciled); 1 (Initiated), 8 (classified with
     errors) and 9 (instance error) fail;
   - the verdict must be exactly one of Pay Application, Invoice, Lien Waiver ("Other", empty or anything else fails);
   - when Doc Center reports a confidence, it must be at least ri!minConfidence (this instance's Generative AI path
     reports none, measured 2026-09-25, so only the first two checks decide here).
   Returns a map: ok, typeKey (PAY_APPLICATION / INVOICE / LIEN_WAIVER / BACKUP), documentType, verdict (what the model
   said), confidence, reason (why a document was not classified; "" when ok). */
a!localVariables(
  local!c: if(a!isNullOrEmpty(ri!classification), a!map(found: false), ri!classification),
  local!found: a!defaultValue(index(local!c, "found", false), false),
  local!verdict: trim(tostring(a!defaultValue(index(local!c, "classification", ""), ""))),
  local!status: a!defaultValue(index(local!c, "statusId", null), null),
  local!confidence: index(local!c, "confidence", null),
  local!labels: {"Pay Application", "Invoice", "Lien Waiver"},
  local!keys: {"PAY_APPLICATION", "INVOICE", "LIEN_WAIVER"},
  local!pos: if(local!verdict = "", 0, index(wherecontains(local!verdict, local!labels), 1, 0)),
  local!statusOk: if(a!isNullOrEmpty(local!status), false, contains({3, 4, 6}, tointeger(local!status))),
  local!confidenceOk: if(
    a!isNullOrEmpty(local!confidence),
    true,
    tointeger(local!confidence) >= a!defaultValue(ri!minConfidence, 0)
  ),
  local!reason: if(
    not(local!found),
    "Doc Center returned no classification",
    if(
      not(local!statusOk),
      "Doc Center classification ended with status " & a!defaultValue(local!status, "unknown"),
      if(
        local!pos = 0,
        if(local!verdict = "", "no category returned", "classified as " & local!verdict),
        if(local!confidenceOk, "", "confidence " & local!confidence & " below " & ri!minConfidence)
      )
    )
  ),
  local!ok: local!reason = "",
  a!map(
    ok: local!ok,
    typeKey: if(local!ok, index(local!keys, local!pos, "BACKUP"), "BACKUP"),
    documentType: if(local!ok, index(local!labels, local!pos, "Backup"), "Backup"),
    verdict: local!verdict,
    confidence: local!confidence,
    reason: local!reason
  )
)

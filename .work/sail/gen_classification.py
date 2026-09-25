"""Phase 5.6: rules for Doc Center classification of supporting documents and extraction on pay applications.
Writes five .sail files:
  SD_getSupportingDocClassification(document)          the newest Doc Center classification instance for the document
  SD_gateSupportingDocClassification(classification, minConfidence)   the deterministic gate on the verdict
  SD_getPayApplicationExtraction(document)             the newest Doc Center extraction instance and its values
  SD_gatePayApplicationExtraction(extraction)          the deterministic gate on the pay application's figures
  SD_supportingDocNotes(...)                           the Documents tab's per-document treatment line
No f-strings (SAIL braces)."""

CI = "'recordType!{bba819fb-55a0-47e1-bb74-e385f32b6916}AIA Classification Instance"
CIF = {"id": "c37dcf0a-9121-412d-815c-9cf8ab808987", "modelVersionId": "e2128500-29b6-4143-8739-a1fb810aa4b4",
       "documentId": "309857f9-08b4-4e1f-8f58-7056d45924cb", "sourceDocumentId": "3664ec70-c5b8-41fa-94a3-54992698d10c",
       "statusId": "eafba38c-479c-41cc-8401-9a7780c56ef0", "confidence": "498f9d66-55b7-4ce7-962e-0d095106af90",
       "classification": "ae0890a9-a317-4434-a2b3-4027d6a656a2", "reasoning": "16671b78-1d60-4ca6-b194-760009222ccc",
       "aiActions": "7d9c4763-62fe-46fa-8099-ef08097412b4", "createdOn": "de53ac81-f96e-4387-8313-5367745dd474",
       "modifiedOn": "892e8449-13f0-4e4c-b3ce-ab062ced1b4c", "validationErrors": "1ae570c0-eff6-4684-a33d-fd2902f3faa5"}
EI = "'recordType!{64322398-e457-4695-87d5-09794164cf77}AIA Extraction Instance"
EIF = {"id": "7a1970b4-ae29-4d49-96d5-3659721cff16", "statusId": "d0b39390-3147-451b-b49e-f4256e466577",
       "aiActions": "4905bbe8-7240-4898-b52b-0badf6c3540f", "createdOn": "c821645a-28b5-41c7-821b-85af4119c6be",
       "modifiedOn": "90898700-0cd9-41db-bf2c-ece3656b815c", "modelVersionId": "b597f1b0-ea3e-4f5c-8a7f-ae999e66f407",
       "validationErrors": "34d54369-4e12-400c-aad0-f4c538673a07"}


def ci(n):
    return CI + ".fields.{" + CIF[n] + "}" + n + "'"


def ei(n):
    return EI + ".fields.{" + EIF[n] + "}" + n + "'"


CI_FIELDS = ", ".join(ci(n) for n in CIF)
get_classification = """/* Draw approval (Phase 5.6): the Doc Center classification of one supporting document — the newest AIA Classification
   Instance whose documentId or sourceDocumentId is the document (read right after the synchronous run of
   AIA Classification Run Model Version, whose instance is not an output that can be mapped over the Dev MCP).
   Returns a map: found, instanceId, modelVersionId, classification, confidence (null on this instance's Generative AI
   path, measured 2026-09-25), reasoning, statusId, aiActions, createdOn, modifiedOn, validationErrors. */
a!localVariables(
  local!docId: if(a!isNullOrEmpty(ri!document), null, tointeger(ri!document)),
  local!row: if(
    a!isNullOrEmpty(local!docId),
    null,
    index(
      a!queryRecordType(
        recordType: @CI@',
        fields: {@CI_FIELDS@},
        filters: a!queryLogicalExpression(
          operator: "OR",
          filters: {
            a!queryFilter(field: @CI_documentId@, operator: "=", value: local!docId),
            a!queryFilter(field: @CI_sourceDocumentId@, operator: "=", value: local!docId)
          }
        ),
        pagingInfo: a!pagingInfo(startIndex: 1, batchSize: 1, sort: a!sortInfo(field: @CI_id@, ascending: false))
      ).data,
      1,
      null
    )
  ),
  if(
    a!isNullOrEmpty(local!row),
    a!map(found: false),
    a!map(
      found: true,
      instanceId: local!row[@CI_id@],
      modelVersionId: local!row[@CI_modelVersionId@],
      classification: tostring(a!defaultValue(local!row[@CI_classification@], "")),
      confidence: local!row[@CI_confidence@],
      reasoning: tostring(a!defaultValue(local!row[@CI_reasoning@], "")),
      statusId: local!row[@CI_statusId@],
      aiActions: a!defaultValue(local!row[@CI_aiActions@], 0),
      createdOn: local!row[@CI_createdOn@],
      modifiedOn: local!row[@CI_modifiedOn@],
      validationErrors: tostring(a!defaultValue(local!row[@CI_validationErrors@], ""))
    )
  )
)
"""
for n in CIF:
    get_classification = get_classification.replace("@CI_" + n + "@", ci(n))
get_classification = get_classification.replace("@CI_FIELDS@", CI_FIELDS).replace("@CI@", CI)

gate_classification = """/* Draw approval (Phase 5.6): the deterministic gate on a Doc Center classification verdict. The model's verdict is
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
"""

EI_FIELDS = ", ".join(ei(n) for n in EIF)
get_extraction = """/* Draw approval (Phase 5.6): Doc Center's extraction of one pay application — the newest AIA Extraction Instance for
   the document (rule!SD_getExtractionInstanceIdForDocument) with its status, AI actions and timestamps, and the values
   through DocCenter's public rule AIA_API_Extraction_ConvertInstanceIdToMap (model sdPayApplication: contractorName,
   applicationNumber, currentPaymentDue, each as printed).
   Returns a map: found, instanceId, statusId, aiActions, createdOn, modifiedOn, validationErrors, contractorName,
   applicationNumber, currentPaymentDue. */
a!localVariables(
  local!instanceId: rule!SD_getExtractionInstanceIdForDocument(document: ri!document),
  local!row: if(
    a!isNullOrEmpty(local!instanceId),
    null,
    index(
      a!queryRecordType(
        recordType: @EI@',
        fields: {@EI_FIELDS@},
        filters: a!queryFilter(field: @EI_id@, operator: "=", value: local!instanceId),
        pagingInfo: a!pagingInfo(startIndex: 1, batchSize: 1)
      ).data,
      1,
      null
    )
  ),
  local!values: if(a!isNullOrEmpty(local!instanceId), a!map(), rule!AIA_API_Extraction_ConvertInstanceIdToMap(instanceId: local!instanceId)),
  if(
    a!isNullOrEmpty(local!row),
    a!map(found: false),
    a!map(
      found: true,
      instanceId: local!instanceId,
      statusId: local!row[@EI_statusId@],
      aiActions: a!defaultValue(local!row[@EI_aiActions@], 0),
      createdOn: local!row[@EI_createdOn@],
      modifiedOn: local!row[@EI_modifiedOn@],
      validationErrors: tostring(a!defaultValue(local!row[@EI_validationErrors@], "")),
      contractorName: trim(tostring(a!defaultValue(index(local!values, "contractorName", ""), ""))),
      applicationNumber: trim(tostring(a!defaultValue(index(local!values, "applicationNumber", ""), ""))),
      currentPaymentDue: trim(tostring(a!defaultValue(index(local!values, "currentPaymentDue", ""), "")))
    )
  )
)
"""
for n in EIF:
    get_extraction = get_extraction.replace("@EI_" + n + "@", ei(n))
get_extraction = get_extraction.replace("@EI_FIELDS@", EI_FIELDS).replace("@EI@", EI)

gate_extraction = """/* Draw approval (Phase 5.6): the deterministic gate on a pay application's extracted figures. The Current Payment
   Due is used only when the instance exists with statusId 2 (Extracted) or 4 / 6 (reconciled) and the printed value,
   after removing "$", commas and spaces, is digits with at most one decimal point and at most two decimals, greater
   than zero. Anything else keeps the document typed as a Pay Application but with no figure ("the Current Payment Due
   could not be read"), which the corroboration shows in amber. Party and reference are kept as printed.
   Returns a map: ok, amount, amountText (as printed), party, reference, failures. */
a!localVariables(
  local!e: if(a!isNullOrEmpty(ri!extraction), a!map(found: false), ri!extraction),
  local!found: a!defaultValue(index(local!e, "found", false), false),
  local!status: index(local!e, "statusId", null),
  local!statusOk: if(a!isNullOrEmpty(local!status), false, contains({2, 4, 6}, tointeger(local!status))),
  local!printed: tostring(a!defaultValue(index(local!e, "currentPaymentDue", ""), "")),
  local!amountText: substitute(substitute(substitute(local!printed, ",", ""), "$", ""), " ", ""),
  local!shapeOk: if(
    len(local!amountText) = 0,
    false,
    and(
      and(a!forEach(items: enumerate(len(local!amountText)) + 1, expression: find(mid(local!amountText, fv!item, 1), "0123456789.") > 0)),
      len(local!amountText) - len(substitute(local!amountText, ".", "")) <= 1,
      if(find(".", local!amountText) = 0, true, len(local!amountText) - find(".", local!amountText) <= 2)
    )
  ),
  local!value: if(local!shapeOk, round(todecimal(local!amountText), 2), null),
  local!amount: if(and(local!found, local!statusOk, not(a!isNullOrEmpty(local!value))), if(local!value > 0, local!value, null), null),
  local!failures: reject(
    fn!isnull,
    {
      if(local!found, null, "Doc Center returned no extraction"),
      if(or(not(local!found), local!statusOk), null, "Doc Center extraction ended with status " & a!defaultValue(local!status, "unknown")),
      if(and(local!found, local!statusOk, a!isNullOrEmpty(local!amount)), "the Current Payment Due could not be read" & if(local!printed = "", "", " (printed as " & local!printed & ")"), null)
    }
  ),
  a!map(
    ok: not(a!isNullOrEmpty(local!amount)),
    amount: local!amount,
    amountText: local!printed,
    party: tostring(a!defaultValue(index(local!e, "contractorName", ""), "")),
    reference: tostring(a!defaultValue(index(local!e, "applicationNumber", ""), "")),
    failures: local!failures
  )
)
"""

notes = """/* Draw approval (Phase 5.6): the Documents tab's treatment line for one supporting document — what Doc Center did with
   it and what it cost. Classified only: "Classified by Doc Center as Invoice (sdDrawSupportingDocuments) · 38.1 s · 3 AI
   actions · filed, not read". Classified and read: the classification, then "Read by Doc Center extraction
   (sdPayApplication): Stonebridge Construction Group · Application No. 14 · Current Payment Due $2,490,296.23 · 24.6 s ·
   4 AI actions". Not classified: the reason. At most 1,000 characters. */
a!localVariables(
  local!v: if(a!isNullOrEmpty(ri!verdict), a!map(ok: false, reason: "no classification"), ri!verdict),
  local!c: if(a!isNullOrEmpty(ri!classification), a!map(), ri!classification),
  local!p: ri!payApp,
  local!e: if(a!isNullOrEmpty(ri!extraction), a!map(), ri!extraction),
  local!classifyCost: " · " & fixed(a!defaultValue(ri!classifySeconds, 0), 1) & " s · " & a!defaultValue(index(local!c, "aiActions", 0), 0) & " AI actions",
  local!classified: if(
    a!defaultValue(index(local!v, "ok", false), false),
    "Classified by Doc Center as " & index(local!v, "documentType", "") & " (" & ri!classificationModelKey & ")" & local!classifyCost,
    "Not classified by Doc Center (" & a!defaultValue(index(local!v, "reason", ""), "no reason") & "; " & ri!classificationModelKey & ")" & local!classifyCost & " · filed as Backup"
  ),
  local!read: if(
    a!isNullOrEmpty(local!p),
    if(a!defaultValue(index(local!v, "ok", false), false), " · filed, not read", ""),
    " · Read by Doc Center extraction (" & ri!extractionModelKey & "): " &
    joinarray(
      reject(
        fn!isnull,
        {
          if(a!defaultValue(index(local!p, "party", ""), "") = "", null, index(local!p, "party", "")),
          if(a!defaultValue(index(local!p, "reference", ""), "") = "", null, "Application No. " & index(local!p, "reference", "")),
          if(
            a!isNullOrEmpty(index(local!p, "amount", null)),
            joinarray(index(local!p, "failures", {}), "; "),
            "Current Payment Due " & rule!SD_fmtMoney(value: index(local!p, "amount", null), showCents: true)
          )
        }
      ),
      " · "
    ) &
    " · " & fixed(a!defaultValue(ri!extractSeconds, 0), 1) & " s · " & a!defaultValue(index(local!e, "aiActions", 0), 0) & " AI actions"
  ),
  left(local!classified & local!read, 1000)
)
"""

files = {
    "SD_getSupportingDocClassification.sail": get_classification,
    "SD_gateSupportingDocClassification.sail": gate_classification,
    "SD_getPayApplicationExtraction.sail": get_extraction,
    "SD_gatePayApplicationExtraction.sail": gate_extraction,
    "SD_supportingDocNotes.sail": notes,
}
for name, body in files.items():
    assert "@" not in body.replace("@appian", ""), name
    open(name, "w").write(body)
    print("wrote", name, len(body))

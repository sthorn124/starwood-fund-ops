/* Draw approval (Phase 5.6): the Documents tab's treatment line for one supporting document — what Doc Center did with
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

/* Draw approval (Phase 5.6): the deterministic gate on a pay application's extracted figures. The Current Payment
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

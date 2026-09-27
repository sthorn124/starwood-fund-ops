/* Draw approval (Phase 6c): a phone number as it is shown and logged — only its last four digits ("+1 ••• ••• 1234").
   The full number lives in the SMS recipient constant alone; the draw's exchange log never carries it. */
a!localVariables(
  local!digits: stripwith(a!defaultValue(ri!number, ""), " +-().abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"),
  if(len(local!digits) < 4, "(no number)", "+" & if(len(local!digits) > 10, left(local!digits, len(local!digits) - 10), "1") & " ••• ••• " & right(local!digits, 4))
)

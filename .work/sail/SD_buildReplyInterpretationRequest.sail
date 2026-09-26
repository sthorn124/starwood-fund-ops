/* Draw approval (Phase 6a): the one AI call's request (DocCenter's Text Input skill with a Runtime Prompt). The
   model reads only the reply's own words (SD_extractReplyText) and answers in two fixed lines; it never sees the
   draw's figures and never decides anything the gate does not check. */
a!localVariables(
  local!c: a!defaultValue(ri!context, a!map()),
  a!map(
    prompt: "You read one email reply from an approver in a capital-call draw approval workflow. The approver was asked to approve or reject a draw at their step (" & a!defaultValue(index(local!c, "role", ""), "") & "). Decide what the reply says about that request." & char(10) & char(10) &
      "Answer with exactly two lines and nothing else:" & char(10) &
      "DECISION|APPROVE or DECISION|REJECT or DECISION|AMBIGUOUS" & char(10) &
      "COMMENT|<the reply's substantive comment, copied word for word, or nothing>" & char(10) & char(10) &
      "Rules:" & char(10) &
      "- APPROVE only when the reply clearly approves the draw as it stands (for example: approved, looks good approve, OK to fund, go ahead)." & char(10) &
      "- REJECT only when the reply clearly declines or stops it (for example: rejected, do not fund, decline, hold this)." & char(10) &
      "- AMBIGUOUS for everything else: no decision yet, a question, a conditional or partial approval, a request for changes, mixed signals, or anything you are unsure about. Never guess." & char(10) &
      "- COMMENT: copy exactly, character for character, any remark in the reply beyond the bare decision (a reason, a condition, an instruction). Do not paraphrase, summarise or add words. Leave it empty if there is none." & char(10) &
      "- No explanation, no quotes around the lines, no other text.",
    inputText: a!defaultValue(ri!replyText, "")
  )
)

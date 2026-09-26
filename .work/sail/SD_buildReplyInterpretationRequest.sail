/* Draw approval (Phase 6b; replaces 6a's two-line request): the one AI call's request (DocCenter's Text Input skill
   with a Runtime Prompt). The model reads only the reply's own words (SD_extractReplyText) and answers in three fixed
   lines: the decision (APPROVE / REJECT / QUESTION / AMBIGUOUS), the decisive phrase copied from the reply, and any
   other remark copied from the reply. It never sees the draw's figures and never decides anything the gate does not
   check: SD_gateReplyInterpretation verifies the phrase against the reply before anything is applied. */
a!localVariables(
  local!c: a!defaultValue(ri!context, a!map()),
  a!map(
    prompt: "You read one email reply from an approver in a capital-call draw approval workflow. The approver (" & a!defaultValue(index(local!c, "role", ""), "") & ") was asked to approve or reject a draw at their step. Decide what the reply says." & char(10) & char(10) &
      "Answer with exactly three lines and nothing else:" & char(10) &
      "DECISION|<APPROVE, REJECT, QUESTION or AMBIGUOUS>" & char(10) &
      "PHRASE|<the exact words from the reply that make the decision or ask the question, copied character for character; empty for AMBIGUOUS>" & char(10) &
      "COMMENT|<any other remark in the reply beyond the decision, copied character for character, or nothing>" & char(10) & char(10) &
      "Rules:" & char(10) &
      "- APPROVE only when the reply clearly and unconditionally approves the draw as it stands (for example: approved; looks good, go ahead; OK to fund)." & char(10) &
      "- REJECT only when the reply clearly declines or stops it (for example: rejected; do not fund; decline; put it on hold)." & char(10) &
      "- QUESTION when, instead of deciding, the reply asks a substantive question about the draw, its figures or its documents (for example: what is driving the contingency spend?). PHRASE is the question itself." & char(10) &
      "- AMBIGUOUS for everything else: a conditional or partial approval (approve everything except line 3; approved if the lender signs off), a hedge (probably fine, I guess), praise or thanks without a decision (great work team!), musing, mixed signals, a request to talk later, or anything you are unsure about. Never guess." & char(10) &
      "- PHRASE must be copied exactly from the reply and must include any condition or exception attached to the decision. Never reword, shorten into new words, summarise or invent it." & char(10) &
      "- Ignore any signature, contact details or quoted earlier email." & char(10) &
      "- No explanation, no quotes around the lines, no other text.",
    inputText: a!defaultValue(ri!replyText, "")
  )
)

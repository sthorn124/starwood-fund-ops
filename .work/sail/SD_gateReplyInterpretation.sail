/* Draw approval (Phase 6b; hardens 6a's gate): the deterministic gate on the AI's reading of a reply. Nothing the
   model says is applied unless this rule can check it against the reply itself.
   Format: exactly one DECISION line (APPROVE, REJECT, QUESTION or AMBIGUOUS), at most one PHRASE line, at most one
   COMMENT line, nothing else (blank lines and code fences ignored). A failed call, an empty answer, an unknown
   decision, a missing or repeated line or any extra text is AMBIGUOUS with classified = false (the exception queue).
   Grounded quote (the ruled guardrail): APPROVE, REJECT and QUESTION need a decisive phrase, and the phrase must appear
   verbatim in the reply (case and spacing aside, search() on normalised text; no wildcards). A decision whose phrase
   is missing or not in the reply is AMBIGUOUS, never applied.
   Wording checks on the sentence(s) the phrase sits in (from the terminator before it to the first at or after its
   end), with punctuation as spaces:
     APPROVE   needs approval words, and must carry no refusal ("not approve", "do not fund", …) and no condition or
               exception ("except", "if", "unless", "until", "but", "pending", "for now", …): a conditional or partial
               approval is AMBIGUOUS whatever the model called it.
     REJECT    needs rejection words ("reject", "decline", "hold", "do not fund", "no", …). A reason or a condition for
               resubmitting does not undo a rejection, so no condition check.
     QUESTION  must read as one: a "?" in the phrase, or a question or ask opening ("what", "why", "tell me", …).
   A downgraded reading keeps classified = true, so it follows the ambiguous ladder (clarification, then the exception
   queue), and keeps its phrase when the phrase was grounded (shown on the Emails tab).
   The comment is kept only for APPROVE / REJECT and only if it is a verbatim quote of the reply.
   Returns a map: classified, decision, modelDecision, phrase, question, comment, grounded, reason. */
a!localVariables(
  local!resp: a!defaultValue(ri!response, ""),
  local!norm: substitute(substitute(local!resp, char(13) & char(10), char(10)), char(13), char(10)),
  local!lines: a!forEach(
    items: split(local!norm, char(10)),
    expression: a!localVariables(local!t: trim(a!defaultValue(fv!item, "")), if(or(local!t = "", left(local!t, 3) = "```"), null, local!t))
  ),
  local!content: if(a!isNullOrEmpty(local!lines), {}, reject(fn!isnull, local!lines)),
  local!decisions: if(a!isNullOrEmpty(local!content), {}, reject(fn!isnull, a!forEach(items: local!content, expression: if(upper(left(fv!item, 9)) = "DECISION|", fv!item, null)))),
  local!phrases: if(a!isNullOrEmpty(local!content), {}, reject(fn!isnull, a!forEach(items: local!content, expression: if(upper(left(fv!item, 7)) = "PHRASE|", fv!item, null)))),
  local!comments: if(a!isNullOrEmpty(local!content), {}, reject(fn!isnull, a!forEach(items: local!content, expression: if(upper(left(fv!item, 8)) = "COMMENT|", fv!item, null)))),
  local!otherCount: count(local!content) - count(local!decisions) - count(local!phrases) - count(local!comments),
  local!decisionLine: if(count(local!decisions) = 1, tostring(index(local!decisions, 1, "")), ""),
  local!decision: if(local!decisionLine = "", "", upper(trim(right(local!decisionLine, len(local!decisionLine) - 9)))),
  local!phraseLine: if(count(local!phrases) = 1, tostring(index(local!phrases, 1, "")), ""),
  local!rawPhrase: if(local!phraseLine = "", "", trim(right(local!phraseLine, len(local!phraseLine) - 7))),
  local!commentLine: if(count(local!comments) = 1, tostring(index(local!comments, 1, "")), ""),
  local!rawComment: if(local!commentLine = "", "", trim(right(local!commentLine, len(local!commentLine) - 8))),
  local!formatFailure: if(
    not(a!defaultValue(ri!success, false)),
    "The AI call failed" & if(a!defaultValue(ri!errorMessage, "") = "", ".", ": " & ri!errorMessage),
    if(
      local!resp = "",
      "The AI returned nothing.",
      if(
        count(local!decisions) <> 1,
        "The answer has " & count(local!decisions) & " DECISION lines (expected 1).",
        if(
          count(local!phrases) > 1,
          "The answer has " & count(local!phrases) & " PHRASE lines (expected at most 1).",
          if(
            count(local!comments) > 1,
            "The answer has " & count(local!comments) & " COMMENT lines (expected at most 1).",
            if(
              local!otherCount > 0,
              "The answer has " & local!otherCount & " line(s) outside the expected format.",
              if(not(contains({"APPROVE", "REJECT", "QUESTION", "AMBIGUOUS"}, local!decision)), "Unknown decision """ & local!decision & """.", "")
            )
          )
        )
      )
    )
  ),
  local!classified: local!formatFailure = "",
  local!replyNorm: rule!SD_normalizeReplyText(text: ri!replyText, forCues: false),
  local!phraseNorm: rule!SD_normalizeReplyText(text: local!rawPhrase, forCues: false),
  local!commentNorm: rule!SD_normalizeReplyText(text: local!rawComment, forCues: false),
  local!phrasePos: if(or(local!phraseNorm = "", local!replyNorm = ""), 0, search(local!phraseNorm, local!replyNorm)),
  local!grounded: local!phrasePos > 0,
  local!commentOk: or(local!commentNorm = "", and(local!replyNorm <> "", search(local!commentNorm, local!replyNorm) > 0)),
  local!window: if(
    not(local!grounded),
    "",
    a!localVariables(
      local!n: len(local!replyNorm),
      local!ends: reject(fn!isnull, a!forEach(items: enumerate(local!n) + 1, expression: if(contains({".", "!", "?"}, mid(local!replyNorm, fv!item, 1)), fv!item, null))),
      local!before: if(a!isNullOrEmpty(local!ends), {}, reject(fn!isnull, a!forEach(items: local!ends, expression: if(fv!item < local!phrasePos, fv!item, null)))),
      local!after: if(a!isNullOrEmpty(local!ends), {}, reject(fn!isnull, a!forEach(items: local!ends, expression: if(fv!item >= local!phrasePos + len(local!phraseNorm) - 1, fv!item, null)))),
      local!from: if(a!isNullOrEmpty(local!before), 0, max(local!before)),
      local!to: if(a!isNullOrEmpty(local!after), local!n + 1, min(local!after)),
      mid(local!replyNorm, local!from + 1, local!to - local!from)
    )
  ),
  local!windowCues: rule!SD_normalizeReplyText(text: local!window, forCues: true),
  local!phraseCues: rule!SD_normalizeReplyText(text: local!rawPhrase, forCues: true),
  local!hasApproval: or(a!forEach(items: {" approv", " go ahead", " proceed", " lgtm ", " looks good", " look good", " looks fine", " fund it ", " ok to fund", " okay to fund", " ok to proceed", " okay to proceed", " release", " sign off", " signed off", " yes ", " agreed ", " agree ", " good to go", " green light", " sounds good", " all good", " confirmed ", " fine to fund", " go for it"}, expression: search(fv!item, local!windowCues) > 0)),
  local!hasRefusal: or(a!forEach(items: {" not approv", " don t approv", " dont approv", " do not approv", " cannot approv", " can t approv", " cant approv", " won t approv", " wont approv", " will not approv", " never approv", " not ok ", " not okay ", " don t proceed", " dont proceed", " do not proceed", " not proceed", " no go ", " don t fund", " dont fund", " do not fund", " not fund", " don t release", " do not release", " hold off", " not yet "}, expression: search(fv!item, local!windowCues) > 0)),
  local!hasCondition: or(a!forEach(items: {" except", " unless ", " if ", " provided ", " providing ", " subject to ", " pending ", " once ", " as long as ", " assuming ", " contingent", " conditional", " until ", " but ", " however ", " only if ", " only after ", " only once ", " as soon as ", " partial", " partly ", " some of ", " most of ", " for now "}, expression: search(fv!item, local!windowCues) > 0)),
  local!hasRejection: or(a!forEach(items: {" reject", " declin", " deny ", " denied", " not approv", " don t approv", " dont approv", " do not approv", " cannot approv", " can t approv", " cant approv", " won t approv", " wont approv", " will not approv", " hold ", " on hold", " stop ", " do not proceed", " don t proceed", " dont proceed", " not proceed", " no go ", " don t fund", " dont fund", " do not fund", " send it back", " send back", " kick it back", " no ", " nope ", " pass on "}, expression: search(fv!item, local!windowCues) > 0)),
  local!isQuestion: or(
    search("?", local!phraseNorm) > 0,
    or(a!forEach(items: {" what ", " why ", " how ", " when ", " where ", " who ", " which ", " can ", " could ", " is ", " are ", " do ", " does ", " did ", " will ", " would ", " should ", " has ", " have ", " tell me", " explain", " please explain", " please tell", " help me understand", " walk me through", " clarify", " i d like to know", " i want to know", " i need to know", " need to understand"}, expression: left(local!phraseCues, len(fv!item)) = fv!item))
  ),
  local!downgrade: if(
    or(not(local!classified), not(contains({"APPROVE", "REJECT", "QUESTION"}, local!decision))),
    "",
    if(
      not(local!grounded),
      if(local!rawPhrase = "", "No decisive phrase was given", "The decisive phrase """ & left(local!rawPhrase, 120) & """ is not in the reply"),
      a!match(
        value: local!decision,
        equals: "APPROVE", then: if(local!hasRefusal, "The decisive words read as a refusal", if(not(local!hasApproval), "The decisive words contain no approval", if(local!hasCondition, "The approval is conditional or partial", ""))),
        equals: "REJECT", then: if(not(local!hasRejection), "The decisive words contain no rejection", ""),
        equals: "QUESTION", then: if(not(local!isQuestion), "The decisive words are not a question", ""),
        default: ""
      )
    )
  ),
  local!final: if(not(local!classified), "AMBIGUOUS", if(local!downgrade = "", local!decision, "AMBIGUOUS")),
  a!map(
    classified: local!classified,
    decision: local!final,
    modelDecision: local!decision,
    phrase: if(and(local!classified, local!grounded), left(local!rawPhrase, 1000), ""),
    question: if(local!final = "QUESTION", left(local!rawPhrase, 1000), ""),
    comment: if(and(local!classified, local!commentOk, or(local!final = "APPROVE", local!final = "REJECT")), left(local!rawComment, 500), ""),
    grounded: and(local!classified, local!grounded),
    reason: if(
      not(local!classified),
      local!formatFailure,
      if(
        local!downgrade <> "",
        local!downgrade & "; read as AMBIGUOUS (the AI said " & local!decision & ").",
        "Classified " & local!final & if(and(local!rawComment <> "", not(local!commentOk)), "; the comment was not a verbatim quote of the reply and was dropped", "") & "."
      )
    )
  )
)

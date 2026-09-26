/* Draw approval (Phase 6a): the deterministic gate on the AI's reading of a reply. The answer must be exactly the
   two expected lines (blank lines and code fences ignored): one DECISION line with APPROVE, REJECT or AMBIGUOUS, and one
   COMMENT line. The comment is kept only if it is a verbatim quote of the reply (case and spacing aside); otherwise
   it is dropped and the decision stands. Anything else - a failed call, an empty answer, an unknown decision, a
   missing or repeated line, any extra text - is AMBIGUOUS with classified = false: the handler routes it to the
   exception queue and never changes state on it.
   Returns a map: classified, decision, comment, reason. */
a!localVariables(
  local!resp: a!defaultValue(ri!response, ""),
  local!norm: substitute(substitute(local!resp, char(13) & char(10), char(10)), char(13), char(10)),
  local!lines: a!forEach(
    items: split(local!norm, char(10)),
    expression: a!localVariables(local!t: trim(a!defaultValue(fv!item, "")), if(or(local!t = "", left(local!t, 3) = "```"), null, local!t))
  ),
  local!content: if(a!isNullOrEmpty(local!lines), {}, reject(fn!isnull, local!lines)),
  local!decisionLines: if(a!isNullOrEmpty(local!content), {}, a!forEach(items: local!content, expression: if(upper(left(fv!item, 9)) = "DECISION|", fv!item, null))),
  local!commentLines: if(a!isNullOrEmpty(local!content), {}, a!forEach(items: local!content, expression: if(upper(left(fv!item, 8)) = "COMMENT|", fv!item, null))),
  local!decisions: if(a!isNullOrEmpty(local!decisionLines), {}, reject(fn!isnull, local!decisionLines)),
  local!comments: if(a!isNullOrEmpty(local!commentLines), {}, reject(fn!isnull, local!commentLines)),
  local!otherCount: count(local!content) - count(local!decisions) - count(local!comments),
  local!decision: if(count(local!decisions) = 1, upper(trim(right(local!decisions[1], len(local!decisions[1]) - 9))), ""),
  local!rawComment: if(count(local!comments) = 1, trim(right(local!comments[1], len(local!comments[1]) - 8)), ""),
  local!squash: lower(trim(joinarray(reject(fn!isnull, a!forEach(items: split(substitute(a!defaultValue(ri!replyText, ""), char(10), " "), " "), expression: if(trim(fv!item) = "", null, trim(fv!item)))), " "))),
  local!commentSquash: lower(trim(joinarray(reject(fn!isnull, a!forEach(items: split(local!rawComment, " "), expression: if(trim(fv!item) = "", null, trim(fv!item)))), " "))),
  local!commentOk: or(local!commentSquash = "", search(local!commentSquash, local!squash) > 0),
  local!failure: if(
    not(a!defaultValue(ri!success, false)),
    "The AI call failed" & if(a!defaultValue(ri!errorMessage, "") = "", ".", ": " & ri!errorMessage),
    if(
      local!resp = "",
      "The AI returned nothing.",
      if(
        count(local!decisions) <> 1,
        "The answer has " & count(local!decisions) & " DECISION lines (expected 1).",
        if(
          count(local!comments) > 1,
          "The answer has " & count(local!comments) & " COMMENT lines (expected at most 1).",
          if(
            local!otherCount > 0,
            "The answer has " & local!otherCount & " line(s) outside the expected format.",
            if(not(contains({"APPROVE", "REJECT", "AMBIGUOUS"}, local!decision)), "Unknown decision """ & local!decision & """.", "")
          )
        )
      )
    )
  ),
  local!classified: local!failure = "",
  a!map(
    classified: local!classified,
    decision: if(local!classified, local!decision, "AMBIGUOUS"),
    comment: if(and(local!classified, local!commentOk), left(local!rawComment, 500), ""),
    reason: if(
      not(local!classified),
      local!failure,
      if(local!commentOk, "Classified " & local!decision & ".", "Classified " & local!decision & "; the comment was not a verbatim quote of the reply and was dropped.")
    )
  )
)

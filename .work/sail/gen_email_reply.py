"""Phase 6a: the email-reply rules. Writes one .sail file per rule. No f-strings (SAIL braces and quotes).

  SD_parseReplyToken(subject)            the [SD-DRAW-<drawId>-S<step>] reference token, stable across Re:/Fwd:
  SD_extractReplyText(body)              the reply's own words: HTML stripped, quoted history and signatures cut
  SD_getReplyContext(drawId, stepOrder, fromAddress)
                                         the draw/step/sender checks, in order: UNMATCHED, UNAUTHORIZED, GUARDRAIL,
                                         NOT_AWAITING, OK; plus what the handler needs (approval row, role, amount,
                                         prior ambiguous replies on the step, the step email's subject)
  SD_buildReplyInterpretationRequest(replyText, context)
                                         the Runtime Prompt and Input Text for the one AI call
  SD_gateReplyInterpretation(success, response, errorMessage, replyText)
                                         the deterministic gate: exact two-line format, decision in the set, the
                                         comment kept only if it is a verbatim quote of the reply; anything else is
                                         AMBIGUOUS with classified = false (never a guess)
  SD_buildReplyResponseEmail(kind, context, replyText)
                                         the clarification / guardrail refusal: "Re: <step subject>", same visual
                                         language as the step email
  SD_getDrawEmailMessages(drawId)        the draw's email exchange as maps, oldest first (Emails tab since 6b)
Phase 6b: the request asks for three lines (DECISION with QUESTION added, the verbatim decisive PHRASE, COMMENT); the gate
grounds the phrase in the reply and checks its sentence's wording; the response builder adds ANSWER and RECEIPT;
  SD_normalizeReplyText(text, forCues)   lower case, straight quotes, collapsed whitespace (cue form: punctuation as
                                         spaces, padded) for the gate's comparisons
  SD_getPendingQuestion(drawId)          the pending approver question, derived from the message log
"""
from refs import *

m = lambda n: fld(MSG, n)
a = lambda n: fld(APPR, n)
d = lambda n: fld(DRAW, n)

TOKEN = r'''/* Draw approval (Phase 6a): the reference token in a step email's subject, "[SD-DRAW-<drawId>-S<stepOrder>]".
   Mail clients keep the subject on a reply or forward and only prefix it (Re:, RE:, Fwd:, AW:, …), so the token is found
   anywhere in the subject, case-insensitive. Returns a map: found, drawId, stepOrder, token. */
a!localVariables(
  local!s: a!defaultValue(ri!subject, ""),
  local!start: search("[SD-DRAW-", local!s),
  local!rest: if(local!start = 0, "", mid(local!s, local!start + 9, 40)),
  local!close: if(local!rest = "", 0, search("]", local!rest)),
  local!inner: if(local!close = 0, "", left(local!rest, local!close - 1)),
  local!parts: if(local!inner = "", {}, split(local!inner, "-")),
  local!drawText: if(count(local!parts) <> 2, "", index(local!parts, 1, "")),
  local!stepText: if(count(local!parts) <> 2, "", index(local!parts, 2, "")),
  local!isDigits: a!forEach(
    items: {local!drawText, if(upper(left(local!stepText, 1)) = "S", right(local!stepText, len(local!stepText) - 1), "")},
    expression: and(len(fv!item) > 0, len(fv!item) <= 9, len(stripwith(fv!item, "0123456789")) = 0)
  ),
  local!ok: and(local!isDigits),
  a!map(
    found: local!ok,
    drawId: if(local!ok, tointeger(local!drawText), null),
    stepOrder: if(local!ok, tointeger(right(local!stepText, len(local!stepText) - 1)), null),
    token: if(local!ok, "[SD-DRAW-" & local!inner & "]", "")
  )
)
'''

EXTRACT = r'''/* Draw approval (Phase 6a; 6b signature cuts): the reply's own words. A mail client's reply carries the whole approval email beneath
   it (quoted with ">" in plain text, or after an "On <date>, <name> wrote:" line, or in an HTML quote container), and
   that email itself says "Approve" and "Reject", so the history must never reach the interpretation. An HTML body is
   cut at its quote container and stripped line by line; the text is then cut
   at the first quote marker (a ">" line, an "On … wrote:" line — also when the client wraps it onto a second line —
   "-----Original Message-----", an Outlook
   "From:" header block or its underscore divider, "Sent from my …"; Phase 6b adds the "-- " signature delimiter and
   Gmail's HTML signature container); blank lines collapse; at most 2,000 characters. A signature with no delimiter in a
   plain-text reply (Gmail's plain-text part, measured on a live reply) stays in the text: harmless to the reading, which
   rests on the decisive phrase, and shown as sent. */
a!localVariables(
  local!raw: substitute(substitute(a!defaultValue(ri!body, ""), char(13) & char(10), char(10)), char(13), char(10)),
  /* HTML only when real markup is present: a plain-text reply can hold "<name@host>" in its attribution line, and
     stripHtml() deletes plain newlines (measured), which would weld the reply to the quoted history */
  local!isHtml: or(
    search("<html", local!raw) > 0, search("<body", local!raw) > 0, search("<div", local!raw) > 0,
    search("<br", local!raw) > 0, search("<p>", local!raw) > 0, search("<p ", local!raw) > 0, search("</", local!raw) > 0
  ),
  /* HTML: cut at the client's quote container (Gmail's gmail_quote div, a blockquote, Outlook's reply header or rule)
     before stripping, then turn line-ending tags into line breaks and strip each line on its own */
  local!cutAt: a!localVariables(
    local!hits: a!forEach(
      items: {"<div class=""gmail_quote", "class=""gmail_quote", "<blockquote", "id=""divRplyFwdMsg", "id=""appendonsend", "<hr", "class=""gmail_signature", "data-smartmail=""gmail_signature"},
      /* an attribute marker (class=…, id=…, data-smartmail=…) cuts at the start of the tag that carries it (measured:
         Gmail's signature div opens with dir="ltr" before its class, which would otherwise be left behind) */
      expression: a!localVariables(
        local!h: search(fv!item, local!raw),
        if(
          or(local!h = 0, left(fv!item, 1) = "<"),
          local!h,
          a!localVariables(
            local!parts: split(left(local!raw, local!h - 1), "<"),
            if(count(local!parts) <= 1, local!h, local!h - len(index(local!parts, count(local!parts), "")) - 1)
          )
        )
      )
    ),
    local!found: where(a!forEach(items: local!hits, expression: fv!item > 0)),
    if(a!isNullOrEmpty(local!found), 0, min(index(local!hits, local!found, {})))
  ),
  local!htmlPart: if(local!cutAt > 1, left(local!raw, local!cutAt - 1), if(local!cutAt = 1, "", local!raw)),
  local!htmlBroken: a!localVariables(
    local!h: local!htmlPart,
    local!h2: substitute(substitute(substitute(substitute(local!h, "<br>", char(10)), "<br/>", char(10)), "<br />", char(10)), "<BR>", char(10)),
    local!h3: substitute(substitute(substitute(substitute(local!h2, "</div>", char(10)), "</DIV>", char(10)), "</p>", char(10)), "</P>", char(10)),
    joinarray(a!forEach(items: split(local!h3, char(10)), expression: stripHtml(a!defaultValue(fv!item, ""))), char(10))
  ),
  local!norm: if(local!isHtml, local!htmlBroken, local!raw),
  local!lines: split(local!norm, char(10)),
  local!n: count(local!lines),
  local!isMarker: a!forEach(
    items: local!lines,
    expression: a!localVariables(
      local!t: trim(a!defaultValue(fv!item, "")),
      or(
        left(local!t, 1) = ">",
        and(left(local!t, 3) = "On ", or(right(local!t, 6) = "wrote:", right(trim(a!defaultValue(index(local!lines, fv!index + 1, ""), "")), 6) = "wrote:")),
        search("-----Original Message-----", local!t) > 0,
        left(local!t, 10) = "__________",
        and(left(local!t, 5) = "From:", fv!index > 1),
        left(local!t, 13) = "Sent from my ",
        /* Phase 6b: the standard signature delimiter ("-- " on its own line; trimmed to "--") */
        local!t = "--"
      )
    )
  ),
  local!firstMarker: if(local!n = 0, 0, a!localVariables(local!w: where(local!isMarker), if(a!isNullOrEmpty(local!w), 0, index(local!w, 1, 0)))),
  local!kept: if(local!n = 0, {}, if(local!firstMarker = 0, local!lines, if(local!firstMarker = 1, {}, index(local!lines, enumerate(local!firstMarker - 1) + 1, {})))),
  local!nonBlank: if(a!isNullOrEmpty(local!kept), {}, a!forEach(items: local!kept, expression: if(trim(a!defaultValue(fv!item, "")) = "", "", trim(fv!item)))),
  local!joined: trim(joinarray(reject(fn!isnull, a!forEach(items: local!nonBlank, expression: if(fv!item = "", null, fv!item))), char(10))),
  left(local!joined, 2000)
)
'''

CONTEXT = r'''/* Draw approval (Phase 6a): everything the reply handler decides before any AI call, from the records at the time
   of the reply. Checks run in this order, and the first that fails names the verdict:
     UNMATCHED     no token, or the token names a draw or step that does not exist
     UNAUTHORIZED  the sender is not the authorized reply address for the step's role (SD_EMAIL_REPLY_ROLES /
                   SD_EMAIL_REPLY_ADDRESSES); no reply is ever sent to an unauthorized sender
     GUARDRAIL     the draw amount is above SD_EMAIL_APPROVAL_MAX: email cannot decide it at any step
     NOT_AWAITING  the draw is not In Progress at this step, or the step's row is not In Progress
     OK            the reply may be interpreted
   Also returns the approval row id, role, approver name, draw number, investment, amount, the number of earlier
   ambiguous replies on this approval row (a second one goes to the exception queue) and the step email's subject
   (for "Re:" on anything sent back). */
a!localVariables(
  local!state: if(a!isNullOrEmpty(ri!drawId), null, rule!SD_getDrawState(ri!drawId)),
  local!found: and(not(a!isNullOrEmpty(local!state)), a!defaultValue(index(local!state, "found", false), false)),
  local!rows: if(
    or(not(local!found), a!isNullOrEmpty(ri!stepOrder)),
    {},
    a!queryRecordType(
      recordType: @APPR@,
      fields: {@A_ID@, @A_ORDER@, @A_ROLE@, @A_NAME@, @A_STATUS@},
      filters: {
        a!queryFilter(field: @A_DRAW@, operator: "=", value: ri!drawId),
        a!queryFilter(field: @A_ORDER@, operator: "=", value: ri!stepOrder)
      },
      pagingInfo: a!pagingInfo(startIndex: 1, batchSize: 5)
    ).data
  ),
  local!row: if(a!isNullOrEmpty(local!rows), null, index(local!rows, 1, null)),
  local!approvalId: if(a!isNullOrEmpty(local!row), null, local!row[@A_ID@]),
  local!role: if(a!isNullOrEmpty(local!row), "", tostring(local!row[@A_ROLE@])),
  local!approverName: if(a!isNullOrEmpty(local!row), "", tostring(local!row[@A_NAME@])),
  local!rowStatus: if(a!isNullOrEmpty(local!row), "", tostring(local!row[@A_STATUS@])),
  local!from: lower(trim(a!defaultValue(ri!fromAddress, ""))),
  local!roleIndex: if(local!role = "", {}, wherecontains(local!role, cons!SD_EMAIL_REPLY_ROLES)),
  local!authorizedAddress: if(a!isNullOrEmpty(local!roleIndex), "", lower(trim(index(cons!SD_EMAIL_REPLY_ADDRESSES, local!roleIndex[1], "")))),
  local!authorized: and(local!authorizedAddress <> "", local!from = local!authorizedAddress),
  local!amount: if(local!found, todecimal(a!defaultValue(index(local!state, "amount", 0), 0)), 0),
  local!overLimit: local!amount > todecimal(cons!SD_EMAIL_APPROVAL_MAX),
  local!drawStatus: if(local!found, tostring(a!defaultValue(index(local!state, "drawStatus", ""), "")), ""),
  local!currentStep: if(local!found, tointeger(a!defaultValue(index(local!state, "currentStep", -1), -1)), -1),
  local!awaiting: and(local!drawStatus = "In Progress", local!currentStep = tointeger(ri!stepOrder), local!rowStatus = "In Progress"),
  local!priorAmbiguous: if(
    a!isNullOrEmpty(local!approvalId),
    0,
    a!queryRecordType(
      recordType: @MSG@,
      fields: {@M_ID@},
      filters: {
        a!queryFilter(field: @M_APPROVAL@, operator: "=", value: local!approvalId),
        a!queryFilter(field: @M_DIRECTION@, operator: "=", value: "INBOUND"),
        a!queryFilter(field: @M_OUTCOME@, operator: "=", value: "AMBIGUOUS")
      },
      pagingInfo: a!pagingInfo(startIndex: 1, batchSize: 1),
      fetchTotalCount: true
    ).totalCount
  ),
  local!verdict: if(
    or(not(local!found), a!isNullOrEmpty(local!row)),
    "UNMATCHED",
    if(not(local!authorized), "UNAUTHORIZED", if(local!overLimit, "GUARDRAIL", if(not(local!awaiting), "NOT_AWAITING", "OK")))
  ),
  a!map(
    verdict: local!verdict,
    reason: a!match(
      value: local!verdict,
      equals: "UNMATCHED", then: if(a!isNullOrEmpty(ri!drawId), "No draw reference token in the subject.", "The subject names draw " & ri!drawId & " step " & a!defaultValue(ri!stepOrder, "?") & ", which does not exist."),
      equals: "UNAUTHORIZED", then: "Sender " & a!defaultValue(ri!fromAddress, "(none)") & " is not the authorized reply address for the " & local!role & " step.",
      equals: "GUARDRAIL", then: "Draw amount " & rule!SD_fmtMoney(value: local!amount, showCents: true) & " is above the email approval limit of " & rule!SD_fmtMoney(value: cons!SD_EMAIL_APPROVAL_MAX, showCents: false) & ".",
      equals: "NOT_AWAITING", then: "The draw is " & local!drawStatus & " at step " & local!currentStep & "; step " & ri!stepOrder & " (" & local!role & ") is " & if(local!rowStatus = "", "not active", local!rowStatus) & ".",
      default: "Awaiting the " & local!role & " decision."
    ),
    drawId: ri!drawId,
    stepOrder: ri!stepOrder,
    approvalId: local!approvalId,
    role: local!role,
    approverName: local!approverName,
    drawNumber: if(local!found, index(local!state, "drawNumber", null), null),
    investmentName: if(local!found, tostring(a!defaultValue(index(local!state, "investmentName", ""), "")), ""),
    amount: local!amount,
    drawStatus: local!drawStatus,
    currentStep: local!currentStep,
    authorized: local!authorized,
    overLimit: local!overLimit,
    awaiting: local!awaiting,
    priorAmbiguous: local!priorAmbiguous,
    stepSubject: if(or(not(local!found), a!isNullOrEmpty(ri!stepOrder)), "", index(rule!SD_buildApprovalEmail(drawId: ri!drawId, stepOrder: ri!stepOrder), "subject", ""))
  )
)
'''

REQUEST = r'''/* Draw approval (Phase 6b; replaces 6a's two-line request): the one AI call's request (DocCenter's Text Input skill
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
'''

NORMALIZE = r'''/* Draw approval (Phase 6b): reply text normalised for comparison by the interpretation gate. Lower case, curly quotes
   and apostrophes made straight, every run of whitespace (spaces, tabs, line breaks) one space, trimmed. With forCues,
   punctuation also becomes spaces and the result is padded with one space each side, so a cue such as " go ahead"
   matches whole words only ("don't" becomes "don t"). */
a!localVariables(
  local!cues: a!defaultValue(ri!forCues, false),
  local!t0: lower(a!defaultValue(ri!text, "")),
  local!t1: substitute(substitute(substitute(substitute(local!t0, "’", "'"), "‘", "'"), "“", """"), "”", """"),
  local!t2: if(
    local!cues,
    @PUNCT@,
    local!t1
  ),
  local!words: reject(
    fn!isnull,
    a!forEach(
      items: split(substitute(substitute(substitute(local!t2, char(13), " "), char(10), " "), char(9), " "), " "),
      expression: if(trim(a!defaultValue(fv!item, "")) = "", null, trim(fv!item))
    )
  ),
  local!joined: if(a!isNullOrEmpty(local!words), "", joinarray(local!words, " ")),
  if(local!cues, " " & local!joined & " ", local!joined)
)
'''
PUNCT_CHARS = [".", ",", "!", "?", ";", ":", "\"\"", "'", "(", ")", "-", "*", "/", "_", "[", "]", "…", "–", "—"]
_p = "local!t1"
for ch in PUNCT_CHARS:
    _p = "substitute(" + _p + ", \"" + ch + "\", \" \")"
NORMALIZE = NORMALIZE.replace("@PUNCT@", _p)


def _sail_list(items):
    return "{" + ", ".join("\"" + i + "\"" for i in items) + "}"


APPROVE_CUES = [" approv", " go ahead", " proceed", " lgtm ", " looks good", " look good", " looks fine", " fund it ",
                " ok to fund", " okay to fund", " ok to proceed", " okay to proceed", " release", " sign off",
                " signed off", " yes ", " agreed ", " agree ", " good to go", " green light", " sounds good",
                " all good", " confirmed ", " fine to fund", " go for it"]
NEGATED_APPROVAL = [" not approv", " don t approv", " dont approv", " do not approv", " cannot approv", " can t approv",
                    " cant approv", " won t approv", " wont approv", " will not approv", " never approv", " not ok ",
                    " not okay ", " don t proceed", " dont proceed", " do not proceed", " not proceed", " no go ",
                    " don t fund", " dont fund", " do not fund", " not fund", " don t release", " do not release",
                    " hold off", " not yet "]
REJECT_CUES = [" reject", " declin", " deny ", " denied", " not approv", " don t approv", " dont approv",
               " do not approv", " cannot approv", " can t approv", " cant approv", " won t approv", " wont approv",
               " will not approv", " hold ", " on hold", " stop ", " do not proceed", " don t proceed", " dont proceed",
               " not proceed", " no go ", " don t fund", " dont fund", " do not fund", " send it back", " send back",
               " kick it back", " no ", " nope ", " pass on "]
CONDITIONS = [" except", " unless ", " if ", " provided ", " providing ", " subject to ", " pending ", " once ",
              " as long as ", " assuming ", " contingent", " conditional", " until ", " but ", " however ", " only if ",
              " only after ", " only once ", " as soon as ", " partial", " partly ", " some of ", " most of ",
              " for now "]
QUESTION_STARTS = [" what ", " why ", " how ", " when ", " where ", " who ", " which ", " can ", " could ", " is ",
                   " are ", " do ", " does ", " did ", " will ", " would ", " should ", " has ", " have ", " tell me",
                   " explain", " please explain", " please tell", " help me understand", " walk me through",
                   " clarify", " i d like to know", " i want to know", " i need to know", " need to understand"]

GATE = r'''/* Draw approval (Phase 6b; hardens 6a's gate): the deterministic gate on the AI's reading of a reply. Nothing the
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
  local!hasApproval: or(a!forEach(items: @APPROVE_CUES@, expression: search(fv!item, local!windowCues) > 0)),
  local!hasRefusal: or(a!forEach(items: @NEGATED_APPROVAL@, expression: search(fv!item, local!windowCues) > 0)),
  local!hasCondition: or(a!forEach(items: @CONDITIONS@, expression: search(fv!item, local!windowCues) > 0)),
  local!hasRejection: or(a!forEach(items: @REJECT_CUES@, expression: search(fv!item, local!windowCues) > 0)),
  local!isQuestion: or(
    search("?", local!phraseNorm) > 0,
    or(a!forEach(items: @QUESTION_STARTS@, expression: left(local!phraseCues, len(fv!item)) = fv!item))
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
'''
GATE = (GATE.replace("@APPROVE_CUES@", _sail_list(APPROVE_CUES)).replace("@NEGATED_APPROVAL@", _sail_list(NEGATED_APPROVAL))
        .replace("@CONDITIONS@", _sail_list(CONDITIONS)).replace("@REJECT_CUES@", _sail_list(REJECT_CUES))
        .replace("@QUESTION_STARTS@", _sail_list(QUESTION_STARTS)))

RESPONSE = r'''/* Draw approval (Phase 6a; Phase 6b adds ANSWER and RECEIPT): what the flow sends on the reply thread, in the step
   email's visual language (navy band, plain table, inline styles). Subject "Re: <step email subject>" (the token rides
   along), so the thread holds and the next reply still reaches the right draw and step.
     CLARIFICATION  the reply did not clearly approve or reject; ask for a clear answer; nothing changed
     GUARDRAIL      the draw is above the email approval limit; decide in the system; nothing changed
     ANSWER         the draw approval team's answer to the approver's question (answeredBy, questionText, answerText);
                    the approver can then decide, or ask again, by reply
     RECEIPT        a decision by email was applied (decision APPROVE / REJECT, outcome = the transition's outcome);
                    no action requested, no reply expected
   Returns a map: subject, html, text (the short plain text logged on the draw; for ANSWER the answer itself). */
a!localVariables(
  local!c: a!defaultValue(ri!context, a!map()),
  local!kind: upper(a!defaultValue(ri!kind, "")),
  local!name: a!defaultValue(index(local!c, "approverName", ""), ""),
  local!drawNo: a!defaultValue(index(local!c, "drawNumber", ""), ""),
  local!drawLabel: "Draw #" & local!drawNo & " · " & a!defaultValue(index(local!c, "investmentName", ""), ""),
  local!amount: rule!SD_fmtMoney(value: index(local!c, "amount", 0), showCents: true),
  local!stepSubject: a!defaultValue(index(local!c, "stepSubject", ""), ""),
  local!subject: if(left(upper(local!stepSubject), 3) = "RE:", local!stepSubject, "Re: " & local!stepSubject),
  local!isFinal: left(upper(a!defaultValue(ri!outcome, "")), 8) = "APPROVED",
  local!lead: a!match(
    value: local!kind,
    equals: "GUARDRAIL", then: "Email approval is not available for this draw. Its amount, " & local!amount & ", is above the " & rule!SD_fmtMoney(value: cons!SD_EMAIL_APPROVAL_MAX, showCents: false) & " limit for decisions by email, so the decision must be made in the system. Your reply has not changed the draw.",
    equals: "ANSWER", then: a!defaultValue(ri!answeredBy, "The draw approval team") & " answered your question on this draw.",
    equals: "RECEIPT", then: if(
      upper(a!defaultValue(ri!decision, "")) = "REJECT",
      "Recorded as your rejection of Draw #" & local!drawNo & ", " & local!amount & ". The draw will not proceed.",
      "Recorded as your approval of Draw #" & local!drawNo & ", " & local!amount & ". The chain has advanced." & if(local!isFinal, " This was the final approval.", "")
    ),
    default: "We could not tell from your reply whether you approve or reject this draw, so nothing has been changed. Please reply to this email with a clear decision, for example ""Approved"" or ""Rejected"", and add any comment you want recorded with it."
  ),
  local!quoted: rule!SD_htmlEscape(text: left(a!defaultValue(ri!replyText, ""), 600)),
  local!questionHtml: rule!SD_htmlEscape(text: left(a!defaultValue(ri!questionText, ""), 1000)),
  local!answerHtml: substitute(rule!SD_htmlEscape(text: a!defaultValue(ri!answerText, "")), char(10), "<br>"),
  local!quoteBlock: "<tr><td style=""padding:4px 18px 12px 18px;""><table role=""presentation"" cellpadding=""0"" cellspacing=""0"" style=""border-left:3px solid #CBD5E1;""><tr><td style=""padding:4px 10px;font-size:12px;line-height:17px;color:#475569;font-style:italic;"">",
  local!body: a!match(
    value: local!kind,
    equals: "ANSWER", then:
      if(local!questionHtml = "", "", local!quoteBlock & "Your question: " & local!questionHtml & "</td></tr></table></td></tr>") &
      "<tr><td style=""padding:4px 18px 14px 18px;font-size:13px;line-height:20px;color:#1F2937;"">" & local!answerHtml & "</td></tr>",
    equals: "RECEIPT", then: "",
    default: if(local!quoted = "", "", local!quoteBlock & "Your reply: " & local!quoted & "</td></tr></table></td></tr>")
  ),
  local!footer: a!match(
    value: local!kind,
    equals: "GUARDRAIL", then: "Open the draw in Starwood Draw Approvals to record your decision.",
    equals: "ANSWER", then: "Reply to this email to approve or reject, or to ask another question. Your reply is recorded on the draw.",
    equals: "RECEIPT", then: "No reply is needed.",
    default: "Reply to this email to answer. Your reply is recorded on the draw."
  ),
  local!html:
    "<table role=""presentation"" width=""100%"" cellpadding=""0"" cellspacing=""0"" style=""max-width:640px;border-collapse:collapse;font-family:Arial,Helvetica,sans-serif;"">" &
    "<tr><td style=""background:#16294D;color:#FFFFFF;padding:12px 18px;font-size:15px;font-weight:bold;"">" & rule!SD_htmlEscape(text: local!drawLabel) & "</td></tr>" &
    "<tr><td style=""padding:14px 18px 6px 18px;font-size:13px;line-height:19px;color:#1F2937;"">Hello " & rule!SD_htmlEscape(text: if(local!name = "", "approver", local!name)) & ",</td></tr>" &
    "<tr><td style=""padding:6px 18px 10px 18px;font-size:13px;line-height:19px;color:#1F2937;"">" & rule!SD_htmlEscape(text: local!lead) & "</td></tr>" &
    local!body &
    "<tr><td style=""background:#16294D;color:#FFFFFF;padding:10px 18px;font-size:12px;font-style:italic;"">" & local!footer & "</td></tr>" &
    "</table>",
  a!map(
    subject: local!subject,
    html: local!html,
    text: if(local!kind = "ANSWER", a!defaultValue(ri!answerText, ""), left(local!lead, 1000))
  )
)
'''

MESSAGES = r'''/* Draw approval (Phase 6a; 6b adds decisivePhrase and senderName): a draw's email exchange, oldest first (by time,
   then id), as maps for the Emails tab and the pending-question rule. */
a!localVariables(
  local!rows: if(
    a!isNullOrEmpty(ri!drawId),
    {},
    a!queryRecordType(
      recordType: @MSG@,
      fields: {@M_ID@, @M_APPROVAL@, @M_STEP@, @M_DIRECTION@, @M_KIND@, @M_FROM@, @M_TO@, @M_SUBJECT@, @M_BODY@, @M_AT@, @M_OUTCOME@, @M_INTERP@, @M_SOURCE@, @M_NOTES@, @M_PHRASE@, @M_SENDER@},
      filters: a!queryFilter(field: @M_DRAW@, operator: "=", value: ri!drawId),
      pagingInfo: a!pagingInfo(startIndex: 1, batchSize: 200, sort: {a!sortInfo(field: @M_AT@, ascending: true), a!sortInfo(field: @M_ID@, ascending: true)})
    ).data
  ),
  if(
    a!isNullOrEmpty(local!rows),
    {},
    a!forEach(
      items: local!rows,
      expression: a!map(
        id: fv!item[@M_ID@],
        approvalId: fv!item[@M_APPROVAL@],
        stepOrder: fv!item[@M_STEP@],
        direction: tostring(a!defaultValue(fv!item[@M_DIRECTION@], "")),
        kind: tostring(a!defaultValue(fv!item[@M_KIND@], "")),
        fromAddress: tostring(a!defaultValue(fv!item[@M_FROM@], "")),
        toAddress: tostring(a!defaultValue(fv!item[@M_TO@], "")),
        subject: tostring(a!defaultValue(fv!item[@M_SUBJECT@], "")),
        body: tostring(a!defaultValue(fv!item[@M_BODY@], "")),
        messageAt: fv!item[@M_AT@],
        outcome: tostring(a!defaultValue(fv!item[@M_OUTCOME@], "")),
        interpretation: tostring(a!defaultValue(fv!item[@M_INTERP@], "")),
        source: tostring(a!defaultValue(fv!item[@M_SOURCE@], "")),
        notes: tostring(a!defaultValue(fv!item[@M_NOTES@], "")),
        decisivePhrase: tostring(a!defaultValue(fv!item[@M_PHRASE@], "")),
        senderName: tostring(a!defaultValue(fv!item[@M_SENDER@], ""))
      )
    )
  )
)
'''

PENDING = r'''/* Draw approval (Phase 6b): the draw's pending approver question, derived from the message log (no stored flag).
   A question is an INBOUND reply the gate read as QUESTION. The latest one is pending while no ANSWER has been sent
   after it (message ids only grow) and the step it was asked at is still the one awaiting a decision (a decision by
   email or by task ends it; the question stays on the thread). Returns a map: pending, messageId, approvalId, stepOrder,
   role, question, askedAt, fromAddress, approverAddress (the step role's authorized reply address, where an answer
   goes), unanswered (questions since the last answer), messageCount. */
a!localVariables(
  local!msgs: rule!SD_getDrawEmailMessages(drawId: ri!drawId),
  local!isQuestion: if(a!isNullOrEmpty(local!msgs), {}, a!forEach(items: local!msgs, expression: and(fv!item.direction = "INBOUND", fv!item.outcome = "QUESTION"))),
  local!isAnswer: if(a!isNullOrEmpty(local!msgs), {}, a!forEach(items: local!msgs, expression: fv!item.kind = "ANSWER")),
  local!qPos: if(a!isNullOrEmpty(local!isQuestion), {}, where(local!isQuestion)),
  local!aPos: if(a!isNullOrEmpty(local!isAnswer), {}, where(local!isAnswer)),
  local!last: if(a!isNullOrEmpty(local!qPos), null, index(local!msgs, index(local!qPos, count(local!qPos), null), null)),
  local!lastAnswerId: if(a!isNullOrEmpty(local!aPos), 0, max(a!forEach(items: local!aPos, expression: tointeger(index(local!msgs, fv!item, null).id)))),
  local!unanswered: if(a!isNullOrEmpty(local!qPos), 0, sum(a!forEach(items: local!qPos, expression: if(tointeger(index(local!msgs, fv!item, null).id) > local!lastAnswerId, 1, 0)))),
  local!state: if(a!isNullOrEmpty(local!last), null, rule!SD_getDrawState(ri!drawId)),
  local!current: if(a!isNullOrEmpty(local!state), null, index(local!state, "current", null)),
  local!awaiting: and(
    not(a!isNullOrEmpty(local!last)),
    not(a!isNullOrEmpty(local!current)),
    tostring(a!defaultValue(index(local!state, "drawStatus", ""), "")) = "In Progress",
    tointeger(a!defaultValue(index(local!state, "currentStep", -1), -1)) = tointeger(a!defaultValue(index(local!last, "stepOrder", -2), -2)),
    tostring(a!defaultValue(index(local!current, "status", ""), "")) = "In Progress"
  ),
  local!answered: and(not(a!isNullOrEmpty(local!last)), local!lastAnswerId > tointeger(a!defaultValue(index(local!last, "id", 0), 0))),
  local!role: if(a!isNullOrEmpty(local!current), "", tostring(a!defaultValue(index(local!current, "role", ""), ""))),
  local!roleIndex: if(local!role = "", {}, wherecontains(local!role, cons!SD_EMAIL_REPLY_ROLES)),
  a!map(
    pending: and(local!awaiting, not(local!answered)),
    messageId: if(a!isNullOrEmpty(local!last), null, index(local!last, "id", null)),
    approvalId: if(a!isNullOrEmpty(local!last), null, index(local!last, "approvalId", null)),
    stepOrder: if(a!isNullOrEmpty(local!last), null, index(local!last, "stepOrder", null)),
    role: local!role,
    question: if(
      a!isNullOrEmpty(local!last),
      "",
      if(a!defaultValue(index(local!last, "decisivePhrase", ""), "") = "", a!defaultValue(index(local!last, "body", ""), ""), index(local!last, "decisivePhrase", ""))
    ),
    askedAt: if(a!isNullOrEmpty(local!last), null, index(local!last, "messageAt", null)),
    fromAddress: if(a!isNullOrEmpty(local!last), "", a!defaultValue(index(local!last, "fromAddress", ""), "")),
    approverAddress: if(a!isNullOrEmpty(local!roleIndex), "", tostring(index(cons!SD_EMAIL_REPLY_ADDRESSES, local!roleIndex[1], ""))),
    unanswered: local!unanswered,
    messageCount: count(local!msgs)
  )
)
'''

subs = {"@APPR@": rt(APPR), "@A_ID@": a("id"), "@A_DRAW@": a("drawId"), "@A_ORDER@": a("approvalOrder"),
        "@A_ROLE@": a("role"), "@A_NAME@": a("approverName"), "@A_STATUS@": a("status"),
        "@MSG@": rt(MSG), "@M_ID@": m("id"), "@M_DRAW@": m("drawId"), "@M_APPROVAL@": m("approvalId"),
        "@M_STEP@": m("stepOrder"), "@M_DIRECTION@": m("direction"), "@M_KIND@": m("kind"), "@M_FROM@": m("fromAddress"),
        "@M_TO@": m("toAddress"), "@M_SUBJECT@": m("subject"), "@M_BODY@": m("body"), "@M_AT@": m("messageAt"),
        "@M_OUTCOME@": m("outcome"), "@M_INTERP@": m("interpretation"), "@M_SOURCE@": m("source"), "@M_NOTES@": m("notes"),
        "@M_PHRASE@": m("decisivePhrase"), "@M_SENDER@": m("senderName")}
for name, text in [("SD_parseReplyToken", TOKEN), ("SD_extractReplyText", EXTRACT), ("SD_getReplyContext", CONTEXT),
                   ("SD_buildReplyInterpretationRequest", REQUEST), ("SD_gateReplyInterpretation", GATE),
                   ("SD_buildReplyResponseEmail", RESPONSE), ("SD_getDrawEmailMessages", MESSAGES),
                   ("SD_normalizeReplyText", NORMALIZE), ("SD_getPendingQuestion", PENDING)]:
    for k, v in subs.items():
        text = text.replace(k, v)
    assert "@A_" not in text and "@M_" not in text and "@MSG@" not in text and "@APPR@" not in text, name
    open(name + ".sail", "w").write(text)
    print("wrote", name, len(text))

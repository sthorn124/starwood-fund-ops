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
  SD_getDrawEmailMessages(drawId)        the draw's email exchange as maps, oldest first, for the Approvals tab
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

EXTRACT = r'''/* Draw approval (Phase 6a): the reply's own words. A mail client's reply carries the whole approval email beneath
   it (quoted with ">" in plain text, or after an "On <date>, <name> wrote:" line, or in an HTML quote container), and
   that email itself says "Approve" and "Reject", so the history must never reach the interpretation. An HTML body is
   cut at its quote container and stripped line by line; the text is then cut
   at the first quote marker (a ">" line, an "On … wrote:" line — also when the client wraps it onto a second line —
   "-----Original Message-----", an Outlook
   "From:" header block or its underscore divider, "Sent from my …"); blank lines collapse; at most 2,000 characters. */
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
      items: {"<div class=""gmail_quote", "class=""gmail_quote", "<blockquote", "id=""divRplyFwdMsg", "id=""appendonsend", "<hr"},
      expression: search(fv!item, local!raw)
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
        left(local!t, 13) = "Sent from my "
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

REQUEST = r'''/* Draw approval (Phase 6a): the one AI call's request (DocCenter's Text Input skill with a Runtime Prompt). The
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
'''

GATE = r'''/* Draw approval (Phase 6a): the deterministic gate on the AI's reading of a reply. The answer must be exactly the
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
'''

RESPONSE = r'''/* Draw approval (Phase 6a): what the flow sends back on the reply thread, in the step email's visual language
   (navy band, plain table, inline styles). kind CLARIFICATION: the reply did not clearly approve or reject; ask for a
   clear answer, nothing changed. kind GUARDRAIL: the draw is above the email approval limit; the decision must be made
   in the system, nothing changed. Subject "Re: <step email subject>" (the token rides along), so the thread holds.
   Returns a map: subject, html, text (a short plain summary for the Approvals tab). */
a!localVariables(
  local!c: a!defaultValue(ri!context, a!map()),
  local!kind: upper(a!defaultValue(ri!kind, "")),
  local!name: a!defaultValue(index(local!c, "approverName", ""), ""),
  local!drawLabel: "Draw #" & a!defaultValue(index(local!c, "drawNumber", ""), "") & " · " & a!defaultValue(index(local!c, "investmentName", ""), ""),
  local!stepSubject: a!defaultValue(index(local!c, "stepSubject", ""), ""),
  local!subject: if(left(upper(local!stepSubject), 3) = "RE:", local!stepSubject, "Re: " & local!stepSubject),
  local!lead: if(
    local!kind = "GUARDRAIL",
    "Email approval is not available for this draw. Its amount, " & rule!SD_fmtMoney(value: index(local!c, "amount", 0), showCents: true) & ", is above the " & rule!SD_fmtMoney(value: cons!SD_EMAIL_APPROVAL_MAX, showCents: false) & " limit for decisions by email, so the decision must be made in the system. Your reply has not changed the draw.",
    "We could not tell from your reply whether you approve or reject this draw, so nothing has been changed. Please reply to this email with a clear decision, for example ""Approved"" or ""Rejected"", and add any comment you want recorded with it."
  ),
  local!quoted: rule!SD_htmlEscape(text: left(a!defaultValue(ri!replyText, ""), 600)),
  local!html:
    "<table role=""presentation"" width=""100%"" cellpadding=""0"" cellspacing=""0"" style=""max-width:640px;border-collapse:collapse;font-family:Arial,Helvetica,sans-serif;"">" &
    "<tr><td style=""background:#16294D;color:#FFFFFF;padding:12px 18px;font-size:15px;font-weight:bold;"">" & rule!SD_htmlEscape(text: local!drawLabel) & "</td></tr>" &
    "<tr><td style=""padding:14px 18px 6px 18px;font-size:13px;line-height:19px;color:#1F2937;"">Hello " & rule!SD_htmlEscape(text: if(local!name = "", "approver", local!name)) & ",</td></tr>" &
    "<tr><td style=""padding:6px 18px 10px 18px;font-size:13px;line-height:19px;color:#1F2937;"">" & rule!SD_htmlEscape(text: local!lead) & "</td></tr>" &
    if(local!quoted = "", "", "<tr><td style=""padding:4px 18px 12px 18px;""><table role=""presentation"" cellpadding=""0"" cellspacing=""0"" style=""border-left:3px solid #CBD5E1;""><tr><td style=""padding:4px 10px;font-size:12px;line-height:17px;color:#475569;font-style:italic;"">Your reply: " & local!quoted & "</td></tr></table></td></tr>") &
    "<tr><td style=""background:#16294D;color:#FFFFFF;padding:10px 18px;font-size:12px;font-style:italic;"">" & if(local!kind = "GUARDRAIL", "Open the draw in Starwood Draw Approvals to record your decision.", "Reply to this email to answer. Your reply is recorded on the draw.") & "</td></tr>" &
    "</table>",
  a!map(
    subject: local!subject,
    html: local!html,
    text: left(local!lead, 1000)
  )
)
'''

MESSAGES = r'''/* Draw approval (Phase 6a): a draw's email exchange, oldest first, as maps for the Approvals tab. */
a!localVariables(
  local!rows: if(
    a!isNullOrEmpty(ri!drawId),
    {},
    a!queryRecordType(
      recordType: @MSG@,
      fields: {@M_ID@, @M_APPROVAL@, @M_STEP@, @M_DIRECTION@, @M_KIND@, @M_FROM@, @M_TO@, @M_SUBJECT@, @M_BODY@, @M_AT@, @M_OUTCOME@, @M_INTERP@, @M_SOURCE@, @M_NOTES@},
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
        notes: tostring(a!defaultValue(fv!item[@M_NOTES@], ""))
      )
    )
  )
)
'''

subs = {"@APPR@": rt(APPR), "@A_ID@": a("id"), "@A_DRAW@": a("drawId"), "@A_ORDER@": a("approvalOrder"),
        "@A_ROLE@": a("role"), "@A_NAME@": a("approverName"), "@A_STATUS@": a("status"),
        "@MSG@": rt(MSG), "@M_ID@": m("id"), "@M_DRAW@": m("drawId"), "@M_APPROVAL@": m("approvalId"),
        "@M_STEP@": m("stepOrder"), "@M_DIRECTION@": m("direction"), "@M_KIND@": m("kind"), "@M_FROM@": m("fromAddress"),
        "@M_TO@": m("toAddress"), "@M_SUBJECT@": m("subject"), "@M_BODY@": m("body"), "@M_AT@": m("messageAt"),
        "@M_OUTCOME@": m("outcome"), "@M_INTERP@": m("interpretation"), "@M_SOURCE@": m("source"), "@M_NOTES@": m("notes")}
for name, text in [("SD_parseReplyToken", TOKEN), ("SD_extractReplyText", EXTRACT), ("SD_getReplyContext", CONTEXT),
                   ("SD_buildReplyInterpretationRequest", REQUEST), ("SD_gateReplyInterpretation", GATE),
                   ("SD_buildReplyResponseEmail", RESPONSE), ("SD_getDrawEmailMessages", MESSAGES)]:
    for k, v in subs.items():
        text = text.replace(k, v)
    assert "@A_" not in text and "@M_" not in text and "@MSG@" not in text and "@APPR@" not in text, name
    open(name + ".sail", "w").write(text)
    print("wrote", name, len(text))

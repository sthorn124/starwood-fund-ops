# Closeout — 2026-09-26 — Phase 6b: approver Q&A on the email thread, grounded interpretation, decision receipts

## Scope and identity
- **Build work:** Dev MCP `appian` as `scott.thorn@appian.com`, full scope. The account is in `SD Administrators`, `SD Users`, the three step groups and `SD Draw Demo Approvers`.
- **Persona work:** sail as `sd.accountant`, a member of `SD Draw Demo Approvers`. It read the Summary pending card, drove the Emails-tab reply box, and re-read every tab fresh.
- **Not used:** `appian-runtime` and `--from-devmcp`.
- **Draw 66 untouched:** step 3, step process 536909994, `updatedAt` 2026-09-22 15:34:33.

## Bookkeeping
- **Scott's live Gmail reply passed.** Row 19 on draw 94 (#79), from scott.thorn@appian.com: "This looks good to me. Go ahead with the draw and proceed." It was read as APPROVE and completed the chain. His real address was kept, and Reply-To routed the reply to the receiver.
- **Still owed from that check:** the exception-form Mark Reviewed click (there is no review row yet) and the email-lane geometry.
- **Ruling recorded:** the conversational step-email copy stands. The sample's red exact-match warning is deliberately gone and is narrated, not reproduced.
- **BUILD_PLAN rescoped:**
  - **6b** is this conversation lane.
  - **6c** is the velocity set: task-escalation reminders, a chase digest on a site view, cycle-time capture, and SMS staged. It also takes the Asset Manager edit, treasury content, tie-out colour and feed staging.

## What was built
**Questions are a first-class outcome.**
- The AI call now returns three lines: `DECISION` (APPROVE / REJECT / QUESTION / AMBIGUOUS), the verbatim `PHRASE`, and the verbatim `COMMENT`.
- A QUESTION changes nothing and is logged with outcome Question and the question as its phrase. Nothing is sent to the approver.
- It is **pending**, derived from the log, until an answer follows it or the step is decided.
- **Where it shows:**
  - the **Summary**, to the draw approval team: amber "The CEO asked a question by email — answer it from the Emails tab", with an **Answer Question** button;
  - the **Emails tab**, to everyone.

**The grounded-quote gate** (`SD_gateReplyInterpretation` v2).
- APPROVE, REJECT and QUESTION need a phrase that appears verbatim in the reply, ignoring case and spacing. A missing or invented phrase makes the reading AMBIGUOUS, never applied.
- On top of that, fixed rules read the phrase's sentence:
  - **APPROVE** needs approval words, with no refusal and no condition or exception (except, if, unless, until, but, pending, for now…);
  - **REJECT** needs rejection words;
  - **QUESTION** must read as a question.
- A downgraded reading follows the clarification / exception ladder. The phrase is stored on the message row, shown in the Reading, and written into the approval row's comment.

**The specialist's answer from the record.**
- The Emails tab's reply box (members of `SD Draw Demo Approvers` only) starts the new `SD Answer Draw Question` process.
- It sends the answer on the same thread ("Re: <step subject>", Reply-To the receiver) to the step role's authorized address.
- It logs the answer with the specialist's name, which clears the pending state.
- The process's initiator role is `SD Draw Demo Approvers` only. A break-test with no pending question sent nothing.

**The thread has its own tab.**
- **Emails** now sits between Approvals and Documents, as a two-sided conversation:
  - the approver's messages on the left with a slate bar; the flow's and the team's on the right, navy on a faint tint;
  - direction is also written on every message;
  - each message shows sender, kind, time, step, text, the AI READING (decisive phrase plus reading) and an outcome tag;
  - a pending question sits at the top in amber, with the reply box.
- Approvals keeps the pointer "N approval emails on this draw · View the email exchange".

**Decision receipts.** After an applied decision, the handler sends "Recorded as your approval of Draw #<n>, $<amount>. The chain has advanced." on the thread. Final approval adds "This was the final approval."; a rejection has its own wording. The footer reads "No reply is needed", and the receipt is logged. Treasury is unchanged: it runs before the receipt.

**Also:**
- `SD_extractReplyText` now cuts Gmail's signature container and the "-- " delimiter.
- The message table gained `decisivePhrase` and `senderName`, with widths measured by a real write (1,000 / 255; the readback said 255 for both).

## Objects (read back at close-out)
| Object | Id | State |
|---|---|---|
| Process `SD Handle Approval Reply` | `0000f074-9a9b-…` | 29 nodes (70 QUESTION log; 42–45 receipt; phrase and sender on every row), validator clean |
| Process `SD Answer Draw Question` | `0000f074-ad0d-8000-2600-7f0000014e7a` | 10 nodes, validator clean, initiator `SD Draw Demo Approvers` |
| Process `SD Draw Approval Step` | `0000f06e-a547-…` | node 13 writes the sender name; validator clean |
| Constant `SD_ANSWER_QUESTION_PM` | `…_575728` | → `SD Answer Draw Question` |
| Rules `SD_normalizeReplyText`, `SD_getPendingQuestion` (new) | `…_575680`, `…_575706` | identical to the repo |
| Rules `SD_buildReplyInterpretationRequest` v2, `SD_gateReplyInterpretation` v2, `SD_buildReplyResponseEmail` v2, `SD_getDrawEmailMessages` v2, `SD_extractReplyText` v4, `SD_newEmailMessage` v2 | `…_575577`, `…_575583`, `…_575601`, `…_575589`, `…_575571`, `…_575627` | identical to the repo |
| Interface `SD_view_drawEmails` → view **Emails** (stub `_ivHayg`) | `…_575734` | v1, `error: null` |
| Interfaces `SD_view_drawApprovals` v4 (pointer), `SD_view_drawSummary` v10 (pending card) | `…_570853`, `…_570837` | identical to the repo |
| Fields `decisivePhrase` (1,000), `senderName` (255) on `SD Draw Email Message` | `9a40d4fd-…`, `e014b841-…` | widths measured |
| `SD_EMAIL_REPLY_ADDRESSES` | `…_575553` | v5: all nine roles scott.thorn@appian.com, restored after the test mapping |

## Verified
- **Gauntlet: 45/45.**
  - Token T1–T8.
  - Extraction X1–X11, including the signature cuts, and Scott's plain-text signature pinned as kept.
  - Format G1–G10.
  - **Grounding N1–N16:** clean approve, clean reject, question, hedge, conditional "except" and "if" (including trimmed phrases), enthusiasm, a fabricated phrase, a non-question, a refusal read as approval, Scott's live reply, a fabricated question, "for now", and a later sentence's "if" not tainting the decision.
- **Live prompt probe, 8 specimens, all as stated:**
  - **APPROVE:** clean approve, and Scott's reply with its signature.
  - **REJECT:** reject.
  - **QUESTION:** the contingency question.
  - **AMBIGUOUS:** the hedge, "except line 3", "if the lender signs off", and "great work team!". The model quoted each condition inside its phrase.
- **End to end on draw 95 (#80), without touching draw 66:**

| Step | Result |
|---|---|
| Unauthorized "Approved." (production mapping) | UNAUTHORIZED, nothing changed |
| Question: "what's driving the contingency spend on this draw?" | QUESTION logged, no email sent, pending. As `sd.accountant`: the Summary amber card and **Answer Question**; the Emails tab question card with **Your answer** and **Send Answer** (disabled while empty) |
| Answer typed and sent **as `sd.accountant` via sail** | ANSWER on the thread, sender "Priya Raman", notes naming `sd.accountant`. Pending cleared; a fresh read shows the card gone and the answer on the thread |
| "Thanks. Approved if the lender signs off on the revised budget." | AMBIGUOUS, the conditional phrase stored, clarification sent, nothing changed |
| "Thanks, that covers it. Approved, go ahead and fund the draw." | APPROVE, phrase "Approved, go ahead and fund the draw." stored. Draw **Approved**, treasury 14:50:40. Receipt at 14:50:46: "Recorded as your approval of Draw #80, $2,604,252.23. The chain has advanced. This was the final approval." |
| Guardrail regression on Gateway #12 | refused, refusal sent, nothing changed |

- **Emails tab of #80, as `sd.accountant`:** 8 messages. Outcome tags in order: Approval request sent, Sender not authorized, Question, Answer sent, Unclear · clarification sent, Clarification sent, Approved by email, Receipt sent.
- **Approvals of #80:** the pointer is present, and the CEO row's comment carries the decisive phrase.
- **Test mapping:** CAO + CEO → the loop address (v4), then restored (v5), both read back.
- **Cleanup confirmed by absence:** the probe, the loop sender, the width probe and the gauntlet runner.
- **Draw 86 (#73)** is staged at the CEO step for Scott's live Q&A check. Its step email reached his inbox at 10:53 AM EDT.

## Not verified — browser checklists (TODO)
- **Live Q&A loop from Gmail (on draw 86, #73):**
  1. Ask a question from your inbox.
  2. As `sd.accountant`, see the Summary card and the Emails reply box.
  3. As `sd.assetmanager`, see no reply box and no Summary card. This non-member branch has not been exercised yet.
  4. Send the answer; it clears the card.
  5. In Gmail, the answer lands **in the same thread**.
  6. Reply "thanks, approved". #73 is Approved, and the receipt lands in the same thread.
  7. Geometry of the amber cards.
- **Exception review click and email-lane geometry:**
  - task 22161: Mark Reviewed writes the first review row;
  - the Emails tab on #77–#80 and #12, at desktop and phone width;
  - the Approvals pointer.

## Rulings needed
- **Questions on a draw above the email limit** currently get the guardrail refusal, because the limit check runs before the AI reads the reply. Should they reach the draw approval team as questions instead? (TODO, Client validation.)
- **Carried:**
  - the pay-application tie against $0.00 when there is no Hard Costs line;
  - "Does not tie" colour.

## Findings
- **A Gmail reply's signature stays in the stored text.** Gmail's plain-text part has no "-- " delimiter, so nothing marks where the signature starts. Recorded as a known data artifact; the reading is unaffected.
- **The decisive phrase makes each email decision self-auditing on the approval row:** the reply, the reading, and the words it was read on.

## Promotion candidates
- **1 promoted** into appian-supplemental §9 ("Mail an Appian Cloud instance sends is stamped from the site's system address…"): the From re-stamping, routing replies by Reply-To, testing authorized paths with a temporary mapping, and the email trigger being Designer-only. The repo copy of the skill is synced.
- **2 resolved:** the trigger schema fact, folded into the promoted entry; and the bare-`pv!` Send E-Mail trap, already recorded.
- **1 re-staged:** `msg!body` carries the text/plain part when there is one.
- **2 new staged:** sail `load --fresh` after an interact; the prompt-method observation.
- **Method trigger fired again:** the working form was applied.
- **Checkpoint:** current through this entry.

## TODO changes
- **Added:**
  - Browser checks owed: "Live Q&A loop from Gmail (Phase 6b)" and "Exception review click and email-lane geometry".
  - Client validation: "Questions on a draw above the email limit".
  - Before demo: 6b additions to the email beat.
- **Moved to Done:** Phase 6b; Scott's live Gmail reply (6a steps 1–4).
- **Struck through (ruled):** "The step email's reply copy".
- **Replaced:** the 6a browser item, by the two browser items above.
- **Deferred, amended:** "Email paths proven by rule tests only" now also names the non-member view.

## BUILD_PLAN changes
- **6a:** the live-reply and copy-ruling items are marked ✅ 2026-09-26.
- **6b:** rescoped to the conversation lane; all six items are marked ✅ 2026-09-26. Added: Scott's live Q&A loop, and the ruling on questions for over-limit draws.
- **New Phase 6c:** the velocity set, plus the former 6b carry-overs.

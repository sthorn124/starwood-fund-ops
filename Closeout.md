# Closeout — 2026-09-26 — Phase 6a: CEO email approval with AI reply interpretation

## Scope and identity
- **Build work:** Dev MCP `appian` as `scott.thorn@appian.com`. Full scope: `SD Administrators`, `SD Users`, and all three step groups. That makes this account the recipient of every step email and a member of the exception queue's group.
- **Handler:** runs its unattended nodes as DESIGNER. The receiver hands off as DESIGNER.
- **Persona readback:** sail as `sd.accountant` (`~/.sail-sd.accountant`).
- **Not used:** `appian-runtime` and `--from-devmcp`.
- **Draw 66 untouched:** re-read at the end, In Progress at step 3, step process 536909994, `updatedAt` 2026-09-22 15:34:33.
- **Scott's part, in Designer:** he set the receiver's Receive Message (Email) trigger, Public Events and the trigger mappings. The Dev MCP cannot set any of these.

## What was built
**Capability first (brief item 1).**
- Inbound email to a process works on `ny.appiancloud.com`, proven by loop test: email sent from the instance started `SD Receive Approval Reply`, which handed sender, subject and body to the handler.
- Nothing was faked.
- The receiver's address is `processmodeluuid0000f074-9ac4-8000-25d1-7f0000014e7a@ny.appiancloud.com`.

**Receiver → handler.**
- `SD Receive Approval Reply` is two nodes: the email start, and an asynchronous hand-off.
- `SD Handle Approval Reply` has 24 nodes and runs these steps:
  1. **Read** the `[SD-DRAW-<id>-S<step>]` token (stable across Re:/RE:/Fwd:) and the reply's own words. Quoted history is cut; it would otherwise say "Approve Reject".
  2. **Check, in order:**
     - the draw and step exist;
     - the sender is authorized (the constant role→address mapping; every role is scott.thorn@appian.com);
     - the **dollar guardrail** (`SD_EMAIL_APPROVAL_MAX` $5,000,000);
     - the step is awaiting a decision.

     A failed check changes nothing and is logged on the draw. Only the guardrail answers the sender, with a refusal on the thread.
  3. **One Generative AI call** reads the reply (skill 148, Claude Sonnet 4.6, about 3.3 s and 1 AI action).
  4. **A deterministic gate** (`SD_gateReplyInterpretation`) accepts exactly two lines, a known decision, and a verbatim comment. Anything else is an unclassified AMBIGUOUS.
  5. **APPROVE or REJECT** goes through `SD Apply Draw Approval Decision` with source EMAIL. The actor is the sender, and the comment is the reply plus the reading. The transition supersedes the open task. Final approval notifies treasury.
  6. **A first unclear reply** gets a clarification on the thread.
  7. **A second unclear reply, or an unclassifiable one,** becomes the **Review email reply** task for `SD Draw Demo Approvers` (`SD_form_emailException`). No email is sent and nothing changes.

**Thread continuity.**
- Every outbound message is sent from the receiver address with the display name "Starwood Draw Approvals" and Reply-To the receiver. This covers the step email, the clarification and the refusal.
- Responses carry "Re: <step subject>".
- Every inbound and outbound message, and the exception review, is a `SD Draw Email Message` row. The Approvals tab shows them in a new **Email Exchange** card: When / Message (direction, source, step, text) / Reading (the AI reading and the notes line) / Outcome tag.
- The step process now records each step email on the draw (new node 13).

**Other changes.**
- `SD_buildApprovalEmail` v3:
  - the subject ends with the token;
  - the reply instruction invites a reply "in your own words";
  - the red warning is gone;
  - a draw over the limit gets an amber "email approval is not available" line.
- `scripts/seed_draw66.py --cleanup-ingested` takes `msgs=`.
- `PROJECT_INSTRUCTIONS.md` carries the new rules: dollar guardrail, thread continuity, and reply matching and checks. Phase 6 is split into 6a and 6b.

## Objects (read back at close-out)
| Object | Id | State |
|---|---|---|
| Process `SD Receive Approval Reply` | `0000f074-9ac4-8000-25d1-7f0000014e7a` | 2 nodes; trigger and Public Events set in Designer; the description still names old, unused PVs (TODO) |
| Process `SD Handle Approval Reply` | `0000f074-9a9b-8000-25ce-7f0000014e7a` | v1, 34 PVs, 24 nodes, validator clean; the gateway is node 6 because a node's type cannot change on update |
| Process `SD Draw Approval Step` | `0000f06e-a547-8000-24cc-7f0000014e7a` | node 8 sender and Reply-To, new node 13, 2 new PVs; validator clean |
| Record type `SD Draw Email Message` | `3686a81f-86e2-498e-a4d1-ce40236c824a` | widths **measured** through a real Write Records node: 255 / 1,000 / 1,000 / 4,000 / 1,000 / 1,000 |
| Rules `SD_parseReplyToken`, `SD_extractReplyText` (v2), `SD_buildReplyInterpretationRequest`, `SD_gateReplyInterpretation`, `SD_getDrawEmailMessages`, `SD_getReplyContext`, `SD_buildReplyResponseEmail`, `SD_newEmailMessage` | `…_575565`, `…_575571`, `…_575577`, `…_575583`, `…_575589`, `…_575595`, `…_575601`, `…_575627` | identical to the repo `.sail` files |
| Rule `SD_buildApprovalEmail` | `…_571551` | v3, identical to the repo |
| Interface `SD_form_emailException` | `…_575621` | v2, `error: null` |
| Interface `SD_view_drawApprovals` | `…_570853` | v3 (Email Exchange), `error: null` |
| Constants `SD_EMAIL_APPROVAL_MAX`, `SD_EMAIL_REPLY_ADDRESS`, `SD_EMAIL_SENDER_NAME`, `SD_EMAIL_REPLY_ROLES`, `SD_EMAIL_REPLY_ADDRESSES`, `SD_EMAIL_INTERPRETATION_MODEL` | `…_575529` … `…_575559` | `SD_EMAIL_REPLY_ADDRESSES` is v3: all nine scott.thorn@appian.com, restored after the test mapping |

## Verified (end to end by loop-test email, draw 66 untouched)
Loop mail from the instance always arrives from `admin@ny.appiancloud.com`, so the verification ran in two stages:
- **Production mapping:** the unauthorized-sender case, which is genuine under this mapping.
- **Temporary mapping:** CEO and CAO → that address, read back, then restored and read back.

| Case | Draw | Result |
|---|---|---|
| Unauthorized sender | 92 (#77) | row UNAUTHORIZED, "Nothing changed."; draw still awaiting the CEO |
| Approve ("Looks good, approved. Please release the funds on the 16th.") | 92 | **Approved**; treasury notified 14:01:35 UTC; the CEO row's comment carries the reply and "read as APPROVE (comment: Please release the funds on the 16th.)" |
| Reject ("Reject. Hold this one until the lender signs off…", subject "RE:") | 93 (#78) | **Rejected at step 9**; no treasury |
| Unclear ("Let me think about this one over the weekend.") | 94 (#79) | AMBIGUOUS; clarification sent on the thread; nothing changed |
| Unclear again ("Can we talk about the contingency on Monday first?") | 94 | EXCEPTION; task **22161** "Review email reply" open for `SD Draw Demo Approvers`; no email; CEO task 22116 still live |
| Guardrail ("Approved.") | Gateway 12 | refused ($8,940,000 > $5,000,000); refusal sent on the thread; the CAO step is unchanged |

- **Approvals tab as `sd.accountant` via sail,** read from the stored YAML:
  - **#77:** step email / Sent · reply / **Sender not authorized** · reply / **Approved by email**. The CEO row reads "10/05/2026 email · admin@ny.appiancloud.com".
  - **#78:** Sent · **Rejected by email**.
  - **#79:** Sent · **Unclear · clarification sent** · clarification / Sent · **Sent to exception queue**.
  - **#12:** **Over the email limit** · refusal / Sent.
- **Gauntlet** `gauntlet_SD_emailReply.sail`: 29/29 (token, extraction, gate).
- **Renders:** Approvals view and exception form, both `diagnostics.error: null`.
- **Cleanup, confirmed by absence:**
  - throwaway rules `zz_gauntletEmailReply` and `zz_measureEmailMessageWidths`: 404;
  - throwaway processes `zz_loopTestSendReply` and `zz_measureEmailMessageWidths`: no `zz` process model is listed;
  - message rows 1–6 (capability tests) and 18 (the width probe) deleted by explicit id.

## Not verified, and the browser checklist
- **A reply from a real mailbox.** Three things are unproven:
  - that the external sender keeps its address;
  - that Reply-To routes the reply to the receiver;
  - that the clarification threads in Gmail.
- **The exception form's Mark Reviewed** and handler node 62, which logs the review.
- **Geometry** of the Email Exchange card and the exception form.
- **UNMATCHED, NOT_AWAITING and an unclassifiable answer:** these paths are proven by rule tests and the gauntlet only.

**Checklist, for Scott** (TODO → "Live email reply from a real mailbox"):
1. In your inbox, open the #79 CEO email ("… Step 9 of 9 (CEO) [SD-DRAW-94-S9]"). Click Reply. The To line must be `processmodeluuid0000f074-9ac4-8000-25d1-7f0000014e7a@ny.appiancloud.com`.
2. Reply in your own words, for example "Looks good, approved."
3. After 1–3 min, as `sd.accountant`, open #79 › Approvals:
   - the CEO row reads Approved, "email · scott.thorn@appian.com";
   - the Email Exchange has a new **Approved by email** row;
   - the draw is Approved.
4. Optional: have the session accelerate draw 95 to the CEO step. Reply unclearly and expect the clarification in the same Gmail thread.
5. Eyeball the Email Exchange on #77, #78, #79 and #12: wrapping, no tag ellipsis, no horizontal scroll at ~1280 px.
6. As `sd.accountant`, open task 22161:
   - navy header "Email reply needs a person", with the draw and step legible;
   - type a note and click **Mark Reviewed**;
   - #79 gains an "Exception reviewed by sd.accountant" row with outcome **Reviewed**.

## Rulings needed
- **The step email's reply copy** now departs from the client sample: it invites a conversational reply, drops the red warning, and adds an amber over-limit line. Accept it, or restore the sample's wording and narrate the rule? (TODO, Client validation.)
- **Carried from the chip fix:**
  - the pay-application tie against $0.00 when there is no Hard Costs line;
  - the amber-versus-red colour for "Does not tie".

## Findings
- **Instance-sent mail is re-stamped** from `admin@ny.appiancloud.com` whatever From is configured. The loop tests worked around this with a temporary mapping, restored by readback.
- **An email decision after an accelerated chain is dated a day after the previous step**, not on the email's date (the monotonic rule): #77's CEO row reads 10/05 while its reply reads 09/26. This is recorded as a known data artifact.
- **The exception form was created before its layout gate ran** (transcript order). The gate was run after the fact; the navy header with default text colours matches the reconciliation form, so nothing changed. The Approvals edit was gated first.
- **Draws 92–94 were Phase 5.6 specimens.** Their corroboration states are unchanged; their approval states now carry the Phase 6a outcomes.

## Promotion candidates
Promotion candidates: 7 found; 0 promoted; 7 listed (staged at gate 1 in `BUILD_LOG.md`):
- the email trigger and Public Events cannot be set over the Dev MCP;
- Receive Message mappings target parameters only;
- instance-sent mail arrives from `admin@<site>`;
- a bare `=pv!x` in a Send E-Mail text input fails the save;
- `stripHtml()` deletes newlines;
- a node's type cannot change on update;
- an email body arrives as HTML.

The method candidate "gate skipped when batching" fired and was reproduced in both directions; it stays held at gate 1. Checkpoint: current through this entry.

## TODO changes
**Added:**
- **Before demo:** "Email approval beat" (how it runs, the specimens, and clearing draw 66's message rows before a rehearsal).
- **Browser checks owed:** "Live email reply from a real mailbox, and the Email Exchange in the browser".
- **Client validation:** the step email's reply copy.
- **Deferred:**
  - the receiver's stale description (fix in Designer);
  - email paths proven by rule tests only;
  - Phase 6a dependencies to re-verify per instance.

**Moved to Done:** Phase 6a.

## BUILD_PLAN changes
- **Phase 6a:** all seven object items marked ✅ 2026-09-26. The header now reads built and verified, with Scott's live reply owed.
- **Added to 6a:** "Live reply from a real mail client" and "Ruling on the step email's reply copy".
- **Phase 6b:** unchanged.

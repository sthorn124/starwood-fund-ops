# Closeout — 2026-09-26 — Phase 6c: velocity ladder, site-reachable exceptions, Asset Manager edit, treasury content, feed staging

This is the final build phase. It covers items 0–10 of the Phase 6c brief:
- the rulings;
- exceptions reachable from the site;
- cycle time;
- reminders, the chase view and digest, and SMS;
- the Asset Manager's budget edit;
- the treasury email;
- feed-arrival staging;
- end-to-end verification;
- the demo runbook.

## Scope and identity
- **Design work:** Dev MCP `appian` as `scott.thorn@appian.com`. That account is in `SD Administrators`, `SD Users` and the three draw step groups, so every design read, rule test, render, process run and `completeTask` ran at administrator scope.
- **Persona checks:** sail, as `sd.accountant` (`~/.sail-sd.accountant`, member of `SD Draw Demo Approvers`) and as `sd.assetmanager` (`~/.sail-sd.assetmanager`, member of `SD Draw Asset Managers`).
- **Not used:** `appian-runtime`, `--from-devmcp`.
- **Credentials:** Scott entered the Twilio Account SID and Auth Token himself in Designer; the session never saw or typed them. He gave only the two phone numbers in chat, and the repo holds neither: only the masked "+1 ••• ••• 6630" appears.
- **Draw 66:** its chain was not touched. The live task 536876873 was rendered, never submitted.

## Rulings recorded (`PROJECT_INSTRUCTIONS.md`)
1. **Nothing in the flow requires Tempo.** Every task and action is reachable from the site: the Summary's action area or the Draws list. This is a standing rule; a new task type isn't done until the site links it.
2. **The guardrail blocks email decisions, not email conversation.**
   - Interpretation runs before the limit check.
   - On a draw over $5M, a question or an unclear reply flows as normal.
   - Only a reply read as APPROVE or REJECT is refused, and the refusal now records the reading.
3. **A figure that doesn't tie is amber everywhere.** That covers the reconciliation verdict, the pinned total's "off by", the document chips and the Summary. Red is kept for failures.

## What changed, and how it works

**Guardrail order.**
- The reply checks now run: draw and step found → sender authorized → step awaiting a decision → the AI reading.
- Over the limit, a decision goes to the refusal path, which logs the reading and the decisive phrase. A question or a hedge goes where it would on any draw.

**Email-reply review, reachable from the site.** An unclear second reply opens a **Review email reply** task for the draw approval team.
- **The team (`SD Draw Demo Approvers`) sees:**
  - an amber Summary card, "An email reply needs review", with **Review Reply**;
  - the draw marked YOUR ACTION on the Draws page, counted in Awaiting My Action;
  - **Review this reply** on the Emails tab's exception row;
  - a row in Needs chasing.
- **Everyone else** sees a state line without the action.
- **How it's found:** the open review is derived from the message log, and its task is found through the handler process id now stored on the row.

**Cycle time**, computed from dates already on the rows; nothing new is logged.
- Summary: "Received <date> · decided in N days" (or "in approval N days so far"), plus days from receipt to funding.
- Approvals: Time at Step per row, and the same cycle line.
- Draws page: a fifth KPI, **Avg Days to Decide**.
- Accelerated chains carry generated decision dates, spread a day apart into the future, so their durations are fictional.

**The chase ladder.**
- **Reminder** at `SD_CHASE_AGE_DAYS` (3 days): the step email again, under an amber banner. Subject: "Reminder · Draw #n · funding in N days · awaiting your approval [token]". It goes on the same thread to the step's group and is logged as REMINDER.
- **Text** at `SD_SMS_AGE_DAYS` (6 days): "Draw #n · $amount · funding in N days · awaiting your approval · reply by email".
  - Sent through Twilio only when `SD_SMS_MODE` is LIVE; otherwise composed and logged as **Staged · not sent**.
  - Every text is logged with channel SMS and the masked number. A failure is logged with Twilio's own message.
- **How the escalation reaches the chase process:** both rungs run `SD Chase Approval Step`. The escalation's message carries nothing custom.
  - The chase process takes the message's `OriginProcessID` (the step process that escalated) and finds the draw holding it.
  - The step is that draw's current step.
  - The rung is a reminder unless one is already logged for that approval row, in which case it's the text.
  - It sends nothing if the step has moved on.
- **Needs chasing** on the Draws page (the draw approval team only) and the **daily digest** to the team use one query. It lists steps waiting 3+ days and open reply reviews, ranked by amount then days to funding, each with who holds it, contact address, task group and the last chase.

**Asset Manager edit.**
- **The form:** at the Asset Manager's step only, the task form opens wide with an editable Adjustment and Current Draw per line, plus live tie-out and net-adjustment lines. Approve and Reject are unchanged.
- **On submit,** the step process:
  - writes the changed lines, recomputing proposed budget, PTD, % and balance (the roll-ups follow because they're computed from the lines);
  - writes one record event per line, attributed to the submitter;
  - then applies the decision.
- **What people see afterwards:** Budget Detail marks each edited line "Edited by <name> at approval, <date>" and adds a Line History. The next step email is built from the lines, so the edits travel downstream.
- **Guard:** an edit at any other step is refused by the planning rule, and the form shows no grid there.

**Treasury.** On final approval, the treasury email reads:
- subject "Approved for funding · Draw #n · <investment> · $amount · fund by <date>";
- a green "execute payment" band and a PAYMENT box (amount, pay-by date, fund, investment, draw, cash/equity, purpose, submitter);
- APPROVAL CHAIN 9 OF 9, with the final approver, date and channel;
- a link to the draw, and "no bank details".

The recipient is unchanged: the designer.

**Feed staging.** An administrators-only card at the foot of the Draws page runs Receive Capital Call's own `a!startProcess` call with packages already on the instance:
- **Stage Malformed Template** (`THSV_Draw67_Budget_Template_v2`) for beats 1–2;
- **Stage Corrected Package** (the template plus pay application, invoice and lien waiver) for beat 3.

Personas never see the card. It replaces the Designer-started `SD Stage Feed Arrival` I built earlier this session; that process is now deleted.

### Objects
- **New rules:**
  - `SD_getOpenEmailException`, `SD_getEscalationMinutes`, `SD_buildStepReminderEmail` (v2), `SD_buildStepSms`, `SD_maskPhone`, `SD_getChaseRows` (v3), `SD_buildChaseDigestEmail` (v3), `SD_resolveChaseTarget` (v1);
  - `SD_planBudgetEdit`, `SD_budgetEditLineRecords`, `SD_budgetEditEventRecords`, `SD_getBudgetLineEdits`;
  - `SD_buildTreasuryEmail`, `SD_getDrawApprovalRowSource`.
- **Changed rules:** `SD_getReplyContext`, `SD_buildReplyResponseEmail`, `SD_getDrawEmailMessages`, `SD_newEmailMessage` (v3), `SD_getDrawDetail` (v9), `SD_getDrawListRows` (v2).
- **Interfaces:** `SD_form_drawApprovalDecision` (v4), `SD_form_reconcileExtraction` (v8), `SD_view_drawSummary` (v11), `SD_view_drawBudgetDetail` (v4), `SD_view_drawApprovals` (v5), `SD_view_drawEmails` (v2), `SD_page_draws` (v11).
- **Process models:**
  - `SD Chase Approval Step`: new; 17 nodes, with parameter `originProcessId`.
  - `SD Send Chase Digest`: new.
  - `SD Draw Approval Step`: nodes 14–18 (the edit writes); the task input `budgetEditsJson`.
  - `SD Apply Draw Approval Decision`: nodes 19–20 (treasury).
  - `SD Handle Approval Reply`: guardrail reorder; `processId` on the exception row.
- **Data:** `SD Draw Email Message` gains `channel` and `processId`. Record events on `SD Draw Budget Line` (history type plus event type "Edited at Approval").
- **Constants:** chase and SMS days, test minutes, SMS mode (**STAGED**), the SMS recipient and Twilio number, the edit event type, three feed-package constants, and `SD_ADMINISTRATORS_GROUP`.
- **Twilio:** connected system `SD Twilio SMS`, integration `SD_sendTwilioSms`.
- **Deleted, absence confirmed:** `SD Stage Feed Arrival`, and the throwaway `zz_loopTestSendReply6c`. The temporary reply mapping was restored to all nine `scott.thorn@appian.com` (v7, read back).

## Verified

**The guardrail, on Gateway #12 ($8.94M; run as the designer through the real receiver and handler):**
- Row 40: "Before I sign off, what is the retainage balance being held on this draw?" was read as QUESTION with its phrase quoted, and logged for the team. No refusal.
- Row 45: "Approved, go ahead and fund it." was read as APPROVE, then refused (GUARDRAIL, with the reading). Row 46 is the refusal on the thread.

**The email-reply review on draw 79 (#70), at the CEO step:**
- **The two hedges:**
  - "Let me think about it over the weekend." was read as AMBIGUOUS, and a clarification was sent (rows 44, 47).
  - "I'm leaning toward yes but hold off for now." raised an EXCEPTION (row 48), and review task **268455639** opened.
- **As `sd.accountant` (via sail):**
  - #70 shows YOUR ACTION, and the Needs chasing row reads "Email reply to review".
  - The Summary shows the amber card with **Review Reply** (a task link in the page data).
  - The Emails tab shows **Review this reply**.
- **As `sd.assetmanager` (via sail):**
  - no Needs chasing switch;
  - YOUR ACTION only on #66, the account's own step;
  - #70 shows the state line with no task link on either tab.

**A defect found by that persona check, now fixed.** The Draws page returned an error for `sd.accountant`: "Insufficient permission", from `group()` on a step group the persona can't view. The designer's render had been clean. Group names now come from the step-group constants, and the page loads for both personas. A staged text also read "Text sent" in the chase view; it now reads "Text staged, not sent" (or "Text failed").

**Cycle time (via sail, both personas):**
- #70's Summary: "Received Sep 22 · in approval 5 days so far · 55 days from receipt to funding date".
- #74's Approvals: Time at Step per row.
- Fifth KPI: "AVG DAYS TO DECIDE 14.9 · 10 decided draws".

**The chase ladder (run as the designer):**
- **Direct runs on #72:** the reminder was sent to the group and logged, and a staged text was logged.
- **Started the way an escalation will start it**, with only the origin process id:
  - #72's step process resolved to the text rung. It sent LIVE, and Twilio refused it (below); the failure was logged with Twilio's message.
  - #70's resolved to the reminder rung: "REMINDER sent to SD Draw CEO", logged.
  - An unknown id resolves to "not found".
- **A step that has moved on gets nothing:** a chase for step 9 while draw 78 sat at step 5 was STALE.
- **Needs chasing (as `sd.accountant`):** 8 rows, then 7 after #69 was approved, ranked by amount, with contacts.
- **Digest:** ran once and was sent to the team.

**Asset Manager edit:**
- On #74 (draw 87), step 3 was completed with four line edits. Result: four events, the draw advanced to step 4, net adjustments $0.
- As `sd.assetmanager`, Budget Detail shows "Edited by Scott Thorn at approval, Sep 26" on the four lines, plus the Line History. The designer submitted, hence the name.
- Blocked at step 9: the planning rule refuses, and #70's form renders medium width with no grid.
- Draw 66's step 3 form (render only): no error, 34 editable fields, "Ties ✓".

**Treasury, live:**
- Draw 78 (#69) was accelerated to the CEO step and approved by email reply: row 50 APPROVE, APPROVED.
- The receipt is row 51. `treasuryNotifiedAt` is 2026-09-27 00:06:42 UTC.
- The email renders as described above (9.8 KB).

**Clean package through the feed path, draw 99:**
- The three documents were classified correctly. The pay application was read: $2,490,296.23, Stonebridge, application 14.
- Its reconciliation form, rendered with the real extraction, shows **Ties ✓ $2,604,252.23** and "Renumbered from #67 (on file)".
- The pay application ties to Hard Costs, the invoice is "filed as Invoice", and the lien waiver is received.
- The task is left open as a feed-arrived specimen.

**Staging card:** it renders for the designer (no error, both buttons) and is absent for both personas (via sail).

## Not verified, and why
- **Escalations firing on their own.** The escalation levels, the chase process's message trigger and the digest's daily timer can only be set in Designer. The chase process was fired exactly as an escalation will start it. You said to defer this to TODO; the steps are simplified there, under "Designer setup owed".
- **The live text on your phone.** Twilio accepted the credentials but refused the message: **error 572006, "Trial accounts can only use predefined SMS templates"**. It was tried twice, and both are logged on #72 › Emails as "Text failed". SMS is back to STAGED (v5). Going live needs a Twilio account that can send free-form texts.
- **The Asset Manager's own submit on a real task.** sail can't open tasks, so the write path was proven as the designer on #74. Draw 66's live task was issued by the pre-edit process version, so it needs cycling first (the runbook's first step).
- **Geometry, and the email and SMS surfaces:** layout of the chase grid, the five KPIs and the staging card, and the reminder, digest and treasury emails as they arrive in Gmail. These are browser checks.
- **The staging buttons themselves.** A button that starts a process can't be driven from a render, and the personas can't see the card.

## Browser checklist (full steps in `TODO.md`)
1. **Review from the site** (as `sd.accountant`): Draws → #70 → **Review Reply** (task 268455639) → mark it reviewed → the Summary card and YOUR ACTION go away.
2. **Needs chasing (7)** (as `sd.accountant`): layout, and #72's "Text failed" line.
3. **Gmail:**
   - the reminder "Reminder · Draw #70 · funding in 50 days · awaiting your approval [SD-DRAW-79-S9]", threaded with the step email;
   - the digest;
   - the treasury email "Approved for funding · Draw #69 · …".
4. **Live SMS:** blocked until the Twilio account changes.
5. **The Asset Manager edit on draw 66,** after the reset cycle: as `sd.assetmanager`, edit a line, then Approve. Expect "Edited by Elena Marchetti at approval" and the Line History.
6. **Feed-trigger dry run** (as the designer):
   - Stage Malformed Template: after ~90 s, "Not loaded" and the alert.
   - Stage Corrected Package: after ~80 s, the reconciliation task for `sd.accountant`.
   - Clean up both draws afterwards.

## Demo runbook (in full in `TODO.md`)
0. **Before the run:**
   - reset draw 66, which also cycles its task onto the new step model;
   - clear draw 66's message rows;
   - read back test minutes = 0 and SMS mode = STAGED.
1. **Package arrives.** Draws page card → **Stage Malformed Template**, narrated as the EY feed.
2. **Ingestion fails.** The draw reads "Not loaded", and the alert with the AI comparison lands in Gmail. Specimen: draw 96 or 83.
3. **Corrected package ingests.** **Stage Corrected Package** → about 2 min → `sd.accountant` reconciles (Ties ✓), then Confirm. Specimens: 99, 92.
4. **#66: QIU and the pre-completed chain.**
5. **The Asset Manager edits and approves #66.** Specimen: #74.
6. **The chain runs on; the CEO replies in Gmail.**
   - Run the accelerator (87 s), then the CEO replies in Gmail.
   - Optional asides: Needs chasing, a reminder, the staged text, and a question on #12.
   - Specimens: 92, 95, 79 (#70, review open), 12.
7. **The treasury email.** Specimen: 78 (#69).

## Rulings or actions needed from you
- **Twilio:** upgrade the account, or register a template, to send live texts. Or accept SMS as staged for the demo.
- **Designer setup** (B, C, D in `TODO.md`), whenever you want the ladder to run by itself. Then tell the next session, which will fire one escalation end to end.
- **The contingency narrative:** skipped in 6c by your ruling; it's in TODO/Deferred as a stretch item.

## Promotion candidates
9 found; 0 promoted; 9 listed, staged in `BUILD_LOG.md` with triggers:
- `group()` in persona-rendered rules;
- script-task outputs reading the PV values from when the node started;
- `a!urlForRecord` with one identifier returns a string;
- map keys are case-insensitive;
- `ToValidAddresses` is empty for group sends;
- `max()` over integers returns a decimal;
- escalations and triggers are Designer-only;
- a form-urlencoded body via an explicit header;
- a task keeps its process version while its form doesn't.

Checkpoint: current through this entry.

## TODO changes
- **Added:**
  - the Demo runbook (beats 1–7 with specimens);
  - "Designer setup owed" (B, C, D, with the verification that follows);
  - "Phase 6c browser checks" (7 items);
  - Deferred: live SMS (Twilio trial, error 572006) and the contingency narrative stretch.
- **Replaced:** the 6a exception-click step (22161, done by you) with the site-reachable click on #70.
- **Struck, with rulings:**
  - the over-limit question;
  - the tie-out colour item;
  - the stale #79 specimen line.
- **Updated:** the reconciliation and chip checks now expect amber.
- **Done:** Phase 6c.

## BUILD_PLAN changes
- **Phase 6c marked built and verified.** Reminders, digest, cycle time, SMS (staged; live blocked), the Asset Manager edit, treasury content, amber tie-out, feed simulation, the site-reachable review and the guardrail reorder are all ✅ 2026-09-26.
- **Still open:** Designer setup, live SMS, polish and rehearsal (the runbook is written).
- **Struck:** the stretch item.

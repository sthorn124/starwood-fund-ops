# TODO — Starwood draw approval

Open items by class. Sessions add discovered items unprompted as they surface, and any response that touched this file ends with a `TODO changes:` line stating what was added, moved, or closed. Every item carries an owner and a firing condition ("trigger: …"); nothing is parked on "later". Superseded items are struck through with a pointer to the standing decision, not deleted; completed items move to Done with the date. The contract is `CLAUDE.md` §8.

## Blocking

## Before demo

- **Demo runbook (rewritten 2026-09-28, second fix session: one draw, no staging of the main draw).** Demo order: failure opens, recovery follows; this supersedes the earlier success-first order (2026-09-27). Demo prep is clickable only (`PROJECT_INSTRUCTIONS.md`): the Draws page's **DEMO STAGING · ADMINISTRATORS ONLY** card stages what the beats need, and nothing is reset, reused or cleaned by requirement. Presenter windows: the designer (an `SD Administrators` member) for the staging card; `sd.accountant` and `sd.assetmanager` for the beats; Gmail on scott.thorn@appian.com.
  - **Beat 0 — before the demo.**
    1. Read back `SD_ESCALATION_TEST_MINUTES` = 0 and `SD_SMS_MODE` = STAGED (Twilio stays staged, ruled).
    2. Staging card → **Stage Mismatch Package**. It settles in ~2 min (the reconciliation task at ~80 s, the pay application read ~2 min after the click); its task waits for beat 3. Its Draws row reads "New draw · <time>" with "…Budget_Template.xlsx + THSV_Draw67_PayApp_G702_mismatch.pdf" beneath.
    3. Optionally **Stage Corrected Package** once more as the fallback draw, confirmed before the demo (it then sits at the Asset Manager, step 2).
    4. No stage-for-approval click exists in prep or demo.
    5. **Never start two feeds with the same template within ~2 minutes of each other** (the mismatch and corrected packages share one template): the second run can take the first run's Doc Center instance while it is still blank and fail with "required header fields came back blank" (measured 2026-09-28, draws 110 and 111; Deferred). Stage the mismatch package well before the demo, and let beat 1's malformed template (a different file) run alone.
  - **Beat 1 — the malformed package is refused (live).** Staging card → **Stage Malformed Template** (narrate the EY API/SFTP drop). The row reads "Not loaded · <time>" (measured 2026-09-28: 87 s after the click); the plain-English alert with the AI comparison against the last good template lands in Gmail. *Fallback specimen:* the kept failed ingest (draw 96).
  - **Beat 2 — the corrected package arrives and the accountant confirms it (live, as `sd.accountant`).** Staging card → **Stage Corrected Package**. Doc Center classifies each PDF, reads the pay application, files the invoice and logs the lien waiver. The reconciliation task arrives ~90 s after the click (measured 2026-09-28: the extraction stored at 75 s, the task open by ~90 s) and the pay application reads ~40 s later (else "Being classified" + Refresh). Draws → the row "New draw · <time>" (YOUR ACTION; "+ 3 supporting files" beneath) → Summary → **Reconcile Extraction**: the extraction beside the workbook, **Ties ✓ $2,604,252.23**, the pay application corroborating Hard Costs, the invoice filed, the lien waiver received, the Draw Number read-only (system-assigned). **Confirm & Assemble Draw**. The draw is born at the Asset Manager's desk: step 2 of 9, order 1 already Approved with Priya's confirmation (measured 2026-09-28: order 1 Approved at the confirm second, the Asset Manager's task live ~15 s later; `sd.assetmanager` sees YOUR ACTION and "Your approval is pending — Asset Manager, step 2 of 9").
  - **Beat 3 — the mismatch draw from beat 0 (live, as `sd.accountant`; droppable to Q&A).** Draws → its row ("New draw · <time>", the mismatch PDF named beneath) → Summary → **Reconcile Extraction**: amber **Does not tie** with "off by $37,500.00" beside it, and amber **No lien waiver received**. Close without confirming (leave the task open). *Fallback specimen:* **#78** (draw 93).
  - **Beat 4 — the Asset Manager edits and approves (live, as `sd.assetmanager`, on the main draw).** Draws → the main draw (YOUR ACTION) → Summary: the chain (Priya's approval at order 1, stamped at the confirm minute; Elena at step 2), QIU Detail, the cycle line → **Review & Approve**: the task form opens WIDE with the editable budget grid. Move $10,000 from All Project Contingency to A&E - Architectural (net adjustments stay $0; totals recompute), **Approve**. Budget Detail then reads "Edited by Elena Marchetti at approval, <date>" with a Line History, her approval is dated the actual minute, today, and the next step email carries the new values. *Fallback specimen:* **#74** (draw 87).
  - **Beat 5 — the chain runs on; a reminder goes out (as the designer, then `sd.accountant`).** Staging card → **A draw in approval** → pick the main draw → **Advance to President** (measured 2026-09-28: 72 s to step 8, 80 s to the live President task; narrate "the chain approves over the following days" — the recorded dates are today's, a few seconds apart, and the days are narration only, ruled 2026-09-28); the line turns green "… step 8 of 9 · President (James Callahan): the task is live". **Send Reminder Now** (measured 13 s; the reminder's subject is "Re: <the President step email's subject>", so Gmail threads it with that email): the reminder on the President step's thread in Gmail and the text staged. As `sd.accountant`: Draws → **Needs chasing** shows the main draw beside #12, ranked by dollars then days (the main draw "Reminder sent today · text staged"; #12 "Step 6 waiting N days" with its staged text beneath). Name the daily digest. Then **Advance to CEO** (measured 32 s to the live CEO task and its step email).
  - **Beat 6 — the CEO decides by email, on the main draw (Gmail; droppable to Q&A).** The step email "Draw Funding Approval: Draw #n · … · Step 9 of 9 (CEO)" arrives. Three replies, 1–3 min each (cut the vague round if short on time):
    1. **A question** ("Before I sign, what's driving the contingency spend?"): as `sd.accountant`, the Summary's amber card → Emails → **Your answer** → **Send Answer**; the answer arrives on the same thread.
    2. **A vague reply** ("let me think about it"): the system asks for a clear decision on the thread. One sentence: a second vague reply goes to a person (the Review Reply card).
    3. **A clear approval** ("looks good, approve"): Approved, and a receipt quoting the exact words on the thread.

    The rule, once: nothing changes unless the deciding words are in the reply and a rule confirmed them. Then **#12**: a clear approval refused over the $5,000,000 limit; the refusal is already in the inbox. Standing specimens for the asides: **#80** (draw 95, the full conversation), **#77** (draw 92, approved by email), **#73** (draw 86), **#79** (draw 94, the junk PDF not classified), **#70** (draw 79).
  - **Beat 7 — treasury is told to fund.** On the final approval the treasury email "Approved for funding · Draw #n · … · fund by <date>" reaches the designer's inbox; close on the draw's Summary. *Fallback specimen:* **#69** (draw 78).
  - **Optional, any time:** staging card → **Clean Up Old Runs…** → confirm. Removes every ingested draw that is neither seeded nor a named specimen (`SD_DEMO_KEEP_DRAW_IDS`), children first, and cancels their open tasks. The demo does not require it.
  - *Owner:* the presenter. *Trigger:* every rehearsal and the demo.
- **Designer setup owed (Phase 6c): escalations, their message trigger and the digest schedule.** The Dev MCP cannot set escalations, message triggers or timer triggers. Everything else is built and was fired directly; the escalation message now carries nothing custom (the chase process resolves the draw, the step and the rung from the escalating process's id), so no mapping on the sending side is needed. Owner: Scott. Steps, in this order (Designer → application **Starwood Demo**):
  - **B. Let `SD Chase Approval Step` be started by a message.**
    1. Open process model **SD Chase Approval Step**.
    2. **File → Properties → General** tab → tick **Public Events** → **OK**.
    3. Double-click the **Start** node → **Triggers** tab → add **Receive Message** → click its **Configure** link.
    4. **Setup** tab → message type **Process to process**. No conditions.
    5. **Data** tab → **New Mapping**: Value `msg!properties.OriginProcessID`, operator **is stored as**, process variable **originProcessId** (a parameter the session added). That is the only mapping.
    6. **OK**, **OK** → **File → Save & Publish**.
  - **C. Two escalations on the step task.**
    1. Open **SD Draw Approval Step** → double-click the user task **Approve or reject draw**.
    2. **Escalations** tab → **Add Escalation** (Level 1) → timer **Configure** → delay = the expression `rule!SD_getEscalationMinutes(level: 1)`, unit **minutes** → **OK**.
    3. Level 1 action → **Send Message Event** → **Setup** tab → **Directory…** → **SD Chase Approval Step** → **Select** its start event → **OK**. No Data mappings.
    4. **Add Escalation** (Level 2) → timer `rule!SD_getEscalationMinutes(level: 2)` minutes (its clock starts when Level 1 fires) → action **Send Message Event** → the same start event → **OK**.
    5. **OK** → **File → Save & Publish**. After this, the session does not edit `SD Draw Approval Step` over the Dev MCP (an MCP save could drop what Designer set).
  - **D. The daily digest.** Open **SD Send Chase Digest** → **Start** node → **Triggers** → add **Timer** → **Configure** → start tomorrow 7:00 AM, repeat every 1 day → **OK** → **File → Save & Publish**.
  - **Then the session verifies:** sets `SD_ESCALATION_TEST_MINUTES` to 2, brings a spare ingested draw to a new step so its task comes from the new version (since 2026-09-28: confirm a spare corrected package — its Asset Manager task is fresh — or advance a draw with the staging card), reads the REMINDER row (~2 min) and the SMS row (~4 min) on its Emails tab, and restores the minutes to 0 by readback. Escalations apply only to tasks issued after the publish.
  - *Trigger:* before the demo, if the reminder ladder is to run by itself.

- **Accelerator timing (demo-script fact, measured 2026-09-21; re-measured 2026-09-28).** 2026-09-21: from the accelerator to the CEO task, **87 s** in the old sequence (24 s settle, then ≈12 s per step). 2026-09-28, the one-draw run: **Advance to President** from step 3, 72 s to step 8 and 80 s to the live task; **Advance to CEO** from step 8, 32 s; no target from step 1 (the regression on #82), ~2 min to the CEO. Narrate it ("the chain approves over the following days"); since 2026-09-28 the recorded decision dates are real timestamps, seconds apart, so the days are narration only.
  - *Owner:* the presenter.
  - *Trigger:* the first rehearsal.
- ~~**Demo reset.** Before every run: apply `scripts/seed_draw66.py --reset-csv` through `updateRecordData` (draw, then approvals) and confirm no "Approve or reject draw" task is open. Never edit rows by hand.~~ **Superseded 2026-09-27:** demo prep is clickable only (runbook above; `PROJECT_INSTRUCTIONS.md`); no reset, no scripts, draw 66 is list history.
  - *Owner:* the presenter or the session.
  - *Trigger:* before every rehearsal and the demo.

- ~~**Demo start (2026-09-22).** After the reset, start `SD Draw Approval Process` on draw 66 and wait ~10 s: the Draws page shows "Awaiting My Action 1" and YOUR ACTION on #66 for `sd.assetmanager` only while that task is live. The task currently live is **536876873** (step process **536909994**, restarted 15:34 UTC after the earlier step process 536909940 was found cancelled — its task 536874206 read Aborted with no assignees). **Do not cancel `SD Draw Approval Step` instances or the `SD Draw Approval Process` run that owns draw 66's live task** when sweeping Process Monitoring; the reset CSV plus a fresh start is the only way to cycle it.~~ **Superseded 2026-09-27:** demo prep is clickable only (runbook above; `PROJECT_INSTRUCTIONS.md`); no reset, no scripts, draw 66 is list history.
  - *Owner:* the presenter or the session.
  - *Trigger:* before every rehearsal and the demo.
- **Email approval beat (Phase 6a, 2026-09-26).**
  - **How it runs:** the accelerator (or a live approval) brings a draw to step 9. The step process emails `SD Draw CEO` (scott.thorn@appian.com) from "Starwood Draw Approvals", with Reply-To the receiver and the subject ending `[SD-DRAW-<id>-S9]`. Scott replies from that mailbox in his own words, and the draw moves 1–3 min later. Only replies from the authorized address act; every role maps to scott.thorn@appian.com today.
  - **Specimens now on file:**
    - **92 (#77):** Approved by email, treasury notified.
    - **93 (#78):** Rejected by email.
    - **94 (#79):** ~~at the CEO step with its CEO task **22116** live, one clarification sent, and a **Review email reply** task **22161** open~~ Approved by Scott's live reply; review task 22161 completed by Scott (row 36). The open-exception specimen is now **79 (#70)**, task **268455639** (Phase 6c).
    - **12 (Gateway #12):** the guardrail refusal.
  - ~~**Before rehearsing the beat on draw 66:** delete draw 66's earlier `SD Draw Email Message` rows by explicit id.~~ Superseded 2026-09-27: the email beat runs on the draw staged for approval, which has no earlier replies; nothing is deleted before a demo.
  - ~~**Before a rehearsal that clears ingested draws:** pass their message rows as `msgs=` to `--cleanup-ingested`.~~ Superseded 2026-09-27: Clean Up Old Runs (optional) removes message rows with their draws.
  - **Phase 6b additions:**
    - The CEO may reply with a question. It changes nothing and waits on the Summary (draw approval team) and the Emails tab. Priya answers from the Emails tab, and the answer goes on the same thread. Every applied email decision gets a receipt on the thread.
    - **Specimens:**
      - **95 (#80):** the full conversation (question → answer → conditional approval read as unclear → clarification → approval → receipt), Approved.
      - **86 (#73):** at the CEO step, staged for Scott's live Q&A check.
    - A pending question is derived from the log. ~~Before a rehearsal on draw 66, the same message-row cleanup clears any leftover question.~~ (Superseded 2026-09-27: no draw is reused.)
  - *Owner:* the presenter or the session.
  - *Trigger:* before every rehearsal of the email beat.
- ~~**Ingestion demo reset — Phase 5.6 additions (read 2026-09-25; extends the Phase 5.5 state below).**~~ **Superseded 2026-09-27:** demo prep is clickable only (runbook above; `PROJECT_INSTRUCTIONS.md`); no reset, no scripts, draw 66 is list history.
  - **Reconciled 5.6 draws, each In Progress at step 1 with an Accountant task open:**
    - **92 = #77:** clean package; TIES; documents 6637–6640.
    - **93 = #78:** mismatch; ATTENTION; 6641–6642.
    - **94 = #79:** clean plus junk; TIES, "1 not classified"; 6643–6647.
    - **95 = #80:** template only; NONE; 6648.
  - **Also on file, not the session's:**
    - **90 = #76:** a clean package confirmed by **Priya Raman** at 18:15 local — Scott's persona run, so its template row reads "confirmed by Priya Raman".
    - **91:** Ingestion Failed; v2 plus the mismatch pay application.
    - Neither is deleted without Scott's word.
  - **New failure specimen:** **96** (v2 plus a pay application and a lien waiver, both classified; rows 6649–6651). With 83, 89 and 91 the Draws page now shows four "Not loaded" rows; keep one.
  - **Scott's Phase 5.6 browser pass (read 2026-09-25 evening):**
    - **97 = #81:** the package with the junk PDF; TIES, "1 not classified".
    - **98 = #82:** the mismatch package; ATTENTION.
    - Both are In Progress at step 1. They are Scott's; neither is deleted without his word.
  - **`sd.accountant`'s Awaiting My Action reads 16:** every verification draw sits at step 1.
  - **Before a rehearsal of the package beat:** clear the verification draws with `--cleanup-ingested`, children first. Read the children by `drawId`: lines 16, approvals 9, QIU from the prior set, and the document rows above.
  - *Owner:* the presenter or the session.
  - *Trigger:* before every rehearsal that shows ingestion.
- **Package latency (demo-script fact, measured 2026-09-25, Phase 5.6).**
  - Each supporting document takes **~50 s** to be classified by Doc Center, and a pay application **~67 s** more to be read. The documents run in parallel, so a package settles **~2 min** after Receive.
  - The reconciliation task arrives at **~80 s**. Opened at once, it shows the pay application as grey "Being classified" with a Refresh link; the form re-reads every 30 s.
  - Wait ~40 s before opening the task, or narrate the pending state ("Doc Center is still reading the pay application").
  - *Owner:* the presenter.
  - *Trigger:* the first rehearsal of the package beat.
- ~~**Ingestion demo reset — state as read 2026-09-25 after Phase 5.5 (supersedes the draw list in the next item).**~~ **Superseded 2026-09-27:** demo prep is clickable only (runbook above; `PROJECT_INSTRUCTIONS.md`); no reset, no scripts, draw 66 is list history.
  - **Reconciled draws (In Progress):** `SD Draw` rows **74–80** are #67 (74), #67 (75), #71 (76), #68 (77), #69 (78), #70 (79) and #72 (80); steps 1–2, several with open approval tasks. Phase 5.5 added **86 = #73** (the clean package: pay application, invoice, lien waiver; corroboration TIES; documents 6621–6624), **87 = #74** (the mismatch package; ATTENTION; documents 6625–6626) and **88 = #75** (template only; NONE; document 6627), each at step 1 with an Accountant task open — so `sd.accountant`'s Awaiting My Action reads 9.
  - **Ingesting shells:** none. **81, 84 and 85 were deleted 2026-09-25** (rows only, children first, absence confirmed) so the Draws page had one "New draw" for sail to open; their pipeline instances still hold open reconciliation tasks (see "Cancel the stranded build-time process instances").
  - **Failure specimens:** **83** (Phase 5, document 55641, template row 6617) and **89** (Phase 5.5 regression: v2 template plus a pay application and a lien waiver, rows 6628–6630; the supporting documents are read and listed, never corroborated). Keep one.
  - **Before a rehearsal of the package beat:** clear #73–#75 (or keep one as the "already ingested" specimen) with `--cleanup-ingested` — read the children first (lines, approvals, QIU and documents by `drawId`; approvals are 9 rows per draw, lines 16, QIU from the prior draw's set) — then run Receive Capital Call as `sd.accountant` with the template and the package PDFs in the upload slots (one PDF per slot).
  - **Keep one failed draw for the demo beat.** Each new v2 submission adds another "Not loaded" row. Clear extras with `python3 scripts/seed_draw66.py --cleanup-ingested draw=<id> docs=<row>` and `deleteRecordData`, children first (a failed draw has only its template row). Read the row id first.
  - *Owner:* the presenter or the session.
  - *Trigger:* before every rehearsal that shows ingestion or the failure beat.
- ~~**Ingestion demo reset (2026-09-22, updated by the intake fix and Phase 4).** Draw 75 is now at **step 2** (Phase 4 advanced it to send a real step email; step process 536910004, task 536877532, order 1 Approved with the build comment); draw 77 is #68 at step 1; draw 78 is an Ingesting shell. Four ingested rows now exist beside the seed: the reconciled #67s **74** and **75** (below) and the Ingesting shells **76** (document 55289, ingestion process 268476653) and **77** (document 55293) from the intake fix's two persona submits — each shell has a Doc Center instance and a reconciliation task open for `SD Draw Demo Approvers`, so the Draws page shows two "New draw · Ingesting" rows and "AWAITING MY ACTION" counts them once reconciled. Clean the shells with `--cleanup-ingested` (read their child ids first: document rows 6610/6611; no lines, QIU or approvals yet) or reconcile them (they will renumber to #68/#69). Two ingested #67s coexist: `SD Draw` **74** (the session's verified run, In Progress at step 1, step process 38746) and **75** (Scott's persona run the same afternoon, confirmed by Priya Raman, step process 536909980; document 55280, document row 6609, approvals 6619–6627). While both exist the reconciliation form's Draw Number chip on a new #67 reads amber "Submitted as #67, already on file — renumbered to next in sequence" with 68 prefilled (the collision rule, 2026-09-22). Before a rehearsal keep one as the "already-ingested" specimen and clear the other: `listRecordData` the children by `drawId`, then `python3 scripts/seed_draw66.py --cleanup-ingested draw=<74|75> lines=<a-b> approvals=<a-b> qiu=<a-b> docs=<id>` (for 74: `lines=6617-6632 approvals=6610-6618 qiu=6611-6620 docs=6608`) and apply its CSVs with `deleteRecordData` children first. Then run **Receive Capital Call** as `sd.accountant` with `THSV_Draw67_Budget_Template.xlsx`; the Ingesting row appears within ~10 s, the reconciliation task ~80 s after submit.~~ **Superseded 2026-09-27:** demo prep is clickable only (runbook above; `PROJECT_INSTRUCTIONS.md`); no reset, no scripts, draw 66 is list history.
  - *Owner:* the presenter or the session.
  - *Trigger:* before every rehearsal that shows ingestion.
- **Cancel the stranded build-time process instances — optional housekeeping, not demo prep (2026-09-27).** Clean Up Old Runs cancels the open processes of the draws it removes; the instances below belong to draws deleted earlier by hand, so they stay a Process Monitoring job. (They hold no data; the rows were deleted): launcher runs 268476637, 38725, 38732 and 536909956 / 268476640 (the two `testProcessModel` launcher runs — **note 2026-09-22: 536909956 is the `SD Draw Approval Process` run that started draw 66's step process 536909940; that step was found cancelled/aborted this afternoon and has been restarted as 536909994, so leave `SD Draw Approval Step` 536909994 and its parent 536909993 alone**), their `SD Receive Capital Call` children (the ones for draws 67–73, including 38740's predecessors), the Doc Center `AIA Extraction Run Model Version` instances for documents 55245/55247/55252 whose Save Extraction child paused on the `[]` bug, and the two orphan approval-process runs 38744/38745 (both completed). Process Monitoring, filter by model name, cancel; do not resume.
  - **Add (2026-09-25, Phase 5.5):** `SD Receive Capital Call` **39011** (draw 85, deleted: the multi-file upload run handed two missing documents; its reconciliation task **16354** is still open for `SD Draw Demo Approvers`) and its `SD Read Supporting Documents` child (id not read; it wrote nothing), plus the pipelines of the deleted shells **81** (task 9464) and **84** (process 536910222, task 536885220). Cancel; do not resume — completing any of those tasks would write to a deleted draw id.
  - **Add (2026-09-25):** `SD Receive Capital Call` instance **38992** — Phase 5's first live failure run, paused (inferred) at node 40 "Ingestion failure alert (email)" when it ran as the persona; its draw 82 and template row 6616 were deleted. Cancel; do not resume (resuming would send a stale alert and rewrite a deleted row).
  - **Update 2026-09-27:** Clean Up Old Runs cancelled 15 processes that still held tasks for the 14 draws it removed (9 cancelled, 6 already closed), including draw 99's pipeline and draw 98's CEO step. The designer's task list still shows the two orphan **Reconcile extracted draw** tasks named above: **9464** (process 38772, draw 81) and **536885220** (process 536910222, draw 84). Their draws no longer exist, so the button cannot reach them; they stay a Process Monitoring job.
  - *Owner:* Scott.
  - *Trigger:* whenever convenient (they show in Process Monitoring and the designer's task list only; no demo beat needs this).

- ~~**Ruling owed: numbering a draw whose investment matches nothing (found 2026-09-28).**~~ **Accepted 2026-09-28:** numbered #1, as built (`PROJECT_INSTRUCTIONS.md`). Draw numbers run per investment (THSV #63–#83, Gateway #11–#12). A draw whose extracted investment name matches no investment on file is numbered in the sequence of draws with no investment (today #1), on the form and at commit. Accept it, or keep an unmatched draw unnumbered until the accountant corrects the name? *Owner:* Scott. *Trigger:* before the demo, or the first template with an unknown investment.
- ~~**Ruling owed: a live Asset Manager approval is dated the next day (found 2026-09-28, second fix session).**~~ **Ruled and built 2026-09-28 (third session):** decisions are stamped at the actual moment; no +1-day floor, no day spreading (`PROJECT_INSTRUCTIONS.md`). The transition's monotonic rule makes every decision at least a day after the previous one. Order 1 is now approved at the confirm time, so Elena's live approval minutes later is dated tomorrow: on #83 the confirmation reads 09/28 and her approval 09/29. The same rule spread the old accelerated chains a day apart. Either accept it and narrate the chain as running over the following days, or exempt live TASK and EMAIL decisions from the +1 day (so hers carries its real time). *Owner:* Scott. *Trigger:* before the demo.
- **#12's question is pending again (2026-09-28).** Deleting the test answer (row 62) restored the unanswered state. The Summary shows the amber question card to the draw approval team, and the Emails tab shows the reply box. Leave it as the "a question flows" aside, or answer it from the Emails tab (this sends a real email on the thread). *Owner:* Scott. *Trigger:* before the demo.
- ~~**Ruling owed: order 1 is staged though it has a live persona (demo-practices, "Live where live is possible").**~~ **Struck 2026-09-28:** raised by the demo-practices skill, which Scott removed on 2026-09-27 (`2382c33`); no ruling is owed.
- ~~**Ruling owed: the failure comparison becomes record content with no human review (demo-practices, AI tier 3).**~~ **Struck 2026-09-28:** raised by the demo-practices skill, which Scott removed on 2026-09-27 (`2382c33`); no ruling is owed.

## Browser checks owed

- **Same-day decision dates on #84 (2026-09-28, third session).**
  - *Owner:* Scott.
  - *Steps:*
    1. As `sd.accountant`: Draws → **#84** → **Approvals**. Expect nine rows: 1–8 Approved with one date (09/29/2026 in the evening, the GMT-date item in Deferred), Time at Step "< 1 day" on every row, and the CEO row highlighted.
    2. **Summary:** expect "8 of 9 approved", every step "✓" with the same date, and "in approval 0 days so far · 48 days from receipt to funding date".
    3. **Gmail:** the CEO step email for Draw #84 (11:00 PM EDT). Its Approval Status reads 09/28/2026 on rows 1–8.
  - *Trigger:* the next browser pass.

*(Owner: a named human. Each item lists the steps, the persona to log in as, and the expected strings — a checklist the human can run, not an open question. Content, state, and behaviour that a session can check through sail as the persona are not browser checks: geometry, document access, and what sail cannot reach are (`CLAUDE.md` §4).)*

- **Geometry of the three built pages against the mockups** (card widths, the four KPI cards in one row on desktop, grid column widths, the navy band, the strip's button alignment). Owner: Scott. Log in as `sd.assetmanager`, compare the Draws page, #66 Summary and the task form with `mockups/draw-list.html`, `draw-summary.html`, `task-approval.html`. Note deltas in `TODO.md`; the mockups are not changed by build sessions.
  - *Trigger:* before the first rehearsal.
- **The rebuilt full-width reconciliation form, as the persona (reconciliation stays a task by design, so its submit is a browser check; the persona submit itself was evidenced on 2026-09-22 by draw 75's "confirmed by Priya Raman").** Owner: Scott.
  1. As `sd.accountant` open `/suite/sites/subscription-agreement-analyst/receive-capital-call`, attach `THSV_Draw67_Budget_Template.xlsx`, click **Receive**. After ~80 s open the new draw's Summary → **Reconcile Extraction**.
  2. Expect the form full width with two side-by-side panes and the navy header "Reconcile extracted draw #<n>" (the next draw number for the investment). Left pane, top: the verdict strip "EXTRACTION instance #<n> · 12 header fields · 16 budget lines" (12 since `drawNumber` left model 85 on 2026-09-28) with the no-per-field-confidence line and the green **Ties ✓ $2,604,252.23** chip at its right; "DRAW HEADER · EXTRACTED"; the header fields in two columns of normal-width inputs, labels above, no mid-word wrapping (Draw Number / Fund / Funding Date / Cash-Equity / Over Budget Reason on the left; Investment Name / Draw Type / Draw Amount / Budget status / Submitted By on the right); Draw Number read-only "#<n>" with the instruction "Assigned by the system: the next draw number for this investment." and no chip (ruled 2026-09-28); one chip, under Investment Name (green **Matches investment on file**); no chips anywhere else; Purpose, Budget and Contingency Explanation and General Comments as full-width paragraphs; the 16-row grid with right-aligned numbers and the pinned line "Current Draw total $2,604,252.23 vs draw amount $2,604,252.23 Ties ✓" beneath it.
  3. Right pane: "SOURCE DOCUMENT", the xlsx name as a download link, and the workbook rendered inline (DocCenter's viewer) at TALL height — cells legible, no "cannot be displayed" fallback. If the viewer shows the fallback link instead, note it: it means the persona lacks Viewer on `AIA Reconcile Connected System` (granted to `SD Draw Approvers` on 2026-09-22) or the plug-in refuses xlsx for non-designers.
  4. Edit Hard Costs' Current Draw to 2490296.00 and tab out: the pinned total recomputes to $2,604,252.00 with amber "off by ($0.23)" (amber since Phase 6c); the verdict strip's chip turns amber **Does not tie** with the amber line "lines $2,604,252.00 vs draw $2,604,252.23 · off by $0.23" beneath it (since the 2026-09-25 chip fix). Restore 2490296.23; both turn green. Type "abc" in Investment Name: the chip turns amber **No matching investment** and Draw Number should read #1 (the sequence of draws with no investment; rule-tested, not rendered); restore it.
  5. Click **Confirm & Assemble Draw** (bottom right, the only button). Within ~15 s the draw shows #<n> · In Progress · **step 2 of 9 · Asset Manager · Elena Marchetti** (since 2026-09-28), and the Approvals tab reads order 1 Accountant · Priya Raman · Approved · "reconciliation · sd.accountant" at the confirm time; Documents tab "Extracted & Confirmed · Doc Center extraction confirmed by **Priya Raman** MM/DD/YYYY"; Budget Detail 16 lines; QIU "model as of" today; Funding History lists #<n> and the investment's prior approved draws. This is the first run with the real accountant's click: the session's run (draw 108) was confirmed by the designer, so its order 1 reads "reconciliation · scott.thorn@appian.com".
  6. Repeat at a laptop width (~1280 px) and a phone width: the panes stay side by side on desktop; the header columns stack on a phone.
  - *Trigger:* before the first rehearsal.
- **The rebuilt intake page in a browser.** Owner: Scott. As `sd.accountant` open `/suite/sites/subscription-agreement-analyst/page/receive-capital-call`: navy header "Receive Capital Call"; the upload card with Receive disabled until a file is attached; attach the xlsx, click **Receive**: expect the card to be replaced by "Capital call received · Doc Center extraction is running on THSV_Draw67_Budget_Template.xlsx · The draw appears in the Draws list immediately…", a navy **Go to Draws** card-button and an outline **Receive Another** button. Click Go to Draws: the Draws page opens in the same tab with a new "New draw · Ingesting" row. Back on the page, Receive Another returns the empty upload form. *Trigger:* before the first rehearsal.
- ~~**Package intake, corroboration section and Documents tab, as the persona (Phase 5.5, reworded for Phase 5.6).**~~ Done 2026-09-25 by Scott: intake, the corroboration states, junk classification, the Documents tab and downloads verified in the browser. The one finding, chip text truncating at 40 characters, is resolved by the 2026-09-25 chip fix (see Done), and its layout has its own check below.
- **Tie-out columns and chips on the mismatch package (reworked 2026-09-28; was the 2026-09-25 chip-layout check).** Owner: Scott.
  1. As the designer: Draws → staging card → **Stage Mismatch Package**. Or use draw **106**, which the session staged the same way on 2026-09-28: its reconciliation task **536883728** is open for `SD Draw Demo Approvers` and its pay application has settled. As `sd.accountant`, open that draw's Summary → **Reconcile Extraction** (the Draws page lists it as "New draw" with YOUR ACTION).
  2. **Tie-out and Difference.** Under SUPPORTING DOCUMENTS · CORROBORATION, the pay application row reads amber **Does not tie** in the Tie-out column and amber "off by $37,500.00" in the Difference column beside it. Until 2026-09-28 both sat in one cell as a side-by-side, which this 26.6 site printed as component internals ("backgroundColor=#E6F4EC … text=Ties", Scott's browser pass). They are now two columns. Check that:
     - the tag is whole and not squeezed;
     - the Difference text wraps rather than being cut off;
     - no component internals appear anywhere on the form;
     - the grid fits the left pane without horizontal scroll.
  3. **Waiver tag.** Below the grid, expect the amber **No lien waiver received**, in full.
  4. **Draw Number.** Expect read-only "#83" (or the next number if more draws are on file) with "Assigned by the system: the next draw number for this investment.", and no chip. Under Investment Name, expect the green **Matches investment on file**, in full.
  5. **Verdict strip.** Edit Hard Costs' Current Draw to 2490296.00 and tab out. The strip shows the amber **Does not tie** with "lines $2,604,252.00 vs draw $2,604,252.23 · off by $0.23" right-aligned beneath it. Also check:
     - the pay application row reads **Does not tie** / "off by $37,500.23";
     - the pinned total reads "off by ($0.23)" in amber.

     Restore the value. Then **Confirm** (the draw lands at step 1 under its assigned number) or leave the task open.
  6. On a clean package (**Stage Corrected Package**), the pay application reads green **Ties** with no figure under Difference, and the invoice reads grey **Received · filed as Invoice**.
  7. At a laptop width (~1280 px): no tag shows an ellipsis anywhere on the form.
  - *Trigger:* before the first rehearsal that shows the package beat.
- ~~**Document download as a persona** (S9)~~ — Done 2026-09-25 by Scott: downloads from the Documents tab were verified as `sd.accountant` in the Phase 5.6 browser pass.
- **Exception review click and email-lane geometry (Phase 6a, carried into 6b).** Owner: Scott. Scott's live reply (6a steps 1–4) passed on 2026-09-26; see Done. What remains:
  1. ~~**Exception task 22161 from the task list**~~ — done by Scott 2026-09-26 (row 36). ~~**The site-reachable click on #70 (task 268455639)**~~ — done by Scott 2026-09-28 (row 61, "Reviewed").
     - Since 2026-09-28 the Summary banner shows only while a review task is open, and Mark Reviewed clears it. Verified via sail as `sd.accountant` on #70: the banner is present with its task and gone after the review; an unclear reply whose task no longer exists shows nothing on Summary.
     - No review is open on any draw today. The next second unclear reply on a draw at an email step creates one.
     - What stays a browser check is the banner's geometry the next time one is open: the amber card with **Review Reply** at the right, stacking on a phone.
  2. **Geometry of the Emails tab** (the 6a Email Exchange grid moved there in 6b), as `sd.accountant`, on #77, #78, #79, #80 and #12 › Emails, at ~1280 px and at phone width:
     - approver messages sit left, the flow's and the team's sit right; on a phone the cards go full width;
     - text wraps inside the cards, with nothing cut;
     - the time stays on one line at the card's right;
     - the AI READING block and the notes line wrap;
     - no tag shows an ellipsis (the longest is "Question · awaiting an answer", 29);
     - no horizontal scroll.
  3. **Approvals tab pointer:** "N approval emails on this draw · View the email exchange" sits under the chain and opens the Emails tab.
  - *Trigger:* before the first rehearsal of the email beat.
- **Live Q&A loop from Gmail (Phase 6b).** Owner: Scott. Loop tests cannot be an authorized sender, and they cannot show Gmail's threading; this is the proof of both.
  1. **In your scott.thorn@appian.com inbox,** open "Draw Funding Approval: Draw #73 · Tamarack Hotel & Spa Vail · $2,604,252.23 · Step 9 of 9 (CEO) [SD-DRAW-86-S9]" (sent 2026-09-26 10:53 AM EDT; staged for this check). Reply with a question, e.g. "Before I sign, what's driving the contingency spend on this draw?"
  2. **After 1–3 min, as `sd.accountant`,** open Draws › #73:
     - the Summary shows the amber card "The CEO asked a question by email — answer it from the Emails tab", your question, and **Answer Question**;
     - click it: the Emails tab opens with the amber "QUESTION FROM THE CEO · AWAITING AN ANSWER" card and the **Your answer** box; **Send Answer** is disabled until you type.
  3. **As `sd.assetmanager`** (not in the draw approval team), open #73: no amber card on the Summary; the Emails tab shows the question card **without** the reply box, and the line "The draw approval team answers approver questions from this tab." This non-member branch has not been exercised yet.
  4. **Back as `sd.accountant`,** type an answer and click **Send Answer**. Expect:
     - the green "Answer sent to scott.thorn@appian.com. It is on the thread below, and the question is answered.";
     - the question card is gone;
     - the thread shows "Priya Raman via Starwood Draw Approvals · ANSWER".
  5. **In Gmail:** the answer arrives **in the same thread** as the step email and your question, from "Starwood Draw Approvals", headed "Priya Raman answered your question on this draw.", quoting your question. Clicking Reply addresses `processmodeluuid0000f074-9ac4-8000-25d1-7f0000014e7a@ny.appiancloud.com`.
  6. **Reply "thanks, approved".** After 1–3 min:
     - #73 is **Approved**;
     - the Emails tab shows your reply with outcome **Approved by email** and its decisive phrase in the AI READING block;
     - a receipt "Recorded as your approval of Draw #73, $2,604,252.23. The chain has advanced. This was the final approval." arrives **in the same Gmail thread**;
     - the Approvals CEO row reads "email · scott.thorn@appian.com".
  7. **Geometry of the new pieces:** the amber Summary card (the button at the right; stacks on a phone), and the reply box full width inside the amber card.
  - *Trigger:* before the first rehearsal of the email beat.
- **Phase 6c browser checks.** Owner: Scott. Content and state were read through sail as the personas (see `BUILD_LOG.md`); these are what sail cannot see.
  1. **Needs chasing view** (as `sd.accountant`, Draws → **Needs chasing (3)** on 2026-09-28): the radio cards sit left above the list; the grid shows #, Draw (link + investment), Amount, Funding (date + "in N days"), Waiting On (name + role · step), Why (#12 "Step 6 waiting 10 days" with "Text staged, not sent Sep 28, 6:46 PM" beneath; #83 "Reminder sent today · text staged" on one line; #70 "Reminder sent Sep 26"), Contact (address + "task: <group>"); no horizontal scroll at ~1280 px; the five KPI cards fit one row on desktop (`EXTRA_NARROW`) and wrap on a phone.
  2. **Reminder email in Gmail**: "Reminder · Draw #70 · funding in 50 days · awaiting your approval [SD-DRAW-79-S9]" (sent 2026-09-27 ~00:38 UTC) — amber banner above the navy header, then the full step email; it threads with the step email; replying still reaches the receiver.
  3. **Digest email in Gmail**: "Draw approvals needing a chase · N draws · $… · <date>" — navy bands, the ranked table, draw links open the site record.
  4. **Treasury email in Gmail**: "Approved for funding · Draw #69 · Tamarack Hotel & Spa Vail · $2,604,252.23 · fund by Nov 16" — green "execute payment" band, PAYMENT box, APPROVAL CHAIN 9 of 9, the link opens #69.
  5. **Live SMS on your phone** — blocked: Twilio trial accounts reject free-form text (error 572006); see Deferred. Until then the rung logs "Staged · not sent".
  6. **Asset Manager edit on a real task, on the draw confirmed in beat 2** (since 2026-09-28 it is at step 2 with Elena's task the moment it is confirmed; the session's #83 has moved on to the CEO, so confirm a new corrected package): as `sd.assetmanager`, open its task from the Summary (**Review & Approve**); the form is WIDE with an editable Adjustment and Current Draw per line; change one line, watch the tie-out and net-adjustments lines recompute, Approve. Expect Budget Detail "Edited by Elena Marchetti at approval, <date>" and the Line History naming Elena. (sail cannot open tasks; on #83 the designer completed it, so its Line History names Scott Thorn.)
  7. **Staging card dry run** (as the designer), in the runbook's order: **Stage Mismatch Package** → Ingesting row "New draw · <time>" naming the mismatch PDF → a reconciliation task whose pay application reads **Does not tie** after ~2 min; **Stage Malformed Template** → "Not loaded · <time>" and the alert in Gmail after ~90 s; **Stage Corrected Package** → "New draw · <time>" with "+ 3 supporting files" → the reconciliation task after ~90 s; then in **A draw in approval**, pick a draw: **Advance to President** → the line re-checks every 30 s and turns green "… step 8 of 9 · President (James Callahan): the task is live …" after ~80 s; **Send Reminder Now** (the button shows its loading state for ~13 s) → "Draw #n (step 8 · President): reminder sent to SD Draw Demo Approvers · text staged to +1 ••• ••• 6630. It is on the draw's Emails tab and in Needs chasing."; **Advance to CEO** → green at step 9 after ~30 s; **Clean Up Old Runs…** → cancel at the confirm step unless every listed draw may go. Check the card's layout: three rows, the first two with three buttons each, right-aligned; the picker full width under the row text; text wrapping; stacked on a phone.
  - *Trigger:* before the first rehearsal of the Phase 6c beats.
- **The reminder threads with its step email in Gmail (second fix session 2026-09-28).** Owner: Scott. In scott.thorn@appian.com, find "Draw Funding Approval: Draw #83 · Tamarack Hotel & Spa Vail · $2,604,252.23 · Step 8 of 9 (President) [SD-DRAW-108-S8]" (sent 2026-09-28 10:30 PM EDT). Expect the reminder, "Re: " plus the same subject (10:30 PM, ten seconds later), **in the same conversation**, with the amber banner "Reminder: this approval is still waiting and the draw is funding in 48 days…" above the navy header, then the full step email (Hello James Callahan; A&E - Architectural +$31,000 and contingency ($67,753) from the Asset Manager's edit; the approval status with step 8 highlighted). If Gmail files it separately, note it: identical subjects are then not enough, and the reminder needs the step email's Message-ID as In-Reply-To (not settable from the Send E-Mail node over the Dev MCP). *Trigger:* before the first rehearsal of beat 5.
- **Geometry of the two Phase 3 forms** (start form drop zone; the rebuilt reconciliation form's pane split — the left pane's nine-column DENSE grid must not wrap its numbers at desktop width, and the right pane's viewer should fill the pane height). Owner: Scott. *Trigger:* with the check above.

## Client validation questions

- ~~**Funding History on an ingested draw:** the view lists the last three *approved* draws (65/64/63 for #67); the Phase 3 brief expected 66/65/64.~~ Ruled 2026-09-22: prior approved draws only; 65/64/63 is correct. `PROJECT_INSTRUCTIONS.md` Business rules.
- ~~**General Comments is not extracted from the template.** Does any real template carry General Comments, and should it be re-added with a filled specimen?~~ Ruled 2026-09-22: stays unextracted and editable at reconciliation; re-add only if a filled specimen appears. `PROJECT_INSTRUCTIONS.md` Business rules.

- ~~**The step email's reply copy now departs from the client sample (Phase 6a).** The sample's footer says Reply "Approve" or "Reject", with a red warning. The Phase 6a email instead:~~ **Ruled 2026-09-26:** the conversational copy stands; the sample's red exact-match warning is deliberately gone (the defect the client named) and is narrated, not reproduced. `PROJECT_INSTRUCTIONS.md` Business rules.
  - invites a reply "in your own words";
  - drops the red warning;
  - shows an amber "email approval is not available" line on a draw over $5,000,000.

  ~~Does the client accept this wording, or want the sample's back with the conversational rule narrated?~~

- ~~**Questions on a draw above the email limit (Phase 6b).** The guardrail check runs before the AI reads a reply, so an approver's question on a draw over $5,000,000 (e.g. Gateway #12) gets the "email approval is not available" refusal rather than being logged as a question for the team. Should a question on an over-limit draw still reach the draw approval team (the decision would still have to be made in the system)?~~ **Ruled 2026-09-26 (Phase 6c):** the guardrail blocks decisions, not conversation; interpretation runs first and only APPROVE/REJECT is refused. Built and verified on Gateway #12 (message rows 40 QUESTION, 45 GUARDRAIL with the reading, 46 refusal). `PROJECT_INSTRUCTIONS.md` Business rules.

## Deferred

- ~~**State the rung of every demo piece and the tier of every AI touch in the build record**~~ **Struck 2026-09-28:** raised by the demo-practices skill, which Scott removed on 2026-09-27 (`2382c33`).
- ~~**The preflight does not check demo-practices drift.**~~ **Struck 2026-09-28:** the skill was removed on 2026-09-27 (`2382c33`); there is nothing to compare.
- **Three constant descriptions are stale** (read 2026-09-27): `SD_FEED_PACKAGE_FAILING_TEMPLATE` says "for demo beats 1–2" (it is beat 3 since the 2026-09-27 ruling), and `SD_FEED_PACKAGE_TEMPLATE` and `SD_ADMINISTRATORS_GROUP` name the deleted `SD Stage Feed Arrival`. Descriptions only; values are right. *Owner:* the build session. *Trigger:* the next edit of any of the three constants.
- **`SD_planCleanup` labels an id that no longer exists as refused ("Not removed (seeded or a named specimen)").** Measured 2026-09-27 by calling it with 15 deleted ids: all 15 came back under `refused`. The page only passes live candidates, so the report is accurate on the button's path; a direct `testProcessModel` call with a stale id gets a misleading line. Fix: split `refused` into excluded and not found. *Owner:* the build session. *Trigger:* the next change to `SD_planCleanup` or the cleanup report.
- **The comparison with no earlier template** (the standard-template baseline in `SD_buildTemplateComparisonRequest`) and **with no layout difference** (the AI call skipped, rules text) are proven only by rule tests and the gauntlet, not by a live run. *Owner:* the build session. *Trigger:* the first malformed template for an investment with no loaded template, or a failure caused only by blank header values.
- **The overview's standard-wording fallback rate.** In 5 probe calls after the prompt was tightened, 3 overviews passed and 2 fell back. In both live runs the overview passed. If a rehearsal shows the standard wording often, revisit the prompt (not the gate). *Owner:* the build session. *Trigger:* the first rehearsal that shows "(summary in standard wording)".
- **Dependencies to re-verify on another instance:** the Excel Tools plug-in (`readexcelsheet`), DocCenter's Text Input AI skill (id 148, used with a Runtime Prompt) and the model id in `SD_TEMPLATE_COMPARISON_MODEL`. *Owner:* the build session. *Trigger:* any move of the app to another instance.
- **Dev MCP 26.6.100 is available on the App Market** (the site runs 26.6.95). The site admin updates the plugin first; then run `maintenance/dev-mcp-update.md`. *Owner:* Scott. *Trigger:* before the next build session, or when the operator chooses.
- **Second ingestion run with an edited value** (brief item 5, "if time"): folded into the browser check above, step 5. *Trigger:* that check.
- ~~**Backup documents on an ingested draw** (contractor / A&E invoices) — the pipeline attaches only the template.~~ Built 2026-09-25 as Phase 5.5 (supporting documents in the package, read and corroborated). `CLAUDE.md` business rules.
- ~~**Live paths of corroboration not yet exercised end to end:** an invoice whose total matches no line, a Backup document, and a "Not read" reading.~~ Superseded 2026-09-25 by Phase 5.6: invoices are no longer read or tied, "Not read" is retired, and the unrelated-PDF path (Backup / Not classified) ran live on draw 94. `CLAUDE.md` business rules, document handling architecture.
- ~~**The reading prompt and model per instance:** DocCenter's Doc Input skill (id 267) and `SD_DOCUMENT_READING_MODEL`.~~ Retired 2026-09-25 (Phase 5.6; the constant is deleted). Replaced by the next item.
- **Doc Center models per instance (Phase 5.6).** Classification model 7 (`sdDrawSupportingDocuments`, version 8, categories 31–34) and extraction model 86 (`sdPayApplication`, version 143, fields 3636–3638) are DocCenter data rows on this instance, not design objects, so they do not travel with the application. On another instance: re-insert them (the row shapes are in `BUILD_LOG.md`, Phase 5.6 Step 2), re-run the training set as labelled test instances, and point `SD_SUPPORTING_DOC_CLASSIFICATION_MODEL_KEY` / `SD_PAY_APPLICATION_EXTRACTION_MODEL_KEY` at the new keys. *Owner:* the build session. *Trigger:* any move of the app to another instance.
- **Doc Center classification reports no confidence (measured 2026-09-25).** The instance's confidence is null on every run, even with the version's threshold at 80, so the "low confidence → Backup" branch of `SD_gateSupportingDocClassification` is dormant: only "Other", an error or an unknown label reach Backup live (the gauntlet covers the confidence branch, G5/G6). *Owner:* the build session. *Trigger:* a DocCenter update that returns a confidence, or a ruling to use Doc Center's self-learning (off on model 7).
- **A pay application ties against $0.00 when the template has lines but no Hard Costs line (pre-existing, found 2026-09-25).**
  - `SD_corroborateDocuments` sums the `SD_PAY_APP_TIE_CATEGORY` lines. With no such line the sum is 0, so the row reads **Does not tie** / "off by $2,490,296.23" against a template figure of $0.00.
  - "No line to tie to" appears only when the template has no lines at all. Gauntlet C10 pins the current behaviour and C9 pins the no-line branch.
  - Not changed in the chip fix: the brief allowed no behaviour changes.
  - Ruling needed: should a missing Hard Costs line read "No line to tie to"?
  - *Owner:* Scott (ruling), then the build session.
  - *Trigger:* a template variant without a Hard Costs line, or the next change to the corroboration rule.
- ~~**Tie-out colours now differ by place (2026-09-25).** Three "does not tie" states use different colours:~~ **Ruled and built 2026-09-26 (Phase 6c): amber everywhere** (`SD_form_reconcileExtraction` v8, `SD_view_drawSummary` v11). `PROJECT_INSTRUCTIONS.md` Business rules.
  - the reconciliation form's verdict chip is **amber**, per the chip-fix brief;
  - the pinned total's "off by" beneath the grid is **red**;
  - the Summary's AMOUNT VERIFICATION "Does not tie" is **red**.

  ~~The last two were not chips in scope. Ruling needed: one colour for an amount that does not tie.~~
- **5.5-era draws keep 5.5 statuses and summaries.** Draws 86–91 carry supporting-document rows with status Read / Not read and stored summaries that say "invoice ties"; the rules still handle them (Read rows are treated by type), but the wording is 5.5's. Clear them at the next ingestion reset rather than rewrite them. *Owner:* the presenter or the session. *Trigger:* the next ingestion demo reset.
- **Doc Center `generalComments` field** removed from model 85 — re-add only when a template carries a filled General Comments cell (ruled 2026-09-22; `PROJECT_INSTRUCTIONS.md` Business rules). *Trigger:* that template.
- **`SD Draw Approvers` holds Viewer on DocCenter's `AIA Reconcile Connected System`** (granted 2026-09-22 for the reconciliation form's inline xlsx viewer; the `updateObjectSecurity` readback also flipped `inheritSecurity` to `true` with no inherited groups). *Status 2026-09-22:* Scott has messaged DocCenter's owners; no objection has been raised, so this is a note, not an open check. If a reply objects, revert with `updateObjectSecurity` to the original role map (administrator `14a675fc-…`, viewer `AIA All Users` only) and route the accountant to the download link. *Owner:* Scott. *Trigger:* an objection from the DocCenter owners.
- ~~**Two "New draw" rows cannot be told apart by sail (found 2026-09-28).**~~ **Closed 2026-09-28 (second fix session):** unconfirmed rows are labelled "New draw · <time>" with their package (`SD_getDrawListRows` v3), and sail opened each by its label. While two draws are Ingesting, the Draws page shows two identical "New draw" links. `sail navigate` refuses the handle ("names 2 different destinations and cannot be told apart"), so an ingesting draw's Summary is sail-reachable only when it is the only one. On 2026-09-28 that was Scott's draw 104 and the session's 106. A distinguishing label, for example "New draw · received 6:44 PM", would fix it. *Owner:* the build session. *Trigger:* the next change to `SD_page_draws` or `SD_getDrawListRows`.
- **Stage for Approval is retired but still on the instance (2026-09-28).** A confirmed draw now starts at the Asset Manager, so the staging card no longer offers it. `SD Stage Draw for Approval` (`0000f076-76a3-…`), `SD_isStageForApprovalEligible`, `SD_getStageForApprovalCandidates` and `SD_STAGE_FOR_APPROVAL_PM` are unused, and their eligibility (steps 1–2 → the Asset Manager at 3) no longer matches new draws. Delete them on Scott's word (a design-object delete is irreversible). *Owner:* Scott (ruling), then the build session. *Trigger:* the next cleanup of unused objects.
- **Chase rows sent by hand read as escalations (2026-09-28).** A reminder or text from **Send Reminder Now** is logged with the chase process's fixed notes, "Escalation level 1 on the step task … after 0 days waiting" / "Escalation level 2 (SMS) staged"; the Emails tab shows them. The wording lives in `SD Chase Approval Step`, which is not edited over the Dev MCP while its Designer setup is owed. Fix: pass the start (escalation or manual) and word the notes from it. *Owner:* the build session. *Trigger:* the first edit of `SD Chase Approval Step` after Designer setup B.
- **Evening dates read tomorrow on the record views (found 2026-09-28, third session).** The views and `SD_getDrawDetail` format decision and activation datetimes as `text(todate(x), …)`. `todate()` takes the **GMT** date (docs 26.6, `todate()`: "Otherwise the date is returned in GMT"; `local()`: `todate(local(now()))` for the local date). The step email formats the datetime directly (`text(x, …)`, the user's zone). Between 8 PM and midnight EDT the two disagree. Measured on #84 as the designer: the email's status table reads 09/28/2026 and the Approvals tab 09/29/2026 for the same decisions (02:56–02:59 UTC). As `sd.accountant` via sail the Summary and Approvals read 09/29. Real timestamps expose it; the old seeded times (10:20, 15:20, 11:05 UTC) never crossed midnight. `receivedDate` (a Date set by `today()` in the pipeline, GMT context) reads "Sep 29" for the same reason. Fix: `todate(local(x))` wherever a datetime becomes a date in the views, the list, `SD_getDrawDetail`'s day counts and the Summary's "✓ MM/DD" line (~30 `todate()` calls across nine generators, not all on datetimes); decide whether `receivedDate` should be the local date. *Owner:* the build session. *Trigger:* before the demo if it or a rehearsal runs after 8 PM Eastern; otherwise the next change to the draw views.
- **Two feeds of the same template at once can share a Doc Center instance (measured 2026-09-28).** `SD Receive Capital Call` finds its extraction instance as the newest one for the document (`SD_getExtractionInstanceIdForDocument`), because the Doc Center run's instance output is not mappable over the Dev MCP. The session's draw 110 and your draw 111 extracted template 55855 25 s apart: both took instance **898**. 110 read it while it was still blank and failed ("required header fields came back blank"), sending a spurious failure alert; 111 read it complete. Fix: identify the pipeline's own instance, for example the Doc Center run's output mapped in Designer, or the oldest instance created after this pipeline's extraction node started, with no other pipeline holding it. Until then, the runbook caution (beat 0) applies. *Owner:* the build session. *Trigger:* before the demo if the runbook caution cannot be kept, otherwise the next change to the pipeline's extraction nodes.
- **`SD_getDrawListRows` sort for Ingesting rows:** an ingesting shell sorts first only for its assignees, otherwise last with "New draw". Decide whether Ingesting should always sort first. *Trigger:* the first rehearsal.

- ~~**Draw personas can see the intake pages.**~~ **Ruled 2026-09-27: they stay visible** (`PROJECT_INSTRUCTIONS.md`); nothing to change. `SD Draw Approvers` is a viewer of the whole `SASite`, so `sd.accountant` / `sd.assetmanager` also see Dashboard, New Subscription and Subscription Records. A visibility expression on those pages (member of `Subscription Agreement Analysts`) would hide them; not done this session because the brief limited security changes to reaching the Draws page.
  - *Owner:* Scott (ruling), then the build session.
  - *Trigger:* the first rehearsal as a persona, or a ruling.
- **Page group "Draws" in the site navigation** — not exposed over the Dev MCP; a Designer step.
  - *Owner:* Scott.
  - *Trigger:* before the demo, if the flat page bar reads wrong.
- **"Save for Later" on the task form** (in `mockups/task-approval.html`) is not built: a task form has no draft save without a process change (a "save draft" path in `SD Draw Approval Step`).
  - *Owner:* the build session.
  - *Trigger:* a ruling that the demo needs it.
- **Live SMS needs a Twilio account that can send free-form text (found 2026-09-26). Ruled 2026-09-27: SMS stays STAGED for the demo** (`PROJECT_INSTRUCTIONS.md`); the item below remains the route if that ruling changes. The connected system authenticates (Scott entered the SID and token); the first live send reached Twilio and was refused: HTTP 400, error **572006** "Invalid template name. Trial accounts can only use predefined SMS templates." Two attempts, both logged as **Text failed** on #72 (draw 80, since removed by Clean Up Old Runs on 2026-09-27) with Twilio's message. `SD_SMS_MODE` is back to **STAGED** (read back v5). To go live: upgrade the Twilio account (or register a template and adapt `SD_sendTwilioSms`), then set `SD_SMS_MODE` to LIVE and fire `SD Chase Approval Step` once with `originProcessId` of a test draw's step process. *Owner:* Scott (the account), then the session. *Trigger:* the Twilio account change.
- **Stretch: AI-drafted contingency narrative** (BUILD_PLAN 6c) — skipped in 6c by Scott's ruling (2026-09-26). *Owner:* Scott. *Trigger:* a ruling that the demo needs it.
- ~~**"Advance draw (demo)" related action** (BUILD_PLAN Phase 2) is still open; the accelerator is started through `testProcessModel` today.~~ **Closed 2026-09-28:** built as the staging card's **Advance to President** / **Advance to CEO**.
  - *Owner:* the build session.
  - *Trigger:* the first rehearsal that needs a presenter-clickable accelerator.
- **Seed narrative dates are in October 2026; the clock is September.** Aging strings compute from `today()` and clamp at 0, so until October the seeded step reads "today" / "< 1 day" and the funding date reads "in N days" with N > 12. The Phase 3 ingestion run will replace the seed; until then, a re-dating script would be the §2 per-session ritual.
  - *Owner:* the build session.
  - *Trigger:* Phase 3, or the first rehearsal that needs the mockup's "2 days" / "in 12 days" to read true.
- **Record-title tie:** the record header shows "Draw Funding Approval | <investment>", and the four views repeat a fact strip beneath the tabs (the mockup's band). If the duplication reads heavy in the browser, hide the default record header (`updateRecordType.hideRecordHeader`) and render the title in the strip.
  - *Owner:* Scott (after the geometry check).
  - *Trigger:* the geometry browser check.
- **QIU `notes` width is 1,000 characters** (measured; the readback says 255). The spec says notes carry paragraphs; 1,000 may be short for a long one. Widening is a drop-and-recreate (supplemental §7).
  - *Owner:* Scott.
  - *Trigger:* the first QIU note that needs more than 1,000 characters, or Phase 3 when ingestion defines what a note holds.
- **Record-level security on the draw types**, defined once on `SD Draw` and inherited through RELATED_RECORDS. The persona accounts now exist and both read every draw (no row security yet; the views rendered identically for both personas and the designer on 2026-09-22).
  - *Owner:* the build session.
  - *Trigger:* a ruling that personas should see fewer draws than they do.

- ~~**Correct appian-supplemental §3 on group membership.**~~ **Done 2026-09-27** (see Done): corrected in the template repo, the user-level copy and this repo's copy, identical. It still states that `addGroupMembers`, `getGroup` and `listGroupMembers` return 403. That is the pre-26.6.90 behaviour. Reads work on 26.6.90 and 26.6.95, and **membership writes work on 26.6.95** (three adds measured 2026-09-21); `reference/mcp-capability-boundaries.md` records both.
  - *Owner:* Scott (the skill's owner).
  - *Change:* edit the skill in the template repo, then re-sync the user-level copy and this repo's `skills/appian-supplemental/SKILL.md`, keeping the two identical (`CLAUDE.md` §2 step 6).
  - *Trigger:* the next template sync, or earlier if a session is misled by the stale text.
- ~~**Measure whether `createProcessModel(errorAlertGroupUuid)` persists** on 26.6.95.~~ Measured 2026-09-21: `getProcessModel` returns no alert-group field, so it is unmeasurable over MCP. Moved to Browser checks owed (Designer).
- **Inventory the remaining object types** of `Starwood Demo` (rules, constants, integrations, documents, agents and so on), names only.
  - *Owner:* the build session.
  - *Trigger:* the first session that designs draw approval objects which reuse intake objects.
- **Confirm the designer identity by probe.** Run a throwaway rule returning `loggedInUser()`, then delete it.
  - *Owner:* the build session.
  - *Trigger:* the first session in which the plan gate passes.

*(Each item names its trigger.)*

- **`SD Receive Approval Reply`'s description names the old PVs** (`fromAddress` / `subject` / `body`). The trigger maps into `emailFrom` / `emailSubject` / `emailBody`. The old PVs are unused. Fix the text, and optionally delete the three unused PVs, **in Designer**, where the email trigger is safe. *Owner:* Scott. *Trigger:* the next time the receiver is opened in Designer.
- **Email paths proven by rule tests only (Phase 6a; 6b adds the non-member view of a pending question — see the Q&A browser check, step 3):**
  - a reply with no token (UNMATCHED);
  - a reply for a step not awaiting a decision (NOT_AWAITING: `SD_getReplyContext` returned it for draw 94 mid-acceleration);
  - an answer the gate could not classify. That route shares nodes 60–62 with the second-ambiguous route, which ran live; the gate's failure modes are gauntlet G7–G12.

  Re-running loop tests needs a throwaway sender again (`zz_loopTestSendReply` was deleted; its shape is in `BUILD_LOG.md` Phase 6a). *Owner:* the build session. *Trigger:* the next change to the handler or the reply rules.
- **Dependencies to re-verify on another instance (Phase 6a):**
  - the receiver's address and its Designer-set trigger (neither travels by MCP);
  - `SD_EMAIL_REPLY_ADDRESS`;
  - DocCenter's Text Input skill 148;
  - `SD_EMAIL_INTERPRETATION_MODEL`.

  *Owner:* the build session. *Trigger:* any move of the app to another instance.

## Done

- ✅ 2026-09-28 **Third session: real decision timestamps, day-spreading removed.**
  - **Ruling recorded** (`PROJECT_INSTRUCTIONS.md`): every decision is stamped at the moment it happens; the 2026-09-21 `dayOffsetPerStep` ruling is superseded; the Asset Manager's-date ruling is closed; unmatched-investment numbering (#1) is accepted.
  - **Built:** the transition's node 4 writes `now()` (no +1-day floor); the accelerator writes `now()` per step, and its `dayOffsetPerStep` parameter is gone; `SD_view_drawApprovals` v6 reads Time at Step in calendar days ("< 1 day" for a same-day step).
  - **Regression, the demo path, on #84 (draw 112):** confirmed 02:56:28 UTC → Elena's task approval 02:57:03 → Advance to President (orders 3–7, 02:57:45–02:58:32) → Send Reminder Now (14.8 s) → Advance to CEO (the President approved 02:59:56, the CEO task live). Every decision is on the same day, in time order, seconds to minutes apart. #12 and #66 were untouched; Needs chasing matches the pre-session baseline.

- ✅ 2026-09-28 **Second fix session: the Asset Manager at step 2, the accelerator stop, the manual reminder, the chased-step listing, labelled rows, the one-draw runbook.**
  - **Ruling recorded** (`PROJECT_INSTRUCTIONS.md`, "One-draw demo").
  - **Built:**
    - chains from `SD_DRAW_CHAIN_ROLES`, with order 1 approved by the confirmation and the draw starting at step 2;
    - accelerator `targetRole`;
    - `SD Send Reminder Now`;
    - the reminder threading its step email;
    - chase rows v5;
    - list rows v3 with labels;
    - page v14 (row 2 "A draw in approval").
  - **Tested end to end once, as on stage:** malformed refused (draw 107); corrected package confirmed as #83 (draw 108) at step 2 with order 1 Approved as Priya at the confirm second; the Asset Manager's YOUR ACTION as `sd.assetmanager` via sail; the edit and approval; Advance to President; Send Reminder Now; Needs chasing with #12; Advance to CEO; the CEO email.
  - **Regression:** the untargeted accelerator took #82 to the CEO on its old chain.

- ✅ 2026-09-28 **Fix session: system-assigned draw numbers, docs tie rendering, mismatch staging button, review banner, #12 specimen.**
  - **Ruling recorded** (`PROJECT_INSTRUCTIONS.md`): the draw number is system-assigned, the next in sequence. The template's number is document content only.
  - **Built:**
    - `SD_getNextDrawNumber`;
    - the reconciliation form v9: a read-only number with no chips, and separate Tie-out and Difference columns;
    - `drawNumber` removed from Doc Center model 85, the reconcile payload, the template validation and the failure email;
    - pipeline node 16 assigns the number at commit;
    - **Stage Mismatch Package** (page v13, constant `SD_FEED_PACKAGE_MISMATCH_SUPPORTING`);
    - the Summary review banner only while a task is open (v12), and the chase list the same (v4).
  - **#12:** stray row 62 deleted. The reminder (row 67) and staged text (row 68) were fired.
  - **Verified via sail:**
    - **as `sd.accountant`:** draw 105 = #82, with Funding History #82, #80, #79, #77; the review banner cleared on #70, and no banner on a stale review; #12's thread and its Needs chasing row;
    - **as the designer (render):** the mismatch draw 106 renders "Does not tie" / "off by $37,500.00" and "#83".
  - Browser checks updated.

- ✅ 2026-09-27 **Housekeeping: demo-practices skill created from the build record; supplemental §3 corrected.**
  - `skills/demo-practices/SKILL.md` was verified rule by rule against `BUILD_LOG.md`, the git history and `TODO.md`: 1 confirmed, 9 corrected, 2 added.
  - It landed in the template repo (authoritative), this repo and `~/.claude/skills/demo-practices/`, identical.
  - appian-supplemental §3 now says reads work from 26.6.90 and writes from 26.6.95. The version is 2026-09-27, and the template also gained the 2026-09-26 §9 promotion; all three copies are identical.
  - Both `CLAUDE.md` files point at the skill.
  - The ruling that draw numbers and record ids carry no demo significance is recorded; beat 2 and the plan narrative are now id-free.

- ✅ 2026-09-27 **Fix session: stage-for-approval and optional cleanup buttons; runbook without resets.**
  - **Rulings recorded** (`PROJECT_INSTRUCTIONS.md`, the runbook):
    - Ingested chains start at step 1.
    - Demo prep is clickable only.
    - Draw 66 is list history.
    - Success before failure.
    - Twilio stays STAGED.
    - Intake pages stay visible to the draw personas.
  - **Built:**
    - **Stage for Approval** (`SD Stage Draw for Approval`; accelerator params `stopAtStep` and `attribution`).
    - **Clean Up Old Runs** (`SD Clean Up Old Runs`).
    - The keep-list and seed constants.
    - Five rules.
    - `SD_page_draws` v12.
  - **Verified:**
    - Guards refused 66, 87 and 75.
    - #82 was staged, and sd.assetmanager saw YOUR ACTION and "Your approval is pending" through sail.
    - The edit-and-approve wrote two events.
    - The accelerator ran to the CEO; the step email's status table showed 1–2 N/A, 3 with the edit comment, 4–8 accelerated and 9 current.
    - The cleanup of 14 draws: report equal to the plan, absence read back, seeds and keep list intact; the report's process count was fixed and re-verified on draw 102.
    - The regression intake landed at step 1 (#81, draw 101).
    - The failure path was unchanged (draw 100).
  - Designer setup B–D still owed, so the ladder was not re-verified.

- ✅ 2026-09-26 **Phase 6c: velocity ladder, site-reachable exceptions, Asset Manager edit, treasury content, feed staging** (the final build phase).
  - **Rulings recorded** in `PROJECT_INSTRUCTIONS.md`: nothing requires Tempo; the guardrail blocks decisions, not conversation; tie-out non-tie is amber everywhere.
  - **Verified:** guardrail order on Gateway #12 (QUESTION row 40 reaches the team; approval row 45 refused with its reading, refusal row 46); the email-reply review reachable from the site as `sd.accountant` and absent for `sd.assetmanager` (sail, draw 79 / #70); cycle time on Summary, Approvals and the fifth KPI; reminder and text rungs fired through the escalation path (`originProcessId` only); the chase view and digest; the Asset Manager edit's write path, attribution and block at other steps (#74, #70); treasury HTML on a live email approval (#69, draw 78); the clean package through the feed path (draw 99, rendered TIES); both personas' Draws page read back.
  - **Found and fixed via sail:** the Draws page failed for `sd.accountant` ("Insufficient permission": `group()` on a step group the persona cannot see) — group names now come from the step-group constants; a staged text read "Text sent" in the chase view.
  - **Not done:** live SMS (Twilio trial restriction, Deferred); escalation/trigger/schedule setup (Designer, Before demo); the contingency narrative stretch (skipped by ruling).

- ✅ 2026-09-26 **Phase 6b: the email lane becomes a conversation.**
  - **Built:** approver questions logged and pending (Summary card for the team, Emails tab for all); the specialist's answer from the record on the same thread; the grounded-quote gate with wording checks; decision receipts; the thread on its own Emails tab, with a pointer on Approvals.
  - **Tests:** the gauntlet passes 45/45; an 8-specimen live prompt probe passed.
  - **Verified end to end on draw 95:** question → pending → answer as `sd.accountant` via sail → cleared → hedge read AMBIGUOUS → approve with its phrase stored → receipt → treasury.
  - **6a regressions:** unauthorized and guardrail still behave. Draw 66 untouched.
- ✅ 2026-09-26 **Scott's live Gmail reply (6a browser check, steps 1–4).** "This looks good to me. Go ahead with the draw and proceed." from scott.thorn@appian.com on #79 was read as APPROVE and completed the chain (row 19).
  - The real sender address was kept, and Reply-To routed the reply to the receiver.
  - His plain-text Gmail signature stayed in the stored text (no "-- " delimiter; known artifact).
- ✅ 2026-09-26 **Phase 6a: CEO approval by email reply.**
  - **Built:** the receiver and handler, the reply rules and their gauntlet (29/29), the exception form, the dollar guardrail, thread continuity, and the Approvals tab's Email Exchange.
  - **Verified end to end by loop-test email, draw 66 untouched:** unauthorized sender, approve (with treasury), reject, unclear once (clarification), unclear twice (exception task), and the guardrail.
  - **Read back:** as the designer, and on the Approvals tab as `sd.accountant` via sail.
  - Scott's live reply is owed (Browser checks owed).
- ✅ 2026-09-25 — **Chip fix: every tag under 40 characters, with figures in wrapping text.**
  - Changed (old → new, all in the reconciliation form or its corroboration rule):
    - the verdict "Does not tie · lines $X vs draw $Y" → amber **Does not tie** plus a wrapping line;
    - the tie-out "Does not tie: $X vs $Y" → **Does not tie** plus "off by $X" beside it;
    - "No <category> line to tie to" → **No line to tie to** plus a detail line;
    - the waiver tag → **No lien waiver received**;
    - the renumbered chip → **Renumbered from #N (on file)**;
    - "#N is already on file for this investment" → **#N already on file**;
    - "Out of sequence: last draw is …" → **Out of sequence (last #N)** / **(none on file)**;
    - "Matches <name> on file" → **Matches investment on file**.
  - Verified by `testInterface` on the live payloads (draws 92, 93, 94) and on constructed states: next in sequence, out of sequence, a forced already-on-file value, and a non-tie. The longest rendered tag is 29 characters.
  - Gauntlet 10/10.
  - Persona smoke check as `sd.accountant`. Browser layout check owed (above).
- ✅ 2026-09-25 — **Phase 5.6 browser checklist (Scott):** intake, the corroboration states, junk classification, the Documents tab and downloads, verified in the browser. The one finding was chip truncation at 40 characters, resolved the same day by the chip fix.

- ✅ 2026-09-25 — **Phase 5.6 built and verified live.** Supporting documents are now typed by a Doc Center classification model. Only the pay application is read, by extraction.
  - **Models and training:** classification model 7 / version 8, trained on 24 labelled specimens, 24/24 correct; extraction model 86 / version 143.
  - **Rewiring:** the worker `SD Classify Supporting Document`; the 5.5 prompt and parser deleted.
  - **Live runs:** clean draw 92 (#77, TIES), mismatch 93 (#78, ATTENTION), junk 94 (#79, TIES with "1 not classified"), template-only 95 (#80, NONE), and v2 regression 96 (Ingestion Failed).
  - Persona reads as `sd.accountant` and `sd.assetmanager`. Draw 66 untouched.
  - Browser checklist owed (Browser checks).

- ✅ 2026-09-25 — **Phase 5.5 built and verified live:** package intake (upload slots), AI reading of supporting documents, corroboration at reconciliation and on the draw. Clean package draw 86 (#73, TIES), mismatch draw 87 (#74, ATTENTION), template-only draw 88 (#75, NONE), failure regression draw 89 (Ingestion Failed); persona reads as `sd.accountant`; draw 66 untouched. Browser checklist owed (Browser checks).

- ✅ 2026-09-25 — **Phase 5 browser checks (Scott):** the ingestion failure alert verified in Gmail, and the failed-draw card verified in the UI as the persona.
- ✅ 2026-09-25 — **Phase 5 built and verified live:** ingestion failure path with AI template comparison (draw 83, the alert sent from the failure branch, persona reads as `sd.accountant` and `sd.assetmanager`, clean-template regression on draw 84). Gmail eyeball owed (Browser checks).
- ✅ 2026-09-25 — **Browser check (Scott): the Phase 4 approval email in Gmail** — no clipping, the tables render correctly.
- ✅ 2026-09-25 — **Ruling: Gmail routing stays exactly as wired** (closes Phase 4's open ruling). scott.thorn@appian.com receives every step email and plays the CEO at the demo's email beat; no persona addresses, no recipient overrides.
- ✅ 2026-09-21 — **Service accounts in `SD Administrators`:** ruled an exception. `scott.mcp` and `NoahMCPServiceAccount` stay in the group, because `scott.mcp` backs the chat runtime connector and removal risk is not worth it on a demo instance. The ruling is recorded at the end of `CLAUDE.md` §6.
- ✅ 2026-09-21 — **Host application:** `Starwood Demo` (`dd3bb740-b105-421b-a866-29d542a144da`) is confirmed. `Capital Calls & Distributions` is another client's app and out of scope; do not read from it or reference it. Recorded in `PROJECT_INSTRUCTIONS.md` and `CLAUDE.md`.
- ✅ 2026-09-21 — **Dev MCP updated from 26.6.90 to 26.6.95 and re-verified.** Both halves report build `20260911-210447`, and sail reports 26.6.95. The pins in `reference/toolchain.md` §1 and §12 are refreshed.
- ✅ 2026-09-21 — **Phase 0 plan written.** `PROJECT_INSTRUCTIONS.md` is complete, and `BUILD_PLAN.md` is authored and passes the plan gate.
- ✅ 2026-09-21 — **Phase 0 discrepancies: all seven ruled** and applied to `PROJECT_INSTRUCTIONS.md` and `BUILD_PLAN.md`.
  1. "Accounting manager" means the Accounting Controller, order 2. Orders 1–2 are pre-completed, and the chain sits at the Asset Manager, order 3.
  2. The CEO (order 9) is the live email approver. The Executive (order 5) is data only.
  3. The Fund Accountant is the chain's Accountant (order 1); that step is data only.
  4. There are ten QIU metrics, listed in canon order.
  5. The chain has nine contiguous orders, 1–9. The sample's gap at order 4 is a source artifact and is not reproduced.
  6. `SD Investment` is a record type (name and description, related to `SA Fund`). DealCloud is narrated, not integrated.
  7. Blue Granite continuity is narration only. The flow never reads or writes subscription records.
- ✅ 2026-09-21 — **Phase 1 core built and verified:** six record types, seed, groups, constants, rules, task form, four process models (transition, step, launcher, accelerator), happy path and reject break-test as the designer.
- ✅ 2026-09-21 — **Browser checks (Scott):** treasury and step emails received (outbound email confirmed); alert group persists on all four models; task form renders in Tempo and blocks a blank-comment reject.
- ✅ 2026-09-21 — **Rulings recorded:** Budget Summary as roll-up; accelerator dates 1 day per step; mockups from the Project; demo runs from Phase 3 ingestion.
- ✅ 2026-09-21 — **Column widths proven through the production path:** 4,000 and 1,000 as requested; readback of 255 is wrong; no truncation.
- ✅ 2026-09-21 — **Race test passed after the settle fix;** timing recorded (87 s).
- ✅ 2026-09-22 — **Spec artifacts uploaded to the claude.ai Project** (they stay out of GitHub by `.gitignore`).
- ✅ 2026-09-22 — **Persona accounts and sail logins:** `sd.accountant` (SD Draw Demo Approvers) and `sd.assetmanager` (SD Draw Asset Managers), both in SD Users, live sail sessions in `~/.sail-sd.accountant` and `~/.sail-sd.assetmanager`; Persona site stub set. Seed rows carry the accounts' display names.
- ✅ 2026-09-22 — **`sd.accountant` renamed to Priya Raman (Scott, Admin Console) and the seed re-synced:** approval rows 1101, 1201, 6301, 6401, 6501, 6601, 6610, 6619 and document row 6601 updated by explicit id; `scripts/seed_draw66.py` and `CLAUDE.md` say Raman; readback zero "Ramen"; Draws page as `sd.accountant` reads "Accountant Priya Raman".
- ✅ 2026-09-22 — **Rulings recorded (fix session):** reconciliation stays a task (persona submit = browser check by design); Funding History = prior approved draws; General Comments stays unextracted and editable; Doc Center xlsx extraction proven (format question and PDF fallback struck); ingested chain starts at step 1 with the accelerator bridging. `PROJECT_INSTRUCTIONS.md` and `BUILD_PLAN.md`.
- ✅ 2026-09-22 — **Phase 4 core built:** the approval step email is HTML from live draw data (`SD_buildApprovalEmail` + helpers, node 8 of `SD Draw Approval Step`), verified on draws 66 and 12 by render and on draw 75 by a live send; the Gmail look is the browser check above.
- ✅ 2026-09-22 — **`SD_getOpenTaskId` hardened** to live statuses (0 Assigned / 1 Accepted): the aborted task 536874206 on the cancelled step 536909940 now reads null; the live task 536876873 on 536909994 still returns.
- ✅ 2026-09-22 — **Browser check (Scott): the task opens from #66's Summary strip as `sd.assetmanager`** — the restyled form renders from Review & Approve, Reject without a comment is blocked ("A comment is required when rejecting a draw."), Approve reads "Comments (optional)"; the task was left open (now 536876873 after the restart).
- ✅ 2026-09-22 — **DocCenter owners messaged about the `SD Draw Approvers` Viewer grant** on `AIA Reconcile Connected System`; no objection so far (note kept under Deferred with the revert recipe).
- ✅ 2026-09-22 — **Draw 66's current approver can act again:** the step process behind draw 66 (536909940) had been cancelled — its task 536874206 read Aborted with no assignees — so no Review & Approve link could render; `activeStepProcessId` cleared by CSV and `SD Draw Approval Process` restarted at step 3 (step process 536909994, task 536876873 assigned to `SD Draw Asset Managers`); approval rows untouched. As `sd.assetmanager` via sail: AWAITING 1, #66 YOUR ACTION, Summary strip with Review & Approve (ProcessTaskLink 536876873); as `sd.accountant`: no action on #66.
- ✅ 2026-09-22 — **Intake confirmation state:** `SD_page_receiveCapitalCall` replaces the frozen launcher and its start form (both deleted, absence confirmed); Receive = submit upload → `a!startProcess`; confirmation state, Go to Draws, Receive Another; verified as `sd.accountant` via sail (two shells, 76 and 77, on the Draws list). The frozen-launcher deferred item is removed.
- ✅ 2026-09-22 — **Draw-number collision handling at reconciliation** ruled and built: renumber-on-collision with the amber chip, green "Next in sequence" otherwise; both states proven by `testInterface`. *(Superseded 2026-09-28: draw numbers are system-assigned and the sequence logic is removed.)*
- ✅ 2026-09-22 — **Reconciliation form rebuilt full width** with the inline document viewer, verdict strip, two-column header, pinned recomputing total, two chips, single primary button; `testInterface` clean on instance 849 and on a control (draw 12 → "Next in sequence").
- ✅ 2026-09-22 — **Phase 2b built and persona-verified:** Draws page, four `SD Draw` views, restyled task form, seed texture, monotonic decision dates; `SD Draw Approvers` views `SASite`.

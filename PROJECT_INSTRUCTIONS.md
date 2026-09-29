# Project instructions — Starwood draw approval

*Phase 0 complete, 2026-09-21. The header facts come from instantiation. The sections below Header facts are the Phase 0 transcription from the claude.ai Project.*

## Header facts

- **Repo:** https://github.com/sthorn124/starwood-fund-ops
- **Client:** Starwood
- **Appian instance:** `ny.appiancloud.com`
- **Application:** `Starwood Demo`, the existing subscription-intake app. Its UUID is `dd3bb740-b105-421b-a866-29d542a144da`.
- **Host application, ruled 2026-09-21:** draw approval lives in `Starwood Demo` (`dd3bb740-b105-421b-a866-29d542a144da`), which is confirmed. `Capital Calls & Distributions` on the same instance belongs to a different client and is out of scope for this build. Do not read from it or reference it.
- **App prefix:** `SD`
- **Flow name:** **draw approval**. This is the canonical name. Use it consistently in all objects, docs, and commits.
- **Spec source:** the three artifacts in the repo root are the authoritative spec for the new approval email layout and for the Sep/Oct 2026 enhancement scope.
  - `current approval email sample blacklined.pdf`: the approval email as it is today, redacted.
  - `New approval email sample blacklined.pdf`: the new approval email layout, redacted.
  - `Draw workflow enhancements simple overview 9-12-26.xlsx`: the current draw workflow, with the Sep/Oct 2026 enhancements and notes beside each step.

  **These files are local only.** The repo's `.gitignore` excludes `*.pdf` and `*.xlsx`, so they are **not on GitHub**. Any reader working from GitHub, including the claude.ai Project, must be given them directly, for example by uploading them to the Project.

## Demo narrative
Continuation of the subscription intake story on one platform: Blue Granite's capital entered Harborline Real Assets Fund II through intake; this flow deploys it. A hotel property held by the fund submits draw #66 ($2,604,252.23, PIP/Renovation) with the standard Excel budget template. The demo runs the future state front to back:
1. The capital call and template arrive (narrated as the EY API/SFTP feed; triggered manually in demo).
2. Ingestion fails on a malformed template. The alert email to the accountant and asset managers explains the failure in plain English, with an AI comparison against the last successfully ingested template describing what changed.
3. The corrected template ingests via Doc Center. The accountant reviews extraction results and confirms; budget data lands in the draw tables and appears in the UI.
4. QIU data is aggregated to the draw. The pre-completed approvals are orders 1–2: the Accountant and the Accounting Controller are both Approved. The chain sits at the Asset Manager step, order 3. *Ruled 2026-09-22: this applies to the seeded draw 66. An ingested draw starts its chain at step 1 (Accountant), and the demo accelerator bridges from wherever the chain sits to the CEO step; revisit only if rehearsal shows drag.*
5. The asset manager reviews in the UI, edits a budget line at their approval step, and approves.
6. The CEO (order 9) receives the new-format approval email, replies conversationally ("looks good, approve"), and AI interprets the reply as an approval. The chain completes.
7. Treasury receives the execution notification. Capital moves.
**Demo order and demo prep, ruled 2026-09-27 (fix session; supersedes the beat order above and every reset-based preparation).**
- **Success before failure.** The demo shows a successful ingestion before the failure path: (1) the corrected package arrives from the feed and ingests; (2) the accountant reconciles and confirms it (that draw's on-stage story ends at step 1); (3) the malformed template arrives and fails, with the alert and the AI comparison; (4) QIU and the chain on a draw staged for approval; (5) the Asset Manager edits a line and approves it; (6) the chain runs on and the CEO approves by email; (7) treasury is told to fund.
- **Demo prep is clickable only.** The Draws page's administrators-only staging card stages what the beats need: the feed packages (the corrected package, the malformed template and, since 2026-09-28, the mismatch package: the same template with a pay application that does not tie to Hard Costs), and one pre-demo **Stage for Approval** click. Nothing is reset, reused or cleaned by requirement; no script runs before a demo. **Clean Up Old Runs** exists and is optional.
- **Ingested chains start at step 1**, as built (the 2026-09-22 ruling stands). Stage for Approval brings an ingested draw to the Asset Manager step by approving orders 1–2 as their named approvers, with the accelerator's date mechanics.
- **Draw 66 stays as seeded list history.** No beat requires it; it is never reset for a demo.
- **Twilio stays STAGED** (ruled): texts are composed and logged as "Staged · not sent" until an account that can send free-form messages exists.
- **Intake pages stay visible to the draw personas** (ruled): `SD Draw Approvers` keeps its viewer role on the whole site.
- **Draw numbers and record ids carry no demo significance** (ruled from 2026-09-27; closes the beat-2 ruling). No beat, specimen, staging step, prompt or plan may depend on a specific record id or business number. ~~The sequence chips ("Next in sequence", "Out of sequence", "Renumbered … (on file)") are narrated as a control, not scripted around. Beat 2's "Out of sequence → type the next number" stands.~~ *(Superseded 2026-09-28 by the system-assigned draw number below: the chips and the typing are gone.)* The keep-list of nine specimens (`SD_DEMO_KEEP_DRAW_IDS`) is confirmed.

**One-draw demo, ruled 2026-09-28 (second fix session; supersedes the success-first order and Stage for Approval above).**
- **Order:** failure opens, recovery follows. Prep stages the mismatch package; beat 1 the malformed package is refused; beat 2 the corrected package is confirmed; beat 3 the mismatch draw is opened and closed unconfirmed; beats 4–7 follow one draw from the Asset Manager to treasury. No stage-for-approval click exists in prep or demo.
- **Chain for ingested draws:** built from `SD_DRAW_CHAIN_ROLES`, not copied from the prior draw: 1 Accountant, 2 Asset Manager, 3 Accounting Controller, 4 AM SVP, 5 Executive, 6 Chief Accounting Officer, 7 CFO of Funds, 8 President, 9 CEO. Approver names may still come from the prior draw, matched by role. The accountant's confirmation is the first approval: order 1 is written Approved at the confirm time, attributed to the confirming accountant, and the draw starts at step 2 with the Asset Manager's task live. Existing draws keep their historical chains; the email and status table render whatever the rows say.
- **Accelerator target:** President or CEO, default CEO. To the President it approves through step 7 and leaves step 8 In Progress with a live task; a later run to the CEO advances from wherever the chain sits.
- **Send Reminder Now** (staging card, the draw picker): runs the chase mechanism for the chosen draw's current step at once, with no waiting-days threshold: the reminder on the step's thread and the staged text.
- **Needs chasing** also lists a step with a reminder sent or a text staged, whatever its age, and the Why column says so ("Reminder sent today · text staged"). The 3-day rule is unchanged.
- **Unconfirmed draw rows** on the Draws page are labelled by received time and package ("New draw · 6:44 PM", with the template and supporting files), so two are tellable apart on stage and by sail.
- **Decision dates are real timestamps (ruled 2026-09-28, the third session of the day; supersedes the 2026-09-21 `dayOffsetPerStep` ruling and closes the open ruling on the Asset Manager's date).** Every approval decision is stamped at the moment it happens, whether from a live task, an email reply, the reconciliation confirm or an accelerator advance. There is no +1-day floor and no forward-dated step. "The chain approves over the following days" is narration only. Existing draws' dates are historical data and stay untouched.
- **A draw whose investment matches nothing is numbered in the sequence of draws with no investment (#1), as built.** Accepted 2026-09-28.
- **Dates are local (ruled and built 2026-09-29; rehearsals run at night).** A decision or activation time becomes a date in the viewer's time zone on every screen (`todate(local(x))`), and in the business time zone, `SD_BUSINESS_TIMEZONE` (America/New_York), wherever a process builds or stores a date: the step and treasury emails, `receivedDate`, the QIU as-of date and the budget-edit note. After 8 PM Eastern the record and the email now show the same date. This closes the Deferred evening-date item. Dates already stored stay as they are.
- **The Draws list flags what the draw approval team owes an answer to (2026-09-29).** A row shows an amber **Question waiting** while the approver's email question has no answer, and **Reply needs review** while an email reply's review task is open — on its own line in the Current Step cell, under the approver and days (moved there from the Status column the same day; Status shows the status chip alone). The derivations are the Summary's own two cards, so the tag goes when the question is answered or the reply reviewed. The team sees the tags; the action stays on the draw.
- **The Draws list fits a laptop without horizontal scrolling (2026-09-29).** Its columns use relative widths — Draw, Type, Amount, Funding Date and Status 2X, Investment 3X, Current Step 4X — which share the grid's width instead of adding up past it; long labels wrap.
- **The keep list is pocket-only (ruled 2026-09-29).** Clean Up Old Runs keeps the seeds (`SD_SEED_DRAW_IDS`: #11, #12, #63–#66, excluded automatically) and two pocket specimens (`SD_DEMO_KEEP_DRAW_IDS`): **#70**, the second-vague email-reply thread at the CEO step, and **#78**, the mismatch package rejected at step 9. Everything else a demo needs is produced live or by a staging button. The earlier named specimens (#69, #73, #74, #77, #79, #80 and the Sep 25 failed ingest) were removed that day, and runbook fallbacks that named them now point to a live run or a staging button.
- **The same-template collision stays Deferred** (2026-09-29), with the runbook's beat-0 caution: never start two feeds of the same template within about two minutes.

The 9-step approval chain (contiguous orders 1–9, as in the current email sample) exists as data and renders in the status table; live interactions are the asset manager (UI) and the CEO (email) only. Chain steps between the asset manager and the CEO are advanced by a demo accelerator, narrated as the chain approving over subsequent days.

## Personas
- Fund Accountant. Owns ingestion. Receives failure alerts with the AI diff, reviews Doc Center extraction results, approves the AI-drafted contingency narrative. This is the same person as the chain's Accountant role (order 1). The order 1 approval step is data only: it is seeded as Approved and never acted on live.
- Asset Manager. Reviews the draw at their step, edits budget data at approval, receives ingestion failure alerts.
- CEO (order 9). Approves by email reply only. Never opens the UI. The Executive role (order 5) is a separate, data-only chain role.
- Remaining chain roles (Accountant, Accounting Controller, AM SVP, Executive, Chief Accounting Officer, CFO of Funds, President) exist as approval data, spoken to, not shown. The Accountant row is the Fund Accountant's data-only approval.

## Data model (entity level)
- SD Investment: name and description, mapping the new email's "Investment Name" and "Investment Description [from DealCloud]". It is related to the existing SA Fund. DealCloud is narrated as the upstream source and is not integrated.
- SD Draw: header facts (funding date, draw type, purpose, amount, budget status, over budget reason, general comments, contingency explanation, status, current step); related to SD Investment, and through it to SA Fund.
- SD Draw Budget Line: budget category, category group (Land/Soft/Hard), initial budget, revised approved budget, proposed adjustments this draw, proposed budget, current draw, total PTD ($ and %), balance to complete, in-this-draw flag.
- SD Draw Approval: order, role, approver, status, decision date, comments. Drives both routing and the status table.
- SD QIU Metric: the ten metrics from the email samples, model as-of date, current model value, current projection, variance, notes. The metrics, in order:
  1. IRR
  2. Profit
  3. Multiple
  4. Peak Equity
  5. Current Equity Contributions (through prior quarter)
  6. Current Quarter Equity Contribution
  7. Future Equity Contributions (after current quarter)
  8. Distributions To-Date (through prior quarter)
  9. Current Quarter Distribution
  10. Future Distributions (after current quarter)
- SD Draw Document: the source template and backup documents attached to the draw.
Field vocabulary follows the new approval email sample exactly.

## Build phases
*Restructured by ruling on 2026-09-21: interfaces moved out of Phase 1 into a new mockup-first Phase 2, and the later phases shifted by one.*
- Phase 1: data model (including SD Investment), seed data, data-driven sequential approval process with demo accelerator and treasury notification terminal step. No custom views.
- Phase 2: UI foundation, mockup-first: HTML mockups for the draw list and draw summary views in mockups/, reviewed and approved before any SAIL is written; then the views built against them, on the existing intake site in a new page group.
  - Mockups are authored in the claude.ai Project and delivered into mockups/. Build sessions treat them as the UI contract and do not author or modify them. Ruled 2026-09-21.
- Phase 3: Doc Center ingestion success path: template in, extraction, accountant reconciliation, budget tables populated, data on the UI.
- Phase 4: new approval email layout rendered as HTML email from live draw data, matched to the spec PDF.
- Phase 5: ingestion failure path: plain-English alert email, AI diff against the last successful template.
- Phase 5.5 (2026-09-25): supporting documents in the package, corroborated at reconciliation. Phase 5.6 (2026-09-25): supporting documents classified by a Doc Center classification model; extraction on pay applications only.
- Phase 6 was split on 2026-09-26:
  - Phase 6a: CEO email approval with AI reply interpretation (receiver, interpretation, dollar guardrail, thread continuity, exchange on the Approvals tab).
  - Phase 6b (rescoped 2026-09-26): the email lane becomes a conversation — approver questions answered from the draw record on the same thread, a grounded-quote interpretation gate, decision receipts, the thread on its own Emails tab.
  - Phase 6c: the velocity set (deadline reminders through task escalations, a chase digest backed by a site view, cycle-time capture, SMS staged); asset manager budget edit at approval step; treasury notification content; tie-out colour unification; feed staging; AI-drafted contingency narrative with accountant review (stretch); polish.

## Vocabulary canon
- Flow name: draw approval. Never "capital call" in object names; "capital call request" acceptable in narrative text only.
- Roles, exact: Accountant, Accounting Controller, Asset Manager, AM SVP, Executive, Chief Accounting Officer, CFO of Funds, President, CEO.
- Draw types: Development, PIP/Renovation. Demo draw is PIP/Renovation.
- Category groups: Land, Soft, Hard.
- Approval statuses: Pending, In Progress, Approved, Rejected.
- QIU stays QIU, unexpanded. Extraction platform is Doc Center.
- "Accounting manager" in source documents (narrative beat 4, workflow xlsx step 3) means the Accounting Controller, order 2. The term does not appear in object names or UI text.
- Approval orders are contiguous 1–9: 1 Accountant, 2 Accounting Controller, 3 Asset Manager, 4 AM SVP, 5 Executive, 6 Chief Accounting Officer, 7 CFO of Funds, 8 President, 9 CEO. The new email sample's status table skips order 4 and runs to 10. That is a source artifact in the client mockup, not a tenth step; the build does not reproduce the gap.

## Business rules
- Approvals are strictly sequential by order; Approve advances, Reject terminates the draw, final approval sets the draw Approved and triggers the treasury notification.
- Email approval accepts conversational replies; AI classifies intent as Approve, Reject, or Ambiguous. Ambiguous generates a clarification reply, never a state change.
  - **How a reply is matched (Phase 6a, 2026-09-26).** Every step email's subject ends with the token `[SD-DRAW-<drawId>-S<step>]`. A reply is matched by that token, which survives Re:/Fwd:.
  - **Checks, in order, before any AI call (the guardrail moved after the reading in Phase 6c):**
    1. Draw and step found.
    2. Sender authorized for the step's role, through the constant role→address mapping (for the demo every role maps to scott.thorn@appian.com).
    3. The step is the one awaiting a decision.
    4. Dollar guardrail (below): since Phase 6c a flag, applied after the reading and only to a decision.
  - **When a check fails,** nothing changes and the reply is logged on the draw. This covers an unauthorized sender and a step not awaiting a decision; the log is visible in the Approvals tab.
  - **Reading the reply.** One Generative AI skill call reads the reply's own words (quoted history cut first) as APPROVE, REJECT or AMBIGUOUS, with the reply's own comment. A deterministic gate turns any malformed answer into an unclassified AMBIGUOUS.
  - **APPROVE or REJECT** goes through the one decision transition with source EMAIL. The approval row's comments carry the reply text and the reading, and final approval triggers treasury as usual.
  - **Exceptions.** An unclassifiable reply, or a second unclear reply on the same step, goes to an exception-queue task for SD Draw Demo Approvers. It sends no email and changes nothing.
- **Questions by email (Phase 6b, 2026-09-26).** A reply may ask a substantive question about the draw instead of deciding ("what's driving the contingency spend?").
  - It is read as QUESTION, logged on the draw, and changes nothing: the step keeps awaiting its decision. Nothing is sent back to the approver automatically.
  - The question is pending until the draw approval team (SD Draw Demo Approvers) answers it from the draw record, or the step is decided. The Summary shows it to that team; the Emails tab shows it to everyone.
  - The answer goes on the same email thread to the step's approver address and is logged with the answerer's name. The approver's next reply is read as usual: a decision, another question, or unclear.
- **Grounded interpretation (Phase 6b, ruled guardrail design).** The AI must quote the decisive phrase: the exact words in the reply that make the decision or ask the question.
  - A decision is applied only when that phrase appears verbatim in the reply. A phrase that is missing or not in the reply makes the reading AMBIGUOUS, never applied.
  - A conditional or hedged decision is AMBIGUOUS. Examples: "approve everything except line 3", "approved if the lender signs off", "probably fine, I guess". The fixed-rules gate also refuses an approval whose sentence carries a condition, an approval with no approval words ("great work team!"), and a refusal read as an approval.
  - The phrase is stored with the reading and shown on the thread.
- **Decision receipt (Phase 6b).** When an email decision is applied, the approver gets a short receipt on the same thread: "Recorded as your approval of Draw #<n>, $<amount>. The chain has advanced." A rejection gets the rejection wording. No action is requested and no reply is expected. The treasury notification on final approval is unchanged.
- **The thread has its own tab (Phase 6b).** The Emails tab (Summary / Budget Detail / Approvals / Emails / Documents) shows the approval email thread as one conversation, with the pending question and the reply box on top. Approvals keeps a one-line pointer.
- **Step email reply copy (ruled 2026-09-26).** The step email's conversational reply instruction ("reply in your own words") stands. The client sample's red exact-match warning (reply exactly "Approve" or "Reject") is deliberately gone: it is the defect the client named. It is narrated in the demo, not reproduced.
- **Dollar guardrail (Phase 6a, ruled 2026-09-26).** A draw above `SD_EMAIL_APPROVAL_MAX` ($5,000,000) cannot be decided by email at any step.
  - A reply on such a draw changes nothing.
  - The sender is told on the thread to decide in the system, and the attempt is logged on the draw.
  - THSV draws ($2.6M) are approvable by email; Gateway #12 ($8.94M) is refused.
  - **The guardrail blocks email decisions, not email conversation (ruled 2026-09-26, Phase 6c).** Interpretation runs before the limit check. On an over-limit draw a QUESTION or an AMBIGUOUS reply flows normally (the question reaches the team, the hedge gets a clarification that also says the decision must be made in the system); only a reply read as APPROVE or REJECT gets the refusal, and the refusal row carries the reading.
- **Nothing in the draw approval flow requires Tempo (ruled 2026-09-26, Phase 6c; standing rule).** Every task and every action is reachable from the site: the Summary's action area (step decision, reconciliation, email-reply review) or the Draws list (YOUR ACTION rows, the KPI, the Needs chasing view). A new task type is not done until the site links it for its assignees and shows its state to everyone else. *Refined 2026-09-28 (fix session): the Summary's email-reply review card shows only while an open review task exists, and Mark Reviewed clears it. An unclear reply with no open task shows nothing on the Summary; the Emails tab keeps the full history. There is no "task not found" state.*
- **Tie-out non-tie colour is amber everywhere (ruled 2026-09-26, Phase 6c).** A figure that does not tie is a warning to resolve, not an error: the reconciliation verdict, the pinned total's off-by line, the document chips and the Summary's "Does not tie" all use the amber tone. Red is kept for failures (ingestion failed, rejected, text failed).
- **Thread continuity (Phase 6a, ruled 2026-09-26).** Every outbound message in the approval flow is sent as one thread:
  - **Messages covered:** the step email, the clarification and the guardrail refusal.
  - **Sender:** each carries the same display name, "Starwood Draw Approvals".
  - **Reply-To:** set to the receiver address, so a mail client's reply lands at the receiver.
  - **Subject:** "Re: <the step email's subject>", so the token stays in it.
  - **Record on the draw:** every inbound and outbound message is mirrored onto the draw (SD Draw Email Message) and rendered in the Approvals tab's Email Exchange, with sender, time, direction, text, the AI reading and source EMAIL.
  - **Measured:** Appian Cloud delivers instance mail from `admin@ny.appiancloud.com` whatever From is configured, so Reply-To is what carries a reply to the receiver.
- Ingestion failure alerts the accountant and asset managers; the alert includes a plain-English failure reason and the AI diff versus the last successfully ingested template.
- Doc Center extraction below confidence threshold routes to accountant reconciliation before data commits. *Ruled 2026-09-22: on this instance the spreadsheet path reports no per-field confidence, so every ingested draw routes to reconciliation; the form says so rather than inventing a score.*
- Reconciliation is a process task assigned to the accountant group, not a related action on the draw. Persona-scoped verification of its submit is therefore a browser check by design (sail cannot open tasks). Ruled 2026-09-22.
- Funding History on a draw lists the investment's prior *approved* draws only. On draw #67 that is #65, #64, #63, which is correct; the Phase 3 brief's expectation of #66/#65/#64 was wrong (#66 is still in approval). Ruled 2026-09-22.
- General Comments is not extracted by Doc Center; the field stays editable on the reconciliation form for the accountant to type into. Re-add it to extraction model 85 only if a template with a filled General Comments cell appears. Ruled 2026-09-22.
- **The draw number is system-assigned. Ruled 2026-09-28 (fix session; supersedes the 2026-09-22 collision ruling below).** A draw's number is the next number in its investment's sequence, like any case number: the highest number on file for the investment plus one. The template's draw number is document content only: it is never extracted into the record, never validated, and never displayed as a control. All sequence and collision logic ("Out of sequence", "Renumbered from", next-number prompts) is removed. The reconciliation form shows the assigned number read-only, with no chips, and the pipeline assigns the same number when the draw is committed. Text in the document that mentions a number, such as the Purpose line "Draw #67 for THSV…", stays as the document wrote it.
- ~~Draw numbers are business data extracted from the template and are never replaced silently; a collision is resolved at reconciliation. When the extracted number already exists for the extracted investment, the reconciliation form prefills the next available number for that investment and shows an amber chip "Renumbered from #<extracted> (on file)" (wording shortened 2026-09-25: a tag displays at most 40 characters; it read "Submitted as #<extracted>, already on file — renumbered to next in sequence"); the accountant can override, and the confirmed value commits. When the extracted number is genuinely next in sequence the chip is green "Next in sequence". Ruled 2026-09-22.~~ **Superseded 2026-09-28** by the system-assigned draw number above.
- An ingested draw's approval chain starts at step 1 (Accountant), copied from the investment's most recent prior draw that has one. The demo accelerator bridges from wherever the chain sits to the CEO step. The narrative's "orders 1–2 pre-completed" applies to the seeded draw 66. Ruled 2026-09-22; revisit only if rehearsal shows drag.
- **Document handling architecture. Ruled 2026-09-25 (Phase 5.6; corrects Phase 5.5).** Doc Center owns identifying and reading documents.
  - **Classification:** a Doc Center classification model types every supporting document.
  - **Extraction:** runs only where an extracted figure drives a control. Today that is the pay application's Current Payment Due, tied against the template.
  - **Invoices and lien waivers** stop at classification: they are typed, filed and presence-checked, and never read.
  - **Generative AI skills** are kept for language tasks: the ingestion-failure comparison, and Phase 6's reply interpretation and narrative drafting.
  - **Superseded:** Phase 5.5's prompt-based typing (one Generative AI skill call per PDF) was interim.
- Over budget requires a reason; contingency utilization requires the explanation narrative (AI-drafted, accountant-approved).
- Asset manager may modify budget lines only at their own approval step; edits are attributed and visible downstream.
- Step emails go to the step group's members as wired (`To:` the step's group). scott.thorn@appian.com receives every step email and plays the CEO at the demo's email beat; no persona addresses, no recipient overrides. Ruled 2026-09-25.
- Budget Summary figures (Land / Soft / Hard / Total) are computed as roll-ups from the budget detail lines, never reproduced from the sample as printed. The sample's summary contains arithmetic inconsistencies (totals shift by $57,753 while its adjustments column shows none); demo data must reconcile. Ruled 2026-09-21.
- ~~Accelerator decision dates spread 1 day per step (`dayOffsetPerStep` = 1), matching the "chain approves over subsequent days" narration. Stage for Approval (2026-09-27) uses the same mechanics for orders 1–2. The funding date must stay after the last generated decision date. Ruled 2026-09-21.~~ **Superseded 2026-09-28** by real decision timestamps (the One-draw demo block).
- New demo runs are created by Phase 3 ingestion of the standard template document, not by any generator or reset mechanism. The seeded draw 66 and the reset script are interim build tooling until ingestion exists. Ruled 2026-09-21. *Confirmed 2026-09-27: new runs come from the staging card's feed packages; draw 66 is list history and the reset script is no longer part of demo prep.*
- The draw approval flow does not touch subscription intake data. No object in this flow reads or writes subscription records, and this build does not modify the intake demo's subscription data. The one intake object the flow relates to is SA Fund, through SD Investment.

## Open questions
- Audience: Starwood direct vs reusable FS asset (sets how literal the Starwood branding stays).
- ~~Outbound email delivery and inbound email receipt on the NY instance: verify capability in Phase 4/6 (renumbered from 3/5 by the 2026-09-21 restructure), not assumed.~~
  - Outbound delivery was resolved in Phase 4 (2026-09-22).
  - Inbound receipt was resolved in Phase 6a (2026-09-26): an email sent from the instance to the receiver process model's address started it (loop-tested).
  - A reply from a real mail client is the remaining browser check.
- ~~Doc Center handling of the Excel template format: confirm in Phase 3 (renumbered from 2); fallback is extraction from a PDF rendition of the template.~~ Resolved 2026-09-22: Doc Center xlsx extraction is proven on this instance (the intake build and Phase 3 both extract the workbook directly); the PDF-rendition fallback is struck.
- Resolved 2026-09-21: draw views join the existing intake site (`SASite`, "Subscription Agreement Analyst", stub `subscription-agreement-analyst`) in a new page group. There is no dedicated site.
- Deferred 2026-09-21: persona accounts. Phase 1 verifies as the designer.
- Resolved 2026-09-21: Blue Granite continuity is narration only. None of Blue Granite's subscriptions is Accepted, and that is left as it is; the narrative's "entered the fund" is spoken, not shown in data. See Business rules: this flow does not touch subscription intake data.

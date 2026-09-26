# TODO — Starwood draw approval

Open items by class. Sessions add discovered items unprompted as they surface, and any response that touched this file ends with a `TODO changes:` line stating what was added, moved, or closed. Every item carries an owner and a firing condition ("trigger: …"); nothing is parked on "later". Superseded items are struck through with a pointer to the standing decision, not deleted; completed items move to Done with the date. The contract is `CLAUDE.md` §8.

## Blocking

## Before demo

- **Accelerator timing (demo-script fact, measured 2026-09-21).** From the presenter clicking the accelerator to the CEO task being live: **87 s** in the exact demo sequence (accelerator fired 7 s after the Asset Manager's approval; 24 s settle, then ≈12 s per step for steps 4–8, then the CEO task). 81 s when the previous task is idle. Narrate it ("the chain approves over the following days") or start it before the beat.
  - *Owner:* the presenter.
  - *Trigger:* the first rehearsal.
- **Demo reset.** Before every run: apply `scripts/seed_draw66.py --reset-csv` through `updateRecordData` (draw, then approvals) and confirm no "Approve or reject draw" task is open. Never edit rows by hand.
  - *Owner:* the presenter or the session.
  - *Trigger:* before every rehearsal and the demo.

- **Demo start (2026-09-22).** After the reset, start `SD Draw Approval Process` on draw 66 and wait ~10 s: the Draws page shows "Awaiting My Action 1" and YOUR ACTION on #66 for `sd.assetmanager` only while that task is live. The task currently live is **536876873** (step process **536909994**, restarted 15:34 UTC after the earlier step process 536909940 was found cancelled — its task 536874206 read Aborted with no assignees). **Do not cancel `SD Draw Approval Step` instances or the `SD Draw Approval Process` run that owns draw 66's live task** when sweeping Process Monitoring; the reset CSV plus a fresh start is the only way to cycle it.
  - *Owner:* the presenter or the session.
  - *Trigger:* before every rehearsal and the demo.
- **Email approval beat (Phase 6a, 2026-09-26).**
  - **How it runs:** the accelerator (or a live approval) brings a draw to step 9. The step process emails `SD Draw CEO` (scott.thorn@appian.com) from "Starwood Draw Approvals", with Reply-To the receiver and the subject ending `[SD-DRAW-<id>-S9]`. Scott replies from that mailbox in his own words, and the draw moves 1–3 min later. Only replies from the authorized address act; every role maps to scott.thorn@appian.com today.
  - **Specimens now on file:**
    - **92 (#77):** Approved by email, treasury notified.
    - **93 (#78):** Rejected by email.
    - **94 (#79):** at the CEO step with its CEO task **22116** live, one clarification sent, and a **Review email reply** task **22161** open for `SD Draw Demo Approvers`.
    - **12 (Gateway #12):** the guardrail refusal.
  - **Before rehearsing the beat on draw 66:** delete draw 66's earlier `SD Draw Email Message` rows by explicit id (`deleteRecordData`; read them with `SD_getDrawEmailMessages`). A leftover INBOUND AMBIGUOUS row makes the next unclear reply skip the clarification and go straight to the exception queue.
  - **Before a rehearsal that clears ingested draws:** pass their message rows as `msgs=` to `--cleanup-ingested`.
  - *Owner:* the presenter or the session.
  - *Trigger:* before every rehearsal of the email beat.
- **Ingestion demo reset — Phase 5.6 additions (read 2026-09-25; extends the Phase 5.5 state below).**
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
- **Ingestion demo reset — state as read 2026-09-25 after Phase 5.5 (supersedes the draw list in the next item).**
  - **Reconciled draws (In Progress):** `SD Draw` rows **74–80** are #67 (74), #67 (75), #71 (76), #68 (77), #69 (78), #70 (79) and #72 (80); steps 1–2, several with open approval tasks. Phase 5.5 added **86 = #73** (the clean package: pay application, invoice, lien waiver; corroboration TIES; documents 6621–6624), **87 = #74** (the mismatch package; ATTENTION; documents 6625–6626) and **88 = #75** (template only; NONE; document 6627), each at step 1 with an Accountant task open — so `sd.accountant`'s Awaiting My Action reads 9.
  - **Ingesting shells:** none. **81, 84 and 85 were deleted 2026-09-25** (rows only, children first, absence confirmed) so the Draws page had one "New draw" for sail to open; their pipeline instances still hold open reconciliation tasks (see "Cancel the stranded build-time process instances").
  - **Failure specimens:** **83** (Phase 5, document 55641, template row 6617) and **89** (Phase 5.5 regression: v2 template plus a pay application and a lien waiver, rows 6628–6630; the supporting documents are read and listed, never corroborated). Keep one.
  - **Before a rehearsal of the package beat:** clear #73–#75 (or keep one as the "already ingested" specimen) with `--cleanup-ingested` — read the children first (lines, approvals, QIU and documents by `drawId`; approvals are 9 rows per draw, lines 16, QIU from the prior draw's set) — then run Receive Capital Call as `sd.accountant` with the template and the package PDFs in the upload slots (one PDF per slot).
  - **Keep one failed draw for the demo beat.** Each new v2 submission adds another "Not loaded" row. Clear extras with `python3 scripts/seed_draw66.py --cleanup-ingested draw=<id> docs=<row>` and `deleteRecordData`, children first (a failed draw has only its template row). Read the row id first.
  - *Owner:* the presenter or the session.
  - *Trigger:* before every rehearsal that shows ingestion or the failure beat.
- **Ingestion demo reset (2026-09-22, updated by the intake fix and Phase 4).** Draw 75 is now at **step 2** (Phase 4 advanced it to send a real step email; step process 536910004, task 536877532, order 1 Approved with the build comment); draw 77 is #68 at step 1; draw 78 is an Ingesting shell. Four ingested rows now exist beside the seed: the reconciled #67s **74** and **75** (below) and the Ingesting shells **76** (document 55289, ingestion process 268476653) and **77** (document 55293) from the intake fix's two persona submits — each shell has a Doc Center instance and a reconciliation task open for `SD Draw Demo Approvers`, so the Draws page shows two "New draw · Ingesting" rows and "AWAITING MY ACTION" counts them once reconciled. Clean the shells with `--cleanup-ingested` (read their child ids first: document rows 6610/6611; no lines, QIU or approvals yet) or reconcile them (they will renumber to #68/#69). Two ingested #67s coexist: `SD Draw` **74** (the session's verified run, In Progress at step 1, step process 38746) and **75** (Scott's persona run the same afternoon, confirmed by Priya Raman, step process 536909980; document 55280, document row 6609, approvals 6619–6627). While both exist the reconciliation form's Draw Number chip on a new #67 reads amber "Submitted as #67, already on file — renumbered to next in sequence" with 68 prefilled (the collision rule, 2026-09-22). Before a rehearsal keep one as the "already-ingested" specimen and clear the other: `listRecordData` the children by `drawId`, then `python3 scripts/seed_draw66.py --cleanup-ingested draw=<74|75> lines=<a-b> approvals=<a-b> qiu=<a-b> docs=<id>` (for 74: `lines=6617-6632 approvals=6610-6618 qiu=6611-6620 docs=6608`) and apply its CSVs with `deleteRecordData` children first. Then run **Receive Capital Call** as `sd.accountant` with `THSV_Draw67_Budget_Template.xlsx`; the Ingesting row appears within ~10 s, the reconciliation task ~80 s after submit.
  - *Owner:* the presenter or the session.
  - *Trigger:* before every rehearsal that shows ingestion.
- **Cancel the stranded build-time process instances** (they hold no data; the rows were deleted): launcher runs 268476637, 38725, 38732 and 536909956 / 268476640 (the two `testProcessModel` launcher runs — **note 2026-09-22: 536909956 is the `SD Draw Approval Process` run that started draw 66's step process 536909940; that step was found cancelled/aborted this afternoon and has been restarted as 536909994, so leave `SD Draw Approval Step` 536909994 and its parent 536909993 alone**), their `SD Receive Capital Call` children (the ones for draws 67–73, including 38740's predecessors), the Doc Center `AIA Extraction Run Model Version` instances for documents 55245/55247/55252 whose Save Extraction child paused on the `[]` bug, and the two orphan approval-process runs 38744/38745 (both completed). Process Monitoring, filter by model name, cancel; do not resume.
  - **Add (2026-09-25, Phase 5.5):** `SD Receive Capital Call` **39011** (draw 85, deleted: the multi-file upload run handed two missing documents; its reconciliation task **16354** is still open for `SD Draw Demo Approvers`) and its `SD Read Supporting Documents` child (id not read; it wrote nothing), plus the pipelines of the deleted shells **81** (task 9464) and **84** (process 536910222, task 536885220). Cancel; do not resume — completing any of those tasks would write to a deleted draw id.
  - **Add (2026-09-25):** `SD Receive Capital Call` instance **38992** — Phase 5's first live failure run, paused (inferred) at node 40 "Ingestion failure alert (email)" when it ran as the persona; its draw 82 and template row 6616 were deleted. Cancel; do not resume (resuming would send a stale alert and rewrite a deleted row).
  - *Owner:* Scott.
  - *Trigger:* before the demo (they show in Process Monitoring only).

## Browser checks owed

*(Owner: a named human. Each item lists the steps, the persona to log in as, and the expected strings — a checklist the human can run, not an open question. Content, state, and behaviour that a session can check through sail as the persona are not browser checks: geometry, document access, and what sail cannot reach are (`CLAUDE.md` §4).)*

- **Geometry of the three built pages against the mockups** (card widths, the four KPI cards in one row on desktop, grid column widths, the navy band, the strip's button alignment). Owner: Scott. Log in as `sd.assetmanager`, compare the Draws page, #66 Summary and the task form with `mockups/draw-list.html`, `draw-summary.html`, `task-approval.html`. Note deltas in `TODO.md`; the mockups are not changed by build sessions.
  - *Trigger:* before the first rehearsal.
- **The rebuilt full-width reconciliation form, as the persona (reconciliation stays a task by design, so its submit is a browser check; the persona submit itself was evidenced on 2026-09-22 by draw 75's "confirmed by Priya Raman").** Owner: Scott.
  1. Reset per "Ingestion demo reset" above, then as `sd.accountant` open `/suite/sites/subscription-agreement-analyst/receive-capital-call`, attach `THSV_Draw67_Budget_Template.xlsx`, click **Receive**. After ~80 s open the new draw's Summary → **Reconcile Extraction**.
  2. Expect the form full width with two side-by-side panes and the navy header "Reconcile extracted draw #67". Left pane, top: the verdict strip "EXTRACTION instance #<n> · 13 header fields · 16 budget lines" with the no-per-field-confidence line and the green **Ties ✓ $2,604,252.23** chip at its right; "DRAW HEADER · EXTRACTED"; the header fields in two columns of normal-width inputs, labels above, no mid-word wrapping (Draw Number / Fund / Funding Date / Cash-Equity / Over Budget Reason on the left; Investment Name / Draw Type / Draw Amount / Budget status / Submitted By on the right); a chip under Draw Number (green **Next in sequence** when the extracted number is next; while other #67s exist, the field is prefilled **68** and the chip is amber **Renumbered from #67 (on file)**; typing 67 back turns it amber **#67 already on file**; wording since the 2026-09-25 chip fix) and under Investment Name (green **Matches investment on file**); no chips anywhere else; Purpose, Budget and Contingency Explanation and General Comments as full-width paragraphs; the 16-row grid with right-aligned numbers and the pinned line "Current Draw total $2,604,252.23 vs draw amount $2,604,252.23 Ties ✓" beneath it.
  3. Right pane: "SOURCE DOCUMENT", the xlsx name as a download link, and the workbook rendered inline (DocCenter's viewer) at TALL height — cells legible, no "cannot be displayed" fallback. If the viewer shows the fallback link instead, note it: it means the persona lacks Viewer on `AIA Reconcile Connected System` (granted to `SD Draw Approvers` on 2026-09-22) or the plug-in refuses xlsx for non-designers.
  4. Edit Hard Costs' Current Draw to 2490296.00 and tab out: the pinned total recomputes to $2,604,252.00 with red "off by ($0.23)"; the verdict strip's chip turns amber **Does not tie** with the amber line "lines $2,604,252.00 vs draw $2,604,252.23 · off by $0.23" beneath it (since the 2026-09-25 chip fix). Restore 2490296.23; both turn green. Type "abc" in Investment Name: the chip turns amber **No matching investment** and the Draw Number chip disappears; restore it.
  5. Click **Confirm & Assemble Draw** (bottom right, the only button). Within ~15 s the draw shows #67 · In Progress · step 1 of 9 · Accountant · Priya Raman; Documents tab "Extracted & Confirmed · Doc Center extraction confirmed by **Priya Raman** MM/DD/YYYY"; Budget Detail 16 lines; QIU "model as of" today; Funding History #67, #65, #64, #63.
  6. Repeat at a laptop width (~1280 px) and a phone width: the panes stay side by side on desktop; the header columns stack on a phone.
  - *Trigger:* before the first rehearsal.
- **The rebuilt intake page in a browser.** Owner: Scott. As `sd.accountant` open `/suite/sites/subscription-agreement-analyst/page/receive-capital-call`: navy header "Receive Capital Call"; the upload card with Receive disabled until a file is attached; attach the xlsx, click **Receive**: expect the card to be replaced by "Capital call received · Doc Center extraction is running on THSV_Draw67_Budget_Template.xlsx · The draw appears in the Draws list immediately…", a navy **Go to Draws** card-button and an outline **Receive Another** button. Click Go to Draws: the Draws page opens in the same tab with a new "New draw · Ingesting" row. Back on the page, Receive Another returns the empty upload form. *Trigger:* before the first rehearsal.
- ~~**Package intake, corroboration section and Documents tab, as the persona (Phase 5.5, reworded for Phase 5.6).**~~ Done 2026-09-25 by Scott: intake, the corroboration states, junk classification, the Documents tab and downloads verified in the browser. The one finding, chip text truncating at 40 characters, is resolved by the 2026-09-25 chip fix (see Done), and its layout has its own check below.
- **Chip layout after the 40-character fix (2026-09-25).** Owner: Scott.
  1. As `sd.accountant`, receive the template plus `THSV_Draw67_PayApp_G702_mismatch.pdf` only. After ~2 min open **Reconcile Extraction**.
  2. **Tie-out cell.** Expect the amber **Does not tie** chip with amber "off by $37,500.00" beside it, in one cell. This is a side-by-side layout inside a read-only grid cell: documented from 26.9; the object validator accepted it and it rendered here, but the browser is the only proof. Check that:
     - the text wraps under or beside the chip rather than being cut off;
     - the chip is not squeezed;
     - the grid still fits the left pane without horizontal scroll.
  3. **Waiver tag.** Below the grid, expect the amber **No lien waiver received**, in full.
  4. **Draw Number.** Expect the amber **Renumbered from #67 (on file)**. Under Investment Name, expect the green **Matches investment on file**, in full.
  5. **Verdict strip.** Edit Hard Costs' Current Draw to 2490296.00 and tab out. The verdict strip should show the amber **Does not tie**, with the amber "lines $2,604,252.00 vs draw $2,604,252.23 · off by $0.23" right-aligned beneath it. Also check:
     - the grid's pay application row now reads **Does not tie** / "off by $37,500.23";
     - the pinned total still reads "off by ($0.23)" in red (see the colour ruling in Deferred).

     Restore the value and **Confirm**.
  6. At a laptop width (~1280 px): no tag shows an ellipsis anywhere on the form.
  - *Trigger:* before the first rehearsal that shows the package beat.
- ~~**Document download as a persona** (S9)~~ — Done 2026-09-25 by Scott: downloads from the Documents tab were verified as `sd.accountant` in the Phase 5.6 browser pass.
- **Live email reply from a real mailbox, and the Email Exchange in the browser (Phase 6a).** Owner: Scott. A loop test cannot be an authorized sender: instance-sent mail always arrives from `admin@ny.appiancloud.com`. The real sender path and the Reply-To routing are therefore proven only by this check.
  1. **In your scott.thorn@appian.com inbox,** open "Draw Funding Approval: Draw #79 · Tamarack Hotel & Spa Vail · $2,604,252.23 · Step 9 of 9 (CEO) [SD-DRAW-94-S9]" (sent 2026-09-26 ~9:59 AM EDT). Note the sender line: display name "Starwood Draw Approvals"; the address is whatever Appian Cloud stamps.
  2. **Click Reply.** The To line must be `processmodeluuid0000f074-9ac4-8000-25d1-7f0000014e7a@ny.appiancloud.com` (the Reply-To). If it is `admin@…` or anything else, stop and record it: Reply-To is not honoured and the flow needs another route.
  3. **Write a clear approval** in your own words, e.g. "Looks good, approved. Please fund on the 16th.", and send.
  4. **After 1–3 min, as `sd.accountant`,** open Draws › #79 › Approvals:
     - **Approval Detail:** the CEO row is **Approved**, "email · scott.thorn@appian.com", and its comment quotes your reply and "read as APPROVE".
     - **Email Exchange:** a new last row "Reply from scott.thorn@appian.com · Inbound · source email · step 9", Outcome **Approved by email**.
     - The draw's status is **Approved**.
     - The session can confirm `treasuryNotifiedAt` is set (the Phase 1 treasury placeholder; what it sends is Phase 6b).
  5. **Optional, to see the thread:** ask the session to accelerate draw 95 (#80) to the CEO step first. Reply "let me think about it". Expect a clarification from "Starwood Draw Approvals" **in the same Gmail thread** within ~2 min, and nothing changed on #80. Then reply "Approved".
  6. **Geometry,** as `sd.accountant`, on #77, #78, #79 and #12 › Approvals › Email Exchange:
     - When is two lines;
     - the Message text wraps in the wide column, with nothing cut;
     - the Reading column's small text wraps;
     - no Outcome tag shows an ellipsis (the longest is "Unclear · clarification sent", 28);
     - no horizontal scroll at ~1280 px.
  7. **Exception task:**
     - As `sd.accountant`, open **Review email reply** (task 22161) from the task list.
     - Expect the navy header "Email reply needs a person", with "Draw #79 · Tamarack Hotel & Spa Vail · Step 9 · CEO" legible on the navy; WHY IT IS HERE "A second reply on this step that is not a clear approval or rejection."; THE REPLY "Can we talk about the contingency on Monday first?".
     - Type a note and click **Mark Reviewed**.
     - #79's Email Exchange gains "Exception reviewed by sd.accountant · Internal · source exception_queue", Outcome **Reviewed**, with your note. The draw is unchanged.
     - This is the first live run of handler node 62.
  - *Trigger:* before the first rehearsal of the email beat.
- **Geometry of the two Phase 3 forms** (start form drop zone; the rebuilt reconciliation form's pane split — the left pane's nine-column DENSE grid must not wrap its numbers at desktop width, and the right pane's viewer should fill the pane height). Owner: Scott. *Trigger:* with the check above.

## Client validation questions

- ~~**Funding History on an ingested draw:** the view lists the last three *approved* draws (65/64/63 for #67); the Phase 3 brief expected 66/65/64.~~ Ruled 2026-09-22: prior approved draws only; 65/64/63 is correct. `PROJECT_INSTRUCTIONS.md` Business rules.
- ~~**General Comments is not extracted from the template.** Does any real template carry General Comments, and should it be re-added with a filled specimen?~~ Ruled 2026-09-22: stays unextracted and editable at reconciliation; re-add only if a filled specimen appears. `PROJECT_INSTRUCTIONS.md` Business rules.

- **The step email's reply copy now departs from the client sample (Phase 6a).** The sample's footer says Reply "Approve" or "Reject", with a red warning. The Phase 6a email instead:
  - invites a reply "in your own words";
  - drops the red warning;
  - shows an amber "email approval is not available" line on a draw over $5,000,000.

  Does the client accept this wording, or want the sample's back with the conversational rule narrated? *Owner:* Scott with the client. *Trigger:* the next client review of the email.

## Deferred

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
- **Tie-out colours now differ by place (2026-09-25).** Three "does not tie" states use different colours:
  - the reconciliation form's verdict chip is **amber**, per the chip-fix brief;
  - the pinned total's "off by" beneath the grid is **red**;
  - the Summary's AMOUNT VERIFICATION "Does not tie" is **red**.

  The last two were not chips in scope. Ruling needed: one colour for an amount that does not tie.
  - *Owner:* Scott.
  - *Trigger:* the chip-layout browser check.
- **5.5-era draws keep 5.5 statuses and summaries.** Draws 86–91 carry supporting-document rows with status Read / Not read and stored summaries that say "invoice ties"; the rules still handle them (Read rows are treated by type), but the wording is 5.5's. Clear them at the next ingestion reset rather than rewrite them. *Owner:* the presenter or the session. *Trigger:* the next ingestion demo reset.
- **Doc Center `generalComments` field** removed from model 85 — re-add only when a template carries a filled General Comments cell (ruled 2026-09-22; `PROJECT_INSTRUCTIONS.md` Business rules). *Trigger:* that template.
- **`SD Draw Approvers` holds Viewer on DocCenter's `AIA Reconcile Connected System`** (granted 2026-09-22 for the reconciliation form's inline xlsx viewer; the `updateObjectSecurity` readback also flipped `inheritSecurity` to `true` with no inherited groups). *Status 2026-09-22:* Scott has messaged DocCenter's owners; no objection has been raised, so this is a note, not an open check. If a reply objects, revert with `updateObjectSecurity` to the original role map (administrator `14a675fc-…`, viewer `AIA All Users` only) and route the accountant to the download link. *Owner:* Scott. *Trigger:* an objection from the DocCenter owners.
- **`SD_getDrawListRows` sort for Ingesting rows:** an ingesting shell sorts first only for its assignees, otherwise last with "New draw". Decide whether Ingesting should always sort first. *Trigger:* the first rehearsal.

- **Draw personas can see the intake pages.** `SD Draw Approvers` is a viewer of the whole `SASite`, so `sd.accountant` / `sd.assetmanager` also see Dashboard, New Subscription and Subscription Records. A visibility expression on those pages (member of `Subscription Agreement Analysts`) would hide them; not done this session because the brief limited security changes to reaching the Draws page.
  - *Owner:* Scott (ruling), then the build session.
  - *Trigger:* the first rehearsal as a persona, or a ruling.
- **Page group "Draws" in the site navigation** — not exposed over the Dev MCP; a Designer step.
  - *Owner:* Scott.
  - *Trigger:* before the demo, if the flat page bar reads wrong.
- **"Save for Later" on the task form** (in `mockups/task-approval.html`) is not built: a task form has no draft save without a process change (a "save draft" path in `SD Draw Approval Step`).
  - *Owner:* the build session.
  - *Trigger:* a ruling that the demo needs it.
- **"Advance draw (demo)" related action** (BUILD_PLAN Phase 2) is still open; the accelerator is started through `testProcessModel` today.
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

- **Correct appian-supplemental §3 on group membership.** It still states that `addGroupMembers`, `getGroup` and `listGroupMembers` return 403. That is the pre-26.6.90 behaviour. Reads work on 26.6.90 and 26.6.95, and **membership writes work on 26.6.95** (three adds measured 2026-09-21); `reference/mcp-capability-boundaries.md` records both.
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
- **Email paths proven by rule tests only (Phase 6a):**
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
- ✅ 2026-09-22 — **Draw-number collision handling at reconciliation** ruled and built: renumber-on-collision with the amber chip, green "Next in sequence" otherwise; both states proven by `testInterface`.
- ✅ 2026-09-22 — **Reconciliation form rebuilt full width** with the inline document viewer, verdict strip, two-column header, pinned recomputing total, two chips, single primary button; `testInterface` clean on instance 849 and on a control (draw 12 → "Next in sequence").
- ✅ 2026-09-22 — **Phase 2b built and persona-verified:** Draws page, four `SD Draw` views, restyled task form, seed texture, monotonic decision dates; `SD Draw Approvers` views `SASite`.

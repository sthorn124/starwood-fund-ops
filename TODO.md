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
- **Ingestion demo reset — state as read 2026-09-25 (supersedes the draw list in the next item).**
  - **Reconciled #67s (In Progress):** `SD Draw` rows **74–80** are #67 (74), #67 (75), #71 (76), #68 (77), #69 (78), #70 (79) and #72 (80); steps 1–2, several with open approval tasks.
  - **Ingesting shells:** **81** (document 55334, reconciliation task 9464) and **84** (the Phase 5 regression run, document 55647, instance 859, reconciliation task 536885220). **Reconciling 84 would renumber it to #73** under the collision rule.
  - **The Phase 5 failure specimen:** **83**, Ingestion Failed, document 55641, template row 6617.
  - **Keep one failed draw for the demo beat.** Each new v2 submission adds another "Not loaded" row. Clear extras with `python3 scripts/seed_draw66.py --cleanup-ingested draw=<id> docs=<row>` and `deleteRecordData`, children first (a failed draw has only its template row). Read the row id first.
  - *Owner:* the presenter or the session.
  - *Trigger:* before every rehearsal that shows ingestion or the failure beat.
- **Ingestion demo reset (2026-09-22, updated by the intake fix and Phase 4).** Draw 75 is now at **step 2** (Phase 4 advanced it to send a real step email; step process 536910004, task 536877532, order 1 Approved with the build comment); draw 77 is #68 at step 1; draw 78 is an Ingesting shell. Four ingested rows now exist beside the seed: the reconciled #67s **74** and **75** (below) and the Ingesting shells **76** (document 55289, ingestion process 268476653) and **77** (document 55293) from the intake fix's two persona submits — each shell has a Doc Center instance and a reconciliation task open for `SD Draw Demo Approvers`, so the Draws page shows two "New draw · Ingesting" rows and "AWAITING MY ACTION" counts them once reconciled. Clean the shells with `--cleanup-ingested` (read their child ids first: document rows 6610/6611; no lines, QIU or approvals yet) or reconcile them (they will renumber to #68/#69). Two ingested #67s coexist: `SD Draw` **74** (the session's verified run, In Progress at step 1, step process 38746) and **75** (Scott's persona run the same afternoon, confirmed by Priya Raman, step process 536909980; document 55280, document row 6609, approvals 6619–6627). While both exist the reconciliation form's Draw Number chip on a new #67 reads amber "Submitted as #67, already on file — renumbered to next in sequence" with 68 prefilled (the collision rule, 2026-09-22). Before a rehearsal keep one as the "already-ingested" specimen and clear the other: `listRecordData` the children by `drawId`, then `python3 scripts/seed_draw66.py --cleanup-ingested draw=<74|75> lines=<a-b> approvals=<a-b> qiu=<a-b> docs=<id>` (for 74: `lines=6617-6632 approvals=6610-6618 qiu=6611-6620 docs=6608`) and apply its CSVs with `deleteRecordData` children first. Then run **Receive Capital Call** as `sd.accountant` with `THSV_Draw67_Budget_Template.xlsx`; the Ingesting row appears within ~10 s, the reconciliation task ~80 s after submit.
  - *Owner:* the presenter or the session.
  - *Trigger:* before every rehearsal that shows ingestion.
- **Cancel the stranded build-time process instances** (they hold no data; the rows were deleted): launcher runs 268476637, 38725, 38732 and 536909956 / 268476640 (the two `testProcessModel` launcher runs — **note 2026-09-22: 536909956 is the `SD Draw Approval Process` run that started draw 66's step process 536909940; that step was found cancelled/aborted this afternoon and has been restarted as 536909994, so leave `SD Draw Approval Step` 536909994 and its parent 536909993 alone**), their `SD Receive Capital Call` children (the ones for draws 67–73, including 38740's predecessors), the Doc Center `AIA Extraction Run Model Version` instances for documents 55245/55247/55252 whose Save Extraction child paused on the `[]` bug, and the two orphan approval-process runs 38744/38745 (both completed). Process Monitoring, filter by model name, cancel; do not resume.
  - **Add (2026-09-25):** `SD Receive Capital Call` instance **38992** — Phase 5's first live failure run, paused (inferred) at node 40 "Ingestion failure alert (email)" when it ran as the persona; its draw 82 and template row 6616 were deleted. Cancel; do not resume (resuming would send a stale alert and rewrite a deleted row).
  - *Owner:* Scott.
  - *Trigger:* before the demo (they show in Process Monitoring only).

## Browser checks owed

*(Owner: a named human. Each item lists the steps, the persona to log in as, and the expected strings — a checklist the human can run, not an open question. Content, state, and behaviour that a session can check through sail as the persona are not browser checks: geometry, document access, and what sail cannot reach are (`CLAUDE.md` §4).)*

- **The Phase 5 ingestion failure alert in Gmail.** Owner: Scott. The live one is draw 83's: "Draw template could not be loaded: Tamarack Hotel & Spa Vail · Draw #67 (as submitted) · THSV_Draw67_Budget_Template_v2.xlsx", sent 2026-09-25 ~16:43 UTC to `SD Draw Demo Approvers` and `SD Draw Asset Managers` (scott.thorn@appian.com, sd.accountant, sd.assetmanager). Ignore the "[build test]" copy of ~16:40 UTC (the control run). Eyeball: (1) navy header "DRAW TEMPLATE NOT LOADED | Tamarack Hotel & Spa Vail" with the facts line and the red **Ingestion Failed** chip; (2) WHAT WENT WRONG in a pink panel with a red left bar and two red bullets; (3) WHAT CHANGED SINCE THE LAST TEMPLATE THAT LOADED — overview, four navy bullets (Current Draw → Draw Funding This Period; Total PTD inc. This Draw (%) missing; Insurance missing; Start-up/Marketing missing), grey italic footer "Compared with … by AI (Claude Sonnet 4.6)…"; (4) THE FILE label/value rows; (5) WHAT HAPPENS NEXT; navy footer "Automated alert from draw approval. Replies to this email are not read."; (6) no clipping (8.7 KB), no stripped styling, curly quotes intact; (7) Gmail mobile readable. Rendered copy: `.work/email/draw83_ingestion_failure.html`. Note deltas here. *Trigger:* before the first rehearsal.
- **Geometry of the failed-draw Summary card** (draw 83, as `sd.accountant`): the red card in the action strip's slot, the three small-caps headings, bulleted lists indented and wrapped cleanly, the Receive Capital Call link inline; the page below shows only Draw Origin. Owner: Scott. *Trigger:* with the geometry check below.
- **Geometry of the three built pages against the mockups** (card widths, the four KPI cards in one row on desktop, grid column widths, the navy band, the strip's button alignment). Owner: Scott. Log in as `sd.assetmanager`, compare the Draws page, #66 Summary and the task form with `mockups/draw-list.html`, `draw-summary.html`, `task-approval.html`. Note deltas in `TODO.md`; the mockups are not changed by build sessions.
  - *Trigger:* before the first rehearsal.
- **The rebuilt full-width reconciliation form, as the persona (reconciliation stays a task by design, so its submit is a browser check; the persona submit itself was evidenced on 2026-09-22 by draw 75's "confirmed by Priya Raman").** Owner: Scott.
  1. Reset per "Ingestion demo reset" above, then as `sd.accountant` open `/suite/sites/subscription-agreement-analyst/receive-capital-call`, attach `THSV_Draw67_Budget_Template.xlsx`, click **Receive**. After ~80 s open the new draw's Summary → **Reconcile Extraction**.
  2. Expect the form full width with two side-by-side panes and the navy header "Reconcile extracted draw #67". Left pane, top: the verdict strip "EXTRACTION instance #<n> · 13 header fields · 16 budget lines" with the no-per-field-confidence line and the green **Ties ✓ $2,604,252.23** chip at its right; "DRAW HEADER · EXTRACTED"; the header fields in two columns of normal-width inputs, labels above, no mid-word wrapping (Draw Number / Fund / Funding Date / Cash-Equity / Over Budget Reason on the left; Investment Name / Draw Type / Draw Amount / Budget status / Submitted By on the right); a chip under Draw Number (green **Next in sequence** when the extracted number is next; while other #67s exist, the field is prefilled **68** and the chip is amber **Submitted as #67, already on file — renumbered to next in sequence**; typing 67 back turns it amber **#67 is already on file for this investment**) and under Investment Name (green **Matches Tamarack Hotel & Spa Vail on file**); no chips anywhere else; Purpose, Budget and Contingency Explanation and General Comments as full-width paragraphs; the 16-row grid with right-aligned numbers and the pinned line "Current Draw total $2,604,252.23 vs draw amount $2,604,252.23 Ties ✓" beneath it.
  3. Right pane: "SOURCE DOCUMENT", the xlsx name as a download link, and the workbook rendered inline (DocCenter's viewer) at TALL height — cells legible, no "cannot be displayed" fallback. If the viewer shows the fallback link instead, note it: it means the persona lacks Viewer on `AIA Reconcile Connected System` (granted to `SD Draw Approvers` on 2026-09-22) or the plug-in refuses xlsx for non-designers.
  4. Edit Hard Costs' Current Draw to 2490296.00 and tab out: the pinned total recomputes to $2,604,252.00 and both tie-out chips turn red ("Does not tie" / "off by ($0.23)"). Restore 2490296.23; both turn green. Type "abc" in Investment Name: the chip turns amber **No matching investment** and the Draw Number chip disappears; restore it.
  5. Click **Confirm & Assemble Draw** (bottom right, the only button). Within ~15 s the draw shows #67 · In Progress · step 1 of 9 · Accountant · Priya Raman; Documents tab "Extracted & Confirmed · Doc Center extraction confirmed by **Priya Raman** MM/DD/YYYY"; Budget Detail 16 lines; QIU "model as of" today; Funding History #67, #65, #64, #63.
  6. Repeat at a laptop width (~1280 px) and a phone width: the panes stay side by side on desktop; the header columns stack on a phone.
  - *Trigger:* before the first rehearsal.
- **The rebuilt intake page in a browser.** Owner: Scott. As `sd.accountant` open `/suite/sites/subscription-agreement-analyst/page/receive-capital-call`: navy header "Receive Capital Call"; the upload card with Receive disabled until a file is attached; attach the xlsx, click **Receive**: expect the card to be replaced by "Capital call received · Doc Center extraction is running on THSV_Draw67_Budget_Template.xlsx · The draw appears in the Draws list immediately…", a navy **Go to Draws** card-button and an outline **Receive Another** button. Click Go to Draws: the Draws page opens in the same tab with a new "New draw · Ingesting" row. Back on the page, Receive Another returns the empty upload form. *Trigger:* before the first rehearsal.
- **Document download as a persona** (S9): on #67's Documents tab as `sd.accountant`, click `THSV_Draw67_Budget_Template.xlsx`; expect the 7,650-byte workbook. Owner: Scott. *Trigger:* with the check above.
- **Geometry of the two Phase 3 forms** (start form drop zone; the rebuilt reconciliation form's pane split — the left pane's nine-column DENSE grid must not wrap its numbers at desktop width, and the right pane's viewer should fill the pane height). Owner: Scott. *Trigger:* with the check above.

## Client validation questions

- ~~**Funding History on an ingested draw:** the view lists the last three *approved* draws (65/64/63 for #67); the Phase 3 brief expected 66/65/64.~~ Ruled 2026-09-22: prior approved draws only; 65/64/63 is correct. `PROJECT_INSTRUCTIONS.md` Business rules.
- ~~**General Comments is not extracted from the template.** Does any real template carry General Comments, and should it be re-added with a filled specimen?~~ Ruled 2026-09-22: stays unextracted and editable at reconciliation; re-add only if a filled specimen appears. `PROJECT_INSTRUCTIONS.md` Business rules.

## Deferred

- **The comparison with no earlier template** (the standard-template baseline in `SD_buildTemplateComparisonRequest`) and **with no layout difference** (the AI call skipped, rules text) are proven only by rule tests and the gauntlet, not by a live run. *Owner:* the build session. *Trigger:* the first malformed template for an investment with no loaded template, or a failure caused only by blank header values.
- **The overview's standard-wording fallback rate.** In 5 probe calls after the prompt was tightened, 3 overviews passed and 2 fell back. In both live runs the overview passed. If a rehearsal shows the standard wording often, revisit the prompt (not the gate). *Owner:* the build session. *Trigger:* the first rehearsal that shows "(summary in standard wording)".
- **Dependencies to re-verify on another instance:** the Excel Tools plug-in (`readexcelsheet`), DocCenter's Text Input AI skill (id 148, used with a Runtime Prompt) and the model id in `SD_TEMPLATE_COMPARISON_MODEL`. *Owner:* the build session. *Trigger:* any move of the app to another instance.
- **Dev MCP 26.6.100 is available on the App Market** (the site runs 26.6.95). The site admin updates the plugin first; then run `maintenance/dev-mcp-update.md`. *Owner:* Scott. *Trigger:* before the next build session, or when the operator chooses.
- **Second ingestion run with an edited value** (brief item 5, "if time"): folded into the browser check above, step 5. *Trigger:* that check.
- **Backup documents on an ingested draw** (contractor / A&E invoices) — the pipeline attaches only the template. *Trigger:* Phase 5/6 scoping.
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

## Done

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

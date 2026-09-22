# BUILD PLAN — Starwood draw approval

This file is the build's high-level checklist and its state of record for what is done and what remains. At close-out, `- [ ]` becomes `- ✅ <date>`, and newly discovered work is added to the right phase (`CLAUDE.md` §10).
- **Not the specification.** Detailed build specs live in the build prompts under `prompts/`.
- **Mockups** are the contract for interfaces.
- **Actual environment state** is `BUILD_LOG.md`.
- **Source of this plan:** Phase 0 in the claude.ai Project, transcribed into `PROJECT_INSTRUCTIONS.md` on 2026-09-21. That file holds the canonical narrative, personas, data model, vocabulary canon, business rules and open questions. The sections below point to it rather than restating it; where they summarise it, `PROJECT_INSTRUCTIONS.md` wins.

**Host:** `Starwood Demo` (`dd3bb740-b105-421b-a866-29d542a144da`) on `ny.appiancloud.com`, prefix `SD`. `Capital Calls & Distributions` is out of scope and is not read or referenced.

## Demo Narrative

Industry: real estate private equity, fund operations. Use case: **draw approval**, the funding of capital call draws for renovation and development projects at properties the fund holds. It continues the subscription-intake story on the same platform: Blue Granite's capital entered Harborline Real Assets Fund II through intake, and this flow deploys it.

Beat by beat, in `PROJECT_INSTRUCTIONS.md` § Demo narrative:
1. Draw #66 arrives.
2. Ingestion fails, and an AI diff explains why.
3. The corrected template ingests through Doc Center.
4. QIU data is aggregated to the draw.
5. The Asset Manager edits and approves in the UI.
6. The CEO approves by a conversational email reply.
7. Treasury is notified.

Only two approvers act live: the Asset Manager in the UI and the CEO by email. A demo accelerator advances the steps between them.

## Personas and What Each Sees

The canonical list is in `PROJECT_INSTRUCTIONS.md` § Personas.

| Persona | Surface | Sees and does | Does not |
|---|---|---|---|
| Fund Accountant | UI and email | Failure alerts with the AI diff; Doc Center extraction review and confirmation; approval of the contingency narrative (stretch). The same person as the chain's Accountant role (order 1), whose approval step is data only. | Approve on behalf of chain roles, or act on the order 1 step live |
| Asset Manager | UI and email | The draw at their step; edits budget lines at that step only; approves; receives ingestion failure alerts | Edit budget lines outside their own step |
| CEO (order 9) | Email only | The new-format approval email; replies conversationally | Open the UI |
| Remaining chain roles | Data only | Rows in the approval status table, including Executive (order 5), a separate role from the CEO | Appear live |

**Accounts for sail verification.** These need local-password accounts, because SSO-only identities cannot log in through sail (`reference/patterns.md` §12):
- one for the Fund Accountant;
- one for the Asset Manager.

The CEO is verified by email, not sail. Creating the accounts, and the sail logins, are operator steps (`GETTING_STARTED.md` §1) and are tracked in `TODO.md`.

## Data Model (entity level)

The canonical definition is in `PROJECT_INSTRUCTIONS.md` § Data model. Field vocabulary follows the new approval email sample exactly.

| Entity | Kind | Joins |
|---|---|---|
| SD Investment | Reference (seeded) | Many-to-one to `SA Fund` (existing; id 4 is "Harborline Real Assets Fund II, L.P."). Holds name and description (the email's "Investment Name" and "Investment Description [from DealCloud]"). DealCloud is narrated, not integrated. |
| SD Draw | Transactional (demo-created per run, plus seeded draw #66) | Many-to-one to SD Investment, and through it to `SA Fund` |
| SD Draw Budget Line | Transactional | Many-to-one to SD Draw |
| SD Draw Approval | Transactional, drives routing | Many-to-one to SD Draw; nine rows per draw, contiguous orders 1–9 |
| SD QIU Metric | Reference per draw (seeded) | Many-to-one to SD Draw; ten rows per draw, the ten metrics in canon order |
| SD Draw Document | Transactional | Many-to-one to SD Draw; holds Appian document references |

## Build Phases

### Phase 0 — Plan

- ✅ 2026-09-21 Build repo instantiated; baseline inventory of `Starwood Demo` captured (`BASELINE_INVENTORY.md`)
- ✅ 2026-09-21 Rulings: service accounts in `SD Administrators` kept as an exception; `Starwood Demo` confirmed as the host application
- ✅ 2026-09-21 Dev MCP updated to 26.6.95 and re-verified
- ✅ 2026-09-21 Narrative, personas, entity model, vocabulary canon, business rules and open questions transcribed into `PROJECT_INSTRUCTIONS.md`
- ✅ 2026-09-21 This build plan authored
- ✅ 2026-09-21 Discrepancies found while transcribing, all seven ruled: Accounting Controller mapping, CEO as the email approver, Fund Accountant as order 1, ten QIU metrics, nine contiguous orders, SD Investment, and Blue Granite as narration only. The rulings are applied in `PROJECT_INSTRUCTIONS.md`.

### Phase 1 — Foundation: data model, seed, sequential approval process  ← CORE COMPLETE 2026-09-21

**Restructured 2026-09-21 (ruling).** Interfaces moved out of Phase 1 into Phase 2, which works mockup-first. This phase builds no custom record views or pages. The only interface it may need is the minimal functional task form a user input task requires; that form is recorded as a Phase 2 restyle target.

**Objects to create.** All are added to `Starwood Demo`, and all names use the `SD` prefix.

- **Existing objects referenced, not created:**
  - `SA Fund` (id 4, "Harborline Real Assets Fund II, L.P.") is the fund.
  - `BASELINE_INVENTORY.md` shows no investment or property record type, so `SD Investment` is created.
  - The legacy `SD Fund` scaffold is not used.
- **Record types.** Six, created with `length` set at create time, because altering a width later does nothing (supplemental §7):
  - ✅ 2026-09-21 `SD Investment`: name and description; related to `SA Fund`.
  - ✅ 2026-09-21 `SD Draw`: header facts per the data model, plus `status` and `currentStep`; related to SD Investment.
  - ✅ 2026-09-21 `SD Draw Budget Line`: `categoryGroup` limited to Land / Soft / Hard, and an `inThisDraw` flag. Category names come from the new email sample.
  - ✅ 2026-09-21 `SD Draw Approval`: order, role, approver, status (Pending / In Progress / Approved / Rejected), decision date, comments.
  - ✅ 2026-09-21 `SD QIU Metric`: the ten metrics in canon order, with model as-of date, current model value, current projection, variance and notes. Values are stored as formatted text, so currency, percent and multiples are carried uniformly.
  - ✅ 2026-09-21 `SD Draw Document`.
- **Relationships and security.**
  - ✅ 2026-09-21 SD Draw to each child (one-to-many), SD Draw to SD Investment (many-to-one), and SD Investment to `SA Fund` (many-to-one).
  - ✅ 2026-09-21 Every relationship read back after it is written.
  - [ ] Record-level security: deferred with the persona accounts (ruling 2026-09-21). Trigger: the persona accounts exist.
  - [ ] **Interim tooling notice (ruled 2026-09-21):** the seeded draw 66 and `scripts/seed_draw66.py` are build tooling until Phase 3 ingestion creates demo runs from the standard template document; no generator or reset mechanism becomes a demo feature.
- **Groups.**
  - ✅ 2026-09-21 `SD Draw Approvers` as the parent.
  - ✅ 2026-09-21 Role subgroups for the Asset Manager and the CEO only.
  - ✅ 2026-09-21 `SD Draw Demo Approvers` as the catch-all for unrepresented roles.
  - ✅ 2026-09-21 The designer added to the groups this session's verification needs.
- **Seed data.** A deterministic script with explicit ids and no `now()`, `today()` or `rand()`. Keys come from the source; no `max()+1` (`CLAUDE.md` §12).
  - ✅ 2026-09-21 One SD Investment row: a fictional hotel property on Harborline Fund II (`SA Fund` id 4), narrated as coming from DealCloud.
  - ✅ 2026-09-21 Draw #66: PIP/Renovation, $2,604,252.23, On Budget, a near-future funding date, on that investment.
  - ✅ 2026-09-21 Its budget lines and its ten QIU metric rows, from the new approval email sample.
  - ✅ 2026-09-21 Its approval chain: nine rows, contiguous orders 1–9, with fictional approver names. Orders 1–2 are Approved with recent decision dates, order 3 (Asset Manager) is In Progress, and orders 4–9 are Pending.
- **Processes:**
  - ✅ 2026-09-21 **`SD Apply Draw Approval Decision`** (unattended): the single state transition.
    - It takes the draw id, the step order, the decision, a comment, the actor and the source (task, accelerator, or email later).
    - It guards against stale decisions and writes the step's approval row.
    - On Approve, it moves the next order to In Progress and updates `currentStep`.
    - On Reject, it sets the draw to Rejected.
    - On final approval (order 9), it sets the draw to Approved and sends the treasury notification placeholder, gated on the final-approval write succeeding.
    - Every business write is its own Write Records node with `ErrorOccurred` wired.
  - ✅ 2026-09-21 **`SD Draw Approval Process`** walks the approval rows in contiguous order.
    - Each step is a user input task (approve or reject, with a comment) assigned to the role's group, or to the catch-all group where the role has none.
    - Every decision goes through `SD Apply Draw Approval Decision`.
    - Each step transition sends a plain-text placeholder notification; the real layout is Phase 4.
  - ✅ 2026-09-21 **Demo accelerator:** advances every step between the current one and order 9 as Approved, with generated decision dates, in one action.
    - ✅ 2026-09-21 Decision dates spread 1 day per step (`dayOffsetPerStep` default 1); measured 09-23 → 09-27 against a 10-15 funding date.
    - ✅ 2026-09-21 Settle phase added: the accelerator waits for a consistent, stable draw state before its first decision (race test passed; 87 s to the CEO task).
  - ✅ 2026-09-21 **Measure `createProcessModel(errorAlertGroupUuid)` persistence:** measured as unmeasurable over MCP (`getProcessModel` exposes no alert-group field); a Designer check is owed in `TODO.md`.

**Dependencies:**
- Phase 0 is complete.
- The spec PDFs are read at high resolution for the budget categories and values.

**Verification, stated before the run (as the designer):**
- **Record types.** Each type and field read back.
- **Seed.** Row counts per type equal the expected counts: 1 investment, 1 draw, 10 QIU metrics, and 9 approvals with orders 1–9 and no gap. Budget-line totals match the email sample.
- **End to end, at the process and task level:**
  1. Start the process on draw #66; it sits at order 3.
  2. Complete the Asset Manager task as Approve.
  3. Run the accelerator; the draw sits at order 9.
  4. Complete the CEO task as Approve.
  5. The draw is Approved, and the treasury placeholder fires.
- **Break-test.** A Reject on a fresh run sets the draw to Rejected and ends it.

**Built beyond the list:** `SD Draw Approval Step` (the step task process), `SD_form_drawApprovalDecision` (minimal task form, Phase 2 restyle target), `SD_getDrawState` and `SD_getDrawApprovalGroup`, five constants, `SD Draw.treasuryNotifiedAt`, and `scripts/seed_draw66.py` with its `--reset-csv` demo reset.

**Verified 2026-09-21, as the designer** (`BUILD_LOG.md`): every pass condition above held, including the reject break-test. **Phase 2a (same day):** email delivery confirmed by Scott; widths proven through the production path (4,000 and 1,000); the race test passed after the settle fix. Not verified: persona behaviour.

**Demo-visible outcome.** No UI this phase. Draw #66 exists with its full data, and the approval chain runs from the Asset Manager through the accelerator to the CEO and on to Approved.

### Phase 2 — UI foundation (mockup-first)

**Ruled 2026-09-21.**
- Draw views join the existing intake site, `SASite` ("Subscription Agreement Analyst", stub `subscription-agreement-analyst`), in a new page group. There is no dedicated site.
- Persona accounts are deferred; Phase 1 verifies as the designer.

**Objects:**
- ✅ 2026-09-22 **HTML mockups** for the draw list, the draw summary views and the task form, delivered into `mockups/` **from the claude.ai Project** (ruled 2026-09-21: build sessions treat them as the UI contract and never author or modify them), committed at `0bf29c2` before any SAIL was written.
- ✅ 2026-09-22 **Draws page** (`SD_page_draws` on `SASite`, stub `draws`), built against `mockups/draw-list.html`: four computed KPI cards, filters and search, the viewer-aware grid (YOUR ACTION, highlight, awaiting-first sort). The record list itself is not used; rows open the record through links.
- ✅ 2026-09-22 **`SD Draw` record views**, four tabs against `mockups/draw-summary.html`: Summary (action strip, progress, Draw Origin with tie-out, Draw Funding Detail, Budget Summary roll-up + Remaining Contingency, Funding History, QIU Detail), Budget Detail, Approvals, Documents. Record title expression set. All figures computed from the rows.
- [ ] **Related actions:**
  - ~~"Record decision", visible only to the current step's role~~ — superseded 2026-09-22 by the Summary's action strip, which links the current step's assignee group straight to the open task (`SD_getOpenTaskId`);
  - "Advance draw (demo)", visible to administrators only — still open; the accelerator is started through `testProcessModel` today.
- ✅ 2026-09-22 **Task form restyled** (`SD_form_drawApprovalDecision`) against `mockups/task-approval.html`; the step task node now passes `drawId` and `stepOrder`. "Save for Later" is not built (no draft save on a task form without a process change).
- ✅ 2026-09-22 **Draws page added to `SASite`** (`updateSite`, existing pages passed by uuid; their stubs `2rcKrQ` / `VRvmbQ` / `tO9EuA` were preserved, so the earlier "regenerates every stub" warning did not apply to this form of the call). `SD Draw Approvers` added as a site viewer.
  - [ ] **Page group** ("Draws" grouping in the site navigation) — a Designer step; not exposed over the Dev MCP. *Owner: Scott. Trigger: before the demo, if the flat page bar reads wrong.*
- ✅ 2026-09-22 **Persona site stub build parameter** set to `subscription-agreement-analyst` (page `draws`); both persona sessions load it through sail.

**Also done 2026-09-22 (Phase 2b):** seed texture for the list (investment 2, draws 63/64/65/11/12, 54 approval rows, QIU as-of, received/submitted-by, three document rows); monotonic decision dates in the transition (`max(now, previous decision + 1 day)`), verified end to end with nine ascending dates before the funding date; persona-verified through sail as `sd.assetmanager` and `sd.accountant` (`BUILD_LOG.md`).
- [ ] **Persona task open from the strip and the restyled form's submit** — browser check (`TODO.md`): sail cannot follow a task link. *Owner: Scott. Trigger: before the first rehearsal.*
- [ ] **Intake pages visible to draw personas** — `SD Draw Approvers` now views the whole site; decide whether the intake pages get a visibility expression. *Owner: Scott. Trigger: the first rehearsal as a persona.*

**Dependencies:** Phase 1; mockup approval.

**Verification:**
- `testInterface` returns `diagnostics.error: null`, and hidden branches are revealed once each.
- Persona checks through sail once the persona accounts exist; until then, as the designer, with scope stated.
- The intake site's existing pages still resolve after `updateSite`.
- **Browser only:** geometry.

**Demo-visible outcome:** draw #66 opens as a record on the intake site, showing its header, budget, QIU table and a live approval status table.

### Phase 3 — Doc Center ingestion, success path  ← CORE COMPLETE 2026-09-22

**Objects:**
- ✅ 2026-09-22 **Working example first.** Copied the intake app's `SD Process Batch Roster (MCP)` mechanism (subprocess `AIA Extraction Run Model Version`, `modelKey`) and DocCenter's own create process (models are rows in the AIA tables).
- ✅ 2026-09-22 **Excel template handling.** Doc Center extracts the xlsx directly (Generative AI spreadsheet path, model `drawBudgetTemplate` 85/142); 12 header fields and all 16 lines correct on the first run. No PDF rendition needed. The template is uploaded through the start form by a persona (binary uploads over MCP corrupt, so the form is the only route).
- ✅ 2026-09-22 **Ingestion process** — built as `SD Receive Capital Call` (+ the frozen start-form launcher `SD Receive Capital Call (Intake Form)`): shell → document row → extraction → reconciliation task → header + lines commit → template Extracted & Confirmed → QIU + chain assembly → In Progress at step 1 → `SD Draw Approval Process`. Every extraction routes to reconciliation (Doc Center gives no confidence on the spreadsheet path, so there is no threshold to branch on); nothing commits before confirmation.
- ✅ 2026-09-22 **Accountant reconciliation form** `SD_form_reconcileExtraction`: a user input task for `SD Draw Demo Approvers`, editable header and 16-line grid, document link, tie-out chip, "no per-field confidence" notice; confirm-to-commit.
- ✅ 2026-09-22 **Manual trigger**: `SASite` action page **Receive Capital Call** (narrated as the EY API/SFTP feed).
- ✅ 2026-09-22 **`SD Draw Document` row** for the template (Received → Extracted & Confirmed, real download link). Backup documents remain a later item.
- ✅ 2026-09-22 **Post-confirm assembly** (brief item 4): QIU rows copied from the investment's latest prior draw and re-dated; nine-row chain copied with names; approval process started at step 1. `scripts/seed_draw66.py --cleanup-ingested` added.
- ✅ 2026-09-22 **Persona submit of the reconciliation task** — ruled a browser check by design (reconciliation stays a task, not a related action; sail cannot open tasks). Evidence on the instance the same day: a second intake run as `sd.accountant` produced draw 75 (#67) whose document row reads "Doc Center extraction confirmed by Priya Raman 09/22/2026". The rebuilt full-width form (see below) still owes one browser pass for geometry and the inline viewer.
- [ ] **Second run with one edited value** (brief's "if time") — not run. *Trigger: the persona browser check above; edit Draw Amount and confirm the committed value.*
- [ ] **Backup documents** attached to an ingested draw. *Trigger: Phase 5/6 scoping.*
- [ ] **Cancel the stranded build-time process instances** in Process Monitoring (see `TODO.md`). *Owner: Scott. Trigger: before the demo.*
- ✅ 2026-09-22 **Funding History semantics for an ingested draw:** ruled — prior *approved* draws only (65/64/63 for #67 is correct; the brief's 66/65/64 was wrong). Recorded in `PROJECT_INSTRUCTIONS.md` Business rules.
- ✅ 2026-09-22 **General Comments stays unextracted;** the field remains editable at reconciliation; re-add to model 85 only if a filled specimen appears. Ruled; `PROJECT_INSTRUCTIONS.md` Business rules.
- ✅ 2026-09-22 **Ingested chain starts at step 1 (Accountant);** the accelerator bridges to the CEO step; the narrative's "orders 1–2 pre-completed" applies to seeded draw 66. Ruled; revisit only if rehearsal shows drag.
- ✅ 2026-09-22 **Reconciliation form rebuilt full width** (fix session): one `a!paneLayout` in the form — left pane verdict strip, two-column header, full-width paragraphs, editable grid with the tie-out total pinned beneath; right pane the workbook inline through DocCenter's viewer (`rule!AIA_UTIL_displayInlineDocument`; `SD Draw Approvers` granted Viewer on `AIA Reconcile Connected System`) under a download link; chips on Investment Name and Draw Number only; single primary **Confirm & Assemble Draw**. `testInterface` clean on the live payload; geometry and the viewer as a persona are Scott's browser check.
- ✅ 2026-09-22 **Intake confirmation (fix session):** the Receive Capital Call page is a regular interface (`SD_page_receiveCapitalCall`) — Receive commits the upload and starts the pipeline through `a!startProcess`, then flips to the confirmation state with Go to Draws and Receive Another. The frozen launcher and its start form are deleted (absence confirmed). Verified via sail as `sd.accountant`: confirmation state rendered, Receive Another reset the form, two new Ingesting shells (draws 76, 77) on the Draws list.
- ✅ 2026-09-22 **Draw-number collision handling at reconciliation** (ruled; `PROJECT_INSTRUCTIONS.md` Business rules): collision → prefilled next available + amber "Submitted as #<n>, already on file — renumbered to next in sequence"; clean → green "Next in sequence". Both states proven by `testInterface` (draw 74 with duplicate #67s on file → 68 renumbered; Gateway draw 12 → next in sequence).
- [ ] **Browser pass on the rebuilt reconciliation form** — panes at common widths, the inline xlsx as `sd.accountant`, chips (including the amber renumbered chip while duplicate #67s exist), pinned total recomputing on edit, the override surviving edits to other fields. *Owner: Scott. Trigger: before the first rehearsal.*
- ✅ 2026-09-22 **Draw 66's approver action restored (fix session):** root cause was a cancelled step process (task Aborted, no assignees), not the lookup; flow restarted at step 3 (step process 536909994, task 536876873), rows untouched, persona-verified. Hardening of `SD_getOpenTaskId` against dead tasks is parked in `TODO.md`.
- [ ] **Browser pass on the intake page** — the confirmation card, the Go to Draws card-link landing on the Draws page in the same tab, the error line (never seen: force it by removing Initiator from a test account, or accept as untested). *Owner: Scott. Trigger: with the check above.*
- [ ] **Clean up the extra ingested rows before a demo:** reconciled #67s 74 and 75, and the Ingesting shells 76 and 77 (each with an open reconciliation task and a Doc Center instance) from the intake fix's two persona submits. Keep one as the "already-ingested" specimen; `--cleanup-ingested` for the rest. With the collision rule the chips now read correctly whatever coexists, so this is tidiness, not correctness. *Owner: Scott. Trigger: the ingestion demo reset.*

**Dependencies:** Phase 1 record types; Phase 2 views; the Doc Center capability on the instance; a clean template specimen.

**Verification (2026-09-22):**
- **Specimens held constant:** the clean template `THSV_Draw67_Budget_Template.xlsx` (md5 f4f99f07…); the malformed `_v2` is reserved for Phase 5.
- **Pass conditions met:** 16 lines, current-draw lines sum $2,604,252.23 = header amount (Ties ✓); header facts equal the template's; QIU 10 rows as of 09/22/2026; chain at step 1 with a live task (step process 38746); template Extracted & Confirmed; Draws page as `sd.assetmanager` shows #67 without YOUR ACTION and #66 with; as `sd.accountant` #67 carries YOUR ACTION at step 1.
- **Break-test (low-confidence routing):** not applicable as designed — every extraction routes to reconciliation; the Phase 5 malformed template is the failure specimen.
- **Accountant path:** upload and submit driven through sail as `sd.accountant`; the task itself is browser-only (see above).

**Demo-visible outcome:** the template goes in; the accountant reconciles; draw #67 appears with lines, QIU, chain and document.

### Phase 4 — New approval email layout  ← CORE COMPLETE 2026-09-22

**Objects:**
- ✅ 2026-09-22 **Capability check:** outbound email from the NY instance was confirmed in Phase 2a (treasury and step emails received); Phase 4 sends through the same node.
- ✅ 2026-09-22 **`SD_buildApprovalEmail(drawId, stepOrder)`** (built as this name, not `SD_draw_approvalEmailBody`): subject + HTML body from the draw's records at send time, section by section against `New approval email sample blacklined.pdf` — navy header band with the header facts; greeting and the reply instruction; Draw Funding Detail; Draw Detail by Budget Category (In this Draw, All Other Budget Categories, BUDGET total); Budget Summary **rolled up from the lines** (ruled); Remaining Contingency; QIU Detail; Approval Status with contiguous orders 1–9 and the current step marked; reply footer. Helpers `SD_htmlEscape`, `SD_fmtMoneyDash`, `SD_emailCells`, `SD_emailRow`. Generator `.work/sail/gen_email.py`.
- ✅ 2026-09-22 **Data handling:** every record text HTML-escaped; money through `SD_fmtMoney` (cents on the header amount only), dashes for null/zero, PTD as `0.0%`; correct with no lines / no QIU / no contingency line (draw 12 render).
- ✅ 2026-09-22 **Send node:** `SD Draw Approval Step` node 8 "Step notification (approval email)" now sends `pv!email.subject` / `pv!email.html` (computed once in node 4 into the new Map PV `email`); recipients unchanged (`To: pv!assignGroup`, the step's group). The treasury notification stays a placeholder (Phase 6).
- [ ] **Gmail check** of the live email (draw 75 / step 2, sent to `SD Draw Demo Approvers` = scott.thorn@appian.com + sd.accountant): section order, table rendering, the marked current row, QIU values, no clipping (44.9 KB body). *Owner: Scott. Trigger: before the first rehearsal.*
- [ ] **Gmail routing for the demo** — the step emails go to the step group's members' addresses (see the closeout's routing table); decide the demo inbox and set the persona addresses / a recipient override. *Owner: Scott (ruling), then the build session. Trigger: Phase 6 planning.*

**Dependencies:** Phase 1 data; Phase 2 views. The spec PDF read at full resolution (2026-09-22).

**Verification (2026-09-22):**
- The body rule evaluated against draw 66 / step 3 (every header fact, all 16 lines, the roll-ups, the contingency line, the ten QIU rows, nine approval rows with #3 marked) and against draw 12 / step 6 (no lines: the empty-state rows); section headings present in the sample's order; no `<style>`, `<img>`, `href` or `class`.
- Live send: draw 75 advanced from step 1 to step 2 through the transition; the step-2 process (536910004) registered itself and issued task 536877532 to `SD Draw Demo Approvers`; the body node 4 evaluated is saved as `.work/email/draw75_step2.html`.
- **Mailbox only:** the rendered look in Gmail (checklist in `TODO.md`).

**Demo-visible outcome:** each approver's inbox shows the new-format email with the full budget tables; the CEO's is the one the demo reads.

### Phase 5 — Ingestion failure path

**Objects:**
- [ ] **Template validation** in `SD Ingest Draw Template`, which classifies the failure: file unreadable, structure changed, or values missing.
- [ ] **Last-good baseline:** the last successfully ingested template kept as the comparison source.
- [ ] **AI diff:** a model call comparing the failed template with the last good one, producing a plain-English explanation.
  - It runs in the process or in an interface, never in an expression rule, because model calls cannot live there (supplemental §3).
  - A deterministic validation gate sits on its output before the alert uses it (`examples/deterministic-validation-gauntlet.md`).
- [ ] **Alert email** to the accountant and the asset managers: the failure reason plus the AI diff.

**Dependencies:** Phases 3 and 4; a malformed-template specimen.

**Verification:**
- **Specimens held constant:** a malformed template and a clean template.
- **Pass conditions:**
  - The malformed template produces the alert, and no budget lines are written. This is the break-test.
  - The diff names the real structural difference.
  - The clean template produces no alert.
- **Live run:** the AI output is judged on a live run, not a fixture.

**Demo-visible outcome:** the malformed template fails, and the alert explains what changed in words the accountant understands.

### Phase 6 — Email approval, Asset Manager edit, narrative, polish

**Objects:**
- [ ] **Inbound email capability check** on the NY instance, tried here with the result logged. If absent, stop and report; no workaround is improvised.
- [ ] **Reply interpretation:** the AI classifies each reply as Approve, Reject or Ambiguous.
  - Approve and Reject call `SD Apply Draw Approval Decision`.
  - Ambiguous sends a clarification reply and never changes state.
- [ ] **Asset Manager budget edit** at their approval step only.
  - Edits are attributed by record events, composed at write time.
  - Edits are visible downstream in the view and the email.
- [ ] **Stretch: AI-drafted contingency narrative** with Fund Accountant review; the approved text lands in the draw's contingency explanation field.
- [ ] **Treasury notification content** finalised.
- [ ] **Polish and demo readiness:** a reset action with an explicit id list, a verify-ready check, and a rehearsal on the live path.

**Dependencies:** Phases 1–5; an email-capable instance.

**Verification:**
- **Interpretation specimens held constant:** a clear approve, a clear reject, and an ambiguous reply. Each lands as specified, and the ambiguous reply is confirmed to leave the draw's state unchanged. This is the break-test.
- **Asset Manager edit:**
  - As the Asset Manager through sail, the edit is possible at their step.
  - It is blocked at any other step.
  - The attribution appears in the activity.

**Demo-visible outcome:** "looks good, approve" completes the chain, and treasury is notified.

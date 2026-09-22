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

**Verified 2026-09-21, as the designer** (`BUILD_LOG.md`): every pass condition above held, including the reject break-test. Not verified: email delivery, persona behaviour, widths over 255 through the production path.

**Demo-visible outcome.** No UI this phase. Draw #66 exists with its full data, and the approval chain runs from the Asset Manager through the accelerator to the CEO and on to Approved.

### Phase 2 — UI foundation (mockup-first)

**Ruled 2026-09-21.**
- Draw views join the existing intake site, `SASite` ("Subscription Agreement Analyst", stub `subscription-agreement-analyst`), in a new page group. There is no dedicated site.
- Persona accounts are deferred; Phase 1 verifies as the designer.

**Objects:**
- [ ] **HTML mockups** for the draw list and the draw summary views, committed to `mockups/`. They are reviewed and approved before any SAIL is written.
- [ ] **`SD Draw` record list**, built against its approved mockup.
- [ ] **`SD Draw` summary view**, built against its approved mockup: header facts, the budget grid by category group, the approval status table and the QIU table.
- [ ] **Related actions:**
  - "Record decision", visible only to the current step's role;
  - "Advance draw (demo)", visible to administrators only.
- [ ] **Restyle the Phase 1 task form**, if one was created, to the approved mockup's vocabulary.
- [ ] **Site pages on `SASite`, in a new page group.**
  - Page groups take interface pages only.
  - Navigation grouping is not exposed over the Dev MCP, so the grouping may be a Designer step.
  - `updateSite` regenerates every page's URL stub, so any reference to an intake page is re-checked afterwards.
- [ ] **Persona site stub build parameter** set to `subscription-agreement-analyst`.

**Dependencies:** Phase 1; mockup approval.

**Verification:**
- `testInterface` returns `diagnostics.error: null`, and hidden branches are revealed once each.
- Persona checks through sail once the persona accounts exist; until then, as the designer, with scope stated.
- The intake site's existing pages still resolve after `updateSite`.
- **Browser only:** geometry.

**Demo-visible outcome:** draw #66 opens as a record on the intake site, showing its header, budget, QIU table and a live approval status table.

### Phase 3 — Doc Center ingestion, success path

**Objects:**
- [ ] **Working example first.** Read the existing `SD Process Packet (async)` Doc Center configuration and copy the mechanism, changing one thing at a time (supplemental §1). Find it before building anything new.
- [ ] **Excel template handling.** Confirm Doc Center handles the Excel budget template as-is. The fallback is extraction from a PDF rendition (open question). Any binary sample template is added by hand in Designer and its byte size read back, because binary uploads over MCP corrupt.
- [ ] **Ingestion process `SD Ingest Draw Template`:** document in, Doc Center extraction, confidence check, a branch to reconciliation below the threshold, then budget-line writes.
- [ ] **Accountant reconciliation form:** a start form or related action on `SD Draw` showing the extracted values with their confidence, and a confirm-to-commit step. Data commits only after confirmation.
- [ ] **Manual trigger** for the demo ("template arrives"), narrated as the EY API/SFTP feed.
- [ ] **`SD Draw Document` rows** for the template and the backup documents.

**Dependencies:** Phase 1 record types; Phase 2 views; the Doc Center capability on the instance; a clean template specimen.

**Verification:**
- **Specimens held constant:** a clean template and a low-confidence template, identified by their properties.
- **Pass conditions:**
  - The clean template produces the expected budget-line count and totals, stated number against number, with the draw's totals matching the email sample.
  - The low-confidence template routes to reconciliation, and nothing is written before confirmation. This is the break-test.
- **Accountant path:** driven through sail as the Fund Accountant.

**Demo-visible outcome:** a corrected template goes in; the accountant confirms the extraction; budget lines appear on the draw.

### Phase 4 — New approval email layout

**Objects:**
- [ ] **Capability check first:** whether outbound email is delivered from the NY instance (open question), tried on the instance with the result logged.
- [ ] **`SD_draw_approvalEmailBody`:** an HTML body rule built from live draw data, matched section by section to `New approval email sample blacklined.pdf`:
  - header band;
  - Draw Funding Detail;
  - Draw Detail by Budget Category;
  - Budget Summary;
  - Remaining Contingency;
  - QIU Detail;
  - Approval Status, with contiguous orders 1–9; the sample's numbering gap is not reproduced;
  - the reply instruction.
- [ ] **Data handling in the body:** every data value escaped; currency through `SD_formatCurrency`.
- [ ] **Send node:** a Send E-Mail node with `IsHTML` true, sent to the current approver at the CEO step, and to the treasury recipient for the notification.

**Dependencies:** Phase 1 data; Phase 2 views for the link-back. The spec PDF is re-rendered at high resolution to read the fine print; the earlier render was 612×792.

**Verification:**
- The body rule is evaluated against draw #66, and every figure is checked against the seed.
- Each section heading from the spec is present in the output.
- **Browser and mailbox only:** rendering, column widths and wrapping in a real mail client, as a human checklist against the PDF.

**Demo-visible outcome:** the CEO's inbox shows the new-format email with the full budget tables.

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

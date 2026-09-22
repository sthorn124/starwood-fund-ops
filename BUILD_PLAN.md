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

### Phase 1 — Foundation: data model, seed, sequential approval, base views  ← NEXT SESSION'S SCOPE

**Objects to create.** All are added to `Starwood Demo`, and all names use the `SD` prefix.

- **Record types.** Six, created with `length` set at create time, because altering a width later does nothing (supplemental §7):
  - [ ] `SD Investment`: name and description; related to `SA Fund`.
  - [ ] `SD Draw`: header facts per the data model, plus `status` and `currentStep`; related to SD Investment.
  - [ ] `SD Draw Budget Line`: `categoryGroup` limited to Land / Soft / Hard, and an `inThisDraw` flag.
  - [ ] `SD Draw Approval`: order, role, approver, status (Pending / In Progress / Approved / Rejected), decision date, comments.
  - [ ] `SD QIU Metric`: the ten metrics from the email samples, in canon order (`PROJECT_INSTRUCTIONS.md` § Data model), with model as-of date, current model value, current projection, variance and notes.
  - [ ] `SD Draw Document`.
- **Relationships and security.**
  - [ ] SD Draw to each child (one-to-many), SD Draw to SD Investment (many-to-one), and SD Investment to `SA Fund` (many-to-one).
  - [ ] Record-level security defined once on `SD Draw` and inherited by the children through RELATED_RECORDS.
  - [ ] Every relationship and security rule read back after it is written.
- **Groups.**
  - [ ] Draw approval runtime groups under `SD Users`: at least the Fund Accountant and the Asset Manager.
  - [ ] Membership added by a human in Designer. Membership writes over the Dev MCP are unverified, so an empty group is the expected state until then. The Security groups build parameter in `CLAUDE.md` is updated when the groups exist.
- **Shared rules**, implemented once and used by every consumer:
  - [ ] `SD_getDrawNextApproval`: the next Pending order for a draw.
  - [ ] `SD_formatCurrency`: `round()` before `text()`, with one thousands group per magnitude up to billions (supplemental §4).
  - [ ] Budget roll-up rules: totals by category group, Total PTD %, balance to complete.
- **Seed data.** A deterministic script with explicit ids and no `now()`, `today()` or `rand()`. Keys come from the source; no `max()+1` (`CLAUDE.md` §12).
  - [ ] One SD Investment row: the hotel property on Harborline Fund II (`SA Fund` id 4).
  - [ ] Draw #66: PIP/Renovation, $2,604,252.23, on that investment.
  - [ ] Its budget lines, transcribed from the new approval email sample.
  - [ ] Its ten QIU metric rows, in canon order.
  - [ ] Its approval chain: nine rows, contiguous orders 1–9. Orders 1–2 (Accountant, Accounting Controller) are Approved, order 3 (Asset Manager) is In Progress, and orders 4–9 are Pending (narrative beat 4).
- **Processes.** All unattended, so `testProcessModel` can exercise them.
  - [ ] **`SD Apply Draw Approval Decision`** takes the draw id, the decision, comments and the actor.
    - It writes the step's approval row.
    - On Approve, it moves the next order to In Progress and updates `currentStep`.
    - On Reject, it terminates the draw.
    - On final approval, it sets the draw to Approved and branches to the treasury notification.
    - Every business write is its own Write Records node with `ErrorOccurred` wired, and the downstream nodes are gated on write success.
  - [ ] **`SD Advance Draw (Demo Accelerator)`** applies Approve to each step between the Asset Manager and the CEO through the decision process, one step at a time, with a hard iteration ceiling.
  - [ ] **The treasury notification terminal step**: a Send E-Mail node with its four traps handled (supplemental §9), gated on the final-approval write. Whether outbound email is actually delivered is verified in Phase 3.
- **Base record views and actions.**
  - [ ] `SD Draw` summary view: header facts, the budget grid by category group, the approval status table and the QIU table.
  - [ ] Related action "Record decision" on `SD Draw`, visible only to the current step's role.
  - [ ] Related action "Advance draw (demo)", visible to administrators only.
- **Site.** Draw views join an existing site or a dedicated one, per the open question.
  - [ ] Ruled before the views are placed on any site.
  - [ ] The Persona site stub build parameter set once the site exists.
- **Mockup pass** for the draw summary view:
  - [ ] Done before the view is built.
  - [ ] Committed under `mockups/` as the interface contract.

**Dependencies:**
- Phase 0 discrepancies ruled.
- The mockup for the draw view.
- The site decision.
- Persona accounts and group membership: human steps in Designer, needed only for the persona verification.

**Verification, stated before the run:**
- **Record types.** Each type and field read back, and each field's width proven by a real-length write through a Write Records node.
- **Seed.** Row counts per type, read as the designer with scope stated, equal the seed script's expected counts: 1 investment, 1 draw, 10 QIU metrics, and 9 approvals with orders 1–9 and no gap.
- **Decision process, each path through `testProcessModel`, with the draw read back afterwards:**
  - Approve advances `currentStep` by exactly one order.
  - Reject sets the draw to Rejected, and no later approval row changes.
  - Final approval sets the draw to Approved, and the notification node is reached.
- **Break-tests.**
  - Force a failed approval write; confirm neither the next-step write nor the notification fires.
  - Run the accelerator against a draw already at the CEO step; confirm it stops at its ceiling.
- **Views.** `testInterface` returns `diagnostics.error: null`, and the hidden branches are revealed once each.
- **Persona checks through sail, once the site and accounts exist:**
  - as the Asset Manager, the "Record decision" action appears only at their step;
  - as the Fund Accountant, it does not appear.
- **Browser only:** geometry of the summary view.

**Demo-visible outcome:** draw #66 opens as a record, showing its header, budget by category group, QIU table and a live approval status table. Recording a decision as the Asset Manager and then running the accelerator walks the chain to the CEO step. A final approval marks the draw Approved.

### Phase 2 — Doc Center ingestion, success path

**Objects:**
- [ ] **Working example first.** Read the existing `SD Process Packet (async)` Doc Center configuration and copy the mechanism, changing one thing at a time (supplemental §1). Find it before building anything new.
- [ ] **Excel template handling.** Confirm Doc Center handles the Excel budget template as-is. The fallback is extraction from a PDF rendition (open question). Any binary sample template is added by hand in Designer and its byte size read back, because binary uploads over MCP corrupt.
- [ ] **Ingestion process `SD Ingest Draw Template`:** document in, Doc Center extraction, confidence check, a branch to reconciliation below the threshold, then budget-line writes.
- [ ] **Accountant reconciliation form:** a start form or related action on `SD Draw` showing the extracted values with their confidence, and a confirm-to-commit step. Data commits only after confirmation.
- [ ] **Manual trigger** for the demo ("template arrives"), narrated as the EY API/SFTP feed.
- [ ] **`SD Draw Document` rows** for the template and the backup documents.

**Dependencies:** Phase 1 record types and views; the Doc Center capability on the instance; a clean template specimen.

**Verification:**
- **Specimens held constant:** a clean template and a low-confidence template, identified by their properties.
- **Pass conditions:**
  - The clean template produces the expected budget-line count and totals, stated number against number, with the draw's totals matching the email sample.
  - The low-confidence template routes to reconciliation, and nothing is written before confirmation. This is the break-test.
- **Accountant path:** driven through sail as the Fund Accountant.

**Demo-visible outcome:** a corrected template goes in; the accountant confirms the extraction; budget lines appear on the draw.

### Phase 3 — New approval email layout

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

**Dependencies:** Phase 1 data. The spec PDF is re-rendered at high resolution to read the fine print; the earlier render was 612×792.

**Verification:**
- The body rule is evaluated against draw #66, and every figure is checked against the seed.
- Each section heading from the spec is present in the output.
- **Browser and mailbox only:** rendering, column widths and wrapping in a real mail client, as a human checklist against the PDF.

**Demo-visible outcome:** the CEO's inbox shows the new-format email with the full budget tables.

### Phase 4 — Ingestion failure path

**Objects:**
- [ ] **Template validation** in `SD Ingest Draw Template`, which classifies the failure: file unreadable, structure changed, or values missing.
- [ ] **Last-good baseline:** the last successfully ingested template kept as the comparison source.
- [ ] **AI diff:** a model call comparing the failed template with the last good one, producing a plain-English explanation.
  - It runs in the process or in an interface, never in an expression rule, because model calls cannot live there (supplemental §3).
  - A deterministic validation gate sits on its output before the alert uses it (`examples/deterministic-validation-gauntlet.md`).
- [ ] **Alert email** to the accountant and the asset managers: the failure reason plus the AI diff.

**Dependencies:** Phases 2 and 3; a malformed-template specimen.

**Verification:**
- **Specimens held constant:** a malformed template and a clean template.
- **Pass conditions:**
  - The malformed template produces the alert, and no budget lines are written. This is the break-test.
  - The diff names the real structural difference.
  - The clean template produces no alert.
- **Live run:** the AI output is judged on a live run, not a fixture.

**Demo-visible outcome:** the malformed template fails, and the alert explains what changed in words the accountant understands.

### Phase 5 — Email approval, Asset Manager edit, narrative, polish

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

**Dependencies:** Phases 1–4; an email-capable instance.

**Verification:**
- **Interpretation specimens held constant:** a clear approve, a clear reject, and an ambiguous reply. Each lands as specified, and the ambiguous reply is confirmed to leave the draw's state unchanged. This is the break-test.
- **Asset Manager edit:**
  - As the Asset Manager through sail, the edit is possible at their step.
  - It is blocked at any other step.
  - The attribution appears in the activity.

**Demo-visible outcome:** "looks good, approve" completes the chain, and treasury is notified.

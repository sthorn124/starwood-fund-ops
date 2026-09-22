# Closeout — 2026-09-22 — Phase 3: Doc Center ingestion, success path — capital call intake, extraction, accountant reconciliation, draw assembly

## Scope and identity

- **Designer:** Dev MCP `appian` as `scott.thorn@appian.com` — member of `SD Administrators`, `SD Users` and all three draw approval step groups (incl. `SD Draw Demo Approvers`, which is why it could complete the accountant's task). Every `testInterface` / `testRule` / `listRecordData` readback and the one `completeTask` ran under it. Unattended Doc Center and commit nodes run as DESIGNER by design.
- **Personas, via sail:** `sd.accountant` (`~/.sail-sd.accountant`, `SD Draw Demo Approvers`) drove the intake form and read the Draws page and the draw's tabs; `sd.assetmanager` (`~/.sail-sd.assetmanager`) read the Draws page. Both sessions live all session. `--from-devmcp` never used; `appian-runtime` never used.
- **Docs gate honoured:** docs-search on `a!fileUploadField` (folder target needs Editor) and on the editable grid before either form.

## The capability result (brief item 1)

**Doc Center extracts the xlsx directly — that is the live path. No PDF rendition.** Doc Center here is the DocCenter application (prefix AIA); its extraction models are data rows, and model 85 `drawBudgetTemplate` (version 142, 12 header fields + a 9-column `budgetLines` table) was created with `insertRecordData`. `AIA Extraction Run Model Version` sent the workbook down the Generative-AI spreadsheet path (one claude-haiku-4-5 call, ~22 s) and returned every header field and all 16 lines correctly on the first live run. Recorded in `reference/mcp-capability-boundaries.md`.

**Extraction quality observed:** all 12 header fields right; `submittedBy` arrived as "Submitted by Vail Peak Management LLC (Property Manager)" (the form strips the prefix); the 16 lines exact, as the sheet displays them ("106,664,345", "(21,509)", "91.9%", blanks) — parsed by `SD_parseExtractedNumber`; **no per-field confidence** on the spreadsheet path (the form says so). **Nothing needed the accountant on the clean template.** Two Doc Center traps cost time: its save step throws when the LLM returns `[]` for a blank scalar field (`generalComments` removed from the model), and it caches the LLM response per document.

## What was built

- **Intake (item 2).** `SASite` page **Receive Capital Call** → `SD Receive Capital Call (Intake Form)` (start form `SD_form_receiveCapitalCall`, one xlsx into the new `SD Draw Documents` folder) → async `SD Receive Capital Call`: draw shell (**Ingesting**, `receivedDate` today, `ingestionProcessId`), document row (**Received**), Doc Center extraction as the designer, instance id on the draw. The shell is on the Draws list within ~10 s ("New draw", Ingesting, YOUR ACTION for the accountant group).
- **Extraction → reconciliation (item 3).** `SD_getExtractionForReconcile` turns the instance into text/JSON; task **Reconcile extracted draw** (`SD_form_reconcileExtraction`, assigned to `SD Draw Demo Approvers`): editable header, editable 16-line grid, document link, tie-out chip, confidence notice. On confirm: header facts, 16 `SD Draw Budget Line` rows (groups/inThisDraw derived), document row **Extracted & Confirmed** "by <name> MM/DD/YYYY".
- **Assembly (item 4, done).** QIU set and nine-row chain copied from the investment's most recent prior draw (QIU re-dated to today; names as the mockups), draw **In Progress** at step 1, `SD Draw Approval Process` started. `scripts/seed_draw66.py --cleanup-ingested` (explicit ids, seeded ids refused, children first); `CLAUDE.md` demo-repeatability note.
- **UI tolerance for shells:** Draws page dropdowns no longer crash on blank names (the shell had broken the page with "Choice values cannot be null"), "Ingesting" filter choice, "New draw" label and step cell; `SD_getDrawDetail` v6 treats an Ingesting draw as the accountant group's with the task found on `ingestionProcessId`; Summary strip "Doc Center extraction is ready…" with a **Reconcile Extraction** card; fact-strip crumb.
- **Housekeeping:** fifteen Phase 2b objects that were outside the application (created without `appUuid`) added to it.

**Where the reconciliation task lives in the UI:** Draws page → the "New draw" row (YOUR ACTION for the accountant group) → Summary → blue strip → **Reconcile Extraction** (a `ProcessTaskLink`); also in the Tasks list as "Reconcile extracted draw".

## How the pipeline works (30 nodes, `0000f06f-5661-…`)

Start → cancel? → **Create draw shell** (Write, `ingestionProcessId` = pp!id) → shell written? → read id → **Register template document** → read row id → **Doc Center: extract** (sync subprocess, `modelKey` drawBudgetTemplate, DESIGNER) → **Find extraction instance** (by document id) → extracted? → **Store extraction id** → **Prepare reconciliation** (JSON) → **Reconcile extracted draw** (task) → parse → **Commit header facts** → committed? → **Commit budget lines** → **Template Extracted & Confirmed** → **Assemble QIU and chain** → QIU available? → **Aggregate QIU rows** → **Create approval chain** → chain written? → **Activate draw** → **Start SD Draw Approval Process** (async) → done. Failures → **Ingestion Failed**. Every write is its own node with `PauseOnError` false and `ErrorOccurred` wired; the three gates are the shell, the header commit and the chain.

The launcher is a separate three-node model because the Dev MCP cannot read a model that has a start form; it is frozen (change = delete, recreate, re-point the page).

## Verified

**As `sd.accountant` via sail:** page list; form loads; local xlsx uploaded and **Receive** submitted; Draws page shows the Ingesting row first with YOUR ACTION and the KPI "New draw (ingesting) · Accountant reconciliation · today"; Summary strip with **Reconcile Extraction** → stored `ProcessTaskLink` task **8435** (listed by `listMyTasks`, process 38740, issued 78 s after submit). After assembly: `#67 YOUR ACTION | Tamarack Hotel & Spa Vail | $2,604,252.23 | 11/16/2026 in 55 days | 1 of 9 · Accountant Priya Ramen · today | In Progress`; Documents tab "Extracted & Confirmed · Doc Center extraction confirmed by Scott Thorn 09/22/2026"; Budget Detail 16 lines.

**As `sd.assetmanager` via sail (item 6):** Awaiting 1 · Draw #66; `#66 YOUR ACTION` first; `#67` present with **no** YOUR ACTION (chain at Accountant).

**As the designer:** `SD Draw` 74 = #67 with every header fact equal to the template (amount 2,604,252.23, funding 2026-11-16, PIP/Renovation, On Budget, N/A, purpose, contingency, submittedBy stripped, investment 1); 16 lines equal to the template row for row; 10 QIU rows as of 2026-09-22; chain 6610–6618 with the mockup names, order 1 In Progress; `SD Draw Approval Process` → "STARTED step 1 of draw 74 (step process 38746)". `testInterface` Summary #67: **Ties ✓** $2,604,252.23, Budget Summary total $390,196,711 / current draw $2,604,252, Funding History #67, #65, #64, #63, QIU "model as of 09/22/2026", INGESTION "Extracted & Confirmed"; Documents view carries a real `DownloadDocLink_[Document:55270]`; the reconciliation form rendered with the live payload (13 fields, 16 rows, Ties ✓). Pipeline topology and every node read back; both probes 404.

## Not verified (and the browser checklist)

- **The persona's own submit of the task** — the brief's "complete the reconciliation task via sail as sd.accountant": sail cannot open a task (measured in Phase 2b, again here — no `tasks` command, task links are `<display>`). The task was completed over the Dev MCP as the designer with the unedited payload, so the document row reads "confirmed by Scott Thorn" this session. Checklist in `TODO.md` (reset → intake as `sd.accountant` → Reconcile Extraction → Confirm & assemble draw → expect "confirmed by Priya Ramen"), with the edited-value run as its optional step 5.
- Document download as a persona (S9); geometry of both forms — browser only.
- The `Ingestion Failed` branch never fired (Phase 5's malformed template is the break-test).

## Defects found and fixed

- Subprocess parameter mappings sent under `customInputs` left the child's `document` null (three stalled runs) → mappings belong in `inputs` as `pv!x`.
- Doc Center's save step on `[]` for a scalar (two stalled instances) → field removed from the model.
- The Draws page crashed on an Ingesting shell (blank dropdown choice values) → blanks dropped.
- `activeStepProcessId` could not be nulled by Write Records, which blocked the approval launcher ("NOT_STARTED … activeStepProcessId=38740") → separate `ingestionProcessId` column; draw 74 repaired by CSV.
- Fifteen Phase 2b objects were outside the application → added.

## Rulings needed

1. **Reconciliation as a task versus a related action.** The task matches the brief but is browser-only for personas; a related action on the draw would be sail-drivable end to end. Keep the task (recommended: it is what the mockups and the approval steps do) or switch.
2. **Funding History on #67** lists prior *approved* draws (65/64/63); the brief expected 66/65/64.
3. **General Comments** is not extracted (see Known data artifacts); re-add only with a filled specimen.
4. **Stranded process instances** from the build need cancelling in Process Monitoring (`TODO.md` lists them).

## Promotion candidates

9 found: start-form models unreadable over the Dev MCP (gate 2, three models); `tostring()`/`text()`/`todate()`/`a!toJson` number and date traps; Write Records cannot null a field; Start Process smart service unconfigurable + non-parameter child outputs unmappable; `deleteRecordData` does not cascade; objects created without `appUuid` sit outside the app; Doc Center findings (instance-specific); `completeTask` completes a group task with all ACPs. **1 earlier trigger fired** (subprocess mapping) and was ruled: promoted to `reference/mcp-capability-boundaries.md` §4, held from the supplemental pending the skill owner's reconciliation with its own wording. 0 promoted to the skill; repo and user-level copies unchanged and identical. Checkpoint current through this entry.

## Repo changes

`CLAUDE.md` (Phase 3 objects, ingestion rules, "yours" for Ingesting, repeatability, two artifacts, files), `BUILD_PLAN.md` (Phase 3 ✅ items and new open items), `BUILD_LOG.md` (entry + staging), `TODO.md`, `Closeout.md`, `reference/mcp-capability-boundaries.md`, `scripts/seed_draw66.py` (cleanup mode), `.work/sail/` (new `.sail` files, `gen_receive_process.py`, `gen_ingest_rules.py`, regenerated page/view/detail/strip, `refs.py`), the two `ref_AIA_*.sail` reference copies. The xlsx templates stay local (gitignored).

## TODO changes

Added — Before demo: ingestion demo reset; cancel stranded instances. Browser checks owed: the persona reconciliation run (with the edited-value step), document download as a persona, Phase 3 form geometry (replacing the "document links appear only once files are attached" item). Client validation: Funding History semantics; General Comments. Deferred: edited-value run pointer, backup documents, the frozen launcher, the removed Doc Center field, Ingesting sort order. Closed: none.

## BUILD_PLAN.md changes

Phase 3 marked CORE COMPLETE 2026-09-22: working example, xlsx handling, ingestion process, reconciliation form, manual trigger, document row, post-confirm assembly all ✅; new open items: persona submit (browser), edited-value run, backup documents, stranded instances, Funding History ruling.

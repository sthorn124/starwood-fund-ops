# Closeout — 2026-09-25 — Phase 5.5: multi-document corroboration at intake

## Scope and identity

- **Design work:** the Dev MCP `appian` as `scott.thorn@appian.com`. This account is full scope: a member of `SD Administrators`, `SD Users` and the three step groups. Every `testRule`, `testInterface`, `listRecordData`, `completeTask` and `testProcessModel` call below ran as this account.
- **Persona reads:** sail as `sd.accountant` (`~/.sail-sd.accountant`) and `sd.assetmanager` (`~/.sail-sd.assetmanager`). Both sessions were live. The default `~/.sail` holds no session.
- **Not used:** `appian-runtime` and `--from-devmcp`.
- **Draw 66:** untouched. Elena's task 536876873 and step process 536909994 are still open.
- **Preflight:** earlier this session. Dev MCP 26.6.95 (26.6.100 is on the App Market, flagged), sail 26.6.95, skill copies identical.

**Framing, recorded in `BUILD_PLAN.md` from the client meeting.** Corroboration catches bad submissions before the approval chain starts, and it evidences the package on the draw record. Its value is verification: fewer error loops, fewer approver interruptions, lien exposure surfaced, audit evidence. It is deliberately not extraction-labour savings.

## 0. Bookkeeping

- **TODO:** the Phase 5 browser checks moved to Done. You verified the alert in Gmail and the failed-draw card in the UI as the persona.
- **BUILD_PLAN, documentation only:**
  - The final demo's intake arrives through a simulated feed (email-in or a watched drop location), narrated as the EY API/SFTP feed.
  - Receive Capital Call is build-time tooling.
  - Feed-arrival simulation is a Phase 6 staging item. Intake stays "a set of documents in, one draw out".

## 1. The demo package (`scripts/gen_draw_package.py`, committed)

The generator reads `THSV_Draw67_Budget_Template.xlsx` itself, so every tie is exact. It writes four one-page PDFs in pure Python, because this machine has no PDF library.

**Keep these four files.** They sit at the repo root and are gitignored:

| File | Bytes | md5 | What it carries |
|---|---|---|---|
| `THSV_Draw67_PayApp_G702.pdf` | 7,637 | efc383e6… | G702-style application from **Stonebridge Construction Group** (GC) to THSV Holdings LLC c/o Vail Peak Management LLC. Application No. 14, period 10/01–10/31/2026. **Current Payment Due $2,490,296.23**, which is the template's Hard Costs current draw. |
| `THSV_Draw67_PayApp_G702_mismatch.pdf` | 7,637 | 4bcaa3da… | Identical except **Current Payment Due $2,527,796.23** (+$37,500.00). |
| `THSV_Draw67_Invoice_AlderFinch.pdf` | 3,865 | 7637859c… | Invoice AF-2026-1087 from Alder & Finch Architects, LLP, dated 10/31/2026. Total **$59,582.00**, which is the **A&E - Architectural** current draw; the generator names that line. |
| `THSV_Draw67_LienWaiver_Conditional.pdf` | 4,285 | 6415b9f9… | Conditional waiver and release on progress payment from Stonebridge, through 10/31/2026. It is there to be present; no figure is read from it. |

Regenerate the files with `python3 scripts/gen_draw_package.py`.

**One interpretation:** "Hard Costs current draw subtotal" is taken as the **Hard Costs line** ($2,490,296.23), the GC's contract line. The Hard group roll-up ($2,491,584.23) adds FF&E, which a GC pay application does not carry.

## 2. Intake accepts a package

**Receive Capital Call** (`SD_page_receiveCapitalCall` v8) takes:
- the template: one xlsx, required;
- supporting documents: **upload slots**, one PDF each. A new empty slot opens after each upload, up to 10.

One Receive commits every upload and passes `supportingDocuments` to the pipeline. The confirmation reads "N supporting documents are being classified and read…" or "No supporting documents came with this package."

**Why slots, not one multi-file field (measured, the session's main finding).** The first live run used a single multi-file field.
- After three uploads through sail, only the last PDF existed; the first two were "Document Does Not Exist".
- An upload that replaces a field's value discards the temporary file it replaced, and sail's upload sends only the new file.
- The pipeline was handed two dead documents. It still ran the template path to a reconciliation task on time, because reading is asynchronous and never blocks. The reading child wrote nothing.
- One file per field keeps every upload in its own field. That run's draw 85 was deleted.

**Pipeline `SD Receive Capital Call`** (48 PVs; nodes 42–45 added, validator clean):
- Node 42 sends any supporting documents to the new **`SD Read Supporting Documents`** child, **asynchronously**.
- The template path (extraction, validation, failure branch) is unchanged. A package with no documents takes node 42's default path, exactly as before.
- The child registers each PDF as an `SD Draw Document` row (Received).
- It makes **one AI call per PDF** (DocCenter's Doc Input skill 267, Claude Sonnet 4.6). The call classifies the document as Pay Application, Invoice, Lien Waiver or Backup and reads party, reference and one figure.
- It gates the answer with a deterministic parser. Unknown or failed → Backup, "Not read".
- It then rewrites the row: type, status Read, amount, party, reference, and a notes line with the AI time and actions.

**AI time and actions, measured on the live runs:**

| Document | Time | AI actions |
|---|---|---|
| Pay application | 7.9 s | 3 |
| Mismatch pay application | 6.8 s | 3 |
| Pay application (failure run) | 6.4 s | 3 |
| Invoice | 6.1 s | 2 |
| Lien waiver | 6.7 s | 2 |
| Lien waiver (failure run) | 5.3 s | 2 |

A three-document package was fully read before the reconciliation task arrived, about 80 s after submit.

**Documents tab:** it lists every row with its type, a status chip (Read is green, Not read is amber) and the AI notes line.

## 3. Corroboration at reconciliation

The reconciliation form (`SD_form_reconcileExtraction` v4) gains **SUPPORTING DOCUMENTS · CORROBORATION** under the budget grid. It is a read-only grid with the columns Document (party · reference beneath), Type, Document figure, Template figure and Tie-out. It is computed by rules over the lines **as the accountant edits them**; no model is involved.

**Tie-out rules:**
- **Pay Application:** Current Payment Due against the Hard Costs current draw.
- **Invoice:** the total against the budget line with exactly that current draw. If no line matches: "Does not tie: $X · no matching budget line".
- **Lien Waiver:** green "Lien waiver received".
- **Backup:** grey "Received".

**Chips and lines:**
- Green **Ties**, or amber **Does not tie: <doc figure> vs <template figure>**.
- A pay application without a lien waiver adds the amber line **No lien waiver received with the pay application**.
- No documents at all → the neutral line "No supporting documents came with this package; the template is reconciled on its own."
- While a document is still being read, a Refresh link shows, and the section re-reads every 30 s.
- **Nothing blocks Confirm.**

**After Confirm**, pipeline nodes 44/45 recompute over the committed lines and write two fields on the draw:
- `corroborationSummary`, for example "3 supporting documents · pay application ties · invoice ties · lien waiver received";
- `corroborationState`: TIES, ATTENTION or NONE.

The **Summary's Draw Origin card** ends with a **SUPPORTING DOCUMENTS** line: a Package ties / Needs attention / None received chip and the summary. It shows only on draws that carry a summary, so draw 66 and the other seeded draws look exactly as before.

## 4. Live verification (sail as `sd.accountant`; readbacks as the designer)

| Run | Draw | What was verified |
|---|---|---|
| **Clean package** (template + pay application + invoice + lien waiver) | 86 → **#73** | Form: two green **Ties** (Pay App $2,490,296.23 vs Hard Costs · current draw $2,490,296.23; Invoice $59,582.00 vs A&E - Architectural · current draw $59,582.00) and green **Lien waiver received**. Confirmed. Draw: TIES, "3 supporting documents · pay application ties · invoice ties · lien waiver received". **As `sd.accountant`:** Draw Origin chip green **Package ties** with that line; Documents tab lists 4 rows with types (Budget Template / Pay Application / Invoice / Lien Waiver). |
| **Mismatch** (template + mismatch pay application, no waiver) | 87 → **#74** | Form: amber **Does not tie: $2,527,796.23 vs $2,490,296.23** and the amber no-waiver line; Confirm enabled. Confirmed. Draw: ATTENTION. **As `sd.accountant`:** chip amber **Needs attention**, "1 supporting document · pay application does not tie ($2,527,796.23 vs $2,490,296.23) · no lien waiver with the pay application". |
| **Template only** (regression) | 88 → **#75** | Page: "No supporting documents came with this package." Form: the neutral line; no grid, no amber; everything else as before (Ties ✓, collision renumbering). Confirmed. Draw: NONE, "No supporting documents received". **As `sd.accountant`:** grey **None received**. |
| **Failure regression** (v2 template + pay application + lien waiver) | 89 | Both PDFs read, and the template still took the **Ingestion Failed** branch: the same reasons and comparison as Phase 5; no reconciliation task; the alert sent (row 6628 written after the send node). One more alert is in the inbox. |
| **Draw 66** | 66 | Untouched (designer readback). `sd.assetmanager` still sees "Awaiting My Action 1 · Draw #66 · Asset Manager step". |

**How the tasks were confirmed.** sail cannot open a task link, a known limit, reproduced here. Each reconciliation form was therefore:
- rendered with `testInterface` as the designer, using the task's real inputs;
- completed with `completeTask` as the designer, sending exactly what the form's Confirm button serialises (reproduced by a throwaway rule).

The template rows therefore read "confirmed by Scott Thorn".

**Cleanup.**
- **Stale Ingesting shells.** Four rows all read "New draw", and sail refused the ambiguous link. Draws **81, 84, 85** were deleted by explicit id, children first, and their absence was confirmed.
- **Throwaway rules.** `zz_probeCorroboration` and `zz_probeReports` were deleted; both return 404.

## Objects changed

- **New process:** `SD Read Supporting Documents` (`0000f073-a7ee-8000-25b1-7f0000014e7a`).
- **New rules:**
  - `SD_supportingDocumentPrompt` (`…_573543`);
  - `SD_parseSupportingDocReading` (`…_573549`);
  - `SD_getSupportingDocuments` (`…_573555`);
  - `SD_corroborateDocuments` (`…_573561`, v2);
  - `SD_getDrawCorroboration` (`…_573567`).
- **New constants:** `SD_DOCUMENT_READING_MODEL` (`…_573531`), `SD_PAY_APP_TIE_CATEGORY` (`…_573537`).
- **New fields:**
  - `SD Draw Document`: `extractedAmount`, `extractedParty`, `extractedReference`;
  - `SD Draw`: `corroborationSummary`, `corroborationState`.
- **Changed:**
  - `SD Receive Capital Call`: 48 PVs, nodes 42–45, 8 → 42, 22 → 44;
  - `SD_page_receiveCapitalCall` v8;
  - `SD_form_reconcileExtraction` v4;
  - `SD_getDrawDetail` v8;
  - `SD_view_drawSummary` v8;
  - `SD_cmp_statusTag` v3.
- **Data:**
  - new draws 86–89 and their rows;
  - draws 81, 84, 85 and rows 6615, 6618, 6620 deleted.

## Not verified, and the browser checklist

- **The accountant's own Confirm from the task:** sail cannot open task links. The Dev MCP designer completed it instead.
- **Geometry,** all browser-only:
  - the upload slots;
  - the corroboration grid and its chips (fit, wrapping);
  - the Draw Origin line;
  - the Documents tab.
- **PDF download as the persona.**
- **Live paths not yet exercised:** "no matching budget line", a Backup document and a "Not read" reading. They are covered only by the gauntlet (C3/C6/C7) and the child's break-test.

The full checklist is in `TODO.md` → Browser checks owed → "Phase 5.5 package intake, corroboration section and Documents tab, as the persona". In short:
1. As `sd.accountant`, attach the template and the three PDFs, one per slot. Clear and re-attach a slot. Try a non-PDF. Receive.
2. Reconcile Extraction. Expect two green Ties and "Lien waiver received". Edit Hard Costs to see the pay-app chip turn amber, restore it, then Confirm.
3. Expect Draw Origin to show "Package ties", and the Documents tab to list 4 typed rows that download.
4. Run the mismatch package. Expect amber "Does not tie: $2,527,796.23 vs $2,490,296.23", the amber no-waiver line, and "Needs attention".

## Rulings needed

None blocking. Two notes for you:
- **Demo clutter:** `sd.accountant` now has 9 draws awaiting action. The package beat's reset is in `TODO.md` (Before demo).
- **Stranded process instances** (draw 85's pipeline 39011 and its child; the deleted shells' pipelines for 81 and 84) are listed in `TODO.md`. Cancel them in Process Monitoring, and do not resume them.

## Promotion candidates

**3 found, staged at gate 1:**
- A replaced upload discards its temporary file, and sail's upload sends only the new file.
- An `a!forEach` whose items are all skipped yields `[[]]`, which `count()` counts and `len()` skips.
- sail cannot address repeated link labels.

**2 triggers fired:**
- The AI-skill `customInputs` form was confirmed on a second skill and extended: a document input must be sent typed `DOCUMENT`. It is proposed for promotion at the next template sync and was not promoted here.
- "sail does not follow a task link" was reproduced.

**Promoted:** none. The supplemental is unchanged, and the repo and user-level copies are identical.

## TODO changes

- **Updated (Before demo):** the ingestion reset state. #73–#75 added; 81/84/85 removed; failed draws 83 and 89; package-beat reset steps.
- **Extended:** the stranded-instances cancellation list (39011 and its child, plus the pipelines for 81 and 84).
- **Added (Browser checks owed):** the Phase 5.5 package, corroboration and Documents checklist.
- **Added (Deferred):** live "no matching line", Backup and Not read paths; the Doc Input skill and model are instance-specific.
- **Struck through:** "Backup documents on an ingested draw", now built.
- **Done:** Phase 5.5.

## BUILD_PLAN.md changes

- Phase 5.5 is marked ✅ 2026-09-25, and all four objects are ✅.
- Two open follow-ups were added: the persona-driven confirm and geometry (browser), and the untested live paths.
- Phase 6 carries the feed-arrival simulation item.

## Repo changes

- **Added:**
  - `scripts/gen_draw_package.py`;
  - `.work/sail/gen_corroboration.py`, `gen_read_supporting.py`, `gen_receive_corroboration.py` and their payload JSONs;
  - `gauntlet_SD_corroboration.sail` and the five rule `.sail` files.
- **Updated:**
  - the page, form, summary, detail and status-tag sources and generators;
  - `refs.py`;
  - `CLAUDE.md`: objects, business rule, repeatability, files;
  - `BUILD_LOG.md`, `BUILD_PLAN.md`, `TODO.md`.
- **Not committed:** the PDFs (gitignored).

# Closeout — 2026-09-25 — Phase 5.6: Doc Center classification for supporting documents, extraction on pay applications only

## Scope and identity

- **Designer:** the Dev MCP `appian`, as `scott.thorn@appian.com`. Full scope: `SD Administrators`, `SD Users` and the three draw-approval step groups. Every design change, `testRule`, `testInterface`, `listRecordData`, `listMyTasks` and `completeTask` ran under it.
- **Personas through sail:**
  - `sd.accountant` (`~/.sail-sd.accountant`, member of `SD Draw Demo Approvers`) drove the intake page and read the Draws page, the Summary and the Documents tab.
  - `sd.assetmanager` (`~/.sail-sd.assetmanager`) read the Draws page.
- **Not used:** `appian-runtime` and `--from-devmcp`.
- **Draw 66 was not touched.** Elena's task 536876873 and step process 536909994 are still open.
- **DocCenter** (`81997754-…`) was read, and its data tables were written, as a dependency. The out-of-scope client app was not read.
- **The Doc Center path needed no manual step.** The Dev MCP could create and train the classification model, so there is no click-list for Scott. Wiring in a different model later is a one-constant change: `SD_SUPPORTING_DOC_CLASSIFICATION_MODEL_KEY` / `SD_PAY_APPLICATION_EXTRACTION_MODEL_KEY`.

## The ruling (item 0)

Recorded in `PROJECT_INSTRUCTIONS.md` (Business rules), `BUILD_PLAN.md` (Phase 5.6) and `CLAUDE.md` (business rules):

- Doc Center owns identifying and reading documents.
- A classification model types every supporting document.
- Extraction runs only where an extracted figure drives a control: the pay application's Current Payment Due, tied against the template's Hard Costs line.
- Invoices and lien waivers stop at classification: typed, filed and presence-checked, never read.
- Generative AI skills are kept for language tasks: the ingestion-failure comparison now, and Phase 6's reply interpretation and narrative drafting.
- Phase 5.5's prompt-based typing was interim.

## What was built

### Training set (item 1)

`scripts/gen_training_set.py` (committed) writes the training PDFs. The files are local only; `training/` and `*.pdf` are gitignored.

| Type | Count | Variation |
|---|---|---|
| Pay applications | 8 | G702-style, 8 contractors, application numbers, periods and amounts; layouts A/B/C |
| Invoices | 8 | 8 vendors (FF&E, MEP engineering, materials testing, landscape architecture, interiors, security, signage, permits), invoice numbers, dates and totals; layouts A/B/C |
| Lien waivers | 8 | conditional and unconditional, progress and final, 8 claimants; layouts A/B/C |
| **Training total** | **24** | 87,289 bytes, plus `training/manifest.csv` |
| Junk specimen (not in the training set) | 1 | `THSV_Junk_UtilityNotice.pdf` at the repo root, 2,800 bytes: a utility's scheduled-outage notice to the hotel |

- Every file is pure ASCII (`write_pdf(..., ascii_only=True)`). The Dev MCP's `uploadDocument` corrupts bytes above 0x7F; pure-ASCII files avoided it, and 24/24 stored sizes equal the local sizes.
- The four demo PDFs are unchanged (same md5).

### Doc Center models (item 2), created on the instance over the Dev MCP

- **Classification model 7** "SD Draw Supporting Documents", key `sdDrawSupportingDocuments`:
  - Version 8, Published.
  - Categories: 31 Pay Application, 32 Invoice, 33 Lien Waiver, and 34 Other (Doc Center's own catch-all; Other → Backup, "Not classified").
  - Confidence threshold 80, no vision, single output. Instructions: decide by the document's title, parties and purpose.
- **Training:**
  - The 24 PDFs were uploaded to a new folder `SD Draw Classification Training`, labels in the descriptions.
  - They were run as labelled test instances 58–81: **24/24 correct** (8/8 per type).
  - All 24 were reconciled. Version 8 reads back correctCount 24 / instanceCount 24, accuracy 1.0 "High", 62 AI actions.
- **What "trained" means here.** The only classification type on this instance is Doc Center's **Generative AI** type. The prompt is built from the category names, the descriptions and the version's instructions. The labelled test cases measure accuracy; they do not fit weights. There is no ML-trained classification type on this instance.
- **Reconciliation was done by direct write.** Doc Center's own reconcile process takes a full instance record that the Dev MCP cannot pass. So the fields a correct, override-free reconciliation sets were written by explicit id (58–81). Self-learning is off on model 7, so no downstream step was skipped.
- **Extraction model 86** "SD Pay Application", key `sdPayApplication`:
  - Version 143, section 224.
  - Fields: 3636 contractorName, 3637 applicationNumber, 3638 currentPaymentDue (Generative AI). Instruction: "extract only values printed".

### Pipeline (item 3)

- **`SD Classify Supporting Document`** (new, `0000f073-d1d7-…`) is the per-document worker. Every node runs as the designer. For each document:
  1. Doc Center classifies it (synchronous subprocess).
  2. `SD_gateSupportingDocClassification` gates the verdict.
  3. What happens next depends on the verdict:
     - **Pay Application:** Doc Center extraction, then `SD_gatePayApplicationExtraction`, then the row is written **Classified and read** with party, application number and amount.
     - **Invoice or Lien Waiver:** **Classified only**, no figures.
     - **Other, an error, an unknown label, or a reported confidence below 80:** Backup, **Not classified**.
  - Every row gets a notes line with its treatment, seconds and AI actions (`SD_supportingDocNotes`).
- **`SD Read Supporting Documents`** is now the dispatcher. It registers each PDF ("Being classified by Doc Center") and starts one worker per document **asynchronously**, so the documents run in parallel. The 5.5 AI node, its gate and its write are removed.
- **Rules:** `SD_getSupportingDocClassification`, `SD_gateSupportingDocClassification`, `SD_getPayApplicationExtraction`, `SD_gatePayApplicationExtraction`, `SD_supportingDocNotes`.
  - Gauntlet `gauntlet_SD_classificationGates.sail`: 20/20 pass (G1–G10 classification, E1–E10 extraction).
- **Constants:** the two model keys and `SD_CLASSIFICATION_MIN_CONFIDENCE` = 80.
- **Retired:** `SD_supportingDocumentPrompt`, `SD_parseSupportingDocReading` and the constant `SD_DOCUMENT_READING_MODEL`. Nothing else used them (`getObjectDependents`). All three are deleted; each read returns 404.

### Corroboration and display (item 4)

- **`SD_corroborateDocuments` v5:**
  - Pay application tie: unchanged.
  - Invoice: "Received · filed as Invoice" (grey), no figure, no tie. The line-match logic is removed.
  - Lien waiver: "Lien waiver received". The waiver rule is unchanged.
  - Not classified: "Received · not classified" (grey, no warning).
  - Still pending: "Being classified".
  - New state **RECEIVED**, for documents with nothing to tie.
  - Gauntlet C1–C8: 8/8 pass.
- **Display:**
  - `SD_cmp_statusTag` v4: Classified and read / Classified only green; Not classified amber.
  - `SD_form_reconcileExtraction` v6: "typed by Doc Center; the pay application is read and tied out against the lines above".
  - `SD_page_receiveCapitalCall` v9: the confirmation copy.
  - `SD_view_drawSummary` v9: the green **Package received** chip.
  - The Documents tab shows each row's treatment and time/cost through the status tag and notes line; it needed no change.
- **Close-out readback:** all ten deployed expressions are identical to the repo's `.sail` files.

## Verification (item 5)

Draw 66 was not touched in any of these runs. Each package was submitted through sail as `sd.accountant`. Rows and state were read back as the designer.

Each form was rendered as the designer with the task's real inputs. The extraction was checked identical to instance 863 by a throwaway rule. Each task was then completed with `completeTask` as the designer, using the form's own serialisation.

| Package | Draw | What the terminal showed |
|---|---|---|
| **Clean** (template + pay app + invoice + waiver) | 92 → **#77** | **Rows:** Pay Application Classified and read, $2,490,296.23, Stonebridge, Application No. 14. Invoice and Lien Waiver Classified only, no figures.<br>**Form:** green **Ties**; grey **Received · filed as Invoice**; green **Lien waiver received**.<br>**Stored:** TIES, "3 supporting documents · pay application ties · invoice filed · lien waiver received".<br>**As `sd.accountant`:** green **Package ties**. The Documents tab shows the four rows with notes. While the draw was still Ingesting, the strip read "Doc Center extraction is ready for your reconciliation". |
| **Mismatch** (template + mismatch pay app) | 93 → **#78** | **Rows:** Classified and read, $2,527,796.23.<br>**Form:** amber **Does not tie: $2,527,796.23 vs $2,490,296.23** (both figures also in the grid columns); amber **No lien waiver received with the pay application**.<br>**Stored:** ATTENTION, with both figures and the no-waiver part.<br>**As `sd.accountant`:** amber **Needs attention**. |
| **With the junk PDF** (clean package + utility notice) | 94 → **#79** | **Junk row:** Backup / **Not classified**, "classified as Other … filed as Backup". Doc Center's reasoning: a service-interruption notice, "not a bill".<br>**Live pending render:** pay app grey **Being classified** with Refresh; junk grey **Received · not classified**.<br>**Settled form:** Ties / filed / received / not classified; no amber.<br>**Stored:** TIES, "4 supporting documents · … · 1 not classified".<br>**As `sd.accountant`:** green **Package ties**. The Documents tab shows 5 rows, the junk amber Not classified on its own row. Amount verification is intact; the draw moved on to step 1. |
| **Template only** | 95 → **#80** | **Confirmation:** "No supporting documents came with this package."<br>**Rows:** the template row only.<br>**Form:** the neutral line, no grid.<br>**Stored:** NONE.<br>**As `sd.accountant`:** grey **None received**. |
| **v2 failure** (v2 template + pay app + waiver) | 96 | **Supporting documents:** classified. Pay app Classified and read, $2,490,296.23; waiver Classified only.<br>**Template:** still **Ingestion Failed**, with the same two reasons as Phase 5. AI comparison 5.3 s, 4 AI actions; alert email sent.<br>No reconciliation task was issued.<br>**As `sd.accountant`:** a fourth "Not loaded" row. |

- **Draw 66, read as the designer:** step 3, step process 536909994, task 536876873, updated 2026-09-22 15:34:33.
- **Draw 66, read as `sd.assetmanager` via sail:** "Awaiting My Action 1 · Draw #66 · Asset Manager step".
- **Throwaways, all deleted:**
  - `zz_probeTraining`: 404.
  - `zz_probeAia`: 404.
  - `zz_trainSupportingDocClassifier`: "Does not exist: Process Model".

### Time and cost per document: 5.6 against 5.5's combined call

All figures are measured by the worker and printed in each row's notes line.

| | 5.5 combined AI call (type + read) | 5.6 Doc Center classification | 5.6 pay-application extraction |
|---|---|---|---|
| Seconds per document | 5.3–7.9 (AI call, n = 10) | **48.5–54.3** (n = 10) | **64.4–70.2** (n = 4) |
| AI actions per document | 2–3 | **3** (one run 4) | **3** |
| Model | Claude Sonnet 4.6 (constant) | Doc Center's default (Haiku 4.5 on this instance) | Doc Center's default |
| Clean 3-PDF package | 7 AI actions, ~25 s wall (one after another) | 9 classification + 3 extraction = **12 AI actions**, **~2 min** wall (in parallel) | |

- **Where the time goes.** Doc Center's own LLM call is short: instance 85 went from created to classified in 8 s. Most of the ~50 s is Doc Center's orchestration around a synchronous run.
- **What the added cost buys.**
  - 5.6 costs about 1.7× the AI actions of 5.5 and is several times slower per package.
  - In return, documents are typed by a governed Doc Center model with measured accuracy (24/24), not by a prompt.
  - Invoices and waivers are never read.
  - The only figure extracted is the one a control uses.
- **Timing against the task.** The reconciliation task arrives at ~80 s, before a pay application has settled (~2 min). The form shows "Being classified" with Refresh until then. This is a demo-script fact in `TODO.md`.

## Findings

- **The docs-search gate was missed.** The §5 docs-search gate was not run before this phase's four interface edits. The transcript shows this; memory did not.
  - Run afterwards, the gate confirms the hex colours are valid.
  - It also surfaced a real issue: **a tag shows at most 40 characters and truncates the rest, with the full text on hover.** Three amber tags exceed that:
    - "Does not tie: $X vs $Y" (44, Phase 5.5);
    - "No lien waiver received with the pay application" (48, Phase 5.5);
    - "Submitted as #67, already on file — renumbered to next in sequence" (66, Phase 3).
  - Truncation is browser-only, so nothing was changed. Shorter wording is proposed in the browser checklist.
- **Doc Center classification returns no confidence** on this instance (null on 30+ runs, with threshold 80). The low-confidence branch of the gate is covered by the gauntlet only. Live, only "Other", an error or an unknown label reach Backup.
- **Latency:** see the timing section above.

## Not verified

- **The accountant's own Confirm.** sail cannot open a task. Every Confirm ran as the designer, so the new template rows read "confirmed by Scott Thorn".
- **Geometry:** tag truncation, the corroboration grid in the left pane, the notes column, and the intake copy.
- **Live low-confidence, classification-error and extraction-error paths:** gauntlet only.
- **Cost in tokens or currency.** Doc Center reports AI actions only.
- **Persona document download** (S9).

## Browser checklist (Scott; details in `TODO.md` → Browser checks)

1. **Intake.** As `sd.accountant` on Receive Capital Call, attach the template plus the pay app, invoice, waiver and junk PDFs, one per slot. Click Receive and expect "4 supporting documents are being classified by Doc Center; …".
2. **Reconciliation form.** After ~2 min, open Reconcile Extraction and expect:
   - pay app green **Ties**;
   - invoice grey **Received · filed as Invoice** with "—" figures;
   - waiver green;
   - junk grey **Received · not classified**.

   Then edit Hard Costs to force the amber "Does not tie" and **check whether the 44-character chip truncates**. Check the no-waiver tag (48) with the mismatch package and the renumber chip (66) the same way. If they truncate, rule on shorter wording. Proposed: "Does not tie · off by $37,500.00", "No lien waiver received", "Renumbered from #67 (on file)".
3. **Summary:** green **Package ties**, with "… · 1 not classified".
4. **Documents tab:** five rows. Green Classified and read / Classified only, amber Not classified, each with its notes line. The notes column should wrap, not clip. Each PDF downloads.

## Rulings needed

- **Chip wording** if the browser check shows truncation (above).
- **Draws 90 (#76) and 91 are yours:** 18:15/18:31 local, confirmed by Priya Raman. Keep them or clear them at the next reset; the session will not delete them without your word.

## Promotion candidates

- **4 new, staged at gate 1:**
  - Doc Center Generative-AI classification returns no confidence;
  - ~40–45 s of Doc Center orchestration around a synchronous run;
  - reconciling Doc Center test instances by direct write;
  - pure-ASCII PDFs survive `uploadDocument`.
- **1 method candidate:** a reading gate skipped silently in a batch of edits.
- **3 triggers fired and re-staged:**
  - `tostring()` of a Decimal;
  - the `[[]]` trap, with its working form extended to `sum()` of 1/0;
  - sail not following task links.
- **None promoted.** The supplemental is unchanged; the repo and user-level copies are identical.
- The checkpoint is current through this entry.

## TODO changes

- **Added:**
  - Before demo: "Ingestion demo reset — Phase 5.6 additions" (draws 92–96; 90/91 are Scott's; Awaiting My Action 14) and "Package latency" (~50 s / ~67 s / ~2 min against a task at ~80 s).
  - Deferred: "Doc Center models per instance", "Doc Center classification reports no confidence" and "5.5-era draws keep 5.5 statuses and summaries".
- **Reworded:** the Browser check "Package intake, corroboration section and Documents tab" now has 5.6 wording and the 40-character tag checks.
- **Struck, with pointers:**
  - "Live paths of corroboration not yet exercised" (superseded by 5.6);
  - "The reading prompt and model per instance" (retired).
- **Done:** Phase 5.6 built and verified live.

## BUILD_PLAN.md changes

- Phase 5.6 is marked **BUILT 2026-09-25**, with all six object items ✅.
- Added:
  - a browser pass on the 5.6 display (40-character tags, notes column; owner Scott);
  - "Narrate or absorb the package latency" (owner the presenter).
- The Phase 5.5 follow-up "Invoice with no matching line, Backup and 'Not read' paths live" is struck as superseded.

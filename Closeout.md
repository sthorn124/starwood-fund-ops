# Closeout — 2026-09-22 — Fix session: intake confirmation state, draw-number collision handling at reconciliation

## Scope and identity

- **Designer:** Dev MCP `appian` as `scott.thorn@appian.com` — `SD Administrators`, `SD Users`, the three draw step groups. Every `testInterface`, `getProcessModel`, `getObjectSecurity`, `getSite` and `listRecordData` readback ran under it.
- **Persona, via sail:** `sd.accountant` (`~/.sail-sd.accountant`, `SD Draw Demo Approvers` → `SD Draw Approvers`) drove the intake page end to end and read the Draws page. `--from-devmcp` and `appian-runtime` never used.
- **Docs gate honoured** before the interface work: local-variable refresh semantics, file upload outside a start form (`a!submitUploadedFiles`), `a!startProcess` (Initiator, async `onSuccess`), `a!urlForSite` with `site!`, `a!safeLink(openLinkIn)`.
- **Two items, no other changes.** No throwaway objects created.

## 1. Intake confirmation

**Built.** `SD_page_receiveCapitalCall` (new interface, `…_571309`, v4) is now the `SASite` page **Receive Capital Call** (INTERFACE page; site v9; stub `receive-capital-call` preserved). Same navy header as the Draws page. **Receive** commits the upload (`a!submitUploadedFiles`) and, once the file is in `SD Draw Documents`, starts `SD Receive Capital Call` through `a!startProcess(cons!SD_RECEIVE_CAPITAL_CALL_PM, document)` — new PROCESS_MODEL constant `…_571303`. The same page then flips to the confirmation state: "Capital call received · Doc Center extraction is running on <file> · The draw appears in the Draws list immediately as a new draw (Ingesting). Reconciliation reaches the accountant in roughly 90 seconds, as the Reconcile Extraction task on that draw." with **Go to Draws** (a navy card-link through `a!urlForSite` to the Draws page, same tab — `a!buttonWidget` has no `link` keyword here) and **Receive Another** (resets). An error line covers a failed submit or start.

**Deleted.** The frozen launcher `SD Receive Capital Call (Intake Form)` (`getProcessModel` → "Does not exist") and its start form `SD_form_receiveCapitalCall` (404), after `getObjectDependents` showed nothing but the application referencing them. The frozen-launcher item is gone from `TODO.md`; the pipeline itself is unchanged (`SD Draw Approvers` already held Initiator).

**Verified as `sd.accountant` via sail.** Page loads with Receive disabled; upload → document 55289 and Receive enabled; the first Receive started the pipeline (draw **76** Ingesting, document row 6610) but the confirmation render threw — the upload field saves a *List of Document* even with `maxSelections: 1`, and `document()` rejected it. Fixed in v4 (`index(…, 1)`), re-run: upload → 55293, **Receive** → the page re-rendered to the confirmation state (all three lines, the Go to Draws url `…/subscription-agreement-analyst/page/draws`, Receive Another); **Receive Another** → the empty form; Draws page fresh → two "New draw · Ingesting · Doc Center extraction · Accountant reconciliation received Sep 22" rows (draws 76 and 77). The hidden confirmation branch was also rendered as the designer through a probe copy, restored, and read back.

## 2. Draw-number collision handling

**Ruling recorded** (`PROJECT_INSTRUCTIONS.md` Business rules): draw numbers are business data extracted from the template, never replaced silently; collisions are resolved at reconciliation.

**Built** in `SD_form_reconcileExtraction` (v3): when the extracted number already exists for the matched investment (own row excluded), the Draw Number field is prefilled with the next available number and the chip reads amber **"Submitted as #<extracted>, already on file — renumbered to next in sequence"**; when the extracted number is genuinely next, green **"Next in sequence"**. The prefill happens once (`a!refreshVariable(refreshOnReferencedVarChange: false)`) so the accountant's override survives edits to other fields; whatever is confirmed commits. Two further values of the editable field are covered in amber rather than misreported: an override back onto a used number ("#n is already on file for this investment") and a gap ("Out of sequence: last draw is #n"). The title keeps the extracted number.

**Verified by `testInterface` (designer).** Live payload, draw 74 with duplicate #67s on file: Draw Number **68**, amber renumbered chip, title "Reconcile extracted draw #67", Ties ✓, `error: null`. Control, Gateway draw 12 (only #11 on file): Draw Number 12, green "Next in sequence", `error: null`.

## Not verified (and the browser checklist)

- **Intake page in a browser** (`TODO.md`, new item): the confirmation card, Go to Draws landing on the Draws page in the same tab, Receive Another; the error line was never provoked.
- **Rebuilt reconciliation form** (existing item, chip wording updated): the amber renumbered chip with 68 prefilled while other #67s exist; typing 67 back → "#67 is already on file for this investment"; an override surviving edits to other fields; the inline viewer as the persona; geometry.
- Draws 76 and 77's pipelines were not followed to their tasks (unchanged pipeline).

## Defects found and fixed

- `a!buttonWidget(link:)` rejected ("Unrecognized Keyword — link") → card-link.
- `a!cardLayout` inside `a!sideBySideLayout` rejected — only once the hidden branch was rendered → columns layout. The probe-copy flip is what caught it.
- `a!fileUploadField` value is a list → `document()` threw on the live persona click → `index(…, 1)` before `document()` and before the process parameter.

## Rulings needed

None. Housekeeping for Scott: four ingested rows now exist beside the seed (reconciled #67s 74 and 75; Ingesting shells 76 and 77 with open reconciliation tasks) — keep one specimen, `--cleanup-ingested` the rest before a rehearsal (`TODO.md` reset note has the ids).

## Promotion candidates

5 found — no `link` on `a!buttonWidget` (the tree's `"link": null` is not settable); card rejected in a side-by-side, and only when the branch renders; upload field saves a list; submit-then-start ordering for a process that reads the file; sail drives an in-page state flip and prints it — listed at gate 1, none promoted. No trigger fired. Checkpoint current through this entry. Supplemental unchanged.

## Repo changes

`PROJECT_INSTRUCTIONS.md`, `CLAUDE.md`, `BUILD_PLAN.md`, `BUILD_LOG.md` (entry + 5 staged candidates + checkpoint), `TODO.md`, `Closeout.md`, `.work/sail/SD_page_receiveCapitalCall.sail` (new), `.work/sail/SD_form_reconcileExtraction.sail`, `.work/sail/SD_form_receiveCapitalCall.sail` (removed).

## TODO changes

Removed: the frozen intake launcher (Deferred). Added: Browser checks — the rebuilt intake page. Updated: the ingestion demo reset (four ingested rows, the shells' ids, the chip wording under the collision rule); the rebuilt-form browser check's chip strings. Done: intake confirmation state; draw-number collision handling.

## BUILD_PLAN.md changes

Phase 3: intake confirmation ✅; draw-number collision handling ✅; the rebuilt-form browser pass reworded for the collision chip; new open items — the intake page browser pass, and cleaning up the four ingested rows (was: delete one of the two #67s).

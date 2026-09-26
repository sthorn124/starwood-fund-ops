# Closeout — 2026-09-25 — Fix session: tie-out chips with wrapping off-by detail, all tags under 40 characters

## Scope and identity

- **Designer:** the Dev MCP `appian`, as `scott.thorn@appian.com`. Full scope: `SD Administrators`, `SD Users` and the three draw-approval step groups. Every render, rule test, readback and delete ran under it.
- **Persona:** sail as `sd.accountant` (`~/.sail-sd.accountant`), for the smoke check.
- **Not used:** `appian-runtime` and `--from-devmcp`.
- **Draw 66 was not touched.**
- **No data was written.** This session changed chip wording and layout only.

## Why

Scott's browser pass on the Phase 5.6 checklist passed intake, the corroboration states, junk classification, the Documents tab and downloads. It confirmed one finding: chip text truncates at 40 characters. That is the tag's documented display limit, flagged in the 5.6 close-out.

## The gate, run before any edit

- **Frontend-design guidance:** read.
- **Vendor pack:** `components/grid-field-instructions.md` says a grid cell takes one component: never a `sideBySideLayout`.
- **Docs-search:**
  - 26.6: `a!gridColumn` takes a single component.
  - The **26.9 release notes** add side-by-side layouts in read-only grid cells ("place a status tag next to a due date").
  - `MINIMIZE` suits fixed-width items; `preventWrapping` must not be used with it.
  - A tag displays at most 40 characters.
- **The instance decided:** a throwaway grid with a tag and a rich-text line side by side in one cell was accepted by the object validator and rendered by `testInterface` (`error: null`, `preventWrapping=false`). So the "off by" detail sits **beside** the chip in the same cell, as the brief wanted. The probe was deleted (404).

## Every changed tag, old → new

| Where | Old | New |
|---|---|---|
| Reconciliation verdict strip (lines vs draw amount) | "Does not tie · lines $X vs draw $Y" (red; 56 characters with this draw's figures) | **Does not tie** (amber), with amber wrapping text beneath: "lines $<sum> vs draw $<amount> · off by $<difference>". Green "Ties ✓ $X" is unchanged. |
| Corroboration Tie-out cell (pay application) | "Does not tie: $2,527,796.23 vs $2,490,296.23" (44) | **Does not tie** (amber), with amber wrapping "off by $37,500.00" beside it. Green "Ties" is unchanged. |
| Corroboration Tie-out cell (no tie target) | "No Hard Costs line to tie to" (length set by a constant) | **No line to tie to**, with detail "no Hard Costs line in the template" |
| Lien waiver line | "No lien waiver received with the pay application" (48) | **No lien waiver received** |
| Draw Number, collision | "Submitted as #67, already on file — renumbered to next in sequence" (66) | **Renumbered from #67 (on file)** |
| Draw Number, override onto a used number | "#78 is already on file for this investment" (42) | **#78 already on file** |
| Draw Number, gap | "Out of sequence: last draw is #N" / "… none on file" (up to 42) | **Out of sequence (last #N)** / **Out of sequence (none on file)** |
| Investment match | "Matches Tamarack Hotel & Spa Vail on file" (41, set by the name) | **Matches investment on file** (amber "No matching investment" is unchanged) |

- **Swept and left as they were (fixed text, ≤ 40):**
  - status tags (fixed vocabulary, longest "Extracted & Confirmed", 21);
  - the Summary's "No budget lines", "Ties ✓", "Does not tie", "Package ties", "Package received", "Needs attention", "None received";
  - "Being classified", "Figure could not be read", "Received · filed as Invoice", "Lien waiver received", "Received · not classified", "Received", "Next in sequence".
- **Figures:** figures now appear only in wrapping text or grid columns, never in a chip. The stored corroboration summary (rich text on the Summary) is unchanged.

## What changed, by object

- **`SD_corroborateDocuments` v6** (generator `gen_corroboration.py`):
  - chips carry no figures;
  - each item has a new `detail` ("off by $X");
  - the logic is unchanged.
- **Gauntlet `gauntlet_SD_corroboration.sail` (C1–C10), 10/10 pass:**
  - every case checks the detail line and fails any chip over 40 characters;
  - C9 covers "No line to tie to", and C10 pins the pre-existing no-Hard-Costs-line behaviour (below).
- **`SD_form_reconcileExtraction` v7:**
  - the new verdict chip and its wrapping line;
  - the Tie-out cell is a side-by-side of the chip (`MINIMIZE`) and its detail;
  - the four chip wordings above;
  - an unused local removed.
- **Docs:**
  - `PROJECT_INSTRUCTIONS.md`: collision-chip wording, noted as shortened.
  - `CLAUDE.md`: a new rule, "Chips never carry figures or names"; updated wording and versions; Scott's draws 97/98.
  - `TODO.md`, `BUILD_PLAN.md`, `BUILD_LOG.md`.

## Verified

`testInterface` as the designer, through a throwaway wrapper that builds the payload the way the pipeline does (`SD_getExtractionForReconcile(instanceId)`). A checker listed every rendered tag with its length.

| State | Payload | Longest tag | Figures |
|---|---|---|---|
| Clean | draw 92 (#77) | 29 | — |
| Mismatch, no waiver | draw 93 (#78) | 29 | "off by $37,500.00" beside **Does not tie**; **No lien waiver received** (23) |
| Junk package | draw 94 (#79) | 29 | "Received · not classified" (25) |
| Collision | every live payload | 29 ("Renumbered from #67 (on file)") | — |
| Non-tie | draw 92, Hard Costs set to 2,490,296.00 | 29 | verdict: "lines $2,604,252.00 vs draw $2,604,252.23 · off by $0.23"; grid: "off by $0.23" |
| Next in sequence | draw 92, number 83 | 16 | — |
| Out of sequence | draw 92, number 90 | 26 ("Out of sequence (last #82)") | — |
| Override onto a used number | probe copy with the prefill forced to 77 | 19 ("#77 already on file") | — |

- **No tag over 40 in any render.** The same checker on the pre-fix render found 66, 41, 44 and 48.
- **Close-out readback:** form v7 and rule v6 read back identical to the repo.
- **Throwaways deleted, each 404:** `zz_probeGridCell`, `zz_gauntletChips`, `zz_probeReconcileStates`, `zz_probeFormOnFile`.
- **Persona smoke check, as `sd.accountant` via sail:**
  - the Draws page loads (27 rows, Awaiting My Action 16);
  - #78's Summary renders ("current draw lines sum to $2,604,252.23", the SUPPORTING DOCUMENTS line, **Needs attention**);
  - the Documents tab statuses render;
  - the longest tag on those pages is 21 characters.

## Not verified

- **The reconciliation form as the persona.** It opens only from its task, and sail does not follow task links (reproduced in Phases 5.5 and 5.6). No draw is Ingesting now, so there is no task. The form's content is covered by the designer renders above.
- **Geometry, which is browser-only:**
  - whether "off by …" wraps cleanly beside the chip in the grid cell;
  - how the verdict's right-aligned line wraps;
  - that no tag shows an ellipsis.
- **"Out of sequence (none on file)"** was not rendered: it needs an investment with no draws on file. It is fixed text, 30 characters.

## Browser checklist (Scott; `TODO.md` → "Chip layout after the 40-character fix")

1. **Package.** As `sd.accountant`, receive the template plus the mismatch pay application. After ~2 min open **Reconcile Extraction**.
2. **Tie-out cell.** Expect the amber **Does not tie** with amber "off by $37,500.00" beside it in one cell. Check that:
   - the text wraps rather than clips;
   - the chip is not squeezed;
   - the grid still fits the left pane.
3. **Other chips.** Expect **No lien waiver received**, **Renumbered from #67 (on file)** and **Matches investment on file**, each shown in full.
4. **Verdict strip.** Set Hard Costs' Current Draw to 2490296.00 and expect:
   - the verdict strip shows the amber **Does not tie**, with "lines $2,604,252.00 vs draw $2,604,252.23 · off by $0.23" beneath it;
   - the pay application row reads "off by $37,500.23".

   Restore the value and Confirm.
5. **Laptop width (~1280 px):** no tag shows an ellipsis.

## Rulings needed

1. **A missing Hard Costs line.** Behaviour since Phase 5.5, pinned by gauntlet C10: a template with lines but no Hard Costs line ties the pay application against $0.00 ("Does not tie · off by $2,490,296.23"). "No line to tie to" appears only when there are no lines at all. Should a missing Hard Costs line read "No line to tie to"? I didn't change it, because the brief allowed no behaviour changes.
2. **One colour for a non-tie.** The verdict chip is now amber, per the brief. The pinned total's "off by" and the Summary's "Does not tie" are still red; they weren't chips in scope.
3. **Scott's draws 97 (#81) and 98 (#82)** from the browser pass. Keep them or clear them at the next reset. The next ingested draw prefills #83.

## Promotion candidates

- **2 found, staged at gate 1:**
  - a side-by-side layout in a read-only grid cell is accepted and renders here, contradicting the pack's grid-column restriction (trigger: the browser check of the Tie-out cell);
  - `joinarray` drops empty strings.
- **1 trigger fired:** the Phase 5.6 method candidate on skipped reading gates. The working form was applied (the gate ran first and changed the design); it is held at gate 1.
- **None promoted.** The supplemental is unchanged; the repo and user-level copies are identical.

## TODO changes

- **Closed (to Done):**
  - the Phase 5.6 package browser check and the persona download check (S9), both verified by Scott;
  - the chip fix.
- **Added:**
  - Browser check: "Chip layout after the 40-character fix".
  - Deferred: "A pay application ties against $0.00 when the template has lines but no Hard Costs line" and "Tie-out colours now differ by place".
- **Updated:**
  - the reset state (Scott's draws 97/98; Awaiting My Action 16);
  - the chip wording in the full-width form check.

## BUILD_PLAN.md changes

- ✅ Phase 5.6 browser pass (Scott) and ✅ the chip fix.
- Added: the chip-layout browser check and the two rulings.

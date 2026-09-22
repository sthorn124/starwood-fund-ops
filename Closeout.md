# Closeout — 2026-09-22 — Fix session: reconciliation form full width with inline document viewer, rulings recorded, persona name synced

## Scope and identity

- **Designer:** Dev MCP `appian` as `scott.thorn@appian.com` — `SD Administrators`, `SD Users`, the three draw step groups, and (relevant today) a direct member of DocCenter's `AIA All Users`, so every designer render of the inline viewer is full-scope. All `testInterface` / `testRule` / `listRecordData` / security readbacks ran under it.
- **Persona, via sail:** `sd.accountant` (`~/.sail-sd.accountant`, `SD Draw Demo Approvers`) — one Draws-page readback. `sd.assetmanager` not needed. `--from-devmcp` and `appian-runtime` never used.
- **Docs gate honoured** before the layout edit: pane layout in a form (widths, padding, forced FULL width), `a!documentViewerField` (no native Office rendering), connected-system security for component plug-ins.
- **No new features beyond the brief.** No throwaway objects created.

## Found on arrival

Scott had already run the persona browser check after the Phase 3 close-out: a second ingested #67 exists — `SD Draw` **75** (instance 850, ingestion process 536909974, step process 536909980, document 55280, document row 6609 "Doc Center extraction confirmed by **Priya Raman** 09/22/2026", approvals 6619–6627). Draw 74 still exists beside it. That is the evidence that closes the persona-submit item, and it also means two #67s coexist until one is cleaned up (see TODO).

## 1. Rulings recorded

In `PROJECT_INSTRUCTIONS.md` (Business rules, Demo narrative item 4, Open questions) and `BUILD_PLAN.md` Phase 3:
- Reconciliation stays a task, not a related action; persona-scoped verification of its submit is a browser check by design.
- Funding History = prior *approved* draws only; #65/#64/#63 on draw 67 is correct, the brief's 66/65/64 was wrong.
- General Comments stays unextracted; the field remains editable at reconciliation; re-add to model 85 only if a filled specimen appears.
- Doc Center xlsx extraction is proven on this instance; the Excel-format open question and the PDF-rendition fallback are struck (~~struck~~ with the resolution line, not deleted).
- The ingested chain starts at step 1 (Accountant); the accelerator bridges to the CEO step; "orders 1–2 pre-completed" applies to seeded draw 66; revisit only if rehearsal shows drag.

TODO items closed accordingly (Funding History and General Comments client-validation questions struck with pointers; the persona-submit browser check rewritten around the rebuilt form).

## 2. Account rename sync (Ramen → Raman)

- Readback first: `SD_getUserDisplayName("sd.accountant")` → **Priya Raman**.
- Updated by explicit id: `SD Draw Approval.approverName` on **1101, 1201, 6301, 6401, 6501, 6601, 6610, 6619**; `SD Draw Document.notes` on **6601**. Readback of all 72 approval rows: zero "Ramen".
- `scripts/seed_draw66.py` (CHAIN, DOCS row, docstring) and `CLAUDE.md` say Raman; `checks()` passes (7 OK).
- As `sd.accountant` via sail: Draws page "1 of 9 · Accountant **Priya Raman** · today" on both #67 rows; "AWAITING MY ACTION 2".

## 3. Reconciliation form rebuilt — `SD_form_reconcileExtraction` v2

Full width via one `a!paneLayout` inside the form (two `AUTO` panes, even split, dividers on):
- **Left pane:** verdict strip — "EXTRACTION instance #849 · 13 header fields · 16 budget lines", the no-per-field-confidence line, and the tie-out chip at the right (green **Ties ✓ $2,604,252.23** / red "Does not tie · lines $x vs draw $y"); "DRAW HEADER · EXTRACTED"; two columns of normal-width fields, labels above (Draw Number / Fund / Funding Date / Cash-Equity / Over Budget Reason | Investment Name / Draw Type / Draw Amount / Budget status / Submitted By); **chips on exactly two fields** — Draw Number: green "Next in sequence" / amber "Out of sequence: last draw is #n" (hidden when no investment matched); Investment Name: green "Matches <investment> on file" / amber "No matching investment"; Purpose, Budget and Contingency Explanation, General Comments as full-width paragraphs; the 16-row editable grid (right-aligned numbers, DENSE, zebra) with the pinned line "Current Draw total $x vs draw amount $y · Ties ✓ / off by ($d)" recomputing from the grid's own locals.
- **Right pane** (light grey, LESS padding): "SOURCE DOCUMENT", the xlsx name as a download link, then the workbook inline through DocCenter's `rule!AIA_UTIL_displayInlineDocument(documentId, sourceDocumentId, height: "TALL")` — the native `a!documentViewerField` cannot render Office files (docs), DocCenter's component plug-in can, and the instance already uses it.
- **Single primary button** bottom right: **Confirm & Assemble Draw**. Inputs and saves unchanged, so the process's task node still binds.
- **One security change outside the app:** `SD Draw Approvers` granted **Viewer** on DocCenter's `AIA Reconcile Connected System` (the plug-in's connected system; docs: component plug-ins need Viewer on it; `AIA All Users` holds neither persona). Readback confirms the roles; the readback also shows `inheritSecurity: true` where it read `false` before — recorded, with the one-call revert in TODO.

### Verified (as the designer)
- `testInterface` on the live payload (instance 849 / draw 74 / document 55270): `diagnostics.error: null`; every string above rendered in order, 16 rows, Ties ✓; the tree reads `formWidth: "FULL"`, both panes `showPaneDivider: true`, the viewer component present with `documentId 55270 / connectedSystem 47597`. The Draw Number chip read **"Out of sequence: last draw is #67"** — correct, because draw 75 is also #67.
- **Control render** (draw 12 of Gateway, draw number 12, amount 100 vs one line of 90): "Next in sequence" (self-exclusion and investment filter proven), "Matches Gateway Logistics Park Phase II on file" from a lower-case input, "Does not tie · lines $90.00 vs draw $100.00", "off by ($10.00)". `error: null`.
- Interface version 2 read back; connected-system role map read back.

### Not verified
- **Geometry** at common widths — the brief's "re-render checks at common widths if the tooling allows": it does not (sail carries no geometry, `testInterface` no widths). Browser check, Scott.
- **The inline viewer as `sd.accountant`** — `testInterface` runs as the designer, who is in `AIA All Users`. Browser check step 3, with the fallback symptom ("cannot be displayed … download") and the revert recipe written down.
- **The persona submit of the rebuilt form** — a task; browser check by ruling. The pre-rebuild submit is evidenced by draw 75.
- **Chip and total behaviour on live edits** — recompute proven by the control render; the interaction itself is browser-only.

## Browser checklist (Scott, before the first rehearsal) — `TODO.md` "The rebuilt full-width reconciliation form"
1. Reset per "Ingestion demo reset"; as `sd.accountant` Receive Capital Call with the template; after ~80 s Summary → **Reconcile Extraction**.
2. Full-width two-pane form; verdict strip with the green Ties chip; two-column header, labels above, no mid-word wraps; the two chips only; three full-width paragraphs; 16-row grid with the pinned total.
3. Right pane: download link and the workbook rendered inline at TALL height, no fallback link.
4. Edit Hard Costs' Current Draw to 2490296.00 → total $2,604,252.00, both tie chips red "off by ($0.23)"; restore. Type "abc" in Investment Name → amber "No matching investment", Draw Number chip disappears; restore.
5. **Confirm & Assemble Draw** → #67 · In Progress · 1 of 9 · Accountant · Priya Raman; document row "confirmed by Priya Raman".
6. Repeat at ~1280 px and phone width.

## Defects found and fixed
- `a!gridLayout` rejects `marginBelow` ("Unrecognized Keyword", `updateInterface`) — removed. Staged.

## Rulings needed
- None new. Two housekeeping items for Scott: delete one of the two #67s (74 or 75) before a demo so the Draw Number chip reads "Next in sequence"; and confirm DocCenter's owners are fine with `SD Draw Approvers` as a Viewer on their connected system (else revert and fall back to the download link).

## Promotion candidates
3 found — `a!gridLayout` `marginBelow` rejection; `updateObjectSecurity` `inheritSecurity` readback flip; DocCenter inline xlsx viewer and its Viewer requirement — listed at gate 1, none promoted. No trigger fired. Checkpoint current through this entry. Repo and user-level `appian-supplemental` unchanged.

## Repo changes
`PROJECT_INSTRUCTIONS.md`, `BUILD_PLAN.md`, `BUILD_LOG.md` (entry + 3 staged candidates + checkpoint), `TODO.md`, `CLAUDE.md` (form row with the DocCenter dependency; seed-texture name), `scripts/seed_draw66.py`, `.work/sail/SD_form_reconcileExtraction.sail`, `Closeout.md`.

## TODO changes
Closed: the Ramen/Raman item (→ Done); Funding History and General Comments client-validation questions (struck with pointers to the rulings). Rewritten: the reconciliation browser check (now the rebuilt form, six steps, persona submit evidenced); the Phase 3 geometry item; the ingestion demo reset (two #67s, cleanup for either). Added: Deferred — the connected-system Viewer grant with its revert recipe; Done — rename sync, rulings, form rebuild.

## BUILD_PLAN.md changes
Phase 3: persona submit ✅ (ruled a browser check; evidenced by draw 75), Funding History ✅ ruled, General Comments ✅ ruled, chain-at-step-1 ✅ ruled, form rebuild ✅; new open items: the browser pass on the rebuilt form, and deleting one of the two #67s before a demo.

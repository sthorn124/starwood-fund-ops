# Closeout — 2026-09-22 — Phase 2b: draw list page, tabbed draw record views, restyled approval task form, list-texture seed, monotonic decision dates, persona-verified

## Scope and identity

- **Designer:** Dev MCP `appian` as `scott.thorn@appian.com` — member of `SD Administrators`, `SD Users` and all three draw approval step groups, so every designer render is full-scope and says nothing about a persona.
- **Personas, via sail:** `sd.assetmanager` (`~/.sail-sd.assetmanager`, in `SD Draw Asset Managers`) and `sd.accountant` (`~/.sail-sd.accountant`, in `SD Draw Demo Approvers`), both in `SD Users`, both direct members of `SD Draw Approvers`. Both sessions were live all session. `--from-devmcp` was never used; `appian-runtime` was never used.
- **Preflight:** plan gate passes; Dev MCP 26.6.95 / sail 26.6.95 match the pins; skill copies identical. The site returned 500 to both personas until the security change below.
- **Docs gate honoured:** docs-search on every layout parameter in play before the first SAIL; pack references for header-content, side-by-side, columns, rich text and card choice read.

## What was built (the brief's items, in order)

0. **TODO closed:** the spec artifacts are in the Project (they stay out of GitHub by `.gitignore`).
- **Personas:** account display names checked; seed rows now carry them. `sd.accountant` is **Priya Ramen** on the account (the mockups and spec say Raman) — flagged in `TODO.md`. `sd.assetmanager` = Elena Marchetti.
1–3. **Seed texture:** investment 2 (Gateway Logistics Park Phase II), draws 63/64/65 (THSV, approved), 11 (Gateway, approved) and 12 (Gateway, In Progress at step 6, deliberately empty of lines, QIU and documents), 54 approval rows, QIU as-of 09/30/2026, `receivedDate` / `submittedBy` on draw 66, three metadata-only document rows. `scripts/seed_draw66.py` rewritten to carry it all.
4. **Monotonic decision dates** in the transition: `max(requested, previous decision + 1 day)`, activation stamped on the next row. Verified end to end: nine ascending dates 10/06 → 10/14, funding 10/15 after the last; then reset.
5. **Four record views on `SD Draw`** — Summary, Budget Detail, Approvals, Documents — against `mockups/draw-summary.html`, every figure computed from the rows (roll-ups, tie-out to the cent, PTD, contingency %, aging). Record title "Draw Funding Approval | <investment>". The Summary's action strip appears only to the current step's assignee group while a task is open, and its "Review & Approve" card links to that task.
6. **Draws page on `SASite`** (`draws`) against `mockups/draw-list.html`: four computed KPIs, filters and search, the viewer-aware grid (YOUR ACTION, highlight, awaiting-first sort). `SD Draw Approvers` added as a site viewer so both personas reach it; the intake pages' stubs were preserved. The navigation page group is a Designer step.
7. **Task form restyled** against `mockups/task-approval.html` (header, context card with record link, Approve/Reject choice cards with data-driven consequence text, comment optional/required). The step task node now passes `drawId` and `stepOrder`; the live task was cycled onto the new wiring (task 536874206, step process 536909940, is live for the Asset Managers).

Supporting objects: `SD_getDrawDetail`, `SD_getDrawListRows`, `SD_getOpenTaskId` (+ constant `SD_CURRENT_TASKS_FOR_PROCESS_REPORT_ID`), `SD_getUserDisplayName`, `SD_fmtMoney`, `SD_fmtRelativeDays`, four `SD_cmp_*` interface pieces. UUIDs and stubs are in `CLAUDE.md`.

## How it works

- `SD_getDrawDetail(drawId)` is the one read behind every view and every list row: header fields, investment and fund, routing state (`SD_getDrawState`), `viewerIsAssignee` (membership of the current step's group), `awaitingViewer` (…and an open task exists), `openTaskId`, and day counts from `today()`.
- The open task is found through the platform's own "Current Tasks for Process" system report (`a!queryProcessAnalytics`, context = the draw's `activeStepProcessId`), because a task's id is not otherwise reachable from SAIL before the task ends. The report's document id (39) is an instance constant, re-verify per instance.
- "Awaiting My Action", the YOUR ACTION tag, the row highlight and the action strip all key off `awaitingViewer`, so a draw at a step with no task issued shows nothing to act on — which is what made `sd.accountant` read 0 against Gateway #12.
- Every aging and "in N days" string is computed and clamps at 0. The seed's narrative sits in October 2026, so until then the seeded step reads "today" and the funding date "in 23 days" rather than the mockup's "2 days" / "in 12 days".

## Mockup elements not matched in SAIL, and how they were approximated

| Mockup element | Built as |
|---|---|
| Navy band with crumb, h1 and fact strip above the tabs | Appian's record header carries the h1 (title expression); a white fact-strip card (Draw #, Amount, Status chip, Funding Date + "in N days", Draw Type, Fund) sits at the top of every view, under the tabs |
| "Review & Approve" button | A linked card styled as a button (a button widget takes no link) |
| Two-tone progress bar (22.2 % + 11.1 %) | Single-tone `a!progressBarField` (approved ÷ total) plus a nine-icon stepper: ✓ green approved, ● blue in progress, ○ grey pending, ✕ red rejected |
| Row click opens the record | The Draw and Investment cells are record links |
| "Save for Later" | Not built — a task form has no draft save without a process change (`TODO.md`, Deferred) |
| Ingestion / Amount Verification badges | `a!tagField` chips: "Extracted & Confirmed" (from the document row's status), "Ties ✓" / "Does not tie" / "No budget lines" (computed) |
| Budget Summary adjustments Soft +$57,753 / Hard ($57,753) | Computed roll-up prints "—" for all three groups (the seeded reallocation nets to zero inside Soft); totals $390,196,711 and $18,693,028 (cents on three lines). The roll-up ruling wins; the mockup is unchanged; recorded in `CLAUDE.md` § Known data artifacts |
| Seeded approval rows' attribution | Rows whose source is "seed" show no source/actor line; "N/A" comments render "—" |
| Persona name "Priya Raman" | "Priya Ramen" (the account's display name; flagged) |

## Verified

**As the designer (`testInterface`, `diagnostics.error: null`):** all four views for #66 and #12, the Draws page, and the form with decision NONE and REJECT. Figures: In Approval **$11,544,252 / 2 draws**; Funded YTD 2026 **$24,928,659 / 4 draws**; Awaiting 1; order #66, #12, #65, #64, #11, #63. Summary #66 reconciles: tie-out $2,604,252.23; Budget Summary total $390,196,711 / current draw $2,604,252; contingency 6.8 % → 6.5 % over $18,693,028; funded to date $368,899,431 (94.5 %), PTD 95.2 %; Budget Detail BUDGET row equals the mockup's row for row. Gateway #12 renders all four tabs with intentional empty states. Form: header, cards and the required-comment validation on reject.

**As `sd.assetmanager` via sail:** Draws page loads; Awaiting My Action = 1 (Draw #66 · Asset Manager step); #66 carries YOUR ACTION and sorts first; #66 Summary shows the strip and the "Review & Approve" card whose stored link is `ProcessTaskLink` task **536874206** — the id the task report returns for step process 536909940; Gateway #12: no strip, no YOUR ACTION, four tabs render.

**As `sd.accountant` via sail:** page loads; Awaiting = 0 ("Nothing waiting on you"); no YOUR ACTION; #66 Summary has no strip; Budget Detail, Approvals, Documents readable; #12's four tabs render. No tab was blocked.

**Readbacks:** transition nodes 4 and 22; step node 9's ACPs and inputMap; the four views' stubs; the site's four pages (intake stubs unchanged) and role map; the probe rule's 404 after deletion; the monotonic-date run.

## Not verified (and the browser checklist)

- **Following the task link and submitting the restyled form as a persona.** sail lists a card link as `<display>` and cannot follow a task link. Checklist (Scott, as `sd.assetmanager`): Draws page → "AWAITING MY ACTION 1 · Draw #66 · Asset Manager step", #66 highlighted with YOUR ACTION and first → click #66 → strip "Your approval is pending — Asset Manager, step 3 of 9" + **Review & Approve** → the form reads "Step 3 of 9 — Asset Manager" / "Assigned to Elena Marchetti · with you since Oct 7 · funds scheduled Oct 15", cards "Advance to AM SVP (step 4 of 9)" and "Terminate this draw request" → select Reject and Submit with no comment: "A comment is required when rejecting a draw." → **do not submit**; select Approve; leave the task open.
- **Geometry** of the three pages against the mockups (one-row KPI cards, column widths, the band, the strip's button alignment) — browser only.
- **Document download links** — no files attached until Phase 3.
- **Record-level security** — none exists; both personas see every draw. Deferred with a trigger.

## Defects found and fixed this session

- **`a!forEach` returning `{}` as a filter**: a viewer with nothing awaiting saw "Awaiting My Action 6" (null placeholders counted), and a draw without budget lines errored in `wherecontains` (the empty result kept the record list's type). Fixed everywhere with guarded `index(list, wherecontains(…), {})`.
- **`text()` truncates** (…430.77 → 430): `SD_fmtMoney` rounds first.
- **`min()` over dates** printed Oct 14 for Oct 15: the next funding date is computed as a day offset from today.
- **Task-form wiring**: the live task predated `drawId` / `stepOrder`; it was rejected with a "build reset" comment (the transition stamped 10/08 11:05, per the monotonic rule), the draw reset through the two CSVs, and the launcher rerun.

## Rulings needed

1. **"Ramen" or "Raman"** for `sd.accountant` — fix the account or accept the seed.
2. **Intake pages visible to draw personas** — `SD Draw Approvers` views the whole site; add a visibility expression to the intake pages, or leave it.
3. **Whether the mockups get a pass** for the deltas above (record header/band, single-tone bar, "—" adjustments, Save for Later) — in the Project, per the mockup ruling.

## Promotion candidates

7 found, all STAGED at gate 1 with triggers (`BUILD_LOG.md` staging section): the `a!forEach`-as-filter trap (measured both directions); `text()` truncation; `min()` over dates; `updateSite` preserving stubs when existing pages are passed by uuid; the task-report route to a task id (instance-specific report id); sail not following task links; the record-link/summary-view ordering. 0 promoted; skill copies unchanged and identical. Checkpoint current through this entry.

## Repo changes

`CLAUDE.md` (build parameters moved out of the §13 template into the project table and completed; objects table; business rules; demo repeatability; artifacts; seed texture; UI files), `BUILD_PLAN.md` (Phase 2 items ✅, new open items), `BUILD_LOG.md` (entry + 7 candidates), `TODO.md`, `Closeout.md`, `scripts/seed_draw66.py`, `.work/sail/*.sail` and generators, `.work/render_text.py`, `mockups/*.html` (committed first at `0bf29c2`, unmodified).

## TODO changes

Closed: spec artifacts; persona accounts and sail logins. Added — Before demo: demo start (launch the process, wait ~10 s), the Ramen/Raman flag. Browser checks owed: task from the strip and form submit; geometry; document links. Deferred: intake pages visible to personas; page group; Save for Later; Advance-draw related action; seed dates versus the clock; record-title duplication. Updated: record-level security (personas exist; trigger is now a ruling).

## BUILD_PLAN.md changes

Phase 2: mockups, Draws page, four record views, task form restyle, site page, persona stub all ✅ 2026-09-22; "Record decision" related action struck as superseded by the action strip; "Advance draw (demo)" still open; new open items for the page group (Designer), the persona task browser check, and intake-page visibility.

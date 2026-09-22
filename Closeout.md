# Closeout — 2026-09-22 — Phase 4: new approval email layout as HTML from live draw data

## Scope and identity

- **Designer:** Dev MCP `appian` as `scott.thorn@appian.com` — `SD Administrators`, `SD Users`, the three step groups (and therefore a recipient of every step email on this instance). Every rule test, model read/update, group readback, the one process start and the record readbacks ran under it.
- **Personas:** none needed this phase — the deliverable goes to a mailbox, and the hardening only removes a false positive for administrators. `--from-devmcp` and `appian-runtime` never used.
- **Throwaways:** `zz_probeFolder` created and deleted (404 confirmed). Spec read at full resolution: `New approval email sample blacklined.pdf`; the current-format sample noted as the outgoing layout.

## 0. TODO bookkeeping

Done: the Elena browser check (task opens from #66's Summary strip; Reject without a comment is blocked; task left open) and the DocCenter-owners message about the `SD Draw Approvers` Viewer grant (no objection so far — kept as a Deferred note with the revert recipe, not an open check).

## 1–2. The email

**`SD_buildApprovalEmail(drawId, stepOrder)`** (new, `…_571551`) returns `a!map(subject, html, bytes)` built from the draw's records at send time, one layout for every step, in the sample's section order:

navy header band "DRAW FUNDING APPROVAL | <investment>" + facts line (draw #, fund, draw type, funding date, amount, budget status) → "Hello <step approver>," with the reply instruction and the red italic warning → **DRAW FUNDING DETAIL** (12 label/value rows) → **DRAW DETAIL BY BUDGET CATEGORY** (9 columns; In this Draw / All Other Budget Categories / bold BUDGET total; Current Draw column tinted) → **BUDGET SUMMARY** (Land / Soft / Hard / BUDGET, rolled up from the lines per the ruling, never from the sample) → **REMAINING CONTINGENCY** ($ and %) → **QIU DETAIL — <investment>** (ten rows, model as-of date in the header, projection, variance, notes) → **APPROVAL STATUS** (nine contiguous rows 1–9; role, approver, status chip, decision date, comments; the current row amber with "▶ n" and "◀ Current step — your approval is requested") → navy footer "Reply "Approve" or "Reject" to this email." (Phase 6 adds the interpretation.)

Constraints met: table layout, every style inline, no `<style>`, no images, no links, no classes; fonts and colour set on each inner table so the body stays lean — **44.9 KB** for the full-size draw (Gmail clips at ~102 KB). Chips are inline spans in the app's palette; navy `#16294D` bands. Values are formatted as in the app (`SD_fmtMoney`, cents on the header amount only, `0.0%`, dashes for empty); every record text is HTML-escaped. Helpers: `SD_htmlEscape`, `SD_fmtMoneyDash`, `SD_emailCells`, `SD_emailRow`; generator `.work/sail/gen_email.py`.

**Wired into `SD Draw Approval Step`:** new Map PV `email`, computed once in node 4 by the rule; node 8 "Step notification (approval email)" sends `pv!email.subject` / `pv!email.html` (`IsHTML` on). Subject: "Draw Funding Approval: Draw #n · <investment> · <amount> · Step k of 9 (<role>)".

## 3. Where each step's email goes on this instance

Recipient wiring unchanged: `To: pv!assignGroup`, the step's group (`SD_getDrawApprovalGroup`), members as read back:

| Step(s) | Group | Members (addresses as configured on the accounts) |
|---|---|---|
| 3 · Asset Manager | `SD Draw Asset Managers` | scott.thorn@appian.com, sd.assetmanager |
| 9 · CEO | `SD Draw CEO` | scott.thorn@appian.com |
| 1, 2, 4–8 · every other role | `SD Draw Demo Approvers` | scott.thorn@appian.com, sd.accountant |

So the designer's mailbox receives every step email today; the persona accounts' addresses are whatever you set on them (not readable here). The treasury notification (final approval) still goes to `SD_DRAW_TREASURY_RECIPIENT` (= the designer, placeholder). Setting the Gmail routing for the demo is the next step (TODO).

## 4. Correctness on any draw

Rendered for draw 66 / step 3 (full: 16 lines, roll-ups, contingency, 10 QIU rows, ▶ 3) and for draw 12 / step 6 (no lines, no QIU, no contingency: "No budget lines on this draw", "No QIU metrics on this draw", "No contingency line on this draw", ▶ 6). Nothing is typed in from the sample; the BUDGET figures are the app's roll-ups ($390,196,711 / $18,693,028), not the sample's printed ones — as ruled.

## 5. Live send

Draw 66 untouched (Elena's task 536876873 still open). Draw 75 (#67, ingested, step 1) was advanced one step through the transition (`APPROVE`, source `BUILD`, comment "Phase 4 approval email verification (build)") → "ADVANCED to step 2". Readbacks: `activeStepProcessId 536910004` (the step-2 process registered itself, so node 4's email evaluation succeeded), task **536877532** assigned to `SD Draw Demo Approvers` (status 0), order 1 Approved 17:28:31, order 2 In Progress. The body node 4 evaluated is saved as [.work/email/draw75_step2.html](.work/email/draw75_step2.html) (44,718 bytes; "Hello Daniel Osei,", ▶ 2 marked, order 1's comment shown) with a row dump beside it; section order checked programmatically against the sample.

## 6. Hardening

`SD_getOpenTaskId` (v2) accepts only statuses 0 Assigned / 1 Accepted. Verified on the existing data: the cancelled step 536909940 (aborted task 536874206) → **null**; the live step 536909994 → **536876873**. TODO item closed.

## Not verified (and the checklist)

- **The Send E-Mail node's own completion** — not readable over the Dev MCP or through analytics on this instance (the system report folders read empty; no process-instance read). Evidence is indirect (rule and register node ran, task issued, rule renders clean); the inbox is the proof.
- **Gmail look** — [TODO.md](TODO.md) "The Phase 4 approval email in Gmail": (1) section order; (2) the nine-column tables render as tables with right-aligned numbers and the tinted Current Draw column; (3) the current row amber with the blue In Progress chip and the ◀ marker; (4) QIU values as in the app; (5) no "[Message clipped]", no stripped styling; (6) mobile Gmail scrolls the tables. The live one: "Draw Funding Approval: Draw #67 · Tamarack Hotel & Spa Vail · $2,604,252.23 · Step 2 of 9 (Accounting Controller)", ~17:28 UTC, to scott.thorn@appian.com and sd.accountant.
- Steps 3–9 not sent this phase (same node and rule; renders cover the shape).

## Rulings needed

- **Gmail routing for the demo** — which inbox plays the CEO (and the other approvers): set the persona accounts' addresses, or add a recipient override, before Phase 6. Recorded in BUILD_PLAN Phase 4.

## Promotion candidates

2 found — a Send E-Mail node's completion is unreadable over the Dev MCP and the system report folders read empty (working form: prove by what the process wrote afterwards and by the inbox); the f-string trap when generating SAIL with doubled-quote escapes — listed at gate 1, none promoted. No trigger fired. Checkpoint current through this entry. Supplemental unchanged.

## Repo changes

`BUILD_PLAN.md`, `BUILD_LOG.md`, `TODO.md`, `CLAUDE.md`, `Closeout.md`, `.work/sail/gen_email.py`, `.work/sail/SD_buildApprovalEmail.sail`, `SD_htmlEscape.sail`, `SD_fmtMoneyDash.sail`, `SD_emailCells.sail`, `SD_emailRow.sail`, `SD_getOpenTaskId.sail`, `.work/email/` (four files).

## TODO changes

Done: the Elena browser check; the DocCenter-owners message; Phase 4 core; the `SD_getOpenTaskId` hardening (item removed from Deferred). Added: Browser checks — the Phase 4 email in Gmail (six points). Updated: the ingestion demo reset (draw 75 now at step 2; 77 is #68; 78 a shell); the connected-system grant note.

## BUILD_PLAN.md changes

Phase 4 marked CORE COMPLETE 2026-09-22: capability check, the body rule (as `SD_buildApprovalEmail`), data handling, the send node ✅; open: the Gmail check and the Gmail routing ruling.

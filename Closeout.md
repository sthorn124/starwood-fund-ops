# Closeout — 2026-09-21 — Phase 1 built and verified: data model, seeded draw #66, sequential approval process with demo accelerator

## Scope and identity

- **Designer:** Dev MCP `appian` (157 tools) as `scott.thorn@appian.com`, from the session file; a member of `SD Administrators`, `SD Users`, and (added this session) the three draw approval step groups. Every readback below ran under that account. The draw types carry no row security yet, so nothing was filtered.
- **Not used:** `appian-runtime`, sail (no persona sessions; personas deferred by ruling).
- **Preflight:** plan gate passed; DevMCP 26.6.95 and sail 26.6.95 match their pins; skill copies identical; no ritual.

## Step 0: restructure and rulings (docs)

- Interfaces moved out of Phase 1 into a new mockup-first Phase 2; ingestion is Phase 3, the email layout Phase 4, the failure path Phase 5, and the final work Phase 6. `BUILD_PLAN.md` and `PROJECT_INSTRUCTIONS.md` § Build phases agree.
- **Ruling recorded:** draw views join the existing intake site, `SASite` ("Subscription Agreement Analyst", stub `subscription-agreement-analyst`), in a new page group. The site is not an object of `Starwood Demo`, which is why the baseline showed zero sites; it was found through `getObjectDependents`.
- **Ruling recorded:** persona accounts deferred; this session verified as the designer.

## What was built (all in `Starwood Demo`, prefix `SD`; UUIDs in `CLAUDE.md`)

| Object | Notes |
|---|---|
| `SD Investment`, `SD Draw`, `SD Draw Budget Line`, `SD Draw Approval`, `SD QIU Metric`, `SD Draw Document` | Six record types in `SA Fund`'s data source. Relationships: Investment → `SA Fund` (one-way; `SA Fund` untouched), Draw → Investment (both ways), Draw → four CASCADING children. `SD Draw` gained `cashEquityNeeded` (from the email sample), `activeStepProcessId` and `treasuryNotifiedAt`; `SD Draw Approval` gained `actedBy` and `decisionSource`. |
| Seed | Investment 1 (Tamarack Hotel & Spa Vail, THSV, on fund 4); draw 66 ($2,604,252.23, PIP/Renovation, On Budget, funding 2026-10-15); 16 budget lines; 9 approval rows (orders 1–9, 1–2 Approved, 3 In Progress, 4–9 Pending); 10 QIU rows as formatted text. `scripts/seed_draw66.py` carries the data, reconciles the groups against the sample, and prints reset CSVs. |
| Groups | `SD Draw Approvers` under `SD Users`, containing `SD Draw Asset Managers`, `SD Draw CEO`, `SD Draw Demo Approvers`. The designer is a direct member of the three step groups. |
| Constants | Three GROUP constants (by name), `SD_DRAW_TREASURY_RECIPIENT` (USER, placeholder = the designer), `SD_DRAW_FINAL_APPROVAL_ORDER` (9). |
| Rules | `SD_getDrawState(drawId)` (the one routing read), `SD_getDrawApprovalGroup(role)`. |
| Interface | `SD_form_drawApprovalDecision`: minimal task form, **Phase 2 restyle target**. |
| Processes | `SD Apply Draw Approval Decision` (the single transition, 28 nodes), `SD Draw Approval Step` (task + sync call to the transition), `SD Draw Approval Process` (launcher), `SD Advance Draw to CEO Step (Demo Accelerator)`. |

## How it works

- **One transition for every channel.** Task, accelerator and (Phase 6) email all call `SD Apply Draw Approval Decision` with the draw, the step, the decision, and a `source`. It guards against stale decisions, cancels a superseded open step task, writes the step row, then rejects, advances (activating the next row and starting its task), or on order 9 approves the draw and sends the treasury notification. Every business write is its own Write Records node with `ErrorOccurred` wired and downstream nodes gated on it. An inbound-email receiver later needs only to call it with `source: "EMAIL"`.
- **Step tasks** are assigned by role: Asset Manager and CEO to their groups, every other role to the catch-all. Each step process registers its own process id on the draw so an external decision can cancel it.
- **The accelerator** approves from the current step to order 9 one transition at a time (no next task started, ceiling 9), then starts the CEO task through the launcher. About 12 seconds per step on this instance.
- **Placeholder notifications** (plain text in HTML) at each step and at final approval; the real layout is Phase 4.

## Verified, as the designer

Pass conditions were written in `BUILD_PLAN.md` before the run.
1. Launcher on draw 66 → `STARTED step 3`; draw's `activeStepProcessId` = the step process; task "Approve or reject draw" listed.
2. `completeTask(APPROVE)` → row 3 Approved (actor, source TASK); draw at step 4; row 4 In Progress; new step process registered.
3. Accelerator → rows 4–8 Approved (source ACCELERATOR, ~12 s apart); draw at step 9; row 9 In Progress; the step-4 task cancelled (task total unchanged); CEO task open.
4. `completeTask(APPROVE)` on the CEO task → draw Approved, all nine rows Approved, `treasuryNotifiedAt` set, which proves the notification node completed without an exception.
5. Reset via the script's CSVs → seeded state read back.
6. **Break-test:** fresh run, `completeTask(REJECT)` → draw Rejected at step 3, row 3 Rejected with attribution, rows 4–9 untouched, no notification, no task opened.
7. Reset again → seeded state; no draw task open (task total back to the pre-existing 52).

Also: the transition returned `STALE` and wrote nothing when asked to decide step 5 at step 3; both rules tested against the seed; the form renders with `error: null`; every record type, relationship and group read back.

## Not verified

- **Email delivery** to any inbox (the nodes completed; the mailbox is a browser check).
- **Step notification emails** on the parallel branch: not observed.
- **`errorAlertGroupUuid` persistence:** `getProcessModel` exposes no alert-group field; Designer check owed.
- **Column widths over 255** through the production write path (readbacks say `VARCHAR(255)` for every TEXT column; a 289-character insert succeeded).
- **Persona behaviour and record-level security:** deferred with the persona accounts.
- **The race** between a just-started step process and an immediately following accelerator run: not exercised.

## Browser checklist (owner: Scott)

- Inbox `scott.thorn@appian.com`: expect `[Placeholder] Draw #66 approved - execute cash payment` (2026-09-22 02:05 UTC) and the step notifications for steps 3 and 9.
- Designer: each of the four process models → Properties → Alerts shows `SD Administrators`.
- Designer: start the launcher on draw 66 after a reset, open the task, check the title, summary, radio and comment; reject without a comment and expect the required message; reset.

## Rulings needed

- Budget Summary figures: reproduce the sample as printed, or the roll-up of the detail lines?
- Accelerator decision dates: all "now" (default), or spread by N days per step (`dayOffsetPerStep`)?

## Findings and promotion

7 candidates found, all STAGED at gate 1 with triggers (`BUILD_LOG.md` staging): width readbacks under-report at create; `addGroupMembers` works on 26.6.95 (the boundaries doc is updated); subprocess output mapping of the child's parameter PVs; `completeTask` input shape; the client ReadTimeout on ~60 s runs; empty CSV cells clear values; the alert group is unreadable over MCP. 0 promoted. Checkpoint current through this entry.

Departures from the plan, logged: 16 budget lines, not 17 (the sample has 16); no reverse relationship on `SA Fund` (an intake object left untouched); display labels with `/`, `?` or `(` were rewritten by the platform on save (Phase 2 sets labels).

## Repo changes

`CLAUDE.md` (build parameters filled: groups and site stub; a draw approval project section with UUIDs, rules as built, the reset procedure and known data artifacts), `BUILD_PLAN.md` (restructured; Phase 1 items ✅), `PROJECT_INSTRUCTIONS.md` (build phases, two resolved questions), `BUILD_LOG.md`, `TODO.md`, `reference/mcp-capability-boundaries.md` (group writes measured), `scripts/seed_draw66.py`, `.work/sail/*.sail` and `.work/pm/*.py` (the sources sent to the instance).

## TODO changes

- **Added, Before demo:** accelerator timing; the demo reset procedure.
- **Added, Browser checks owed:** the treasury email, the step emails, the process alert groups, the task form render and validation.
- **Added, Client validation:** the Budget Summary artifact; accelerator decision dates.
- **Added, Deferred:** column widths through the production path; record-level security on the draw types.
- **Updated:** the `errorAlertGroupUuid` item (unmeasurable over MCP; moved to Designer); the supplemental §3 correction now also covers membership writes.
- **Done:** Phase 1 core.

## BUILD_PLAN.md changes

Phases renumbered 1–6 with the new Phase 2. Phase 1: 20 items ✅ 2026-09-21; record-level security stays open with its trigger. Next session: Phase 2, mockups first.

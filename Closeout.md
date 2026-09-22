# Closeout — 2026-09-22 — Fix session: current approver action renders on the draw summary (draw 66, step 3)

## Scope and identity

- **Designer:** Dev MCP `appian` as `scott.thorn@appian.com` — `SD Administrators`, `SD Users`, the three step groups; a direct member of `SD Draw Asset Managers` beside `sd.assetmanager` (group readback). Every rule test, task listing, security/model read, record read and the one process start ran under it.
- **Personas, via sail:** `sd.assetmanager` (`~/.sail-sd.assetmanager`) and `sd.accountant` (`~/.sail-sd.accountant`). `--from-devmcp` and `appian-runtime` never used.
- **One defect, no other changes.** One throwaway rule `zz_probeStepTask` was created to read the task report's full row and deleted (404 confirmed). No design object was modified.

## Symptom, reproduced first

As `sd.assetmanager` via sail: Draws page "AWAITING MY ACTION 0 · Nothing waiting on you", #66 listed without YOUR ACTION; #66 Summary shows the step card ("Step 3 of 9 · Asset Manager · Elena Marchetti") and no strip, no Review & Approve, no `ProcessTaskLink` in the stored YAML.

## Diagnosis, in the brief's order

1. **Live step process and open task?** Draw 66 read `In Progress`, `currentStep 3`, `activeStepProcessId 536909940`. `SD_getOpenTaskId(536909940)` returned task 536874206 — a row came back, so the lookup "found a task". The probe read that row in full: **Status 7 = Aborted** (the docs' task-status list, 0-based), **Assignees = []**, Owner null. The designer's own task list (58 tasks) did not contain 536874206 although it listed every other live "Approve or reject draw" task. **Root cause: the step process behind draw 66 had been cancelled** (the Process Monitoring sweep — the TODO's cancel list included the `testProcessModel` launcher run 536909956 that started this step process), so there was no live task for step 3 and nothing for the Summary to link. Found at step 1; steps 2 and 3 were not needed:
   - the assignment is right — `SD Draw Asset Managers` holds `sd.assetmanager` (and the designer), and the step model's Viewer is `SD Users`;
   - the lookup is right — it does find the step's task; the task was dead.
   - **Why the designer and the persona disagreed:** the designer's `SD_getDrawDetail(66)` read `awaitingViewer: true` on the aborted task (the report hands it to a full-scope reader), while the persona, who cannot see an unassigned aborted task, correctly got nothing. A §4 identity trap on a task report: recorded as a promotion candidate and as a hardening TODO (`SD_getOpenTaskId` should accept status 0/1 only) — deliberately not changed in this session.

2. **Fix.** `activeStepProcessId` on `SD Draw` 66 cleared by CSV (`id,activeStepProcessId` / `66,`) because the launcher's `canStart` refuses while it is set; **no approval row touched**. `SD Draw Approval Process` started with `drawId 66` → `COMPLETED`, "STARTED step 3 of draw 66 (step process **536909994**)"; the launcher's own state readback shows orders 1–2 Approved with their dates (10/06 15:20, 10/07 11:05) and order 3 In Progress, unchanged.

## Verified

- **Designer:** `SD_getDrawDetail(66)` → `activeStepProcessId 536909994` (written by the step process itself), `openTaskId 536876873`, `awaitingViewer true`, approvals unchanged. The task report's row for 536909994: task **536876873**, status **0 Assigned**, assignees **[1528] = SD Draw Asset Managers**. `listMyTasks` now 59, including 536876873 ("Approve or reject draw", SD Draw Approval Step 11:34 AM EDT).
- **As `sd.assetmanager` via sail:** Draws page (fresh) "AWAITING MY ACTION 1 · Draw #66 · Asset Manager step · today", "#66 YOUR ACTION"; #66 Summary: "Your approval is pending — Asset Manager, step 3 of 9 · With you since Oct 7 · funds scheduled in 23 days" and **Review & Approve**; the stored YAML carries the `ProcessTaskLink` with `task.id 536876873`, site stub `subscription-agreement-analyst`, page `draws`.
- **As `sd.accountant` via sail:** #66 Summary shows the step card only — no strip, zero `ProcessTaskLink` (not her step). Her Draws page still reads "AWAITING MY ACTION 5 · New draw (ingesting) · Accountant reconciliation": the reconciliation path is untouched and unchanged.
- Probe rule deleted; `getExpressionRule` → 404.

## Not verified

- The persona's click on Review & Approve — sail cannot follow a task link; the existing browser check ("Task opens from the Summary action strip…") covers it, and its task is now 536876873.
- Process Monitoring's view of 536909940 (the Dev MCP has no process-instance read); the Aborted status and empty assignee list are the evidence.
- Found on arrival, left as found: Scott's intake runs continue — draw 77 was reconciled as **#68** by the collision rule (as designed), draw 78 is a new Ingesting shell.

## Rulings needed

None. One caution for the Process Monitoring cleanup: `SD Draw Approval Step` 536909994 and its parent run 536909993 are draw 66's live task — the TODO cancel list is annotated so they are not swept.

## Promotion candidates

2 found — the "Current Tasks for Process" report returns an aborted task to an administrator (status 7, no assignees) and nothing to a group member, so a "row came back" lookup reads differently by identity; the designer's `listMyTasks` as a stand-in for a persona's task list when the designer is in the assignee group — listed at gate 1, none promoted. No trigger fired. Checkpoint current through this entry. Supplemental unchanged.

## Repo changes

`BUILD_LOG.md` (entry + 2 staged candidates + checkpoint), `TODO.md`, `BUILD_PLAN.md`, `CLAUDE.md` (demo-repeatability note on a cancelled step process), `Closeout.md`. No SAIL files changed.

## TODO changes

Updated: Demo start (the live task is now 536876873 / step process 536909994; do not cancel step instances behind a live draw); the Process Monitoring cancel list (536909956 annotated; 536909993/536909994 protected). Added: Deferred — harden `SD_getOpenTaskId` to status 0/1. Done: draw 66's approver action restored.

## BUILD_PLAN.md changes

Phase 3: one ✅ line for the approver-action fix (root cause a cancelled step process, not the lookup; hardening parked).

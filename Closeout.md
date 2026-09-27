# Closeout — 2026-09-27 — Fix session: stage-for-approval and optional cleanup buttons; runbook without resets

## Scope and identity

- **Build identity.** All build work ran as `scott.thorn@appian.com` through the Dev MCP (`appian`): rule tests, process runs, task completions and renders. That account is a member of `SD Administrators`, `SD Users` and the three draw approval step groups. Every designer read is full scope and proves nothing about a persona.
- **Persona checks** ran through sail against `subscription-agreement-analyst`:
  - `~/.sail-sd.accountant` as `sd.accountant` (Priya Raman; `SD Draw Demo Approvers`).
  - `~/.sail-sd.assetmanager` as `sd.assetmanager` (Elena Marchetti; `SD Draw Asset Managers`).
  - Identity was confirmed by what each page showed: each persona sees its own YOUR ACTION rows, and neither sees the administrators' card.
- **Not used:** the runtime connector and `--from-devmcp`.
- **Constraint held:** no resets, no scripts, and no chain changed except the draws this session created or staged. Draw 66 was not touched.

## Rulings recorded (brief item 0)

These are in `PROJECT_INSTRUCTIONS.md` ("Demo order and demo prep, ruled 2026-09-27"), the `TODO.md` runbook, and the `CLAUDE.md` business rules.

- Ingested chains start at step 1 as built; the 2026-09-22 ruling stands.
- Demo prep is clickable only. The staging card stages what the beats need. Nothing is reset, reused or cleaned by requirement.
- Draw 66 stays on the list as seeded history, and no beat requires it.
- Success comes before failure. This supersedes the Phase 0 beat order.
- Twilio stays STAGED.
- The intake pages stay visible to the draw personas.

## What changed, by object

All objects are in `Starwood Demo`; `listApplicationObjects` confirms every one.

- **Constants.**
  - `SD_SEED_DRAW_IDS` = {11, 12, 63, 64, 65, 66}.
  - `SD_DEMO_KEEP_DRAW_IDS` = {78, 79, 86, 87, 92, 93, 94, 95, 96}. These are:

    | Draw | Specimen |
    |---|---|
    | #69 | treasury |
    | #70 | open email-reply exception |
    | #73 | your Gmail Q&A |
    | #74 | Asset Manager edit |
    | #77 | approved by email |
    | #78 | mismatch, rejected by email |
    | #79 | junk PDF |
    | #80 | full conversation |
    | draw 96 | the kept failed ingest |

  - `SD_STAGE_FOR_APPROVAL_PM` and `SD_CLEAN_UP_OLD_RUNS_PM`.
- **Rules.**
  - `SD_isStageForApprovalEligible` (v2).
  - `SD_getStageForApprovalCandidates`.
  - `SD_getCleanupCandidates`.
  - `SD_planCleanup`.
  - `SD_cleanupRecords`.
  - Generator: `.work/sail/gen_demo_prep.py`.
- **Demo accelerator** (`SD Advance Draw to CEO Step`).
  - Adds `stopAtStep` (default: the CEO step) and `attribution` (default: ACCELERATOR).
  - With SEED, each decision is recorded as the chain's named approver, with source SEED and comment "N/A".
  - Its default behaviour is unchanged, verified below.
- **`SD Stage Draw for Approval`** (new, 8 nodes, all run as the designer).
  - Re-checks eligibility.
  - Runs the accelerator synchronously with `stopAtStep` 3 and SEED attribution.
  - Reads the result back and reports "STAGED: …" or "REFUSED: … Nothing was written."
- **`SD Clean Up Old Runs`** (new, 24 nodes, all run as the designer).
  - Plans the run.
  - Cancels the processes that still hold tasks.
  - Deletes children first, one guarded Delete Records node per type: events, messages, documents, QIU, approvals, lines.
  - Deletes the draws only if every child delete succeeded.
  - Writes a report.
  - **Fixed this session:** node 7 no longer counts an already-closed process as cancelled, and the report now reads "Cancelled N open processes; K had already closed".
- **Security.** Both new models are admin-only: administrator `SD Administrators`; the inherited `SD Users` viewer was removed.
- **`SD_page_draws` v12.** The **DEMO STAGING · ADMINISTRATORS ONLY** card has three rows:
  1. **The feed arrives** — Stage Corrected Package first, then Stage Malformed Template.
  2. **Stage for approval** — a picker of eligible draws (default: the newest), the button, a result line, and a "Check now" link.
  3. **Clean up old runs** — marked optional ("removes accumulated ingested draws; the demo does not require it"), with a two-click confirm, a red list of what will go, and the report.
- **Docs.**
  - The runbook in `TODO.md` is rewritten: specimen plus live, success before failure, beats 0–7.
  - Every reset, message-row deletion and cleanup-as-requirement instruction is struck.
  - Browser checks 6 and 7 are re-aimed.
  - `CLAUDE.md`, `BUILD_PLAN.md` and `BUILD_LOG.md` are updated.

## How it works now (the runbook, short form)

- **Beat 0, before the demo.**
  - Read back `SD_ESCALATION_TEST_MINUTES` = 0 and `SD_SMS_MODE` = STAGED.
  - As the designer: Draws → staging card → **Stage for Approval**. The picker defaults to the newest eligible draw; today the only one is **#81 (draw 101)**.
  - About 45 s later the line confirms "step 3 of 9 · Asset Manager (Elena Marchetti) · the task is live for SD Draw Asset Managers". That draw carries beats 4–7.
- **Beat 1.** **Stage Corrected Package**, live.
- **Beat 2.** `sd.accountant` reconciles and confirms, ending at step 1.
  - **Draw Number:** with no #67 on file now, the field keeps 67 with an amber "Out of sequence (last #80)" chip. Type 81 and the chip turns green "Next in sequence".
- **Beat 3.** **Stage Malformed Template**, live: the "Not loaded" row and the Gmail alert with the AI comparison. Show the mismatch from specimen #78, or stage it live.
- **Beat 4.** QIU and the chain on the staged draw.
- **Beat 5.** Elena's edit-and-approve on the staged draw.
- **Beat 6.** The accelerator, then the CEO's Gmail reply.
- **Beat 7.** Treasury.
- **Asides:** #78 mismatch, the failed ingest (draw 96), the #80 conversation, the #70 exception, the #12 guardrail.
- **Clean Up Old Runs** is optional at any time.

## Verified

All checks ran as the designer unless stated otherwise.

**Guards.** Stage for Approval refused three draws, each with "REFUSED: … Nothing was written":
- draw 66 (seeded);
- draw 87 (keep list, step 4);
- draw 75 (step 2, no open task). This refusal was re-tested after the eligibility fix below.

**Staging #82 (draw 98).**
- **Timing and chain.** Staged in 46.8 s:
  - Orders 1–2 were approved as Priya Raman and Daniel Osei, source SEED, a day apart (09/27 and 09/28).
  - Order 3 went In Progress, and a fresh task (7602) was issued from the current step model.
- **As `sd.assetmanager` via sail:**
  - The Draws page showed YOUR ACTION on #66 and #82, with no staging card.
  - #82's Summary read "Your approval is pending — Asset Manager, step 3 of 9", with **Review & Approve**.
- **The task form** rendered WIDE with the editable grid: `error: null`, 33 editable fields, "Ties ✓".

**Edit and approve.** Task 7602 was completed with two edits:
- A&E - Architectural adjustment: 21,000 → 31,000.
- Contingency: (57,753) → (67,753).
- Net adjustment stayed $0.
- Two line events were written.
- The draw moved to step 4.
- The comment says the designer acted for the step.

**Accelerator (defaults) to the CEO step.**
- The CEO step email was logged (row 57).
- Its status table rendered as:
  - 1–2 approved, "N/A";
  - 3 approved with the edit comment;
  - 4–8 "Approved via demo accelerator";
  - 9 "◀ Current step".
- The edits carried downstream: A&E $31,000, contingency ($67,753).

**Card states.** The designer render of v12 returned `error: null`. The hidden confirm and done states were checked on `zz` probe copies (both `error: null`); the probes were deleted and their absence confirmed.

**Clean Up Old Runs, against the pile of 14 draws** (74–77, 80, 83, 88–91, 97–100).
- The report matched the plan exactly: 2 events, 7 messages, 28 documents, 90 QIU, 81 approvals, 144 lines, 14 draws, "No errors".
- Absence was read back:
  - `SD Draw` holds only the seeds, the keep list and #81.
  - The approval and document tables hold only rows of those draws.
  - The cancelled tasks are gone from the designer's list.
- One inaccurate line was found and fixed: the report said "Cancelled 15" when 9 were cancelled and 6 had already closed.
- **Re-verified after the fix** on a throwaway intake (draw 102, uploaded via sail as `sd.accountant`, with its reconciliation task open). Report: "REMOVED 1 of 1 draws … 1 documents … Cancelled 1 open process. No errors." Draw 102 and its document row were read back absent.

**Regressions.**
- **Failure path unchanged.** Draw 100, the v2 template uploaded via sail as `sd.accountant`:
  - went to Ingestion Failed with the plain-English reason;
  - carried an AI comparison ("Compared with … Draw #82 … by AI (Claude Sonnet 4.6)");
  - its template row notes "alert email sent".
- **Clean template-only intake still lands at step 1.** Draw 101, uploaded via sail as `sd.accountant`:
  - its reconciliation task opened at about 80 s;
  - it was confirmed as #81;
  - it reads In Progress at step 1 with a 9-row chain and a live task.

**Final Draws page via sail.**

| | `sd.accountant` | `sd.assetmanager` |
|---|---|---|
| Rows | 16 | 16 |
| Awaiting My Action | 3 (#81 Accountant step, #74, #70) | 1 (#66) |
| "Not loaded" rows | one (draw 96) | one (draw 96) |
| Staging card | absent | absent |

## Not verified, and why

- **The card's own clicks.** All four buttons start processes from the page. The designer render cannot click them, the personas cannot see the card, and driving sail as the designer would need `--from-devmcp`, which is barred for routine checks. The processes themselves were verified directly. Browser check 7 covers the clicks, including whether the cleanup report reaches the page after the synchronous start.
- **The persona's own Asset Manager submit.** sail cannot open tasks. Browser check 6 covers it, on #81 once staged.
- **Geometry:** the card, the picker and the red confirm line.
- **The CEO step email for #82 in Gmail.** It was rendered and logged, and draw 98 was removed afterwards.
- **Brief item 5 (the escalation ladder firing by itself). Skipped.** `TODO.md` "Designer setup owed" B, C and D are not marked done, so the ladder stays owed with its recipe.

## Browser checklist (for Scott)

1. **Beat 0 dry run, as the designer.**
   - Draws → staging card → the picker shows "#81 · step 1 of 9 · Accountant · received Sep 27" → **Stage for Approval**.
   - Within about a minute the line reads "Draw #81 is staged for approval: step 3 of 9 · Asset Manager (Elena Marchetti) · the task is live for SD Draw Asset Managers".
2. **Browser check 6, as `sd.assetmanager`.**
   - Open #81 → **Review & Approve** → the WIDE form with the editable grid.
   - Move $10,000 from All Project Contingency to A&E - Architectural → **Approve**.
   - Budget Detail should read "Edited by Elena Marchetti at approval, <date>" on both lines, with a Line History.
3. **Browser check 7, the staging card dry run.**
   - Check the layout: three rows, buttons right-aligned, text wrapping; stacked on a phone.
   - Stage Corrected Package → Ingesting row → reconciliation task for `sd.accountant` after about 80 s.
   - Stage Malformed Template → "Not loaded" and the Gmail alert.
   - **Clean Up Old Runs…** → red confirm line → **Delete N Draws** → the report. Run it only after a staging run has added a spare draw, or cancel at the confirm step; today the only candidate is #81, which beat 0 needs.

## Flagged for you

- **Your browser-pass draws are gone.** Draws **90 (#76), 91, 97 (#81) and 98 (#82)** were in the pile Clean Up Old Runs removed. The superseded Phase 5.6 reset note in `TODO.md` said those four are "not deleted without Scott's word". I took the brief's item 4 ("run Clean Up Old Runs against the pile") as that word. The deletes cannot be undone. The keep list still holds a specimen of each kind they illustrated: junk PDF #79, mismatch #78, clean #77.
- **Beat 2's draw-number chip changed.** The cleanup removed every #67 on file (draws 74 and 75), so the corrected package's #67 now reads amber "Out of sequence (last #80)" instead of "Renumbered from #67 (on file)". The runbook says to type the next number. If you want the "Renumbered" story on stage, one confirmed #67 has to stay on file.

## Rulings needed

1. **Beat 2 story.** Either accept "Out of sequence → type the next number", or keep a confirmed #67 on file for the "Renumbered" chip. The recommendation is to accept: it needs nothing kept.
2. **Keep list.** Confirm the nine specimens above. Changing the list is a one-constant edit.

## Promotion candidates

3 found; 0 promoted; 3 staged, each with a trigger in the `BUILD_LOG.md` staging section:
- **Viewer-aware rule fields inside a process.** `openTaskId` read null in-process, so the eligibility check refused every draw until it called the lookup itself.
- **Delete Records over the Dev MCP.** The hidden `Version` input was auto-set to 6; the counts matched the plan and were proven by absence.
- **Cancel Process `alreadyClosed` on 6 of 15 listed processes.** Cause not isolated. The likely reading is that cancelling a pipeline took its descendant step process with it.

One earlier trigger was ruled. The task-version candidate fired on a substitute: a fresh task from the current model wrote the edits. It is held at gate 1.

Checkpoint: current through this entry.

## TODO changes

- **Added:**
  - Deferred: `SD_planCleanup` lists nonexistent ids as refused.
  - Deferred: three stale constant descriptions.
  - Done: this session.
- **Updated:**
  - The runbook's beat 2 now covers the draw-number chip.
  - The ladder-verification recipe now uses a spare staged draw instead of the deleted #75.
  - The stranded-instances item: 15 processes were handled by the cleanup; tasks 9464 and 536885220 remain a Process Monitoring job.
  - Browser checks 6 and 7 now use #81 and describe the report wording.
- **Unchanged:** Designer setup B–D stays owed.

## BUILD_PLAN.md changes

- **Phase 6c.** Stage for Approval, Clean Up Old Runs and the runbook without resets are marked ✅ 2026-09-27.
- **Polish item.** The reset action and the verify-ready check are struck by ruling. The rehearsal stays open.
- **Feed-arrival item.** Its beat mapping now reads corrected package = beat 1, malformed template = beat 3.

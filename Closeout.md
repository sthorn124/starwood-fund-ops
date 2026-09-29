# Closeout — 2026-09-29 — Quick session: keep list cut to pocket specimens, cleanup re-run

## Scope and identity

- **Constant change, cleanup run and readbacks:** the Dev MCP as `scott.thorn@appian.com` (full scope).
- **Persona reads:** sail as `sd.accountant` and as `sd.assetmanager`.
- **Runtime connector:** not called.
- **Preflight:** this morning's stands (same day).

## What changed

- **The keep list:** `SD_DEMO_KEEP_DRAW_IDS` went from nine draws to **{79, 93}**:
  - **#70 = draw 79,** the second-vague reply thread at the CEO step;
  - **#78 = draw 93,** the mismatch package rejected at step 9.
  - The seeds (#11, #12, #63–#66) stay excluded automatically.
  - The read-back is numbers on an INTEGER constant (v2).
- **Recorded:**
  - in `PROJECT_INSTRUCTIONS.md`: the keep list is pocket-only; everything else a demo needs is produced live or by a staging button;
  - in `CLAUDE.md`: the same;
  - in the runbook: fallbacks that named removed specimens now point to a live run or a staging button.

## What I found first

- **Draws 97–114 were already gone.** A cleanup under the old keep list had run since my last session; I assume it was the staging card's button.
- **Three new Ingesting shells, 115–117,** had been staged at 8:45–8:46 AM (malformed, mismatch, corrected), one or two minutes before I read the list.
- **I waited for them to settle before deleting** (115 failed; 116 and 117 reached their reconciliation tasks; every supporting PDF was classified or read). This did two things:
  - no background classification could write a row back after its delete;
  - the two pipelines' processes were cancelled by the cleanup, which cancels only processes holding a task.

## The cleanup

`SD Clean Up Old Runs`, run directly with the explicit list **78, 86, 87, 92, 94, 95, 96, 115, 116, 117**. Those are #69, #73, #74, #77, #79, #80, the Sep 25 failed ingest (96), and the three shells from this morning.

| Removed | Count |
|---|---|
| Draws | 10 of 10 |
| Budget lines | 96 |
| Approval rows | 54 |
| QIU rows | 60 |
| Documents | 27 |
| Email messages | 28 |
| Budget-line events | 4 |
| Processes cancelled | 3 (1 more had already closed) |

It took 23 seconds with no errors.

The stuck pipeline instances from the build (draws 67–73's, in TODO) are outside the cleanup, and no tool here can cancel them. They stay a Process Monitoring job.

## Verified

- **By absence (designer, full scope):** no cleanup candidates remain. Every child table (budget lines, approvals, QIU, documents, email messages, line events) holds rows only for the seeds, #70 and #78; the line-event table is empty.
- **As `sd.accountant` via sail:**
  - **the list is exactly #66, #12, #70, #78, #65, #64, #11, #63;**
  - Awaiting My Action is **0**, with no YOUR ACTION rows;
  - #12's Current Step reads "Robert Chen · 10 days" then **Question waiting**;
  - **Needs chasing (2):** #12 "Step 6 waiting 10 days · Text staged, not sent Sep 28, 6:46 PM" and #70 "Reminder sent Sep 26".
- **As `sd.assetmanager` via sail:** the same eight rows, and no tag on #12 (the tag is for the draw approval team only, as built). But see the ruling below.

## Not as the brief expected

- **"No YOUR ACTION rows for any persona" does not hold for `sd.assetmanager`.** They see **#66 YOUR ACTION** (Awaiting My Action 1). That's seeded #66's live step-3 task, and seeds are outside the cleanup. I left it alone:
  - completing the task would change the seeded chain;
  - cancelling its step process is ruled out in `CLAUDE.md`.

## Rulings needed

- **#66's live Asset Manager task:** complete it (approve or reject), or accept it as list history? `TODO.md`, Before demo.
- **Still open:** #12's pending question (you clear it by answering).
- **Closed as moot:** #84's stored date (the draw no longer exists).

## Promotion candidates

- **0 found.** None promoted.
- **Checkpoint:** current through this session's entry.

## TODO changes

- **Added, Before demo:** the #66 ruling.
- **Added, Browser checks:** a note that checks naming removed draws run on the next live draw.
- **Closed:**
  - the #84 ruling (moot);
  - #84's date check (moved to the next rehearsal draw).
- **Rewritten:** the tag check now names #12 alone; the runbook fallbacks.
- **Done:** this session.

## BUILD_PLAN.md changes

- ✅ 2026-09-29 Keep list cut to pocket specimens, and the list cleaned.

## Commit

"fix: keep list cut to pocket specimens". Pushed to `origin/main`, then verified that HEAD equals `origin/main` and the tree is clean.

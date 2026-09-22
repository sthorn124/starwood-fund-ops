# Closeout — 2026-09-21 — Phase 2a: browser checks recorded, rulings applied, widths and race verified, accelerator dates spread

## Scope and identity

- **Designer:** Dev MCP `appian` as `scott.thorn@appian.com` (session file), a member of `SD Administrators`, `SD Users` and the three draw approval step groups. Every readback below ran under that account. The draw types carry no row security, so nothing was filtered.
- **Not used:** `appian-runtime`, sail (no persona sessions).
- **Preflight:** plan gate passes; DevMCP 26.6.95 and sail 26.6.95 match their pins; skill copies identical.
- **No interfaces, no mockups**, per the brief.

## Browser checks, run by Scott, now recorded

- **Outbound email works on this instance.** The treasury placeholder and the step notification emails arrived in the designer's inbox.
- **`errorAlertGroupUuid` persists.** All four process models show `SD Administrators` under Properties → Alerts. The Dev MCP still cannot read it back; that gap stays recorded.
- **The task form renders in Tempo** (step heading with role and approver, draw summary line, decision radios, comments), and a blank-comment reject is blocked by the required-field validation.

All four TODO items are closed.

## Rulings recorded

In `PROJECT_INSTRUCTIONS.md` (§ Business rules, § Build phases) and `BUILD_PLAN.md`:
1. Budget Summary figures are roll-ups of the budget detail lines, never the sample's printed figures; demo data must reconcile.
2. Accelerator decision dates spread 1 day per step (`dayOffsetPerStep` = 1); the funding date stays after the last generated date.
3. Mockups are authored in the claude.ai Project and delivered into `mockups/`; build sessions treat them as the UI contract and never author or modify them.
4. New demo runs come from Phase 3 ingestion of the standard template; draw 66 and the reset script are interim tooling.

## Work item 1: column widths, definitive

Method: a throwaway model `zz SD Width Probe` (one Write Records node per record type, `PauseOnError` false, errors mapped to PVs), driven by `testProcessModel`; deleted afterwards, absence confirmed.

| Column | Requested | Readback | Measured |
|---|---|---|---|
| `SD Draw.contingencyExplanation` | 4,000 | `VARCHAR(4000)` | 1,200 characters written and read back intact |
| `SD QIU Metric.notes` | 1,000 | `VARCHAR(255)` | 300 and 1,000 pass; 1,001 fails `Data too long for column 'NOTES'` |
| `SD Investment.investmentDescription` | 1,000 | `VARCHAR(255)` | same: 1,000 passes, 1,001 fails |
| `SD Draw Approval.comments` | 1,000 | `VARCHAR(255)` | 600-character comment written through the real transition, read back intact |

**Result:** the physical width is exactly the requested length. The readback of `VARCHAR(255)` is wrong. Nothing truncates silently; a write past the limit fails loudly. **No column was altered:** the spec's paragraph fields hold 4,000 (`contingencyExplanation`) and 1,000 (QIU `notes`). Whether 1,000 is enough for a QIU note is flagged in `TODO.md`; widening would be a drop-and-recreate. Probe values were restored to the seed text and read back. Recorded in `reference/mcp-capability-boundaries.md`; the staged width finding is resolved.

## Work item 2: accelerator date spread

`dayOffsetPerStep` default changed 0 → 1 (read back). Two runs produced decisions for steps 4–8 on 2026-09-23, 24, 25, 26, 27, one day apart. The last generated date (09-27) precedes the funding date (10-15). As the ruling's narration allows, the CEO's live decision carries today's date, earlier than the President's generated one.

## Work item 3: race and timing

**First attempt, before any fix (observation first):** approval at 02:41:39 UTC, accelerator started 10 s later. It read a half-applied transition (rows 3 and 4 already updated, `currentStep` still 3), asked to decide step 3, was refused STALE by the transition's guard, and stopped after 0 iterations. **No data was harmed** and the Asset Manager's attribution stayed, but the demo sequence would have failed.

**Fix:** a settle phase in the accelerator. On its first pass it re-reads every 5 s until the row at `currentStep` is In Progress and the state is identical across three reads (12-wait ceiling, else `SETTLE_TIMEOUT`); later iterations do not settle.

**Race run, the exact demo sequence:**

| Event | Time (UTC) | Offset |
|---|---|---|
| Asset Manager approval submitted | 02:46:54 | 0 s |
| Accelerator started | 02:47:01 | +7 s |
| First accelerator decision (step 4) | 02:47:25 | 24 s settle |
| Steps 5, 6, 7, 8 | 02:47:37, :49, 02:48:00, :12 | ≈12 s each |
| CEO step process registered on the draw | 02:48:28 | |
| CEO task assigned | 02:48:30 | **87 s from accelerator start; 94 s from the approval** |

Row 3 kept its `TASK` attribution; the superseded step-4 task was cancelled (task total unchanged); exactly one draw task was open at the end. **No stale-decision failure.** An idle-case run (open task, nothing in flight) took 81 s (18 s settle). Both `testProcessModel` calls hit the client's 60 s read timeout while the process completed; the data, not the call, is the evidence.

**Demo-script fact:** clicking the accelerator to the CEO task being live is about a minute and a half. Narrate it.

## State of the instance

Draw 66 is at the seeded state (In Progress, step 3, orders 1–2 Approved, 3 In Progress, 4–9 Pending, no open step process), read back; task total 52, so no draw task is open. Each run was closed with a CEO approval before the reset, so two more treasury notifications were sent to the designer's inbox.

## Verified

Every fact above by readback as the designer or by a local timestamp around the call; each probe write by a readback of the stored value; the probe model's deletion by a failed `getProcessModel`.

## Not verified

- Email delivery for this session's runs (not re-checked; the capability is now confirmed).
- Persona behaviour and record-level security (deferred with the persona accounts).
- Widths on `purpose` and `overBudgetReason` (1,000 by inference from the same declaration, not probed).

## Findings and promotion

- **Resolved:** the width readback finding (measured; recorded in the boundaries doc) and the alert-group persistence (confirmed in Designer).
- **New, staged:** a driver that follows a multi-write transition must settle on a consistent, stable state before acting (trap and working form in the log; trigger named).
- 0 promoted to the supplemental. Checkpoint current through this entry.

## Repo changes

`PROJECT_INSTRUCTIONS.md` (four rulings), `BUILD_PLAN.md` (rulings; Phase 1 date-spread and settle items ✅), `CLAUDE.md` (accelerator behaviour, timing fact, column widths), `reference/mcp-capability-boundaries.md` (widths entry), `BUILD_LOG.md`, `TODO.md`.

## TODO changes

- **Closed:** the four browser checks; the two client questions (Budget Summary, decision dates); the width proof.
- **Updated:** "Accelerator timing" now carries the measured 87 s and the settle behaviour.
- **Added, Deferred:** QIU `notes` width is 1,000; widening is a drop-and-recreate (trigger: a longer note, or Phase 3).
- **Still open:** Before demo: the spec artifacts not on GitHub; persona accounts. Deferred: supplemental §3 correction; record-level security; remaining-object inventory; identity probe.

## BUILD_PLAN.md changes

Phase 1: two new ✅ items (date spread, settle phase). Phase 2 is next: mockups arrive from the Project into `mockups/` before Phase 2b.

# Closeout — 2026-09-28 — Fix session: real decision timestamps, day-spreading removed

## Scope and identity

- **Design work and every designer readback:** the Dev MCP as `scott.thorn@appian.com`, a member of `SD Administrators`, `SD Users` and the three draw step groups (full scope).
- **Persona reads:** sail as `sd.accountant` (Priya Raman), from `~/.sail-sd.accountant`.
- **Runtime connector:** not called.
- **Preflight:** not re-run for this brief. The second session's preflight from earlier this evening stands: Dev MCP 26.6.95 matches the pin, sail 26.6.95, and both personas were live.

## Decisions recorded (`PROJECT_INSTRUCTIONS.md`, One-draw demo block)

- **Decision dates are real timestamps.**
  - Every approval decision is stamped at the moment it happens, whether it comes from a live task, an email reply, the reconciliation confirm or an accelerator advance.
  - There is no +1-day floor and no forward-dated step. "The chain approves over the following days" is narration only.
  - Existing draws' dates are historical data and stay untouched.
  - The 2026-09-21 `dayOffsetPerStep` ruling is struck as superseded. The owed ruling on the Asset Manager's date is closed.
- **A draw whose investment matches nothing is numbered #1, as built.** Accepted.

## What changed

**1. The transition, `SD Apply Draw Approval Decision` (v9.0, read back).**
- Node 4 now writes `now()` as the effective date. It was `max(requested, previous decision + 1 day)`.
- The step's decision date and the next step's `activatedAt` are therefore the moment the transition runs, whatever the source: task, email, confirm or accelerator.
- The `decisionDate` parameter is kept, so existing subprocess mappings still bind, and it is ignored.
- Order stays monotonic because time does.

**2. The accelerator, `SD Advance Draw to CEO Step (Demo Accelerator)` (v13.0, read back).**
- Each step it advances is stamped `now()`. It was `now() + (iteration + 1) × dayOffsetPerStep`.
- The `dayOffsetPerStep` parameter is removed.
- The retired `SD Stage Draw for Approval` still lists that parameter, unmapped, on a node. It is unused and was left.

**3. The Approvals tab, `SD_view_drawApprovals` v6.**
- The regression showed "1 day" in Time at Step for steps decided seconds apart. The column had a `max(1, …)` floor built for the day-apart dates.
- It now counts calendar days from activation to decision, reading "< 1 day" for a step decided the day it opened.
- Chains a day apart still read "1 day".
- Seeded #66's order 1 (activated and decided 10/06) now reads "< 1 day" instead of "1 day". Its data is unchanged.

**4. The runbook (`TODO.md`).**
- **Beat 4:** Priya's approval is "stamped at the confirm minute", and Elena's is "dated the actual minute, today".
- **Beat 5 and the accelerator-timing item:** the recorded dates are today's, seconds apart; the days are narration only.
- **Beat 0 has a new caution:** never start two feeds of the same template within ~2 minutes (see Findings).

The throwaway `zz_feedLauncher28c` was created for the feed arrivals, then deleted. Its read now returns "Does not exist".

## The regression: the demo path, on #84 (draw 112)

| Order | Role · approver | Decided (UTC, 09-29; 10:56–10:59 PM EDT on 09-28) | How |
|---|---|---|---|
| 1 | Accountant · Priya Raman | 02:56:28 (the confirm; activated 02:53:07) | reconciliation |
| 2 | Asset Manager · Elena Marchetti | 02:57:03 | her task |
| 3–7 | Controller → CFO of Funds | 02:57:45 · 02:57:56 · 02:58:08 · 02:58:20 · 02:58:32 | Advance to President |
| 8 | President · James Callahan | 02:59:56 | Advance to CEO (34.7 s) |
| 9 | CEO · Thomas Bergman | In Progress since 02:59:56; step email sent 03:00:15 | — |

- **All decisions are the same day and in time order,** 11 to 84 seconds apart. Each row's activation equals the previous decision.
- **Send Reminder Now** took 14.8 s: the reminder went on the President's thread and the text was staged.
- **Step email (the CEO's):** the APPROVAL STATUS table shows orders 1–8 Approved, each **09/28/2026**, with the CEO row highlighted. The funding date reads November 16, 2026.
- **Summary, as `sd.accountant` via sail:**
  - "FUNDING DATE November 16, 2026 · in 48 days";
  - "Received Sep 29 · in approval 0 days so far · 48 days from receipt to funding date";
  - "8 of 9 approved · started 09/29" with every step "✓ 09/29";
  - "At this step since today".
- **Approvals, as `sd.accountant` via sail:** Decision On 09/29/2026 for orders 1–8, with their sources, and Time at Step "< 1 day" on every row (after the v6 fix).
- **Seeded draws, read back:**
  - #12's rows 1201–1206 and #66's rows 6601–6603 are exactly as before: same decision dates, activations and last-updated times.
- **Needs chasing, as `sd.accountant` via sail:**
  - While #84 sat at the President step: (3) — #12 "Step 6 waiting 10 days" with its staged text, #84 "Reminder sent today · text staged", and #70.
  - After Advance to CEO: (2) — #12 and #70 exactly as before. #84 left because its chased step is no longer the current one.

## Findings

- **Two feeds of the same template can collide.** The regression's first corrected feed (draw 110) failed with "required header fields came back blank".
  - Your draw 111, the same template 25 s later, took the same Doc Center instance (898). 110 read it while it was still blank.
  - 110 is an Ingestion Failed row and sent you a spurious failure alert. 111 is Ingesting with its task open. I re-ran as 112.
  - This is not caused by today's change. The pipeline finds its instance as "the newest for this document".
  - Recorded as the beat-0 caution, a Deferred item with a fix, and a staged promotion candidate.
- **After 8 PM Eastern, the record views show tomorrow's date.**
  - The views turn datetimes into dates with `todate()`, which the docs say returns the GMT date. The email formats in the viewer's zone.
  - Measured tonight as the same designer: the email reads 09/28, the Approvals tab 09/29, for the same decisions.
  - The old seeded times never crossed midnight UTC, which hid it.
  - From midnight to 8 PM Eastern both agree. Deferred with a trigger: fix before any demo or rehearsal after 8 PM Eastern.
- **Zero-day spans.** The cycle line says "in approval 0 days so far" (and will say "decided in 0 days" after a same-day decision). This is true, and left as is.

## Not verified, and why

- **Browser only:** the Approvals tab and the Summary with same-day dates (content verified via sail; geometry unaffected), and the staging card's three clicks (their processes ran directly).
- **Gmail:** the reminder threading and #84's CEO step email in your inbox.
- **Persona clicks:** Confirm and the Asset Manager's Approve were completed as the designer, so #84 shows "reconciliation · scott.thorn@appian.com" and "task · scott.thorn@appian.com". On stage the forms save the persona.
- **Beats 6–7** were not run. #84 waits at the CEO, with its email sent at 11:00 PM EDT.

## Browser checklist

1. **As `sd.accountant`, Draws → #84 → Approvals.** Nine rows, 1–8 Approved 09/29/2026 (or 09/28 once the evening-date fix lands), Time at Step "< 1 day" throughout, and the CEO row highlighted.
2. **As `sd.accountant`, #84 → Summary.** The progress strip "Accountant ✓ … President ✓" with one date, and the cycle line as above.
3. **Gmail.** The CEO step email for Draw #84 (11:00 PM EDT): its Approval Status table reads 09/28/2026 on every row.
4. **The next daytime rehearsal (before 8 PM Eastern).** Confirm → Elena's approval → Advance to President → Advance to CEO. Every date reads today in both the email and the record.

## Rulings needed

- **Evening-date fix.** Fix the views' dates now (`todate(local(x))`, roughly 30 call sites), or only if the demo or a rehearsal runs after 8 PM Eastern?
- **Still open from earlier today:** #12's pending question (leave it, or answer it).

## Promotion candidates

- **1 staged at gate 1:** finding a child run's output as "the newest row for my key" races with a concurrent run on the same key.
- **Not a candidate:** the `todate()` GMT behaviour is documented (fails gate 3).
- **None promoted.** The supplemental skill copies are identical.
- **Checkpoint:** current through this session's entry.

## TODO changes

- **Rewritten:** the runbook's beats 4 and 5 and the accelerator-timing item (dates today, days as narration).
- **Added, beat 0:** the same-template caution.
- **Added, Browser checks:** same-day decision dates on #84 (Approvals, Summary, and the CEO email in Gmail).
- **Added, Deferred:**
  - two feeds of the same template can share a Doc Center instance;
  - evening dates read tomorrow on the record views.
- **Closed:**
  - the Asset Manager date ruling (ruled and built);
  - the unmatched-investment numbering ruling (accepted #1).
- **Done:** this session.

## BUILD_PLAN.md changes

- The 2026-09-21 day-spread item is marked superseded.
- New ✅ 2026-09-28 **Real decision timestamps**, including the Approvals tab's calendar-day Time at Step, tested on #84.

## Commit

"fix: real decision timestamps, day-spreading removed". Pushed to `origin/main`, then verified that HEAD equals `origin/main` and the tree is clean.

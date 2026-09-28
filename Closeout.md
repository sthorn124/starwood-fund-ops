# Closeout — 2026-09-27 — Housekeeping: demo-practices skill created from the build record; supplemental §3 corrected

## Scope

- **No Appian instance work.** Nothing was called on the Dev MCP, the runtime connector or sail.
- **Two repositories were touched:**
  - this build repo;
  - the template repo `~/appian-devmcp-method` (origin `appian-fs-sc/appian-devmcp-method`). It was reachable from this machine, so it holds the authoritative copies and nothing is left for you to copy by hand.
- **The user-level skills** in `~/.claude/skills/` were updated.
- **Not touched:** the other build repo on this machine (`~/snowflake-tradesettlements-demo`) has its own supplemental copy. It belongs to another build; its preflight will report the drift the next time it runs.

## Preflight §2 step 6 — the skill comparison, before any edit

- The build repo's and the user-level `appian-supplemental` were identical (2026-09-26).
- The template copy (2026-09-24) lacked exactly one line: the 2026-09-26 §9 promotion ("Mail an Appian Cloud instance sends is stamped from the site's system address").
- The build copy was a strict superset, so it became the base for all three. The brief's "keep them identical" settled the direction.

## What changed

1. **Ruling recorded** (`PROJECT_INSTRUCTIONS.md`, in the 2026-09-27 demo-prep block):
   - Draw numbers and record ids carry no demo significance.
   - No beat, specimen, staging step, prompt or plan may depend on one.
   - The sequence chips are narrated as a control, not scripted around.
   - Beat 2's "Out of sequence → type the next number" stands.
   - The keep list of nine specimens is confirmed.
   - **Applied at once:**
     - The runbook's beat 2 (`TODO.md`) no longer scripts any number.
     - The `BUILD_PLAN.md` narrative's Phase 0 order ("Draw #66 arrives", failure first) is struck and replaced by the ruled, id-free order.
2. **`skills/demo-practices/SKILL.md`, new.**
   - The authoritative copy is in the template repo. Synced copies are here and at `~/.claude/skills/demo-practices/SKILL.md`; all three are byte-identical.
   - Frontmatter (`name`, `description`) was added so it loads as a user-level skill. It registered in the session as soon as it was installed.
   - Rule wording is as you wrote it. Only the evidence lines and one build-specific sentence changed (verification below), plus two added rules.
3. **appian-supplemental §3, corrected.** The 403 entry now states the measured behaviour:
   - reads work from 26.6.90 (UUID-addressed `listGroups`, `getGroup`, `listGroupMembers`);
   - `addGroupMembers` works on 26.6.95 (three adds, each read back; one Cloud site; re-verify per instance);
   - `removeGroupMember` is unexercised;
   - membership is proven by `listGroupMembers(directOnly: true)`, never by the add's status;
   - the wall still stands on servers older than 26.6.90.
   - It cites `reference/mcp-capability-boundaries.md` §6. The version is now 2026-09-27.
   - The template, this repo and the user level are identical.
4. **`reference/mcp-capability-boundaries.md` §6, both repos.** The heading "reading now works, writing unverified" contradicted its own body and the corrected skill. It now reads "reads work from 26.6.90, writes from 26.6.95". Only the heading changed.
5. **`CLAUDE.md`, template and this repo.** One line after "Skill precedence" says `skills/demo-practices/SKILL.md` holds the judgment rules for demo builds. It is to be read during planning as well as building: before a plan or build prompt is written or accepted, and at the start of every build session.
6. **Template only.** Without these, a new build would not install the skill the new CLAUDE.md line assumes:
   - `GETTING_STARTED.md` step 4 now installs three skills, adding the demo-practices bullet.
   - `README.md` gains the skill's row.
7. **TODO item closed:** the owed appian-supplemental §3 correction.

## Verification of the skill, per rule

Each evidence line was checked against `BUILD_LOG.md`, the git history (closeouts included) and `TODO.md`. There are 10 evidence-bearing rules: **1 confirmed, 9 corrected, 2 added**. Every rule keeps its wording, and none was softened or caveated. Where the record shows the build departing from a rule, the evidence says so and the departure goes to Scott as a ruling.

| Rule | Result | What the record showed |
|---|---|---|
| No precious specimens | **Corrected** | The draw-66 reset was a live TODO item in every build commit from Phase 1 (`f263949`, 09-21) to Phase 6c (`92400d8`, 09-26): **fifteen** build sessions, not five. The four deleted draws' "not deleted without Scott's word" note sat in a struck TODO block. |
| Ids and business numbers are demo-insignificant | **Corrected** | No duplicate was explicitly preserved. The browser checks, the chip gauntlet's collision specimen and beat 2 expected "Renumbered from #67 (on file)", which held only while duplicate #67s stayed on file. Keeping one was proposed, then ruled out. |
| Accumulation is the default | **Corrected** | The record has two reset rulings: 09-21 (interim tooling, "no … reset mechanism becomes a demo feature") and 09-27. On 09-22 and 09-25 reset *instructions were added*, not killed. |
| Verify as the persona | **Corrected** (labels only) | All three catches are confirmed. "Task-restart fix" was renamed to the record's "approver-action fix", and dates were added. |
| Demo-plausible, and say which | **Corrected** | Accelerated dates are recorded as "fictional; say so if asked", not "narration-consistent". |
| The demo-magic ladder | **Corrected** | "Nothing is faked" was wrong: each ingested draw copies the previous draw's QIU set, re-dated, "narrated as the QIU model feed", which is rung 3. The Twilio reason in the record is the trial's refusal (572006) plus the ruling; no cost reasoning is recorded. |
| Mockup-first | **Corrected** | Only three mockups exist, and the intake page, Emails tab, exception form and staging card had none, so "the one screen" was wrong. The record never calls the form unusable: it was rebuilt the same day from prose, with inputs and bindings unchanged. |
| Success before failure | **Confirmed** | Phase 0 (`4b937cf`): arrives → fails → corrected template ingests. Reordered 09-27. |
| Live where possible | **Corrected** | There are three staged elements, not two. Order 1's Accountant **is** a persona account, so Stage for Approval's order 1 departs from the rule (flagged). |
| AI authority tiers | **Corrected** | The fabrication specimens are N8 and N14. The "by AI" attribution is confirmed in the stored text and the rendered alert. The comparison is written to the draw with **no human review**, a tier-3 departure (flagged). |
| Every action is reachable from the demo surface | **Added** | Recurring: the step decision's Summary strip (09-22), the reconciliation card (Phase 3), and the email-reply review, opened "from the task list" until the 09-26 "nothing requires Tempo" ruling. |
| Measure every wait on stage and script it | **Added** | Recurring: the accelerator's 87 s (09-21), reconciliation's ~80 s plus ~40 s (09-25), the email reply's 1–3 min (09-26). Each became a runbook narration line. |

**Limit of this check.** It covers the repo record only. A claim resting only on your claude.ai Project conversations would not appear here.

## Rulings needed

1. **Order 1 is staged though it has a live persona.** Stage for Approval approves orders 1–2 pre-demo. Order 2 has no persona, but order 1's Accountant is `sd.accountant`, whose on-stage beat is reconciliation on a different draw. Either:
   - accept it by ruling (the step-1 approval is not a beat); or
   - have `sd.accountant` approve step 1 live and stage only order 2.
2. **The failure comparison becomes record content with no human review.** It is gated line by line against the rule-computed diff and labelled "by AI", but tier 3 requires human review before AI text becomes record content. Either:
   - add a review step (for example, an accountant acknowledgement); or
   - rule the stored comparison an alert artefact, not record content.
3. **The QIU feed is rung 3 (faked).** No ruling is needed, but the presenter should narrate it as a simulated feed, not a model. The record now says so (this closeout, and the skill's "In this build" line).

## TODO changes

- **Closed:**
  - The appian-supplemental §3 correction (struck, and moved to Done).
- **Added, Before demo:**
  - Ruling: order 1 staged though it has a live persona.
  - Ruling: the failure comparison stored without human review.
- **Added, Deferred:**
  - State each piece's rung and each AI touch's tier in the build record (the build session, next session).
  - Extend preflight §2 step 6 to compare demo-practices too (Scott, the next template change to §2).
- **Updated:**
  - Runbook beat 2 is now id-free.
- **Done:**
  - This session.

## BUILD_PLAN.md changes

- The Demo Narrative's Phase 0 order is struck and replaced by the ruled, id-free order.
- No phase items changed, since nothing was built.

## Promotion candidates

- **0 found.**
- **One resolved:** the staged `addGroupMembers` candidate was carried into appian-supplemental §3 at the owner's direction, tagged re-verify per instance. Its trigger stays open to generalise it.
- **Reached the template:** the 2026-09-26 §9 promotion.
- **Checkpoint:** current through this session's entry.

## Commits

Both repositories were committed as "skills: demo-practices created from build record; supplemental §3 corrected", pushed, and verified against `origin/main`.

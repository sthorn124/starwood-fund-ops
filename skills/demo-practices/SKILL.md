---
name: demo-practices
description: Judgment rules for SC demo builds, learned from incidents — staging actions over precious specimens, id-free beats, optional cleanup, persona verification, the demo-magic ladder, site-reachable actions, scripted waits, and AI authority tiers. Read at planning time and before accepting any demo build prompt, not only in build sessions.
---

# Demo build practices

Practices for SC demo builds, learned from incidents. They bind planning and prompts as much as build sessions: several exist because the planning side drifted, not the session. Read at planning time, not just build time. Platform and tooling facts live in appian-supplemental; this file is judgment.

## Why we build demos
A demo exists to prove the platform's value to a customer by meeting and exceeding their stated requirements for the use case, and to make the business value it drives visible and quantifiable. We are not building products. Effort is spent where it proves value; polish, robustness, and completeness matter exactly as far as they serve the proof. Every build decision in this file follows from that.

## No precious specimens
Any state a demo beat needs must be producible on demand by a staging action (a button, a process). A plan or prompt saying "keep record N" or "reset record N" is the signal to build the staging action instead. Kept specimens are conveniences; every one must remain reproducible on demand, and no beat may depend on one.
Evidence: the draw-66 reset ritual stayed a live TODO item through fifteen build sessions (Phase 1, 2026-09-21, to Phase 6c, 2026-09-26) before Stage for Approval replaced it (2026-09-27); a cleanup run deleted four browser-pass draws whose "not deleted without Scott's word" note sat in a struck TODO block, because preservation lists rot (2026-09-27 closeout, Flagged).

## Ids and business numbers are demo-insignificant
Never script a beat, specimen, verification, or prompt around a specific record id or business number. Ids are auto-assigned and opaque; narrate whatever value appears.
Evidence: the template's #67 made the draw-number chip a scripted expectation — browser checks, the chip gauntlet's collision specimen and the runbook's beat 2 all expected "Renumbered from #67 (on file)", which held only while duplicate #67s stayed on file; when a cleanup removed them the beat changed, keeping a #67 on file was proposed, and the dependency was ruled out (2026-09-27).

## Accumulation is the default; cleanup is a button, never a prerequisite
Old runs are list texture that reads as a live system. Cleanup exists for whoever wants a tidier list, marked optional, and is never a step in demo prep or verification.
Evidence: resets were ruled interim build tooling on 2026-09-21 ("no generator or reset mechanism becomes a demo feature"), yet reset instructions kept growing in TODO — the draw-66 CSV reset, the ingestion resets of 2026-09-22 and 2026-09-25, the email-row deletions of 2026-09-26 — until the 2026-09-27 ruling struck them all.

## Verify as the persona, not the designer
Admin-scope renders lie about permissions, task visibility, and actionability. Every phase check that matters runs as the real persona account.
Evidence: persona checks caught a site 500 the designer render passed (group() permission, Phase 6c, 2026-09-26), an upload-field type error behind a clean designer render (intake fix, 2026-09-22), and an aborted task the designer read as actionable while the Asset Manager saw no action (approver-action fix, 2026-09-22).

## Demo-plausible beats production-correct, and the closeout says which one was built
Cut toward the demo, but the record must state what is simulated or staged so narration never overclaims.
Evidence: the staging card simulates feed arrival, recorded as such (narrated as the EY API/SFTP drop); accelerated chains carry generated decision dates, recorded as fictional with what to say if asked (Phase 6c cycle-time rule; known data artifacts).

## The demo-magic ladder
When a capability is needed on stage, take the first rung that works, top to bottom:
1. Real: build it functionally when the effort is proportionate to the value it proves.
2. Staged: a real mechanism triggered artificially (an accelerator, a staging button) when there is no live actor or timing makes live impossible.
3. Faked: surface-only, hard-coded behind the scenes. Last resort, only when real is technically infeasible or the build cost clearly outruns the value proved.
The record states which rung each piece sits on, so narration never overclaims. In this build: the email interpretation is real; the chain bridge and feed arrival are staged; the QIU feed is faked (each ingested draw copies the previous draw's QIU set, re-dated, narrated as the QIU model feed).
Evidence: SMS stays staged because the Twilio trial account refuses free-form text (error 572006, 2026-09-26) and the account upgrade was not taken (ruled 2026-09-27); the accelerator (no live personas for steps 4-8); the staging card (no real SFTP feed exists to arrive from).

## Mockup-first for designed screens; prose is enough for rendering fixes
New screens get an approved mockup before SAIL; layout repairs to existing content are describable in prose.
Evidence: the reconciliation form, built in Phase 3 without a mockup (the mockups covered only the draw list, the draw summary and the task form), was rebuilt full width with an inline document viewer the same day (2026-09-22); the rebuild from a prose brief worked because the content was already right — its inputs and bindings carried over unchanged.

## Success before failure in the demo order
Show the future state working before showing it defending itself. Value first, robustness second.
Evidence: the Phase 0 beat order opened on the failure path; reordered by ruling 2026-09-27.

## Live where live is possible; stage only what has no live persona
Every beat a real persona can perform runs live on stage. Staged bridges (accelerators, pre-demo clicks) cover only steps with no live actor, and the presenter can say which is which if asked.
Evidence: the accelerator bridges orders 4-8 and the staging card delivers the feed because neither has a live actor (no persona accounts, no source system); the pre-demo Stage for Approval takes orders 1-2, where order 2 has no persona but order 1's Accountant is a persona account, so that step departs from the rule (flagged 2026-09-27).

## Every action is reachable from the demo surface
Every task and action a beat needs is reachable from the pages the audience sees; nothing sends the presenter to a task inbox or a designer tool. A new task type is not done until the page links it.
Evidence: the step decision gained its Summary action strip (approver-action fix, 2026-09-22) and the reconciliation task its Summary card (Phase 3, 2026-09-22); the email-reply review was opened from the task list until it got its own card and link, ruled "nothing requires Tempo" (Phase 6c, 2026-09-26).

## Measure every wait on stage and script it
Every on-stage wait is measured on the live path and written into the runbook with the line the presenter says, or the step they take, while it runs.
Evidence: the accelerator's 87 s to the CEO task (2026-09-21), the reconciliation task's ~80 s plus the pay application's ~40 s read (Phase 5.6, 2026-09-25), and the email reply's 1-3 minutes (Phase 6a, 2026-09-26) each became a narration line in the runbook.

## AI authority scales with consequence; state changes are absolute
Three tiers, by what the output can do:
1. Acts (approves, rejects, writes records, moves state): a deterministic gate is mandatory. The gate verifies the AI's claim against a checkable fact (a verbatim quote, a computed diff, a numeric tie); gate failure degrades to the safe state, never a guess. No exceptions, ever.
2. Routes or files (classification, assignment): uncertainty takes a safe default a human will see; deterministic checks apply wherever a checkable fact exists downstream.
3. Speaks (explanations, comparisons, drafts): grounded in deterministically computed inputs, labeled as AI, and never the source of record for a business fact. Human review before it becomes record content.
The build record states which tier every AI touch sits on; the presenter can answer "how is this one controlled" for each without overclaiming.
Evidence: tier 1, the grounded-quote gate on reply interpretation (state change only after verbatim verification; the gauntlet's fabricated-phrase and fabricated-question specimens, N8 and N14, prove the failure mode); tier 2, classification files unknowns to Backup as "Not classified", and the pay application must tie numerically before the package counts as tying; tier 3, the failure comparison narrates only rule-computed differences, each line checked against the computed diff, attributed "by AI" in the email — and it is written to the draw with no human review, a departure from tier 3 (flagged 2026-09-27).

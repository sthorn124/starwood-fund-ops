# Worked example: regressing an agent's instructions against held-constant specimens

This is the worked example behind the regression-specimen discipline in `reference/patterns.md` §3 and `CLAUDE.md` §11. It follows one agent's instruction text through six versions, probed each time against the same two cases, and shows what the discipline bought: a definition that discriminates, a threshold that never moved, and a variance finding that would otherwise have been filed as a regression. Identifiers, counterparties, desks, and the application's names are removed; every number is as measured.

## The agent and the gate it feeds

A triage agent assesses one predicted trade-settlement failure per run. Its input is a single pre-assembled text block of case facts — the case, the trade, the prediction, the counterparty, and later the instrument, matching status, and onward deliveries. It returns five structured outputs: an assessment, a remediation (drawn from a deterministic lookup, never invented), an urgency, a confidence score in `[0, 1]`, and an escalate flag.

A process model consumes those outputs and routes on them. Confidence at or above a threshold constant of **0.80** resolves the case straight through with no human review; below it the case goes to an analyst; one failure category always escalates to a human credit decision, and the process tests that category directly rather than trusting the agent's flag. The threshold is a bank-realistic bar chosen before the agent existed, tunable live for the demo, and deliberately not tuned to the agent.

Confidence is therefore the gate input, and its meaning is the whole question: it has to mean *"is the proposed remediation the right course of action for these facts"*, never *"will this trade fail"* (that is why the case exists) and never *"can the desk execute it"* (that is downstream work).

## The specimen pair, held constant

Two cases were fixed at the start and never changed. Every fact below stayed identical run to run, and the failure reason was held constant between them so that facts were the only variable.

| | Clean — a straight-through candidate | Concerning — must not be automated |
|---|---|---|
| Failure reason | funding shortfall | funding shortfall (same) |
| Broker confirmation lag against the 23 h window | **1.71 h** (7.4 % of the window) | **26.07 h** (113 % — the lag exceeds the entire window) |
| Notional | **88,001.91 EUR** | **30,415,081 EUR** (346 × larger) |
| Counterparty | medium risk tier, **9.55 %** historical fail rate (dataset mean 9.20 %, median 5.87 %) | high risk tier, **21.58 %** historical fail rate — the worst in the book |
| Model fail probability | 0.5988, high tier | 0.8095, critical tier |
| Other facts (later versions) | matched, zero onward deliveries, modest notional for the desk | large for the desk |

The clean case is the cleanest the dataset can produce when screened on facts rather than probability. The concerning case is the most concerning non-credit case the dataset holds: a filter for high-tier counterparty, fail rate above 20 %, lag above 20 hours, and notional above 5 M returned three matches, and this one carried the highest lag. A third specimen was added at the end — an authored case with a 1.15 h lag against a **3 h** window, **18,700,500 EUR** notional, and a high-tier counterparty at 19.89 % — built so that timing and counterparty pull in opposite directions.

Every probe was a live run through the process, driven from the design tooling as the design account; outputs were read from the structured output map and from the rows the process wrote, never from the agent's own run summary (see `reference/model-output-verification.md`). Each probe changed one thing.

## The version sequence

### v1 — confidence as execution feasibility

Three runs on complete context returned **0.65 / 0.62 / 0.30**, and no run cleared 0.80. The agent was reasoning correctly and said so: *"No data on current securities lending inventory or borrow availability was included in the case context, which caps confidence somewhat."* The ceiling was the data model, not the agent — feasibility data does not exist in the case facts.

### v2 — confidence redefined as "correct course of action"

Only the output's description changed; the instructions did not. Four non-stub runs returned **0.72 / 0.75 / 0.75 / 0.90** — a range, each with its own stated reason — so the "anchored score" hypothesis died. But the cleanest case scored *lowest* of the non-credit runs (**0.72**), and the agent's sentence named why: *"not generous given the 0.60 fail probability, so confidence is held below high."* The model's fail probability was being folded into remediation confidence — a category error the definition did not forbid. Non-credit cases clustered at 0.72–0.75, so at 0.80 straight-through would essentially never fire.

**The decision handed back at this point** was the threshold's first test. Option (a): lower the constant to 0.70, reachable that day. Option (b): close the semantic gap first — state that fail probability is why the case exists, not evidence against the remediation. The recommendation was (b) then re-probe, because (a) alone would set the gate under a number the agent computed partly on the wrong basis.

### v3 — fail probability excluded, by one sentence

Same clean specimen: **0.85**, up from 0.72. The confidence sentence was now about the remediation (*"That window is sufficient for a treasury funding chase before settlement"*) and the probability was cited as a case fact rather than as grounds for doubt. Straight-through fired for the first time. The v2→v3 delta on an identical specimen was **+0.13**, attributable to one sentence. Three probes, one variable each.

**What v3 did not establish** was discrimination: no concerning case had been run under it. That was the next probe, and it failed.

**The concerning specimen under v3 also scored 0.85** — identical to the clean case — and auto-resolved with no analyst review: a 30.4 M EUR trade whose broker confirmation alone could not complete inside the settlement window, against the worst counterparty available. The mechanism was in the assessment: *"broker confirmation lag of 26.07 hours is a contributing pressure. The 23-hour window is workable…"* The agent saw 26.07, saw 23, and never compared them. v3 named "cutoff too tight to complete" as grounds for lowering confidence and the agent applied that test qualitatively, never arithmetically. Excluding fail probability had removed the one thing that was suppressing scores and left nothing that actually bit.

Distribution under v3: **0.85 clean / 0.85 concerning / 0.90 credit**. No threshold could separate the pair. The probe stopped per its stop condition — reported, nothing tuned — and the authored demo data was explicitly *not* built against this distribution, because a scripted packet built then would have straight-throughed cases it should have referred.

### v4 — the timing arithmetic made mandatory

Four changes: (a) a mandatory decision step comparing the broker confirmation lag to the hours remaining until cutoff, **stating both numbers and the comparison in the assessment**, with confidence capped at 0.5 or lower when the lag is at or near the window; (b) compounding of concerning facts made explicit; (c) a grounding section prohibiting entities, actions, or "executed" claims absent from the context; (d) an instruction for the run-summary field.

| | Clean | Concerning |
|---|---|---|
| v3 | 0.85 | 0.85 |
| **v4** | **0.78** | **0.35** |
| lane | analyst review | escalated |

**Discrimination proven: spread 0.43 on facts alone.** Both assessments stated number against number — *"1.71 hours against 23 hours remaining… comfortably sufficient"*; *"26.07 hours exceeds the 23 hours remaining… the remediation window is already breached"*. The pass condition was the arithmetic, not the score: a low confidence reached without the comparison would have been luck.

**But the clean case fell 0.85 → 0.78, two hundredths under the gate.** Cause, in the agent's words: *"while [the counterparty's] historical fail rate of 9.55 % is mildly elevated, the counterparty risk tier is medium, producing only minor downward pressure on confidence."* Compounding was being applied to the lowest counterparty fail rate in the filtered dataset. Not global over-suppression — over-application of compounding to facts that were not concerning. Because the spread was 0.43, any threshold in roughly 0.40–0.78 would have separated the pair; the question had become threshold-versus-distribution rather than a definition bug, which is a materially better position than v3, where no threshold could have worked. Stop condition fired; nothing tuned.

A side effect worth the record: the concerning case set `escalate: true` and took the escalation lane, which exposed a hardcoded audit sentence written when only the credit category could reach that lane — the stored row asserted a credit rationale that did not exist. It was made reason-aware before the next probe. An audit trail is worth its worst row.

### v5 — favourable facts are reassurance, not concerns

The weighing step was rewritten: only genuinely concerning facts count against confidence; favourable facts — modest size, a roomy window, a low-risk counterparty with a near-average fail rate — are reassurance and must not lower it; a case favourable across the board deserves 0.85 or higher; concerning facts compound.

| | Clean | Concerning |
|---|---|---|
| v3 | 0.85 | 0.85 |
| v4 | 0.78 | 0.35 |
| **v5** | **0.87** | **0.45** |
| lane | **straight-through** | **escalated** |

Both directions correct at the unchanged threshold. The same 9.55 % that v4 read as *"mildly elevated"* now read as *"below-average… no compounding concerns"*, and the concerning assessment carried the arithmetic: *"a broker confirmation lag of 26.07 h against only 23 h remaining… the lag exceeds the window, making straight-through completion before cutoff infeasible."*

### The threshold decision

At three points a constant change would have "fixed" the result faster than an instruction change: at v2 (lower to 0.70 and straight-through fires on the observed cluster), at v4 (any value from 0.40 to 0.78 separates the pair), and at v6 (below). Each time the decision was the same: **0.80 stays, because it is a bank-realistic bar and the model has to earn it.** The gate sits where the demo narrative wants it, and it was closed by evidence rather than by tuning a constant. Lowering it at v2 would have set the gate under a number computed on the wrong basis; lowering it at v4 would have hidden the over-compounding defect instead of fixing it.

### v6 — the variance coda

With an extended context (instrument identity, matching status, onward deliveries), the clean specimen under v5 returned **0.78 and 0.87 six minutes apart** — one on each side of the gate. The first reading had been reported as a regression. **A replicate disproved that**: the specimen was not sitting above the gate, it was *straddling* it, and v5's 0.87 was one draw from a distribution that also produced 0.78. The two assessments differed only in bookkeeping — one counted *"High risk tier prediction"* and *"above-zero fail rate"* as mild concerns, the other found none — and both "concerns" were inadmissible under v5's own intent. v5 had named only fail *probability* as never-a-concern and left the prediction's risk *tier* unnamed.

A false premise had also been propping v5 up: its passing assessment called 9.55 % "below-average", but across all fifty counterparties the mean is **9.20 %** and the median 5.87 %. The right answer had been reached by a wrong reason, which is why it was unstable. v6 keyed the rule to the counterparty's risk tier with a numeric backstop placed in the empty gap between the medium band (8.19–11.59 %) and the high band (18.75–21.58 %): low or medium tier is not a concern; high tier or a fail rate at or above **13.8 %** is. The list of concerning facts became closed rather than open-ended, and the new context fields were classified on both sides.

| Specimen | v5 | **v6** | Lane |
|---|---|---|---|
| clean, three replicate runs | 0.78 / 0.87 (straddling) | **0.87 / 0.88 / 0.88** | straight-through × 3 |
| concerning | 0.45 | **0.35** | escalated |
| authored (timing favourable, counterparty adverse) | — | **0.62** | held for review, arithmetic stated |

Spread across the three clean runs: **0.01**, against 0.09 under v5. The authored case was the one v6 most had to get right — it must neither straight-through on good timing nor escalate on a bad counterparty — and 0.62 with `escalate: false` is exactly that. Threshold unchanged at 0.80; only the weighing step changed.

## Scores at a glance

| Version | What changed | Clean | Concerning | Verdict |
|---|---|---|---|---|
| v1 | confidence = execution feasibility | 0.65 / 0.62 / 0.30 (three runs, complete context) | — | ceiling was the data model |
| v2 | confidence = correct course of action | **0.72** (four runs 0.72–0.90) | — | fail probability folded in |
| v3 | fail probability excluded | **0.85** | **0.85** | straight-through fires; no discrimination |
| v4 | timing arithmetic mandatory; compounding | **0.78** | **0.35** | spread 0.43; clean under gate |
| v5 | favourable facts are reassurance | **0.87** | **0.45** | both correct at 0.80 |
| v6 | tier-keyed closed list; backstop 13.8 % | **0.87 / 0.88 / 0.88** | **0.35** | spread 0.01; straddle gone |

Latency per run stayed at roughly 40–60 seconds throughout, which is what shaped the workbench design: triage on arrival or fire-and-poll, never on click.

## What the discipline consists of

- **Hold the specimens constant.** Same two cases, every fact identical, the failure reason shared, so a score change is attributable to the instruction change and to nothing else. Identify specimens by their properties, never by platform-assigned ids.
- **One variable per probe.** Definition, then exclusion, then arithmetic, then weighing. When two changes went in together (an input type change and a key-name fix), attribution was recorded as unresolved rather than guessed.
- **Probe in both directions.** A clean-case pass alone cannot distinguish a working definition from one that says yes to everything; v3 proved it.
- **State the pass condition as content, not as a score.** The arithmetic had to appear in the assessment, number against number. A right score reached without it would have been luck.
- **Replicate before acting on a single wrong-side reading.** The v5 "regression" was variance; the replicate cost one run and saved a wrong fix.
- **Stop when the stop condition fires.** Each probe had a stated stop condition; the session reported and did not tune. The threshold decision stayed with the owner.
- **Keep the fixture out of it.** Assertions read what the live run showed. A recorded answer key is compared against live runs to measure determinism; it is never the thing under test.
- **Never read the model's self-report.** Every score above came from the structured outputs and the rows written; the run-summary field fabricated throughout (`reference/model-output-verification.md`).
- **Log every version with the failure it closed.** The instruction file carries the deployed text verbatim plus a version history stating what each change was for, so the next person can see why a clause is as blunt as it is.

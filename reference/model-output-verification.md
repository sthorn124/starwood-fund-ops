# Model-authored output: verify before you surface it

A finding from the settlement build, stated generically, with the observations that established it. It extends `reference/silent-failure-taxonomy.md` §J and the agent design rules in `reference/patterns.md` §3.

## The finding

The platform's execute-agent process node returns, alongside the agent's structured outputs, a free-text **run summary** authored by the model about its own run. Over 23 runs across four instruction states that field never reliably described the run, and from the thirteenth run onward it fabricated: plausible, confident, specific content that had nothing to do with what happened.

**Rule:** a model-authored summary or explanation field is never surfaced to a user, an audit trail, or an operator screen without independent verification, and it is never used to diagnose a run. Observability comes from the platform's tool-call monitor and from structured outputs and written rows, not from the model's self-report.

## The observations, in order

The field was captured on every run and read after each one. The count below is the full series.

| Phase | Instruction state | Runs | What the field said |
|---|---|---|---|
| 1 | No instruction addressed the field | 12 | Identical generic boilerplate on every run, claiming no inputs were provided — including runs that demonstrably received a full context and produced a complete assessment. On the one run that genuinely had no input it happened to describe the fault; on the working runs it contradicted observable reality. Actively misleading as a diagnostic. |
| 2 | Same | 1 (run 13) | A detailed, confident, wholly invented remediation narrative: a case identifier that did not exist, a named customer with an id, a "$15,000 funding gap", a payment plan of "$1,250 over 12 months", a notification emailed to an invented address — ending *"The remediation has been successfully executed."* None of it happened; none of those entities exist anywhere in the application. |
| 3 | A "run summary" section added to the instructions: describe only this run, reference only entities from the context, never describe actions not taken or work as executed | 2 | Both summaries run-descriptive and accurate, naming only context entities. The candidate "the field ignores instructions" was closed as falsified. |
| 4 | Same instruction text, unchanged, next instruction version | 2 | Both fabricated. One described an entirely different domain: a search for a named customer, an account number, a **$15,847.32** balance, an account type, an opening date. The other stayed on topic and was wrong in three places: it invented a rule (*"escalation for any broker confirmation lag exceeding 24 hours"*, which exists nowhere), invented a "regulatory cutoff", and **reported confidence 0.85 when the actual output was 0.45.** |
| 5 | Same text, a separate probe | 1 | Invented a trade identifier. |
| 6 | Next instruction version, five runs across three specimens | 5 | Between them: two invented trade identifiers, an invented instrument identifier with a quantity of 50,000 and a price of $98.50, a wrong securities identifier where the context supplied the correct one, invented dates, a four-step remediation procedure that exists nowhere, meta-narration (*"I'll help you execute the agent task"*), and one summary **reporting confidence 0.85 against an actual output of 0.88.** |

Of the eleven runs examined after the boilerplate phase, only the two immediately following the added instruction were accurate. The source's own tally at the end of the series: **ten observations across four instruction states**, on top of the twelve boilerplate runs before the first fabrication.

## Why the steering attempt is the important part

The instruction fix looked like it worked. Two clean, accurate summaries followed the added section, after twelve boilerplate runs and one fabrication, and the staged candidate was closed as falsified: the field did not ignore instructions, it had merely been unsteered.

The next two runs, with the same instruction text in place and unchanged, both fabricated. The two clean summaries were luck, not compliance. The closure was reversed and recorded as a reversal — which is also the worked example of the promotion gate's first rule: **two observations in one direction are not reproduction.** A candidate closed on insufficient evidence is reopened, and the history is not rewritten.

What that establishes is stronger than "the field is unreliable": **steering the field is unreliable.** An instruction can produce compliant output on one run and be ignored on the next with nothing changed, so no amount of prompt work makes the field safe to show. The only safe treatment is structural.

## The rule, in working form

- **Never surface it.** Not to a user, not in an audit view, not in operator-facing text, not in a diagnostic. In the build this became: the field is captured to a process variable and consumed by nothing, and that "consumed by nothing" was verified by reading back every node's output mapping and confirming no node, variable, or expression references it.
- **Never diagnose from it.** On the one run where it happened to describe a real fault, that was coincidence; on working runs it contradicted reality. Diagnose an agent run from its structured outputs, from the rows it wrote, and from the platform's trace.
- **Never quote its numbers.** Twice it reported a confidence figure that contradicted the structured output the process actually routed on. A reader would not catch that.
- **Observability is the platform's, not the model's.** Tool calls are not observable from a process run at all — the trace lives in the agent tooling's monitor view — so any check that depends on what the agent called (tool economy, corroboration calls) is run there, by a human, never inferred from a summary.
- **The structured outputs are the record, and deterministic code writes the sentences.** Audit detail is composed at write time by the process from values in hand — the confidence the gate compared, the threshold it compared against, the remediation the lookup returned — never by asking the model to narrate what it did.
- **Generalise it.** The same treatment applies to any model-authored explanation, rationale, or "what I did" field on any platform: it is a proposal about the run, not a record of it. Where an assessment must be shown (the agent's own reasoning on a case), it is shown with attribution as machine-authored, bound to the structured outputs it accompanies, and every figure in it is one the deterministic layer can check.

## Where this sits

- `reference/silent-failure-taxonomy.md` §J carries the one-line entry.
- `reference/patterns.md` §3 (the agent folder) and §6 (agent decides, deterministic code disposes) carry the design consequences: read-only agent, no write tool, process-composed audit sentences.
- `examples/agent-eval-walkthrough.md` shows the evaluation that ran alongside these observations, in which every score was taken from the structured outputs and none from this field.

# appian-devmcp-method

Agentic coding sessions do not compound by default: each one starts without the last one's findings, and against a platform that fails silently — writes that return success and change nothing, readbacks that misreport the schema, validators that pass broken objects — an LLM coding agent that trusts its tool results ships defects with a green light on every one. This repo is the context-engineering and verification layer that makes such an agent reliable against that platform. Every session grounds in the same files in the same order, verifies by existence and readback rather than by status, and closes out into a log the next session reads first. Environment findings are promoted from the build log into the shared skill only through explicit gates, and agent behaviour changes are proven against held-constant regression specimens before they count.

It is the generic core extracted from two complete Appian demo builds driven through the Appian Dev MCP from Claude Code: the operating rules a session follows, the platform and Dev MCP facts that were measured rather than assumed, and the working patterns that carried over unchanged from one build to the next. Nothing in it names a client, an application, or a dataset.

## How it works

Three actors share one repo.

- **Claude Code** builds against the Appian Dev MCP under the operating rules in `CLAUDE.md`. It grounds in the same files in the same order every session, runs a preflight that stops the session if the build is not yet planned or the design tools are absent, verifies every write by existence and readback, and closes out by writing `Closeout.md`, updating the plan, the log, and the TODO, and pushing.
- **A claude.ai Project** plans, designs, and authors prompts. It fetches the build's current state from the repo through the GitHub connector at the start of each conversation, acts as domain expert, design partner, and skeptic, iterates HTML mockups before anything is built, and delivers complete Claude Code prompts.
- **The human operator** decides, supervises, and gates: rules on design and architecture decisions, watches that the method is followed during a run, reviews each close-out, and rules on promotion candidates.

The loop: plan in the Project → complete prompts into Claude Code → verified build work against the Dev MCP → session close-out writes `Closeout.md` and pushes → the Project fetches the current state at the next conversation → findings promote through explicit gates into the operating files: the build's own `CLAUDE.md` for project facts, and the shared skill and reference files for anything that survives the noun test.

Verification splits by what can be observed from where. Content, field state, visibility, and behaviour are checked from the terminal as each persona, through the sail CLI that ships in the Dev MCP bundle, with every observation stating the identity it ran as; geometry and paint stay in the browser.

The system also detects when its own documentation drifts from the environment. The session preflight compares the Dev MCP server's reported version against the version pinned in the reference docs, and on a mismatch Claude Code walks the operator through a written update-and-re-verification procedure (`maintenance/dev-mcp-update.md`), so documentation that describes a previous generation is flagged before it can mislead a session.

A standard project-instruction block configures the claude.ai Project: it names the build's repo, carries the build context (client, domain, use case, personas, audience, stakes, design cues), sets the fetch behaviour for `Closeout.md`, `TODO.md`, and `BUILD_LOG.md`, and assigns the expertise roles. It lives in `GETTING_STARTED.md` §2, with the notes on filling it in.

## What is in the repo

| Path | What it is |
|---|---|
| `GETTING_STARTED.md` | The operator's manual, first-time setup through the ongoing rhythm of a build: setup walkthrough, the standard project-instruction block, Phase 0 planning, the round loop, the mockup rule, close-out discipline, weekly hygiene, what not to do. |
| `CLAUDE.md` | The operating core Claude Code runs under: grounding order, preflight, the verification doctrine and its terminal-versus-browser split, identity discipline across the Dev MCP, a runtime MCP, and sail, the log and TODO contracts, the promotion loop, the close-out routine, regression discipline. |
| `skills/appian-supplemental/SKILL.md` | The user-level supplemental skill: measured platform, SAIL, and Dev MCP facts plus the portable working method. |
| `reference/silent-failure-taxonomy.md` | Every way an operation has reported success while doing something else, with the working form for each. |
| `reference/mcp-capability-boundaries.md` | What the Dev MCP cannot do, with the evidence and the workaround, and what the sail CLI reaches beyond it on published pages. |
| `reference/model-output-verification.md` | Why a model-authored summary field is never surfaced without verification, on the observations that established it. |
| `reference/toolchain.md` | Registration, authentication, server naming, docs-search, connector inheritance, the sail CLI, and the local document and source-edit pipelines. |
| `reference/patterns.md` | Reusable working patterns: prompt-driven specs, mockup-driven UI, the agent folder, authored demo packets, repeatability, guard patterns, live-agent demo operations, persona-scoped verification, the demo dry-run. |
| `maintenance/dev-mcp-update.md` | The Dev MCP update procedure, written to be executed by Claude Code: side-by-side install, config change on approval, host restart, re-verification of the toolchain and the server-behaviour entries, version pin refresh. |
| `examples/agent-eval-walkthrough.md` | Worked example of the regression-specimen discipline: six agent instruction versions probed against a held-constant specimen pair. |
| `examples/deterministic-validation-gauntlet.md` | Worked example of the governance counterpart: a sixteen-check deterministic gate between an agent's proposal and execution. |
| `examples/persona-verification-walkthrough.md` | Worked example of persona-scoped verification: a measured evaluation of the sail CLI, the designer-versus-persona diff, and the measurement record the verification split and the identity rules cite. |
| `BUILD_PLAN.md`, `BUILD_LOG.md`, `TODO.md` | Starter stubs carrying their contracts; Phase 0 populates the plan, the build fills the rest. |
| `PROJECT_INSTRUCTIONS.md` (build-owned, not in the template) | The claude.ai Project instructions, generated by Claude Code from the block in `GETTING_STARTED.md` §2 and the build's own files. It is generated thin at setup and again when Phase 0 completes, and regenerated only when the build's context changes. It is never synced from the template (`GETTING_STARTED.md` §1, step j). |
| `mockups/`, `prompts/`, `agent/`, `.work/` | Empty working directories the patterns expect: banked mockups; numbered build prompts (`prompts/NNN-<slug>.md`) with model prompt files under `prompts/model/`; agent design artifacts; deployed-source copies and harness generators. |

## Evidence

Counts are taken from the two build logs, the sail evaluation's measurement record, and this repo's own files; nothing here is estimated.

| Measure | Count | Where it comes from |
|---|---|---|
| Silent-failure classes documented | 13 classes, 125 entries | `reference/silent-failure-taxonomy.md` |
| Capability boundaries established | 56 for the Dev MCP, 11 for the sail CLI | `reference/mcp-capability-boundaries.md` §1–8 and §10 |
| sail evaluation measurements | 34, each cited where a rule rests on it | `examples/persona-verification-walkthrough.md` |
| Promotion candidates put through the gate | 148 gate evaluations, 65 promotions | the two build logs' checkpoint lines: 73 evaluations and 16 promotions in the settlement build; 41 candidates found and 17 promoted in the client-onboarding build's checkpoint-era entries, plus its one backfill pass that classified 34 earlier candidates and promoted 32; gate evaluations include re-evaluations of standing candidates across sessions, so the figure is not a count of distinct findings |
| Agent instruction versions evaluated | 6, on a held-constant specimen pair | `examples/agent-eval-walkthrough.md` |
| Deterministic checks in the validation gauntlet | 16 | `examples/deterministic-validation-gauntlet.md` |
| Model-authored summary runs examined | 23, across four instruction states | `reference/model-output-verification.md` |

These show the discipline running rather than describing it:

- `examples/agent-eval-walkthrough.md` — six agent instruction versions probed against a held-constant specimen pair, the threshold held at 0.80 on evidence rather than moved to fit the model, and a variance finding that a replicate caught before it was filed as a regression.
- `examples/deterministic-validation-gauntlet.md` — the sixteen-check deterministic gate between an agent's proposal and execution, with the incident behind each check class and the case for deterministic code over a second model pass.
- `examples/persona-verification-walkthrough.md` — one site read through sail as the design account and as a persona, the two views disagreeing in both directions, and a restricted-data leak that only the persona's view could show.
- `reference/model-output-verification.md` — the observation series across 23 runs that established why a model-authored summary is never surfaced without verification, including the instruction fix that worked once and then failed.
- `maintenance/dev-mcp-update.md` — captured from its first live execution: a Dev MCP server update in which the version pin flagged staleness, the auth documentation was re-verified against the new server's source, and stale behaviour in the silent-failure taxonomy was corrected (see the toolchain and taxonomy commit history).

## Adopting it

Ask the owner for collaborator access (the repo is private), click **Use this template** on this repo's page, then follow `GETTING_STARTED.md` end to end: first-time setup, the project-instruction block, Phase 0 planning, and the round loop.

Generalizable findings flow back as pull requests against this repo. A finding that passes the promotion gate in `CLAUDE.md` §9 — measured, noun-free, contradicting the docs or the pack or costing real time, rule-shaped, contradictions named — returns as an edit to the skill or the reference files. Client-specific material never does.

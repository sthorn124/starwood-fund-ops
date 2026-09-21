# Appian Dev MCP build — operating core

This file is the generic operating core for an Appian application built through the Appian Dev MCP from Claude Code. Copy it into a new build's project folder as `CLAUDE.md`, keep everything below as written, and add the project's own sections beneath it (vocabulary canon, data model, naming prefix, groups, business rules, repeatability rules, files in the repo). Nothing in this core names a client, an application, a record type, a dataset, or a demo scenario; everything in it applies to every build. Bracketed S-numbers cite rows of the sail evaluation's measurement record in `examples/persona-verification-walkthrough.md`.

**Skill precedence.** The user-level **appian-supplemental** skill governs environment, platform, and Dev MCP facts and the portable working method. A project skill (a `<prefix>-standards` or client-standards skill), if the build has one, governs SAIL styling, naming, colours, and this build's layout applications. This file governs the project's data model, vocabulary, and business rules and wins on conflict for project matters. appian-supplemental wins over the vendor pack and the docs only where it records a measured correction. Surprising environment behaviour discovered in a build is recorded in the build log as a promotion candidate first; it reaches appian-supplemental only through the promotion gate (§9), and the project file then keeps at most an application pointer.

## 1. Grounding order at session start

Read, in this order, before anything else:

1. **This file** (`CLAUDE.md`), in full.
2. **The client-standards / project skill**, if the build has one.
3. **The appian-supplemental skill** (user level) — mandatory before any Appian object work or any SAIL generation or edit. Load the vendor pack's Dev MCP references it names before object work.
4. **The BUILD_LOG tail** — the last session entry at minimum (roughly the last 50 lines), including the promotion checkpoint line — then the open sections of `TODO.md` and the current phase of `BUILD_PLAN.md`.

Then run the preflight (§2). Nothing is designed, written, or run before all four are read: the log tail is where the previous session left the environment, and the environment is never assumed to match the plan.

## 2. Session preflight (before any work)

1. **Confirm the build is planned.** `BUILD_PLAN.md` must exist and contain actual build content beyond the template stub: the stub marker line is gone and the Build Phases section holds at least one checklist item. If it does not, **STOP**: report that the build is not yet planned and that Phase 0 — the build plan, the demo narrative, the personas, and the entity-level data model — happens in the claude.ai Project before build sessions begin (see `GETTING_STARTED.md` §3). In this state do not create objects, seed data, or accept build prompts; the only permitted work is reading the environment.
2. **Verify the Dev MCP is connected AND the full design-object tool surface is present.** List the tools available in the session and confirm the design CRUD families are loaded — record types, fields, relationships, expression rules, interfaces, process models and nodes, sites, constants, documents, `testRule`, `testInterface`, `testProcessModel`, `validateDesignObject` — not merely `ping` or a runtime subset. Then make one trivial design read, `listRecordTypes` scoped to the **Application UUID** build parameter (§13), and confirm it returns the application's types.
3. **If the design tools are missing or the read fails: STOP.** Report the tool count and which families are present. Do not diagnose the cause, do not improvise a reduced-scope pass, do not substitute runtime tools, do not proceed degraded. A missing design surface has been measured as transient (it returned on its own the next session), so treat it as retry-next-session, not as something to work around. The one exception is a name collision, which does not clear on retry: if the tools that are present under `appian` are the runtime family (snake_case `appian_*` plus `ping`), report that a runtime server shares the Dev MCP's name (§6, `reference/toolchain.md` §2) [S34]. Note that `claude mcp list` reporting the server connected and `ping` returning 200 prove transport, not that the design surface loaded — in a collision, the `ping` that answers is the runtime server's.
4. **Check the Dev MCP and sail versions against their pins — a flag, not a gate.** Call `getDevMcpVersionInfo` and compare the reported plugin version and build stamp with the version pin at the top of `reference/toolchain.md` §1. On a mismatch: report that the server has updated and that `toolchain.md` §1 describes the previous generation; offer to walk the operator through the update procedure (they say "run the update procedure" and the session executes `maintenance/dev-mcp-update.md`); print both bundle download paths for the current site, with `<site>` taken from the registration's `LCP_URL`: the documented downloads page `https://<site>/suite/plugins/servlet/stateless/downloads` (the operator-facing entry), and the direct bundle link the version tool itself prints, `https://<site>/suite/plugins/servlet/stateless/lcp-mcp-bundle` (`maintenance/dev-mcp-update.md` Step 0); and note the drift in `BUILD_LOG.md`. Also surface the tool's own recommendations: if the site's plugin is behind the App Market, say so and note that the site admin updates the plugin before a bundle download is worthwhile, because the bundle versions with the site's plugin. Then run `sail --version` and report it beside the Dev MCP's version, compared with the sail pin in `reference/toolchain.md` §12. sail ships in the same bundle and reported the bundle's own version on the verified machine [S1]. If `sail` is missing or does not execute, say so, point the operator at `GETTING_STARTED.md` §1, and route persona-scoped checks to the browser checklist until it is installed. Unlike the plan gate, the session proceeds after reporting.
5. **Establish which MCP server every tool family belongs to and which identity it executes as** (§6). Servers are named by role: `appian` for the Dev MCP, `appian-runtime` for a runtime server. Two servers under one name shadow or merge silently [S34]:
   - **Merge:** snake_case `appian_*` tools under `mcp__appian__`.
   - **Shadow:** a connected `appian` missing the design families.
6. **Compare the repo's `skills/appian-supplemental/SKILL.md` with the installed user-level copy at `~/.claude/skills/appian-supplemental/SKILL.md`.** If they differ, say so, show which is newer, and let the human decide the direction of the sync before continuing: install the repo copy after a template update, or copy the installed skill into the repo after a promotion. Never overwrite either silently.
7. **Run the per-session ritual named in the Per-session ritual build parameter** (§13) before rendering anything — for example re-dating time-anchored fixtures with the project's idempotent script, so a stale book is not mistaken for a broken screen.
8. State the executing identity and its group scope at the top of the session's work, because every readback that follows is interpreted under it (§4). For sail, the persona sessions available on this machine are the ones step 9 reports; no sail command reports the acting identity (§6) [S2]. Compare the executing identity with the **Design account** build parameter and report a mismatch. Verify by readback, not from the plan, that the groups named in the **Security groups** build parameter exist, are nested as believed, and have members — a plan has recorded groups as nested that were siblings, and as created when they were not.

9. **Report the persona sail sessions on this machine.** Persona sessions are machine-local state. They are never written to a tracked file and never reconciled against the plan.
   - **Discover.** Take every directory matching `~/.sail-*`, plus the default `~/.sail` if it holds a `session.json`.
   - **Read each `session.json` for its `username` and `host` fields only.** The file is a bearer credential [S27], so it is never printed or copied into the session, the log, or `Closeout.md`. Read the two fields with a one-line extractor, never with `cat`. Where the file carries `"source": "devmcp"`, the directory is a designer import, not a persona, and is reported as such [S30]. A directory without a `session.json` is reported as holding no session.
   - **Check liveness, read-only:** `sail --data-dir <dir> pages <site>`, where `<site>` is the **Persona site stub** build parameter (§13).
   - **Report:** each username as **live** (the page list came back) or **expired** (an authentication error), quoting sail's error for anything else. Name the directory beside each result. If the default `~/.sail` holds a session, say so, because it should stay empty (§6).
   - **That is the whole step.** Nothing is logged in, repaired, or recorded.
   - **The username is only a claim.** It is what the operator typed at login, not something the server verified. Liveness proves the session works; which account it is still gets confirmed by observation, as §6 requires.
   - **Later in the session:** when a build prompt asks for verification as a persona that has no live session, sail's own error is the signal. Report "no live session for `<persona>`, run the login" and skip that verification. Never fall back to another identity.

## 3. Observation precedes fixes

- **Never guess before reading evidence.** Before theorising about a defect, read the deployed object, the stored expression (read back, not what was sent), the process instance's variables, the node's actual configuration, or the row itself. The reported symptom is frequently not the defect; the deployed source frequently is not what the last session believed it deployed.
- **Reproduce before changing.** Reproduce the failure, change one thing, re-measure. A control on data known to be good, or on a path known to work, is what isolates a cause; without it a fix is a guess that happened to coincide.
- **A single wrong-side reading is one draw, not a verdict.** Replicate before acting; an apparent regression has been measured as variance on a held-constant specimen.
- **A negative capability claim names its evidence** — "tried here, failed, here is the error" — never "the docs do not mention it". A capability is present if something on the instance uses it; find the working example and copy its configuration before concluding anything cannot be done.
- **Stop and report rather than improvise** when a capability is missing, when an input contract cannot be read (an agent's declared input names, a node's parameter names), or when the only next step is guessing spellings. Reporting a blocker is a complete outcome; a workaround invented under uncertainty is not.
- **Read the docs, then the instance, in that order — and the instance wins.** Docs establish what a parameter is; only the instance establishes what this environment does.

## 4. Verification doctrine

- **Writes are verified by existence and readback, never by operation status.** `COMPLETED`, HTTP 200, `error: null`, a green save and "valid" prove nothing happened. A write path is proven by exercising the actual control and counting persisted rows per record type; a delete is proven by absence (404 / zero rows) read as a full-scope account; a document is proven by existence and byte size. Direct payload inserts validate shape and bypass the control's accumulator, so they are not verification of the control.
- **Object validator over `validateExpression`.** `validateExpression` evaluates both branches of an `if`, is not a keyword check, and accepts parameters the object validator rejects; the rendered tree lists attributes that are not settable. Only the object validator (`validateDesignObject`, `createInterface`/`updateInterface`, `createExpressionRule`) is authoritative for interfaces and rules, and an interface counts as done only at `diagnostics.error: null` through `testInterface`.
- **Content, state, and behaviour are verified from the terminal, per persona, through sail; geometry and paint only in the browser.**
  - **What sail verifies.** The sail CLI (`reference/toolchain.md` §12) reads and drives published pages as whichever account its session holds [S5, S10–S13, S15, S16, S21]:
    - content, in page order;
    - field state: required, invalid, disabled, read-only;
    - visibility and conditionally rendered content, such as status-driven bands;
    - navigation through record links, tabs, related actions, and process launches;
    - behaviour: cascades, validation, and submits.
  - **Read the YAML, not just the listing.** The listing sail prints is a summary. Full grid rows, tag values, milestone details, and a changed sort order exist only in its stored YAML [S7].
  - **What sail cannot verify.** The YAML carries style values (hex colours, size and style enums) and the requested layout parameters. It carries nothing computed: no pixel sizes, positions, line breaks, or truncation [S8]. So wrapping, truncation, overflow, alignment, card heights, focus, hover, link colour against the site accent, chart drawing, and branding are never sail-verifiable. The Dev MCP's tree and harness renders cannot verify them either: they prove structure (component order, colour values, requested widths, error-free evaluation) and carry no geometry.
  - **Reporting.** Every UI summary separates terminal-verified facts, each with the account it ran as, from browser-only ones. It never describes a layout as confirmed on terminal evidence. Where a parameter's whole job is geometry, verify the parameter's value, not the shape of the content it governs.
- **A write driven through sail is verified by a fresh read of its target, never by the submit output.**
  - The submit prints the page as it was before the form opened, so the old value is still on screen after a successful write [S13].
  - The reload its own note suggests, `load --fresh`, fetches the site's default page, not the record [S13].
  - Verify by navigating to the specific page or record afterwards and, where the app has one, by its own attribution: an activity entry naming the acting user [S13].
  - A submit that validation blocked exits 0 with `✓ Interacted` [S12]. Read the ⚠ lines and the field states, never the exit code.
- **Build prompts may end with persona-scoped verification steps** — "as `<persona>` via sail: these pages resolve, this band renders, this action appears only when …" — instead of flagging those facts for browser verification; each of those three kinds of fact was read from the terminal as a persona [S4, S5, S10]. The session runs them against the operator's persona sessions and reports each result with its account. Geometry still goes to the browser checklist.
- **Readbacks must state the identity and scope they ran under, or they prove nothing.** Record-level security filters every read silently — `listRecordData`, `a!queryRecordType`, counts, min and max, related-record traversals — with no marker distinguishing absent from invisible. Write the scope into the readback ("as `<user>`, member of `<groups>`"). Before concluding rows are absent, re-read as a member of every scope or prove absence another way. A design-account render proves nothing about a persona: on one site, the design account and a persona disagreed in both directions on pages, KPI values, masked values, and available actions [S32].
- **Readbacks both over-report and under-report schema; measure behaviour, never trust metadata.** A column width has read back wider than the physical column (after an ALTER that changed nothing and returned 200) and narrower than it (a 4000-character column reported as 255). Document metadata reports an extension the runtime resolves differently. A create response has omitted relationships that exist. An integration reads back with function names that do not match what runs, and a boolean set to `false` reads back `null`. The rule is the same in every case: probe through the path production uses — a write of the real length through the real Write Records node, a runtime `document()` call, one live integration call — and treat a readback as a claim to be tested.
- **Visibility, security, and document access are verified behaviourally**, as a member and as a non-member: through sail as each persona for pages, content, values, and actions [S32], and in the browser for document access, which sail cannot reach [S9]. Nothing automated distinguishes "hidden by rule" from "hidden by a broken rule", and a visibility expression that throws hides its target without reporting.
- **A hidden branch is unevaluated, so a clean render proves nothing about it.** Anything behind `showWhen: false`, an inactive wizard step, a toggled section, or a view-switch local runs untested until it is revealed. Flip the default in a probe copy, render, restore, verify the restored source byte-identical, and re-render.
- **Gates are proven by break-test, not by a happy path.** Force the upstream failure and confirm the guarded node did not fire; a passing happy path says nothing about a gate.
- **A generated harness goes stale silently and positively.** Regenerate it in the same change that edits its source, and before trusting a harness render check that one string you know you changed appears in it.
- **Every summary lists what was NOT verified and why**, with the browser checklist the human can run for what stays browser-only — steps, personas, expected strings. Partial runs are reported as partial, never as a path exercised.
- **Verification ceremony scope:** these are build-time and change-time rules. Routine operation of a working build needs no readback, no row count, no wrapper; ceremony retires with the defect it was built for.

## 5. Docs-search consultation

The docs-search MCP is the first resort for any uncertain platform semantics — function signatures, parameter vocabularies, node behaviour, configuration options, anywhere in the platform. Never guess at a keyword, parameter value, or documented behaviour when the docs can settle it; state the documented answer before acting on it.

Layout and visual edits carry a mandatory gate: before any edit that creates or modifies interface layout, styling, or visual design — including a one-line width or colour change — consult docs-search on the parameter semantics in play (width vocabulary of the specific layout, wrapping, alignment, component interaction) together with the vendor pack's layout references the supplemental names. This area is gated because its failures are silent: keywords no-op in validators that don't reject them, a plausible invalid icon fails the whole interface at create time, and "it renders in the component tree" is not evidence a keyword is accepted.

When the docs MCP is unavailable (its session expires), say so, and settle the question by measurement on the instance, which outranks documentation in the supplemental's precedence order anyway.

## 6. Identity discipline

- **Know which MCP server and which identity every tool call runs as.** A tool's name announces its server only through the name the server was registered under, and the client's server listing may not show every server.
  - **Name servers by role:** `appian` for the Dev MCP (the name in Appian's documented registration, `reference/toolchain.md` §1) and `appian-runtime` for a runtime server.
  - **Two servers under one name fail silently in either direction** [S34]. One session carried only the desktop-inherited server's 10 tools under the name, with the design tools absent. Another carried both sets merged: 167 tools under one prefix.
  - **How each is caught.** The preflight's design-surface check (§2) exists for the first case. The tool-family tell catches the second: camelCase unprefixed design tools versus snake_case, product-prefixed runtime tools plus `ping`.
  - Confirm the executing identity when in doubt with a throwaway rule returning `loggedInUser()`, then delete it.
- **Design work goes through the Dev MCP as the designer account.** Processes are driven through `testProcessModel`; reads through `testRule` or wrapper interfaces. A runtime or service-account MCP never executes design-session work — not for tests, not for break-tests, not "just to check" — and the service account is granted no group membership or scope in the application.
- **Why this is binding:** under a foreign identity, row-secured reads return empty silently while primary-key-targeted writes still succeed. A process completes green having read nothing, and anything downstream that reasons over the empty read — an LLM especially — confabulates rather than fails, writing plausible rows into the audit trail. The tell is that text composed from the process's own parameters is correct while every record read is blank.
- **Connected systems and integrations run under their own configured credential, not the session's**, and a session cannot always see which. State which identity a probe or a process ran under, and never assume a connected system's scope from the design account's.
- **sail is a third identity path.** Beside the Dev MCP (the designer) and a runtime MCP (a service account), the sail CLI drives published pages as whichever account its session holds.
  - **Where its identity lives:**
    - It is whichever `session.json` sits in the data directory in effect [S25, S26].
    - That file is a portable bearer credential: a copy authenticated from another directory [S27].
    - No sail command prints the acting identity, and the file's `username` is only the name typed at login [S2, S25].
    - Persona-scoped reads look like plain facts: the same KPI read 94.41 as a persona and 126.01 as the designer, with nothing on screen saying which [S32].
  - **Therefore:**
    - Every sail observation states its account ("as `<persona>` via sail").
    - Each persona has its own data directory, passed on every command (`--data-dir ~/.sail-<persona>`).
    - The default directory stays empty, so a command that forgets the flag fails with "no session found" instead of running as someone [S26].
    - Identity is confirmed by observation — the pages that resolve [S4], an activity entry naming the acting user after a write [S13] — never assumed from a directory's name.
- **Persona logins are the operator's.** sail's password login reads `SAIL_USERNAME` and `SAIL_PASSWORD` from the environment and, per its help, works only for local Appian accounts. The operator logs each persona in once, and the session persists on disk [S25, S29]. A session never asks for, types, or stores a password. When a persona's session is missing or rejected, it reports "no live session for `<persona>`, run the login" and skips that verification, with no fallback to another identity (§2, step 9).
- **`--from-devmcp` is reserved for deliberate designer-versus-persona diffs, never routine verification.**
  - It imports the designer's session, so every read through it has the design account's scope [S32].
  - The import is not a copy of that session. All three cookie values are the Dev MCP's own, and `sail logout` on the import revoked the Dev MCP's server session as well [S31].
  - Import into a throwaway data directory, and discard it by deleting that directory, never by `logout`.
- **The design account is usually full-scope**, so a design-account render, count, or click proves nothing about what a persona sees [S32]. Persona checks run through sail as the persona, from sessions the operator logged in, for content, state, and behaviour. Geometry, and whatever sail cannot reach, stay browser checks owned by a human (§4).

## 7. The BUILD_LOG contract

- **Append-only session log** of what has actually been built in the environment: object names and UUIDs, versions, the decisions behind them and why, what was verified and how (with the account scope of every readback), what was not verified, and findings. Append after every build step. Corrections are new entries that name what they correct; superseded candidates in the staging section carry a bracketed in-place marker (`[RESOLVED …]`, `[REVERSED …]`, `[TRIAL REASSIGNED …]`) so a reader of that section alone never chases a dead trigger.
- **The readback is the record.** Object versions, states, and security are written from readback at close-out, never from memory; a close-out has recorded the wrong version by remembering it.
- **The tail provides continuity and is always consulted before acting** (§1). The log is the environment's state of record between sessions; `BUILD_PLAN.md` is the intent.
- **It is the staging area for promotion candidates** (§9): it carries the "Promotion candidates (staging)" section, and every entry that touches promotion ends with a promotion checkpoint.
- **Entry shape:** date and title; scope line (identity and groups every readback ran under, including the account behind each sail data directory); what changed, by object; decisions and why; verified (how, with counts and scope); not verified (and why, with the browser checklist); promotion checkpoint.
- **Structural deltas are logged like data deltas.** When a built layout departs from its mockup, say so in the log and fix the mockup in the next mockup pass, or the mockup and the build drift and neither is trustworthy.

## 8. The TODO.md contract

- **Open items by class.** The sections a build carries are: Blocking; Before demo; Browser checks owed (each with a human owner and the exact steps, personas, and expected strings); Client validation questions; Deferred (each with its trigger); Done (✅ with the date). Phase-specific sections may sit above these while a phase is live.
- **Sessions add discovered items unprompted as they surface** — deferred work, client questions, browser checks a session cannot perform, edge cases observed but not fixed — and any response that touched `TODO.md` ends with a `TODO changes:` line stating what was added, moved, or closed.
- **Every item carries an owner and a firing condition.** Parked work names the defined moment that fires it ("trigger: the next session that opens this object", "before another presenter runs it"); nothing is parked on "later".
- **Superseded items are struck through with a pointer to the standing decision**, not deleted, when the reasoning is worth keeping; completed items move to Done with the date. Retired mechanisms keep their numbering so references elsewhere still resolve.
- **A browser check a session cannot do is written as a checklist the human can run**, not as an open question.

## 9. The promotion loop

`BUILD_LOG findings → promotion candidates with named triggers → gate evaluation at close-out → promotion into CLAUDE.md or skill files`, with a checkpoint that makes it self-enforcing.

1. **Capture.** A surprising observation is recorded in the build log as a candidate the session it is found — stated as the trap and the working form, marked STAGED with the gate it is held at (usually gate 1, one observation) and a **named trigger**: the defined moment that will confirm or discard it ("the next process model with a datetime parameter", "the first traversal verified in a row-secured app", "any session where a scoped read returns empty against data known to exist").
2. **Gate.** An entry is promoted only when all five hold: **measured**, not suspected (reproduction, a control, or a deliberate re-test — two observations in one direction are not reproduction); **survives the noun test** (stateable with zero project nouns); **earns its context cost** (contradicts the docs or the pack, or cost real time); **rule-shaped** (trap and working form, instance-dependent facts tagged "re-verify per instance"); **contradictions named** (which docs page or pack file it supersedes).
3. **Home.** Portable platform and Dev MCP facts go to appian-supplemental; project facts to the project's CLAUDE.md; styling to the project skill; prompt-design and method observations that fail the noun test go to the project's agent eval log or CLAUDE.md. One home per fact; the project file keeps at most an application pointer to a promoted entry.
4. **Close-out line.** Every close-out includes "Promotion candidates: N found; promoted / listed / none", so the session that discovers a finding classifies it while it is in context.
5. **Checkpoint.** The build log carries "Promotion checkpoint: current through `<entry>`". A session that touches promotion refuses to call itself complete if the checkpoint lags the log tail by more than one session.
6. **Trigger firing.** When a trigger fires, the candidate is ruled — promoted, discarded with the gate it failed, or re-staged with a new trigger — and the ruling is written into the staging section with a bracketed marker on the old entry. A candidate closed on insufficient evidence is reopened, and the reversal is recorded rather than the history rewritten.

## 10. The close-out routine

The final actions of every session, in this order:

1. **Write `Closeout.md`** — a full, dynamic write-out of everything that happened in the run, rewritten from scratch every session in one write: no fixed template, no growth, never patched, never appended to. Its first line is the session-date header `# Closeout — <YYYY-MM-DD> — <one-line title>`, so the Project can tell from the first line whether the file it fetched describes the session it expects; everything below the header follows the session. The file and the close-out printed in the session are the same document; if the session ran through several rounds, the close-out is written from the current state of the work, not accreted round by round. Its content follows the session — typically scope and identity, what changed by object, how it works, verified and not verified, the browser checklist, rulings needed, promotion candidates, TODO changes, `BUILD_PLAN.md` changes.
2. **Update `BUILD_PLAN.md`** — mark items completed this session (`- [ ]` becomes `- ✅ <date>`) and add newly discovered tasks to the right phase. A close-out that built something but did not touch the plan is incomplete. The plan stays a high-level checklist; detailed specs live in the build prompts.
3. **Append the BUILD_LOG entry** (§7), ending with the promotion checkpoint.
4. **Evaluate promotion candidates** (§9) and write the promotion line. If a promotion changed the installed user-level skill, copy it into the repo's `skills/appian-supplemental/SKILL.md` so the machine and the repo agree and the template pull request can be raised from the build repo.
5. **Update `TODO.md`** (§8) and print the `TODO changes:` line.
6. **Commit and push:** `git add -A`, `git commit -m "closeout: <date> — <one-line summary>"`, `git push origin main`.
7. **Verify the push landed.** `git fetch origin`, then confirm `git rev-parse HEAD` equals `git rev-parse origin/main` and `git status` reports nothing to commit. A push exit code is operation status, not evidence (§4): the next conversation reads `Closeout.md` from GitHub, so a close-out whose commit is not on `origin/main` has not been handed off. On a mismatch or a rejected push, report it as a failed close-out with the git output; never force-push to make it agree.

## 11. Regression discipline

Worked examples: `examples/agent-eval-walkthrough.md` (the specimen discipline) and `examples/deterministic-validation-gauntlet.md` (the validation gate that makes agent output safe to act on).

- **Hold named test specimens constant across iterations**, so a behaviour change is attributable to the change made and not to input drift. Specimens are identified by their properties, never by platform-assigned ids, which change on relaunch. The specimen set includes a clean case and a concerning case; every tuning change is probed in both directions, because a clean-case pass alone cannot distinguish a working definition from one that says yes to everything.
- **Change one thing at a time**, state what the variable was, and replicate before acting on a single wrong-side reading (§3). When two changes go in together, record that the decisive one is not isolated rather than attributing it.
- **Pass conditions are stated before the run**, in terms the output must contain (the arithmetic stated number against number, the row written, the event absent), never in terms of a score that could be reached by luck.
- **Break-tests are part of the suite**: the forced failure that proves each gate is re-run when the gate's model changes.
- **Fixtures and harnesses move with the source.** Fixture rows are states the real flow can produce, with prose composed from the row, never authored beside it; time-anchored fixtures are re-dated as an offset from now by an idempotent script before every rendering session; a harness is regenerated in the commit that changes its source.
- **Live over fixtures.** Click tests and rehearsals run the real path with the real agent; assertions target the live run, never fixture recordings. Fixtures are break-glass for a failed readiness check, nothing else.
- **Deterministic sample data**: static values, no `rand()`, `now()`, or `today()` in seeds; regenerated by script or corrected by targeted in-place writes, never hand-edited.

## 12. Writes against demo data

- **Every automated write names its targets explicitly and never sweeps.** Seeders, backfills, reshifts, and in-place fixes carry an explicit id list — never a query, a range, or "all rows where…" — so the blast radius is readable in the payload before the call is made and a growing data set cannot widen it.
- **Never mint a key as `max()+1` over a row-secured record type**; let the source assign keys, take foreign keys from relationships, or mint from an unsecured type.
- **Cleanup is verified by absence** as a full-scope account, children before parents. Throwaway probe objects carry a `zz` or `tmp` marker in their names and are deleted in the same session that created them, with the deletion confirmed by a 404 or an empty list. Deleting a design object is irreversible over MCP, so a throwaway from another session is deleted on the owner's word, not on inference.

## 13. Project sections (added per build, below this line)

**Build parameters.** The project sections open with this block. It holds the build-specific values that core steps read by name. Copy it to the top of the project sections and fill it in before the first build session.

- **Rule for an unset value.** A value the build cannot have yet — for example an application that Phase 1 has not created — is written `unset` with the reason. A step that needs an unset or blank parameter reports "build parameter `<name>` is unset" and skips the check that needs it. It never guesses a value.
- **Changing a value.** Values change only through an edit to this block. A preflight report never writes one.

```
## Build parameters

| Parameter | Value | Read by |
|---|---|---|
| Application UUID | <uuid of the build's Appian application> | §2 step 2 (design read) |
| App prefix | <object-name prefix, e.g. ABC> | §13 naming; no preflight step reads it |
| Design account | <account the Dev MCP signs in as> | §2 step 8 (identity check) |
| Security groups | <groups the build gates on, with nesting> | §2 step 8 (group readback) |
| Per-session ritual | <script and trigger, or "none"> | §2 step 7 |
| Persona site stub | <URL stub of the site personas use> | §2 step 9 (sail liveness) |
```

Add, in the build's own words: vocabulary canon (exact stored values and display labels); data model and relationships; naming prefix and groups; business rules implemented once as shared rules; demo repeatability rules (session tagging, reset and verify-ready actions, reserved id ranges); known data artifacts that are deliberately not fixed, each with what shows, why, and what to say; the files in the repo and what each is for.

---

# Project: Starwood — draw approval (added to the subscription-intake app)

This build adds the **draw approval** flow to an existing Appian app on `ny.appiancloud.com`, the subscription-intake demo app (`Starwood Demo`). Draw approval covers capital call draws for renovation and development projects. **"Draw approval" is the canonical name for the new flow.** Use it, in exactly that wording, in every object, document, and commit. The intake app existed before this repo did, so its state lives on the instance. `BASELINE_INVENTORY.md` records it as found on 2026-09-21.

## Build parameters

| Parameter | Value | Read by |
|---|---|---|
| Application UUID | `dd3bb740-b105-421b-a866-29d542a144da` (application `Starwood Demo`, URL identifier `HiQyLQ`) | §2 step 2 (design read) |
| App prefix | `SD`, as read from the application on 2026-09-21. Existing objects also carry `SA` / `SA_` (for example `SA Fund` and `SA_NewSubscriptionUploadForm`), and two are unprefixed (`Subscription Agreement` and `Subscription Agreement Analysts`). New draw approval objects use `SD`. | §13 naming; no preflight step reads it |
| Design account | `scott.thorn@appian.com`. This is the username recorded in the Dev MCP session file for `ny.appiancloud.com` on 2026-09-21. It has not yet been confirmed with a `loggedInUser()` probe, because the plan gate forbids creating objects. | §2 step 8 (identity check) |
| Security groups | Existing: `SD Users` contains `SD Administrators`, `SD Fund Operations Manager`, `SD Fund Operations Analyst` and `SD Compliance Reviewer`. `Subscription Agreement Analysts` and `SD Compliance Reviewers` are not nested under `SD Users`. The draw approval groups are **unset**: their roles and nesting are Phase 0 decisions. | §2 step 8 (group readback) |
| Per-session ritual | none. No time-anchored fixtures exist yet. | §2 step 7 |
| Persona site stub | **unset**. The application contains no site (`listApplicationObjects` returned sites: 0 on 2026-09-21), so there is nothing for personas to load through sail yet. | §2 step 9 (sail liveness) |

## MCP servers this build uses, and the runtime connector

- **Named servers.** This build uses `appian` (the Dev MCP, which is the designer identity) and `appian-public-docs` (docs search). Every other server in the session is ignored, per `reference/toolchain.md` §4.
- **The runtime connector is present in Code sessions, inherited from the desktop app.** It was checked on 2026-09-21:
  - The server is `appian-runtime`, kind `desktop`, with 10 snake_case tools (`appian_*` plus `ping`).
  - It is registered in the desktop app's own `claude_desktop_config.json` through `mcp-remote` to `https://ny.appiancloud.com/mcp`. `~/.claude.json` does not declare it, so `claude mcp list` does not show it.
  - Per the operator, it runs as the **`scott.mcp` service account**. This session did not call it, so that identity has not been confirmed by observation.
- **The runtime connector is not the designer identity. Never use it for build work.** Its tools are banned in this build by name: `mcp__appian-runtime__*`. That covers tests, break-tests, and "just to check" reads (§6).
  - The naming split holds today: `appian` has 157 camelCase design tools and `appian-runtime` has 10 runtime tools, with no collision.
  - Re-check the names after any desktop-app update (`reference/toolchain.md` §2).
- **Open issue: the service account has scope in this application.** `scott.mcp` and `NoahMCPServiceAccount` are members of `SD Administrators`, and so they are also in `SD Users`. This contradicts §6, which says a service account is granted no group membership in the application. The finding is recorded in `TODO.md`. This session did not change it.

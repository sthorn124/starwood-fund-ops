# BUILD LOG — Starwood draw approval

What has actually been built in the environment, with object identifiers and the decisions behind them. Append after every build step; never rewrite a closed entry — a correction is a new entry that names what it corrects. Entry shape: date and title; scope line (the identity and group memberships every readback ran under); what changed, by object; decisions and why; verified (how, with counts and scope); not verified (and the browser checklist that covers it); promotion checkpoint. The contract is `CLAUDE.md` §7; the promotion loop is §9.

**Promotion checkpoint: current through 2026-09-21 — Phase 2a: browser checks, rulings, width and race verification — level with the log tail.** A session touching promotion refuses to call itself complete if this checkpoint lags the log tail by more than one session.

## Promotion candidates (staging)

*(Session close-outs append here: "Promotion candidates: N found; promoted / listed / none". Each staged candidate states the trap and the working form, the gate it is held at, and a named trigger — the defined moment that will confirm or discard it. A superseded candidate gets a bracketed in-place marker — `[RESOLVED …]`, `[REVERSED …]`, `[TRIAL REASSIGNED …]` — never a rewrite, so a reader of this section alone never chases a dead trigger.)*

- **[RESOLVED 2026-09-21: already recorded; the supplemental skill lags it. See the ruling below.]** **STAGED (gate 1: one observation) — listing group members worked over the Dev MCP here, contradicting appian-supplemental §3.**
  - *The skill says:* `listGroupMembers`, `getGroup` and `addGroupMembers` return HTTP 403 across the whole surface.
  - *Observed:* on `ny.appiancloud.com` with DevMCP plugin 26.6.95 and bundle stamp 20260903-195919, `listGroupMembers` returned 200 with members for all seven application groups, as `scott.thorn@appian.com`.
  - *Unknown:* whether this is a plugin-version change or a property of this instance. `getGroup` and `addGroupMembers` were not tried.
  - *Trigger:* the first session that needs to add a member to a draw approval group. Try `addGroupMembers` there and read the result back with `listGroupMembers`. Then rule on this candidate: promote it (re-verify per instance), or discard it with the gate it failed.

- **Ruling, 2026-09-21, on the `listGroupMembers` candidate: RESOLVED as already recorded.** Nothing is promoted from this build.
  - *Where the fact already lives:* `reference/mcp-capability-boundaries.md` ("Group membership: reading now works, writing unverified"). It records that group reads work from DevMCP 26.6.90, measured live. This build's observation, and a re-read on 26.6.95 (`listGroupMembers(uuid, directOnly: true)` returned 3 direct members of `SD Administrators`), agree with it.
  - *The actual defect:* appian-supplemental §3 ("GROUP MEMBERSHIP ADMINISTRATION IS NOT AVAILABLE OVER THE DEV MCP") still states the previous generation's 403 for reads. That skill text is stale against the repo's own boundaries doc.
  - *Follow-up:* the correction is a TODO for the skill's owner, not a new promotion.
  - *Membership writes:* `addGroupMembers` stays unverified. Its trigger remains the first session that adds a member to a draw approval group.

- **[RESOLVED 2026-09-21: measured through the production path; promoted to `reference/mcp-capability-boundaries.md` §7-class entry, not to the supplemental until a second instance confirms it.]** **STAGED (gate 1) — TEXT column widths under-report on readback at create time.** Fields created with `length` 1000 or 20 read back as `VARCHAR(255)`, while a 289-character `insertRecordData` write to a "1000" column succeeded and read back intact. Working form: treat the readback as a claim and prove width by a real-length write through the production path. *Trigger:* the first Write Records node write longer than 255 characters to a draw approval column (the `comments` or `contingencyExplanation` fields).
- **STAGED (gate 1) — `addGroupMembers` works on DevMCP 26.6.95.** Three user adds returned `status: success` and each read back with `listGroupMembers(directOnly)`. This closes the "writing unverified" gap in `reference/mcp-capability-boundaries.md` (updated in this session) and further dates supplemental §3. *Trigger:* the next group-membership write on another instance, to tag it "re-verify per instance" or general.
- **STAGED (gate 1) — a subprocess node maps the child's parameter PVs back out through `outputs[].saveInto`.** With `referenceUuid` set, the schema lists every parameter PV as an output; `{"name": "outcome", "saveInto": "pv!decisionOutcome"}` carried the child's result to the parent on a synchronous call. Input mappings were bare `pv!x` strings in `inputs` with no `customInputs` block, and they worked. *Trigger:* the next subprocess node built on any build.
- **STAGED (gate 1) — `completeTask(taskId, inputs: [{name, value}])` completes a user input task with ACP values, including ACPs the node reads back as `required: true`.** The form's own button logic does not run on this path, so every ACP must be supplied. *Trigger:* the next MCP-driven task completion.
- **STAGED (gate 1) — `testProcessModel` with `timeoutSeconds: 60` returned a client `Network error: ReadTimeout` at roughly 60 s while the process kept running to completion.** The error is transport, not the process; verify by reading the data. *Trigger:* the next run expected to exceed 45 s.
- **STAGED (gate 1) — `updateRecordData` with an empty CSV cell clears the value (sets null).** Measured on DATETIME, INTEGER and TEXT columns. *Trigger:* the next reset or backfill that must leave a column untouched, where the column is omitted from the CSV instead.
- **[RESOLVED 2026-09-21: the value persists; confirmed in Designer (Properties → Alerts shows `SD Administrators` on all four models). The readback gap stands as recorded.]** **STAGED (gate 1) — `createProcessModel(errorAlertGroupUuid)` cannot be read back over the Dev MCP.** `getProcessModel` returns no alert-group field at all, so persistence is unmeasurable here; the check is a Designer step. *Trigger:* the next Dev MCP generation, to see whether the readback gains the field.

- **STAGED (gate 1, 2026-09-22) — `a!forEach` that returns `{}` for skipped items is not a filter.** When *every* item is skipped the result is N null placeholders (a KPI counted 6 "awaiting" rows for a viewer with none), while a mixed result drops them; and an empty `a!forEach` result keeps the source list's type, so `wherecontains(true, …)` over it fails with "Invalid types (Boolean, <record type>)" (a view rendered for a draw with lines and errored for one without). Working form: `if(a!isNullOrEmpty(list), {}, index(list, wherecontains(value, a!forEach(items: list, expression: <boolean or text>)), {}))`. Measured in both directions (failure, then the fix, on the same specimens). *Trigger:* the next interface that filters a list in SAIL.
- **STAGED (gate 1, 2026-09-22) — `text()` truncates, it does not round.** 368,899,430.77 printed as $368,899,430 and 2,491,584.83 as $2,491,584 under `"$#,###,###,###,##0"`; `round(value, 0)` first gives 431 / 585. Extends the supplemental's "text() truncates and needs explicit thousands groups" with the rounding half. *Trigger:* the next money format written.
- **STAGED (gate 1, 2026-09-22) — `min()` over a list of Dates returns a value that formats a day early.** `text(min({date(2026,10,15)}), "MMM D")` printed "Oct 14" for the designer; computing the offset in days from `today()` and adding it back printed "Oct 15". Time-zone shift on the datetime that `min` returns. *Trigger:* the next date aggregate shown to a user.
- **STAGED (gate 1, 2026-09-22) — `updateSite` with the existing pages passed by `uuid` alone preserved their URL stubs** (`2rcKrQ`, `VRvmbQ`, `tO9EuA` read back unchanged after adding a fourth page). This contradicts the earlier warning carried in `BUILD_PLAN.md` that `updateSite` regenerates every stub; that warning may describe the full-page-object form of the call. *Trigger:* the next `updateSite` on any site.
- **STAGED (gate 1, 2026-09-22) — the open task of a process is reachable in SAIL only through a task report, and the platform ships one.** `a!queryProcessAnalytics(report: todocument(<id of "Current Tasks for Process.arf">), contextProcessIds: {pid}).data[1].dp0` returns the task id, which `a!processTaskLink` accepts; a persona who is an assignee rendered the link (sail, as `sd.assetmanager`). The report's document id is instance-specific (39 here; found by walking `folder(6, "folderChildren")` — folders 3–6 are the System Knowledge Center's roots, and the Task Reports folder had been moved into a "Misc Routines" KC). `tp!id` cannot be written earlier: custom outputs evaluate at the end of the task (docs). Re-verify per instance. *Trigger:* the next build that links a record view to a live task.
- **STAGED (gate 1, 2026-09-22) — sail does not follow a task link.** A `cardLayout` whose `link` is `a!processTaskLink` is listed as `<display>`, not `⤴ <navigate>`; the stored YAML carries the `ProcessTaskLink` with its task id, so the target is terminal-verifiable, the click is a browser check. *Trigger:* the next persona check that must open a task.
- **STAGED (gate 1, 2026-09-22) — a record link to a record type with no summary view fails interface validation** ("Record links will not work until the record type has a summary view"), so the summary view's own interface cannot carry a record link at creation: create it with the link stubbed, add it as the summary view, then restore the link with `updateInterface`. *Trigger:* the next record type whose first view links to itself.

- **STAGED (gate 1) — an accelerator that reads a draw immediately after a task submit sees a half-applied transition and must settle first.** Measured: 10 s after `completeTask`, the approval rows were already updated but the draw's `currentStep` was not, so a decision computed from that read was refused as STALE. Working form: before the first decision, re-read on a 5 s timer until the row at `currentStep` is In Progress and the state is identical across three reads (18–24 s measured), with a ceiling that stops rather than guesses. Portable shape: "a multi-write transition is not atomic to a concurrent reader; a driver that follows one must wait for a consistent, stable state." *Trigger:* the next build with a process that chains decisions across a multi-node write transition.

## Entries

### 2026-09-21 — Instantiation and read-only preflight

**Scope.**
- **Design reads:** Dev MCP (`appian`, 157 tools) as `scott.thorn@appian.com`, as recorded in the session file. That account is a member of `SD Administrators` and `SD Users`.
- **sail:** no persona sessions exist.
- **Runtime MCP:** `appian-runtime` was present but not called.

**What changed.** Nothing on the instance. Repo files only:
- `CLAUDE.md`: the build parameters and the MCP-servers note.
- `BASELINE_INVENTORY.md` and `PROJECT_INSTRUCTIONS.md`: new.
- `TODO.md`, `Closeout.md`, and this log.

**Preflight findings.**
1. **Plan gate: STOP.** `BUILD_PLAN.md` is still the template stub. No objects were created and no data was seeded. Only reads were made.
2. **Dev MCP design surface present.** 157 tools, including the record-type, interface, process-model, site, constant, document, test and validate families. `listRecordTypes` scoped to the application returned 16 types.
3. **Version drift.**
   - *Server and plugin:* the plugin is 26.6.95 (App Market up to date, built 20260911-210447). The local bundle is 20260903-195919 (`mcp_src_sha` `a037e2a260ba8fee`), which is the 26.6.90 build that `toolchain.md` §1 pins. The server reports that the bundle is out of sync with the plugin (plugin `mcp_src_sha` `71a81a27e39421db`) and recommends re-downloading it.
   - *Where to get the bundle:* the downloads page `https://ny.appiancloud.com/suite/plugins/servlet/stateless/downloads`, or the direct link `https://ny.appiancloud.com/suite/plugins/servlet/stateless/lcp-mcp-bundle`.
   - *sail:* reports 26.6.90, which matches its pin but trails the plugin.
   - *Branch:* the plugin was built from a detached branch.
4. **Servers and identity.**
   - `appian` is a user-config stdio server with 157 camelCase tools.
   - `appian-runtime` is inherited from the desktop app, with 10 snake_case tools (`appian_*` plus `ping`). It points at `https://ny.appiancloud.com/mcp` and, per the operator, runs as `scott.mcp`; this session did not verify that.
   - The two servers have separate names, so there is no shadow and no merge.
   - The design identity is taken from the Dev MCP cookie file's `username` field. A `loggedInUser()` probe was skipped because it would create an object.
5. **Skill sync.** The repo copy and the installed copy of `appian-supplemental` are byte-identical.
6. **Per-session ritual:** none.
7. **Groups, read back** with `listGroupMembers` (all members, including inherited):
   - `SD Administrators`: `NoahMCPServiceAccount`, `scott.mcp`, `scott.thorn@appian.com`.
   - `SD Users`: those three users plus the nested groups `SD Administrators`, `SD Compliance Reviewer`, `SD Fund Operations Analyst` and `SD Fund Operations Manager`.
   - `SD Compliance Reviewers`: `alexis.kane@appian.com`.
   - `SD Fund Operations Manager`, `SD Compliance Reviewer`, `SD Fund Operations Analyst` and `Subscription Agreement Analysts`: empty.
   - **Finding:** service accounts sit in `SD Administrators`, which contradicts §6.
8. **Persona sessions:** `~/.sail` and `~/.sail-designer` exist, and neither holds a `session.json`. There are no live persona sessions. The persona site stub is unset because the application has no site.

**Application identified.**
- `Starwood Demo` (`dd3bb740-…a144da`, prefix `SD`) is the subscription-intake app. It was matched by its object names and descriptions, such as the subscription packet intake models and the Fund Operations groups.
- Also seen on the instance, and out of scope unless ruled otherwise: `New Fund Instruction Intake` (NFII) and `Capital Calls & Distributions` (CCD).

**Spec artifacts.** All three are present and readable:
- *Current email PDF:* one page, the table-based approval email.
- *New email PDF:* one page, with added sections for draw detail by budget category, budget summary, remaining contingency, QIU detail and approval status.
- *Enhancements xlsx:* one sheet with the seven current workflow steps and the Sep/Oct 2026 enhancements on steps 2, 4, 5 and 6.

All three are gitignored (`*.pdf`, `*.xlsx`), so they are not pushed.

**Verified.** Every fact above comes from a Dev MCP read as the designer, from a local file read, or from `sail --version`.

**Not verified.**
- The executing identity by probe.
- The runtime connector's identity.
- The fine print of the new email PDF. It was rendered at 612×792, so detailed reading of its tables needs a higher-resolution render.
- Object types beyond the five inventoried.

**Promotion.** 1 candidate found (group-member listing works here): listed as STAGED, none promoted.

Promotion checkpoint: current through 2026-09-21 — Instantiation and read-only preflight.

### 2026-09-21 — Phase 0 rulings and Dev MCP update attempt

**Scope.**
- **This is a ruling session.** No build work was done and nothing on the instance was written.
- **The one Dev MCP read** was `getDevMcpVersionInfo`, as `scott.thorn@appian.com` from the session file. That account is a member of `SD Administrators` and `SD Users`.
- **Not used:** `appian-runtime` and sail.

**Ruling 1: the service accounts in `SD Administrators` are an exception, not removed.**
- `scott.mcp` and `NoahMCPServiceAccount` stay in `SD Administrators`, and so in `SD Users`.
- *Reason:* `scott.mcp` backs the chat runtime connector. On a demo instance, removing it is a risk not worth taking.
- *Where it is recorded:* a project exception block at the end of `CLAUDE.md` §6, the clause it contradicts. The "Open issue" bullet in the project section now points to that block.
- *What stays in force:* the rest of §6. `mcp__appian-runtime__*` still never runs design-session work.
- *TODO:* the service-account item is closed and moved to Done.

**Ruling 2: the host application.**
- Draw approval lives in `Starwood Demo` (`dd3bb740-b105-421b-a866-29d542a144da`), which is confirmed.
- `Capital Calls & Distributions` belongs to a different client and is out of scope for this build. It is not to be read from or referenced.
- *Where it is recorded:* `PROJECT_INSTRUCTIONS.md` (header facts) and the `CLAUDE.md` project section.
- *Correction:* this corrects the previous entry, which listed that app as "out of scope unless ruled otherwise". It is now out of scope by ruling.
- *TODO:* the client-validation item is closed and moved to Done.

**Dev MCP update: stopped at Step 0. No versions changed.**
- **Ordering rule, per `maintenance/dev-mcp-update.md`:** `getDevMcpVersionInfo` re-run.
  - *Plugin:* 26.6.95, build `20260911-210447`, `mcpSrcSha` `71a81a27e39421db`. App Market status `UP_TO_DATE`, so the plugin side needs nothing.
  - *Local server:* build `20260903-195919`, `mcp_src_sha` `a037e2a260ba8fee`, which is the 26.6.90 pin.
  - *Verdict:* this is still out of sync, so an update is warranted.
- **Bundle check:** the only Dev MCP bundle in `~/Downloads` is `appian-dev-mcp-server-bundle.tar.gz` (Sep 12, 11,784,292 bytes). The `BUILD-INFO.txt` inside it, read without extracting, shows `build_timestamp=20260903-195919`, the installed generation. The other `lcp-mcp-server-bundle*.tar.gz` files date from July and belong to the previous generation.
- **Result:** the procedure stops here. Installing this bundle would reinstall 26.6.90.
- **Why the session could not continue:** Step 0, downloading the bundle, is an operator step behind the site login. Phase 2's version check also needs a full app relaunch, so versions cannot be verified as matching within this session.
- **Nothing was touched:** no install directory, no registration, and no sail link.
- **Prerequisites confirmed for Phase 1:**
  - Python 3.14.6 and uv 0.11.28.
  - The current registration is the documented shape (`uv run --directory /Users/scott.thorn/appian-dev-mcp-server python -m lcp_mcp_server`, with env `LCP_URL` only).
- **Pins:** `reference/toolchain.md` §1 and §12 are unchanged, because nothing was re-verified.

**Verified.**
- The version report came from `getDevMcpVersionInfo`.
- The bundle's build stamp was read from the tarball.
- The ruling text was read back in the files.

**Not verified.** Any version match after an update, because no update took place.

**Promotion.** 0 new candidates. The staged `listGroupMembers` candidate is unchanged; its trigger has not fired.

Promotion checkpoint: current through 2026-09-21 — Phase 0 rulings and Dev MCP update attempt.

### 2026-09-21 — Dev MCP update, Phase 1 (install): 26.6.90 → 26.6.95

**Scope.**
- **This is maintenance.** There was no build work and no instance writes.
- **No Dev MCP calls this session.** The version report used is the one from the previous entry: plugin 26.6.95, build `20260911-210447`, `mcpSrcSha` `71a81a27e39421db`.

**This supersedes the previous entry's Step 0 blocker.** The operator downloaded the bundle.

**Steps, per `maintenance/dev-mcp-update.md` Phase 1:**
- **Bundle:** `~/Downloads/appian-dev-mcp-server-bundle (1).tar.gz`, downloaded 2026-09-21 17:26, 11,910,499 bytes, sha256 `a342f936…883544`.
  - The name carries a browser suffix. It was identified by content rather than by asking the operator: its `BUILD-INFO.txt` shows `build_timestamp=20260911-210447` and `mcp_src_sha=71a81a27e39421db`, identical to the plugin's report.
  - The old Sep 12 bundle (stamp `20260903-195919`) is also still in Downloads. Neither bundle was deleted.
- **Prerequisites:** Python 3.14.6 and uv 0.11.28. The bundle's `pyproject.toml` requires Python `>=3.13`, which is met. The package version is still `0.1.0`, so the build stamp is the discriminator.
- **Side-by-side install.**
  - *Locations:* `NEW_INSTALL` is `~/appian-dev-mcp-server-20260911-210447`. `pyproject.toml` sits at the archive root, alongside `bin/`, `lib/`, `sdk/` and `src/lcp_mcp_server`. `OLD_INSTALL` (`~/appian-dev-mcp-server`) is untouched and kept as the rollback.
  - *Sync:* `uv sync` succeeded and the `.venv` exists. `import lcp_mcp_server, playwright` succeeded.
  - *Browser:* `sync --extra browser` failed with "Extra `browser` is not defined". That is harmless, because Playwright is a core dependency. Playwright Chromium 153.0.8010.12 was installed, and a headless launch test returned the page title.
- **sail:** `NEW_INSTALL/bin/setup-mac.sh` cleared the quarantine flag and repointed `~/.local/bin/sail` from the old bundle's binary to `NEW_INSTALL/bin/sail-darwin-arm64` (sha256 `5ccd5559…901bca`).
  - `sail --version` now reports `sail version 26.6.95`, and `sail --help` runs.
  - The old binary remains in `OLD_INSTALL/bin/` for rollback.
- **Registration.**
  - *Scan:* the only Dev MCP registration is the global `appian` entry in `~/.claude.json`. A depth-2 scan under `~` found no project `.mcp.json` carrying the Dev MCP. The desktop config's `appian-runtime` entry is a different server and was not touched.
  - *Change:* on the operator's approval, `~/.claude.json` was backed up to `~/.claude.json.bak-2026-09-21-devmcp-update`, and only `mcpServers.appian.args[2]` (`--directory`) was changed, to `NEW_INSTALL`. A structural diff against the backup shows that single change. The env is unchanged (`LCP_URL=https://ny.appiancloud.com`).
  - *Config compatibility:* the new `config.py` differs from the old one only by a reformatted `LCP_API_PATH` line and a renamed property (`beta_base_url` → `lcp_base_url`). The environment variables read are unchanged.

**Verified.**
- The bundle's build stamp matches the plugin's.
- Imports succeed and the headless browser launches.
- `sail --version` reports 26.6.95.
- The registration was read back from the file.

**Not verified.**
- That the running server is the new one. The running session keeps the server process it started with.
- That `getDevMcpVersionInfo` reports plugin and bundle in sync.

Both are Phase 2 checks and need a fresh session after a full quit and relaunch.

**Pins:** `reference/toolchain.md` §1 and §12 are not yet refreshed. That is Phase 2, step 4.

**Promotion.** 0 new. The staged `listGroupMembers` candidate carries over, and Phase 2's boundary sweep (group membership) should re-check it under the new server.

Promotion checkpoint: current through 2026-09-21 — Dev MCP update, Phase 1 (install).

### 2026-09-21 — Dev MCP update, Phase 2 (re-verify): 26.6.95 confirmed running

**Scope.**
- **Maintenance only.** There was no build work and no instance writes.
- **Dev MCP reads:** `getDevMcpVersionInfo`, `listRecordTypes` (limit 1) and `listGroupMembers` (`SD Administrators`, `directOnly`), as `scott.thorn@appian.com` from the session file. That account is a member of `SD Administrators` and `SD Users`.
- **Not used:** `appian-runtime`. No persona sail sessions were available.
- **Relaunch and sign-in:** the operator relaunched after Phase 1. No SSO window was needed, because the persisted session under `~/.appian-devmcp/` was reused.

**Step 1: the running server.**
- `getDevMcpVersionInfo` reports the plugin as 26.6.95 (build `20260911-210447`) and the MCP server as build `20260911-210447`, with `mcp_src_sha 71a81a27e39421db` on both halves.
- Its recommendation: "No action needed: both halves are up to date and came from the same build."
- The build stamp equals `NEW_INSTALL/BUILD-INFO.txt`. **The versions match.**
- The session lists `appian` with 157 tools and `appian-runtime` with 10, so the names are still separate. The design read returned 16 record types.

**Step 2: the real version.** Plugin 26.6.95 per the tool. The package version is still `0.1.0` in `pyproject.toml`, so the build stamp is the discriminator. The bundle ships no changelog; its `INSTALL.txt` covers sail setup only.

**Step 3: the source diff against 26.6.90.** ASTs were compared to separate logic changes from reformatting.
- `browser_auth.py` is byte-identical (sha256 `bcf11935…`, the same as the pin). Auth default, environment variables, state directory, expiry handling and logout are therefore unchanged.
- `config.py`: the only substantive change is a property rename, `beta_base_url` → `lcp_base_url`.
- `server.py`: the LCP client is renamed off "beta", and a new `enforce_generate_interface_sail` flag is added.
- **Tool inventory:** 157 → 157, the same names, equal to the live count.
- **Logic changes that matter to a build:**
  1. An inline-SAIL guard on `createInterface` / `updateInterface`, active only when `SAIL_MCP_ENABLED=true`. It is off here.
  2. `createProcessModel` now takes `errorAlertGroupUuid` in place of `errorAlertGroupName`. Persistence is unmeasured.
  3. Record type `securityMode` is validated client-side.
  4. Integrations have response-to-document properties.
  5. Any 2xx on a DELETE is treated as success.
  6. Non-blocking write checkpoints for a hosted copilot, inert in a local stdio session.

**Step 4: pins refreshed.**
- `reference/toolchain.md` §1 now reads "Verified against DevMCP 26.6.95", with the build stamp and hashes as reported by the tool, `NEW_INSTALL`, today's date, the `browser_auth.py` sha256, and the rollback path.
- §12 now reads "Verified against sail 26.6.95", with the binary path and sha256 `5ccd5559…901bca`.

**Step 5: sail.**
- `sail --version` reports 26.6.95.
- Help for the root and all nine subcommands, captured from both binaries, is byte-identical (328 lines each).
- No persona session exists, so the read-only live measurements (pages, load, show offline, JSON error stream) were **not re-run**. The write-dependent entries were also not re-measured.

**Step 6: sweep.**
- *Names:* no live reference to the old install path remains outside the rollback notes and the historical log and walkthrough.
- *`reference/mcp-capability-boundaries.md`:* gained a "Changed in DevMCP 26.6.95" block, and its `errorAlertGroupName` entry was annotated.
- *`reference/silent-failure-taxonomy.md`:* its `errorAlertGroupName` entry was annotated.
- *Other behavioural entries left as recorded:* ping as a false positive, transport marshalling, instance enumeration, multiple node instances, attended tasks, agent reads. The files implementing them changed only by reformatting, or the entries are plugin-side.
- *Group membership:* re-read live on 26.6.95, and it works.

**Promotion.**
- The `listGroupMembers` candidate is **RESOLVED** (see the staging section). It was already recorded in the boundaries doc; appian-supplemental §3 is stale and its correction is a TODO.
- 0 new candidates.

**Verified.**
- The version match came from the tool.
- The source diffs were run locally.
- The sail help diff was run locally.
- Group reads and the record-type read were live, as the designer.

**Not verified.**
- Whether `errorAlertGroupUuid` persists.
- The inline-SAIL guard's error in practice (it is off).
- Write checkpoints.
- sail's behaviour against a live persona on 26.6.95.

**Rollback.** Still available: `~/appian-dev-mcp-server`, its `bin/` sail binary, and `~/.claude.json.bak-2026-09-21-devmcp-update`.

Promotion checkpoint: current through 2026-09-21 — Dev MCP update, Phase 2 (re-verify).

### 2026-09-21 — Phase 0 transcription and build plan

**Scope.**
- **Docs only.** No build work and no instance writes.
- **Two read-only Dev MCP calls** as `scott.thorn@appian.com`, a member of `SD Administrators` and `SD Users`: `listRecordData` on `SA Fund` and on `Subscription Agreement`. They ground two plan facts, recorded below.
- **Not used:** `appian-runtime` and sail.

**What changed.** Repo files only:
- **`PROJECT_INSTRUCTIONS.md`:** the seven Phase 0 sections were filled with the supplied text, verbatim (a diff against the supplied text shows it byte-identical). The header facts are unchanged, and the italic status line now says Phase 0 is complete.
- **`BUILD_PLAN.md`:** rewritten from the template stub. It passes the plan gate: the stub marker is gone and `## Build Phases` holds 53 checklist items across Phases 0–5.
  - Each phase lists the objects to create or modify, its dependencies, its verification (pass conditions and break-tests stated in advance), and its demo-visible outcome.
  - **Phase 1 is marked as the next session's scope.**
- **`TODO.md`:** the Blocking item "Phase 0 plan" is closed, the persona-accounts item is sharpened, and 7 transcription discrepancies are added as client validation questions.

**Design decisions in the plan, and why.**
- **The approval process is event-driven and unattended.** `SD Apply Draw Approval Decision` takes the draw id, the decision, comments and the actor. It is not a long-running process with user input tasks, because `testProcessModel` refuses attended models (supplemental §9). That keeps every routing path verifiable over MCP.
- **The demo accelerator reuses the same decision process** step by step, with a hard ceiling, so the accelerator cannot diverge from the real routing rules.
- **The treasury notification is gated on the final-approval write,** never merely sequenced after it (supplemental §6 and §9).
- **Doc Center work starts by reading the existing `SD Process Packet (async)` configuration:** a working example on the instance comes first (supplemental §1).
- **Model calls stay out of expression rules,** and AI output passes a deterministic validation gate before any alert or state change uses it.

**Facts read (as the designer).**
- `SA Fund` id 4 is "Harborline Real Assets Fund II, L.P.", so the narrative's fund exists.
- Blue Granite Pension Trust has multiple `Subscription Agreement` rows on fund 4, all "Under Review" or earlier, none Accepted. This is recorded as a narrative continuity question.
- `Starwood Demo` has no investment or property entity. This is recorded as a data-model question.

**Verified.**
- The verbatim transcription, by diff.
- The plan gate, by a structural check.
- The two record reads, with scope stated.

**Not verified.** The fine print in the spec PDFs (the QIU row count and the approval step count). The earlier render was low resolution, so a high-resolution re-read is queued as part of the discrepancy questions.

**Promotion.** 0 candidates found.

Promotion checkpoint: current through 2026-09-21 — Phase 0 transcription and build plan.

### 2026-09-21 — Phase 0 discrepancy rulings applied

**Scope.** Docs only: no build work, no instance reads or writes, and no MCP or sail calls.

**This corrects the Phase 0 transcription entry.** The operator ruled all seven discrepancies raised there. The text of `PROJECT_INSTRUCTIONS.md` changes for the first time since the verbatim transcription.

**`PROJECT_INSTRUCTIONS.md`:**
- **Narrative.**
  - Beat 4: orders 1–2 (Accountant, Accounting Controller) are pre-completed as Approved, and the chain sits at the Asset Manager, order 3.
  - Beat 6 names the CEO (order 9).
  - The chain is described as 9 steps with contiguous orders 1–9.
- **Personas.**
  - The Fund Accountant is the chain's Accountant (order 1), and that step is data only.
  - "Executive (CEO)" becomes "CEO (order 9)", with the Executive (order 5) noted as a separate, data-only role.
- **Data model.**
  - SD Investment added: name and description, related to SA Fund; DealCloud narrated, not integrated.
  - SD Draw now relates to SD Investment.
  - SD QIU Metric says "ten metrics", and they are listed explicitly in order.
- **Vocabulary canon.**
  - Added the Accounting Controller mapping for "accounting manager"; the term is not used in object names or UI text.
  - Added the contiguous orders 1–9 by role. The sample's gap is not reproduced.
- **Business rules.** Added the constraint that the flow does not touch subscription intake data. SA Fund is the one intake object it relates to, through SD Investment.
- **Open questions.** The Blue Granite continuity question is recorded as resolved: narration only.

**`BUILD_PLAN.md`:**
- The Phase 0 discrepancy item is ✅ 2026-09-21.
- Personas and the data-model table follow the rulings: SD Investment added, the CEO at order 9, 9 approval rows, 10 QIU rows.
- **Phase 1:**
  - six record types, SD Investment first;
  - relationships Draw → Investment → SA Fund;
  - an SD Investment seed row;
  - the seeded chain with orders 1–2 Approved, 3 In Progress, 4–9 Pending;
  - seed pass conditions of 1 investment, 1 draw, 10 QIU rows, and 9 approvals with no gap.
- **Phase 3:** the email's Approval Status uses contiguous orders.
- The plan gate still passes, with 55 checklist items.

**`TODO.md`:** "Phase 0 discrepancies" closed and moved to Done with the seven rulings.

**Verified.**
- Each replacement was asserted to match its target exactly once.
- A grep finds no remaining "Executive (CEO)", no "nine metrics", and "accounting manager" only in the canon rule that maps it.
- The plan-gate check passes.

**Not verified.** Nothing on the instance was touched.

**Promotion.** 0 candidates.

Promotion checkpoint: current through 2026-09-21 — Phase 0 discrepancy rulings applied.

### 2026-09-21 — Phase 1 build (in progress): restructure, record types

**Scope.**
- **Designer:** Dev MCP `appian` (157 tools) as `scott.thorn@appian.com`, from the session file; a member of `SD Administrators` and `SD Users`.
- **Other tools:** sail and `appian-runtime` were not used.
- **Row security:** none of the new record types has security rules yet, so the designer's reads of them are unfiltered.

**Preflight.**
- The plan gate passes.
- `appian` has 157 design tools, and `listRecordTypes` returned 16.
- DevMCP 26.6.95 matches the pin, with both halves on build `20260911-210447`. sail is on 26.6.95.
- The skill copies are identical.
- There is no per-session ritual, and there are no persona sessions. The persona site stub was unset at preflight.

**Step 0: phase restructure (docs).**
- **`BUILD_PLAN.md`:** Phase 1 now covers the data model, seed and process, with no custom views. The new Phase 2 is the mockup-first UI foundation. Ingestion moves to 3, the email layout to 4, the failure path to 5, and the final work to 6. `PROJECT_INSTRUCTIONS.md` § Build phases and the phase references in its open questions are updated to match.
- **Ruling recorded, site:** draw views join the existing intake site in a new page group. The intake site was found through `getObjectDependents` on the intake dashboard: `SASite` (`ffae752f-b3d1-44d5-a9ba-c408b66bdb65`), display name "Subscription Agreement Analyst", stub `subscription-agreement-analyst`. It is **not listed as an object of `Starwood Demo`**, which is why the baseline showed zero sites.
- **Second site found:** `42637df6-96f5-4347-85ab-299a7c83ce24`, which hosts the `subscription-intake-dashboard` page. `getSite` on it fails with `Unexpected error: 'targetUuid'`, so it is unread.
- **Ruling recorded, personas:** persona accounts are deferred, and this session verifies as the designer.

**Step 1: existing objects.**
- `SA Fund` (`978232cc-…3dcfb`, data source `_a-0000ebae-…_10766`) is referenced, and id 4 is Harborline Real Assets Fund II, L.P.
- No investment or property type exists, so `SD Investment` is created.
- The legacy `SD Fund` scaffold is not used.
- **No reverse relationship was added to `SA Fund`,** to avoid modifying an intake object; the one-way `SD Investment.fund` suffices for traversal. This is a deliberate departure from the pack's bidirectional rule.

**Step 2: record types.** All six are in `SA Fund`'s data source, have `createTable: true`, and are added to `Starwood Demo`.

| Record type | UUID | Relationships (read back) |
|---|---|---|
| SD Investment | `f285a98c-746c-40e7-899e-65d8d20f766b` | `fund` M:1 → SA Fund; `draws` 1:M → SD Draw |
| SD Draw | `c9d3a947-71aa-4024-879e-363873a12860` | `investment` M:1; `budgetLines`, `approvals`, `qiuMetrics`, `documents` 1:M (CASCADING) |
| SD Draw Budget Line | `ddc4073e-6372-49e2-80de-a088b424abcd` | `draw` M:1 |
| SD Draw Approval | `02c207d5-c725-4d11-bf40-b33573e87ffa` | `draw` M:1 |
| SD QIU Metric | `a0920e4c-0c76-4494-a61a-6e38d5db390a` | `draw` M:1 |
| SD Draw Document | `f3e0033f-2047-4c68-8f6f-cf32166091e9` | `draw` M:1 |

**Field decisions.**
- **Added "Cash/Equity Needed from the Fund?"** as the `cashEquityNeeded` BOOLEAN. The field is in the new email sample's Draw Funding Detail but not in the data model's list; the email's vocabulary governs.
- **`SD Draw Approval` gains `actedBy` and `decisionSource`** (TASK, ACCELERATOR, EMAIL, SEED), for attribution.
- **`SD Draw` gains `activeStepProcessId`,** so an external decision can cancel the open step task.
- **QIU values are TEXT,** per the instruction.
- **No USER-type fields.** Actor names are TEXT, to avoid the mandatory system-user relationships.

**Findings.**
- **Width readbacks under-report.** Every TEXT field created with a length other than 4000 reads back as `VARCHAR(255)`: 1000 → 255 and 20 → 255. Measured by a 289-character write to `SD Investment.investmentDescription` (requested 1000) through `insertRecordData` on probe row id 990: the write succeeded and read back intact. The column is wider than the readback states. The probe row was deleted, and absence was confirmed with an empty `listRecordData`.
  - This is the known supplemental §7 and `CLAUDE.md` §4 class, "readbacks both over- and under-report".
  - It is not the production write path; the proof through a Write Records node is owed.
- **Display names containing `/`, `?` or `(`, and multi-word display names, were rewritten on save.** For example, "On / Under / Over Budget" became "Budget Status". Display labels are left to Phase 2.

**Step 3: seed data** (`scripts/seed_draw66.py`, explicit ids, no `now()`/`today()`/`rand()`; its checks pass with exit 0).
- Investment 1: "Tamarack Hotel & Spa Vail" (THSV) on `SA Fund` 4.
- Draw 66: PIP/Renovation, $2,604,252.23, funding 2026-10-15, On Budget, In Progress at step 3, with the sample's purpose and contingency text.
- 16 budget lines (ids 6601–6616) transcribed from the new email sample. The plan said 17; the sample has 9 "In this Draw" and 7 "All Other" lines.
- 9 approval rows (6601–6609), contiguous orders 1–9, fictional approvers; 1–2 Approved with SEED attribution, 3 In Progress, 4–9 Pending.
- 10 QIU rows (6601–6610), values as formatted text, model as-of 2026-06-30.
- **Read back as the designer:** 1 / 1 / 16 / 9 / 10 rows, and 0 documents. Insert responses were not taken as proof.
- **Reconciliation:** Land, Soft and Hard roll-ups match the sample's Budget Summary except for known source artifacts (the $57,753 contingency adjustment placed differently, and $1 rounding), which the script encodes explicitly. Cents are carried on three lines so the draw lines sum to the amount; see `CLAUDE.md` known artifacts.

**Step 4: groups and constants.**
- `SD Draw Approvers` (`…_5513`, under `SD Users`) with `SD Draw Asset Managers` (`…_5515`), `SD Draw CEO` (`…_5517`) and `SD Draw Demo Approvers` (`…_5519`). Nesting read back.
- The designer was added to the three step groups with `addGroupMembers` and read back as a direct member of each.
- Constants: three GROUP constants by name, `SD_DRAW_TREASURY_RECIPIENT` (USER = the designer, placeholder) and `SD_DRAW_FINAL_APPROVAL_ORDER` (9).

**Step 5: rules, form and process models.**
- `SD_getDrawState(drawId)` returns the routing map; tested against draw 66 with the expected current (order 3) and next (order 4) rows. `SD_getDrawApprovalGroup(role)` returns the three groups (ids 1528, 1529, 1530) for Asset Manager, CEO and AM SVP.
- `SD_form_drawApprovalDecision` (`…_570715`): `testInterface` `error: null`. Its Submit button records `loggedInUser()` into `actor` and defaults a blank comment, so no ACP submits null. **Phase 2 restyle target.**
- `SD Draw.treasuryNotifiedAt` (DATETIME) added so the notification's completion is readable.
- Four process models, all `errorAlertGroupUuid` = `SD Administrators`. **Measurement:** `getProcessModel` exposes no alert-group field, so persistence cannot be confirmed by readback; owed as a Designer check.
- **`SD Apply Draw Approval Decision`** (`0000f06e-a53d-…`, 28 nodes): the single transition as described in `CLAUDE.md`. Probe: a decision for step 5 while the draw sat at step 3 returned `STALE` with no write.
- **`SD Draw Approval Step`** (`0000f06e-a547-…`, 12 nodes): registers `pp!id` on the draw, sends a placeholder notification on a parallel branch, presents the task, then calls the transition synchronously. All five form ACPs read back `required: true` (the supplemental's forced-required trap, handled by the form's defaults).
- **`SD Draw Approval Process`** (`0000f06e-a54a-…`, 8 nodes): starts the step task for the current step when no step process is open.
- **`SD Advance Draw to CEO Step (Demo Accelerator)`** (`0000f06e-a54d-…`, 13 nodes): the loop with a ceiling of 9.
- The subprocess pattern was copied from the intake app's `SD Start Intake (MCP)` node (bare `pv!` mappings, `pmUUID`). The intake app's Send E-Mail and user input task nodes were unconfigured scaffolds, not working examples.

**Step 6: end-to-end verification, as the designer (member of all three step groups).** Pass conditions were stated in `BUILD_PLAN.md` before the run.
1. `SD Draw Approval Process` on draw 66: outcome `STARTED step 3 (step process 38661)`; draw read back with `activeStepProcessId` 38661; task 4250 "Approve or reject draw" listed.
2. `completeTask(4250, APPROVE)`: row 3 Approved with `actedBy` the designer and source TASK; ~7 s later the draw read back at step 4 with row 4 In Progress, and ~4 s after that `activeStepProcessId` 38663 (the step-4 process). **Timing:** the transition completes after `completeTask` returns; a read taken 1–2 s later still showed step 3.
3. Accelerator: `testProcessModel` returned a client ReadTimeout at ~60 s while the process completed. Read back: rows 4–8 Approved with source ACCELERATOR at ~12 s intervals, draw at step 9 with row 9 In Progress and `activeStepProcessId` 536909926; task 536873553 open; the step-4 task gone (task total unchanged at 53, so it was cancelled).
4. `completeTask(536873553, APPROVE)`: draw Approved, all nine rows Approved, `treasuryNotifiedAt` 2026-09-22 02:05:04 UTC. The write downstream of the Send E-Mail node ran, so the node completed without an exception.
5. Reset with the script's CSVs, read back at the seeded state.
6. **Break-test:** fresh start (step process 38665, task 4460), `completeTask(4460, REJECT)`: draw Rejected at step 3, `activeStepProcessId` cleared, row 3 Rejected with the comment and attribution, rows 4–9 untouched, `treasuryNotifiedAt` null, no task opened.
7. Reset again; read back at the seeded state; task total 52, equal to the pre-existing non-draw count, so no draw task is open.

**Not verified.**
- **Email delivery.** No inbox was checked. The nodes completed; whether mail arrived is a mailbox check.
- **Step notification emails to groups** on the parallel branch: not observed at all.
- **`errorAlertGroupUuid` persistence:** unreadable over MCP.
- **Column widths** through the production write path at lengths over 255.
- **Persona behaviour:** no persona sessions; everything ran as the designer, who is full-scope.
- **The race** between the accelerator and a just-started step process (`activeStepProcessId` not yet registered): not exercised; the demo runs these as separate beats.

**Promotion.** 7 candidates found; all STAGED at gate 1 with triggers (staging section). 0 promoted. `reference/mcp-capability-boundaries.md`'s group-membership entry is updated with the measured write.

**Rulings needed.** Listed in `TODO.md`: the Budget Summary artifact, and whether accelerator decision dates should be spread (`dayOffsetPerStep`).

Promotion checkpoint: current through 2026-09-21 — Phase 1 build.

### 2026-09-21 — Phase 2a: browser checks recorded, rulings applied, width and race verified, accelerator dates spread

**Scope.**
- **Designer:** Dev MCP `appian` as `scott.thorn@appian.com` (session file), a member of `SD Administrators`, `SD Users` and the three draw step groups. All readbacks ran under that account; the draw types carry no row security.
- **Not used:** `appian-runtime`, sail.
- **Preflight:** plan gate passes; DevMCP 26.6.95 and sail 26.6.95 match their pins; skills identical.

**Browser checks, run by Scott, recorded as complete.**
- **Outbound email works on this instance.** The treasury placeholder email and the step notification emails arrived in the designer's inbox.
- **`errorAlertGroupUuid` persists.** All four process models show `SD Administrators` under Properties → Alerts. The MCP readback gap stands.
- **The task form renders in Tempo:** step heading with role and approver, the draw summary line, the decision radios and the comments box; a reject with a blank comment is blocked by the required-field validation.

**Rulings recorded** (in `PROJECT_INSTRUCTIONS.md` § Business rules / § Build phases and `BUILD_PLAN.md`): Budget Summary is a roll-up of the detail lines, never the sample's printed figures; accelerator dates spread 1 day per step with the funding date after the last generated date; mockups come from the claude.ai Project into `mockups/` and build sessions never author or modify them; new demo runs come from Phase 3 ingestion, and draw 66 plus the reset script are interim tooling.

**Work item 1: column widths, definitive.** Throwaway model `zz SD Width Probe` (`0000f06e-be90-…`), one Write Records node per record type, `PauseOnError` false, errors mapped to PVs, driven by `testProcessModel`; deleted afterwards (`getProcessModel` → "Does not exist").
- `SD Draw.contingencyExplanation` (created `length` 4000, reads back `VARCHAR(4000)`): a 1,200-character value written and read back intact.
- `SD QIU Metric.notes` and `SD Investment.investmentDescription` (created `length` 1000, both read back `VARCHAR(255)`): 300 and 1,000 characters written and read back intact; 1,001 characters failed on both with `Data too long for column`. **The physical width is exactly the requested 1,000. The create-time readback of `VARCHAR(255)` is wrong. Nothing truncates silently; the node fails loudly past the limit.**
- `SD Draw Approval.comments` (created 1000, reads back 255): a 600-character comment written through the real transition (`SD Apply Draw Approval Decision`) and read back intact.
- Probe values restored to the seed text and read back; QIU 6601 `notes` cleared.
- **No column was altered:** nothing truncated, and the spec's paragraph fields have 4,000 (`contingencyExplanation`) and 1,000 (`notes`) characters. Whether 1,000 is enough for QIU notes is flagged in `TODO.md`; widening would be a drop-and-recreate.
- *Observation, unexplained:* the probe's `len(pv!longText)` reported 1,444 for a 1,200-character input, while the stored value read back as the text sent. The readback is the record.

**Work item 2: accelerator date spread.** `dayOffsetPerStep` default changed from 0 to 1 (PV default read back as `"1"`). Re-run: steps 4–8 decided at 2026-09-23, 24, 25, 26, 27, one day apart; the last generated date (2026-09-27) precedes the funding date (2026-10-15). As the ruling anticipates, the CEO's later live decision carries today's date, earlier than the President's generated one.

**Work item 3: race and timing.**
- **First attempt, unfixed accelerator (observation before fix).** Approval at 02:41:39 UTC; accelerator started 02:41:49 (+10 s). Its read saw rows 3 Approved and 4 In Progress but `currentStep` still 3, asked to decide step 3, was refused STALE by the transition, and stopped after 0 iterations. **No data was harmed** (the guard held; the Asset Manager's TASK attribution stayed) but the demo sequence would have failed.
- **Fix:** a settle phase in the accelerator. On its first pass it re-reads every 5 s (Timer `delayUntil: now() + intervalds(0, 0, 5)`) until the row at `currentStep` is In Progress and the state snapshot (`currentStep|rowStatus|activeStepProcessId`) is identical across three reads, up to 12 waits, else `SETTLE_TIMEOUT`. Later iterations do not settle.
- **Idle-case run** (open step-4 task, no in-flight decision): start 02:44:06; first decision 02:44:24 (18 s settle); CEO task live 02:45:27. **81 s.**
- **Race run, the demo sequence:** approval 02:46:54; accelerator start 02:47:01 (+7 s); first decision 02:47:25 (24 s settle); steps 4–8 at 02:47:25, :37, :49, 02:48:00, :12 (≈12 s each); CEO step process 38691 registered 02:48:28 and its task assigned 02:48:30. **87 s from accelerator start, 94 s from the approval.** Row 3 kept the TASK attribution; the superseded step-4 task was cancelled (task total unchanged); exactly one draw task open at the end. **No stale-decision failure.**
- Both runs returned the client `ReadTimeout` at ~60 s while the process continued.
- Each run closed with a CEO approval (draw Approved, `treasuryNotifiedAt` set) and a reset to the seeded state; final readback: seeded state, task total 52 (no draw task).

**Verified.** Every fact above by readback as the designer or by a local timestamp around the call.

**Not verified.** Email delivery for this session's runs (not re-checked; delivery is now confirmed as a capability). Persona behaviour. Widths on columns not probed (`purpose`, `overBudgetReason`, 1000-requested, by inference only).

**Promotion.** 2 candidates resolved (width: measured and recorded in the boundaries doc; alert group: persists per Designer). 1 new candidate staged (the settle rule). 0 promoted to the supplemental.

Promotion checkpoint: current through 2026-09-21 — Phase 2a: browser checks, rulings, width and race verification.

### 2026-09-22 — Phase 2b: draw list page, tabbed draw record views, restyled approval task form, list-texture seed, monotonic decision dates, persona-verified

**Scope and identity.** Designer: Dev MCP `appian` as `scott.thorn@appian.com`, a member of `SD Administrators`, `SD Users` and the three draw approval step groups (full-scope; every `testInterface` / `testRule` / `listRecordData` readback below ran under it). Personas through sail: `~/.sail-sd.assetmanager` (username `sd.assetmanager`, `SD Draw Asset Managers`) and `~/.sail-sd.accountant` (`sd.accountant`, `SD Draw Demo Approvers`), both live, both in `SD Users`; identity confirmed by observation (the pages that resolve, the YOUR ACTION row that only the asset manager sees). `--from-devmcp` not used. `appian-runtime` not used. Docs-search used for every layout parameter in play (grid columns and widths, tag, progress bar, card choice templates, record/task links, header content layout, headerTemplateFull); the pack's header-content, sidebyside, columns, rich-text and card-choice references read before the first SAIL.

**Preflight.** Plan gate passes; Dev MCP 26.6.95 (`20260911-210447`) and sail 26.6.95 match the pins; skill copies identical; persona sessions live but the site returned 500 to both personas until the site security change below.

**What changed, by object (UUIDs in `CLAUDE.md` § Draw approval objects).**
- *Data (items 1–3 of the brief, before the summary).* Investment 2 `Gateway Logistics Park Phase II` (fund 4); draws 63/64/65 (THSV, Approved) and 11 (Gateway, Approved), 12 (Gateway, In Progress at step 6, no lines/QIU/documents); 45 approval rows inserted + 9 updated (54 total, ids = draw × 100 + order, `activatedAt` = previous decision); QIU as-of 2026-09-30; `SD Draw.receivedDate` / `submittedBy`, `SD Draw Approval.activatedAt`, `SD Draw Document.status` / `notes` / `receivedDate` added; three metadata-only document rows 6601–6603. Persona rows renamed to the accounts' display names (Priya **Ramen** — the account's spelling, flagged; Elena Marchetti). `scripts/seed_draw66.py` rewritten to carry all of it.
- *Transition (item 4).* `SD Apply Draw Approval Decision` node 4 computes `effectiveDate = max(requested, previousDecisionDate + 1 day)`; node 22 writes `activatedAt` on the next row; `SD_getDrawState` v2 returns `previousDecisionDate`, `decisionDate` and `activatedAt` per row. Verified end to end from the seeded state (all nine dates ascending, 10/06 → 10/14, funding 10/15), then reset.
- *Rules.* `SD_getUserDisplayName`, `SD_getOpenTaskId` (+ constant `SD_CURRENT_TASKS_FOR_PROCESS_REPORT_ID` = 39), `SD_fmtMoney` (v3: rounds first; negatives in parentheses), `SD_fmtRelativeDays`, `SD_getDrawDetail` (v4), `SD_getDrawListRows`.
- *Shared interface pieces.* `SD_cmp_statusTag`, `SD_cmp_sourceLine`, `SD_cmp_labelValue`, `SD_cmp_drawFactStrip`.
- *Record views on `SD Draw` (item 5).* `SD_view_drawSummary` (v5) as **Summary** (`summary`); `SD_view_drawBudgetDetail` (v3) as **Budget Detail** (`_5vAYPw`); `SD_view_drawApprovals` (v2) as **Approvals** (`_HP07OQ`); `SD_view_drawDocuments` (v1) as **Documents** (`_8-A_WA`). Record title expression: `"Draw Funding Approval | " & investment name`. Each view is `rule!SD_view_…(drawId: rv!identifier)`.
- *Draws page (item 6).* `SD_page_draws` (v4) added to `SASite` as page **Draws** (`draws`, uuid `76fd3289-…`, icon f155) with the three intake pages passed by uuid and preserved. Site security: viewer = `Subscription Agreement Analysts` + `SD Draw Approvers` (both personas are direct members of the latter, read back). The navigation page group is a Designer step (not exposed over the Dev MCP).
- *Task form (item 7).* `SD_form_drawApprovalDecision` v3 restyled; inputs `drawId` and `stepOrder` added; `SD Draw Approval Step` node 9 gained ACPs `drawId` / `stepOrder` (read back in the inputMap). The live task that predated the wiring was completed with REJECT ("Build reset"), the draw reset through the two CSVs, and the launcher rerun: step process 536909940, task 536874206 live for `SD Draw Asset Managers`.
- *Cleanup.* Throwaway rule `zz_SD_probeFolder` deleted; `getExpressionRule` returns 404.

**Decisions and why.**
- **"Awaiting my action" means group membership *and* an open task** (`awaitingViewer`). Without the second half, `sd.accountant` (a member of the catch-all `SD Draw Demo Approvers`) would count Gateway #12 — at step 6 with no process started — as awaiting them, against the brief's expectation of 0. The action strip follows the same rule, so it shows only while a task exists.
- **The task link is resolved through the platform's "Current Tasks for Process" report**, because a user input task's `tp!id` is only available at task end and nothing else in SAIL maps a process id to its open task. The report's document id is an instance constant with a re-verify note.
- **Band versus record header.** Appian's record header carries the mockup's h1; the mockup's fact strip is a white card at the top of every view (under the tabs). Colours follow the mockup palette; the strip's "Review & Approve" is a linked card, since a button widget takes no link.
- **Approval progress bar** is a single-tone `a!progressBarField` (approved/total) plus a nine-icon stepper (✓ green, ● blue, ○ grey), because a two-tone bar (mockup's 22.2 % + 11.1 %) is not a SAIL component.
- **Budget Summary shows "—" adjustments for every group** (computed roll-up; the seeded reallocation nets to zero inside Soft), where the mockup prints Soft +$57,753 / Hard ($57,753). The roll-up ruling of 2026-09-21 wins; the mockup is not touched (ruled); the delta is recorded in `CLAUDE.md` § Known data artifacts. Totals read $390,196,711 and $18,693,028 (cents on three lines), one dollar off the mockup's printed figures for the same reason.
- **Seeded attribution is hidden.** Rows with `decisionSource` "seed" show no source/actor line and "N/A" comments render as "—"; real decisions (TASK / ACCELERATOR / EMAIL) show their source and actor under the date.
- **Empty states are intentional** (Gateway #12): "No budget lines" chip, "budget detail not yet extracted", empty grids with messages, "Funded to date is computed from the budget detail…".
- **Not built:** "Save for Later" (no draft save on a task form without a process change); row-click navigation on the list (rows open through the Draw and Investment links); the "Advance draw (demo)" related action; a page group.

**Verified (with scope).**
- *As the designer, `testInterface` (`diagnostics.error: null`) on all four views for draws 66 and 12, the Draws page, and the form (drawId 66 / stepOrder 3, decision NONE and REJECT).* Summary #66: tie-out "Ties ✓ … $2,604,252.23"; Budget Summary Land $121,825,238 / Soft $67,174,329 / Hard $201,197,144 / Total $390,196,711, Current Draw — / $112,667 / $2,491,585 / $2,604,252; Remaining Contingency $1,274,757 → ($57,753) → $1,217,004 and 6.8 % → 6.5 % over $18,693,028; Funding History "Funded to date: $368,899,431 of $390,196,711 (94.5 %)", "This draw brings PTD to 95.2 %", rows #66, #65, #64, #63; QIU 10 rows as of 09/30/2026. Budget Detail #66: In this Draw 9 lines, All Other 7, BUDGET $278,676,480 / $390,196,711 / — / $390,196,711 / $2,604,252 / $371,503,683 / 95.2 % / $18,693,028 — equal to the mockup's Budget Detail row for row. Approvals #66: nine rows, row 3 highlighted, time at step 1 day / 1 day / < 1 day, note text. Documents #66: three rows with chips. Draws page: Awaiting 1 (#66 · Asset Manager step), In Approval $11,544,252 / 2 draws, Funding Next 30 Days $2,604,252 / 1 draw · next: Oct 15 (computed against today, 2026-09-22; the mockup's frame is October), Funded YTD 2026 $24,928,659 / 4 draws; order #66, #12, #65, #64, #11, #63. Form: header "Step 3 of 9 — Asset Manager / Assigned to Elena Marchetti · with you since Oct 7 · funds scheduled Oct 15", cards "Advance to AM SVP (step 4 of 9)" / "Terminate this draw request", Comments required with the right message when REJECT is selected.
- *As `sd.assetmanager` via sail:* `pages` lists Draws (`draws`); the page loads with Awaiting 1 / Draw #66, #66 carries YOUR ACTION and sorts first; #66 Summary shows the action strip and the "Review & Approve" card whose stored YAML link is `ProcessTaskLink` task 536874206 — the id `SD_getOpenTaskId` returns for step process 536909940; Gateway #12 shows no strip and no YOUR ACTION and all four tabs render (41 read-only values, empty-state grids).
- *As `sd.accountant` via sail:* the page loads with Awaiting 0 ("Nothing waiting on you"), no YOUR ACTION; #66 Summary without the strip (42 values against the asset manager's 44); Budget Detail (19 grid rows), Approvals (9), Documents (3) all readable; #12's four tabs render.
- *Monotonic dates:* full run readback as above; the reject used for the reset landed at 10/08 11:05 (floor = previous decision + 1 day), as the rule says.
- *Site readback:* four pages with the three intake stubs unchanged; security role map read back with both viewer groups.

**Not verified.**
- Following the task link and submitting the restyled form as a persona (sail cannot follow a task link; the form was rendered by `testInterface` as the designer only) → browser checklist in `TODO.md`.
- Geometry of all three pages (widths, one-row KPI cards, band, column widths, button alignment) → browser checklist.
- Document download links (no files attached until Phase 3).
- The Draws page under Tempo or on mobile.
- Record-level security: none exists; both personas see every draw.

**Structural deltas from the mockups (§7).** Record header instead of the mockup's band (fact strip repeated under the tabs); the list's row click is two link cells; the progress bar is single-tone plus a stepper; "Save for Later" absent; "Ties ✓" chip and stepper icons stand in for the mockup's coloured badges; Budget Summary adjustments "—" (data, see above). None of these changes the mockups (ruled); they are listed for the next mockup pass in the Project.

**Findings.** Seven candidates staged (staging section): the `a!forEach`-as-filter trap (measured in both directions, with the fix as control), `text()` truncation, `min()` over dates, `updateSite` stub preservation, the task-report route to a task id, sail and task links, the summary-view record-link ordering. Also noted, not staged: `testInterface`'s `maxResponseSizeBytes` did not truncate ~30–70 KB responses; `updateRecordType.titleExpression` accepts a related field and stores the `#"urn:appian:record-field:v1:…"` form.

**Promotion.** 7 candidates found; 7 listed as STAGED at gate 1 with triggers; 0 promoted (each has one measurement or one instance). The supplemental is unchanged, so the repo and user-level copies stay identical.

**TODO changes:** closed "Spec artifacts are not on GitHub" and "Persona accounts and sail logins"; added Before demo "Demo start" and the "Ramen/Raman" name flag; added three Browser checks owed (task from the strip and form submit, geometry, document links); added Deferred items (intake pages visible to personas, page group, Save for Later, Advance-draw related action, seed dates versus the clock, record-title duplication); updated the record-level-security item.

Promotion checkpoint: current through 2026-09-22 — Phase 2b.

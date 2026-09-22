# BUILD LOG — Starwood draw approval

What has actually been built in the environment, with object identifiers and the decisions behind them. Append after every build step; never rewrite a closed entry — a correction is a new entry that names what it corrects. Entry shape: date and title; scope line (the identity and group memberships every readback ran under); what changed, by object; decisions and why; verified (how, with counts and scope); not verified (and the browser checklist that covers it); promotion checkpoint. The contract is `CLAUDE.md` §7; the promotion loop is §9.

**Promotion checkpoint: current through 2026-09-21 — Phase 0 transcription and build plan — level with the log tail.** A session touching promotion refuses to call itself complete if this checkpoint lags the log tail by more than one session.

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

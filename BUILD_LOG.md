# BUILD LOG — Starwood draw approval

What has actually been built in the environment, with object identifiers and the decisions behind them. Append after every build step; never rewrite a closed entry — a correction is a new entry that names what it corrects. Entry shape: date and title; scope line (the identity and group memberships every readback ran under); what changed, by object; decisions and why; verified (how, with counts and scope); not verified (and the browser checklist that covers it); promotion checkpoint. The contract is `CLAUDE.md` §7; the promotion loop is §9.

**Promotion checkpoint: current through 2026-09-21 — Phase 0 rulings and Dev MCP update attempt — level with the log tail.** A session touching promotion refuses to call itself complete if this checkpoint lags the log tail by more than one session.

## Promotion candidates (staging)

*(Session close-outs append here: "Promotion candidates: N found; promoted / listed / none". Each staged candidate states the trap and the working form, the gate it is held at, and a named trigger — the defined moment that will confirm or discard it. A superseded candidate gets a bracketed in-place marker — `[RESOLVED …]`, `[REVERSED …]`, `[TRIAL REASSIGNED …]` — never a rewrite, so a reader of this section alone never chases a dead trigger.)*

- **STAGED (gate 1: one observation) — listing group members worked over the Dev MCP here, contradicting appian-supplemental §3.**
  - *The skill says:* `listGroupMembers`, `getGroup` and `addGroupMembers` return HTTP 403 across the whole surface.
  - *Observed:* on `ny.appiancloud.com` with DevMCP plugin 26.6.95 and bundle stamp 20260903-195919, `listGroupMembers` returned 200 with members for all seven application groups, as `scott.thorn@appian.com`.
  - *Unknown:* whether this is a plugin-version change or a property of this instance. `getGroup` and `addGroupMembers` were not tried.
  - *Trigger:* the first session that needs to add a member to a draw approval group. Try `addGroupMembers` there and read the result back with `listGroupMembers`. Then rule on this candidate: promote it (re-verify per instance), or discard it with the gate it failed.

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

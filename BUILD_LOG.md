# BUILD LOG — Starwood draw approval

What has actually been built in the environment, with object identifiers and the decisions behind them. Append after every build step; never rewrite a closed entry — a correction is a new entry that names what it corrects. Entry shape: date and title; scope line (the identity and group memberships every readback ran under); what changed, by object; decisions and why; verified (how, with counts and scope); not verified (and the browser checklist that covers it); promotion checkpoint. The contract is `CLAUDE.md` §7; the promotion loop is §9.

**Promotion checkpoint: current through 2026-09-21 — Instantiation and read-only preflight — level with the log tail.** A session touching promotion refuses to call itself complete if this checkpoint lags the log tail by more than one session.

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

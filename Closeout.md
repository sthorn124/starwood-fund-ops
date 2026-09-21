# Closeout — 2026-09-21 — Dev MCP update complete: 26.6.95 running and re-verified

## Scope and identity

- **This was maintenance:** `maintenance/dev-mcp-update.md` Phase 2. There was no build work and no instance writes.
- **Dev MCP reads** ran as `scott.thorn@appian.com` (from the session file), which is a member of `SD Administrators` and `SD Users`:
  - `getDevMcpVersionInfo`;
  - `listRecordTypes` (limit 1);
  - `listGroupMembers` on `SD Administrators` (`directOnly`).
- **No sign-in was needed.** The persisted session was reused after the relaunch.
- **Not used:** `appian-runtime`. No persona sail sessions exist.

## Result: the versions match

| | Before | Now |
|---|---|---|
| Plugin (site) | 26.6.95, build `20260911-210447` | same |
| MCP server (local) | build `20260903-195919` (26.6.90) | build `20260911-210447` (26.6.95) |
| `mcp_src_sha` | plugin `71a81a27…`, local `a037e2a2…` (drift) | `71a81a27e39421db` on both |
| Tool's verdict | "Update the MCP server: it is out of sync" | "No action needed: both halves are up to date and came from the same build" |
| sail | 26.6.90 | 26.6.95 |
| Tools under `appian` / `appian-runtime` | 157 / 10 | 157 / 10 (names still separate) |

## What the new server does differently (source diff against 26.6.90)

**Unchanged:**
- auth (`browser_auth.py` is byte-identical);
- the environment variables read;
- the 157-tool inventory, name for name;
- group handling (formatting-only changes). Group reads were re-measured live and work.

**Changed, and worth knowing before building:**
1. **Inline-SAIL guard.**
   - When `SAIL_MCP_ENABLED=true`, `createInterface` and `updateInterface` reject an inline `expression`.
   - **It is off here**, because the registration sets only `LCP_URL`. Inline SAIL writes work as before.
2. **`createProcessModel` takes `errorAlertGroupUuid`** instead of `errorAlertGroupName`. Whether it persists is unmeasured, so the Designer step and a readback remain the known-good path.
3. **Record type `securityMode` is validated client-side.** `GUIDED` is rejected with the valid values named.
4. **Integrations can save a response as a document.** They take mutually exclusive literal or expression pairs for folder and name, and up to five `documentLocations`.
5. **Any 2xx on a DELETE is treated as success.** A delete is still proven only by absence.
6. **Non-blocking write checkpoints** for a hosted copilot. They are inert in a local session and are not a rollback mechanism here.

## Repo changes

- **`reference/toolchain.md`:**
  - §1 is re-pinned to DevMCP 26.6.95: build stamp and hashes as reported by the tool, new install path, date, `browser_auth.py` sha256, rollback path, and a summary of what changed.
  - §12 is re-pinned to sail 26.6.95: binary path and sha256 `5ccd5559…`, plus the byte-identical help-surface check.
- **`reference/mcp-capability-boundaries.md`:** a new "Changed in DevMCP 26.6.95" block, and an annotation on the `errorAlertGroupName` entry.
- **`reference/silent-failure-taxonomy.md`:** an annotation on the `errorAlertGroupName` entry.
- **`BUILD_LOG.md`:**
  - the Phase 2 entry;
  - the `listGroupMembers` candidate marked `[RESOLVED …]`, with its ruling in the staging section.
- **`TODO.md`:** Phase 2 closed, and two Deferred items added.

## Verified

- The version match, from `getDevMcpVersionInfo`.
- The source and tool-inventory diffs, run locally, with an AST comparison to set aside pure reformatting.
- The sail help diff (root plus nine subcommands, byte-identical).
- The live design read and group read, as the designer.

## Not verified

- Whether `errorAlertGroupUuid` persists on `createProcessModel`. This needs an object write, and the plan gate still forbids creating objects.
- The inline-SAIL guard in practice, because it is off.
- Write checkpoints.
- sail's behaviour against a live persona on 26.6.95 (no persona sessions). This covers the read-only measurements (pages, load, show offline, the JSON error stream) and the write-dependent ones.

## Rollback (kept until the next update)

- `~/appian-dev-mcp-server`, the 26.6.90 install and its `bin/` sail binary.
- `~/.claude.json.bak-2026-09-21-devmcp-update`.

## Promotion candidates

0 new; 1 ruled. The `listGroupMembers` candidate is **RESOLVED as already recorded**: `reference/mcp-capability-boundaries.md` has recorded working group reads since 26.6.90, and 26.6.95 re-measures the same.

The real gap is appian-supplemental §3, which still says reads return 403. Its correction is a TODO for the skill's owner. The checkpoint is current through this entry.

## TODO changes

- **Closed and moved to Done:** "Dev MCP update, Phase 2 (re-verify)", as ✅ 2026-09-21.
- **Added under Deferred:**
  - correct appian-supplemental §3 on group reads (Scott; trigger: the next template sync);
  - measure whether `createProcessModel(errorAlertGroupUuid)` persists (build session; trigger: the first draw approval process model).
- **Still open:**
  - Blocking: the Phase 0 plan.
  - Before demo: the spec artifacts not on GitHub, and persona accounts with sail logins.

## BUILD_PLAN.md changes

None. It is still a stub pending Phase 0.

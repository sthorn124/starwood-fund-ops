# Closeout — 2026-09-21 — Dev MCP update Phase 1: 26.6.95 installed side by side, relaunch pending

## Scope

- **This was a maintenance session.** There was no build work, no instance writes, and no Dev MCP calls.
- **What ran:** `maintenance/dev-mcp-update.md` Phase 1. The session stopped at the mandatory phase boundary.

## What changed on this machine

| Item | Before | After |
|---|---|---|
| Dev MCP install | `~/appian-dev-mcp-server` (build `20260903-195919`, 26.6.90) | New: `~/appian-dev-mcp-server-20260911-210447` (build `20260911-210447`, 26.6.95). The old install is kept as the rollback. |
| `~/.claude.json` → `mcpServers.appian` `--directory` | `/Users/scott.thorn/appian-dev-mcp-server` | `/Users/scott.thorn/appian-dev-mcp-server-20260911-210447`. This was the only change. The backup is `~/.claude.json.bak-2026-09-21-devmcp-update`. |
| `sail` link (`~/.local/bin/sail`) | old bundle, 26.6.90 | new bundle, `sail version 26.6.95` |
| Playwright Chromium | — | 153.0.8010.12 installed; the headless launch test passed |

**Not touched:** the desktop app's `appian-runtime` entry, the old install, and both bundles in `~/Downloads`.

## How the bundle was identified

- The file is `appian-dev-mcp-server-bundle (1).tar.gz`, downloaded today.
- It carries a browser suffix, so it was identified by content: its `BUILD-INFO.txt` shows `build_timestamp=20260911-210447` and `mcp_src_sha=71a81a27e39421db`, identical to the plugin's own report.

## Verified

- The bundle's build stamp matches the plugin's.
- `import lcp_mcp_server, playwright` succeeds.
- The headless Chromium launch works.
- `sail --version` reports 26.6.95, and `sail --help` runs.
- The registration was read back from the file: a structural diff against the backup shows only the `--directory` change.
- The new `config.py` reads the same environment variables.
- The `--extra browser` error is harmless, because Playwright is a core dependency.

## Not verified (Phase 2)

- That the running server is the new build, because this session still runs the old server process.
- That `getDevMcpVersionInfo` reports plugin and bundle in sync.
- The re-verification of `reference/toolchain.md` §1, §2, §4 and §12 against the new source and help, the capability-boundary sweep, and the pin refresh.

## Next step

Fully quit and relaunch Claude Code now; the running session keeps the old server. In the new session, say "continue the update procedure". The first Dev MCP tool call will open a browser sign-in window: complete SSO and MFA there, and the session is captured under `~/.appian-devmcp/`.

## Rollback

- Point `mcpServers.appian` `--directory` back at `~/appian-dev-mcp-server`, or restore the dated backup of `~/.claude.json`.
- Re-run `~/appian-dev-mcp-server/bin/setup-mac.sh` to point sail back at the old binary.
- Relaunch.

## Promotion candidates

0 new. The staged `listGroupMembers` candidate carries over. Phase 2's sweep of group-membership boundaries should re-check it under the new server.

## TODO changes

- **Replaced** "Dev MCP bundle out of sync" (the Step 0 blocker) with "Dev MCP update, Phase 2 (re-verify)", triggered by the next session after a relaunch.

## BUILD_PLAN.md changes

None. It is still a stub pending Phase 0.

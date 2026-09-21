# Dev MCP update procedure

**Executed by Claude Code, not copy-pasted by a human.** When the operator says "run the update procedure", the session reads this file and works through it: it performs the machine steps itself, prompts the operator at each step only a person can do, and stops at the phase boundary. Every step is verified before the next; nothing is deleted; the previous install stays as rollback.

## When this runs, what it produces, and its shape

- **When:** a new Dev MCP bundle is available — the preflight version check (`CLAUDE.md` §2) reports that `getDevMcpVersionInfo`'s plugin version or build stamp no longer matches the pin in `reference/toolchain.md` §1, or that `sail --version` no longer matches the sail pin in §12, or the operator triggers it.
- **What it produces:**
  - the new server installed side by side with the old one, and the MCP registration pointed at it;
  - the sail CLI from the same bundle linked in its place;
  - `reference/toolchain.md` §1, §2, and §12 re-verified against the new server's source and the new sail's help;
  - the server-behaviour and sail entries in `reference/silent-failure-taxonomy.md` and `reference/mcp-capability-boundaries.md` re-checked;
  - both version pins refreshed;
  - one commit.
- **Shape:** two Claude Code sessions with a mandatory host restart between them — Phase 1 installs and reconfigures under the old server; Phase 2 verifies under the new one, because a running session keeps the server process it started with. Steps the session cannot perform and hands to the operator: downloading the bundle (it sits behind the site's login), the quit and relaunch itself, the browser SSO and MFA sign-in, and approval of the configuration change and the final commit.

## Parameters — determined at runtime, never hardcoded

| Name | How the session determines it |
|---|---|
| `SITE` | the hostname of `LCP_URL` in the current registration (`claude mcp get appian`, or the `appian` entry in `~/.claude.json`) |
| `OLD_INSTALL` | the `--directory` value in the current registration |
| `NEW_INSTALL` | a fresh directory that is not `OLD_INSTALL`; the convention is `~/appian-dev-mcp-server-<build stamp>` once the bundle's `BUILD-INFO.txt` has been read, or the documented `~/appian-dev-mcp-server` if that path is free |
| `BUNDLE` | the newest `appian-dev-mcp-server-bundle*.tar.gz` in `~/Downloads`, confirmed with the operator if more than one candidate exists or the name differs |
| `PIN` | the version pin in `reference/toolchain.md` §1: plugin version, build stamp, install path, install date, auth-source hash |
| `SAIL_PIN` | the sail pin in `reference/toolchain.md` §12: `sail --version` output, binary path, sha256 |

## Step 0 — Bundle (operator step; the session walks them through it)

The bundle downloads from the operator's own Appian site and versions with the site's plugin. Both paths sit behind the site's login. There are two, and the session prints both with `SITE` filled in:

- **`https://SITE/suite/plugins/servlet/stateless/downloads`** is the documented downloads page and the operator-facing entry. Give it first.
- **`https://SITE/suite/plugins/servlet/stateless/lcp-mcp-bundle`** is the direct bundle link that `getDevMcpVersionInfo` prints in its recommendations. It was observed in the tool's output; its download behaviour has not been measured. Offer it as a shortcut, and fall back to the downloads page if it does not produce the bundle.

The session tells the operator to sign in and download the bundle to `~/Downloads`, and waits for confirmation before proceeding.

**Ordering rule.** Run `getDevMcpVersionInfo` first and read its recommendations. If the site's plugin is behind the App Market, the site administrator must update the plugin before anyone downloads — a download taken before that just reinstalls the current generation. If the plugin and the local bundle already carry the same build stamp, there is nothing to update; say so and stop.

## Phase 1 — Install (this session)

1. **Prerequisites.** `python3 --version` must be 3.13 or later (the bundle's `pyproject.toml` states `requires-python`; check it after extraction too). `uv --version` must succeed; if `uv` is missing, install it with `curl -LsSf https://astral.sh/uv/install.sh | sh` and verify. If Python is below the requirement, stop and ask — never attempt a Python upgrade unprompted.
2. **Locate the bundle.** Find `BUNDLE` in `~/Downloads`. If more than one file could be it, or the name carries a browser suffix, confirm the exact filename with the operator. Never delete the bundle.
3. **Inspect before extracting.** List the tarball's top-level entries. `pyproject.toml` must be at the root so that the documented `--directory` layout results; if the archive wraps everything in a folder, extract and adjust `NEW_INSTALL` to that folder. Read the extracted `BUILD-INFO.txt`: its build stamp is the version being installed. If it equals `PIN`'s build stamp, this is the current generation — stop and revisit the ordering rule.
4. **Install side by side.** `mkdir -p NEW_INSTALL`; `tar -xzf BUNDLE -C NEW_INSTALL`; verify the tree (`src/lcp_mcp_server` present, module name `lcp_mcp_server` unchanged across generations). `OLD_INSTALL` is not modified or deleted; it is the rollback.
5. **Sync and verify.** `uv --directory NEW_INSTALL sync`, then confirm `.venv` exists and `uv --directory NEW_INSTALL run python -c "import lcp_mcp_server, playwright"` succeeds. Then `uv --directory NEW_INSTALL sync --extra browser` — if the bundle defines no `browser` extra the command errors with "Extra `browser` is not defined"; that is harmless when Playwright is already a core dependency, and the session reports it as such rather than as a failure. Then `uv --directory NEW_INSTALL run playwright install chromium`, and verify with `playwright install --dry-run chromium` and a headless launch test.
6. **Link sail from the new bundle.**
   - `NEW_INSTALL/bin/` holds the sail binaries and one setup script per platform. Run the one for this machine (`NEW_INSTALL/bin/setup-mac.sh` on macOS).
   - It repoints an existing `sail` link that points at a sail binary, and refuses to replace anything else. If it refuses, report what `sail` currently resolves to and let the operator decide.
   - Verify: `sail --version` should report the new bundle's version, and `sail --help` should run.
   - `OLD_INSTALL/bin/` keeps the previous binary for rollback.
7. **Registration.** Find every Dev MCP registration: project `.mcp.json` files, the global `mcpServers` in `~/.claude.json`, and the Claude Desktop config at `~/Library/Application Support/Claude/claude_desktop_config.json`. That config's `appian-runtime` entry, if present, is the runtime MCP Server via `mcp-remote`, a different server that this procedure never touches. If that entry is still named `appian`, report the name collision (`reference/toolchain.md` §2) and leave the renaming to the operator, with the desktop app quit. Show the operator the current entry (secrets redacted) and the proposed replacement: the documented block — `uv run --directory NEW_INSTALL python -m lcp_mcp_server` with `env` carrying `LCP_URL` — where only the `--directory` value changes. If the current entry differs structurally from the documented shape (previous-generation variables such as `LCP_USERNAME`, `LCP_PASSWORD`, `LCP_API_PATH`, `LCP_AUTH_METHOD`), propose aligning it to the documentation and flag every difference with what the new server's `config.py` does with each variable. **Apply only on the operator's approval**, after backing up `~/.claude.json` to a dated copy; re-read the file to confirm only that entry changed; `claude mcp get appian` should show `NEW_INSTALL`.
8. **STOP — phase boundary.** Print exactly this: *"Phase 1 complete. Fully quit and relaunch Claude Code now (the running session keeps the old server). In the new session, say 'continue the update procedure'. The first Dev MCP tool call will open a browser sign-in window: complete SSO and MFA there; the session is captured under `~/.appian-devmcp/`."* Do nothing further in this session.

## Phase 2 — Re-verify (a fresh session after the relaunch)

1. **Confirm the new server is the one running.** Call `getDevMcpVersionInfo` (this may be the call that opens the browser sign-in; wait for the operator to complete it). Its `mcpServer` build stamp must equal `NEW_INSTALL/BUILD-INFO.txt`; if it still equals the old pin, the relaunch did not take — check `claude mcp get appian` and stop. Read the tool's recommendations: plugin and bundle from the same build is the expected state.
2. **Find the real version.** The plugin version and build stamp from the tool; `pyproject.toml` and `__init__.py` in `NEW_INSTALL` (the package version string may not change between generations — the build stamp is the discriminator); any changelog the bundle ships. Record what was found and where.
3. **Re-verify `reference/toolchain.md` §1 against the new source.** Read `NEW_INSTALL/src/lcp_mcp_server/browser_auth.py`, `config.py`, and `server.py`, and `diff` each against `OLD_INSTALL`'s copy. State what the code shows for: the default auth method and the environment variables read; the session storage path and layout; persistence across restarts; expiry detection and whether the server reopens the browser itself; logout; anything new. Rewrite the section from the code, not from the old text. Diff the tool inventory too — new tools close boundaries:
   - **What to diff:** the names of the `@mcp.tool`-decorated functions in `tools/*.py` in both installs. A count of `async def` lines also counts helper coroutines (13 of them in DevMCP 26.6.90).
   - **Cross-check:** confirm the new count equals the tool count the session reports for `appian`.
   - **On macOS:** write any extraction with `[[:space:]]`, never `\s`. BSD `sed` does not support `\s` and silently leaves every line unchanged; that is how three helpers were once counted as tools (`reference/mcp-capability-boundaries.md`, tool count note).
4. **Update the version pin** in `toolchain.md` §1: plugin version and build stamp as reported by the tool (with the tool named as the source), `NEW_INSTALL`, today's date, and the sha256 of the new `browser_auth.py`. Keep the "on server update, say 'run the update procedure'" note.
5. **Re-verify sail against `toolchain.md` §12.**
   - `sail --version` must report the new bundle's version.
   - Capture `sail --help` and every subcommand's `--help`, and diff them against the surface §12 records: commands, flags, value formats, and login modes. Rewrite §12 from the new help, not from the old text.
   - If the operator has a persona session logged in, repeat the read-only measurements against it, stating the account: `pages`, a `load`, `show` with the network blocked, and an unknown target under `--json` for the error stream.
   - Entries that need a write to re-measure are left flagged as not re-measured unless the operator approves a demo write: the submit's pre-form snapshot, `load --fresh`'s destination, the batch drops, and the import-and-logout session sharing.
   - Refresh `SAIL_PIN`: the version string, the binary path, and its sha256.
6. **Sweep the repo for old-path and old-behaviour references.**
   - **Names first:** `OLD_INSTALL`, the old state directory, retired variable names.
   - **Then behaviour, which a name sweep misses.** Check every entry in `reference/silent-failure-taxonomy.md` and `reference/mcp-capability-boundaries.md` that describes what the server does:
     - auth expiry and the ping false positive;
     - transport marshalling of test inputs and document content;
     - tool-surface gaps such as instance enumeration, multiple node instances, attended tasks, group membership, and agent reads.

     Include `toolchain.md` §2 and §4, and the sail entries: taxonomy class M, boundaries §10, and toolchain §12.
   - **For each entry:** verify it against the new code, the new help, or a read-only live call, and mark which generation it belongs to. Leave plugin-side entries that a server update cannot change with a note saying so.
7. **Summarize the behavioural delta** for the operator: what the new server and the new sail do differently, which boundaries narrowed or closed, and which entries could not be re-measured without a write and were left flagged.
8. **Commit and push on approval**, with the message `toolchain: re-verified against Dev MCP <version>`.
9. **Rollback stays available.** `OLD_INSTALL`, its `bin/` sail binary, and the dated `~/.claude.json` backup hold the previous generation and its registration until the next update. Re-running `OLD_INSTALL`'s setup script points `sail` back at the old binary. The operator decides when to remove them.

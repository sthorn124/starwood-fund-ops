# Toolchain and environment

Setup and environment knowledge for an Appian build driven through the Dev MCP from Claude Code. Everything here is environment-general; site URLs, accounts, and credentials belong in the build's own notes, never in this repo. Everything here was verified against a build log, a build script, the Dev MCP server's own source, or the sail evaluation. §1 records the server version the server-sourced sections describe, and §12 records the sail version. Bracketed S-numbers cite the sail evaluation's measurement record in `examples/persona-verification-walkthrough.md`.

## 1. Dev MCP registration and authentication

**Verified against DevMCP 26.6.95.**
- **Source of the version:** the server's own `getDevMcpVersionInfo` tool, which reads the plugin's `/meta` endpoint and the bundle's `BUILD-INFO.txt` and compares the two.
- **What it reported on the verified machine, 2026-09-21:** both halves came from the same build, and the tool said "No action needed".
  - Plugin `Appian Dev MCP` 26.6.95, App Market status up to date.
  - Build stamp `20260911-210447`, `mcp_src_sha 71a81a27e39421db`, `plugin_src_sha 29c65279f1df2529`.
  - Built from a detached branch rather than the mainline.
- **The build stamp is the discriminator.** The bundle's package version string (`lcp-mcp-server` 0.1.0 in `pyproject.toml` and `__init__.py`) has not changed across three generations. The MCP initialize handshake names the server `Appian-DevMCP-Server` and carries no product version.
- **Install:** `~/appian-dev-mcp-server-20260911-210447`, installed 2026-09-21 from `appian-dev-mcp-server-bundle (1).tar.gz`. `src/lcp_mcp_server/browser_auth.py` hashes to sha256 `bcf11935a9eca9c6ad48fbc0f0167924013d6dd2b4ecbdd1607ba04bfd45d385`.
- **Rollback:** the 26.6.90 install (build `20260903-195919`, `mcp_src_sha a037e2a260ba8fee`) remains at `~/appian-dev-mcp-server`.
- **What changed from 26.6.90 to 26.6.95.** The pieces this section and §2 describe are unchanged:
  - `browser_auth.py` is byte-identical.
  - `config.py` reads the same environment variables. The only changes are that the internal property `beta_base_url` became `lcp_base_url` and one line was reformatted.
  - The 157-tool inventory is identical by name.
  - The behavioural changes are recorded in `mcp-capability-boundaries.md` ("Changed in DevMCP 26.6.95").
- This section and §2 describe the 26.6.95 build.

**On server update, say "run the update procedure".** Claude Code then executes `maintenance/dev-mcp-update.md`, which:
- installs the new bundle side by side;
- re-verifies this section and §2 against the new server's source;
- re-checks the server-behaviour entries in the taxonomy and the capability boundaries;
- refreshes this pin.

**Why the procedure exists.** The auth default, the environment variable names, the state directory layout, the expiry handling, and the logout behaviour are all read from the source, and every one of them changed between the generation before 26.6.90 and 26.6.90.

**Every session:** the preflight (`CLAUDE.md` §2) compares `getDevMcpVersionInfo`'s report with this pin, and `sail --version` with the sail pin in §12, because sail ships in the same bundle.

- **What it is.** The Appian Dev MCP is a local server package (`lcp-mcp-server`, Python module `lcp_mcp_server`) run with `uv`. It is downloaded as a bundle that matches the site's DevMCP plugin, from one of two paths behind the site's login. The documented downloads page, `/suite/plugins/servlet/stateless/downloads`, is the operator-facing entry. The direct bundle link, `/suite/plugins/servlet/stateless/lcp-mcp-bundle`, is the one `getDevMcpVersionInfo` prints (`maintenance/dev-mcp-update.md` Step 0). The bundle is then unpacked into a directory of your choosing: `~/appian-dev-mcp-server` in the documentation and on the verified machine (the two source builds ran the previous generation from `~/lcp-mcp-server`). It talks to the site through the plugin's stateless servlet at `/suite/plugins/servlet/stateless/lcp-api`. Setup instructions are Appian's own: `https://docs.appian.com/suite/help/26.8/devmcp.html`. Install is `uv sync` then `uv run playwright install chromium`; the documented `uv sync --extra browser` step errors on this bundle ("Extra `browser` is not defined") because Playwright is a core dependency that the first sync already installs, so the error is harmless. Where the Playwright download is blocked, `LCP_BROWSER_CHANNEL=chrome` or `msedge` uses a system browser instead.
- **Where it is registered.** In Claude Code's user-level configuration (`~/.claude.json`, global `mcpServers`, or `claude mcp add`), not per project; every project folder on the machine inherits it. The documented block, which is also the complete one for a single-user SSO site:

  ```json
  "appian": {
    "command": "uv",
    "args": ["run", "--directory", "/ABSOLUTE/PATH/TO/appian-dev-mcp-server", "python", "-m", "lcp_mcp_server"],
    "env": { "LCP_URL": "https://<site>.appiancloud.com" }
  }
  ```

  Optional variables, all read by this build: `USERNAME` (names the per-user session directory, lets several registrations run as different users, and makes the server refuse a login by anyone else); `LCP_AUTH_METHOD: basic` with `USERNAME` and `PASSWORD` for a site where no browser can be opened; `LCP_SIGNIN_PATH` (`/suite/?signin=<idp>` to skip a sign-in chooser); `LCP_AUTH_LANDING_PATH` for a custom post-login page; `LCP_BROWSER_CHANNEL`; `LCP_COOKIE_PATH` and `LCP_BROWSER_PROFILE_PATH` as state-path overrides; and the standard `HTTPS_PROXY`, `HTTP_PROXY`, `SSL_CERT_FILE`. The previous generation's variables are gone: `LCP_USERNAME` and `LCP_PASSWORD` are no longer read at all, and `LCP_API_PATH` now defaults to the servlet path that used to have to be set explicitly (its old default was a different endpoint). Leaving `PASSWORD` or `LCP_PASSWORD` in the block without `LCP_AUTH_METHOD` is a startup configuration error, by design, because the default auth method changed from basic to browser.
- **Authentication flow** (read from `browser_auth.py`, `config.py`, and `server.py`). Browser auth is the default. At startup the server loads any persisted session from `~/.appian-devmcp/<hostname>/<USERNAME or default>/cookies.json`, so the common case opens no browser and the stdio handshake is not blocked. When there is no valid session, the first tool call launches a Chromium window (a persistent profile at `browser-profile/` beside the cookie file) at the sign-in path, and you complete SSO and MFA in it within five minutes. When the browser reaches a post-login Appian page (`/suite/tempo`, `/suite/design`, `/suite/sites`, `/suite/actions`, `/suite/records`, `/suite/reports`, or the configured landing path) the server captures the session cookies — `JSESSIONID`, the `__appian*` CSRF tokens, and remember-me cookies where present — asks `/suite/cors/ping` which user it is signed in as, records that username inside the cookie file, and from then on replays the cookies as a `Cookie` header plus the CSRF token on every plugin call. On the verified machine the captured file holds three cookies, the recorded username, an 8-hour expiry, and owner-only permissions. The identity the tools execute as is the account that signed in, and every readback is scoped by that account's group memberships. If `USERNAME` is configured and the browser authenticates as someone else, the server discards the cookies and fails with a message naming both users.
- **Session persistence and expiry.** The session lives on disk, not in the process, so it survives server restarts and app relaunches. Session cookies carry no expiry, so the server caps their replayable lifetime at 8 hours, and it treats a 401, a 403, or any non-5xx HTML response on the JSON API path as an expired or server-invalidated session — an SSO bounce, whatever status the identity provider used. On expiry it clears the stored cookies, opens the browser window again, and retries the call once, under a lock so concurrent tool calls open a single window. The normal expiry is therefore self-healing: a sign-in window appears mid-session, you complete it, the call proceeds. To end a session or switch users, the server's `logout` tool deletes the per-user state directory — cookies and browser profile together, because the profile caches the identity provider's own session and would otherwise sign the same user straight back in with no credential prompt and no MFA; the equivalent by hand is deleting `~/.appian-devmcp/*`. A leftover `~/.appian-mcp/` directory is the previous generation's state and is not read.
- **The quit-and-relaunch fix is not an auth fix.** What it cures is a server process that has stopped answering: no sign-in window appears when one should, design calls hang, or the design-object tools are absent from the session while `claude mcp list` still reports the server connected and `ping` still answers — measured once with the previous generation, where the surface came back by the next session. MCP servers are started by the app at launch, so fully quitting the Claude desktop app (menu-bar quit, not closing the window) and relaunching it restarts every server process. Use it for that symptom and nothing else, and rule out a name collision first: if the tools present under `appian` are the runtime family, a relaunch reshuffles the collision rather than curing it (§2) [S34]. For auth errors the documented order is: expect the browser to reopen on the next call; if it does not, `logout` (or delete `~/.appian-devmcp/*`) and call again. The app's Settings → Developer page shows each server's connection status and logs.
- **Preflight, every session.** Before any work, confirm the design-object tool surface is present (not just `ping` and a runtime subset) and make one trivial design read. If the surface is missing, stop and report; it has been measured as transient and returned on its own the next session. The full preflight is in `CLAUDE.md` §2. `getDevMcpVersionInfo` tells you whether the plugin and the bundle are the same build before you spend a session debugging a tool.

## 2. Two servers, one name: the identity trap

Pinned to the server version recorded in §1.

Two Appian MCP servers can be configured on one machine:

- the **Dev MCP**: the design surface, executing as the designer account;
- a **runtime MCP**: invoke process, data fabric query, agent invoke, executing as whatever service account its API key belongs to.

**Registered under the same name, they silently share one tool namespace, or one hides the other** [S34]. On one machine, with both named `appian`:

- one session carried only the runtime server's 10 tools under the name, with the design tools absent while a same-named server answered;
- after a relaunch, a session carried both sets merged: 167 tools under one `mcp__appian__` prefix.

`claude mcp list` shows neither the collision nor the desktop-inherited server. Nothing in a merged tool's name says which server it runs on or as whom.

- **The rule: name servers by role.** `appian` for the Dev MCP, the name in Appian's documented registration block (§1), and `appian-runtime` for the runtime server. Renamed that way on the same machine, the next session listed `appian` with the Dev MCP's 157 tools and `appian-runtime` with the runtime server's 10. The runtime tools then carried their server in their names (`mcp__appian-runtime__appian_invoke_process_model`) [S34].
- **The symptoms of a collision.** Either the preflight's design-surface check fails while `appian` is connected (the shadow), or snake_case `appian_*` tools appear under `mcp__appian__` beside the camelCase design tools (the merge).
- **The tell between families holds either way.** Dev MCP tools are camelCase and unprefixed (`listRecordTypes`, `getRecordType`, `testRule`, `testProcessModel`, `createExpressionRule`). Runtime tools are snake_case with a product prefix (`appian_invoke_process_model`, `appian_data_fabric_sql_query`, `appian_search_tools`, `appian_invoke_agent`) plus `ping`.
- **The consequence of using the wrong family:** a process started through the runtime server under a foreign service account completes green with every row-secured read empty and every PK-targeted write succeeding. See `silent-failure-taxonomy.md`.
- **The rule for use:** design-session work uses the Dev MCP only. Runtime tools are not used for tests or checks. The service account gets no scope in the application. When a runtime server is present, its tools are banned in the project's `CLAUDE.md` by name.
- **Confirming identity:** a throwaway expression rule returning `loggedInUser()`, run through `testRule`, then deleted.
- **Where the runtime server comes from, and why its name drifts.**
  - **Registration.** Appian's runtime MCP Server authenticates with a static service-account API key sent as a bearer header, which the desktop app's connector dialog cannot carry. So it is registered in the desktop app's own config (`~/Library/Application Support/Claude/claude_desktop_config.json` on macOS) through the `mcp-remote` bridge. The header value is held in an environment variable (`Authorization:${APPIAN_AUTH}`), because a space inside a `--header` argument is mangled and yields an opaque 401. Every call through it runs as that service account.
  - **How Claude Code sessions receive it.** That registration is invisible to `claude mcp list`, and the desktop app hands it to every Claude Code session it runs, alongside the servers in the Claude Code configuration (§4). The app's log records `[localMcpBridge] announcing <name>: 10 tool(s)` as it passes the server in [S34].
  - **The app rewrites the file from its in-memory copy.** A rename made while the app was running was undone at the app's next `Config file written` log event, leaving the file byte-identical to the pre-edit copy. The same rename made with the app fully quit held [S34].
  - **So:** edit that file only with the app quit, and re-check the runtime server's name after app updates.

## 3. Docs-search MCP registration

- **What it is.** Appian's public documentation search, an HTTP MCP server registered at user level alongside the Dev MCP:

  ```json
  "appian-public-docs": { "type": "http", "url": "https://appian-docs-public.mcp.kapa.ai" }
  ```

  Its tool is `search_appian_knowledge_sources`. It is consulted before any layout edit and before any uncertain parameter, keyword, or icon name (`CLAUDE.md` §5).
- **It expires.** Its token expires and the server drops out of a session with no warning beyond the tool being unavailable. When that happens, say so in the response, settle the question by measurement on the instance, and re-authorize it from an interactive `claude` session (`/mcp`) afterwards. Do not silently skip the grounding step.
- **What it is for and not for.** It establishes what a parameter is and what the general component surface documents. It cannot establish what a specific environment can do; a working example on the instance outranks it, and "the docs do not mention it" is never evidence of absence.

## 4. Account-level connector inheritance (check for it)

Connectors configured in the **Claude desktop app** (claude.ai connectors and plugin connectors) are inherited by **every Claude Code session on the machine** and are **invisible to `claude mcp list`**, which shows only servers registered in the Claude Code configuration. So are the local servers in the desktop app's own config file, and one of those can collide by name with a Claude Code server (§2). A session can therefore carry dozens of tool servers — data warehouses, ticketing, chat, CRM, document stores — that nothing in the project or in `~/.claude.json` mentions.

- **Why it matters.** A tool name in a session may belong to a server nobody registered for this build, running under whatever account the desktop app connected it as. That is the same class of trap as §2, one level up: the identity behind a tool is not visible from the tool's name.
- **How to check.** At preflight, read the session's own tool listing and the "servers require authentication" notice rather than `claude mcp list`; `~/.claude/mcp-needs-auth-cache.json` lists inherited connectors that are configured but not authorized. Manage them in the desktop app's connector settings and its config file (§2), not in Claude Code.
- **Rule.** A build names the servers it uses (Dev MCP, docs-search, and any project-specific server) in its `CLAUDE.md`; every other server present in the session is ignored, and no data leaves the build through a connector the build did not name.

## 5. Skills and packs

- **Vendor pack.** Appian's base skill for the Dev MCP, the `skills/appian` folder of `https://github.com/appian/dev-mcp-skills`.
  - **Where it lives.** It is installed at user level as `~/.claude/skills/appian/`, with `SKILL.md` at the top of that folder, so Claude Code loads it as a skill named `appian` alongside the supplemental. Its `references/` directory carries the layout, component, and object references that the supplemental names for grounding. Load the applicable references before object work.
  - **Installed version.** On the verified machine, from commit `6e87fb6` (2026-09-23).
  - **How to install or update it.** Clone the repo to a temporary folder and copy its `skills/appian` folder into place, as Appian's README does. The first-launch setup prompt (`GETTING_STARTED.md` §1, step f) does this.
  - **How to check for an update.** Diff a fresh clone's `skills/appian` against the installed folder.
  - **The older layout never loaded.** An older install cloned the whole repo into `~/.claude/skills/appian/`. That left `SKILL.md` two folders down, so Claude Code never registered the skill, and sessions reached its references only by path.
- **appian-supplemental.** Installed at `~/.claude/skills/appian-supplemental/SKILL.md` from this repo's `skills/appian-supplemental/`. It corrects the pack where the pack is measured wrong and carries the portable method. Grow it only through the promotion gate in `CLAUDE.md` §9.
- **Frontend design guidance.** The frontend-design plugin skill is loaded before any interface layout or styling edit, per the supplemental's UI grounding section.
- **Project skill.** A `.claude/skills/<prefix>-standards/SKILL.md` inside the build folder carries only what is specific to that build (palette, naming prefix, layout applications). Environment-general facts discovered while building it are written to the supplemental as candidates, never to the project skill.

## 6. Local working files

- **`.work/`** holds byte-exact copies of deployed SAIL (`<Object>.sail`) and the harness generators that derive throwaway verification interfaces from them. Every `update*` call over the Dev MCP is a full replacement of the object's expression (and `updateProcessModel.nodes` and a node's `data` section are full replacements too), so the local copy is the thing edited and the environment is the thing pushed to, then read back.
- **`prompts/`** holds the Claude Code build prompts as numbered files (`prompts/NNN-<slug>.md`, see `GETTING_STARTED.md` §4); `prompts/model/` holds every word a model inside the application is given, as files, with `prompts/model/_generated/` for the SAIL mirrors and a checksum lock file (see §7 and `patterns.md`). The template ships the directory empty.
- **`mockups/` and `agent/`** ship empty and are described in `patterns.md`; **`fixtures/`** is an optional per-build directory for hand-authored verification fixtures and their re-date script. External-system scripts a human runs (warehouse DDL, procedures, verification queries) live in a folder named for that system, and are statically checked before hand-off (tokenised with comments and strings stripped, parentheses balanced, forbidden tokens absent, expected counts of bodies and checks) with unresolved values left as deliberately invalid markers so nothing deploys silently.
- **Reading spreadsheets without extra packages:** an `.xlsx` is a zip; `unzip` plus the standard library's `xml.etree` over `xl/worksheets/sheet1.xml` and `xl/sharedStrings.xml` reads it without `openpyxl`. Generators stay standard-library, deterministic, and md5-stable across runs, take an explicit `--as-of` date so a diff isolates the edit from date drift, and put their assertions at the bottom.

## 7. Source-edit pattern: Python string replacement with asserts

Edits to large deployed sources (a 300 KB wizard, `BUILD_PLAN.md`, `TODO.md`) are made by a short Python script rather than by hand, and the script **asserts the anchor is unique before replacing it**:

```python
import pathlib
p = pathlib.Path(".work/Some_interface.sail")
s = p.read_text()
old = "  local!removedCsv: \";\","          # an exact, unique anchor
new = "  local!removedCsv: \";13;30;\","
assert s.count(old) == 1, s.count(old)     # 0 means the source moved; 2 means the anchor is ambiguous
s = s.replace(old, new, 1)
p.write_text(s)
```

Rules that make this safe:

- One anchor, one assert, one replacement; a failed assert is the signal that the source changed since the anchor was chosen, which is exactly when a blind edit would land in the wrong place.
- Whole-file read and write; no regex without an anchored, counted match.
- Anything derived from the source is computed from it, never listed by hand (a harness's hidden unused-locals block is computed from the declared locals that appear exactly once; comments are stripped before counting so prose naming a variable is not counted as a reference).
- Generated mirrors of a source-of-record file carry a checksum lock (`sha256` of the source, written beside the mirror) and a `--check` mode that fails when the mirror is stale, so drift between a repo file and a deployed rule is detectable rather than silent.
- After the edit, push the object over the Dev MCP and verify by readback and render, not by the edit having applied locally.
- **Fingerprint every round trip.** After every save, flip, and restore, read the deployed source back and compare it to the local intended copy with `md5` (a readback may differ only by a trailing newline); `diff` a restored source against its pre-change file and count changed code lines versus comment-only hunks; a refactor is proven by feeding a real past run's stored input through the old and new rule and comparing the digests character for character. Note that a probe saved to an object counts as a version — record which versions were probes.

## 8. Document pipeline

- **Generated documents are built with the standard library only and are byte-stable.** The document generators use no third-party packages (no `openpyxl`, no `reportlab`), no `rand()` and no `today()`, so the same input produces the same bytes on every run (checked by `md5`), which is what makes a demo identical at every rehearsal and a multi-run agent-consistency test meaningful.
- **Generated documents are kept pure ASCII so they survive the Dev MCP's string-typed upload.** `uploadDocument` round-trips content through UTF-8 and doubles every byte above `0x7F` (a 32-byte probe stored as 64), so a CSV is written with `encoding="ascii"`, and a PDF is hand-built with uncompressed content streams and WinAnsi text, encoded as latin-1 through an escape function for parentheses and backslashes — such a PDF uploaded intact. A spreadsheet is a ZIP (1,889 of one file's 4,699 bytes were non-ASCII, including control bytes) and cannot be uploaded at all; it is dropped into the folder by hand and confirmed intact by reading `document(id, "size")` against the local file before anything is wired to it.
- **Word templates and their payloads are one contract** (supplemental §8): regenerate templates outside Appian, upload as a new version of the existing document, prove generation by existence and size, and treat literal `${…}` survivals, empty loop tables, and pagination as browser-only checks.
- **An animated GIF was encoded by hand** (no image library on the machine), decoded back frame by frame before it went anywhere, and served at `size: "FIT"`, because any other size resamples it to one flattened frame.

## 9. Non-ASCII and escaping in source

- **The Dev MCP transport is not uniform about non-ASCII.** `uploadDocument` doubles high bytes (§8); an expression payload carrying a raw `❄` (U+2744) round-tripped the transport intact (`len` 1, code 10052), so the doubling is specific to document upload. Interface and rule sources in both builds carry raw UTF-8 characters (middle dots, em dashes, glyph markers), and the HTML mockups are raw UTF-8 with a `charset` meta tag; no source file in either build uses `\uXXXX` escapes.
- **SAIL has no backslash escapes.** A pass that wrote `\"`-style escapes into a SAIL literal shipped a defect; the house style for attribute-heavy emitters is `local!q: char(34)` concatenated in, because SAIL's doubled-quote form is miscountable by eye.
- **Values that reach XML are escaped by one dedicated rule** (`& < > " '`, ampersand first), and the escaping is proven arithmetically — every `&` in the output counted against the entities it opens — not by inspection.

## 10. Browser checks and personas

- **Persona checks split by kind** (`CLAUDE.md` §4). The session checks content, field state, visibility, navigation, record-view actions, and behaviour on published pages through sail as the persona (§12), from sessions the operator logged in. The design account's own reads prove nothing about a persona [S32].
- **What stays a browser check owned by a human**, written into `TODO.md` as a checklist with steps, personas, and expected strings:
  - geometry and paint;
  - document access as a persona, since sail cannot follow a download link [S9];
  - plain URL links;
  - anything on an interface not placed on a page;
  - any persona without a local account.
- The in-app browser cannot stand in for a persona either: it lands on the site's SSO, and a session never types credentials.
- Screenshots supplied by the human settle the geometric questions; a build does not ask for them to be closed by fixing card heights or pinning widths.

## 11. Evidence from human-run external consoles

When a human must run something in an external console (a warehouse worksheet, an admin tool) and paste evidence back, deliver **one statement that returns one grid** with `check_name | result | detail` and `PASS`/`FAIL` per row. Multi-statement blocks whose results must be clicked through or exported one at a time are not evidence: the console shows one result at a time and exports only the visible one. Setup scripts may run many statements; their verification is a separate one-grid statement. Where intermediate states are needed, use the console's scripting block form so the whole check runs as one statement and an exception handler appends a FAIL row rather than stopping the output.

## 12. The sail CLI: persona sessions from the terminal

**Verified against sail 26.6.95.**

- **The binary:** `~/appian-dev-mcp-server-20260911-210447/bin/sail-darwin-arm64`, 8,944,338 bytes, sha256 `5ccd5559a074f9246a9d6f921d913d7de6f943ef875ade932ebef3457f901bca`.
  - It is linked as `~/.local/bin/sail` by the bundle's `setup-mac.sh`.
  - It shipped in the DevMCP 26.6.95 bundle installed per §1.
  - `sail --version` reports `sail version 26.6.95`, the bundle's own version.
- **Re-verified 2026-09-21:**
  - The complete help surface is byte-identical to 26.6.90's: `--help` for the root and for all nine subcommands (`pages`, `load`, `show`, `navigate`, `interact`, `back`, `login`, `logout`, `completion`), 328 lines each.
  - The command table below therefore stands unchanged.
- **Measured on 26.6.90 only:** the behaviour entries below. No persona session was live on the machine, so they were not re-measured against 26.6.95.
- **Rollback:** the 26.6.90 binary (sha256 `43c346d8…a1c37`) remains in `~/appian-dev-mcp-server/bin/`.
- The preflight (`CLAUDE.md` §2) runs `sail --version` beside `getDevMcpVersionInfo` every session. The update procedure (`maintenance/dev-mcp-update.md`) re-links and re-verifies sail along with the server, because they ship in one bundle.
- Everything below was read from `--help`, read from the bundle's setup scripts, or measured in the evaluation recorded in `examples/persona-verification-walkthrough.md`. Nothing is taken from the binary's symbols, which misreported the surface [S3].

### What it is and how it is installed

- **What it is.** A single Go binary: a command-line client for Appian's SAIL interfaces.
  - It logs in as an account and exchanges the same SAIL UI JSON a browser would. Requests go to the site's REST endpoints (for example `/suite/rest/a/sites/latest/<site>/nav`), and the stored UI is the server's component tree.
  - It has no browser engine and renders nothing. That is why it sees component state and style values but no computed layout [S8].
  - Every command that leaves a UI on screen prints a listing ("On screen there are N actions you can take and M read-only values") and stores the full UI beside it.
- **Where it ships.** The Dev MCP bundle's `bin/` holds three binaries (`sail-darwin-arm64`, `sail-linux-amd64`, `sail-windows-amd64.exe`) and one setup script per platform [S1].
- **What `setup-mac.sh` does** (read from the script):
  - clears the Gatekeeper quarantine flag a downloaded binary carries;
  - links `sail` into `/usr/local/bin`, or into `~/.local/bin` when that is not writable, warning that the fallback may not be on `PATH`;
  - refuses to replace a `sail` that is not its own link;
  - repoints an existing link that points at a sail binary, so re-running it from a newer bundle moves `sail` to that bundle;
  - finishes by running `sail --help` to prove the binary executes.

  On the verified machine it took the `~/.local/bin` fallback [S1]. The macOS binary is arm64 only.
- **`setup-windows.bat`** states in its own header that it has not been run on Windows. It copies rather than links, and edits the user `PATH`.

### Commands and output

- **Command surface, from `--help`** [S2]:

  | Command | What it does |
  |---|---|
  | `pages <site>` | Lists the pages the account can see, in tab order, marking the default. |
  | `load <site> [page]` | Fetches a page by URL stub or tab label. `--fresh` deliberately discards entered values; otherwise a load over a page with interactions is refused [S24]. |
  | `show <site>` | Re-prints the stored page; no request is sent [S6]. |
  | `navigate <site> <target>` (alias `nav`) | Follows a record link, tab, related action, or process launch. |
  | `interact <site> <ref> [<value>] …` | Sets fields and presses buttons; `--confirm` for targets with a browser confirmation dialog. |
  | `back <site>` (aliases `close`, `dismiss`) | Discards the current UI and restores the one it came from, closing a related-action form without submitting. |
  | `login <host> [site]` | Stores a session; takes `--from-devmcp` and `--user`. |
  | `logout` | Revokes the session on the server and deletes local state. |
  | `completion`, `help` | Shell completion and help. |

  Global flags are `--data-dir`, `--json`, and `-v`/`--version`. There is no identity command.
- **Reading the listing.** Each line is a ref, quoted exactly as it must be passed, followed by its kind:

  | Kind | Meaning |
  |---|---|
  | `<display>` | Text on the page. The root help says this includes a chart's plotted values. |
  | `<navigate>` | A link, with what following it does: "opens a record view", "opens a related action form", "launches a process (not reversible)". |
  | `<click>` | A button or link to press. |
  | `<index>` | A choice field, followed by its `choices:` line. |
  | `<text>`, `<date>`, `<search>` | Text, date, and picker or search fields. |
  | `<grid>` | A grid, with `handle:` lines for sort columns, search, refresh, and pages. |
  | `<url>` | A plain hyperlink no sail command can follow. |

  Also on the listing:
  - Field state is bracketed: `[REQUIRED]`, `[INVALID]`, `[DISABLED]`, `[READONLY]`.
  - A `confirm:` line marks a target the browser would confirm first.
  - Refs beginning `⌗` are ones sail synthesised for unnamed or repeated components. The help says they hold across reloads; they renumber when a re-render removes a sibling [S22].
  - An ambiguous target is listed as unaddressable ("this name leads to more than one destination") [S9].
- **The listing is a summary; the YAML is the page.** Each load, navigate, or interact overwrites two files per site in the data directory: `<site>-ui.json` (the full tree) and `<site>-ui-concise.yaml` (the same content, compacted). For one dashboard page they were 572,942 and 154,694 bytes [S5]. Grid rows past the second, tag values, milestone details, and a changed sort order are only in these files [S7]. Read the YAML whenever the question is about values.

### Driving components

- **Value formats, from `interact --help`:**
  - Buttons and links take no value. Text, paragraph, and number fields take the literal text.
  - Dropdowns, radios, and checkboxes take the **1-based index** of the choice: "1,3" for multi-select, "" for none. A dropdown empties by selecting its placeholder.
  - Dates take `YYYY-MM-DD` or `M/D/YYYY`; anything else is refused before sending [S21].
  - File uploads take a local path.
  - Grids, charts, tabs, and hierarchies take a `handle:` line. Pickers and record-grid searches take a handle plus the search text.
- **Batching.** Several pairs in one command go out as one request, resolved before sending: an unresolvable ref fails the whole command and nothing is sent [S20]. A target that takes no value may only end the batch; mid-batch, the error names the next token as a component with no value [S14].
- **Addressing, as measured** [S3, S14]:
  - `interact` resolves a label case-insensitively and by any unambiguous beginning. It also resolves a full component id, but not an id prefix.
  - `navigate` resolved a shortened target only with its `⤴` marker, despite its help saying the marker is optional. The full label resolved without it.
- **`--json` for agents.**
  - `pages` returns `default`, `loaded`, `pages` (each with `default`, `label`, `loaded`, `stub`), `site`, and `status`.
  - `interact` returns `status`, `changed`, `changedFields`, `options`, `validations`, `movedNothing`, `conciseUiPath`, `site`, and `ui` [S12].
  - Errors do not come back as JSON. They go to stderr as plain text, with stdout empty and a non-zero exit [S19, S23], so check the exit code before parsing.
  - A validation-blocked submit returns `status: "ok"` and exit 0 [S12].

### Sessions and login

- **Sessions and storage.**
  - The data directory defaults to `$SAIL_HOME`, then `~/.sail`. `--data-dir` sets it per command and isolates sessions completely [S26].
  - The directory is created `0700`. `session.json` is `0600` and holds the host, the session cookies, the CSRF token, a timestamp, and the username typed at login, plus `"source": "devmcp"` for an import [S25, S30].
  - `session.json` is a bearer credential: a copy authenticated from another directory [S27].
  - `logout` invalidates the session on the server and deletes `session.json` and every page file, leaving the directory [S28].
- **Login.**
  - `SAIL_USERNAME` and `SAIL_PASSWORD` in the environment, then `sail login <host>`, store a session for later commands.
  - The account must be a local Appian account; on a site that also has SSO, that is a test account rather than an SSO identity. A login with neither the variables nor `--from-devmcp` is refused, naming the variables [S29].
  - `--from-devmcp` imports the session the Dev MCP captured with its browser for the same host; `--user` picks one when several identities are cached. It checks the session against the site first and names the authenticated user once [S29, S30].
  - The imported session is the Dev MCP's own server session, not a copy of it (`CLAUDE.md` §6) [S31].
- **Speed, measured on one site:** `load` 0.72–1.83 s, `navigate` 0.36–1.41 s, a submit 0.54 s, `show` 0.20 s [S5, S6, S10, S11, S13].

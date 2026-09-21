# Closeout — 2026-09-21 — Phase 0 rulings recorded; Dev MCP update blocked at bundle download

## Scope and identity

- **This was a ruling session.** No build work was done and nothing on the instance was written.
- **The one Dev MCP read** was `getDevMcpVersionInfo`, as `scott.thorn@appian.com` (from the session file). That account is a member of `SD Administrators` and `SD Users`.
- **Not used:** the runtime connector `appian-runtime` and sail.

## Ruling 1: the service accounts in `SD Administrators` are an exception, not removed

- `scott.mcp` and `NoahMCPServiceAccount` stay in `SD Administrators`, and so in `SD Users`.
- **Reason:** `scott.mcp` backs the chat runtime connector. On a demo instance, removing it is a risk not worth taking.
- **Where it is recorded:**
  - an exception block dated 2026-09-21 at the end of `CLAUDE.md` §6, next to the clause it contradicts;
  - the project section's former "Open issue" bullet, which now points to that block.
- **What the exception covers:** only the membership.
  - The runtime connector (`mcp__appian-runtime__*`) still never runs design-session work.
  - A read through any service account runs with administrator scope, so it proves nothing about what a persona sees.
- **Logged** in `BUILD_LOG.md`. The TODO item is closed.

## Ruling 2: the host application

- Draw approval lives in **`Starwood Demo`** (`dd3bb740-b105-421b-a866-29d542a144da`), which is confirmed.
- `Capital Calls & Distributions` belongs to a different client and is out of scope for this build. Do not read from it or reference it.
- **Recorded** in `PROJECT_INSTRUCTIONS.md` (header facts), the `CLAUDE.md` project section, and `BUILD_LOG.md`. The latter corrects the previous entry's wording, "out of scope unless ruled otherwise".
- The client-validation TODO item is closed.

## Dev MCP update: not done, stopped at Step 0

**Ordering check:**
- The plugin is 26.6.95, build `20260911-210447`, and App Market reports it `UP_TO_DATE`.
- The local server is build `20260903-195919`, the 26.6.90 pin, and is still out of sync.
- An update is therefore warranted.

**Where it stopped:**
- The only Dev MCP bundle in `~/Downloads` is `appian-dev-mcp-server-bundle.tar.gz` (Sep 12). Its `BUILD-INFO.txt` shows `build_timestamp=20260903-195919`, which is the installed generation. Installing it would reinstall 26.6.90, so the procedure stops there by its own rule.
- The 26.6.95 bundle sits behind the site login. Downloading it is an operator step.

**Why versions could not be verified as matching this session:** even with the bundle, the procedure runs in two phases with a full app relaunch between them. The running session keeps the old server process, so Phase 2's version match can only be checked in a fresh session.

**Nothing was changed:**
- The install directory, the `~/.claude.json` registration, and the sail link are untouched.
- The pins in `reference/toolchain.md` §1 and §12 are unchanged.

**Phase 1 prerequisites are already confirmed:**
- Python 3.14.6 and uv 0.11.28.
- The registration is the documented shape (`uv run --directory /Users/scott.thorn/appian-dev-mcp-server python -m lcp_mcp_server`, env `LCP_URL` only).

**To finish the update:**
1. Sign in and download the bundle to `~/Downloads`, from `https://ny.appiancloud.com/suite/plugins/servlet/stateless/downloads` or the direct link `https://ny.appiancloud.com/suite/plugins/servlet/stateless/lcp-mcp-bundle`.
2. Say "run the update procedure". Phase 1 installs the bundle side by side, relinks sail, and changes the registration on your approval.
3. Fully quit and relaunch the app, then say "continue the update procedure". Phase 2 verifies that the versions match and refreshes the pins.

## Verified

- The version report, from `getDevMcpVersionInfo`.
- The bundle's build stamp, read from the tarball without extracting it.
- The ruling text, read back in `CLAUDE.md`, `PROJECT_INSTRUCTIONS.md` and `TODO.md`.

## Not verified

- A version match after an update, because no update took place.

## Promotion candidates

0 new. The staged `listGroupMembers` candidate carries over unchanged. The checkpoint is current through this entry.

## TODO changes

- **Closed and moved to Done (2026-09-21):**
  - service accounts in `SD Administrators`, ruled an exception;
  - which application hosts draw approval, ruled `Starwood Demo`.
- **Updated:** "Dev MCP bundle out of sync" now carries the Step 0 blocker and the three steps to finish.
- **Still open:** Blocking: the Phase 0 plan. Before demo: the spec artifacts not on GitHub, and persona accounts with sail logins.

## BUILD_PLAN.md changes

None. It is still a stub pending Phase 0.

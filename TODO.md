# TODO — Starwood draw approval

Open items by class. Sessions add discovered items unprompted as they surface, and any response that touched this file ends with a `TODO changes:` line stating what was added, moved, or closed. Every item carries an owner and a firing condition ("trigger: …"); nothing is parked on "later". Superseded items are struck through with a pointer to the standing decision, not deleted; completed items move to Done with the date. The contract is `CLAUDE.md` §8.

## Blocking

- **Phase 0 plan for draw approval.** `BUILD_PLAN.md` is still the stub, so the preflight plan gate stops all build work until it is written.
  - *Owner:* Scott, in the claude.ai Project.
  - *Trigger:* before the first build session.

## Before demo

- **Dev MCP bundle out of sync with the plugin.** The plugin is 26.6.95 and the local bundle is the 26.6.90 build (20260903).
  - *Owner:* Scott.
  - *Status 2026-09-21:* the update procedure was started and stopped at Step 0. The only bundle in `~/Downloads` (`appian-dev-mcp-server-bundle.tar.gz`, Sep 12) carries the installed build stamp `20260903-195919`, so there was nothing new to install.
  - *Steps:*
    1. Sign in and download the 26.6.95 bundle to `~/Downloads`, from `https://ny.appiancloud.com/suite/plugins/servlet/stateless/downloads` or the direct link `…/lcp-mcp-bundle`.
    2. Say "run the update procedure". Phase 1 installs the new bundle beside the old one, relinks sail, and changes the registration on your approval.
    3. Fully quit and relaunch, then say "continue the update procedure". Phase 2 checks that the versions match.
  - *Trigger:* your next session, once the bundle is downloaded.
- **Spec artifacts are not on GitHub.** `.gitignore` excludes `*.pdf` and `*.xlsx`, so the three spec files exist only on this machine.
  - *Owner:* Scott.
  - *Steps:* upload them to the claude.ai Project, or rule that they are force-added to the repo.
  - *Trigger:* before Phase 0 starts in the Project.
- **Persona accounts and sail logins.** No persona sessions exist, and the application has no site yet, so the persona site stub is unset.
  - *Owner:* Scott.
  - *Trigger:* once Phase 0 names the draw approval personas and the site exists.

## Browser checks owed

*(Owner: a named human. Each item lists the steps, the persona to log in as, and the expected strings — a checklist the human can run, not an open question. Content, state, and behaviour that a session can check through sail as the persona are not browser checks: geometry, document access, and what sail cannot reach are (`CLAUDE.md` §4).)*

## Client validation questions

## Deferred

- **Inventory the remaining object types** of `Starwood Demo` (rules, constants, integrations, documents, agents and so on), names only.
  - *Owner:* the build session.
  - *Trigger:* the first session that designs draw approval objects which reuse intake objects.
- **Confirm the designer identity by probe.** Run a throwaway rule returning `loggedInUser()`, then delete it.
  - *Owner:* the build session.
  - *Trigger:* the first session in which the plan gate passes.

*(Each item names its trigger.)*

## Done

- ✅ 2026-09-21 — **Service accounts in `SD Administrators`:** ruled an exception. `scott.mcp` and `NoahMCPServiceAccount` stay in the group, because `scott.mcp` backs the chat runtime connector and removal risk is not worth it on a demo instance. The ruling is recorded at the end of `CLAUDE.md` §6.
- ✅ 2026-09-21 — **Host application:** `Starwood Demo` (`dd3bb740-b105-421b-a866-29d542a144da`) is confirmed. `Capital Calls & Distributions` is another client's app and out of scope; do not read from it or reference it. Recorded in `PROJECT_INSTRUCTIONS.md` and `CLAUDE.md`.

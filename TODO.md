# TODO — Starwood draw approval

Open items by class. Sessions add discovered items unprompted as they surface, and any response that touched this file ends with a `TODO changes:` line stating what was added, moved, or closed. Every item carries an owner and a firing condition ("trigger: …"); nothing is parked on "later". Superseded items are struck through with a pointer to the standing decision, not deleted; completed items move to Done with the date. The contract is `CLAUDE.md` §8.

## Blocking

- **Phase 0 plan for draw approval.** `BUILD_PLAN.md` is still the stub, so the preflight plan gate stops all build work until it is written.
  - *Owner:* Scott, in the claude.ai Project.
  - *Trigger:* before the first build session.

## Before demo

- **Service accounts hold application scope.** `scott.mcp` and `NoahMCPServiceAccount` are members of `SD Administrators`, and so of `SD Users`. `CLAUDE.md` §6 says a service account gets no membership in the application. This may be intentional for the existing intake MCP process models (`SD Start Intake (MCP)` and the others).
  - *Owner:* Scott.
  - *Decision needed:* remove them, or record the exception in `CLAUDE.md`.
  - *Trigger:* before the first draw approval security design.
- **Dev MCP bundle out of sync with the plugin.** The plugin is 26.6.95 and the local bundle is the 26.6.90 build (20260903).
  - *Owner:* Scott.
  - *Steps:* download the bundle from `https://ny.appiancloud.com/suite/plugins/servlet/stateless/lcp-mcp-bundle`, then say "run the update procedure" (`maintenance/dev-mcp-update.md`).
  - *Trigger:* the next session start.
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

- **Which application should draw approval live in?** It is assumed to go into `Starwood Demo` (prefix `SD`), next to subscription intake. The instance also holds a separate `Capital Calls & Distributions` app (CCD).
  - *Owner:* Scott.
  - *Trigger:* Phase 0.

## Deferred

- **Inventory the remaining object types** of `Starwood Demo` (rules, constants, integrations, documents, agents and so on), names only.
  - *Owner:* the build session.
  - *Trigger:* the first session that designs draw approval objects which reuse intake objects.
- **Confirm the designer identity by probe.** Run a throwaway rule returning `loggedInUser()`, then delete it.
  - *Owner:* the build session.
  - *Trigger:* the first session in which the plan gate passes.

*(Each item names its trigger.)*

## Done

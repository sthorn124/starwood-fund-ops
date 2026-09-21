# Closeout — 2026-09-21 — Instantiation: build repo for the existing intake app, draw approval flow to follow

## Scope and identity

- **Design reads:** Dev MCP `appian` (157 tools) as `scott.thorn@appian.com`, taken from the session file and not probed. The account is a member of `SD Administrators` and `SD Users`.
- **Instance and application:** `ny.appiancloud.com`, application `Starwood Demo` (`dd3bb740-b105-421b-a866-29d542a144da`, prefix `SD`).
- **Not used:** the runtime connector `appian-runtime` was present but not called. No sail persona sessions exist.
- **Plan gate:** STOP. `BUILD_PLAN.md` is still the stub, so this session made reads only.

## What changed

**On the instance:** nothing.

**In the repo:**
- `CLAUDE.md`: a project section with the filled Build parameters block and an MCP-servers note. The note says the runtime connector is inherited from the desktop app, runs as the `scott.mcp` service account per the operator, and is banned for build work.
- `BASELINE_INVENTORY.md`: new. Lists the record types (16), process models (15), interfaces (14), sites (0) and groups (7) by name.
- `PROJECT_INSTRUCTIONS.md`: new, stage one.
- `BUILD_LOG.md`: the first entry and one staged promotion candidate.
- `TODO.md`: new items.
- `BUILD_PLAN.md`: untouched, because Phase 0 happens in the claude.ai Project.

## Preflight results

| Step | Result |
|---|---|
| 1. Plan gate | **STOP.** The plan is the stub, so no build work was done. |
| 2. Design surface | Present, with 157 tools. `listRecordTypes` returned 16 types. |
| 3. Degraded? | No. |
| 4. Versions | **Drift.** The plugin is 26.6.95. The local bundle is the 26.6.90 build (20260903-195919), and the server says the bundle is out of sync with the plugin. sail reports 26.6.90. Bundle downloads: `https://ny.appiancloud.com/suite/plugins/servlet/stateless/downloads` and `…/lcp-mcp-bundle`. To update, say "run the update procedure". |
| 5. Servers | `appian` is the user-config Dev MCP, with camelCase tools. `appian-runtime` is inherited from the desktop app (10 `appian_*` tools plus `ping`, via `mcp-remote` to `/mcp`). The names are separate, so there is no shadow or merge. |
| 6. Skill sync | The repo copy and the installed copy are identical. |
| 7. Ritual | None. |
| 8. Identity and groups | The designer is `scott.thorn@appian.com`, matching the Design account parameter. The groups exist and their nesting was read back. Only `SD Administrators`, `SD Users` and `SD Compliance Reviewers` have members. **Service accounts `scott.mcp` and `NoahMCPServiceAccount` are in `SD Administrators`**, which contradicts §6. |
| 9. sail personas | `~/.sail` and `~/.sail-designer` hold no sessions. There are no live personas, and the persona site stub is unset because the application has no site. |

## Spec artifacts

All three are present and readable:
- `current approval email sample blacklined.pdf` (1 page).
- `New approval email sample blacklined.pdf` (1 page).
- `Draw workflow enhancements simple overview 9-12-26.xlsx`: one sheet with seven workflow steps. The Sep/Oct enhancements cover:
  - ingesting the budget excel into data tables, with plain-language failure alerts and an AI comparison against a prior good upload;
  - showing the budget on the UI and in the approval email;
  - letting the asset manager edit the budget;
  - the new approval email format.

**They are gitignored (`*.pdf`, `*.xlsx`) and not on GitHub.**

## Not verified

- The designer identity by a `loggedInUser()` probe, which would require creating an object.
- The runtime connector's executing identity.
- The fine print of the new email's tables, because the render was low resolution.
- Object types other than the five inventoried.

## Rulings needed

1. **Service-account membership in `SD Administrators`:** remove it, or record it as an exception.
2. **Spec artifacts:** upload them to the Project, or force-add them to git.
3. **Which application draw approval lives in:** `Starwood Demo` is assumed; there is also a separate `Capital Calls & Distributions` app.

## Promotion candidates

1 found: `listGroupMembers` works over the Dev MCP on this instance, which contradicts supplemental §3. It is listed as STAGED; none were promoted. The checkpoint is current through this entry.

## TODO changes

Added:
- **Blocking:** the Phase 0 plan.
- **Before demo:** service-account scope, the Dev MCP bundle update, the spec artifacts not being on GitHub, and persona accounts with sail logins.
- **Client validation:** which application hosts draw approval.
- **Deferred:** the remaining-object inventory and the identity probe.

## BUILD_PLAN.md changes

None. It stays a stub pending Phase 0.

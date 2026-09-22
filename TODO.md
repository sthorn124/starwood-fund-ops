# TODO — Starwood draw approval

Open items by class. Sessions add discovered items unprompted as they surface, and any response that touched this file ends with a `TODO changes:` line stating what was added, moved, or closed. Every item carries an owner and a firing condition ("trigger: …"); nothing is parked on "later". Superseded items are struck through with a pointer to the standing decision, not deleted; completed items move to Done with the date. The contract is `CLAUDE.md` §8.

## Blocking

## Before demo

- **Spec artifacts are not on GitHub.** `.gitignore` excludes `*.pdf` and `*.xlsx`, so the three spec files exist only on this machine.
  - *Owner:* Scott.
  - *Steps:* upload them to the claude.ai Project, or rule that they are force-added to the repo.
  - *Trigger:* before Phase 0 starts in the Project.
- **Persona accounts and sail logins.** Local-password accounts are needed for the Fund Accountant and the Asset Manager (`BUILD_PLAN.md` § Personas), because SSO-only identities cannot log in through sail.
  - *Owner:* Scott.
  - *Steps:*
    1. Create both accounts.
    2. Add them to the draw approval groups in Designer, once Phase 1 creates the groups.
    3. Log each one into its own sail data directory (`~/.sail-<persona>`, per `GETTING_STARTED.md` §1).
    4. Set the Persona site stub build parameter once the site exists.
  - *Trigger:* before Phase 1's persona verification steps.

## Browser checks owed

*(Owner: a named human. Each item lists the steps, the persona to log in as, and the expected strings — a checklist the human can run, not an open question. Content, state, and behaviour that a session can check through sail as the persona are not browser checks: geometry, document access, and what sail cannot reach are (`CLAUDE.md` §4).)*

## Client validation questions

- **Phase 0 discrepancies found while transcribing.** These are to be ruled before the Phase 1 prompt is written. The transcription in `PROJECT_INSTRUCTIONS.md` is verbatim and was not altered.
  - *Owner:* Scott, in the claude.ai Project.
  - *Trigger:* before the Phase 1 build prompt.
  1. **"Accounting manager" is not a canon role.** Narrative beat 4 says the accounting manager approval is shown pre-completed, but the role canon has no Accounting Manager. The workflow xlsx step 3 also says "accounting manager". Which canon role is it: Accounting Controller?
  2. **"Executive" is two things.**
     - The Personas section heads the live email approver "Executive (CEO)".
     - The canon lists Executive and CEO as separate roles.
     - "Remaining chain roles" includes Executive.

     Confirm that the live email approver is the CEO role, order 9, and that the Executive role, order 5, is data only.
  3. **Is the Fund Accountant the chain's "Accountant"?** The Fund Accountant persona is live (ingestion and reconciliation), while "Accountant" (order 1) is listed as a data-only chain role. Confirm that they are the same person but that the approval step is data only.
  4. **Number of QIU metrics.** The data model says "the nine metrics from the email sample". The current email sample's QIU table shows ten rows by my read: IRR, Profit, Multiple, Peak Equity, Current Equity Contributions, Current Quarter Equity Contribution, Future Equity Contributions, Distributions To-Date, Current Quarter Distribution, Future Distributions. Re-count on a high-resolution render and rule nine or ten.
  5. **Number of approval steps.** The narrative says "the 9-role approval chain", and the canon lists nine roles. The new email sample's approval status table appears to run to order 10 in the low-resolution render. Re-count at high resolution.
  6. **The investment and property side has no entity.**
     - The new email shows Investment Name, Investment Description ("from DealCloud") and Fund.
     - The data model says SD Draw is "related to the existing investment/fund structure", but `Starwood Demo` has no investment or property record type, only `SA Fund` (id 4 is "Harborline Real Assets Fund II, L.P.").
     - Rule one of two options: header fields on SD Draw, or a new SD Investment entity.
  7. **Narrative continuity on Blue Granite.** Its subscriptions to fund 4 are all "Under Review" or earlier; none is Accepted. This was read as the designer, a member of `SD Administrators`. The narrative says its capital "entered" Harborline Fund II. Either accept this as narration, or have the intake demo end with an Accepted subscription.
## Deferred

- **Correct appian-supplemental §3 on group membership.** It still states that `getGroup` and `listGroupMembers` return 403. That is the pre-26.6.90 behaviour. Reads work on 26.6.90 and on 26.6.95 (measured live 2026-09-21), and the repo's `reference/mcp-capability-boundaries.md` already records it.
  - *Owner:* Scott (the skill's owner).
  - *Change:* edit the skill in the template repo, then re-sync the user-level copy and this repo's `skills/appian-supplemental/SKILL.md`, keeping the two identical (`CLAUDE.md` §2 step 6).
  - *Trigger:* the next template sync, or earlier if a session is misled by the stale text.
- **Measure whether `createProcessModel(errorAlertGroupUuid)` persists** on 26.6.95. Read the model back after creating it.
  - *Owner:* the build session.
  - *Trigger:* the first draw approval process model created.
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
- ✅ 2026-09-21 — **Dev MCP updated from 26.6.90 to 26.6.95 and re-verified.** Both halves report build `20260911-210447`, and sail reports 26.6.95. The pins in `reference/toolchain.md` §1 and §12 are refreshed.
- ✅ 2026-09-21 — **Phase 0 plan written.** `PROJECT_INSTRUCTIONS.md` is complete, and `BUILD_PLAN.md` is authored and passes the plan gate.

# TODO — Starwood draw approval

Open items by class. Sessions add discovered items unprompted as they surface, and any response that touched this file ends with a `TODO changes:` line stating what was added, moved, or closed. Every item carries an owner and a firing condition ("trigger: …"); nothing is parked on "later". Superseded items are struck through with a pointer to the standing decision, not deleted; completed items move to Done with the date. The contract is `CLAUDE.md` §8.

## Blocking

## Before demo

- **Accelerator timing (demo-script fact, measured 2026-09-21).** From the presenter clicking the accelerator to the CEO task being live: **87 s** in the exact demo sequence (accelerator fired 7 s after the Asset Manager's approval; 24 s settle, then ≈12 s per step for steps 4–8, then the CEO task). 81 s when the previous task is idle. Narrate it ("the chain approves over the following days") or start it before the beat.
  - *Owner:* the presenter.
  - *Trigger:* the first rehearsal.
- **Demo reset.** Before every run: apply `scripts/seed_draw66.py --reset-csv` through `updateRecordData` (draw, then approvals) and confirm no "Approve or reject draw" task is open. Never edit rows by hand.
  - *Owner:* the presenter or the session.
  - *Trigger:* before every rehearsal and the demo.

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

## Deferred

- **QIU `notes` width is 1,000 characters** (measured; the readback says 255). The spec says notes carry paragraphs; 1,000 may be short for a long one. Widening is a drop-and-recreate (supplemental §7).
  - *Owner:* Scott.
  - *Trigger:* the first QIU note that needs more than 1,000 characters, or Phase 3 when ingestion defines what a note holds.
- **Record-level security on the draw types**, defined once on `SD Draw` and inherited through RELATED_RECORDS.
  - *Owner:* the build session.
  - *Trigger:* the persona accounts exist.

- **Correct appian-supplemental §3 on group membership.** It still states that `addGroupMembers`, `getGroup` and `listGroupMembers` return 403. That is the pre-26.6.90 behaviour. Reads work on 26.6.90 and 26.6.95, and **membership writes work on 26.6.95** (three adds measured 2026-09-21); `reference/mcp-capability-boundaries.md` records both.
  - *Owner:* Scott (the skill's owner).
  - *Change:* edit the skill in the template repo, then re-sync the user-level copy and this repo's `skills/appian-supplemental/SKILL.md`, keeping the two identical (`CLAUDE.md` §2 step 6).
  - *Trigger:* the next template sync, or earlier if a session is misled by the stale text.
- ~~**Measure whether `createProcessModel(errorAlertGroupUuid)` persists** on 26.6.95.~~ Measured 2026-09-21: `getProcessModel` returns no alert-group field, so it is unmeasurable over MCP. Moved to Browser checks owed (Designer).
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
- ✅ 2026-09-21 — **Phase 0 discrepancies: all seven ruled** and applied to `PROJECT_INSTRUCTIONS.md` and `BUILD_PLAN.md`.
  1. "Accounting manager" means the Accounting Controller, order 2. Orders 1–2 are pre-completed, and the chain sits at the Asset Manager, order 3.
  2. The CEO (order 9) is the live email approver. The Executive (order 5) is data only.
  3. The Fund Accountant is the chain's Accountant (order 1); that step is data only.
  4. There are ten QIU metrics, listed in canon order.
  5. The chain has nine contiguous orders, 1–9. The sample's gap at order 4 is a source artifact and is not reproduced.
  6. `SD Investment` is a record type (name and description, related to `SA Fund`). DealCloud is narrated, not integrated.
  7. Blue Granite continuity is narration only. The flow never reads or writes subscription records.
- ✅ 2026-09-21 — **Phase 1 core built and verified:** six record types, seed, groups, constants, rules, task form, four process models (transition, step, launcher, accelerator), happy path and reject break-test as the designer.
- ✅ 2026-09-21 — **Browser checks (Scott):** treasury and step emails received (outbound email confirmed); alert group persists on all four models; task form renders in Tempo and blocks a blank-comment reject.
- ✅ 2026-09-21 — **Rulings recorded:** Budget Summary as roll-up; accelerator dates 1 day per step; mockups from the Project; demo runs from Phase 3 ingestion.
- ✅ 2026-09-21 — **Column widths proven through the production path:** 4,000 and 1,000 as requested; readback of 255 is wrong; no truncation.
- ✅ 2026-09-21 — **Race test passed after the settle fix;** timing recorded (87 s).

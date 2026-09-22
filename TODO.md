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

- **Demo start (2026-09-22).** After the reset, start `SD Draw Approval Process` on draw 66 and wait ~10 s: the Draws page shows "Awaiting My Action 1" and YOUR ACTION on #66 for `sd.assetmanager` only while that task is live. The task currently live is 536874206 (step process 536909940).
  - *Owner:* the presenter or the session.
  - *Trigger:* before every rehearsal and the demo.
- **`sd.accountant`'s display name is "Priya Ramen"; the mockups and the spec say "Priya Raman".** The seed now uses the account's spelling (ruled by the Phase 2b brief: persona rows carry the accounts' display names), so the UI reads "Ramen".
  - *Owner:* Scott.
  - *Steps:* either correct the account's last name in Admin Console (then rerun the seed's approval rows) or accept "Ramen".
  - *Trigger:* before the first rehearsal.

## Browser checks owed

*(Owner: a named human. Each item lists the steps, the persona to log in as, and the expected strings — a checklist the human can run, not an open question. Content, state, and behaviour that a session can check through sail as the persona are not browser checks: geometry, document access, and what sail cannot reach are (`CLAUDE.md` §4).)*

- **Task opens from the Summary action strip and the restyled form submits (sail cannot follow a task link).** Owner: Scott.
  1. Log in as `sd.assetmanager`; open `/suite/sites/subscription-agreement-analyst/draws`. Expect the "AWAITING MY ACTION" card to read `1` with `Draw #66 · Asset Manager step`, and #66 highlighted with **YOUR ACTION**, sorted first.
  2. Click `#66`. On Summary expect the blue strip "Your approval is pending — Asset Manager, step 3 of 9" and the **Review & Approve** button.
  3. Click it. Expect the task form header "Step 3 of 9 — Asset Manager" / "Assigned to Elena Marchetti · with you since Oct 7 · funds scheduled Oct 15", the context card with "Draw #66 — Tamarack Hotel & Spa Vail" as a link, and the two decision cards: **Approve** "Advance to AM SVP (step 4 of 9)" and **Reject** "Terminate this draw request".
  4. Select Reject and click Submit Decision with no comment: expect the field error "A comment is required when rejecting a draw." **Do not submit.** Select Approve; the Comments label reads "Comments (optional)". Leave the task open.
  - *Trigger:* before the first rehearsal.
- **Geometry of the three built pages against the mockups** (card widths, the four KPI cards in one row on desktop, grid column widths, the navy band, the strip's button alignment). Owner: Scott. Log in as `sd.assetmanager`, compare the Draws page, #66 Summary and the task form with `mockups/draw-list.html`, `draw-summary.html`, `task-approval.html`. Note deltas in `TODO.md`; the mockups are not changed by build sessions.
  - *Trigger:* before the first rehearsal.
- **Document download links** appear only once real files are attached (Phase 3); the three seeded rows render names as text. Owner: the Phase 3 session. *Trigger:* Phase 3 ingestion.

## Client validation questions

## Deferred

- **Draw personas can see the intake pages.** `SD Draw Approvers` is a viewer of the whole `SASite`, so `sd.accountant` / `sd.assetmanager` also see Dashboard, New Subscription and Subscription Records. A visibility expression on those pages (member of `Subscription Agreement Analysts`) would hide them; not done this session because the brief limited security changes to reaching the Draws page.
  - *Owner:* Scott (ruling), then the build session.
  - *Trigger:* the first rehearsal as a persona, or a ruling.
- **Page group "Draws" in the site navigation** — not exposed over the Dev MCP; a Designer step.
  - *Owner:* Scott.
  - *Trigger:* before the demo, if the flat page bar reads wrong.
- **"Save for Later" on the task form** (in `mockups/task-approval.html`) is not built: a task form has no draft save without a process change (a "save draft" path in `SD Draw Approval Step`).
  - *Owner:* the build session.
  - *Trigger:* a ruling that the demo needs it.
- **"Advance draw (demo)" related action** (BUILD_PLAN Phase 2) is still open; the accelerator is started through `testProcessModel` today.
  - *Owner:* the build session.
  - *Trigger:* the first rehearsal that needs a presenter-clickable accelerator.
- **Seed narrative dates are in October 2026; the clock is September.** Aging strings compute from `today()` and clamp at 0, so until October the seeded step reads "today" / "< 1 day" and the funding date reads "in N days" with N > 12. The Phase 3 ingestion run will replace the seed; until then, a re-dating script would be the §2 per-session ritual.
  - *Owner:* the build session.
  - *Trigger:* Phase 3, or the first rehearsal that needs the mockup's "2 days" / "in 12 days" to read true.
- **Record-title tie:** the record header shows "Draw Funding Approval | <investment>", and the four views repeat a fact strip beneath the tabs (the mockup's band). If the duplication reads heavy in the browser, hide the default record header (`updateRecordType.hideRecordHeader`) and render the title in the strip.
  - *Owner:* Scott (after the geometry check).
  - *Trigger:* the geometry browser check.
- **QIU `notes` width is 1,000 characters** (measured; the readback says 255). The spec says notes carry paragraphs; 1,000 may be short for a long one. Widening is a drop-and-recreate (supplemental §7).
  - *Owner:* Scott.
  - *Trigger:* the first QIU note that needs more than 1,000 characters, or Phase 3 when ingestion defines what a note holds.
- **Record-level security on the draw types**, defined once on `SD Draw` and inherited through RELATED_RECORDS. The persona accounts now exist and both read every draw (no row security yet; the views rendered identically for both personas and the designer on 2026-09-22).
  - *Owner:* the build session.
  - *Trigger:* a ruling that personas should see fewer draws than they do.

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
- ✅ 2026-09-22 — **Spec artifacts uploaded to the claude.ai Project** (they stay out of GitHub by `.gitignore`).
- ✅ 2026-09-22 — **Persona accounts and sail logins:** `sd.accountant` (SD Draw Demo Approvers) and `sd.assetmanager` (SD Draw Asset Managers), both in SD Users, live sail sessions in `~/.sail-sd.accountant` and `~/.sail-sd.assetmanager`; Persona site stub set. Seed rows carry the accounts' display names.
- ✅ 2026-09-22 — **Phase 2b built and persona-verified:** Draws page, four `SD Draw` views, restyled task form, seed texture, monotonic decision dates; `SD Draw Approvers` views `SASite`.

# Closeout — 2026-09-28 — Second fix session: Asset Manager at step 2, accelerator stop, manual reminder, chased-step listing, labelled rows, one-draw runbook

## Scope and identity

- **Design work and every designer readback:** the Dev MCP as `scott.thorn@appian.com`, a member of `SD Administrators`, `SD Users` and the three draw step groups (full scope).
- **Persona checks:** sail, as `sd.accountant` (Priya Raman) from `~/.sail-sd.accountant` and as `sd.assetmanager` (Elena Marchetti) from `~/.sail-sd.assetmanager`.
- **Runtime connector:** not called.
- **Preflight:**
  - Dev MCP 26.6.95 matches the pin (26.6.100 is on the App Market, already in TODO); sail 26.6.95.
  - The design read returned 27 record types; the supplemental skill copies are identical.
  - The groups read back as recorded; both personas are live.
  - Readbacks: `SD_ESCALATION_TEST_MINUTES` = 0, `SD_SMS_MODE` = STAGED.

## Decisions recorded

`PROJECT_INSTRUCTIONS.md` has one short block, "One-draw demo":
- failure opens, recovery follows, with no stage-for-approval click;
- the chain order for ingested draws, with the confirmation as the first approval;
- the accelerator's President / CEO target;
- Send Reminder Now;
- the chased-step listing;
- labelled unconfirmed rows.

## What changed

**1. The chain for an ingested draw.**
- **New constant `SD_DRAW_CHAIN_ROLES`:** 1 Accountant, 2 Asset Manager, 3 Accounting Controller, 4 AM SVP, 5 Executive, 6 Chief Accounting Officer, 7 CFO of Funds, 8 President, 9 CEO.
- **`SD_buildIngestedApprovalChain` v2:**
  - builds the rows in that order; names still come from the prior draw, matched by role;
  - **order 1 is written Approved at the confirm time**, acted by the confirming account, source RECONCILIATION;
  - order 2 is In Progress.
- **The ingestion pipeline:**
  - takes the confirm time (new PV `confirmedAt`, node 15);
  - passes it to the chain (node 23);
  - **activates the draw at step 2** (node 28).
- **Result:** the moment the accountant confirms, the Asset Manager's task is live.
- **Existing draws** keep their chains. Everything downstream (group assignment, the budget edit, the email, the status table) already keys on role, so nothing else changed.

**2. Accelerator stop point.**
- New parameter `targetRole` ("President" or "CEO"), resolved to that role's step on the draw's own chain. Blank keeps the old behaviour (the CEO).
- Constant `SD_ADVANCE_DRAW_PM`.

**3. Send Reminder Now.**
- New process `SD Send Reminder Now`. It runs the existing chase process twice, synchronously, for the draw's current step: a reminder email, then the staged text. There is no waiting threshold. Administrators only.
- The reminder's subject is now **"Re: " + the step email's subject**, so Gmail should thread it with that step email.

**4. Needs chasing** (`SD_getChaseRows` v5).
- It also lists any step with a reminder or text logged at its current step, whatever its age. The Why reads "Reminder sent today · text staged".
- Steps waiting 3+ days read exactly as before (#12 unchanged).

**5. Labelled rows** (`SD_getDrawListRows` v3, page v14).
- An unconfirmed draw's link reads "New draw · 6:44 PM" or "Not loaded · 10:21 PM", with its package beneath: the template plus the supporting files, one named or several counted.
- sail can now open each one by its label. That closes the Deferred item.

**6. The staging card** (page v14).
- **Row 2 is now "A draw in approval":** a draw picker with **Advance to President**, **Send Reminder Now** and **Advance to CEO**. It replaces Stage for Approval, whose process and rules stay on the instance, unused (a Deferred item: delete on your word).
- The feed row's text follows the new beat order.

**7. The runbook** (`TODO.md`) is rewritten to beats 0–7 in the new order, with each beat's measured timing and fallback specimen, and the one-line order note.

**Also:** the `SD Draw Asset Managers` description now says order 2 on new draws. The throwaway `zz_feedLauncher28b` was created, used and deleted (absence confirmed).

## The end-to-end test

The run went exactly in the runbook's order. The feed buttons' calls went through a throwaway launcher using the buttons' own constants. Tasks were completed by the designer, because sail cannot open them.

| Beat | What happened | Measured |
|---|---|---|
| 0 | Mismatch draw 106 (staged in the last session) waits at reconciliation | — |
| 1 | Malformed template → draw 107 **Ingestion Failed**, with the reason and the AI comparison; row "Not loaded · 10:21 PM" as `sd.accountant` via sail | 87 s |
| 2 | Corrected package → draw 108. Invoice and lien waiver classified; pay application read ($2,490,296.23). As `sd.accountant` via sail: row "New draw · 10:23 PM" + "3 supporting files", Summary's Reconcile Extraction card. Designer render: Ties ✓, pay application Ties, Draw Number #83. **Confirmed → #83 at step 2**, order 1 **Approved as Priya Raman at 02:27:55 UTC (the confirm second)**, Elena In Progress | task open ~90 s; pay application ~2 min |
| 3 | As `sd.accountant` via sail: "New draw · 6:44 PM" (the mismatch PDF named) opens draw 106's Summary with the Reconcile Extraction card | — |
| 4 | As `sd.assetmanager` via sail: **YOUR ACTION**, "Your approval is pending — Asset Manager, step 2 of 9", Review & Approve. Then the task: A&E - Architectural +$10,000 from contingency, Approve. Two line events written at step 2 | step 2's task live ~15 s after confirm |
| 5 | **Advance to President** → step 8 with a live task. **Send Reminder Now** → reminder (row 72, "Re: …Step 8 of 9 (President) [SD-DRAW-108-S8]") + staged text (row 73). As `sd.accountant` via sail: **Needs chasing (3)**: #12 "Step 6 waiting 10 days" with its staged text beneath; #83 "Reminder sent today · text staged"; #70 (its Sep 26 reminder). **Advance to CEO** → CEO task and step email (row 74) | 80 s · 13 s · 32 s |
| Regression | Accelerator with no target on #82 (old chain, step 1) → CEO, CEO task live, the Asset Manager kept order 3 | ~2 min |

**The reminder** is described from the rendered rule; this is its first eyeball:
- An amber banner reads "Reminder: this approval is still waiting and the draw is funding in 48 days. The approval request is repeated below; reply to this email with your decision."
- Below it is the full President step email:
  - "Hello James Callahan… step 8 of 9, President";
  - the budget table carrying Elena's edit (A&E - Architectural adjustment $31,000, contingency ($67,753));
  - the approval status: Priya 09/28 with "Confirmed the Doc Center extraction at reconciliation…", Elena 09/29, steps 3–7 a day apart, step 8 highlighted.
- It reads right. I could not see Gmail: the Gmail threading and look are your check (below).

## Not verified, and why

- **Browser only:**
  - the new staging row (geometry and the three clicks; the processes behind them ran directly);
  - the reminder **threading in Gmail**;
  - the malformed-template alert in Gmail;
  - the persona clicks of Confirm and of the Asset Manager's edit-and-approve.
- **Designer attribution on #83:** the designer completed both tasks, so #83 reads "reconciliation · scott.thorn@appian.com" at order 1 and "Scott Thorn" in the Line History. The named approver is still Priya Raman. On stage both carry the persona, because the forms save `loggedInUser()`.
- **Beats 6–7 were not run.** #83 waits at the CEO step with its email in your inbox, ready for a Gmail rehearsal of beat 6.

## Browser checklist (full steps in `TODO.md`)

1. **Reminder in Gmail.** "Re: Draw Funding Approval: Draw #83 · … · Step 8 of 9 (President) [SD-DRAW-108-S8]" (10:30 PM EDT) should sit in the same conversation as the President step email sent 10 s earlier, with the amber banner on top.
2. **Staging card dry run:** mismatch, malformed, corrected; then Advance to President → Send Reminder Now → Advance to CEO; layout at ~1280 px and phone.
3. **Reconciliation, as `sd.accountant`:** Confirm lands the draw at step 2 · Asset Manager, and order 1 reads "reconciliation · sd.accountant".
4. **Asset Manager edit, as `sd.assetmanager`,** on the draw just confirmed: "Edited by Elena Marchetti".
5. **Needs chasing (3)** layout.

## Rulings needed

- **A live Asset Manager approval is dated the next day.** The transition dates every decision at least a day after the previous one. Now that order 1 is approved at the confirm time, Elena's approval minutes later reads tomorrow (on #83: confirmation 09/28, her approval 09/29). Accept it and narrate "the following days", or exempt live TASK / EMAIL decisions from the +1 day?
- **Still open from earlier today:**
  - numbering for an unmatched investment (#1);
  - #12's pending question (leave it, or answer it).

## Known artifacts recorded (`CLAUDE.md`)

- A live Asset Manager approval is dated the day after the confirmation (the ruling above).
- Chase rows sent by hand carry the chase process's escalation notes ("Escalation level 1 on the step task … 0 days waiting"). They are fixed with that process's next edit, after its Designer setup.

## Promotion candidates

- **1 newly staged at gate 1:** `updateProcessModel` with only the PV list keeps every node.
- **1 trigger fired, held at gate 2:** a subprocess can't map a child's non-parameter PV. It reproduced on `SD Send Reminder Now`, and the same working form held (read what the child wrote). Not promoted: the error names the fix, so it fails gate 3.
- **None promoted.** The supplemental skill copies are unchanged.
- **Checkpoint:** current through this session's entry.

## TODO changes

- **Rewritten:**
  - the demo runbook (beats 0–7, failure first, measured timings);
  - the accelerator timing item;
  - the browser checks for the reconcile confirm (now step 2), Needs chasing (3), the Asset Manager edit (on the confirmed draw), and the staging-card dry run (new row).
- **Added, Before demo:** the ruling on a live Asset Manager approval dated the next day.
- **Added, Browser checks:** the reminder threads with its step email in Gmail.
- **Added, Deferred:**
  - Stage for Approval retired but still on the instance;
  - chase rows sent by hand read as escalations.
- **Closed:**
  - two "New draw" rows sail could not tell apart;
  - the "Advance draw (demo)" related action (built as the staging card's buttons).
- **Done:** this session.

## BUILD_PLAN.md changes

- Five items ✅ 2026-09-28 (second fix session).
- The Phase 2 "Advance draw (demo)" item closed.
- The narrative rewritten to the failure-first order; the 2026-09-27 order struck.

## Commit

"fix: asset manager at step 2, accelerator stop, manual reminder, chased-step listing, labeled rows, one-draw runbook". Pushed to `origin/main`; HEAD verified equal to `origin/main` with a clean tree.

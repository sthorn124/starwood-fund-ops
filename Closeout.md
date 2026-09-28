# Closeout — 2026-09-28 — Fix session: system-assigned draw numbers, docs tie rendering, mismatch staging button, review banner, #12 specimen

## Scope and identity

- **Design work and every designer readback:** the Dev MCP as `scott.thorn@appian.com`, a member of `SD Administrators`, `SD Users` and the three draw step groups (full scope).
- **Persona checks:** sail, as `sd.accountant` (Priya Raman, `SD Draw Demo Approvers`) from `~/.sail-sd.accountant`.
- **Runtime connector:** not called.
- **Your own activity today, found and left alone:**
  - draw 103 (Ingestion Failed) and draw 104 (Ingesting, reconciliation task open), from the staging card;
  - #81 advanced to step 4;
  - #70's review ("talked ti him", row 61);
  - the test answer on #12 (row 62), deleted by item 5.

## What changed

**0. Ruling** (`PROJECT_INSTRUCTIONS.md`).
- The draw number is system-assigned: the next number in the investment's sequence, like a case number.
- The template's number is document content only.
- The 2026-09-22 collision ruling and the 2026-09-27 "type the next number" line are struck, with pointers to the new ruling.
- Also recorded: the mismatch package on the staging card, and the review-banner refinement under "nothing requires Tempo".

**1. System-assigned numbers.**
- **New rule `SD_getNextDrawNumber(investmentId, excludeDrawId)`:** the investment's highest draw number plus 1, computed as a MAX aggregate.
- **Reconciliation form v9:**
  - Draw Number is read-only: "#n", with "Assigned by the system: the next draw number for this investment."
  - The title is "Reconcile extracted draw #n".
  - Every sequence and collision chip, local and refresh variable is gone.
  - `drawNumber` is no longer in the confirmed header.
- **Pipeline:** node 16 assigns the same number at commit.
- **The template's number is no longer read anywhere:**
  - Doc Center model 85 no longer extracts it (field 3613 deleted; absence read back);
  - the reconcile payload, the template validation and the failure email no longer use it (pipeline node 39 updated; payload regenerated).

**2. Tie-out rendering.**
- The Documents tab was not the source: it has no tie-out, and it reads clean via sail.
- The source was the reconciliation form's corroboration grid. Its Tie-out cell held a side-by-side (tag plus text).
- On this 26.6 site a read-only grid cell takes a single component; side-by-side in a cell arrives in 26.9. The designer render accepted it, but the browser printed its internals.
- The cell is now two columns: **Tie-out** (the tag) and **Difference** ("off by $X").

**3. Stage Mismatch Package.**
- New constant `SD_FEED_PACKAGE_MISMATCH_SUPPORTING` (the mismatch pay application, document 55877).
- The Draws page is v13: a third button with the same intake call as Stage Corrected Package, card text covering all three packages, and a MISMATCH status line.
- Runbook beat 3 now offers: live via the button, or the saved #78.

**4. Review clears the banner.**
- The Summary's email-reply review card shows only while a review task is open (Summary v12). The "Review task not found — see the Emails tab" state is deleted.
- The Needs chasing list follows the same rule (`SD_getChaseRows` v4).

**5. Gateway #12.**
- Row 62 ("23423") is deleted, and absence was read back. The Sep 26 rows are untouched.
- The chase ladder fired once: a reminder (row 67, a real email to `SD Draw Demo Approvers`) and a staged text (row 68, "+1 ••• ••• 6630").
- The chain and dates are unchanged.

**Throwaways.** `zz_cancelProcess28` and `zz_stageMismatch28` were created, run and deleted, with absence confirmed.

## Verified

1. **Regression.** Ran as `sd.accountant` via sail; the reconciliation task was completed as the designer.
   - The corrected package was received through the Receive Capital Call page as `sd.accountant` via sail.
   - Doc Center extracted the fresh document without the field (instance 889).
   - The designer render of the form showed "#82", read-only, with no chips. The task was completed as the designer, because sail cannot open tasks.
   - Draw **105 = #82**, In Progress at step 1, TIES.
   - As `sd.accountant` via sail: #82 shows YOUR ACTION on the Draws page, and its **Funding History lists #82, #80, #79, #77**.
2. **Tie-out columns.** The designer render shows the Tie-out and Difference columns. The Documents tabs of #77 and #82 read clean as `sd.accountant` via sail.
3. **Mismatch package** (checked by designer render and as `sd.accountant` via sail).
   - Started with the button's exact call through a throwaway launcher, which created **draw 106**. Its pay application was classified and read: $2,527,796.23.
   - The designer render of its reconciliation form shows:
     - Draw Number **#83**;
     - amber **Does not tie** in Tie-out, with amber **off by $37,500.00** in Difference;
     - amber **No lien waiver received**;
     - no draw-number tag.
   - The page render shows the three staging buttons.
   - As `sd.accountant` via sail: two "New draw · YOUR ACTION" rows (104 and 106), and no staging card.
4. **Banner** (as `sd.accountant` via sail on #70).
   - With an open review task: the amber card and the Review Reply link show.
   - After Mark Reviewed: the card is gone, and the Emails tab shows the review.
   - For a reply whose review task was cancelled: no card and no link on Summary; the Emails tab keeps the reply, and the KPI does not count #70.
5. **#12** (as `sd.accountant` via sail).
   - The Emails tab reads the Sep 26 guardrail rows, then the question, the approval attempt, the refusal, the reminder and the staged text.
   - **Needs chasing (1)** shows #12 with "Step 6 waiting 9 days · Text staged, not sent Sep 28, 6:46 PM".

## Not verified, and why

- **Browser only:**
  - the Stage Mismatch Package **click** itself (the session ran the same call through a throwaway launcher);
  - the **geometry** of the new columns (tag whole, "off by" wrapping, nothing clipped);
  - the persona **submit** of the reconciliation form;
  - the review card's geometry the next time one is open.
- **Draw 106's Summary as the persona.** sail refuses two identical "New draw" links while your draw 104 is also Ingesting. This is logged as a Deferred item: give new draws a distinguishing label.
- **An unmatched investment's number** (it should read #1): rule-tested only.
- **The reminder email in Gmail:** not checked.

## Browser checklist (full steps in `TODO.md`)

1. **Tie-out columns and chips on the mismatch package.** Draw 106's reconciliation task (536883728) is open for `sd.accountant`. Or click **Stage Mismatch Package** yourself; that is also the click check. Expect:
   - Does not tie / off by $37,500.00 side by side in two columns;
   - No lien waiver received;
   - Draw Number #83, read-only, with no chip;
   - no internals, no clipping, no ellipsis at ~1280 px.
2. **Reconciliation form, as the persona:** the read-only number, the 12-field verdict strip, and Confirm lands the draw under its assigned number.
3. **Staging card dry run with three buttons.** On 2026-09-28 the Clean Up candidates include #82 (beat 0's draw) and your 103 and 104, so cancel at its confirm step.
4. **Asset Manager edit:** stage **#82** (draw 105, the only eligible draw today).

## Rulings needed

- **Unmatched investment numbering.** The sequence is per investment, which matches the existing data (THSV #63–#83, Gateway #11–#12). A draw whose investment name matches nothing is numbered in the sequence of draws with no investment, so it becomes #1. Is that acceptable, or should an unmatched draw stay unnumbered until the accountant fixes the name?
- **#12's question is pending again.** Deleting row 62 restored the unanswered state from before your test answer. The Summary shows the amber question card to the draw approval team, and the Emails tab shows the reply box. Leave it (the "a question flows" aside), or answer it from the Emails tab? Answering sends a real email on the thread.

## Known artifacts recorded (`CLAUDE.md`)

- An ingested draw's Purpose line still reads "Draw #67 for THSV…". It is the document's own text.
- Draw 96's failure reason, written before the ruling, says "(Draw #67)".
- #12's directly fired chase rows are labelled as escalations.

## Promotion candidates

- **3 newly staged at gate 1:**
  - the validator and render accept a grid-cell layout the running version does not support, and the browser prints its internals;
  - deleting a Doc Center model field is safe on the cached path;
  - an email-triggered receiver can be started directly with its trigger's parameters (administrators only).
- **1 reversal ruled:** the 2026-09-25 "side-by-side in a grid cell renders here" candidate.
- **2 triggers fired and held at gate 1:** sail repeated link labels; script-task outputs.
- **None promoted.** The repo and user-level `appian-supplemental` copies are identical and unchanged.
- **Checkpoint:** current through this session's entry.

## TODO changes

- **Struck:**
  - the two "Ruling owed" items and the two Deferred items the 2026-09-27 skill closeout added (the skill was removed on 2026-09-27, `2382c33`);
  - the #70 exception click (done by you on 2026-09-28).
- **Rewritten:**
  - runbook beat 2 (system-assigned number, no chips);
  - beat 3 (Stage Mismatch Package, or #78);
  - the beat 6 specimens (#70 has no open review; #12 carries the ladder);
  - the reconciliation-form check;
  - the chip-layout check, now "Tie-out columns and chips on the mismatch package", on draw 106;
  - the Phase 6c checks: Needs chasing (1) with #12, not #72; stage #82; three staging buttons with the current Clean Up candidates.
- **Updated:** the #72 reference in the Twilio item notes that draw 80 was removed.
- **Added, Before demo:** the ruling on unmatched-investment numbering; #12's pending question (leave it or answer it).
- **Added, Deferred:** two "New draw" rows cannot be told apart by sail.
- **Done:** this session.

## BUILD_PLAN.md changes

- Five items ✅ 2026-09-28: system-assigned draw numbers, tie-out rendering, Stage Mismatch Package, review clears the banner, Gateway #12 specimen.
- Narrative beat 3 notes the optional live mismatch package.

## Commit

"fix: system-assigned draw numbers, docs tie rendering, mismatch staging button, review banner, #12 specimen". Pushed to `origin/main`; HEAD verified equal to `origin/main` with a clean tree.

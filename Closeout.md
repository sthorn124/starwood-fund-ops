# Closeout — 2026-09-29 — Fix session: local-time dates, the Draws list's question indicator, #70's reminder text

## Scope and identity

- **Design work and every designer readback:** the Dev MCP as `scott.thorn@appian.com`, a member of `SD Administrators`, `SD Users` and the three draw step groups (full scope).
- **Persona checks:** sail as `sd.accountant` (Priya Raman), from `~/.sail-sd.accountant`. That includes the one persona write, the test answer.
- **Runtime connector:** not called.
- **Preflight:**
  - Dev MCP 26.6.95 matches the pin (26.6.100 is on the App Market, already in TODO); sail 26.6.95.
  - The design read returned 27 record types.
  - Both draw personas are live, and the default `~/.sail` is empty.
  - The groups read back as recorded; the supplemental skill copies are identical.

## Decisions recorded (`PROJECT_INSTRUCTIONS.md`, One-draw demo block)

- **Dates are local.** Applied now because rehearsals run at night. This closes the Deferred evening-date trigger. Stored dates stay as written.
- **The Draws list flags what the draw approval team owes an answer to:** an amber **Question waiting** or **Reply needs review** beside the status. It uses the Summary's own derivations and clears when answered or reviewed.
- **The same-template collision stays Deferred,** with the beat-0 caution.

## What I measured before changing anything

A throwaway process formatted #84's decision time, 02:56 UTC on 09-29 (10:56 PM Eastern on the 28th), several ways:

| How the date is made | Result |
|---|---|
| `text(x)`, which is how the step email does it | 09/28 (the process ran in New York time) |
| `todate(x)`, which is how the screens did it | **09/29**: `todate()` takes the GMT date, as the docs say |
| `todate(local(x))` | 09/28 |

There was a second problem. The ingestion pipeline stores `today()` as the received date, and it stored **09-29** for your draw 111 and my draw 112, both started around 10:50 PM Eastern. A process started from a page or as a background subprocess runs in its model's configured zone, not yours; the docs say the same ("Programmatically launched processes always use the configured time zone").

## What changed

**1. Local-time dates.**
- **Screens** now turn a date-and-time into a date in the **viewer's** zone:
  - the Approvals tab (started, Decision On, Time at Step);
  - the Summary ("✓ MM/DD", started, the decided-on date, "With you since");
  - the Approve/Reject task form;
  - the detail rule's day counts.
- **Anything a process builds or stores** uses the new constant **`SD_BUSINESS_TIMEZONE`** (America/New_York):
  - the step email's Approval Status dates;
  - the treasury email;
  - the failure-comparison fallback date;
  - the Asset Manager's edit note;
  - the pipeline's `receivedDate` (node 4) and QIU as-of date (node 23).
- The ~20 other `todate()` calls take true Date fields (funding date, received date, the QIU as-of date). They were left alone, because `local()` would move a Date back a day.
- The pipeline's generator also gained node 4's `ingestionProcessId`, which was on the instance but in no generator.

**2. The question indicator on the Draws list.**
- The list rule marks each row `questionWaiting` (a pending question, derived exactly as the Summary's amber card) or `reviewWaiting` (an email reply whose review task is open, as the review card).
- It does this for the draw approval team only; that's who answers.
- The shared status-tag component gained an optional `notes` input: each note becomes an amber tag after the status. Every other caller passes nothing and is unchanged.
- The page's Status column passes "Question waiting" / "Reply needs review".

**3. #70's old reminder (message row 54), text only.**
- **Body:** "…has waited 0 days…" became "Reminder: this approval is still waiting and the draw is funding in 50 days. The approval request is repeated below; reply to this email with your decision."
- **Note:** "…after 0 days waiting (SD_CHASE_AGE_DAYS 3)…" became "…the step email re-sent as a reminder; …".
- The subject, time and figures are unchanged.

**4. Runbook beat 6.**
- After the question goes out from Gmail, switch to `sd.accountant`. The main draw's row shows **Question waiting** once the reply has been read (40 s to 2.5 min; refresh).
- Open the draw: the amber card → **Answer Question** → **Send Answer**. The tag clears.
- The beat now says the Emails tab already holds the climb (the step emails of the tasks that were issued, the reminder, the staged text), and the Q&A appends to it live.

**Housekeeping.** Every changed object was compared with its committed source before sending (all matched). The throwaway `zz_tzProbe29` was deleted; its read returns "Does not exist".

## Verified

| Check | Account | Result |
|---|---|---|
| #84 Approvals | `sd.accountant` via sail | started 09/28/2026; Decision On **09/28/2026** for orders 1–8; Time at Step "< 1 day" |
| #84 Summary | `sd.accountant` via sail | "8 of 9 approved · started 09/28"; every step "✓ 09/28"; the CEO "at this step 1 day" (activated 10:59 PM on the 28th; now the 29th) |
| #84 CEO step email | designer, rendered inside a process | Approval Status orders 1–8: **09/28/2026** |
| Seeded #66 and #12 | `sd.accountant` via sail | unchanged: #66 10/06 and 10/07; #12 09/14–09/19, step 6 at 10 days |
| Draws list tags | `sd.accountant` via sail | #12 and #85 "In Progress, Question waiting"; #84 and #70 (reviewed) no tag |
| Tag clears | `sd.accountant` via sail | see the note below the table |
| #70 reminder text | `sd.accountant` via sail | the Emails tab shows the new body and note |
| Pipeline after the node 4 change | designer | a malformed-template feed made draw 114: Ingestion Failed in 90 s with the usual reason and AI comparison; the alert went to the team |

**How the clearing test ran, on #82 (draw 105, at the CEO step):**
1. The designer fed the reply handler, from your authorized address: "Session test, 2026-09-29: before I sign, what is the retainage balance on this draw?". It was read as QUESTION.
2. The list tagged #82.
3. I answered from #82's Emails tab with the real control. The answer shows "from the draw record by Priya Raman (sd.accountant)".
4. The pending state read false and the tag was gone.

**#85 is your draw 113.** The CEO asked "what's driving the contingency draw?" at 11:18 PM last night and nobody has answered, so the tag is right.

## Not verified, and why

- **A process running in GMT.** I couldn't make a process run in GMT here, so the business-zone form isn't measured in that context. It rests on `todate()` acting on GMT, which I measured, and on the docs.
- **"Reply needs review" on a live row.** No draw has an open review task, so only the component render covers it.
- **Browser only:**
  - how two tags sit in the narrow Status column;
  - tonight's rehearsal dates in Gmail and on screen.
- **#84's stored received date and QIU as-of date** still read Sep 29 and 09/29/2026. The old pipeline stored them as GMT dates, and stored dates are left as written (the 2026-09-28 ruling). It's recorded as a known artifact. New draws store the Eastern date.

## Emails sent this session

- **One answer on #82's thread** to scott.thorn@appian.com, marked as a session test.
- **One ingestion-failure alert** for draw 114, sent to the team.

## Browser checklist (also in `TODO.md`)

1. **As `sd.accountant`, Draws.** #12 and #85 show **In Progress** plus an amber **Question waiting**. Check how the two tags sit in the Status column; they should wrap, never split.
2. **Tonight's rehearsal, after 8 PM Eastern.** Confirm, approve as the Asset Manager, then Advance to President. The Approvals tab, the Summary's "✓" dates and the President step email in Gmail should all show today's date.
3. **Beat 6.** Send the question from Gmail. The main draw's row gains **Question waiting** within about 2.5 minutes. Answer from the amber card, and the tag clears.

## Rulings needed

- **#84's stored Sep 29 received date.** Leave it (my default, per the ruling), or correct that one row to 09/28? #84 is last night's rehearsal draw; tonight's rehearsal makes a new one.
- **Still open:** #12's pending question (leave it, or answer it).

## Known artifacts recorded (`CLAUDE.md`)

- **Evening-ingested draws keep a GMT received date.** This applies to draws from before today's fix; #84 shows it.

## Promotion candidates

- **0 found.** The two time-zone facts are both documented, so they fail gate 3; they're recorded as the project rule "Dates are local".
- **No staged trigger fired.**
- **None promoted.** The supplemental skill copies are identical.
- **Checkpoint:** current through this session's entry.

## TODO changes

- **Rewritten:** runbook beat 6, step 1 (the Question waiting tag, answering from the amber card, the Emails tab as the running record).
- **Added, Browser checks:** the attention tags and the evening dates.
- **Added, Before demo:** the ruling on #84's stored received date.
- **Closed:** the Deferred evening-date item (fixed).
- **Done:** this session.

## BUILD_PLAN.md changes

- ✅ 2026-09-29 Local dates.
- ✅ 2026-09-29 Draws list attention tags.
- ✅ 2026-09-29 #70's reminder row and beat 6.

## Commit

"fix: local-time dates, question indicator on the draw list, #70 reminder text". Pushed to `origin/main`, then verified that HEAD equals `origin/main` and the tree is clean.

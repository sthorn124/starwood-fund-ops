# Closeout — 2026-09-25 — Phase 5: ingestion failure path with AI template comparison

## Scope and identity

- **Designer:** Dev MCP `appian` as `scott.thorn@appian.com` (`SD Administrators`, `SD Users`, the three step groups). Every design change, rule test, process test and record readback ran under it, so all of them have full scope.
- **Personas:** sail with `~/.sail-sd.accountant` for both uploads and all persona reads; `~/.sail-sd.assetmanager` for the second persona's reads. `appian-runtime` and `--from-devmcp` were not used.
- **Draw 66 untouched:** step 3, Elena's task 536876873 open, `updatedAt` still 2026-09-22.
- **Preflight:** design surface present (157 tools; `listRecordTypes` returned 20 types). Dev MCP 26.6.95 and sail 26.6.95 match their pins. The skill copies are identical. `sd.accountant` and `sd.assetmanager` are live.
  - **Flag:** the App Market has Dev MCP **26.6.100**. The site admin updates the plugin first; the bundle is at `https://ny.appiancloud.com/suite/plugins/servlet/stateless/downloads` (direct: `…/lcp-mcp-bundle`). Logged; tracked in TODO Deferred.

## 0. Bookkeeping

- The Phase 4 Gmail check is marked done (no clipping; tables render correctly).
- **Ruling recorded** (`PROJECT_INSTRUCTIONS.md`, `BUILD_PLAN.md` Phase 4, `TODO.md` Done): Gmail routing stays exactly as wired. scott.thorn@appian.com receives every step email and plays the CEO; no persona addresses, no overrides. This closes Phase 4, now marked COMPLETE.
- **`BUILD_PLAN.md`, documentation only:**
  - Phase 5.5: multi-document corroboration at intake. The template plus supporting documents such as a contractor pay application; key figures tied out at reconciliation, with a mismatch shown as an amber chip; it catches bad submissions before the chain starts.
  - Phase 6 additions:
    - email thread continuity, with the exchange mirrored onto the draw;
    - low-confidence reply interpretation goes to a super-user exception queue and never changes state;
    - a dollar-threshold guardrail: draws above it must be approved in the UI.

## 1. Failure detection

`SD Receive Capital Call` gains nodes 31–41. After extraction, node 31 runs `SD_validateIngestedTemplate`. The no-extraction branch goes there too.

A template fails when any of these hold:
- Doc Center returned no instance.
- The budget table isn't found.
- A standard column or category row is missing. This is read **from the workbook itself** with Excel Tools `readexcelsheet`, because Doc Center's model quietly mapped "Draw Funding This Period" onto Current Draw.
- Investment Name, Draw Number, Funding Date or Draw Amount came back blank.

A pass goes to the reconciliation task, unchanged. A failure creates no task:
- **Node 37** writes the draw **Ingestion Failed** with `ingestionFailureReason` and `ingestionComparison` (new TEXT 4000 fields; 4,000 characters measured through Write Records, 4,001 fails loudly) and the investment matched by name. It never writes the draw number, so the collision rule is untouched.
- **Node 41** marks the template row Ingestion Failed with a notes line.

## 2. The AI comparison

**The call:** one **Execute Generative AI Skill** call (node 35).
- DocCenter's Text Input skill with a Runtime Prompt; model **Claude Sonnet 4.6** (`cons!SD_TEMPLATE_COMPARISON_MODEL`).
- Input: both workbooks' labels only (header fields, column headings, category rows; no amounts).
- Baseline: the last successfully ingested template for the same investment (`SD_getLastGoodTemplate`; today, draw 80's #72). The standard template is the fallback.

**The gate:** `SD_checkTemplateComparison` decides whether the answer is used.
- Every CHANGE line must be a difference the rules found.
- A rename must sit in the same position once the other changes are set aside.
- Nothing may be missed or doubled.
- The overview must summarise without counting, quoting or restating changes.
- If only the overview fails, the checked lines are kept under standard summary wording. If the lines fail, the text is listed by rules.
- The footer always says which kind of text it is.
- The gauntlet (`.work/sail/gauntlet_SD_checkTemplateComparison.sail`) proves every check with a specimen that must fail: 2 pass, 13 fail as expected, and 1 composes the no-difference text.

**Accuracy test:** met on both live runs, and on 7 of 7 probe calls for the change lines. The stored text for draw 83:

> The budget table columns and budget category rows in the new file are laid out differently from the last template that loaded, so figures cannot be matched to the right columns and budget lines of the draw. The sender should restore the standard column headings and budget category rows and resend the file.
> • The “Current Draw” column is now headed “Draw Funding This Period”.
> • The “Total PTD inc. This Draw (%)” column is missing.
> • The “Insurance” budget line is missing.
> • The “Start-up/Marketing” budget line is missing.
> Compared with THSV_Draw67_Budget_Template.xlsx (Draw #72, received 09/22/2026) by AI (Claude Sonnet 4.6); every change listed was checked against both workbooks.

It names all three seeded differences and nothing else.

**Tokens and latency:**
- **4.9 s and 4 AI actions** for the live call (4.7–6.4 s in the probes).
- Prompt 2,868 plus input 1,969 characters, about 1.2k input tokens; about 700 characters out, about 180 tokens. The token counts are estimates, because the node reports AI actions, not tokens.
- End to end, submit to failure recorded: **92 s**, almost all Doc Center extraction.

**Prompt tuning, measured:** the first two probe overviews miscounted or double-described (one said a second column had been renamed). The prompt and the gate were tightened. Afterwards the probes' overviews passed 3 of 5 and fell back to standard wording 2 of 5; both live runs' overviews passed.

## 3. The alert email

`SD_buildIngestionFailureEmail` produces the alert in the Phase 4 visual language: navy bands, inline styles, no images, links or classes, 8.7 KB.
- Subject: "Draw template could not be loaded: Tamarack Hotel & Spa Vail · Draw #67 (as submitted) · THSV_Draw67_Budget_Template_v2.xlsx".
- Body sections:
  - WHAT WENT WRONG: the reason, in a pink panel;
  - WHAT CHANGED SINCE THE LAST TEMPLATE THAT LOADED: the comparison and its footer;
  - THE FILE: the file name, received time, investment, draw number and sender;
  - WHAT HAPPENS NEXT: correct and resubmit through Receive Capital Call; the draw stays on the list as Ingestion Failed.
- Node 40 sends it from the failure branch to `SD Draw Demo Approvers` and `SD Draw Asset Managers`.
- The rendered copy is at [.work/email/draw83_ingestion_failure.html](.work/email/draw83_ingestion_failure.html).

## 4. The record

- **Summary** of a failed draw:
  - a red state card in the action strip's slot: why, what changed (bulleted), what happens next, with a link to Receive Capital Call;
  - the fact strip and Draw Origin; the sections describing a loaded draw are hidden;
  - no action and no YOUR ACTION.
- **Draws list:** the row reads "Not loaded · Template could not be loaded · received Sep 25 · resubmit via Receive Capital Call" with a red **Ingestion Failed** tag, and the status filter gains Ingestion Failed. The fact strip's breadcrumb reads "Received template (not loaded)".

## 5. Live verification

**Run 1** (as `sd.accountant`, draw 82):
- The branch fired and wrote the draw correctly, but the template row was never marked, so node 41 did not run.
- **Isolation:** node 39's rule and node 41's expression both evaluated cleanly. A control copy of node 40 run as the designer **completed**.
- The difference was identity: node 40 ran as the persona, who isn't in `SD Draw Asset Managers`. **Fix:** node 40 now runs as the designer.
- The control showed `count(ac!ToValidAddresses)` is 0 for group recipients, so the notes no longer report a count.
- Draw 82 (incomplete) and its row were deleted by explicit id, absence confirmed. Process 38992 is left for cancellation (TODO).
- The control sent one "[build test]" alert at ~16:40 UTC.

**Run 2** (as `sd.accountant`, draw 83):
- Ingestion Failed at 16:43:31.
- Template row 6617 reads "Template check failed … Comparison: AI (Claude Sonnet 4.6); AI call 0::00:00:04.896, 4 AI actions; alert email sent to the accountant and asset manager groups". That downstream write proves the send node completed.
- **Break-test** (as the designer): 0 lines, 0 approvals and 0 QIU; no open task.
- **Persona reads**, identical for `sd.accountant` and `sd.assetmanager`: the list row and the Summary as described above, with no action. `sd.assetmanager`'s Awaiting My Action is still "1 · Draw #66".

**Regression** (clean template as `sd.accountant`, draw 84): the reconciliation task (536885220) was open 94 s after submit, with no failure texts and the template row untouched.

## Objects changed

- **Record type `SD Draw`:** fields `ingestionFailureReason` (`3139df20-…`) and `ingestionComparison` (`74b593a2-…`).
- **Constants:** `SD_DRAW_TEMPLATE_COLUMNS` (…_573159), `SD_DRAW_TEMPLATE_CATEGORIES` (…_573165), `SD_DRAW_TEMPLATE_HEADER_LABELS` (…_573171), `SD_TEMPLATE_COMPARISON_MODEL` (…_573177).
- **New rules:** `SD_readTemplateStructure` (…_573199), `SD_listMinus` (…_573187), `SD_joinQuoted` (…_573193), `SD_diffTemplateStructure` (…_573223), `SD_validateIngestedTemplate` (…_573229), `SD_getLastGoodTemplate` (…_573246), `SD_buildTemplateComparisonRequest` (…_573273), `SD_checkTemplateComparison` (…_573286), `SD_curlQuotes` (…_573267), `SD_splitIngestionText` (…_573353), `SD_buildIngestionFailureEmail` (…_573363).
- **Updated rule:** `SD_getDrawDetail` v7.
- **Process `SD Receive Capital Call`:** 46 PVs; nodes 31–41; nodes 11 and 13 rewired. Validator: no errors.
- **Interfaces:** `SD_view_drawSummary` v7, `SD_page_draws` v7, `SD_cmp_statusTag` v2, `SD_cmp_drawFactStrip` v3.
- **Throwaways, all deleted with absence confirmed:** `zz_probeReadExcel`, `zz_probeWidth`, `zz_probeAiCompare`, `zz_probeAlertSend`.
- **The width probe** wrote and then cleared the two new columns on draw 76, an ingested #71, not a shell as my notes said. Net zero; `updatedAt` unchanged.

## Not verified, and the browser checklist

**Not verified:**
- **Gmail rendering of the alert.** Checklist in `TODO.md` Browser checks, with the subject and time.
- **Why the persona-run send stopped.** Inferred; there is no process-instance read.
- **Live runs of three paths:** the standard-template baseline, the skipped-AI path and the rules-only fallback. Covered by rule tests and the gauntlet only (TODO Deferred).
- **Geometry** of the red card and the list row (TODO).

**Browser checklist (Scott):**
1. Gmail: open "Draw template could not be loaded: Tamarack Hotel & Spa Vail · Draw #67 (as submitted) · …_v2.xlsx" (~16:43 UTC). Check the navy header and red chip, the pink WHAT WENT WRONG panel with two red bullets, four navy comparison bullets with a grey italic footer, THE FILE rows, WHAT HAPPENS NEXT, no clipping and curly quotes intact. Ignore the "[build test]" copy.
2. As `sd.accountant`, open the Draws page: the "Not loaded" row shows a red Ingestion Failed tag. Open it: the red card sits under the fact strip, its bullets indent cleanly, the Receive Capital Call link opens the intake page, and only Draw Origin appears below.

## Rulings needed

None blocking. For awareness: the comparison uses Claude Sonnet 4.6, not DocCenter's default Haiku 4.5. That is one call of about 5 s and 4 AI actions per failed template.

## Promotion candidates

8 found, all staged at gate 1 in `BUILD_LOG.md`, none promoted:
- Send E-Mail run as a persona to a group that persona isn't in;
- `ToValidAddresses` is 0 for group recipients;
- `length()` / `count()` / `split()` with blank items;
- `contains()` on an empty Any Type list, and eager `and()` / `or()`;
- `a!fromJson` and `try()` at validation;
- AI-skill inputs must be sent as `customInputs`, and `getAiSkill` errors;
- the Excel Tools result wrapper;
- a method note: summaries over itemised facts miscount.

One trigger fired: the Phase 4 "send completion unreadable" candidate was applied and re-staged. The checkpoint is current through this entry. The supplemental is unchanged.

## TODO changes

- **Done:** the Phase 4 Gmail check; the Gmail routing ruling; Phase 5 built.
- **Added:**
  - Browser checks: the alert in Gmail; the failed-draw card geometry.
  - Before demo: the ingestion reset state as read 2026-09-25 (74–80 reconciled #67–#72; 81 and 84 Ingesting; 83 the failure specimen); instance 38992 added to the stranded-instances list.
  - Deferred, each with a trigger: the untested comparison paths; the overview fallback rate; dependencies to re-verify per instance; the Dev MCP 26.6.100 update.

## BUILD_PLAN.md changes

- Phase 4 marked COMPLETE 2026-09-25: the Gmail check and the routing ruling are closed.
- Phase 5 rewritten as built: five items ✅, the Gmail eyeball open, pass conditions met with evidence.
- Phase 5.5 added, and three Phase 6 items added (documentation only).

## Repo changes

- `BUILD_LOG.md`, `BUILD_PLAN.md`, `TODO.md`, `CLAUDE.md` (objects, business rule, repeatability, a known artifact, files), `PROJECT_INSTRUCTIONS.md` (the routing ruling), `Closeout.md`.
- `.work/sail/`:
  - 11 new `.sail` rule files, plus the regenerated Summary, Draws page, detail rule, status tag and fact strip;
  - generators `gen_last_good.py`, `gen_failure_email.py`, `gen_receive_failure.py`;
  - `receive_failure_payloads.json`;
  - the gauntlet;
  - `refs.py`.
- `.work/save_rule_html.py`.
- `.work/email/draw83_ingestion_failure.html` and `.txt`.

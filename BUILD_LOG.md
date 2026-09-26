# BUILD LOG — Starwood draw approval

What has actually been built in the environment, with object identifiers and the decisions behind them. Append after every build step; never rewrite a closed entry — a correction is a new entry that names what it corrects. Entry shape: date and title; scope line (the identity and group memberships every readback ran under); what changed, by object; decisions and why; verified (how, with counts and scope); not verified (and the browser checklist that covers it); promotion checkpoint. The contract is `CLAUDE.md` §7; the promotion loop is §9.

**Promotion checkpoint: current through 2026-09-26 — Phase 6a: CEO email approval with AI reply interpretation — level with the log tail.** A session touching promotion refuses to call itself complete if this checkpoint lags the log tail by more than one session.

## Promotion candidates (staging)

*(Session close-outs append here: "Promotion candidates: N found; promoted / listed / none". Each staged candidate states the trap and the working form, the gate it is held at, and a named trigger — the defined moment that will confirm or discard it. A superseded candidate gets a bracketed in-place marker — `[RESOLVED …]`, `[REVERSED …]`, `[TRIAL REASSIGNED …]` — never a rewrite, so a reader of this section alone never chases a dead trigger.)*

- **[RESOLVED 2026-09-21: already recorded; the supplemental skill lags it. See the ruling below.]** **STAGED (gate 1: one observation) — listing group members worked over the Dev MCP here, contradicting appian-supplemental §3.**
  - *The skill says:* `listGroupMembers`, `getGroup` and `addGroupMembers` return HTTP 403 across the whole surface.
  - *Observed:* on `ny.appiancloud.com` with DevMCP plugin 26.6.95 and bundle stamp 20260903-195919, `listGroupMembers` returned 200 with members for all seven application groups, as `scott.thorn@appian.com`.
  - *Unknown:* whether this is a plugin-version change or a property of this instance. `getGroup` and `addGroupMembers` were not tried.
  - *Trigger:* the first session that needs to add a member to a draw approval group. Try `addGroupMembers` there and read the result back with `listGroupMembers`. Then rule on this candidate: promote it (re-verify per instance), or discard it with the gate it failed.

- **Ruling, 2026-09-21, on the `listGroupMembers` candidate: RESOLVED as already recorded.** Nothing is promoted from this build.
  - *Where the fact already lives:* `reference/mcp-capability-boundaries.md` ("Group membership: reading now works, writing unverified"). It records that group reads work from DevMCP 26.6.90, measured live. This build's observation, and a re-read on 26.6.95 (`listGroupMembers(uuid, directOnly: true)` returned 3 direct members of `SD Administrators`), agree with it.
  - *The actual defect:* appian-supplemental §3 ("GROUP MEMBERSHIP ADMINISTRATION IS NOT AVAILABLE OVER THE DEV MCP") still states the previous generation's 403 for reads. That skill text is stale against the repo's own boundaries doc.
  - *Follow-up:* the correction is a TODO for the skill's owner, not a new promotion.
  - *Membership writes:* `addGroupMembers` stays unverified. Its trigger remains the first session that adds a member to a draw approval group.

- **[RESOLVED 2026-09-21: measured through the production path; promoted to `reference/mcp-capability-boundaries.md` §7-class entry, not to the supplemental until a second instance confirms it.]** **STAGED (gate 1) — TEXT column widths under-report on readback at create time.** Fields created with `length` 1000 or 20 read back as `VARCHAR(255)`, while a 289-character `insertRecordData` write to a "1000" column succeeded and read back intact. Working form: treat the readback as a claim and prove width by a real-length write through the production path. *Trigger:* the first Write Records node write longer than 255 characters to a draw approval column (the `comments` or `contingencyExplanation` fields).
- **STAGED (gate 1) — `addGroupMembers` works on DevMCP 26.6.95.** Three user adds returned `status: success` and each read back with `listGroupMembers(directOnly)`. This closes the "writing unverified" gap in `reference/mcp-capability-boundaries.md` (updated in this session) and further dates supplemental §3. *Trigger:* the next group-membership write on another instance, to tag it "re-verify per instance" or general.
- **[TRIGGER FIRED 2026-09-22 — promoted to `reference/mcp-capability-boundaries.md` §4 (measured a second time, both directions: `customInputs` mapping left the child's parameter null; `inputs: [{name, expression: "pv!x"}]` worked; a bare `"x"` in `inputs` stored the literal). Held out of the supplemental until a third instance, because the supplemental's own text ("`myVar` stores `pv!myVar`") describes a rewrite that did not happen on `updateProcessModel`/`updateProcessModelNode` — the two entries must be reconciled by the skill owner.]** **STAGED (gate 1) — a subprocess node maps the child's parameter PVs back out through `outputs[].saveInto`.** With `referenceUuid` set, the schema lists every parameter PV as an output; `{"name": "outcome", "saveInto": "pv!decisionOutcome"}` carried the child's result to the parent on a synchronous call. Input mappings were bare `pv!x` strings in `inputs` with no `customInputs` block, and they worked. *Trigger:* the next subprocess node built on any build.
- **STAGED (gate 1) — `completeTask(taskId, inputs: [{name, value}])` completes a user input task with ACP values, including ACPs the node reads back as `required: true`.** The form's own button logic does not run on this path, so every ACP must be supplied. *Trigger:* the next MCP-driven task completion.
- **STAGED (gate 1) — `testProcessModel` with `timeoutSeconds: 60` returned a client `Network error: ReadTimeout` at roughly 60 s while the process kept running to completion.** The error is transport, not the process; verify by reading the data. *Trigger:* the next run expected to exceed 45 s.
- **STAGED (gate 1) — `updateRecordData` with an empty CSV cell clears the value (sets null).** Measured on DATETIME, INTEGER and TEXT columns. *Trigger:* the next reset or backfill that must leave a column untouched, where the column is omitted from the CSV instead.
- **[RESOLVED 2026-09-21: the value persists; confirmed in Designer (Properties → Alerts shows `SD Administrators` on all four models). The readback gap stands as recorded.]** **STAGED (gate 1) — `createProcessModel(errorAlertGroupUuid)` cannot be read back over the Dev MCP.** `getProcessModel` returns no alert-group field at all, so persistence is unmeasurable here; the check is a Designer step. *Trigger:* the next Dev MCP generation, to see whether the readback gains the field.

- **STAGED (gate 1, 2026-09-22) — `a!forEach` that returns `{}` for skipped items is not a filter.** When *every* item is skipped the result is N null placeholders (a KPI counted 6 "awaiting" rows for a viewer with none), while a mixed result drops them; and an empty `a!forEach` result keeps the source list's type, so `wherecontains(true, …)` over it fails with "Invalid types (Boolean, <record type>)" (a view rendered for a draw with lines and errored for one without). Working form: `if(a!isNullOrEmpty(list), {}, index(list, wherecontains(value, a!forEach(items: list, expression: <boolean or text>)), {}))`. Measured in both directions (failure, then the fix, on the same specimens). *Trigger:* the next interface that filters a list in SAIL.
- **STAGED (gate 1, 2026-09-22) — `text()` truncates, it does not round.** 368,899,430.77 printed as $368,899,430 and 2,491,584.83 as $2,491,584 under `"$#,###,###,###,##0"`; `round(value, 0)` first gives 431 / 585. Extends the supplemental's "text() truncates and needs explicit thousands groups" with the rounding half. *Trigger:* the next money format written.
- **STAGED (gate 1, 2026-09-22) — `min()` over a list of Dates returns a value that formats a day early.** `text(min({date(2026,10,15)}), "MMM D")` printed "Oct 14" for the designer; computing the offset in days from `today()` and adding it back printed "Oct 15". Time-zone shift on the datetime that `min` returns. *Trigger:* the next date aggregate shown to a user.
- **STAGED (gate 1, 2026-09-22) — `updateSite` with the existing pages passed by `uuid` alone preserved their URL stubs** (`2rcKrQ`, `VRvmbQ`, `tO9EuA` read back unchanged after adding a fourth page). This contradicts the earlier warning carried in `BUILD_PLAN.md` that `updateSite` regenerates every stub; that warning may describe the full-page-object form of the call. *Trigger:* the next `updateSite` on any site.
- **STAGED (gate 1, 2026-09-22) — the open task of a process is reachable in SAIL only through a task report, and the platform ships one.** `a!queryProcessAnalytics(report: todocument(<id of "Current Tasks for Process.arf">), contextProcessIds: {pid}).data[1].dp0` returns the task id, which `a!processTaskLink` accepts; a persona who is an assignee rendered the link (sail, as `sd.assetmanager`). The report's document id is instance-specific (39 here; found by walking `folder(6, "folderChildren")` — folders 3–6 are the System Knowledge Center's roots, and the Task Reports folder had been moved into a "Misc Routines" KC). `tp!id` cannot be written earlier: custom outputs evaluate at the end of the task (docs). Re-verify per instance. *Trigger:* the next build that links a record view to a live task.
- **STAGED (gate 1, 2026-09-22) — sail does not follow a task link.** A `cardLayout` whose `link` is `a!processTaskLink` is listed as `<display>`, not `⤴ <navigate>`; the stored YAML carries the `ProcessTaskLink` with its task id, so the target is terminal-verifiable, the click is a browser check. *Trigger:* the next persona check that must open a task.
- **STAGED (gate 1, 2026-09-22) — a record link to a record type with no summary view fails interface validation** ("Record links will not work until the record type has a summary view"), so the summary view's own interface cannot carry a record link at creation: create it with the link stubbed, add it as the summary view, then restore the link with `updateInterface`. *Trigger:* the next record type whose first view links to itself.

- **STAGED (gate 1) — an accelerator that reads a draw immediately after a task submit sees a half-applied transition and must settle first.** Measured: 10 s after `completeTask`, the approval rows were already updated but the draw's `currentStep` was not, so a decision computed from that read was refused as STALE. Working form: before the first decision, re-read on a 5 s timer until the row at `currentStep` is In Progress and the state is identical across three reads (18–24 s measured), with a ceiling that stops rather than guesses. Portable shape: "a multi-write transition is not atomic to a concurrent reader; a driver that follows one must wait for a consistent, stable state." *Trigger:* the next build with a process that chains decisions across a multi-node write transition.

- **STAGED (gate 2 — measured on three models, 2026-09-22) — a process model that carries a start form cannot be read or modified over the Dev MCP.** `getProcessModel`, `updateProcessModel` and `createProcessModelNode` fail with `Unexpected error: 'interfaceUuid'`; the `updateProcessModel` that sets the form persists and then errors on its own readback; later calls read first and persist nothing. Working form: build complete, set `startForm` last, treat the model as frozen; or split the start form into a three-node launcher that starts the real model asynchronously. Recorded in `reference/mcp-capability-boundaries.md` §4. *Trigger:* the next Dev MCP generation (re-test `getProcessModel` on `SA Upload and Create Subscription`), or the next build that needs a start form.
- **STAGED (gate 1, 2026-09-22) — `tostring()` of a Decimal keeps 7 significant digits** (`tostring(2604252.23)` = "2604252", `tostring(186977333.5)` = "1.869773e+08"), `text(v, "0.############")` prints binary noise ("2604252.229999999981") and mangles negatives (`text(-21509, "0.##")` = "2150-9.00"), while `fixed(v, 4, true)` is exact for these magnitudes. `todate("2026-11-16")` fails ("Date out of range"); `todate("11/16/2026")` works; ISO dates are parsed with `date(left, mid, right)`. `a!toJson` prints a large decimal in scientific notation (`1.869773335E8`), which `a!fromJson` reads back. Working form: carry numbers as `fixed(…, 4, true)` text through JSON and PVs. *Trigger:* the next rule that serialises a decimal or parses a date string.
- **STAGED (gate 1, 2026-09-22) — Write Records does not clear a field set to `null`** in the record constructor (the old value survives); `updateRecordData` with an empty CSV cell does (2026-09-21). *Trigger:* the next process that must null a column.
- **STAGED (gate 1, 2026-09-22) — the Start Process smart service cannot be configured over the Dev MCP** (`customInputs` in any type spelling → `acSchemaId is null`), and a subprocess node cannot map a child's non-parameter PV to an output (`Unknown output`). Working form: synchronous subprocess plus a query for the row the child wrote. *Trigger:* the next call into a child whose result is not a parameter.
- **STAGED (gate 1, 2026-09-22) — `deleteRecordData` does not cascade through CASCADING relationships**; children are deleted explicitly, children first. *Trigger:* the next cleanup of a parent row.
- **STAGED (gate 1, 2026-09-22) — objects created without `appUuid` are outside the application** (five Phase 2b rules, a constant and nine interfaces were absent from `listApplicationObjects` until `addObjectsToApplication`), while `createInterface(parentFolderUuid)` without `appUuid` looked fine at creation. Working form: always pass `appUuid`; check `listApplicationObjects` at close-out. *Trigger:* the next close-out.
- **STAGED (gate 1, 2026-09-22, instance-specific) — Doc Center findings**, recorded in full in `reference/mcp-capability-boundaries.md` (before §10): models are data rows and can be created by insert; xlsx extraction works directly with no per-field confidence; the save step throws on `[]` for a scalar field and stalls the calling subprocess; the LLM response is cached per document; `AIA_API_Extraction_ConvertInstanceIdToMap` is the read surface. *Trigger:* Phase 5 (malformed template) and the next Doc Center model.
- **STAGED (gate 1, 2026-09-22) — a persona's mid-flow task is unreachable from sail**, but the task's existence and id are terminal-verifiable through the record view's `ProcessTaskLink` (as in Phase 2b) and `listMyTasks` / `completeTask` exercise the task as the designer when the designer is an assignee — `completeTask(taskId, inputs)` with all nine ACPs completed a group-assigned user input task and the process ran on (extends the Phase 1 candidate: measured live). *Trigger:* the next MCP-driven task completion.
- **STAGED (gate 1, 2026-09-22, fix session) — `a!gridLayout` rejects `marginBelow`** ("Unrecognized Keyword … marginBelow" from `updateInterface`), while every field component beside it accepts it. Working form: space beneath an editable grid with the next component's `marginAbove` or a wrapper. *Trigger:* the next editable grid whose spacing is set.
- **STAGED (gate 1, 2026-09-22, fix session) — `updateObjectSecurity` on a connected system read back `inheritSecurity: true` where the object had read `false` before the call**, with the roles exactly as sent and no inherited groups listed (parent `SYSTEM_CONNECTED_SYSTEMS_ROOT_FOLDER`). Unknown whether the flag was flipped by the call or only reported differently. Working form: read the object's security before and after, and record both. *Trigger:* the next `updateObjectSecurity` on any object whose readback showed `inheritSecurity: false`.
- **STAGED (gate 1, 2026-09-22, intake fix) — `a!buttonWidget` has no `link` keyword on 26.6** (`createInterface`: "Unrecognized Keyword — link") although the rendered tree lists `"link": null` on every button — the tree's attributes are not settable parameters, as `CLAUDE.md` §4 warns. Working form: a navigating "button" is a `a!cardLayout(link: a!safeLink(…))` styled as one, or a link field. *Trigger:* the next button that must navigate.
- **STAGED (gate 1, 2026-09-22, intake fix) — a `a!cardLayout` is rejected inside `a!sideBySideLayout`** ("The item at index 1 contains a component that is not supported in a side by side layout. Received: CardLayout") — and the validator only raised it once the branch was rendered (it sat behind `showWhen: false` at creation and passed). Two lessons: cards go in a columns layout beside buttons; a hidden branch is unvalidated as well as unevaluated, so the probe-copy flip in §4 is what caught it. *Trigger:* the next side-by-side that holds a card, and the next interface with a hidden branch.
- **STAGED (gate 1, 2026-09-22, intake fix) — `a!fileUploadField` saves a List of Document even with `maxSelections: 1`** when its value is a local variable: `document(local!v, "name")` threw "Received the type List of Document" on a live persona click (a start form's `ri!document` of type Document coerced silently, which is why Phase 3 never saw it). Working form: `index(local!v, 1, null)` before `document()` and before passing it as a process parameter. *Trigger:* the next upload field outside a start form.
- **STAGED (gate 1, 2026-09-22, intake fix) — outside a start form, `a!submitUploadedFiles(onSuccess: a!startProcess(...))` moves the file into the target folder before the process reads it**, and the process started as the persona with `SD Draw Approvers` holding Initiator (draw shell + document row written, Doc Center subprocess as DESIGNER). The docs' example nests them the other way round (`a!startProcess(onSuccess: a!submitUploadedFiles())`), which would hand Doc Center a document still in the temporary folder. *Trigger:* the next page that uploads a file and starts a process on it.
- **STAGED (gate 1, 2026-09-22, intake fix) — sail drives `a!fileUploadField` on a site-page interface and a non-submit `a!startProcess` button**, and prints the in-page state flip ("the whole page re-rendered (a structural change)") — the post-click state is readable directly, unlike a form submit [S13]. A `load` after interactions is refused without `--fresh`. *Trigger:* the next in-page state change verified through sail.
- **STAGED (gate 1, 2026-09-22, approver fix) — the "Current Tasks for Process" system report returns a cancelled step's task to an administrator, with status 7 (Aborted) and an empty assignee list, and returns nothing for it to an ordinary member of the assignee group.** A lookup that takes "a row came back" as "a task is open" therefore reads differently by identity: full-scope readers see a dead task as live, personas see none — a §4 S32 case measured on a task report. Working form: filter the report's status column to 0 (Assigned) / 1 (Accepted), and treat an administrator's `awaitingViewer` as unproven for personas. Status codes per the docs' task-report pattern (0-based): Assigned, Accepted, Completed, Not Started, Cancelled, Paused, Unattended, Aborted, Cancelled By Exception, Submitted, Running, Error. *Trigger:* the next open-task lookup on any build, and the hardening TODO on `SD_getOpenTaskId`.
- **STAGED (gate 1, 2026-09-22, approver fix) — a persona's task list is not readable from the terminal, but the designer's `listMyTasks` stands in when the designer is a member of the assignee group:** the dead task was absent from it (58 tasks) and the restarted one present (59), which corroborated the report's status column. *Trigger:* the next task-assignment check.
- **STAGED (gate 1, 2026-09-22, Phase 4) — a Send E-Mail node's completion is not readable over the Dev MCP or through process analytics on this instance.** There is no process-instance read; the "Current Tasks for Process" report lists only the attended task; the System Knowledge Center's Process Reports / Process Model Reports / Summary Reports / Application Reports folders (12, 19, 29, 5088 under folder 6) read empty to the designer, and folder 33 "Task Reports" (under "Reports" 5304) lists no children although report 39 lives there. Working form: prove the send by what the process wrote afterwards (the step process registered itself, the task issued) and by the inbox; render the same rule as the body evidence. *Trigger:* the next build that must prove an unattended node ran.
- **STAGED (gate 1, 2026-09-22, Phase 4) — the Python f-string trap for generated SAIL:** SAIL's doubled-quote escapes (`style=""…""`) produce `"""` inside a triple-double-quoted f-string and end it; generate with `f'''…'''` and hoist quoted arguments into variables. Method, not platform — noun-free but not a platform fact; goes to the project file if anywhere. *Trigger:* the next generator that emits inline HTML.
- **STAGED (gate 1, 2026-09-22, fix session) — DocCenter renders an xlsx inline through its own component plug-in, not `a!documentViewerField`.** The docs say the native viewer does not render Office files without the MS Document Editor plug-in; DocCenter's `rule!AIA_UTIL_displayInlineDocument(documentId, sourceDocumentId, height)` routes Excel to `rule!AIA_PLG_DocumentViewer` → `fn!documentViewer(connectedSystem: cons!AIA_RECONCILE_CONNECTED_SYSTEM)`, which rendered in `testInterface` as a component plug-in (`documentViewer/index.html`, document 55270, connected system 47597). Per the docs' service-account rule for component plug-ins with a connected system, users need Viewer on that connected system, so `SD Draw Approvers` was granted it. Instance-specific (DocCenter must be installed). *Trigger:* the browser check as `sd.accountant` (does the viewer render for a non-designer?), then the next build that shows a workbook inline.

- **[TRIGGER FIRED 2026-09-25, Phase 5 — still gate 1: the unattended send was proven by what ran afterwards]** The Phase 4 candidate above (a Send E-Mail node's completion is unreadable) fired. Its working form, proving the send by a later write, was applied deliberately: node 41 writes the template row only after node 40. It caught a stalled send (run 1: no write) and proved a completed one (run 2: written). The candidate is re-staged at gate 1. *New trigger:* the next build that proves an unattended node by a downstream write.
- **STAGED (gate 1, 2026-09-25, Phase 5) — a Send E-Mail node addressed to a group the process initiator does not belong to stopped the process when the node ran as the initiator (a persona)**; the identical node run as the designer completed (control process), and switching the node to run as the designer fixed the live run. Cause inferred (no instance read): the persona's view of the recipient group. Working form: run notification nodes as the designer when the initiator is a persona, and prove completion by a downstream write. Contradicts nothing in the docs we read; instance-dependent (group visibility settings), re-verify per instance. *Trigger:* the next Send E-Mail node in a persona-started process.
- **STAGED (gate 1, 2026-09-25, Phase 5) — `count(ac!ToValidAddresses)` is 0 when the recipients are groups**, so a Send E-Mail node's "valid addresses" output is not a recipient count for group sends. *Trigger:* the next need to count an email's recipients.
- **STAGED (gate 1, 2026-09-25, Phase 5) — `length()` skips `""` and null items; `count()` counts them; `split()` keeps empty fields as nulls in position** (measured: `length({"a","","b"})` = 2, `count` = 3; `split("a||b","|")` = `{"a", null, "b"}`). A list built by `a!forEach` over sheet rows lost 2 of 16 items to `length()`. Working form: size slices from known positions or `count()`; index `split()` results by position. Complements the supplemental's `count()`-on-dictionaries trap. *Trigger:* the next `length()` on a list that can hold blanks.
- **STAGED (gate 1, 2026-09-25, Phase 5) — `contains()` on an empty list typed Any Type fails with "can only act on data of the same type (Any Type, Text)"; `and()` and `or()` evaluate every argument**, so a guard inside them does not protect the call. Working form: guard with `if()`. *Trigger:* the next membership test on a possibly empty computed list.
- **STAGED (gate 1, 2026-09-25, Phase 5) — `a!fromJson` on malformed text fails at validation ("not valid JSON") and `try()` is rejected by the Dev MCP validator as an undocumented function**, though DocCenter's own rules use `try(a!fromJson(…))`. Working form for parsing model output in a rule: ask for a line format and parse with `split()` by position, which cannot throw. *Trigger:* the next rule that parses model output.
- **STAGED (gate 1, 2026-09-25, Phase 5) — Execute Generative AI Skill: the skill's own inputs (Input Text, Runtime Prompt, Runtime Model, Enable Extended Thinking) are refused under `inputs` ("Unknown input … use customInputs") and accepted as `customInputs`**, and the live calls prove they reach the skill. `getProcessModelNodeTypeSchema` lists only AiSkill and RemoteServiceKey even with the skill's uuid; `listAiSkills` and `getAiSkill` fail with "Unexpected error: 'type'". Working form: copy a working node's configuration (the AI skill's integer id and the input names) and send the skill inputs as customInputs. Dev MCP 26.6.95; re-verify on 26.6.100. *Trigger:* the next Execute Generative AI Skill node built over the Dev MCP.
- **STAGED (gate 1, 2026-09-25, Phase 5) — Excel Tools `readexcelsheet` returns `{success, result}`, and `length()` of `result` as returned reads 1** until it is rebuilt with `a!forEach(items: …, expression: fv!item)`. Plugin-specific; re-verify per instance. *Trigger:* the next workbook read with the Excel Tools plug-in.
- **STAGED (gate 1, 2026-09-25, Phase 5; method, not platform) — a model's summary paragraph over a list it also itemises miscounts or double-describes the items** (2 of the first 2 live answers). Its itemised lines were right 7 of 7 times. Working form: gate the items against a rule-computed ground truth; keep the summary general (no counts, no change verbs, only the parts that changed) and gate that too; when only the summary fails, keep the checked items under standard wording. Belongs in the project's eval notes or `CLAUDE.md` if promoted, not the supplemental. *Trigger:* the next AI output that pairs a summary with itemised facts.
- **[TRIGGER FIRED 2026-09-25, Phase 5.5 — confirmed in a second context, held at gate 1 for the operator]** The Phase 5 candidate "Execute Generative AI Skill: skill inputs go in `customInputs`" fired on the reading child (`SD Read Supporting Documents` node 9, DocCenter's Doc Input skill 267): the same form worked, and it extends — a document input must be sent **typed** (`type: "DOCUMENT"`); untyped it read back as Text. It passes the five gates on this evidence (a deliberate re-test on a second skill), but promotion changes the user-level supplemental, which has an owner-held correction pending (`TODO.md` Deferred); proposed for the next template sync. *New trigger:* that sync.
- **[TRIGGER FIRED 2026-09-25, Phase 5.5 — reproduced]** "sail does not follow a task link" (2026-09-22): the Reconcile Extraction card on an Ingesting draw's Summary is again listed as `<display>`; the task was completed over the Dev MCP with the form's own serialisation. Still gate 1 (one platform behaviour, two observations, no control). *New trigger:* the next sail release.
- **STAGED (gate 1, 2026-09-25, Phase 5.5) — an upload that replaces a file field's value discards the temporary file it replaced; sail's upload sends only the new file.** Measured: three PDFs uploaded through sail into one multi-file `a!fileUploadField` (`maxSelections: 10`) left the field holding only the last (plain `saveInto`); with a `saveInto` that appended, the field showed all three, but after `a!submitUploadedFiles` only the last existed — `document()` on the first two: "Document Does Not Exist or has been Deleted" — and `a!startProcess` passed the dead ids on (the process read nothing and ran on). The docs say missing documents are ignored by the submit, so nothing errors. Working form: one file per field (upload slots: a new empty field after each upload), so no upload ever leaves a field's value unless the user clears it. The browser's multi-file behaviour (it reports the whole list) was not measured here. *Trigger:* the next multi-file upload driven through sail, or a browser test of one.
- **STAGED (gate 1, 2026-09-25, Phase 5.5) — an `a!forEach` whose every item returns `{}` yields `[[]]`, and inside a list that empty element is counted by `count()` but skipped by `len()`, so `where(len(list) > 0)` indexes the wrong items.** Measured in the corroboration gauntlet (C5/C6 lost their trailing summary parts; fixed with per-item lengths `where(a!forEach(items: list, expression: len(tostring(fv!item)) > 0))`, and the gauntlet then passed). Extends the Phase 5 `length()`/`count()` candidate. *Trigger:* the next list assembled from conditionally skipped `a!forEach` items.
- **STAGED (gate 1, 2026-09-25, Phase 5.5) — sail cannot address repeated link labels:** a grid whose rows share a link label ("New draw" ×4) is refused ("names 4 different destinations and cannot be told apart; nothing on the page distinguishes them"). Working form: make the target unique (here: clear the stale rows) before a persona check. *Trigger:* the next persona navigation into a list with repeated labels.
- **[TRIGGER FIRED 2026-09-25, Phase 5.6 — reproduced, held at gate 1]** "`tostring()` of a Decimal keeps 7 significant digits" (2026-09-22) fired in the classification gates' own gauntlet: 3 false failures (`tostring(2490296.23)`), fixed with `fixed(x, 2, true)`. Still gate 1: two accidental recurrences, no deliberate re-test. *New trigger:* the next Decimal compared as text.
- **[TRIGGER FIRED 2026-09-25, Phase 5.6 — reproduced, held at gate 1]** The `[[]]` candidate (Phase 5.5) fired in the corroboration gauntlet: an invoice-figure check built as "the list of offending items is non-empty" read true on every case, because `a!forEach` returned `{}` per item. Working form, extended: count with `sum(a!forEach(…, if(cond, 1, 0)))` rather than testing the emptiness of a filtered `a!forEach`. *New trigger:* the next emptiness test on a filtered `a!forEach`.
- **[TRIGGER FIRED 2026-09-25, Phase 5.6 — reproduced]** "sail does not follow a task link": the Reconcile Extraction card was again `<display>` (draw 92). Unchanged at gate 1. *New trigger:* the next sail release.
- **STAGED (gate 1, 2026-09-25, Phase 5.6) — Doc Center's Generative-AI classification returns no confidence.** The instance's confidence is null and the response carries only the classification and a reasoning paragraph, even with the model version's confidence threshold set to 80 (instances 58–81, 85, 89; 30+ runs). A gate that routes "low confidence" therefore never fires live. Working form: gate on the label (an explicit "Other" category plus an exact-match check) and on the instance status; keep the confidence branch for a model that reports one. DocCenter-version-dependent; re-verify per instance. *Trigger:* the next Doc Center classification model on any instance, or a DocCenter update.
- **STAGED (gate 1, 2026-09-25, Phase 5.6) — a synchronous Doc Center run spends ~40–45 s of orchestration around an ~8 s LLM call.** Measured: classification instance 85 went from created to classified in 8.0 s, while the calling worker measured 53.9 s from its start to the subprocess returning. Across 10 live classifications the worker saw 48.5–54.3 s; the 4 extractions took 64.4–70.2 s. Working form: one asynchronous worker per document (the documents then settle in the time of the slowest), and never a serial loop. *Trigger:* the next Doc Center run inside a latency-sensitive flow.
- **STAGED (gate 1, 2026-09-25, Phase 5.6) — Doc Center's reconcile process for test instances takes a full instance record as its input, which a Dev MCP process test cannot pass.** Working form used: write the fields a correct, override-free reconciliation sets (status 4, accuracy 1, reconciled by/on) with `updateRecordData`, with explicit ids; the model version's accuracy readback then reports the set (24/24). This bypasses Doc Center's reconcile logic, which is safe only with self-learning off. *Trigger:* the next Doc Center model trained over the Dev MCP.
- **STAGED (gate 1, 2026-09-25, Phase 5.6) — pure-ASCII PDFs survive `uploadDocument`.** The known corruption (bytes above 0x7F doubled) comes only from the optional binary-marker comment in generated PDFs. Dropping it made 24/24 training files store at their exact local size, and Doc Center read them. Working form: generate test PDFs ASCII-only and verify the stored size. Extends `reference/mcp-capability-boundaries.md`'s upload entry. *Trigger:* the next generated document uploaded over the Dev MCP.
- **[TRIGGER FIRED 2026-09-25, chip fix — working form applied; held at gate 1, see the fix-session entry]** **STAGED (gate 1, 2026-09-25, Phase 5.6; method, not platform) — a reading gate is skipped silently when edits are batched.** The docs-search gate was not run before four interface edits made in one batch; the transcript showed it, not memory. Run afterwards, it surfaced a real finding (tag text truncates at 40 characters). Working form: before claiming a gate in a log, check that the call is in the transcript; run the gate before the batch, not per edit. Home: the project `CLAUDE.md` if promoted. *Trigger:* the next batch of interface edits.
- **STAGED (gate 1, 2026-09-25, chip fix) — a side-by-side layout inside a read-only grid cell passes the object validator and renders on this instance**, though the 26.6 docs and the vendor pack (`components/grid-field-instructions.md`: "NOT ALLOWED IN GRID COLUMNS") say a cell takes a single component. The 26.9 release notes document it. Measured: `createInterface` accepted it and `testInterface` rendered it with `error: null`. Working form: a tag (`MINIMIZE`) beside a wrapping rich-text detail in one cell. Platform-version-dependent; re-verify per instance. *Trigger:* the browser check of the Tie-out cell.
- **STAGED (gate 1, 2026-09-25, chip fix) — `joinarray` drops empty strings** (`joinarray({"","",""}, ";")` returned "", not ";;"). Working form: map empties to a visible marker before joining when positions matter. *Trigger:* the next `joinarray` over items that can be empty.

- **STAGED (gate 1, 2026-09-26, Phase 6a) — a process model's email trigger and Public Events cannot be set over the Dev MCP.** The `core.0` and `event.receiveMessage` node schemas expose no inputs, and `getProcessModel` / `updateProcessModel` carry no trigger or Public Events field. Working form: a human sets both in Designer; keep that model minimal (a hand-off node only) so it never needs MCP edits. One observation: `updateProcessModelNode` on another node preserved the Designer-set trigger. *Trigger:* the next MCP edit to an email-started model — re-check the trigger after it.
- **STAGED (gate 1, 2026-09-26, Phase 6a) — Receive Message mappings target process parameters only.** In Designer, PVs created over MCP as non-parameters were not offered; "New…" creates parameters. Working form: create the mapping targets with `isParameter: true` before the Designer step. Property syntax (Scott): `msg!properties.FromEmail`, `msg!properties.Subject`, `msg!body`. *Trigger:* the next Receive Message trigger configured.
- **STAGED (gate 1, 2026-09-26, Phase 6a) — mail the instance sends to itself arrives from `admin@<site>` whatever From says** (custom sender, process model and process designer, measured on `ny.appiancloud.com`; re-verify per instance). Consequence: a loop test is never an authorized sender. Working form: temporarily map the roles under test to that address, restore by readback. *Trigger:* Scott's live reply (does an external sender keep its address, and what does the recipient see as From?).
- **STAGED (gate 1, 2026-09-26, Phase 6a) — a Send E-Mail text input written as a bare `=pv!x` failed the model save** with "begin 0, end -1, length 8"; `=tostring(pv!x)` saved. *Trigger:* the next Send E-Mail node configured over MCP.
- **STAGED (gate 1, 2026-09-26, Phase 6a) — `stripHtml()` deletes plain newlines**, collapsing a multi-line reply to one line (gauntlet X1–X3 failed, then passed with the working form: split on line breaks first, strip each line). *Trigger:* the next `stripHtml()` over multi-line text.
- **STAGED (gate 1, 2026-09-26, Phase 6a) — `updateProcessModel` refuses to change the type of a node at an existing id** ("node type cannot be changed on update"). Working form: give the new node a new id. *Trigger:* the next full node replacement on an existing model.
- **STAGED (gate 1, 2026-09-26, Phase 6a) — an HTML email's `msg!body` arrives as HTML** (loop test; an external client's reply is unmeasured). Working form: detect HTML and cut quote containers before stripping. *Trigger:* Scott's live reply.
- **[TRIGGER FIRED 2026-09-26, Phase 6a — reproduced both ways; held at gate 1]** "a reading gate is skipped silently when edits are batched": the new exception form was created before its layout gate ran (found by transcript order; gated after the fact, no change needed); the Approvals view edit was gated first. Method, not platform; CLAUDE.md §5 already requires the gate for creations. *New trigger:* the next new interface.

## Entries

### 2026-09-21 — Instantiation and read-only preflight

**Scope.**
- **Design reads:** Dev MCP (`appian`, 157 tools) as `scott.thorn@appian.com`, as recorded in the session file. That account is a member of `SD Administrators` and `SD Users`.
- **sail:** no persona sessions exist.
- **Runtime MCP:** `appian-runtime` was present but not called.

**What changed.** Nothing on the instance. Repo files only:
- `CLAUDE.md`: the build parameters and the MCP-servers note.
- `BASELINE_INVENTORY.md` and `PROJECT_INSTRUCTIONS.md`: new.
- `TODO.md`, `Closeout.md`, and this log.

**Preflight findings.**
1. **Plan gate: STOP.** `BUILD_PLAN.md` is still the template stub. No objects were created and no data was seeded. Only reads were made.
2. **Dev MCP design surface present.** 157 tools, including the record-type, interface, process-model, site, constant, document, test and validate families. `listRecordTypes` scoped to the application returned 16 types.
3. **Version drift.**
   - *Server and plugin:* the plugin is 26.6.95 (App Market up to date, built 20260911-210447). The local bundle is 20260903-195919 (`mcp_src_sha` `a037e2a260ba8fee`), which is the 26.6.90 build that `toolchain.md` §1 pins. The server reports that the bundle is out of sync with the plugin (plugin `mcp_src_sha` `71a81a27e39421db`) and recommends re-downloading it.
   - *Where to get the bundle:* the downloads page `https://ny.appiancloud.com/suite/plugins/servlet/stateless/downloads`, or the direct link `https://ny.appiancloud.com/suite/plugins/servlet/stateless/lcp-mcp-bundle`.
   - *sail:* reports 26.6.90, which matches its pin but trails the plugin.
   - *Branch:* the plugin was built from a detached branch.
4. **Servers and identity.**
   - `appian` is a user-config stdio server with 157 camelCase tools.
   - `appian-runtime` is inherited from the desktop app, with 10 snake_case tools (`appian_*` plus `ping`). It points at `https://ny.appiancloud.com/mcp` and, per the operator, runs as `scott.mcp`; this session did not verify that.
   - The two servers have separate names, so there is no shadow and no merge.
   - The design identity is taken from the Dev MCP cookie file's `username` field. A `loggedInUser()` probe was skipped because it would create an object.
5. **Skill sync.** The repo copy and the installed copy of `appian-supplemental` are byte-identical.
6. **Per-session ritual:** none.
7. **Groups, read back** with `listGroupMembers` (all members, including inherited):
   - `SD Administrators`: `NoahMCPServiceAccount`, `scott.mcp`, `scott.thorn@appian.com`.
   - `SD Users`: those three users plus the nested groups `SD Administrators`, `SD Compliance Reviewer`, `SD Fund Operations Analyst` and `SD Fund Operations Manager`.
   - `SD Compliance Reviewers`: `alexis.kane@appian.com`.
   - `SD Fund Operations Manager`, `SD Compliance Reviewer`, `SD Fund Operations Analyst` and `Subscription Agreement Analysts`: empty.
   - **Finding:** service accounts sit in `SD Administrators`, which contradicts §6.
8. **Persona sessions:** `~/.sail` and `~/.sail-designer` exist, and neither holds a `session.json`. There are no live persona sessions. The persona site stub is unset because the application has no site.

**Application identified.**
- `Starwood Demo` (`dd3bb740-…a144da`, prefix `SD`) is the subscription-intake app. It was matched by its object names and descriptions, such as the subscription packet intake models and the Fund Operations groups.
- Also seen on the instance, and out of scope unless ruled otherwise: `New Fund Instruction Intake` (NFII) and `Capital Calls & Distributions` (CCD).

**Spec artifacts.** All three are present and readable:
- *Current email PDF:* one page, the table-based approval email.
- *New email PDF:* one page, with added sections for draw detail by budget category, budget summary, remaining contingency, QIU detail and approval status.
- *Enhancements xlsx:* one sheet with the seven current workflow steps and the Sep/Oct 2026 enhancements on steps 2, 4, 5 and 6.

All three are gitignored (`*.pdf`, `*.xlsx`), so they are not pushed.

**Verified.** Every fact above comes from a Dev MCP read as the designer, from a local file read, or from `sail --version`.

**Not verified.**
- The executing identity by probe.
- The runtime connector's identity.
- The fine print of the new email PDF. It was rendered at 612×792, so detailed reading of its tables needs a higher-resolution render.
- Object types beyond the five inventoried.

**Promotion.** 1 candidate found (group-member listing works here): listed as STAGED, none promoted.

Promotion checkpoint: current through 2026-09-21 — Instantiation and read-only preflight.

### 2026-09-21 — Phase 0 rulings and Dev MCP update attempt

**Scope.**
- **This is a ruling session.** No build work was done and nothing on the instance was written.
- **The one Dev MCP read** was `getDevMcpVersionInfo`, as `scott.thorn@appian.com` from the session file. That account is a member of `SD Administrators` and `SD Users`.
- **Not used:** `appian-runtime` and sail.

**Ruling 1: the service accounts in `SD Administrators` are an exception, not removed.**
- `scott.mcp` and `NoahMCPServiceAccount` stay in `SD Administrators`, and so in `SD Users`.
- *Reason:* `scott.mcp` backs the chat runtime connector. On a demo instance, removing it is a risk not worth taking.
- *Where it is recorded:* a project exception block at the end of `CLAUDE.md` §6, the clause it contradicts. The "Open issue" bullet in the project section now points to that block.
- *What stays in force:* the rest of §6. `mcp__appian-runtime__*` still never runs design-session work.
- *TODO:* the service-account item is closed and moved to Done.

**Ruling 2: the host application.**
- Draw approval lives in `Starwood Demo` (`dd3bb740-b105-421b-a866-29d542a144da`), which is confirmed.
- `Capital Calls & Distributions` belongs to a different client and is out of scope for this build. It is not to be read from or referenced.
- *Where it is recorded:* `PROJECT_INSTRUCTIONS.md` (header facts) and the `CLAUDE.md` project section.
- *Correction:* this corrects the previous entry, which listed that app as "out of scope unless ruled otherwise". It is now out of scope by ruling.
- *TODO:* the client-validation item is closed and moved to Done.

**Dev MCP update: stopped at Step 0. No versions changed.**
- **Ordering rule, per `maintenance/dev-mcp-update.md`:** `getDevMcpVersionInfo` re-run.
  - *Plugin:* 26.6.95, build `20260911-210447`, `mcpSrcSha` `71a81a27e39421db`. App Market status `UP_TO_DATE`, so the plugin side needs nothing.
  - *Local server:* build `20260903-195919`, `mcp_src_sha` `a037e2a260ba8fee`, which is the 26.6.90 pin.
  - *Verdict:* this is still out of sync, so an update is warranted.
- **Bundle check:** the only Dev MCP bundle in `~/Downloads` is `appian-dev-mcp-server-bundle.tar.gz` (Sep 12, 11,784,292 bytes). The `BUILD-INFO.txt` inside it, read without extracting, shows `build_timestamp=20260903-195919`, the installed generation. The other `lcp-mcp-server-bundle*.tar.gz` files date from July and belong to the previous generation.
- **Result:** the procedure stops here. Installing this bundle would reinstall 26.6.90.
- **Why the session could not continue:** Step 0, downloading the bundle, is an operator step behind the site login. Phase 2's version check also needs a full app relaunch, so versions cannot be verified as matching within this session.
- **Nothing was touched:** no install directory, no registration, and no sail link.
- **Prerequisites confirmed for Phase 1:**
  - Python 3.14.6 and uv 0.11.28.
  - The current registration is the documented shape (`uv run --directory /Users/scott.thorn/appian-dev-mcp-server python -m lcp_mcp_server`, with env `LCP_URL` only).
- **Pins:** `reference/toolchain.md` §1 and §12 are unchanged, because nothing was re-verified.

**Verified.**
- The version report came from `getDevMcpVersionInfo`.
- The bundle's build stamp was read from the tarball.
- The ruling text was read back in the files.

**Not verified.** Any version match after an update, because no update took place.

**Promotion.** 0 new candidates. The staged `listGroupMembers` candidate is unchanged; its trigger has not fired.

Promotion checkpoint: current through 2026-09-21 — Phase 0 rulings and Dev MCP update attempt.

### 2026-09-21 — Dev MCP update, Phase 1 (install): 26.6.90 → 26.6.95

**Scope.**
- **This is maintenance.** There was no build work and no instance writes.
- **No Dev MCP calls this session.** The version report used is the one from the previous entry: plugin 26.6.95, build `20260911-210447`, `mcpSrcSha` `71a81a27e39421db`.

**This supersedes the previous entry's Step 0 blocker.** The operator downloaded the bundle.

**Steps, per `maintenance/dev-mcp-update.md` Phase 1:**
- **Bundle:** `~/Downloads/appian-dev-mcp-server-bundle (1).tar.gz`, downloaded 2026-09-21 17:26, 11,910,499 bytes, sha256 `a342f936…883544`.
  - The name carries a browser suffix. It was identified by content rather than by asking the operator: its `BUILD-INFO.txt` shows `build_timestamp=20260911-210447` and `mcp_src_sha=71a81a27e39421db`, identical to the plugin's report.
  - The old Sep 12 bundle (stamp `20260903-195919`) is also still in Downloads. Neither bundle was deleted.
- **Prerequisites:** Python 3.14.6 and uv 0.11.28. The bundle's `pyproject.toml` requires Python `>=3.13`, which is met. The package version is still `0.1.0`, so the build stamp is the discriminator.
- **Side-by-side install.**
  - *Locations:* `NEW_INSTALL` is `~/appian-dev-mcp-server-20260911-210447`. `pyproject.toml` sits at the archive root, alongside `bin/`, `lib/`, `sdk/` and `src/lcp_mcp_server`. `OLD_INSTALL` (`~/appian-dev-mcp-server`) is untouched and kept as the rollback.
  - *Sync:* `uv sync` succeeded and the `.venv` exists. `import lcp_mcp_server, playwright` succeeded.
  - *Browser:* `sync --extra browser` failed with "Extra `browser` is not defined". That is harmless, because Playwright is a core dependency. Playwright Chromium 153.0.8010.12 was installed, and a headless launch test returned the page title.
- **sail:** `NEW_INSTALL/bin/setup-mac.sh` cleared the quarantine flag and repointed `~/.local/bin/sail` from the old bundle's binary to `NEW_INSTALL/bin/sail-darwin-arm64` (sha256 `5ccd5559…901bca`).
  - `sail --version` now reports `sail version 26.6.95`, and `sail --help` runs.
  - The old binary remains in `OLD_INSTALL/bin/` for rollback.
- **Registration.**
  - *Scan:* the only Dev MCP registration is the global `appian` entry in `~/.claude.json`. A depth-2 scan under `~` found no project `.mcp.json` carrying the Dev MCP. The desktop config's `appian-runtime` entry is a different server and was not touched.
  - *Change:* on the operator's approval, `~/.claude.json` was backed up to `~/.claude.json.bak-2026-09-21-devmcp-update`, and only `mcpServers.appian.args[2]` (`--directory`) was changed, to `NEW_INSTALL`. A structural diff against the backup shows that single change. The env is unchanged (`LCP_URL=https://ny.appiancloud.com`).
  - *Config compatibility:* the new `config.py` differs from the old one only by a reformatted `LCP_API_PATH` line and a renamed property (`beta_base_url` → `lcp_base_url`). The environment variables read are unchanged.

**Verified.**
- The bundle's build stamp matches the plugin's.
- Imports succeed and the headless browser launches.
- `sail --version` reports 26.6.95.
- The registration was read back from the file.

**Not verified.**
- That the running server is the new one. The running session keeps the server process it started with.
- That `getDevMcpVersionInfo` reports plugin and bundle in sync.

Both are Phase 2 checks and need a fresh session after a full quit and relaunch.

**Pins:** `reference/toolchain.md` §1 and §12 are not yet refreshed. That is Phase 2, step 4.

**Promotion.** 0 new. The staged `listGroupMembers` candidate carries over, and Phase 2's boundary sweep (group membership) should re-check it under the new server.

Promotion checkpoint: current through 2026-09-21 — Dev MCP update, Phase 1 (install).

### 2026-09-21 — Dev MCP update, Phase 2 (re-verify): 26.6.95 confirmed running

**Scope.**
- **Maintenance only.** There was no build work and no instance writes.
- **Dev MCP reads:** `getDevMcpVersionInfo`, `listRecordTypes` (limit 1) and `listGroupMembers` (`SD Administrators`, `directOnly`), as `scott.thorn@appian.com` from the session file. That account is a member of `SD Administrators` and `SD Users`.
- **Not used:** `appian-runtime`. No persona sail sessions were available.
- **Relaunch and sign-in:** the operator relaunched after Phase 1. No SSO window was needed, because the persisted session under `~/.appian-devmcp/` was reused.

**Step 1: the running server.**
- `getDevMcpVersionInfo` reports the plugin as 26.6.95 (build `20260911-210447`) and the MCP server as build `20260911-210447`, with `mcp_src_sha 71a81a27e39421db` on both halves.
- Its recommendation: "No action needed: both halves are up to date and came from the same build."
- The build stamp equals `NEW_INSTALL/BUILD-INFO.txt`. **The versions match.**
- The session lists `appian` with 157 tools and `appian-runtime` with 10, so the names are still separate. The design read returned 16 record types.

**Step 2: the real version.** Plugin 26.6.95 per the tool. The package version is still `0.1.0` in `pyproject.toml`, so the build stamp is the discriminator. The bundle ships no changelog; its `INSTALL.txt` covers sail setup only.

**Step 3: the source diff against 26.6.90.** ASTs were compared to separate logic changes from reformatting.
- `browser_auth.py` is byte-identical (sha256 `bcf11935…`, the same as the pin). Auth default, environment variables, state directory, expiry handling and logout are therefore unchanged.
- `config.py`: the only substantive change is a property rename, `beta_base_url` → `lcp_base_url`.
- `server.py`: the LCP client is renamed off "beta", and a new `enforce_generate_interface_sail` flag is added.
- **Tool inventory:** 157 → 157, the same names, equal to the live count.
- **Logic changes that matter to a build:**
  1. An inline-SAIL guard on `createInterface` / `updateInterface`, active only when `SAIL_MCP_ENABLED=true`. It is off here.
  2. `createProcessModel` now takes `errorAlertGroupUuid` in place of `errorAlertGroupName`. Persistence is unmeasured.
  3. Record type `securityMode` is validated client-side.
  4. Integrations have response-to-document properties.
  5. Any 2xx on a DELETE is treated as success.
  6. Non-blocking write checkpoints for a hosted copilot, inert in a local stdio session.

**Step 4: pins refreshed.**
- `reference/toolchain.md` §1 now reads "Verified against DevMCP 26.6.95", with the build stamp and hashes as reported by the tool, `NEW_INSTALL`, today's date, the `browser_auth.py` sha256, and the rollback path.
- §12 now reads "Verified against sail 26.6.95", with the binary path and sha256 `5ccd5559…901bca`.

**Step 5: sail.**
- `sail --version` reports 26.6.95.
- Help for the root and all nine subcommands, captured from both binaries, is byte-identical (328 lines each).
- No persona session exists, so the read-only live measurements (pages, load, show offline, JSON error stream) were **not re-run**. The write-dependent entries were also not re-measured.

**Step 6: sweep.**
- *Names:* no live reference to the old install path remains outside the rollback notes and the historical log and walkthrough.
- *`reference/mcp-capability-boundaries.md`:* gained a "Changed in DevMCP 26.6.95" block, and its `errorAlertGroupName` entry was annotated.
- *`reference/silent-failure-taxonomy.md`:* its `errorAlertGroupName` entry was annotated.
- *Other behavioural entries left as recorded:* ping as a false positive, transport marshalling, instance enumeration, multiple node instances, attended tasks, agent reads. The files implementing them changed only by reformatting, or the entries are plugin-side.
- *Group membership:* re-read live on 26.6.95, and it works.

**Promotion.**
- The `listGroupMembers` candidate is **RESOLVED** (see the staging section). It was already recorded in the boundaries doc; appian-supplemental §3 is stale and its correction is a TODO.
- 0 new candidates.

**Verified.**
- The version match came from the tool.
- The source diffs were run locally.
- The sail help diff was run locally.
- Group reads and the record-type read were live, as the designer.

**Not verified.**
- Whether `errorAlertGroupUuid` persists.
- The inline-SAIL guard's error in practice (it is off).
- Write checkpoints.
- sail's behaviour against a live persona on 26.6.95.

**Rollback.** Still available: `~/appian-dev-mcp-server`, its `bin/` sail binary, and `~/.claude.json.bak-2026-09-21-devmcp-update`.

Promotion checkpoint: current through 2026-09-21 — Dev MCP update, Phase 2 (re-verify).

### 2026-09-21 — Phase 0 transcription and build plan

**Scope.**
- **Docs only.** No build work and no instance writes.
- **Two read-only Dev MCP calls** as `scott.thorn@appian.com`, a member of `SD Administrators` and `SD Users`: `listRecordData` on `SA Fund` and on `Subscription Agreement`. They ground two plan facts, recorded below.
- **Not used:** `appian-runtime` and sail.

**What changed.** Repo files only:
- **`PROJECT_INSTRUCTIONS.md`:** the seven Phase 0 sections were filled with the supplied text, verbatim (a diff against the supplied text shows it byte-identical). The header facts are unchanged, and the italic status line now says Phase 0 is complete.
- **`BUILD_PLAN.md`:** rewritten from the template stub. It passes the plan gate: the stub marker is gone and `## Build Phases` holds 53 checklist items across Phases 0–5.
  - Each phase lists the objects to create or modify, its dependencies, its verification (pass conditions and break-tests stated in advance), and its demo-visible outcome.
  - **Phase 1 is marked as the next session's scope.**
- **`TODO.md`:** the Blocking item "Phase 0 plan" is closed, the persona-accounts item is sharpened, and 7 transcription discrepancies are added as client validation questions.

**Design decisions in the plan, and why.**
- **The approval process is event-driven and unattended.** `SD Apply Draw Approval Decision` takes the draw id, the decision, comments and the actor. It is not a long-running process with user input tasks, because `testProcessModel` refuses attended models (supplemental §9). That keeps every routing path verifiable over MCP.
- **The demo accelerator reuses the same decision process** step by step, with a hard ceiling, so the accelerator cannot diverge from the real routing rules.
- **The treasury notification is gated on the final-approval write,** never merely sequenced after it (supplemental §6 and §9).
- **Doc Center work starts by reading the existing `SD Process Packet (async)` configuration:** a working example on the instance comes first (supplemental §1).
- **Model calls stay out of expression rules,** and AI output passes a deterministic validation gate before any alert or state change uses it.

**Facts read (as the designer).**
- `SA Fund` id 4 is "Harborline Real Assets Fund II, L.P.", so the narrative's fund exists.
- Blue Granite Pension Trust has multiple `Subscription Agreement` rows on fund 4, all "Under Review" or earlier, none Accepted. This is recorded as a narrative continuity question.
- `Starwood Demo` has no investment or property entity. This is recorded as a data-model question.

**Verified.**
- The verbatim transcription, by diff.
- The plan gate, by a structural check.
- The two record reads, with scope stated.

**Not verified.** The fine print in the spec PDFs (the QIU row count and the approval step count). The earlier render was low resolution, so a high-resolution re-read is queued as part of the discrepancy questions.

**Promotion.** 0 candidates found.

Promotion checkpoint: current through 2026-09-21 — Phase 0 transcription and build plan.

### 2026-09-21 — Phase 0 discrepancy rulings applied

**Scope.** Docs only: no build work, no instance reads or writes, and no MCP or sail calls.

**This corrects the Phase 0 transcription entry.** The operator ruled all seven discrepancies raised there. The text of `PROJECT_INSTRUCTIONS.md` changes for the first time since the verbatim transcription.

**`PROJECT_INSTRUCTIONS.md`:**
- **Narrative.**
  - Beat 4: orders 1–2 (Accountant, Accounting Controller) are pre-completed as Approved, and the chain sits at the Asset Manager, order 3.
  - Beat 6 names the CEO (order 9).
  - The chain is described as 9 steps with contiguous orders 1–9.
- **Personas.**
  - The Fund Accountant is the chain's Accountant (order 1), and that step is data only.
  - "Executive (CEO)" becomes "CEO (order 9)", with the Executive (order 5) noted as a separate, data-only role.
- **Data model.**
  - SD Investment added: name and description, related to SA Fund; DealCloud narrated, not integrated.
  - SD Draw now relates to SD Investment.
  - SD QIU Metric says "ten metrics", and they are listed explicitly in order.
- **Vocabulary canon.**
  - Added the Accounting Controller mapping for "accounting manager"; the term is not used in object names or UI text.
  - Added the contiguous orders 1–9 by role. The sample's gap is not reproduced.
- **Business rules.** Added the constraint that the flow does not touch subscription intake data. SA Fund is the one intake object it relates to, through SD Investment.
- **Open questions.** The Blue Granite continuity question is recorded as resolved: narration only.

**`BUILD_PLAN.md`:**
- The Phase 0 discrepancy item is ✅ 2026-09-21.
- Personas and the data-model table follow the rulings: SD Investment added, the CEO at order 9, 9 approval rows, 10 QIU rows.
- **Phase 1:**
  - six record types, SD Investment first;
  - relationships Draw → Investment → SA Fund;
  - an SD Investment seed row;
  - the seeded chain with orders 1–2 Approved, 3 In Progress, 4–9 Pending;
  - seed pass conditions of 1 investment, 1 draw, 10 QIU rows, and 9 approvals with no gap.
- **Phase 3:** the email's Approval Status uses contiguous orders.
- The plan gate still passes, with 55 checklist items.

**`TODO.md`:** "Phase 0 discrepancies" closed and moved to Done with the seven rulings.

**Verified.**
- Each replacement was asserted to match its target exactly once.
- A grep finds no remaining "Executive (CEO)", no "nine metrics", and "accounting manager" only in the canon rule that maps it.
- The plan-gate check passes.

**Not verified.** Nothing on the instance was touched.

**Promotion.** 0 candidates.

Promotion checkpoint: current through 2026-09-21 — Phase 0 discrepancy rulings applied.

### 2026-09-21 — Phase 1 build (in progress): restructure, record types

**Scope.**
- **Designer:** Dev MCP `appian` (157 tools) as `scott.thorn@appian.com`, from the session file; a member of `SD Administrators` and `SD Users`.
- **Other tools:** sail and `appian-runtime` were not used.
- **Row security:** none of the new record types has security rules yet, so the designer's reads of them are unfiltered.

**Preflight.**
- The plan gate passes.
- `appian` has 157 design tools, and `listRecordTypes` returned 16.
- DevMCP 26.6.95 matches the pin, with both halves on build `20260911-210447`. sail is on 26.6.95.
- The skill copies are identical.
- There is no per-session ritual, and there are no persona sessions. The persona site stub was unset at preflight.

**Step 0: phase restructure (docs).**
- **`BUILD_PLAN.md`:** Phase 1 now covers the data model, seed and process, with no custom views. The new Phase 2 is the mockup-first UI foundation. Ingestion moves to 3, the email layout to 4, the failure path to 5, and the final work to 6. `PROJECT_INSTRUCTIONS.md` § Build phases and the phase references in its open questions are updated to match.
- **Ruling recorded, site:** draw views join the existing intake site in a new page group. The intake site was found through `getObjectDependents` on the intake dashboard: `SASite` (`ffae752f-b3d1-44d5-a9ba-c408b66bdb65`), display name "Subscription Agreement Analyst", stub `subscription-agreement-analyst`. It is **not listed as an object of `Starwood Demo`**, which is why the baseline showed zero sites.
- **Second site found:** `42637df6-96f5-4347-85ab-299a7c83ce24`, which hosts the `subscription-intake-dashboard` page. `getSite` on it fails with `Unexpected error: 'targetUuid'`, so it is unread.
- **Ruling recorded, personas:** persona accounts are deferred, and this session verifies as the designer.

**Step 1: existing objects.**
- `SA Fund` (`978232cc-…3dcfb`, data source `_a-0000ebae-…_10766`) is referenced, and id 4 is Harborline Real Assets Fund II, L.P.
- No investment or property type exists, so `SD Investment` is created.
- The legacy `SD Fund` scaffold is not used.
- **No reverse relationship was added to `SA Fund`,** to avoid modifying an intake object; the one-way `SD Investment.fund` suffices for traversal. This is a deliberate departure from the pack's bidirectional rule.

**Step 2: record types.** All six are in `SA Fund`'s data source, have `createTable: true`, and are added to `Starwood Demo`.

| Record type | UUID | Relationships (read back) |
|---|---|---|
| SD Investment | `f285a98c-746c-40e7-899e-65d8d20f766b` | `fund` M:1 → SA Fund; `draws` 1:M → SD Draw |
| SD Draw | `c9d3a947-71aa-4024-879e-363873a12860` | `investment` M:1; `budgetLines`, `approvals`, `qiuMetrics`, `documents` 1:M (CASCADING) |
| SD Draw Budget Line | `ddc4073e-6372-49e2-80de-a088b424abcd` | `draw` M:1 |
| SD Draw Approval | `02c207d5-c725-4d11-bf40-b33573e87ffa` | `draw` M:1 |
| SD QIU Metric | `a0920e4c-0c76-4494-a61a-6e38d5db390a` | `draw` M:1 |
| SD Draw Document | `f3e0033f-2047-4c68-8f6f-cf32166091e9` | `draw` M:1 |

**Field decisions.**
- **Added "Cash/Equity Needed from the Fund?"** as the `cashEquityNeeded` BOOLEAN. The field is in the new email sample's Draw Funding Detail but not in the data model's list; the email's vocabulary governs.
- **`SD Draw Approval` gains `actedBy` and `decisionSource`** (TASK, ACCELERATOR, EMAIL, SEED), for attribution.
- **`SD Draw` gains `activeStepProcessId`,** so an external decision can cancel the open step task.
- **QIU values are TEXT,** per the instruction.
- **No USER-type fields.** Actor names are TEXT, to avoid the mandatory system-user relationships.

**Findings.**
- **Width readbacks under-report.** Every TEXT field created with a length other than 4000 reads back as `VARCHAR(255)`: 1000 → 255 and 20 → 255. Measured by a 289-character write to `SD Investment.investmentDescription` (requested 1000) through `insertRecordData` on probe row id 990: the write succeeded and read back intact. The column is wider than the readback states. The probe row was deleted, and absence was confirmed with an empty `listRecordData`.
  - This is the known supplemental §7 and `CLAUDE.md` §4 class, "readbacks both over- and under-report".
  - It is not the production write path; the proof through a Write Records node is owed.
- **Display names containing `/`, `?` or `(`, and multi-word display names, were rewritten on save.** For example, "On / Under / Over Budget" became "Budget Status". Display labels are left to Phase 2.

**Step 3: seed data** (`scripts/seed_draw66.py`, explicit ids, no `now()`/`today()`/`rand()`; its checks pass with exit 0).
- Investment 1: "Tamarack Hotel & Spa Vail" (THSV) on `SA Fund` 4.
- Draw 66: PIP/Renovation, $2,604,252.23, funding 2026-10-15, On Budget, In Progress at step 3, with the sample's purpose and contingency text.
- 16 budget lines (ids 6601–6616) transcribed from the new email sample. The plan said 17; the sample has 9 "In this Draw" and 7 "All Other" lines.
- 9 approval rows (6601–6609), contiguous orders 1–9, fictional approvers; 1–2 Approved with SEED attribution, 3 In Progress, 4–9 Pending.
- 10 QIU rows (6601–6610), values as formatted text, model as-of 2026-06-30.
- **Read back as the designer:** 1 / 1 / 16 / 9 / 10 rows, and 0 documents. Insert responses were not taken as proof.
- **Reconciliation:** Land, Soft and Hard roll-ups match the sample's Budget Summary except for known source artifacts (the $57,753 contingency adjustment placed differently, and $1 rounding), which the script encodes explicitly. Cents are carried on three lines so the draw lines sum to the amount; see `CLAUDE.md` known artifacts.

**Step 4: groups and constants.**
- `SD Draw Approvers` (`…_5513`, under `SD Users`) with `SD Draw Asset Managers` (`…_5515`), `SD Draw CEO` (`…_5517`) and `SD Draw Demo Approvers` (`…_5519`). Nesting read back.
- The designer was added to the three step groups with `addGroupMembers` and read back as a direct member of each.
- Constants: three GROUP constants by name, `SD_DRAW_TREASURY_RECIPIENT` (USER = the designer, placeholder) and `SD_DRAW_FINAL_APPROVAL_ORDER` (9).

**Step 5: rules, form and process models.**
- `SD_getDrawState(drawId)` returns the routing map; tested against draw 66 with the expected current (order 3) and next (order 4) rows. `SD_getDrawApprovalGroup(role)` returns the three groups (ids 1528, 1529, 1530) for Asset Manager, CEO and AM SVP.
- `SD_form_drawApprovalDecision` (`…_570715`): `testInterface` `error: null`. Its Submit button records `loggedInUser()` into `actor` and defaults a blank comment, so no ACP submits null. **Phase 2 restyle target.**
- `SD Draw.treasuryNotifiedAt` (DATETIME) added so the notification's completion is readable.
- Four process models, all `errorAlertGroupUuid` = `SD Administrators`. **Measurement:** `getProcessModel` exposes no alert-group field, so persistence cannot be confirmed by readback; owed as a Designer check.
- **`SD Apply Draw Approval Decision`** (`0000f06e-a53d-…`, 28 nodes): the single transition as described in `CLAUDE.md`. Probe: a decision for step 5 while the draw sat at step 3 returned `STALE` with no write.
- **`SD Draw Approval Step`** (`0000f06e-a547-…`, 12 nodes): registers `pp!id` on the draw, sends a placeholder notification on a parallel branch, presents the task, then calls the transition synchronously. All five form ACPs read back `required: true` (the supplemental's forced-required trap, handled by the form's defaults).
- **`SD Draw Approval Process`** (`0000f06e-a54a-…`, 8 nodes): starts the step task for the current step when no step process is open.
- **`SD Advance Draw to CEO Step (Demo Accelerator)`** (`0000f06e-a54d-…`, 13 nodes): the loop with a ceiling of 9.
- The subprocess pattern was copied from the intake app's `SD Start Intake (MCP)` node (bare `pv!` mappings, `pmUUID`). The intake app's Send E-Mail and user input task nodes were unconfigured scaffolds, not working examples.

**Step 6: end-to-end verification, as the designer (member of all three step groups).** Pass conditions were stated in `BUILD_PLAN.md` before the run.
1. `SD Draw Approval Process` on draw 66: outcome `STARTED step 3 (step process 38661)`; draw read back with `activeStepProcessId` 38661; task 4250 "Approve or reject draw" listed.
2. `completeTask(4250, APPROVE)`: row 3 Approved with `actedBy` the designer and source TASK; ~7 s later the draw read back at step 4 with row 4 In Progress, and ~4 s after that `activeStepProcessId` 38663 (the step-4 process). **Timing:** the transition completes after `completeTask` returns; a read taken 1–2 s later still showed step 3.
3. Accelerator: `testProcessModel` returned a client ReadTimeout at ~60 s while the process completed. Read back: rows 4–8 Approved with source ACCELERATOR at ~12 s intervals, draw at step 9 with row 9 In Progress and `activeStepProcessId` 536909926; task 536873553 open; the step-4 task gone (task total unchanged at 53, so it was cancelled).
4. `completeTask(536873553, APPROVE)`: draw Approved, all nine rows Approved, `treasuryNotifiedAt` 2026-09-22 02:05:04 UTC. The write downstream of the Send E-Mail node ran, so the node completed without an exception.
5. Reset with the script's CSVs, read back at the seeded state.
6. **Break-test:** fresh start (step process 38665, task 4460), `completeTask(4460, REJECT)`: draw Rejected at step 3, `activeStepProcessId` cleared, row 3 Rejected with the comment and attribution, rows 4–9 untouched, `treasuryNotifiedAt` null, no task opened.
7. Reset again; read back at the seeded state; task total 52, equal to the pre-existing non-draw count, so no draw task is open.

**Not verified.**
- **Email delivery.** No inbox was checked. The nodes completed; whether mail arrived is a mailbox check.
- **Step notification emails to groups** on the parallel branch: not observed at all.
- **`errorAlertGroupUuid` persistence:** unreadable over MCP.
- **Column widths** through the production write path at lengths over 255.
- **Persona behaviour:** no persona sessions; everything ran as the designer, who is full-scope.
- **The race** between the accelerator and a just-started step process (`activeStepProcessId` not yet registered): not exercised; the demo runs these as separate beats.

**Promotion.** 7 candidates found; all STAGED at gate 1 with triggers (staging section). 0 promoted. `reference/mcp-capability-boundaries.md`'s group-membership entry is updated with the measured write.

**Rulings needed.** Listed in `TODO.md`: the Budget Summary artifact, and whether accelerator decision dates should be spread (`dayOffsetPerStep`).

Promotion checkpoint: current through 2026-09-21 — Phase 1 build.

### 2026-09-21 — Phase 2a: browser checks recorded, rulings applied, width and race verified, accelerator dates spread

**Scope.**
- **Designer:** Dev MCP `appian` as `scott.thorn@appian.com` (session file), a member of `SD Administrators`, `SD Users` and the three draw step groups. All readbacks ran under that account; the draw types carry no row security.
- **Not used:** `appian-runtime`, sail.
- **Preflight:** plan gate passes; DevMCP 26.6.95 and sail 26.6.95 match their pins; skills identical.

**Browser checks, run by Scott, recorded as complete.**
- **Outbound email works on this instance.** The treasury placeholder email and the step notification emails arrived in the designer's inbox.
- **`errorAlertGroupUuid` persists.** All four process models show `SD Administrators` under Properties → Alerts. The MCP readback gap stands.
- **The task form renders in Tempo:** step heading with role and approver, the draw summary line, the decision radios and the comments box; a reject with a blank comment is blocked by the required-field validation.

**Rulings recorded** (in `PROJECT_INSTRUCTIONS.md` § Business rules / § Build phases and `BUILD_PLAN.md`): Budget Summary is a roll-up of the detail lines, never the sample's printed figures; accelerator dates spread 1 day per step with the funding date after the last generated date; mockups come from the claude.ai Project into `mockups/` and build sessions never author or modify them; new demo runs come from Phase 3 ingestion, and draw 66 plus the reset script are interim tooling.

**Work item 1: column widths, definitive.** Throwaway model `zz SD Width Probe` (`0000f06e-be90-…`), one Write Records node per record type, `PauseOnError` false, errors mapped to PVs, driven by `testProcessModel`; deleted afterwards (`getProcessModel` → "Does not exist").
- `SD Draw.contingencyExplanation` (created `length` 4000, reads back `VARCHAR(4000)`): a 1,200-character value written and read back intact.
- `SD QIU Metric.notes` and `SD Investment.investmentDescription` (created `length` 1000, both read back `VARCHAR(255)`): 300 and 1,000 characters written and read back intact; 1,001 characters failed on both with `Data too long for column`. **The physical width is exactly the requested 1,000. The create-time readback of `VARCHAR(255)` is wrong. Nothing truncates silently; the node fails loudly past the limit.**
- `SD Draw Approval.comments` (created 1000, reads back 255): a 600-character comment written through the real transition (`SD Apply Draw Approval Decision`) and read back intact.
- Probe values restored to the seed text and read back; QIU 6601 `notes` cleared.
- **No column was altered:** nothing truncated, and the spec's paragraph fields have 4,000 (`contingencyExplanation`) and 1,000 (`notes`) characters. Whether 1,000 is enough for QIU notes is flagged in `TODO.md`; widening would be a drop-and-recreate.
- *Observation, unexplained:* the probe's `len(pv!longText)` reported 1,444 for a 1,200-character input, while the stored value read back as the text sent. The readback is the record.

**Work item 2: accelerator date spread.** `dayOffsetPerStep` default changed from 0 to 1 (PV default read back as `"1"`). Re-run: steps 4–8 decided at 2026-09-23, 24, 25, 26, 27, one day apart; the last generated date (2026-09-27) precedes the funding date (2026-10-15). As the ruling anticipates, the CEO's later live decision carries today's date, earlier than the President's generated one.

**Work item 3: race and timing.**
- **First attempt, unfixed accelerator (observation before fix).** Approval at 02:41:39 UTC; accelerator started 02:41:49 (+10 s). Its read saw rows 3 Approved and 4 In Progress but `currentStep` still 3, asked to decide step 3, was refused STALE by the transition, and stopped after 0 iterations. **No data was harmed** (the guard held; the Asset Manager's TASK attribution stayed) but the demo sequence would have failed.
- **Fix:** a settle phase in the accelerator. On its first pass it re-reads every 5 s (Timer `delayUntil: now() + intervalds(0, 0, 5)`) until the row at `currentStep` is In Progress and the state snapshot (`currentStep|rowStatus|activeStepProcessId`) is identical across three reads, up to 12 waits, else `SETTLE_TIMEOUT`. Later iterations do not settle.
- **Idle-case run** (open step-4 task, no in-flight decision): start 02:44:06; first decision 02:44:24 (18 s settle); CEO task live 02:45:27. **81 s.**
- **Race run, the demo sequence:** approval 02:46:54; accelerator start 02:47:01 (+7 s); first decision 02:47:25 (24 s settle); steps 4–8 at 02:47:25, :37, :49, 02:48:00, :12 (≈12 s each); CEO step process 38691 registered 02:48:28 and its task assigned 02:48:30. **87 s from accelerator start, 94 s from the approval.** Row 3 kept the TASK attribution; the superseded step-4 task was cancelled (task total unchanged); exactly one draw task open at the end. **No stale-decision failure.**
- Both runs returned the client `ReadTimeout` at ~60 s while the process continued.
- Each run closed with a CEO approval (draw Approved, `treasuryNotifiedAt` set) and a reset to the seeded state; final readback: seeded state, task total 52 (no draw task).

**Verified.** Every fact above by readback as the designer or by a local timestamp around the call.

**Not verified.** Email delivery for this session's runs (not re-checked; delivery is now confirmed as a capability). Persona behaviour. Widths on columns not probed (`purpose`, `overBudgetReason`, 1000-requested, by inference only).

**Promotion.** 2 candidates resolved (width: measured and recorded in the boundaries doc; alert group: persists per Designer). 1 new candidate staged (the settle rule). 0 promoted to the supplemental.

Promotion checkpoint: current through 2026-09-21 — Phase 2a: browser checks, rulings, width and race verification.

### 2026-09-22 — Phase 2b: draw list page, tabbed draw record views, restyled approval task form, list-texture seed, monotonic decision dates, persona-verified

**Scope and identity.** Designer: Dev MCP `appian` as `scott.thorn@appian.com`, a member of `SD Administrators`, `SD Users` and the three draw approval step groups (full-scope; every `testInterface` / `testRule` / `listRecordData` readback below ran under it). Personas through sail: `~/.sail-sd.assetmanager` (username `sd.assetmanager`, `SD Draw Asset Managers`) and `~/.sail-sd.accountant` (`sd.accountant`, `SD Draw Demo Approvers`), both live, both in `SD Users`; identity confirmed by observation (the pages that resolve, the YOUR ACTION row that only the asset manager sees). `--from-devmcp` not used. `appian-runtime` not used. Docs-search used for every layout parameter in play (grid columns and widths, tag, progress bar, card choice templates, record/task links, header content layout, headerTemplateFull); the pack's header-content, sidebyside, columns, rich-text and card-choice references read before the first SAIL.

**Preflight.** Plan gate passes; Dev MCP 26.6.95 (`20260911-210447`) and sail 26.6.95 match the pins; skill copies identical; persona sessions live but the site returned 500 to both personas until the site security change below.

**What changed, by object (UUIDs in `CLAUDE.md` § Draw approval objects).**
- *Data (items 1–3 of the brief, before the summary).* Investment 2 `Gateway Logistics Park Phase II` (fund 4); draws 63/64/65 (THSV, Approved) and 11 (Gateway, Approved), 12 (Gateway, In Progress at step 6, no lines/QIU/documents); 45 approval rows inserted + 9 updated (54 total, ids = draw × 100 + order, `activatedAt` = previous decision); QIU as-of 2026-09-30; `SD Draw.receivedDate` / `submittedBy`, `SD Draw Approval.activatedAt`, `SD Draw Document.status` / `notes` / `receivedDate` added; three metadata-only document rows 6601–6603. Persona rows renamed to the accounts' display names (Priya **Ramen** — the account's spelling, flagged; Elena Marchetti). `scripts/seed_draw66.py` rewritten to carry all of it.
- *Transition (item 4).* `SD Apply Draw Approval Decision` node 4 computes `effectiveDate = max(requested, previousDecisionDate + 1 day)`; node 22 writes `activatedAt` on the next row; `SD_getDrawState` v2 returns `previousDecisionDate`, `decisionDate` and `activatedAt` per row. Verified end to end from the seeded state (all nine dates ascending, 10/06 → 10/14, funding 10/15), then reset.
- *Rules.* `SD_getUserDisplayName`, `SD_getOpenTaskId` (+ constant `SD_CURRENT_TASKS_FOR_PROCESS_REPORT_ID` = 39), `SD_fmtMoney` (v3: rounds first; negatives in parentheses), `SD_fmtRelativeDays`, `SD_getDrawDetail` (v4), `SD_getDrawListRows`.
- *Shared interface pieces.* `SD_cmp_statusTag`, `SD_cmp_sourceLine`, `SD_cmp_labelValue`, `SD_cmp_drawFactStrip`.
- *Record views on `SD Draw` (item 5).* `SD_view_drawSummary` (v5) as **Summary** (`summary`); `SD_view_drawBudgetDetail` (v3) as **Budget Detail** (`_5vAYPw`); `SD_view_drawApprovals` (v2) as **Approvals** (`_HP07OQ`); `SD_view_drawDocuments` (v1) as **Documents** (`_8-A_WA`). Record title expression: `"Draw Funding Approval | " & investment name`. Each view is `rule!SD_view_…(drawId: rv!identifier)`.
- *Draws page (item 6).* `SD_page_draws` (v4) added to `SASite` as page **Draws** (`draws`, uuid `76fd3289-…`, icon f155) with the three intake pages passed by uuid and preserved. Site security: viewer = `Subscription Agreement Analysts` + `SD Draw Approvers` (both personas are direct members of the latter, read back). The navigation page group is a Designer step (not exposed over the Dev MCP).
- *Task form (item 7).* `SD_form_drawApprovalDecision` v3 restyled; inputs `drawId` and `stepOrder` added; `SD Draw Approval Step` node 9 gained ACPs `drawId` / `stepOrder` (read back in the inputMap). The live task that predated the wiring was completed with REJECT ("Build reset"), the draw reset through the two CSVs, and the launcher rerun: step process 536909940, task 536874206 live for `SD Draw Asset Managers`.
- *Cleanup.* Throwaway rule `zz_SD_probeFolder` deleted; `getExpressionRule` returns 404.

**Decisions and why.**
- **"Awaiting my action" means group membership *and* an open task** (`awaitingViewer`). Without the second half, `sd.accountant` (a member of the catch-all `SD Draw Demo Approvers`) would count Gateway #12 — at step 6 with no process started — as awaiting them, against the brief's expectation of 0. The action strip follows the same rule, so it shows only while a task exists.
- **The task link is resolved through the platform's "Current Tasks for Process" report**, because a user input task's `tp!id` is only available at task end and nothing else in SAIL maps a process id to its open task. The report's document id is an instance constant with a re-verify note.
- **Band versus record header.** Appian's record header carries the mockup's h1; the mockup's fact strip is a white card at the top of every view (under the tabs). Colours follow the mockup palette; the strip's "Review & Approve" is a linked card, since a button widget takes no link.
- **Approval progress bar** is a single-tone `a!progressBarField` (approved/total) plus a nine-icon stepper (✓ green, ● blue, ○ grey), because a two-tone bar (mockup's 22.2 % + 11.1 %) is not a SAIL component.
- **Budget Summary shows "—" adjustments for every group** (computed roll-up; the seeded reallocation nets to zero inside Soft), where the mockup prints Soft +$57,753 / Hard ($57,753). The roll-up ruling of 2026-09-21 wins; the mockup is not touched (ruled); the delta is recorded in `CLAUDE.md` § Known data artifacts. Totals read $390,196,711 and $18,693,028 (cents on three lines), one dollar off the mockup's printed figures for the same reason.
- **Seeded attribution is hidden.** Rows with `decisionSource` "seed" show no source/actor line and "N/A" comments render as "—"; real decisions (TASK / ACCELERATOR / EMAIL) show their source and actor under the date.
- **Empty states are intentional** (Gateway #12): "No budget lines" chip, "budget detail not yet extracted", empty grids with messages, "Funded to date is computed from the budget detail…".
- **Not built:** "Save for Later" (no draft save on a task form without a process change); row-click navigation on the list (rows open through the Draw and Investment links); the "Advance draw (demo)" related action; a page group.

**Verified (with scope).**
- *As the designer, `testInterface` (`diagnostics.error: null`) on all four views for draws 66 and 12, the Draws page, and the form (drawId 66 / stepOrder 3, decision NONE and REJECT).* Summary #66: tie-out "Ties ✓ … $2,604,252.23"; Budget Summary Land $121,825,238 / Soft $67,174,329 / Hard $201,197,144 / Total $390,196,711, Current Draw — / $112,667 / $2,491,585 / $2,604,252; Remaining Contingency $1,274,757 → ($57,753) → $1,217,004 and 6.8 % → 6.5 % over $18,693,028; Funding History "Funded to date: $368,899,431 of $390,196,711 (94.5 %)", "This draw brings PTD to 95.2 %", rows #66, #65, #64, #63; QIU 10 rows as of 09/30/2026. Budget Detail #66: In this Draw 9 lines, All Other 7, BUDGET $278,676,480 / $390,196,711 / — / $390,196,711 / $2,604,252 / $371,503,683 / 95.2 % / $18,693,028 — equal to the mockup's Budget Detail row for row. Approvals #66: nine rows, row 3 highlighted, time at step 1 day / 1 day / < 1 day, note text. Documents #66: three rows with chips. Draws page: Awaiting 1 (#66 · Asset Manager step), In Approval $11,544,252 / 2 draws, Funding Next 30 Days $2,604,252 / 1 draw · next: Oct 15 (computed against today, 2026-09-22; the mockup's frame is October), Funded YTD 2026 $24,928,659 / 4 draws; order #66, #12, #65, #64, #11, #63. Form: header "Step 3 of 9 — Asset Manager / Assigned to Elena Marchetti · with you since Oct 7 · funds scheduled Oct 15", cards "Advance to AM SVP (step 4 of 9)" / "Terminate this draw request", Comments required with the right message when REJECT is selected.
- *As `sd.assetmanager` via sail:* `pages` lists Draws (`draws`); the page loads with Awaiting 1 / Draw #66, #66 carries YOUR ACTION and sorts first; #66 Summary shows the action strip and the "Review & Approve" card whose stored YAML link is `ProcessTaskLink` task 536874206 — the id `SD_getOpenTaskId` returns for step process 536909940; Gateway #12 shows no strip and no YOUR ACTION and all four tabs render (41 read-only values, empty-state grids).
- *As `sd.accountant` via sail:* the page loads with Awaiting 0 ("Nothing waiting on you"), no YOUR ACTION; #66 Summary without the strip (42 values against the asset manager's 44); Budget Detail (19 grid rows), Approvals (9), Documents (3) all readable; #12's four tabs render.
- *Monotonic dates:* full run readback as above; the reject used for the reset landed at 10/08 11:05 (floor = previous decision + 1 day), as the rule says.
- *Site readback:* four pages with the three intake stubs unchanged; security role map read back with both viewer groups.

**Not verified.**
- Following the task link and submitting the restyled form as a persona (sail cannot follow a task link; the form was rendered by `testInterface` as the designer only) → browser checklist in `TODO.md`.
- Geometry of all three pages (widths, one-row KPI cards, band, column widths, button alignment) → browser checklist.
- Document download links (no files attached until Phase 3).
- The Draws page under Tempo or on mobile.
- Record-level security: none exists; both personas see every draw.

**Structural deltas from the mockups (§7).** Record header instead of the mockup's band (fact strip repeated under the tabs); the list's row click is two link cells; the progress bar is single-tone plus a stepper; "Save for Later" absent; "Ties ✓" chip and stepper icons stand in for the mockup's coloured badges; Budget Summary adjustments "—" (data, see above). None of these changes the mockups (ruled); they are listed for the next mockup pass in the Project.

**Findings.** Seven candidates staged (staging section): the `a!forEach`-as-filter trap (measured in both directions, with the fix as control), `text()` truncation, `min()` over dates, `updateSite` stub preservation, the task-report route to a task id, sail and task links, the summary-view record-link ordering. Also noted, not staged: `testInterface`'s `maxResponseSizeBytes` did not truncate ~30–70 KB responses; `updateRecordType.titleExpression` accepts a related field and stores the `#"urn:appian:record-field:v1:…"` form.

**Promotion.** 7 candidates found; 7 listed as STAGED at gate 1 with triggers; 0 promoted (each has one measurement or one instance). The supplemental is unchanged, so the repo and user-level copies stay identical.

**TODO changes:** closed "Spec artifacts are not on GitHub" and "Persona accounts and sail logins"; added Before demo "Demo start" and the "Ramen/Raman" name flag; added three Browser checks owed (task from the strip and form submit, geometry, document links); added Deferred items (intake pages visible to personas, page group, Save for Later, Advance-draw related action, seed dates versus the clock, record-title duplication); updated the record-level-security item.

Promotion checkpoint: current through 2026-09-22 — Phase 2b.

## 2026-09-22 — Phase 3: Doc Center ingestion, success path (capital call intake, extraction, accountant reconciliation, draw assembly)

**Scope and identity.** Designer: Dev MCP `appian` as `scott.thorn@appian.com` (full-scope; every `testInterface` / `testRule` / `listRecordData` readback ran under it; `completeTask` ran under it). Personas through sail: `~/.sail-sd.accountant` (`sd.accountant`, `SD Draw Demo Approvers`) drove the intake form and read the Draws page and the draw's views; `~/.sail-sd.assetmanager` read the Draws page. Both live all session. `--from-devmcp` not used; `appian-runtime` not used. Unattended Doc Center and commit nodes run as DESIGNER (`runAs`), so no AIA read ran under a persona. Docs-search consulted for `a!fileUploadField` (target-folder permission: Editor) and the editable grid (`a!gridLayout` / `a!gridLayoutColumnConfig` vocabulary) before either form.

**Capability check (brief item 1) — measured, xlsx path live.** Doc Center on `ny.appiancloud.com` is the DocCenter application (prefix AIA). Its extraction models are rows; model 85 `drawBudgetTemplate` (version 142, section 223, 12 header fields + a 9-column table) was created with `insertRecordData`. `AIA Extraction Run Model Version` routes an xlsx to the Generative-AI spreadsheet path and returned every header field and all 16 lines correctly on the first live run (instance 846: 22 s LLM call, claude-haiku-4-5). Recorded in `reference/mcp-capability-boundaries.md`. No PDF rendition was needed. Two blockers found and fixed on the way: Doc Center's save step throws when the LLM returns `[]` for a blank scalar field (the `generalComments` field was removed from the model; its `[]` had stalled instances 846 and 847 and their calling processes), and the response is cached per document (a description change showed no effect on the same file).

**What changed, by object (UUIDs in `CLAUDE.md` § Draw approval objects).**
- *Folder and constant.* `SD Draw Documents` under `SD Artifacts` (admin `SD Administrators`, editor `SD Draw Approvers`, viewer `SD Users`; `author` is not a role the tool accepts — Editor is what the upload needs) and `SD_DRAW_DOCUMENTS_FOLDER`.
- *Record fields.* `SD Draw.extractionInstanceId`, `SD Draw.ingestionProcessId` (INTEGER).
- *Rules.* `SD_extractedValueToText` (v2), `SD_getExtractionForReconcile`, `SD_getExtractionInstanceIdForDocument`, `SD_parseExtractedNumber`, `SD_parseExtractedDate`, `SD_buildIngestedBudgetLines`, `SD_buildIngestedApprovalChain`, `SD_buildIngestedQiu`; `SD_getDrawDetail` v6 (Ingesting draws: group = Demo Approvers, task found on `ingestionProcessId`, role "Accountant reconciliation", day count from `receivedDate`).
- *Interfaces.* `SD_form_receiveCapitalCall` (start form), `SD_form_reconcileExtraction` (task form); `SD_page_draws` v6 (blank names dropped from the fund/investment dropdowns — an Ingesting shell had crashed the page with "Choice values cannot be null"; "Ingesting" status choice; "New draw" label and a "Doc Center extraction · Accountant reconciliation" step cell); `SD_view_drawSummary` v6 (strip text and "Reconcile Extraction" card for an Ingesting draw); `SD_cmp_drawFactStrip` v2 (crumb "New draw (ingesting)").
- *Processes.* `SD Receive Capital Call` (`0000f06f-5661-…`, 30 nodes; topology read back: 1→3→4→5→6→7→8→9→10→11→12→13→14→15→16→17→18→19→22→23→24→(25→)26→27→28→29→30→2, failures 5/11/18/27→20→21→2) and the frozen launcher `SD Receive Capital Call (Intake Form)` (`0000f06f-5971-…`; two earlier launchers and one earlier main model were deleted after the start-form and subprocess-mapping findings). Both models: initiator `SD Draw Approvers`. `SASite` page **Receive Capital Call** (ACTION, stub `receive-capital-call`), existing stubs preserved.
- *Application membership.* Fifteen Phase 2b objects (five rules, a constant, nine interfaces) were outside the application; added with `addObjectsToApplication`.
- *Doc Center rows.* Field 3624 `generalComments` deleted; field descriptions of 3624/3625 edited before that (no effect on a cached document).
- *Data.* Verified run: `SD Draw` **74** (displays #67), budget lines 6617–6632, approvals 6610–6618, QIU 6611–6620, document 6608 (document id 55270). Build-time shells 67–73 and their document rows deleted explicitly (draws first when they had no children, children first otherwise). `scripts/seed_draw66.py --cleanup-ingested` added (refuses seeded ids).
- *Cleanup.* `zz_SD_probeAia` and `zz_SD_probeFmt` deleted; both return 404.

**Decisions and why.**
- **Launcher + main model.** The Dev MCP cannot read a model with a start form (three models measured), so the start form lives on a three-node launcher and the pipeline stays editable. The main model has no start form and is started with `inputs: [{name: "document", expression: "pv!document"}]`.
- **Everything the accountant sees comes from process variables as text**, because DocCenter's record types are secured for its own groups and a persona-scoped read would return empty silently (§6). Numbers travel as `fixed(…, 4, true)` because `tostring()` loses precision above seven digits.
- **The reconciliation is a user input task** (the brief's wording), assigned to `SD Draw Demo Approvers`, and the Phase 2 UI finds it the way it finds approval tasks: the shell carries `ingestionProcessId`, `SD_getDrawDetail` resolves the open task through the "Current Tasks for Process" report, and the Draws page / Summary strip show YOUR ACTION and "Reconcile Extraction". It was first stored in `activeStepProcessId`, which blocked `SD Draw Approval Process` ("NOT_STARTED … activeStepProcessId=38740") because Write Records could not null it — hence the separate column.
- **No confidence threshold.** Doc Center gives no per-field confidence on the spreadsheet path, so every extraction routes to reconciliation and the form says so; the Phase 5 malformed template is the failure specimen.
- **`generalComments` dropped from the model** rather than prompt-engineered: the parser bug is in Doc Center's save step and the cache made prompt changes unobservable on the demo file.
- **Header-field commit takes `investmentId` from the form's exact-name match** (case-insensitive); an unmatched name leaves the draw without an investment and the form says so in the field's instructions.

**Verified (with scope).**
- *As `sd.accountant` via sail:* `pages` lists Receive Capital Call; the form loads (upload field REQUIRED, Receive, Cancel); `interact` uploads the local xlsx and `Receive` submits (process 38739 = the launcher); the Draws page shows the new row as **Ingesting** within 8 s of submit ("New draw", dashes, first row, YOUR ACTION, KPI "1 · New draw (ingesting) · Accountant reconciliation · today"); the draw's Summary strip reads "Doc Center extraction is ready for your reconciliation…" with the **Reconcile Extraction** card whose stored link is `ProcessTaskLink` task **8435** (listed by `listMyTasks` as "Reconcile extracted draw", process 38740, issued 78 s after submit). After assembly: Draws page row `#67 YOUR ACTION | Tamarack | $2,604,252.23 | 11/16/2026 in 55 days | 1 of 9 · Accountant Priya Ramen · today | In Progress`; Documents tab row `THSV_Draw67_Budget_Template.xlsx | Budget Template | Extracted & Confirmed | 09/22/2026 | Doc Center extraction confirmed by Scott Thorn 09/22/2026`; Budget Detail 16 lines + BUDGET.
- *As `sd.assetmanager` via sail:* Draws page Awaiting 1 · Draw #66; `#66 YOUR ACTION` first; `#67` present with no YOUR ACTION ("1 of 9 · Accountant Priya Ramen"); Ingesting shell visible to them without YOUR ACTION (before assembly).
- *As the designer:* `listRecordData` readbacks — draw 74: drawNumber 67, investmentId 1, amount 2604252.23, cashEquityNeeded true, fundingDate 2026-11-16, PIP/Renovation, purpose, On Budget, N/A, contingency text, status In Progress, currentStep 1, extractionInstanceId 849, submittedBy "Vail Peak Management LLC (Property Manager)"; 16 budget lines equal to the template row for row (groups Hard ×2 / Land ×2 / Soft ×12; inThisDraw true for the nine active lines); 10 QIU rows as of 2026-09-22 with draw 66's values; chain 6610–6618 with the mockup names, order 1 In Progress, activatedAt 14:10:50; document row Extracted & Confirmed. `testInterface` (`diagnostics.error: null`): Summary #67 — fact strip $2,604,252.23 / In Progress — Accountant / November 16, 2026 in 55 days / PIP/Renovation / Harborline; strip "Your approval is pending — Accountant, step 1 of 9"; "Step 1 of 9 · Accountant · Priya Ramen · 0 of 9 approved"; Draw Origin "Received September 22, 2026", source document with a `DownloadDocLink_[Document:55270]`, INGESTION "Extracted & Confirmed", AMOUNT VERIFICATION **Ties ✓** "current draw lines sum to $2,604,252.23"; Budget Summary Land $121,825,238 / Soft $67,174,329 / Hard $201,197,144 / Total $390,196,711, current draw $112,668 / $2,491,584 / $2,604,252; Funding History #67, #65, #64, #63 ("Funded to date $369,013,387 of $390,196,711 (94.5 %) · brings PTD to 95.2 %"); QIU "model as of 09/22/2026". Documents view: the download link on the real file. The reconciliation form rendered with the real payload: 13 header fields populated, 16 rows, "Ties ✓", the no-confidence notice, document link. `SD Draw Approval Process` for draw 74: "STARTED step 1 of draw 74 (step process 38746)".
- *Task completion:* `completeTask(8435, all nine ACPs)` as the designer with the unedited payload (the form's own serialisation, reproduced) → header, lines, document, QIU, chain and activation all written (readbacks above).
- *Readbacks:* every node of the pipeline (30), the launcher's mapping (`pv!document`), folder security, both models' role maps, the site's five pages, 404 on both probes.

**Not verified.**
- **The persona's own submit of the reconciliation task** (the brief's "via sail as sd.accountant"): sail cannot open a task; the task was completed over the Dev MCP as the designer, so the document row reads "confirmed by Scott Thorn". Browser checklist in `TODO.md` (run the intake again, open the draw as `sd.accountant`, Reconcile Extraction → Confirm & assemble draw → expect "confirmed by Priya Ramen").
- **Edited-value run** (brief's "if time"): not run.
- **The reconciliation form's geometry** (two-column header, nine-column editable grid at DENSE spacing) and the start form's drop zone — browser only.
- **Document download as a persona** (S9) — browser only; the link's target is verified from the designer's render.
- **Funding History semantics for an ingested draw**: lists prior *approved* draws (65/64/63), not 66 — ruling needed.
- **The `Ingestion Failed` branch** (nodes 20/21) — never fired; Phase 5 is the break-test.

**Findings.** Nine candidates staged (staging section); one earlier candidate's trigger fired and was ruled (subprocess mapping → boundaries doc). Also fixed, not staged: a Dev MCP `listExpressionRules(appUuid)` showed only 14 rules, which is what exposed the missing application membership.

**Promotion.** 9 found; 8 listed as STAGED with triggers; 1 fired trigger ruled — promoted to `reference/mcp-capability-boundaries.md` §4 (not to the supplemental: it contradicts the supplemental's own wording and needs the skill owner's reconciliation). The supplemental is unchanged; repo and user-level copies remain identical.

**TODO changes:** see the close-out line.

Promotion checkpoint: current through 2026-09-22 — Phase 3: Doc Center ingestion, success path.

## 2026-09-22 — Fix session: reconciliation form full width with inline document viewer, rulings recorded, persona name synced

**Scope.** Dev MCP `appian` as `scott.thorn@appian.com` (member of `SD Administrators`, `SD Users`, the three draw step groups; also a direct member of `AIA All Users`, so every designer render of DocCenter's viewer is full-scope). sail as `sd.accountant` (`~/.sail-sd.accountant`, `SD Draw Demo Approvers`) for the one persona readback. `appian-runtime` and `--from-devmcp` not used. Docs gate honoured before the layout edit: `a!pane` / `a!paneLayout` in a form (widths, padding, forced FULL width), `a!documentViewerField` (no native Office rendering), connected-system security for component plug-ins.

**Found on arrival (not done by this session).** A second ingested #67 exists: `SD Draw` **75** (created 14:35, extraction instance 850, ingestion process 536909974, step process 536909980, document 55280, document row 6609, approvals 6619–6627), with its document row reading "Doc Center extraction confirmed by **Priya Raman** 09/22/2026" — so Scott ran the persona intake-and-reconcile browser check after the Phase 3 close-out and the account rename is already live. Draw 74 (the session's verified run) still exists beside it. Draw 66's live step process is now 536909940.

**What changed, by object.**
- **Interface `SD_form_reconcileExtraction`** (`…_571183`, now **version 2**; inputs unchanged, so process node 14's nine ACP mappings still bind). Rebuilt as a full-width two-pane form: `a!formLayout` → one `a!paneLayout(showPaneDividers: true)` with two `AUTO` panes (even split). Left pane: verdict strip (`a!sideBySideLayout`: "EXTRACTION instance #n · 13 header fields · 16 budget lines" + the confidence note, and the tie-out `a!tagField` — green "Ties ✓ $x" / red "Does not tie · lines $x vs draw $y" — at the right); "DRAW HEADER · EXTRACTED"; a two-column `a!columnsLayout` of plain fields (labels above; stacks on PHONE); chips on exactly two fields — under **Draw Number** green "Next in sequence" / amber "Out of sequence: last draw is #n" (shown only when an investment matched; "none on file" when the investment has no other draws), under **Investment Name** green "Matches <investment> on file" / amber "No matching investment"; Purpose, Budget and Contingency Explanation, General Comments (instructions: not extracted; per the ruling it stays editable) as full-width `a!paragraphField`s; the 16-row `a!gridLayout` unchanged in content (right-aligned `a!floatingPointField`s, DENSE, zebra); beneath it a right-aligned rich-text line "Current Draw total $x vs draw amount $y · Ties ✓ / off by ($d)" that recomputes from the same locals the grid saves into. Right pane (background `#F5F6F8`, padding LESS): "SOURCE DOCUMENT", the workbook name as `a!documentDownloadLink`, then `rule!AIA_UTIL_displayInlineDocument(documentId: ri!documentId, sourceDocumentId: ri!documentId, height: "TALL")` (a plain note when no document). Buttons: the single primary **Confirm & Assemble Draw** (label case per the brief), same saves as before. `showTitleBarDivider` / `showButtonDivider` true. Amber palette `#FDF3E0` / `#92600A` taken from `mockups/draw-summary.html`'s `--amber` tokens; green and red as the build's status tags.
  - *Sequence check:* a second `a!queryRecordType` on `SD Draw` filtered by `investmentId = matched id` and `id <> ri!drawId` (`applyWhen` the draw id is set), `max(drawNumber)`; "next" means `drawNumber = max + 1`.
  - *One validator rejection on the way:* `a!gridLayout(marginBelow: …)` → "Unrecognized Keyword at line 275 — marginBelow"; removed (staged).
- **DocCenter's `AIA Reconcile Connected System`** (`_a-0000ef94-6bb9-8000-a1b4-011c48011c48_661273`, the only connected system in the DocCenter app): **`SD Draw Approvers` (`…_5513`) added as a Viewer** beside `AIA All Users`, administrator unchanged (`14a675fc-…`). Reason: the inline viewer is a component plug-in bound to this connected system, and the docs say such a component needs Viewer on the connected system; `AIA All Users` (161 members) holds neither persona. Readback confirms the role map as sent. The readback also shows `inheritSecurity: true` where the pre-call read showed `false`, with no inherited groups — recorded as a candidate and as a TODO with the revert recipe. This is the one change outside `Starwood Demo`; it is reversible in one call.
- **Record data (explicit ids, no sweep).** `SD Draw Approval.approverName` → "Priya Raman" on 1101, 1201, 6301, 6401, 6501, 6601, 6610, 6619 (`updateRecordData`); `SD Draw Document.notes` on 6601 → "Doc Center extraction confirmed by Priya Raman 10/05/2026". No other row carried the old spelling (the 74/75 document rows already read Scott Thorn / Priya Raman).
- **Repo.** `scripts/seed_draw66.py` (CHAIN, DOCS, docstring → Raman; `checks()` still passes: 7 OK), `CLAUDE.md` (seed-texture note), `PROJECT_INSTRUCTIONS.md` (five rulings: Business rules gains reconciliation-as-task, Funding History = prior approved draws, General Comments unextracted-but-editable, ingested chain starts at step 1 with the accelerator bridging, and the confidence-threshold rule annotated; Demo narrative item 4 annotated; Open questions: the Excel-format question and its PDF-rendition fallback struck as resolved), `BUILD_PLAN.md` (Phase 3: persona submit ✅ ruled a browser check with the draw-75 evidence; Funding History ✅ ruled; General Comments ✅; chain-at-step-1 ✅; the rebuild ✅; two new open items — the browser pass on the rebuilt form, and deleting one of the two #67s), `TODO.md`, `.work/sail/SD_form_reconcileExtraction.sail` (the deployed expression).

**Decisions and why.**
- **Even pane split (both `AUTO`).** The brief asked for the document at about half or slightly more; the docs' guidance is one fixed pane plus one `AUTO`, but a fixed left pane would squeeze the nine-column grid at laptop widths, and a fixed right pane would cap the workbook on wide screens. Two `AUTO` panes distribute evenly and keep both halves fluid; if the browser pass wants the workbook wider, the left pane takes `WIDE_PLUS`.
- **DocCenter's rule rather than `a!documentViewerField`.** The native viewer does not render xlsx (docs); DocCenter's does, through its plug-in, and the instance already uses it on its own reconcile page. The dependency is recorded in the form's header comment and in `CLAUDE.md`.
- **The Draw Number chip hides when no investment matched** rather than inventing a third string: without an investment there is no sequence to check, and the Investment Name chip already says amber.
- **Rulings recorded as the brief stated them**; the persona-submit item was closed on the instance evidence (draw 75) rather than on the ruling alone.

**Verified.**
- `testInterface` on the live payload (instance 849, draw 74, document 55270, header and lines JSON from `rule!SD_getExtractionForReconcile(849)`): `diagnostics.error: null`, 344 ms; rendered strings in order: the button, "EXTRACTION instance #849 · 13 header fields · 16 budget lines", the confidence line, "Ties ✓ $2,604,252.23", the header fields with their values (Funding Date 2026-11-16, Draw Amount 2604252.23, Submitted By stripped), "Matches Tamarack Hotel & Spa Vail on file", **"Out of sequence: last draw is #67"** (correct: draw 75 is also #67), the three paragraphs, 16 grid rows (Operating Deficits −21509, Contingency adj. −57753), "Current Draw total $2,604,252.23 vs draw amount $2,604,252.23 Ties ✓", "SOURCE DOCUMENT", the xlsx as `DownloadDocLink_[Document:55270]`, and the viewer component (`documentViewer/index.html`, value `{"documentId":55270,"connectedSystem":{"id":47597},"settings":{"showExportButton":false}}`). The tree's form attributes read `formWidth: "FULL"`, `isHeaderFixed`, `isButtonFooterFixed`, `showPaneDivider: true` on both panes. As the designer.
- **Control render** (draw 12 of Gateway, whose only other draw is #11; draw number 12, amount 100 against one line of 90): "Next in sequence" — proves the self-exclusion and the investment filter; "Matches Gateway Logistics Park Phase II on file" from a lower-case input — proves the case-insensitive match; "Does not tie · lines $90.00 vs draw $100.00" and "off by ($10.00)" — proves the tie-out recomputes from the lines. `error: null`.
- `rule!SD_getUserDisplayName("sd.accountant")` → "Priya Raman" (testRule). `listRecordData` on `SD Draw Approval` (72 rows) after the update: eight rows read "Priya Raman", zero read "Ramen"; `SD Draw Document` 6601 reads the new note. As the designer.
- **As `sd.accountant` via sail:** Draws page loads; "AWAITING MY ACTION 2 · Draw #67 · Accountant step · today"; both #67 rows read "1 of 9 · Accountant Priya Raman · today" with YOUR ACTION; 8 rows.
- Connected-system security readback after the grant: viewer = `AIA All Users` + `SD Draw Approvers`.
- Interface version readback: 2 (previous 1). No throwaway objects were created.

**Not verified (and why).**
- **Geometry** — pane widths at common screen widths, label wrapping, the grid's numeric columns, the viewer's height. sail carries no geometry and `testInterface` no widths, so the brief's "re-render checks at common widths" is not possible with the tooling; it is Scott's browser check (`TODO.md`, the rebuilt-form item, steps 2–3 and 6).
- **The inline viewer as a persona.** `testInterface` runs as the designer (a member of `AIA All Users`); whether the plug-in renders for `sd.accountant` with the new Viewer grant is the same browser check, step 3, with the fallback symptom and the revert recipe written down.
- **The persona submit of the rebuilt form** — a task; browser check by ruling (step 5). The pre-rebuild submit is evidenced by draw 75.
- **The chips' edit-time behaviour in a browser** (step 4) — the recompute is proven by the control render, the interaction is not.

**Promotion candidates:** 3 found (grid `marginBelow` rejection; `inheritSecurity` readback flip; DocCenter inline xlsx viewer and its Viewer requirement) — listed, none promoted (all gate 1, single observations). No trigger fired. Repo and user-level `appian-supplemental` unchanged.

Promotion checkpoint: current through 2026-09-22 — Fix session: reconciliation form full width, rulings, persona name synced.

## 2026-09-22 — Fix session: intake confirmation state, draw-number collision handling at reconciliation

**Scope.** Dev MCP `appian` as `scott.thorn@appian.com` (member of `SD Administrators`, `SD Users`, the three draw step groups); every `testInterface`, `getProcessModel`, `getObjectSecurity`, `getSite` and `listRecordData` readback ran under it. sail as `sd.accountant` (`~/.sail-sd.accountant`, `SD Draw Demo Approvers` → `SD Draw Approvers`) drove the intake page and read the Draws page. `appian-runtime` and `--from-devmcp` not used. Docs gate before the interface work: local-variable refresh semantics, `a!fileUploadField` outside a start form / `a!submitUploadedFiles`, `a!startProcess` (permissions, async `onSuccess`), `a!urlForSite` with the `site!` reference, `a!safeLink(openLinkIn)`.

**What changed, by object.**
- **Interface `SD_page_receiveCapitalCall`** (new, `_a-0000f060-57b9-8000-9c4d-011c48011c48_571309`, in the app, **version 4**; no inputs). `a!headerContentLayout` with the Draws page's navy header; state local `form` / `received` / `error`. Intake card: instructions, `a!fileUploadField` (target `cons!SD_DRAW_DOCUMENTS_FOLDER`, `maxSelections: 1`, xlsx validation), an error line shown on `error`, **Receive** (SOLID, `validate: true`, disabled until a file is attached) whose `saveInto` is `a!submitUploadedFiles(onSuccess: a!startProcess(processModel: cons!SD_RECEIVE_CAPITAL_CALL_PM, processParameters: a!map(document: local!uploaded), onSuccess: state ← received, onError: state ← error), onError: state ← error + fv!error)`. Confirmation card (`showWhen: received`): "Capital call received · Doc Center extraction is running on <file> · The draw appears in the Draws list immediately as a new draw (Ingesting). Reconciliation reaches the accountant in roughly 90 seconds, as the Reconcile Extraction task on that draw."; **Go to Draws** as a navy `a!cardLayout(link: a!safeLink(uri: a!urlForSite(sitePage: 'site!{…}SASite.pages.{…}draws'), openLinkIn: "SAME_TAB"))` in a NARROW column beside the outline **Receive Another** button (clears the document and the error, state ← form). Versions: 1 created; 2 the probe copy with `local!state: "received"` (hidden-branch render, §4); 3 restored; 4 the list-typed-upload fix (`local!uploaded: index(local!document, 1, null)`).
- **Constant `SD_RECEIVE_CAPITAL_CALL_PM`** (new, PROCESS_MODEL → `SD Receive Capital Call` `0000f06f-5661-…`, `…_571303`, in the app).
- **`SASite`** (version 8 → **9**): page **Receive Capital Call** (`cec364e7-…`) re-pointed from ACTION → the launcher to INTERFACE → `SD_page_receiveCapitalCall`; stub `receive-capital-call`, icon, description and the other four pages preserved (uuid-merge form).
- **Deleted:** process model `SD Receive Capital Call (Intake Form)` (`0000f06f-5971-8000-24f9-7f0000014e7a`; `getProcessModel` → "Does not exist") and interface `SD_form_receiveCapitalCall` (`…_570984`; `getInterface` → 404). Dependents checked first: only the application and the launcher's own start-form reference. `.work/sail/SD_form_receiveCapitalCall.sail` removed from the repo.
- **Pipeline `SD Receive Capital Call`:** unchanged. Read back to confirm its parameters (`document` Document, `cancel` Boolean) and its security — `SD Draw Approvers` already held Initiator, so no security change.
- **Interface `SD_form_reconcileExtraction`** (`…_571183`, version 2 → **3**): draw-number collision handling. New locals `extractedDrawNumber` (from the header JSON), `nextAvailable` (= max prior number + 1 for the matched investment, own row excluded), `collision` (extracted ∈ prior numbers), `drawNumber` = `a!refreshVariable(value: if(collision, nextAvailable, extracted), refreshOnReferencedVarChange: false)` so the prefill happens once and an override survives edits to other fields, `drawNumberOnFile`, `nextInSequence`, `drawNumberChip` ∈ RENUMBERED / NEXT / ON_FILE / GAP. Chip text: RENUMBERED amber "Submitted as #<extracted>, already on file — renumbered to next in sequence"; NEXT green "Next in sequence"; ON_FILE amber "#<n> is already on file for this investment"; GAP amber "Out of sequence: last draw is #<n>". The title keeps the extracted number; the confirmed `local!drawNumber` commits as before.
- **Repo:** `PROJECT_INSTRUCTIONS.md` (collision ruling in Business rules), `CLAUDE.md` (object table, ingestion rule, collision rule, repeatability, files), `BUILD_PLAN.md`, `TODO.md` (frozen-launcher deferred item removed; intake browser check added; reset note updated), `.work/sail/SD_page_receiveCapitalCall.sail`, `.work/sail/SD_form_reconcileExtraction.sail`.

**Decisions and why.**
- **Submit the upload before starting the process.** Outside a start form the file sits in a temporary folder until `a!submitUploadedFiles`; the pipeline's Doc Center node reads the document, so the file must be in `SD Draw Documents` first. The docs' example nests the calls the other way round; ours nests `a!startProcess` inside `onSuccess` of the submit. Measured working (draw shell, document row 6610 with document 55289).
- **Go to Draws as a card-link, not a button.** `a!buttonWidget(link:)` is rejected by the validator on this instance; a card carrying `a!safeLink` is the idiom the Summary strip already uses for the task link.
- **Asynchronous start.** `a!startProcess` default (`isSynchronous: false`) — `onSuccess` fires when the start request is accepted, so the confirmation appears at once and the ~80 s pipeline runs on.
- **Collision states beyond the two ruled.** The ruling names the collision and the clean case; an override back onto a used number (ON_FILE) and a gap (GAP) are also possible values of the editable field, so the chip covers them in amber rather than reading "Next in sequence" falsely. Nothing is blocked: the confirmed value always commits (business data, never replaced silently).

**Verified.**
- `testInterface` on `SD_page_receiveCapitalCall`: intake state `error: null` (upload target 55227, Receive disabled with no file); confirmation state rendered through the probe copy (`local!state: "received"`): "Capital call received", both message lines, the Go to Draws card with `uri: https://ny.appiancloud.com/suite/sites/subscription-agreement-analyst/page/draws`, `openLinkIn: SAME_TAB`, Receive Another. Restored expression read back with `local!state: "form"` (version 3, then 4 after the list fix). As the designer.
- **As `sd.accountant` via sail:** page loads (Receive disabled); upload of the local xlsx → document 55289, Receive enabled; first **Receive** click → HTTP 500 "at function 'document' [line 131]: Received the type List of Document" (the confirmation render), *but* the process had started: draw **76** (Ingesting, `ingestionProcessId` 268476653, 15:09:01) and document row 6610 (55289, Received) read back as the designer. After the version-4 fix: upload → 55293, **Receive** → the page re-rendered to the confirmation state ("Capital call received / Doc Center extraction is running on THSV_Draw67_Budget_Template.xlsx / …", Go to Draws url, Receive Another); **Receive Another** → the empty upload form (Receive disabled); Draws page `--fresh` → 10 rows, two "New draw · Ingesting · Doc Center extraction · Accountant reconciliation received Sep 22" rows (draws 76 and 77) beside the seed and the two #67s; "AWAITING MY ACTION 2 · Draw #67 · Accountant step · today".
- `getSite` after the update: version 9, the page INTERFACE → `…_571309`, stubs unchanged. Deletions: 404 / "Does not exist".
- `testInterface` on `SD_form_reconcileExtraction` v3, live payload (draw 74, instance 849): `error: null`; Draw Number **68**, amber (`#FDF3E0`/`#92600A`) "Submitted as #67, already on file — renumbered to next in sequence"; title "Reconcile extracted draw #67"; Investment chip green; Ties ✓. Control (Gateway draw 12, extracted 12, only #11 on file): Draw Number 12, green "Next in sequence"; "Matches Gateway Logistics Park Phase II on file"; Ties ✓ $100.00. Both as the designer.

**Not verified (and why).**
- The intake page's **error state** never fired (no failure to provoke without removing a permission); browser check by choice, or accept as untested.
- **Go to Draws navigation** — a `<url>` that sail cannot follow; browser check (the target URL is read back).
- The **override surviving edits** (`refreshOnReferencedVarChange: false`) and the ON_FILE / GAP chips — reasoned from the docs' refresh table and the a!match, not rendered; browser check on the rebuilt form.
- Geometry of both pages — browser only.
- The two new shells' pipelines (76, 77) were not followed to the reconciliation task; they run the unchanged pipeline.

**Promotion candidates:** 5 found (no `link` on `a!buttonWidget`; card rejected in a side-by-side and only when rendered; upload field saves a list; submit-then-start ordering; sail drives in-page state flips) — listed at gate 1, none promoted. No trigger fired. Repo and user-level `appian-supplemental` unchanged.

Promotion checkpoint: current through 2026-09-22 — Fix session: intake confirmation state, draw-number collision handling.

## 2026-09-22 — Fix session: current approver action on the draw summary (draw 66, step 3)

**Scope.** Dev MCP `appian` as `scott.thorn@appian.com` (member of `SD Administrators`, `SD Users`, the three step groups; a direct member of `SD Draw Asset Managers` beside `sd.assetmanager` — group readback). Every `testRule`, `listMyTasks`, `getObjectSecurity`, `getProcessModel`, `listRecordData` and the one `testProcessModel` ran under it. sail as `sd.assetmanager` (`~/.sail-sd.assetmanager`) and `sd.accountant` (`~/.sail-sd.accountant`) for the persona readbacks. `appian-runtime` and `--from-devmcp` not used. One throwaway rule `zz_probeStepTask` (`…_571416`) created for the task-report readback and deleted (404 confirmed).

**Symptom, reproduced.** As `sd.assetmanager` via sail: Draws page "AWAITING MY ACTION 0 · Nothing waiting on you", #66 without YOUR ACTION; #66 Summary shows the step card "Step 3 of 9 · Asset Manager · Elena Marchetti" and no strip, no Review & Approve, no `ProcessTaskLink` in the stored YAML.

**Diagnosis, in the brief's order.**
1. *Live step process and open task?* Draw 66 read `status In Progress, currentStep 3, activeStepProcessId 536909940` (designer). `SD_getOpenTaskId(536909940)` returned task **536874206** — so the lookup found "a task". The probe read the report's full row: `c2` (Status) = **7 = Aborted** (docs' task-report pattern, 0-based), `c11` (Assignees) = **[]**, Owner null. The designer's `listMyTasks` (58 tasks) did not list 536874206 although it listed every other live "Approve or reject draw" task, corroborating: **no live task for step 3; the step process was cancelled** (the Process Monitoring sweep — `TODO.md`'s cancel list named the `testProcessModel` launcher run 536909956 that started this step process). **Root cause found at step 1.** Steps 2 and 3 were not needed: the group assignment is right (`SD Draw Asset Managers` holds `sd.assetmanager` and the designer; the step model's Viewer is `SD Users`), and the lookup does find a task — the task was dead.
   - *Why the two identities disagreed:* the designer's `SD_getDrawDetail(66)` read `viewerIsAssignee: true, openTaskId: 536874206, awaitingViewer: true` — a full-scope reader is handed the aborted task by the report and would have rendered YOUR ACTION and a dead link; the persona is not, so she saw nothing. Recorded as a candidate and a hardening TODO (`SD_getOpenTaskId` to accept status 0/1 only) — not changed here (one defect, no other changes).
2. *Fix.* `updateRecordData` on `SD Draw` 66: `activeStepProcessId` cleared (empty cell) — the launcher's `canStart` requires it null; **no approval row touched**. `testProcessModel` on `SD Draw Approval Process` with `drawId 66` → `COMPLETED`, outcome "STARTED step 3 of draw 66 (step process **536909994**)", `state` showing orders 1–2 Approved with their dates (10/06 15:20, 10/07 11:05) and order 3 In Progress, unchanged.

**Verified.**
- Designer: `SD_getDrawDetail(66)` → `activeStepProcessId 536909994` (registered by the step process itself), `openTaskId 536876873`, `awaitingViewer true`; approvals unchanged. The report's row for 536909994: task **536876873**, status **0 Assigned**, assignees **[1528]** = `SD Draw Asset Managers` (`currentGroup: 1528`). `listMyTasks` now 59 tasks, including 536876873 ("Approve or reject draw", SD Draw Approval Step 11:34 AM EDT).
- **As `sd.assetmanager` via sail:** Draws page (fresh) "AWAITING MY ACTION 1 · Draw #66 · Asset Manager step · today", "#66 YOUR ACTION … 3 of 9 · Asset Manager Elena Marchetti"; #66 Summary: strip "Your approval is pending — Asset Manager, step 3 of 9 · With you since Oct 7 · funds scheduled in 23 days" and **Review & Approve**; stored YAML carries `ProcessTaskLink` with `task.id 5.36876873e+08`, `siteUrlStub subscription-agreement-analyst`, `pageUrlStub draws`.
- **As `sd.accountant` via sail:** #66 Summary shows the step card only, no strip, zero `ProcessTaskLink` in the YAML (not her step); her Draws page "AWAITING MY ACTION 5 · New draw (ingesting) · Accountant reconciliation" — the reconciliation path unchanged (nothing in it was touched).
- Probe rule deleted: `getExpressionRule` → 404.

**Not verified.** The persona's own click on Review & Approve (sail cannot follow a task link) — the existing browser check covers it; whether Process Monitoring shows 536909940 as Cancelled (the Dev MCP has no process-instance read; the task's Aborted status and empty assignees are the evidence). Draws 74/75/77 (#67/#67/#68) and shells 76/78 were left as found (Scott's intake runs continue; draw 77 was reconciled as #68 by the collision rule, as designed).

**Promotion candidates:** 2 found (the task report returns aborted tasks to administrators only; the designer's task list as a stand-in for a persona's) — listed at gate 1, none promoted. No trigger fired. Repo and user-level `appian-supplemental` unchanged.

Promotion checkpoint: current through 2026-09-22 — Fix session: current approver action on the draw summary.

## 2026-09-22 — Phase 4: new approval email layout as HTML from live draw data

**Scope.** Dev MCP `appian` as `scott.thorn@appian.com` (member of `SD Administrators`, `SD Users`, the three step groups — so also a recipient of every step email on this instance). Every `testRule`, `getProcessModel`, `updateProcessModel*`, `listGroupMembers`, the one `testProcessModel` and the record readbacks ran under it. No persona checks this phase (nothing persona-visible changed: the email goes to a mailbox, the hardening only removes a false positive for administrators). `appian-runtime` and `--from-devmcp` not used. Two throwaway rules (`zz_probeFolder`, `…_571569`) created and deleted (404 confirmed); the earlier `zz_probeStepTask` was deleted in the previous session. Spec read at full resolution: `New approval email sample blacklined.pdf`.

**Item 0 — TODO bookkeeping.** The Elena browser check (task opens from #66's Summary strip; Reject blocks without a comment) and the DocCenter-owners message are recorded as done; the connected-system grant stays as a Deferred note with its revert recipe (no objection so far).

**What changed, by object.**
- **Rule `SD_buildApprovalEmail(drawId, stepOrder)`** (new, `…_571551`, v2): returns `a!map(subject, html, bytes)`. Reads `SD_getDrawDetail`, the draw's budget lines, QIU rows and approval rows (with comments); computes the In-this-Draw / All-Other split, the BUDGET total row, the Land / Soft / Hard roll-ups (as the Summary view, per the ruling), the contingency line over the total balance, the QIU as-of date; formats money through `SD_fmtMoney` (cents only on the header amount), `0.0%` for PTD, em dashes for null/zero; escapes every record text. Layout: one outer table (max-width 1040, Arial), navy header band "DRAW FUNDING APPROVAL | <investment>" + a facts line (draw #, fund, draw type, funding date, amount, budget status), greeting "Hello <step approver>," with the sample's reply instruction and the red italic warning, then sections in the sample's order — DRAW FUNDING DETAIL (12 label/value rows), DRAW DETAIL BY BUDGET CATEGORY (9 columns, group rows, Current Draw column tinted, BUDGET total bold), BUDGET SUMMARY (Land / Soft / Hard / BUDGET + the roll-up note), REMAINING CONTINGENCY ($ and % rows), QIU DETAIL — <investment> (Metric / Current QIU Model (date) / Current Projection / Variance / Notes), APPROVAL STATUS (Order / Role / Approver / Status chip / Decision Date / Comments; the current step's row amber with "▶ n" and "◀ Current step — your approval is requested"), navy footer "Reply "Approve" or "Reject" to this email." Table layout, every style inline, no `<style>`, no images, no links, no classes. Subject: "Draw Funding Approval: Draw #n · <investment> · <amount> · Step k of 9 (<role>)".
- **Helper rules** (new): `SD_htmlEscape(text)` `…_571527`; `SD_fmtMoneyDash(value)` `…_571533` (whole dollars, dash for null/0); `SD_emailCells(texts, aligns, style, tag)` `…_571539`; `SD_emailRow(cells, aligns, bold, cellStyles)` `…_571545` (v2: leaner td style, fonts inherited from the inner table). Generator `.work/sail/gen_email.py`.
- **Process `SD Draw Approval Step`** (`0000f06e-a547-…`, no start form, editable): new PV `email` (Map) — the other 18 PVs re-sent unchanged and read back; node 4 "Derive step" gains a seventh custom output `rule!SD_buildApprovalEmail(drawId: pv!drawId, stepOrder: pv!stepOrder)` → `pv!email`; node 8 renamed "Step notification (approval email)", `Subject` = `pv!email.subject` (fallback "Draw approval requested: <stepLabel>"), `BodyHTML` = `pv!email.html` (fallback the old one-line text), `From` Process Model, `IsHTML` 1, Priority 3, **`To: pv!assignGroup` unchanged**. Read back after each update.
- **Rule `SD_getOpenTaskId`** (`…_570801`, v2, item 6): reads up to 10 report rows and returns the first with status `c2` ∈ {0 Assigned, 1 Accepted}; anything else (7 Aborted, etc.) is not a task.
- **Repo:** `BUILD_PLAN.md` (Phase 4 core complete), `TODO.md`, `CLAUDE.md` (objects, business rule, files), `.work/sail/gen_email.py` + the six new `.sail` files, `.work/sail/SD_getOpenTaskId.sail`, `.work/email/` (rendered bodies and row dumps).

**Decisions and why.**
- **One rule, one Map PV, computed in node 4.** The subject and body come from one evaluation (one set of queries), stored in `pv!email` before the register/notify/task fan-out; node 8 only reads it. If the rule ever failed, node 4 would pause by exception before any write — no half-sent state.
- **Both line groups in the detail table.** The brief names the in-this-draw lines; the sample's structure carries both groups plus the BUDGET total, and the summary needs every line anyway. The Current Draw column is tinted as the sample boxes it.
- **Gmail-lean styling.** Fonts and colour on each inner table, not on each cell: 68.4 KB → 44.9 KB for the full-size draw, well under Gmail's ~102 KB clip. No `<style>` block (Gmail strips it), no images, no links.
- **Chips as inline `<span>`s with background/colour**, the app's status palette (Approved green, In Progress blue, Rejected red, Pending grey); the current row amber `#FFF8E6`.
- **Recipient wiring untouched** (item 3): `To: pv!assignGroup`.
- **Verification draw:** draw 75 (#67, ingested, at step 1) rather than draw 66 (demo state, Elena's task 536876873 untouched). Advanced with the transition (`APPROVE`, source `BUILD`, comment "Phase 4 approval email verification (build)"), which superseded its step-1 task process 536909980 and started the step-2 process.

**Verified.**
- `SD_buildApprovalEmail(66, 3)`: `error: null`; subject "Draw Funding Approval: Draw #66 · Tamarack Hotel & Spa Vail · $2,604,252.23 · Step 3 of 9 (Asset Manager)"; "Hello Elena Marchetti,"; the 12 detail rows (Amount $2,604,252.23, Funding Date October 15, 2026, General Comments —); In this Draw 9 lines (Hard Costs … $2,490,297 … 91.9%; Operating Deficits ($21,509); All Project Contingency ($57,753)), All Other 7 lines, BUDGET $278,676,480 / $390,196,711 / — / $390,196,711 / $2,604,252 / $371,503,683 / 95.2% / $18,693,028 (the app's roll-up figures, not the sample's printed ones); Budget Summary Land / Soft $112,667 / Hard $2,491,585 / BUDGET; Remaining Contingency $1,274,757 → $1,217,004, 6.8% → 6.5%; QIU 10 rows as of 09/30/2026; Approval Status 1–9 with ▶ 3 marked; 44,678 bytes (v2). Section order equals the sample's; 0 `<style>`, 0 `<img>`, 0 `href`, 0 `class`.
- `SD_buildApprovalEmail(12, 6)` (the no-lines specimen): "Hello Robert Chen,", "No budget lines on this draw", "No contingency line on this draw", "No QIU metrics on this draw", ▶ 6 marked, 20,605 bytes, `error: null`.
- Model readbacks: PV list 19 with `email` Map; node 4 seven outputs; node 8 new name, Subject/BodyHTML expressions, `To =pv!assignGroup`, `IsHTML 1`.
- **Live send:** transition on draw 75 → `COMPLETED`, "ADVANCED to step 2" (supersede true, step write OK, next write OK). Afterwards `SD_getDrawDetail(75)`: `currentStep 2`, `activeStepProcessId 536910004` (the new step process registered itself — node 7 ran, so node 4's email evaluation succeeded), `openTaskId 536877532`, order 1 Approved 17:28:31 with the build comment, order 2 In Progress; the task report row for 536910004: task 536877532, status 0, assignees [1530] = `SD Draw Demo Approvers` (scott.thorn@appian.com, sd.accountant). The body node 4 evaluated is deterministic over those rows; `SD_buildApprovalEmail(75, 2)` rendered it again ("Hello Daniel Osei," ▶ 2 marked, order 1's comment shown, 44,718 bytes) and it is saved as `.work/email/draw75_step2.html` (+ `.txt`); section order checked programmatically against the sample.
- **Item 6:** `SD_getOpenTaskId(536909940)` → null (the aborted task 536874206 no longer returns); `SD_getOpenTaskId(536909994)` → 536876873 (Elena's live task, untouched).
- Probe rules deleted (404).

**Not verified (and why).**
- **The Send E-Mail node's own completion** — not readable over the Dev MCP or through analytics on this instance (see the staged candidate). Evidence is indirect: node 4 (the rule) and node 7 ran, the task issued, and the rule renders without error; the inbox is the proof — Scott's Gmail check (`TODO.md`), the email arrived at scott.thorn@appian.com and sd.accountant's address at ~17:28 UTC.
- **Gmail rendering** (tables, chips, the tinted column, clipping, mobile) — mailbox only.
- **Where the persona accounts' addresses point** — user attributes are not readable here; the routing table names the groups and members.
- Steps 3–9 emails not sent this phase (same node, same rule; the render for step 3 and step 6 covers the shape).

**Promotion candidates:** 2 found (Send E-Mail completion unreadable + the empty report folders; the f-string trap for generated SAIL) — listed at gate 1, none promoted. No trigger fired. Repo and user-level `appian-supplemental` unchanged.

Promotion checkpoint: current through 2026-09-22 — Phase 4: new approval email layout as HTML from live draw data.

## 2026-09-25 — Phase 5: ingestion failure path with AI template comparison

**Scope.** Dev MCP `appian` as `scott.thorn@appian.com` (member of `SD Administrators`, `SD Users`, the three step groups), so every design read and rule test here has administrator scope. Persona checks go through sail as `sd.accountant` (`~/.sail-sd.accountant`) and `sd.assetmanager` (`~/.sail-sd.assetmanager`). `appian-runtime` and `--from-devmcp` are not used. Draw 66 is not touched: Elena's task 536876873 and step process 536909994 stay open.

**Preflight.** The plan gate passes. The design surface is present (157 camelCase tools), and `listRecordTypes` returns the app's 20 types. `getDevMcpVersionInfo` reports 26.6.95 / build 20260911-210447, matching the pin. **Drift flag:** the App Market has 26.6.100. The site admin updates the plugin before a bundle download is worthwhile (downloads page `https://ny.appiancloud.com/suite/plugins/servlet/stateless/downloads`, bundle `…/lcp-mcp-bundle`). `sail --version` reports 26.6.95, matching its pin. Persona sessions: `sd.accountant` and `sd.assetmanager` are live. `alex.analyst`, `sam.supervisor` and `test.presenter` get a 500 "Site does not exist…", because they belong to other builds. `~/.sail-designer` and the default `~/.sail` hold no session. The repo and installed `appian-supplemental` are identical (v2026-09-24.2). There is no per-session ritual.

**Item 0 — bookkeeping.**
- TODO: Scott reports the Phase 4 Gmail check done: no clipping, and the tables render correctly. The item moves to Done.
- Ruling (closes Phase 4's open ruling): Gmail routing stays exactly as wired. scott.thorn@appian.com receives every step email and plays the CEO at the demo's email beat; there are no persona addresses and no recipient overrides. Recorded in `PROJECT_INSTRUCTIONS.md` (business rules), `BUILD_PLAN.md` Phase 4 and `TODO.md` Done.
- `BUILD_PLAN.md`, documentation only: Phase 5.5 (multi-document corroboration at intake) and three Phase 6 additions (email thread continuity mirrored onto the draw; low-confidence interpretation routed to a super-user exception queue, never a state change; a dollar-threshold guardrail that sends large draws to the UI).

**Capability probes (throwaway rule `zz_probeReadExcel`, `…_573121`).**
- Excel Tools `readexcelsheet(todocument(55270), 0, 0, 10)` read the clean template ingested on draw 74 in 123 ms. It returns the cells as formatted text (row 17 is the nine column headers, rows 18–33 the 16 categories, row 34 TOTAL BUDGET). The workbook's structure can therefore be read without AI.
- `a!genAiModels()` lists GPT 5.5, GPT 5.4, Claude Sonnet 4.6, Nova 2 Lite, Claude Haiku 4.5, Claude Sonnet 4.5 and Claude Sonnet 4. DocCenter's default is Haiku 4.5.
- `a!fromJson` on malformed JSON fails validation outright ("The jsonText parameter was not valid JSON"). `try()`, which DocCenter's own `AIA_ExtractJsonInner` uses, is rejected by the Dev MCP validator as an undocumented function. So the AI answers in a pipe-delimited line format that `split()` parses and that cannot throw.
- `listAiSkills` and `getAiSkill` both fail with "Unexpected error: 'type'". The Text Input skill (id 148) and the node's configuration are therefore copied from a working example: node 8 "Text Input" of DocCenter's `AIA Generic Prompt` (`0002ecfc-…`), with Input Text, Runtime Prompt, Runtime Model, Enable Extended Thinking, Usage Groups and `RemoteServiceKey` `ai_skill_generative_ai`. Docs (Execute Generative AI Skill, 26.6) confirm that Runtime Prompt replaces the skill's prompt and Runtime Model takes a model id from `a!genAiModels()`.

**Build step 1 — fields, constants, rules, gate (as the designer).**
- `SD Draw` gains `ingestionFailureReason` (`3139df20-…`) and `ingestionComparison` (`74b593a2-…`), both TEXT 4000. The readback says `VARCHAR(255)`. Measured through a Write Records node with throwaway process `zz_probeWidth`: 4,000 characters stored as 4000/4000, and 4,001 failed with "Data too long for column 'INGESTION_COMPARISON'". The fields were then cleared back to null, and the process was deleted ("Does not exist" on read). **The probe's target, draw 76, turned out to be an ingested #71 at step 1, not a build shell.** My notes were stale: draws 74–80 are reconciled #67–#72 and 81 is an Ingesting shell. The write touched only the two new, still-null columns and restored them to null. `listRecordData` afterwards shows 76's other fields and `updatedAt` (2026-09-22 18:59:27) unchanged.
- Constants: `SD_DRAW_TEMPLATE_COLUMNS` (9), `SD_DRAW_TEMPLATE_CATEGORIES` (16), `SD_DRAW_TEMPLATE_HEADER_LABELS` (12), `SD_TEMPLATE_COMPARISON_MODEL` = `appian/anthropic.claude-sonnet-4-6`.
- Rules:
  - `SD_readTemplateStructure` (Excel Tools, labels only).
  - `SD_listMinus`, `SD_joinQuoted`, `SD_diffTemplateStructure`.
  - `SD_validateIngestedTemplate`: the deterministic gate after extraction, covering no extraction instance, no budget table, missing standard columns or rows, and blank required header values.
  - `SD_getLastGoodTemplate`: investment by name; draws past ingestion; newest Budget Template row holding a document.
  - `SD_buildTemplateComparisonRequest`: baseline, diff, Runtime Prompt, Input Text.
  - `SD_checkTemplateComparison`: the gate on the AI answer.
  - `SD_curlQuotes`, `SD_splitIngestionText`.
  - `SD_buildIngestionFailureEmail`.
  - `SD_getDrawDetail` v7: exposes the two fields and `ingestionFailed`; `viewerIsAssignee` is forced false for a failed draw.
- Measured traps:
  - `readexcelsheet` returns `{success, result}`, and `length()` of `result` as returned reads 1. It is rebuilt with `a!forEach`.
  - `length()` skips both `""` and null items (`length({"a","","b"})` = 2); `count()` counts them (3).
  - `split()` keeps empty fields as nulls in position.
  - `contains()` on an empty Any Type list fails with a type error.
  - `and()` and `or()` evaluate every argument, so the guards are written with `if()`.
- **The gate, proven by gauntlet** (`.work/sail/gauntlet_SD_checkTemplateComparison.sail`):
  - Pass: the good answer, and the same answer with curly quotes.
  - Fail on the change lines, falling back to the rules text: invented, missed, doubled, extra quote, JSON/fenced, not-success, wrong rename pairing (the position check) and stray `|`.
  - Fail on the overview only, keeping the checked AI lines under standard summary wording: overview quotes a label, counts (live answer 1), a digit, restates changes (live answer 2), names an unchanged part.
  - The no-difference skip composes the rules text.
- **Live AI calls** (throwaway `zz_probeAiCompare`, a hand-built v2 structure against the clean template on draw 80, Sonnet 4.6, DocCenter's Text Input skill 148 with a Runtime Prompt): 7 calls.
  - **Change lines correct on 7/7:** the "Current Draw" → "Draw Funding This Period" rename paired correctly, "Total PTD inc. This Draw (%)" removed, "Insurance" and "Start-up/Marketing" missing, nothing invented.
  - **Overview:** runs 1 and 2 miscounted or double-described. The prompt was tightened and the gate extended (no counts, no change verbs, only parts that changed). Runs 3, 5 and 6 then passed in full; runs 4 and 7 fell to standard summary wording (a word check: "missing", then counted).
  - 4 AI actions per call; 4.7–6.4 s from request to check (5.8–8.5 s for the whole probe process). Prompt 2,868 characters plus input 1,969, about 1.2k input tokens by the 4-character rule; about 700 characters out (the node reports AI actions, not tokens).
- The skill's own inputs (Input Text, Runtime Prompt, Runtime Model, Enable Extended Thinking) are refused as "Unknown input" under `inputs` and accepted as `customInputs` (read back typed; the live calls prove they reach the skill).

**Build step 2 — pipeline and UI.**
- `SD Receive Capital Call`: 46 PVs (12 new) and nodes 31–41. The path is 31 check template → 32 Template OK? (yes → 14 Reconcile) → 33 prepare comparison → 34 differences? (→ 35 AI, or straight to 36) → 36 check comparison → 37 write the draw Ingestion Failed with reason, comparison and investment → 38 written? (no → 20) → 39 build alert → 40 Send E-Mail to `SD_DRAW_DEMO_APPROVERS_GROUP` and `SD_DRAW_ASSET_MANAGER_GROUP` (IsHTML, From Process Model, count of valid To addresses into a PV) → 41 template document row Ingestion Failed with a notes line (comparison source, AI timing and actions, recipient count) → End. Node 11's no-extraction branch and node 13 now both go to 31. `validateDesignObject`: no errors. Generator `.work/sail/gen_receive_failure.py` writes `receive_failure_payloads.json`.
- `SD_view_drawSummary` v7: a red state card in the action strip's slot (why it could not be loaded, what changed, what happens next, with a link to Receive Capital Call). For a failed draw, approval progress, Funding Detail, Budget Summary, Funding History and QIU are hidden. Draw 66 re-rendered as the designer: error null, Review & Approve strip, every section.
- `SD_page_draws` v7: status filter gains Ingestion Failed; a failed row reads "Not loaded", "Template could not be loaded · received … · resubmit via Receive Capital Call". `SD_cmp_statusTag` v2: Ingestion Failed is red.
- Docs gate: `a!richTextBulletedList` (26.6) read before the card was written.

**Build step 3 — live failure run, as `sd.accountant` via sail (`~/.sail-sd.accountant`).**
- **Run 1 (16:36:25 UTC, document 55635 → draw 82, process 38992).** Doc Center extracted instance 857 (status 2, 14 lines; its model read "Draw Funding This Period" as Current Draw and left PTD % empty, which is why the gate reads the workbook itself). Node 12 ran at 16:37:50. The failure branch wrote draw 82 **Ingestion Failed** at 16:38:02 with investment 1, the reason and the comparison (the AI's, passing the gate in full). The template row was **never marked**, so node 41 did not run.
  - Isolation, without an instance read:
    - Node 39's rule rendered draw 82's alert cleanly.
    - Node 41's notes expression evaluated cleanly with the run's values.
    - Control `zz_probeAlertSend`, node 40 copied exactly and run through `testProcessModel` as the designer: **COMPLETED**.
  - The one difference in the live run was node 40 running as INITIATOR, which is `sd.accountant`, not a member of `SD Draw Asset Managers`. **Fix: node 40 now runs as DESIGNER.** Node 41's notes line was also reworded, because the control showed `count(ac!ToValidAddresses)` = 0 for group recipients, so no recipient count is written.
  - Process 38992 is left paused at node 40 (inferred: no instance read over the Dev MCP) and is listed for cancellation in `TODO.md`. Draw 82 and its row 6616 were deleted by explicit id (the cleanup script's CSVs, children first). Absence was confirmed as the designer: `SD_getDrawDetail(82).found` false, row 6616 gone. They had 0 lines, 0 approvals and 0 QIU.
  - The control sent one extra alert, subject prefixed "[build test]", ~16:40 UTC, to the same two groups.
- **Run 2 (16:41:59 UTC, document 55641 → draw 83, process 268476890).** Node 12 at 16:43:21; draw 83 **Ingestion Failed** at 16:43:31 (investment 1). Template row 6617 **Ingestion Failed**, note "Template check failed 09/25/2026 12:43 PM. Comparison: AI (Claude Sonnet 4.6); AI call 0::00:00:04.896, 4 AI actions; alert email sent to the accountant and asset manager groups." Node 41 runs only after node 40, so **the send node completed**.
  - End to end, submit to the failure recorded: **92 s**, almost all Doc Center (81 s to node 12).
  - The AI call: **4.9 s, 4 AI actions**. Input about 4.8k characters (prompt 2,868 + input 1,969), roughly 1.2k tokens; output about 700 characters, roughly 180 tokens. Token counts are estimates by the 4-character rule, because the node reports AI actions, not tokens.
- **Accuracy test (both runs, same text):**
  - The stored comparison names all three seeded differences: "The “Current Draw” column is now headed “Draw Funding This Period”", "The “Total PTD inc. This Draw (%)” column is missing", "The “Insurance” budget line is missing", "The “Start-up/Marketing” budget line is missing".
  - Nothing else is named: no header field, no other row, no amounts.
  - The overview passed its checks and was the AI's own.
  - The footer reads "Compared with THSV_Draw67_Budget_Template.xlsx (Draw #72, received 09/22/2026) by AI (Claude Sonnet 4.6); every change listed was checked against both workbooks."
- **Break-test:** draws 82 and 83 have 0 budget lines, 0 approvals and 0 QIU rows (only their template rows), read as the designer. `SD_getOpenTaskId(268476890)` is null, and the designer's task list has no reconciliation task for either process.
- **Alert email:** re-rendered from draw 83's records (the same rows node 39 read) and saved as `.work/email/draw83_ingestion_failure.html` (8,658 bytes; 0 `<style>`, 0 `<img>`, 0 `href`, 0 `class`) with a `.txt` dump. Subject "Draw template could not be loaded: Tamarack Hotel & Spa Vail · Draw #67 (as submitted) · THSV_Draw67_Budget_Template_v2.xlsx".
- **Persona reads (sail), as `sd.accountant` and as `sd.assetmanager`, identical:**
  - Draws page row "Not loaded · Tamarack Hotel & Spa Vail · — · Template could not be loaded received Sep 25 · resubmit via Receive Capital Call · Ingestion Failed", with no YOUR ACTION. `sd.assetmanager`'s Awaiting My Action stays "1 · Draw #66 · Asset Manager step".
  - Draw 83's Summary: breadcrumb "Received template (not loaded)"; the card "Ingestion failed — this budget template could not be loaded"; both reason bullets and all four comparison bullets (YAML); the footer; "What happens next" with the Receive Capital Call link; Draw Origin's ingestion tag Ingestion Failed with the notes line; no Review & Approve, Reconcile Extraction or YOUR ACTION.
- `SD_cmp_drawFactStrip` v3: the breadcrumb for a failed draw reads "Received template (not loaded)" instead of "New draw (ingesting)", which run 1's persona read showed.

**Build step 4 — regression and cleanup.**
- **Clean template, as `sd.accountant` via sail (16:45:44 UTC, document 55647 → draw 84, process 536910222):** node 12 at 16:47:04. The Draws page showed the new row with YOUR ACTION at 16:47:18 (94 s after submit). As the designer: `SD_getDrawDetail(84)` is Ingesting with instance 859, `openTaskId` 536885220, `awaitingViewer` true, no failure texts; template row 6618 "Received" (untouched by the failure branch). The success path passes node 31/32 unchanged.
- **Draw 66 untouched:** as the designer, step 3, `activeStepProcessId` 536909994, `openTaskId` 536876873, `updatedAt` 2026-09-22 15:34:33. As `sd.assetmanager`, Awaiting My Action "1 · Draw #66 · Asset Manager step".
- **Throwaways, all deleted with absence confirmed:** `zz_probeReadExcel` (404), `zz_probeWidth`, `zz_probeAiCompare` and `zz_probeAlertSend` ("Does not exist").

**Decisions and why.**
- **Structure from the workbook, not from the AI extraction.** Doc Center's model mapped "Draw Funding This Period" onto Current Draw and simply left PTD % empty, so the extraction alone would have hidden the rename. `readexcelsheet` reads the labels deterministically, and the same read is the ground truth for the AI gate.
- **Validation placed after extraction, as briefed.** The no-extraction branch (node 11) now also goes through the check, so it produces a reason and a comparison too. Earlier write-error branches keep the Phase 3 status-only path (nodes 20/21).
- **One AI call, labels only.** The model sees both workbooks' header labels, column headings and category rows (no amounts), so it cannot talk about values. It uses DocCenter's Text Input skill with a Runtime Prompt (no skill can be created over the Dev MCP) and Claude Sonnet 4.6 (DocCenter's default is Haiku 4.5; the rename judgement is the point). The call is skipped when the layouts do not differ.
- **The gate decides, in two parts:** the change lines (facts) and the overview (summary). Facts that pass are used even if the summary fails. The footer always says which kind of text it is.
- **The failed draw keeps the investment, not the draw number.** This leaves the reconciliation collision rule untouched for the corrected resubmission.
- **Draw 82 deleted.** It was the stalled first run's incomplete artifact (template row never marked, alert never sent). Draw 83 is the specimen.

**Not verified (and why).**
- **The alert in Gmail** (rendering, clipping, mobile) is mailbox only; the checklist is in `TODO.md`. The send is proven by node 41's downstream write, not by an inbox read. Run 1's alert most likely never went out: the process stopped at the node.
- **Why the persona-run send stopped.** Inferred from the control, with no instance read. Recorded as a staged candidate.
- **Live paths not exercised:** the standard-template baseline (no earlier template), the skipped-AI path (no layout difference) and the rules-only fallback are covered by rule tests and the gauntlet only (`TODO.md` Deferred).
- **Geometry of the red card and the list row** is browser only (`TODO.md`).
- **Token counts** are estimated from characters; the node reports AI actions (4 per call), not tokens.

**Promotion candidates:** 8 staged at gate 1: persona-run Send E-Mail to a group; `ToValidAddresses` for groups; `length()`/`count()`/`split()` with blanks; `contains()` on an empty Any Type list and eager `and()`/`or()`; `a!fromJson`/`try()` at validation; AI-skill inputs as `customInputs` plus the `getAiSkill` error; the Excel Tools result wrapper; the summary-over-items method note. None promoted, because each rests on one session's observation. One trigger fired: the Phase 4 "send completion unreadable" candidate was applied and re-staged with a new trigger. The supplemental is unchanged; the repo copy and the installed copy are identical.

Promotion checkpoint: current through 2026-09-25 — Phase 5: ingestion failure path with AI template comparison.

## 2026-09-25 — Phase 5.5: multi-document corroboration at intake

**Scope.** Same session as Phase 5, same identities: Dev MCP `appian` as `scott.thorn@appian.com` (full scope: `SD Administrators`, `SD Users`, the three step groups); sail as `sd.accountant` (`~/.sail-sd.accountant`) and `sd.assetmanager` (`~/.sail-sd.assetmanager`). `appian-runtime` and `--from-devmcp` are not used. Draw 66 is untouched (Elena's task 536876873). The preflight from earlier this session stands (Dev MCP 26.6.95, sail 26.6.95, skill copies identical; App Market 26.6.100 flagged).

**Item 0 — bookkeeping.**
- TODO: Scott reports the Phase 5 browser checks done: the alert verified in Gmail, and the failed-draw card verified in the UI as the persona. Both items moved to Done.
- `BUILD_PLAN.md` Phase 5.5: the client-meeting framing is recorded (verification value, not savings on extraction labour).
- Documentation only: the final demo's intake arrives through a simulated feed (email-in or a watched drop location), narrated as the EY API/SFTP feed. Receive Capital Call is build-time tooling. Feed simulation is a Phase 6 staging item, and intake stays "a set of documents in, one draw out".

**Step 1 — the demo package (`scripts/gen_draw_package.py`, committed; the PDFs are local and gitignored).**
- The generator reads `THSV_Draw67_Budget_Template.xlsx` itself with zipfile/regex (no openpyxl or PDF library on this machine) and writes four one-page PDFs in pure Python (Helvetica, WinAnsi, uncompressed text layer) beside the templates:
  - `THSV_Draw67_PayApp_G702.pdf` (md5 efc383e6…): a G702-style application and certificate. Stonebridge Construction Group to THSV Holdings LLC c/o Vail Peak Management LLC; Application No. 14; period 10/01–10/31/2026 (funding 11/16/2026). The figures are read from the template's **Hard Costs** line: original contract sum $106,664,345.00 (initial budget); change orders $80,312,988.00; contract sum to date $186,977,333.00 (revised); completed & stored to date $171,792,118.00 (PTD $); retainage $0.00; previous certificates $169,301,821.77; **Current Payment Due $2,490,296.23** (the line's current draw); balance to finish $15,185,215.00.
  - `THSV_Draw67_PayApp_G702_mismatch.pdf` (md5 4bcaa3da…): identical except **Current Payment Due $2,527,796.23** (+$37,500.00).
  - `THSV_Draw67_Invoice_AlderFinch.pdf` (md5 7637859c…): Alder & Finch Architects, LLP, invoice AF-2026-1087 dated 10/31/2026; three items summing to **$59,582.00** = the **A&E - Architectural** line's current draw. The generator names that line, so the tie target is unambiguous.
  - `THSV_Draw67_LienWaiver_Conditional.pdf` (md5 6415b9f9…): a conditional waiver and release on progress payment from Stonebridge, through 10/31/2026. It states the check amount, but no figure is read from it.
- **Interpretation recorded:** "the Hard Costs current draw subtotal" is taken as the template's **Hard Costs line** ($2,490,296.23), the GC's contract line. The Hard category-group roll-up would be $2,491,584.23, because it includes FF&E ($1,288), which a GC pay application does not carry.
- Checked by rendering each PDF with `sips`, and the dollar figures by reading each text layer.

**Step 2 — reading the supporting documents (built and tested as the designer).**
- **Fields:** `SD Draw Document` `extractedAmount` (DECIMAL), `extractedParty`, `extractedReference` (TEXT); `SD Draw` `corroborationSummary` (TEXT 1000, readback 255; the summary is kept ≤ 250 characters by the rule), `corroborationState` (TEXT). UUIDs in `refs.py` and `CLAUDE.md`.
- **Constants:** `SD_DOCUMENT_READING_MODEL` (`…_573531`) = `appian/anthropic.claude-sonnet-4-6`; `SD_PAY_APP_TIE_CATEGORY` (`…_573537`) = "Hard Costs".
- **Rules** (`gen_corroboration.py`): `SD_supportingDocumentPrompt` (`…_573543`: four lines TYPE / PARTY / REFERENCE / AMOUNT, digits only, never compute), `SD_parseSupportingDocReading` (`…_573549`: the gate — unknown type or failed call → Backup / Not read; an amount only for Pay Application and Invoice, only in a valid shape, > 0), `SD_getSupportingDocuments` (`…_573555`), `SD_corroborateDocuments` (`…_573561`, v2), `SD_getDrawCorroboration` (`…_573567`). **Gauntlet** `gauntlet_SD_corroboration.sail`: P1–P9 and C1–C7 pass. v1 lost the trailing parts of the C5/C6 summaries (the `[[]]` / `len()` trap, staged); v2 takes lengths per item.
- **Process `SD Read Supporting Documents`** (`0000f073-a7ee-8000-25b1-7f0000014e7a`, `gen_read_supporting.py`): a loop over the documents (register the row Received → AI node → gate → rewrite the row), all nodes as DESIGNER, ceiling 20. The AI node's Input Document had to be sent typed `DOCUMENT` (untyped it read back Text). Validator clean. **Break-test** (`testProcessModel`, process 268476902): an xlsx handed to the PDF skill returned "Unsupported file type" and the row was written Backup / Not read; the test row 6619 was deleted, absence confirmed.
- **Pipeline** `SD Receive Capital Call` (`gen_receive_corroboration.py`): 48 PVs (+ `supportingDocuments`, `corroboration`, read back); nodes 42 XOR "Supporting documents?" → 43 async subprocess → 9, and 44 "Corroboration (rules)" → 45 Write "Draw corroboration" → 23; 8 → 42 and 22 → 44 rewired; node 43's mappings read back `pv!drawId` / `pv!supportingDocuments`; `validateDesignObject` clean.

**Step 3 — the pages.** Docs-search consulted before each layout edit (file upload `fv!files` and `maxSelections`, `a!submitUploadedFiles` with several upload fields, read-only grid column components and widths, `a!refreshVariable` intervals, `a!sideBySideLayout` parameters).
- `SD_page_receiveCapitalCall` **v8**: supporting-document upload slots (one PDF per field; see the finding below), confirmation text "N supporting documents are being classified and read…", `supportingDocuments` in the process parameters, Receive Another resets the slots. v5–v7 were the multi-file field and its accumulating `saveInto` (superseded).
- `SD_form_reconcileExtraction` **v4**: the corroboration section (grid, chips, the waiver tag, the neutral line, Refresh while any document is being read, 30 s refresh). Rendered as the designer for draw 66 (two seeded Backup rows: grid branch, `Type` data `["Backup","Backup"]`) and draw 75 (neutral branch), `error: null` both.
- `SD_getDrawDetail` **v8** (+ the two fields), `SD_view_drawSummary` **v8** (Draw Origin's SUPPORTING DOCUMENTS line, shown only when `corroborationSummary` is set; draw 75 re-rendered unchanged), `SD_cmp_statusTag` **v3** (Read green, Not read amber). The Documents tab needed no change.

**Step 4 — live verification (sail as `sd.accountant`, readbacks as the designer).**
- **First run failed, and the failure is the finding (draw 85, 16:13 local).** The page then had one multi-file field. sail's three uploads left only the last PDF in the field (plain `saveInto`); with an appending `saveInto` (v7) the field showed all three, but after Receive only the last existed (55685); 55683 and 55684 "Document Does Not Exist". The pipeline ran on unblocked (extraction 860, reconciliation task 16354) — the template path never waits on the documents, as designed — and the reading child wrote nothing. Fixed by upload slots (v8). Draw 85 deleted with its row 6620; its pipeline 39011 and the child are listed for cancellation.
- **Stale shells cleared so the new draw could be opened:** four Ingesting rows all read "New draw" and sail refused the ambiguous link. Draws **81, 84, 85** had only their template rows (6615, 6618, 6620; no lines, approvals or QIU, read back); deleted by explicit id children-first through `seed_draw66.py --cleanup-ingested` (which refuses seeded ids); absence confirmed (`SD_getDrawDetail(84).found` false; child lists empty). The standing TODO reset names the session as owner. Their pipeline instances hold open tasks (9464, 536885220, 16354) → `TODO.md` cancellation list.
- **Clean package (draw 86, submitted 16:18:17 local; template 55692 + PDFs 55693–55695, all present after Receive):** confirmation "3 supporting documents are being classified and read…". Rows written by the child: Pay Application Read $2,490,296.23 · Stonebridge Construction Group · 14 (**7.9 s, 3 AI actions**); Invoice Read $59,582.00 · Alder & Finch Architects, LLP · AF-2026-1087 (**6.1 s, 2**); Lien Waiver Read · Stonebridge (**6.7 s, 2**) — all three before the reconciliation task (task 268444448, 79 s after submit). As `sd.accountant`: the Summary strip "Doc Center extraction is ready for your reconciliation"; the Documents tab four rows with types and the notes lines. The form rendered as the designer with the task's inputs (rebuilt by `SD_getExtractionForReconcile(861)`): "3 with the package", Pay Application $2,490,296.23 vs Hard Costs · current draw $2,490,296.23 green **Ties**; Invoice $59,582.00 vs A&E - Architectural · current draw $59,582.00 green **Ties**; Lien Waiver green **Lien waiver received**; no waiver tag. Completed with `completeTask` as the designer (the form's own serialisation, produced by a throwaway rule copying the Confirm `saveInto`; draw number 73 under the collision rule; the read-only `linesJson` input sent as `[]`, the commit reads `confirmedLinesJson`). Readback: #73 In Progress at step 1 (Priya Raman), `corroborationState` **TIES**, summary "3 supporting documents · pay application ties · invoice ties · lien waiver received". **As `sd.accountant`:** Draw Origin "SUPPORTING DOCUMENTS · Package ties (#E6F4EC/#1E7E46) · 3 supporting documents · pay application ties · invoice ties · lien waiver received"; amount verification "current draw lines sum to $2,604,252.23"; Documents tab 4 rows (template Extracted & Confirmed).
- **Mismatch package (draw 87, 16:25:43; template + mismatch pay application, no waiver):** Pay Application Read $2,527,796.23 (6.8 s, 3 AI actions). Form (designer render, instance 862 — header and lines identical to 861's, compared in a throwaway rule): amber (#FDF3E0/#92600A) **Does not tie: $2,527,796.23 vs $2,490,296.23** and the amber **No lien waiver received with the pay application**; Confirm enabled. Confirmed as #74: `corroborationState` **ATTENTION**, summary "1 supporting document · pay application does not tie ($2,527,796.23 vs $2,490,296.23) · no lien waiver with the pay application". As `sd.accountant`: Draw Origin chip amber **Needs attention** with that line.
- **Template only (draw 88, 16:28:47):** confirmation "No supporting documents came with this package."; only the template row; the form's section reads "none with this package" and the neutral "No supporting documents came with this package; the template is reconciled on its own." (no grid, no amber); the rest unchanged (Ties ✓, #75 prefilled with the collision chip). Confirmed as #75 In Progress, `corroborationState` NONE, "No supporting documents received"; as `sd.accountant` the chip is grey **None received**.
- **Failure regression (draw 89, 16:29:27; v2 template + pay application + lien waiver):** both documents read (6.4 s / 3; 5.3 s / 2); the template still took the failure branch: **Ingestion Failed**, the same two reasons and four comparison lines as Phase 5 (baseline now "Draw #74, received 09/25/2026"), no reconciliation task, template row 6628 Ingestion Failed with "alert email sent…" (node 41 after node 40 — the alert was sent; one more alert in the inbox). Corroboration is not written on a failed draw (nodes 44/45 follow Confirm only). Draws page as `sd.accountant`: "Not loaded" rows 83 and 89.
- **Draw 66 untouched** (designer): step 3, `activeStepProcessId` 536909994, `openTaskId` 536876873, `updatedAt` 2026-09-22 15:34:33. As `sd.assetmanager`: Awaiting My Action "1 · Draw #66 · Asset Manager step".
- **Throwaways:** `zz_probeCorroboration` (`…_573573`) and `zz_probeReports` (`…_573731`) deleted, 404 confirmed.

**Decisions and why.**
- **Reading is asynchronous and separate** (a child process), so the template path can never be blocked and a no-documents package is untouched (node 42's default path). Measured: the first, broken run still produced its reconciliation task on time.
- **One AI call per PDF, gated; corroboration is rules.** The model classifies and reads one figure; it never sees the template, so a tie is independent evidence that the figure was read right. The chips are computed over the lines as the accountant edits them; the draw's stored result is computed again over the committed lines.
- **Upload slots instead of one multi-file field** — the measured discard of replaced temporary uploads (finding above). One file per field works for sail and the browser alike.
- **The tie target is the Hard Costs line**, not the Hard group roll-up (Step 1 interpretation, now `SD_PAY_APP_TIE_CATEGORY`).

**Not verified (and why).**
- **The accountant's own Confirm from the task** — sail cannot open a task (staged candidate reproduced); completed over the Dev MCP as the designer, so the template rows read "confirmed by Scott Thorn". The form's content was read from designer renders with the tasks' real inputs, not as the persona. Browser checklist in `TODO.md`.
- **Geometry** of the upload slots, the corroboration grid and chips, the Draw Origin line and the Documents tab; PDF download as the persona — browser only (`TODO.md`).
- **The browser's behaviour with the old multi-file field** was never measured; the slots make it moot.
- **Live "no matching line", Backup and "Not read" paths** — gauntlet and break-test only (`TODO.md` Deferred).
- **Token counts** — the node reports AI actions (2–3 per document), not tokens.

**Promotion candidates:** 3 new staged at gate 1 (replaced uploads discarded / sail's single-file upload; the `[[]]` and `len()` misalignment; sail and repeated link labels); 2 triggers fired (AI-skill `customInputs` confirmed on a second skill and extended with the typed document input — proposed for promotion at the next template sync, not promoted here; sail and task links reproduced). None promoted; the supplemental is unchanged and the repo and user-level copies are identical.

Promotion checkpoint: current through 2026-09-25 — Phase 5.5: multi-document corroboration at intake.

## 2026-09-25 — Phase 5.6: Doc Center classification for supporting documents, extraction on pay applications only

**Scope.** Same session as Phases 5 and 5.5, same identities. Dev MCP `appian` as `scott.thorn@appian.com` (full scope: `SD Administrators`, `SD Users`, the three step groups); every readback below ran under it. sail as `sd.accountant` (`~/.sail-sd.accountant`) and `sd.assetmanager` (`~/.sail-sd.assetmanager`). `appian-runtime` and `--from-devmcp` not used. Draw 66 untouched. DocCenter (`81997754-651d-4840-9385-128c04dc7fa5`) is read and its data tables written as a dependency; the out-of-scope client app is not touched.

**Step 0 — ruling recorded.** `PROJECT_INSTRUCTIONS.md` Business rules and `BUILD_PLAN.md` Phase 5.6 now carry the document handling architecture:
- Doc Center classification types every supporting document.
- Extraction runs only where a figure drives a control (the pay application's Current Payment Due).
- Invoices and lien waivers are typed, filed and presence-checked, never read.
- Generative AI skills are kept for language tasks. Phase 5.5's prompt-based typing was interim.

**Capability reading (before any write).** Doc Center has classification as data, parallel to extraction:
- `AIA Classification Model` → `AIA Classification Model Version` (role, instructions, llm, confidenceThreshold, useVision, allowMultipleOutputs, status) → `AIA Classification Model Version Category` (name, description, sortOrder).
- It records results as `AIA Classification Instance` rows (classification, confidence, reasoning, aiActions, statusId, testInstance), and runs through `AIA Classification Run Model Version` (`5c825cfa-…`; parameters document, modelKey or modelVersionId, isDocumentTestCase).

The model type:
- All six classification models on the instance are type "Generative AI". The create wizard (`AIA_ClassificationModel_Sub_ModelDetails`) offers no type choice. Extraction, by contrast, lists "Trained Model" among its types.
- `AIA_Classification_GeneratePrompt` builds the classifier's prompt from the version's role, its categories and their descriptions, and its instructions.
- On this instance, "training" a Doc Center classification model therefore means:
  - categories and descriptions;
  - labelled test instances (`isDocumentTestCase`), reconciled so Doc Center measures accuracy;
  - optional self-learning suggestions from reconciled instances.
- It does not mean fitting weights. Recorded plainly so nobody reads "trained" as an ML fit.

Four of the six models carry an "Other" catch-all category, Doc Center's idiom for unrecognised documents; this model follows it.

The upload path: `uploadDocument` doubles bytes above 0x7F (`reference/mcp-capability-boundaries.md`). The generated PDFs are ASCII except the optional binary-marker comment on line 2, so ASCII-only PDFs can be placed on the instance over the Dev MCP and checked by size.

**Step 1 — training set (`scripts/gen_training_set.py`, committed; files local, `training/` and `*.pdf` gitignored).**
- **Contents:**
  - 8 pay applications (three layouts: banded G702-style, ruled "Contractor's Application for Payment", compact "Payment Application"; retainage 0/5/10 %).
  - 8 invoices (FF&E, MEP engineering, materials testing, landscape, interiors, security, signage, permits; three layouts).
  - 8 lien waivers (conditional and unconditional, progress and final, GC and subcontractor claimants; three layouts).
  - All with distinct parties, projects, amounts, reference numbers and dates. `training/manifest.csv` holds file, label and figure.
- **Junk specimen:** `THSV_Junk_UtilityNotice.pdf` (a utility service-interruption notice for the hotel), kept at the repo root, outside the training set.
- **Deterministic:** static lists, no randomness.
- **ASCII:** `write_pdf(..., ascii_only=True)` drops the binary-marker comment, so every file is pure ASCII (checked: 0 bytes above 0x7F in all 25 files). The four demo PDFs keep their marker; their md5s are unchanged.
- **Sizes:** 2,582–5,351 bytes; 87,289 bytes for the 24.

**Step 2 — Doc Center models (DocCenter data rows, written with `insertRecordData`, the same way as extraction model 85).**
- **Classification model 7 `sdDrawSupportingDocuments`** ("SD Draw Supporting Documents", type Generative AI, AI log on, self-learning off):
  - Version 8: Published, confidenceThreshold 80, text mode, single output, Doc Center's default LLM. The instruction line says "Use Other for any document that is not one of the listed types".
  - Categories 31 Pay Application, 32 Invoice, 33 Lien Waiver, 34 Other, each with a description.
- **Extraction model 86 `sdPayApplication`** ("SD Pay Application", Generative AI):
  - Version 143, section 224.
  - Fields 3636 `contractorName`, 3637 `applicationNumber`, 3638 `currentPaymentDue` (Text, "exactly as printed").
  - The instruction says not to calculate or reformat.
- **First live classification** (LW03, document 55730, test instance 58, via `testProcessModel` on `AIA Classification Run Model Version` as the designer):
  - Verdict "Lien Waiver", status 3, 3 AI actions.
  - The AI log: one call, 6.6 s, `claude-haiku-4-5` (Doc Center's default), TEXT mode.
  - ≈38 s from instance creation to the saved outcome; Doc Center's own orchestration takes the rest.
  - **No confidence is returned:** the instance's confidence is null and the response carries only classification and reasoning, even with a threshold set.
- **First live extraction** (demo pay application, document 55693, instance 867):
  - contractorName "Stonebridge Construction Group", applicationNumber "14", currentPaymentDue "$2,490,296.23".
  - Status 2, 3 AI actions.
- **Training upload:**
  - The 24 files went to a new knowledge folder `SD Draw Classification Training` (`…_574063`, under `SD Artifacts`) with `uploadDocument`. LW03 was uploaded by the session; the other 23 by a background agent under the same Dev MCP identity, with no other instance calls.
  - Every stored size equals the local size, read back by a throwaway rule: 24/24.
  - The labels are in the document descriptions ("Label: Invoice").
  - Document ids: PA01–PA08 55736, 55738, 55741, 55742, 55744, 55745, 55747, 55748; IN01–IN08 55749, 55750, 55752, 55753, 55754, 55755, 55759, 55765; LW01–LW08 55766, 55768, 55730, 55770, 55771, 55772, 55773, 55774.
- **Training run:**
  - A throwaway `zz_trainSupportingDocClassifier` dispatched the other 23 as asynchronous test instances (`isDocumentTestCase` true). Process 268476953 dispatched all 23 in 14 s.
  - Instances 58–81: **24/24 classified correctly** (8/8 pay applications, 8/8 invoices, 8/8 lien waivers), status 3, 2–3 AI actions each.
  - Reconciled by direct write of the fields a correct, override-free reconciliation sets (statusId 4, accuracy 1, reconciledBy/On, ids 58–81 listed explicitly).
    - Doc Center's `AIA Classification Reconcile Instance` / `Save Results` take a full instance record as input, which the Dev MCP cannot pass.
    - With self-learning off, no downstream trigger is skipped.
  - Readback of version 8 as the designer: correctCount 24, instanceCount 24, accuracyAvg 1.0, bucket "High", totalAiActions 62.

**Step 3 (part) — rules and gates (`.work/sail/gen_classification.py`).**
- **Rules:**
  - `SD_getSupportingDocClassification(document)` (`…_574253`)
  - `SD_gateSupportingDocClassification(classification, minConfidence)` (`…_574259`): status 3/4/6 only; the verdict must be exactly Pay Application, Invoice or Lien Waiver; a reported confidence must reach the minimum; anything else → Backup with a reason.
  - `SD_getPayApplicationExtraction(document)` (`…_574265`)
  - `SD_gatePayApplicationExtraction(extraction)` (`…_574271`): status 2/4/6; the printed amount must be digits with at most one point and 2 decimals, and greater than 0.
  - `SD_supportingDocNotes(...)` (`…_574277`): the treatment line.
- **Constants:**
  - `SD_SUPPORTING_DOC_CLASSIFICATION_MODEL_KEY` (`…_574228`) = sdDrawSupportingDocuments
  - `SD_PAY_APPLICATION_EXTRACTION_MODEL_KEY` (`…_574234`) = sdPayApplication
  - `SD_CLASSIFICATION_MIN_CONFIDENCE` (`…_574240`) = 80
- **Gauntlet** `.work/sail/gauntlet_SD_classificationGates.sail`: 20/20 pass (G1–G10, E1–E10).
  - The first run showed 3 false failures from the gauntlet's own `tostring()` of a Decimal (7 significant digits, the staged trap); it compares with `fixed(…, 2, true)` now.

**Step 3 (rest) — the processes, corroboration and the display.**
- **`SD Classify Supporting Document`** (`0000f073-d1d7-8000-25be-7f0000014e7a`, new; `gen_classify_worker.py` → `classify_worker_payload.json`):
  - The per-document worker. Parameters `drawId`, `doc`, `docRowId`; model keys default from the two constants, so rewiring is one constant change.
  - Nodes: Prepare (`startedAt`) → subprocess **sync** to `AIA Classification Run Model Version` → verdict script (`classifiedAt`, the gated verdict) → XOR "Pay application?"
    - Yes → subprocess **sync** to `AIA Extraction Run Model Version` → figures script (`extractedAt`, gated figures) → Write **Classified and read**.
    - No → Write **Classified only** / **Not classified** (type from the verdict, figures null).
  - Every node runs as DESIGNER. `validateDesignObject` clean.
- **`SD Read Supporting Documents`** (`0000f073-a7ee-…`) is now the dispatcher:
  - Nodes 9–11 (the 5.5 AI call, its gate and its write) removed.
  - Node 6 registers the row "Being classified by Doc Center".
  - New node 14 starts the worker **asynchronously** per document, so a package's documents are classified in parallel.
  - PVs trimmed to what the loop uses. `validateDesignObject` clean.
- **Why a worker per document:** Doc Center's orchestration adds roughly 45 s around each LLM call (measured below). A serial loop would make a four-document package take about four minutes; in parallel it settles in the time of its slowest document.
- **`SD_corroborateDocuments` v5** (`…_573561`; `gen_corroboration.py`):
  - The pay application tie is unchanged.
  - Invoice → "Received · filed as Invoice" (grey, no figure, no tie). The invoice line-match is removed.
  - Lien Waiver → "Lien waiver received".
  - Backup / Not classified → "Received · not classified" (grey, no warning).
  - A row still Received → "Being classified" (grey); the state reads ATTENTION until it settles.
  - Summary parts: "invoice filed", "lien waiver received", "N not classified", "N still being classified". New state **RECEIVED** (documents present, none needing a tie).
  - Gauntlet `gauntlet_SD_corroboration.sail` rewritten: C1–C8, 8/8 pass. The 5.5 parse specimens retired with the parser.
  - Two defects found by the gauntlet and fixed before deploy:
    - the rule counted pending rows by type; it now counts settled rows only, and C5 uses a real pending row;
    - the gauntlet's own invoice-figure check hit the `[[]]` trap; it now uses `sum()` of 1/0.
- **Display.** **Gate missed:** the §5 docs-search gate was *not* run before these four edits (checked against the session transcript). Two of them are colour changes (new status-tag mappings and the Package received chip), so the gate applied. It was run afterwards, before verification closed:
  - `a!tagItem` `backgroundColor` / `textColor` accept any valid hex. `a!richTextItem` `color` accepts any valid hex. The deployed values are within the documented vocabulary, and every tag rendered with its hex in the persona reads below.
  - The same page states that **a tag displays at most 40 characters and truncates longer text, showing it in full on hover**. This finding predates 5.6 but surfaced now. Three amber tags on the reconciliation form exceed 40 characters:
    - "Does not tie: $2,527,796.23 vs $2,490,296.23" (44, Phase 5.5);
    - "No lien waiver received with the pay application" (48, Phase 5.5);
    - "Submitted as #67, already on file — renumbered to next in sequence" (66, Phase 3).
  - Truncation is geometry, so sail cannot see it. It goes to the browser checklist with a proposed fix; no change was made this phase. Both figures of a mismatch also sit in the grid's Document figure and Template figure columns, so the content is on the form either way.
  - The edits:
    - `SD_cmp_statusTag` **v4**: Classified and read / Classified only green; Not classified amber.
    - `SD_form_reconcileExtraction` **v6**: the subheading reads "typed by Doc Center; the pay application is read and tied out against the lines above".
    - `SD_page_receiveCapitalCall` **v9**: the confirmation copy says Doc Center classifies each PDF and only the pay application is read.
    - `SD_view_drawSummary` **v9** (`gen_view_summary.py`): the green **Package received** chip for state RECEIVED.
    - The Documents tab needed no change: it already shows each row's status tag and notes line.
- **Retirement:**
  - `getObjectDependents` showed only the application for each of `SD_supportingDocumentPrompt` (`…_573543`), `SD_parseSupportingDocReading` (`…_573549`) and the constant `SD_DOCUMENT_READING_MODEL` (`…_573531`).
  - All three were deleted; each now returns 404.
  - Their `.sail` files were removed from the repo.

**Step 5 — live verification.** Packages were driven through sail as `sd.accountant` (`~/.sail-sd.accountant`): intake page, Draws page, Summary, Documents tab. Rows, tasks and draw state were read back as the designer. Each reconciliation form was rendered as the designer with the task's real inputs:
- the extraction instance was found by document id;
- its header and lines were confirmed identical to instance 863 by a throwaway rule (Doc Center's cache on the same workbook).

Each task was completed with `completeTask` as the designer with the form's own serialisation. The draw number is the one the collision rule prefilled.
- **Clean package — draw 92, confirmed as #77.**
  - Submitted 19:08:22 local (template 55855; PDFs 55856–55858). Confirmation: "3 supporting documents are being classified by Doc Center; a pay application is read and tied out against the template on the reconciliation task."
  - Worker rows:
    - Pay Application — **Classified and read**: $2,490,296.23 · Stonebridge Construction Group · Application No. 14; classified 52.2 s / 3 AI actions, read 70.2 s / 3.
    - Invoice — **Classified only**, 48.5 s / 3, no figures.
    - Lien Waiver — **Classified only**, 49.1 s / 3.
  - Reconciliation task 536889071 was issued 81 s after Receive, before the pay application had finished reading. The form covers that case with "Being classified" and Refresh, as the junk run showed live below.
  - As `sd.accountant` while Ingesting:
    - the Summary strip read "Doc Center extraction is ready for your reconciliation";
    - the Documents tab listed 4 rows: statuses Received / Classified and read / Classified only ×2, tags green #E6F4EC/#1E7E46, each with its notes line.
  - Form, settled: "3 with the package · typed by Doc Center; the pay application is read and tied out against the lines above".
    - Pay Application: $2,490,296.23 "Current payment due" vs "Hard Costs · current draw", green **Ties**.
    - Invoice: grey **Received · filed as Invoice** (#EEF1F5/#64748B), no figure.
    - Lien Waiver: green **Lien waiver received**.
    - Draw number #77 prefilled, amber renumbered chip.
  - Readback: `corroborationState` **TIES**, summary "3 supporting documents · pay application ties · invoice filed · lien waiver received", In Progress at step 1.
  - As `sd.accountant`: Draw Origin green **Package ties** with that line.
- **Mismatch package — draw 93, confirmed as #78.**
  - Submitted 19:13:45 (template 55876 + the mismatch pay application 55877, no waiver).
  - Worker row: Classified and read, $2,527,796.23, classified 53.9 s / 4 AI actions, read 64.4 s / 3.
  - Doc Center's own classification instance (85) ran from 23:13:56.3 to 23:14:04.3, about 8 s. Its reasoning names the document "a G702-style contractor's application and certificate for payment". Task 536889333 was issued 82 s after Receive.
  - Form:
    - amber **Does not tie: $2,527,796.23 vs $2,490,296.23** (#FDF3E0/#92600A), with both figures also in the Document figure and Template figure columns;
    - the amber **No lien waiver received with the pay application**.
  - Readback: **ATTENTION**, "1 supporting document · pay application does not tie ($2,527,796.23 vs $2,490,296.23) · no lien waiver with the pay application".
  - As `sd.accountant`: amber **Needs attention** with that line.
- **Package with the junk PDF — draw 94, confirmed as #79.**
  - Submitted 19:17:42: template 55888, the three clean PDFs 55889–55891, and `THSV_Junk_UtilityNotice.pdf` 55892.
  - Junk row: Backup / **Not classified**. Notes: "Not classified by Doc Center (classified as Other; sdDrawSupportingDocuments) · 50.0 s · 3 AI actions · filed as Backup". Doc Center's reasoning calls it "a customer notice … regarding a scheduled service interruption" and quotes "It is not a bill".
  - The other rows: pay application 51.6 s + 67.3 s ($2,490,296.23); invoice 53.2 s; waiver 51.6 s.
  - **Live pending state:** a form render during classification showed:
    - the pay application as grey **Being classified**, with the Refresh link;
    - invoice filed, waiver received;
    - the junk as grey **Received · not classified**.
  - Settled render: green **Ties**, filed, received, grey not-classified; no amber and no Refresh. Task 268450368 was issued 77 s after Receive.
  - Readback: **TIES**, "4 supporting documents · pay application ties · invoice filed · lien waiver received · 1 not classified", In Progress at step 1 with its step task. Nothing downstream broke.
  - As `sd.accountant`: green **Package ties** with that line. Documents tab: 5 rows, the junk amber **Not classified** with its notes (the only warning, on its own row), and amount verification "current draw lines sum to $2,604,252.23".
- **Template only — draw 95, confirmed as #80.**
  - Submitted 19:21:34. Confirmation: "No supporting documents came with this package."
  - Only the template row was written. Task 536891450 was issued 84 s after Receive.
  - Form: "none with this package" and the neutral "No supporting documents came with this package; the template is reconciled on its own." No grid, no amber.
  - Readback: **NONE**, "No supporting documents received".
  - As `sd.accountant`: grey **None received**.
- **v2 failure regression — draw 96.**
  - Submitted 19:24:37: `THSV_Draw67_Budget_Template_v2.xlsx` 55915, plus the clean pay application 55916 and the lien waiver 55917.
  - The supporting documents were classified independently:
    - Pay Application: Classified and read, $2,490,296.23; 50.0 s + 68.8 s.
    - Lien Waiver: Classified only, 54.3 s.
  - The template still took the failure branch: **Ingestion Failed** with the same two reasons as Phase 5 (missing columns "Current Draw" and "Total PTD inc. This Draw (%)"; missing lines "Insurance" and "Start-up/Marketing").
  - Template row 6649: Ingestion Failed, "Comparison: AI (Claude Sonnet 4.6); AI call 0::00:00:05.298, 4 AI actions; alert email sent…". The alert was sent, so one more alert is in the inbox.
  - No reconciliation task: the designer's task total moved only by the completed task and draw 95's new step task. Corroboration is not written on a failed draw, as designed.
  - As `sd.accountant`: the Draws page has four "Not loaded · Template could not be loaded … resubmit via Receive Capital Call" rows (83, 89, 91, 96).
- **Draw 66 untouched** (designer): In Progress at step 3, `activeStepProcessId` 536909994, `openTaskId` 536876873, `updatedAt` 2026-09-22 15:34:33.750. As `sd.assetmanager` via sail: "AWAITING MY ACTION 1 · Draw #66 · Asset Manager step · today", #66 first with YOUR ACTION.
- **Throwaways:**
  - `zz_probeTraining` (`…_574076`): deleted, 404.
  - `zz_trainSupportingDocClassifier` (`0000f073-d214-…`): deleted; the read returns "Does not exist: Process Model" (HTTP 500 rather than 404).
  - `zz_probeAia` (`…_574097`): deleted, 404. Every throwaway created this phase (`getObjectDependents` showed only the application for each) is gone.

**Time and cost per document: 5.6 against 5.5's combined call.** All figures are worker-measured and written in the notes line: seconds from the worker's start to the Doc Center subprocess returning, and AI actions from Doc Center's instance.

| | 5.5 combined call (one AI skill call: type + read) | 5.6 classification (Doc Center) | 5.6 pay application extraction (Doc Center) |
|---|---|---|---|
| Seconds per document | 5.3–7.9 AI-call time (n = 10 live: draws 86, 87, 89, 90, 91) | 48.5–54.3 (n = 10 live: draws 92, 93, 94, 96) | 64.4–70.2 (n = 4 live) |
| AI actions per document | 2–3 (pay application 3, invoice 2, waiver 2) | 3 (one run 4) | 3 |
| Model | Claude Sonnet 4.6, chosen in the constant | Doc Center's default for Generative-AI classification (Haiku 4.5 on this instance) | Doc Center's extraction default |
| Clean package, 3 PDFs | 7 AI actions; read one after another, ~21 s of AI time, ~25 s wall | 3 × 3 = 9 AI actions for classification, + 3 for extraction = 12; in parallel, settled ~123 s after the rows were registered | |

- **Where the time goes.** Doc Center's LLM call is short: instance 85 went from created to classified in 8 s. The rest of each ~50 s is Doc Center's own orchestration around it (the run process, the AI log, the synchronous subprocess returning). Extraction adds another ~65 s on the pay application.
- **Cost.** 5.6 spends about 1.7× the AI actions of 5.5 on the same package (12 against 7). Invoices and waivers still cost one classification each, 3 actions, where 5.5 spent 2 to type and read them. The added cost buys typing by a governed, measured Doc Center model (24/24 on the training set) instead of a prompt.
- **Latency.** Documents run in parallel. A package settles about 2 minutes after Receive, against about 25 s in 5.5. The reconciliation task arrives at ~80 s, so the first ~40 s of a pay application's corroboration shows "Being classified" with Refresh.

**Close-out readback** (designer). Each deployed expression was read with `getInterface` / `getExpressionRule` and diffed against the repo's `.sail` copy: identical for all ten, trailing whitespace aside.
- `SD_cmp_statusTag` v4
- `SD_form_reconcileExtraction` v6
- `SD_page_receiveCapitalCall` v9
- `SD_view_drawSummary` v9
- `SD_corroborateDocuments` v5
- the five 5.6 rules, v1 each

The three 5.6 constants read back "sdDrawSupportingDocuments", "sdPayApplication" and 80. The process models were validated clean when built; this session has no process-instance read.

**Decisions and why.**
- **Built over the Dev MCP; no manual Doc Center step.** Doc Center's classification models are data rows (model → version → categories). The Dev MCP writes them the same way as extraction model 85. "Training" on this instance means:
  - labelled test instances;
  - reconciliation, which records accuracy.

  So the brief's fallback path (Scott clicks it together, the pipeline waits on a constant) was not needed. The constants exist anyway, so rewiring to another model is one change.
- **What "trained" means here, stated plainly.** The only classification type on this instance is Doc Center's **Generative AI** type. Its prompt is built from the category names and descriptions and the version's instructions. Test instances measure accuracy (24/24); they do not fit weights. An ML-trained classification type does not exist on this instance.
- **An "Other" category**, following Doc Center's own idiom. It gives the model a way to say "none of these", which the gate turns into Backup / Not classified. Without it the model has to pick one of the three.
- **A worker per document, started asynchronously.** Each Doc Center call carries ~40–45 s of orchestration, so parallel is the only way a package settles in about 2 minutes. The template path still never waits on documents.
- **Extraction only on a Pay Application**, per the ruling. Invoice and waiver rows carry no figures. `extractedAmount`, `extractedParty` and `extractedReference` stay null for them, and the invoice line-match is gone, not hidden.
- **The corroboration state for a package with only filed documents is RECEIVED** (green "Package received"), not TIES: nothing was tied, and nothing needs attention.
- **The tag-length finding (40 characters) is reported, not fixed.** It predates 5.6. The fix is a wording change to three chips, which should be ruled with the browser check in hand rather than guessed. Both mismatch figures are also in the grid columns.

**Not verified (and why).**
- **The accountant's own Confirm.** sail cannot open a task (reproduced again: "Reconcile Extraction" is listed as `<display>`). Every Confirm ran over the Dev MCP as the designer, so the template rows read "confirmed by Scott Thorn". The form content was read from designer renders with each task's real inputs.
- **Geometry.** Chip truncation at 40 characters (documented; see the finding above), the corroboration grid, the Documents tab's notes column width, and the intake copy. These are browser-only (`TODO.md`).
- **The low-confidence branch live.** Doc Center returns no confidence on this instance, so "low confidence → Backup" is proven only by the gauntlet (G5, G6). Live, only "Other" reached Backup.
- **A classification error or extraction error live** (instance status 9 / 5). Covered by the gates' gauntlet only (G4, G10, E5). No live specimen forces Doc Center to error.
- **Cost in currency or tokens.** Doc Center reports AI actions, not tokens. The comparison above is in AI actions and seconds.
- **The persona's document download** (S9): browser only.

**Promotion candidates.**
- **4 new, staged at gate 1:**
  - Doc Center Generative-AI classification returns no confidence;
  - Doc Center orchestration latency around a synchronous run;
  - reconciling Doc Center test instances over the Dev MCP by direct write;
  - pure-ASCII PDFs survive `uploadDocument`.
- **1 method candidate:** a reading gate skipped in a batch of edits.
- **3 triggers fired:**
  - `tostring()` of a Decimal, in the gates gauntlet;
  - the `[[]]` trap, in the corroboration gauntlet;
  - sail and task links, reproduced.
- **None promoted.** The supplemental is unchanged; the repo and user-level copies are identical (diffed at close-out).

Promotion checkpoint: current through 2026-09-25 — Phase 5.6: Doc Center classification for supporting documents, extraction on pay applications only.

## 2026-09-25 — Fix session: tie-out chips with wrapping off-by detail, all tags under 40 characters

**Scope.** Same session and identities as Phase 5.6.
- Dev MCP `appian` as `scott.thorn@appian.com` (full scope: `SD Administrators`, `SD Users`, the three step groups). Every render, rule test, readback and delete ran under it.
- sail as `sd.accountant` (`~/.sail-sd.accountant`) for the persona smoke check.
- `appian-runtime` and `--from-devmcp` were not used. Draw 66 was not touched. No data was written: this is wording and layout only.

**Why.** Scott's browser pass on the Phase 5.6 checklist confirmed that chips truncate at 40 characters. That is the documented tag limit the 5.6 close-out flagged. Everything else on that checklist passed: intake, the corroboration states, junk classification, the Documents tab and downloads.

**Gate (§5 and the supplemental's UI grounding), run before any edit this time:**
- **Frontend-design guidance:** read.
- **Pack:** `components/grid-field-instructions.md` says to NEVER use a `sideBySideLayout` in a grid column; it lists single components only (tag, rich text, and so on). `layouts/sidebyside-layout-instructions.md` and `components/rich-text-instructions.md` were available.
- **Docs-search:**
  - `a!gridColumn` value: on 26.6, only a single supported component (text, image, link, rich text, button array, tag, record action, progress bar).
  - The **26.9 release notes** add side-by-side layouts in read-only grid cells ("place a status tag next to a due date").
  - `a!sideBySideItem`: `MINIMIZE` suits fixed-width items, and `preventWrapping` must not be used with `MINIMIZE`.
  - `a!richTextDisplayField` `align` / wrapping.
  - The tag's 40-character display limit (from Phase 5.6).
- **Measured on the instance, which wins:** a throwaway `zz_probeGridCell` (`…_575479`) holding a grid whose cell is a side-by-side of a tag (`MINIMIZE`) and a rich-text line.
  - The object validator accepted it at `createInterface`.
  - `testInterface` rendered it with `error: null`: the cell carries the side-by-side, the tag, and the rich text with `preventWrapping=false`.
  - Deleted; 404.

**What changed.**
- **`SD_corroborateDocuments` v6** (`…_573561`; `gen_corroboration.py`):
  - Chips never carry figures. Each item gains `detail`.
  - "Does not tie: $X vs $Y" → chip **Does not tie**, with detail "off by $<absolute difference>".
  - "No <category> line to tie to" (length depended on a constant) → **No line to tie to**, with detail "no Hard Costs line in the template".
  - The stored summary is unchanged ("pay application does not tie ($X vs $Y)" is rich text on the Summary, not a chip).
  - `SD_getSupportingDocuments` and `SD_getDrawCorroboration` regenerated byte-identical.
- **Gauntlet** `gauntlet_SD_corroboration.sail`, now C1–C10:
  - Every case checks the detail line and fails any chip over 40 characters.
  - C9 covers "No line to tie to" (no lines at all).
  - C10 pins a pre-existing behaviour (see Findings).
  - Result: **10/10 pass**, run through a throwaway `zz_gauntletChips` (`…_575490`), deleted with a 404.
  - The first run showed 4 false failures from the gauntlet's own expectation format: `joinarray` drops empty strings. Empty details are now shown as "-". C9's expected text was fixed from `SD_fmtMoney`'s source (a null prints "—") before the run.
- **`SD_form_reconcileExtraction` v7** (`…_571183`):
  - **Verdict strip:** "Does not tie · lines $X vs draw $Y" (red; 56 characters with this draw's figures) → amber **Does not tie**. Beneath it is a right-aligned, wrapping amber line: "lines $<sum> vs draw $<amount> · off by $<difference>" ("vs draw —" with no off-by when there is no draw amount). The strip's bottom margin moves to the new line when it shows. Green "Ties ✓ $X" is unchanged.
  - **Tie-out cell:** a side-by-side of the chip (`MINIMIZE`) and its detail in the chip's colour, shown only when there is a detail.
  - **Draw Number chip:**
    - "Submitted as #N, already on file — renumbered to next in sequence" → **Renumbered from #N (on file)**;
    - "#N is already on file for this investment" → **#N already on file**;
    - "Out of sequence: last draw is #N / none on file" → **Out of sequence (last #N)** / **Out of sequence (none on file)**.
  - **Investment chip:** "Matches <investment name> on file" → **Matches investment on file**. The now-unused `local!matchedInvestmentName` was removed.
  - **Waiver tag:** "No lien waiver received with the pay application" → **No lien waiver received**.
  - The header comment was updated.
- **Swept and unchanged (all ≤ 40, fixed text):**
  - `SD_cmp_statusTag`: fixed vocabulary, longest "Extracted & Confirmed" (21). It is used by the fact strip, the Draws list, and the Approvals, Documents and Summary views.
  - Summary chips: "No budget lines", "Ties ✓", "Does not tie", "Package ties", "Package received", "Needs attention", "None received".
  - Corroboration chips: "Being classified", "Figure could not be read", "Ties", "Received · filed as Invoice", "Lien waiver received", "Received · not classified", "Received".
  - "Next in sequence", "No matching investment".
  - "YOUR ACTION" on the Draws page is rich text, not a tag.
- **Docs:**
  - `PROJECT_INSTRUCTIONS.md`: the collision-chip wording, noted as shortened.
  - `CLAUDE.md`: collision and corroboration wording, a new "Chips never carry figures or names" rule, object versions, Scott's draws 97/98.
  - `TODO.md` and `BUILD_PLAN.md`.

**Verified** (`testInterface` as the designer). A throwaway wrapper `zz_probeReconcileStates` (`…_575506`) built the payload exactly as the pipeline does, `SD_getExtractionForReconcile(instanceId)`, and passed it to the form. A checker listed every rendered tag with its length.

| State | Payload | Tags rendered (longest) | Detail text |
|---|---|---|---|
| Clean | draw 92, instance 868 | Ties ✓ $2,604,252.23 · Renumbered from #67 (on file) · Matches investment on file · Ties · Received · filed as Invoice · Lien waiver received (29) | none |
| Mismatch, no waiver | draw 93, instance 870 | … · **Does not tie** (12) · **No lien waiver received** (23) (29) | "off by $37,500.00", amber, `preventWrapping=false`, in the same side-by-side cell as the chip |
| Junk package | draw 94, instance 872 | … · Received · not classified (25) (29) | none |
| Collision | every live payload (duplicate #67s on file) | Renumbered from #67 (on file) (29) | — |
| Non-tie + collision | draw 92, Hard Costs 2,490,296.00, number 81 (on file: Scott's draw 97) | Does not tie ×2 · Renumbered from #81 (on file) (29) | verdict "lines $2,604,252.00 vs draw $2,604,252.23 · off by $0.23" (amber, right-aligned); grid "off by $0.23" |
| Next in sequence | draw 92, number 83 | Next in sequence (16) | — |
| Out of sequence | draw 92, number 90 | Out of sequence (last #82) (26) | — |
| Override onto a used number | probe copy `zz_probeFormOnFile` (`…_575512`; prefill forced to 77, payload from the instance), draw 93 | #77 already on file (19) | — |

- **Over 40 in any render: none.** Before the fix, the same checker on the Phase 5.6 render of draw 93 listed 66, 41, 44 and 48.
- **Not rendered:** "Out of sequence (none on file)" (30, fixed text) needs an investment with no draws on file, and none exists.
- **Both probes deleted;** each read returns 404.
- **Close-out readback:** form v7 and rule v6 read back identical to the repo `.sail` files, trailing whitespace aside.
- **Persona smoke check (sail as `sd.accountant`):**
  - The Draws page loads: 27 rows, Awaiting My Action 16.
  - #78's Summary renders: "current draw lines sum to $2,604,252.23"; the SUPPORTING DOCUMENTS line; the chip **Needs attention**.
  - The Documents tab shows statuses Classified and read / Extracted & Confirmed.
  - The distinct tags on those pages run up to 21 characters.

**Not verified (and why).**
- **The reconciliation form as the persona.** It is reachable only through its task, and sail does not follow task links (reproduced in Phase 5.5 and 5.6). No draw is Ingesting now, so there is no task to reach. The form's content was verified by the designer renders above.
- **Geometry:**
  - whether the side-by-side cell wraps "off by …" cleanly in the browser (the object validator and the tree prove structure only);
  - whether the verdict's right-aligned line wraps well;
  - that no tag shows an ellipsis.

  Browser checklist: `TODO.md` → "Chip layout after the 40-character fix".

**Findings.**
- **A pay application ties against $0.00 when the template has lines but none for Hard Costs** (pre-existing since 5.5). The target is a sum of the matching lines, which is 0 when none match. "No line to tie to" fires only when there are no lines at all. Gauntlet C10 pins the current behaviour. It was not changed, because the brief allowed no behaviour changes. A ruling is owed (`TODO.md` Deferred).
- **Colours now differ by place.** The verdict chip is amber (per the brief), while the pinned total's "off by" and the Summary's "Does not tie" stay red. A ruling is owed.
- **Two more draws are Scott's:** 97 (#81) and 98 (#82) from his browser pass. The next ingested draw prefills #83.

**Promotion candidates.**
- **STAGED (gate 1, 2026-09-25, chip fix) — a side-by-side layout inside a read-only grid cell passes the object validator and renders on this instance.** The 26.6 docs and the vendor pack say a grid cell takes a single component, and the pack says a `sideBySideLayout` there is "NOT ALLOWED". The 26.9 release notes document the feature.
  - Measured: `createInterface` accepted it; `testInterface` rendered the side-by-side with its tag and rich text, `error: null`.
  - Working form: a status tag (`MINIMIZE`) beside a wrapping rich-text detail in one cell.
  - Contradicts `components/grid-field-instructions.md` ("CRITICAL GRID COLUMN RESTRICTIONS"). Platform-version-dependent: re-verify per instance.
  - *Trigger:* Scott's browser check of the Tie-out cell. If it renders cleanly there, the candidate meets gate 1's measurement bar for the pack correction.
- **STAGED (gate 1, 2026-09-25, chip fix) — `joinarray` drops empty strings:** `joinarray({"","",""}, ";")` returned "", not ";;".
  - Working form: map empties to a visible marker before joining when positions matter.
  - *Trigger:* the next `joinarray` over items that can be empty.
- **[TRIGGER FIRED 2026-09-25, chip fix — working form applied, held at gate 1]** The Phase 5.6 method candidate "a reading gate is skipped silently when edits are batched" fired.
  - This batch ran the gate first (frontend-design, pack, docs-search, then an instance probe) and logged it before any edit.
  - Run first, the gate changed the design: the pack's grid-cell rule would have forced the detail into another column, and the probe showed that was unnecessary.
  - Held at gate 1 (method, one application). *New trigger:* the next batch of interface edits.
- **None promoted.**

Promotion checkpoint: current through 2026-09-25 — Fix session: tie-out chips with wrapping off-by detail, all tags under 40 characters.

## 2026-09-26 — Phase 6a: CEO email approval with AI reply interpretation

**Scope.**
- **Dev MCP:** `appian` as `scott.thorn@appian.com`, full scope: `SD Administrators`, `SD Users`, and the three step groups, so also a recipient of every step email. Every design write, `testRule`, `testInterface`, `testProcessModel` and record readback ran under it.
- **Handler identity:** the receiver hands off as DESIGNER, so the handler's initiator is the designer, and every unattended handler node runs as DESIGNER.
- **sail:** as `sd.accountant` (`~/.sail-sd.accountant`) for the Approvals-tab readback. The sessions found were `alex.analyst`, `sam.supervisor`, `sd.accountant`, `sd.assetmanager` and `test.presenter`; `~/.sail-designer` holds no session and the default `~/.sail` is empty.
- **Not used:** `appian-runtime` and `--from-devmcp`.
- **Draw 66** was not touched: re-read at the end, In Progress at step 3, step process 536909994, `updatedAt` 2026-09-22 15:34:33.
- **Designer work by Scott** (the Dev MCP cannot set these): the receiver's Receive Message (Email) trigger, Public Events, and the trigger's message mappings.

**Capability check (brief item 1; before any build).**
- **Docs:** a process model receives email at `processmodeluuid<uuid>@<site>` once its Start Event has a Receive Message trigger of type Email and Public Events is on.
- **The Dev MCP cannot set either** (measured):
  - the `core.0` and `event.receiveMessage` schemas expose no inputs;
  - `getProcessModel` / `updateProcessModel` carry no trigger or Public Events field.
- **Scott configured `SD Receive Approval Reply` in Designer.**
  - The trigger's mappings could target only process **parameters**. The PVs the session had created over MCP were not parameters, so they were not offered. Scott created `emailFrom`, `emailSubject` and `emailBody` with "New…".
  - He corrected the property syntax to `msg!properties.FromEmail`, `msg!properties.Subject` and `msg!body`.
  - The session then repointed node 3 with `updateProcessModelNode`. The trigger and Public Events survived that MCP update (one observation).
- **Loop tests** (a throwaway `zz_loopTestSendReply` sending from the instance to the receiver): five emails, then message rows 2–6.
  - Rows 2–3 had empty fields until node 3 was repointed.
  - Rows 4–6 had sender, subject and body.
  - Every row arrived from `admin@ny.appiancloud.com`, whatever From was configured (custom sender, process model, process designer).
  - An HTML body arrives as HTML.
  - Latency: 40 s to 2.5 min.
- **Receipt proven; nothing faked.**

**What changed, by object.**
- **Process `SD Receive Approval Reply`** (`0000f074-9ac4-…`), built earlier this session: two nodes, the email Start Event and node 3, which hands off (asynchronous subprocess, as DESIGNER) to the handler with `fromAddress` / `subject` / `body` = `pv!emailFrom` / `pv!emailSubject` / `pv!emailBody`. Its description still names the old, unused PVs; that fix is for Designer (TODO).
- **Process `SD Handle Approval Reply`** (`0000f074-9a9b-…`): stage 0 (4 nodes) → **v1, 34 PVs and 24 nodes**, from `gen_reply_handler.py`.
  - **Gateway is node 6:** the first `updateProcessModel` was refused with "Node 4: node type cannot be changed on update", because stage 0's node 4 was Write Records.
  - Node map: see `CLAUDE.md`.
  - `validateDesignObject`: no errors. Node 40's subprocess inputs read back in the same form as the accelerator's working node.
- **Process `SD Draw Approval Step`** (`0000f06e-a547-…`):
  - PVs `writeError` and `writeErrorText` added, with the existing list and defaults re-sent and read back.
  - End "Notified" moved to x 1100.
  - **New node 13** "Record step email on the draw" (Write Records, DESIGNER, OUTBOUND STEP_EMAIL row).
  - **Node 8** now sends from Custom Sender `SD_EMAIL_REPLY_ADDRESS`, display name `SD_EMAIL_SENDER_NAME`, Reply-To the receiver, and connects to 13.
  - `validateDesignObject`: no errors.
  - Running instances keep their own version: draw 66's step process 536909994 is on the old one.
- **Record type `SD Draw Email Message`** (`3686a81f-…`).
- **Rules** (`gen_email_reply.py`):
  - `SD_parseReplyToken` v1;
  - `SD_extractReplyText` v2 (HTML detected, quote containers cut, per-line strip);
  - `SD_buildReplyInterpretationRequest` v1;
  - `SD_gateReplyInterpretation` v1;
  - `SD_getReplyContext` v1;
  - `SD_buildReplyResponseEmail` v1;
  - `SD_getDrawEmailMessages` v1;
  - `SD_newEmailMessage` v1: the row constructor. It was added so the 24-node payload shrank from ~33 KB to ~20 KB and every write node shares one cut-to-column rule.
- **`SD_buildApprovalEmail` v3:** the token in the subject, a conversational reply instruction, the red warning removed, and an amber over-limit line. The copy departs from the client sample; a ruling is owed.
- **Interface `SD_form_emailException`:** v1 created; v2 removes a repeated step from the subtitle ("step 9 (Step 9 · CEO)" → "Step 9 · CEO").
- **Interface `SD_view_drawApprovals` v3:** the Email Exchange card, from `gen_view_tabs.py`. The generator reproduced the committed v2 byte-identical before the edit.
- **Constants** `SD_EMAIL_*` (six). `SD_EMAIL_REPLY_ADDRESSES` went v1 (all scott.thorn@appian.com) → v2 (the temporary loop mapping, below) → v3 (all scott.thorn@appian.com again), each read back.
- **`scripts/seed_draw66.py`:** `--cleanup-ingested` takes `msgs=` (SD Draw Email Message, deleted first). The dry run printed the expected blocks, and the seed checks still exit 0.
- **`PROJECT_INSTRUCTIONS.md`:**
  - Phase 6 split into 6a / 6b;
  - the reply-matching rules;
  - the **dollar guardrail** and **thread continuity** business rules (brief item 0);
  - the inbound-email open question marked resolved.

**Gates run.**
- **Docs-search:**
  - inbound email and Receive Message mappings;
  - the Send E-Mail From options;
  - `a!gridColumn` width vocabulary and AUTO behaviour (stated: AUTO takes what fixed columns leave, and there is no `WIDE_PLUS`);
  - `a!headerTemplateFull` and `a!formLayout.contentsWidth`.
- **Pack:** `components/grid-field-instructions.md` (width strategy, tags in cells) and `layouts/form-layout-instructions.md` (`MEDIUM` for a single-column form).
- **Frontend-design guidance:** read before the Approvals-view edit.
- **Gate order:**
  - **The exception form was created before its layout gate ran** (transcript order). The gate was run after the fact; the navy header with default text colours matches the reconciliation form Scott has seen in the browser, so nothing changed.
  - **The Approvals view was gated before its edit.**

**Verified.** All loop tests went from the instance to the receiver. All readbacks ran as the designer unless noted.

**Unauthorized sender (production mapping), draw 92, S9:**
- Row 9: outcome UNAUTHORIZED, body "Approved." (the Gmail-style quote was cut), note "…not the authorized reply address for the CEO step. Nothing changed."
- Draw 92 re-read: still step 9, awaiting.

**Temporary mapping.** CAO (6) and CEO (9) → `admin@ny.appiancloud.com`, read back, then:
- `SD_getReplyContext(12, 6, admin@…)` = GUARDRAIL ($8,940,000 > $5,000,000, approvalId 1206);
- `(92, 9, admin@…)` = OK.

**Accelerator** on draws 92, 93, 94 in parallel:
- `testProcessModel` hit its 60 s timeout each time while the processes completed.
- All three reached step 9 by 13:59:47 UTC.
- Node 13 wrote the STEP_EMAIL rows 7, 8, 10, each with the token in the subject, to "SD Draw CEO", ~44 KB of HTML.

**Loop replies.** Each AI call took 3.0–3.4 s and 1 AI action on `appian/anthropic.claude-sonnet-4-6`.

| Reply | Draw | Rows | Result read back |
|---|---|---|---|
| "Looks good, approved. Please release the funds on the 16th." (quote history contains "Approve Reject") | 92 (#77) | 16 | APPROVE, comment "Please release the funds on the 16th."; transition APPROVED. Draw **Approved**, `treasuryNotifiedAt` 14:01:35, `activeStepProcessId` cleared. CEO row 6717 Approved, decision date 10/05 (the monotonic rule after the accelerated chain) |
| "Reject. Hold this one until the lender signs off on the revised budget." (subject "RE:") | 93 (#78) | 15 | REJECT, comment kept; transition "REJECTED at step 9". Draw **Rejected**, no treasury |
| "Let me think about this one over the weekend." | 94 (#79) | 13, 14 | AMBIGUOUS; clarification sent on the thread ("Re: <step subject>") to the sender; nothing changed |
| "Can we talk about the contingency on Monday first?" (second) | 94 | 17 | Read AMBIGUOUS; `priorAmbiguous` 1, so EXCEPTION. Task **22161** "Review email reply" issued (in the designer's list as a member of `SD Draw Demo Approvers`). No email sent. CEO task 22116 still live |
| "Approved." | 12 (Gateway) | 11, 12 | GUARDRAIL; refusal sent on the thread; CAO row 1206 still In Progress, no decision or comment |

**Mapping restored** to all nine → scott.thorn@appian.com (v3, read back) after the last reply was handled.

**Approvals tab as `sd.accountant` via sail.** These were read from sail's stored YAML, not the listing.
- **#77:** CEO row "Decision On 10/05/2026 email · admin@ny.appiancloud.com". Comment: "Email reply from admin@…: "Looks good, approved…" · read as APPROVE (comment: Please release the funds on the 16th.)". Email Exchange 3 rows: step email / Sent; reply / **Sender not authorized**; reply / **Approved by email**.
- **#78:** 2 rows, the second **Rejected by email**. The CEO comment carries the reply and the reading.
- **#79:** 4 rows: Sent, **Unclear · clarification sent**, the clarification / Sent, **Sent to exception queue**.
- **#12:** 2 rows, **Over the email limit** and the refusal / Sent.

**Renders.**
- `testInterface` of `SD_view_drawApprovals` on draw 92 before any message: `error: null`, empty state "No approval emails on this draw yet".
- `SD_form_emailException` on draw 92: `error: null`.

**Column widths measured** through a real Write Records node: a throwaway `zz_measureEmailMessageWidths` process wrote one row through `SD_newEmailMessage` at every maximum. A throwaway rule read the stored `len()`s: fromAddress 255, toAddress 1,000, subject 1,000, body 4,000, interpretation 1,000, notes 1,000.

**Gauntlet** `gauntlet_SD_emailReply.sail`: 29/29 (T1–T8, X1–X8, G1–G13), re-run before its throwaway runner was deleted.

**Close-out readback.** All 11 Phase 6a rules and interfaces read back identical to the repo `.sail` files (trailing whitespace aside).

**Cleanup, verified by absence:**
- `zz_gauntletEmailReply` (`…_575607`) and `zz_measureEmailMessageWidths` (rule `…_575650`): 404.
- `zz_loopTestSendReply` (`0000f074-9b08-…`) and `zz_measureEmailMessageWidths` (process `0000f074-a56b-…`): the application lists no `zz` process model.
- Message rows 1–6 (capability tests, no draw) and 18 (the width probe) deleted by explicit id; the table now holds rows 7–17 only.

**Not verified (and why).**
- **A reply from a real mail client:**
  - that an external sender keeps its own address;
  - that Reply-To routes a mail client's reply to the receiver;
  - that the clarification threads in Gmail.

  Loop tests cannot show any of these. Checklist: `TODO.md` → "Live email reply from a real mailbox".
- **Handler node 62** (the review log) and the exception form's **Mark Reviewed**: task forms are not reachable through sail, and completing the task over MCP would bypass the button's save. It is in the same checklist.
- **UNMATCHED, NOT_AWAITING and an unclassifiable answer:** proven by rule tests and the gauntlet, not live (TODO Deferred).
- **Geometry** of the Email Exchange card and the exception form: browser only (same checklist).
- **What the sender line looks like in Gmail:** the loop proves only that the instance's own receiver sees `admin@…`.

**Findings.**
- **Instance-sent mail is re-stamped from `admin@ny.appiancloud.com`.** A loop test therefore can never exercise the authorized path. The working form used here: temporarily map the roles under test to that address, run the tests, and restore by readback.
- **An email decision after an accelerated chain is dated a day after the previous step** (the monotonic rule), not on the email's date. Recorded as a known data artifact in `CLAUDE.md`.
- **Draws 92–94 were Phase 5.6 specimens.** Their corroboration states are unchanged; their approval states now carry the Phase 6a outcomes.

**Promotion candidates.** All staged at gate 1:
- `SD Receive Approval Reply`'s email trigger and Public Events cannot be set over the Dev MCP.
- Receive Message mappings target parameters only.
- Instance-sent mail arrives from `admin@<site>`.
- A bare `=pv!x` in a Send E-Mail text input fails the save.
- `stripHtml()` deletes newlines.
- A node's type cannot change on update.
- An email body arrives as HTML.
- **Method trigger fired:** the gate was skipped for the new exception form and run first for the Approvals view.
- **None promoted.**

Promotion checkpoint: current through 2026-09-26 — Phase 6a: CEO email approval with AI reply interpretation.

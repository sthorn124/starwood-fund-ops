# Worked example: verifying as the persona with the sail CLI

This is the worked example behind the verification split in `CLAUDE.md` §4, the sail identity rules in `CLAUDE.md` §6, and `reference/patterns.md` §12–13. It records one evaluation of the sail CLI that ships in the Dev MCP bundle. The evaluation ran against a delivered demo application on a live site, from two accounts: a persona with a local password, logged in by the operator, and the design account, imported from the Dev MCP. Every rule, boundary, and taxonomy entry elsewhere in this repo that cites an S-number points at a row of the measurement record at the end of this file. The application, the client, the records, and every person are removed; the numbers are as measured (sail 26.6.90 and DevMCP 26.6.90, one site, one day).

## The question

The method had routed every persona-scoped fact — what a role sees, which actions it gets, whether a masked value stays masked — to a human clicking through a browser. The reason was that the Dev MCP renders only as the design account and cannot click (`reference/mcp-capability-boundaries.md` §5). sail offered a different seat: a command-line client that logs in as an account, exchanges the same SAIL UI JSON a browser would, and prints and drives what is on screen. The evaluation asked four things of it, in order:

1. What is its real command surface?
2. What does it observe, and what can it demonstrably not observe?
3. What does it drive, and how is a write verified?
4. What is its session and identity model?

It then read the same pages as both accounts and diffed them.

The application was a delivered demo with no showing scheduled, so writes were allowed. Every write was reverted, and the revert verified the same way as the write. The persona's session came from the operator's own login; the session never saw a password.

## What the terminal sees, and what it cannot

As the persona, a dashboard page loaded in 1.83 s and listed, in page order, 29 actions and 48 read-only values [S5]:

- the title and a process launch marked "launches a process (not reversible)";
- five KPI tiles, and three insight sentences with their disclosure links;
- a conditional attention band with its gating lines and a related action;
- an events list, and a filter dropdown with its choices and current value;
- a grid with its sort, search, and refresh handles, and seven record links;
- a chat component.

Record views, their tabs, related-action forms, and a process launch's start form all listed their contents the same way, with field states (`[REQUIRED]`, `[INVALID]`, `[DISABLED]`, `[READONLY]`) and next moves [S10, S11, S21]. Re-reading any of it with `show` took 0.2 s and sent no request [S6].

The listing is a summary. The complete page is the YAML sail stores beside it. The grid's rows past the second, every tag value, each milestone's name and date, and a new sort order are there and nowhere else [S7]. That YAML carries style (hex colours, size and style enums) and the layout parameters the interface requested. It carries nothing a browser computes: no pixel sizes, positions, line breaks, or truncation [S8]. Some things are out of reach altogether: document downloads, an action repeated per grid row under one label, and, per sail's help, plain URL links [S9].

That is the split `CLAUDE.md` §4 now states:

- **Terminal-verifiable per persona:** content, field state, visibility, conditional rendering, navigation, and behaviour, reading the YAML where the listing stops.
- **Browser-only:** wrapping, truncation, overflow, alignment, card heights, chart drawing, and branding.

## Designer versus persona: one site, two accounts

The same pages were loaded as the persona and as the design account. The stored YAML was then diffed, after normalising the component ids the server mints per render [S32].

| Surface | Persona | Design account |
|---|---|---|
| Pages the site offers | 2 | 8 |
| Rows on the record-list page | 8 | 8, stored page identical |
| KPI: total value across active records ($B) | 94.41 | 126.01 |
| KPI: value going live within 90 days ($B) | 22.9 | 54.5 |
| A restricted record's four sensitive cells in the dashboard grid | `Restricted` | real values |
| The same record's view: four headline values and two sub-summaries | `Restricted` | real values |
| Actions offered on that record's view | 26 | 29 (three more related actions) |
| A related action in the dashboard's attention band | offered | "none available to you" |
| A control record's view | identical | identical |

Both KPI gaps are 31.6, exactly the restricted record's value. The roll-ups are security-aware, and the persona's tiles carry a tooltip saying restricted records are excluded, text that exists only in the YAML. The rows were not the difference: row security returned the same eight records to both accounts. Everything else was.

**The trap runs both ways.** Read from the design seat, this site over-reports what the persona sees: six extra pages, higher totals, and real values where the persona sees `Restricted`. It also under-reports what the persona can do: the attention band offers the persona an action the design account does not get. A readback that states no account is wrong in both directions at once, and nothing on the screen says whose view it is. That is why every sail observation states its account. It is also why `--from-devmcp`, which imports exactly that design seat, is kept for deliberate diffs like this one (`CLAUDE.md` §6).

Where the differences showed also matters. The KPI values and the actions differed in the listing itself. The restricted record, however, sat in row 7 of a 7-row grid, and the listing previews only two rows. Its masked cells, and the difference between the two accounts, appeared only in the YAML [S7, S32].

## The leak the persona's view exposed

Read as the persona, the site's record-list page showed that restricted record's four sensitive fields in clear [S33]. They were the same four the dashboard grid and the record's own view showed as `Restricted`. One record type, one persona, one session, three surfaces, two answers.

Designer-scoped verification could never have seen it:

- The design account sees real values on every surface.
- The record-list page's stored UI was identical for both accounts.
- So from the design seat all three surfaces agree, and there is nothing to notice.

The leak exists only as a disagreement between surfaces inside the persona's view. Every designer-scoped check the build had run passed, and none of them looked there. The masking had been implemented in the interfaces the build wrote. The record list is not one of those interfaces, so it inherited nothing.

When data is genuinely restricted, the remedy is at the data and security layer, so every surface inherits it (`reference/silent-failure-taxonomy.md` G). The check that finds the next leak is a sweep of every surface as every persona (`reference/patterns.md` §13).

## Writes: the output is not the evidence

As the persona, a status related action was opened, a dropdown set, and the form submitted in 0.54 s [S13]. sail reported success with the process id. It also noted that the page it printed was the one from before the form opened, and that page still showed the old status. The note suggests `sail load <site> --fresh` for the current page, but that command loads the site's default page, not the record. A session that trusted the output would report a write that "did not happen". One that followed the suggested reload would read a different page.

The write was proven three ways, each read fresh:

- the record-list row showed the new status;
- the record's view showed the new tag text in its new colour;
- the record's activity tab carried a new entry naming the persona and the change. The count rose by one per write: 52, then 53 after the restore.

The restore went the same way, driven through a shortened, lower-cased button label [S13, S14].

The surrounding failures are all quiet at the exit code:

- A submit that validation blocked exited 0 with "✓ Interacted" and the form still open [S12].
- A disabled button was sent anyway and exited 0 with "Nothing changed" [S16].
- An out-of-range dropdown index cleared the field [S17].
- A picker suggestion batched after a field that restructured the form was dropped without a mention [S18].

These are the basis for `CLAUDE.md` §4's write rule and for the sail section of the taxonomy (M).

## Sessions and identity

- **No command says who you are.** The surface has no identity command [S2]. The session file records the username typed at login, not an answer from the server [S25]. An import names the authenticated user once, at import time, and never again [S30].
- **The session file is the identity, and it is portable.** A copy of it authenticated from another directory [S27]. An empty directory, set by `--data-dir` or `SAIL_HOME`, failed with "no session found" [S26].
- **Logout is real.** It deleted the session and page files in 0.21 s. The copy taken beforehand was then refused with HTTP 401 [S28].
- **An import is not a copy of the designer's session; it is the same session.**
  - With the Dev MCP's session expired, the import refused locally in 0.07 s and wrote nothing [S29].
  - After a Dev MCP tool call refreshed that session, the import succeeded in 0.18 s and named the design account. The session file it wrote held the Dev MCP's own three cookies [S30, S31].
  - `sail logout` on the import then left the Dev MCP's cookie file byte-identical but its session dead. The Dev MCP server's next call hit a 401, reopened its browser, and recaptured a session in 3.1 s [S31].
  - That recovery was silent only because the browser profile's identity-provider session was still alive. Without it, the build's next design call would have stopped on an SSO and MFA prompt.

These are the basis for `CLAUDE.md` §6:

- every observation states its account;
- each persona has its own directory;
- the default directory stays empty;
- an imported session is discarded by deleting its directory, never by `logout`.

## What static analysis got wrong

Before the tool was run, its binary was read statically. That read got the surface wrong in both directions:

- it reported a `whoami` command that does not exist (the name belonged to an internal method);
- it missed the `navigate` command and the `--json` flag;
- it credited record-view and related-action following to `interact`.

It got these right, all later confirmed by `--help` or by behaviour:

- the environment-variable login and its local-account requirement;
- `--from-devmcp` and `--user`;
- `--data-dir` and the `~/.sail` default;
- `--fresh` and `--confirm`;
- the value formats;
- `show` without a server round-trip;
- `logout` revoking and deleting.

The help was then wrong once too. It says a navigation target may be shortened with or without its `⤴` marker, but without the marker a shortened target failed [S3]. Metadata, then documentation, then behaviour: only the last is evidence (`reference/silent-failure-taxonomy.md` C).

## Along the way: two servers under one name

The evaluation began in a session where the Dev MCP's design tools were absent while a server named `appian` answered with ten tools. That server was a runtime MCP server registered under the same name in the desktop app's config, which Claude Code sessions receive alongside their own servers. After a relaunch, the same collision produced the opposite shape: both servers' tools merged under one prefix, 167 in all. Renaming the runtime server by role, with the desktop app quit, separated them: 157 design tools under `appian` and 10 under `appian-runtime` [S34]. `reference/toolchain.md` §2 carries the rule.

## Measurement record

sail 26.6.90, DevMCP 26.6.90, one site, 2026-09-21. "Persona" is a regional role with a local account, logged in by the operator. "Design account" is the designer's session imported from the Dev MCP. Times are wall-clock for one command.

| ID | Measured | Result |
|---|---|---|
| S1 | Version and installation | `sail --version` reported `sail version 26.6.90`, the bundle's own version. The bundle's `bin/` holds `sail-darwin-arm64` (8,944,338 bytes), `sail-linux-amd64` (9,466,018), `sail-windows-amd64.exe` (9,750,528), and `setup-mac.sh`, `setup-linux.sh`, `setup-windows.bat`. `setup-mac.sh` cleared the quarantine flag and, with `/usr/local/bin` not writable, linked `~/.local/bin/sail`. The Windows script's header says it has not been run on Windows. |
| S2 | Command surface, from `--help` | Commands: `back` (aliases `close`, `dismiss`), `completion`, `help`, `interact`, `load`, `login`, `logout`, `navigate` (alias `nav`), `pages`, `show`. Global flags: `--data-dir`, `--json`, `-v`/`--version`. Command flags: `login --from-devmcp --user`, `load --fresh`, `interact --confirm`. No identity command. |
| S3 | Static read of the binary versus the help and behaviour | The static read reported a `whoami` command (none exists), missed `navigate` and `--json`, and attributed record-view and related-action following to `interact`. `navigate`'s help says targets shorten "with or without the ⤴ marker". A shortened target without the marker failed ("no navigation target matches"); the same prefix with the marker resolved, and the full label resolved without it. |
| S4 | Pages, persona | `pages` listed 2 pages: a dashboard (the default) and a record list. Pages gated to other groups were absent; naming one returned "has no page matching … pages: …", exit 1. The design account saw 8 [S32]. |
| S5 | Dashboard load, persona | 1.83 s. 29 actions and 48 read-only values, listed in page order: title, a process launch, five KPIs, three insights with disclosure links, a conditional attention band, an events list, a filter dropdown, a grid with handles, seven record links, a chat component. Stored: `<site>-ui.json` 572,942 bytes and `<site>-ui-concise.yaml` 154,694 bytes. A record-list page loaded in 0.72 s (14 actions). |
| S6 | `show` | 0.197 s; output identical to the load except the headline. With every proxy variable pointed at a dead port, `show` succeeded and `pages` failed with a proxy connection error, so `show` sends no request. |
| S7 | What only the YAML holds | A 7-row grid was listed as "showing 1-7 of 7", its first two rows, and "+5 more on this page". All rows were in the YAML, the restricted record in row 7. A record view's 8 tag values were in the YAML only; the listing showed the status label without its value. A timeline listed its milestones as 14 click refs named after the record, "n of 14"; each milestone's name, date, and state was only in a YAML tooltip. After a sort, the listing said only that the page re-rendered; the new order was readable only in the YAML. |
| S8 | Style and layout in the stored UI | Hex colours, size and style enums, requested widths, margins, and alignment were present. A status tag's background changed from `#B45309` to `#B3261E` with the status write. A scan of the full UI JSON found no pixel, position, or computed-size keys. |
| S9 | Unreachable targets | Five document download links on a record tab were refused by `navigate` ("no navigation target matches") and by `interact` ("no component matches"). An action rendered per grid row under one label was refused: "names 43 different destinations and cannot be told apart". The YAML carries no row-qualified handle for it. No page the persona reached had a plain URL link, a chart, or a grid past one page, so those were not exercised. sail's help says `<url>` "is a plain hyperlink no sail command can follow" and that `<display>` includes a chart's plotted values. |
| S10 | Record link, tabs, `back` | `navigate` to a record: 1.41 s, 29 actions and 38 read-only values (six related actions, seven tabs, the view's content). A plan tab listed 299 read-only values and listed two per-row actions as unaddressable. `back` returned to the list page. `back` with nothing to return to: exit 1, "the loaded UI is a site page". |
| S11 | Related-action form, `back` | Opened in 0.36 s: three lines of guidance and roll-up text, a required dropdown with ten choices, and submit and cancel buttons. Setting the dropdown printed a property diff ("value: 5 -> 6"). `back` dismissed the form, and a fresh read showed the value unchanged. |
| S12 | Validation-blocked submit | Blanking the required dropdown and pressing submit in one batch: exit 0, "✓ Interacted", "⚠ A value is required", the field `[REQUIRED INVALID]`, the form still open. Under `--json`: `status: "ok"`, `movedNothing: "True"`, `validations: ["A value is required"]`, nothing on stderr. A start form's "Next" with three required fields blank: three ⚠ lines, exit 0. |
| S13 | A real write and its verification | Submit took 0.54 s and printed "✓ Submitted related action … (process <id>) — returned to record view". It added a note that the page below is as it was before the form opened, and suggested `sail load <site> --fresh`. The printed page and a later `show` still showed the old status, and `load --fresh` loaded the site's default page. Verified instead by the record-list row (new status), a fresh record view (new tag text and colour), and the activity tab: a new entry naming the persona and the change; 52 entries, then 53 after the restore. |
| S14 | Addressing | `interact` resolved lower-cased label prefixes: a two-word prefix set a field, and a six-character prefix pressed the submit button. It also resolved a full component id, but not an 8-character id prefix. An empty target was sent, and the server answered HTTP 500. A no-value target placed mid-batch was refused with `component "10" has no value`. |
| S15 | Grid sort, search, filter | The sort handle sorted ascending, then descending, readable in the YAML. The search handle with text took 8 rows to 1; with "" it returned 8. A filter dropdown removed seven record links and added one. |
| S16 | Disabled button, cascade | A `[DISABLED]` button: "⚠ Nothing changed … the server accepted the interaction and no value moved", exit 0. Choosing a dropdown value: the diff showed a dependent button's `disabled: true -> false`. |
| S17 | Out-of-range and invalid indexes | Index 99: exit 0, "✓ Interacted", the field's value to `(empty)`, the dependent button re-disabled. Index 0 and a choice's text were refused before sending, with the choice list. `-1` was parsed as a flag. |
| S18 | Picker, and a batched pick | Picker search text produced a `▸ <name>` handle. A batch of a category dropdown, then that handle, exited 0 with "✓ Interacted". The category change loaded an existing record into the form and removed the picker, and the pick was dropped without a mention. |
| S19 | Confirmation guard | A save button carried a `confirm:` line. Without `--confirm`: exit 1, the dialog's text quoted, the command to proceed printed, the form untouched. Under `--json` the refusal went to stderr as plain text, with 0 bytes on stdout. With `--confirm`, a text field and the save in one batch submitted, and a fresh tab showed the change; it was restored the same way. |
| S20 | A batch naming a field not yet on the form | Refused whole ("pair 2 of 3: no component matches"). The first pair's dropdown was still unset, so nothing was sent. |
| S21 | Process launch | A site-level launch opened its start form in 0.65 s: nine fields, two buttons. Dates in `YYYY-MM-DD` and `M/D/YYYY` were accepted; an impossible date and a third format were refused before sending. `back` returned to the list page, and no record was created (8 rows before and after). On a second launch, the cancel button (an ordinary submit, per the help) returned HTTP 400 for a missing required process variable: an application defect, not investigated. |
| S22 | Ordinal refs | Three disclosure links were `⌗ … 1`, `2`, `3`. Expanding the first added its explanation and a hide link, and renumbered the others to "1 of 2" and "2 of 2". |
| S23 | Errors under `--json` | An unknown navigation target: exit 1, 0 bytes on stdout, the error as plain text on stderr. |
| S24 | The load guard | After interactions, loading another page was refused ("loading would fetch a new page and discard that"), naming `show` and `load --fresh`. |
| S25 | Session storage | Data directory `0700`. `session.json` `0600`, 783 bytes for a password login: host, five cookies, CSRF token, timestamp, and the username typed at login. One JSON and one YAML page file per site, overwritten by every load, navigate, and interact. |
| S26 | Isolation | An empty directory, set by `--data-dir` or `SAIL_HOME`: "no session found; run sail login first", exit 1; `show` there reported "not loaded". The default directory's session was unaffected. |
| S27 | Portability | `session.json` copied into another directory authenticated there: its pages resolved. |
| S28 | Logout | "✓ Logged out (2 page state file(s) removed)", 0.21 s. The session file and both page files were deleted and the directory kept. The copy taken beforehand then got HTTP 401 (`APNX-1-4187-000`, "Authentication failed"). |
| S29 | Login refusals | `--from-devmcp` with the Dev MCP's cached cookies expired: refused locally in 0.07 s ("every cookie in … has expired — reopen the session in DevMCP"), nothing written. `--user` naming an identity with no cache: "no DevMCP browser session found at …". `login` with neither the variables nor `--from-devmcp`: "set SAIL_USERNAME and SAIL_PASSWORD environment variables". |
| S30 | Import | After a Dev MCP tool call refreshed its session: "✓ Imported DevMCP session for <host> (authenticated as <design account>)", exit 0, 0.18 s. It wrote only `session.json`: 397 bytes, `0600`, three cookies, `"source": "devmcp"`. The Dev MCP's cookie file was byte-identical afterwards, and the persona's directory untouched. With the network blocked, the import failed at a `/suite/cors/ping` request and wrote nothing. |
| S31 | Shared session | All three cookie values in the imported file were the Dev MCP's. After `sail logout` on the import, the Dev MCP's cookie file was byte-identical but its session dead: a probe import reported it "no longer valid". The Dev MCP server's next call logged a 401 and "Session expired — re-authenticating via browser", recaptured three cookies, and answered in 3.1 s. There was no prompt, because the browser profile's identity-provider session was alive. |
| S32 | Designer versus persona | The table above. Stored-YAML lines differing after normalising render ids: dashboard 25, restricted record view 108, record list 0, control record view 0. Dashboard listing: 29 actions and 48 read-only values as the persona, 28 and 49 as the design account. |
| S33 | Record-list leak | On the record-list page, as the persona, the restricted record's four sensitive fields were in clear. The dashboard grid and the record view showed the same four as `Restricted`. The record-list page's stored UI was identical for the design account. |
| S34 | Two servers under one name | The Dev MCP and a runtime server were both registered as `appian`, the runtime one in the desktop app's config. One session had only the runtime server's 10 tools under the name; after a relaunch, both sets merged, 167 tools. The desktop app's log: `[localMcpBridge] announcing appian: 10 tool(s)`. A rename made while the app ran was undone at its next `Config file written` event, leaving the file byte-identical to the pre-edit copy. Made with the app quit, it held: `appian` 157 tools (Claude Code configuration), `appian-runtime` 10 (desktop). |

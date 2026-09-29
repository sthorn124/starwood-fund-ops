# Closeout — 2026-09-29 — Fix session: attention tags in Current Step; Draws list column widths

## Scope and identity

- **Design work and readbacks:** the Dev MCP as `scott.thorn@appian.com` (full scope).
- **Persona reads:** sail as `sd.accountant` (Priya Raman), from `~/.sail-sd.accountant`.
- **Runtime connector:** not called.
- **Preflight:** the one from this morning's session stands (same day, same conversation):
  - Dev MCP 26.6.95 matches the pin; sail 26.6.95;
  - both draw personas are live; the groups read back as recorded.

## What changed

One object: the Draws page, `SD_page_draws`, from v15 (this morning's version, confirmed before the edit) to **v16**. The read-back equals the file sent.

**1. The attention tags moved into Current Step.**
- "Question waiting" and "Reply needs review" now sit on their own line in the Current Step cell, under "approver · days", in amber (#92600A), small and bold.
- The Status column shows the status chip alone again.
- The derivations and the team-only visibility are unchanged.

They're an amber text line rather than a chip because a read-only grid cell holds a single component on 26.6. The docs' list of cell contents is text, rich text, a link, an image, a tag field and so on, one per cell. Putting a chip beside text needs side-by-side in a cell, which is 26.9 and printed component internals in your browser on 09-28. The vendor pack says the same: use rich text in grid cells. So the line follows the YOUR ACTION pattern in the Draw column.

**2. The columns share the width instead of adding up past it.**
- **Before:** fixed widths, five columns at NARROW_PLUS, Investment at MEDIUM_PLUS and Current Step at MEDIUM. That's about 1,550 px by the pack's approximations (NARROW_PLUS ~172, MEDIUM ~260, MEDIUM_PLUS ~430), more than a laptop grid is wide.
- **Why it scrolled:** the docs say fixed widths turn on horizontal scrolling when their total exceeds the grid, and extra room goes out by content. That's how Investment grew.
- **Now:** relative widths, which the docs recommend for a list that fits its container:

| Column | Width |
|---|---|
| Draw | 2X |
| Investment | 3X (narrower) |
| Type | 2X |
| Amount | 2X |
| Funding Date | 2X |
| Current Step | 4X (room for the tag line) |
| Status | 2X (at the end) |

On a ~1,180 px grid that's roughly 139 px per 2X column, 208 px for Investment and 278 px for Current Step.

## Verified (as `sd.accountant` via sail, read from sail's stored UI JSON)

| Check | Result |
|---|---|
| #12 Current Step | "6 of 9 · Chief Accounting Officer" / "Robert Chen · 10 days" (grey, small) / **"Question waiting"** (amber, small, bold), each on its own line |
| #12 Status | "In Progress" chip alone |
| #85 (your draw 113) | "9 of 9 · CEO" / "Thomas Bergman · 1 day" / "Question waiting" |
| Clean rows | unchanged: #84, #83, #82, #70, #66, #81, #74, the approved and rejected rows, the Ingesting and Not loaded rows |
| Column config | the rendered grid carries Draw 2X, Investment 3X, Type 2X, Amount 2X, Funding Date 2X, Current Step 4X, Status 2X |

## Not verified, and why

- **No horizontal scroll.** sail and the design tree carry the widths requested, not the pixels drawn, so neither can prove the absence of a scroll bar. The config is what the docs say fits. The screen itself is your check.
- **"Reply needs review" on a live row:** no draw has an open review task right now.

## Browser check (one glance, in `TODO.md`)

As `sd.accountant`, the Draws page at a laptop width (1,280–1,440 px, browser at 100%):

1. **No scroll bar** under the grid; Status is the last column, fully visible.
2. **#12 and #85:** "Question waiting" in amber on the third line of Current Step; Status is the chip alone.
3. **Places that may wrap badly** (estimated, not measured):
   - **Draw column, unconfirmed rows:** "New draw · Sep 28, 10:51 PM" plus YOUR ACTION takes 2–3 lines.
   - **Investment column, unconfirmed rows:** the file name "THSV_Draw67_Budget_Template.xlsx" is one 32-character word with no break points, about the column's width. Check that it doesn't spill into Type.
   - **Current Step, Ingesting and Not loaded rows:** "Doc Center extraction · Accountant reconciliation" and "received … · resubmit via Receive Capital Call" take 2–3 lines.
   - **Current Step, "6 of 9 · Chief Accounting Officer":** close to one line; it may wrap.

## Rulings needed

- **Still open from this morning:**
  - #84's stored Sep 29 received date (leave it, or correct that one row);
  - #12's pending question.

## Promotion candidates

- **0 found:** the width behaviour is documented.
- **None promoted.** The supplemental skill copies are unchanged.
- **Checkpoint:** current through this session's entry.

## TODO changes

- **Rewritten:**
  - the Draws browser check (no-scroll check, the tag's new place, the wrap list);
  - beat 6, step 1 (the tag now appears in Current Step).
- **Done:** this session.

## BUILD_PLAN.md changes

- ✅ 2026-09-29 Draws list layout: the attention line in Current Step, relative column widths.

## Commit

"fix: attention tags in Current Step; Draws list column widths". Pushed to `origin/main`, then verified that HEAD equals `origin/main` and the tree is clean.

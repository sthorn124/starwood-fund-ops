# Project instructions — Starwood draw approval

*Phase 0 complete, 2026-09-21. The header facts come from instantiation. The sections below Header facts are the Phase 0 transcription from the claude.ai Project.*

## Header facts

- **Repo:** https://github.com/sthorn124/starwood-fund-ops
- **Client:** Starwood
- **Appian instance:** `ny.appiancloud.com`
- **Application:** `Starwood Demo`, the existing subscription-intake app. Its UUID is `dd3bb740-b105-421b-a866-29d542a144da`.
- **Host application, ruled 2026-09-21:** draw approval lives in `Starwood Demo` (`dd3bb740-b105-421b-a866-29d542a144da`), which is confirmed. `Capital Calls & Distributions` on the same instance belongs to a different client and is out of scope for this build. Do not read from it or reference it.
- **App prefix:** `SD`
- **Flow name:** **draw approval**. This is the canonical name. Use it consistently in all objects, docs, and commits.
- **Spec source:** the three artifacts in the repo root are the authoritative spec for the new approval email layout and for the Sep/Oct 2026 enhancement scope.
  - `current approval email sample blacklined.pdf`: the approval email as it is today, redacted.
  - `New approval email sample blacklined.pdf`: the new approval email layout, redacted.
  - `Draw workflow enhancements simple overview 9-12-26.xlsx`: the current draw workflow, with the Sep/Oct 2026 enhancements and notes beside each step.

  **These files are local only.** The repo's `.gitignore` excludes `*.pdf` and `*.xlsx`, so they are **not on GitHub**. Any reader working from GitHub, including the claude.ai Project, must be given them directly, for example by uploading them to the Project.

## Demo narrative
Continuation of the subscription intake story on one platform: Blue Granite's capital entered Harborline Real Assets Fund II through intake; this flow deploys it. A hotel property held by the fund submits draw #66 ($2,604,252.23, PIP/Renovation) with the standard Excel budget template. The demo runs the future state front to back:
1. The capital call and template arrive (narrated as the EY API/SFTP feed; triggered manually in demo).
2. Ingestion fails on a malformed template. The alert email to the accountant and asset managers explains the failure in plain English, with an AI comparison against the last successfully ingested template describing what changed.
3. The corrected template ingests via Doc Center. The accountant reviews extraction results and confirms; budget data lands in the draw tables and appears in the UI.
4. QIU data is aggregated to the draw. The pre-completed approvals are orders 1–2: the Accountant and the Accounting Controller are both Approved. The chain sits at the Asset Manager step, order 3.
5. The asset manager reviews in the UI, edits a budget line at their approval step, and approves.
6. The CEO (order 9) receives the new-format approval email, replies conversationally ("looks good, approve"), and AI interprets the reply as an approval. The chain completes.
7. Treasury receives the execution notification. Capital moves.
The 9-step approval chain (contiguous orders 1–9, as in the current email sample) exists as data and renders in the status table; live interactions are the asset manager (UI) and the CEO (email) only. Chain steps between the asset manager and the CEO are advanced by a demo accelerator, narrated as the chain approving over subsequent days.

## Personas
- Fund Accountant. Owns ingestion. Receives failure alerts with the AI diff, reviews Doc Center extraction results, approves the AI-drafted contingency narrative. This is the same person as the chain's Accountant role (order 1). The order 1 approval step is data only: it is seeded as Approved and never acted on live.
- Asset Manager. Reviews the draw at their step, edits budget data at approval, receives ingestion failure alerts.
- CEO (order 9). Approves by email reply only. Never opens the UI. The Executive role (order 5) is a separate, data-only chain role.
- Remaining chain roles (Accountant, Accounting Controller, AM SVP, Executive, Chief Accounting Officer, CFO of Funds, President) exist as approval data, spoken to, not shown. The Accountant row is the Fund Accountant's data-only approval.

## Data model (entity level)
- SD Investment: name and description, mapping the new email's "Investment Name" and "Investment Description [from DealCloud]". It is related to the existing SA Fund. DealCloud is narrated as the upstream source and is not integrated.
- SD Draw: header facts (funding date, draw type, purpose, amount, budget status, over budget reason, general comments, contingency explanation, status, current step); related to SD Investment, and through it to SA Fund.
- SD Draw Budget Line: budget category, category group (Land/Soft/Hard), initial budget, revised approved budget, proposed adjustments this draw, proposed budget, current draw, total PTD ($ and %), balance to complete, in-this-draw flag.
- SD Draw Approval: order, role, approver, status, decision date, comments. Drives both routing and the status table.
- SD QIU Metric: the ten metrics from the email samples, model as-of date, current model value, current projection, variance, notes. The metrics, in order:
  1. IRR
  2. Profit
  3. Multiple
  4. Peak Equity
  5. Current Equity Contributions (through prior quarter)
  6. Current Quarter Equity Contribution
  7. Future Equity Contributions (after current quarter)
  8. Distributions To-Date (through prior quarter)
  9. Current Quarter Distribution
  10. Future Distributions (after current quarter)
- SD Draw Document: the source template and backup documents attached to the draw.
Field vocabulary follows the new approval email sample exactly.

## Build phases
*Restructured by ruling on 2026-09-21: interfaces moved out of Phase 1 into a new mockup-first Phase 2, and the later phases shifted by one.*
- Phase 1: data model (including SD Investment), seed data, data-driven sequential approval process with demo accelerator and treasury notification terminal step. No custom views.
- Phase 2: UI foundation, mockup-first: HTML mockups for the draw list and draw summary views in mockups/, reviewed and approved before any SAIL is written; then the views built against them, on the existing intake site in a new page group.
  - Mockups are authored in the claude.ai Project and delivered into mockups/. Build sessions treat them as the UI contract and do not author or modify them. Ruled 2026-09-21.
- Phase 3: Doc Center ingestion success path: template in, extraction, accountant reconciliation, budget tables populated, data on the UI.
- Phase 4: new approval email layout rendered as HTML email from live draw data, matched to the spec PDF.
- Phase 5: ingestion failure path: plain-English alert email, AI diff against the last successful template.
- Phase 6: CEO email approval with AI reply interpretation; asset manager budget edit at approval step; AI-drafted contingency narrative with accountant review (stretch); treasury notification content; polish.

## Vocabulary canon
- Flow name: draw approval. Never "capital call" in object names; "capital call request" acceptable in narrative text only.
- Roles, exact: Accountant, Accounting Controller, Asset Manager, AM SVP, Executive, Chief Accounting Officer, CFO of Funds, President, CEO.
- Draw types: Development, PIP/Renovation. Demo draw is PIP/Renovation.
- Category groups: Land, Soft, Hard.
- Approval statuses: Pending, In Progress, Approved, Rejected.
- QIU stays QIU, unexpanded. Extraction platform is Doc Center.
- "Accounting manager" in source documents (narrative beat 4, workflow xlsx step 3) means the Accounting Controller, order 2. The term does not appear in object names or UI text.
- Approval orders are contiguous 1–9: 1 Accountant, 2 Accounting Controller, 3 Asset Manager, 4 AM SVP, 5 Executive, 6 Chief Accounting Officer, 7 CFO of Funds, 8 President, 9 CEO. The new email sample's status table skips order 4 and runs to 10. That is a source artifact in the client mockup, not a tenth step; the build does not reproduce the gap.

## Business rules
- Approvals are strictly sequential by order; Approve advances, Reject terminates the draw, final approval sets the draw Approved and triggers the treasury notification.
- Email approval accepts conversational replies; AI classifies intent as Approve, Reject, or Ambiguous. Ambiguous generates a clarification reply, never a state change.
- Ingestion failure alerts the accountant and asset managers; the alert includes a plain-English failure reason and the AI diff versus the last successfully ingested template.
- Doc Center extraction below confidence threshold routes to accountant reconciliation before data commits.
- Over budget requires a reason; contingency utilization requires the explanation narrative (AI-drafted, accountant-approved).
- Asset manager may modify budget lines only at their own approval step; edits are attributed and visible downstream.
- Budget Summary figures (Land / Soft / Hard / Total) are computed as roll-ups from the budget detail lines, never reproduced from the sample as printed. The sample's summary contains arithmetic inconsistencies (totals shift by $57,753 while its adjustments column shows none); demo data must reconcile. Ruled 2026-09-21.
- Accelerator decision dates spread 1 day per step (`dayOffsetPerStep` = 1), matching the "chain approves over subsequent days" narration. The funding date must stay after the last generated decision date. Ruled 2026-09-21.
- New demo runs are created by Phase 3 ingestion of the standard template document, not by any generator or reset mechanism. The seeded draw 66 and the reset script are interim build tooling until ingestion exists. Ruled 2026-09-21.
- The draw approval flow does not touch subscription intake data. No object in this flow reads or writes subscription records, and this build does not modify the intake demo's subscription data. The one intake object the flow relates to is SA Fund, through SD Investment.

## Open questions
- Audience: Starwood direct vs reusable FS asset (sets how literal the Starwood branding stays).
- Outbound email delivery and inbound email receipt on the NY instance: verify capability in Phase 4/6 (renumbered from 3/5 by the 2026-09-21 restructure), not assumed.
- Doc Center handling of the Excel template format: confirm in Phase 3 (renumbered from 2); fallback is extraction from a PDF rendition of the template.
- Resolved 2026-09-21: draw views join the existing intake site (`SASite`, "Subscription Agreement Analyst", stub `subscription-agreement-analyst`) in a new page group. There is no dedicated site.
- Deferred 2026-09-21: persona accounts. Phase 1 verifies as the designer.
- Resolved 2026-09-21: Blue Granite continuity is narration only. None of Blue Granite's subscriptions is Accepted, and that is left as it is; the narrative's "entered the fund" is spoken, not shown in data. See Business rules: this flow does not touch subscription intake data.

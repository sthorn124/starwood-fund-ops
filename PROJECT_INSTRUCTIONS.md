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
4. QIU data is aggregated to the draw. The accounting manager approval is shown pre-completed.
5. The asset manager reviews in the UI, edits a budget line at their approval step, and approves.
6. The executive receives the new-format approval email, replies conversationally ("looks good, approve"), and AI interprets the reply as an approval. The chain completes.
7. Treasury receives the execution notification. Capital moves.
The 9-role approval chain from the email sample exists as data and renders in the status table; live interactions are the asset manager (UI) and the CEO (email) only. Chain steps between the asset manager and the CEO are advanced by a demo accelerator, narrated as the chain approving over subsequent days.

## Personas
- Fund Accountant. Owns ingestion. Receives failure alerts with the AI diff, reviews Doc Center extraction results, approves the AI-drafted contingency narrative.
- Asset Manager. Reviews the draw at their step, edits budget data at approval, receives ingestion failure alerts.
- Executive (CEO). Approves by email reply only. Never opens the UI.
- Remaining chain roles (Accountant, Accounting Controller, AM SVP, Executive, Chief Accounting Officer, CFO of Funds, President) exist as approval data, spoken to, not shown.

## Data model (entity level)
- SD Draw: header facts (funding date, draw type, purpose, amount, budget status, over budget reason, general comments, contingency explanation, status, current step); related to the existing investment/fund structure.
- SD Draw Budget Line: budget category, category group (Land/Soft/Hard), initial budget, revised approved budget, proposed adjustments this draw, proposed budget, current draw, total PTD ($ and %), balance to complete, in-this-draw flag.
- SD Draw Approval: order, role, approver, status, decision date, comments. Drives both routing and the status table.
- SD QIU Metric: the nine metrics from the email sample, model as-of date, current model value, current projection, variance, notes.
- SD Draw Document: the source template and backup documents attached to the draw.
Field vocabulary follows the new approval email sample exactly.

## Build phases
- Phase 1: data model, seed data, data-driven sequential approval process with demo accelerator and treasury notification terminal step, base record views.
- Phase 2: Doc Center ingestion success path: template in, extraction, accountant reconciliation, budget tables populated, data on the UI.
- Phase 3: new approval email layout rendered as HTML email from live draw data, matched to the spec PDF.
- Phase 4: ingestion failure path: plain-English alert email, AI diff against the last successful template.
- Phase 5: CEO email approval with AI reply interpretation; asset manager budget edit at approval step; AI-drafted contingency narrative with accountant review (stretch); treasury notification content; polish.

## Vocabulary canon
- Flow name: draw approval. Never "capital call" in object names; "capital call request" acceptable in narrative text only.
- Roles, exact: Accountant, Accounting Controller, Asset Manager, AM SVP, Executive, Chief Accounting Officer, CFO of Funds, President, CEO.
- Draw types: Development, PIP/Renovation. Demo draw is PIP/Renovation.
- Category groups: Land, Soft, Hard.
- Approval statuses: Pending, In Progress, Approved, Rejected.
- QIU stays QIU, unexpanded. Extraction platform is Doc Center.

## Business rules
- Approvals are strictly sequential by order; Approve advances, Reject terminates the draw, final approval sets the draw Approved and triggers the treasury notification.
- Email approval accepts conversational replies; AI classifies intent as Approve, Reject, or Ambiguous. Ambiguous generates a clarification reply, never a state change.
- Ingestion failure alerts the accountant and asset managers; the alert includes a plain-English failure reason and the AI diff versus the last successfully ingested template.
- Doc Center extraction below confidence threshold routes to accountant reconciliation before data commits.
- Over budget requires a reason; contingency utilization requires the explanation narrative (AI-drafted, accountant-approved).
- Asset manager may modify budget lines only at their own approval step; edits are attributed and visible downstream.

## Open questions
- Audience: Starwood direct vs reusable FS asset (sets how literal the Starwood branding stays).
- Outbound email delivery and inbound email receipt on the NY instance: verify capability in Phase 3/5, not assumed.
- Doc Center handling of the Excel template format: confirm in Phase 2; fallback is extraction from a PDF rendition of the template.
- Whether draw views join the existing intake site or get a dedicated site.

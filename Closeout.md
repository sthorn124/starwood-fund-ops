# Closeout — 2026-09-21 — Phase 0 transcribed; build plan authored, plan gate now passes

## Scope and identity

- **Docs only.** No build work and no instance writes.
- **Two read-only Dev MCP reads** ran as `scott.thorn@appian.com`, a member of `SD Administrators` and `SD Users`: `listRecordData` on `SA Fund` and on `Subscription Agreement`.
- **Not used:** `appian-runtime` and sail.

## What changed

- **`PROJECT_INSTRUCTIONS.md`:**
  - Filled the seven sections with the supplied text: Demo narrative, Personas, Data model, Build phases, Vocabulary canon, Business rules, Open questions. A diff against the supplied text shows it byte-identical.
  - The header facts are unchanged. The italic status line now reads "Phase 0 complete".
- **`BUILD_PLAN.md`:** rewritten from the stub into the standard format.
  - The Demo Narrative, Personas and Data Model sections point to `PROJECT_INSTRUCTIONS.md` as canonical.
  - Phases 0–5 each list the objects, dependencies, verification (pass conditions and break-tests stated in advance), and demo-visible outcome.
  - Phase 0 items are marked ✅ 2026-09-21. **Phase 1 is marked as the next session's scope.**
- **`TODO.md` and `BUILD_LOG.md`:** updated; see below.

## Plan gate

**PASS.** The stub marker is gone, and `## Build Phases` holds 53 checklist items under Phases 0–5. The next session's preflight will allow build work.

## Key design decisions in the plan

- **One unattended decision process.** `SD Apply Draw Approval Decision` implements the sequential routing: Approve advances, Reject terminates, final approval sets the draw Approved and notifies treasury. The UI step, the email step and the demo accelerator all call it. Because it has no attended nodes, every path can be tested with `testProcessModel`, including break-tests.
- **The treasury notification is gated on the final-approval write's success,** not just placed after it.
- **Phase 2 starts from the instance's own working Doc Center example** (`SD Process Packet (async)`).
- **AI outputs pass a deterministic validation gate** before any alert or state change uses them: the failure diff, the reply intent, and the contingency narrative. Ambiguous replies never change state.
- **Email capabilities are tried on the instance first,** and nothing is assumed: outbound delivery in Phase 3, inbound receipt in Phase 5.

## Facts read from the instance (as the designer)

- `SA Fund` id 4 = "Harborline Real Assets Fund II, L.P.", so the narrative's fund exists.
- Blue Granite Pension Trust's subscriptions to fund 4 are all "Under Review" or earlier; none is Accepted.
- There is no investment or property record type in `Starwood Demo`.

## Rulings needed before the Phase 1 prompt

These are in `TODO.md` → Client validation questions. The transcription itself was not altered.
1. **"Accounting manager" in narrative beat 4** is not a canon role. Is it the Accounting Controller?
2. **"Executive (CEO)":** confirm the live email approver is the CEO, order 9, and that Executive, order 5, is data only.
3. **Fund Accountant and the chain's "Accountant":** are they the same person, with the approval step data only?
4. **QIU metric count:** "nine" is stated, but the email sample reads as ten rows. Re-count at high resolution.
5. **Approval step count:** "9-role chain" is stated, but the new sample appears to run to order 10. Re-count at high resolution.
6. **Investment and property:** header fields on SD Draw, or a new SD Investment entity? The new email shows Investment Name and Description "from DealCloud".
7. **Blue Granite continuity:** its capital "entered" the fund, but no subscription is Accepted.

## Verified

- The verbatim transcription, by diff.
- The plan gate, by a structural check.
- The two record reads, with scope stated.

## Not verified

- The fine print of the spec PDFs, where questions 4 and 5 depend on a high-resolution re-read.

## Promotion candidates

0 found. The checkpoint is current through this entry.

## TODO changes

- **Closed and moved to Done:** Blocking "Phase 0 plan for draw approval" (✅ 2026-09-21).
- **Added:** Client validation "Phase 0 discrepancies" (7 items; Scott; trigger: before the Phase 1 prompt).
- **Sharpened:** "Persona accounts and sail logins", which now names the Fund Accountant and Asset Manager accounts and the steps.
- **Still open:**
  - Before demo: the spec artifacts not on GitHub, and the persona accounts.
  - Deferred: the supplemental §3 correction, `errorAlertGroupUuid` persistence, the remaining-object inventory, and the identity probe.

## BUILD_PLAN.md changes

- Authored from the stub.
- Phase 0: five items ✅ 2026-09-21 and one open (discrepancies ruled).
- Phases 1–5: all open. Phase 1 is the next session's scope.

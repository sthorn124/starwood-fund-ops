# Closeout — 2026-09-21 — Phase 0 discrepancies ruled and applied; Phase 1 ready to prompt

## Scope

Docs only: no build work, and no instance, MCP or sail calls.

## Rulings applied

| # | Ruling | Where it landed |
|---|---|---|
| 1 | "Accounting manager" means the Accounting Controller, order 2. Orders 1–2 are pre-completed as Approved, and the chain sits at the Asset Manager, order 3. | Narrative beat 4; a new canon rule (the term is never used in object names or UI text); the Phase 1 seed |
| 2 | The CEO (order 9) is the live email approver. The Executive (order 5) is data only. | Narrative beat 6 now says "The CEO (order 9)"; the persona is renamed from "Executive (CEO)" to "CEO (order 9)"; the plan's persona table and Phase 3 outcome |
| 3 | The Fund Accountant is the chain's Accountant (order 1); that step is data only. | Personas in both files |
| 4 | Ten QIU metrics, listed in order. | Data model, with all ten listed; Phase 1 record type and seed |
| 5 | Nine contiguous orders, 1–9. The sample's gap at order 4 and its order 10 are a source artifact, not reproduced. | A new canon rule with the full order-by-role list; the narrative; Phase 1 seed pass conditions; the Phase 3 Approval Status section |
| 6 | `SD Investment` is a record type: name and description ("Investment Name", "Investment Description [from DealCloud]"), related to `SA Fund`. SD Draw relates to it. DealCloud is narrated, not integrated. | Data model in both files; Phase 1 now has six record types, the Draw → Investment → SA Fund relationships and an investment seed row |
| 7 | Blue Granite continuity is narration only. The flow never reads or writes subscription records. | Business rules (a new constraint); Open questions (recorded as resolved) |

## Files changed

- `PROJECT_INSTRUCTIONS.md`: the narrative, personas, data model, vocabulary canon, business rules and open questions, per the table above. The header facts are unchanged.
- `BUILD_PLAN.md`:
  - the Phase 0 discrepancy item is ✅ 2026-09-21;
  - the personas table, the data-model table and the Phase 1 objects, seed and pass conditions follow the rulings;
  - Phase 3's Approval Status now uses contiguous orders;
  - the plan gate still passes, with 55 items.
- `TODO.md`: "Phase 0 discrepancies" moved to Done.
- `BUILD_LOG.md`: a ruling entry.

## Verified

- Each edit was asserted to match its target exactly once.
- A grep finds no remaining "Executive (CEO)" and no "nine metrics". "Accounting manager" survives only in the canon rule that maps it.
- The plan-gate check passes.

## Not verified

Nothing on the instance was touched this session.

## Next

Phase 1 is the next session's scope: six record types, the seed, the decision process, the accelerator, the treasury notification and the base views.

**Still to settle before Phase 1 views and persona checks:**
- whether draw views join the intake site or a dedicated one;
- the mockup for the draw summary view;
- the persona accounts.

## Promotion candidates

0 found. The checkpoint is current through this entry.

## TODO changes

- **Closed and moved to Done:** "Phase 0 discrepancies" (all seven ruled, ✅ 2026-09-21).
- **Still open:**
  - Before demo: the spec artifacts not on GitHub, and the persona accounts with sail logins.
  - Deferred: the supplemental §3 correction, `errorAlertGroupUuid` persistence, the remaining-object inventory, and the identity probe.

## BUILD_PLAN.md changes

- The Phase 0 discrepancy item is ✅ 2026-09-21. All Phase 0 items are now complete.
- Phase 1's object list now includes `SD Investment`, making six record types. The relationships, seed and pass conditions are updated.

# BUILD PLAN — <build name>

<!-- STUB. Populated during Phase 0 in the claude.ai Project (see GETTING_STARTED.md §3). The preflight in CLAUDE.md §2 treats this file as unpopulated while this marker line is present or the Build Phases section holds no checklist item. Delete this line when the plan is real. -->

**What the plan gate checks (`CLAUDE.md` §2, step 1).** It checks structure only, and passes when both of these hold:

1. The stub marker line above (`<!-- STUB. …`) is gone.
2. There is a `## Build Phases` heading, and beneath it, before the next `##` heading, at least one checklist line: `- [ ] …` or `- ✅ …`.

Phase headings sit under that heading as `###`. A plan written elsewhere under other headings (for example `## Phase 1 — …` at the top level) fails the gate for formatting reasons alone. Move its phases under `## Build Phases` as `###` headings and leave their content unchanged. The Demo Narrative, Personas and Data Model sections are not checked by the gate. A retrofitted plan may point to where that content already lives instead of copying it.

This file is the build's high-level checklist and its state of record for what is done and what remains: phases and features as status-markable items, with `- [ ]` becoming `- ✅ <date>` at close-out and newly discovered work added to the right phase. It is deliberately not a specification. Detailed build specs live in the prompts themselves under `prompts/`, mockups are the contract for interfaces, and the environment's actual state is `BUILD_LOG.md`. A close-out that built something but did not touch this file is incomplete (`CLAUDE.md` §10).

## Demo Narrative

*(Open with the industry, domain and use case in a sentence or two, because the claude.ai Project reads them from here rather than from its instructions. Then the story the demo tells, beat by beat, for its audience: what the room sees first, what each beat proves, where the agent and the governance moments land, and what the closing beat leaves them with. Written in the domain's own vocabulary.)*

## Personas and What Each Sees

*(Each role that appears in the demo — the screens they open, what they care about, and what they should and should not see and be able to do. This is where that is written: the claude.ai Project reads this section when it authors the verification section of each build prompt, and the security scope and the display vocabulary follow from it. Keep it current at close-out like the rest of the plan. When a build changes what a persona sees or can do, update this section in the same close-out.)*

*(Which personas need local-password accounts, so that sessions can verify their views through sail? SSO-only identities cannot log in to it (`reference/patterns.md` §12). List each account to create; the operator logs each one in (`GETTING_STARTED.md` §1, *Persona sail logins — step by step*).)*

## Data Model (entity level)

*(The entities, their relationships, and which are reference data, transactional data, and demo-created data. Field-level detail comes later, in the build prompts; this section settles what exists and how it joins.)*

## Build Phases

*(Checklist form. One phase per heading, one line per feature or gate, status-markable. Phase 0 is planning; the first Claude Code session happens only when the sections above are populated.)*

### Phase 0 — Plan

### Phase 1 — Foundation

### Phase 2 — <next phase>

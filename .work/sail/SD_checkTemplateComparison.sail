/* Draw approval (Phase 5): the deterministic gate on the AI comparison (examples/deterministic-validation-gauntlet.md).
   The AI proposes; this rule decides whether its answer is used. The answer must be the line format the prompt asks for:
     OVERVIEW|<paragraph>                      exactly one, non-empty, at most 700 characters, no quotation marks,
                                               no digits or number words, no change verbs (it summarises; it
                                               must not count or restate the changes), and it names only parts
                                               of the workbook (header fields / columns / category rows) that changed
     CHANGE|<KIND>|<baseline>|<received>|<sentence>   one per difference
   and every CHANGE line must hold against the diff computed from the two workbooks (ri!diff, SD_diffTemplateStructure):
     - KIND is a known kind; a RENAMED/REMOVED label is one the diff lists as removed from that family (column, row,
       field), a RENAMED/ADDED label one it lists as added; the unused side is empty;
     - a RENAMED pair sits in the same place (positions equal once the other removed/added labels are set aside);
     - the sentence quotes exactly its own label(s) and no other, and holds no stray | ;
     - every label the diff lists is explained exactly once (nothing missed, nothing invented, nothing doubled).
   Nothing is parsed with a!fromJson, so a malformed answer cannot throw; it fails the gate instead.
   Returns a map: ok (everything passed), aiUsed (the change lines passed and are used), overviewByAi, failures,
   overview, bullets, footer, text (≤ 4,000 characters, the value stored on the draw:
   overview, one "• " line per change, the footer). When only the overview fails, the AI's change lines are kept under
   standard summary wording. When the change lines fail, or no AI call was made (ri!aiAttempted false), the text is
   composed from the diff by rules, which list removals and additions without pairing renames. */
a!localVariables(
  local!diff: if(a!isNullOrEmpty(ri!diff), a!map(count: 0), ri!diff),
  local!diffCount: a!defaultValue(index(local!diff, "count", 0), 0),
  local!baselineLabel: a!defaultValue(ri!baselineLabel, "the last template that loaded"),
  local!raw: substitute(
    substitute(substitute(a!defaultValue(ri!response, ""), char(13), ""), "“", char(34)),
    "”",
    char(34)
  ),
  local!lines: if(
    local!raw = "",
    {},
    a!forEach(items: split(local!raw, char(10)), expression: trim(a!defaultValue(fv!item, "")))
  ),
  local!lineCount: count(local!lines),
  local!overviewLines: if(
    local!lineCount = 0,
    {},
    index(local!lines, where(a!forEach(items: local!lines, expression: left(fv!item, 9) = "OVERVIEW|")), {})
  ),
  local!changeLines: if(
    local!lineCount = 0,
    {},
    index(local!lines, where(a!forEach(items: local!lines, expression: left(fv!item, 7) = "CHANGE|")), {})
  ),
  local!overviewCount: if(a!isNullOrEmpty(local!overviewLines), 0, count(local!overviewLines)),
  local!changeCount: if(a!isNullOrEmpty(local!changeLines), 0, count(local!changeLines)),
  /* a | between the overview's sentences (seen on live calls) is a separator, not content: read as a space */
  local!overview: if(
    local!overviewCount = 0,
    "",
    trim(substitute(mid(tostring(index(local!overviewLines, 1, "")), 10, 4000), "|", " "))
  ),
  /* the overview must not count: a miscount is an invented fact the per-line checks cannot see (observed on the first live call) */
  local!overviewWords: if(
    local!overview = "",
    {},
    split(
      lower(
        substitute(substitute(substitute(substitute(substitute(substitute(substitute(
          local!overview, ",", " "), ".", " "), ";", " "), ":", " "), "(", " "), ")", " "), "—", " ")
      ),
      " "
    )
  ),
  local!numberWords: {"one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten", "eleven", "twelve"},
  /* ... nor restate individual changes: the second live call described one rename twice. Summaries only. */
  local!changeWords: {
    "renamed", "retitled", "relabeled", "relabelled", "removed", "dropped", "deleted", "added", "inserted", "missing",
    "omitted", "replaced"
  },
  local!overviewRestates: if(
    local!overview = "",
    false,
    or(a!forEach(items: local!changeWords, expression: contains(touniformstring(local!overviewWords), fv!item)))
  ),
  /* ... nor name a part of the workbook that did not change (header fields / columns / category rows) */
  local!overviewFamilies: {
    if(or(contains(touniformstring(local!overviewWords), "header"), contains(touniformstring(local!overviewWords), "field"), contains(touniformstring(local!overviewWords), "fields")), "FIELD", {}),
    if(or(contains(touniformstring(local!overviewWords), "column"), contains(touniformstring(local!overviewWords), "columns")), "COLUMN", {}),
    if(or(contains(touniformstring(local!overviewWords), "row"), contains(touniformstring(local!overviewWords), "rows"), contains(touniformstring(local!overviewWords), "category"), contains(touniformstring(local!overviewWords), "categories")), "ROW", {})
  },
  local!changedFamilies: {
    if(and(a!isNullOrEmpty(index(local!diff, "fieldsRemoved", {})), a!isNullOrEmpty(index(local!diff, "fieldsAdded", {}))), {}, "FIELD"),
    if(and(a!isNullOrEmpty(index(local!diff, "columnsRemoved", {})), a!isNullOrEmpty(index(local!diff, "columnsAdded", {}))), {}, "COLUMN"),
    if(and(a!isNullOrEmpty(index(local!diff, "rowsRemoved", {})), a!isNullOrEmpty(index(local!diff, "rowsAdded", {}))), {}, "ROW")
  },
  local!overviewWrongPart: if(
    a!isNullOrEmpty(local!overviewFamilies),
    false,
    or(
      a!forEach(
        items: local!overviewFamilies,
        expression: if(a!isNullOrEmpty(local!changedFamilies), true, not(contains(touniformstring(local!changedFamilies), fv!item)))
      )
    )
  ),
  local!overviewCounts: if(
    local!overview = "",
    false,
    or(
      or(a!forEach(items: enumerate(10), expression: find(tostring(fv!item), local!overview) > 0)),
      or(a!forEach(items: local!numberWords, expression: contains(touniformstring(local!overviewWords), fv!item)))
    )
  ),
  local!kinds: {
    "COLUMN_RENAMED", "COLUMN_REMOVED", "COLUMN_ADDED", "ROW_RENAMED", "ROW_REMOVED", "ROW_ADDED",
    "FIELD_RENAMED", "FIELD_REMOVED", "FIELD_ADDED"
  },
  local!norm: a!forEach(
    items: {
      a!map(family: "COLUMN", removed: index(local!diff, "columnsRemoved", {}), added: index(local!diff, "columnsAdded", {}),
        before: index(local!diff, "baselineColumns", {}), after: index(local!diff, "receivedColumns", {})),
      a!map(family: "ROW", removed: index(local!diff, "rowsRemoved", {}), added: index(local!diff, "rowsAdded", {}),
        before: index(local!diff, "baselineRows", {}), after: index(local!diff, "receivedRows", {})),
      a!map(family: "FIELD", removed: index(local!diff, "fieldsRemoved", {}), added: index(local!diff, "fieldsAdded", {}),
        before: index(local!diff, "baselineFields", {}), after: index(local!diff, "receivedFields", {}))
    },
    expression: a!map(
      family: fv!item.family,
      removed: if(a!isNullOrEmpty(fv!item.removed), {}, a!forEach(items: fv!item.removed, expression: lower(trim(fv!item)))),
      added: if(a!isNullOrEmpty(fv!item.added), {}, a!forEach(items: fv!item.added, expression: lower(trim(fv!item)))),
      before: if(a!isNullOrEmpty(fv!item.before), {}, a!forEach(items: fv!item.before, expression: lower(trim(fv!item)))),
      after: if(a!isNullOrEmpty(fv!item.after), {}, a!forEach(items: fv!item.after, expression: lower(trim(fv!item))))
    )
  ),
  local!parsed: if(
    local!changeCount = 0,
    {},
    a!forEach(
      items: local!changeLines,
      expression: a!localVariables(
        local!p: split(fv!item, "|"),
        local!kind: upper(trim(a!defaultValue(index(local!p, 2, ""), ""))),
        local!family: a!defaultValue(index(split(local!kind, "_"), 1, ""), ""),
        local!action: a!defaultValue(index(split(local!kind, "_"), 2, ""), ""),
        local!from: trim(a!defaultValue(index(local!p, 3, ""), "")),
        local!to: trim(a!defaultValue(index(local!p, 4, ""), "")),
        local!sentence: trim(a!defaultValue(index(local!p, 5, ""), "")),
        local!fam: index(local!norm, index(wherecontains(local!family, {"COLUMN", "ROW", "FIELD"}), 1, 0), null),
        local!removedN: a!defaultValue(index(local!fam, "removed", {}), {}),
        local!addedN: a!defaultValue(index(local!fam, "added", {}), {}),
        local!needFrom: or(local!action = "RENAMED", local!action = "REMOVED"),
        local!needTo: or(local!action = "RENAMED", local!action = "ADDED"),
        local!fromOk: if(
          local!needFrom,
          if(or(local!from = "", a!isNullOrEmpty(local!removedN)), false, contains(local!removedN, lower(local!from))),
          local!from = ""
        ),
        local!toOk: if(
          local!needTo,
          if(or(local!to = "", a!isNullOrEmpty(local!addedN)), false, contains(local!addedN, lower(local!to))),
          local!to = ""
        ),
        /* contains() on an empty (Any Type) list fails on type, so every contains() on a diff list is guarded (measured).
           A rename must sit in the same place: the old label's position in the baseline, other removed labels set
           aside, equals the new label's position in the received file, other added labels set aside */
        local!beforeN: a!defaultValue(index(local!fam, "before", {}), {}),
        local!afterN: a!defaultValue(index(local!fam, "after", {}), {}),
        local!keptBefore: if(
          a!isNullOrEmpty(local!beforeN),
          {},
          index(
            local!beforeN,
            where(a!forEach(items: local!beforeN, expression: if(a!isNullOrEmpty(local!removedN), true, or(fv!item = lower(local!from), not(contains(local!removedN, fv!item)))))),
            {}
          )
        ),
        local!keptAfter: if(
          a!isNullOrEmpty(local!afterN),
          {},
          index(
            local!afterN,
            where(a!forEach(items: local!afterN, expression: if(a!isNullOrEmpty(local!addedN), true, or(fv!item = lower(local!to), not(contains(local!addedN, fv!item)))))),
            {}
          )
        ),
        local!posBefore: if(a!isNullOrEmpty(local!keptBefore), 0, index(wherecontains(lower(local!from), local!keptBefore), 1, 0)),
        local!posAfter: if(a!isNullOrEmpty(local!keptAfter), 0, index(wherecontains(lower(local!to), local!keptAfter), 1, 0)),
        local!placeOk: if(
          local!action = "RENAMED",
          and(local!posBefore > 0, local!posBefore = local!posAfter),
          true
        ),
        local!qParts: if(local!sentence = "", {}, split(local!sentence, char(34))),
        local!qn: count(local!qParts),
        local!quoted: if(
          local!qn < 3,
          {},
          a!forEach(
            items: enumerate(floor((local!qn - 1) / 2)),
            expression: lower(trim(a!defaultValue(index(local!qParts, 2 * fv!item + 2, ""), "")))
          )
        ),
        local!expected: {if(local!from = "", {}, lower(local!from)), if(local!to = "", {}, lower(local!to))},
        /* and() evaluates every argument, so the empty cases are guarded by if() rather than inside and() */
        local!quotesOk: if(
          or(local!qn < 3, mod(local!qn - 1, 2) <> 0, count(local!expected) = 0),
          false,
          and(
            and(a!forEach(items: local!quoted, expression: contains(local!expected, fv!item))),
            and(a!forEach(items: local!expected, expression: contains(local!quoted, fv!item)))
          )
        ),
        local!line: "change " & fv!index & " (" & local!kind & ")",
        a!map(
          family: local!family,
          action: local!action,
          fromN: if(local!needFrom, lower(local!from), ""),
          toN: if(local!needTo, lower(local!to), ""),
          sentence: local!sentence,
          failure: if(
            not(contains(local!kinds, local!kind)),
            local!line & ": unknown kind",
            if(
              not(isnull(index(local!p, 6, null))),
              local!line & ": a | inside the sentence",
              if(
                local!sentence = "",
                local!line & ": no sentence",
                if(
                  not(local!fromOk),
                  local!line & ": """ & local!from & """ is not a removed " & lower(local!family) & " label",
                  if(
                    not(local!toOk),
                    local!line & ": """ & local!to & """ is not an added " & lower(local!family) & " label",
                    if(
                      not(local!placeOk),
                      local!line & ": """ & local!to & """ does not sit where """ & local!from & """ was, so it is not a rename of it",
                      if(not(local!quotesOk), local!line & ": the sentence does not quote exactly its own label(s)", "")
                    )
                  )
                )
              )
            )
          )
        )
      )
    )
  ),
  local!usedFrom: if(local!changeCount = 0, {}, a!forEach(items: local!parsed, expression: fv!item.family & "|" & fv!item.fromN)),
  local!usedTo: if(local!changeCount = 0, {}, a!forEach(items: local!parsed, expression: fv!item.family & "|" & fv!item.toN)),
  local!coverage: a!forEach(
    items: local!norm,
    expression: a!localVariables(
      local!fam: fv!item,
      joinarray(
        {
          a!forEach(
            items: local!fam.removed,
            expression: a!localVariables(
              local!k: count(if(local!changeCount = 0, {}, wherecontains(local!fam.family & "|" & fv!item, local!usedFrom))),
              if(local!k = 1, {}, "removed " & lower(local!fam.family) & " """ & fv!item & """ explained " & local!k & " times")
            )
          ),
          a!forEach(
            items: local!fam.added,
            expression: a!localVariables(
              local!k: count(if(local!changeCount = 0, {}, wherecontains(local!fam.family & "|" & fv!item, local!usedTo))),
              if(local!k = 1, {}, "added " & lower(local!fam.family) & " """ & fv!item & """ explained " & local!k & " times")
            )
          )
        },
        "; "
      )
    )
  ),
  local!changeFailures: if(local!changeCount = 0, {}, a!forEach(items: local!parsed, expression: fv!item.failure)),
  /* two groups: the change lines (the facts) and the overview (the summary). Facts that pass are used even when the
     summary fails; the summary is then standard wording and the footer says so. */
  local!lineFailuresAll: {
    if(a!defaultValue(ri!aiAttempted, true), {}, "no AI call was made"),
    if(
      a!defaultValue(ri!success, false),
      {},
      "the AI call did not succeed" & if(a!isNullOrEmpty(ri!errorMessage), "", ": " & ri!errorMessage)
    ),
    local!changeFailures,
    local!coverage
  },
  local!overviewFailuresAll: {
    if(local!overviewCount = 1, {}, "expected one OVERVIEW line, found " & local!overviewCount),
    if(local!overview = "", "the overview is empty", {}),
    if(len(local!overview) > 700, "the overview is longer than 700 characters", {}),
    if(find(char(34), local!overview) > 0, "the overview quotes a label", {}),
    if(local!overviewCounts, "the overview counts the changes", {}),
    if(local!overviewRestates, "the overview restates individual changes", {}),
    if(local!overviewWrongPart, "the overview names a part of the workbook that did not change", {})
  },
  local!lineFailures: if(
    a!isNullOrEmpty(local!lineFailuresAll),
    {},
    index(local!lineFailuresAll, where(len(local!lineFailuresAll) > 0), {})
  ),
  local!overviewFailures: if(
    a!isNullOrEmpty(local!overviewFailuresAll),
    {},
    index(local!overviewFailuresAll, where(len(local!overviewFailuresAll) > 0), {})
  ),
  local!failures: {local!lineFailures, local!overviewFailures},
  local!linesOk: a!isNullOrEmpty(local!lineFailures),
  local!overviewOk: a!isNullOrEmpty(local!overviewFailures),
  local!ok: and(local!linesOk, local!overviewOk),
  local!models: a!genAiModels(),
  local!modelName: index(
    index(local!models, "name", {}),
    index(wherecontains(tostring(cons!SD_TEMPLATE_COMPARISON_MODEL), touniformstring(index(local!models, "id", {}))), 1, 0),
    "AI"
  ),
  local!ruleBullets: {
    a!forEach(items: index(local!diff, "columnsRemoved", {}), expression: "• The column “" & fv!item & "” is missing."),
    a!forEach(items: index(local!diff, "columnsAdded", {}), expression: "• There is a column “" & fv!item & "” that the earlier template does not have."),
    a!forEach(items: index(local!diff, "rowsRemoved", {}), expression: "• The budget line “" & fv!item & "” is missing."),
    a!forEach(items: index(local!diff, "rowsAdded", {}), expression: "• There is a budget line “" & fv!item & "” that the earlier template does not have."),
    a!forEach(items: index(local!diff, "fieldsRemoved", {}), expression: "• The header field “" & fv!item & "” is missing."),
    a!forEach(items: index(local!diff, "fieldsAdded", {}), expression: "• There is a header field “" & fv!item & "” that the earlier template does not have.")
  },
  local!ruleOverview: if(
    local!diffCount = 0,
    "The layout of this file matches " & local!baselineLabel & ": no columns, budget lines or header fields were added, removed or renamed, so the problem is not in the layout.",
    "This file is laid out differently from " & local!baselineLabel & ", so its budget lines could not be matched to the draw. The differences are listed below; the sender should restore the standard layout and resend it."
  ),
  local!aiBullets: if(
    local!changeCount = 0,
    {},
    a!forEach(items: local!parsed, expression: "• " & rule!SD_curlQuotes(text: fv!item.sentence))
  ),
  local!bullets: if(local!linesOk, local!aiBullets, local!ruleBullets),
  local!footer: if(
    local!linesOk,
    "Compared with " & local!baselineLabel & " by AI (" & local!modelName & "); every change listed was checked against both workbooks"
      & if(local!overviewOk, ".", " (summary in standard wording)."),
    "Compared with " & local!baselineLabel & ". Listed from the two workbooks by rules"
      & if(a!defaultValue(ri!aiAttempted, true), " because the AI comparison did not pass its checks.", ".")
  ),
  local!overviewOut: if(local!ok, local!overview, local!ruleOverview),
  local!text: local!overviewOut
    & if(a!isNullOrEmpty(local!bullets), "", char(10) & joinarray(local!bullets, char(10)))
    & char(10) & local!footer,
  a!map(
    ok: local!ok,
    aiUsed: local!linesOk,
    overviewByAi: local!ok,
    failures: local!failures,
    overview: local!overviewOut,
    bullets: local!bullets,
    footer: local!footer,
    changeCount: local!changeCount,
    text: if(len(local!text) > 4000, left(local!text, 3997) & "…", local!text)
  )
)

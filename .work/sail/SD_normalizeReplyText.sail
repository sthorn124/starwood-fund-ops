/* Draw approval (Phase 6b): reply text normalised for comparison by the interpretation gate. Lower case, curly quotes
   and apostrophes made straight, every run of whitespace (spaces, tabs, line breaks) one space, trimmed. With forCues,
   punctuation also becomes spaces and the result is padded with one space each side, so a cue such as " go ahead"
   matches whole words only ("don't" becomes "don t"). */
a!localVariables(
  local!cues: a!defaultValue(ri!forCues, false),
  local!t0: lower(a!defaultValue(ri!text, "")),
  local!t1: substitute(substitute(substitute(substitute(local!t0, "’", "'"), "‘", "'"), "“", """"), "”", """"),
  local!t2: if(
    local!cues,
    substitute(substitute(substitute(substitute(substitute(substitute(substitute(substitute(substitute(substitute(substitute(substitute(substitute(substitute(substitute(substitute(substitute(substitute(substitute(local!t1, ".", " "), ",", " "), "!", " "), "?", " "), ";", " "), ":", " "), """", " "), "'", " "), "(", " "), ")", " "), "-", " "), "*", " "), "/", " "), "_", " "), "[", " "), "]", " "), "…", " "), "–", " "), "—", " "),
    local!t1
  ),
  local!words: reject(
    fn!isnull,
    a!forEach(
      items: split(substitute(substitute(substitute(local!t2, char(13), " "), char(10), " "), char(9), " "), " "),
      expression: if(trim(a!defaultValue(fv!item, "")) = "", null, trim(fv!item))
    )
  ),
  local!joined: if(a!isNullOrEmpty(local!words), "", joinarray(local!words, " ")),
  if(local!cues, " " & local!joined & " ", local!joined)
)

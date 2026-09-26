/* Draw approval (Phase 6a): the reply's own words. A mail client's reply carries the whole approval email beneath
   it (quoted with ">" in plain text, or after an "On <date>, <name> wrote:" line, or in an HTML quote container), and
   that email itself says "Approve" and "Reject", so the history must never reach the interpretation. An HTML body is
   cut at its quote container and stripped line by line; the text is then cut
   at the first quote marker (a ">" line, an "On … wrote:" line — also when the client wraps it onto a second line —
   "-----Original Message-----", an Outlook
   "From:" header block or its underscore divider, "Sent from my …"); blank lines collapse; at most 2,000 characters. */
a!localVariables(
  local!raw: substitute(substitute(a!defaultValue(ri!body, ""), char(13) & char(10), char(10)), char(13), char(10)),
  /* HTML only when real markup is present: a plain-text reply can hold "<name@host>" in its attribution line, and
     stripHtml() deletes plain newlines (measured), which would weld the reply to the quoted history */
  local!isHtml: or(
    search("<html", local!raw) > 0, search("<body", local!raw) > 0, search("<div", local!raw) > 0,
    search("<br", local!raw) > 0, search("<p>", local!raw) > 0, search("<p ", local!raw) > 0, search("</", local!raw) > 0
  ),
  /* HTML: cut at the client's quote container (Gmail's gmail_quote div, a blockquote, Outlook's reply header or rule)
     before stripping, then turn line-ending tags into line breaks and strip each line on its own */
  local!cutAt: a!localVariables(
    local!hits: a!forEach(
      items: {"<div class=""gmail_quote", "class=""gmail_quote", "<blockquote", "id=""divRplyFwdMsg", "id=""appendonsend", "<hr"},
      expression: search(fv!item, local!raw)
    ),
    local!found: where(a!forEach(items: local!hits, expression: fv!item > 0)),
    if(a!isNullOrEmpty(local!found), 0, min(index(local!hits, local!found, {})))
  ),
  local!htmlPart: if(local!cutAt > 1, left(local!raw, local!cutAt - 1), if(local!cutAt = 1, "", local!raw)),
  local!htmlBroken: a!localVariables(
    local!h: local!htmlPart,
    local!h2: substitute(substitute(substitute(substitute(local!h, "<br>", char(10)), "<br/>", char(10)), "<br />", char(10)), "<BR>", char(10)),
    local!h3: substitute(substitute(substitute(substitute(local!h2, "</div>", char(10)), "</DIV>", char(10)), "</p>", char(10)), "</P>", char(10)),
    joinarray(a!forEach(items: split(local!h3, char(10)), expression: stripHtml(a!defaultValue(fv!item, ""))), char(10))
  ),
  local!norm: if(local!isHtml, local!htmlBroken, local!raw),
  local!lines: split(local!norm, char(10)),
  local!n: count(local!lines),
  local!isMarker: a!forEach(
    items: local!lines,
    expression: a!localVariables(
      local!t: trim(a!defaultValue(fv!item, "")),
      or(
        left(local!t, 1) = ">",
        and(left(local!t, 3) = "On ", or(right(local!t, 6) = "wrote:", right(trim(a!defaultValue(index(local!lines, fv!index + 1, ""), "")), 6) = "wrote:")),
        search("-----Original Message-----", local!t) > 0,
        left(local!t, 10) = "__________",
        and(left(local!t, 5) = "From:", fv!index > 1),
        left(local!t, 13) = "Sent from my "
      )
    )
  ),
  local!firstMarker: if(local!n = 0, 0, a!localVariables(local!w: where(local!isMarker), if(a!isNullOrEmpty(local!w), 0, index(local!w, 1, 0)))),
  local!kept: if(local!n = 0, {}, if(local!firstMarker = 0, local!lines, if(local!firstMarker = 1, {}, index(local!lines, enumerate(local!firstMarker - 1) + 1, {})))),
  local!nonBlank: if(a!isNullOrEmpty(local!kept), {}, a!forEach(items: local!kept, expression: if(trim(a!defaultValue(fv!item, "")) = "", "", trim(fv!item)))),
  local!joined: trim(joinarray(reject(fn!isnull, a!forEach(items: local!nonBlank, expression: if(fv!item = "", null, fv!item))), char(10))),
  left(local!joined, 2000)
)

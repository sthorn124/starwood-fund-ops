/* Phase 6a gauntlet: the deterministic parts of reading an email reply. Each specimen states its expected result;
   the run returns one "PASS <id>" / "FAIL <id>: <got>" line per specimen. Re-run after any change to
   SD_parseReplyToken, SD_extractReplyText or SD_gateReplyInterpretation, or to the interpretation prompt's format.
   T  token: the draw and step survive Re:/Fwd: prefixes; anything malformed is not found.
   X  extraction: the reply's own words only; quoted history (which itself says "Approve" and "Reject") never passes.
   G  gate: exactly the two expected lines, a known decision, a verbatim comment; anything else is AMBIGUOUS and
      unclassified (classified = false), never a guess. */
a!localVariables(
  local!t: a!forEach(
    items: {
      a!map(id: "T1 plain", s: "Draw approval requested: Draw #77 · Tamarack Hotel & Spa Vail · CEO [SD-DRAW-92-S9]", want: "true|92|9"),
      a!map(id: "T2 Re:", s: "Re: Draw approval requested: Draw #77 · Tamarack Hotel & Spa Vail · CEO [SD-DRAW-92-S9]", want: "true|92|9"),
      a!map(id: "T3 RE: Fwd: lower case", s: "RE: Fwd: draw approval requested [sd-draw-12-s6]", want: "true|12|6"),
      a!map(id: "T4 no token", s: "Re: Draw approval requested: Draw #77", want: "false||"),
      a!map(id: "T5 letters in id", s: "Re: [SD-DRAW-9x-S9]", want: "false||"),
      a!map(id: "T6 no step prefix", s: "Re: [SD-DRAW-92-9]", want: "false||"),
      a!map(id: "T7 unclosed", s: "Re: [SD-DRAW-92-S9", want: "false||"),
      a!map(id: "T8 extra part", s: "Re: [SD-DRAW-92-S9-X]", want: "false||")
    },
    expression: a!localVariables(
      local!r: rule!SD_parseReplyToken(subject: fv!item.s),
      local!got: lower(tostring(local!r.found)) & "|" & a!defaultValue(local!r.drawId, "") & "|" & a!defaultValue(local!r.stepOrder, ""),
      if(local!got = fv!item.want, "PASS " & fv!item.id, "FAIL " & fv!item.id & ": " & local!got)
    )
  ),
  local!x: a!forEach(
    items: {
      a!map(id: "X1 Gmail plain with quote", b: "Looks good, approve." & char(10) & char(10) & "On Fri, Sep 26, 2026 at 9:40 AM Starwood Draw Approvals <x@y> wrote:" & char(10) & "> Reply Approve or Reject to this email" & char(10) & "> Draw #77", want: "Looks good, approve."),
      a!map(id: "X2 wrapped attribution", b: "Reject - hold until the lender signs off." & char(10) & "On Fri, Sep 26, 2026 at 9:40 AM Starwood Draw Approvals <" & char(10) & "processmodeluuid1@ny.appiancloud.com> wrote:" & char(10) & "> Approve", want: "Reject - hold until the lender signs off."),
      a!map(id: "X3 HTML reply", b: "<div dir=""ltr"">thanks, will look at this</div><br><div class=""gmail_quote"">On Fri wrote:<blockquote>Approve</blockquote></div>", want: "thanks, will look at this"),
      a!map(id: "X4 Outlook block", b: "Approved." & char(13) & char(10) & char(13) & char(10) & "________________________________" & char(13) & char(10) & "From: Starwood Draw Approvals" & char(13) & char(10) & "Sent: Friday" & char(13) & char(10) & "Reply Approve or Reject", want: "Approved."),
      a!map(id: "X5 signature", b: "OK to fund." & char(10) & "Sent from my iPhone", want: "OK to fund."),
      a!map(id: "X6 two paragraphs kept", b: "Approved." & char(10) & char(10) & "Please release on the 15th." & char(10) & "> quoted", want: "Approved." & char(10) & "Please release on the 15th."),
      a!map(id: "X7 only a quote", b: "> Approve" & char(10) & "> Reject", want: ""),
      a!map(id: "X8 empty", b: "", want: "")
    },
    expression: a!localVariables(
      local!got: rule!SD_extractReplyText(body: fv!item.b),
      if(local!got = fv!item.want, "PASS " & fv!item.id, "FAIL " & fv!item.id & ": [" & local!got & "]")
    )
  ),
  local!reply: "Looks good, approve. Please release funds on the 15th.",
  local!g: a!forEach(
    items: {
      a!map(id: "G1 approve with comment", ok: true, r: "DECISION|APPROVE" & char(10) & "COMMENT|Please release funds on the 15th.", want: "true|APPROVE|Please release funds on the 15th."),
      a!map(id: "G2 reject no comment", ok: true, r: "DECISION|REJECT" & char(10) & "COMMENT|", want: "true|REJECT|"),
      a!map(id: "G3 ambiguous", ok: true, r: "DECISION|AMBIGUOUS" & char(10) & "COMMENT|", want: "true|AMBIGUOUS|"),
      a!map(id: "G4 comment not verbatim", ok: true, r: "DECISION|APPROVE" & char(10) & "COMMENT|Release on the fifteenth", want: "true|APPROVE|"),
      a!map(id: "G5 fenced, blank lines", ok: true, r: "```" & char(10) & "DECISION|APPROVE" & char(10) & char(10) & "COMMENT|" & char(10) & "```", want: "true|APPROVE|"),
      a!map(id: "G6 lower case decision", ok: true, r: "decision|approve" & char(10) & "comment|", want: "true|APPROVE|"),
      a!map(id: "G7 unknown decision", ok: true, r: "DECISION|YES" & char(10) & "COMMENT|", want: "false|AMBIGUOUS|"),
      a!map(id: "G8 two decisions", ok: true, r: "DECISION|APPROVE" & char(10) & "DECISION|REJECT" & char(10) & "COMMENT|", want: "false|AMBIGUOUS|"),
      a!map(id: "G9 extra prose", ok: true, r: "The approver approves." & char(10) & "DECISION|APPROVE" & char(10) & "COMMENT|", want: "false|AMBIGUOUS|"),
      a!map(id: "G10 no decision line", ok: true, r: "COMMENT|Please release funds on the 15th.", want: "false|AMBIGUOUS|"),
      a!map(id: "G11 call failed", ok: false, r: "", want: "false|AMBIGUOUS|"),
      a!map(id: "G12 empty answer", ok: true, r: "", want: "false|AMBIGUOUS|"),
      a!map(id: "G13 comment only case differs", ok: true, r: "DECISION|APPROVE" & char(10) & "COMMENT|please RELEASE funds on the 15th.", want: "true|APPROVE|please RELEASE funds on the 15th.")
    },
    expression: a!localVariables(
      local!r: rule!SD_gateReplyInterpretation(success: fv!item.ok, response: fv!item.r, errorMessage: if(fv!item.ok, "", "timeout"), replyText: local!reply),
      local!got: lower(tostring(local!r.classified)) & "|" & local!r.decision & "|" & local!r.comment,
      if(local!got = fv!item.want, "PASS " & fv!item.id, "FAIL " & fv!item.id & ": " & local!got & " (" & local!r.reason & ")")
    )
  ),
  a!flatten({local!t, local!x, local!g})
)

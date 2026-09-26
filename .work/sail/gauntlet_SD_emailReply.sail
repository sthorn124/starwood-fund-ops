/* Phase 6a/6b gauntlet: the deterministic parts of reading an email reply. Each specimen states its expected result;
   the run returns one "PASS <id>" / "FAIL <id>: <got>" line per specimen. Re-run after any change to
   SD_parseReplyToken, SD_extractReplyText, SD_normalizeReplyText or SD_gateReplyInterpretation, or to the
   interpretation prompt's output format.
   T  token: the draw and step survive Re:/Fwd: prefixes; anything malformed is not found.
   X  extraction: the reply's own words only; quoted history (which itself says "Approve" and "Reject") never passes;
      a delimited signature is cut (X9, X10); an undelimited plain-text signature stays (X11, pinned: Gmail's
      plain-text part, measured on Scott's live reply).
   G  format (Phase 6b three-line answer): anything malformed is AMBIGUOUS and unclassified (classified = false).
   N  grounding (Phase 6b): the decisive phrase must be in the reply, and its sentence must read as what the model
      said; a hedge, a condition, praise, a refusal read as approval or a fabricated phrase is AMBIGUOUS, never applied.
   Expected strings: classified|decision|phrase|question|comment. */
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
      a!map(id: "X8 empty", b: "", want: ""),
      a!map(id: "X9 -- delimiter", b: "What is driving the contingency spend?" & char(10) & "-- " & char(10) & "Scott Thorn" & char(10) & "Appian", want: "What is driving the contingency spend?"),
      a!map(id: "X10 HTML gmail_signature", b: "<div dir=""ltr"">Approved.<br clear=""all""><div><div dir=""ltr"" class=""gmail_signature"" data-smartmail=""gmail_signature"">Scott Thorn<br>Appian</div></div></div>", want: "Approved."),
      a!map(id: "X11 plain signature kept (pinned)", b: "This looks good to me. Go ahead with the draw and proceed." & char(10) & "*Scott Thorn*" & char(10) & "appian.com", want: "This looks good to me. Go ahead with the draw and proceed." & char(10) & "*Scott Thorn*" & char(10) & "appian.com")
    },
    expression: a!localVariables(
      local!got: rule!SD_extractReplyText(body: fv!item.b),
      if(local!got = fv!item.want, "PASS " & fv!item.id, "FAIL " & fv!item.id & ": [" & local!got & "]")
    )
  ),
  local!cases: {
    /* format */
    a!map(id: "G1 call failed", ok: false, reply: "Approved.", r: "", want: "false|AMBIGUOUS|||"),
    a!map(id: "G2 empty answer", ok: true, reply: "Approved.", r: "", want: "false|AMBIGUOUS|||"),
    a!map(id: "G3 unknown decision", ok: true, reply: "Approved.", r: "DECISION|YES" & char(10) & "PHRASE|Approved." & char(10) & "COMMENT|", want: "false|AMBIGUOUS|||"),
    a!map(id: "G4 two decisions", ok: true, reply: "Approved.", r: "DECISION|APPROVE" & char(10) & "DECISION|REJECT" & char(10) & "PHRASE|Approved.", want: "false|AMBIGUOUS|||"),
    a!map(id: "G5 extra prose", ok: true, reply: "Approved.", r: "The approver approves." & char(10) & "DECISION|APPROVE" & char(10) & "PHRASE|Approved." & char(10) & "COMMENT|", want: "false|AMBIGUOUS|||"),
    a!map(id: "G6 two phrases", ok: true, reply: "Approved.", r: "DECISION|APPROVE" & char(10) & "PHRASE|Approved." & char(10) & "PHRASE|Approved" & char(10) & "COMMENT|", want: "false|AMBIGUOUS|||"),
    a!map(id: "G7 fenced, blank lines, lower-case keys", ok: true, reply: "Approved.", r: "```" & char(10) & "decision|approve" & char(10) & char(10) & "phrase|Approved." & char(10) & "comment|" & char(10) & "```", want: "true|APPROVE|Approved.||"),
    a!map(id: "G8 ambiguous, empty phrase", ok: true, reply: "Let me think about it.", r: "DECISION|AMBIGUOUS" & char(10) & "PHRASE|" & char(10) & "COMMENT|", want: "true|AMBIGUOUS|||"),
    a!map(id: "G9 approve without a PHRASE line", ok: true, reply: "Approved.", r: "DECISION|APPROVE" & char(10) & "COMMENT|", want: "true|AMBIGUOUS|||"),
    a!map(id: "G10 comment not verbatim dropped", ok: true, reply: "Looks good, approved. Please release funds on the 15th.", r: "DECISION|APPROVE" & char(10) & "PHRASE|Looks good, approved." & char(10) & "COMMENT|Release on the fifteenth", want: "true|APPROVE|Looks good, approved.||"),
    /* grounding */
    a!map(id: "N1 clean approve", ok: true, reply: "Looks good, approved. Please release funds on the 15th.", r: "DECISION|APPROVE" & char(10) & "PHRASE|Looks good, approved." & char(10) & "COMMENT|Please release funds on the 15th.", want: "true|APPROVE|Looks good, approved.||Please release funds on the 15th."),
    a!map(id: "N2 clean reject (a reason does not undo it)", ok: true, reply: "Reject. Hold this one until the lender signs off on the revised budget.", r: "DECISION|REJECT" & char(10) & "PHRASE|Reject. Hold this one until the lender signs off on the revised budget." & char(10) & "COMMENT|", want: "true|REJECT|Reject. Hold this one until the lender signs off on the revised budget.||"),
    a!map(id: "N3 question", ok: true, reply: "Before I sign, what's driving the contingency spend on this draw?", r: "DECISION|QUESTION" & char(10) & "PHRASE|what's driving the contingency spend on this draw?" & char(10) & "COMMENT|", want: "true|QUESTION|what's driving the contingency spend on this draw?|what's driving the contingency spend on this draw?|"),
    a!map(id: "N4 hedge called approve", ok: true, reply: "I'd lean towards approving, but let me check with Mark first.", r: "DECISION|APPROVE" & char(10) & "PHRASE|I'd lean towards approving, but let me check with Mark first." & char(10) & "COMMENT|", want: "true|AMBIGUOUS|I'd lean towards approving, but let me check with Mark first.||"),
    a!map(id: "N5 conditional except (phrase trimmed)", ok: true, reply: "Approve everything except line 3.", r: "DECISION|APPROVE" & char(10) & "PHRASE|Approve everything" & char(10) & "COMMENT|", want: "true|AMBIGUOUS|Approve everything||"),
    a!map(id: "N6 conditional if (phrase trimmed)", ok: true, reply: "Approved if the lender signs off.", r: "DECISION|APPROVE" & char(10) & "PHRASE|Approved" & char(10) & "COMMENT|", want: "true|AMBIGUOUS|Approved||"),
    a!map(id: "N7 enthusiasm is not approval", ok: true, reply: "Great work team!", r: "DECISION|APPROVE" & char(10) & "PHRASE|Great work team!" & char(10) & "COMMENT|", want: "true|AMBIGUOUS|Great work team!||"),
    a!map(id: "N8 fabricated phrase", ok: true, reply: "Let me look at this tomorrow.", r: "DECISION|APPROVE" & char(10) & "PHRASE|Approved, go ahead." & char(10) & "COMMENT|", want: "true|AMBIGUOUS|||"),
    a!map(id: "N9 question that is not one", ok: true, reply: "Nice job on this one.", r: "DECISION|QUESTION" & char(10) & "PHRASE|Nice job on this one." & char(10) & "COMMENT|", want: "true|AMBIGUOUS|Nice job on this one.||"),
    a!map(id: "N10 refusal called approve", ok: true, reply: "I can't approve this yet.", r: "DECISION|APPROVE" & char(10) & "PHRASE|I can't approve this yet." & char(10) & "COMMENT|", want: "true|AMBIGUOUS|I can't approve this yet.||"),
    a!map(id: "N11 same refusal called reject", ok: true, reply: "I can't approve this yet.", r: "DECISION|REJECT" & char(10) & "PHRASE|I can't approve this yet." & char(10) & "COMMENT|", want: "true|REJECT|I can't approve this yet.||"),
    a!map(id: "N12 Scott's live reply", ok: true, reply: "This looks good to me. Go ahead with the draw and proceed." & char(10) & "*Scott Thorn*" & char(10) & "Senior Advisory Solutions Consultant, Financial Services", r: "DECISION|APPROVE" & char(10) & "PHRASE|Go ahead with the draw and proceed." & char(10) & "COMMENT|This looks good to me.", want: "true|APPROVE|Go ahead with the draw and proceed.||This looks good to me."),
    a!map(id: "N13 phrase differs only in case and spacing", ok: true, reply: "Looks good,  APPROVED.", r: "DECISION|APPROVE" & char(10) & "PHRASE|looks good, approved." & char(10) & "COMMENT|", want: "true|APPROVE|looks good, approved.||"),
    a!map(id: "N14 fabricated question", ok: true, reply: "Approved.", r: "DECISION|QUESTION" & char(10) & "PHRASE|Why is contingency up?" & char(10) & "COMMENT|", want: "true|AMBIGUOUS|||"),
    a!map(id: "N15 approved for now", ok: true, reply: "Approved for now.", r: "DECISION|APPROVE" & char(10) & "PHRASE|Approved for now." & char(10) & "COMMENT|", want: "true|AMBIGUOUS|Approved for now.||"),
    a!map(id: "N16 later sentence's condition does not taint", ok: true, reply: "Approved. Let me know if you need anything else.", r: "DECISION|APPROVE" & char(10) & "PHRASE|Approved." & char(10) & "COMMENT|Let me know if you need anything else.", want: "true|APPROVE|Approved.||Let me know if you need anything else.")
  },
  local!g: a!forEach(
    items: local!cases,
    expression: a!localVariables(
      local!r: rule!SD_gateReplyInterpretation(success: fv!item.ok, response: fv!item.r, errorMessage: if(fv!item.ok, "", "timeout"), replyText: fv!item.reply),
      local!got: lower(tostring(local!r.classified)) & "|" & local!r.decision & "|" & a!defaultValue(local!r.phrase, "") & "|" & a!defaultValue(local!r.question, "") & "|" & a!defaultValue(local!r.comment, ""),
      if(local!got = fv!item.want, "PASS " & fv!item.id, "FAIL " & fv!item.id & ": " & local!got & " (" & local!r.reason & ")")
    )
  ),
  a!flatten({local!t, local!x, local!g})
)

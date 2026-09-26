/* Draw approval (Phase 6a): the exception-queue task for an email reply the flow would not act on — one the
   interpretation gate could not classify, or a second ambiguous reply on the same step. Assigned to SD Draw Demo
   Approvers (the demo's super-user). It shows why the reply is here and the reply itself, and records that a person
   reviewed it (with an optional note). It never changes the draw: the decision stays with the step's own task in the
   system (ruled — no state change on an unclear reply until a human decides in the UI). */
a!localVariables(
  local!d: if(a!isNullOrEmpty(ri!drawId), null, rule!SD_getDrawDetail(drawId: ri!drawId)),
  local!found: and(not(a!isNullOrEmpty(local!d)), a!defaultValue(index(local!d, "found", false), false)),
  local!drawLabel: if(
    local!found,
    "Draw #" & a!defaultValue(index(local!d, "drawNumber", ri!drawId), ri!drawId) & " · " & a!defaultValue(index(local!d, "investmentName", ""), ""),
    "Draw " & a!defaultValue(ri!drawId, "—")
  ),
  a!formLayout(
    titleBar: a!headerTemplateFull(
      title: "Email reply needs a person",
      secondaryText: local!drawLabel & " · " & if(a!defaultValue(ri!stepLabel, "") = "", "Step " & a!defaultValue(ri!stepOrder, "—"), ri!stepLabel),
      backgroundColor: "#16294D"
    ),
    contents: {
      a!richTextDisplayField(
        labelPosition: "COLLAPSED",
        value: {
          a!richTextItem(text: "WHY IT IS HERE", color: "#6B7280", size: "SMALL", style: "STRONG"),
          char(10),
          a!richTextItem(text: a!defaultValue(ri!reason, "The reply could not be acted on automatically."), color: "#92600A"),
          char(10),
          a!richTextItem(text: "Nothing on the draw has changed.", color: "#6B7280", size: "SMALL")
        },
        marginBelow: "STANDARD"
      ),
      a!richTextDisplayField(
        labelPosition: "COLLAPSED",
        value: {
          a!richTextItem(text: "THE REPLY", color: "#6B7280", size: "SMALL", style: "STRONG"),
          char(10),
          a!richTextItem(text: "From " & a!defaultValue(ri!fromAddress, "(unknown sender)"), color: "#6B7280", size: "SMALL"),
          char(10),
          a!richTextItem(text: if(a!defaultValue(ri!replyText, "") = "", "(no text in the reply)", ri!replyText))
        },
        marginBelow: "STANDARD"
      ),
      a!richTextDisplayField(
        labelPosition: "COLLAPSED",
        value: {
          a!richTextItem(text: "WHAT TO DO", color: "#6B7280", size: "SMALL", style: "STRONG"),
          char(10),
          a!richTextItem(text: "Contact the approver, or have them decide in the step task in the system. The full exchange is on the draw's Approvals tab. Mark this reviewed when it is handled.")
        },
        marginBelow: "STANDARD"
      ),
      a!paragraphField(
        label: "Review note",
        instructions: "Optional. Recorded on the draw with the email exchange.",
        value: ri!reviewNote,
        saveInto: ri!reviewNote,
        height: "SHORT"
      )
    },
    buttons: a!buttonLayout(
      primaryButtons: a!buttonWidget(
        label: "Mark Reviewed",
        submit: true,
        style: "SOLID",
        saveInto: a!save(ri!reviewedBy, tostring(loggedInUser()))
      )
    ),
    contentsWidth: "MEDIUM"
  )
)

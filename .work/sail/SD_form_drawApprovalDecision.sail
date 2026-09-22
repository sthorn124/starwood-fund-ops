/* Draw approval: step task form (Phase 1, minimal and functional).
   PHASE 2 RESTYLE TARGET: rebuilt against the approved mockup; no styling decisions are made here.
   ri!drawSummary and ri!stepLabel are display text composed by the step process. ri!decision
   (APPROVE / REJECT), ri!decisionComment and ri!actor are written back to the task's ACPs on submit:
   the Submit button records the acting user and defaults a blank comment, so no ACP submits null. */
a!formLayout(
  titleBar: a!defaultValue(ri!stepLabel, "Draw approval step"),
  contents: {
    a!richTextDisplayField(
      labelPosition: "COLLAPSED",
      value: a!richTextItem(text: a!defaultValue(ri!drawSummary, "Draw details unavailable"))
    ),
    a!radioButtonField(
      label: "Decision",
      choiceLabels: {"Approve", "Reject"},
      choiceValues: {"APPROVE", "REJECT"},
      value: if(a!defaultValue(ri!decision, "NONE") = "NONE", null, ri!decision),
      saveInto: ri!decision,
      required: true
    ),
    a!paragraphField(
      label: "Comments",
      value: if(a!defaultValue(ri!decisionComment, "-") = "-", null, ri!decisionComment),
      saveInto: ri!decisionComment,
      required: a!defaultValue(ri!decision, "") = "REJECT",
      requiredMessage: "A comment is required to reject a draw."
    )
  },
  buttons: a!buttonLayout(
    primaryButtons: a!buttonWidget(
      label: "Submit",
      submit: true,
      style: "SOLID",
      saveInto: {
        a!save(ri!actor, tostring(loggedInUser())),
        a!save(
          ri!decisionComment,
          if(
            or(a!isNullOrEmpty(ri!decisionComment), ri!decisionComment = "-"),
            "(no comment)",
            ri!decisionComment
          )
        )
      }
    )
  )
)

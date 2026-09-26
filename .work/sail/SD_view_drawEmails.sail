/* Draw approval (Phase 6b): the Emails view of a draw record — the approval email thread as one conversation.
   Oldest first. The approver's messages sit left (slate bar), what the flow and the draw approval team send sits right
   (navy bar, faint navy tint); the direction is also written on every message ("Received from …" / "Sent to …"), so the
   bar never carries meaning alone. Each message shows sender, kind, time, step and source, the text, the AI reading
   (the decisive phrase and the reading line) where there is one, and an outcome tag (40 characters or fewer).
   A pending approver question (SD_getPendingQuestion) is lifted to the top in amber; members of SD Draw Demo Approvers
   answer it there: the reply box starts SD Answer Draw Question synchronously (a!startProcess, isSynchronous: the view
   refreshes once the answer is sent and logged, which also clears the pending state). Everyone else sees who answers.
   Widths and bars per the docs gate (26.6): relative columns (5X card, 1X offset) stack on phones; one bar position
   (START) for every card. */
a!localVariables(
  local!d: rule!SD_getDrawDetail(drawId: ri!drawId),
  local!found: a!defaultValue(index(local!d, "found", false), false),
  local!refreshKey: 0,
  local!msgs: a!refreshVariable(
    value: if(local!found, rule!SD_getDrawEmailMessages(drawId: ri!drawId), {}),
    refreshOnVarChange: local!refreshKey
  ),
  local!pending: a!refreshVariable(
    value: if(local!found, rule!SD_getPendingQuestion(drawId: ri!drawId), a!map(pending: false)),
    refreshOnVarChange: local!refreshKey
  ),
  local!isPending: a!defaultValue(index(local!pending, "pending", false), false),
  local!pendingId: tointeger(a!defaultValue(index(local!pending, "messageId", null), -2)),
  local!pendingPos: if(
    or(not(local!isPending), a!isNullOrEmpty(local!msgs)),
    {},
    where(a!forEach(items: local!msgs, expression: tointeger(a!defaultValue(fv!item.id, -1)) = local!pendingId))
  ),
  local!pendingSender: if(
    a!isNullOrEmpty(local!pendingPos),
    a!defaultValue(index(local!pending, "fromAddress", ""), ""),
    a!localVariables(
      local!pm: index(local!msgs, local!pendingPos[1], null),
      if(a!defaultValue(local!pm.senderName, "") = "", a!defaultValue(local!pm.fromAddress, ""), local!pm.senderName)
    )
  ),
  local!isSpecialist: a!isUserMemberOfGroup(username: loggedInUser(), groups: cons!SD_DRAW_DEMO_APPROVERS_GROUP),
  local!answer: null,
  local!sentTo: null,
  local!sendError: null,
  {
    a!richTextDisplayField(labelPosition: "COLLAPSED", value: a!richTextItem(text: "Draw not found.", color: "NEGATIVE"), showWhen: not(local!found)),
    rule!SD_cmp_drawFactStrip(detail: local!d),
    /* the pending question, with the reply box for the draw approval team */
    a!cardLayout(
      contents: {
        a!richTextDisplayField(
          labelPosition: "COLLAPSED",
          value: {
            a!richTextIcon(icon: "question-circle", color: "#92600A"),
            " ",
            a!richTextItem(
              text: "QUESTION FROM THE " & upper(a!defaultValue(index(local!pending, "role", ""), "APPROVER")) & " · AWAITING AN ANSWER",
              color: "#92600A",
              size: "SMALL",
              style: "STRONG"
            ),
            char(10),
            a!richTextItem(text: a!defaultValue(index(local!pending, "question", ""), ""), size: "MEDIUM", style: "STRONG", color: "#16294D"),
            char(10),
            a!richTextItem(
              text: local!pendingSender
                & if(a!isNullOrEmpty(index(local!pending, "askedAt", null)), "", " · asked " & text(index(local!pending, "askedAt", null), "MMM D, h:mm a"))
                & " · step " & a!defaultValue(index(local!pending, "stepOrder", "?"), "?")
                & " · nothing has changed; the step still awaits its decision",
              color: "#6B7280",
              size: "SMALL"
            )
          },
          marginBelow: "STANDARD"
        ),
        a!paragraphField(
          label: "Your answer",
          labelPosition: "ABOVE",
          value: local!answer,
          saveInto: local!answer,
          height: "MEDIUM",
          characterLimit: 3000,
          placeholder: "Answer the approver's question in plain words.",
          showWhen: local!isSpecialist
        ),
        a!buttonArrayLayout(
          buttons: a!buttonWidget(
            label: "Send Answer",
            style: "SOLID",
            loadingIndicator: true,
            disabled: trim(a!defaultValue(local!answer, "")) = "",
            saveInto: a!startProcess(
              processModel: cons!SD_ANSWER_QUESTION_PM,
              processParameters: a!map(drawId: ri!drawId, answerText: local!answer),
              isSynchronous: true,
              onSuccess: {
                a!save(local!sentTo, a!defaultValue(index(local!pending, "approverAddress", ""), "")),
                a!save(local!answer, null),
                a!save(local!sendError, null),
                a!save(local!refreshKey, local!refreshKey + 1)
              },
              onError: a!save(local!sendError, "The answer could not be sent: the process did not start. Nothing was emailed."),
              onIncomplete: {
                a!save(local!sendError, "The answer is still being sent. Refresh the tab in a moment to see it on the thread."),
                a!save(local!refreshKey, local!refreshKey + 1)
              }
            )
          ),
          align: "START",
          showWhen: local!isSpecialist,
          marginBelow: "NONE"
        ),
        a!richTextDisplayField(
          labelPosition: "COLLAPSED",
          value: a!richTextItem(
            text: if(
              local!isSpecialist,
              "Emailed on the same thread to " & a!defaultValue(index(local!pending, "approverAddress", ""), "the approver") & ", from Starwood Draw Approvals. The approver can then decide, or ask again, by reply.",
              "The draw approval team answers approver questions from this tab."
            ),
            color: "#6B7280",
            size: "SMALL"
          ),
          marginBelow: "NONE"
        )
      },
      showWhen: and(local!found, local!isPending),
      style: "#FFFBF2",
      decorativeBarPosition: "START",
      decorativeBarColor: "#D97706",
      borderColor: "#F2D8A7",
      shape: "SEMI_ROUNDED",
      padding: "STANDARD",
      showBorder: true,
      showShadow: false,
      marginBelow: "STANDARD"
    ),
    /* after sending: confirmation (the thread below already shows the answer) or the reason it did not go */
    a!cardLayout(
      contents: a!richTextDisplayField(
        labelPosition: "COLLAPSED",
        value: {
          a!richTextIcon(icon: "check-circle", color: "#1E7E46"),
          " ",
          a!richTextItem(text: "Answer sent to " & a!defaultValue(local!sentTo, "") & ". It is on the thread below, and the question is answered.", color: "#1E7E46", style: "STRONG")
        },
        marginBelow: "NONE"
      ),
      showWhen: and(not(a!isNullOrEmpty(local!sentTo)), not(local!isPending), a!isNullOrEmpty(local!sendError)),
      style: "#E6F4EC",
      shape: "SEMI_ROUNDED",
      padding: "LESS",
      showBorder: false,
      marginBelow: "STANDARD"
    ),
    a!cardLayout(
      contents: a!richTextDisplayField(
        labelPosition: "COLLAPSED",
        value: a!richTextItem(text: a!defaultValue(local!sendError, ""), color: "#92600A", style: "STRONG"),
        marginBelow: "NONE"
      ),
      showWhen: not(a!isNullOrEmpty(local!sendError)),
      style: "#FDF3E0",
      shape: "SEMI_ROUNDED",
      padding: "LESS",
      showBorder: false,
      marginBelow: "STANDARD"
    ),
    /* the conversation */
    a!cardLayout(
      contents: {
        a!richTextDisplayField(
          labelPosition: "COLLAPSED",
          value: a!richTextItem(text: "Email Conversation", size: "MEDIUM", style: "STRONG", color: "#16294D"),
          marginBelow: "EVEN_LESS"
        ),
        rule!SD_cmp_sourceLine(
          text: count(local!msgs) & if(count(local!msgs) = 1, " message", " messages")
            & " on this draw, oldest first · a reply is read by one AI call and applied only when its decisive phrase is found in the reply · draws above "
            & rule!SD_fmtMoney(value: cons!SD_EMAIL_APPROVAL_MAX, showCents: false) & " are decided in the system, not by email"
        ),
        a!richTextDisplayField(
          labelPosition: "COLLAPSED",
          value: a!richTextItem(text: "No approval emails on this draw yet.", color: "#6B7280"),
          showWhen: a!isNullOrEmpty(local!msgs)
        ),
        a!forEach(
          items: local!msgs,
          expression: a!localVariables(
            local!dir: a!defaultValue(fv!item.direction, ""),
            local!kind: a!defaultValue(fv!item.kind, ""),
            local!isIn: local!dir = "INBOUND",
            local!isOut: local!dir = "OUTBOUND",
            local!isPendingQ: and(local!isPending, tointeger(a!defaultValue(fv!item.id, -1)) = local!pendingId),
            local!sender: if(
              a!defaultValue(fv!item.senderName, "") <> "",
              fv!item.senderName & if(and(local!isOut, local!kind = "ANSWER"), " via Starwood Draw Approvals", ""),
              if(local!isOut, "Starwood Draw Approvals", a!defaultValue(fv!item.fromAddress, "(unknown sender)"))
            ),
            local!kindLabel: a!match(
              value: local!kind,
              equals: "STEP_EMAIL", then: "APPROVAL REQUEST",
              equals: "REPLY", then: "REPLY",
              equals: "CLARIFICATION", then: "CLARIFICATION",
              equals: "GUARDRAIL_REFUSAL", then: "EMAIL APPROVAL REFUSED",
              equals: "ANSWER", then: "ANSWER",
              equals: "RECEIPT", then: "DECISION RECEIPT",
              equals: "EXCEPTION_REVIEW", then: "EXCEPTION REVIEW",
              default: upper(local!kind)
            ),
            local!meta: if(
              local!isIn,
              "Received from " & a!defaultValue(fv!item.fromAddress, ""),
              if(local!isOut, "Sent to " & a!defaultValue(fv!item.toAddress, ""), "Internal")
            ) & if(a!isNullOrEmpty(fv!item.stepOrder), "", " · step " & fv!item.stepOrder) & " · source " & lower(a!defaultValue(fv!item.source, "")),
            local!body: trim(a!defaultValue(fv!item.body, "")),
            local!o: a!defaultValue(fv!item.outcome, ""),
            local!tag: a!match(
              value: local!o,
              equals: "APPROVE", then: "Approved by email",
              equals: "REJECT", then: "Rejected by email",
              equals: "QUESTION", then: if(local!isPendingQ, "Question · awaiting an answer", "Question"),
              equals: "AMBIGUOUS", then: "Unclear · clarification sent",
              equals: "EXCEPTION", then: "Sent to exception queue",
              equals: "GUARDRAIL", then: "Over the email limit",
              equals: "UNAUTHORIZED", then: "Sender not authorized",
              equals: "NOT_AWAITING", then: "Step not awaiting a decision",
              equals: "UNMATCHED", then: "No draw reference",
              equals: "SENT", then: a!match(
                value: local!kind,
                equals: "STEP_EMAIL", then: "Approval request sent",
                equals: "CLARIFICATION", then: "Clarification sent",
                equals: "GUARDRAIL_REFUSAL", then: "Refusal sent",
                equals: "ANSWER", then: "Answer sent",
                equals: "RECEIPT", then: "Receipt sent",
                default: "Sent"
              ),
              equals: "REVIEWED", then: "Reviewed",
              equals: "RECEIVED", then: "Received",
              default: if(local!o = "", "—", left(local!o, 40))
            ),
            local!tone: a!match(
              value: local!o,
              equals: "APPROVE", then: "G",
              equals: "REJECT", then: "R",
              equals: "QUESTION", then: if(local!isPendingQ, "A", "B"),
              equals: "SENT", then: "N",
              equals: "REVIEWED", then: "N",
              equals: "RECEIVED", then: "N",
              default: "A"
            ),
            a!columnsLayout(
              columns: {
                a!columnLayout(contents: {}, width: "1X", showWhen: local!isOut),
                a!columnLayout(
                  contents: a!cardLayout(
                    contents: {
                      a!sideBySideLayout(
                        items: {
                          a!sideBySideItem(
                            item: a!richTextDisplayField(
                              labelPosition: "COLLAPSED",
                              value: {
                                a!richTextItem(text: local!sender, style: "STRONG", color: "#16294D"),
                                "   ",
                                a!richTextItem(text: local!kindLabel, size: "SMALL", style: "STRONG", color: "#6B7280")
                              },
                              marginBelow: "NONE"
                            )
                          ),
                          a!sideBySideItem(
                            item: a!richTextDisplayField(
                              labelPosition: "COLLAPSED",
                              value: a!richTextItem(
                                text: if(a!isNullOrEmpty(fv!item.messageAt), "—", text(fv!item.messageAt, "MMM D, YYYY h:mm a")),
                                size: "SMALL",
                                color: "#6B7280"
                              ),
                              align: "RIGHT",
                              marginBelow: "NONE"
                            ),
                            width: "MINIMIZE"
                          )
                        },
                        alignVertical: "TOP",
                        spacing: "STANDARD",
                        marginBelow: "EVEN_LESS"
                      ),
                      a!richTextDisplayField(
                        labelPosition: "COLLAPSED",
                        value: a!richTextItem(text: local!meta, size: "SMALL", color: "#6B7280"),
                        marginBelow: "LESS"
                      ),
                      a!richTextDisplayField(
                        labelPosition: "COLLAPSED",
                        value: a!richTextItem(
                          text: if(local!body = "", "(no text)", if(len(local!body) > 1500, left(local!body, 1500) & "…", local!body)),
                          color: if(local!body = "", "#6B7280", "#1F2937")
                        ),
                        marginBelow: "LESS"
                      ),
                      a!cardLayout(
                        contents: a!richTextDisplayField(
                          labelPosition: "COLLAPSED",
                          value: {
                            a!richTextItem(text: "AI READING", size: "SMALL", style: "STRONG", color: "#6B7280"),
                            char(10),
                            if(
                              a!defaultValue(fv!item.decisivePhrase, "") = "",
                              "",
                              {
                                a!richTextItem(text: "Decisive phrase: ", size: "SMALL", color: "#6B7280"),
                                a!richTextItem(text: "“" & fv!item.decisivePhrase & "”", size: "SMALL", style: "EMPHASIS", color: "#1F2937"),
                                char(10)
                              }
                            ),
                            a!richTextItem(text: a!defaultValue(fv!item.interpretation, ""), size: "SMALL", color: "#6B7280")
                          },
                          marginBelow: "NONE"
                        ),
                        showWhen: a!defaultValue(fv!item.interpretation, "") <> "",
                        style: "#F8FAFC",
                        shape: "SEMI_ROUNDED",
                        padding: "LESS",
                        showBorder: false,
                        marginBelow: "LESS"
                      ),
                      a!sideBySideLayout(
                        items: {
                          a!sideBySideItem(
                            item: a!tagField(
                              labelPosition: "COLLAPSED",
                              tags: a!tagItem(
                                text: local!tag,
                                backgroundColor: a!match(value: local!tone, equals: "G", then: "#E6F4EC", equals: "R", then: "#FDECEC", equals: "A", then: "#FDF3E0", equals: "B", then: "#E8F0FC", default: "#EEF1F5"),
                                textColor: a!match(value: local!tone, equals: "G", then: "#1E7E46", equals: "R", then: "#B42318", equals: "A", then: "#92600A", equals: "B", then: "#1D5BBF", default: "#64748B")
                              ),
                              size: "SMALL"
                            ),
                            width: "MINIMIZE"
                          ),
                          a!sideBySideItem(
                            item: a!richTextDisplayField(
                              labelPosition: "COLLAPSED",
                              value: a!richTextItem(text: a!defaultValue(fv!item.notes, ""), size: "SMALL", color: "#6B7280"),
                              marginBelow: "NONE"
                            )
                          )
                        },
                        alignVertical: "MIDDLE",
                        spacing: "STANDARD",
                        marginBelow: "NONE"
                      )
                    },
                    style: if(local!isOut, "#F5F7FB", "NONE"),
                    decorativeBarPosition: "START",
                    decorativeBarColor: if(local!isPendingQ, "#D97706", if(local!isOut, "#16294D", if(local!isIn, "#94A3B8", "#CBD5E1"))),
                    borderColor: if(local!isPendingQ, "#F2D8A7", "#E5E7EB"),
                    shape: "SEMI_ROUNDED",
                    padding: "STANDARD",
                    showBorder: true,
                    showShadow: false,
                    marginBelow: "NONE"
                  ),
                  width: "5X"
                ),
                a!columnLayout(contents: {}, width: "1X", showWhen: not(local!isOut))
              },
              stackWhen: {"PHONE"},
              marginBelow: "STANDARD"
            )
          )
        )
      },
      style: "NONE",
      shape: "SEMI_ROUNDED",
      padding: "STANDARD",
      showBorder: true,
      showShadow: false,
      marginBelow: "STANDARD"
    )
  }
)

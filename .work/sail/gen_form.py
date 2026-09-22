from refs import *
sail = f"""/* Draw approval: the step task form, restyled against mockups/task-approval.html (the UI contract).
   Header (step position, role, assignee, aging, funding date) · context card linking to the draw record ·
   the two decision cards with data-driven consequence text · comments (optional on approve, required on reject).
   ri!drawId / ri!stepOrder drive every figure through rule!SD_getDrawDetail; ri!drawSummary / ri!stepLabel remain
   as the process-composed fallback for a task issued before those inputs existed. ri!decision (APPROVE / REJECT),
   ri!decisionComment and ri!actor are written back to the task's ACPs on submit, never null.
   "Save for Later" from the mockup is not built: an Appian task form has no draft save without a process change. */
a!localVariables(
  local!d: if(a!isNullOrEmpty(ri!drawId), null, rule!SD_getDrawDetail(drawId: ri!drawId)),
  local!found: a!defaultValue(index(local!d, "found", false), false),
  local!step: a!defaultValue(ri!stepOrder, index(local!d, "currentStep", null)),
  local!total: a!defaultValue(index(local!d, "totalSteps", 9), 9),
  local!approvals: a!defaultValue(index(local!d, "approvals", {{}}), {{}}),
  local!row: a!localVariables(
    local!idx: if(or(a!isNullOrEmpty(local!approvals), a!isNullOrEmpty(local!step)), {{}}, wherecontains(tointeger(local!step), a!forEach(items: local!approvals, expression: tointeger(fv!item.approvalOrder)))),
    if(a!isNullOrEmpty(local!idx), null, index(local!approvals, local!idx[1], null))
  ),
  local!nextRow: a!localVariables(
    local!idx: if(or(a!isNullOrEmpty(local!approvals), a!isNullOrEmpty(local!step)), {{}}, wherecontains(tointeger(local!step) + 1, a!forEach(items: local!approvals, expression: tointeger(fv!item.approvalOrder)))),
    if(a!isNullOrEmpty(local!idx), null, index(local!approvals, local!idx[1], null))
  ),
  local!role: if(a!isNullOrEmpty(local!row), null, index(local!row, "role", null)),
  local!approver: if(a!isNullOrEmpty(local!row), null, index(local!row, "approverName", null)),
  local!activatedAt: if(a!isNullOrEmpty(local!row), null, index(local!row, "activatedAt", null)),
  local!fundingDate: index(local!d, "fundingDate", null),
  local!approvedRows: if(
    a!isNullOrEmpty(local!approvals),
    {{}},
    index(local!approvals, wherecontains("Approved", a!forEach(items: local!approvals, expression: tostring(a!defaultValue(fv!item.status, "")))), {{}})
  ),
  local!approvedLine: if(
    a!isNullOrEmpty(local!approvedRows),
    "",
    joinarray(a!forEach(items: local!approvedRows, expression: fv!item.role & " ✓ " & if(a!isNullOrEmpty(fv!item.decisionDate), "", text(todate(fv!item.decisionDate), "MM/DD"))), " · ")
  ),
  local!isFinal: if(a!isNullOrEmpty(local!step), false, tointeger(local!step) >= local!total),
  local!approveText: if(
    local!isFinal,
    "Final approval · Treasury is notified to execute the cash payment",
    "Advance to " & if(a!isNullOrEmpty(local!nextRow), "the next step", index(local!nextRow, "role", "the next step")) & " (step " & if(a!isNullOrEmpty(local!step), "?", tointeger(local!step) + 1) & " of " & local!total & ")"
  ),
  local!decisionValue: if(or(a!isNullOrEmpty(ri!decision), a!defaultValue(ri!decision, "NONE") = "NONE"), null, ri!decision),
  a!formLayout(
    titleBar: a!headerTemplateFull(
      title: if(
        local!found,
        "Step " & a!defaultValue(local!step, "?") & " of " & local!total & " — " & a!defaultValue(local!role, ""),
        a!defaultValue(ri!stepLabel, "Draw approval step")
      ),
      secondaryText: if(
        local!found,
        "Assigned to " & a!defaultValue(local!approver, "—") & " · with you since " & if(a!isNullOrEmpty(local!activatedAt), "—", text(todate(local!activatedAt), "MMM D")) & " · funds scheduled " & if(a!isNullOrEmpty(local!fundingDate), "—", text(local!fundingDate, "MMM D")),
        a!defaultValue(ri!drawSummary, "")
      ),
      backgroundColor: "#16294D"
    ),
    contents: {{
      /* Context card */
      a!cardLayout(
        contents: {{
          a!richTextDisplayField(
            labelPosition: "COLLAPSED",
            value: {{
              a!richTextItem(text: "DRAW", color: "#6B7280", size: "SMALL"),
              char(10),
              if(
                local!found,
                a!richTextItem(
                  text: "Draw #" & a!defaultValue(index(local!d, "drawNumber", ""), "") & " — " & a!defaultValue(index(local!d, "investmentName", ""), ""),
                  link: a!recordLink(recordType: {rt(DRAW)}, identifier: ri!drawId, openLinkIn: "NEW_TAB"),
                  linkStyle: "STANDALONE",
                  size: "MEDIUM",
                  style: "STRONG"
                ),
                a!richTextItem(text: a!defaultValue(ri!drawSummary, "Draw details unavailable"), size: "MEDIUM", style: "STRONG", color: "#16294D")
              )
            }},
            marginBelow: "STANDARD"
          ),
          a!columnsLayout(
            columns: {{
              a!columnLayout(contents: rule!SD_cmp_labelValue(label: "Amount", value: rule!SD_fmtMoney(value: index(local!d, "amount", null), showCents: true), emphasize: true, marginBelow: "NONE"), width: "AUTO"),
              a!columnLayout(contents: rule!SD_cmp_labelValue(label: "Draw Type", value: index(local!d, "drawType", null), marginBelow: "NONE"), width: "AUTO"),
              a!columnLayout(contents: rule!SD_cmp_labelValue(label: "On / Under / Over Budget", value: index(local!d, "budgetStatus", null), marginBelow: "NONE"), width: "AUTO"),
              a!columnLayout(contents: rule!SD_cmp_labelValue(label: "Fund", value: index(local!d, "fundName", null), marginBelow: "NONE"), width: "AUTO")
            }},
            showWhen: local!found,
            stackWhen: {{"PHONE", "TABLET_PORTRAIT"}},
            marginBelow: "STANDARD"
          ),
          rule!SD_cmp_labelValue(label: "Purpose", value: index(local!d, "purpose", null)),
          rule!SD_cmp_labelValue(label: "Budget and Contingency Explanation", value: index(local!d, "contingencyExplanation", null)),
          a!richTextDisplayField(
            labelPosition: "COLLAPSED",
            value: {{
              a!richTextItem(
                text: count(local!approvedRows) & " of " & local!total & " approved" & if(local!approvedLine = "", "", " · " & local!approvedLine) & " · Review the full draw, budget detail, and documents on the ",
                color: "#6B7280",
                size: "SMALL"
              ),
              a!richTextItem(
                text: "draw record",
                link: a!recordLink(recordType: {rt(DRAW)}, identifier: ri!drawId, openLinkIn: "NEW_TAB"),
                linkStyle: "STANDALONE",
                size: "SMALL"
              ),
              a!richTextItem(text: ".", color: "#6B7280", size: "SMALL")
            }},
            showWhen: local!found,
            marginBelow: "NONE"
          )
        }},
        style: "NONE",
        shape: "SEMI_ROUNDED",
        padding: "STANDARD",
        showBorder: true,
        showShadow: false,
        marginBelow: "STANDARD"
      ),
      /* Decision card */
      a!cardLayout(
        contents: {{
          a!richTextDisplayField(
            labelPosition: "COLLAPSED",
            value: a!richTextItem(text: "Your Decision", size: "MEDIUM", style: "STRONG", color: "#16294D"),
            marginBelow: "STANDARD"
          ),
          a!cardChoiceField(
            labelPosition: "COLLAPSED",
            data: {{
              a!map(id: "APPROVE", title: "Approve", description: local!approveText, icon: "check", color: "POSITIVE"),
              a!map(id: "REJECT", title: "Reject", description: "Terminate this draw request", icon: "times", color: "NEGATIVE")
            }},
            cardTemplate: a!cardTemplateBarTextStacked(
              id: fv!data.id,
              primaryText: fv!data.title,
              secondaryText: fv!data.description,
              icon: fv!data.icon,
              iconColor: fv!data.color
            ),
            value: local!decisionValue,
            saveInto: a!save(ri!decision, if(a!isNullOrEmpty(save!value), "NONE", tostring(save!value))),
            maxSelections: 1,
            required: true,
            requiredMessage: "Choose Approve or Reject.",
            align: "START",
            spacing: "STANDARD",
            marginBelow: "STANDARD"
          ),
          a!paragraphField(
            label: "Comments" & if(local!decisionValue = "REJECT", "", " (optional)"),
            labelPosition: "ABOVE",
            instructions: "Comments are recorded on the approval and visible to later steps.",
            placeholder: "Visible to all downstream approvers and recorded on the draw",
            value: if(a!defaultValue(ri!decisionComment, "-") = "-", null, ri!decisionComment),
            saveInto: ri!decisionComment,
            required: local!decisionValue = "REJECT",
            requiredMessage: "A comment is required when rejecting a draw.",
            height: "MEDIUM",
            marginBelow: "NONE"
          )
        }},
        style: "NONE",
        shape: "SEMI_ROUNDED",
        padding: "STANDARD",
        showBorder: true,
        showShadow: false,
        marginBelow: "STANDARD"
      )
    }},
    buttons: a!buttonLayout(
      primaryButtons: a!buttonWidget(
        label: "Submit Decision",
        submit: true,
        style: "SOLID",
        saveInto: {{
          a!save(ri!actor, tostring(loggedInUser())),
          a!save(
            ri!decisionComment,
            if(or(a!isNullOrEmpty(ri!decisionComment), ri!decisionComment = "-"), "(no comment)", ri!decisionComment)
          )
        }}
      )
    ),
    contentsWidth: "MEDIUM"
  )
)
"""
open("SD_form_drawApprovalDecision.sail","w").write(sail)
print("written", len(sail))

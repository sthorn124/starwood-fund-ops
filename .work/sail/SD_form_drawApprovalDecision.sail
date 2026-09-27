/* Draw approval: the step task form, restyled against mockups/task-approval.html (the UI contract).
   Header (step position, role, assignee, aging, funding date) · context card linking to the draw record ·
   the two decision cards with data-driven consequence text · comments (optional on approve, required on reject).
   ri!drawId / ri!stepOrder drive every figure through rule!SD_getDrawDetail; ri!drawSummary / ri!stepLabel remain
   as the process-composed fallback for a task issued before those inputs existed. ri!decision (APPROVE / REJECT),
   ri!decisionComment and ri!actor are written back to the task's ACPs on submit, never null.
   "Save for Later" from the mockup is not built: an Appian task form has no draft save without a process change.
   Phase 6c: at the Asset Manager's step (the approval row's role is "Asset Manager") the budget lines are editable before
   deciding — the same editable-grid pattern as the reconciliation form. The Asset Manager changes a line's proposed
   adjustment or current draw; proposed budget, PTD and balance to complete recompute as they type, with the current-draw
   tie-out against the draw amount and the net of the adjustments beneath. On submit the changed lines go to the process
   as ri!budgetEditsJson ([{id, toAdj, toCurrent}], "[]" for none), which writes them, attributed, before the decision is
   applied (rule!SD_planBudgetEdit re-checks everything). Editing never approves, rejects or blocks the decision. */
a!localVariables(
  local!d: if(a!isNullOrEmpty(ri!drawId), null, rule!SD_getDrawDetail(drawId: ri!drawId)),
  local!found: a!defaultValue(index(local!d, "found", false), false),
  local!step: a!defaultValue(ri!stepOrder, index(local!d, "currentStep", null)),
  local!total: a!defaultValue(index(local!d, "totalSteps", 9), 9),
  local!approvals: a!defaultValue(index(local!d, "approvals", {}), {}),
  local!row: a!localVariables(
    local!idx: if(or(a!isNullOrEmpty(local!approvals), a!isNullOrEmpty(local!step)), {}, wherecontains(tointeger(local!step), a!forEach(items: local!approvals, expression: tointeger(fv!item.approvalOrder)))),
    if(a!isNullOrEmpty(local!idx), null, index(local!approvals, local!idx[1], null))
  ),
  local!nextRow: a!localVariables(
    local!idx: if(or(a!isNullOrEmpty(local!approvals), a!isNullOrEmpty(local!step)), {}, wherecontains(tointeger(local!step) + 1, a!forEach(items: local!approvals, expression: tointeger(fv!item.approvalOrder)))),
    if(a!isNullOrEmpty(local!idx), null, index(local!approvals, local!idx[1], null))
  ),
  local!role: if(a!isNullOrEmpty(local!row), null, index(local!row, "role", null)),
  local!approver: if(a!isNullOrEmpty(local!row), null, index(local!row, "approverName", null)),
  local!activatedAt: if(a!isNullOrEmpty(local!row), null, index(local!row, "activatedAt", null)),
  local!fundingDate: index(local!d, "fundingDate", null),
  local!approvedRows: if(
    a!isNullOrEmpty(local!approvals),
    {},
    index(local!approvals, wherecontains("Approved", a!forEach(items: local!approvals, expression: tostring(a!defaultValue(fv!item.status, "")))), {})
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
  /* Phase 6c: the Asset Manager's budget edit. The lines are read once (refreshOnReferencedVarChange off) so edits survive. */
  local!isAmStep: and(local!found, tostring(a!defaultValue(local!role, "")) = "Asset Manager"),
  local!edit: a!refreshVariable(
    value: if(
      not(local!isAmStep),
      {},
      a!forEach(
        items: a!queryRecordType(
          recordType: 'recordType!{ddc4073e-6372-49e2-80de-a088b424abcd}SD Draw Budget Line',
          fields: { 'recordType!{ddc4073e-6372-49e2-80de-a088b424abcd}SD Draw Budget Line.fields.{14803371-b715-43a4-bc3a-94e314f16f8a}id', 'recordType!{ddc4073e-6372-49e2-80de-a088b424abcd}SD Draw Budget Line.fields.{2dd34362-59f3-46ad-bb7b-12f44273015e}lineOrder', 'recordType!{ddc4073e-6372-49e2-80de-a088b424abcd}SD Draw Budget Line.fields.{4b8934ab-ad8e-4fc0-ac4e-86a762018dee}budgetCategory', 'recordType!{ddc4073e-6372-49e2-80de-a088b424abcd}SD Draw Budget Line.fields.{eb2ed1b0-6417-4468-a2a2-a0e7f643e931}revisedApprovedBudget', 'recordType!{ddc4073e-6372-49e2-80de-a088b424abcd}SD Draw Budget Line.fields.{497f7abe-c453-4b00-97ad-1f5da03f5cd2}proposedAdjustmentsThisDraw', 'recordType!{ddc4073e-6372-49e2-80de-a088b424abcd}SD Draw Budget Line.fields.{5242c9d6-c607-43c9-900c-756163dcbae5}currentDraw', 'recordType!{ddc4073e-6372-49e2-80de-a088b424abcd}SD Draw Budget Line.fields.{aab45d4c-cd07-43ce-87e6-21d485c77827}totalPtdIncThisDrawAmount' },
          filters: a!queryFilter(field: 'recordType!{ddc4073e-6372-49e2-80de-a088b424abcd}SD Draw Budget Line.fields.{830216a5-8980-4ac0-a8f9-7baa33bbea6b}drawId', operator: "=", value: ri!drawId),
          pagingInfo: a!pagingInfo(startIndex: 1, batchSize: 100, sort: a!sortInfo(field: 'recordType!{ddc4073e-6372-49e2-80de-a088b424abcd}SD Draw Budget Line.fields.{2dd34362-59f3-46ad-bb7b-12f44273015e}lineOrder', ascending: true))
        ).data,
        expression: a!map(
          id: fv!item['recordType!{ddc4073e-6372-49e2-80de-a088b424abcd}SD Draw Budget Line.fields.{14803371-b715-43a4-bc3a-94e314f16f8a}id'],
          category: tostring(a!defaultValue(fv!item['recordType!{ddc4073e-6372-49e2-80de-a088b424abcd}SD Draw Budget Line.fields.{4b8934ab-ad8e-4fc0-ac4e-86a762018dee}budgetCategory'], "")),
          revised: todecimal(a!defaultValue(fv!item['recordType!{ddc4073e-6372-49e2-80de-a088b424abcd}SD Draw Budget Line.fields.{eb2ed1b0-6417-4468-a2a2-a0e7f643e931}revisedApprovedBudget'], 0)),
          origAdj: todecimal(a!defaultValue(fv!item['recordType!{ddc4073e-6372-49e2-80de-a088b424abcd}SD Draw Budget Line.fields.{497f7abe-c453-4b00-97ad-1f5da03f5cd2}proposedAdjustmentsThisDraw'], 0)),
          adj: todecimal(a!defaultValue(fv!item['recordType!{ddc4073e-6372-49e2-80de-a088b424abcd}SD Draw Budget Line.fields.{497f7abe-c453-4b00-97ad-1f5da03f5cd2}proposedAdjustmentsThisDraw'], 0)),
          origCur: todecimal(a!defaultValue(fv!item['recordType!{ddc4073e-6372-49e2-80de-a088b424abcd}SD Draw Budget Line.fields.{5242c9d6-c607-43c9-900c-756163dcbae5}currentDraw'], 0)),
          cur: todecimal(a!defaultValue(fv!item['recordType!{ddc4073e-6372-49e2-80de-a088b424abcd}SD Draw Budget Line.fields.{5242c9d6-c607-43c9-900c-756163dcbae5}currentDraw'], 0)),
          ptdOld: todecimal(a!defaultValue(fv!item['recordType!{ddc4073e-6372-49e2-80de-a088b424abcd}SD Draw Budget Line.fields.{aab45d4c-cd07-43ce-87e6-21d485c77827}totalPtdIncThisDrawAmount'], 0))
        )
      )
    ),
    refreshOnReferencedVarChange: false
  ),
  local!changedFlags: if(
    a!isNullOrEmpty(local!edit),
    {},
    a!forEach(items: local!edit, expression: or(abs(a!defaultValue(fv!item.adj, 0) - fv!item.origAdj) >= 0.005, abs(a!defaultValue(fv!item.cur, 0) - fv!item.origCur) >= 0.005))
  ),
  local!changedCount: if(a!isNullOrEmpty(local!changedFlags), 0, count(wherecontains(true, local!changedFlags))),
  local!curTotal: if(a!isNullOrEmpty(local!edit), 0, sum(a!forEach(items: local!edit, expression: a!defaultValue(fv!item.cur, 0)))),
  local!adjNet: if(a!isNullOrEmpty(local!edit), 0, sum(a!forEach(items: local!edit, expression: a!defaultValue(fv!item.adj, 0)))),
  local!drawAmount: todecimal(a!defaultValue(index(local!d, "amount", 0), 0)),
  local!ties: abs(local!curTotal - local!drawAmount) < 0.005,
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
    contents: {
      /* Context card */
      a!cardLayout(
        contents: {
          a!richTextDisplayField(
            labelPosition: "COLLAPSED",
            value: {
              a!richTextItem(text: "DRAW", color: "#6B7280", size: "SMALL"),
              char(10),
              if(
                local!found,
                a!richTextItem(
                  text: "Draw #" & a!defaultValue(index(local!d, "drawNumber", ""), "") & " — " & a!defaultValue(index(local!d, "investmentName", ""), ""),
                  link: a!recordLink(recordType: 'recordType!{c9d3a947-71aa-4024-879e-363873a12860}SD Draw', identifier: ri!drawId, openLinkIn: "NEW_TAB"),
                  linkStyle: "STANDALONE",
                  size: "MEDIUM",
                  style: "STRONG"
                ),
                a!richTextItem(text: a!defaultValue(ri!drawSummary, "Draw details unavailable"), size: "MEDIUM", style: "STRONG", color: "#16294D")
              )
            },
            marginBelow: "STANDARD"
          ),
          a!columnsLayout(
            columns: {
              a!columnLayout(contents: rule!SD_cmp_labelValue(label: "Amount", value: rule!SD_fmtMoney(value: index(local!d, "amount", null), showCents: true), emphasize: true, marginBelow: "NONE"), width: "AUTO"),
              a!columnLayout(contents: rule!SD_cmp_labelValue(label: "Draw Type", value: index(local!d, "drawType", null), marginBelow: "NONE"), width: "AUTO"),
              a!columnLayout(contents: rule!SD_cmp_labelValue(label: "On / Under / Over Budget", value: index(local!d, "budgetStatus", null), marginBelow: "NONE"), width: "AUTO"),
              a!columnLayout(contents: rule!SD_cmp_labelValue(label: "Fund", value: index(local!d, "fundName", null), marginBelow: "NONE"), width: "AUTO")
            },
            showWhen: local!found,
            stackWhen: {"PHONE", "TABLET_PORTRAIT"},
            marginBelow: "STANDARD"
          ),
          rule!SD_cmp_labelValue(label: "Purpose", value: index(local!d, "purpose", null)),
          rule!SD_cmp_labelValue(label: "Budget and Contingency Explanation", value: index(local!d, "contingencyExplanation", null)),
          a!richTextDisplayField(
            labelPosition: "COLLAPSED",
            value: {
              a!richTextItem(
                text: count(local!approvedRows) & " of " & local!total & " approved" & if(local!approvedLine = "", "", " · " & local!approvedLine) & " · Review the full draw, budget detail, and documents on the ",
                color: "#6B7280",
                size: "SMALL"
              ),
              a!richTextItem(
                text: "draw record",
                link: a!recordLink(recordType: 'recordType!{c9d3a947-71aa-4024-879e-363873a12860}SD Draw', identifier: ri!drawId, openLinkIn: "NEW_TAB"),
                linkStyle: "STANDALONE",
                size: "SMALL"
              ),
              a!richTextItem(text: ".", color: "#6B7280", size: "SMALL")
            },
            showWhen: local!found,
            marginBelow: "NONE"
          )
        },
        style: "NONE",
        shape: "SEMI_ROUNDED",
        padding: "STANDARD",
        showBorder: true,
        showShadow: false,
        marginBelow: "STANDARD"
      ),
      /* Phase 6c: the Asset Manager's budget edit, before deciding */
      a!cardLayout(
        contents: {
          a!richTextDisplayField(
            labelPosition: "COLLAPSED",
            value: {
              a!richTextItem(text: "Budget Lines", size: "MEDIUM", style: "STRONG", color: "#16294D"),
              char(10),
              a!richTextItem(
                text: "As Asset Manager you may adjust a line before you decide. Edits are saved to the draw with your name and today's date when you submit, and every later email and view shows them. Editing does not approve or reject the draw.",
                color: "#6B7280",
                size: "SMALL"
              )
            },
            marginBelow: "STANDARD"
          ),
          a!gridLayout(
            labelPosition: "COLLAPSED",
            headerCells: {
              a!gridLayoutHeaderCell(label: "Budget Category"),
              a!gridLayoutHeaderCell(label: "Revised", align: "RIGHT"),
              a!gridLayoutHeaderCell(label: "Adjustment", align: "RIGHT"),
              a!gridLayoutHeaderCell(label: "Proposed", align: "RIGHT"),
              a!gridLayoutHeaderCell(label: "Current Draw", align: "RIGHT"),
              a!gridLayoutHeaderCell(label: "Balance", align: "RIGHT")
            },
            columnConfigs: {
              a!gridLayoutColumnConfig(width: "DISTRIBUTE", weight: 4),
              a!gridLayoutColumnConfig(width: "DISTRIBUTE", weight: 3),
              a!gridLayoutColumnConfig(width: "DISTRIBUTE", weight: 3),
              a!gridLayoutColumnConfig(width: "DISTRIBUTE", weight: 3),
              a!gridLayoutColumnConfig(width: "DISTRIBUTE", weight: 3),
              a!gridLayoutColumnConfig(width: "DISTRIBUTE", weight: 3)
            },
            rows: a!forEach(
              items: local!edit,
              expression: a!localVariables(
                local!changed: or(abs(a!defaultValue(fv!item.adj, 0) - fv!item.origAdj) >= 0.005, abs(a!defaultValue(fv!item.cur, 0) - fv!item.origCur) >= 0.005),
                local!proposed: fv!item.revised + a!defaultValue(fv!item.adj, 0),
                local!ptd: fv!item.ptdOld - fv!item.origCur + a!defaultValue(fv!item.cur, 0),
                a!gridRowLayout(
                  id: fv!index,
                  contents: {
                    a!richTextDisplayField(
                      value: {
                        a!richTextItem(text: fv!item.category, style: if(local!changed, "STRONG", "PLAIN")),
                        if(local!changed, {char(10), a!richTextItem(text: "edited", color: "#1D5BBF", size: "SMALL", style: "STRONG")}, "")
                      }
                    ),
                    a!richTextDisplayField(value: a!richTextItem(text: rule!SD_fmtMoney(value: fv!item.revised, showCents: false)), align: "RIGHT"),
                    a!floatingPointField(value: fv!item.adj, saveInto: fv!item.adj, align: "RIGHT"),
                    a!richTextDisplayField(value: a!richTextItem(text: rule!SD_fmtMoney(value: local!proposed, showCents: false)), align: "RIGHT"),
                    a!floatingPointField(value: fv!item.cur, saveInto: fv!item.cur, align: "RIGHT"),
                    a!richTextDisplayField(value: a!richTextItem(text: rule!SD_fmtMoney(value: local!proposed - local!ptd, showCents: false)), align: "RIGHT")
                  }
                )
              )
            ),
            spacing: "DENSE",
            shadeAlternateRows: true,
            emptyGridMessage: "No budget lines on this draw"
          ),
          a!richTextDisplayField(
            labelPosition: "COLLAPSED",
            align: "RIGHT",
            value: {
              a!richTextItem(text: "Current Draw total  ", color: "#6B7280", size: "SMALL"),
              a!richTextItem(text: rule!SD_fmtMoney(value: local!curTotal, showCents: true), color: "#16294D", style: "STRONG"),
              a!richTextItem(text: "   vs draw amount " & rule!SD_fmtMoney(value: local!drawAmount, showCents: true), color: "#6B7280", size: "SMALL"),
              a!richTextItem(
                text: if(local!ties, "   Ties ✓", "   off by " & rule!SD_fmtMoney(value: local!curTotal - local!drawAmount, showCents: true)),
                color: if(local!ties, "#1E7E46", "#92600A"),
                size: "SMALL",
                style: "STRONG"
              ),
              char(10),
              a!richTextItem(text: "Net adjustments this draw  ", color: "#6B7280", size: "SMALL"),
              a!richTextItem(text: rule!SD_fmtMoney(value: local!adjNet, showCents: false), color: if(abs(local!adjNet) < 0.005, "#16294D", "#92600A"), size: "SMALL", style: "STRONG"),
              char(10),
              a!richTextItem(
                text: if(local!changedCount = 0, "No lines edited", local!changedCount & if(local!changedCount = 1, " line edited", " lines edited") & " · saved with your decision"),
                color: if(local!changedCount = 0, "#6B7280", "#1D5BBF"),
                size: "SMALL",
                style: if(local!changedCount = 0, "PLAIN", "STRONG")
              )
            },
            marginBelow: "NONE"
          )
        },
        showWhen: local!isAmStep,
        style: "NONE",
        shape: "SEMI_ROUNDED",
        padding: "STANDARD",
        showBorder: true,
        showShadow: false,
        marginBelow: "STANDARD"
      ),
      /* Decision card */
      a!cardLayout(
        contents: {
          a!richTextDisplayField(
            labelPosition: "COLLAPSED",
            value: a!richTextItem(text: "Your Decision", size: "MEDIUM", style: "STRONG", color: "#16294D"),
            marginBelow: "STANDARD"
          ),
          a!cardChoiceField(
            labelPosition: "COLLAPSED",
            data: {
              a!map(id: "APPROVE", title: "Approve", description: local!approveText, icon: "check", color: "POSITIVE"),
              a!map(id: "REJECT", title: "Reject", description: "Terminate this draw request", icon: "times", color: "NEGATIVE")
            },
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
        },
        style: "NONE",
        shape: "SEMI_ROUNDED",
        padding: "STANDARD",
        showBorder: true,
        showShadow: false,
        marginBelow: "STANDARD"
      )
    },
    buttons: a!buttonLayout(
      primaryButtons: a!buttonWidget(
        label: "Submit Decision",
        submit: true,
        style: "SOLID",
        saveInto: {
          a!save(ri!actor, tostring(loggedInUser())),
          /* Phase 6c: only the changed lines, as the process expects them; "[]" when nothing was edited */
          a!save(
            ri!budgetEditsJson,
            if(
              local!changedCount = 0,
              "[]",
              a!toJson(
                a!forEach(
                  items: index(local!edit, wherecontains(true, local!changedFlags), {}),
                  expression: a!map(id: fv!item.id, toAdj: a!defaultValue(fv!item.adj, 0), toCurrent: a!defaultValue(fv!item.cur, 0))
                )
              )
            )
          ),
          a!save(
            ri!decisionComment,
            if(or(a!isNullOrEmpty(ri!decisionComment), ri!decisionComment = "-"), "(no comment)", ri!decisionComment)
          )
        }
      )
    ),
    contentsWidth: if(local!isAmStep, "WIDE", "MEDIUM")
  )
)

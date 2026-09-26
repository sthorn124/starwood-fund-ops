/* Draw approval: the Approvals view of a draw record (mockups/draw-summary.html, Approvals tab).
   The nine-row chain as data: order, role, approver, status, decision date, time at step (computed), comments.
   The row in progress is highlighted. Time at step: decided rows count whole days from activation to decision
   (at least 1); the open row counts from activation to today.
   Phase 6a: an Email Exchange card below the chain lists every approval email, reply and response on the draw
   (SD Draw Email Message), with its direction, source, the AI reading and the outcome. */
a!localVariables(
  local!d: rule!SD_getDrawDetail(drawId: ri!drawId),
  local!found: a!defaultValue(index(local!d, "found", false), false),
  local!rows: if(
    not(local!found),
    {},
    a!localVariables(
      local!raw: a!queryRecordType(
      recordType: 'recordType!{02c207d5-c725-4d11-bf40-b33573e87ffa}SD Draw Approval',
      fields: {
        'recordType!{02c207d5-c725-4d11-bf40-b33573e87ffa}SD Draw Approval.fields.{69abcdf2-55da-48dc-8cc4-794b5d5e0042}id', 'recordType!{02c207d5-c725-4d11-bf40-b33573e87ffa}SD Draw Approval.fields.{44b8ee63-1230-4abd-ae83-ca2cddf182b6}approvalOrder', 'recordType!{02c207d5-c725-4d11-bf40-b33573e87ffa}SD Draw Approval.fields.{30524217-4621-4b41-9af4-490d2f082bdd}role', 'recordType!{02c207d5-c725-4d11-bf40-b33573e87ffa}SD Draw Approval.fields.{983be1c0-67e4-464f-b7c2-1e3a1c735458}approverName', 'recordType!{02c207d5-c725-4d11-bf40-b33573e87ffa}SD Draw Approval.fields.{4c1bf7fb-0736-4c9a-946e-99f6989ac83a}status', 'recordType!{02c207d5-c725-4d11-bf40-b33573e87ffa}SD Draw Approval.fields.{e6597b65-664d-4ccc-9dd0-f3e508ecdcc5}activatedAt', 'recordType!{02c207d5-c725-4d11-bf40-b33573e87ffa}SD Draw Approval.fields.{a6a03063-3b14-4f00-8cab-b5d10602405e}decisionDate', 'recordType!{02c207d5-c725-4d11-bf40-b33573e87ffa}SD Draw Approval.fields.{3c1aae42-13a1-4c13-894a-9fdef20f7fce}comments', 'recordType!{02c207d5-c725-4d11-bf40-b33573e87ffa}SD Draw Approval.fields.{2e6ad17e-66f3-4ab2-97b6-c21ee10dd203}actedBy', 'recordType!{02c207d5-c725-4d11-bf40-b33573e87ffa}SD Draw Approval.fields.{6597627c-af44-4119-9b92-286179df119d}decisionSource'
      },
      filters: a!queryFilter(field: 'recordType!{02c207d5-c725-4d11-bf40-b33573e87ffa}SD Draw Approval.fields.{5dacd7ec-3f3f-4645-9d08-684793b0b54b}drawId', operator: "=", value: ri!drawId),
      pagingInfo: a!pagingInfo(startIndex: 1, batchSize: 100, sort: a!sortInfo(field: 'recordType!{02c207d5-c725-4d11-bf40-b33573e87ffa}SD Draw Approval.fields.{44b8ee63-1230-4abd-ae83-ca2cddf182b6}approvalOrder', ascending: true))
    ).data,
      a!forEach(items: local!raw, expression: a!map(id: fv!item['recordType!{02c207d5-c725-4d11-bf40-b33573e87ffa}SD Draw Approval.fields.{69abcdf2-55da-48dc-8cc4-794b5d5e0042}id'], approvalOrder: fv!item['recordType!{02c207d5-c725-4d11-bf40-b33573e87ffa}SD Draw Approval.fields.{44b8ee63-1230-4abd-ae83-ca2cddf182b6}approvalOrder'], role: fv!item['recordType!{02c207d5-c725-4d11-bf40-b33573e87ffa}SD Draw Approval.fields.{30524217-4621-4b41-9af4-490d2f082bdd}role'], approverName: fv!item['recordType!{02c207d5-c725-4d11-bf40-b33573e87ffa}SD Draw Approval.fields.{983be1c0-67e4-464f-b7c2-1e3a1c735458}approverName'], status: fv!item['recordType!{02c207d5-c725-4d11-bf40-b33573e87ffa}SD Draw Approval.fields.{4c1bf7fb-0736-4c9a-946e-99f6989ac83a}status'], activatedAt: fv!item['recordType!{02c207d5-c725-4d11-bf40-b33573e87ffa}SD Draw Approval.fields.{e6597b65-664d-4ccc-9dd0-f3e508ecdcc5}activatedAt'], decisionDate: fv!item['recordType!{02c207d5-c725-4d11-bf40-b33573e87ffa}SD Draw Approval.fields.{a6a03063-3b14-4f00-8cab-b5d10602405e}decisionDate'], comments: fv!item['recordType!{02c207d5-c725-4d11-bf40-b33573e87ffa}SD Draw Approval.fields.{3c1aae42-13a1-4c13-894a-9fdef20f7fce}comments'], actedBy: fv!item['recordType!{02c207d5-c725-4d11-bf40-b33573e87ffa}SD Draw Approval.fields.{2e6ad17e-66f3-4ab2-97b6-c21ee10dd203}actedBy'], decisionSource: fv!item['recordType!{02c207d5-c725-4d11-bf40-b33573e87ffa}SD Draw Approval.fields.{6597627c-af44-4119-9b92-286179df119d}decisionSource']))
    )
  ),
  local!started: if(a!isNullOrEmpty(local!rows), index(local!d, "createdAt", null), a!defaultValue(index(local!rows, 1, null).activatedAt, index(local!d, "createdAt", null))),
  local!emails: if(local!found, rule!SD_getDrawEmailMessages(drawId: ri!drawId), {}),
  {
    a!richTextDisplayField(labelPosition: "COLLAPSED", value: a!richTextItem(text: "Draw not found.", color: "NEGATIVE"), showWhen: not(local!found)),
    rule!SD_cmp_drawFactStrip(detail: local!d),
    a!cardLayout(
    contents: {
      a!richTextDisplayField(
        labelPosition: "COLLAPSED",
        value: a!richTextItem(text: "Approval Detail", size: "MEDIUM", style: "STRONG", color: "#16294D"),
        marginBelow: "EVEN_LESS"
      ),
      rule!SD_cmp_sourceLine(text: "Sequential chain of " & count(local!rows) & " · drives routing and the summary progress" & if(a!isNullOrEmpty(local!started), "", " · started " & text(todate(local!started), "MM/DD/YYYY"))),
      a!gridField(
        labelPosition: "COLLAPSED",
        data: local!rows,
        columns: {
          a!gridColumn(label: "Order", value: fv!row.approvalOrder, align: "CENTER", width: "ICON_PLUS", backgroundColor: if(tostring(a!defaultValue(fv!row.status, "")) = "In Progress", "#E8F0FC", "NONE")),
          a!gridColumn(label: "Role", value: a!richTextDisplayField(value: a!richTextItem(text: fv!row.role, style: if(tostring(a!defaultValue(fv!row.status, "")) = "In Progress", "STRONG", "PLAIN"))), width: "MEDIUM", backgroundColor: if(tostring(a!defaultValue(fv!row.status, "")) = "In Progress", "#E8F0FC", "NONE")),
          a!gridColumn(label: "Approver", value: a!defaultValue(fv!row.approverName, "—"), width: "MEDIUM", backgroundColor: if(tostring(a!defaultValue(fv!row.status, "")) = "In Progress", "#E8F0FC", "NONE")),
          a!gridColumn(label: "Status", value: rule!SD_cmp_statusTag(status: fv!row.status), width: "NARROW_PLUS", backgroundColor: if(tostring(a!defaultValue(fv!row.status, "")) = "In Progress", "#E8F0FC", "NONE")),
          a!gridColumn(
            label: "Decision On",
            value: a!richTextDisplayField(
              value: if(
                a!isNullOrEmpty(fv!row.decisionDate),
                a!richTextItem(text: "—"),
                {
                  a!richTextItem(text: text(todate(fv!row.decisionDate), "MM/DD/YYYY")),
                  /* seeded rows carry source "seed"; only real decisions (task, email, system) show their source and actor */
                  if(
                    or(a!isNullOrEmpty(fv!row.decisionSource), lower(fv!row.decisionSource) = "seed"),
                    "",
                    {char(10), a!richTextItem(text: lower(fv!row.decisionSource) & if(or(a!isNullOrEmpty(fv!row.actedBy), lower(fv!row.actedBy) = "seed"), "", " · " & fv!row.actedBy), color: "#6B7280", size: "SMALL")}
                  )
                }
              )
            ),
            width: "NARROW_PLUS",
            backgroundColor: if(tostring(a!defaultValue(fv!row.status, "")) = "In Progress", "#E8F0FC", "NONE")
          ),
          a!gridColumn(
            label: "Time at Step",
            value: a!localVariables(
              local!s: tostring(a!defaultValue(fv!row.status, "")),
              if(
                a!isNullOrEmpty(fv!row.activatedAt),
                "—",
                if(
                  or(local!s = "Approved", local!s = "Rejected"),
                  if(
                    a!isNullOrEmpty(fv!row.decisionDate),
                    "—",
                    a!localVariables(
                      local!days: max(1, tointeger(ceiling(todecimal(todatetime(fv!row.decisionDate) - todatetime(fv!row.activatedAt))))),
                      local!days & if(local!days = 1, " day", " days")
                    )
                  ),
                  if(
                    local!s = "In Progress",
                    a!localVariables(
                      local!days: max(0, tointeger(today() - todate(fv!row.activatedAt))),
                      if(local!days = 0, "< 1 day", local!days & if(local!days = 1, " day", " days"))
                    ),
                    "—"
                  )
                )
              )
            ),
            width: "NARROW_PLUS",
            backgroundColor: if(tostring(a!defaultValue(fv!row.status, "")) = "In Progress", "#E8F0FC", "NONE")
          ),
          a!gridColumn(label: "Comments", value: if(a!isNullOrEmpty(fv!row.comments), "—", if(or(trim(fv!row.comments) = "", upper(trim(fv!row.comments)) = "N/A"), "—", fv!row.comments)), backgroundColor: if(tostring(a!defaultValue(fv!row.status, "")) = "In Progress", "#E8F0FC", "NONE"))
        },
        pageSize: 20,
        spacing: "DENSE",
        borderStyle: "LIGHT",
        rowHeader: 2,
        emptyGridMessage: "No approval chain on this draw"
      ),
      rule!SD_cmp_sourceLine(text: "The CEO approves by email reply. All decisions are recorded with actor, source (task, email, or system), and timestamp. On final approval, Treasury is notified to execute the cash payment.")
    },
    style: "NONE",
    shape: "SEMI_ROUNDED",
    padding: "STANDARD",
    showBorder: true,
    showShadow: false,
    marginBelow: "STANDARD"
  ),
    a!cardLayout(
    contents: {
      a!richTextDisplayField(
        labelPosition: "COLLAPSED",
        value: a!richTextItem(text: "Email Exchange", size: "MEDIUM", style: "STRONG", color: "#16294D"),
        marginBelow: "EVEN_LESS"
      ),
      rule!SD_cmp_sourceLine(text: "Every approval email, reply and response on this draw, oldest first · a reply is read by one AI call, checked by fixed rules, and applied only from an authorized sender at the step awaiting a decision · draws above " & rule!SD_fmtMoney(value: cons!SD_EMAIL_APPROVAL_MAX, showCents: false) & " are decided in the system, not by email"),
      a!gridField(
        labelPosition: "COLLAPSED",
        data: local!emails,
        columns: {
          a!gridColumn(
            label: "When",
            value: a!richTextDisplayField(
              value: if(
                a!isNullOrEmpty(fv!row.messageAt),
                a!richTextItem(text: "—"),
                {
                  a!richTextItem(text: text(fv!row.messageAt, "MM/DD/YYYY")),
                  char(10),
                  a!richTextItem(text: text(fv!row.messageAt, "h:mm a"), color: "#6B7280", size: "SMALL")
                }
              )
            ),
            width: "NARROW_PLUS"
          ),
          a!gridColumn(
            label: "Message",
            value: a!localVariables(
              local!k: fv!row.kind,
              local!dir: a!match(value: fv!row.direction, equals: "INBOUND", then: "Inbound", equals: "OUTBOUND", then: "Outbound", equals: "INTERNAL", then: "Internal", default: fv!row.direction),
              local!body: trim(a!defaultValue(fv!row.body, "")),
              a!richTextDisplayField(
                value: {
                  a!richTextItem(
                    text: a!match(
                      value: local!k,
                      equals: "STEP_EMAIL", then: "Approval email to " & fv!row.toAddress,
                      equals: "REPLY", then: "Reply from " & fv!row.fromAddress,
                      equals: "CLARIFICATION", then: "Clarification to " & fv!row.toAddress,
                      equals: "GUARDRAIL_REFUSAL", then: "Email approval refused, to " & fv!row.toAddress,
                      equals: "EXCEPTION_REVIEW", then: "Exception reviewed by " & fv!row.fromAddress,
                      default: local!k & " · " & fv!row.fromAddress
                    ),
                    style: "STRONG"
                  ),
                  char(10),
                  a!richTextItem(
                    text: local!dir & " · source " & lower(fv!row.source) & if(a!isNullOrEmpty(fv!row.stepOrder), "", " · step " & fv!row.stepOrder),
                    color: "#6B7280",
                    size: "SMALL"
                  ),
                  char(10),
                  a!richTextItem(
                    text: if(
                      local!body = "",
                      "(no text)",
                      if(len(local!body) > 700, left(local!body, 700) & "…", local!body)
                    ),
                    color: if(local!body = "", "#6B7280", "STANDARD")
                  )
                }
              )
            )
          ),
          a!gridColumn(
            label: "Reading",
            value: a!richTextDisplayField(
              value: {
                if(
                  fv!row.interpretation = "",
                  "",
                  {a!richTextItem(text: fv!row.interpretation, size: "SMALL"), char(10)}
                ),
                a!richTextItem(text: if(fv!row.notes = "", "—", fv!row.notes), color: "#6B7280", size: "SMALL")
              }
            ),
            width: "MEDIUM"
          ),
          a!gridColumn(
            label: "Outcome",
            value: a!localVariables(
              local!o: fv!row.outcome,
              local!tone: a!match(
                value: local!o,
                equals: "APPROVE", then: "G",
                equals: "REJECT", then: "R",
                equals: "SENT", then: "N",
                equals: "RECEIVED", then: "N",
                equals: "REVIEWED", then: "N",
                default: "A"
              ),
              a!tagField(
                labelPosition: "COLLAPSED",
                tags: a!tagItem(
                  text: a!match(
                    value: local!o,
                    equals: "APPROVE", then: "Approved by email",
                    equals: "REJECT", then: "Rejected by email",
                    equals: "AMBIGUOUS", then: "Unclear · clarification sent",
                    equals: "EXCEPTION", then: "Sent to exception queue",
                    equals: "GUARDRAIL", then: "Over the email limit",
                    equals: "UNAUTHORIZED", then: "Sender not authorized",
                    equals: "NOT_AWAITING", then: "Step not awaiting a decision",
                    equals: "UNMATCHED", then: "No draw reference",
                    equals: "SENT", then: "Sent",
                    equals: "RECEIVED", then: "Received",
                    equals: "REVIEWED", then: "Reviewed",
                    default: if(local!o = "", "—", left(local!o, 40))
                  ),
                  backgroundColor: a!match(value: local!tone, equals: "G", then: "#E6F4EC", equals: "R", then: "#FDECEC", equals: "A", then: "#FDF3E0", default: "#EEF1F5"),
                  textColor: a!match(value: local!tone, equals: "G", then: "#1E7E46", equals: "R", then: "#B42318", equals: "A", then: "#92600A", default: "#64748B")
                ),
                size: "SMALL"
              )
            ),
            width: "NARROW_PLUS"
          )
        },
        pageSize: 20,
        spacing: "DENSE",
        borderStyle: "LIGHT",
        emptyGridMessage: "No approval emails on this draw yet"
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

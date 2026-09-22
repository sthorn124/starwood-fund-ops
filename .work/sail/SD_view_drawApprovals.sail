/* Draw approval: the Approvals view of a draw record (mockups/draw-summary.html, Approvals tab).
   The nine-row chain as data: order, role, approver, status, decision date, time at step (computed), comments.
   The row in progress is highlighted. Time at step: decided rows count whole days from activation to decision
   (at least 1); the open row counts from activation to today. */
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
  )
  }
)

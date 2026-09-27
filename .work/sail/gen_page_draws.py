from refs import *
money = lambda e, c="false": f"rule!SD_fmtMoney(value: {e}, showCents: {c})"
HL = 'if(a!defaultValue(fv!row.actionForViewer, false), "#E8F0FC", "NONE")'

def kpi(label, value, sub, attn="false"):
    return f'''a!cardLayout(
          contents: {{
            a!richTextDisplayField(
              labelPosition: "COLLAPSED",
              value: {{
                a!richTextItem(text: upper({label}), color: "#6B7280", size: "SMALL"),
                char(10),
                a!richTextItem(text: {value}, size: "LARGE", style: "STRONG", color: "#16294D"),
                char(10),
                a!richTextItem(text: {sub}, color: "#6B7280", size: "SMALL")
              }},
              marginBelow: "NONE"
            )
          }},
          decorativeBarPosition: if({attn}, "START", "NONE"),
          decorativeBarColor: "#1D5BBF",
          style: "NONE",
          shape: "SEMI_ROUNDED",
          padding: "STANDARD",
          showBorder: true,
          showShadow: false,
          marginBelow: "NONE"
        )'''

sail = f"""/* Draw approval: the Draws page on the intake site, built against mockups/draw-list.html (the UI contract).
   Band · four KPI cards · filter row · the draw grid · note. Every KPI and every row comes from
   rule!SD_getDrawListRows (one read per draw, viewer-aware), so "Awaiting My Action", the YOUR ACTION tag and
   the row highlight all mean the same thing: the viewer holds the current step and a task is open for it.
   Rows are already sorted by that rule: awaiting the viewer first, in approval by funding date ascending, then
   completed by funding date descending. Filters and search narrow the rows without changing the order.
   Phase 6c: "yours" also covers an email reply waiting for the draw approval team's review (actionForViewer), a fifth
   KPI shows the average days from receipt to decision over decided draws, and the draw approval team (the oversight role)
   can switch to "Needs chasing": rule!SD_getChaseRows over the same rows — steps waiting SD_CHASE_AGE_DAYS or more and
   replies to review, ranked by amount then days to funding, with who holds each and how to reach them. */
a!localVariables(
  local!rows: rule!SD_getDrawListRows(),
  local!search,
  local!status,
  local!fund,
  local!investment,
  local!type,
  /* an Ingesting shell has no investment or fund yet; "" is not a legal dropdown choice value, so blanks are dropped */
  local!funds: a!localVariables(local!names: a!forEach(items: local!rows, expression: tostring(a!defaultValue(fv!item.fundName, ""))), local!named: if(a!isNullOrEmpty(local!names), {{}}, index(local!names, wherecontains(false, a!forEach(items: local!names, expression: fv!item = "")), {{}})), if(a!isNullOrEmpty(local!named), {{}}, union(local!named, local!named))),
  local!investments: a!localVariables(local!names: a!forEach(items: local!rows, expression: tostring(a!defaultValue(fv!item.investmentName, ""))), local!named: if(a!isNullOrEmpty(local!names), {{}}, index(local!names, wherecontains(false, a!forEach(items: local!names, expression: fv!item = "")), {{}})), if(a!isNullOrEmpty(local!named), {{}}, union(local!named, local!named))),
  /* row subsets are selected with wherecontains over a boolean list: an a!forEach that returns {{}} for skipped
     items yields N nulls when every item is skipped, which counted as 6 "awaiting" rows for a viewer with none */
  local!filtered: if(a!isNullOrEmpty(local!rows), {{}}, index(
    local!rows,
    wherecontains(
      true,
      a!forEach(
        items: local!rows,
        expression: a!localVariables(
          local!s: lower(a!defaultValue(local!search, "")),
          local!hay: lower("#" & a!defaultValue(fv!item.drawNumber, "") & " " & a!defaultValue(fv!item.investmentName, "") & " " & a!defaultValue(fv!item.purpose, "") & " " & a!defaultValue(fv!item.drawType, "")),
          and(
            or(a!isNullOrEmpty(local!status), tostring(a!defaultValue(fv!item.status, "")) = local!status),
            or(a!isNullOrEmpty(local!fund), a!defaultValue(fv!item.fundName, "") = local!fund),
            or(a!isNullOrEmpty(local!investment), a!defaultValue(fv!item.investmentName, "") = local!investment),
            or(a!isNullOrEmpty(local!type), a!defaultValue(fv!item.drawType, "") = local!type),
            or(local!s = "", find(local!s, local!hay) > 0)
          )
        )
      )
    ),
    {{}}
  )),
  /* KPIs, computed from the full (unfiltered) row set */
  local!awaiting: if(a!isNullOrEmpty(local!rows), {{}}, index(local!rows, wherecontains(true, a!forEach(items: local!rows, expression: a!defaultValue(fv!item.actionForViewer, false))), {{}})),
  /* Phase 6c: cycle time over decided draws (received to terminal decision; accelerated chains carry generated dates) */
  local!decided: if(a!isNullOrEmpty(local!rows), {{}}, index(local!rows, wherecontains(false, a!forEach(items: local!rows, expression: a!isNullOrEmpty(fv!item.daysToDecide))), {{}})),
  local!avgDays: if(a!isNullOrEmpty(local!decided), null, round(sum(a!forEach(items: local!decided, expression: fv!item.daysToDecide)) / count(local!decided), 1)),
  /* Phase 6c: the Needs chasing view, for the draw approval team (SD Draw Demo Approvers, the oversight role) */
  local!isOversight: a!defaultValue(a!isUserMemberOfGroup(username: loggedInUser(), groups: cons!SD_DRAW_DEMO_APPROVERS_GROUP), false),
  local!view: "ALL",
  local!chase: if(local!isOversight, rule!SD_getChaseRows(rows: local!rows), {{}}),
  /* Phase 6c: demo staging for administrators only — the EY feed arrival, run through the same a!startProcess call the
     Receive Capital Call page makes, with the prepared package already on the instance (SD_FEED_PACKAGE_*) */
  local!isAdmin: a!defaultValue(a!isUserMemberOfGroup(username: loggedInUser(), groups: cons!SD_ADMINISTRATORS_GROUP), false),
  local!feedState,
  local!feedAt,
  local!chaseRanked: if(a!isNullOrEmpty(local!chase), {{}}, a!forEach(items: local!chase, expression: a!update(fv!item, "rank", fv!index))),
  local!inApproval: if(a!isNullOrEmpty(local!rows), {{}}, index(local!rows, wherecontains("In Progress", a!forEach(items: local!rows, expression: tostring(a!defaultValue(fv!item.status, "")))), {{}})),
  local!next30: if(a!isNullOrEmpty(local!rows), {{}}, index(
    local!rows,
    wherecontains(
      true,
      a!forEach(
        items: local!rows,
        expression: and(
          tostring(a!defaultValue(fv!item.status, "")) <> "Rejected",
          not(a!isNullOrEmpty(fv!item.fundingDate)),
          todate(fv!item.fundingDate) >= today(),
          todate(fv!item.fundingDate) <= today() + 30
        )
      )
    ),
    {{}}
  )),
  /* min() over dates comes back as a datetime and can shift a day in the viewer's time zone, so the nearest date is found as a day offset from today */
  local!nextFunding: if(a!isNullOrEmpty(local!next30), null, today() + min(a!forEach(items: local!next30, expression: tointeger(todate(fv!item.fundingDate) - today())))),
  local!fundedYtd: if(a!isNullOrEmpty(local!rows), {{}}, index(
    local!rows,
    wherecontains(
      true,
      a!forEach(
        items: local!rows,
        expression: and(
          tostring(a!defaultValue(fv!item.status, "")) = "Approved",
          not(a!isNullOrEmpty(fv!item.fundingDate)),
          year(todate(fv!item.fundingDate)) = year(today()),
          todate(fv!item.fundingDate) <= today()
        )
      )
    ),
    {{}}
  )),
  local!firstAwaiting: if(a!isNullOrEmpty(local!awaiting), null, index(local!awaiting, 1, null)),
  a!headerContentLayout(
    header: {{
      a!cardLayout(
        contents: {{
          a!richTextDisplayField(
            labelPosition: "COLLAPSED",
            value: {{
              a!richTextItem(text: "Fund Operations", color: "#93C5FD", size: "SMALL"),
              char(10),
              a!richTextItem(text: "Draws", size: "LARGE", style: "STRONG", color: "#FFFFFF"),
              char(10),
              a!richTextItem(
                text: "Capital call draw requests across investments" & if(
                  count(local!funds) = 1,
                  " · " & local!funds[1],
                  if(count(local!funds) = 0, "", " · " & count(local!funds) & " funds")
                ),
                color: "#C7D2E5",
                size: "SMALL"
              )
            }},
            marginBelow: "NONE"
          )
        }},
        style: "#16294D",
        height: "AUTO",
        padding: "MORE",
        showBorder: false,
        showShadow: false,
        marginBelow: "NONE"
      )
    }},
    contents: {{
      a!cardGroupLayout(
        cards: {{
          {kpi('"Awaiting My Action"', 'tostring(count(local!awaiting))',
               '''if(
                  a!isNullOrEmpty(local!firstAwaiting),
                  "Nothing waiting on you",
                  if(
                    and(a!defaultValue(local!firstAwaiting.exceptionForViewer, false), not(a!defaultValue(local!firstAwaiting.awaitingViewer, false))),
                    "Draw #" & a!defaultValue(local!firstAwaiting.drawNumber, "") & " · email reply to review",
                    if(a!isNullOrEmpty(local!firstAwaiting.drawNumber), "New draw (ingesting)", "Draw #" & local!firstAwaiting.drawNumber) & " · " & a!defaultValue(local!firstAwaiting.currentRole, "") & if(a!defaultValue(local!firstAwaiting.ingesting, false), " · ", " step · ") & if(a!defaultValue(local!firstAwaiting.daysAtStep, 0) = 0, "today", local!firstAwaiting.daysAtStep & if(local!firstAwaiting.daysAtStep = 1, " day", " days"))
                  )
                )''', 'count(local!awaiting) > 0')},
          {kpi('"In Approval"', money('sum(a!forEach(items: local!inApproval, expression: a!defaultValue(fv!item.amount, 0)))'),
               'count(local!inApproval) & if(count(local!inApproval) = 1, " draw", " draws")')},
          {kpi('"Funding Next 30 Days"', money('sum(a!forEach(items: local!next30, expression: a!defaultValue(fv!item.amount, 0)))'),
               'count(local!next30) & if(count(local!next30) = 1, " draw", " draws") & if(a!isNullOrEmpty(local!nextFunding), "", " · next: " & text(local!nextFunding, "MMM D"))')},
          {kpi('"Funded YTD " & year(today())', money('sum(a!forEach(items: local!fundedYtd, expression: a!defaultValue(fv!item.amount, 0)))'),
               'count(local!fundedYtd) & if(count(local!fundedYtd) = 1, " draw", " draws")')},
          {kpi('"Avg Days to Decide"', 'if(a!isNullOrEmpty(local!avgDays), "—", text(local!avgDays, "0.0"))',
               'if(a!isNullOrEmpty(local!decided), "No decided draws yet", count(local!decided) & if(count(local!decided) = 1, " decided draw", " decided draws") & " · receipt to decision")')}
        }},
        cardWidth: "EXTRA_NARROW",
        spacing: "STANDARD",
        marginBelow: "STANDARD"
      ),
      /* Phase 6c: the oversight view switch (draw approval team only) */
      a!radioButtonField(
        labelPosition: "COLLAPSED",
        choiceLabels: {{"All draws", "Needs chasing (" & count(local!chase) & ")"}},
        choiceValues: {{"ALL", "CHASE"}},
        value: local!view,
        saveInto: local!view,
        choiceLayout: "COMPACT",
        choiceStyle: "CARDS",
        showWhen: local!isOversight,
        marginBelow: "STANDARD"
      ),
      a!cardLayout(
        contents: {{
          a!richTextDisplayField(
            labelPosition: "COLLAPSED",
            value: a!richTextItem(text: "Needs Chasing", size: "MEDIUM", style: "STRONG", color: "#16294D"),
            marginBelow: "EVEN_LESS"
          ),
          rule!SD_cmp_sourceLine(
            text: "Approval steps waiting " & cons!SD_CHASE_AGE_DAYS & " days or more, and email replies waiting for the team's review · ranked by amount, then days to funding · the same list goes to the team by email every morning · amber: waiting " & cons!SD_SMS_AGE_DAYS & " days or more, when the escalation texts the approver"
          ),
          a!gridField(
            labelPosition: "COLLAPSED",
            data: local!chaseRanked,
            columns: {{
              a!gridColumn(label: "#", value: fv!row.rank, align: "CENTER", width: "ICON_PLUS"),
              a!gridColumn(
                label: "Draw",
                value: a!richTextDisplayField(
                  value: {{
                    a!richTextItem(
                      text: "#" & a!defaultValue(fv!row.drawNumber, fv!row.drawId),
                      link: a!recordLink(recordType: {rt(DRAW)}, identifier: fv!row.drawId),
                      linkStyle: "STANDALONE",
                      style: "STRONG"
                    ),
                    char(10),
                    a!richTextItem(text: fv!row.investmentName, color: "#6B7280", size: "SMALL")
                  }}
                ),
                width: "MEDIUM"
              ),
              a!gridColumn(label: "Amount", value: {money("fv!row.amount")}, align: "END", width: "NARROW_PLUS"),
              a!gridColumn(
                label: "Funding",
                value: a!richTextDisplayField(
                  value: {{
                    a!richTextItem(text: if(a!isNullOrEmpty(fv!row.fundingDate), "—", text(todate(fv!row.fundingDate), "MM/DD/YYYY"))),
                    char(10),
                    a!richTextItem(text: rule!SD_fmtRelativeDays(days: fv!row.daysToFunding), color: "#6B7280", size: "SMALL")
                  }}
                ),
                width: "NARROW_PLUS"
              ),
              a!gridColumn(
                label: "Waiting On",
                value: a!richTextDisplayField(
                  value: if(
                    fv!row.role = "",
                    a!richTextItem(text: "The draw approval team"),
                    {{
                      a!richTextItem(text: fv!row.approverName, style: "STRONG"),
                      char(10),
                      a!richTextItem(text: fv!row.role & " · step " & fv!row.currentStep & " of " & fv!row.totalSteps, color: "#6B7280", size: "SMALL")
                    }}
                  )
                ),
                width: "MEDIUM"
              ),
              a!gridColumn(
                label: "Why",
                value: a!richTextDisplayField(
                  value: {{
                    a!richTextItem(text: fv!row.reason, color: if(fv!row.smsDue, "#92600A", "#1F2937"), style: if(fv!row.smsDue, "STRONG", "PLAIN")),
                    if(
                      fv!row.lastChaseLabel = "",
                      "",
                      {{char(10), a!richTextItem(text: fv!row.lastChaseLabel & " " & text(fv!row.lastChaseAt, "MMM D, h:mm a"), color: "#6B7280", size: "SMALL")}}
                    )
                  }}
                ),
                width: "MEDIUM"
              ),
              a!gridColumn(
                label: "Contact",
                value: a!richTextDisplayField(
                  value: {{
                    a!richTextItem(text: if(fv!row.contact = "", "—", fv!row.contact)),
                    if(fv!row.groupName = "", "", {{char(10), a!richTextItem(text: "task: " & fv!row.groupName, color: "#6B7280", size: "SMALL")}})
                  }}
                )
              )
            }},
            pageSize: 25,
            spacing: "STANDARD",
            borderStyle: "LIGHT",
            rowHeader: 2,
            emptyGridMessage: "Nothing needs chasing: no step has waited " & cons!SD_CHASE_AGE_DAYS & " days, and no email reply is waiting for review"
          )
        }},
        showWhen: and(local!isOversight, local!view = "CHASE"),
        style: "NONE",
        shape: "SEMI_ROUNDED",
        padding: "STANDARD",
        showBorder: true,
        showShadow: false,
        marginBelow: "STANDARD"
      ),
      a!cardLayout(
        contents: {{
          a!columnsLayout(
            columns: {{
              a!columnLayout(
                contents: a!textField(
                  labelPosition: "COLLAPSED",
                  placeholder: "Search draws, investments, purposes…",
                  value: local!search,
                  saveInto: local!search,
                  refreshAfter: "KEYPRESS",
                  marginBelow: "NONE"
                ),
                width: "AUTO"
              ),
              a!columnLayout(
                contents: a!dropdownField(
                  labelPosition: "COLLAPSED",
                  placeholder: "Status: All",
                  choiceLabels: {{"Ingesting", "Ingestion Failed", "In Progress", "Approved", "Rejected"}},
                  choiceValues: {{"Ingesting", "Ingestion Failed", "In Progress", "Approved", "Rejected"}},
                  value: local!status,
                  saveInto: local!status,
                  marginBelow: "NONE"
                ),
                width: "NARROW_PLUS"
              ),
              a!columnLayout(
                contents: a!dropdownField(
                  labelPosition: "COLLAPSED",
                  placeholder: "Fund: All",
                  choiceLabels: local!funds,
                  choiceValues: local!funds,
                  value: local!fund,
                  saveInto: local!fund,
                  disabled: a!isNullOrEmpty(local!funds),
                  marginBelow: "NONE"
                ),
                width: "MEDIUM"
              ),
              a!columnLayout(
                contents: a!dropdownField(
                  labelPosition: "COLLAPSED",
                  placeholder: "Investment: All",
                  choiceLabels: local!investments,
                  choiceValues: local!investments,
                  value: local!investment,
                  saveInto: local!investment,
                  disabled: a!isNullOrEmpty(local!investments),
                  marginBelow: "NONE"
                ),
                width: "MEDIUM"
              ),
              a!columnLayout(
                contents: a!dropdownField(
                  labelPosition: "COLLAPSED",
                  placeholder: "Type: All",
                  choiceLabels: {{"Development", "PIP/Renovation"}},
                  choiceValues: {{"Development", "PIP/Renovation"}},
                  value: local!type,
                  saveInto: local!type,
                  marginBelow: "NONE"
                ),
                width: "NARROW_PLUS"
              )
            }},
            stackWhen: {{"PHONE", "TABLET_PORTRAIT"}},
            marginBelow: "NONE"
          )
        }},
        showWhen: local!view <> "CHASE",
        style: "NONE",
        shape: "SEMI_ROUNDED",
        padding: "STANDARD",
        showBorder: true,
        showShadow: false,
        marginBelow: "STANDARD"
      ),
      a!cardLayout(
        contents: {{
          a!gridField(
            labelPosition: "COLLAPSED",
            data: local!filtered,
            columns: {{
              a!gridColumn(
                label: "Draw",
                value: a!richTextDisplayField(
                  value: {{
                    a!richTextItem(
                      text: if(
                        a!isNullOrEmpty(fv!row.drawNumber),
                        if(tostring(a!defaultValue(fv!row.status, "")) = "Ingestion Failed", "Not loaded", "New draw"),
                        "#" & fv!row.drawNumber
                      ),
                      link: a!recordLink(recordType: {rt(DRAW)}, identifier: fv!row.id),
                      linkStyle: "STANDALONE",
                      style: "STRONG"
                    ),
                    if(
                      a!defaultValue(fv!row.actionForViewer, false),
                      {{char(10), a!richTextItem(text: "YOUR ACTION", color: "#1D5BBF", size: "SMALL", style: "STRONG")}},
                      ""
                    )
                  }}
                ),
                width: "NARROW_PLUS",
                backgroundColor: {HL}
              ),
              a!gridColumn(
                label: "Investment",
                value: a!richTextDisplayField(
                  value: a!richTextItem(
                    text: a!defaultValue(fv!row.investmentName, "—"),
                    link: a!recordLink(recordType: {rt(DRAW)}, identifier: fv!row.id),
                    linkStyle: "STANDALONE"
                  )
                ),
                width: "MEDIUM_PLUS",
                backgroundColor: {HL}
              ),
              a!gridColumn(label: "Type", value: a!defaultValue(fv!row.drawType, "—"), width: "NARROW_PLUS", backgroundColor: {HL}),
              a!gridColumn(label: "Amount", value: {money("fv!row.amount", "true")}, align: "END", width: "NARROW_PLUS", backgroundColor: {HL}),
              a!gridColumn(
                label: "Funding Date",
                value: a!richTextDisplayField(
                  value: {{
                    a!richTextItem(text: if(a!isNullOrEmpty(fv!row.fundingDate), "—", text(todate(fv!row.fundingDate), "MM/DD/YYYY"))),
                    if(
                      tostring(a!defaultValue(fv!row.status, "")) = "In Progress",
                      {{char(10), a!richTextItem(text: rule!SD_fmtRelativeDays(days: fv!row.daysToFunding), color: "#6B7280", size: "SMALL")}},
                      ""
                    )
                  }}
                ),
                width: "NARROW_PLUS",
                backgroundColor: {HL}
              ),
              a!gridColumn(
                label: "Current Step",
                value: a!richTextDisplayField(
                  value: a!localVariables(
                    local!s: tostring(a!defaultValue(fv!row.status, "")),
                    if(
                      local!s = "In Progress",
                      {{
                        a!richTextItem(text: a!defaultValue(fv!row.currentStep, "?") & " of " & a!defaultValue(fv!row.totalSteps, "?") & " · " & a!defaultValue(fv!row.currentRole, "")),
                        char(10),
                        a!richTextItem(
                          text: a!defaultValue(fv!row.currentApprover, "") & if(
                            a!isNullOrEmpty(fv!row.daysAtStep),
                            "",
                            " · " & if(fv!row.daysAtStep = 0, "today", fv!row.daysAtStep & if(fv!row.daysAtStep = 1, " day", " days"))
                          ),
                          color: "#6B7280",
                          size: "SMALL"
                        )
                      }},
                      if(
                        local!s = "Approved",
                        a!richTextItem(text: "Complete", color: "#6B7280"),
                        if(
                          local!s = "Rejected",
                          a!richTextItem(text: "Rejected at step " & a!defaultValue(fv!row.currentStep, "?"), color: "#B42318"),
                          if(
                            local!s = "Ingesting",
                            {{
                              a!richTextItem(text: "Doc Center extraction · Accountant reconciliation"),
                              char(10),
                              a!richTextItem(text: "received " & if(a!isNullOrEmpty(fv!row.receivedDate), "—", text(todate(fv!row.receivedDate), "MMM D")), color: "#6B7280", size: "SMALL")
                            }},
                            if(
                              local!s = "Ingestion Failed",
                              {{
                                a!richTextItem(text: "Template could not be loaded", color: "#B42318"),
                                char(10),
                                a!richTextItem(text: "received " & if(a!isNullOrEmpty(fv!row.receivedDate), "—", text(todate(fv!row.receivedDate), "MMM D")) & " · resubmit via Receive Capital Call", color: "#6B7280", size: "SMALL")
                              }},
                              a!richTextItem(text: "—", color: "#6B7280")
                            )
                          )
                        )
                      )
                    )
                  )
                ),
                width: "MEDIUM",
                backgroundColor: {HL}
              ),
              a!gridColumn(label: "Status", value: rule!SD_cmp_statusTag(status: fv!row.status), width: "NARROW_PLUS", backgroundColor: {HL})
            }},
            pageSize: 25,
            spacing: "STANDARD",
            borderStyle: "LIGHT",
            rowHeader: 1,
            emptyGridMessage: "No draws match these filters"
          ),
          rule!SD_cmp_sourceLine(text: "Rows render from SD Draw records. Sort: rows awaiting the viewer first, then in-approval by funding date ascending, then completed by funding date descending. The highlighted row and the YOUR ACTION tag appear when the viewer holds the current approval step and a task is open for it, or when an email reply on the draw is waiting for the viewer's team to review.")
        }},
        showWhen: local!view <> "CHASE",
        style: "NONE",
        shape: "SEMI_ROUNDED",
        padding: "STANDARD",
        showBorder: true,
        showShadow: false,
        marginBelow: "STANDARD"
      )
      ,
      /* Phase 6c: demo staging (SD Administrators only). The presenter stages the EY API/SFTP drop before beat 1: the
         prepared template and supporting PDFs go through a!startProcess(cons!SD_RECEIVE_CAPITAL_CALL_PM, …) exactly as the
         Receive Capital Call page sends them, so the pipeline, the Ingesting row and the reconciliation task are the real ones. */
      a!cardLayout(
        contents: {{
          a!columnsLayout(
            columns: {{
              a!columnLayout(
                contents: {{
                  a!richTextDisplayField(
                    labelPosition: "COLLAPSED",
                    value: {{
                      a!richTextItem(text: "DEMO STAGING · ADMINISTRATORS ONLY", color: "#6B7280", size: "SMALL", style: "STRONG"),
                      char(10),
                      a!richTextItem(
                        text: if(
                          local!feedState = "ERROR",
                          "The feed arrival could not be started. Check that the package documents in SD_FEED_PACKAGE_FAILING_TEMPLATE, SD_FEED_PACKAGE_TEMPLATE and SD_FEED_PACKAGE_SUPPORTING still exist.",
                          if(
                            a!isNullOrEmpty(local!feedState),
                            "Stage the EY feed arrival through the same intake path as Receive Capital Call. Beats 1–2: the malformed template (" & document(cons!SD_FEED_PACKAGE_FAILING_TEMPLATE, "name") & ") fails validation and sends the alert. Beat 3: the corrected package (" & document(cons!SD_FEED_PACKAGE_TEMPLATE, "name") & " and " & count(cons!SD_FEED_PACKAGE_SUPPORTING) & " supporting PDFs) ingests.",
                            if(local!feedState = "FAILING", "Malformed template", "Corrected package") & " staged at " & text(local!feedAt, "h:mm a") & ". The new draw appears within about 10 seconds (reload this page); " &
                            if(local!feedState = "FAILING", "the ingestion failure alert follows in about 90 seconds.", "the accountant's reconciliation task follows in about 90 seconds.")
                          )
                        ),
                        color: if(local!feedState = "ERROR", "#B42318", "#1F2937"),
                        size: "SMALL"
                      )
                    }},
                    marginBelow: "NONE"
                  )
                }}
              ),
              a!columnLayout(
                contents: a!buttonArrayLayout(
                  buttons: {{
                    a!buttonWidget(
                      label: "Stage Malformed Template",
                      style: "OUTLINE",
                      size: "SMALL",
                      saveInto: a!startProcess(
                        processModel: cons!SD_RECEIVE_CAPITAL_CALL_PM,
                        processParameters: a!map(document: cons!SD_FEED_PACKAGE_FAILING_TEMPLATE, supportingDocuments: {{}}),
                        onSuccess: {{ a!save(local!feedState, "FAILING"), a!save(local!feedAt, now()) }},
                        onError: a!save(local!feedState, "ERROR")
                      )
                    ),
                    a!buttonWidget(
                      label: "Stage Corrected Package",
                      style: "OUTLINE",
                      size: "SMALL",
                      saveInto: a!startProcess(
                        processModel: cons!SD_RECEIVE_CAPITAL_CALL_PM,
                        processParameters: a!map(document: cons!SD_FEED_PACKAGE_TEMPLATE, supportingDocuments: cons!SD_FEED_PACKAGE_SUPPORTING),
                        onSuccess: {{ a!save(local!feedState, "PACKAGE"), a!save(local!feedAt, now()) }},
                        onError: a!save(local!feedState, "ERROR")
                      )
                    )
                  }},
                  align: "END",
                  marginBelow: "NONE"
                ),
                width: "MEDIUM"
              )
            }},
            alignVertical: "MIDDLE",
            stackWhen: {{"PHONE"}},
            marginBelow: "NONE"
          )
        }},
        showWhen: local!isAdmin,
        style: "NONE",
        shape: "SEMI_ROUNDED",
        padding: "LESS",
        showBorder: true,
        showShadow: false,
        marginBelow: "STANDARD"
      )
    }},
    backgroundColor: "#F5F6F8",
    contentsPadding: "STANDARD"
  )
)
"""
open("SD_page_draws.sail","w").write(sail)
print("written", len(sail))

from refs import *
money = lambda e, c="false": f"rule!SD_fmtMoney(value: {e}, showCents: {c})"
HL = 'if(a!defaultValue(fv!row.awaitingViewer, false), "#E8F0FC", "NONE")'

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
   completed by funding date descending. Filters and search narrow the rows without changing the order. */
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
  local!awaiting: if(a!isNullOrEmpty(local!rows), {{}}, index(local!rows, wherecontains(true, a!forEach(items: local!rows, expression: a!defaultValue(fv!item.awaitingViewer, false))), {{}})),
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
                  if(a!isNullOrEmpty(local!firstAwaiting.drawNumber), "New draw (ingesting)", "Draw #" & local!firstAwaiting.drawNumber) & " · " & a!defaultValue(local!firstAwaiting.currentRole, "") & if(a!defaultValue(local!firstAwaiting.ingesting, false), " · ", " step · ") & if(a!defaultValue(local!firstAwaiting.daysAtStep, 0) = 0, "today", local!firstAwaiting.daysAtStep & if(local!firstAwaiting.daysAtStep = 1, " day", " days"))
                )''', 'count(local!awaiting) > 0')},
          {kpi('"In Approval"', money('sum(a!forEach(items: local!inApproval, expression: a!defaultValue(fv!item.amount, 0)))'),
               'count(local!inApproval) & if(count(local!inApproval) = 1, " draw", " draws")')},
          {kpi('"Funding Next 30 Days"', money('sum(a!forEach(items: local!next30, expression: a!defaultValue(fv!item.amount, 0)))'),
               'count(local!next30) & if(count(local!next30) = 1, " draw", " draws") & if(a!isNullOrEmpty(local!nextFunding), "", " · next: " & text(local!nextFunding, "MMM D"))')},
          {kpi('"Funded YTD " & year(today())', money('sum(a!forEach(items: local!fundedYtd, expression: a!defaultValue(fv!item.amount, 0)))'),
               'count(local!fundedYtd) & if(count(local!fundedYtd) = 1, " draw", " draws")')}
        }},
        cardWidth: "NARROW",
        spacing: "STANDARD",
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
                      a!defaultValue(fv!row.awaitingViewer, false),
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
          rule!SD_cmp_sourceLine(text: "Rows render from SD Draw records. Sort: rows awaiting the viewer first, then in-approval by funding date ascending, then completed by funding date descending. The highlighted row and the YOUR ACTION tag appear when the viewer holds the current approval step and a task is open for it.")
        }},
        style: "NONE",
        shape: "SEMI_ROUNDED",
        padding: "STANDARD",
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

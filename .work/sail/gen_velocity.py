"""Phase 6c: the velocity rules. Writes one .sail file per rule. No f-strings in the SAIL bodies (braces and quotes).

  SD_getEscalationMinutes(level)          minutes until a step task's escalation level fires (1 = reminder email at
                                          SD_CHASE_AGE_DAYS, 2 = SMS at SD_SMS_AGE_DAYS; SD_ESCALATION_TEST_MINUTES > 0
                                          overrides both for a test). Called by the step task's escalation timers.
  SD_buildStepReminderEmail(drawId, stepOrder)
                                          the step email again, under an amber reminder banner, with the subject
                                          "Reminder · Draw #<n> · funding in <d> days · awaiting your approval" and the
                                          reply token, so a reply still reaches the right draw and step
  SD_buildStepSms(drawId, stepOrder)      the SMS rung's text: "Draw #<n> · $<amount> · funding in <d> days · awaiting
                                          your approval · reply by email" (over the email limit: "decide in the system")
  SD_maskPhone(number)                    "+1 ••• ••• 1234": how a phone number is shown and logged
  SD_getChaseRows(rows)                   the "Needs chasing" rows: in-approval steps waiting SD_CHASE_AGE_DAYS or more,
                                          and draws with an email reply to review, ranked by amount (largest first),
                                          then by days to funding; who holds each, with contact and last chase
  SD_buildChaseDigestEmail(rows)          the daily digest to the draw approval team, from SD_getChaseRows
  SD_resolveChaseTarget(originProcessId)  what a step-task escalation is about: the draw holding that step process, its
                                          current step and approval row, and the rung (REMINDER unless one is logged)
"""
from refs import *

m = lambda n: fld(MSG, n)

SITE_DRAWS = "'site!{ffae752f-b3d1-44d5-a9ba-c408b66bdb65}SASite.pages.{76fd3289-c3d8-4c52-ad60-8342f924d6d6}draws'"

ESC = r'''/* Draw approval (Phase 6c): minutes until an escalation level on the step task fires. The step task (SD Draw Approval
   Step, "Approve or reject draw") carries two escalation levels, configured in Designer (the Dev MCP exposes no
   escalations): level 1 re-sends the step email as a reminder once the step has waited SD_CHASE_AGE_DAYS; level 2 is the
   SMS rung at SD_SMS_AGE_DAYS. Appian starts a level's timer when the level before it fires, so level 2 waits the
   difference. SD_ESCALATION_TEST_MINUTES above 0 replaces both waits (a test on a throwaway draw; restore it to 0). */
a!localVariables(
  local!test: tointeger(a!defaultValue(cons!SD_ESCALATION_TEST_MINUTES, 0)),
  local!level: tointeger(a!defaultValue(ri!level, 1)),
  if(
    local!test > 0,
    local!test,
    if(
      local!level = 2,
      tointeger(max(1, cons!SD_SMS_AGE_DAYS - cons!SD_CHASE_AGE_DAYS)) * 1440,
      tointeger(max(1, cons!SD_CHASE_AGE_DAYS)) * 1440
    )
  )
)
'''

REMINDER = r'''/* Draw approval (Phase 6c): the escalation reminder for a step that has waited. It is the step email itself
   (rule!SD_buildApprovalEmail, the draw as it stands now) under an amber banner saying how long the step has waited and
   when the draw funds. Subject "Reminder · Draw #<n> · funding in <d> days · awaiting your approval", ending with the
   reply token [SD-DRAW-<id>-S<step>] so a reply is read like any other. Sent, like the step email, to the step's group,
   from and reply-to the receiver address. Returns a map: subject, html, text (the line logged on the draw), bytes,
   daysWaiting, daysToFunding. */
a!localVariables(
  local!base: rule!SD_buildApprovalEmail(drawId: ri!drawId, stepOrder: ri!stepOrder),
  local!d: rule!SD_getDrawDetail(drawId: ri!drawId),
  local!drawNo: a!defaultValue(index(local!d, "drawNumber", null), ri!drawId),
  local!waiting: a!defaultValue(index(local!d, "daysAtStep", 0), 0),
  local!toFunding: index(local!d, "daysToFunding", null),
  local!fundingText: if(a!isNullOrEmpty(local!toFunding), "funding date not set", "funding " & rule!SD_fmtRelativeDays(days: local!toFunding)),
  local!overLimit: todecimal(a!defaultValue(index(local!d, "amount", 0), 0)) > todecimal(cons!SD_EMAIL_APPROVAL_MAX),
  local!subject: "Reminder · Draw #" & local!drawNo & " · " & local!fundingText & " · awaiting your approval [SD-DRAW-" & ri!drawId & "-S" & ri!stepOrder & "]",
  local!lead: "Reminder: this approval " & if(local!waiting < 1, "is still waiting", "has waited " & local!waiting & if(local!waiting = 1, " day", " days")) & " and the draw is " & local!fundingText & ". " &
    if(local!overLimit, "The approval request is repeated below; please record your decision in the system.", "The approval request is repeated below; reply to this email with your decision."),
  local!banner: "<tr><td style=""background:#FDF3E0;color:#92600A;padding:10px 18px;font-size:13px;line-height:18px;font-weight:bold;border-bottom:1px solid #F3D9A4;font-family:Arial,Helvetica,sans-serif;"">" & rule!SD_htmlEscape(text: local!lead) & "</td></tr>",
  local!anchor: "<tr><td style=""background:#16294D;color:#FFFFFF;padding:14px 18px 6px 18px;",
  local!html: substitute(tostring(index(local!base, "html", "")), local!anchor, local!banner & local!anchor),
  a!map(
    subject: local!subject,
    html: local!html,
    text: local!lead,
    bytes: len(local!html),
    daysWaiting: local!waiting,
    daysToFunding: local!toFunding
  )
)
'''

SMS = r'''/* Draw approval (Phase 6c): the SMS rung's text for a step that has waited SD_SMS_AGE_DAYS. One short line, no link:
   "Draw #<n> · $<amount> · funding in <d> days · awaiting your approval · reply by email" (on a draw above the email
   limit the close is "decide in Starwood Draw Approvals"). Returns a map: text, length. */
a!localVariables(
  local!d: rule!SD_getDrawDetail(drawId: ri!drawId),
  local!drawNo: a!defaultValue(index(local!d, "drawNumber", null), ri!drawId),
  local!toFunding: index(local!d, "daysToFunding", null),
  local!overLimit: todecimal(a!defaultValue(index(local!d, "amount", 0), 0)) > todecimal(cons!SD_EMAIL_APPROVAL_MAX),
  local!text: "Draw #" & local!drawNo & " · " & rule!SD_fmtMoney(value: index(local!d, "amount", 0), showCents: false) & " · " &
    if(a!isNullOrEmpty(local!toFunding), "funding date not set", "funding " & rule!SD_fmtRelativeDays(days: local!toFunding)) &
    " · awaiting your approval · " & if(local!overLimit, "decide in Starwood Draw Approvals", "reply by email"),
  a!map(text: local!text, length: len(local!text))
)
'''

MASK = r'''/* Draw approval (Phase 6c): a phone number as it is shown and logged — only its last four digits ("+1 ••• ••• 1234").
   The full number lives in the SMS recipient constant alone; the draw's exchange log never carries it. */
a!localVariables(
  local!digits: stripwith(a!defaultValue(ri!number, ""), " +-().abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"),
  if(len(local!digits) < 4, "(no number)", "+" & if(len(local!digits) > 10, left(local!digits, len(local!digits) - 10), "1") & " ••• ••• " & right(local!digits, 4))
)
'''

CHASE = r'''/* Draw approval (Phase 6c): the "Needs chasing" rows — the one query behind the Draws page's Needs chasing view and the
   daily chase digest. A draw is listed when its current approval step has waited SD_CHASE_AGE_DAYS or more (days since
   the step was activated, from today), or when an email reply on it is waiting for the draw approval team's review
   (an open exception with its review task still open; fix 2026-09-28). Ranked by amount, largest first, then by days to funding, soonest first: the money at stake
   before the calendar. Each row says who is sitting on what: the step's role and named approver, the group the task
   is assigned to, the role's authorized email address (SD_EMAIL_REPLY_ADDRESSES) and when the step was last chased
   (the latest REMINDER or SMS logged at that step). ri!rows takes the Draws page's rows (rule!SD_getDrawListRows) so
   the page does not read twice; empty, the rule reads them itself. */
a!localVariables(
  local!all: if(a!isNullOrEmpty(ri!rows), rule!SD_getDrawListRows(), ri!rows),
  local!threshold: tointeger(cons!SD_CHASE_AGE_DAYS),
  local!flags: if(
    a!isNullOrEmpty(local!all),
    {},
    a!forEach(
      items: local!all,
      expression: or(
        and(a!defaultValue(fv!item.inProgress, false), a!defaultValue(fv!item.daysAtStep, 0) >= local!threshold),
        /* fix 2026-09-28: an email reply counts only while its review task is open (as on the Summary) */
        and(a!defaultValue(fv!item.exceptionOpen, false), not(a!isNullOrEmpty(fv!item.exceptionTaskId)))
      )
    )
  ),
  local!picked: if(a!isNullOrEmpty(local!flags), {}, index(local!all, wherecontains(true, local!flags), {})),
  local!mapped: if(
    a!isNullOrEmpty(local!picked),
    {},
    a!forEach(
      items: local!picked,
      expression: a!localVariables(
        local!inProgress: a!defaultValue(fv!item.inProgress, false),
        local!role: if(local!inProgress, tostring(a!defaultValue(fv!item.currentRole, "")), ""),
        local!roleIdx: if(local!role = "", {}, wherecontains(local!role, cons!SD_EMAIL_REPLY_ROLES)),
        local!group: if(local!role = "", null, rule!SD_getDrawApprovalGroup(role: local!role)),
        local!aging: and(local!inProgress, a!defaultValue(fv!item.daysAtStep, 0) >= local!threshold),
        local!exception: and(a!defaultValue(fv!item.exceptionOpen, false), not(a!isNullOrEmpty(fv!item.exceptionTaskId))),
        local!step: tointeger(a!defaultValue(fv!item.currentStep, 0)),
        local!chases: a!localVariables(
          local!msgs: rule!SD_getDrawEmailMessages(drawId: fv!item.id),
          if(
            a!isNullOrEmpty(local!msgs),
            {},
            index(
              local!msgs,
              wherecontains(
                true,
                a!forEach(items: local!msgs, expression: and(or(fv!item.kind = "REMINDER", fv!item.kind = "SMS"), tointeger(a!defaultValue(fv!item.stepOrder, 0)) = local!step))
              ),
              {}
            )
          )
        ),
        local!lastChase: if(a!isNullOrEmpty(local!chases), null, index(local!chases, count(local!chases), null)),
        a!map(
          drawId: fv!item.id,
          drawNumber: fv!item.drawNumber,
          investmentName: a!defaultValue(fv!item.investmentName, ""),
          amount: todecimal(a!defaultValue(fv!item.amount, 0)),
          fundingDate: fv!item.fundingDate,
          daysToFunding: a!defaultValue(fv!item.daysToFunding, 99999),
          status: tostring(a!defaultValue(fv!item.status, "")),
          currentStep: local!step,
          totalSteps: a!defaultValue(fv!item.totalSteps, 9),
          role: local!role,
          approverName: if(local!inProgress, a!defaultValue(fv!item.currentApprover, ""), ""),
          /* the step group's name from the three step-group constants: group() needs view rights on the group, which
             a persona may not have (measured: "Insufficient permission" rendering the Draws page as sd.accountant) */
          groupName: if(
            a!isNullOrEmpty(local!group),
            "",
            displayvalue(
              tointeger(local!group),
              {tointeger(cons!SD_DRAW_ASSET_MANAGER_GROUP), tointeger(cons!SD_DRAW_CEO_GROUP), tointeger(cons!SD_DRAW_DEMO_APPROVERS_GROUP)},
              {"SD Draw Asset Managers", "SD Draw CEO", "SD Draw Demo Approvers"},
              "the step's group"
            )
          ),
          contact: if(a!isNullOrEmpty(local!roleIdx), "", tostring(index(cons!SD_EMAIL_REPLY_ADDRESSES, local!roleIdx[1], ""))),
          daysAtStep: if(local!inProgress, a!defaultValue(fv!item.daysAtStep, 0), null),
          aging: local!aging,
          smsDue: and(local!aging, a!defaultValue(fv!item.daysAtStep, 0) >= tointeger(cons!SD_SMS_AGE_DAYS)),
          exceptionOpen: local!exception,
          reason: if(
            local!aging,
            "Step " & local!step & " waiting " & fv!item.daysAtStep & " days" & if(local!exception, " · email reply to review", ""),
            "Email reply to review"
          ),
          /* what the last chase did, as a phrase: a staged or failed text never reads as sent */
          lastChaseLabel: if(
            a!isNullOrEmpty(local!lastChase),
            "",
            if(index(local!lastChase, "kind", "") = "SMS", "Text", "Reminder") & " " &
            displayvalue(tostring(index(local!lastChase, "outcome", "")), {"STAGED", "FAILED"}, {"staged, not sent", "failed"}, "sent")
          ),
          lastChaseAt: if(a!isNullOrEmpty(local!lastChase), null, index(local!lastChase, "messageAt", null))
        )
      )
    )
  ),
  if(
    a!isNullOrEmpty(local!mapped),
    {},
    todatasubset(
      local!mapped,
      a!pagingInfo(startIndex: 1, batchSize: -1, sort: {a!sortInfo(field: "amount", ascending: false), a!sortInfo(field: "daysToFunding", ascending: true)})
    ).data
  )
)
'''

DIGEST = r'''/* Draw approval (Phase 6c): the daily chase digest for the draw approval team — one summary email built from
   rule!SD_getChaseRows (the same query as the Draws page's Needs chasing view): every step waiting SD_CHASE_AGE_DAYS or
   more and every email reply waiting for review, ranked by amount then days to funding, each with who holds it, how to
   reach them, when it was last chased, and a link to the draw. The Phase 4 visual language: navy bands, table layout,
   inline styles, no images. Returns a map: subject, html, text, count, bytes. */
a!localVariables(
  local!rows: rule!SD_getChaseRows(rows: ri!rows),
  local!n: count(local!rows),
  local!total: if(local!n = 0, 0, sum(a!forEach(items: local!rows, expression: a!defaultValue(fv!item.amount, 0)))),
  local!subject: if(
    local!n = 0,
    "Draw approvals · nothing needs chasing · " & text(today(), "MMM D"),
    "Draw approvals needing a chase · " & local!n & if(local!n = 1, " draw", " draws") & " · " & rule!SD_fmtMoney(value: local!total, showCents: false) & " · " & text(today(), "MMM D")
  ),
  local!th: "background:#E8EEF7;color:#16294D;padding:6px 8px;border-bottom:1px solid #C9D4EF;font-size:10px;font-weight:bold;text-align:left;",
  local!td: "padding:6px 8px;border-bottom:1px solid #E5E7EB;font-size:11px;vertical-align:top;",
  local!rowsHtml: if(
    local!n = 0,
    "<tr><td colspan=""7"" style=""" & local!td & "color:#6B7280;"">No approval step has waited " & cons!SD_CHASE_AGE_DAYS & " days or more, and no email reply is waiting for review.</td></tr>",
    concat(
      a!forEach(
        items: local!rows,
        expression: a!localVariables(
          /* a!urlForRecord with one identifier returns one string (index(…, 1) would take its first character): tostring it */
          local!url: tostring(a!urlForRecord(recordType: 'recordType!{c9d3a947-71aa-4024-879e-363873a12860}SD Draw', targetLocation: @SITE_DRAWS@, identifier: fv!item.drawId)),
          local!hot: a!defaultValue(fv!item.smsDue, false),
          "<tr>" &
          "<td style=""" & local!td & "text-align:center;font-weight:bold;color:#16294D;"">" & fv!index & "</td>" &
          "<td style=""" & local!td & """><a href=""" & local!url & """ style=""color:#1D5BBF;font-weight:bold;text-decoration:none;"">Draw #" & a!defaultValue(fv!item.drawNumber, fv!item.drawId) & "</a><br><span style=""color:#6B7280;"">" & rule!SD_htmlEscape(text: fv!item.investmentName) & "</span></td>" &
          "<td style=""" & local!td & "text-align:right;font-weight:bold;"">" & rule!SD_fmtMoney(value: fv!item.amount, showCents: false) & "</td>" &
          "<td style=""" & local!td & """>" & if(a!isNullOrEmpty(fv!item.fundingDate), "—", text(todate(fv!item.fundingDate), "MMM D") & "<br><span style=""color:#6B7280;"">" & rule!SD_fmtRelativeDays(days: fv!item.daysToFunding) & "</span>") & "</td>" &
          "<td style=""" & local!td & """>" & if(fv!item.role = "", "The draw approval team", rule!SD_htmlEscape(text: fv!item.approverName) & "<br><span style=""color:#6B7280;"">" & rule!SD_htmlEscape(text: fv!item.role) & " · step " & fv!item.currentStep & " of " & fv!item.totalSteps & "</span>") & "</td>" &
          "<td style=""" & local!td & if(local!hot, "color:#92600A;font-weight:bold;", "") & """>" & rule!SD_htmlEscape(text: fv!item.reason) & if(fv!item.lastChaseLabel = "", "", "<br><span style=""color:#6B7280;font-weight:normal;"">" & fv!item.lastChaseLabel & " " & text(fv!item.lastChaseAt, "MMM D") & "</span>") & "</td>" &
          "<td style=""" & local!td & """>" & if(fv!item.contact = "", "—", "<a href=""mailto:" & fv!item.contact & """ style=""color:#1D5BBF;text-decoration:none;"">" & rule!SD_htmlEscape(text: fv!item.contact) & "</a>") & if(fv!item.groupName = "", "", "<br><span style=""color:#6B7280;"">task: " & rule!SD_htmlEscape(text: fv!item.groupName) & "</span>") & "</td>" &
          "</tr>"
        )
      )
    )
  ),
  local!html: concat(
    "<div style=""margin:0;padding:0;background:#F5F6F8;"">",
    "<table role=""presentation"" width=""100%"" cellpadding=""0"" cellspacing=""0"" border=""0"" style=""background:#F5F6F8;""><tr><td align=""center"" style=""padding:12px;"">",
    "<table role=""presentation"" width=""100%"" cellpadding=""0"" cellspacing=""0"" border=""0"" style=""max-width:1040px;background:#FFFFFF;border:1px solid #D9DEE7;font-family:Arial,Helvetica,sans-serif;color:#1F2937;"">",
    "<tr><td style=""background:#16294D;color:#FFFFFF;padding:14px 18px 6px 18px;font-size:16px;font-weight:bold;"">DRAW APPROVALS &nbsp;|&nbsp; NEEDS CHASING</td></tr>",
    "<tr><td style=""background:#16294D;color:#C7D2E5;padding:0 18px 12px 18px;font-size:11px;"">" & text(today(), "dddd, MMMM D, YYYY") & " &nbsp;&middot;&nbsp; " & local!n & if(local!n = 1, " draw", " draws") & " &nbsp;&middot;&nbsp; " & rule!SD_fmtMoney(value: local!total, showCents: false) & " waiting</td></tr>",
    "<tr><td style=""padding:14px 18px 10px 18px;font-size:13px;line-height:18px;"">These approval steps have waited " & cons!SD_CHASE_AGE_DAYS & " days or more, or have an email reply waiting for the team's review. They are ranked by amount, then by days to funding. Steps waiting " & cons!SD_SMS_AGE_DAYS & " days or more are in amber: that is when the escalation texts the approver.</td></tr>",
    "<tr><td style=""padding:0 12px;""><table role=""presentation"" width=""100%"" cellpadding=""0"" cellspacing=""0"" border=""0"" style=""border-collapse:collapse;font-family:Arial,Helvetica,sans-serif;color:#1F2937;"">",
    "<tr><td colspan=""7"" style=""background:#16294D;color:#FFFFFF;padding:6px 12px;font-size:11px;font-weight:bold;letter-spacing:0.5px;"">WAITING, RANKED</td></tr>",
    "<tr><th style=""" & local!th & "text-align:center;"">#</th><th style=""" & local!th & """>Draw</th><th style=""" & local!th & "text-align:right;"">Amount</th><th style=""" & local!th & """>Funding</th><th style=""" & local!th & """>Waiting on</th><th style=""" & local!th & """>Why</th><th style=""" & local!th & """>Contact</th></tr>",
    local!rowsHtml,
    "</table></td></tr>",
    "<tr><td style=""height:12px;font-size:1px;line-height:12px;"">&nbsp;</td></tr>",
    "<tr><td style=""background:#16294D;color:#FFFFFF;padding:10px 18px;font-size:12px;font-style:italic;"">Sent daily to the draw approval team. The live list is the Draws page's Needs chasing view.</td></tr>",
    "</table></td></tr></table></div>"
  ),
  a!map(
    subject: local!subject,
    html: local!html,
    text: local!subject,
    count: local!n,
    bytes: len(local!html)
  )
)
'''
DIGEST = DIGEST.replace("@SITE_DRAWS@", SITE_DRAWS)

RESOLVE = r'''/* Draw approval (Phase 6c): what an escalation of a step task is about. The step task's escalations send a
   process-to-process message to SD Chase Approval Step with no custom properties, so the only thing the chase process
   receives is msg!properties.OriginProcessID: the SD Draw Approval Step process that escalated. That process registers
   itself on its draw (SD Draw.activeStepProcessId), so the draw is the one whose activeStepProcessId is that id; the step
   is the draw's current step. The rung comes from the log, not from the message: no reminder logged yet for this
   approval row means level 1 (REMINDER), otherwise level 2 (SMS). found is false when no draw holds that process (the
   step was decided and the next step registered, so nothing is chased). */
a!localVariables(
  local!rows: if(
    a!isNullOrEmpty(ri!originProcessId),
    {},
    a!queryRecordType(
      recordType: @DRAW@,
      fields: {@DRAW_ID@},
      filters: a!queryFilter(field: @DRAW_ASP@, operator: "=", value: tointeger(ri!originProcessId)),
      pagingInfo: a!pagingInfo(startIndex: 1, batchSize: 1)
    ).data
  ),
  local!drawId: if(a!isNullOrEmpty(local!rows), null, tointeger(index(index(local!rows, 1, null), @DRAW_ID@, null))),
  local!state: if(a!isNullOrEmpty(local!drawId), null, rule!SD_getDrawState(local!drawId)),
  local!current: if(a!isNullOrEmpty(local!state), null, index(local!state, "current", null)),
  local!approvalId: if(a!isNullOrEmpty(local!current), null, tointeger(index(local!current, "id", null))),
  local!msgs: if(a!isNullOrEmpty(local!drawId), {}, rule!SD_getDrawEmailMessages(drawId: local!drawId)),
  local!reminded: if(
    or(a!isNullOrEmpty(local!msgs), a!isNullOrEmpty(local!approvalId)),
    false,
    contains(
      a!forEach(
        items: local!msgs,
        expression: and(fv!item.kind = "REMINDER", tointeger(a!defaultValue(fv!item.approvalId, 0)) = local!approvalId)
      ),
      true
    )
  ),
  a!map(
    found: not(a!isNullOrEmpty(local!drawId)),
    drawId: local!drawId,
    stepOrder: if(a!isNullOrEmpty(local!state), null, tointeger(index(local!state, "currentStep", null))),
    approvalId: local!approvalId,
    rung: if(local!reminded, "SMS", "REMINDER")
  )
)
'''
RESOLVE = RESOLVE.replace("@DRAW@", rt(DRAW)).replace("@DRAW_ID@", fld(DRAW, "id")).replace("@DRAW_ASP@", fld(DRAW, "activeStepProcessId"))

for name, text in [("SD_getEscalationMinutes", ESC), ("SD_buildStepReminderEmail", REMINDER), ("SD_buildStepSms", SMS),
                   ("SD_maskPhone", MASK), ("SD_getChaseRows", CHASE), ("SD_buildChaseDigestEmail", DIGEST),
                   ("SD_resolveChaseTarget", RESOLVE)]:
    assert "@" not in text.replace("@appian", ""), name
    open(name + ".sail", "w").write(text)
    print("wrote", name, len(text))

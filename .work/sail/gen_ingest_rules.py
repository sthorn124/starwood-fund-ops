"""Generates the Phase 3 assembly rules: SD_buildIngestedBudgetLines, SD_buildIngestedApprovalChain, SD_buildIngestedQiu."""
from refs import *
L = lambda n: fld(LINE, n)
A = lambda n: fld(APPR, n)
Q = lambda n: fld(QIU, n)
D = lambda n: fld(DRAW, n)

lines = f"""/* Draw approval (Phase 3): the SD Draw Budget Line rows for an ingested draw, from the accountant-confirmed lines JSON
   (rule!SD_form_reconcileExtraction's confirmedLinesJson: lineOrder, budgetCategory, nine amounts as fixed(…, 4) text).
   categoryGroup follows the Budget Summary roll-up (Hard: Hard Costs, FF&E; Land: Land, Acquisition Costs; else Soft);
   inThisDraw is true when the line draws or adjusts this period, which is what separates the email's "In this Draw"
   rows from "All Other Budget Categories". Returns {{}} when there are no lines. */
a!localVariables(
  local!rows: if(a!isNullOrEmpty(ri!linesJson), {{}}, a!fromJson(ri!linesJson)),
  if(
    a!isNullOrEmpty(local!rows),
    {{}},
    a!forEach(
      items: local!rows,
      expression: a!localVariables(
        local!cat: trim(tostring(a!defaultValue(fv!item.budgetCategory, ""))),
        local!catKey: lower(local!cat),
        local!group: if(
          or(local!catKey = "hard costs", local!catKey = "ff&e"),
          "Hard",
          if(or(local!catKey = "land", local!catKey = "acquisition costs"), "Land", "Soft")
        ),
        local!current: todecimal(a!defaultValue(fv!item.currentDraw, "0")),
        local!adj: todecimal(a!defaultValue(fv!item.proposedAdjustmentsThisDraw, "0")),
        {rt(LINE)}(
          {L('drawId')}: ri!drawId,
          {L('lineOrder')}: tointeger(a!defaultValue(fv!item.lineOrder, fv!index)),
          {L('budgetCategory')}: local!cat,
          {L('categoryGroup')}: local!group,
          {L('inThisDraw')}: or(local!current <> 0, local!adj <> 0),
          {L('initialBudget')}: todecimal(a!defaultValue(fv!item.initialBudget, "0")),
          {L('revisedApprovedBudget')}: todecimal(a!defaultValue(fv!item.revisedApprovedBudget, "0")),
          {L('proposedAdjustmentsThisDraw')}: local!adj,
          {L('proposedBudget')}: todecimal(a!defaultValue(fv!item.proposedBudget, "0")),
          {L('currentDraw')}: local!current,
          {L('totalPtdIncThisDrawAmount')}: todecimal(a!defaultValue(fv!item.totalPtdIncThisDrawAmount, "0")),
          {L('totalPtdIncThisDrawPct')}: todecimal(a!defaultValue(fv!item.totalPtdIncThisDrawPct, "0")),
          {L('balanceToComplete')}: todecimal(a!defaultValue(fv!item.balanceToComplete, "0"))
        )
      )
    )
  )
)
"""

prior = f"""  local!priorDraws: if(
    a!isNullOrEmpty(ri!investmentId),
    {{}},
    a!queryRecordType(
      recordType: {rt(DRAW)},
      fields: {{ {D('id')}, {D('fundingDate')} }},
      filters: a!queryLogicalExpression(
        operator: "AND",
        filters: {{
          a!queryFilter(field: {D('investmentId')}, operator: "=", value: ri!investmentId),
          a!queryFilter(field: {D('id')}, operator: "<>", value: ri!drawId)
        }}
      ),
      pagingInfo: a!pagingInfo(
        startIndex: 1,
        batchSize: 10,
        sort: {{
          a!sortInfo(field: {D('fundingDate')}, ascending: false),
          a!sortInfo(field: {D('id')}, ascending: false)
        }}
      )
    ).data
  ),
  local!priorIds: a!forEach(items: local!priorDraws, expression: fv!item[{D('id')}]),"""

chain = f"""/* Draw approval: the nine SD Draw Approval rows for an ingested draw, built when the accountant confirms the
   reconciliation. Second fix session 2026-09-28 (ruled): roles come from cons!SD_DRAW_CHAIN_ROLES in its order
   (1 Accountant, 2 Asset Manager, 3 Accounting Controller, 4 AM SVP, 5 Executive, 6 Chief Accounting Officer, 7 CFO of
   Funds, 8 President, 9 CEO), never from a prior draw's order. Named approvers still come from the investment's most
   recent prior draw that carries a chain (by funding date, then id), matched by ROLE; a role not on it has no name.
   Order 1 is the accountant's confirmation: Approved at ri!confirmedAt, acted by ri!confirmedBy, source RECONCILIATION,
   activated when the draw was received; its named approver is the prior chain's Accountant, else the confirming user's
   display name. Order 2 (Asset Manager) is In Progress, activated at ri!confirmedAt, so SD Draw Approval Process issues
   the Asset Manager's task at once; orders 3-9 are Pending. Existing draws are never rebuilt: this runs only when a new
   draw is assembled, and every other part of the flow reads whatever the draw's rows say. */
a!localVariables(
{prior}
  local!sourceRows: if(
    a!isNullOrEmpty(local!priorIds),
    {{}},
    a!queryRecordType(
      recordType: {rt(APPR)},
      fields: {{ {A('drawId')}, {A('approvalOrder')}, {A('role')}, {A('approverName')} }},
      filters: a!queryFilter(field: {A('drawId')}, operator: "in", value: local!priorIds),
      pagingInfo: a!pagingInfo(startIndex: 1, batchSize: 200, sort: a!sortInfo(field: {A('approvalOrder')}, ascending: true))
    ).data
  ),
  /* the first prior draw (most recent) that actually carries a chain */
  local!sourceDrawId: a!localVariables(
    local!withRows: if(
      a!isNullOrEmpty(local!sourceRows),
      {{}},
      a!forEach(items: local!priorIds, expression: if(contains(a!forEach(items: local!sourceRows, expression: tointeger(fv!item[{A('drawId')}])), tointeger(fv!item)), fv!item, 0))
    ),
    local!kept: if(a!isNullOrEmpty(local!withRows), {{}}, index(local!withRows, wherecontains(false, a!forEach(items: local!withRows, expression: fv!item = 0)), {{}})),
    if(a!isNullOrEmpty(local!kept), null, local!kept[1])
  ),
  local!template: if(
    a!isNullOrEmpty(local!sourceDrawId),
    {{}},
    index(local!sourceRows, wherecontains(tointeger(local!sourceDrawId), a!forEach(items: local!sourceRows, expression: tointeger(fv!item[{A('drawId')}]))), {{}})
  ),
  local!roles: cons!SD_DRAW_CHAIN_ROLES,
  local!templateRoles: if(a!isNullOrEmpty(local!template), {{}}, a!forEach(items: local!template, expression: tostring(fv!item[{A('role')}]))),
  /* the prior chain's named approver for each canonical role, "" when the role is not on it */
  local!names: a!forEach(
    items: local!roles,
    expression: a!localVariables(
      local!hit: if(a!isNullOrEmpty(local!templateRoles), {{}}, wherecontains(tostring(fv!item), local!templateRoles)),
      if(a!isNullOrEmpty(local!hit), "", tostring(a!defaultValue(index(local!template, local!hit[1], null)[{A('approverName')}], "")))
    )
  ),
  local!confirmedAt: a!defaultValue(ri!confirmedAt, now()),
  local!confirmer: if(or(a!isNullOrEmpty(ri!confirmedBy), ri!confirmedBy = "-"), "", tostring(ri!confirmedBy)),
  local!confirmerName: if(local!confirmer = "", "", tostring(a!defaultValue(rule!SD_getUserDisplayName(username: local!confirmer), local!confirmer))),
  local!receivedAt: a!localVariables(
    local!r: if(
      a!isNullOrEmpty(ri!drawId),
      {{}},
      a!queryRecordType(
        recordType: {rt(DRAW)},
        fields: {{ {D('createdAt')} }},
        filters: a!queryFilter(field: {D('id')}, operator: "=", value: ri!drawId),
        pagingInfo: a!pagingInfo(startIndex: 1, batchSize: 1)
      ).data
    ),
    local!row: index(local!r, 1, null),
    if(a!isNullOrEmpty(local!row), null, local!row[{D('createdAt')}])
  ),
  a!forEach(
    items: enumerate(count(local!roles)) + 1,
    expression: a!localVariables(
      local!order: fv!item,
      local!first: local!order = 1,
      local!named: tostring(index(local!names, local!order, "")),
      {rt(APPR)}(
        {A('drawId')}: ri!drawId,
        {A('approvalOrder')}: local!order,
        {A('role')}: tostring(local!roles[local!order]),
        {A('approverName')}: if(local!named <> "", local!named, if(and(local!first, local!confirmerName <> ""), local!confirmerName, null)),
        {A('status')}: if(local!first, "Approved", if(local!order = 2, "In Progress", "Pending")),
        {A('activatedAt')}: if(local!first, a!defaultValue(local!receivedAt, local!confirmedAt), if(local!order = 2, local!confirmedAt, null)),
        {A('decisionDate')}: if(local!first, local!confirmedAt, null),
        {A('actedBy')}: if(and(local!first, local!confirmer <> ""), local!confirmer, null),
        {A('decisionSource')}: if(local!first, "RECONCILIATION", null),
        {A('comments')}: if(local!first, "Confirmed the Doc Center extraction at reconciliation; the draw was assembled and sent to the Asset Manager.", null)
      )
    )
  )
)
"""

qiu = f"""/* Draw approval (Phase 3): the SD QIU Metric rows for an ingested draw — the ten metrics copied from the investment's
   most recent prior draw that carries a QIU set, re-dated to ri!asOfDate (narrated as the QIU model feed). Values are
   display text, exactly as the approval email shows them. Returns {{}} when the investment has no prior QIU set. */
a!localVariables(
{prior}
  local!sourceRows: if(
    a!isNullOrEmpty(local!priorIds),
    {{}},
    a!queryRecordType(
      recordType: {rt(QIU)},
      fields: {{ {Q('drawId')}, {Q('metricOrder')}, {Q('metric')}, {Q('currentModelValue')}, {Q('currentProjection')}, {Q('variance')} }},
      filters: a!queryFilter(field: {Q('drawId')}, operator: "in", value: local!priorIds),
      pagingInfo: a!pagingInfo(startIndex: 1, batchSize: 200, sort: a!sortInfo(field: {Q('metricOrder')}, ascending: true))
    ).data
  ),
  local!sourceDrawId: a!localVariables(
    local!withRows: if(
      a!isNullOrEmpty(local!sourceRows),
      {{}},
      a!forEach(items: local!priorIds, expression: if(contains(a!forEach(items: local!sourceRows, expression: tointeger(fv!item[{Q('drawId')}])), tointeger(fv!item)), fv!item, 0))
    ),
    local!kept: if(a!isNullOrEmpty(local!withRows), {{}}, index(local!withRows, wherecontains(false, a!forEach(items: local!withRows, expression: fv!item = 0)), {{}})),
    if(a!isNullOrEmpty(local!kept), null, local!kept[1])
  ),
  local!template: if(
    a!isNullOrEmpty(local!sourceDrawId),
    {{}},
    index(local!sourceRows, wherecontains(tointeger(local!sourceDrawId), a!forEach(items: local!sourceRows, expression: tointeger(fv!item[{Q('drawId')}]))), {{}})
  ),
  if(
    a!isNullOrEmpty(local!template),
    {{}},
    a!forEach(
      items: local!template,
      expression: {rt(QIU)}(
        {Q('drawId')}: ri!drawId,
        {Q('metricOrder')}: fv!item[{Q('metricOrder')}],
        {Q('metric')}: fv!item[{Q('metric')}],
        {Q('modelAsOfDate')}: ri!asOfDate,
        {Q('currentModelValue')}: fv!item[{Q('currentModelValue')}],
        {Q('currentProjection')}: fv!item[{Q('currentProjection')}],
        {Q('variance')}: fv!item[{Q('variance')}],
        {Q('notes')}: ""
      )
    )
  )
)
"""
open("SD_buildIngestedBudgetLines.sail","w").write(lines)
open("SD_buildIngestedApprovalChain.sail","w").write(chain)
open("SD_buildIngestedQiu.sail","w").write(qiu)
print("written")

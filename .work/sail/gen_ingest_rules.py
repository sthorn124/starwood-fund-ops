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

chain = f"""/* Draw approval (Phase 3): the nine SD Draw Approval rows for an ingested draw. Roles and named approvers are copied
   from the investment's most recent prior draw (by funding date, then id) — the chain of record for that property —
   and fall back to the canon roles with no named approver when the investment has no prior chain. Order 1 starts
   In Progress (activated now) so SD Draw Approval Process can issue the Accountant task; orders 2–9 are Pending. */
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
  local!canonRoles: {{"Accountant", "Accounting Controller", "Asset Manager", "AM SVP", "Executive", "Chief Accounting Officer", "CFO of Funds", "President", "CEO"}},
  a!forEach(
    items: enumerate(9) + 1,
    expression: a!localVariables(
      local!order: fv!item,
      local!idx: if(a!isNullOrEmpty(local!template), {{}}, wherecontains(local!order, a!forEach(items: local!template, expression: tointeger(fv!item[{A('approvalOrder')}])))),
      local!src: if(a!isNullOrEmpty(local!idx), null, index(local!template, local!idx[1], null)),
      {rt(APPR)}(
        {A('drawId')}: ri!drawId,
        {A('approvalOrder')}: local!order,
        {A('role')}: if(a!isNullOrEmpty(local!src), local!canonRoles[local!order], local!src[{A('role')}]),
        {A('approverName')}: if(a!isNullOrEmpty(local!src), null, local!src[{A('approverName')}]),
        {A('status')}: if(local!order = 1, "In Progress", "Pending"),
        {A('activatedAt')}: if(local!order = 1, now(), null)
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

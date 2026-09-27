/* Draw approval (fix session 2026-09-27): the draws Stage for Approval can take, most recent first (the picker's default
   is the first). ri!rows takes the Draws page's rows (rule!SD_getDrawListRows) so the page does not read twice; empty,
   the rule reads them itself. Each item: drawId, drawNumber, currentStep, currentRole, currentApprover, investmentName,
   label ("#81 · step 1 of 9 · Accountant · received Sep 26"). */
a!localVariables(
  local!all: if(a!isNullOrEmpty(ri!rows), rule!SD_getDrawListRows(), ri!rows),
  local!flags: if(
    a!isNullOrEmpty(local!all),
    {},
    a!forEach(items: local!all, expression: rule!SD_isStageForApprovalEligible(detail: fv!item))
  ),
  local!picked: if(
    or(a!isNullOrEmpty(local!flags), not(contains(local!flags, true))),
    {},
    index(local!all, wherecontains(true, local!flags), {})
  ),
  local!mapped: if(
    a!isNullOrEmpty(local!picked),
    {},
    a!forEach(
      items: local!picked,
      expression: a!map(
        drawId: tointeger(fv!item.id),
        drawNumber: fv!item.drawNumber,
        currentStep: tointeger(fv!item.currentStep),
        currentRole: tostring(a!defaultValue(fv!item.currentRole, "")),
        currentApprover: tostring(a!defaultValue(fv!item.currentApprover, "")),
        investmentName: tostring(a!defaultValue(fv!item.investmentName, "")),
        label: "#" & a!defaultValue(fv!item.drawNumber, fv!item.id) & " · step " & fv!item.currentStep & " of 9 · " &
          a!defaultValue(fv!item.currentRole, "") &
          if(a!isNullOrEmpty(fv!item.receivedDate), "", " · received " & text(todate(fv!item.receivedDate), "MMM D"))
      )
    )
  ),
  if(
    a!isNullOrEmpty(local!mapped),
    {},
    todatasubset(local!mapped, a!pagingInfo(startIndex: 1, batchSize: -1, sort: a!sortInfo(field: "drawId", ascending: false))).data
  )
)

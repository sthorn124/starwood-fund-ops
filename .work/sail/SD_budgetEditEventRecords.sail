/* Draw approval (Phase 6c): one "Edited at Approval" event per line of an Asset Manager's edit plan, written straight into
   SD Draw Budget Line Event History (a plain Write Records node, CaptureEvents off: the supplemental's working form for a
   worded event). User = the Asset Manager who submitted the task; automation NONE (1: done by a person); the comment is
   the attribution sentence the plan composed, cut to 250 characters for the VARCHAR(255) column. */
if(
  a!isNullOrEmpty(index(ri!plan, "lines", {})),
  {},
  a!forEach(
    items: index(ri!plan, "lines", {}),
    expression: 'recordType!{ee493a87-e51b-4148-8893-26de1e924ffb}SD Draw Budget Line Event History'(
      'recordType!{ee493a87-e51b-4148-8893-26de1e924ffb}SD Draw Budget Line Event History.fields.{7e9a52d1-8566-4199-b6b9-167488e2383e}recordId': tointeger(fv!item.id),
      'recordType!{ee493a87-e51b-4148-8893-26de1e924ffb}SD Draw Budget Line Event History.fields.{ea2dea0a-3312-4fbb-bcb2-b7ab0e2994c8}eventTypeId': cons!SD_BUDGET_EDIT_EVENT_TYPE_ID,
      'recordType!{ee493a87-e51b-4148-8893-26de1e924ffb}SD Draw Budget Line Event History.fields.{61330b88-d4ce-46ea-9fe7-6a6b41eceed6}user': touser(ri!actor),
      'recordType!{ee493a87-e51b-4148-8893-26de1e924ffb}SD Draw Budget Line Event History.fields.{f4ee5141-fec8-4e43-bdc5-1517fd82e679}timestamp': now(),
      'recordType!{ee493a87-e51b-4148-8893-26de1e924ffb}SD Draw Budget Line Event History.fields.{41f484ce-15f9-4537-9965-ad31088a0d0e}automationTypeId': 1,
      'recordType!{ee493a87-e51b-4148-8893-26de1e924ffb}SD Draw Budget Line Event History.fields.{b34057f7-f0af-4b64-a149-67e0a0992ee0}comment': left(tostring(fv!item.comment), 250)
    )
  )
)

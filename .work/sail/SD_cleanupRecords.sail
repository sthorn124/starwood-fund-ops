/* Draw approval (fix session 2026-09-27): the record values a Delete Records node takes for one type, identified by
   primary key only. ri!kind: EVENT, MESSAGE, DOCUMENT, QIU, APPROVAL, LINE or DRAW; ri!ids: the explicit id list from
   SD_planCleanup. An unknown kind or an empty list returns an empty list. */
if(
  a!isNullOrEmpty(ri!ids),
  {},
  a!forEach(
    items: tointeger(ri!ids),
    expression: a!match(
      value: upper(a!defaultValue(ri!kind, "")),
      equals: "EVENT", then: 'recordType!{ee493a87-e51b-4148-8893-26de1e924ffb}SD Draw Budget Line Event History'('recordType!{ee493a87-e51b-4148-8893-26de1e924ffb}SD Draw Budget Line Event History.fields.{cbefa248-a552-4bbb-9733-d4dd1d291a99}id': fv!item),
      equals: "MESSAGE", then: 'recordType!{3686a81f-86e2-498e-a4d1-ce40236c824a}SD Draw Email Message'('recordType!{3686a81f-86e2-498e-a4d1-ce40236c824a}SD Draw Email Message.fields.{7d692543-d14a-44a7-b2eb-2aba819cea1f}id': fv!item),
      equals: "DOCUMENT", then: 'recordType!{f3e0033f-2047-4c68-8f6f-cf32166091e9}SD Draw Document'('recordType!{f3e0033f-2047-4c68-8f6f-cf32166091e9}SD Draw Document.fields.{a0e2e466-e3fb-4f48-9744-481735a1ba8f}id': fv!item),
      equals: "QIU", then: 'recordType!{a0920e4c-0c76-4494-a61a-6e38d5db390a}SD QIU Metric'('recordType!{a0920e4c-0c76-4494-a61a-6e38d5db390a}SD QIU Metric.fields.{f3d5f8f7-3ecf-4749-b749-78f2836cd65d}id': fv!item),
      equals: "APPROVAL", then: 'recordType!{02c207d5-c725-4d11-bf40-b33573e87ffa}SD Draw Approval'('recordType!{02c207d5-c725-4d11-bf40-b33573e87ffa}SD Draw Approval.fields.{69abcdf2-55da-48dc-8cc4-794b5d5e0042}id': fv!item),
      equals: "LINE", then: 'recordType!{ddc4073e-6372-49e2-80de-a088b424abcd}SD Draw Budget Line'('recordType!{ddc4073e-6372-49e2-80de-a088b424abcd}SD Draw Budget Line.fields.{14803371-b715-43a4-bc3a-94e314f16f8a}id': fv!item),
      equals: "DRAW", then: 'recordType!{c9d3a947-71aa-4024-879e-363873a12860}SD Draw'('recordType!{c9d3a947-71aa-4024-879e-363873a12860}SD Draw.fields.{443829ca-5971-4d31-8fac-ab7a317e509b}id': fv!item),
      default: null
    )
  )
)

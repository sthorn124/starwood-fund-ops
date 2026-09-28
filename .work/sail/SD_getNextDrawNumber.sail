/* Draw approval (fix session 2026-09-28): the system-assigned draw number — the next number in the investment's
   sequence, like any case number: the highest draw number on file for the investment plus one (1 when it has none).
   Ruled 2026-09-28: the template's draw number is document content only, never extracted, validated or shown as a
   control. excludeDrawId leaves the draw being assigned out of its own sequence. A draw with no matched investment
   takes the sequence of the draws that have none. MAX aggregate, so the answer does not depend on a batch size.
   Called by the reconciliation form (shown read-only) and by SD Receive Capital Call node 16, which assigns it at
   commit time, so the stored number is authoritative. */
a!localVariables(
  local!rows: a!queryRecordType(
    recordType: 'recordType!{c9d3a947-71aa-4024-879e-363873a12860}SD Draw',
    fields: a!aggregationFields(
      measures: a!measure(
        field: 'recordType!{c9d3a947-71aa-4024-879e-363873a12860}SD Draw.fields.{9aa1030b-f76b-49aa-bef6-99eb90327804}drawNumber',
        function: "MAX",
        alias: "maxNumber"
      )
    ),
    filters: a!queryLogicalExpression(
      operator: "AND",
      filters: {
        a!queryFilter(
          field: 'recordType!{c9d3a947-71aa-4024-879e-363873a12860}SD Draw.fields.{09edf0b2-28a3-4a7f-b9dc-ae2afefa24d0}investmentId',
          operator: "=",
          value: ri!investmentId,
          applyWhen: not(a!isNullOrEmpty(ri!investmentId))
        ),
        a!queryFilter(
          field: 'recordType!{c9d3a947-71aa-4024-879e-363873a12860}SD Draw.fields.{09edf0b2-28a3-4a7f-b9dc-ae2afefa24d0}investmentId',
          operator: "is null",
          applyWhen: a!isNullOrEmpty(ri!investmentId)
        ),
        a!queryFilter(
          field: 'recordType!{c9d3a947-71aa-4024-879e-363873a12860}SD Draw.fields.{443829ca-5971-4d31-8fac-ab7a317e509b}id',
          operator: "<>",
          value: ri!excludeDrawId,
          applyWhen: not(a!isNullOrEmpty(ri!excludeDrawId))
        )
      }
    ),
    pagingInfo: a!pagingInfo(startIndex: 1, batchSize: 1)
  ).data,
  local!max: index(index(local!rows, 1, null), "maxNumber", null),
  if(a!isNullOrEmpty(local!max), 0, tointeger(local!max)) + 1
)

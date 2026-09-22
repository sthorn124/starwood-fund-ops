/* Draw approval (Phase 3): the SD QIU Metric rows for an ingested draw — the ten metrics copied from the investment's
   most recent prior draw that carries a QIU set, re-dated to ri!asOfDate (narrated as the QIU model feed). Values are
   display text, exactly as the approval email shows them. Returns {} when the investment has no prior QIU set. */
a!localVariables(
  local!priorDraws: if(
    a!isNullOrEmpty(ri!investmentId),
    {},
    a!queryRecordType(
      recordType: 'recordType!{c9d3a947-71aa-4024-879e-363873a12860}SD Draw',
      fields: { 'recordType!{c9d3a947-71aa-4024-879e-363873a12860}SD Draw.fields.{443829ca-5971-4d31-8fac-ab7a317e509b}id', 'recordType!{c9d3a947-71aa-4024-879e-363873a12860}SD Draw.fields.{d3bf793a-2b28-4d8c-81d4-8b05cb63f5a6}fundingDate' },
      filters: a!queryLogicalExpression(
        operator: "AND",
        filters: {
          a!queryFilter(field: 'recordType!{c9d3a947-71aa-4024-879e-363873a12860}SD Draw.fields.{09edf0b2-28a3-4a7f-b9dc-ae2afefa24d0}investmentId', operator: "=", value: ri!investmentId),
          a!queryFilter(field: 'recordType!{c9d3a947-71aa-4024-879e-363873a12860}SD Draw.fields.{443829ca-5971-4d31-8fac-ab7a317e509b}id', operator: "<>", value: ri!drawId)
        }
      ),
      pagingInfo: a!pagingInfo(
        startIndex: 1,
        batchSize: 10,
        sort: {
          a!sortInfo(field: 'recordType!{c9d3a947-71aa-4024-879e-363873a12860}SD Draw.fields.{d3bf793a-2b28-4d8c-81d4-8b05cb63f5a6}fundingDate', ascending: false),
          a!sortInfo(field: 'recordType!{c9d3a947-71aa-4024-879e-363873a12860}SD Draw.fields.{443829ca-5971-4d31-8fac-ab7a317e509b}id', ascending: false)
        }
      )
    ).data
  ),
  local!priorIds: a!forEach(items: local!priorDraws, expression: fv!item['recordType!{c9d3a947-71aa-4024-879e-363873a12860}SD Draw.fields.{443829ca-5971-4d31-8fac-ab7a317e509b}id']),
  local!sourceRows: if(
    a!isNullOrEmpty(local!priorIds),
    {},
    a!queryRecordType(
      recordType: 'recordType!{a0920e4c-0c76-4494-a61a-6e38d5db390a}SD QIU Metric',
      fields: { 'recordType!{a0920e4c-0c76-4494-a61a-6e38d5db390a}SD QIU Metric.fields.{5fbabfd8-3d5f-4593-a48b-191b529eb267}drawId', 'recordType!{a0920e4c-0c76-4494-a61a-6e38d5db390a}SD QIU Metric.fields.{ecef76a6-01a5-4d0d-8941-a02394945e7e}metricOrder', 'recordType!{a0920e4c-0c76-4494-a61a-6e38d5db390a}SD QIU Metric.fields.{75d24b80-5a71-4593-9726-440e6253e421}metric', 'recordType!{a0920e4c-0c76-4494-a61a-6e38d5db390a}SD QIU Metric.fields.{1db4ed90-8f43-447c-8c7c-aca831ccf178}currentModelValue', 'recordType!{a0920e4c-0c76-4494-a61a-6e38d5db390a}SD QIU Metric.fields.{212e37e2-434d-4337-bb4b-ea129a230f25}currentProjection', 'recordType!{a0920e4c-0c76-4494-a61a-6e38d5db390a}SD QIU Metric.fields.{b135520a-cbed-4cd7-8a3c-0bbaa699b1ba}variance' },
      filters: a!queryFilter(field: 'recordType!{a0920e4c-0c76-4494-a61a-6e38d5db390a}SD QIU Metric.fields.{5fbabfd8-3d5f-4593-a48b-191b529eb267}drawId', operator: "in", value: local!priorIds),
      pagingInfo: a!pagingInfo(startIndex: 1, batchSize: 200, sort: a!sortInfo(field: 'recordType!{a0920e4c-0c76-4494-a61a-6e38d5db390a}SD QIU Metric.fields.{ecef76a6-01a5-4d0d-8941-a02394945e7e}metricOrder', ascending: true))
    ).data
  ),
  local!sourceDrawId: a!localVariables(
    local!withRows: if(
      a!isNullOrEmpty(local!sourceRows),
      {},
      a!forEach(items: local!priorIds, expression: if(contains(a!forEach(items: local!sourceRows, expression: tointeger(fv!item['recordType!{a0920e4c-0c76-4494-a61a-6e38d5db390a}SD QIU Metric.fields.{5fbabfd8-3d5f-4593-a48b-191b529eb267}drawId'])), tointeger(fv!item)), fv!item, 0))
    ),
    local!kept: if(a!isNullOrEmpty(local!withRows), {}, index(local!withRows, wherecontains(false, a!forEach(items: local!withRows, expression: fv!item = 0)), {})),
    if(a!isNullOrEmpty(local!kept), null, local!kept[1])
  ),
  local!template: if(
    a!isNullOrEmpty(local!sourceDrawId),
    {},
    index(local!sourceRows, wherecontains(tointeger(local!sourceDrawId), a!forEach(items: local!sourceRows, expression: tointeger(fv!item['recordType!{a0920e4c-0c76-4494-a61a-6e38d5db390a}SD QIU Metric.fields.{5fbabfd8-3d5f-4593-a48b-191b529eb267}drawId']))), {})
  ),
  if(
    a!isNullOrEmpty(local!template),
    {},
    a!forEach(
      items: local!template,
      expression: 'recordType!{a0920e4c-0c76-4494-a61a-6e38d5db390a}SD QIU Metric'(
        'recordType!{a0920e4c-0c76-4494-a61a-6e38d5db390a}SD QIU Metric.fields.{5fbabfd8-3d5f-4593-a48b-191b529eb267}drawId': ri!drawId,
        'recordType!{a0920e4c-0c76-4494-a61a-6e38d5db390a}SD QIU Metric.fields.{ecef76a6-01a5-4d0d-8941-a02394945e7e}metricOrder': fv!item['recordType!{a0920e4c-0c76-4494-a61a-6e38d5db390a}SD QIU Metric.fields.{ecef76a6-01a5-4d0d-8941-a02394945e7e}metricOrder'],
        'recordType!{a0920e4c-0c76-4494-a61a-6e38d5db390a}SD QIU Metric.fields.{75d24b80-5a71-4593-9726-440e6253e421}metric': fv!item['recordType!{a0920e4c-0c76-4494-a61a-6e38d5db390a}SD QIU Metric.fields.{75d24b80-5a71-4593-9726-440e6253e421}metric'],
        'recordType!{a0920e4c-0c76-4494-a61a-6e38d5db390a}SD QIU Metric.fields.{276dbba0-0b4b-460c-ba32-0f12a1ec51ce}modelAsOfDate': ri!asOfDate,
        'recordType!{a0920e4c-0c76-4494-a61a-6e38d5db390a}SD QIU Metric.fields.{1db4ed90-8f43-447c-8c7c-aca831ccf178}currentModelValue': fv!item['recordType!{a0920e4c-0c76-4494-a61a-6e38d5db390a}SD QIU Metric.fields.{1db4ed90-8f43-447c-8c7c-aca831ccf178}currentModelValue'],
        'recordType!{a0920e4c-0c76-4494-a61a-6e38d5db390a}SD QIU Metric.fields.{212e37e2-434d-4337-bb4b-ea129a230f25}currentProjection': fv!item['recordType!{a0920e4c-0c76-4494-a61a-6e38d5db390a}SD QIU Metric.fields.{212e37e2-434d-4337-bb4b-ea129a230f25}currentProjection'],
        'recordType!{a0920e4c-0c76-4494-a61a-6e38d5db390a}SD QIU Metric.fields.{b135520a-cbed-4cd7-8a3c-0bbaa699b1ba}variance': fv!item['recordType!{a0920e4c-0c76-4494-a61a-6e38d5db390a}SD QIU Metric.fields.{b135520a-cbed-4cd7-8a3c-0bbaa699b1ba}variance'],
        'recordType!{a0920e4c-0c76-4494-a61a-6e38d5db390a}SD QIU Metric.fields.{125838c4-1335-43ca-be24-7633c09662e0}notes': ""
      )
    )
  )
)

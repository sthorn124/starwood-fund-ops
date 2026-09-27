/* Draw approval (Phase 6c): the decision source (TASK, EMAIL, ACCELERATOR, SEED) recorded on a draw's approval row,
   for the treasury notification's "final approval … by email reply / in Starwood Draw Approvals". */
if(
  or(a!isNullOrEmpty(ri!drawId), a!isNullOrEmpty(ri!approvalOrder)),
  "",
  a!localVariables(
    local!row: index(
      a!queryRecordType(
        recordType: 'recordType!{02c207d5-c725-4d11-bf40-b33573e87ffa}SD Draw Approval',
        fields: {'recordType!{02c207d5-c725-4d11-bf40-b33573e87ffa}SD Draw Approval.fields.{6597627c-af44-4119-9b92-286179df119d}decisionSource'},
        filters: {
          a!queryFilter(field: 'recordType!{02c207d5-c725-4d11-bf40-b33573e87ffa}SD Draw Approval.fields.{5dacd7ec-3f3f-4645-9d08-684793b0b54b}drawId', operator: "=", value: ri!drawId),
          a!queryFilter(field: 'recordType!{02c207d5-c725-4d11-bf40-b33573e87ffa}SD Draw Approval.fields.{44b8ee63-1230-4abd-ae83-ca2cddf182b6}approvalOrder', operator: "=", value: ri!approvalOrder)
        },
        pagingInfo: a!pagingInfo(startIndex: 1, batchSize: 1)
      ).data,
      1,
      null
    ),
    if(a!isNullOrEmpty(local!row), "", tostring(a!defaultValue(local!row['recordType!{02c207d5-c725-4d11-bf40-b33573e87ffa}SD Draw Approval.fields.{6597627c-af44-4119-9b92-286179df119d}decisionSource'], "")))
  )
)

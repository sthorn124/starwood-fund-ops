"""UUID-qualified record references for the draw approval SAIL generators."""
DRAW = ("c9d3a947-71aa-4024-879e-363873a12860", "SD Draw")
INV = ("f285a98c-746c-40e7-899e-65d8d20f766b", "SD Investment")
LINE = ("ddc4073e-6372-49e2-80de-a088b424abcd", "SD Draw Budget Line")
APPR = ("02c207d5-c725-4d11-bf40-b33573e87ffa", "SD Draw Approval")
QIU = ("a0920e4c-0c76-4494-a61a-6e38d5db390a", "SD QIU Metric")
DOC = ("f3e0033f-2047-4c68-8f6f-cf32166091e9", "SD Draw Document")
FUND = ("978232cc-9d8d-42fb-9073-ca776be3dcfb", "SA Fund")
MSG = ("3686a81f-86e2-498e-a4d1-ce40236c824a", "SD Draw Email Message")

F = {
  DRAW: dict(id="443829ca-5971-4d31-8fac-ab7a317e509b", drawNumber="9aa1030b-f76b-49aa-bef6-99eb90327804",
    investmentId="09edf0b2-28a3-4a7f-b9dc-ae2afefa24d0", amount="58586ee5-5a93-4670-a8ee-cd1c88cdb903",
    cashEquityNeeded="4cf33493-ff2d-4c80-a647-869913a054ee", fundingDate="d3bf793a-2b28-4d8c-81d4-8b05cb63f5a6",
    drawType="5e39494a-0995-4196-828b-ab809cf187db", purpose="0420a7a0-6645-4d31-9c0b-4c19ff7d88da",
    budgetStatus="23929877-d10e-4cff-a967-6bb3b0f61eac", overBudgetReason="d05fa5d6-60fa-4e20-be49-1ce42ff1e7d9",
    generalComments="c9513036-39a7-4877-9e18-852a36d7dc23", contingencyExplanation="3a000d1d-0179-488f-87a9-1dc3b87ec048",
    status="e63818ec-ea02-40a0-bfdd-2c14b760dc2c", currentStep="51d3ea43-572b-4052-a36d-369d39f8d05d",
    activeStepProcessId="a132be23-f941-4d59-a22c-b57e29900ea6", createdAt="bafcfa5d-b988-4c12-a134-cd826184f0b7",
    updatedAt="9b41d47b-ef3a-4ea7-bf7e-0935b9c83393", treasuryNotifiedAt="f98054f6-7140-4046-b3d0-2be2f78e6873",
    receivedDate="039b9281-34a3-468c-881e-20a4ce03d900", submittedBy="18a40650-1ce5-4cc4-8132-6018cd1064a9",
    extractionInstanceId="1c798a00-4519-49c1-9c04-27e7fb78a9d3", ingestionProcessId="e418c5aa-c0db-4e02-8fb9-a4ce72ccdcef",
    ingestionFailureReason="3139df20-a318-49b1-a9e7-13f6317880ef", ingestionComparison="74b593a2-ffea-4eb9-90af-49729fcdcb25",
    corroborationSummary="37d76e51-3aa8-4ab0-a2fb-26eec0bebf51", corroborationState="8d2c7d6c-f7c0-4845-b49d-f1278f9b09bc"),
  INV: dict(id="5739486c-cd04-4774-a878-17ca0b9933c4", investmentName="e79c63ed-a43c-4951-b679-e2578ed5cbf6",
    investmentDescription="fc86153c-eedd-41de-a0dd-a20def74fd2d", propertyCode="d90fc43b-4092-45ff-829f-a2e745032638",
    fundId="0c4e3566-5774-4e32-917e-abe83f6f9179"),
  LINE: dict(id="14803371-b715-43a4-bc3a-94e314f16f8a", drawId="830216a5-8980-4ac0-a8f9-7baa33bbea6b",
    lineOrder="2dd34362-59f3-46ad-bb7b-12f44273015e", budgetCategory="4b8934ab-ad8e-4fc0-ac4e-86a762018dee",
    categoryGroup="2bb6dc6b-76ba-4c39-ba45-837acbf905c1", inThisDraw="afd91132-85fa-48aa-a534-0c6a2818b0c3",
    initialBudget="037ae530-9352-430e-a9b8-9d8b11b8450d", revisedApprovedBudget="eb2ed1b0-6417-4468-a2a2-a0e7f643e931",
    proposedAdjustmentsThisDraw="497f7abe-c453-4b00-97ad-1f5da03f5cd2", proposedBudget="eb2590fe-db09-40e0-8711-a0a044141fe6",
    currentDraw="5242c9d6-c607-43c9-900c-756163dcbae5", totalPtdIncThisDrawAmount="aab45d4c-cd07-43ce-87e6-21d485c77827",
    totalPtdIncThisDrawPct="69bde771-7a23-4f20-9c2a-4303372651cd", balanceToComplete="88da0de6-2ef3-428e-9e04-9edc085fe9b1"),
  APPR: dict(id="69abcdf2-55da-48dc-8cc4-794b5d5e0042", drawId="5dacd7ec-3f3f-4645-9d08-684793b0b54b",
    approvalOrder="44b8ee63-1230-4abd-ae83-ca2cddf182b6", role="30524217-4621-4b41-9af4-490d2f082bdd",
    approverName="983be1c0-67e4-464f-b7c2-1e3a1c735458", status="4c1bf7fb-0736-4c9a-946e-99f6989ac83a",
    decisionDate="a6a03063-3b14-4f00-8cab-b5d10602405e", comments="3c1aae42-13a1-4c13-894a-9fdef20f7fce",
    actedBy="2e6ad17e-66f3-4ab2-97b6-c21ee10dd203", decisionSource="6597627c-af44-4119-9b92-286179df119d",
    activatedAt="e6597b65-664d-4ccc-9dd0-f3e508ecdcc5"),
  QIU: dict(id="f3d5f8f7-3ecf-4749-b749-78f2836cd65d", drawId="5fbabfd8-3d5f-4593-a48b-191b529eb267",
    metricOrder="ecef76a6-01a5-4d0d-8941-a02394945e7e", metric="75d24b80-5a71-4593-9726-440e6253e421",
    modelAsOfDate="276dbba0-0b4b-460c-ba32-0f12a1ec51ce", currentModelValue="1db4ed90-8f43-447c-8c7c-aca831ccf178",
    currentProjection="212e37e2-434d-4337-bb4b-ea129a230f25", variance="b135520a-cbed-4cd7-8a3c-0bbaa699b1ba",
    notes="125838c4-1335-43ca-be24-7633c09662e0"),
  DOC: dict(id="a0e2e466-e3fb-4f48-9744-481735a1ba8f", drawId="75e7a282-935e-488c-8f72-2b32468edbfc",
    document="2be78aec-5184-4fd9-8c89-5eabf2bf45ad", documentName="fbdf2e7f-9289-4130-82a5-bda409cccf85",
    documentType="154ca280-0c9e-4ee5-aed2-111e441a035c", uploadedBy="b05f8b67-228d-4c39-aa07-519e3f448bb8",
    uploadedAt="5e348596-a740-4af9-82ac-423ed4f15b63", status="2863739f-c94b-4f6c-804a-b0fcef1572f7",
    notes="2b7e89b7-8344-41ad-a71f-9bfb117a9e0c", receivedDate="2e8183a8-cc80-4093-92c3-f77c04777ac5",
    extractedAmount="bdb3e5b5-4258-4f86-b966-c93ecc1bdc74", extractedParty="2d16e3e7-0168-4871-8914-27372cd42cae",
    extractedReference="3f4fdc48-d009-425e-a793-b5a4e83f2a76"),
  FUND: dict(fundName="fb775e5a-1ed9-4ce9-85ca-bb1b43767475"),
  MSG: dict(id="7d692543-d14a-44a7-b2eb-2aba819cea1f", drawId="163bd929-1a5c-4862-a6b4-e64a7af2e463",
    approvalId="2bc241c2-0f50-4ca7-aad2-5f2065c28e3e", stepOrder="eec43b21-b977-4527-9343-f4a9f0b2b915",
    direction="7bc67c6f-53fd-4bd1-99a1-0748c73ae443", kind="e12b21b7-9fcd-4f26-9371-74db2e074a1c",
    fromAddress="ec1d6acb-41e9-49b5-a4df-eb40ec25a181", toAddress="add14594-0467-46b4-ac85-ad853f0dd3e0",
    subject="8a51f991-924b-415f-b810-3f5452f7ea83", body="a73467a6-901c-42cd-87c2-e6f52a81dcd1",
    messageAt="13756bd6-152a-4c93-aba0-84269d1d5ade", outcome="ae349a0e-1ad6-4f39-ab7f-f531937147d1",
    interpretation="0aef50c3-deb5-4704-ac28-a9a3a35ae650", source="4c41085b-ca45-480a-bb74-ebc8e9b58299",
    notes="26ebc1a1-f628-4e0f-8e50-67a18fdd3fa4"),
}
REL = dict(investment="58a1018a-d85c-42b9-94ed-b51a9f0ef3d2", fund="1b588a74-afbc-4756-aacf-69483491d566",
           budgetLines="c52fed02-7e7f-4be0-93a3-c35ee33b10eb", approvals="c0c98a7d-4967-47dd-b576-6eaffcddaf0c",
           qiuMetrics="f675a7f5-8a38-4370-8a9f-519bab9b8cdb", documents="fa304691-b7a3-44c1-9060-41470ddc2394",
           draws="3ae39877-0000-0000-0000-000000000000")

def rt(t): return f"'recordType!{{{t[0]}}}{t[1]}'"
def fld(t, name): return f"'recordType!{{{t[0]}}}{t[1]}.fields.{{{F[t][name]}}}{name}'"
def rel_fld(base, relname, target, name):
    return f"'recordType!{{{base[0]}}}{base[1]}.relationships.{{{REL[relname]}}}{relname}.fields.{{{F[target][name]}}}{name}'"
def rel2_fld(base, r1, r2, target, name):
    return (f"'recordType!{{{base[0]}}}{base[1]}.relationships.{{{REL[r1]}}}{r1}"
            f".relationships.{{{REL[r2]}}}{r2}.fields.{{{F[target][name]}}}{name}'")

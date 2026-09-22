a!localVariables(
  /*Load Branding Data for Styling*/
  local!brandingMap: rule!AIA_UTIL_LoadBrandingMap(),
  /*Extraction Instance Fields*/
  local!extractionFields: rule!AIA_Extraction_GetFieldsForModelVersionId(
    modelVersionId: ri!ExtractionInstance['recordType!{64322398-e457-4695-87d5-09794164cf77}AIA Extraction Instance.fields.{b597f1b0-ea3e-4f5c-8a7f-ae999e66f407}modelVersionId'],
    additionalFields: {
      'recordType!{f00f33ce-439e-4c81-9931-a244a643c0e8}AIA Extraction Model Version.relationships.{3e78fcff-a033-4b81-a754-e8fff1062c32}modelFields.fields.{6cbb3806-487c-4b1f-8f4d-1cfb6bfb3684}microAccuracy',
      
    }
  ),
  /*In the case that a user reconciles a Large Table but then cancels out of the Reconcile action entirely, we want to make sure changes don't get persisted in the underlying stored document*/
  /*Thus, any reconciled Large Table data will be saved into this local first, and on the Submit button of this action, the local gets persisted into the underlying JSON document for the field*/
  local!largeTableReconciledDataMaps: a!forEach(
    items: rule!AIA_UTIL_Filter(
      records: local!extractionFields,
      field: 'recordType!{2838cbf2-2e48-4696-90bc-50ef0fca9ae9}AIA Extraction Model Version Field.fields.{b7f55314-b6cd-432d-8772-3ce35eef1547}type',
      value: cons!AIA_EXTRACTION_FIELD_TYPE_LARGE_TABLE
    ),
    expression: a!map(
      key: fv!item['recordType!{2838cbf2-2e48-4696-90bc-50ef0fca9ae9}AIA Extraction Model Version Field.fields.{ed32edda-9ac0-476c-b19c-ec552b6452c4}key'],
      reconciledDataTempDoc: null
    )
  ),
  local!drilldownField,
  /*Extraction Field Sections*/
  local!sections: union(
    local!extractionFields['recordType!{2838cbf2-2e48-4696-90bc-50ef0fca9ae9}AIA Extraction Model Version Field.fields.{a85207dc-1bc4-4f30-8d8e-3467192d3cf9}section'],
    local!extractionFields['recordType!{2838cbf2-2e48-4696-90bc-50ef0fca9ae9}AIA Extraction Model Version Field.fields.{a85207dc-1bc4-4f30-8d8e-3467192d3cf9}section']
  ),
  local!extractionModel: rule!AIA_QR_getExtractionModel(
    returnType: "SINGLE_OBJECT",
    modelId: ri!extractionInstance['recordType!{64322398-e457-4695-87d5-09794164cf77}AIA Extraction Instance.relationships.{5162b7ef-b5b5-4edc-a3d9-870a7f5127c0}modelVersion.fields.{ef345a40-c4a8-4090-bc67-ecc5c980b688}modelId'],
    fields: {
      'recordType!{1d688c85-2aff-47a5-84a7-b5c4ccf02a4d}AIA Extraction Model.fields.{4f803b8d-659e-4b3b-bf8c-c5e6d65c8821}useLandscapeView',
      'recordType!{1d688c85-2aff-47a5-84a7-b5c4ccf02a4d}AIA Extraction Model.fields.{e1b07563-caeb-4a42-85d4-2e48bdef2fcf}version'
    }
  ),
  local!ExtractionInstanceFields: a!defaultValue(
    ri!extractionInstance['recordType!{64322398-e457-4695-87d5-09794164cf77}AIA Extraction Instance.relationships.{8d64a7fc-95d1-4c81-b1d8-f583dafbf127}instanceFields'],
    rule!AIA_Extract_ExtractFieldsFromJsonResponse(
      jsonResponse: "",
      ExtractionInstance: ri!ExtractionInstance
    ).extractedFields
  ),
  local!highlightedBox,
  local!selectedBox,
  local!selectedField,
  local!interactionId: 0,
  local!captureSelection,
  local!isExcel: rule!AIA_DocIsExcel(
    document: ri!ExtractionInstance['recordType!{64322398-e457-4695-87d5-09794164cf77}AIA Extraction Instance.fields.{507e0674-64d1-4f82-9bed-13d283c9d410}documentId']
  ),
  local!hasBoundingBoxes: or(
    local!isExcel,
    and(
      a!isNotNullOrEmpty(
        ri!ExtractionInstance['recordType!{64322398-e457-4695-87d5-09794164cf77}AIA Extraction Instance.fields.{df53ae63-a64a-4a79-ad4f-79ca0c54cd84}hasBoundingBoxes']
      ),
      a!isNotNullOrEmpty(
        ri!ExtractionInstance['recordType!{64322398-e457-4695-87d5-09794164cf77}AIA Extraction Instance.fields.{29678053-763f-4511-afb9-9e5f13e1ec05}boundingBoxesDocumentId']
      ),
      ri!ExtractionInstance['recordType!{64322398-e457-4695-87d5-09794164cf77}AIA Extraction Instance.fields.{df53ae63-a64a-4a79-ad4f-79ca0c54cd84}hasBoundingBoxes']
    )
  ),
  local!extractionInstance: a!refreshVariable(
    refreshOnVarChange: local!ExtractionInstanceFields,
    value: a!update(
      ri!extractionInstance,
      'recordType!{64322398-e457-4695-87d5-09794164cf77}AIA Extraction Instance.relationships.{8d64a7fc-95d1-4c81-b1d8-f583dafbf127}instanceFields',
      local!ExtractionInstanceFields
    )
  ),
  local!validations: rule!AIA_GetValidationsForInstance(instance: ri!extractionInstance),
  local!layout: a!defaultValue(
    value: if(
      local!extractionModel['recordType!{1d688c85-2aff-47a5-84a7-b5c4ccf02a4d}AIA Extraction Model.fields.{4f803b8d-659e-4b3b-bf8c-c5e6d65c8821}useLandscapeView'] = true,
      cons!AIA_LAYOUTS[2],
      cons!AIA_LAYOUTS[1]
    ),
    default: cons!AIA_LAYOUTS[1]
  ),
  a!headerContentLayout(
    header: {
      rule!AIA_ExtractionInstance_RecordAction_ReconcileHeader(
        layout: local!layout,
        drilldownField: local!drilldownField
      )
    },
    contents: if(
      a!isNullOrEmpty(local!drilldownField),
      a!paneLayout(
        panes: {
          a!pane(
            contents: {
              /*Display Field Validation*/
              rule!AIA_ExtractionInstance_Sub_DisplayReconcileValidation(
                ValidationErrors: local!validations,
                ExtractionInstance: local!extractionInstance,
                brandingMap: local!brandingMap
              ),
              a!forEach(
                items: local!sections,
                expression: a!localVariables(
                  local!currentSection: fv!item,
                  a!boxLayout(
                    label: a!defaultValue(
                      local!currentSection,
                      cons!AIA_SECTION_EXTRACTED_DATA
                    ),
                    accessibilityText: a!defaultValue(
                      local!currentSection,
                      cons!AIA_SECTION_EXTRACTED_DATA
                    ),
                    labelHeadingTag: "H3",
                    style: local!brandingMap.Blue0,
                    showBorder: false(),
                    isCollapsible: true(),
                    contents: a!cardLayout(
                      shape: "SEMI_ROUNDED",
                      marginAbove: "NONE",
                      marginBelow: "LESS",
                      style: local!brandingMap.DefaultPageBackground,
                      padding: "LESS",
                      showBorder: false(),
                      showShadow: false(),
                      contents: a!forEach(
                        items: local!extractionFields,
                        expression: rule!AIA_ExtractionInstance_Sub_ReconcileSection(
                          brandingMap: local!brandingMap,
                          ModelVersionField: fv!item,
                          ExtractionInstanceFields: local!ExtractionInstanceFields,
                          ValidationErrors: local!validations,
                          drilldownField: local!drilldownField,
                          section: local!currentSection,
                          showTarget: local!hasBoundingBoxes,
                          largeTableReconciledDataMaps: local!largeTableReconciledDataMaps,
                          showMarker: and(
                            local!hasBoundingBoxes,
                            not(local!isExcel)
                          ),
                          highlightSaves: {
                            a!save(
                              local!highlightedBox,
                              if(
                                rule!AIA_IsObject(index(save!value, 1, null)),
                                index(save!value, "sourceCell", save!value),
                                save!value
                              )
                            ),
                            a!save(
                              local!interactionId,
                              local!interactionId + 2
                            )
                          },
                          captureSaves: {
                            if(
                              or(
                                a!isNullOrEmpty(
                                  index(local!captureSelection, "time", null)
                                ),
                                elapsedseconds(local!captureSelection.time, now()) > 10
                              ),
                              a!save(
                                local!selectedField,
                                if(
                                  and(
                                    a!isNotNullOrEmpty(local!selectedField),
                                    local!selectedField = save!value
                                  ),
                                  null,
                                  save!value
                                )
                              ),
                              a!localVariables(
                                local!fieldIndex: index(
                                  wherecontains(
                                    tostring(
                                      fv!item['recordType!{2838cbf2-2e48-4696-90bc-50ef0fca9ae9}AIA Extraction Model Version Field.fields.{c0992839-e052-4de6-8ed6-b2be0ca73c93}fieldId']
                                    ),
                                    touniformstring(
                                      local!ExtractionInstanceFields['recordType!{7c86b423-dc7a-4a37-980a-5600d4d9e298}AIA Extraction Instance Field.fields.{8ff8d9a6-8162-4201-b888-740989804f77}modelVersionFieldId']
                                    )
                                  ),
                                  1,
                                  null
                                ),
                                {
                                  rule!AIA_Extraction_CaptureFieldSaves(
                                    ExtractionInstanceFields: local!ExtractionInstanceFields,
                                    resultFieldIndex: local!fieldIndex,
                                    ModelVersionFields: local!extractionFields,
                                    value: local!captureSelection.value
                                  ),
                                  rule!AIA_Extraction_CaptureBoxSaves(
                                    ExtractionInstanceFields: local!ExtractionInstanceFields,
                                    resultFieldIndex: local!fieldIndex,
                                    highlightedBox: local!highlightedBox,
                                    value: local!captureSelection.boundingBoxIds,
                                    interactionId: local!interactionId
                                  ),
                                  a!save(local!captureSelection, null)
                                }
                              )
                            )
                          },
                          selectedBoxId: local!selectedBox,
                          selectedField: local!selectedField,
                          extractionModel: local!extractionModel
                        )
                      )
                    ),
                    padding: "NONE",
                    marginBelow: "STANDARD"
                  )
                )
              ),
              if(
                local!layout = cons!AIA_LAYOUTS[2],
                if(
                  local!hasBoundingBoxes,
                  rule!AIA_ExtractionInstance_Sub_ReconcileDocument(
                    ExtractionInstance: ri!ExtractionInstance,
                    ExtractionInstanceFields: local!ExtractionInstanceFields,
                    ModelVersionFields: local!extractionFields,
                    highlightedBox: local!highlightedBox,
                    captureSelection: local!captureSelection,
                    selectedBox: local!selectedBox,
                    selectedField: local!selectedField,
                    interactionId: local!interactionId,
                    brandingMap: local!brandingMap
                  ),
                  rule!AIA_UTIL_displayInlineDocument(
                    documentId: ri!ExtractionInstance['recordType!{64322398-e457-4695-87d5-09794164cf77}AIA Extraction Instance.fields.{507e0674-64d1-4f82-9bed-13d283c9d410}documentId'],
                    sourceDocumentId: ri!ExtractionInstance['recordType!{64322398-e457-4695-87d5-09794164cf77}AIA Extraction Instance.fields.{7fd35d67-9a78-4cf1-b78d-6ee582af1222}sourceDocumentId'],
                    height: "TALL"
                  )
                ),
                {}
              ),
              a!horizontalLine(),
              a!buttonLayout(
                /*Cancel Button*/
                secondaryButtons: a!buttonWidget(
                  label: 'translation!{b777166b-bd4b-4195-a492-718ccbfcaecc}AIA_Translations.{df61ccad-fe9a-4d7a-ba9a-d89b08f3467a}Cancel',
                  submit: true(),
                  validate: false(),
                  value: true,
                  saveInto: ri!cancel,
                  loadingIndicator: true()
                ),
                /*Submit Button*/
                primaryButtons: a!buttonWidget(
                  label: 'translation!{b777166b-bd4b-4195-a492-718ccbfcaecc}AIA_Translations.{d16bad4f-bd7d-4749-973b-caf37acbd5cb}Submit',
                  submit: true(),
                  validate: true(),
                  /*Submit Save Intos*/
                  saveInto: {
                    /*For any Large Tables that were reconciled, save the results stored in the tempDoc to the actual doc stored for the field*/
                    if(
                      a!isNotNullOrEmpty(local!largeTableReconciledDataMaps),
                      a!forEach(
                        items: local!largeTableReconciledDataMaps,
                        expression: a!localVariables(
                          local!updateFile,
                          if(
                            a!isNotNullOrEmpty(fv!item.reconciledDataTempDoc),
                            a!save(
                              local!updateFile,
                              rule!AIA_PLG_UpdateFile(
                                document: rule!AIA_UTIL_Filter(
                                  records: local!ExtractionInstanceFields,
                                  field: 'recordType!{7c86b423-dc7a-4a37-980a-5600d4d9e298}AIA Extraction Instance Field.relationships.{c0e1e855-dc32-4468-ba94-97b027839510}modelVersionField.fields.{ed32edda-9ac0-476c-b19c-ec552b6452c4}key',
                                  value: fv!item.key
                                )['recordType!{7c86b423-dc7a-4a37-980a-5600d4d9e298}AIA Extraction Instance Field.fields.{bb8978d8-a808-49d8-b9ad-9343a8819615}extractedValue'],
                                operations: a!map(
                                  method: "REPLACE",
                                  content: fv!item.reconciledDataTempDoc
                                )
                              )
                            ),
                            /*Dummy save in the case the Large Table wasn't reconciled at all*/
                            a!save(local!updateFile, local!updateFile)
                          )
                        )
                      ),
                      {}
                    ),
                    a!save(
                      ri!ExtractionInstance['recordType!{64322398-e457-4695-87d5-09794164cf77}AIA Extraction Instance.relationships.{8d64a7fc-95d1-4c81-b1d8-f583dafbf127}instanceFields'],
                      local!ExtractionInstanceFields
                    ),
                    a!save(
                      ri!extractionInstance,
                      a!update(
                        ri!extractionInstance,
                        {
                          'recordType!{64322398-e457-4695-87d5-09794164cf77}AIA Extraction Instance.fields.{d0b39390-3147-451b-b49e-f4256e466577}statusId',
                          'recordType!{64322398-e457-4695-87d5-09794164cf77}AIA Extraction Instance.fields.{2552bcbf-3670-4a5c-a5fd-aa8003e2696a}modifiedBy',
                          'recordType!{64322398-e457-4695-87d5-09794164cf77}AIA Extraction Instance.fields.{90898700-0cd9-41db-bf2c-ece3656b815c}modifiedOn'
                        },
                        {
                          cons!AIA_INSTANCE_STATUS_RECONCILED_MANUALLY,
                          loggedInUser(),
                          now()
                        }
                      )
                    )
                  },
                  style: "SOLID"
                )
              )
            },
            padding: "LESS"
          ),
          a!pane(
            contents: if(
              local!hasBoundingBoxes,
              rule!AIA_ExtractionInstance_Sub_ReconcileDocument(
                ExtractionInstance: ri!ExtractionInstance,
                ExtractionInstanceFields: local!ExtractionInstanceFields,
                ModelVersionFields: local!extractionFields,
                highlightedBox: local!highlightedBox,
                captureSelection: local!captureSelection,
                selectedBox: local!selectedBox,
                selectedField: local!selectedField,
                interactionId: local!interactionId,
                brandingMap: local!brandingMap
              ),
              rule!AIA_UTIL_displayInlineDocument(
                documentId: ri!ExtractionInstance['recordType!{64322398-e457-4695-87d5-09794164cf77}AIA Extraction Instance.fields.{507e0674-64d1-4f82-9bed-13d283c9d410}documentId'],
                sourceDocumentId: ri!ExtractionInstance['recordType!{64322398-e457-4695-87d5-09794164cf77}AIA Extraction Instance.fields.{7fd35d67-9a78-4cf1-b78d-6ee582af1222}sourceDocumentId'],
                height: "TALL"
              )
            ),
            padding: "LESS",
            showWhen: local!layout = cons!AIA_LAYOUTS[1]
          )
        }
      ),
      rule!AIA_Extraction_ReconcileLargeTableField(
        brandingMap: local!brandingMap,
        selectedExtractionInstanceField: local!drilldownField,
        ExtractionInstance: ri!ExtractionInstance,
        extractionInstanceFields: local!ExtractionInstanceFields,
        reconciledDataDocument: local!largeTableReconciledDataMaps[rule!AIA_UTIL_Filter(
          records: local!largeTableReconciledDataMaps, field: "key", value: local!drilldownField['recordType!{7c86b423-dc7a-4a37-980a-5600d4d9e298}AIA Extraction Instance Field.relationships.{c0e1e855-dc32-4468-ba94-97b027839510}modelVersionField.fields.{ed32edda-9ac0-476c-b19c-ec552b6452c4}key'],
          filterType: "MATCH_INDICES"
        )[1]].reconciledDataTempDoc,
        Validations: local!validations,
        layout: local!layout
      )
    )
  )
)
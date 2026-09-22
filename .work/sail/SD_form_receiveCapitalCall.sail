/* Draw approval (Phase 3): start form of SD Receive Capital Call — the intake trigger, narrated in the demo as the
   EY API/SFTP feed delivering a property manager's budget template. One upload (xlsx) into SD_DRAW_DOCUMENTS_FOLDER;
   on Receive the process creates the Ingesting draw shell and runs Doc Center extraction. Draw number, investment
   and every header fact come from the document, never from this form. */
a!formLayout(
  titleBar: a!headerTemplateFull(
    title: "Receive Capital Call",
    secondaryText: "Budget template intake · Doc Center extraction · accountant reconciliation",
    backgroundColor: "#16294D"
  ),
  contents: {
    a!cardLayout(
      contents: {
        a!richTextDisplayField(
          labelPosition: "COLLAPSED",
          value: {
            a!richTextItem(text: "BUDGET TEMPLATE", color: "#6B7280", size: "SMALL"),
            char(10),
            a!richTextItem(
              text: "Upload the property manager's draw request template as received. The draw number, investment, funding date, amount and the budget lines are read from the document by Doc Center; nothing is keyed here.",
              color: "#374151"
            )
          },
          marginBelow: "STANDARD"
        ),
        a!fileUploadField(
          label: "Draw request template",
          labelPosition: "ABOVE",
          instructions: "Excel workbook (.xlsx) with the Draw Request sheet: header block, then the budget category table.",
          target: cons!SD_DRAW_DOCUMENTS_FOLDER,
          maxSelections: 1,
          value: ri!document,
          saveInto: ri!document,
          required: true,
          requiredMessage: "Attach the budget template to receive the capital call.",
          validations: if(
            a!isNullOrEmpty(ri!document),
            null,
            if(
              or(upper(fv!files.extension) = { "XLSX", "XLS" }),
              null,
              "The template must be an Excel workbook (.xlsx). Received ." & fv!files.extension
            )
          ),
          dropZoneStyle: "EXPANDED"
        )
      },
      style: "NONE",
      shape: "SEMI_ROUNDED",
      padding: "STANDARD",
      marginBelow: "STANDARD"
    )
  },
  buttons: a!buttonLayout(
    primaryButtons: a!buttonWidget(
      label: "Receive",
      submit: true,
      style: "SOLID",
      loadingIndicator: true
    ),
    secondaryButtons: a!buttonWidget(
      label: "Cancel",
      value: true,
      saveInto: ri!cancel,
      submit: true,
      validate: false,
      style: "OUTLINE"
    )
  )
)

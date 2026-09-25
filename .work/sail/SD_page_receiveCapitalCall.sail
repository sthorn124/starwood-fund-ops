/* Draw approval (Phase 3, intake fixed 2026-09-22; package intake Phase 5.5, 2026-09-25): the SASite page "Receive
   Capital Call" — build-time intake tooling, narrated in the demo as the EY API/SFTP feed delivering a property manager's
   draw package. The package is the budget template (one xlsx, required) plus supporting documents (PDFs, optional,
   several): pay application, invoice, lien waiver, backup. One Receive submits every upload on the page (no documents
   argument, per the a!submitUploadedFiles docs) and passes both to the pipeline; the supporting documents are read by a
   separate asynchronous process, so the template path never waits on them and a package without them behaves as before.
   Supporting documents are taken in upload slots, one file each (see the slot comment below for why).
   A regular site-page interface, not a start form: both uploads target SD_DRAW_DOCUMENTS_FOLDER; Receive first commits
   them (a!submitUploadedFiles — outside a start form files stay in a temporary folder until then) and, once they are in
   the folder, starts SD Receive Capital Call through a!startProcess with the template (document) and the supporting
   documents (supportingDocuments) as its parameters. The same interface
   then flips to a confirmation state: received, extraction running, the draw is on the Draws list now, the accountant's
   reconciliation task follows in about 90 seconds; Go to Draws (site page link) and Receive Another (resets the form).
   Draw number, investment and every header fact come from the document, never from this page. The viewer needs Initiator
   on the pipeline (SD Draw Approvers holds it) and Editor on the folder (SD Draw Approvers holds it). */
a!localVariables(
  local!document,
  /* The upload field saves a List of Document even with maxSelections 1 (measured: document() threw "Received the type
     List of Document" on the confirmation render); everything downstream uses the first item. */
  local!uploaded: index(local!document, 1, null),
  /* Supporting documents, one position per upload slot; a cleared slot keeps its position as null. */
  local!supporting: {},
  local!supportingDocs: if(
    count(local!supporting) = 0,
    {},
    index(local!supporting, where(a!forEach(items: local!supporting, expression: not(a!isNullOrEmpty(fv!item)))), {})
  ),
  local!supportingCount: if(a!isNullOrEmpty(local!supportingDocs), 0, length(a!forEach(items: local!supportingDocs, expression: 1))),
  local!supportingSlots: min(10, count(local!supporting) + 1),
  local!state: "form",
  local!error,
  a!headerContentLayout(
    header: {
      a!cardLayout(
        contents: {
          a!richTextDisplayField(
            labelPosition: "COLLAPSED",
            value: {
              a!richTextItem(text: "Fund Operations", color: "#93C5FD", size: "SMALL"),
              char(10),
              a!richTextItem(text: "Receive Capital Call", size: "LARGE", style: "STRONG", color: "#FFFFFF"),
              char(10),
              a!richTextItem(text: "Draw package intake · Doc Center extraction · supporting-document tie-out · accountant reconciliation", color: "#C7D2E5", size: "SMALL")
            },
            marginBelow: "NONE"
          )
        },
        style: "#16294D",
        height: "AUTO",
        padding: "MORE",
        showBorder: false,
        showShadow: false,
        marginBelow: "NONE"
      )
    },
    contents: {
      /* Intake state: the upload and the Receive button. */
      a!cardLayout(
        contents: {
          a!richTextDisplayField(
            labelPosition: "COLLAPSED",
            value: {
              a!richTextItem(text: "BUDGET TEMPLATE", color: "#6B7280", size: "SMALL", style: "STRONG"),
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
            value: local!document,
            saveInto: local!document,
            required: true,
            requiredMessage: "Attach the budget template to receive the capital call.",
            validations: if(
              a!isNullOrEmpty(local!document),
              null,
              if(
                or(upper(fv!files.extension) = { "XLSX", "XLS" }),
                null,
                "The template must be an Excel workbook (.xlsx). Received ." & fv!files.extension
              )
            ),
            dropZoneStyle: "EXPANDED"
          ),
          a!richTextDisplayField(
            labelPosition: "COLLAPSED",
            value: {
              a!richTextItem(text: "SUPPORTING DOCUMENTS · OPTIONAL", color: "#6B7280", size: "SMALL", style: "STRONG"),
              char(10),
              a!richTextItem(
                text: "The rest of the draw package as received: GC pay application, vendor invoices, lien waivers, other backup. Doc Center classifies each PDF; only the pay application is read, and its Current Payment Due is tied out against the template at reconciliation. Invoices and lien waivers are filed. A package without them is received exactly the same way.",
                color: "#374151"
              )
            },
            marginAbove: "MORE",
            marginBelow: "STANDARD"
          ),
          /* One upload slot per supporting document, and a new empty slot after each upload (up to 10). A single
             multi-file field was tried first (2026-09-25) and is not used: an upload that replaces a field's value
             discards the temporary files it replaced (measured: sail's upload sends only the new file; of three PDFs
             only the last existed after Receive, and the pipeline was handed two missing documents). In slots, no file
             ever leaves its field's value except by the user clearing it. A cleared slot keeps its position as null;
             only the documents present go to the process. */
          a!forEach(
            items: enumerate(local!supportingSlots) + 1,
            expression: a!localVariables(
              local!slot: fv!item,
              a!fileUploadField(
                label: "Supporting document " & local!slot,
                labelPosition: "ABOVE",
                instructions: if(local!slot = local!supportingSlots, "PDF. Another slot opens after each upload (up to 10).", null),
                target: cons!SD_DRAW_DOCUMENTS_FOLDER,
                maxSelections: 1,
                value: index(local!supporting, local!slot, null),
                saveInto: a!save(
                  local!supporting,
                  if(
                    local!slot > count(local!supporting),
                    append(local!supporting, index(save!value, 1, null)),
                    a!update(local!supporting, local!slot, index(save!value, 1, null))
                  )
                ),
                validations: if(
                  a!isNullOrEmpty(index(local!supporting, local!slot, null)),
                  null,
                  if(
                    or(upper(fv!files.extension) = "PDF"),
                    null,
                    "Supporting documents must be PDF files. Received ." & index(fv!files.extension, 1, "")
                  )
                ),
                dropZoneStyle: "COMPACT",
                marginBelow: "LESS"
              )
            )
          ),
          a!richTextDisplayField(
            labelPosition: "COLLAPSED",
            value: a!richTextItem(
              text: "The capital call could not be received: " & a!defaultValue(local!error, "the ingestion process did not start") & ". The template was not sent; try again or tell the build owner.",
              color: "#B42318",
              size: "SMALL"
            ),
            showWhen: local!state = "error",
            marginBelow: "STANDARD"
          ),
          a!buttonArrayLayout(
            buttons: {
              a!buttonWidget(
                label: "Receive",
                style: "SOLID",
                loadingIndicator: true,
                validate: true,
                disabled: a!isNullOrEmpty(local!document),
                saveInto: {
                  a!save(local!error, null),
                  a!submitUploadedFiles(
                    onSuccess: {
                      a!startProcess(
                        processModel: cons!SD_RECEIVE_CAPITAL_CALL_PM,
                        processParameters: a!map(document: local!uploaded, supportingDocuments: local!supportingDocs),
                        onSuccess: a!save(local!state, "received"),
                        onError: { a!save(local!state, "error"), a!save(local!error, "the ingestion process did not start") }
                      )
                    },
                    onError: { a!save(local!state, "error"), a!save(local!error, "the upload could not be saved (" & fv!error & ")") }
                  )
                }
              )
            },
            align: "END",
            marginBelow: "NONE"
          )
        },
        style: "NONE",
        shape: "SEMI_ROUNDED",
        padding: "STANDARD",
        showBorder: true,
        showShadow: false,
        marginBelow: "STANDARD",
        showWhen: local!state <> "received"
      ),
      /* Confirmation state: the same page, after Receive. */
      a!cardLayout(
        contents: {
          a!richTextDisplayField(
            labelPosition: "COLLAPSED",
            value: {
              a!richTextIcon(icon: "check-circle", color: "#1E7E46", size: "MEDIUM"),
              a!richTextItem(text: "  Capital call received", size: "MEDIUM", style: "STRONG", color: "#16294D"),
              char(10),
              a!richTextItem(
                text: "Doc Center extraction is running on " & if(a!isNullOrEmpty(local!uploaded), "the template", document(local!uploaded, "name") & "." & document(local!uploaded, "extension")) & ".",
                color: "#374151"
              ),
              char(10),
              a!richTextItem(
                text: if(
                  local!supportingCount = 0,
                  "No supporting documents came with this package.",
                  local!supportingCount & if(local!supportingCount = 1, " supporting document is", " supporting documents are") & " being classified by Doc Center; a pay application is read and tied out against the template on the reconciliation task."
                ),
                color: "#374151"
              ),
              char(10),
              a!richTextItem(
                text: "The draw appears in the Draws list immediately as a new draw (Ingesting). Reconciliation reaches the accountant in roughly 90 seconds, as the Reconcile Extraction task on that draw.",
                color: "#374151"
              )
            },
            marginBelow: "STANDARD"
          ),
          /* Go to Draws is a link (a!buttonWidget has no link keyword on this instance — measured), styled as the primary
             button: a navy card carrying a!safeLink to the Draws site page. Receive Another is a real button. A card is
             not allowed inside a side-by-side layout (measured), so the two sit in a columns layout. */
          a!columnsLayout(
            columns: {
              a!columnLayout(
                contents: a!cardLayout(
                  contents: a!richTextDisplayField(
                    labelPosition: "COLLAPSED",
                    value: a!richTextItem(text: "Go to Draws", color: "#FFFFFF", style: "STRONG"),
                    align: "CENTER",
                    marginBelow: "NONE"
                  ),
                  link: a!safeLink(
                    uri: a!urlForSite(sitePage: 'site!{ffae752f-b3d1-44d5-a9ba-c408b66bdb65}SASite.pages.{76fd3289-c3d8-4c52-ad60-8342f924d6d6}draws'),
                    openLinkIn: "SAME_TAB"
                  ),
                  style: "#16294D",
                  shape: "SEMI_ROUNDED",
                  padding: "LESS",
                  showBorder: false,
                  showShadow: false,
                  marginBelow: "NONE",
                  accessibilityText: "Go to the Draws page"
                ),
                width: "NARROW"
              ),
              a!columnLayout(
                contents: a!buttonArrayLayout(
                  buttons: a!buttonWidget(
                    label: "Receive Another",
                    style: "OUTLINE",
                    saveInto: { a!save(local!document, null), a!save(local!supporting, {}), a!save(local!error, null), a!save(local!state, "form") }
                  ),
                  align: "START",
                  marginBelow: "NONE"
                ),
                width: "AUTO"
              )
            },
            alignVertical: "MIDDLE",
            spacing: "DENSE",
            stackWhen: {"PHONE"},
            marginBelow: "NONE"
          )
        },
        style: "NONE",
        shape: "SEMI_ROUNDED",
        padding: "STANDARD",
        showBorder: true,
        showShadow: false,
        marginBelow: "STANDARD",
        showWhen: local!state = "received"
      )
    },
    backgroundColor: "#F5F6F8"
  )
)

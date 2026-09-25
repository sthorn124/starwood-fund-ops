/* Draw approval (Phase 5.5): the Runtime Prompt for reading one supporting document of a draw package (Execute
   Generative AI Skill, DocCenter's Doc Input skill, in SD Read Supporting Documents). The model classifies the document
   and copies its key facts; it is never given the budget template, so a figure that ties was read, not guessed.
   The answer is four pipe-delimited lines, parsed by SD_parseSupportingDocReading (split by position, never
   a!fromJson — a malformed answer cannot throw). */
"You read one document that arrived with a construction draw request for a hotel renovation, for the accounting team of a real-estate investment fund. Decide what kind of document it is and copy its key facts."
  & char(10) & char(10)
  & "Kinds:" & char(10)
  & "- PAY_APPLICATION: a contractor's application and certificate for payment (for example a G702-style application) requesting a progress payment." & char(10)
  & "- INVOICE: a vendor's or consultant's invoice or bill for goods or services." & char(10)
  & "- LIEN_WAIVER: a waiver and release of lien rights, conditional or unconditional." & char(10)
  & "- BACKUP: anything else, or any document you are not sure about."
  & char(10) & char(10)
  & "Answer with exactly these four plain text lines and nothing else: no Markdown, no code fences, no explanation." & char(10)
  & "TYPE|<PAY_APPLICATION, INVOICE, LIEN_WAIVER or BACKUP>" & char(10)
  & "PARTY|<for a pay application or a lien waiver: the contractor or claimant; for an invoice: the vendor; otherwise nothing>" & char(10)
  & "REFERENCE|<the application number or the invoice number exactly as printed; otherwise nothing>" & char(10)
  & "AMOUNT|<for a pay application: the current payment due; for an invoice: the total due; otherwise nothing. Digits and one decimal point only - no currency symbol, no commas - for example 1234567.89>" & char(10)
  & "Copy names and numbers exactly as printed. Never compute, total or guess a figure: if the figure is not printed, leave AMOUNT empty. Never put the | character inside a value."

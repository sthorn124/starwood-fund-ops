"""Phase 5: generates SD_buildIngestionFailureEmail.sail — the ingestion failure alert (subject + HTML body) built from
the failed draw's records at send time: the stored plain-English reason and AI comparison, the template document row
(file name, received time), what happens next. Phase 4 visual language: navy bands, table layout, every style inline,
no <style>, no images, no links, lean for Gmail. Placeholders (@...@) are replaced from refs — no f-strings, so SAIL's
doubled quotes and braces pass through untouched."""
from refs import *
c = lambda n: fld(DOC, n)
T = r'''/* Draw approval (Phase 5): the ingestion failure alert — subject and HTML body — for a draw whose budget template could
   not be loaded, built from the draw's records at send time (the reason and the comparison the failure branch stored,
   the Budget Template document row). Inputs from the workbook itself (fileInvestmentName, fileDrawNumber) name the draw
   while it has no draw number of its own. Phase 4 visual language: navy bands, table layout, every style inline, no
   stylesheet, no images, no links — Gmail is the target. Returns a!map(subject, html, bytes). */
a!localVariables(
  local!d: rule!SD_getDrawDetail(drawId: ri!drawId),
  local!found: a!defaultValue(index(local!d, "found", false), false),
  local!doc: if(
    not(local!found),
    null,
    index(
      a!queryRecordType(
        recordType: @DOC@,
        fields: {@C_ID@, @C_NAME@, @C_UPLOADED@, @C_RECEIVED@, @C_STATUS@},
        filters: a!queryLogicalExpression(
          operator: "AND",
          filters: {
            a!queryFilter(field: @C_DRAW@, operator: "=", value: ri!drawId),
            a!queryFilter(field: @C_TYPE@, operator: "=", value: "Budget Template")
          }
        ),
        pagingInfo: a!pagingInfo(startIndex: 1, batchSize: 1, sort: a!sortInfo(field: @C_ID@, ascending: false))
      ).data,
      1,
      null
    )
  ),
  local!fileName: if(a!isNullOrEmpty(local!doc), "the budget template", tostring(local!doc[@C_NAME@])),
  local!uploadedAt: if(a!isNullOrEmpty(local!doc), null, local!doc[@C_UPLOADED@]),
  local!receivedText: if(
    a!isNullOrEmpty(local!uploadedAt),
    if(a!isNullOrEmpty(index(local!d, "receivedDate", null)), "—", text(index(local!d, "receivedDate", null), "MM/DD/YYYY")),
    text(local!uploadedAt, "MM/DD/YYYY h:mm AM/PM") & " (" & trim(text(local!uploadedAt, "zzz")) & ")"
  ),
  local!investment: a!defaultValue(
    index(local!d, "investmentName", null),
    if(a!isNullOrEmpty(ri!fileInvestmentName), "an unrecognised investment", ri!fileInvestmentName)
  ),
  local!drawLabel: if(
    not(a!isNullOrEmpty(index(local!d, "drawNumber", null))),
    "Draw #" & index(local!d, "drawNumber", null),
    if(a!isNullOrEmpty(ri!fileDrawNumber), "Draw (number not read)", "Draw #" & ri!fileDrawNumber & " (as submitted)")
  ),
  local!reason: rule!SD_splitIngestionText(text: index(local!d, "ingestionFailureReason", "")),
  local!comparison: rule!SD_splitIngestionText(text: index(local!d, "ingestionComparison", "")),
  local!band: "background:#16294D;color:#FFFFFF;padding:6px 12px;font-size:11px;font-weight:bold;letter-spacing:0.5px;",
  local!tableOpen: "<table role=""presentation"" width=""100%"" cellpadding=""0"" cellspacing=""0"" border=""0"" style=""border-collapse:collapse;font-family:Arial,Helvetica,sans-serif;font-size:12px;color:#1F2937;"">",
  local!para: "padding:8px 12px 4px 12px;font-size:13px;line-height:19px;",
  local!bulletRows: a!forEach(
    items: {"reason", "comparison"},
    expression: a!localVariables(
      local!kind: fv!item,
      local!parts: if(local!kind = "reason", local!reason, local!comparison),
      joinarray(
        a!forEach(
          items: index(local!parts, "bullets", {}),
          expression: "<tr><td style=""padding:3px 6px 3px 12px;width:14px;vertical-align:top;font-size:13px;line-height:19px;color:" & if(local!kind = "reason", "#B42318", "#16294D") & ";"">&bull;</td><td style=""padding:3px 12px 3px 0;font-size:13px;line-height:19px;"">" & rule!SD_htmlEscape(text: fv!item) & "</td></tr>"
        ),
        ""
      )
    )
  ),
  local!detailRow: a!forEach(
    items: {
      a!map(label: "File received", value: local!fileName),
      a!map(label: "Received", value: local!receivedText),
      a!map(label: "Investment (from the file)", value: local!investment),
      a!map(label: "Draw (from the file)", value: local!drawLabel),
      a!map(label: "Sent by", value: a!defaultValue(index(local!d, "submittedBy", null), "—")),
      a!map(label: "Status on the Draws list", value: "Ingestion Failed")
    },
    expression: "<tr><td style=""padding:5px 12px;width:210px;font-size:12px;color:#4B5563;border-bottom:1px solid #EEF1F5;"">" & fv!item.label & "</td><td style=""padding:5px 12px;font-size:12px;font-weight:bold;border-bottom:1px solid #EEF1F5;"">" & rule!SD_htmlEscape(text: fv!item.value) & "</td></tr>"
  ),
  local!subject: "Draw template could not be loaded: " & local!investment & " · " & local!drawLabel & " · " & local!fileName,
  local!html: concat(
    "<div style=""margin:0;padding:0;background:#F5F6F8;"">",
    "<table role=""presentation"" width=""100%"" cellpadding=""0"" cellspacing=""0"" border=""0"" style=""background:#F5F6F8;""><tr><td align=""center"" style=""padding:12px;"">",
    "<table role=""presentation"" width=""100%"" cellpadding=""0"" cellspacing=""0"" border=""0"" style=""max-width:760px;background:#FFFFFF;border:1px solid #D9DEE7;font-family:Arial,Helvetica,sans-serif;color:#1F2937;"">",
    /* Header band */
    "<tr><td style=""background:#16294D;color:#FFFFFF;padding:14px 18px 6px 18px;font-size:16px;font-weight:bold;font-family:Arial,Helvetica,sans-serif;"">DRAW TEMPLATE NOT LOADED &nbsp;|&nbsp; " & rule!SD_htmlEscape(text: local!investment) & "</td></tr>",
    "<tr><td style=""background:#16294D;color:#C7D2E5;padding:0 18px 12px 18px;font-size:11px;font-family:Arial,Helvetica,sans-serif;"">" & rule!SD_htmlEscape(text: local!drawLabel) & " &nbsp;&middot;&nbsp; " & rule!SD_htmlEscape(text: local!fileName) & " &nbsp;&middot;&nbsp; Received " & rule!SD_htmlEscape(text: local!receivedText) & " &nbsp;&middot;&nbsp; <span style=""background:#FDECEC;color:#B42318;padding:1px 6px;font-weight:bold;"">Ingestion Failed</span></td></tr>",
    /* Greeting */
    "<tr><td style=""padding:14px 18px 10px 18px;font-size:13px;line-height:19px;font-family:Arial,Helvetica,sans-serif;"">Hello,<br>A budget template received through the capital call feed could not be loaded. Nothing from it was loaded into the draw and no reconciliation task was created. The details are below.</td></tr>",
    /* What went wrong */
    "<tr><td style=""padding:0 12px;"">" & local!tableOpen & "<tr><td colspan=""2"" style=""" & local!band & """>WHAT WENT WRONG</td></tr>",
    "<tr><td colspan=""2"" style=""padding:0;""><table role=""presentation"" width=""100%"" cellpadding=""0"" cellspacing=""0"" border=""0"" style=""border-collapse:collapse;border-left:4px solid #B42318;background:#FDECEC;font-family:Arial,Helvetica,sans-serif;color:#1F2937;"">",
    "<tr><td colspan=""2"" style=""" & local!para & """>" & rule!SD_htmlEscape(text: index(local!reason, "lead", "")) & "</td></tr>",
    index(local!bulletRows, 1, ""),
    if(index(local!reason, "tail", "") = "", "", "<tr><td colspan=""2"" style=""padding:4px 12px 10px 12px;font-size:13px;line-height:19px;"">" & rule!SD_htmlEscape(text: index(local!reason, "tail", "")) & "</td></tr>"),
    "</table></td></tr></table></td></tr>",
    "<tr><td style=""height:12px;font-size:1px;line-height:12px;"">&nbsp;</td></tr>",
    /* What changed */
    "<tr><td style=""padding:0 12px;"">" & local!tableOpen & "<tr><td colspan=""2"" style=""" & local!band & """>WHAT CHANGED SINCE THE LAST TEMPLATE THAT LOADED</td></tr>",
    "<tr><td colspan=""2"" style=""" & local!para & """>" & rule!SD_htmlEscape(text: if(index(local!comparison, "lead", "") = "", "No comparison was recorded for this file.", index(local!comparison, "lead", ""))) & "</td></tr>",
    index(local!bulletRows, 2, ""),
    if(index(local!comparison, "tail", "") = "", "", "<tr><td colspan=""2"" style=""padding:6px 12px 10px 12px;font-size:11px;line-height:16px;color:#6B7280;font-style:italic;"">" & rule!SD_htmlEscape(text: index(local!comparison, "tail", "")) & "</td></tr>"),
    "</table></td></tr>",
    "<tr><td style=""height:12px;font-size:1px;line-height:12px;"">&nbsp;</td></tr>",
    /* The file */
    "<tr><td style=""padding:0 12px;"">" & local!tableOpen & "<tr><td colspan=""2"" style=""" & local!band & """>THE FILE</td></tr>" & joinarray(local!detailRow, "") & "</table></td></tr>",
    "<tr><td style=""height:12px;font-size:1px;line-height:12px;"">&nbsp;</td></tr>",
    /* What happens next */
    "<tr><td style=""padding:0 12px;"">" & local!tableOpen & "<tr><td colspan=""2"" style=""" & local!band & """>WHAT HAPPENS NEXT</td></tr>",
    "<tr><td colspan=""2"" style=""" & local!para & """>Correct the workbook so it matches the standard draw budget template, then resubmit it through <b>Receive Capital Call</b> on the draw approval site. The new file is checked again when it arrives.</td></tr>",
    "<tr><td colspan=""2"" style=""padding:4px 12px 10px 12px;font-size:13px;line-height:19px;"">This draw stays on the Draws list as <b>Ingestion Failed</b>, as a record of what was received. It will not be approved or funded, and nothing needs to be deleted.</td></tr>",
    "</table></td></tr>",
    "<tr><td style=""height:12px;font-size:1px;line-height:12px;"">&nbsp;</td></tr>",
    /* Footer */
    "<tr><td style=""background:#16294D;color:#FFFFFF;padding:10px 18px;font-size:12px;font-style:italic;font-family:Arial,Helvetica,sans-serif;"">Automated alert from draw approval. Replies to this email are not read.</td></tr>",
    "</table></td></tr></table></div>"
  ),
  a!map(subject: local!subject, html: local!html, bytes: len(local!html))
)
'''
subs = {"@DOC@": rt(DOC), "@C_ID@": c("id"), "@C_NAME@": c("documentName"), "@C_UPLOADED@": c("uploadedAt"),
        "@C_RECEIVED@": c("receivedDate"), "@C_STATUS@": c("status"), "@C_DRAW@": c("drawId"), "@C_TYPE@": c("documentType")}
for k, v in subs.items():
    T = T.replace(k, v)
assert "@C_" not in T and "@DOC@" not in T
open("SD_buildIngestionFailureEmail.sail", "w").write(T)
print("wrote SD_buildIngestionFailureEmail.sail", len(T))

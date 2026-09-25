/* Regression gauntlet for SD_parseSupportingDocReading and SD_corroborateDocuments (Phase 5.5, 2026-09-25).
   Paste into a throwaway zz rule and testRule it. Lines are the clean template's categories and current draws.
   Expected (parse): P1 Pay Application 2490296.23 Read; P2 Invoice 59582 (commas and $ tolerated); P3 Lien Waiver,
   amount ignored; P4 unknown type → Backup, Not read; P5 failed call → Backup, Not read; P6 letters in AMOUNT → null +
   failure; P7 three decimals → null; P8 fenced answer still read; P9 lower-case keys still read.
   Expected (corroborate): C1 TIES/TIES/RECEIVED, state TIES; C2 mismatch + no waiver → ATTENTION, waiverMissing;
   C3 invoice with no matching line → ATTENTION "no matching budget line"; C4 none → NONE; C5 pending → PENDING,
   ATTENTION; C6 backup only → TIES; C7 pay application figure unread → ATTENTION "Figure could not be read". */
a!localVariables(
  local!cats: {"Hard Costs", "A&E - Architectural", "Overhead, CM & Admin Fees", "A&E - Soils & Environmental", "A&E - Design/Misc Consults", "FF&E", "A&E - Engineering", "Operating Deficits", "All Project Contingency", "Land", "Acquisition Costs", "Taxes", "Permits & Muni Fees", "Insurance", "Financing", "Start-up/Marketing"},
  local!draws: {2490296.23, 59582, 54524, 14504, 4837, 1288, 730, -21509, 0, 0, 0, 0, 0, 0, 0, 0},
  local!doc: a!map(rowId: 1, document: null, name: "x.pdf", type: "Pay Application", status: "Read", amount: 2490296.23, party: "Stonebridge Construction Group", reference: "14", notes: ""),
  local!inv: a!map(rowId: 2, document: null, name: "i.pdf", type: "Invoice", status: "Read", amount: 59582, party: "Alder & Finch Architects, LLP", reference: "AF-2026-1087", notes: ""),
  local!lw: a!map(rowId: 3, document: null, name: "w.pdf", type: "Lien Waiver", status: "Read", amount: null, party: "Stonebridge Construction Group", reference: "", notes: ""),
  a!map(
    P1: rule!SD_parseSupportingDocReading(response: "TYPE|PAY_APPLICATION" & char(10) & "PARTY|Stonebridge Construction Group" & char(10) & "REFERENCE|14" & char(10) & "AMOUNT|2490296.23", success: true, errorMessage: null, modelName: "Claude Sonnet 4.6"),
    P2: rule!SD_parseSupportingDocReading(response: "TYPE|INVOICE" & char(10) & "PARTY|Alder & Finch Architects, LLP" & char(10) & "REFERENCE|AF-2026-1087" & char(10) & "AMOUNT|$59,582.00", success: true, errorMessage: null, modelName: "Claude Sonnet 4.6").amount,
    P3: rule!SD_parseSupportingDocReading(response: "TYPE|LIEN_WAIVER" & char(10) & "PARTY|Stonebridge Construction Group" & char(10) & "REFERENCE|" & char(10) & "AMOUNT|2490296.23", success: true, errorMessage: null, modelName: "Claude Sonnet 4.6"),
    P4: rule!SD_parseSupportingDocReading(response: "TYPE|RECEIPT" & char(10) & "AMOUNT|12.00", success: true, errorMessage: null, modelName: "Claude Sonnet 4.6"),
    P5: rule!SD_parseSupportingDocReading(response: null, success: false, errorMessage: "timeout", modelName: "Claude Sonnet 4.6"),
    P6: rule!SD_parseSupportingDocReading(response: "TYPE|PAY_APPLICATION" & char(10) & "AMOUNT|2,490,296.23 USD", success: true, errorMessage: null, modelName: "Claude Sonnet 4.6"),
    P7: rule!SD_parseSupportingDocReading(response: "TYPE|INVOICE" & char(10) & "AMOUNT|59582.004", success: true, errorMessage: null, modelName: "Claude Sonnet 4.6").amount,
    P8: rule!SD_parseSupportingDocReading(response: "```" & char(10) & "TYPE|INVOICE" & char(10) & "PARTY|Alder & Finch" & char(10) & "REFERENCE|AF-1" & char(10) & "AMOUNT|59582" & char(10) & "```", success: true, errorMessage: null, modelName: "Claude Sonnet 4.6").amount,
    P9: rule!SD_parseSupportingDocReading(response: "type|invoice" & char(10) & "amount|59582", success: true, errorMessage: null, modelName: "Claude Sonnet 4.6").documentType,
    C1: a!localVariables(local!r: rule!SD_corroborateDocuments(documents: {local!doc, local!inv, local!lw}, lineCategories: local!cats, lineCurrentDraws: local!draws), a!map(state: local!r.state, summary: local!r.summary, chips: a!forEach(local!r.items, fv!item.chip), templates: a!forEach(local!r.items, fv!item.templateLabel))),
    C2: a!localVariables(local!r: rule!SD_corroborateDocuments(documents: {a!update(local!doc, "amount", 2527796.23)}, lineCategories: local!cats, lineCurrentDraws: local!draws), a!map(state: local!r.state, waiverMissing: local!r.waiverMissing, summary: local!r.summary, chips: a!forEach(local!r.items, fv!item.chip))),
    C3: a!localVariables(local!r: rule!SD_corroborateDocuments(documents: {a!update(local!inv, "amount", 12345.67)}, lineCategories: local!cats, lineCurrentDraws: local!draws), a!map(state: local!r.state, summary: local!r.summary, chips: a!forEach(local!r.items, fv!item.chip))),
    C4: a!localVariables(local!r: rule!SD_corroborateDocuments(documents: null, lineCategories: local!cats, lineCurrentDraws: local!draws), a!map(state: local!r.state, summary: local!r.summary, count: local!r.count)),
    C5: a!localVariables(local!r: rule!SD_corroborateDocuments(documents: {a!update(local!inv, "status", "Received")}, lineCategories: local!cats, lineCurrentDraws: local!draws), a!map(state: local!r.state, summary: local!r.summary, chips: a!forEach(local!r.items, fv!item.chip))),
    C6: a!localVariables(local!r: rule!SD_corroborateDocuments(documents: {a!update(local!lw, "type", "Backup")}, lineCategories: local!cats, lineCurrentDraws: local!draws), a!map(state: local!r.state, summary: local!r.summary)),
    C7: a!localVariables(local!r: rule!SD_corroborateDocuments(documents: {a!update(local!doc, "amount", null), local!lw}, lineCategories: local!cats, lineCurrentDraws: local!draws), a!map(state: local!r.state, summary: local!r.summary, chips: a!forEach(local!r.items, fv!item.chip)))
  )
)

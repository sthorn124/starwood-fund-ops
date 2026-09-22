"""Deterministic seed for draw approval (Phase 1 + Phase 2b list texture).

Sources: `New approval email sample blacklined.pdf` (repo root, read at high resolution 2026-09-21) for draw 66's
lines and QIU rows; the Phase 2b brief (2026-09-22) for the prior draws, the second investment and the documents;
the approved mockups for the chain's approver names, except rows filled by persona accounts, whose display names win
(sd.accountant = "Priya Ramen", sd.assetmanager = "Elena Marchetti").
Explicit ids only (CLAUDE.md §12); no now()/today()/rand(). Narrative frame: draw 66 received 2026-10-03, chain
started 2026-10-06, funding 2026-10-15.

Usage:
  python3 scripts/seed_draw66.py            # reconciliation checks (exit 0 = pass)
  python3 scripts/seed_draw66.py --csv      # insert CSVs, dependency order
  python3 scripts/seed_draw66.py --reset-csv# update CSVs returning draw 66 (and its 9 rows) to the seeded state
"""
import csv, io, sys
from decimal import Decimal as D

FUND_ID = 4  # SA Fund: Harborline Real Assets Fund II, L.P.
PM = "Vail Peak Management LLC (Property Manager)"
GLP_PM = "Gateway Industrial Partners (Developer)"

INVESTMENTS = [
 dict(id=1, investmentName="Tamarack Hotel & Spa Vail",
      investmentDescription=("212-key full-service ski-in/ski-out resort hotel with spa and two F&B outlets in Vail, Colorado; "
                             "acquired 2023 and undergoing a brand-mandated PIP renovation of guest rooms, spa and public areas."),
      propertyCode="THSV", fundId=FUND_ID),
 dict(id=2, investmentName="Gateway Logistics Park Phase II",
      investmentDescription=("1.2M-sf Class A logistics development on 84 acres at the I-80/I-880 interchange in Tracy, California; "
                             "Phase II adds three cross-dock buildings, 40% pre-leased to a national 3PL. Investment profile from DealCloud."),
      propertyCode="GLP2", fundId=FUND_ID),
]

# Chain names by order (mockup chain; rows 1 and 3 are the persona accounts' display names)
CHAIN = [(1,"Accountant","Priya Ramen"),(2,"Accounting Controller","Daniel Osei"),(3,"Asset Manager","Elena Marchetti"),
         (4,"AM SVP","Mark Feldstein"),(5,"Executive","Sandra Whitmore"),(6,"Chief Accounting Officer","Robert Chen"),
         (7,"CFO of Funds","Alicia Fontaine"),(8,"President","James Callahan"),(9,"CEO","Thomas Bergman")]

DRAW_COLS = ["id","drawNumber","investmentId","amount","cashEquityNeeded","fundingDate","drawType","purpose","budgetStatus",
             "overBudgetReason","generalComments","contingencyExplanation","status","currentStep","activeStepProcessId",
             "createdAt","updatedAt","treasuryNotifiedAt","receivedDate","submittedBy"]

def draw(id_, inv, amount, funding, dtype, purpose, status, step, created, updated, treasury, received, submitted,
         budget="On Budget", obr="N/A", gc="", cont=""):
    return dict(id=id_, drawNumber=id_, investmentId=inv, amount=amount, cashEquityNeeded=1, fundingDate=funding, drawType=dtype,
                purpose=purpose, budgetStatus=budget, overBudgetReason=obr, generalComments=gc, contingencyExplanation=cont,
                status=status, currentStep=step, activeStepProcessId="", createdAt=created, updatedAt=updated,
                treasuryNotifiedAt=treasury, receivedDate=received, submittedBy=submitted)

DRAW66_CONT = ("$57k of the remaining $1.27M contingency budget (4.8%) was utilized for incremental ARUP/SHA (Structural, Architectural) "
               "and ACC (Environmental) design coordination work, outside of the insurance claim")
DRAWS = [
 draw(63,1,"5487203.00","2026-01-09","PIP/Renovation","Hard costs, winter construction phase","Approved",9,
      "2025-12-10 09:00:00","2025-12-30 16:40:00","2025-12-30 16:41:00","2025-12-08",PM),
 draw(64,1,"4022516.00","2026-04-11","PIP/Renovation","Hard costs, FF&E deposits","Approved",9,
      "2026-03-12 09:00:00","2026-04-01 15:10:00","2026-04-01 15:11:00","2026-03-10",PM),
 draw(65,1,"3118940.00","2026-07-14","PIP/Renovation","Hard costs & A&E, Q2 renovation package","Approved",9,
      "2026-06-15 09:00:00","2026-07-03 14:25:00","2026-07-03 14:26:00","2026-06-12",PM),
 draw(11,2,"12300000.00","2026-03-20","Development","Hard costs, building 1 shell and site work","Approved",9,
      "2026-02-20 09:00:00","2026-03-11 17:05:00","2026-03-11 17:06:00","2026-02-18",GLP_PM),
 draw(12,2,"8940000.00","2026-11-02","Development","Hard costs, buildings 2-3 foundations and paving","In Progress",6,
      "2026-09-12 09:00:00","2026-09-19 10:30:00","","2026-09-10",GLP_PM),
 draw(66,1,"2604252.23","2026-10-15","PIP/Renovation","Draw #66 for THSV. The total amount this draw is $2,604,252.23.","In Progress",3,
      "2026-10-06 09:00:00","2026-10-07 11:05:00","","2026-10-03",PM, cont=DRAW66_CONT),
]

# Approval rows: id = drawId*100 + order. (drawId, [(order, status, activatedAt, decisionDate, comments, actedBy, source)])
def chain_all_approved(draw_id, start_day, times):
    """All nine Approved: activation = previous decision; dates from a list of 'YYYY-MM-DD HH:MM:SS'."""
    rows=[]; prev=start_day
    for (o,role,name),t in zip(CHAIN,times):
        rows.append((o,"Approved",prev,t,"N/A","seed","SEED")); prev=t
    return rows
APPROVALS = {
 63: chain_all_approved(63,"2025-12-10 09:00:00",["2025-12-11 10:10:00","2025-12-12 14:30:00","2025-12-15 09:45:00","2025-12-16 16:20:00",
      "2025-12-18 11:00:00","2025-12-19 15:15:00","2025-12-22 10:05:00","2025-12-29 09:30:00","2025-12-30 16:40:00"]),
 64: chain_all_approved(64,"2026-03-12 09:00:00",["2026-03-13 10:00:00","2026-03-16 13:20:00","2026-03-17 15:40:00","2026-03-19 09:10:00",
      "2026-03-20 14:00:00","2026-03-24 10:30:00","2026-03-26 16:45:00","2026-03-31 11:15:00","2026-04-01 15:10:00"]),
 65: chain_all_approved(65,"2026-06-15 09:00:00",["2026-06-16 10:30:00","2026-06-17 14:10:00","2026-06-19 09:20:00","2026-06-22 15:00:00",
      "2026-06-24 11:40:00","2026-06-25 16:05:00","2026-06-29 10:15:00","2026-07-01 13:30:00","2026-07-03 14:25:00"]),
 11: chain_all_approved(11,"2026-02-20 09:00:00",["2026-02-23 10:00:00","2026-02-24 15:30:00","2026-02-26 09:15:00","2026-02-27 16:00:00",
      "2026-03-03 11:20:00","2026-03-04 14:45:00","2026-03-06 10:10:00","2026-03-10 09:40:00","2026-03-11 17:05:00"]),
 12: [(1,"Approved","2026-09-12 09:00:00","2026-09-14 10:20:00","N/A","seed","SEED"),
      (2,"Approved","2026-09-14 10:20:00","2026-09-15 14:05:00","N/A","seed","SEED"),
      (3,"Approved","2026-09-15 14:05:00","2026-09-16 16:30:00","Site work verified against schedule","seed","SEED"),
      (4,"Approved","2026-09-16 16:30:00","2026-09-17 09:50:00","N/A","seed","SEED"),
      (5,"Approved","2026-09-17 09:50:00","2026-09-19 10:30:00","N/A","seed","SEED"),
      (6,"In Progress","2026-09-19 10:30:00","","","",""),
      (7,"Pending","","","","",""),(8,"Pending","","","","",""),(9,"Pending","","","","","")],
 66: [(1,"Approved","2026-10-06 09:00:00","2026-10-06 15:20:00","N/A","seed","SEED"),
      (2,"Approved","2026-10-06 15:20:00","2026-10-07 11:05:00","N/A","seed","SEED"),
      (3,"In Progress","2026-10-07 11:05:00","","","",""),
      (4,"Pending","","","","",""),(5,"Pending","","","","",""),(6,"Pending","","","","",""),
      (7,"Pending","","","","",""),(8,"Pending","","","","",""),(9,"Pending","","","","","")],
}

# Draw 66 budget lines (unchanged from Phase 1; cents reconciliation on three lines, see CLAUDE.md known artifacts)
LINES = [
 ("Hard Costs","Hard",1,106664345,186977333,0,186977333,"2490296.83",171792118,91.9,15185215),
 ("A&E - Architectural","Soft",1,7254819,10752723,21000,10773723,"59581.70",10618256,98.6,155467),
 ("Overhead, CM & Admin Fees","Soft",1,3870000,9174304,0,9174304,"54523.70",7359555,80.2,1814749),
 ("A&E - Soils & Environmental","Soft",1,54024,128859,16753,145612,"14504",145611,100.0,1),
 ("A&E - Design/Misc Consults","Soft",1,596991,1469362,20000,1489362,"4837",1481451,99.5,7911),
 ("FF&E","Hard",1,10141960,14219811,0,14219811,"1288",14016988,98.6,202823),
 ("A&E - Engineering","Soft",1,0,664835,0,664835,"730",663888,99.9,947),
 ("Operating Deficits","Soft",1,1000000,318836,0,318836,"-21509",257805,80.9,61031),
 ("All Project Contingency","Soft",1,4215972,1274757,-57753,1217004,"0",0,0.0,1217004),
 ("Land","Land",0,107550000,107550000,0,107550000,"0",107550000,100.0,0),
 ("Acquisition Costs","Land",0,14278400,14275238,0,14275238,"0",14275238,100.0,0),
 ("Taxes","Soft",0,2211943,3011530,0,3011530,"0",3011530,100.0,0),
 ("Permits & Muni Fees","Soft",0,2483394,3453127,0,3453127,"0",3428127,99.3,25000),
 ("Insurance","Soft",0,0,5235682,0,5235682,"0",5235682,100.0,0),
 ("Financing","Soft",0,8432171,21902223,0,21902223,"0",21879343,99.9,22880),
 ("Start-up/Marketing","Soft",0,9922461,9788091,0,9788091,"0",9788091,100.0,0),
]
QIU_ASOF = "2026-09-30"
QIU = [("IRR","(9.4%)","(9.4%)","0.0%"),("Profit","($129,377,499)","($129,377,499)","$0"),("Multiple","0.59x","0.59x","0.00x"),
 ("Peak Equity","$316,461,272","$316,461,272","$0"),("Current Equity Contributions (through prior quarter)","($288,603,860)","($288,603,860)","$0"),
 ("Current Quarter Equity Contribution","$8,259,741","$8,259,741","$0"),("Future Equity Contributions (after current quarter)","($22,702,431)","($22,702,431)","$0"),
 ("Distributions To-Date (through prior quarter)","$3,104,760","$3,104,760","$0"),("Current Quarter Distribution","—","—","—"),
 ("Future Distributions (after current quarter)","$187,083,773","$187,083,773","$0")]
# Draw 66 documents: metadata-only rows (binary uploads corrupt over the Dev MCP; files are added by hand or by Phase 3 ingestion)
DOCS = [
 (6601,66,"","THSV_Draw66_Budget_Template.xlsx","Budget Template","Extracted & Confirmed","2026-10-03","Doc Center extraction confirmed by Priya Ramen 10/05/2026","EY data feed","2026-10-03 06:15:00"),
 (6602,66,"","THSV_Draw66_ContractorInvoices.pdf","Backup","Attached","2026-10-03","Contractor invoice package, Hard Costs","EY data feed","2026-10-03 06:15:00"),
 (6603,66,"","THSV_Draw66_AE_Invoices.pdf","Backup","Attached","2026-10-03","A&E invoices supporting contingency reallocation","EY data feed","2026-10-03 06:15:00"),
]

def csvtext(header, rows):
    b=io.StringIO(); w=csv.writer(b, lineterminator="\n"); w.writerow(header); [w.writerow(r) for r in rows]; return b.getvalue()
APPR_COLS=["id","drawId","approvalOrder","role","approverName","status","activatedAt","decisionDate","comments","actedBy","decisionSource"]
def appr_rows(draw_id):
    out=[]
    for (o,st,act,dec,com,by,src) in APPROVALS[draw_id]:
        role,name=CHAIN[o-1][1],CHAIN[o-1][2]
        out.append([draw_id*100+o, draw_id, o, role, name, st, act, dec, com, by, src])
    return out

def checks():
    ok=True
    def eq(label,a,b):
        nonlocal ok; good=a==b; ok&=good; print(("OK  " if good else "FAIL"), label, a, "==", b)
    groups={"Land":{}, "Soft":{}, "Hard":{}}; cols=["initial","revised","adj","proposed","current","ptd","bal"]
    for L in LINES:
        g=groups[L[1]]
        for c,v in zip(cols,[D(L[3]),D(L[4]),D(L[5]),D(L[6]),D(L[7]),D(L[8]),D(L[10])]): g[c]=g.get(c,D(0))+v
    eq("current draw total == amount", sum(D(L[7]) for L in LINES), D("2604252.23"))
    eq("Land current", int(groups["Land"]["current"]), 0); eq("Soft current", int(groups["Soft"]["current"].to_integral_value(rounding="ROUND_HALF_UP")), 112667)
    eq("Hard current", int(groups["Hard"]["current"].to_integral_value(rounding="ROUND_HALF_UP")), 2491585)
    eq("line count", len(LINES), 16); eq("qiu count", len(QIU), 10)
    for d,rows in APPROVALS.items():
        eq(f"draw {d} orders contiguous", [r[0] for r in rows], list(range(1,10)))
        decs=[r[3] for r in rows if r[3]]; eq(f"draw {d} decision dates ascending", decs, sorted(decs))
        fd=[x for x in DRAWS if x["id"]==d][0]["fundingDate"]
        if decs: eq(f"draw {d} last decision before funding", decs[-1][:10] < fd, True)
    eq("In Approval total", sum(D(x["amount"]) for x in DRAWS if x["status"]=="In Progress"), D("11544252.23"))
    eq("Funded YTD 2026 total", sum(D(x["amount"]) for x in DRAWS if x["status"]=="Approved" and x["fundingDate"].startswith("2026")), D("24928659.00"))
    eq("Funded YTD count", len([x for x in DRAWS if x["status"]=="Approved" and x["fundingDate"].startswith("2026")]), 4)
    return ok

def reset_csv():
    d66=[x for x in DRAWS if x["id"]==66][0]
    draw_csv=csvtext(["id","status","currentStep","activeStepProcessId","updatedAt","treasuryNotifiedAt"],
                     [[66,"In Progress",3,"",d66["updatedAt"],""]])
    appr_csv=csvtext(["id","status","activatedAt","decisionDate","comments","actedBy","decisionSource"],
                     [[66*100+o,st,act,dec,com,by,src] for (o,st,act,dec,com,by,src) in APPROVALS[66]])
    return draw_csv, appr_csv

if __name__=="__main__":
    if "--reset-csv" in sys.argv:
        a,b=reset_csv(); print(a); print(b); sys.exit(0)
    ok=checks()
    if "--csv" in sys.argv:
        print("### SD Investment"); print(csvtext(list(INVESTMENTS[0]), [list(i.values()) for i in INVESTMENTS]))
        print("### SD Draw"); print(csvtext(DRAW_COLS, [[d[c] for c in DRAW_COLS] for d in DRAWS]))
        print("### SD Draw Approval"); print(csvtext(APPR_COLS, [r for d in (63,64,65,11,12,66) for r in appr_rows(d)]))
        print("### SD Draw Budget Line"); print(csvtext(["id","drawId","lineOrder","budgetCategory","categoryGroup","inThisDraw","initialBudget","revisedApprovedBudget",
              "proposedAdjustmentsThisDraw","proposedBudget","currentDraw","totalPtdIncThisDrawAmount","totalPtdIncThisDrawPct","balanceToComplete"],
              [[6601+i,66,i+1]+list(L) for i,L in enumerate(LINES)]))
        print("### SD QIU Metric"); print(csvtext(["id","drawId","metricOrder","metric","modelAsOfDate","currentModelValue","currentProjection","variance","notes"],
              [[6600+i+1,66,i+1,q[0],QIU_ASOF,q[1],q[2],q[3],""] for i,q in enumerate(QIU)]))
        print("### SD Draw Document"); print(csvtext(["id","drawId","document","documentName","documentType","status","receivedDate","notes","uploadedBy","uploadedAt"], [list(r) for r in DOCS]))
    sys.exit(0 if ok else 1)

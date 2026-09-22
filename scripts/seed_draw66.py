"""Deterministic seed for draw approval Phase 1: draw #66 on the THSV investment.

Source: `New approval email sample blacklined.pdf` (repo root), read at high resolution
2026-09-21. Explicit ids only (CLAUDE.md §12); no now()/today()/rand().
Run: python3 scripts/seed_draw66.py  -> prints CSV blocks and the reconciliation checks.
"""
import csv, io, sys

DRAW_ID = 66          # explicit PK; draw number is also 66
INVESTMENT_ID = 1
FUND_ID = 4           # SA Fund: Harborline Real Assets Fund II, L.P.

INVESTMENT = dict(id=INVESTMENT_ID,
    investmentName="Tamarack Hotel & Spa Vail",
    investmentDescription=("212-key full-service ski-in/ski-out resort hotel with spa and two F&B outlets in Vail, Colorado; "
                           "acquired 2023 and undergoing a brand-mandated PIP renovation of guest rooms, spa and public areas."),
    propertyCode="THSV", fundId=FUND_ID)

DRAW = dict(id=DRAW_ID, drawNumber=66, investmentId=INVESTMENT_ID, amount="2604252.23", cashEquityNeeded=1,
    fundingDate="2026-10-15", drawType="PIP/Renovation",
    purpose="Draw #66 for THSV. The total amount this draw is $2,604,252.23.",
    budgetStatus="On Budget", overBudgetReason="N/A", generalComments="",
    contingencyExplanation=("$57k of the remaining $1.27M contingency budget (4.8%) was utilized for incremental ARUP/SHA "
                            "(Structural, Architectural) and ACC (Environmental) design coordination work, outside of the insurance claim"),
    status="In Progress", currentStep=3, activeStepProcessId="",
    createdAt="2026-09-14 09:00:00", updatedAt="2026-09-17 14:10:00")

# (category, group, inThisDraw, initial, revisedApproved, proposedAdj, proposed, currentDraw, ptdAmt, ptdPct, balance)
# currentDraw cents: the email shows whole dollars that sum to 2,604,253 while the draw amount is 2,604,252.23.
# Cents below are the deliberate reconciliation (known data artifact, BUILD_LOG): Hard Costs -0.17, A&E Arch -0.30,
# Overhead -0.30, so In-this-draw sums to 2,604,252.23 and every line, the Soft/Hard subtotals and the total still
# round to the figures the email prints.
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
# NOTE: Operating Deficits PTD % prints 80.9% in the email; 257,805/318,836 = 80.86%. Kept as printed.

APPROVALS = [  # order, role, approverName, status, decisionDate, comments, actedBy, source
 (1,"Accountant","Priya Raman","Approved","2026-09-16 10:12:00","N/A","seed","SEED"),
 (2,"Accounting Controller","Daniel Okafor","Approved","2026-09-17 14:05:00","N/A","seed","SEED"),
 (3,"Asset Manager","Elena Marchetti","In Progress","","","",""),
 (4,"AM SVP","Marcus Whitfield","Pending","","","",""),
 (5,"Executive","Caroline Ashby","Pending","","","",""),
 (6,"Chief Accounting Officer","Robert Lindqvist","Pending","","","",""),
 (7,"CFO of Funds","Hannah Delacroix","Pending","","","",""),
 (8,"President","Jonathan Reyes","Pending","","","",""),
 (9,"CEO","William Hartley","Pending","","","",""),
]

QIU_ASOF = "2026-06-30"
QIU = [  # metric, currentModelValue, currentProjection, variance
 ("IRR","(9.4%)","(9.4%)","0.0%"),
 ("Profit","($129,377,499)","($129,377,499)","$0"),
 ("Multiple","0.59x","0.59x","0.00x"),
 ("Peak Equity","$316,461,272","$316,461,272","$0"),
 ("Current Equity Contributions (through prior quarter)","($288,603,860)","($288,603,860)","$0"),
 ("Current Quarter Equity Contribution","$8,259,741","$8,259,741","$0"),
 ("Future Equity Contributions (after current quarter)","($22,702,431)","($22,702,431)","$0"),
 ("Distributions To-Date (through prior quarter)","$3,104,760","$3,104,760","$0"),
 ("Current Quarter Distribution","—","—","—"),
 ("Future Distributions (after current quarter)","$187,083,773","$187,083,773","$0"),
]

def csvtext(header, rows):
    b=io.StringIO(); w=csv.writer(b, lineterminator="\n"); w.writerow(header); [w.writerow(r) for r in rows]; return b.getvalue()

def checks():
    from decimal import Decimal as D
    ok=True
    def eq(label,a,b):
        nonlocal ok
        good = a==b; ok &= good; print(("OK  " if good else "FAIL"), label, a, "==", b)
    groups={"Land":{}, "Soft":{}, "Hard":{}}
    cols=["initial","revised","adj","proposed","current","ptd","bal"]
    for L in LINES:
        g=groups[L[1]]
        vals=[D(L[3]),D(L[4]),D(L[5]),D(L[6]),D(L[7]),D(L[8]),D(L[10])]
        for c,v in zip(cols,vals): g[c]=g.get(c,D(0))+v
    summary={"Land":[121828400,121825238,0,121825238,0,121825238,0],
             "Soft":[40041774,67174328,0,67232081,112667,63869339,3362742],
             "Hard":[116806305,201197144,0,201139391,2491585,185809106,15330285]}
    # Known source artifacts in the email sample's Budget Summary (logged in BUILD_LOG, client question in TODO):
    # the summary moves the $57,753 contingency adjustment from Hard to Soft in Proposed Budget and Balance To
    # Complete while printing "—" for Proposed Adjustments, and three cells differ by $1 from the whole-dollar
    # detail lines. Detail lines are seeded as printed; the summary is a roll-up computed from them.
    KNOWN = {("Soft","initial"):1, ("Soft","revised"):1, ("Soft","proposed"):-57752, ("Soft","bal"):-57752,
             ("Hard","proposed"):57753, ("Hard","bal"):57753}
    for grp,exp in summary.items():
        for c,e in zip(cols,exp):
            got=int(groups[grp][c].to_integral_value(rounding="ROUND_HALF_UP"))
            eq(f"{grp}.{c} (detail roll-up minus printed summary)", got-e, KNOWN.get((grp,c),0))
    tot=sum(D(L[7]) for L in LINES); eq("current draw total == amount", tot, D(DRAW["amount"]))
    eq("budget total initial", int(sum(D(L[3]) for L in LINES)), 278676480)
    eq("budget total revised (printed 390,196,710; +$1 source rounding)", int(sum(D(L[4]) for L in LINES)), 390196711)
    eq("line count", len(LINES), 16)
    eq("approval orders contiguous", [a[0] for a in APPROVALS], list(range(1,10)))
    eq("qiu count", len(QIU), 10)
    return ok

def reset_csv():
    """Demo reset: update CSVs that return draw 66 and its 9 approval rows to the seeded state.
    Explicit ids only. Apply with updateRecordData (SD Draw, then SD Draw Approval)."""
    draw=csvtext(["id","status","currentStep","activeStepProcessId","updatedAt","treasuryNotifiedAt"],
                 [[DRAW_ID,"In Progress",3,"",DRAW["updatedAt"],""]])
    appr=csvtext(["id","status","decisionDate","comments","actedBy","decisionSource"],
                 [[6600+a[0],a[3],a[4],a[5],a[6],a[7]] for a in APPROVALS])
    return draw, appr

if __name__=="__main__":
    if "--reset-csv" in sys.argv:
        d,a=reset_csv(); print(d); print(a); sys.exit(0)
    ok=checks()
    if "--csv" in sys.argv:
        print(csvtext(list(INVESTMENT), [list(INVESTMENT.values())]))
        print(csvtext(list(DRAW), [list(DRAW.values())]))
        print(csvtext(["id","drawId","lineOrder","budgetCategory","categoryGroup","inThisDraw","initialBudget","revisedApprovedBudget",
                       "proposedAdjustmentsThisDraw","proposedBudget","currentDraw","totalPtdIncThisDrawAmount","totalPtdIncThisDrawPct","balanceToComplete"],
              [[6601+i, DRAW_ID, i+1, L[0],L[1],L[2],L[3],L[4],L[5],L[6],L[7],L[8],L[9],L[10]] for i,L in enumerate(LINES)]))
        print(csvtext(["id","drawId","approvalOrder","role","approverName","status","decisionDate","comments","actedBy","decisionSource"],
              [[6600+a[0], DRAW_ID]+list(a) for a in APPROVALS]))
        print(csvtext(["id","drawId","metricOrder","metric","modelAsOfDate","currentModelValue","currentProjection","variance","notes"],
              [[6600+i+1, DRAW_ID, i+1, q[0], QIU_ASOF, q[1],q[2],q[3],""] for i,q in enumerate(QIU)]))
    sys.exit(0 if ok else 1)

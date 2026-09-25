#!/usr/bin/env python3
"""Phase 5.6 training set for the Doc Center classification model over draw-package supporting documents.

Writes, under training/ at the repo root (gitignored, local only):

  training/pay_application/PA01_*.pdf ... PA08   GC pay applications, G702-style, three layout variants
  training/invoice/IN01_*.pdf ... IN08            vendor invoices (FF&E, design, engineering, testing, ...), three layouts
  training/lien_waiver/LW01_*.pdf ... LW08        conditional / unconditional, progress / final waivers, three layouts
  training/manifest.csv                           file, label (the category name the model must return)

and, at the repo root beside the demo package, the unrecognisable specimen used only for verification (never part of
the training set):

  THSV_Junk_UtilityNotice.pdf                     a hotel utility service-interruption notice

Every value is static (no randomness): parties, amounts, reference numbers, dates and the layout variant come from the
lists below, so a regenerated set is byte-identical. Every file is pure ASCII (write_pdf(ascii_only=True)), so it can
be placed on the instance with the Dev MCP's uploadDocument and checked by size.

Usage: python3 scripts/gen_training_set.py
"""
import csv
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from gen_draw_package import Page, write_pdf, money, label_block, ROOT  # noqa: E402

OUT = os.path.join(ROOT, "training")

# ------------------------------------------------------------------ pay applications ---------------------------------
PAY_APPS = [
    # contractor, address, owner, project, app no, period from, period to, app date, original, change orders,
    # completed to date, this period, layout
    ("Summit Ridge Builders", ["88 Eagle Road", "Edwards, CO 81632"], "Alpine Lodge Partners LP",
     "Alpine Lodge Keystone - Guest Room PIP", "7", "05/01/2026", "05/31/2026", "06/03/2026",
     24500000.00, 1830400.00, 14215750.00, 1184320.50, "A"),
    ("Harbor Point Construction", ["2200 Waterfront Drive", "Tampa, FL 33602"], "Bayview Hospitality Owner LLC",
     "Bayview Resort Tampa - Lobby and F&B Renovation", "11", "07/01/2026", "07/31/2026", "08/04/2026",
     18750000.00, 942000.00, 16020410.00, 873905.00, "B"),
    ("Granite Peak Contractors", ["5 Industrial Park Way", "Reno, NV 89502"], "Gateway Logistics Park II LLC",
     "Gateway Logistics Park Phase II - Building C Shell", "4", "03/01/2026", "03/31/2026", "04/02/2026",
     41200000.00, 0.00, 9870000.00, 3412760.25, "C"),
    ("Meridian Build Co.", ["1900 Market Street, Floor 6", "Philadelphia, PA 19103"], "Rittenhouse Suites Holdings LLC",
     "Rittenhouse Suites - Spa and Fitness Addition", "9", "08/01/2026", "08/31/2026", "09/05/2026",
     7650000.00, 312500.00, 6104880.00, 402115.75, "A"),
    ("Lakeshore General Contracting", ["400 North Lake Shore Drive", "Chicago, IL 60611"], "Lakefront Tower Owner LP",
     "Lakefront Tower Hotel - Floors 12-18 Conversion", "16", "09/01/2026", "09/30/2026", "10/02/2026",
     52800000.00, 4410000.00, 49015500.00, 2276430.00, "B"),
    ("Cedar & Stone Construction", ["71 Mill Street", "Burlington, VT 05401"], "Green Mountain Inn Partners",
     "Green Mountain Inn - Exterior Envelope Repairs", "3", "06/01/2026", "06/30/2026", "07/06/2026",
     3280000.00, 145600.00, 1377900.00, 518344.10, "C"),
    ("Northgate Construction Services", ["3100 Northgate Blvd", "Sacramento, CA 95833"], "Capitol Hotel Owner LLC",
     "Capitol Hotel Sacramento - MEP Replacement", "12", "04/01/2026", "04/30/2026", "05/04/2026",
     15400000.00, 1210750.00, 12880640.00, 961205.40, "A"),
    ("Blue Mesa Builders", ["820 Canyon Road", "Santa Fe, NM 87501"], "Canyon Road Resort LLC",
     "Canyon Road Resort - Casita Build-Out", "5", "02/01/2026", "02/28/2026", "03/03/2026",
     9900000.00, 0.00, 4155300.00, 1027880.00, "B"),
]


def pay_app_page(c):
    (gc, gc_addr, owner, project, app_no, p_from, p_to, app_date, original, change_orders, completed,
     this_period, layout) = c
    revised = original + change_orders
    retain_pct = {"A": 0.0, "B": 5.0, "C": 10.0}[layout]
    retainage = round(completed * retain_pct / 100.0, 2)
    earned = round(completed - retainage, 2)
    previous = round(earned - this_period, 2)
    balance = round(revised - earned, 2)
    p = Page()
    if layout == "A":
        p.rect(36, 36, 540, 34, fill=0.93, stroke=None)
        p.text(48, 52, "APPLICATION AND CERTIFICATE FOR PAYMENT", 14, True)
        p.text(48, 64, "Contractor's application for payment - G702-style summary", 8, gray=0.35)
    elif layout == "B":
        p.text(306, 54, "CONTRACTOR'S APPLICATION FOR PAYMENT", 15, True, align="center")
        p.text(306, 68, "Application and Certificate for Payment", 9, align="center", gray=0.35)
        p.line(36, 76, 576, 76, 1.2)
    else:
        p.text(48, 50, "PAYMENT APPLICATION", 17, True)
        p.text(48, 64, f"Application No. {app_no}  -  Progress billing", 9, gray=0.35)
        p.rect(400, 36, 176, 34, fill=None, stroke=0.0)
        p.text(488, 50, "APPLICATION NO.", 7, True, align="center", gray=0.35)
        p.text(488, 63, app_no, 11, True, align="center")
    label_block(p, 48, 96, "TO OWNER", [owner] + ["Attn: Asset Management"])
    label_block(p, 318, 96, "FROM CONTRACTOR", [gc] + gc_addr)
    label_block(p, 48, 150, "PROJECT", [project])
    p.line(36, 180, 576, 180)
    facts = [("APPLICATION NO.", app_no), ("PERIOD", f"{p_from} - {p_to}"), ("APPLICATION DATE", app_date)]
    for (k, v), x in zip(facts, [48, 170, 330]):
        p.text(x, 194, k, 7, True, gray=0.35)
        p.text(x, 206, v, 9, True)
    p.line(36, 216, 576, 216)
    rows = [
        ("1.", "ORIGINAL CONTRACT SUM", original),
        ("2.", "NET CHANGE BY CHANGE ORDERS", change_orders),
        ("3.", "CONTRACT SUM TO DATE (Line 1 + 2)", revised),
        ("4.", "TOTAL COMPLETED & STORED TO DATE", completed),
        ("5.", f"RETAINAGE ({retain_pct:.0f}% of completed work)", retainage),
        ("6.", "TOTAL EARNED LESS RETAINAGE", earned),
        ("7.", "LESS PREVIOUS CERTIFICATES FOR PAYMENT", previous),
        ("8.", "CURRENT PAYMENT DUE", this_period),
        ("9.", "BALANCE TO FINISH, INCLUDING RETAINAGE", balance),
    ]
    y = 240 if layout != "C" else 250
    step = 22 if layout == "A" else 20
    for n, label, value in rows:
        bold = n == "8."
        if bold:
            p.rect(40, y - 12, 532, 18, fill=0.90, stroke=0.0, lw=0.8)
        p.text(48, y, n, 9, bold)
        p.text(66, y, label, 9, bold)
        p.text(564, y, money(value), 10 if bold else 9, bold, align="right")
        if layout != "B":
            p.line(48, y + 5, 564, y + 5, 0.3, gray=0.75)
        y += step
    y += 16
    p.text(48, y, "CONTRACTOR'S CERTIFICATION", 9, True)
    y = p.wrap(48, y + 14, 510,
               "The undersigned Contractor certifies that the Work covered by this Application for Payment has been "
               "completed in accordance with the Contract Documents, that all amounts have been paid by the Contractor "
               "for Work for which previous Certificates for Payment were issued, and that current payment shown herein "
               "is now due.")
    p.text(48, y + 12, f"CONTRACTOR: {gc}", 8, True)
    p.line(48, y + 34, 280, y + 34, 0.5)
    p.text(48, y + 44, "By: Project Manager", 8)
    p.text(230, y + 44, f"Date: {app_date}", 8)
    p.text(318, y + 12, "ARCHITECT'S CERTIFICATE FOR PAYMENT", 8, True)
    p.text(318, y + 26, "AMOUNT CERTIFIED", 8)
    p.rect(420, y + 16, 144, 14, fill=None, stroke=0.0)
    p.text(306, 764, "This application is not negotiable. Payment is due only to the Contractor named herein.", 7,
           align="center", gray=0.35)
    return p, this_period


# ------------------------------------------------------------------ invoices -----------------------------------------
INVOICES = [
    # vendor, address, invoice no, date, bill-to, items [(desc, qty, rate)], layout
    ("Aspen Hospitality Furnishings", ["2400 Blake Street", "Denver, CO 80205"], "AHF-40913", "06/12/2026",
     "Alpine Lodge Partners LP", [("Guest room lounge chairs, model AL-22", 64, 685.00),
                                  ("Bedside tables, walnut finish", 128, 312.50)], "A"),
    ("Kessler MEP Engineers", ["55 Harbor Street, Suite 900", "Boston, MA 02210"], "KME-2026-0331", "08/29/2026",
     "Bayview Hospitality Owner LLC", [("MEP engineering services - August 2026", 1, 22400.00),
                                       ("Site visits and field reports (6)", 6, 950.00)], "B"),
    ("Front Range Materials Testing", ["1175 Tejon Street", "Colorado Springs, CO 80903"], "FRMT-18852", "04/15/2026",
     "Gateway Logistics Park II LLC", [("Concrete cylinder testing", 48, 65.00),
                                       ("Compaction testing - technician hours", 36, 95.00)], "C"),
    ("Greenline Landscape Architecture", ["300 South Congress Avenue", "Austin, TX 78704"], "GLA-7725", "09/10/2026",
     "Rittenhouse Suites Holdings LLC", [("Landscape design development", 1, 14800.00)], "A"),
    ("Studio Marlowe Interiors", ["145 West 28th Street", "New York, NY 10001"], "SMI-26-114", "10/07/2026",
     "Lakefront Tower Owner LP", [("Interior design services - construction documents", 1, 36250.00),
                                  ("Sample procurement and finish boards", 1, 2180.40)], "B"),
    ("Sentinel Integrated Security", ["9 Commerce Court", "Portland, ME 04101"], "SIS-005571", "07/18/2026",
     "Green Mountain Inn Partners", [("Access control readers, installed", 22, 1140.00),
                                     ("Security system programming", 16, 145.00)], "C"),
    ("Summit Signage Co.", ["610 Industrial Way", "Boise, ID 83706"], "SSC-3309", "05/21/2026",
     "Capitol Hotel Owner LLC", [("Exterior monument sign, fabricated and installed", 1, 18900.00),
                                 ("Wayfinding signs, interior", 34, 210.00)], "A"),
    ("Peak Permit Services", ["2 Plaza Road", "Santa Fe, NM 87505"], "PPS-1188", "03/09/2026",
     "Canyon Road Resort LLC", [("Permit expediting - building and fire", 1, 6500.00),
                                ("Municipal filing fees (reimbursable)", 1, 3874.25)], "C"),
]


def invoice_page(c):
    vendor, addr, inv_no, inv_date, bill_to, items, layout = c
    total = round(sum(q * r for _, q, r in items), 2)
    p = Page()
    if layout == "A":
        p.text(48, 60, vendor, 16, True)
        for i, ln in enumerate(addr):
            p.text(48, 76 + i * 11, ln, 8.5, gray=0.35)
        p.text(564, 60, "INVOICE", 20, True, align="right")
        meta_x, meta_y = 564, 84
    elif layout == "B":
        p.rect(36, 36, 540, 40, fill=0.92, stroke=None)
        p.text(48, 60, "INVOICE", 18, True)
        p.text(564, 56, vendor, 11, True, align="right")
        p.text(564, 68, ", ".join(addr), 8, align="right", gray=0.35)
        meta_x, meta_y = 564, 96
    else:
        p.text(306, 56, vendor.upper(), 14, True, align="center")
        p.text(306, 70, " | ".join(addr), 8, align="center", gray=0.35)
        p.line(36, 80, 576, 80, 1.0)
        p.text(48, 100, "TAX INVOICE", 13, True)
        meta_x, meta_y = 564, 100
    for i, (k, v) in enumerate([("Invoice No.", inv_no), ("Invoice Date", inv_date), ("Terms", "Net 30")]):
        p.text(meta_x - 94, meta_y + i * 12, k, 8.5, gray=0.35, align="right")
        p.text(meta_x, meta_y + i * 12, v, 8.5, True, align="right")
    label_block(p, 48, 150, "BILL TO", [bill_to, "Accounts Payable"])
    y = 206
    p.rect(40, y, 532, 18, fill=0.90, stroke=None)
    p.text(48, y + 12, "DESCRIPTION", 8, True)
    p.text(390, y + 12, "QTY", 8, True, align="right")
    p.text(470, y + 12, "RATE", 8, True, align="right")
    p.text(564, y + 12, "AMOUNT", 8, True, align="right")
    y += 36
    for desc, q, r in items:
        p.text(48, y, desc, 9)
        p.text(390, y, f"{q:g}", 9, align="right")
        p.text(470, y, money(r), 9, align="right")
        p.text(564, y, money(round(q * r, 2)), 9, align="right")
        p.line(48, y + 6, 564, y + 6, 0.3, gray=0.8)
        y += 22
    y += 12
    p.rect(360, y - 4, 212, 22, fill=0.90, stroke=0.0, lw=0.8)
    p.text(470, y + 11, "TOTAL DUE", 10, True, align="right")
    p.text(564, y + 11, money(total), 11, True, align="right")
    p.text(48, y + 60, "Remittance", 8, True, gray=0.35)
    p.text(48, y + 72, f"Please reference invoice {inv_no} with payment to {vendor}.", 8.5)
    p.text(306, 764, "Thank you for your business.", 8, align="center", gray=0.35)
    return p, total


# ------------------------------------------------------------------ lien waivers -------------------------------------
WAIVERS = [
    # kind, claimant, customer, job, through date, amount, layout
    ("CONDITIONAL WAIVER AND RELEASE ON PROGRESS PAYMENT", "Summit Ridge Builders", "Alpine Lodge Partners LP",
     "Alpine Lodge Keystone", "05/31/2026", 1184320.50, "A"),
    ("UNCONDITIONAL WAIVER AND RELEASE ON PROGRESS PAYMENT", "Harbor Point Construction",
     "Bayview Hospitality Owner LLC", "Bayview Resort Tampa", "06/30/2026", 845210.00, "B"),
    ("CONDITIONAL WAIVER AND RELEASE ON FINAL PAYMENT", "Front Range Materials Testing",
     "Gateway Logistics Park II LLC", "Gateway Logistics Park Phase II", "04/30/2026", 6540.00, "C"),
    ("PARTIAL CONDITIONAL LIEN WAIVER", "Meridian Build Co.", "Rittenhouse Suites Holdings LLC",
     "Rittenhouse Suites", "08/31/2026", 402115.75, "A"),
    ("UNCONDITIONAL WAIVER AND RELEASE ON FINAL PAYMENT", "Studio Marlowe Interiors", "Lakefront Tower Owner LP",
     "Lakefront Tower Hotel", "09/30/2026", 38430.40, "B"),
    ("CONDITIONAL WAIVER AND RELEASE ON PROGRESS PAYMENT", "Cedar & Stone Construction",
     "Green Mountain Inn Partners", "Green Mountain Inn", "06/30/2026", 518344.10, "C"),
    ("SUBCONTRACTOR'S CONDITIONAL LIEN WAIVER", "Valley Electric Inc.", "Capitol Hotel Owner LLC",
     "Capitol Hotel Sacramento", "04/30/2026", 211480.00, "A"),
    ("UNCONDITIONAL WAIVER AND RELEASE ON PROGRESS PAYMENT", "Blue Mesa Builders", "Canyon Road Resort LLC",
     "Canyon Road Resort", "02/28/2026", 1027880.00, "B"),
]


def waiver_page(c):
    kind, claimant, customer, job, through, amount, layout = c
    conditional = "CONDITIONAL" in kind and "UNCONDITIONAL" not in kind
    p = Page()
    if layout == "A":
        p.rect(36, 36, 540, 34, fill=0.93, stroke=None)
        p.text(306, 58, kind, 12, True, align="center")
    elif layout == "B":
        p.text(306, 56, kind, 12, True, align="center")
        p.line(96, 64, 516, 64, 1.0)
    else:
        p.text(48, 56, "LIEN WAIVER", 16, True)
        p.text(48, 70, kind.title(), 9, gray=0.35)
    y = 100
    for k, v in [("Name of Claimant", claimant), ("Name of Customer", customer), ("Job Location", job),
                 ("Through Date", through)]:
        p.text(48, y, k, 8, True, gray=0.35)
        p.text(190, y, v, 9)
        p.line(190, y + 4, 564, y + 4, 0.3, gray=0.75)
        y += 22
    y += 10
    body = ("This document waives and releases lien, stop payment notice, and payment bond rights the claimant has for "
            "labor and service provided, and equipment and material delivered, to the customer on this job through the "
            "Through Date of this document.")
    if conditional:
        body += (" This document is effective only on the claimant's receipt of payment from the financial institution "
                 "on which the following check is drawn.")
    else:
        body += (" The claimant has been paid in full for the amount stated below. Notice: this document waives rights "
                 "unconditionally and states that you have been paid for giving up those rights.")
    y = p.wrap(48, y, 516, body, 9, 12.5)
    y += 10
    p.text(48, y, "Amount of Payment", 8, True, gray=0.35)
    p.text(190, y, money(amount), 9)
    p.line(190, y + 4, 564, y + 4, 0.3, gray=0.75)
    y += 30
    p.text(48, y, "Exceptions", 10, True)
    y = p.wrap(48, y + 16, 516, "This document does not affect retentions, extras for which the claimant has not "
                                "received payment, or disputed claims for additional work.", 9, 12.5)
    y += 18
    p.line(48, y + 26, 300, y + 26, 0.5)
    p.text(48, y + 36, "Claimant's Signature", 8)
    p.text(340, y + 36, "Date of Signature", 8)
    p.text(306, 764, "Lien waiver - keep with the payment records for this job.", 7, align="center", gray=0.35)
    return p


# ------------------------------------------------------------------ junk specimen ------------------------------------
def junk_page():
    p = Page()
    p.text(48, 58, "HOLY CROSS VALLEY ELECTRIC COOPERATIVE", 13, True)
    p.text(48, 72, "Customer notice - scheduled service interruption", 9, gray=0.35)
    p.line(36, 82, 576, 82, 1.0)
    label_block(p, 48, 104, "SERVICE ADDRESS", ["Tamarack Hotel & Spa Vail", "715 West Lionshead Circle",
                                                "Vail, CO 81657"])
    label_block(p, 318, 104, "ACCOUNT", ["Account 4471-0932-18", "Meter 88-20417", "Rate: Large commercial"])
    y = p.wrap(48, 180, 516,
               "To complete replacement of a distribution transformer serving the Lionshead area, electric service at "
               "the address above will be interrupted on Tuesday, November 10, 2026, from 1:00 AM to 4:00 AM Mountain "
               "Time. Crews will restore service as soon as the work is complete. We recommend that you shut down "
               "sensitive equipment before the interruption and confirm that emergency lighting and generator transfer "
               "switches are operational.", 9.5, 13)
    y = p.wrap(48, y + 10, 516,
               "No action is required and there is no charge for this work. Your next statement will show your normal "
               "usage. If you have questions or need to reschedule for a critical event, call our commercial service "
               "desk at 970-555-0142, Monday through Friday, 7:00 AM to 6:00 PM.", 9.5, 13)
    p.text(48, y + 20, "Thank you for your patience while we improve reliability in your area.", 9, True)
    p.text(306, 764, "This notice is for information only. It is not a bill.", 7, align="center", gray=0.35)
    return p


def main():
    rows = []
    for sub in ("pay_application", "invoice", "lien_waiver"):
        os.makedirs(os.path.join(OUT, sub), exist_ok=True)
    for i, c in enumerate(PAY_APPS, 1):
        page, due = pay_app_page(c)
        name = f"PA{i:02d}_{c[0].split()[0]}_App{c[4]}.pdf"
        write_pdf(os.path.join(OUT, "pay_application", name), page, f"Application for Payment No. {c[4]}", True)
        rows.append((f"pay_application/{name}", "Pay Application", f"{due:.2f}"))
    for i, c in enumerate(INVOICES, 1):
        page, total = invoice_page(c)
        name = f"IN{i:02d}_{c[0].split()[0]}_{c[2]}.pdf"
        write_pdf(os.path.join(OUT, "invoice", name), page, f"Invoice {c[2]}", True)
        rows.append((f"invoice/{name}", "Invoice", f"{total:.2f}"))
    for i, c in enumerate(WAIVERS, 1):
        name = f"LW{i:02d}_{c[1].split()[0]}.pdf"
        write_pdf(os.path.join(OUT, "lien_waiver", name), waiver_page(c), c[0].title(), True)
        rows.append((f"lien_waiver/{name}", "Lien Waiver", ""))
    with open(os.path.join(OUT, "manifest.csv"), "w", newline="") as f:
        w = csv.writer(f)
        w.writerow(["file", "label", "figure"])
        w.writerows(rows)
    junk = os.path.join(ROOT, "THSV_Junk_UtilityNotice.pdf")
    n = write_pdf(junk, junk_page(), "Scheduled service interruption notice", True)
    counts = {lab: sum(1 for r in rows if r[1] == lab) for lab in ("Pay Application", "Invoice", "Lien Waiver")}
    print(f"training set in {OUT}: " + ", ".join(f"{k} {v}" for k, v in counts.items()) + f" ({len(rows)} files)")
    print(f"junk specimen: {os.path.basename(junk)} ({n:,} bytes; not part of the training set)")


if __name__ == "__main__":
    main()

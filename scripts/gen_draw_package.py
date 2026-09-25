#!/usr/bin/env python3
"""Phase 5.5 demo package: the supporting documents that arrive with draw #67's budget template.

Reads THSV_Draw67_Budget_Template.xlsx (repo root, local only) and writes four single-page PDFs beside it (the repo
gitignores *.pdf, so they stay local; keep them with the templates):

  THSV_Draw67_PayApp_G702.pdf           GC pay application, G702-style. Current Payment Due = the template's
                                        Hard Costs line, current draw (PAY_APP_TIE_LINE), to the cent.
  THSV_Draw67_PayApp_G702_mismatch.pdf  identical except Current Payment Due is off by MISMATCH_DELTA.
  THSV_Draw67_Invoice_AlderFinch.pdf    design-vendor invoice. Total = the template's INVOICE_TIE_LINE, current draw.
  THSV_Draw67_LienWaiver_Conditional.pdf conditional progress waiver from the GC, current period. Its role is presence.

Every figure that must tie is READ FROM THE TEMPLATE, so the tie is exact by construction; the other figures on the
pay application are the same line's budget columns (initial, revised, PTD, balance), so the form's arithmetic is
consistent. Layouts are simple, clean and form-like: recognisable as a G702-style application, not a replica of the
AIA form. Pure Python (no PDF library on this machine): standard Helvetica fonts, WinAnsi text, rules and boxes.

Usage: python3 scripts/gen_draw_package.py [path/to/template.xlsx]
"""
import html
import os
import re
import sys
import zipfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TEMPLATE = os.path.join(ROOT, "THSV_Draw67_Budget_Template.xlsx")

PAY_APP_TIE_LINE = "Hard Costs"          # the pay application ties to this budget line's Current Draw
INVOICE_TIE_LINE = "A&E - Architectural"  # the invoice ties to this soft-cost line's Current Draw
MISMATCH_DELTA = 37500.00                 # the mismatch pay application's Current Payment Due is this much higher

GC = "Stonebridge Construction Group"
GC_ADDR = ["1450 Frontage Road, Suite 200", "Avon, CO 81620"]
OWNER = "THSV Holdings LLC"
OWNER_CO = "c/o Vail Peak Management LLC (Property Manager)"
OWNER_ADDR = ["715 West Lionshead Circle", "Vail, CO 81657"]
PROJECT = "Tamarack Hotel & Spa Vail - PIP Renovation"
ARCHITECT = "Alder & Finch Architects, LLP"
ARCH_ADDR = ["410 Wazee Street, Suite 300", "Denver, CO 80202"]
APP_NO = "14"
PERIOD_FROM = "10/01/2026"
PERIOD_TO = "10/31/2026"           # the template's funding date is 11/16/2026; this is the billing period before it
APP_DATE = "11/02/2026"
CONTRACT_DATE = "03/15/2024"
SIGNER = "Daniel Reyes, Project Executive"
INVOICE_NO = "AF-2026-1087"
INVOICE_DATE = "10/31/2026"


# ---------------------------------------------------------------- template -----------------------------------------
def read_sheet(path):
    """First worksheet as {row: {col: value}} (raw cell values; numbers as text)."""
    z = zipfile.ZipFile(path)
    ss = []
    if "xl/sharedStrings.xml" in z.namelist():
        x = z.read("xl/sharedStrings.xml").decode()
        for si in re.findall(r"<si>(.*?)</si>", x, re.S):
            ss.append(html.unescape("".join(re.findall(r"<t[^>]*>(.*?)</t>", si, re.S))))
    sheet = sorted(n for n in z.namelist() if n.startswith("xl/worksheets/sheet"))[0]
    rows = {}
    for c in re.finditer(r'<c r="([A-Z]+)(\d+)"([^>]*?)(?:/>|>(.*?)</c>)', z.read(sheet).decode(), re.S):
        col, row, attrs, inner = c.groups()
        if inner is None:
            continue
        v = re.search(r"<v>(.*?)</v>", inner, re.S)
        isv = re.search(r"<is>.*?<t[^>]*>(.*?)</t>", inner, re.S)
        val = None
        if 't="s"' in attrs and v:
            val = ss[int(v.group(1))]
        elif isv:
            val = html.unescape(isv.group(1))
        elif v:
            val = v.group(1)
        if val not in (None, ""):
            rows.setdefault(int(row), {})[col] = val
    return rows


def budget_line(rows, category):
    """The named budget line as {column heading: float} (blank cells as 0)."""
    head_row = next(r for r in sorted(rows) if rows[r].get("A", "").strip().lower() == "budget category")
    headings = {col: text.strip() for col, text in rows[head_row].items()}
    line_row = next(r for r in sorted(rows) if r > head_row and rows[r].get("A", "").strip() == category)
    out = {}
    for col, heading in headings.items():
        if col == "A":
            continue
        raw = rows[line_row].get(col, "0")
        try:
            out[heading] = round(float(raw), 2)
        except ValueError:
            out[heading] = 0.0
    return out


def money(v):
    s = f"{abs(v):,.2f}"
    return f"(${s})" if v < 0 else f"${s}"


# ---------------------------------------------------------------- PDF writer ---------------------------------------
_HELV = [278, 278, 355, 556, 556, 889, 667, 191, 333, 333, 389, 584, 278, 333, 278, 278] + [556] * 10 + \
        [278, 278, 584, 584, 584, 556, 1015, 667, 667, 722, 722, 667, 611, 778, 722, 278, 500, 667, 556, 833, 722,
         778, 667, 778, 722, 667, 611, 722, 667, 944, 667, 667, 611, 278, 278, 278, 469, 556, 333, 556, 556, 500,
         556, 556, 278, 556, 556, 222, 222, 500, 222, 833, 556, 556, 556, 556, 333, 500, 278, 556, 500, 722, 500,
         500, 500, 334, 260, 334, 584]
_HELVB = [278, 333, 474, 556, 556, 889, 722, 238, 333, 333, 389, 584, 278, 333, 278, 278] + [556] * 10 + \
         [333, 333, 584, 584, 584, 611, 975, 722, 722, 722, 722, 667, 611, 778, 722, 278, 556, 722, 611, 833, 722,
          778, 667, 778, 722, 667, 611, 722, 667, 944, 667, 667, 611, 333, 278, 333, 584, 556, 333, 556, 611, 556,
          611, 556, 333, 611, 611, 278, 278, 556, 278, 889, 611, 611, 611, 611, 389, 556, 333, 611, 556, 778, 556,
          556, 500, 389, 280, 389, 584]


def text_width(s, size, bold=False):
    table = _HELVB if bold else _HELV
    return sum(table[ord(ch) - 32] if 32 <= ord(ch) <= 126 else 556 for ch in s) * size / 1000.0


class Page:
    """One Letter page; y measured from the top (converted on output)."""
    W, H = 612, 792

    def __init__(self):
        self.ops = []

    def _y(self, y):
        return self.H - y

    def text(self, x, y, s, size=9, bold=False, align="left", gray=0.0):
        if align == "right":
            x = x - text_width(s, size, bold)
        elif align == "center":
            x = x - text_width(s, size, bold) / 2
        esc = s.replace("\\", "\\\\").replace("(", "\\(").replace(")", "\\)")
        self.ops.append(f"{gray:.2f} g BT /{'F2' if bold else 'F1'} {size} Tf {x:.2f} {self._y(y):.2f} Td ({esc}) Tj ET")

    def line(self, x1, y1, x2, y2, w=0.6, gray=0.0):
        self.ops.append(f"{gray:.2f} G {w} w {x1:.2f} {self._y(y1):.2f} m {x2:.2f} {self._y(y2):.2f} l S")

    def rect(self, x, y, w, h, fill=None, stroke=0.0, lw=0.6):
        if fill is not None:
            self.ops.append(f"{fill:.2f} g {x:.2f} {self._y(y + h):.2f} {w:.2f} {h:.2f} re f")
        if stroke is not None:
            self.ops.append(f"{stroke:.2f} G {lw} w {x:.2f} {self._y(y + h):.2f} {w:.2f} {h:.2f} re S")

    def wrap(self, x, y, width, s, size=8.5, lead=11.5, bold=False):
        """Left-aligned paragraph; returns the y below it."""
        words, line = s.split(), ""
        for w in words:
            cand = (line + " " + w).strip()
            if text_width(cand, size, bold) > width and line:
                self.text(x, y, line, size, bold)
                y += lead
                line = w
            else:
                line = cand
        if line:
            self.text(x, y, line, size, bold)
            y += lead
        return y


def write_pdf(path, page, title):
    content = "\n".join(page.ops).encode("latin-1")
    objs = [
        b"<< /Type /Catalog /Pages 2 0 R >>",
        b"<< /Type /Pages /Kids [3 0 R] /Count 1 >>",
        b"<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] /Resources << /Font << /F1 4 0 R /F2 5 0 R >> >> /Contents 6 0 R >>",
        b"<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica /Encoding /WinAnsiEncoding >>",
        b"<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica-Bold /Encoding /WinAnsiEncoding >>",
        b"<< /Length " + str(len(content)).encode() + b" >>\nstream\n" + content + b"\nendstream",
        b"<< /Title (" + title.encode("latin-1") + b") /Producer (starwood-fund-ops gen_draw_package.py) >>",
    ]
    out = bytearray(b"%PDF-1.4\n%\xe2\xe3\xcf\xd3\n")
    offsets = []
    for i, body in enumerate(objs, start=1):
        offsets.append(len(out))
        out += f"{i} 0 obj\n".encode() + body + b"\nendobj\n"
    xref = len(out)
    out += f"xref\n0 {len(objs) + 1}\n0000000000 65535 f \n".encode()
    for off in offsets:
        out += f"{off:010d} 00000 n \n".encode()
    out += f"trailer\n<< /Size {len(objs) + 1} /Root 1 0 R /Info 7 0 R >>\nstartxref\n{xref}\n%%EOF\n".encode()
    with open(path, "wb") as f:
        f.write(out)
    return len(out)


# ---------------------------------------------------------------- documents ----------------------------------------
def label_block(p, x, y, label, lines, width=250):
    p.text(x, y, label, 7, True, gray=0.35)
    for i, ln in enumerate(lines):
        p.text(x, y + 11 + i * 11, ln, 9)


def pay_application(hc, current_payment_due):
    p = Page()
    p.rect(36, 36, 540, 34, fill=0.93, stroke=None)
    p.text(48, 52, "APPLICATION AND CERTIFICATE FOR PAYMENT", 14, True)
    p.text(48, 64, "Contractor's application for payment - G702-style summary", 8, gray=0.35)
    p.text(564, 52, "PAGE 1 OF 1", 8, True, align="right", gray=0.35)

    label_block(p, 48, 92, "TO OWNER", [OWNER, OWNER_CO] + OWNER_ADDR)
    label_block(p, 318, 92, "FROM CONTRACTOR", [GC] + GC_ADDR)
    label_block(p, 48, 160, "PROJECT", [PROJECT, "Vail, Colorado"])
    label_block(p, 318, 160, "VIA ARCHITECT", [ARCHITECT] + ARCH_ADDR)
    p.line(36, 200, 576, 200)
    facts = [("APPLICATION NO.", APP_NO), ("PERIOD", f"{PERIOD_FROM} - {PERIOD_TO}"), ("APPLICATION DATE", APP_DATE),
             ("CONTRACT DATE", CONTRACT_DATE), ("CONTRACT FOR", "General construction")]
    for (k, v), x in zip(facts, [48, 138, 282, 384, 476]):
        p.text(x, 214, k, 7, True, gray=0.35)
        p.text(x, 226, v, 9, True)
    p.line(36, 236, 576, 236)

    p.text(48, 256, "CONTRACTOR'S APPLICATION FOR PAYMENT", 10, True)
    p.text(48, 268, "Application is made for payment, as shown below, in connection with the Contract.", 8, gray=0.35)
    original = hc["Initial Budget"]
    revised = hc["Revised Approved Budget"]
    completed = hc["Total PTD inc. This Draw ($)"]
    retainage = 0.0
    earned = completed - retainage
    previous = round(completed - hc["Current Draw"], 2)  # previous certificates: the correct application's figure
    rows = [
        ("1.", "ORIGINAL CONTRACT SUM", original),
        ("2.", "NET CHANGE BY CHANGE ORDERS", revised - original),
        ("3.", "CONTRACT SUM TO DATE (Line 1 + 2)", revised),
        ("4.", "TOTAL COMPLETED & STORED TO DATE", completed),
        ("5.", "RETAINAGE (0% - released per Change Order 38)", retainage),
        ("6.", "TOTAL EARNED LESS RETAINAGE (Line 4 less Line 5)", earned),
        ("7.", "LESS PREVIOUS CERTIFICATES FOR PAYMENT", previous),
        ("8.", "CURRENT PAYMENT DUE", current_payment_due),
        ("9.", "BALANCE TO FINISH, INCLUDING RETAINAGE (Line 3 less Line 6)", revised - earned),
    ]
    y = 290
    for n, label, value in rows:
        bold = n == "8."
        if bold:
            p.rect(40, y - 12, 532, 18, fill=0.90, stroke=0.0, lw=0.8)
        p.text(48, y, n, 9, bold)
        p.text(66, y, label, 9, bold)
        p.text(564, y, money(value), 10 if bold else 9, bold, align="right")
        p.line(48, y + 5, 564, y + 5, 0.3, gray=0.75)
        y += 22

    y += 8
    p.text(48, y, "CHANGE ORDER SUMMARY", 8, True, gray=0.35)
    p.text(318, y, "ADDITIONS", 8, True, gray=0.35)
    p.text(564, y, "DEDUCTIONS", 8, True, gray=0.35, align="right")
    p.text(48, y + 12, "Total approved to date (Change Orders 1-38)", 8)
    p.text(430, y + 12, money(revised - original), 8, align="right")
    p.text(564, y + 12, money(0), 8, align="right")
    y += 34

    p.line(36, y, 576, y)
    p.text(48, y + 16, "CONTRACTOR'S CERTIFICATION", 9, True)
    y = p.wrap(48, y + 30, 240,
               "The undersigned Contractor certifies that, to the best of the Contractor's knowledge, information and "
               "belief, the Work covered by this Application has been completed in accordance with the Contract "
               "Documents, that all amounts have been paid by the Contractor for Work for which previous Certificates "
               "for Payment were issued, and that current payment shown herein is now due.")
    p.text(48, y + 14, f"CONTRACTOR: {GC}", 8, True)
    p.line(48, y + 36, 280, y + 36, 0.5)
    p.text(48, y + 46, f"By: {SIGNER}", 8)
    p.text(230, y + 46, f"Date: {APP_DATE}", 8)

    ay = y - 60 if y > 640 else y - 72
    ay = max(ay, 526)
    p.text(318, ay + 16 - 0, "ARCHITECT'S CERTIFICATE FOR PAYMENT", 9, True)
    p.wrap(318, ay + 30, 246,
           "In accordance with the Contract Documents, based on evaluations of the Work and the data comprising this "
           "application, the Architect certifies to the Owner that the Work has progressed as indicated.")
    p.text(318, ay + 88, "AMOUNT CERTIFIED", 8, True)
    p.rect(420, ay + 77, 144, 16, fill=None, stroke=0.0)
    p.text(318, ay + 110, f"ARCHITECT: {ARCHITECT}", 8, True)
    p.line(318, ay + 132, 564, ay + 132, 0.5)
    p.text(318, ay + 142, "By:", 8)
    p.text(480, ay + 142, "Date:", 8)
    p.text(306, 764, "This application is not negotiable. The amount certified is payable only to the Contractor named herein.", 7,
           align="center", gray=0.35)
    return p


def invoice(total):
    p = Page()
    p.text(48, 60, ARCHITECT, 16, True)
    for i, ln in enumerate(ARCH_ADDR + ["accounts@alderfinch.example"]):
        p.text(48, 76 + i * 11, ln, 8.5, gray=0.35)
    p.text(564, 60, "INVOICE", 20, True, align="right")
    for i, (k, v) in enumerate([("Invoice No.", INVOICE_NO), ("Invoice Date", INVOICE_DATE), ("Terms", "Net 30"),
                                ("Project No.", "2319")]):
        p.text(470, 82 + i * 12, k, 8.5, gray=0.35, align="right")
        p.text(564, 82 + i * 12, v, 8.5, True, align="right")
    p.line(36, 140, 576, 140)
    label_block(p, 48, 158, "BILL TO", [OWNER, OWNER_CO] + OWNER_ADDR)
    label_block(p, 318, 158, "PROJECT", [PROJECT, "Architectural services - construction phase",
                                          f"Service period {PERIOD_FROM} - {PERIOD_TO}"])
    y = 236
    p.rect(40, y, 532, 18, fill=0.90, stroke=None)
    p.text(48, y + 12, "DESCRIPTION", 8, True)
    p.text(564, y + 12, "AMOUNT", 8, True, align="right")
    items = [("Construction administration services - October 2026", 38400.00),
             ("Design coordination, structural / architectural interface (ARUP / SHA)", 17560.00)]
    fixed = sum(v for _, v in items)
    if total > fixed:
        items.append(("Reimbursable expenses - travel, printing, courier", round(total - fixed, 2)))
    else:
        items = [("Architectural services - October 2026", total)]
    y += 36
    for desc, amt in items:
        p.text(48, y, desc, 9)
        p.text(564, y, money(amt), 9, align="right")
        p.line(48, y + 6, 564, y + 6, 0.3, gray=0.8)
        y += 22
    y += 10
    for k, v, b in [("Subtotal", total, False), ("Sales tax", 0.0, False)]:
        p.text(470, y, k, 9, align="right")
        p.text(564, y, money(v), 9, align="right")
        y += 16
    p.rect(360, y - 4, 212, 22, fill=0.90, stroke=0.0, lw=0.8)
    p.text(470, y + 11, "TOTAL DUE", 10, True, align="right")
    p.text(564, y + 11, money(total), 11, True, align="right")
    y += 60
    p.text(48, y, "Remittance", 8, True, gray=0.35)
    p.text(48, y + 12, f"Please remit to {ARCHITECT}, {ARCH_ADDR[0]}, {ARCH_ADDR[1]}.", 8.5)
    p.text(48, y + 24, f"Reference invoice {INVOICE_NO} with payment. Questions: accounts@alderfinch.example", 8.5)
    p.text(306, 764, "Thank you for your business.", 8, align="center", gray=0.35)
    return p


def lien_waiver(amount):
    p = Page()
    p.rect(36, 36, 540, 34, fill=0.93, stroke=None)
    p.text(306, 58, "CONDITIONAL WAIVER AND RELEASE ON PROGRESS PAYMENT", 13, True, align="center")
    y = 100
    for k, v in [("Name of Claimant", GC), ("Name of Customer", f"{OWNER}, {OWNER_CO}"),
                 ("Job Location", f"{PROJECT}, Vail, Colorado"), ("Owner", OWNER), ("Through Date", PERIOD_TO)]:
        p.text(48, y, k, 8, True, gray=0.35)
        p.text(190, y, v, 9)
        p.line(190, y + 4, 564, y + 4, 0.3, gray=0.75)
        y += 22
    y += 10
    p.text(48, y, "Conditional Waiver and Release", 10, True)
    y = p.wrap(48, y + 16, 516,
               "This document waives and releases lien, stop payment notice, and payment bond rights the claimant has "
               "for labor and service provided, and equipment and material delivered, to the customer on this job "
               "through the Through Date of this document. Rights based upon labor or service provided, or equipment "
               "or material delivered, pursuant to a written change order that has been fully executed by the parties "
               "prior to the date that this document is signed by the claimant, are waived and released by this "
               "document, unless listed as an Exception below. This document is effective only on the claimant's "
               "receipt of payment from the financial institution on which the following check is drawn:", 9, 12.5)
    y += 8
    for k, v in [("Maker of Check", OWNER), ("Amount of Check", money(amount)),
                 ("Check Payable to", GC)]:
        p.text(48, y, k, 8, True, gray=0.35)
        p.text(190, y, v, 9)
        p.line(190, y + 4, 564, y + 4, 0.3, gray=0.75)
        y += 22
    y += 8
    p.text(48, y, "Exceptions", 10, True)
    y = p.wrap(48, y + 16, 516, "This document does not affect the following: retentions; extras for which the claimant "
                                "has not received payment; disputed claims for additional work in the amount of: $0.00.",
               9, 12.5)
    y += 18
    p.text(48, y, "Signature", 10, True)
    p.line(48, y + 30, 300, y + 30, 0.5)
    p.text(48, y + 40, f"Claimant's Signature - {SIGNER}", 8)
    p.text(340, y + 40, f"Date of Signature: {APP_DATE}", 8)
    p.text(48, y + 58, f"Claimant's Title: Project Executive, {GC}", 8)
    p.text(306, 764, "Conditional waiver - effective only upon receipt of the payment described above.", 7,
           align="center", gray=0.35)
    return p


def main():
    template = sys.argv[1] if len(sys.argv) > 1 else TEMPLATE
    rows = read_sheet(template)
    hc = budget_line(rows, PAY_APP_TIE_LINE)
    inv_line = budget_line(rows, INVOICE_TIE_LINE)
    pay_due = hc["Current Draw"]
    inv_total = inv_line["Current Draw"]
    out = [
        ("THSV_Draw67_PayApp_G702.pdf", pay_application(hc, pay_due), "Application and Certificate for Payment No. 14"),
        ("THSV_Draw67_PayApp_G702_mismatch.pdf", pay_application(hc, round(pay_due + MISMATCH_DELTA, 2)),
         "Application and Certificate for Payment No. 14"),
        ("THSV_Draw67_Invoice_AlderFinch.pdf", invoice(inv_total), f"Invoice {INVOICE_NO}"),
        ("THSV_Draw67_LienWaiver_Conditional.pdf", lien_waiver(pay_due), "Conditional Waiver and Release on Progress Payment"),
    ]
    print(f"template: {os.path.basename(template)}")
    print(f"  pay application ties to '{PAY_APP_TIE_LINE}' current draw = {money(pay_due)}")
    print(f"  mismatch pay application Current Payment Due = {money(pay_due + MISMATCH_DELTA)} (+{money(MISMATCH_DELTA)})")
    print(f"  invoice ties to '{INVOICE_TIE_LINE}' current draw = {money(inv_total)}")
    for name, page, title in out:
        n = write_pdf(os.path.join(ROOT, name), page, title)
        print(f"  wrote {name} ({n:,} bytes)")


if __name__ == "__main__":
    main()

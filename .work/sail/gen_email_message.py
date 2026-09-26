"""Phase 6a/6b: SD_newEmailMessage, the one SD Draw Email Message row constructor every Write Records node in the email
lane calls. Each text is cut to its column (widths measured through a real Write Records node: from 255, to 1,000,
subject 1,000, body 4,000, interpretation 1,000, notes 1,000; Phase 6b adds decisivePhrase 1,000 and senderName 255)
so a long email never fails a write that does not pause on error."""
from refs import *
m = lambda n: fld(MSG, n)
cuts = [("drawId", None), ("approvalId", None), ("stepOrder", None), ("direction", None), ("kind", None),
        ("fromAddress", 255), ("toAddress", 1000), ("subject", 1000), ("body", 4000), ("messageAt", "now"),
        ("outcome", None), ("interpretation", 1000), ("source", "EMAIL"), ("notes", 1000),
        ("decisivePhrase", 1000), ("senderName", 255)]
lines = []
for n, c in cuts:
    if c is None:
        v = "ri!" + n
    elif c == "now":
        v = "a!defaultValue(ri!" + n + ", now())"
    elif c == "EMAIL":
        v = "a!defaultValue(ri!" + n + ", \"EMAIL\")"
    else:
        v = "left(a!defaultValue(ri!" + n + ", \"\"), " + str(c) + ")"
    lines.append("  " + m(n) + ": " + v)
text = ("/* Draw approval (Phase 6a; Phase 6b adds decisivePhrase and senderName): one SD Draw Email Message row, for a Write\n"
        "   Records node. Lengths are cut to the columns (from 255, subject/to/interpretation/notes/decisivePhrase 1,000,\n"
        "   body 4,000, senderName 255; measured through a real Write Records node) so a long email never fails the write. */\n"
        + rt(MSG) + "(\n" + ",\n".join(lines) + "\n)\n")
open("SD_newEmailMessage.sail", "w").write(text)
print("wrote SD_newEmailMessage", len(text))

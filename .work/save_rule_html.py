"""Save the html of a testRule result file (subject/html/bytes map) to .work/email/<name>.html and a .txt summary.
Usage: python3 save_rule_html.py <testRule result json file> <name>"""
import json, sys, re, html as H
res = json.load(open(sys.argv[1]))
r = res["result"]
name = sys.argv[2]
open(f"email/{name}.html", "w").write(r["html"])
text = re.sub(r"<[^>]+>", " ", r["html"])
text = H.unescape(re.sub(r"\s+", " ", text)).strip()
open(f"email/{name}.txt", "w").write("SUBJECT: " + r["subject"] + "\nBYTES: " + str(r["bytes"]) + "\n\n" + text + "\n")
print("saved", name, r["bytes"], "bytes;", "style tags:", r["html"].count("<style"), "img:", r["html"].count("<img"), "href:", r["html"].count("href"), "class=:", r["html"].count("class="))

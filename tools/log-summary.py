#!/usr/bin/env python3
"""Summarize a LuaLaTeX log: errors, undefined references and citations,
multiply-defined labels, missing glyphs, overfull boxes, crowded margins.

    tools/log-summary.py <log> <lang> [<chapter-slug>]

With a chapter slug (chapter-only build), undefined references to labels
defined in other chapters of the same edition are listed separately: they
resolve in the whole book.  Exit status: 0 if clean, 1 otherwise.
"""
import glob
import os
import re
import sys

log, lang = sys.argv[1], sys.argv[2]
slug = sys.argv[3] if len(sys.argv) > 3 else None
root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
if not os.path.exists(log):
    print("!! no log file produced")
    sys.exit(1)
text = open(log, encoding="utf-8", errors="replace").read()
# LaTeX wraps log lines at 79 characters; join them back for matching
joined = re.sub(r"(?m)^(.{79})\n", r"\1", text)
problems = 0

errs = re.findall(r"(?m)^(?:\./|\.\./)?[^\s:]+\.tex:\d+: .*$|^! .*$", joined)
problems += len(errs)
print(f"== errors: {len(errs)}")
for e in dict.fromkeys(errs):
    print("   ", e[:200])

undef = sorted(set(re.findall(r"Reference `([^']+)' on page \d+ undefined", joined)))
elsewhere = {}
if slug:
    for f in glob.glob(os.path.join(root, lang, "lessons", "*.tex")):
        if os.path.basename(f) == slug + ".tex":
            continue
        for m in re.finditer(r"\\label\{([^}]+)\}", open(f, encoding="utf-8").read()):
            elsewhere[m.group(1)] = os.path.basename(f)
really = [u for u in undef if u not in elsewhere]
other = [f"{u} ({elsewhere[u]})" for u in undef if u in elsewhere]
problems += len(really)
print(f"== undefined references: {len(really)}" + (" -> " + ", ".join(really) if really else ""))
if other:
    print("   (defined in other chapters, OK: " + ", ".join(other) + ")")

cites = sorted(set(re.findall(r"Citation '([^']+)' on page \d+ undefined", joined)))
problems += len(cites)
print(f"== undefined citations: {len(cites)}" + (" -> " + ", ".join(cites) if cites else ""))

multi = sorted(set(re.findall(r"Label `([^']+)' multiply defined", joined)))
problems += len(multi)
print(f"== multiply-defined labels: {len(multi)}" + (" -> " + ", ".join(multi) if multi else ""))

miss = sorted(set(re.findall(r"Missing character: There is no (\S+)", joined)))
problems += len(miss)
print(f"== missing glyphs: {len(miss)}" + (" -> " + " ".join(miss) if miss else ""))

over = re.findall(r"Overfull \\hbox \((\d+\.\d+)pt too wide\) (?:in paragraph|detected) at lines? (\d+)", joined)
big = [(float(w), l) for w, l in over if float(w) > 3.0]
problems += len(big)
print(f"== overfull hboxes > 3pt: {len(big)}"
      + ("" if not big else " -> " + ", ".join(f"line {l} ({w:.1f}pt)" for w, l in big[:15])))

moved = len(re.findall(r"Marginpar on page \d+ moved", joined))
print(f"== margin notes moved down (crowded margin): {moved}")

pages = re.findall(r"Output written on \S+ \((\d+) pages?", joined)
print(f"== pages: {pages[-1] if pages else '?'}")
sys.exit(1 if problems else 0)

#!/usr/bin/env python3
"""Regenerate the chapter list and the per-chapter bibliography list of
en/main.tex and ja/main.tex from docs/syllabus.json.

    tools/sync-main.py            rewrite both main.tex files
    tools/sync-main.py --check    exit 1 if they are out of date

Only the regions between the marker lines are touched:

    % BEGIN bib (tools/sync-main.py)      ...  % END bib
    % BEGIN chapters (tools/sync-main.py) ...  % END chapters

Every chapter is included with \\IfFileExists, so the book builds while
chapters are still being written.  Parts come from "parts" in the syllabus
({"part": 1, "title": "...", "title_ja": "...", "first": <chapter number>});
a part page is printed once the part's first chapter exists.
A bib/<slug>.bib file is listed once it exists.
"""
import json
import os
import re
import sys

root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
syl = json.load(open(os.path.join(root, "docs", "syllabus.json"), encoding="utf-8"))
lessons = sorted(syl["lessons"], key=lambda l: l["number"])
parts = {p["first"]: p for p in syl.get("parts", [])}


def bib_block():
    lines = []
    for l in lessons:
        if os.path.exists(os.path.join(root, "bib", l["slug"] + ".bib")):
            lines.append(f"\\addbibresource{{\\subfix{{../bib/{l['slug']}.bib}}}}")
    return lines


def chapter_block(lang):
    lines = []
    for l in lessons:
        p = parts.get(l["number"])
        if p:
            # the part page appears once its first chapter exists
            title = p.get("title_ja", p["title"]) if lang == "ja" else p["title"]
            lines.append(f"\\IfFileExists{{lessons/{l['slug']}.tex}}{{\\part{{{title}}}}}{{}}")
        s = l["slug"]
        lines.append(f"\\IfFileExists{{lessons/{s}.tex}}{{\\subfile{{lessons/{s}}}}}{{}}")
    return lines


def replace(text, name, body, path):
    pat = re.compile(r"(?m)^(% BEGIN " + name + r" \(tools/sync-main\.py\)\n)(.*?)(^% END " + name + r"\n)", re.S)
    if not pat.search(text):
        sys.exit(f"{path}: marker lines for '{name}' not found")
    return pat.sub(lambda m: m.group(1) + "".join(l + "\n" for l in body) + m.group(3), text)


check = "--check" in sys.argv[1:]
stale = []
for lang in ("en", "ja"):
    path = os.path.join(root, lang, "main.tex")
    old = open(path, encoding="utf-8").read()
    new = replace(old, "bib", bib_block(), path)
    new = replace(new, "chapters", chapter_block(lang), path)
    if new != old:
        stale.append(f"{lang}/main.tex")
        if not check:
            open(path, "w", encoding="utf-8").write(new)
if check:
    if stale:
        print("out of date: " + ", ".join(stale))
        sys.exit(1)
    print("main.tex files are up to date")
else:
    print("updated: " + (", ".join(stale) if stale else "nothing"))

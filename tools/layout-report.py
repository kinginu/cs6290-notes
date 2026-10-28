#!/usr/bin/env python3
"""Layout report of a whole-book build log: overfull boxes and crowded
margins, per chapter and per page.

    tools/layout-report.py <main.log> [--toc <main.toc>] [--min-pt 3]
                           [--crowded 3] [--pages]

Reads the LuaLaTeX log of a whole edition (e.g. en/build/main.log, or the
one in the CI artifact build-logs) and prints

  - every overfull \\hbox wider than --min-pt (default 3 pt) with its
    chapter, source file, line range and the page it lands on;
  - the "Marginpar on page N moved" warnings counted per chapter and per
    printed page, flagging pages with at least --crowded (default 3) moved
    notes; --pages also lists every page that has one.

Printed pages are mapped to chapters with the \\contentsline{chapter}
entries of the .toc when --toc is given (CI uploads main.toc next to
main.log); otherwise with the chapter start pages read from the log
itself: the page after the last shipped page at the "chapter N." line
that \\chapter writes (or, if there is none, where <lang>/lessons/NN-*.tex
is opened; the previous chapter's last page may still be pending there).  The source file of an overfull box is the innermost .tex file
open at that point of the log; its page is the next page shipped out.
Front-matter pages (roman numbers) are reported as chapter "--".

Exit status: 1 if there is an overfull box above --min-pt or a crowded
page, else 0.
"""
import argparse
import bisect
import collections
import os
import re
import sys

TOKEN = re.compile(
    r"(?P<over>^Overfull \\hbox \((?P<pt>[\d.]+)pt too wide\)[^\n]*?lines? (?P<lines>[\d-]+))"
    r"|(?P<under>^(?:Underfull|Overfull) \\[hv]box[^\n]*)"
    r"|(?P<moved>Marginpar on page (?P<mpage>\w+) moved)"
    r"|(?P<open>\((?P<file>[^\s()]*\.(?:tex|sty|cls|cfg|def|clo|fd|ldf|aux|toc|lua|bbl|ind)))"
    r"|(?P<lp>\()|(?P<rp>\))"
    r"|(?P<chap>^(?:chapter|Chapter|lesson|Lesson) (?P<cnum>\d+)\.$)"
    r"|(?P<ship>(?<![\w\\\[])\[(?P<page>\d+)(?=[\]\s{<]))", re.M)
LESSON = re.compile(r"lessons/(\d\d)-[^/]*\.tex$")


def toc_starts(path):
    """[(start page, chapter "NN")] from the chapter lines of a .toc."""
    out = []
    for line in open(path, encoding="utf-8", errors="replace"):
        if not line.startswith("\\contentsline {chapter}"):
            continue
        num = re.search(r"\\numberline\s*\{[^}\d]*(\d+)", line)
        page = re.search(r"\}\{([^{}]*)\}\{[^{}]*\}%?\s*$", line)
        if num and page and page.group(1).strip().isdigit():
            out.append((int(page.group(1)), f"{int(num.group(1)):02d}"))
    return sorted(out)


def parse(log):
    text = open(log, encoding="utf-8", errors="replace").read()
    text = re.sub(r"(?m)^(.{79})\n", r"\1", text)  # undo the 79-column wrap
    stack, shipped, starts, opened = [], 0, [], []
    overfull, moved = [], []
    pos = 0
    while True:
        m = TOKEN.search(text, pos)
        if not m:
            break
        pos = m.end()
        if m.group("over") or m.group("under"):
            if m.group("over"):
                files = [f for f in stack if f and f.endswith(".tex")]
                lesson = next((LESSON.search(f).group(1) for f in reversed(files) if LESSON.search(f)), None)
                overfull.append((float(m.group("pt")), m.group("lines"),
                                 os.path.basename(files[-1]) if files else "?", lesson, shipped + 1))
            # the box listing that follows contains typeset text with
            # parentheses: skip to the blank line that ends it
            end = text.find("\n\n", pos)
            pos = len(text) if end < 0 else end
        elif m.group("moved"):
            moved.append(m.group("mpage"))
        elif m.group("open"):
            stack.append(m.group("file"))
            lm = LESSON.search(m.group("file"))
            if lm:
                opened.append((shipped + 1, lm.group(1)))
        elif m.group("chap"):
            starts.append((shipped + 1, f"{int(m.group('cnum')):02d}"))
        elif m.group("lp"):
            stack.append(None)
        elif m.group("rp"):
            if stack:
                stack.pop()
        elif m.group("ship"):
            shipped = int(m.group("page"))
    pages = re.findall(r"Output written on \S+ \((\d+) pages?", text)
    return overfull, moved, starts or opened, pages[-1] if pages else "?"


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("log")
    ap.add_argument("--toc", help="main.toc of the same build")
    ap.add_argument("--min-pt", type=float, default=3.0)
    ap.add_argument("--crowded", type=int, default=3)
    ap.add_argument("--pages", action="store_true", help="list every page with a moved note")
    a = ap.parse_args()
    if not os.path.exists(a.log):
        sys.exit(f"no log: {a.log}")
    overfull, moved, starts, total_pages = parse(a.log)
    if a.toc:
        starts = toc_starts(a.toc)
    else:  # a chapter opened twice (e.g. a rerun) keeps its first start
        seen = {}
        for p, c in starts:
            seen.setdefault(c, p)
        starts = sorted((p, c) for c, p in seen.items())
    keys = [p for p, _ in starts]

    def chapter_of(page):
        if not str(page).isdigit():
            return "--"
        i = bisect.bisect_right(keys, int(page)) - 1
        return starts[i][1] if i >= 0 else "--"

    print(f"== {a.log}: {total_pages} pages, chapter pages from "
          + ("the toc" if a.toc else "the log"))
    big = [o for o in overfull if o[0] > a.min_pt]
    print(f"== overfull hboxes > {a.min_pt:g}pt: {len(big)} (of {len(overfull)})")
    for pt, lines, f, lesson, page in big:
        print(f"   ch {lesson or chapter_of(page)}  p.{page:<4} {f}:{lines}  {pt:.1f}pt")
    per_ch = collections.Counter()
    per_page = collections.Counter()
    for p in moved:
        per_ch[chapter_of(p)] += 1
        per_page[p] += 1
    print(f"== margin notes moved: {len(moved)}")
    if per_ch:
        print("   per chapter: " + " ".join(f"{c}:{n}" for c, n in sorted(per_ch.items())))
    order = sorted(per_page, key=lambda p: (not p.isdigit(), int(p) if p.isdigit() else 0, p))
    crowded = [p for p in order if per_page[p] >= a.crowded]
    print(f"   pages with >= {a.crowded}: {len(crowded)}"
          + ("" if not crowded else " -> " + " ".join(f"p.{p}({per_page[p]}, ch {chapter_of(p)})" for p in crowded)))
    if a.pages:
        print("   all: " + " ".join(f"p.{p}:{per_page[p]}" for p in order))
    return 1 if big or crowded else 0


if __name__ == "__main__":
    sys.exit(main())

#!/usr/bin/env python3
"""Compare the structure of the English and Japanese edition of each chapter.

    tools/parity-check.py [--lesson NN] [--root DIR] [--lint]

For every lesson present in both en/lessons/ and ja/lessons/, the ordered
sequence of structural tokens is extracted from each edition:

  \\chapter \\section \\subsection (and their starred forms), \\label{...} and
  \\input{...} with their argument, \\begin{env} for the environments in ENVS,
  and the margin macros \\source \\margin \\sidenote \\tip \\caution \\term
  \\term* (name only).

Comments, \\verb, \\lstinline and lstlisting bodies are ignored.  The two
sequences are compared with difflib; a lesson whose sequences are identical
prints "ok", otherwise a unified-style diff of the tokens (with line numbers).

Margin items are also compared per paragraph (blank-line separated): the
paragraphs of the two editions are aligned on their non-margin tokens, and
a margin macro that sits in a different paragraph in the two editions is
reported as "anchor: <macro> is in paragraph N (en) vs M (ja)", even when
the global sequence matches.  A deliberate anchor difference (marked with a
% comment in the source) is still reported: read the comment, then accept it.

--lint also scans the text outside comments, \\source arguments and listings
for delivery-format wording:
  EN  \\b(the|this) (lecture|video|slides?)\\b, \\blet['’]s\\b, \\byou\\b
  JA  講義(で|は|が|の), 動画(で|は)
("let's" only, not the verb "lets").  The hits are file:line candidates for
a human to judge; a hit inside a \\margin, \\sidenote, \\tip or \\caution
argument is tagged "(margin)" (a note about the source's terminology may
legitimately say "the lecture").  Lint hits do not change the exit status.

Exit status: 1 if any lesson has a sequence or anchor mismatch, else 0.
"""
import argparse
import collections
import difflib
import glob
import os
import re
import sys

ENVS = ("definition example note keypoint figure table widefigure widetable "
        "marginfigure margintable lstlisting equation align itemize enumerate "
        "description").split()
MARGIN = ("source", "margin", "sidenote", "tip", "caution", "term")
TOKEN = re.compile(
    r"\\(?P<sec>chapter|section|subsection)(?![A-Za-z])(?P<secstar>\*?)"
    r"|\\(?P<arg>label|input)\s*\{(?P<argv>[^}]*)\}"
    r"|\\begin\{(?P<env>" + "|".join(ENVS) + r")\*?\}"
    r"|\\(?P<mm>" + "|".join(MARGIN) + r")(?![A-Za-z])(?P<mmstar>\*?)")
LINT = {
    "en": [re.compile(r"\b(the|this) (lecture|video|slides?)\b", re.I),
           re.compile(r"\blet['’]s\b", re.I), re.compile(r"\byou\b", re.I)],
    "ja": [re.compile(r"講義(で|は|が|の)|動画(で|は)")],
}


def blank(m):
    return re.sub(r"[^\n]", " ", m.group(0))


def strip_noise(text):
    """Blank out comments, \\verb, \\lstinline and listing bodies, keeping
    line breaks.  The \\begin{lstlisting} itself is kept as a token."""
    text = re.sub(r"(?<!\\)%[^\n]*", blank, text)
    text = re.sub(r"(?s)(\\begin\{lstlisting\})(.*?)(?=\\end\{lstlisting\})",
                  lambda m: m.group(1) + blank(re.match(r"(?s).*", m.group(2))), text)
    text = re.sub(r"\\(?:verb|lstinline)\*?([^\sA-Za-z{]).*?\1", blank, text)
    return re.sub(r"\\lstinline\{[^}]*\}", blank, text)


def tokens(path):
    """Return [(token, line, paragraph)] and the list of paragraph start
    lines.  Paragraphs are separated by blank lines of the raw source."""
    raw = open(path, encoding="utf-8").read()
    text = strip_noise(raw)
    para_of_line = []
    p, prev_blank = 0, True
    for ln in raw.split("\n"):
        is_blank = not ln.strip()
        if not is_blank and prev_blank:
            p += 1
        para_of_line.append(p)
        prev_blank = is_blank
    out = []
    for m in TOKEN.finditer(text):
        if m.group("sec"):
            t = "\\" + m.group("sec") + m.group("secstar")
        elif m.group("arg"):
            t = "\\%s{%s}" % (m.group("arg"), m.group("argv").strip())
        elif m.group("env"):
            t = "\\begin{%s}" % m.group("env")
        else:
            t = "\\" + m.group("mm") + m.group("mmstar")
        line = text.count("\n", 0, m.start()) + 1
        out.append((t, line, para_of_line[line - 1]))
    return out


def is_margin(t):
    return t.rstrip("*").lstrip("\\") in MARGIN


def seq_diff(en, ja):
    a = [t for t, _, _ in en]
    b = [t for t, _, _ in ja]
    out = []
    sm = difflib.SequenceMatcher(None, a, b, autojunk=False)
    for tag, i1, i2, j1, j2 in sm.get_opcodes():
        if tag == "equal":
            continue
        ctx = f"@@ -{i1 + 1},{i2 - i1} +{j1 + 1},{j2 - j1} @@"
        if i1 > 0:
            ctx += f" (after {a[i1 - 1]} en:{en[i1 - 1][1]})"
        out.append(ctx)
        out += [f"-  en:{en[i][1]:<5} {a[i]}" for i in range(i1, i2)]
        out += [f"+  ja:{ja[j][1]:<5} {b[j]}" for j in range(j1, j2)]
    return out


def anchor_diff(en, ja):
    """Align paragraphs on their non-margin tokens, then compare where each
    margin item sits."""
    def paras(toks):
        n = max([p for _, _, p in toks] + [0])
        sig = [[] for _ in range(n + 1)]
        for t, _, p in toks:
            if not is_margin(t):
                sig[p].append(t)
        return [tuple(s) for s in sig]
    pa, pb = paras(en), paras(ja)
    mapping = {}
    sm = difflib.SequenceMatcher(None, pa, pb, autojunk=False)
    for tag, i1, i2, j1, j2 in sm.get_opcodes():
        if tag == "equal" or (tag == "replace" and i2 - i1 == j2 - j1):
            for k in range(i2 - i1):
                mapping[i1 + k] = j1 + k
    occ_en = collections.defaultdict(list)
    occ_ja = collections.defaultdict(list)
    for t, line, p in en:
        if is_margin(t):
            occ_en[t].append((p, line))
    for t, line, p in ja:
        if is_margin(t):
            occ_ja[t].append((p, line))
    out = []
    for t in sorted(set(occ_en) | set(occ_ja)):
        xs, ys = occ_en[t], occ_ja[t]
        if len(xs) != len(ys):
            out.append(f"count: {t} {len(xs)} (en) vs {len(ys)} (ja)")
            continue
        for (p, l1), (q, l2) in zip(xs, ys):
            if p in mapping and mapping[p] != q:
                out.append(f"anchor: {t} is in paragraph {p} (en:{l1}) vs {q} (ja:{l2})")
    return out


def arg_spans(text, names):
    """(start, end) of every \\name{...} including its balanced argument."""
    spans = []
    for m in re.finditer(r"\\(?:%s)(?![A-Za-z])\s*\{" % "|".join(names), text):
        depth, j = 1, m.end()
        while j < len(text) and depth:
            c = text[j]
            if c == "\\":
                j += 2
                continue
            depth += {"{": 1, "}": -1}.get(c, 0)
            j += 1
        spans.append((m.start(), j))
    return spans


def lint(path, lang, root):
    raw = open(path, encoding="utf-8").read()
    text = strip_noise(raw)
    out = list(text)
    for a, b in arg_spans(text, ["source"]):
        for k in range(a, b):
            if out[k] != "\n":
                out[k] = " "
    text = "".join(out)
    margin = arg_spans(text, ["margin", "sidenote", "tip", "caution"])
    rel = os.path.relpath(path, root)
    hits = []
    lines = raw.split("\n")
    offset = 0
    for i, ln in enumerate(text.split("\n"), 1):
        for rx in LINT[lang]:
            for m in rx.finditer(ln):
                pos = offset + m.start()
                where = next((" (margin)" for a, b in margin if a <= pos < b), "")
                hits.append(f"lint: {rel}:{i}{where}: \"{m.group(0)}\" in: {lines[i - 1].strip()[:90]}")
        offset += len(ln) + 1
    return hits


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--lesson", type=int, action="append",
                    help="lesson number (repeatable); default: all")
    ap.add_argument("--root", default=os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    ap.add_argument("--lint", action="store_true", help="also scan for delivery-format wording")
    a = ap.parse_args()
    files = {}
    for lang in ("en", "ja"):
        for f in glob.glob(os.path.join(a.root, lang, "lessons", "[0-9][0-9]-*.tex")):
            files.setdefault(os.path.basename(f), {})[lang] = f
    bad, checked, hits = [], 0, 0
    for name in sorted(files):
        n = int(name[:2])
        if a.lesson and n not in a.lesson:
            continue
        both = files[name]
        if len(both) < 2:
            print(f"== {name}: only in {', '.join(both)} (skipped)")
            continue
        checked += 1
        en, ja = tokens(both["en"]), tokens(both["ja"])
        d = seq_diff(en, ja)
        anc = anchor_diff(en, ja)
        if not d and not anc:
            print(f"== {name}: ok ({len(en)} tokens)")
        else:
            bad.append(name[:2])
            print(f"== {name}: MISMATCH ({len(en)} en / {len(ja)} ja tokens)")
            for s in d + anc:
                print("   " + s)
        if a.lint:
            for lang in ("en", "ja"):
                for s in lint(both[lang], lang, a.root):
                    hits += 1
                    print("   " + s)
    summary = f"== parity: {checked} lesson(s) checked, {len(bad)} mismatching"
    if bad:
        summary += " (" + ", ".join(bad) + ")"
    if a.lint:
        summary += f"; {hits} lint hit(s)"
    print(summary)
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())

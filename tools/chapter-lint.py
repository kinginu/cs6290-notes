#!/usr/bin/env python3
"""No-TeX checks of one chapter in both editions (the pre-push gate when
there is no local TeX: CI is the only build).

    tools/chapter-lint.py <slug|NN> [...]     e.g. tools/chapter-lint.py 07
    tools/chapter-lint.py --all
    options: --root DIR

For en/lessons/<slug>.tex and ja/lessons/<slug>.tex (and the figures they
\\input), prints one "file:line: message" per finding:

  syntax     braces balance (\\{ \\} and comments ignored); \\begin/\\end
             matched in order; \\end{lstlisting} at column 0; listing lines
             at most 60 display columns (East Asian wide characters count 2)
  labels     prefixed lNN (e.g. sec:l07-...); unique across <lang>/lessons;
             the same label set in en and ja
  parity     the same count, en vs ja, of each item in COUNTED (sections,
             margin macros, \\term / \\term*, figure \\input, listings,
             environments, tables); tools/parity-check.py compares the order
  refs       every \\cite key is in references.bib or bib/*.bib; every
             \\cref/\\Cref/\\ref target is a \\label of the same edition
  terms      \\term (not \\term*) only for glossary.tsv rows that this lesson
             owns (column lesson); gloss = the glossary's other-language
             term; a JA \\term with kanji carries the glossary reading;
             no line break inside a \\term argument that contains non-ASCII
             text (the break becomes a space in the gloss and the index key);
             no \\term inside the arguments of MARGIN_MACROS
  style      no \\tiny in the chapter or its figures; no SOURCE_PHRASES
             (delivery-format words) inside \\source; "Lesson~N" / "第N章"
             (UNIT_REF) with N within the syllabus numbers

Comments, \\verb, \\lstinline and listing bodies are ignored except where a
check needs them.  The parsers of tools/glossary-check.py and
tools/parity-check.py are reused (they must sit next to this file); that
glossary-check also lists owned terms never \\term'd, which is not a
per-chapter error and is not repeated here.  Not lintable, check by
reading: whether "Lesson~N" really covers the topic, and whether a margin
note's real-world number names its source.

Exit status: 1 if anything is found, 0 if clean, 2 on usage errors.
"""
import argparse
import glob
import importlib.util
import json
import os
import re
import sys
import unicodedata

HERE = os.path.dirname(os.path.abspath(__file__))


def _load(name):
    spec = importlib.util.spec_from_file_location(name.replace("-", "_"), os.path.join(HERE, name + ".py"))
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


GC = _load("glossary-check")
PC = _load("parity-check")

# Items whose count must be equal in the two editions: name -> regex.
COUNTED = {
    "\\section": r"\\section(?![A-Za-z])",
    "\\subsection": r"\\subsection(?![A-Za-z])",
    "\\source": r"\\source(?![A-Za-z])",
    "\\margin": r"\\margin(?![A-Za-z])",
    "\\sidenote": r"\\sidenote(?![A-Za-z])",
    "\\tip": r"\\tip(?![A-Za-z])",
    "\\caution": r"\\caution(?![A-Za-z])",
    "\\term": r"\\term(?![A-Za-z*])",
    "\\term*": r"\\term\*",
    "figure \\input": r"\\input\s*\{[^}]*figures/",
    "lstlisting": r"\\begin\{lstlisting\}",
    "example": r"\\begin\{example\}",
    "definition": r"\\begin\{definition\}",
    "note": r"\\begin\{note\}",
    "keypoint": r"\\begin\{keypoint\}",
    "table": r"\\begin\{(?:table|widetable|margintable)\*?\}",
    "figure": r"\\begin\{(?:figure|widefigure|marginfigure)\*?\}",
}
MARGIN_MACROS = ("margin", "sidenote", "tip", "caution", "source")
# Delivery-format wording that has no place in a \source note (lowercase).
SOURCE_PHRASES = {
    "en": ["visual metaphor", "metaphor", "analogy", "in this video", "in the video",
           "this lecture", "the instructor", "the speaker", "the professor", "joke"],
    "ja": ["比喩", "たとえ話", "この動画", "動画では", "講師", "冗談"],
}
# References to another chapter in prose: language -> regex whose groups
# hold the numbers ("Lessons~3 and~5", "第3--5章").
UNIT_REF = {
    "en": re.compile(r"\b(?:Lessons?|Chapters?)(?:~|\s)+(\d+)((?:(?:\s*,\s*|\s*--\s*|\s+and(?:~|\s)+|\s+or(?:~|\s)+)\d+)*)"),
    "ja": re.compile(r"第\s*(\d+)((?:\s*(?:--|–|〜|～|，|、|・)\s*\d+)*)\s*章"),
}
LISTING_WIDTH = 60
REF = re.compile(r"\\(?:[cC]ref|[vV]ref|ref|pageref|autoref|eqref|labelcref|cpageref|[cC]refrange)\*?\s*\{([^}]*)\}(?:\s*\{([^}]*)\})?")
CITE = re.compile(r"\\[A-Za-z]*cite[A-Za-z]*\*?\s*(?:\[[^\]]*\]\s*){0,2}\{([^}]*)\}")
LABEL = re.compile(r"\\label\s*\{([^}]*)\}")


def width(s):
    return sum(2 if unicodedata.east_asian_width(c) in "WF" else 1 for c in s)


def line_of(text, pos):
    return text.count("\n", 0, pos) + 1


class Lint:
    def __init__(self, root):
        self.root = root
        syl = json.load(open(os.path.join(root, "docs", "syllabus.json"), encoding="utf-8"))
        self.lessons = {l["slug"]: l["number"] for l in syl["lessons"]}
        self.numbers = set(self.lessons.values())
        gpath = os.path.join(root, "glossary.tsv")
        self.gloss = GC.load_glossary(gpath) if os.path.exists(gpath) else []
        self.bibkeys = set()
        for f in [os.path.join(root, "references.bib")] + glob.glob(os.path.join(root, "bib", "*.bib")):
            if os.path.exists(f):
                self.bibkeys.update(k.strip() for k in re.findall(r"@\w+\s*\{\s*([^,\s]+)\s*,", open(f, encoding="utf-8").read()))
        self.labels = {}  # lang -> {label: [files]}
        for lang in ("en", "ja"):
            d = self.labels[lang] = {}
            for f in sorted(glob.glob(os.path.join(root, lang, "lessons", "*.tex"))):
                for m in LABEL.finditer(PC.strip_noise(open(f, encoding="utf-8").read())):
                    d.setdefault(m.group(1).strip(), []).append(f)
        self.found = []

    def rel(self, path):
        return os.path.relpath(path, self.root)

    def add(self, path, line, msg):
        self.found.append(f"{self.rel(path)}:{line}: {msg}")

    # -- per file -----------------------------------------------------------
    def syntax(self, path, raw, text):
        stack = []  # (line, char) of open braces
        i = 0
        while i < len(text):
            c = text[i]
            if c == "\\":
                i += 2
                continue
            if c == "{":
                stack.append(line_of(text, i))
            elif c == "}":
                if stack:
                    stack.pop()
                else:
                    self.add(path, line_of(text, i), "unmatched }")
            i += 1
        for ln in stack:
            self.add(path, ln, "{ never closed")
        envs = []
        for m in re.finditer(r"\\(begin|end)\s*\{([^}]*)\}", text):
            ln, name = line_of(text, m.start()), m.group(2)
            if m.group(1) == "begin":
                envs.append((name, ln))
            elif not envs:
                self.add(path, ln, f"\\end{{{name}}} without \\begin")
            elif envs[-1][0] != name:
                self.add(path, ln, f"\\end{{{name}}} closes \\begin{{{envs[-1][0]}}} of line {envs[-1][1]}")
                envs.pop()
            else:
                envs.pop()
        for name, ln in envs:
            self.add(path, ln, f"\\begin{{{name}}} never ended")
        inlst = False
        for n, l in enumerate(raw.split("\n"), 1):
            code = re.sub(r"(?<!\\)%.*", "", l)
            if not inlst and re.search(r"\\begin\{lstlisting\}", code):
                inlst = True
                continue
            if inlst and "\\end{lstlisting}" in l:
                if not l.startswith("\\end{lstlisting}"):
                    self.add(path, n, "\\end{lstlisting} not at column 0")
                inlst = False
                continue
            if inlst and width(l.rstrip()) > LISTING_WIDTH:
                self.add(path, n, f"listing line is {width(l.rstrip())} columns (max {LISTING_WIDTH})")

    def style(self, path, lang, text, chapter=True):
        for m in re.finditer(r"\\tiny(?![A-Za-z])", text):
            self.add(path, line_of(text, m.start()), "\\tiny (nothing smaller than \\scriptsize)")
        if not chapter:
            return
        for a, b in PC.arg_spans(text, ["source"]):
            arg = re.sub(r"\s+", " ", text[a:b].lower())
            for p in sorted(SOURCE_PHRASES[lang], key=len, reverse=True):
                k = arg.find(p)
                if k >= 0:
                    self.add(path, line_of(text, a), f"delivery-format wording in \\source: \"{p}\"")
                    break
        for m in UNIT_REF[lang].finditer(text):
            nums = [int(m.group(1))] + [int(x) for x in re.findall(r"\d+", m.group(2) or "")]
            bad = [x for x in nums if x not in self.numbers]
            if bad:
                self.add(path, line_of(text, m.start()), f"\"{m.group(0).strip()}\": no chapter {', '.join(map(str, bad))} in the syllabus")

    def refs(self, path, lang, text):
        for m in CITE.finditer(text):
            for k in m.group(1).split(","):
                k = k.strip()
                if k and k not in self.bibkeys:
                    self.add(path, line_of(text, m.start()), f"\\cite key {k} not in references.bib or bib/*.bib")
        for m in REF.finditer(text):
            for g in (m.group(1), m.group(2)):
                for k in (g or "").split(","):
                    k = k.strip()
                    if k and k not in self.labels[lang]:
                        self.add(path, line_of(text, m.start()), f"reference to undefined label {k}")

    def labels_of(self, path, lang, text, nn):
        out = []
        for m in LABEL.finditer(text):
            lab, ln = m.group(1).strip(), line_of(text, m.start())
            out.append(lab)
            if not re.match(rf"^[A-Za-z]+:l{nn}-", lab):
                self.add(path, ln, f"label {lab} lacks the prefix <kind>:l{nn}-")
            others = [f for f in self.labels[lang].get(lab, []) if os.path.abspath(f) != os.path.abspath(path)]
            if others or out.count(lab) > 1:
                where = ", ".join(self.rel(f) for f in others) or "this file"
                self.add(path, ln, f"label {lab} also defined in {where}")
        return set(out)

    def terms(self, path, lang, raw, text, n):
        other = "ja" if lang == "en" else "en"
        index = {}
        for r in self.gloss:
            index.setdefault(GC.key(r[lang], lang), []).append(r)
        for line, star, sort, word, gloss in GC.terms_in(path):
            if star:
                continue
            for part in (sort, word, gloss):
                if part and "\n" in part and re.search(r"[^\x00-\x7f]", part):
                    self.add(path, line, f"line break inside the \\term argument {{{GC.norm(part)}}}")
                    break
            w = GC.norm(word)
            cands = index.get(GC.key(w, lang), [])
            if not cands and lang == "en" and sort:
                cands = index.get(GC.key(GC.norm(sort), "en"), [])
            if not cands:
                self.add(path, line, f"\\term{{{w}}} is not in glossary.tsv")
                continue
            g = GC.norm(gloss) if gloss is not None else None
            cands = sorted(cands, key=lambda r: (
                g is None or GC.key(r[other], other) != GC.key(g, other), r["lesson"] != n, r["see"]))
            r = cands[0]
            if not any(c["lesson"] == n for c in cands):
                owners = sorted({c["lesson"] for c in cands if c["lesson"] is not None})
                self.add(path, line, f"\\term{{{w}}} is owned by lesson {', '.join(map(str, owners)) or '(none)'}: use \\term* or plain text")
            if g is not None and GC.key(g, other) != GC.key(r[other], other):
                self.add(path, line, f"\\term{{{w}}} gloss [{GC.norm(gloss)}], glossary {other}: {r[other]}")
            if lang == "ja":
                if sort is None and GC.KANJI.search(w):
                    self.add(path, line, f"\\term{{{w}}} has no reading (glossary: {r['reading']})")
                elif sort is not None and GC.key(GC.norm(sort), "ja") != GC.key(r["reading"], "ja"):
                    self.add(path, line, f"\\term{{{w}}} reading [{sort}], glossary: {r['reading']}")
        for a, b in PC.arg_spans(text, list(MARGIN_MACROS)):
            for m in re.finditer(r"\\term(?![A-Za-z*])", text[a:b]):
                self.add(path, line_of(text, a + m.start()), "\\term inside a margin macro (it needs its own margin gloss)")

    # -- per chapter --------------------------------------------------------
    def chapter(self, slug):
        n = self.lessons[slug]
        nn = f"{n:02d}"
        files = {lang: os.path.join(self.root, lang, "lessons", slug + ".tex") for lang in ("en", "ja")}
        missing = [lang for lang, f in files.items() if not os.path.exists(f)]
        if missing:
            self.found.append(f"{slug}: missing {', '.join(missing)} edition")
            return
        labels, counts, figs = {}, {}, set()
        for lang, path in files.items():
            raw = open(path, encoding="utf-8").read()
            text = PC.strip_noise(raw)
            self.syntax(path, raw, text)
            self.style(path, lang, text)
            self.refs(path, lang, text)
            labels[lang] = self.labels_of(path, lang, text, nn)
            self.terms(path, lang, raw, text, n)
            counts[lang] = {k: len(re.findall(rx, text)) for k, rx in COUNTED.items()}
            for m in re.finditer(r"\\input\s*\{([^}]*figures/[^}]*)\}", text):
                f = m.group(1).strip().lstrip("./")
                f = f if f.endswith(".tex") else f + ".tex"
                figs.add(os.path.join(self.root, f[f.index("figures/"):]))
        en, ja = files["en"], files["ja"]
        for lab in sorted(labels["en"] - labels["ja"]):
            self.add(ja, 1, f"label {lab} of the en edition is missing")
        for lab in sorted(labels["ja"] - labels["en"]):
            self.add(en, 1, f"label {lab} of the ja edition is missing")
        for k in COUNTED:
            if counts["en"][k] != counts["ja"][k]:
                self.add(ja, 1, f"{k}: {counts['en'][k]} in en, {counts['ja'][k]} in ja")
        for f in sorted(figs):
            if not os.path.exists(f):
                self.add(en, 1, f"figure {self.rel(f)} does not exist")
                continue
            raw = open(f, encoding="utf-8").read()
            text = PC.strip_noise(raw)
            self.syntax(f, raw, text)
            self.style(f, "en", text, chapter=False)


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("chapters", nargs="*", help="slug or chapter number")
    ap.add_argument("--all", action="store_true", help="every chapter of the syllabus that exists")
    ap.add_argument("--root", default=os.path.dirname(HERE))
    a = ap.parse_args()
    lint = Lint(a.root)
    if a.all:
        slugs = [s for s in lint.lessons if os.path.exists(os.path.join(a.root, "en", "lessons", s + ".tex"))]
    else:
        slugs = []
        for c in a.chapters:
            hit = [s for s, n in lint.lessons.items() if s == c or (c.isdigit() and n == int(c))]
            if not hit:
                print(f"no chapter {c} in docs/syllabus.json", file=sys.stderr)
                return 2
            slugs += hit
    if not slugs:
        ap.print_usage(sys.stderr)
        return 2
    total = 0
    for s in slugs:
        before = len(lint.found)
        lint.chapter(s)
        new = lint.found[before:]
        total += len(new)
        print(f"== {s}: " + (f"{len(new)} finding(s)" if new else "ok"))
        for line in dict.fromkeys(new):
            print("   " + line)
    print(f"== chapter-lint: {total} finding(s) in {len(slugs)} chapter(s)")
    return 1 if total else 0


if __name__ == "__main__":
    sys.exit(main())

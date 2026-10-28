#!/usr/bin/env python3
"""Check the \\term entries of the chapters against glossary.tsv.

    tools/glossary-check.py [--lang en|ja|both] [--lesson NN] [--root DIR]

Reads glossary.tsv (columns en, ja, reading, lesson, note) and every
<lang>/lessons/NN-*.tex, parses \\term[sort]{word}[gloss] (sort and gloss
optional) and \\term*{word}, and reports per chapter:

  (a) owned     a glossary term this lesson owns that is never \\term'd in it
                (the EN form in en/, the JA form in ja/); rows whose note
                starts with "see:" are cross-reference rows and are skipped
  (b) elsewhere a \\term of a word that another lesson owns
  (c) unknown   a \\term of a word that is not in the glossary
  (d) gloss     a gloss that differs from the glossary's other-language form
  (e) reading   (ja) a reading that differs from the glossary reading, or
                is missing on a word that contains kanji

\\term* is an emphasized later mention: it does not count for (a) and is
exempt from (b)-(e).  Words are matched on the glossary string after
collapsing whitespace (ignored entirely in JA; ~ is a space, \\& is &, $ and \\slash are dropped or
read as /); EN matching is case-insensitive.  A plural suffix outside the
braces (\\term{latch}es) is not part of the word.  A \\term without a gloss
is listed as a note; it does not affect the exit status.

Exit status: 1 if anything in (a)-(e) is found, else 0; 2 = usage.
"""
import argparse
import csv
import glob
import os
import re
import sys

KANJI = re.compile(r"[\u3400-\u9fff\uf900-\ufaff]")


def norm(s):
    """Plain comparable form of a TeX string or a glossary cell."""
    s = s.replace("\\slash", "/").replace("\\&", "&").replace("~", " ")
    s = re.sub(r"\\(?:allowbreak|linebreak|nobreak)(?![A-Za-z])|\\-", "", s)
    s = re.sub(r"\\(?:textit|textbf|emph|texttt|textrm|mbox)\s*\{([^{}]*)\}", r"\1", s)
    s = s.replace("$", "").replace("{", "").replace("}", "")
    s = re.sub(r"\\[,;: ]", " ", s)
    return re.sub(r"\s+", " ", s).strip()


def strip_noise(text):
    """Blank out comments, \\verb, \\lstinline and lstlisting bodies,
    keeping line breaks so that line numbers stay valid."""
    def blank(m):
        return re.sub(r"[^\n]", " ", m.group(0))
    text = re.sub(r"\\begin\{lstlisting\}.*?\\end\{lstlisting\}", blank, text, flags=re.S)
    text = re.sub(r"\\(?:verb|lstinline)\*?([^\sA-Za-z{]).*?\1", blank, text)
    text = re.sub(r"\\lstinline\{[^}]*\}", blank, text)
    text = re.sub(r"(?<!\\)%[^\n]*", blank, text)
    return text


def group(text, i, open_, close):
    """If text[i] is `open_`, return (content, index after the closing
    delimiter), honouring nested braces; else None."""
    if i >= len(text) or text[i] != open_:
        return None
    depth, j = 0, i + 1
    brace = 0
    while j < len(text):
        c = text[j]
        if c == "\\":
            j += 2
            continue
        if c == "{":
            brace += 1
        elif c == "}":
            if open_ == "{" and brace == 0:
                return text[i + 1:j], j + 1
            brace -= 1
        elif c == close and open_ != "{" and brace == 0 and depth == 0:
            return text[i + 1:j], j + 1
        j += 1
    return None


def terms_in(path):
    """Yield (line, star, sort, word, gloss) for every \\term in a file."""
    text = strip_noise(open(path, encoding="utf-8").read())
    for m in re.finditer(r"\\term(?![A-Za-z])(\*?)", text):
        i = m.end()
        sort = gloss = None
        g = group(text, i, "[", "]")
        if g:
            sort, i = g
        g = group(text, i, "{", "}")
        if not g:
            continue
        word, i = g
        g = group(text, i, "[", "]")
        if g:
            gloss, i = g
        line = text.count("\n", 0, m.start()) + 1
        yield line, m.group(1) == "*", sort, word, gloss


def load_glossary(path):
    with open(path, encoding="utf-8", newline="") as f:
        rows = list(csv.DictReader(f, delimiter="\t"))
    missing = {"en", "ja", "reading", "lesson"} - set(rows[0].keys() if rows else [])
    if missing:
        sys.exit(f"{path}: missing columns {', '.join(sorted(missing))}")
    out = []
    for r in rows:
        try:
            lesson = int((r.get("lesson") or "").strip())
        except ValueError:
            lesson = None
        out.append({
            "en": norm(r["en"] or ""), "ja": norm(r["ja"] or ""),
            "reading": norm(r.get("reading") or ""), "lesson": lesson,
            "see": (r.get("note") or "").strip().startswith("see:"),
        })
    return out


def key(s, lang):
    # EN: case-insensitive.  JA: spaces are not significant (a line break
    # inside a Japanese word, or "Amdahl の法則" vs "Amdahlの法則").
    return s.lower() if lang == "en" else re.sub(r"\s+", "", s)


def check(root, lang, lessons, rows):
    other = "ja" if lang == "en" else "en"
    index = {}
    for r in rows:
        index.setdefault(key(r[lang], lang), []).append(r)
    files = {}
    for f in sorted(glob.glob(os.path.join(root, lang, "lessons", "[0-9][0-9]-*.tex"))):
        n = int(os.path.basename(f)[:2])
        if lessons is None or n in lessons:
            files[n] = f
    problems = 0
    for n, f in files.items():
        rel = os.path.relpath(f, root)
        found = {k: [] for k in "abcde"}
        notes = []
        termed, starred = set(), set()
        for line, star, sort, word, gloss in terms_in(f):
            w = word = norm(word)
            cands = index.get(key(w, lang), [])
            if not cands and lang == "en" and sort:
                cands = index.get(key(norm(sort), "en"), [])
            if star:
                starred.update(id(r) for r in cands)
                continue
            if not cands:
                found["c"].append(f"{rel}:{line}: \\term{{{word}}} is not in the glossary")
                continue
            # several rows can share a form (e.g. an acronym used as the JA
            # term): prefer the row whose other-language form is the gloss,
            # then a row owned by this lesson, then a non-"see:" row
            g = norm(gloss) if gloss is not None else None
            cands = sorted(cands, key=lambda r: (
                g is None or key(r[other], other) != key(g, other),
                r["lesson"] != n, r["see"]))
            r = cands[0]
            termed.update(id(c) for c in cands if c["lesson"] == n)
            termed.add(id(r))
            if not any(c["lesson"] == n for c in cands):
                owners = sorted({c["lesson"] for c in cands if c["lesson"] is not None})
                owner = ("lesson " + ", ".join(f"{o:02d}" for o in owners)) if owners else "no lesson"
                found["b"].append(f"{rel}:{line}: \\term{{{word}}} is owned by {owner}")
            if g is None:
                notes.append(f"{rel}:{line}: \\term{{{word}}} has no gloss")
            elif key(g, other) != key(r[other], other):
                found["d"].append(f"{rel}:{line}: \\term{{{word}}} gloss [{gloss}], glossary {other}: {r[other]}")
            if lang == "ja":
                if sort is None:
                    if KANJI.search(w):
                        found["e"].append(f"{rel}:{line}: \\term{{{word}}} has no reading, glossary: {r['reading']}")
                elif key(norm(sort), "ja") != key(r["reading"], "ja"):
                    found["e"].append(f"{rel}:{line}: \\term{{{word}}} reading [{sort}], glossary: {r['reading']}")
        for r in rows:
            if r["lesson"] == n and not r["see"] and id(r) not in termed:
                # the same form may belong to another row that was \term'd
                if any(id(o) in termed for o in index.get(key(r[lang], lang), [])):
                    continue
                extra = " (only \\term*)" if id(r) in starred else ""
                found["a"].append(f"{r[lang]}{extra}")
        count = sum(len(v) for v in found.values())
        problems += count
        if not count and not notes:
            print(f"== {rel}: ok")
            continue
        print(f"== {rel}: {count} finding(s)")
        labels = {"a": "owned by this lesson, never \\term'd",
                  "b": "\\term of a term owned by another lesson",
                  "c": "\\term of a word not in the glossary",
                  "d": "gloss differs from the glossary",
                  "e": "reading differs from the glossary or is missing"}
        for k in "abcde":
            if found[k]:
                print(f"  ({k}) {labels[k]}: {len(found[k])}")
                if k == "a":
                    print("      " + "; ".join(found[k]))
                else:
                    for s in found[k]:
                        print("      " + s)
        if notes:
            print(f"  note: {len(notes)} \\term without a gloss")
            for s in notes:
                print("      " + s)
    return problems, len(files)


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--lang", choices=["en", "ja", "both"], default="both")
    ap.add_argument("--lesson", type=int, action="append",
                    help="lesson number (repeatable); default: all")
    ap.add_argument("--root", default=os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    a = ap.parse_args()
    gpath = os.path.join(a.root, "glossary.tsv")
    if not os.path.exists(gpath):
        print(f"no glossary: {gpath}", file=sys.stderr)
        return 2
    rows = load_glossary(gpath)
    langs = ["en", "ja"] if a.lang == "both" else [a.lang]
    total = 0
    chapters = 0
    for lang in langs:
        p, c = check(a.root, lang, set(a.lesson) if a.lesson else None, rows)
        total += p
        chapters += c
    print(f"== glossary check: {total} finding(s) in {chapters} chapter file(s)")
    return 1 if total else 0


if __name__ == "__main__":
    sys.exit(main())

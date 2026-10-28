export const meta = {
  name: 'notes-proofread',
  description: 'Proofreading pass over a finished latex-lecture-notes book: reviewers read two chapters each (both editions) and report findings; nothing is edited',
  whenToUse: 'In a finished latex-lecture-notes book, for the review step of docs/workflow.md §4. args: {chapters: [1, 2, …], perReviewer?: 2, maxParallel?: 6, repo?: "/abs/path"}. Returns the findings grouped by chapter; vetting and applying them stays with the lead.',
  phases: [{ title: 'Review', detail: 'one reviewer per pair of chapters: facts, scope, EN/JA parity, style; findings only' }],
}

const pad = n => String(n).padStart(2, '0')
const chapters = (args && args.chapters) || []
if (!chapters.length) throw new Error('args.chapters is empty')
if (!chapters.every(Number.isInteger)) throw new Error('args.chapters must be chapter numbers')
const perReviewer = (args && args.perReviewer) || 2
const groups = []
for (let i = 0; i < chapters.length; i += perReviewer) groups.push(chapters.slice(i, i + perReviewer))

const repo = args && args.repo
  ? `Repository: ${args.repo} — work only inside it and run every command from its root.`
  : 'Repository: the current working directory, a book made from latex-lecture-notes-template — work only inside it and run every command from its root.'

// At most maxParallel reviewers in flight (each may build its chapters).
const maxParallel = (args && args.maxParallel) || 6
let running = 0
const waiting = []
const acquire = () => running < maxParallel ? (running++, Promise.resolve()) : new Promise(r => waiting.push(r))
const release = () => { const next = waiting.shift(); if (next) next(); else running-- }

const SEVERITIES = ['ERROR', 'MISMATCH', 'SCOPE', 'STYLE', 'NIT']
const FINDINGS = {
  type: 'object',
  properties: {
    findings: { type: 'array', items: { type: 'object', properties: {
      chapter: { type: 'integer' },
      location: { type: 'string' },
      severity: { type: 'string', enum: SEVERITIES },
      quote: { type: 'string' },
      problem: { type: 'string' },
      replacementEn: { type: 'string' },
      replacementJa: { type: 'string' },
      evidence: { type: 'string' },
    }, required: ['chapter', 'location', 'severity', 'quote', 'problem', 'replacementEn', 'replacementJa', 'evidence'] } },
    toolCandidatesDismissed: { type: 'array', items: { type: 'string' } },
    verdict: { type: 'string' },
  },
  required: ['findings', 'toolCandidatesDismissed', 'verdict'],
}

function prompt(group) {
  const list = group.join(' and ')
  const flags = group.map(n => `--lesson ${n}`).join(' ')
  return `You are a proofreader of a finished bilingual (English/Japanese) book in LaTeX. Report findings only: do NOT edit, create or delete any source file, and do not commit.
${repo}
Read first: docs/style-guide.md (all of it), docs/book.md (source material, textbook, exclusions, real-world numbers), docs/workflow.md §4 (this pass), glossary.tsv.
Your chapters: ${list}. For each: slug from docs/syllabus.json; files en/lessons/<slug>.tex, ja/lessons/<slug>.tex, figures/l<NN>-*.tex, bib/<slug>.bib.

1. Mechanical first step: run tools/glossary-check.py ${flags} and tools/parity-check.py ${flags} --lint. Every item they print is a candidate: turn the real ones into findings, list the others under toolCandidatesDismissed with a one-line reason (e.g. a deliberate anchor difference marked with a % comment, a margin note that legitimately names the lecture, a term deliberately left un-\\term'd).
2. Read both editions of each chapter completely, side by side, with the figures and the bibliography. To see the pages, run tools/chapter-check.sh <en|ja> <slug> (Bash timeout 900000) and read .png/<lang>-<slug>-NN.png; that only writes build output.
3. Check:
   - facts: every claim, number, formula, worked example (recompute it), table cell, trace and figure; every real-world number in the margin is right, current, attributed to a named source, and identical to the same number in other chapters (grep both editions);
   - scope: material beyond the source unit, vendor specifics or later history in the body (they belong in the margin), body text that refers to the delivery medium ("the lecture", "the video", 「講義では」) instead of speaking as the chapter;
   - EN/JA parity: omitted, added or mistranslated clauses, numbers that differ, untranslated English in Japanese prose, margin items, cautions, tips or figures anchored at a different sentence in the two editions;
   - style guide: register, \\term use and ownership, glosses and readings, labels, punctuation (JA ，．), margin rules;
   - bibliography: every entry is a real work with correct authors, title, venue, year.
4. Each finding: chapter number; location file:line; severity — ERROR (wrong fact, number or figure), MISMATCH (EN and JA differ), SCOPE (beyond the unit or in the wrong place), STYLE (a style-guide rule is broken), NIT (typo, punctuation); the quoted text; what is wrong; the concrete replacement in English AND in Japanese (both editions must stay identical in structure; write "unchanged" for an edition that needs nothing); evidence (the recomputation, the source you checked, or the rule number).
Report only what you can support. Taste is not a finding. Verdict: one sentence per chapter.`
}

phase('Review')
const results = await pipeline(groups, async (group) => {
  await acquire()
  try {
    const tag = group.map(pad).join('+')
    const r = await agent(prompt(group), { label: `proofread:${tag}`, phase: 'Review', schema: FINDINGS })
    if (!r) throw new Error('review failed for chapters ' + tag)
    log(`${tag}: ${r.findings.length} findings`)
    return r
  } finally {
    release()
  }
})

// Findings grouped by chapter, ordered by severity; vetting is the lead's.
const rank = s => SEVERITIES.indexOf(s)
const byChapter = {}
for (const n of chapters) byChapter[pad(n)] = []
results.forEach(r => r && r.findings.forEach(f => {
  const k = pad(f.chapter)
  ;(byChapter[k] = byChapter[k] || []).push(f)
}))
for (const k of Object.keys(byChapter)) byChapter[k].sort((a, b) => rank(a.severity) - rank(b.severity))
const counts = {}
for (const s of SEVERITIES) counts[s] = Object.values(byChapter).flat().filter(f => f.severity === s).length
const failed = groups.filter((g, i) => !results[i]).flat()
if (failed.length) log(`not reviewed: chapters ${failed.join(', ')} — rerun them`)
return {
  counts,
  findings: byChapter,
  dismissed: results.filter(Boolean).flatMap(r => r.toolCandidatesDismissed),
  verdicts: results.filter(Boolean).map(r => r.verdict),
  failed,
}

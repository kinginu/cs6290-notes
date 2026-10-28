export const meta = {
  name: 'notes-review',
  description: 'Review pass over finished chapters of a latex-lecture-notes book: technical + scope reviewers in parallel (read-only), then one fixer per chapter that verifies, edits EN, mirrors JA, lints and commits',
  whenToUse: 'In a finished latex-lecture-notes book, for docs/workflow.md §5. args: {chapters: [1, 2, …], maxParallel?: 6, noBuild?: true, repo?: "/abs/path"}. Without a local TeX (env LNOTES_NO_TEX set, or noBuild / "--no-build" in args) agents run tools/chapter-lint.py instead of chapter-check.sh.',
  phases: [
    { title: 'Review', detail: 'technical reviewer (fetches the cited papers) + scope/conventions reviewer, in parallel, read-only' },
    { title: 'Fix', detail: 'verify each finding, edit EN, mirror JA, add accepted margin items, lint, commit-lesson.sh' },
  ],
}

const pad = n => String(n).padStart(2, '0')
const chapters = (args && args.chapters) || []
if (!chapters.length) throw new Error('args.chapters is empty')
if (!chapters.every(Number.isInteger)) throw new Error('args.chapters must be chapter numbers')
const argText = JSON.stringify(args || {})
const noTex = Boolean((typeof process !== 'undefined' && process.env && process.env.LNOTES_NO_TEX)
  || (args && args.noBuild) || argText.includes('--no-build'))

// At most maxParallel chapters in flight (three agents each: with a cap of
// ~20 concurrent agents, 6 chapters is the limit).
const maxParallel = (args && args.maxParallel) || 6
let running = 0
const waiting = []
const acquire = () => running < maxParallel ? (running++, Promise.resolve()) : new Promise(r => waiting.push(r))
const release = () => { const next = waiting.shift(); if (next) next(); else running-- }

const ISSUES = {
  type: 'object',
  properties: {
    issues: { type: 'array', items: { type: 'object', properties: {
      severity: { type: 'string', enum: ['critical', 'major', 'minor'] },
      location: { type: 'string' }, problem: { type: 'string' }, fix: { type: 'string' },
      evidence: { type: 'string' },
    }, required: ['severity', 'location', 'problem', 'fix', 'evidence'] } },
    marginProposals: { type: 'array', items: { type: 'object', properties: {
      anchor: { type: 'string' }, macro: { type: 'string' }, textEn: { type: 'string' }, source: { type: 'string' },
    }, required: ['anchor', 'macro', 'textEn', 'source'] } },
    verdict: { type: 'string' },
  },
  required: ['issues', 'marginProposals', 'verdict'],
}
const FIX = {
  type: 'object',
  properties: {
    applied: { type: 'array', items: { type: 'string' } },
    rejected: { type: 'array', items: { type: 'object', properties: { issue: { type: 'string' }, reason: { type: 'string' } }, required: ['issue', 'reason'] } },
    marginItemsAdded: { type: 'integer' },
    lectureVsPaperCautions: { type: 'integer' },
    glossaryRowsAdded: { type: 'array', items: { type: 'string' } },
    lintClean: { type: 'boolean' },
    buildClean: { type: 'boolean' },
    commitOutput: { type: 'string' },
    remainingProblems: { type: 'array', items: { type: 'string' } },
  },
  required: ['applied', 'rejected', 'marginItemsAdded', 'lectureVsPaperCautions', 'glossaryRowsAdded', 'lintClean', 'buildClean', 'commitOutput', 'remainingProblems'],
}

const repo = args && args.repo
  ? `Repository: ${args.repo} — work only inside it and run every command from its root.`
  : 'Repository: the current working directory, a book made from latex-lecture-notes-template — work only inside it and run every command from its root.'

const checker = noTex
  ? `Checker: there is no local TeX. Run tools/chapter-lint.py <slug> instead of chapter-check.sh (both editions in one run; it must print "ok"), plus tools/parity-check.py --lesson N and tools/glossary-check.py --lesson N. Never start a TeX or Docker build. The rendered pages are not available; the whole book is built by CI after the push (docs/workflow.md §6).`
  : `Checker: tools/chapter-check.sh <en|ja> <slug>  (1–4 min; use a Bash timeout of 900000). It builds the chapter alone, prints a problem summary and renders the pages to .png/<lang>-<slug>-NN.png. Run tools/chapter-lint.py <slug> as well.`

// Same text as common() of notes-chapters.js, with the checker line above.
function common(n) {
  const p = pad(n)
  return `${repo}
Read first, completely: docs/book.md (this book: source material, citation formats, textbook, code language, what is excluded), docs/style-guide.md (rules — follow them exactly), docs/workflow.md §5 (this pass), and the entry with "number": ${n} in docs/syllabus.json (slug, title, source units in order).
Glossary: glossary.tsv (term ownership in column "lesson", canonical English index keys, Japanese terms and readings).
Reference chapters: the ones docs/book.md names under "Reference chapters" (approved style, density and macro use), both editions.
This chapter: number ${n}, file <lang>/lessons/<slug>.tex with the slug from the syllabus. Label prefix l${p} (e.g. fig:l${p}-name). Figures: figures/l${p}-<name>.tex. New bibliography entries only in bib/<slug>.bib; after creating that file run tools/sync-main.py.
${checker}
Git: never commit or push by hand; only the fix stage runs tools/commit-lesson.sh.`
}

function reviewTechPrompt(n) {
  return `You are an adversarial TECHNICAL reviewer of one finished chapter of bilingual notes. Do NOT edit any file.

${common(n)}

Target: en/lessons/<slug>.tex, the figures it inputs (figures/l${pad(n)}-*.tex) and bib/<slug>.bib; ja/lessons/<slug>.tex only to report numbers or facts that differ from the English.

Assume the chapter contains errors and find them. Check:
- every definition, claim, formula, algorithm or protocol step, invariant and code snippet against the field (docs/book.md), the textbook and the source material;
- every cited paper, manual or documentation page: FETCH it (WebFetch; WebSearch for an accessible copy) and READ the relevant part. Every claim the chapter attributes to it must be in it as stated — a number, condition or result that the paper gives differently is a finding. Where the lecture itself simplified the paper, say so: the fix keeps the lecture's statement and adds a \\caution "lecture vs paper" (style guide §1);
- every worked example: recompute every number, check units and magnitudes, re-trace every step of every table or trace;
- every code listing: would it compile/run as shown; is the output shown correct;
- figures: read the TikZ source; the picture must match the text and be technically right;
- margin notes with real-world numbers: is the number right, current, and is its source named;
- bibliography: every entry in bib/<slug>.bib is a real work with correct authors, title, venue, year and URL.
Report only real problems (no style preferences), each with exact location (file:line and the quoted text), what is wrong, the correct fact or recomputation, the precise fix, and the evidence (URL and section of the source you read, or the recomputation). Severity: critical = wrong content a reader would learn; major = misleading or incomplete explanation, wrong example; minor = small inaccuracy. marginProposals: leave empty unless a fetched source gives a number worth a margin note. Verdict: one sentence.`
}

function reviewScopePrompt(n) {
  return `You are a reviewer of one finished chapter of bilingual notes for COVERAGE, FIDELITY TO THE SOURCE and CONVENTIONS. Do NOT edit any file.

${common(n)}

Target: en/lessons/<slug>.tex (+ figures/l${pad(n)}-*.tex); ja/lessons/<slug>.tex for parity.
First run tools/chapter-lint.py <slug> and tools/parity-check.py --lesson ${n} --lint; each item they print is a candidate finding.

Check and report:
1. Coverage: go through every unit of this chapter in docs/syllabus.json ("units") in order and decide whether its content is in the chapter with enough precision to be learned from the notes alone. A missing main concept = major. If the syllabus has no units, say so in the verdict and reconstruct them from the public course outline (WebSearch), not from memory.
2. Scope: material well beyond what the source covers (padding, textbook-only topics) — minor, major if large.
3. Register: remaining delivery-format language (teaching analogies, jokes, "in this video", "let's", "you", rhetorical questions, speaker mentions), also inside \\source.
4. Excluded material (docs/book.md "Excluded"; for a course, anything that looks like a reproduced quiz, exam, homework or project item) — major.
5. Conventions: \\lessoninfo complete; one \\source per section; \\term only for terms this chapter owns in glossary.tsv, with the glossary's gloss, never inside a margin macro, no line break inside a Japanese \\term argument; no sentence-initial \\term; labels prefixed l${pad(n)}; final keypoint summary; every "Lesson N" / 第N章 points to a chapter that actually treats the topic (open it); code lines ≤ 60 columns; \\end{lstlisting} at column 0; no \\tiny.
6. Margin column (style guide §3.1): count margin items (\\source, \\term glosses, \\margin, \\tip, \\caution, \\sidenote, marginfigure); a chapter with clearly fewer than 3 per page is thin. For a thin chapter propose concrete items in marginProposals: the anchor sentence (quoted), the macro, the English text, and its source (a document you checked — never an unsourced real-world number). Flag existing margin notes with real-world numbers and no named source.
7. EN/JA parity: items missing or anchored at a different sentence in the Japanese edition.
Each issue: severity (critical/major/minor), exact location (file:line and quote), problem, precise fix, evidence (rule number or source). Verdict: one sentence.`
}

function fixPrompt(n, issues, proposals) {
  return `Apply review findings to one finished chapter of bilingual notes, in both editions, then commit and push it.

${common(n)}

Files: en/lessons/<slug>.tex, ja/lessons/<slug>.tex, figures/l${pad(n)}-*.tex, bib/<slug>.bib.
Findings from two independent reviewers:
${JSON.stringify(issues, null, 1)}
Proposed margin items:
${JSON.stringify(proposals, null, 1)}

1. Verify each finding yourself — reviewers can be wrong: recompute numbers, re-read the cited source (WebFetch), re-check the rule. If real, fix it (improve on the suggested fix if needed); every real critical and major finding must be fixed. If not real, reject it with a one-line reason.
2. Where the lecture simplifies against the paper, keep the lecture's statement in the body and add a \\caution "lecture vs paper" stating what the paper says (style guide §1).
3. Margin items: add the proposals you can verify (source named in the note or an adjacent \\source), next to their anchor sentence; drop the others with a reason. Keep margin density at most ~3 items per short run of text.
4. Edit the English chapter first, then mirror EVERY change into the Japanese chapter: same items at the same sentence, glossary.tsv terminology, である調, full-width ，．; identical numbers and math.
5. New glossary rows (only if a new \\term is needed): append them with printf '%s\\t%s\\t%s\\t%s\\t\\n' … >> glossary.tsv; never rewrite or reorder glossary.tsv (other agents are appending their rows at the same time).
6. ${noTex ? 'Run tools/chapter-lint.py <slug>, tools/parity-check.py --lesson ' + n + ' and tools/glossary-check.py --lesson ' + n + ' until chapter-lint prints "ok" and the other two report nothing new. Do not run any TeX build.' : 'Run tools/chapter-lint.py <slug> until it prints "ok", then the checker for both editions until clean, and Read the rendered pages that changed.'}
7. Commit and push: tools/commit-lesson.sh <slug> from the repository root (it stages only this lesson's glossary rows). If it fails, report its output; never force-push, reset or rewrite history, and do not commit by hand.
Return applied fixes, rejected findings with reasons, margin items added, lecture-vs-paper cautions added, glossary rows added, lint status, build status (${noTex ? 'false: no local TeX' : 'both editions clean'}), the commit output, and anything unresolved.`
}

const sev = issues => issues.reduce((a, i) => (a[i.severity]++, a), { critical: 0, major: 0, minor: 0 })

async function runChapter(n) {
  const tag = `ch${pad(n)}`
  await acquire()
  try {
    const reviews = await parallel([
      () => agent(reviewTechPrompt(n), { label: `review-tech:${tag}`, phase: 'Review', schema: ISSUES }),
      () => agent(reviewScopePrompt(n), { label: `review-scope:${tag}`, phase: 'Review', schema: ISSUES }),
    ])
    if (reviews.some(r => !r)) throw new Error('review failed for ' + tag)
    const issues = reviews.flatMap(r => r.issues)
    const proposals = reviews.flatMap(r => r.marginProposals)
    const fix = await agent(fixPrompt(n, issues, proposals), { label: `fix:${tag}`, phase: 'Fix', schema: FIX })
    if (!fix) throw new Error('fix failed for ' + tag)
    log(`${tag}: ${issues.length} findings, ${fix.applied.length} applied, ${fix.rejected.length} rejected, +${fix.marginItemsAdded} margin — ${String(fix.commitOutput).slice(0, 80)}`)
    return {
      chapter: n, reviewIssues: sev(issues), proposals: proposals.length,
      verdicts: reviews.map(r => r.verdict),
      applied: fix.applied.length, rejected: fix.rejected,
      marginItemsAdded: fix.marginItemsAdded, lectureVsPaperCautions: fix.lectureVsPaperCautions,
      glossaryRowsAdded: fix.glossaryRowsAdded, lintClean: fix.lintClean, buildClean: fix.buildClean,
      commit: fix.commitOutput, unresolved: fix.remainingProblems,
    }
  } finally {
    release()
  }
}

const results = await pipeline(chapters, runChapter)
const failed = chapters.filter((n, i) => !results[i])
if (failed.length) log(`not finished: chapters ${failed.join(', ')} — check their files and commits, then rerun them`)
if (noTex) log('no local TeX: push done chapter by chapter; read the CI build-logs of the last push with tools/log-summary.py and tools/layout-report.py (docs/workflow.md §6), then run the layout pass (§7) if needed')
return { noTex, results: results.filter(Boolean), failed }

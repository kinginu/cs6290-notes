#!/bin/sh
# Generate dist/index.html linking to the built PDFs (served via GitHub Pages
# from the `pdf` branch).  Usage: pdf-index.sh <title> <repo url> <commit sha>
# The subtitle under the title is $PAGES_SUBTITLE (CI passes the repository
# variable of that name; Settings -> Secrets and variables -> Actions).
#
# One table: a row per format present in dist/ (A4 first, then the print
# sizes), a column per edition and colour mode:
#   dist/notes-<lang>[-<size>].pdf       colour
#   dist/notes-<lang>[-<size>]-gray.pdf  grayscale (make gray)
# Each cell links to the PDF and shows its page count when pdfinfo is
# installed; a missing file is shown as an empty cell.
set -eu
title=$1; repo=$2; sha=$3
subtitle=${PAGES_SUBTITLE:-Lecture notes — English / 日本語}
date=$(date -u +%Y-%m-%d)

# Row label: size and trim in mm, body font (10 pt x the class scale).
size_label() {
  case $1 in
    a4)      echo "A4<span>210×297 · 10 pt · screen</span>" ;;
    a5)      echo "A5<span>148×210 · 7 pt</span>" ;;
    b5)      echo "B5<span>182×257 · 8.5 pt</span>" ;;
    b6)      echo "B6<span>128×182 · 6.5 pt</span>" ;;
    shinsho) echo "新書判<span>113×176 · 6.5 pt</span>" ;;
    *)       echo "$1" ;;
  esac
}
have_pdfinfo=0
command -v pdfinfo >/dev/null 2>&1 && have_pdfinfo=1
cell() {  # cell <file name in dist/> <link text>
  if [ -f "dist/$1" ]; then
    pages=""
    if [ $have_pdfinfo = 1 ]; then
      n=$(pdfinfo "dist/$1" 2>/dev/null | sed -n 's/^Pages: *//p')
      [ -n "$n" ] && pages="<span>$n pp.</span>"
    fi
    echo "<td><a href=\"$1\">$2</a>$pages</td>"
  else
    echo "<td class=\"none\">–</td>"
  fi
}
rows=""
for size in a4 a5 b6 shinsho b5; do
  suffix=-$size; [ $size = a4 ] && suffix=""
  present=0
  for lang in en ja; do
    for g in "" -gray; do
      [ -f "dist/notes-$lang$suffix$g.pdf" ] && present=1
    done
  done
  [ $present = 1 ] || continue
  rows="$rows
<tr><th scope=\"row\">$(size_label $size)</th>
  $(cell notes-en$suffix.pdf colour)
  $(cell notes-en$suffix-gray.pdf gray)
  $(cell notes-ja$suffix.pdf カラー)
  $(cell notes-ja$suffix-gray.pdf グレー)</tr>"
done

cat > dist/index.html <<HTML
<!doctype html>
<html lang="en">
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>${title}</title>
<style>
  body{font-family:system-ui,sans-serif;max-width:46rem;margin:4rem auto;padding:0 1.5rem;line-height:1.6;color:#222}
  h1{font-size:1.6rem;margin-bottom:.25rem}
  .sub{color:#666;margin-top:0}
  .note{color:#666;font-size:.9rem}
  table{border-collapse:collapse;width:100%;margin-top:2rem}
  th,td{border:1px solid #ccd;padding:.6rem .8rem;text-align:left;vertical-align:top}
  thead th{background:#f4f6fa;font-size:.95rem}
  th span,td span{display:block;font-weight:400;color:#666;font-size:.85rem}
  td a{color:#1F4E79;font-weight:600;text-decoration:none}
  td.none{color:#aaa}
  footer{margin-top:3rem;font-size:.85rem;color:#666}
</style>
<h1>${title}</h1>
<p class="sub">${subtitle}</p>
<table>
<thead><tr><th scope="col">Format</th><th scope="col">English</th><th scope="col">English<span>grayscale</span></th><th scope="col">日本語</th><th scope="col">日本語<span>グレースケール</span></th></tr></thead>
<tbody>${rows}
</tbody>
</table>
<p class="note">A4 is the screen edition.  The smaller formats are two-sided
print editions of the same text; the grayscale PDFs are for monochrome
printing and submission.</p>
<footer>Built ${date} from <a href="${repo}/commit/${sha}">${sha}</a> · <a href="${repo}">source</a></footer>
</html>
HTML

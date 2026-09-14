#!/bin/sh
# Generate dist/index.html linking to the built PDFs (served via GitHub Pages
# from the `pdf` branch).  Usage: pdf-index.sh <title> <repo url> <commit sha>
set -eu
title=$1; repo=$2; sha=$3
date=$(date -u +%Y-%m-%d)
cat > dist/index.html <<HTML
<!doctype html>
<html lang="en">
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>${title}</title>
<style>
  body{font-family:system-ui,sans-serif;max-width:40rem;margin:4rem auto;padding:0 1.5rem;line-height:1.6;color:#222}
  h1{font-size:1.6rem;margin-bottom:.25rem}
  .sub{color:#666;margin-top:0}
  ul{list-style:none;padding:0}
  li{margin:.6rem 0}
  a.pdf{display:block;padding:.9rem 1.1rem;border:1px solid #ccd;border-radius:.4rem;text-decoration:none;color:#1F4E79;font-weight:600}
  a.pdf span{display:block;font-weight:400;color:#666;font-size:.9rem}
  footer{margin-top:3rem;font-size:.85rem;color:#666}
</style>
<h1>${title}</h1>
<p class="sub">Lecture notes — English / 日本語</p>
<ul>
  <li><a class="pdf" href="notes-en.pdf">English edition<span>notes-en.pdf</span></a></li>
  <li><a class="pdf" href="notes-ja.pdf">日本語版<span>notes-ja.pdf</span></a></li>
</ul>
<footer>Built ${date} from <a href="${repo}/commit/${sha}">${sha}</a> · <a href="${repo}">source</a></footer>
</html>
HTML

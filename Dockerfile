# TeX Live 2025 (full scheme, no docs) pinned for reproducible builds.
# The same image is used by `make docker-*`, the VS Code dev container and CI.
# The base image already ships make, git, latexmk, biber, upmendex and a
# non-root user `texlive` (uid 1000), so nothing needs to be installed.
FROM texlive/texlive:TL2025-historic

USER texlive
WORKDIR /work
CMD ["bash"]

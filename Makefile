# Build targets.  Run inside the Docker container (or any TeX Live 2025).
#   make en / make ja / make all      build en/build/main.pdf, ja/build/main.pdf
#   make dist                         copy PDFs to dist/notes-<lang>.pdf
#   make clean
#   make docker-<target>              run <target> inside the container
#   make docker-shell                 interactive shell in the container
LATEXMK    ?= latexmk
LANGS      := en ja
DOCKER_RUN := docker compose run --rm tex

.PHONY: all $(LANGS) dist clean distclean docker-build docker-shell $(addprefix docker-,all $(LANGS) dist clean)

all: $(LANGS)

$(LANGS):
	$(LATEXMK) -cd $@/main.tex

dist: $(LANGS)
	mkdir -p dist
	$(foreach l,$(LANGS),cp $(l)/build/main.pdf dist/notes-$(l).pdf;)

clean:
	$(foreach l,$(LANGS),$(LATEXMK) -cd -C $(l)/main.tex;)
	rm -rf $(foreach l,$(LANGS),$(l)/build $(l)/lessons/build)

distclean: clean
	rm -rf dist

docker-build:
	docker compose build

docker-shell:
	$(DOCKER_RUN) bash

docker-%:
	$(DOCKER_RUN) make $*

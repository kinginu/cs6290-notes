# Build targets.  Run inside the Docker container (or any TeX Live 2025).
#   make en / make ja / make all      build en/build/main.pdf, ja/build/main.pdf
#   make dist                         copy PDFs to dist/notes-<lang>.pdf
#   make en-a5 / ja-b6 / ...          print edition <lang>/build/main-<size>.pdf
#   make print-<size>                 both languages, copied to
#                                     dist/notes-<lang>-<size>.pdf
#   make print                        every print size
#   make clean
#   make docker-<target>              run <target> inside the container
#   make docker-shell                 interactive shell in the container
LATEXMK    ?= latexmk
LANGS      := en ja
SIZES      := a5 b6 shinsho b5
DOCKER_RUN := docker compose run --rm tex

LANG_SIZES  := $(foreach l,$(LANGS),$(addprefix $(l)-,$(SIZES)))
PRINT_SIZES := $(addprefix print-,$(SIZES))

.PHONY: all $(LANGS) $(LANG_SIZES) $(PRINT_SIZES) print dist clean distclean docker-build docker-shell

all: $(LANGS)

$(LANGS):
	$(LATEXMK) -cd $@/main.tex

# en-a5 -> latexmk -jobname=main-a5 with print=a5 passed to the class
$(LANG_SIZES):
	$(LATEXMK) -cd -jobname=main-$(lastword $(subst -, ,$@)) \
	  '-pretex=\PassOptionsToClass{print=$(lastword $(subst -, ,$@))}{lnotes}' \
	  $(firstword $(subst -, ,$@))/main.tex

$(PRINT_SIZES): print-%: $(addsuffix -%,$(LANGS))
	mkdir -p dist
	$(foreach l,$(LANGS),cp $(l)/build/main-$*.pdf dist/notes-$(l)-$*.pdf;)

print: $(PRINT_SIZES)

dist: $(LANGS)
	mkdir -p dist
	$(foreach l,$(LANGS),cp $(l)/build/main.pdf dist/notes-$(l).pdf;)

# Removing the build directories also removes the print jobs (main-<size>.*).
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

# Pipeline de los boletines IES
#   Diagramas: <Boletin NN>/Diagramas/*.d2 -> .svg -> .pdf vectorial
#   Boletín:   <Boletin NN>/*.md -> .tex / .pdf editorial
#
# Uso:
#   make diagramas
#   make boletin
#   make boletin SRC="<Boletin NN>/<archivo>.md"
#   make todo
#   make limpiar
#   make ayuda
#
# Variable BOLETIN (por defecto, el directorio "Boletin NN" más reciente):
#   make todo BOLETIN="Boletin 02"
#
SHELL := /bin/bash
.DEFAULT_GOAL := ayuda

# Directorio de boletín por defecto: el más reciente (orden natural).
BOLETIN ?= $(shell ls -d Boletin* 2>/dev/null | sort -V | tail -1)

DIAGRAMAS_SCRIPT := .opencode/skills/diagramas-d2-pdf/scripts/d2-to-pdf.sh
BOLETIN_SCRIPT   := .opencode/skills/boletin-latex-pdf/scripts/build-boletin.sh
SKILLS_SCRIPTS   := $(dir $(DIAGRAMAS_SCRIPT))

# Fuente del boletín: el .md de boletín más reciente dentro de BOLETIN.
SRC ?= $(shell ls -t "$(BOLETIN)"/*[Bb]oletin*.md 2>/dev/null | head -1)

.PHONY: ayuda diagramas boletin todo limpiar

ayuda:
	@echo "make diagramas                     # .d2 -> .svg + .pdf vectorial"
	@echo "make boletin                      # compila el .md del boletín (BOLETIN)"
	@echo "make boletin SRC=\"<Boletin NN>/<x>.md\"   # compila un boletín concreto"
	@echo "make BOLETIN=\"Boletin 02\" todo     # elige el directorio del boletín"
	@echo "make limpiar                      # borra .svg y .pdf de <BOLETIN>/Diagramas/"

diagramas:
	@EXTRAER="$(SKILLS_SCRIPTS)extraer-d2.sh"; \
	if [[ ! -x "$$EXTRAER" ]]; then echo "Error: falta '$$EXTRAER'" >&2; exit 1; fi; \
	"$$EXTRAER" "$(SRC)"
	@if [[ ! -d "$(BOLETIN)/Diagramas" ]]; then echo "No hay diagramas en '$(BOLETIN)/Diagramas/'"; exit 0; fi
	@find "$(BOLETIN)/Diagramas" -maxdepth 1 -name '*.d2' -exec "$(DIAGRAMAS_SCRIPT)" {} \;

boletin:
	@if [[ -z "$(SRC)" ]]; then echo "No se encontró boletín .md en '$(BOLETIN)' (usa SRC=...)"; exit 1; fi
	@"$(BOLETIN_SCRIPT)" "$(SRC)"

todo: diagramas boletin

limpiar:
	@rm -f "$(BOLETIN)/Diagramas/"*.svg "$(BOLETIN)/Diagramas/"*.pdf
	@echo "Intermedios de '$(BOLETIN)/Diagramas/' eliminados."

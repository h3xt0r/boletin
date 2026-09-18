# Pipeline de los boletines IES
#   Fuente:   <Boletin NN>/YYYY-MM-DD-Boletin-NN: ....md   (diagramas ```text / ```d2)
#   Trabajo:  <Boletin NN>/Boletin-NN: ....md              (sin fecha, ligas a Diagramas/*.pdf)
#   Diagramas: <Boletin NN>/Diagramas/*.d2 -> .svg -> .pdf vectorial
#   Boletín:   <Boletin NN>/<trabajo>.md  ->  .tex / .pdf editorial
#
# La fuente con fecha NUNCA se modifica (es la que se publica en la web); el .md
# de trabajo (sin fecha) se genera a partir de ella y es el que compila pandoc.
#
# Uso:
#   make trabajo [BOLETIN="Boletin NN"]         # fuente con ```d2 -> .md de trabajo
#   make diagramas [BOLETIN="Boletin NN"]       # .d2 -> .svg + .pdf vectorial
#   make boletin [BOLETIN="Boletin NN"]         # compila el .md de trabajo
#   make boletin WORK="<Boletin NN>/<x>.md"     # compila un .md de trabajo concreto
#   make todo BOLETIN="Boletin 02"              # trabajo + diagramas + boletín
#   make limpiar [BOLETIN="Boletin NN"]         # borra .svg/.pdf de Diagramas/
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
EXTRAER_SCRIPT   := .opencode/skills/diagramas-d2-pdf/scripts/extraer-d2.sh

# Fuente del boletín: el .md con fecha (YYYY-MM-DD-Boletin...) más reciente.
SRC ?= $(shell ls "$(BOLETIN)"/????-??-??-Boletin*.md 2>/dev/null | sort | tail -1)

# .md de trabajo: mismo directorio y nombre que la fuente, sin el prefijo de fecha.
WORK ?= $(shell src="$(SRC)"; d="$$(dirname "$$src")"; b="$$(basename "$$src" .md)"; b="$${b#????-??-??-}"; echo "$$d/$$b.md")

.PHONY: ayuda trabajo diagramas boletin todo limpiar

ayuda:
	@echo "make trabajo [BOLETIN=...]          # extrae los ```d2 y escribe el .md de trabajo"
	@echo "make diagramas [BOLETIN=...]         # .d2 -> .svg + .pdf vectorial de '$(BOLETIN)'"
	@echo "make boletin [BOLETIN=...]           # compila el .md de trabajo del boletín"
	@echo "make boletin WORK=\"<Boletin NN>/<x>.md\"   # compila un .md de trabajo concreto"
	@echo "make todo BOLETIN=\"Boletin 02\"      # trabajo + diagramas + boletín"
	@echo "make limpiar [BOLETIN=...]           # borra .svg y .pdf de <BOLETIN>/Diagramas/"

trabajo:
	@if [[ -z "$(SRC)" ]]; then echo "No se encontró fuente .md con fecha en '$(BOLETIN)' (usa SRC=...)"; exit 1; fi
	@"$(EXTRAER_SCRIPT)" "$(SRC)" "$(WORK)"

diagramas:
	@if [[ ! -d "$(BOLETIN)/Diagramas" ]]; then echo "No hay diagramas en '$(BOLETIN)/Diagramas/'"; exit 0; fi
	@find "$(BOLETIN)/Diagramas" -maxdepth 1 -name '*.d2' -exec "$(DIAGRAMAS_SCRIPT)" {} \;

boletin:
	@if [[ -z "$(WORK)" || ! -f "$(WORK)" ]]; then \
	  echo "Falta el .md de trabajo: '$(WORK)'" >&2; \
	  echo "Genéralo a partir de '$(SRC)' (intake ```d2: make trabajo; diagramas ```text: traducción manual)." >&2; \
	  exit 1; \
	fi
	@"$(BOLETIN_SCRIPT)" "$(WORK)"

todo: trabajo diagramas boletin

limpiar:
	@rm -f "$(BOLETIN)/Diagramas/"*.svg "$(BOLETIN)/Diagramas/"*.pdf
	@echo "Intermedios de '$(BOLETIN)/Diagramas/' eliminados."

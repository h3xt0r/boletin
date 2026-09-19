#!/usr/bin/env bash
#
# Publica un boletín de ESTE repositorio (boletines) en la sección web boletin/
# del repositorio del sitio (~/Git/iesencial.com por defecto).
#
# Toma el .md de trabajo (imprenta) del boletín, que ya contiene el texto
# final, los pies y la posición de los diagramas, y produce la copia web:
#
#   <WEB_REPO>/boletin/YYYY-MM-DD-Boletin-NN: Nombre.md
#     · la fecha se toma del prefijo del archivo fuente (dated);
#     · Diagramas/<figura>.pdf  ->  diagramas/<Boletin-NN-slug>/<figura>.svg;
#     · se desescapan los \$ de importes (escapado de LaTeX) a $ para la web.
#   <WEB_REPO>/boletin/diagramas/<Boletin-NN-slug>/  <- .svg copiados.
#
# La fuente y el .md de trabajo nunca se modifican.
#
# POR QUÉ VIVE AQUÍ Y NO EN EL REPO DEL SITIO:
#   el repo de boletines (con sus PDFs) NO existe en el servidor, donde solo se
#   clona iesencial.com. Una herramienta que dependa de él nunca podría
#   ejecutarse allá, así que se mantiene en desarrollo: se corre aquí y escribe
#   en iesencial.com, que es lo que luego viaja al servidor.
#
# Uso (desde la raíz de este repo):
#   scripts/publicar-web.sh                          # boletín más reciente
#   scripts/publicar-web.sh BOLETIN="Boletin 06"
#   scripts/publicar-web.sh BOLETIN="Boletin 06" WEB_REPO=/ruta/al/repo/del/sitio
#   make publicar BOLETIN="Boletin 06"
set -euo pipefail

BOLETINES_REPO="$(cd "$(dirname "$0")/.." && pwd)"
WEB_REPO="${WEB_REPO:-$HOME/Git/iesencial.com}"
BOLETIN="${BOLETIN:-}"

# Acepta los ajustes como argumentos (BOLETIN="Boletin 06" o WEB_REPO=...) o en
# el entorno.
for arg in "$@"; do
  case "$arg" in
    BOLETIN=*)      BOLETIN="${arg#BOLETIN=}" ;;
    WEB_REPO=*)     WEB_REPO="${arg#WEB_REPO=}" ;;
    *) echo "Uso: scripts/publicar-web.sh [BOLETIN=\"Boletin NN\"] [WEB_REPO=/ruta]" >&2; exit 1 ;;
  esac
done

# 1. Directorio del boletín (por defecto el más reciente de este repo).
if [[ -z "$BOLETIN" ]]; then
  latest="$(ls -1d "$BOLETINES_REPO"/Boletin*/ 2>/dev/null | sort -V | tail -1 || true)"
  [[ -n "$latest" ]] || { echo "ERROR: no hay boletines en '$BOLETINES_REPO'." >&2; exit 1; }
  BOLETIN="$(basename "${latest%/}")"
fi
BOLETIN_DIR="$BOLETINES_REPO/$BOLETIN"
if [[ ! -d "$BOLETIN_DIR" ]]; then
  echo "ERROR: no existe el directorio '$BOLETIN_DIR'." >&2
  exit 1
fi
if [[ ! -d "$WEB_REPO/boletin" ]]; then
  echo "ERROR: no existe el repo del sitio ('$WEB_REPO/boletin'). Usa WEB_REPO=..." >&2
  exit 1
fi

# 2. Fuente (con fecha) y .md de trabajo (imprenta).
SRC="$(ls "$BOLETIN_DIR"/????-??-??-Boletin*.md 2>/dev/null | head -1 || true)"
WORK="$(ls "$BOLETIN_DIR"/Boletin-*.md 2>/dev/null | head -1 || true)"
if [[ ! -f "$SRC" ]]; then
  echo "ERROR: falta la fuente (????-??-??-Boletin*.md) en '$BOLETIN_DIR'." >&2
  exit 1
fi
if [[ ! -f "$WORK" ]]; then
  echo "ERROR: falta el .md de trabajo (Boletin-*.md) en '$BOLETIN_DIR'." >&2
  echo "       Ejecuta primero: make trabajo BOLETIN=\"$BOLETIN\"" >&2
  exit 1
fi

DATE="$(basename "$SRC" | cut -c1-10)"                       # 2026-09-10
WORK_BASE="$(basename "$WORK")"                             # Boletin-06: Nombre.md
WEB_NAME="$DATE-$WORK_BASE"                                 # 2026-09-10-Boletin-06: Nombre.md
SLUG="$(basename "$WORK" .md | sed -e 's/["  :]/-/g' -e 's/--*/-/g' -e 's/^-//' -e 's/-$//')"

# 3. Copia web: ligas de diagrama -> .svg + desescapado de \$ (LaTeX).
WEB_TMP="$(mktemp)"
trap 'rm -f "$WEB_TMP"' EXIT
SLUG="$SLUG" python3 - "$WORK" > "$WEB_TMP" <<'PY'
import os, re, sys
slug = os.environ["SLUG"]
src = open(sys.argv[1], encoding="utf-8").read()
out = re.sub(r'!\[(.*?)\]\(Diagramas/([^()]+)\.pdf\)',
             r'![\1](diagramas/' + slug + r'/\2.svg)', src)
out = out.replace(r'\$', '$')   # importes en dólares: el escape de LaTeX no aplica en web
sys.stdout.write(out)
PY

# 4. Copiar los .svg del boletín a <WEB_REPO>/boletin/diagramas/<slug>/.
DEST_DIR="$WEB_REPO/boletin/diagramas/$SLUG"
mkdir -p "$DEST_DIR"
cp "$BOLETIN_DIR"/Diagramas/*.svg "$DEST_DIR/"

# 5. Verificación: cada diagrama referenciado debe existir como .svg.
missing=0
while IFS= read -r stem; do
  if [[ ! -f "$DEST_DIR/$stem.svg" ]]; then
    echo "  FALTA el .svg de: Diagramas/$stem.pdf" >&2
    missing=1
  fi
done < <(grep -o 'Diagramas/[^)]*\.pdf' "$WORK" | sed 's#Diagramas/##; s#\.pdf$##' | sort -u)
if [[ "$missing" -ne 0 ]]; then
  echo "ERROR: faltan diagramas .svg; ejecuta 'make diagramas' aquí." >&2
  exit 1
fi

mv "$WEB_TMP" "$WEB_REPO/boletin/$WEB_NAME"
trap - EXIT

echo "==> Publicado en la web ($WEB_REPO):"
echo "    boletin/$WEB_NAME"
echo "    slug     : $SLUG"
echo "    .svg     : $(find "$DEST_DIR" -name '*.svg' | wc -l) en boletin/diagramas/$SLUG"
echo "    fuente   : $SRC  (sin modificar)"
echo "    trabajo  : $(dirname "$WORK")/$(basename "$WORK")  (sin modificar)"
echo
echo "Pendiente manual:"
echo "  git -C \"$WEB_REPO\" add \"boletin/$WEB_NAME\" \"boletin/diagramas/$SLUG\""
echo "  git -C \"$WEB_REPO\" commit -m \"boletin: publicar $WEB_NAME\""
#!/usr/bin/env bash
#
# build-boletin.sh — Boletín Markdown -> PDF editorial (+ .tex) con pandoc
#
# Uso:
#   build-boletin.sh <boletin.md> [salida_base] [--pdf|--tex|--ambos]
#
# Por defecto genera <salida_base>.pdf y <salida_base>.tex. Si no se indica
# "salida_base", se usa el nombre del .md saneado (sin ':' ni espacios) en su
# mismo directorio. Las imágenes del .md se resuelven relativas a ese directorio,
# de modo que el boletín puede vivir en su propia carpeta (p. ej. "Boletin 02").
#
# La tipografía y la geometría las decide LaTeX a partir de la plantilla mínima
# assets/boletin.tex (carta, 12pt, español): aquí no se imponen tamaños de letra
# ni márgenes.
#
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
template="$script_dir/../assets/boletin.tex"

uso() {
  echo "Uso: $(basename "$0") <boletin.md> [salida_base] [--pdf|--tex|--ambos]" >&2
  exit 2
}

[[ $# -ge 1 && $# -le 3 ]] || uso

src="$1"
mode="${3:---ambos}"
srcdir="$(dirname "$src")"
[[ -f "$src" ]] || { echo "Error: no existe '$src'" >&2; exit 1; }
[[ -f "$template" ]] || { echo "Error: no existe la plantilla '$template'" >&2; exit 1; }

# Membrete de fondo (todas las hojas): vive junto a la plantilla. Se pasa como
# variable de template con RUTA ABSOLUTA porque pandoc ejecuta pdflatex desde
# un directorio temporal y no copia los recursos del preámbulo (solo los del
# cuerpo, via --resource-path).
membrete="$script_dir/../assets/membrete.pdf"
if [[ ! -f "$membrete" ]]; then
  echo "Error: no existe el membrete de fondo '$membrete'" >&2
  echo "Cópialo junto a la plantilla: .opencode/skills/boletin-latex-pdf/assets/membrete.pdf" >&2
  exit 1
fi
membrete_abs="$(cd -- "$(dirname -- "$membrete")" && pwd)/$(basename -- "$membrete")"

# salida_base: parámetro, o nombre saneado en el mismo directorio del .md
if [[ -n "${2:-}" ]]; then
  base="$2"
else
  limpio="$(basename "$src" .md)"
  limpio="${limpio#????-??-??-}"   # quita un prefijo de fecha YYYY-MM-DD-
  limpio="$(printf '%s' "$limpio" | sed -E 's/[^A-Za-z0-9._-]+/-/g; s/-+/-/g; s/^-+//; s/-+$//')"
  base="$srcdir/$limpio"
fi

for t in pandoc pdflatex; do
  command -v "$t" >/dev/null 2>&1 || { echo "Error: falta '$t' en el PATH" >&2; exit 1; }
done

# Aviso: diagramas referenciados que no existan (relativos al directorio del .md)
while IFS= read -r img; do
  [[ -z "$img" ]] && continue
  [[ "$img" == http* ]] && continue
  case "$img" in
    /*) candidato="$img" ;;
    *)  candidato="$srcdir/$img" ;;
  esac
  [[ -f "$candidato" ]] || echo "Advertencia: imagen no encontrada -> $candidato" >&2
done < <(grep -oE '\]\([^)]+\.(pdf|svg|png)\)' "$src" | sed -E 's/^\]\(//; s/\)$//' || true)

opciones=(
  # Modo matemático activado: convierte $I$, $T$, $\neq$ en fórmulas.
  # Los importes en dólares van SIEMPRE escapados en el .md (\$6,000M,
  # \$160 billones): un $ suelto puede cerrarse con un $ posterior válido
  # y volver matemático el texto intermedio (caso Boletín 04).
  --from=markdown+tex_math_dollars
  --resource-path="$srcdir"
  --template="$template"
  # Fondo (membrete) en todas las páginas; ruta absoluta (ver arriba).
  -V "membrete=$membrete_abs"
)

if [[ "$mode" == "--pdf" || "$mode" == "--ambos" ]]; then
  echo "→ PDF: ${base}.pdf"
  pandoc "$src" "${opciones[@]}" --pdf-engine=pdflatex -o "${base}.pdf"
  if command -v pdfinfo >/dev/null 2>&1; then
    pdfinfo "${base}.pdf" | grep -E '^(Pages|Page size):'
  fi
fi

if [[ "$mode" == "--tex" || "$mode" == "--ambos" ]]; then
  echo "→ LaTeX: ${base}.tex"
  pandoc "$src" "${opciones[@]}" -s -t latex --pdf-engine=pdflatex -o "${base}.tex"
fi

echo "✔ Boletín listo: ${base}"

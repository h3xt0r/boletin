#!/usr/bin/env bash
#
# d2-to-pdf.sh — Diagrama D2 -> SVG -> PDF vectorial
#
# Uso:
#   d2-to-pdf.sh <archivo.d2> [directorio_salida]
#
# Genera <base>.svg y <base>.pdf en el directorio indicado (por defecto, el
# mismo directorio del .d2).
#
# Motor de conversión (variable D2PDF_ENGINE):
#   mutool  (por defecto) PDF 100 % vectorial, 0 imágenes raster.
#   rsvg    rsvg-convert (cairo); vectorial en trazos y texto, pero añade
#           máscaras alfa de las cajas de los nodos.
#
set -euo pipefail

uso() {
  echo "Uso: $(basename "$0") <archivo.d2> [directorio_salida]" >&2
  echo "     D2PDF_ENGINE=mutool|rsvg (por defecto: mutool)" >&2
  exit 2
}

[[ $# -ge 1 && $# -le 2 ]] || uso

src="$1"
[[ -f "$src" ]] || { echo "Error: no existe '$src'" >&2; exit 1; }

outdir="${2:-$(dirname "$src")}"
mkdir -p "$outdir"
base="$(basename "$src" .d2)"
svg="$outdir/$base.svg"
pdf="$outdir/$base.pdf"

engine="${D2PDF_ENGINE:-mutool}"
case "$engine" in
  mutool) need=(d2 mutool) ;;
  rsvg)   need=(d2 rsvg-convert) ;;
  *) echo "Error: D2PDF_ENGINE debe ser 'mutool' o 'rsvg' (recibido: '$engine')" >&2; exit 2 ;;
esac

for t in "${need[@]}"; do
  command -v "$t" >/dev/null 2>&1 || { echo "Error: falta '$t' en el PATH" >&2; exit 1; }
done

echo "→ SVG: $svg"
d2 "$src" "$svg"

echo "→ PDF vectorial ($engine): $pdf"
case "$engine" in
  mutool) mutool convert -F pdf -o "$pdf" "$svg" >/dev/null ;;
  rsvg)   rsvg-convert -f pdf -o "$pdf" "$svg" ;;
esac

if command -v pdfinfo >/dev/null 2>&1; then
  pdfinfo "$pdf" | grep -E '^(Pages|Page size):'
fi

echo "✔ Diagrama listo: $pdf"

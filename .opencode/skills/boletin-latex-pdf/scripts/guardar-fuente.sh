#!/usr/bin/env bash
#
# guardar-fuente.sh — Conserva el .md ORIGINAL de un boletín
#
# Uso:
#   guardar-fuente.sh <boletin.md>
#
# Copia el .md tal cual a "<dir>/Fuente/<nombre>.md" para poder rehacer el
# proceso desde cero (con los bloques ```text / ```d2 originales intactos).
#
# El .md de la raíz del boletín es la versión de TRABAJO (con las ligas a
# Diagramas/*.pdf); la copia en Fuente/ es la fuente inmutable. Nunca se
# sobrescribe una fuente ya guardada.
#
set -euo pipefail

[[ $# -eq 1 ]] || { echo "Uso: $(basename "$0") <boletin.md>" >&2; exit 2; }

src="$1"
[[ -f "$src" ]] || { echo "Error: no existe '$src'" >&2; exit 1; }

dir="$(dirname -- "$src")"
base="$(basename -- "$src")"
dest_dir="$dir/Fuente"
dest="$dest_dir/$base"

if [[ -e "$dest" ]]; then
  echo "Fuente ya guardada (no se sobrescribe): $dest"
  exit 0
fi

mkdir -p -- "$dest_dir"
cp -- "$src" "$dest"
echo "✔ Fuente guardada: $dest"

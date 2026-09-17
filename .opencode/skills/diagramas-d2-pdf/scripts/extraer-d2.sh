#!/usr/bin/env bash
#
# extraer-d2.sh — Extrae los bloques ```d2 de un boletín Markdown
#
# Uso:
#   extraer-d2.sh <boletin.md>
#
# Para cada bloque fenced con lenguaje `d2` (en orden de aparición):
#   1. Nombra el diagrama `Diagramas/figura-<N>.d2` (numeración automática).
#   2. Escapa `$` sueltos dentro de las etiquetas (`\$`) para que d2 los
#      trate como literales (montos y variables: $6,000M, $T$, $O$, …).
#   3. Valida que el bloque compile con `d2` antes de tocar el .md; si falla,
#      aborta sin modificar nada.
#   4. Sustituye el bloque por una imagen PDF vectorial:
#      `![<pie>](Diagramas/figura-<N>.pdf)`
#      El pie se toma de la primera línea de comentario (`# Título`) del
#      bloque o, si no hay, de la primera etiqueta de nodo.
#
# Si el boletín no trae bloques ```d2, no hace nada (compatible con el
# intake anterior de bloques ```text).
#
set -euo pipefail

uso() {
  echo "Uso: $(basename "$0") <boletin.md>" >&2
  exit 2
}

[[ $# -eq 1 ]] || uso
src="$1"
[[ -f "$src" ]] || { echo "Error: no existe '$src'" >&2; exit 1; }
command -v d2 >/dev/null 2>&1 || { echo "Error: falta 'd2' en el PATH" >&2; exit 1; }

python3 - "$src" <<'PYEOF'
import os
import re
import shutil
import subprocess
import sys
import tempfile

src = sys.argv[1]


def escapar_dolares(contenido: str) -> str:
    """Escapa $ dentro de las etiquetas d2 (": ...") dejando los \\$ ya escapados."""
    def rep(m: re.Match) -> str:
        s = m.group(1)
        return '"' + re.sub(r'(?<!\\)\$', r'\$', s) + '"'
    return re.sub(r'"((?:[^"\\]|\\.)*)"', rep, contenido)


def obtener_pie(contenido: str, idx: int) -> str:
    """Pie de figura: primer comentario '# Título'; si no, primera etiqueta de nodo."""
    for linea in contenido.splitlines():
        l = linea.strip()
        if not l:
            continue
        if l.startswith('#'):
            t = l.lstrip('#').strip()
            return t if t else "Diagrama %d" % idx
        break
    m = re.search(r'^\s*[A-Za-z0-9_"\'][\w ".\'-]*\s*:\s*"([^"]+)"', contenido, re.M)
    if m:
        t = m.group(1).replace('\\n', ' ').strip()
        return (t[:79].rstrip() + '…') if len(t) > 80 else t
    return "Diagrama %d" % idx


def validar(contenido: str, idx: int) -> None:
    """Comprueba que el bloque compila con d2 (en /tmp/opencode) y aborta si no."""
    tmpdir = '/tmp/opencode'
    os.makedirs(tmpdir, exist_ok=True)
    fd, tmp = tempfile.mkstemp(suffix='.d2', dir=tmpdir)
    os.close(fd)
    svg = tmp[:-3] + '.svg'
    try:
        with open(tmp, 'w', encoding='utf-8') as f:
            f.write(contenido + '\n')
        r = subprocess.run(['d2', tmp, svg], capture_output=True, text=True)
    finally:
        for p in (tmp, svg):
            try:
                os.remove(p)
            except OSError:
                pass
    if r.returncode != 0:
        print("Error: el bloque ```d2 (figura-%d) no compila en %s" % (idx, src), file=sys.stderr)
        print(r.stderr, file=sys.stderr)
        sys.exit(1)


with open(src, encoding='utf-8') as f:
    texto = f.read()

fence = re.compile(r'^(`{3,})[ \t]*d2[ \t]*\n(.*?)\n^\1[ \t]*$', re.M | re.S)
bloques = list(fence.finditer(texto))
if not bloques:
    print("Sin bloques ```d2 en: %s" % src)
    sys.exit(0)

# Preserva el .md ORIGINAL (con los bloques ```d2 intactos) en Fuente/ antes de
# mutarlo. Nunca sobrescribe una fuente ya guardada, para poder rehacer el
# proceso desde cero.
fuente_dir = os.path.join(os.path.dirname(src), 'Fuente')
fuente = os.path.join(fuente_dir, os.path.basename(src))
if not os.path.exists(fuente):
    os.makedirs(fuente_dir, exist_ok=True)
    shutil.copyfile(src, fuente)
    print("→ Fuente preservada: %s" % fuente)

out = []
last = 0
for i, m in enumerate(bloques, 1):
    contenido = m.group(2)
    contenido = escapar_dolares(contenido)
    pie = obtener_pie(contenido, i)
    validar(contenido, i)

    d = os.path.join(os.path.dirname(src), 'Diagramas')
    os.makedirs(d, exist_ok=True)
    d2_path = os.path.join(d, 'figura-%d.d2' % i)
    with open(d2_path, 'w', encoding='utf-8') as f:
        f.write(contenido + '\n')

    out.append(texto[last:m.start()])
    out.append('\n![%s](Diagramas/figura-%d.pdf)\n' % (pie, i))
    last = m.end()
    print("→ %s   (pie: %s)" % (d2_path, pie))

out.append(texto[last:])
with open(src, 'w', encoding='utf-8') as f:
    f.write(''.join(out))

print("✔ %d bloque(s) ```d2 extraído(s): %s" % (len(bloques), src))
PYEOF
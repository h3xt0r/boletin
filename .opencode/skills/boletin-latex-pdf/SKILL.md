---
name: Boletín LaTeX/PDF editorial
description: Compila un boletín Markdown a un PDF de calidad editorial (tamaño carta, español) y a su documento .tex standalone con pandoc + LaTeX, incrustando los diagramas PDF vectoriales. Úsalo para generar o regenerar el PDF/LaTeX de un boletín.
---

# Boletín Markdown → LaTeX / PDF editorial

Produce el PDF final del boletín y, opcionalmente, el `.tex` standalone, con
pandoc y `pdflatex`. Cada boletín vive en su propio directorio `Boletin NN/`.

## Cuándo usarlo

- Hay que generar el PDF de un boletín a partir de su `.md`.
- Se quiere además el documento LaTeX standalone.
- Hay que regenerar el PDF tras cambiar el texto o los diagramas.

## Requisitos

- `pandoc` y `pdflatex` (TeX Live).
- Los diagramas ya convertidos a **PDF vectorial** (skill `diagramas-d2-pdf`).

## Antes de compilar

1. Los diagramas del `.md` deben referenciarse como **imágenes PDF**, con ruta
   relativa al directorio del boletín:

   ```markdown
   ![Nube de Evaporación del Conflicto](Diagramas/nube-evaporacion-conflicto.pdf)
   ```

   Reemplaza cada bloque ` ```text ` por su referencia.
2. **No** añadas `{width=...}`: deja que LaTeX escale. La plantilla de pandoc
   ajusta la imagen al ancho de caja con `keepaspectratio` y no la deforma.

## Compilar

PDF tamaño carta con el motor `pdflatex` (usa `<Boletin NN>/<archivo>.md`):

```bash
pandoc "<Boletin NN>/<archivo>.md" \
  --from=markdown+tex_math_dollars \
  --resource-path="<Boletin NN>" \
  --pdf-engine=pdflatex \
  -V geometry:letterpaper -V geometry:margin=2.5cm \
  -V fontsize=11pt -V lang=es \
  --include-in-header=.opencode/skills/boletin-latex-pdf/assets/editorial.tex \
  -o "<Boletin NN>/<salida>.pdf"
```

Documento LaTeX standalone:

```bash
pandoc "<Boletin NN>/<archivo>.md" \
  --from=markdown+tex_math_dollars --resource-path="<Boletin NN>" \
  -s -t latex --pdf-engine=pdflatex \
  -V geometry:letterpaper -V geometry:margin=2.5cm \
  -V fontsize=11pt -V lang=es \
  --include-in-header=.opencode/skills/boletin-latex-pdf/assets/editorial.tex \
  -o "<Boletin NN>/<salida>.tex"
```

Atajo: `scripts/build-boletin.sh "<Boletin NN>/<archivo>.md"` genera `.pdf` y `.tex`
en el directorio del boletín.

## Claves de calidad editorial

- **`--from=markdown+tex_math_dollars`**: activa el modo matemático de `$` para las
  variables (`$I$`, `$T$`, `$\neq$`). **Los importes en dólares se escapan siempre**
  (`\$160 billones`, `\$6,000M`, `\$30,000–\$40,000`): un `$` suelto puede cerrarse
  con otro `$` válido más adelante en el párrafo y volver matemático todo lo de en
  medio (caso real en Boletín 04 con `\$6,000M en recompras`).
- **`--resource-path`**: resuelve las imágenes relativas al directorio del boletín.
- **Tamaño carta**: `-V geometry:letterpaper -V geometry:margin=2.5cm`.
- **Idioma**: `-V lang=es` (títulos y pies en español).
- **`assets/editorial.tex`**: `caption` (pies de figura en cuerpo menor y etiqueta
  en negrita). Pandoc ya carga `microtype` por su cuenta si está disponible.
- La imagen se convierte en figura con pie automático: `Figura N: <texto alterno>`.

## Convenciones de nombre

Evita `:` y espacios en los archivos generados (problemáticos en Windows y make), y
quita el prefijo de fecha para conservar el nombre corto del boletín:

`2026-09-09-Boletin-02: Mercado de Bonos.md` → `Boletin-02-Mercado-de-Bonos.pdf`

## Verificación

```bash
pdfinfo "<salida>.pdf" | grep -E "Pages|Page size"   # letter: 612 x 792 pts
pdftotext -layout "<salida>.pdf" - | head             # acentos y cifras correctos
pdfimages -list "<salida>.pdf"                        # 0 imágenes raster (diagrama 100% vectorial)
```

El `.tex` referencia las imágenes como `Diagramas/...`: compílalo desde el directorio
de su boletín (`cd "<Boletin NN>" && pdflatex "<salida>.tex"`).

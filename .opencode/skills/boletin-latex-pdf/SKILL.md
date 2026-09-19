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

1. En el `.md` de trabajo, cada diagrama debe referenciarse como **imagen PDF**,
   con ruta relativa al directorio del boletín:

   ```markdown
   ![Nube de Evaporación del Conflicto](Diagramas/nube-evaporacion-conflicto.pdf)
   ```

   El `.md` de trabajo (sin fecha) se genera desde la fuente (con fecha)
   sustituyendo cada bloque ` ```text ` / ` ```d2 ` por su referencia; la fuente
   nunca se modifica.
2. **No** añadas `{width=...}`: deja que LaTeX escale. La plantilla
   (`assets/boletin.tex`) ajusta la imagen al ancho de caja con `keepaspectratio`
   y no la deforma.
3. **Escapa los importes en dólares** del `.md` de trabajo como `\$` antes de
   compilar (`\$6,000M`, `\$160 billones`), reservando `$...$` para las variables
   (`$T$`, `$I$`, `$\neq$`). Ver *Claves de calidad editorial*.

## Compilar

PDF tamaño carta con el motor `pdflatex` (usa `<Boletin NN>/<archivo>.md`):

```bash
pandoc "<Boletin NN>/<archivo>.md" \
  --from=markdown+tex_math_dollars \
  --resource-path="<Boletin NN>" \
  --template=.opencode/skills/boletin-latex-pdf/assets/boletin.tex \
  --pdf-engine=pdflatex \
  -V membrete=".opencode/skills/boletin-latex-pdf/assets/membrete.pdf" \
  -o "<Boletin NN>/<salida>.pdf"
```

Documento LaTeX standalone:

```bash
pandoc "<Boletin NN>/<archivo>.md" \
  --from=markdown+tex_math_dollars --resource-path="<Boletin NN>" \
  --template=.opencode/skills/boletin-latex-pdf/assets/boletin.tex \
  -s -t latex --pdf-engine=pdflatex \
  -V membrete=".opencode/skills/boletin-latex-pdf/assets/membrete.pdf" \
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
- **Plantilla mínima `assets/boletin.tex`**: se pasa con `--template` y solo carga lo
  estrictamente necesario (fuente, acentos, español, matemáticas, gráficos, tablas,
  enlaces y pies de figura). Tamaño carta y 12 pt en el propio
  `\documentclass[12pt,letterpaper]{article}`; la **geometría y la tipografía quedan
  a cargo de LaTeX** (no se pasan `geometry` ni `fontsize` por línea de comandos).
  Cuidado: en una plantilla de pandoc los `$…$` de los comentarios se interpretan
  como variables, así que no deben aparecer en el texto.
- **Membrete de fondo**: la plantilla lleva `\usepackage{background}` y pinta
  `membrete.pdf` a página completa en **todas las hojas**. La ruta se inyecta
  como variable de template con `-V membrete=<ruta>` (el script la pasa
  automáticamente con ruta absoluta, porque `pdflatex` corre desde un
  directorio temporal y los recursos del preámbulo no se copian). Si no se
  define la variable, el fondo simplemente no se carga (`$if(membrete)$`).
  El membrete es **raster** (2550×3300 @300 dpi, exportado de LibreOffice):
  los diagramas siguen siendo 100 % vectoriales. Detalle: el `\includegraphics`
  del fondo pasa `width=\paperwidth,height=\paperheight` **explícitos**, porque
  las claves globales `\setkeys{Gin}` (que ajustan los diagramas al área de
  texto) limitarían el fondo a los márgenes si se dejara solo el ancho.
- **Idioma español**: `\usepackage[spanish]{babel}` vive en la plantilla (títulos,
  guionado y pies "Figura N:").
- **Pies de figura**: `\usepackage{caption}` + `\captionsetup{font=small,labelfont=bf}`
  en la plantilla (sustituyó al antiguo `assets/editorial.tex`).
- **Secciones sin numeración automática**: `\setcounter{secnumdepth}{-1}` en la
  plantilla (equivale a `\section*`): los títulos solo muestran los números que el
  markdown escribe a mano ("1. Titular…", "3. Contabilidad…"), evitando el doble
  "1.3 3. …" de LaTeX + número manual.
- **Títulos nunca huérfanos**: `needspace` + etoolbox (`\pretocmd` sobre
  `\section`/`\subsection`/`\subsubsection`) reservan 3 líneas antes de cada
  sección; si no caben, el título salta de página (imprescindible cuando el
  título precede a una tabla `longtable`).

## Convenciones de nombre

Evita `:` y espacios en los archivos generados (problemáticos en Windows y make).
El `.md` de trabajo ya no lleva la fecha; el script sanea el resto:

`Boletin-02: Mercado de Bonos.md` → `Boletin-02-Mercado-de-Bonos.pdf`

## Verificación

```bash
pdfinfo "<salida>.pdf" | grep -E "Pages|Page size"   # letter: 612 x 792 pts
pdftotext -layout "<salida>.pdf" - | head             # acentos y cifras correctos
pdfimages -list "<salida>.pdf"                        # N imágenes raster = N páginas (1 por página: el membrete de fondo)
```

El membrete de fondo aparece como **1 imagen raster por página** (2550×3300
@300 dpi) en `pdfimages`; los diagramas son contenido vectorial (texto
seleccionable en `pdftotext`, sin raster propio).

El `.tex` referencia las imágenes como `Diagramas/...`: compílalo desde el directorio
de su boletín (`cd "<Boletin NN>" && pdflatex "<salida>.tex"`). Ojo: el `.tex`
lleva la ruta **absoluta** del membrete de fondo (inyectada por el script); si se
compila en otra máquina o el repo se movió, regenera con `make boletin` o ajusta el
`\includegraphics` de `\backgroundsetup`.

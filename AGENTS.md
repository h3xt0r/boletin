# AGENTS.md — Boletines IES (Termodinámica Financiera)

## Qué es este repositorio

Boletines financieros redactados en **Markdown**. Cada boletín incluye uno o más
**diagramas en texto** (bloques ` ```text `) que deben convertirse a un formato
vectorial y producir un **PDF de calidad editorial** con LaTeX + pandoc.

Cada boletín vive en su propio directorio `Boletin NN/` (con espacio).

## Objetivo de cada boletín

1. Convertir los diagramas del boletín (bloques ` ```text ` o ` ```d2 `) a **D2**
   (`Boletin NN/Diagramas/*.d2`).
2. Renderizar cada diagrama a **SVG** y exportarlo a **PDF vectorial** (0 raster).
3. Incrustar los diagramas en el Markdown como imágenes PDF.
4. Compilar el boletín a **PDF tamaño carta** (y a `.tex`) con pandoc + LaTeX.

## Estructura

```text
.
├── AGENTS.md
├── Makefile
├── .opencode/skills/
│   ├── diagramas-d2-pdf/               # texto -> D2 -> SVG -> PDF vectorial
│   └── boletin-latex-pdf/              # Markdown -> .tex / .pdf (pandoc)
└── Boletin NN/                         # un directorio por boletín
    ├── <fecha>-Boletin-NN ... .md      # fuente del boletín
    ├── Boletin-NN-... .pdf / .tex      # salidas
    └── Diagramas/                      # .d2, .svg y .pdf de cada diagrama
```

## Herramientas

`d2`, `mutool` (MuPDF), `pandoc`, `pdflatex` (TeX Live) y poppler-utils
(`pdfinfo`, `pdftotext`, `pdfimages`).

## Flujo de trabajo

1. **Diagramas** — carga la skill `diagramas-d2-pdf`:
   - Si el boletín trae bloques ` ```d2 `, ejecuta
     `.opencode/skills/diagramas-d2-pdf/scripts/extraer-d2.sh "<Boletin NN>/<archivo>.md"`:
     numera `Diagramas/figura-<N>.d2`, valida la compilación con `d2`, escapa el `$`
     suelto de las etiquetas y sustituye cada bloque por `![<pie>](Diagramas/figura-<N>.pdf)`.
   - Si trae bloques ` ```text `, tradúcelos a `Boletin NN/Diagramas/<nombre>.d2`. Usa
     `direction: down` para orientación vertical; en nubes de evaporación usa el
     motor **TALA** con `top`/`left` para evitar el escalonamiento de `dagre`/`elk`.
   - `d2 "Boletin NN/Diagramas/<nombre>.d2" "Boletin NN/Diagramas/<nombre>.svg"`
   - `mutool convert -F pdf -o "Boletin NN/Diagramas/<nombre>.pdf" "Boletin NN/Diagramas/<nombre>.svg"`
   - **Nunca** uses el PDF nativo de d2 (`d2 x.d2 x.pdf`): es raster.
2. **Documento** — carga la skill `boletin-latex-pdf`:
   - En el `.md`, referencia cada diagrama como `Diagramas/<nombre>.pdf` (ruta
     relativa al directorio del boletín) y quita el bloque ` ```text `. Sin `{width}`.
   - Compila con pandoc (`pdflatex`, `letterpaper`, `lang=es`,
     `--from=markdown+tex_math_dollars`). El script añade `--resource-path` con el
     directorio del boletín.
   - Genera también el `.tex` standalone.

### Atajos con make

`BOLETIN` elige el directorio del boletín; por defecto, el `Boletin NN` más reciente.

```bash
make diagramas                            # .d2 -> .svg + .pdf de BOLETIN/Diagramas/
make boletin                              # compila el .md del boletín
make boletin SRC="Boletin 02/<x>.md"      # compila un archivo concreto
make todo BOLETIN="Boletin 03"            # diagramas + boletín del 03
make limpiar                              # borra .svg/.pdf de BOLETIN/Diagramas/
```

## Convenciones

- Un directorio por boletín: `Boletin 02`, `Boletin 03`, … (con espacio).
- Archivos de salida sin `:` ni espacios (`Boletin-02-Mercado-de-Bonos.pdf`).
- PDF tamaño carta (`612 x 792 pt`), márgenes de 2.5 cm, 11 pt, idioma español.
- Diagramas **vectoriales**; nunca PNG para el PDF final.
- El escalado de las imágenes lo hace LaTeX: no fijar `width`.
- El `.tex` usa rutas `Diagramas/...`: compílalo desde el directorio de su boletín.
- No editar a mano los archivos generados (`.pdf`, `.tex`, `.svg`).

## Verificación obligatoria antes de entregar

- `pdfinfo <salida>.pdf` → `612 x 792 pts (letter)`.
- `pdftotext -layout <salida>.pdf -` → acentos y cifras (`$160 billones`) correctos
  y el diagrama como `Figura 1: ...` (texto seleccionable = contenido vectorial).
- `pdfimages -list <salida>.pdf` → **0 imágenes raster** (diagrama 100 % vectorial,
  gracias a `mutool`). Si se usara `rsvg-convert`, aparecerían máscaras alfa de las
  cajas de los nodos.

# AGENTS.md — Boletines IES (Termodinámica Financiera)

## Qué es este repositorio

Boletines financieros redactados en **Markdown**. Cada boletín incluye uno o más
**diagramas en texto** (bloques ` ```text `) o en **d2lang** (bloques ` ```d2 `)
que se convierten a un formato vectorial para producir un **PDF de calidad
editorial** con LaTeX + pandoc.

Cada boletín tiene **dos artefactos**, ambos en la raíz del directorio del boletín:

- **Fuente (web):** `YYYY-MM-DD-Boletin-NN: Nombre.md`, con los diagramas en
  ASCII (bloques ` ```text `) o en d2lang (bloques ` ```d2 `). Es el archivo que
  se publica en la **WEB** (el motor de Markdown renderiza los bloques de código)
  y el punto de partida del proceso. **Se preserva intacta**: el pipeline nunca la
  modifica.
- **Trabajo (imprenta):** `Boletin-NN: Nombre.md` (el mismo nombre **sin la
  fecha**), con las ligas a los diagramas `Diagramas/*.pdf`. Es el que compila
  pandoc para el **PDF impreso**. Se genera a partir de la fuente.

## Estructura

```text
.
├── AGENTS.md
├── Makefile
├── .opencode/skills/
│   ├── diagramas-d2-pdf/               # diagramas -> D2 -> SVG -> PDF vectorial
│   └── boletin-latex-pdf/              # Markdown -> .tex / .pdf (pandoc)
└── Boletin NN/                         # un directorio por boletín
    ├── YYYY-MM-DD-Boletin-NN: ....md   # FUENTE (```text / ```d2)  — intacta (web)
    ├── Boletin-NN: ....md              # TRABAJO (sin fecha, ligas a Diagramas/*.pdf)
    ├── Diagramas/                      # .d2, .svg y .pdf de cada diagrama
    └── Boletin-NN-... .pdf / .tex      # salidas
```

## Herramientas

`d2`, `mutool` (MuPDF), `pandoc`, `pdflatex` (TeX Live) y poppler-utils
(`pdfinfo`, `pdftotext`, `pdfimages`).

## Flujo de trabajo

1. **Fuente** — el usuario coloca `Boletin NN/YYYY-MM-DD-Boletin-NN: Nombre.md`
   (diagramas ` ```text ` o ` ```d2 `). No se toca; el pipeline nunca la modifica.

2. **Diagramas** — carga la skill `diagramas-d2-pdf`:
   - Si la fuente trae bloques ` ```d2 ` (p. ej. `Boletin 05.1`), `make trabajo`
     ejecuta `extraer-d2.sh "<fuente>.md" "<trabajo>.md"`: numera
     `Diagramas/figura-<N>.d2`, valida la compilación con `d2`, escapa el `$`
     suelto de las etiquetas y escribe el `.md` de trabajo con
     `![<pie>](Diagramas/figura-<N>.pdf)`.
   - Si la fuente trae bloques ` ```text `, traduce cada uno a
     `Boletin NN/Diagramas/<nombre>.d2` y escribe el `.md` de trabajo sustituyendo
     el bloque por `![<pie>](Diagramas/<nombre>.pdf)`. Usa `direction: down` para
     orientación vertical; en nubes de evaporación usa el motor **TALA** con
     `top`/`left` para evitar el escalonamiento de `dagre`/`elk`.
   - `make diagramas` renderiza cada `.d2`:
     `d2 x.d2 x.svg` y `mutool convert -F pdf -o x.pdf x.svg`.
   - **Nunca** uses el PDF nativo de d2 (`d2 x.d2 x.pdf`): es raster.

3. **Documento** — carga la skill `boletin-latex-pdf`:
   - El `.md` de trabajo referencia cada diagrama como `Diagramas/<nombre>.pdf`
     (ruta relativa al directorio del boletín). Sin `{width}`.
   - **Escapa SIEMPRE los importes en dólares como `\$`** (`\$6,000M`,
     `\$160 billones`); `$...$` queda reservado para variables (`$T$`, `$I$`,
     `$OE$`). Un `$` suelto puede cerrarse con cualquier `$` posterior válido del
     mismo párrafo y volver matemático todo el texto intermedio (caso Boletín 04).
   - `make boletin` compila el `.md` de trabajo con pandoc (`pdflatex`,
     `--from=markdown+tex_math_dollars`) usando la plantilla mínima
     `assets/boletin.tex` (carta, 12 pt, español; la tipografía y la geometría las
     decide LaTeX). El script añade `--resource-path` con el directorio del
     boletín y **el membrete de fondo** (`-V membrete=<ruta absoluta>`): la
     plantilla lo pinta en todas las hojas vía el paquete `background` (el asset
     vive en `.opencode/skills/boletin-latex-pdf/assets/membrete.pdf`). Genera
     también el `.tex` standalone.

### Atajos con make

`BOLETIN` elige el directorio del boletín; por defecto, el `Boletin NN` más reciente.

```bash
make trabajo                              # fuente con ```d2 -> .md de trabajo + figura-N.d2
make diagramas                            # .d2 -> .svg + .pdf de BOLETIN/Diagramas/
make boletin                              # compila el .md de trabajo del boletín
make boletin WORK="Boletin 02/Boletin-02: Mercado de Bonos.md"
make todo BOLETIN="Boletin 03"            # trabajo + diagramas + boletín
make limpiar                              # borra .svg/.pdf de BOLETIN/Diagramas/
```

## Convenciones

- Un directorio por boletín: `Boletin 02`, `Boletin 03`, … (con espacio).
- **Fuente:** `YYYY-MM-DD-Boletin-NN: Nombre.md`, con los diagramas de texto/d2,
  sin tocar (es la que se publica en la web). **Trabajo:** `Boletin-NN: Nombre.md`
  (sin fecha), con las ligas a `Diagramas/*.pdf`; es el que se compila a imprenta.
  El `.md` de trabajo se puede regenerar desde la fuente en cualquier momento.
- No editar a mano los archivos generados (`.pdf`, `.tex`, `.svg`).
- Archivos de salida sin `:` ni espacios (`Boletin-02-Mercado-de-Bonos.pdf`).
- PDF tamaño carta (`612 x 792 pt`) y 12 pt, con la tipografía y la geometría a
  cargo de LaTeX: la plantilla mínima `assets/boletin.tex` fija solo el tamaño de
  papel y cuerpo (`\documentclass[12pt,letterpaper]{article}`); no se imponen
  márgenes ni tamaños de letra por línea de comandos.
- Diagramas **vectoriales**; nunca PNG para el PDF final.
- El escalado de las imágenes lo hace LaTeX: no fijar `width`.
- Secciones **sin numeración automática** (la plantilla usa
  `\setcounter{secnumdepth}{-1}`, equivalente a `\section*`): solo se muestran
  los números que el markdown escribe a mano en los títulos ("1.", "2.", "A.", …).
- Los títulos **nunca quedan huérfanos** al pie de página: la plantilla reserva
  espacio antes de cada sección (`needspace` + etoolbox, 3 líneas); evita también
  el caso de título seguido de tabla `longtable`.
- El `.tex` usa rutas `Diagramas/...`: compílalo desde el directorio de su boletín.

## Verificación obligatoria antes de entregar

- `pdfinfo <salida>.pdf` → `612 x 792 pts (letter)`.
- `pdftotext -layout <salida>.pdf -` → acentos y cifras literales (los `\$` del
  `.md` aparecen como `$` en el PDF, p. ej. `$6,000M`, `$160 billones`) y el
  diagrama como `Figura 1: ...` (texto seleccionable = contenido vectorial).
- `pdfimages -list <salida>.pdf` → **N imágenes raster = N páginas**: exactamente
  1 por página, la del **membrete** de fondo (2550×3300 @300 dpi); los diagramas
  son 100 % vectoriales (texto seleccionable) gracias a `mutool`. Si se usara
  `rsvg-convert`, aparecerían además máscaras alfa de las cajas de los nodos.

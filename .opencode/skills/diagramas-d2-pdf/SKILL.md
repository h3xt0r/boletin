---
name: Diagramas D2 a PDF vectorial
description: Convierte los diagramas de texto de un boletín al lenguaje D2, los renderiza a SVG con d2 y los exporta a PDF 100 % vectorial (0 imágenes raster) con mutool para incrustarlos en el PDF LaTeX. Úsalo al crear o actualizar cualquier diagrama del boletín.
---

# Diagramas D2 → SVG → PDF vectorial

Genera diagramas **vectoriales** (calidad de imprenta) a partir de los diagramas de
texto que traen los boletines en Markdown. Cada boletín guarda sus diagramas en
`Boletin NN/Diagramas/`.

## Cuándo usarlo

- El boletín trae un diagrama dentro de un bloque de código ` ```text `.
- Hay que crear o actualizar un diagrama en el `Diagramas/` del boletín.
- El PDF final debe mostrar el diagrama nítido a cualquier escala de impresión.

## Requisitos

| Herramienta | Para qué |
| --- | --- |
| `d2` | compilar el `.d2` a `.svg` |
| `mutool` (MuPDF) | convertir el `.svg` a `.pdf` 100 % vectorial |
| `pdfinfo`, `pdftotext`, `pdfimages` (poppler-utils) | verificar el resultado |

## Flujo

1. **Localizar el diagrama de texto** en el `.md` (bloque ` ```text `).
2. **Traducirlo a D2** y guardarlo en `Boletin NN/Diagramas/<nombre>.d2`.
3. **Renderizar el SVG:**
   ```bash
   d2 "Boletin NN/Diagramas/<nombre>.d2" "Boletin NN/Diagramas/<nombre>.svg"
   ```
4. **Exportar el PDF vectorial:**
   ```bash
   mutool convert -F pdf -o "Boletin NN/Diagramas/<nombre>.pdf" "Boletin NN/Diagramas/<nombre>.svg"
   ```

Atajo: `scripts/d2-to-pdf.sh "Boletin NN/Diagramas/<nombre>.d2"` ejecuta los pasos 3
y 4 y verifica. El motor por defecto es `mutool`; usa `D2PDF_ENGINE=rsvg` para
`rsvg-convert`.

## Traducción de diagramas de texto a D2

- Cada caja del diagrama de texto es un nodo con etiqueta: `A: "texto"`.
- Cada flecha `-->` es una arista: `A -> B`.
- Usa `\n` dentro de la etiqueta para reproducir el salto de línea del texto.
- Un conflicto bidireccional se escribe `A <-> B: "CONFLICTO"`.
- Conserva el sentido del original: nodos, jerarquía y conflictos.

### Orientación para hoja carta

Usa `direction: down` para que el árbol **crezca hacia abajo** y aproveche el alto
de una página vertical:

```d2
direction: down
```

### Nubes de evaporación y árboles con arista de conflicto

La arista de conflicto (`D <-> D'`) crea un ciclo y los motores `dagre` y `elk`
**escalonan** los niveles (C y D terminan en pisos distintos). Para dejar B/C en un
nivel y D/D' en otro, fija el motor **TALA** y posiciona los nodos con `top`/`left`:

```d2
vars: {
  d2-config: {
    layout-engine: tala
  }
}

direction: down

A: "Meta"        { top: 0   ; left: 210 }
B: "Requisito 1" { top: 170 ; left: 0   }
C: "Requisito 2" { top: 170 ; left: 360 }
D: "Acción 1"    { top: 340 ; left: 0   }
"D'": "Acción 2" { top: 340 ; left: 360 }

A -> B
A -> C
B -> D
C -> "D'"
D <-> "D'": "CONFLICTO\nSISTÉMICO" {
  style.stroke: "#e53935"
  style.stroke-dash: 4
}
```

Detalles útiles:

- `constraint: "false"` **no** excluye la arista del layout en este build; no sirve
  para evitar el escalonamiento.
- Un rótulo largo en una arista conviene partirlo: `"CONFLICTO\nSISTÉMICO"`.
- Deja separación horizontal suficiente para que el rótulo entre entre D y D'.

En `references/ejemplo-nube-evaporacion.d2` hay un ejemplo completo y funcional.

## No usar

- **`d2 archivo.d2 archivo.pdf`**: el PDF nativo de d2 es **raster** (incrusta el PNG
  en una página) y no tiene texto seleccionable; no sirve para escalado vectorial
  ni para impresión. Genera siempre SVG y conviértelo con `mutool`.
- No hace falta ningún paso a PNG.

## Verificación

```bash
pdfinfo "Boletin NN/Diagramas/<nombre>.pdf"            # debe tener 1 página
pdftotext "Boletin NN/Diagramas/<nombre>.pdf" -         # el texto debe ser seleccionable
pdfimages -list "Boletin NN/Diagramas/<nombre>.pdf"     # con mutool: 0 imágenes raster
pdftocairo -svg "Boletin NN/Diagramas/<nombre>.pdf" /tmp/v.svg   # debe producir <path> y glifos
```

Con el motor por defecto (`mutool`) el PDF es **100 % vectorial** y `pdfimages -list`
no muestra ninguna imagen. La variante `rsvg-convert` (cairo) también conserva trazos
y texto como vectores, pero añade **máscaras alfa** de las cajas de los nodos; úsala
solo si la necesitas.

# Data Model: Sistema de Diseño Loopi v2

**Feature**: `000-design-system`
**Date**: 2026-05-28

> El design system no persiste datos en base de datos. Este documento describe
> el **modelo de tokens de diseño**: las entidades CSS que forman el contrato
> visual del sistema.

## Entidades del Design System

### Token de Color

Variable CSS que representa un valor de la paleta de marca.

| Campo | Tipo | Descripción |
|---|---|---|
| nombre | CSS custom property | Ej. `--color-primary-600` |
| valor | HEX string | Ej. `#b86b3d` |
| escala | `primary` \| `coffee` | Grupo semántico al que pertenece |
| nivel | 50 \| 100 \| … \| 950 | Luminosidad (50 = más claro, 950 = más oscuro) |
| uso_principal | string | Descripción de cuándo usarlo |

**Escala primary** (café intenso — acciones de marca):

| Token | Valor | Uso principal |
|---|---|---|
| `--color-primary-50` | `#fdf8f6` | Fondos de énfasis muy suave |
| `--color-primary-100` | `#f9ede7` | Fondos hover en áreas de información |
| `--color-primary-200` | `#f3d9cc` | Bordes suaves en modo informativo |
| `--color-primary-300` | `#e9bfa8` | Bordes activos secundarios |
| `--color-primary-400` | `#dba07f` | Elementos decorativos |
| `--color-primary-500` | `#cc8158` | Ring de foco (focus:ring) |
| `--color-primary-600` | `#b86b3d` | Color de acción principal (btn-primary bg) |
| `--color-primary-700` | `#9c5630` | Estado hover de btn-primary |
| `--color-primary-800` | `#80462a` | Texto sobre fondos claros de énfasis |
| `--color-primary-900` | `#683a24` | Encabezados con acento de marca |
| `--color-primary-950` | `#381c11` | Texto de alto contraste sobre fondos cálidos |

**Escala coffee** (grises cálidos — fondos y estructura):

| Token | Valor | Uso principal |
|---|---|---|
| `--color-coffee-50` | `#faf6f2` | Fondo de aplicación (bg global) |
| `--color-coffee-100` | `#f3ebe1` | Fondo de secciones alternadas |
| `--color-coffee-200` | `#e6d4c0` | Bordes de separadores |
| `--color-coffee-300` | `#d5b696` | Bordes de inputs en reposo |
| `--color-coffee-400` | `#c4976c` | Íconos decorativos secundarios |
| `--color-coffee-500` | `#b87f50` | Texto de apoyo / captions |
| `--color-coffee-600` | `#a86944` | Texto secundario sobre fondos claros |
| `--color-coffee-700` | `#8c533a` | Texto de importancia media |
| `--color-coffee-800` | `#724434` | Texto principal sobre fondos muy claros |
| `--color-coffee-900` | `#5e392d` | Texto de alta jerarquía con tono cálido |
| `--color-coffee-950` | `#321c17` | Texto de máximo contraste (headings) |

---

### Token de Tipografía

Variable CSS que define la familia de fuente.

| Campo | Tipo | Descripción |
|---|---|---|
| nombre | CSS custom property | Ej. `--font-sans` |
| valor | font-family string | Cadena con fallbacks |
| fuente_principal | string | `Inter Variable` (self-hosted) |
| fallback | string | `system-ui, sans-serif` |

**Escala de pesos**:

| Peso | Valor | Uso |
|---|---|---|
| Regular | 400 | Cuerpo de texto, valores en formularios |
| Medium | 500 | Labels, texto de apoyo destacado |
| Semibold | 600 | Headings, texto de botones |
| Bold | 700 | Títulos principales (`h1`) |

---

### Utilidad de Componente

Clase CSS de alto nivel que encapsula la apariencia y estados de un elemento de interfaz.

| Campo | Tipo | Descripción |
|---|---|---|
| nombre | CSS class | Ej. `btn-primary` |
| tipo | `button` \| `input` \| `container` | Categoría del componente |
| estados | lista | Conjunto de estados visuales definidos |
| area_tactil | px | Área mínima en móvil (≥ 44 × 44 px) |

**Componentes definidos**:

| Clase | Tipo | Estados | Área táctil mínima |
|---|---|---|---|
| `btn-primary` | button | normal, hover, focus, disabled, loading | 44 × 44 px |
| `btn-secondary` | button | normal, hover, focus, disabled | 44 × 44 px |
| `input-field` | input | normal, focus, error, disabled | 44 px alto |
| `card` | container | normal (estático) | N/A |
| `touch-manipulation` | utility | — | — |

---

### Estado de Interacción

Representación visual de una condición del componente en un momento dado.

| Estado | Desencadenante | Visual |
|---|---|---|
| `normal` | Reposo | Apariencia base definida en la utilidad |
| `hover` | Cursor sobre el elemento | Oscurecimiento del fondo (primary-700) |
| `focus` | Tab / clic con teclado | Ring 2px primary-500 + offset 2px |
| `disabled` | `[disabled]` o `[attr.disabled]` | Opacidad 50%, cursor `not-allowed` |
| `loading` | `[disabled]` durante envío | Igual que disabled + spinner inline |
| `error` | Validación fallida en `input-field` | Borde `border-red-500` + texto debajo |

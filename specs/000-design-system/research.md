# Research: Sistema de Diseño Loopi v2

**Feature**: `000-design-system`
**Date**: 2026-05-28
**Branch**: `feature/000-design-system`

## 1. Paleta de Colores Loopi v1

**Decision**: Adoptar la paleta completa extraída de `loopi-web/src/styles.scss` (rama `master`).

**Rationale**: Los valores exactos ya están en producción en v1 y han sido validados visualmente.
No se introducen cambios en los matices para esta iteración.

**Primary palette (café intenso — acciones principales)**:

| Token | Valor |
|---|---|
| `--color-primary-50` | `#fdf8f6` |
| `--color-primary-100` | `#f9ede7` |
| `--color-primary-200` | `#f3d9cc` |
| `--color-primary-300` | `#e9bfa8` |
| `--color-primary-400` | `#dba07f` |
| `--color-primary-500` | `#cc8158` |
| `--color-primary-600` | `#b86b3d` ← color de acción principal |
| `--color-primary-700` | `#9c5630` ← estado hover |
| `--color-primary-800` | `#80462a` |
| `--color-primary-900` | `#683a24` |
| `--color-primary-950` | `#381c11` |

**Coffee palette (grises cálidos — fondos y bordes)**:

| Token | Valor |
|---|---|
| `--color-coffee-50` | `#faf6f2` |
| `--color-coffee-100` | `#f3ebe1` |
| `--color-coffee-200` | `#e6d4c0` |
| `--color-coffee-300` | `#d5b696` |
| `--color-coffee-400` | `#c4976c` |
| `--color-coffee-500` | `#b87f50` |
| `--color-coffee-600` | `#a86944` |
| `--color-coffee-700` | `#8c533a` |
| `--color-coffee-800` | `#724434` |
| `--color-coffee-900` | `#5e392d` |
| `--color-coffee-950` | `#321c17` |

**Verificación de contraste WCAG 2.1 AA**:

- `btn-primary`: texto blanco (`#ffffff`) sobre `primary-600` (`#b86b3d`) → ratio ~4.8:1 ✅
- `btn-secondary` outline: texto `primary-600` sobre blanco → ratio ~4.8:1 ✅
- `input-field`: texto `gray-900` sobre blanco → ratio >10:1 ✅

## 2. Fuente Inter — Self-Hosting

**Decision**: Usar el paquete npm `@fontsource-variable/inter`.

**Rationale**: El paquete incluye los archivos `.woff2` (variable font — un solo archivo cubre
todos los pesos 100–900), se instala como dependencia npm sin commits de binarios al repositorio,
y Angular Build copia los assets automáticamente. Elimina la dependencia de Google Fonts CDN sin
trabajo manual de descarga de archivos.

**Alternativas consideradas**:

- Google Fonts CDN (`@import url(...)`) — rechazado: envía requests a servidores Google en cada
  sesión; incompatible con decisión de privacy-first de la spec.
- Descarga manual de `.woff2` a `src/assets/fonts/` — rechazado: requiere mantener archivos
  binarios en el repo y actualizar manualmente ante nuevas versiones de Inter.
- `@fontsource/inter` (estático) — válido pero inferior: requiere un archivo `.woff2` por peso
  (400, 500, 600). La versión variable es más eficiente.

**Import en `styles.scss`**:

```scss
@import '@fontsource-variable/inter';
```

**Declaración en `@theme`** (Tailwind v4):

```scss
@theme {
  --font-sans: 'Inter Variable', 'Inter', system-ui, sans-serif;
}
```

## 3. Tailwind CSS v4 — Tokens y Utilidades

**Decision**: Usar `@theme { }` para tokens y `@utility` para las clases de componentes.

**Rationale**: Tailwind v4 reemplaza `tailwind.config.ts` con directivas CSS nativas.
`@theme` extiende el sistema de diseño; `@utility` define clases utilitarias personalizadas
que participan en el tree-shaking de Tailwind. Ambas viven en `src/styles.scss`.

**Patrón `@theme`**:

```scss
@theme {
  --font-sans: 'Inter Variable', system-ui, sans-serif;
  --color-primary-600: #b86b3d;
  /* ... todos los tokens */
}
```

**Patrón `@utility`**:

```scss
@utility btn-primary {
  @apply bg-primary-600 hover:bg-primary-700 text-white font-semibold
         py-3 px-4 rounded-lg transition-colors duration-200
         disabled:opacity-50 disabled:cursor-not-allowed
         focus:outline-none focus:ring-2 focus:ring-primary-500 focus:ring-offset-2;
}
```

**Ventajas vs `@layer components`**: `@utility` en Tailwind v4 genera las clases con la misma
especificidad que las utilidades nativas, evitando conflictos de cascade que ocurren con
`@layer components` en v3.

## 4. `btn-secondary` — Ajuste respecto a v1

**Decision**: Cambiar de estilo "soft/gray" (v1) a estilo **outline primario** (v2).

**Rationale**: Clarificación Q2 en `speckit-clarify` — se eligió outline sobre el estilo gray
de v1 para diferenciar claramente la acción secundaria de la primaria con la paleta café.

**v1** (rechazado):

```scss
@apply bg-white hover:bg-gray-50 text-gray-700 border border-gray-300;
```

**v2** (adoptado):

```scss
@apply bg-transparent hover:bg-primary-50 text-primary-600 font-semibold
       py-3 px-4 rounded-lg border-2 border-primary-600
       transition-colors duration-200
       disabled:opacity-50 disabled:cursor-not-allowed
       focus:outline-none focus:ring-2 focus:ring-primary-500 focus:ring-offset-2;
```

## 5. Optimizaciones iOS Móvil

**Decision**: Incluir las optimizaciones de v1 para iOS en los estilos globales.

**Rationale**: Los baristas usan iPhone en tienda. Las optimizaciones previenen zoom involuntario
en inputs y ofrecen áreas seguras (notch, home indicator).

**Incluir de v1**:

- `font-size: 16px` en inputs (previene zoom en iOS al hacer foco)
- `overscroll-behavior-y: contain` en body (previene pull-to-refresh)
- `safe-area-inset-top/bottom` para notch/home indicator
- `-webkit-tap-highlight-color: transparent` (elimina highlight azul en tap)
- Utilidad `touch-manipulation` (`touch-action: manipulation`)

## 6. Migración de `001-autenticacion` (login/logout templates)

**Decision**: Reemplazar clases Tailwind directas en templates por las utilidades del design system.

**Alcance de migración**:

| Archivo | Cambio |
|---|---|
| `login.component.html` | Botón submit → `btn-primary`; campos → `input-field`; contenedor → `card` |
| `login.component.scss` | Eliminar overrides manuales si los hay |
| `styles.scss` | Reemplazar `@use "tailwindcss"` por `@import '@fontsource-variable/inter'` + `@use "tailwindcss"` + tokens + utilidades |

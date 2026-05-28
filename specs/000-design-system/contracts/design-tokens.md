# Contrato: Tokens de Diseño

**Feature**: `000-design-system`
**Tipo**: CSS Custom Properties (variables de diseño)
**Archivo fuente**: `loopi-web-v2/src/styles.scss`

## Alcance

Estos tokens son el **contrato de color y tipografía** del design system.
Toda vista de Loopi v2 DEBE usarlos a través de las clases de Tailwind
(`text-primary-600`, `bg-coffee-50`, etc.) o a través de las utilidades
de componente. Nunca usar valores hex directamente en templates o estilos.

## Tokens de Color

Definidos en el bloque `@theme { }` de `styles.scss`. Tailwind v4 los
expone como clases utilitarias (`bg-*`, `text-*`, `border-*`, etc.).

### Escala `primary` (café intenso)

```css
--color-primary-50:  #fdf8f6
--color-primary-100: #f9ede7
--color-primary-200: #f3d9cc
--color-primary-300: #e9bfa8
--color-primary-400: #dba07f
--color-primary-500: #cc8158   /* ring de foco */
--color-primary-600: #b86b3d   /* acción principal */
--color-primary-700: #9c5630   /* hover de acción */
--color-primary-800: #80462a
--color-primary-900: #683a24
--color-primary-950: #381c11
```

### Escala `coffee` (grises cálidos)

```css
--color-coffee-50:  #faf6f2
--color-coffee-100: #f3ebe1
--color-coffee-200: #e6d4c0
--color-coffee-300: #d5b696
--color-coffee-400: #c4976c
--color-coffee-500: #b87f50
--color-coffee-600: #a86944
--color-coffee-700: #8c533a
--color-coffee-800: #724434
--color-coffee-900: #5e392d
--color-coffee-950: #321c17
```

## Tokens de Tipografía

```css
--font-sans: 'Inter Variable', 'Inter', system-ui, sans-serif
```

Tailwind v4 lo expone como `font-sans`.

## Reglas de Uso

- ✅ `class="text-primary-600"` — correcto (usa el token)
- ✅ `class="bg-coffee-50"` — correcto (usa el token)
- ❌ `style="color: #b86b3d"` — prohibido (hardcoded)
- ❌ `class="text-[#b86b3d]"` — prohibido (clase arbitraria con hex)
- ❌ Cualquier `@import url('fonts.googleapis.com/...')` — prohibido

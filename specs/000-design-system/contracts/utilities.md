# Contrato: Utilidades de Componente

**Feature**: `000-design-system`
**Tipo**: CSS `@utility` classes
**Archivo fuente**: `loopi-web-v2/src/styles.scss`

## Alcance

Estas clases son el **contrato de componentes** del design system. Se definen una sola vez
en `styles.scss` y se aplican directamente en los templates Angular. No requieren imports
adicionales.

**Regla de oro**: ningún formulario o listado debe usar clases Tailwind ad-hoc para campos
de entrada ni botones de acción. Si la utilitaria existente no cubre el caso, se extiende
aquí y se actualiza esta spec.

---

## `btn-primary`

**Uso**: Acción principal de cada vista (submit, confirmar, guardar).

```html
<button type="submit" class="btn-primary" [disabled]="cargando">
  Guardar
</button>
```

**Estilos aplicados**:

- Fondo: `primary-700` (#9c5630) — contraste 5.5:1 con texto blanco (WCAG 2.1 AA ✅)
- Hover: `primary-800` (#80462a)
- Texto: blanco, `font-medium`, `text-sm`
- Padding: `py-2 px-5`
- Esquinas: `rounded-lg`
- Transición: colores 200 ms
- Disabled: opacidad 50%, cursor `not-allowed`
- Focus: ring 2px `primary-600` + offset 2px

**Restricciones**:

- Una sola acción primaria por vista.
- No usar `bg-indigo-*` ni `bg-blue-*` — la paleta de marca es `primary-*`.

---

## `btn-secondary`

**Uso**: Acciones secundarias (cancelar, volver, acción alternativa).

```html
<a routerLink="/tiendas" class="btn-secondary">Cancelar</a>
```

**Estilos aplicados**:

- Fondo: transparente (hover: `primary-50`)
- Borde: 1px `primary-700` — contraste 5.5:1 sobre blanco (WCAG 2.1 AA ✅)
- Texto: `primary-700`, `font-medium`, `text-sm`
- Padding: `py-2 px-5`
- Esquinas: `rounded-lg`
- Transición: colores 200 ms
- Disabled: opacidad 50%, cursor `not-allowed`
- Focus: ring 2px `primary-600` + offset 2px

---

## `input-field`

**Uso**: Inputs de texto, password, email, número, fecha y textareas en formularios.

```html
<input
  id="nombre"
  type="text"
  formControlName="nombre"
  class="input-field"
  [class.input-field-error]="errorDe('nombre')"
/>
```

**Estilos aplicados**:

- Ancho: `w-full`
- Padding: `px-4 py-3` (área táctil ≥ 44 px en móvil)
- Fondo: `bg-white`
- Color de texto: `text-gray-900`
- Borde: `border border-gray-300 rounded-lg`
- Placeholder: `gray-500` — contraste 4.8:1 sobre blanco (WCAG 2.1 AA ✅)
- Focus: ring 2px `primary-600`, borde `primary-600`
- Disabled: `bg-gray-100`, `text-gray-400`, `cursor-not-allowed`
- Transición: colores 200 ms
- Font-size: `1rem` (16 px — previene zoom en iOS al hacer focus)

**Estado de error** — agregar `input-field-error` como clase adicional:

```html
<input class="input-field" [class.input-field-error]="errorDe('codigo')" />
<p class="mt-1 text-xs text-red-600" role="alert">Texto de error descriptivo</p>
```

**Textarea**:

```html
<textarea class="input-field resize-none" rows="3" formControlName="descripcion"></textarea>
```

---

## `input-field-error`

**Uso**: Modificador de estado de error. Se combina con `input-field` o `select-field`.
Nunca se usa solo.

```html
<input class="input-field" [class.input-field-error]="errorDe('nombre')" />
<select class="select-field" [class.input-field-error]="errorDe('tipo')" />
```

**Estilos aplicados**:

- Borde: `border-red-500`
- Focus ring: `focus:ring-red-500`
- Focus border: `focus:border-red-500`

**Regla de posición**: `input-field-error` se define después de `input-field` y `select-field`
en `styles.scss` para garantizar que sus colores tengan precedencia en la cascada CSS.

---

## `select-field`

**Uso**: Elementos `<select>` en formularios. Mismo token visual que `input-field` con
flecha SVG controlada que reemplaza la flecha nativa del browser (incompatible entre
Chrome, Firefox y Safari).

```html
<select
  id="tipo_medida"
  formControlName="tipo_medida"
  class="select-field"
  [class.input-field-error]="errorDe('tipo_medida')"
>
  <option value="" disabled>Selecciona un tipo</option>
  @for (tipo of tipos; track tipo) {
    <option [value]="tipo">{{ tipo | titlecase }}</option>
  }
</select>
```

**Estilos aplicados**:

- Todos los de `input-field` excepto `w-full px-4` → usa `pl-4 pr-10` (espacio para el chevron)
- `appearance-none` — elimina la flecha nativa del browser
- `cursor-pointer`
- Chevron SVG: `stroke="#6b7280"` (gray-500), 20×20 px, posición `right 12px center`

**Estado de error**: igual que `input-field` — agregar `[class.input-field-error]`.

**Excepción — contextos compactos** (ej. topbar `store-selector`): no usar `select-field`
ya que fuerza `py-3` y `w-full`. En su lugar, aplicar `appearance-none` + wrapper con
chevron SVG absoluto de forma explícita.

---

## `card`

**Uso**: Contenedores de información (formularios, paneles, resúmenes).

```html
<div class="card">
  <h2 class="text-xl font-semibold text-coffee-900">Título</h2>
  <!-- contenido -->
</div>
```

**Estilos aplicados**:

- Fondo: blanco
- Esquinas: `rounded-xl`
- Sombra: `shadow-sm`
- Borde: `border border-gray-100`
- Padding: `p-4`

---

## `touch-manipulation`

**Uso**: Aplicar en cualquier elemento interactivo cuando se quiera eliminar el delay
de 300 ms del navegador móvil y el highlight azul de iOS.

```html
<button class="btn-primary touch-manipulation">Guardar</button>
```

**Estilos aplicados**:

- `touch-action: manipulation`
- `-webkit-tap-highlight-color: transparent`

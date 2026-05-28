# Contrato: Utilidades de Componente

**Feature**: `000-design-system`
**Tipo**: CSS `@utility` classes
**Archivo fuente**: `loopi-web-v2/src/styles.scss`

## Alcance

Estas cuatro clases más `touch-manipulation` son el **contrato de componentes**
del design system. Se definen una sola vez en `styles.scss` y se aplican
directamente en los templates Angular. No requieren imports adicionales.

---

## `btn-primary`

**Uso**: Acción principal de cada vista (submit, confirmar, guardar).

```html
<button type="submit" class="btn-primary" [disabled]="cargando">
  Iniciar sesión
</button>
```

**Estilos aplicados**:

- Fondo: `primary-600` (#b86b3d)
- Hover: `primary-700` (#9c5630)
- Texto: blanco, semibold
- Padding: `py-3 px-4` (área táctil ≥ 44 px)
- Esquinas: `rounded-lg`
- Transición: colores 200 ms
- Disabled: opacidad 50%, cursor `not-allowed`
- Focus: ring 2px `primary-500` + offset 2px

**Restricciones**:

- Una sola acción primaria por vista
- No anidar `btn-primary` dentro de `btn-primary`

---

## `btn-secondary`

**Uso**: Acciones secundarias (cancelar, volver, acción alternativa).

```html
<button type="button" class="btn-secondary" (click)="cancelar()">
  Cancelar
</button>
```

**Estilos aplicados**:

- Fondo: transparente (hover: `primary-50`)
- Borde: 2px `primary-600`
- Texto: `primary-600`, semibold
- Padding: `py-3 px-4` (área táctil ≥ 44 px)
- Esquinas: `rounded-lg`
- Transición: colores 200 ms
- Disabled: opacidad 50%, cursor `not-allowed`
- Focus: ring 2px `primary-500` + offset 2px

---

## `input-field`

**Uso**: Inputs de texto, password, email, número, y textareas en formularios.

```html
<input
  id="usuario"
  type="text"
  class="input-field"
  [class.border-red-500]="errorUsuario"
  formControlName="usuario"
/>
```

**Estilos aplicados**:

- Ancho: `w-full`
- Padding: `px-4 py-3` (área táctil ≥ 44 px en móvil)
- Borde: `border border-gray-300 rounded-lg`
- Focus: ring 2px `primary-500`, borde `primary-500`
- Placeholder: `text-gray-400`
- Transición: colores 200 ms
- Font-size: 16px (previene zoom en iOS)

**Estado de error** (agregar clase extra):

```html
<input class="input-field border-red-500" />
<p class="mt-1 text-sm text-red-600">Texto de error descriptivo</p>
```

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

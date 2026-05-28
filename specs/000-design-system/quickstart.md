# Quickstart: Sistema de Diseño Loopi v2

**Feature**: `000-design-system` | **Repo**: `loopi-web-v2`

## Prerrequisitos

El design system se activa instalando una sola dependencia y actualizando `styles.scss`.
No hay configuración adicional de Angular, Tailwind ni PostCSS.

```bash
npm install @fontsource-variable/inter
```

## Estructura de Archivos

```text
loopi-web-v2/
└── src/
    └── styles.scss    ← único archivo a modificar para activar el design system
```

## `styles.scss` Completo

```scss
/* 1. Fuente Inter (self-hosted via @fontsource-variable) */
@import '@fontsource-variable/inter';

/* 2. Tailwind CSS v4 */
@use "tailwindcss";

/* 3. Tokens de diseño de marca */
@theme {
  --font-sans: 'Inter Variable', 'Inter', system-ui, sans-serif;

  /* Paleta primary (café intenso — acciones) */
  --color-primary-50:  #fdf8f6;
  --color-primary-100: #f9ede7;
  --color-primary-200: #f3d9cc;
  --color-primary-300: #e9bfa8;
  --color-primary-400: #dba07f;
  --color-primary-500: #cc8158;
  --color-primary-600: #b86b3d;
  --color-primary-700: #9c5630;
  --color-primary-800: #80462a;
  --color-primary-900: #683a24;
  --color-primary-950: #381c11;

  /* Paleta coffee (grises cálidos — fondos y estructura) */
  --color-coffee-50:  #faf6f2;
  --color-coffee-100: #f3ebe1;
  --color-coffee-200: #e6d4c0;
  --color-coffee-300: #d5b696;
  --color-coffee-400: #c4976c;
  --color-coffee-500: #b87f50;
  --color-coffee-600: #a86944;
  --color-coffee-700: #8c533a;
  --color-coffee-800: #724434;
  --color-coffee-900: #5e392d;
  --color-coffee-950: #321c17;
}

/* 4. Estilos base globales */
html {
  height: 100%;
  height: -webkit-fill-available;
  scroll-behavior: smooth;
}

body {
  min-height: 100%;
  min-height: -webkit-fill-available;
  @apply bg-gray-50 text-gray-900 antialiased font-sans;
  overscroll-behavior-y: contain;
}

/* Prevenir zoom en iOS al hacer foco en inputs */
input[type="number"],
input[type="text"],
input[type="password"],
input[type="email"],
textarea,
select {
  font-size: 16px;
}

/* 5. Utilidades de componente */
/* btn-primary: primary-700 (#9c5630) — contraste 5.5:1 con texto blanco (WCAG 2.1 AA ✅) */
@utility btn-primary {
  @apply bg-primary-700 hover:bg-primary-800 text-white font-semibold
         py-3 px-4 rounded-lg transition-colors duration-200
         disabled:opacity-50 disabled:cursor-not-allowed
         focus:outline-none focus:ring-2 focus:ring-primary-600 focus:ring-offset-2;
}

/* btn-secondary: primary-700 (#9c5630) — contraste 5.5:1 sobre blanco (WCAG 2.1 AA ✅) */
@utility btn-secondary {
  @apply bg-transparent hover:bg-primary-50 text-primary-700 font-semibold
         py-3 px-4 rounded-lg border-2 border-primary-700
         transition-colors duration-200
         disabled:opacity-50 disabled:cursor-not-allowed
         focus:outline-none focus:ring-2 focus:ring-primary-600 focus:ring-offset-2;
}

/* input-field: placeholder-gray-500 — contraste 4.8:1 sobre blanco (WCAG 2.1 AA ✅) */
@utility input-field {
  @apply w-full px-4 py-3 border border-gray-300 rounded-lg
         focus:ring-2 focus:ring-primary-600 focus:border-primary-600
         placeholder-gray-500 transition-colors duration-200;
}

@utility card {
  @apply bg-white rounded-xl shadow-sm border border-gray-100 p-4;
}

@utility touch-manipulation {
  touch-action: manipulation;
  -webkit-tap-highlight-color: transparent;
}

/* 6. Áreas seguras iOS (notch / home indicator) */
.safe-area-top {
  padding-top: env(safe-area-inset-top);
}

.safe-area-bottom {
  padding-bottom: env(safe-area-inset-bottom);
}
```

## Uso en Templates Angular

### Formulario de login

```html
<div class="min-h-screen flex items-center justify-center bg-gray-50 px-4">
  <div class="card w-full max-w-sm">
    <h1 class="text-2xl font-bold text-coffee-950 mb-6">Iniciar sesión</h1>

    <form [formGroup]="form" (ngSubmit)="onSubmit()">
      <div class="mb-4">
        <label for="usuario" class="block text-sm font-medium text-gray-700 mb-1">
          Usuario <span class="text-red-500">*</span>
        </label>
        <input
          id="usuario"
          type="text"
          class="input-field"
          [class.border-red-500]="form.get('usuario')?.invalid && form.get('usuario')?.touched"
          formControlName="usuario"
          autocomplete="username"
          placeholder="ej. juan.perez"
        />
      </div>

      <div class="mb-6">
        <label for="contrasena" class="block text-sm font-medium text-gray-700 mb-1">
          Contraseña <span class="text-red-500">*</span>
        </label>
        <input
          id="contrasena"
          type="password"
          class="input-field"
          [class.border-red-500]="form.get('contrasena')?.invalid && form.get('contrasena')?.touched"
          formControlName="contrasena"
          autocomplete="current-password"
        />
      </div>

      @if (errorMensaje) {
        <p class="mb-4 text-sm text-red-600 error-message">{{ errorMensaje }}</p>
      }

      <button
        type="submit"
        class="btn-primary w-full touch-manipulation"
        [disabled]="form.invalid || cargando"
      >
        @if (cargando) { Ingresando... } @else { Ingresar }
      </button>
    </form>
  </div>
</div>
```

## Convenciones

| Regla | Ejemplo correcto | Ejemplo incorrecto |
|---|---|---|
| Usar tokens, no hex | `text-primary-600` | `style="color:#b86b3d"` |
| Acción primaria por vista | un solo `btn-primary` | dos `btn-primary` en un form |
| Error con texto, no solo color | `<p class="text-red-600">...</p>` | solo `border-red-500` |
| Label asociado a cada input | `<label for="x">` + `id="x"` | solo `placeholder` |
| 16px en inputs (iOS) | ya aplicado por `input-field` | no sobreescribir `font-size` |

## Verificación WCAG 2.1 AA

Ejecutar en la vista de login tras implementar:

```bash
# Con axe-core en el spec
npm run test
```

O manualmente con la extensión axe DevTools en Chrome.

<!--
SYNC IMPACT REPORT
==================
Version: 1.0.0 (extracción inicial)
Origen: extraído de constitution.md v1.12.0 §"Diseño de Interfaz (UX/UI)" como parte de la
        separación principios/estándares (ver constitution.md v2.0.0, Sync Impact Report).
        Ningún contenido normativo cambia de significado en esta extracción;
        solo cambia su ubicación y se le asignan IDs de regla estables.
Reglas: FE-STACK-01, FE-RESP-01, FE-A11Y-01, FE-STATE-01, FE-ERR-01, FE-EMPTY-01, FE-FORM-01,
        FE-LISTFORM-01, FE-LIST-01, FE-FILTER-01, FE-STATUS-01, FE-FORMSURF-01, FE-READONLY-01,
        FE-BTN-01, FE-FEEDBACK-01, FE-VIEW-01, FE-NAV-01, FE-COMP-01, FE-CI-01
-->

# Estándares de Frontend — Loopi v2 (`loopi-web-v2`)

Este documento es normativo (mismo nivel de obligatoriedad que la constitución) y
cubre el **cómo** se implementa el frontend Angular. Los **principios** de por qué el
sistema es como es viven en [`constitution.md`](../constitution.md); este archivo
cambia con más frecuencia que la constitución y tiene su propio versionado semver.

Toda tarea frontend-only o full-stack DEBE verificar cumplimiento de estas reglas
en el `Constitution Check` de `plan.md` (ver `.specify/templates/plan-template.md`).

**`loopi-web-v2/CLAUDE.md` DEBE mantenerse sincronizado con la versión de este
documento** (ver cabecera de versión al inicio de ese archivo). Toda enmienda
aquí requiere propagar el cambio a `loopi-web-v2/CLAUDE.md` en el mismo PR o
en un PR inmediato de seguimiento en ese repositorio.

---

## [FE-STACK-01] Stack de UI

- **Framework CSS**: Tailwind CSS v4 — utility-first, sin librerías de componentes externas.
- **Componentes**: construidos a medida sobre Tailwind CSS. No se usan PrimeNG, Angular Material,
  DaisyUI ni otras librerías de componentes. Los componentes propios viven en
  `loopi-web/src/app/shared/components/`.
- **Fuente y colores**: escala base de Tailwind CSS v4 hasta que el sistema de diseño de marca
  quede definido. Cuando se defina, los tokens van en `tailwind.config.ts` como extensión del
  tema. Ningún color de marca DEBE hardcodearse en clases arbitrarias; siempre como variable
  de diseño.
- Angular (última versión estable), **componentes standalone** obligatorio. Sin NgModules.
- **Signals** para estado reactivo. RxJS solo donde signals no alcance.

---

## [FE-RESP-01] Responsive (Mobile-First)

La aplicación DEBE funcionar correctamente en todos los dispositivos: baristas usan celular en
tienda, administradores y líderes trabajan en desktop. La estrategia es **mobile-first**: los
estilos base aplican a pantallas pequeñas y se extienden con breakpoints de Tailwind.

| Breakpoint | Prefijo Tailwind | Dispositivo objetivo |
| --- | --- | --- |
| < 640 px | (base) | Móvil — baristas en tienda |
| ≥ 640 px | `sm:` | Móvil grande / tablet portrait |
| ≥ 768 px | `md:` | Tablet landscape |
| ≥ 1024 px | `lg:` | Desktop — admin y líderes |
| ≥ 1280 px | `xl:` | Desktop ancho |

Toda vista DEBE ser usable desde el breakpoint base. No se permiten layouts que rompan o
queden inutilizables en pantallas menores a 320 px.

---

## [FE-A11Y-01] Accesibilidad

- **Estándar mínimo**: WCAG 2.1 nivel AA.
- Contraste de color: mínimo 4.5:1 para texto normal, 3:1 para texto grande (≥ 18 pt o 14 pt bold).
- Todo campo de formulario DEBE tener un `<label>` asociado. No se usa `placeholder` como
  reemplazo del label.
- Los errores de validación DEBEN comunicarse con texto descriptivo, no solo con cambio de color.
- Navegación por teclado (Tab / Shift+Tab / Enter / Esc / flechas) DEBE funcionar en todos los
  flujos críticos: login, formularios, modales y menús.
- Los componentes interactivos sin elemento HTML semántico equivalente DEBEN tener atributos
  ARIA (`role`, `aria-label`, `aria-describedby`, `aria-expanded`) según corresponda.
- Las imágenes decorativas llevan `alt=""`. Las imágenes informativas llevan `alt` descriptivo.

---

## [FE-STATE-01] Estados de Carga

| Duración estimada | Indicador |
| --- | --- |
| < 300 ms | Sin indicador (evitar parpadeo innecesario) |
| 300 ms – 3 s | Spinner inline o skeleton loader en el área afectada |
| > 3 s (poco común) | Barra de progreso o mensaje de estado con texto |

Los spinners y skeletons DEBEN estar en el componente afectado, no superpuestos sobre toda la
pantalla, salvo que la acción bloquee realmente toda la interfaz (ej. login inicial).

---

## [FE-ERR-01] Manejo de Errores en UI

- **Error de validación de campo**: texto de error debajo del campo, `text-red-600`, ícono
  opcional. El campo recibe `border-red-500`.
- **Error de API recuperable (4xx)**: toast no intrusivo, esquina superior derecha, auto-cierre
  en 5 s. Nunca bloquear toda la pantalla.
- **Error 401 (sesión expirada)**: `AuthInterceptor` captura y redirige a `/login` con mensaje:
  "Tu sesión expiró. Inicia sesión nuevamente."
- **Error 403 (sin permiso)**: pantalla "No tienes permiso para ver esto" con botón de regreso.
  No revelar datos del recurso al que se intentó acceder.
- **Error 500 / red caída**: mensaje genérico "Ocurrió un error. Intenta de nuevo." con opción
  de reintentar. Registrar en consola para debugging.
- Los mensajes de error al usuario DEBEN ser en español, concisos y accionables. Nunca exponer
  stack traces, IDs internos ni mensajes técnicos al usuario final.
- Los errores de API siempre tienen la forma `{ "error", "mensaje", "campo", "detalles" }`
  (ver [`backend.md#BE-API-01`](backend.md)). Mostrar `mensaje` al usuario; usar `campo` para
  resaltar el campo con error en formularios.

---

## [FE-EMPTY-01] Estados Vacíos (Empty States)

Toda lista, tabla o sección que pueda estar vacía DEBE mostrar un estado vacío con:

- Texto explicativo en primera persona ("Aún no hay pedidos registrados.").
- Acción sugerida cuando aplique ("Crea el primer pedido →").
- Ícono opcional para contexto visual.

Nunca mostrar una lista en blanco sin contexto. El empty state es parte del diseño, no un
caso excepcional. Implementación: `EmptyStateComponent` (ver FE-COMP-01).

---

## [FE-FORM-01] Convenciones de Formularios

- **Validación**: on blur por campo + validación completa on submit.
- **Envío**: el botón de submit DEBE deshabilitarse durante el envío (estado `loading`) para
  prevenir doble-clic. Mostrar spinner inline en el botón o texto "Guardando...".
- **Campos obligatorios**: marcados con `*` junto al label. Leyenda al pie: "* Campo obligatorio".
- **Placeholders**: solo como ejemplo de formato (ej. "ej. usuario@loopi.com"), nunca como
  reemplazo del label.
- **Autocompletar**: habilitar `autocomplete` en credenciales (`current-password`); deshabilitar
  solo cuando el llenado automático sea perjudicial para el flujo.

---

## [FE-LISTFORM-01] Patrón Lista–Formulario

Toda entidad de catálogo o maestro sigue este patrón de navegación y acciones:

- **Lista**: cada fila es clickeable y navega al formulario de edición del registro. No se
  colocan botones de "Editar" ni "Inactivar" por fila. Atributos obligatorios en el `<tr>`:
  `cursor-pointer`, `tabindex="0"`, `role="button"`, handler `(keydown.enter)` para
  accesibilidad por teclado.
- **Formulario (modo edición)**: contiene todas las acciones posibles sobre el registro,
  incluidas las destructivas. Las acciones destructivas van en una sección **"Zona de
  precaución"** al pie del formulario (borde rojo, fondo rojo claro), separada visualmente
  del resto. Un modal de confirmación precede toda acción irreversible.
- **Texto de impacto**: escrito en lenguaje para usuarios no técnicos. No usar jerga interna
  ("unidad canónica", "soft delete", "FK"). Describir el efecto real en el negocio.
  Ejemplo correcto: "Los ítems que usen esta unidad de medida no podrán registrar nuevas
  transacciones." Ejemplo incorrecto: "Los ítems con unidad canónica inactiva quedarán
  bloqueados."

---

## [FE-LIST-01] Superficie de Listado

Todo listado de entidades (tabla, lista de registros) DEBE seguir la misma jerarquía visual
de tres capas que los formularios (ver FE-FORMSURF-01), adaptada a la presentación tabular:

| Capa | Elemento | Clases Tailwind obligatorias |
|------|----------|------------------------------|
| 1 — Página | `<main>` del shell | `bg-gray-50` |
| 2 — Card del listado | `<div>` wrapper | `bg-white rounded-xl border border-gray-100 shadow-sm` |
| 3 — Encabezado de tabla | `<thead>` | `bg-gray-50 border-b border-gray-200` |
| 3 — Filas de datos | `<tbody> <tr>` | `bg-white hover:bg-blue-50/30 transition-colors cursor-pointer` |

**Reglas:**

- El card del listado ocupa el ancho disponible (`w-full`); sin `max-w-*` (a diferencia de los formularios).
- El elemento raíz de la vista de listado es un `<div>` directo sin restricción de ancho.
- No usar `<main>` propio en la vista — sería `<main>` anidado (HTML inválido).
- Implementar con `ListCardComponent` (ver FE-COMP-01).

---

## [FE-FILTER-01] Filtros en Listados

**Posición**: Dentro del card del listado, entre el encabezado y la tabla, separada por
`border-b border-gray-200`. La barra de filtros usa `bg-gray-50/70` para distinguirse del
área de datos. Los controles de filtro usan `h-8` o `h-9` — más compactos que los inputs de
formulario — para comunicar que son controles de navegación, no campos de datos.

**Patrón de chips/pills**: Los filtros activos se representan como chips removibles
(`bg-blue-100 text-blue-700 border border-blue-200 rounded-full`). El chip "Estado: Activo"
aparece azul por defecto; quitarlo explícitamente cambia la vista a todos los registros.

**Regla de default obligatoria**: Todo listado de una entidad con campo `activo` DEBE
preseleccionar el filtro de estado en **Activos** al cargar por primera vez en la sesión.
El usuario puede cambiarlo a Inactivos o Todos de forma explícita. Este filtro se traduce al
parámetro `?estado` del backend (ver [`backend.md#BE-API-01`](backend.md)).

**Implementación**: Usar `FilterBarComponent` con `FilterStateService` (ver FE-COMP-01).
Prohibido implementar filtros ad-hoc por feature.

---

## [FE-STATUS-01] Estados de Registros en Listados

Todo listado con campo `activo` DEBE diferenciar visualmente registros activos e inactivos
con dos mecanismos complementarios:

**1. Badge de estado** — obligatorio en la columna Estado de toda tabla con campo `activo`:

| Estado | Clases del `<span>` |
|--------|---------------------|
| Activo | `inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-700` |
| Inactivo | `inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium bg-gray-100 text-gray-500` |

Implementación: usar `StatusBadgeComponent` (ver FE-COMP-01).

**2. Deemphasis de fila inactiva**: La `<tr>` de un registro inactivo lleva `class="opacity-60"`.
El badge NO recibe `opacity-60` — debe permanecer legible para identificar el estado.

---

## [FE-FORMSURF-01] Superficie de Formulario

Todo formulario de creación o edición DEBE establecer una jerarquía visual de tres capas para
garantizar que los inputs sean percibidos como activos e interactivos en todos los sistemas
operativos y navegadores:

| Capa | Elemento | Clases Tailwind obligatorias |
|------|----------|------------------------------|
| 1 — Página | `<main>` o contenedor raíz | `bg-gray-50` |
| 2 — Tarjeta | `<div>` que envuelve el `<form>` | `bg-white rounded-xl border border-gray-100 shadow-sm p-6 lg:p-8` |
| 3 — Inputs | `<input>`, `<select>`, `<textarea>` | `bg-white` explícito (no depender del default del navegador) |

**Reglas:**

- El contenedor de la tarjeta DEBE tener ancho máximo apropiado a la densidad del formulario:
  - Formularios simples (≤ 6 campos): `max-w-lg` (512 px)
  - Formularios medios (7–15 campos): `max-w-2xl` (672 px)
  - Formularios complejos (> 15 campos o secciones): `max-w-4xl` (896 px)
- La tarjeta se centra horizontalmente con `mx-auto`.
- El `<main>` o página que contenga la tarjeta DEBE usar `bg-gray-50` para que el
  contraste tarjeta/fondo sea visible. Nunca fondo blanco en la página y tarjeta blanca.
- Los campos en estado deshabilitado o read-only: ver FE-READONLY-01.
- La zona de acciones destructivas (inactivar, eliminar) DEBE separarse del formulario principal
  con un `<hr>` y un margen de al menos `mt-8`, ubicada al final de la vista.

**Integración con el Shell:**

Los formularios se renderizan dentro del `<main>` del `ShellComponent`, que ya aplica
`bg-gray-50` al fondo de la página y `p-4 sm:p-6 lg:p-8` como padding base. Por lo tanto:

- **No usar `<main>` propio** en la vista del formulario (sería `<main>` anidado, HTML inválido).
- **No repetir el padding** del shell en el contenedor raíz de la vista.
- El elemento raíz de la vista es un `<div>` con `max-w-{tamaño} mx-auto` para centrar el contenido.

**Ejemplo canónico:**

```html
<!-- Vista del formulario (renderizada dentro del <main> del shell) -->
<div class="max-w-lg mx-auto">
  <!-- Breadcrumb + título fuera de la tarjeta -->
  <nav ...>...</nav>
  <h1 ...>Nueva tienda</h1>

  <!-- Tarjeta del formulario -->
  <div class="bg-white rounded-xl border border-gray-100 shadow-sm p-6 lg:p-8">
    <form ...>
      <input class="bg-white w-full border border-gray-300 rounded-lg px-3 py-2 ..." />
      ...
    </form>
  </div>

  <!-- Zona destructiva (solo en edición) -->
  <div class="mt-8 pt-6 border-t border-gray-200">...</div>
</div>
```

Implementación: `FormCardComponent` (ver FE-COMP-01).

---

## [FE-READONLY-01] Inputs en Estado Read-Only o Deshabilitado

Los campos no editables en formularios de edición (ej. `codigo` de tienda, nombre de usuario
de empleado) DEBEN comunicar inequívocamente su estado mediante contraste con los campos activos:

| Estado | Atributo HTML | Clases del `<input>` |
|--------|--------------|----------------------|
| Editable | — | `bg-white border border-gray-300 text-gray-900 focus:ring-2 focus:ring-blue-500` |
| Read-only | `readonly` | `bg-gray-100 border border-gray-200 text-gray-500 cursor-not-allowed` |
| Deshabilitado | `disabled` | `bg-gray-100 border border-gray-200 text-gray-400 cursor-not-allowed opacity-60` |

**Label del campo read-only**: DEBE incluir una señal visual de no editable. Opciones
(elegir una por módulo, mantenerla consistente):

- Ícono de candado (`LockClosedIcon`, 14 px, `text-gray-400`) junto al label.
- Texto `(no editable)` en `text-xs text-gray-400` junto al label.

**Nunca** usar `bg-white` en un campo `readonly` o `disabled`. El contraste `bg-gray-100`
vs. `bg-white` es el mecanismo primario de comunicación del estado.

Implementación: `ReadonlyFieldComponent` (ver FE-COMP-01).

---

## [FE-BTN-01] Convenciones de Botones de Acción

- **Botón de creación (acción primaria de lista)**: lleva el prefijo `+ ` antes del texto.
  Ejemplos correctos: `+ Nueva tienda`, `+ Nuevo empleado`, `+ Nuevo pedido`.
- **Título de formulario**: NO lleva `+ `. Es un encabezado de página (`<h1>`), no un botón.
  Ejemplos correctos: `Nueva tienda`, `Editar empleado`.
- El prefijo `+ ` aplica solo a los botones/enlaces de acción primaria en vistas de lista.
  No aplica a acciones secundarias (Editar, Inactivar, Reactivar, Cancelar).

---

## [FE-FEEDBACK-01] Feedback de Acciones

- **Éxito (guardar, crear, actualizar)**: toast verde, esquina superior derecha, auto-cierre
  3 s. Texto conciso: "Pedido guardado correctamente."
- **Éxito (eliminar / inactivar)**: toast neutro con opción de deshacer si es reversible en
  la sesión.
- **Acciones destructivas irreversibles**: confirmar con modal antes de ejecutar. El botón de
  confirmación es el más llamativo; el de cancelar es secundario.

---

## [FE-VIEW-01] Estructura Mínima de Vistas

Cada vista de la aplicación DEBE tener:

- **Título de página** (`<h1>`) único y descriptivo — visible en pantalla y en el `<title>`
  del documento.
- **Breadcrumb o navegación contextual** cuando la vista tiene jerarquía padre. En el nivel
  raíz no aplica.
- **Acción primaria** claramente identificada cuando la vista tiene una acción principal
  (ej. "Nuevo pedido", "Confirmar inventario").
- **Layout consistente** con el resto del módulo: mismo padding, misma estructura de header.

Implementación: `PageHeaderComponent` (ver FE-COMP-01).

---

## [FE-NAV-01] Sub-menú Lateral — Estabilidad de Expansión

Cuando el menú lateral contiene grupos con sub-ítems, el estado de expansión del grupo DEBE
estar determinado exclusivamente por el router Angular:

- Un grupo **permanece expandido** mientras la URL activa corresponda a cualquier ruta hija
  del grupo, independientemente de si el usuario navega entre el listado y el formulario del mismo módulo.
- La expansión se implementa con `routerLinkActive` o inspeccionando `router.url` —
  nunca con una variable booleana local que se colapse al navegar.
- El ítem activo dentro del grupo lleva `bg-blue-50 text-blue-700 font-medium`.
- El grupo padre lleva `text-blue-700` cuando algún hijo está activo.
- Un grupo puede colapsarse manualmente solo cuando **ninguna ruta hija está activa**.

---

## [FE-COMP-01] Componentes Angular Transversales

La aplicación provee un catálogo de componentes Angular standalone que toda vista nueva DEBE
usar para garantizar consistencia sin re-implementaciones ad-hoc. Su especificación completa
está en [spec 000-design-system](../../../specs/000-design-system/spec.md).

**Catálogo normativo** (todos en `loopi-web/src/app/shared/`):

| Componente / Servicio | Selector | Responsabilidad |
|----------------------|----------|-----------------|
| `ListCardComponent` | `app-list-card` | Card blanca para listados; capa 2 de la jerarquía visual |
| `FilterBarComponent` | `app-filter-bar` | Barra de filtros con chips; default Estado=Activo |
| `StatusBadgeComponent` | `app-status-badge` | Badge verde/gris para el campo `activo` |
| `DataTableComponent` | `app-data-table` | Tabla con filas clickeables; `opacity-60` en filas inactivas |
| `EmptyStateComponent` | `app-empty-state` | Estado vacío con mensaje y acción sugerida |
| `PaginationComponent` | `app-pagination` | Paginación server-side |
| `PageHeaderComponent` | `app-page-header` | H1 + breadcrumb + slot de acción primaria |
| `FormCardComponent` | `app-form-card` | Card blanca para formularios; variantes sm/md/lg |
| `ReadonlyFieldComponent` | `app-readonly-field` | Label + valor no editable con ícono de candado |
| `DangerZoneComponent` | `app-danger-zone` | Sección de acciones destructivas (borde rojo) |
| `FilterStateService` | `@Injectable({providedIn:'root'})` | Estado de filtros por ruta; persiste durante la sesión |
| `FormModeService` | `@Injectable()` (provisto en el feature) | Contexto create/edit; `DangerZoneComponent` se auto-oculta en create sin `@if` en el template |

**Prohibición**: Está prohibido re-implementar la funcionalidad de cualquier componente de
este catálogo en una vista de feature. Si un componente no cubre el caso, extenderlo con
un `@Input()` nuevo y actualizar la spec 000-design-system.

---

## [FE-CI-01] Gates de CI — `loopi-web-v2`

Ejecutar en orden antes de cada commit, push o PR:

```bash
ng build                          # compila (TypeScript estricto habilitado)
npm audit --audit-level=high      # CVEs de severidad alta/crítica en dependencias de producción
gitleaks detect --no-git          # cero secrets detectados
ng test --watch=false             # todos los tests unitarios pasan
```

**Pruebas frontend**: unitarias por componente + funcionales automatizadas para flujos críticos (P1).

**Gate adicional en CI (GitHub Actions)**: Trivy fs scan (`HIGH,CRITICAL`, `ignore-unfixed: true`).
Ver [`environments-ci.md`](environments-ci.md) para la política común a los tres repos.

---

**Version**: 1.0.0 | **Sincronizado desde**: constitution.md v1.12.0 | **Last Amended**: 2026-07-11

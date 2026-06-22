# Especificación de Feature: Mejoras del Menú Lateral Admin

**Branch de Feature**: `017-sidebar-icons-collapse`

**Creado**: 2026-06-21

**Estado**: Borrador

**Input**: Mejora del menú lateral admin — íconos SVG modernos con Heroicons inline (componente app-icon), colapso manual en desktop con persistencia en localStorage, y refactor de layout sidebar full-height (sidebar como columna exterior del shell).

---

## Escenarios de Usuario y Pruebas *(obligatorio)*

### Historia de Usuario 1 — Íconos visualmente consistentes en el menú lateral (Prioridad: P1)

Un usuario autenticado con cualquier rol (admin, líder de tienda, barista) ve el menú lateral con
íconos de línea (outline) precisos, uniformes y del mismo color que el texto del enlace. Los íconos
se ven idénticos en macOS, Windows, Android y cualquier navegador moderno, porque son vectores SVG,
no emojis dependientes del sistema operativo.

**Por qué esta prioridad**: Es el cambio de mayor impacto visual inmediato. Los emojis son el
elemento que más rompe la percepción profesional de la interfaz. Además, tiene cero riesgo de
regresión funcional.

**Prueba Independiente**: Abrir la aplicación en Chrome/macOS y en Chrome/Windows y verificar que
los íconos del menú se ven idénticos en ambas plataformas, con el color correcto en estado normal
y en estado activo.

**Escenarios de Aceptación**:

1. **Dado** que cualquier usuario autenticado está en la interfaz admin,
   **Cuando** observa el menú lateral,
   **Entonces** cada ítem muestra un ícono SVG de línea que coincide semánticamente con el módulo
   (ej. cuadrícula para Dashboard, edificio para Tiendas, personas para Empleados).

2. **Dado** que el usuario está en el módulo activo (ej. Inventario),
   **Cuando** observa el ícono del ítem activo,
   **Entonces** el ícono adopta el mismo color del texto activo (`text-blue-700`) sin ninguna
   clase adicional, ya que usa `currentColor` para heredar el color del enlace padre.

3. **Dado** que el menú está en modo colapsado (solo íconos visibles en tablet o desktop colapsado),
   **Cuando** el usuario observa los ítems,
   **Entonces** los íconos son suficientemente descriptivos para identificar cada módulo sin texto,
   y el tooltip o `aria-label` muestra el nombre del módulo al enfocar con teclado o mouse.

4. **Dado** que se agrega un nuevo módulo al menú,
   **Cuando** el desarrollador registra el ícono en el componente centralizado,
   **Entonces** el ícono aparece en todos los lugares donde se use el componente de íconos,
   sin duplicar código SVG.

---

### Historia de Usuario 2 — Colapso manual del sidebar en desktop (Prioridad: P1)

Un admin o líder que trabaja en desktop con módulos de muchos datos (inventario, pedidos, ventas)
puede colapsar el menú lateral con un clic para ganar espacio horizontal en el área de contenido.
Al volver a expandirlo, recupera el menú completo con nombre e ícono. La preferencia se recuerda
entre sesiones: si el usuario dejó el sidebar colapsado ayer, abre la app hoy y lo encuentra
colapsado.

**Por qué esta prioridad**: El sidebar ocupa 256px en desktop (w-64). Para módulos con tablas de
muchas columnas o formularios anchos, ese espacio es valioso. Es la mejora de productividad más
directa para el usuario de escritorio.

**Prueba Independiente**: En desktop (≥ 1024px), hacer clic en el botón de colapso, cerrar el
navegador, y al reabrir verificar que el sidebar mantiene su estado colapsado.

**Escenarios de Aceptación**:

1. **Dado** que el usuario está en desktop (pantalla ≥ 1024px) con el sidebar expandido,
   **Cuando** hace clic en el botón de colapso (chevron izquierdo),
   **Entonces** el sidebar se contrae al ancho de solo íconos en menos de 200ms con una
   transición suave, y el área de contenido se expande para ocupar el espacio liberado.

2. **Dado** que el sidebar está colapsado en desktop,
   **Cuando** el usuario hace clic en el botón de expansión (chevron derecho),
   **Entonces** el sidebar se expande mostrando ícono y nombre de cada módulo en menos de 200ms.

3. **Dado** que el usuario colapsó el sidebar en desktop,
   **Cuando** cierra el navegador y vuelve a abrir la aplicación,
   **Entonces** el sidebar aparece colapsado, respetando la preferencia guardada.

4. **Dado** que el sidebar está colapsado en desktop,
   **Cuando** el usuario navega entre módulos,
   **Entonces** el estado colapsado se mantiene durante toda la sesión de navegación.

5. **Dado** que el sidebar está en cualquier estado (expandido/colapsado),
   **Cuando** la pantalla cambia a tablet (640–1023px) o móvil (< 640px),
   **Entonces** el comportamiento responsive de esos breakpoints toma precedencia
   (tablet siempre colapsado, móvil oculto con hamburguesa) independientemente de la
   preferencia de desktop.

---

### Historia de Usuario 3 — Sidebar de altura completa (Prioridad: P2)

Un admin que usa la interfaz en desktop percibe el menú lateral como una columna vertical que
va desde el borde superior hasta el borde inferior de la ventana, con la identidad de marca
(logo "Loopi") en la parte superior del propio sidebar. La cabecera de la aplicación ocupa
únicamente el espacio a la derecha del sidebar, no toda la anchura de la pantalla.

**Por qué esta prioridad**: Este es el patrón de layout de las aplicaciones SaaS modernas de
referencia (Linear, Vercel, Supabase, Notion). Comunica solidez, modernidad y familiaridad
para usuarios acostumbrados a estas herramientas. Sin embargo, es un refactor de layout que
no agrega funcionalidad nueva — de ahí P2.

**Prueba Independiente**: En desktop, verificar que el sidebar llega al borde superior de la
ventana (sin espacio de topbar encima), que el logo aparece dentro del sidebar, y que la
cabecera de la aplicación está a la derecha del sidebar.

**Escenarios de Aceptación**:

1. **Dado** que un admin está en desktop (≥ 1024px),
   **Cuando** observa el layout general de la interfaz,
   **Entonces** el sidebar ocupa toda la altura de la ventana de tope a fondo, sin que
   la topbar se interponga por encima de él.

2. **Dado** que el sidebar es la columna exterior del layout,
   **Cuando** el usuario observa la parte superior del sidebar en desktop,
   **Entonces** ve el logo o nombre de la aplicación ("Loopi") dentro del propio sidebar,
   no en la topbar.

3. **Dado** que el layout fue refactorizado,
   **Cuando** el usuario usa la interfaz en tablet (640–1023px) o móvil (< 640px),
   **Entonces** el comportamiento responsive existente (colapsado a íconos en tablet,
   drawer con hamburguesa en móvil) se mantiene sin regresiones.

4. **Dado** que el sidebar full-height está implementado,
   **Cuando** el admin colapsa manualmente el sidebar en desktop (Historia 2),
   **Entonces** el sidebar colapsado sigue siendo full-height, solo cambia su ancho.

---

### Casos Límite

- ¿Qué ocurre si `localStorage` no está disponible (navegación privada, políticas del navegador)?
  → El sidebar inicia en estado expandido como valor por defecto; no bloquea la funcionalidad.
- ¿Qué ocurre si se agrega un módulo con un ícono no registrado en el componente `app-icon`?
  → Se muestra un ícono genérico de fallback (punto o cuadrado sólido) para no romper el layout.
- ¿Qué ocurre con el tooltip del ícono en modo colapsado al usar teclado?
  → El `aria-label` del enlace expone el nombre del módulo al lector de pantalla; el `title`
  HTML provee el tooltip visual en hover.
- ¿Qué ocurre en la transición al redimensionar la ventana entre breakpoints mientras el
  sidebar está colapsado manualmente?
  → La preferencia guardada solo aplica en ≥ 1024px. En tablet y móvil, las reglas CSS de
  breakpoint tienen prioridad.
- ¿Qué ocurre con el botón de colapso en tablet (640–1023px)?
  → El botón de colapso manual no aparece en tablet. En tablet el sidebar siempre está en
  modo ícono (w-16) por CSS, que es el equivalente al estado colapsado.

---

## Requisitos *(obligatorio)*

### Requisitos Funcionales

- **FR-001**: El sistema DEBE reemplazar los emojis actuales del menú lateral por íconos SVG
  de línea (outline) de Heroicons v2, usando `currentColor` para heredar el color del enlace
  padre en todos los estados (normal, hover, activo).

- **FR-002**: Los paths SVG de los íconos DEBEN estar centralizados en un único componente
  (`app-icon`) que recibe el nombre del ícono como parámetro. No se permite SVG inline
  duplicado en múltiples templates.

- **FR-003**: El componente `app-icon` DEBE incluir los íconos para los 11 módulos del menú
  y un ícono de fallback para nombres no registrados.

- **FR-004**: En modo colapsado del sidebar (solo íconos visibles), cada ícono DEBE tener
  un `aria-label` con el nombre del módulo y un atributo `title` HTML para el tooltip visual.

- **FR-005**: El sistema DEBE ofrecer un botón de colapso/expansión manual del sidebar
  visible en desktop (≥ 1024px), ubicado en la parte inferior o superior del sidebar.

- **FR-006**: El estado colapsado/expandido del sidebar en desktop DEBE persistir en
  `localStorage` con la clave `loopi_sidebar_collapsed`. El valor es `"true"` o `"false"`.

- **FR-007**: Al cargar la aplicación, el sidebar DEBE leer el estado desde `localStorage`
  e inicializarse en el estado guardado. Si la clave no existe o `localStorage` no está
  disponible, iniciar expandido.

- **FR-008**: La transición de colapso y expansión del sidebar DEBE completarse en menos de
  200ms con animación CSS suave (transición de ancho).

- **FR-009**: El layout del shell DEBE refactorizarse para que el sidebar sea la columna
  exterior izquierda del layout (el sidebar ocupa `h-screen` completo); la topbar y el
  contenido principal van en la columna derecha.

- **FR-010**: En el nuevo layout, el logo/nombre de la aplicación DEBE estar en la parte
  superior del sidebar (no en la topbar). En desktop expandido muestra texto completo;
  en modo colapsado muestra solo el ícono o inicial.

- **FR-011**: El botón hamburguesa de la topbar (para abrir el sidebar en móvil) DEBE
  seguir funcionando correctamente después del refactor de layout.

- **FR-012**: El refactor de layout NO DEBE introducir regresiones en los comportamientos
  responsive existentes: tablet colapsado a íconos, móvil con drawer.

- **FR-013**: Cuando la URL activa corresponde a cualquier ruta hija de un grupo de menú
  (ej. listado de empleados `/empleados` o formulario `/empleados/nuevo`), el grupo DEBE
  permanecer expandido sin colapsarse al navegar entre esas rutas. La expansión es determinada
  exclusivamente por el estado del router Angular (`routerLinkActive` o inspección de
  `router.url`) — nunca por una variable booleana local. Un grupo puede colapsarse manualmente
  solo cuando ninguna de sus rutas hijas está activa en ese momento.

### Entidades Clave

- **Componente `app-icon`**: Componente Angular standalone que recibe `name: string` como
  input y renderiza el SVG correspondiente. Centraliza todos los paths SVG del sistema.

- **Estado de colapso del sidebar**: Preferencia del usuario almacenada en `localStorage`
  que indica si el sidebar desktop está colapsado o expandido. Independiente del estado
  de apertura en móvil.

---

## Criterios de Éxito *(obligatorio)*

### Resultados Medibles

- **SC-001**: Los íconos del menú se ven idénticos en Chrome/macOS y Chrome/Windows — cero
  diferencias de renderizado entre plataformas.

- **SC-002**: La transición de colapso/expansión del sidebar en desktop se completa en
  menos de 200ms medidos desde el clic hasta que la animación termina.

- **SC-003**: El estado del sidebar (colapsado/expandido) se restaura correctamente en
  el 100% de las recargas de página tras ser guardado.

- **SC-004**: Cero regresiones en la navegación por teclado y lectores de pantalla:
  todos los ítems del menú mantienen su `aria-label` y navegación Tab/Enter/Esc.

- **SC-005**: El sidebar ocupa toda la altura de la ventana en desktop (0px de espacio
  sin cubrir arriba o abajo del sidebar).

- **SC-006**: Los 11 módulos del menú tienen ícono SVG apropiado; ningún módulo muestra
  el ícono de fallback en la build de producción.

- **SC-007**: La tasa de completación de tareas de navegación no regresa respecto a la
  feature `016-admin-nav` — el menú sigue siendo usable con la misma efectividad.

---

## Supuestos

- La feature `016-admin-nav` está implementada y mergeada: `ShellComponent`, `SidebarComponent`,
  `TopbarComponent` y `NavConfigService` existen y funcionan en `loopi-web`.
- Los íconos de Heroicons v2 outline se usan copiando los paths SVG directamente en el
  código fuente — no se instala ningún paquete npm adicional.
- `localStorage` está disponible en todos los navegadores objetivo (Chrome, Firefox, Safari
  modernos). En navegación privada donde `localStorage` falla silenciosamente, la experiencia
  degrada a sidebar expandido por defecto.
- El botón de colapso manual solo aparece en desktop (≥ 1024px). En tablet y móvil el
  comportamiento de colapso es controlado exclusivamente por CSS breakpoints y el toggle
  de hamburguesa respectivamente.
- El refactor de layout (FR-009 a FR-012) no requiere cambios en `loopi-api`.
- Los tests unitarios existentes de `SidebarComponent` y `ShellComponent` deberán
  actualizarse para reflejar el nuevo comportamiento — no se eliminarán, se adaptarán.

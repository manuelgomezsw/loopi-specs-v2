# Especificación de Feature: Interfaz Admin y Navegación Global

**Branch de Feature**: `016-admin-nav`

**Creado**: 2026-06-21

**Estado**: Borrador

**Input**: Interfaz de tipo admin con menú de navegación que permita moverse entre módulos sin depender de conocer la URL directa.

---

## Escenarios de Usuario y Pruebas *(obligatorio)*

### Historia de Usuario 1 — Admin accede a cualquier módulo desde el menú lateral (Prioridad: P1)

Un administrador, tras iniciar sesión, ve una interfaz con un menú lateral permanente que lista
todos los módulos del sistema (tiendas, empleados, catálogo, inventario, pedidos, mermas, etc.).
Hace clic en el módulo deseado y llega directamente a él, sin necesidad de conocer la URL.

**Por qué esta prioridad**: Resuelve el problema central reportado: el admin queda atrapado en
la pantalla de tiendas sin forma de navegar a otros módulos sin saber la URL. Es la puerta de
entrada a toda la funcionalidad del sistema.

**Prueba Independiente**: Con un usuario `admin` autenticado, verificar que el menú lateral muestra
todos los módulos disponibles y que hacer clic en cada uno redirige correctamente a ese módulo.

**Escenarios de Aceptación**:

1. **Dado** que un admin ha iniciado sesión,
   **Cuando** carga cualquier pantalla del sistema (excepto login),
   **Entonces** el menú lateral está visible con todos los módulos disponibles para su rol.

2. **Dado** que el admin está en la pantalla de Tiendas,
   **Cuando** hace clic en "Inventario" en el menú lateral,
   **Entonces** el sistema lo lleva a la pantalla de Inventario sin recargar la página completa.

3. **Dado** que el admin está navegando en cualquier módulo,
   **Cuando** observa el menú lateral,
   **Entonces** el módulo activo está resaltado visualmente para indicar la ubicación actual.

4. **Dado** que el admin está en un módulo secundario (p. ej., detalle de un pedido),
   **Cuando** hace clic en otro módulo del menú,
   **Entonces** el sistema navega al nuevo módulo correctamente.

---

### Historia de Usuario 2 — Admin selecciona tienda desde selector global (Prioridad: P1)

El administrador, que tiene acceso a todas las tiendas, puede cambiar el contexto de tienda
desde un selector global visible en la cabecera de la interfaz. Al seleccionar una tienda
específica, todos los módulos operacionales muestran datos filtrados por esa tienda. Si no
selecciona ninguna, ve la vista consolidada.

**Por qué esta prioridad**: El admin es el rol que más usa el sistema y su flujo de trabajo
requiere cambiar entre tiendas y la vista consolidada con frecuencia. Es parte fundamental
del shell de administración.

**Prueba Independiente**: Con un admin autenticado y al menos dos tiendas activas, verificar
que el selector cambia el contexto visible en los módulos y que la opción "Consolidado"
muestra datos agregados.

**Escenarios de Aceptación**:

1. **Dado** que el admin está en la interfaz principal,
   **Cuando** observa la cabecera,
   **Entonces** ve un selector de tienda con la opción "Vista consolidada" como valor por defecto.

2. **Dado** que el admin selecciona "Tienda Norte" en el selector global,
   **Cuando** navega a Inventario,
   **Entonces** el inventario muestra solo los datos de "Tienda Norte".

3. **Dado** que el admin tiene una tienda seleccionada,
   **Cuando** navega entre módulos usando el menú lateral,
   **Entonces** el contexto de tienda se mantiene sin reiniciarse.

4. **Dado** que el admin tiene "Tienda Norte" seleccionada,
   **Cuando** cambia a "Vista consolidada" en el selector,
   **Entonces** los módulos muestran datos agregados de todas las tiendas activas.

---

### Historia de Usuario 3 — Lider de tienda y barista ven menú filtrado por rol (Prioridad: P2)

Un líder de tienda o barista, tras iniciar sesión, ve el mismo menú lateral pero solo con
los módulos a los que tiene permiso. No ve opciones de administración (tiendas, empleados,
catálogo). Su contexto de tienda está fijo a la tienda asignada y no existe selector global.

**Por qué esta prioridad**: Compartir el mismo shell de navegación para todos los roles
simplifica el desarrollo y la experiencia, pero requiere que cada rol vea solo lo que le
corresponde. Es importante para seguridad y claridad.

**Prueba Independiente**: Con usuarios `lider_tienda` y `barista`, verificar que el menú
lateral solo muestra los módulos permitidos y que no aparece el selector de tienda global.

**Escenarios de Aceptación**:

1. **Dado** que un lider_tienda ha iniciado sesión,
   **Cuando** observa el menú lateral,
   **Entonces** solo ve los módulos: Inventario, Mermas, Pedidos (recepción), Caja Menor y Ventas.

2. **Dado** que un barista ha iniciado sesión,
   **Cuando** observa el menú lateral,
   **Entonces** solo ve los módulos a los que tiene acceso según la matriz de permisos.

3. **Dado** que un lider_tienda o barista está autenticado,
   **Cuando** observa la cabecera,
   **Entonces** no existe selector de tienda global; su tienda asignada se muestra como contexto fijo.

4. **Dado** que un usuario sin el rol `admin` intenta acceder directamente por URL a un módulo
   de administración,
   **Cuando** el sistema valida su sesión,
   **Entonces** el sistema lo redirige a su módulo principal permitido y no muestra el contenido
   restringido.

---

### Casos Límite

- ¿Qué ocurre si el admin no tiene tiendas activas? → El selector de tienda muestra solo "Vista consolidada".
- ¿Qué ocurre si la sesión expira mientras el usuario navega? → El sistema redirige al login conservando la ruta destino para retomar tras re-autenticarse.
- ¿Qué ocurre si un usuario con rol desconocido o corrupto llega al shell? → El sistema cierra sesión y muestra un mensaje de error.
- ¿Qué ocurre en pantallas de ancho reducido (tablet/móvil)? → El menú lateral se contrae a íconos o se convierte en menú tipo hamburguesa.

---

## Requisitos *(obligatorio)*

### Requisitos Funcionales

- **FR-001**: El sistema DEBE mostrar un menú lateral permanente en todas las pantallas autenticadas (excepto login), con acceso a los módulos habilitados para el rol del usuario activo.

- **FR-002**: El menú lateral DEBE mostrar únicamente las secciones a las que el usuario tiene acceso según su rol (`admin`, `lider_tienda`, `barista`), ocultando completamente las opciones no autorizadas.

- **FR-003**: El menú lateral DEBE resaltar visualmente el módulo activo según la sección en la que se encuentra el usuario.

- **FR-004**: El usuario DEBE poder navegar a cualquier módulo permitido en máximo 2 interacciones desde cualquier punto de la aplicación (1 clic si el menú está visible, 2 clics si está colapsado).

- **FR-005**: El sistema DEBE mostrar un selector de tienda global en la cabecera, visible únicamente para usuarios con rol `admin`, con las opciones: "Vista consolidada" (por defecto) y la lista de tiendas activas.

- **FR-006**: Al cambiar el contexto de tienda en el selector global, el sistema DEBE actualizar la vista del módulo actual con los datos de la tienda seleccionada, sin perder la navegación (no redirigir al inicio).

- **FR-007**: El contexto de tienda seleccionado DEBE persistir durante toda la sesión de navegación; al cambiar de módulo, el contexto no se reinicia.

- **FR-008**: Los usuarios con rol `lider_tienda` o `barista` DEBE ver su tienda asignada como contexto fijo en la cabecera, sin posibilidad de cambiarla.

- **FR-009**: El sistema DEBE impedir el acceso a módulos no autorizados por rol, tanto desde la interfaz (ocultando opciones) como validando en la carga de cada ruta protegida.

- **FR-010**: El menú lateral DEBE ser funcional en pantallas de escritorio y tablet, adaptando su presentación al ancho disponible.

### Entidades Clave

- **Shell de Administración**: Estructura de interfaz que envuelve todas las pantallas autenticadas; contiene el menú lateral y la cabecera con el selector de tienda.

- **Ítem de Menú**: Entrada de navegación con nombre, ícono, ruta destino y lista de roles autorizados. Cada módulo del sistema tiene un ítem de menú correspondiente.

- **Contexto de Sesión de Navegación**: Estado que mantiene el rol activo del usuario y la tienda seleccionada (para `admin`) o asignada (para otros roles) durante la navegación.

---

## Criterios de Éxito *(obligatorio)*

### Resultados Medibles

- **SC-001**: Un admin recién autenticado puede acceder a cualquier módulo del sistema en 1 clic desde la pantalla de aterrizaje post-login.

- **SC-002**: El 100% de los módulos del sistema son accesibles desde el menú de navegación sin necesidad de conocer o escribir la URL directa.

- **SC-003**: El selector de tienda responde al cambio de contexto en menos de 1 segundo, actualizando los datos del módulo activo.

- **SC-004**: El menú lateral muestra cero opciones no autorizadas para cualquier rol (tasa de error de visibilidad: 0%).

- **SC-005**: El contexto de tienda seleccionado se conserva en el 100% de las transiciones entre módulos durante la misma sesión.

- **SC-006**: La tasa de completación de tareas de navegación entre módulos es ≥ 95% en la primera interacción (sin requerir ayuda ni conocimiento previo de URLs).

---

## Supuestos

- El módulo de autenticación (`001-autenticacion`) está implementado y el token de sesión incluye el `rol` del usuario y, para roles no-admin, el `tienda_id` asignado.
- Los módulos existentes no requieren modificación de su lógica interna; la navegación se implementa como una capa de shell que los envuelve.
- La interfaz es web (aplicación de escritorio/tablet en navegador) para esta versión; soporte móvil nativo está fuera de alcance.
- El catálogo de módulos del sistema está definido y es estable para esta versión (los 14 módulos documentados en la especificación funcional).
- El listado de tiendas activas para el selector global proviene del mismo backend que gestiona el módulo de tiendas (`002-gestion-tiendas`).
- La pantalla de login es la única pantalla que no muestra el shell de navegación.

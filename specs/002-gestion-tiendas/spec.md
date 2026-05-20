# Especificación de Feature: Gestión de Tiendas

**Branch de Feature**: `002-gestion-tiendas`
**Creado**: 2026-05-18
**Estado**: Borrador
**Referencia funcional**: [§2.3 Gestión de Tiendas](../loopi-v2-funcional/spec.md)

---

## Escenarios de Usuario y Pruebas *(obligatorio)*

### Historia de Usuario 1 — Crear una tienda nueva (Prioridad: P1)

El administrador registra un nuevo punto de venta físico en el sistema ingresando su nombre,
dirección, ciudad y teléfono. Una vez creada, la tienda queda activa y disponible para asignar
empleados e iniciar operaciones.

**Por qué esta prioridad**: Sin al menos una tienda creada, ningún empleado puede operar
el sistema ni iniciarse el primer inventario.

**Prueba Independiente**: Puede verificarse creando una tienda y comprobando que aparece en
el listado de tiendas activas y que es seleccionable como contexto en el panel del admin.

**Escenarios de Aceptación**:

1. **Dado** que el admin está autenticado,
   **Cuando** crea una tienda con nombre, dirección, ciudad y teléfono válidos,
   **Entonces** la tienda queda registrada como activa y aparece en el listado de tiendas.

2. **Dado** que ya existe una tienda con el mismo nombre,
   **Cuando** el admin intenta crear otra con el mismo nombre,
   **Entonces** el sistema rechaza la operación con un mensaje indicando que el nombre ya existe.

3. **Dado** que un líder de tienda o barista está autenticado,
   **Cuando** intenta acceder a la pantalla de gestión de tiendas,
   **Entonces** el sistema deniega el acceso; solo el admin puede ver y gestionar tiendas.

---

### Historia de Usuario 2 — Editar los datos de una tienda (Prioridad: P1)

El administrador actualiza la información de un punto de venta existente (nombre, dirección,
ciudad o teléfono) cuando estos datos cambian. Los cambios no afectan el historial operativo
de la tienda.

**Por qué esta prioridad**: Los datos de contacto y ubicación cambian con el tiempo; el admin
debe poder mantenerlos actualizados sin perder el historial.

**Prueba Independiente**: Puede verificarse editando un campo y comprobando que el cambio
se refleja de inmediato en el listado y en el selector de tienda del panel del admin.

**Escenarios de Aceptación**:

1. **Dado** que existe una tienda activa,
   **Cuando** el admin edita su dirección y guarda,
   **Entonces** la tienda muestra la nueva dirección y su historial de inventarios se conserva intacto.

2. **Dado** que el admin intenta renombrar una tienda con el nombre de otra existente,
   **Cuando** guarda los cambios,
   **Entonces** el sistema rechaza la operación con un mensaje de nombre duplicado.

---

### Historia de Usuario 3 — Inactivar una tienda (Prioridad: P2)

El administrador marca una tienda como inactiva cuando el punto de venta deja de operar
(cierre temporal o definitivo). La tienda inactiva conserva todo su historial pero no puede
iniciar nuevas operaciones.

**Por qué esta prioridad**: El cierre de un local es un evento de negocio real; inactivar
sin borrar preserva la trazabilidad histórica exigida por el Principio IV de la constitución.

**Prueba Independiente**: Puede verificarse inactivando una tienda y comprobando que ya no
aparece como opción para iniciar inventarios o pedidos, pero su historial sigue visible.

**Escenarios de Aceptación**:

1. **Dado** que existe una tienda activa con historial de inventarios,
   **Cuando** el admin la inactiva,
   **Entonces** la tienda deja de aparecer en el selector de tiendas operativas y su historial
   permanece accesible para el admin.

2. **Dado** que una tienda está inactiva,
   **Cuando** alguien intenta iniciar un inventario o pedido en esa tienda,
   **Entonces** el sistema bloquea la operación con un mensaje indicando que la tienda no está activa.

3. **Dado** que una tienda tiene empleados asignados y se inactiva,
   **Cuando** esos empleados intentan iniciar sesión,
   **Entonces** el sistema les permite autenticarse pero no encuentran operaciones disponibles
   en su tienda inactiva.

---

### Historia de Usuario 4 — Ver el listado de tiendas (Prioridad: P1)

El administrador consulta la lista de todas las tiendas registradas (activas e inactivas)
para tener visibilidad del estado de cada punto de venta de la marca.

**Por qué esta prioridad**: Es la pantalla de entrada a la gestión de tiendas y la base para
seleccionar qué tienda administrar.

**Prueba Independiente**: Puede verificarse con múltiples tiendas en distintos estados y
comprobando que el listado las muestra todas con su estado correcto.

**Escenarios de Aceptación**:

1. **Dado** que existen tiendas activas e inactivas,
   **Cuando** el admin accede al listado de tiendas,
   **Entonces** ve todas las tiendas con su nombre, ciudad y estado (activa/inactiva).

2. **Dado** que el admin está en el listado,
   **Cuando** hace clic en una tienda,
   **Entonces** puede ver y editar todos sus datos.

---

## Requisitos Funcionales

### RF-TDA-01: Creación de tiendas

- RF-TDA-01.1: Solo el administrador puede crear tiendas. Cualquier otro rol recibe acceso denegado.
- RF-TDA-01.2: Una tienda requiere como mínimo: nombre, dirección, ciudad y teléfono.
- RF-TDA-01.3: El nombre de la tienda es único en todo el sistema. El sistema rechaza nombres duplicados.
- RF-TDA-01.4: Una tienda recién creada queda en estado activo por defecto.

### RF-TDA-02: Edición de tiendas

- RF-TDA-02.1: Solo el administrador puede editar los datos de una tienda.
- RF-TDA-02.2: Se pueden editar: nombre, dirección, ciudad y teléfono.
- RF-TDA-02.3: Al editar el nombre, el sistema verifica que no exista otra tienda con ese nombre.
- RF-TDA-02.4: La edición no afecta el historial operativo de la tienda (inventarios, pedidos,
  mermas previos se conservan).

### RF-TDA-03: Inactivación de tiendas

- RF-TDA-03.1: Solo el administrador puede inactivar una tienda.
- RF-TDA-03.2: Una tienda inactiva no puede iniciar nuevos inventarios, pedidos ni compras
  de caja menor. El sistema bloquea estas operaciones con mensaje explicativo.
- RF-TDA-03.3: El historial de una tienda inactiva (inventarios, pedidos, mermas, ventas)
  es accesible para el administrador.
- RF-TDA-03.4: Una tienda inactiva puede volver a activarse. Al reactivarse, retoma su
  operación normal sin perder el historial previo.
- RF-TDA-03.5: No es posible eliminar una tienda; solo inactivarla.

### RF-TDA-04: Listado y consulta

- RF-TDA-04.1: El administrador puede ver el listado de todas las tiendas (activas e inactivas)
  con nombre, ciudad y estado.
- RF-TDA-04.2: Desde el listado, el administrador puede acceder al detalle y edición de
  cualquier tienda.
- RF-TDA-04.3: Las tiendas activas aparecen en el selector global de tienda del panel del
  administrador. Las inactivas no aparecen en dicho selector.

### RF-TDA-05: Aislamiento de datos por tienda

- RF-TDA-05.1: Toda operación del sistema que genera datos (inventario, pedido, merma, compra,
  venta) registra el identificador de la tienda donde ocurrió.
- RF-TDA-05.2: Los empleados con rol lider_tienda y barista solo acceden a datos de su tienda
  asignada. El sistema filtra automáticamente por tienda en todos los módulos operacionales.

---

## Criterios de Éxito

- **Gestión sin errores**: El admin puede crear, editar e inactivar una tienda en menos de
  2 minutos cada operación.
- **Control de acceso**: El 100% de los intentos de gestión de tiendas por parte de roles no
  admin son bloqueados por el sistema.
- **Integridad del historial**: Al inactivar una tienda, el 100% de su historial previo permanece
  accesible para el admin sin pérdida de información.
- **Unicidad de nombres**: El sistema previene el 100% de los casos de tiendas con nombre
  duplicado en el momento de crear o editar.
- **Aislamiento operativo**: Ningún empleado de tienda puede ver ni operar datos de una tienda
  distinta a la suya; el 100% de las operaciones se filtran por tienda.

---

## Entidades Clave

| Entidad | Atributos |
|---------|-----------|
| `Tienda` | nombre (único), dirección, ciudad, teléfono, activo |

---

## Dependencias y Suposiciones

### Dependencias

- **001-autenticacion**: El admin debe estar autenticado para gestionar tiendas. El identificador
  de tienda (`tienda_id`) queda registrado en la sesión de lider_tienda y barista al momento
  del login.
- **003-empleados** (posterior): La tienda es prerequisito para asignar empleados. La edición
  de la tienda asignada a un empleado corresponde a esa feature.

### Suposiciones

- No existe concepto de "grupos de tiendas" ni jerarquías entre tiendas; todas pertenecen
  a la misma marca.
- El administrador puede reactivar una tienda inactiva sin restricciones adicionales.
- No se maneja historial de cambios de nombre de tienda en esta versión; el nombre actual
  es el único visible en reportes históricos.

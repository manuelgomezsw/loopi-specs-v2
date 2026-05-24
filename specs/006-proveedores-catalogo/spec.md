# Especificación de Feature: Proveedores del Catálogo

**Branch de Feature**: `006-proveedores-catalogo`
**Creado**: 2026-05-19
**Estado**: Borrador
**Referencia funcional**: [§4.2 Gestión de Proveedores](../loopi-v2-funcional/spec.md)

---

## Clarifications

### Session 2026-05-24

- Q: ¿Es el NIT editable después de que el proveedor es creado? → A: Sí, el NIT es editable con validación de unicidad (Opción A)
- Q: ¿El sistema valida el formato del NIT (colombiano estricto, solo numérico, o cadena libre)? → A: Cadena libre no vacía; solo valida unicidad, sin restricción de formato (Opción B)
- Q: ¿El listado de proveedores requiere búsqueda o filtrado? → A: Filtro por estado (activo/inactivo) y búsqueda por texto (razón social o NIT) (Opción B)
- Q: ¿La reactivación de un proveedor requiere su propia Historia de Usuario o se cubre como escenario dentro de HU-3? → A: Escenario adicional dentro de HU-3; no requiere historia separada (Opción A)
- Q: ¿Qué muestra el listado de proveedores cuando el catálogo está vacío? → A: Mensaje "No hay proveedores registrados" con botón CTA para crear el primero (Opción A)

---

## Escenarios de Usuario y Pruebas *(obligatorio)*

### Historia de Usuario 1 — Registrar un proveedor (Prioridad: P1)

El administrador registra un nuevo proveedor ingresando su razón social, NIT, y los datos
de contacto (nombre, teléfono y email del contacto). Una vez registrado, el proveedor queda
disponible para asignarlo a items y para generar pedidos de compra.

**Por qué esta prioridad**: Sin al menos un proveedor registrado no se pueden crear items
con proveedor asignado ni generar pedidos de compra. Es prerequisito directo de los módulos
de items y pedidos.

**Prueba Independiente**: Puede verificarse creando un proveedor y comprobando que aparece
disponible al crear o editar un item.

**Escenarios de Aceptación**:

1. **Dado** que el admin está autenticado,
   **Cuando** registra un proveedor con razón social, NIT, nombre de contacto, teléfono y
   email válidos,
   **Entonces** el proveedor queda registrado como activo y aparece en el listado de
   proveedores.

2. **Dado** que ya existe un proveedor con el mismo NIT,
   **Cuando** el admin intenta registrar otro con el mismo NIT,
   **Entonces** el sistema rechaza la operación indicando que el NIT ya está registrado.

3. **Dado** que un lider_tienda o barista intenta acceder a la gestión de proveedores,
   **Cuando** navega a esa sección,
   **Entonces** el sistema deniega el acceso; solo el admin puede gestionar este catálogo.

---

### Historia de Usuario 2 — Editar los datos de un proveedor (Prioridad: P2)

El administrador actualiza la información de un proveedor existente cuando cambia el contacto,
el teléfono, el email o la razón social. Los cambios se reflejan de inmediato en todos los
items que tienen ese proveedor asignado.

**Por qué esta prioridad**: Los datos de contacto de los proveedores cambian con frecuencia;
mantenerlos actualizados es esencial para la gestión de pedidos pero no bloquea la operación
mientras el proveedor esté activo.

**Prueba Independiente**: Puede verificarse editando el nombre de contacto de un proveedor
y comprobando que el cambio se refleja en el listado y en los items que lo tienen asignado.

**Escenarios de Aceptación**:

1. **Dado** que existe un proveedor activo,
   **Cuando** el admin actualiza el nombre de contacto y el teléfono y guarda,
   **Entonces** el proveedor muestra los nuevos datos de contacto sin afectar los items
   ni el historial de pedidos asociados.

2. **Dado** que el admin intenta cambiar el NIT de un proveedor por el NIT de otro
   proveedor ya registrado,
   **Cuando** guarda los cambios,
   **Entonces** el sistema rechaza la operación indicando que el NIT ya pertenece a otro
   proveedor.

---

### Historia de Usuario 3 — Inactivar y reactivar un proveedor (Prioridad: P2)

El administrador marca un proveedor como inactivo cuando deja de trabajar con él, o lo
reactiva si retoma la relación comercial. El proveedor inactivo ya no aparece como opción
para nuevos pedidos, pero los items que lo tenían asignado conservan esa referencia y el
historial de pedidos previos se mantiene intacto. Al reactivarse, el proveedor vuelve a
estar disponible sin pérdida de historial.

**Por qué esta prioridad**: El retiro de un proveedor es un evento de negocio real; inactivar
sin borrar preserva la trazabilidad histórica exigida por el Principio IV de la constitución.

**Prueba Independiente**: Puede verificarse inactivando un proveedor y comprobando que no
aparece como opción al crear un nuevo pedido, pero sus pedidos históricos siguen visibles.
La reactivación se verifica comprobando que el proveedor vuelve a aparecer disponible en
pedidos sin perder su historial.

**Escenarios de Aceptación**:

1. **Dado** que existe un proveedor activo con items y pedidos asociados,
   **Cuando** el admin lo inactiva,
   **Entonces** el proveedor no aparece como opción en la generación de nuevos pedidos y
   el historial de pedidos previos permanece accesible para el admin.

2. **Dado** que un proveedor está inactivo,
   **Cuando** el sistema intenta incluirlo en la generación automática de pedidos,
   **Entonces** el proveedor es excluido del proceso y no se genera ningún pedido para él.

3. **Dado** que un proveedor inactivo tiene items asignados,
   **Cuando** el admin consulta esos items,
   **Entonces** los items muestran el proveedor como referencia histórica pero con indicación
   de que está inactivo.

4. **Dado** que un proveedor está inactivo con historial de pedidos previos,
   **Cuando** el admin lo reactiva,
   **Entonces** el proveedor vuelve a aparecer como opción en la generación de nuevos pedidos
   y su historial de pedidos previos permanece intacto.

---

### Historia de Usuario 4 — Consultar el catálogo de proveedores (Prioridad: P1)

El administrador revisa el listado completo de proveedores (activos e inactivos) para tener
visibilidad del estado de cada uno y verificar sus datos de contacto antes de generar pedidos.

**Por qué esta prioridad**: El listado de proveedores es la pantalla de entrada a la gestión
y la referencia que el admin consulta antes de generar o revisar pedidos.

**Prueba Independiente**: Puede verificarse con múltiples proveedores en distintos estados y
comprobando que el listado los muestra todos con su información de contacto y estado.

**Escenarios de Aceptación**:

1. **Dado** que existen proveedores activos e inactivos,
   **Cuando** el admin accede al listado de proveedores,
   **Entonces** ve todos los proveedores con razón social, NIT, contacto y estado
   (activo/inactivo).

2. **Dado** que el admin está en el listado,
   **Cuando** selecciona un proveedor,
   **Entonces** puede ver y editar todos sus datos, así como la lista de items que lo tienen
   asignado como proveedor habitual.

3. **Dado** que el admin está en el listado,
   **Cuando** escribe parte de una razón social o NIT en el campo de búsqueda, o aplica el
   filtro por estado,
   **Entonces** el listado muestra solo los proveedores que coinciden con el criterio aplicado.

4. **Dado** que no existe ningún proveedor registrado,
   **Cuando** el admin accede al listado de proveedores,
   **Entonces** el sistema muestra el mensaje "No hay proveedores registrados" y un botón
   para crear el primero.

---

## Requisitos Funcionales

### RF-PROV-01: Registro de proveedores

- RF-PROV-01.1: Solo el administrador puede crear, editar e inactivar proveedores. Cualquier
  otro rol recibe acceso denegado.
- RF-PROV-01.2: Un proveedor requiere como mínimo: razón social y NIT. Los campos de
  contacto (nombre, teléfono, email) son opcionales al crear pero recomendados para la
  gestión de pedidos.
- RF-PROV-01.3: El NIT es único en todo el sistema. El sistema rechaza registros con NIT
  duplicado tanto al crear como al editar. No se impone ningún formato específico: se acepta
  cualquier cadena alfanumérica no vacía (incluyendo códigos internos para proveedores informales).
- RF-PROV-01.4: Un proveedor recién creado queda en estado activo por defecto.
- RF-PROV-01.5: El catálogo de proveedores es compartido entre todas las tiendas de la marca.

### RF-PROV-02: Edición de proveedores

- RF-PROV-02.1: Solo el administrador puede editar los datos de un proveedor.
- RF-PROV-02.2: Se pueden editar: NIT, razón social, nombre de contacto, teléfono de contacto
  y email de contacto.
- RF-PROV-02.3: Al editar el NIT, el sistema verifica que no exista otro proveedor con ese
  NIT antes de guardar el cambio.
- RF-PROV-02.4: La edición no afecta el historial de pedidos asociados al proveedor.

### RF-PROV-03: Inactivación de proveedores

- RF-PROV-03.1: Solo el administrador puede inactivar un proveedor.
- RF-PROV-03.2: Un proveedor inactivo no aparece como opción en la generación de nuevos
  pedidos (manuales ni automáticos). El sistema lo excluye del proceso de planeación de
  demanda.
- RF-PROV-03.3: Los items que tienen asignado un proveedor inactivo conservan esa referencia;
  el sistema indica que el proveedor está inactivo en la ficha del item.
- RF-PROV-03.4: El historial de pedidos de un proveedor inactivo permanece accesible para
  el administrador.
- RF-PROV-03.5: Un proveedor inactivo puede volver a activarse. Al reactivarse, vuelve a
  aparecer como opción en la generación de pedidos sin pérdida del historial previo.
- RF-PROV-03.6: No es posible eliminar un proveedor; solo inactivarlo.

### RF-PROV-04: Listado y consulta

- RF-PROV-04.1: El administrador puede ver el listado de todos los proveedores (activos e
  inactivos) con razón social, NIT, contacto y estado.
- RF-PROV-04.2: Desde el detalle de un proveedor, el admin puede ver qué items del catálogo
  lo tienen como proveedor habitual asignado.
- RF-PROV-04.3: El listado permite filtrar por estado (activo / inactivo / todos) y buscar
  por razón social o NIT mediante texto libre.
- RF-PROV-04.4: Cuando no existe ningún proveedor registrado, el listado muestra el mensaje
  "No hay proveedores registrados" junto con un botón de acceso directo para crear el primero.

---

## Criterios de Éxito

- **Gestión sin errores**: El admin puede registrar, editar e inactivar un proveedor en
  menos de 2 minutos cada operación.
- **Control de acceso**: El 100% de los intentos de gestión de proveedores por parte de
  roles no admin son bloqueados.
- **Integridad del catálogo**: El sistema previene el 100% de los casos de proveedores con
  NIT duplicado al crear o editar.
- **Continuidad operativa**: Al inactivar un proveedor, el 100% de los pedidos históricos
  y la referencia en items se conservan sin pérdida de información.
- **Exclusión de inactivos**: El 100% de los proveedores inactivos son excluidos de la
  generación automática y manual de pedidos.

---

## Entidades Clave

| Entidad | Atributos |
|---------|-----------|
| `Proveedor` | razon_social, nit (único), nombre_contacto, telefono_contacto, email_contacto, activo |

---

## Dependencias y Suposiciones

### Dependencias

- **001-autenticacion**: El admin debe estar autenticado para gestionar proveedores.
- **007-items** (posterior): El proveedor es prerequisito para asignar un proveedor habitual
  a un item. La asignación en el item corresponde a esa feature.
- **012-pedidos** (posterior): Los pedidos referencian al proveedor. Un proveedor inactivo
  no puede tener nuevos pedidos generados.
- Sin dependencias de otras features de la Ola 2 — proveedores no requieren unidades de
  medida ni categorías.

### Suposiciones

- El NIT es el identificador único oficial del proveedor. Si el negocio opera con proveedores
  informales sin NIT, se asume un NIT ficticio o código interno asignado por el admin.
- No se gestionan cuentas por pagar a proveedores en esta versión (explícitamente fuera del
  alcance según la spec funcional §1.3).
- Un proveedor puede estar asignado a múltiples items simultáneamente.
- La razón social no requiere ser única; el NIT es el campo de unicidad.
- No se registra historial de cambios del proveedor; los datos actuales son los únicos
  visibles en la ficha.

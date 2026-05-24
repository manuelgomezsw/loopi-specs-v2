# Especificación de Feature: Items del Catálogo

**Branch de Feature**: `007-items-catalogo`
**Creado**: 2026-05-21
**Estado**: Borrador
**Referencia funcional**: [§3.1 Módulo: Catálogo — Submenú Items](../loopi-v2-funcional/spec.md)

---

## Escenarios de Usuario y Pruebas *(obligatorio)*

### Historia de Usuario 1 — Crear un item (Prioridad: P1)

El administrador registra un nuevo insumo, material de consumo o activo en el catálogo
asignándole un código único, nombre, tipo, subcategoría, proveedor habitual, unidad de medida,
costo unitario, frecuencia de inventario, stock de seguridad y tiempo de entrega del proveedor. Una vez creado, el item queda disponible para inventarios, recetas y
pedidos en todas las tiendas.

**Por qué esta prioridad**: Los items son la entidad central del sistema. Sin items no puede
iniciarse ningún inventario, receta, pedido ni compra. Es el prerequisito operativo de toda
la Ola 3 en adelante.

**Prueba Independiente**: Puede verificarse creando un item y comprobando que aparece
disponible al iniciar un conteo de inventario en cualquier tienda.

**Escenarios de Aceptación**:

1. **Dado** que existen unidades de medida, subcategorías y proveedores activos,
   **Cuando** el admin crea el item "Leche Entera" con código `LEC-001`, tipo `insumo`,
   subcategoría "Lácteos > Líquidos", unidad de medida `ml`, proveedor, costo unitario,
   frecuencia `diario` y stock de seguridad,
   **Entonces** el item queda registrado como activo y aparece en el catálogo compartido de
   todas las tiendas.

2. **Dado** que ya existe un item con el código `LEC-001`,
   **Cuando** el admin intenta crear otro con el mismo código,
   **Entonces** el sistema rechaza la operación indicando que el código ya existe.

3. **Dado** que ya existe un item con el nombre "Leche Entera",
   **Cuando** el admin intenta crear otro con el mismo nombre,
   **Entonces** el sistema rechaza la operación indicando que el nombre ya existe.

4. **Dado** que un lider_tienda o barista intenta acceder a la gestión del catálogo de items,
   **Cuando** navega a esa sección,
   **Entonces** el sistema deniega el acceso; solo el admin puede gestionar este catálogo.

---

### Historia de Usuario 2 — Editar un item (Prioridad: P2)

El administrador actualiza los datos de un item existente cuando cambia el proveedor,
el costo unitario, el stock de seguridad u otros parámetros operativos. Los cambios
aplican de inmediato a todas las tiendas, pero no afectan el historial operativo previo.

**Por qué esta prioridad**: Los parámetros operativos (costo, stock de seguridad, tiempo
de entrega) cambian con frecuencia y deben mantenerse actualizados para que los cálculos
de planeación de demanda sean correctos.

**Prueba Independiente**: Puede verificarse editando el stock de seguridad de un item y
comprobando que los cálculos de pedido automático reflejan el nuevo valor.

**Escenarios de Aceptación**:

1. **Dado** que existe el item "Leche Entera" con stock de seguridad 10 000 ml,
   **Cuando** el admin lo actualiza a 15 000 ml y guarda,
   **Entonces** el nuevo valor aplica en los cálculos de planeación de demanda sin afectar
   el historial de inventarios previo.

2. **Dado** que el admin intenta cambiar el código de un item,
   **Cuando** ingresa el nuevo código y guarda,
   **Entonces** el sistema no permite modificar el código una vez que el item está en uso
   en al menos un inventario, pedido o receta, e informa la razón.

3. **Dado** que el admin cambia la unidad de medida de un item que ya tiene historial de
   stock,
   **Cuando** intenta guardar el cambio,
   **Entonces** el sistema advierte que el cambio de unidad de medida invalida el historial
   de stock y requiere confirmación explícita antes de proceder.

---

### Historia de Usuario 3 — Inactivar y reactivar un item (Prioridad: P2)

El administrador marca un item como inactivo cuando deja de usarse en las tiendas
(por ejemplo, un insumo reemplazado o un activo dado de baja). El item inactivo no aparece
en futuros inventarios pero conserva todo su historial.

**Por qué esta prioridad**: La inactivación preserva la trazabilidad histórica de inventarios,
recetas y pedidos sin borrar datos, en cumplimiento del Principio IV de la constitución.

**Prueba Independiente**: Puede verificarse inactivando un item y comprobando que no aparece
al iniciar un nuevo conteo de inventario, pero su historial previo sigue visible en reportes.

**Escenarios de Aceptación**:

1. **Dado** que existe el item "Leche Entera" con historial de inventarios,
   **Cuando** el admin lo inactiva,
   **Entonces** el item deja de aparecer en los conteos de inventario futuros y su historial
   permanece accesible para el admin en reportes.

2. **Dado** que un item está inactivo,
   **Cuando** el admin lo reactiva,
   **Entonces** el item vuelve a aparecer en los conteos según su frecuencia de inventario,
   conservando todo el historial previo.

3. **Dado** que un item inactivo está incluido en una receta activa,
   **Cuando** el sistema intenta calcular el consumo de esa receta,
   **Entonces** el sistema advierte que uno de los ingredientes está inactivo.

---

### Historia de Usuario 4 — Consultar el catálogo de items (Prioridad: P1)

El administrador revisa el listado completo de items del catálogo con sus parámetros
clave para verificar la configuración antes de iniciar operaciones en las tiendas.

**Por qué esta prioridad**: El catálogo de items es la vista operativa central del admin
y la referencia para auditar que todos los insumos estén correctamente configurados.

**Prueba Independiente**: Puede verificarse con items de distintos tipos y frecuencias
comprobando que el listado los muestra filtrados y con sus parámetros clave.

**Escenarios de Aceptación**:

1. **Dado** que existen items activos e inactivos de distintos tipos,
   **Cuando** el admin consulta el catálogo de items,
   **Entonces** ve todos los items con código, nombre, tipo, frecuencia y estado
   (activo/inactivo), con opción de filtrar por tipo, frecuencia o estado.

2. **Dado** que el admin selecciona un item del listado,
   **Cuando** accede a su detalle,
   **Entonces** puede ver todos sus atributos incluyendo costo unitario, stock de
   seguridad, tiempo de entrega y frecuencia de inventario.

---

## Requisitos Funcionales

### RF-ITEM-01: Creación de items

- RF-ITEM-01.1: Solo el administrador puede crear items. Cualquier otro rol recibe
  acceso denegado.
- RF-ITEM-01.2: Un item requiere obligatoriamente: código, nombre, tipo, subcategoría,
  unidad de medida, frecuencia de inventario y stock de seguridad. El `stock_seguridad`
  es obligatorio para todos los tipos de item incluyendo `activo`; para activos donde
  no aplique operativamente, el admin ingresa `0`.
- RF-ITEM-01.3: Los campos opcionales al crear son: proveedor, costo unitario por defecto
  (global) y tiempo de entrega en días.
- RF-ITEM-01.4: El código del item es único en todo el sistema y es asignado manualmente
  por el admin (ej: `CAF-001`, `LEC-002`).
- RF-ITEM-01.5: El nombre del item es único en todo el sistema.
- RF-ITEM-01.6: Los tipos de item válidos son: `insumo`, `material_consumo`, `activo`.
- RF-ITEM-01.7: El `costo_unitario` del item es un valor por defecto global expresado en
  pesos colombianos (COP) sin decimales. Cada tienda puede sobreescribir este valor con
  su propio costo; dicha sobreescritura se gestiona en la entidad `ItemCostoTienda`.
- RF-ITEM-01.8: Un item recién creado queda en estado activo por defecto.
- RF-ITEM-01.9: El catálogo de items es compartido entre todas las tiendas de la marca.

### RF-ITEM-02: Edición de items

- RF-ITEM-02.1: Solo el administrador puede editar un item.
- RF-ITEM-02.2: Se pueden editar en cualquier momento: nombre, proveedor, costo unitario,
  stock de seguridad, tiempo de entrega y frecuencia de inventario.
- RF-ITEM-02.3: El código del item puede editarse libremente mientras el item no tenga
  ningún registro en inventarios, pedidos ni recetas. Una vez que existe al menos un uso
  en cualquiera de estos módulos, el código queda bloqueado y no puede modificarse.
- RF-ITEM-02.4: Cambiar la unidad de medida de un item con historial de stock requiere
  confirmación explícita del admin, quien asume la responsabilidad por la inconsistencia
  histórica resultante.
- RF-ITEM-02.5: La subcategoría puede cambiarse libremente; el item hereda la nueva
  categoría implícitamente. Las subcategorías son independientes del tipo de item:
  cualquier item (`insumo`, `material_consumo` o `activo`) puede asignarse a cualquier
  subcategoría sin restricción de tipo.
- RF-ITEM-02.6: La edición no afecta el historial de inventarios, pedidos ni recetas previos.

### RF-ITEM-03: Inactivación y reactivación

- RF-ITEM-03.1: Solo el administrador puede inactivar o reactivar un item.
- RF-ITEM-03.2: Un item inactivo no aparece en los conteos de inventario futuros ni como
  ingrediente seleccionable en nuevas recetas ni líneas de pedido. El sistema lo excluye
  automáticamente.
- RF-ITEM-03.3: El historial de un item inactivo (inventarios, recetas, pedidos, costos)
  permanece accesible para el administrador.
- RF-ITEM-03.4: Un item inactivo puede reactivarse sin restricciones. Al reactivarse,
  vuelve a los conteos según su frecuencia de inventario.
- RF-ITEM-03.5: No es posible eliminar un item; solo inactivarlo.
- RF-ITEM-03.6: Si un item inactivo es ingrediente de una receta activa, el sistema
  indica la advertencia en la ficha de la receta.

### RF-ITEM-04: Frecuencia de inventario

- RF-ITEM-04.1: La frecuencia determina en qué conteos aparece el item:
  - `diario`: aparece en todos los conteos (diario, semanal y mensual).
  - `semanal`: aparece solo en conteos semanales y mensuales.
  - `mensual`: aparece solo en conteos mensuales.
- RF-ITEM-04.2: Cambiar la frecuencia de inventario aplica a partir del siguiente conteo;
  el historial previo no se altera.

### RF-ITEM-05: Listado y consulta

- RF-ITEM-05.1: El administrador puede consultar el catálogo completo de items con
  código, nombre, tipo, frecuencia y estado.
- RF-ITEM-05.2: El listado permite filtrar por tipo, frecuencia y estado (activo/inactivo).
- RF-ITEM-05.3: Desde el detalle de un item, el admin accede a todos sus atributos
  incluyendo los parámetros de stock y el historial de costos por tienda. El historial
  de costos muestra, para cada tienda, los valores de `costo_unitario` registrados en
  `ItemCostoTienda` con su fecha de vigencia; si una tienda no ha sobreescrito el costo,
  se muestra el valor por defecto global (`Item.costo_unitario`).

---

## Criterios de Éxito

- **Configuración rápida**: El admin puede registrar el conjunto inicial de items del
  catálogo a un ritmo de al menos 20 items en 30 minutos.
- **Control de acceso**: El 100% de los intentos de gestión del catálogo de items por
  parte de roles no admin son bloqueados.
- **Integridad del catálogo**: El sistema previene el 100% de los casos de items con
  código o nombre duplicado al crear o editar.
- **Trazabilidad**: Al inactivar un item, el 100% de su historial operativo previo
  (inventarios, pedidos, costos) permanece accesible para el admin.
- **Consistencia referencial**: El 100% de los items activos tienen siempre una
  subcategoría y una unidad de medida asignadas; no puede existir un item activo sin
  estas referencias.

---

## Entidades Clave

| Entidad | Atributos |
|---------|-----------|
| `Item` | codigo (único), nombre (único), tipo, subcategoria_id, proveedor_id, unidad_medida_id, costo_unitario (por defecto global, COP sin decimales), frecuencia_inventario, stock_seguridad, tiempo_entrega_dias, activo |
| `ItemCostoTienda` | item_id (FK), tienda_id (FK), costo_unitario (COP sin decimales), fecha_vigencia; clave compuesta (item_id, tienda_id, fecha_vigencia) |

---

## Fuera de Alcance

- **Importación masiva (CSV/Excel)**: la carga del catálogo inicial se realiza manualmente
  (item por item). La importación masiva queda diferida para una iteración futura.

---

## Dependencias y Suposiciones

### Dependencias

- **001-autenticacion**: El admin debe estar autenticado para gestionar el catálogo.
- **004-unidades-medida**: Cada item requiere una unidad de medida activa.
- **005-categorias-catalogo**: Cada item requiere una subcategoría activa (que a su vez
  pertenece a una categoría).
- **006-proveedores-catalogo**: El proveedor habitual es opcional al crear el item, pero
  es necesario para la generación de pedidos automáticos.
- **009-inventario** (posterior): Los items con frecuencia configurada aparecen en los
  conteos. La lógica de conteo corresponde a esa feature.
- **008-menu-recetas** (posterior): Los items son ingredientes de las recetas. La gestión
  de recetas corresponde a esa feature.
- **012-pedidos** (posterior): El `tiempo_entrega_dias` y el `stock_seguridad` son insumos
  del algoritmo de planeación de demanda.

### Suposiciones

- El código del item es asignado manualmente por el admin siguiendo la convención de
  nomenclatura del negocio (ej: `CAF-001`). El sistema no genera códigos automáticamente.
- El stock de seguridad se expresa en la misma unidad de medida del item.
- Un item puede no tener proveedor asignado (ej: activos no consumibles), pero en ese
  caso no participará en la generación de pedidos automáticos.
- No existe un cuarto nivel de tipo de item en esta versión; los tipos son fijos:
  `insumo`, `material_consumo`, `activo`.
- El `costo_unitario` global del item (`Item.costo_unitario`) es el valor por defecto para
  todas las tiendas que no hayan registrado un costo propio en `ItemCostoTienda`. El costo
  fijado al crear el item no se actualiza retroactivamente en recepciones ni módulos
  posteriores (ver regla global de costo).

## Clarifications

### Session 2026-05-24

- Q: ¿El costo unitario es global o puede variar por tienda? → A: Cada tienda puede tener su propio costo por item; `costo_unitario` es un valor por defecto global que puede sobreescribirse por tienda mediante la entidad `ItemCostoTienda`.
- Q: ¿El código del item puede editarse en un item recién creado sin uso? → A: Sí, el código puede editarse libremente mientras el item no tenga ningún registro en inventarios, pedidos ni recetas; una vez que existe al menos un uso queda bloqueado.
- Q: ¿Se requiere importación masiva (CSV/Excel) para el setup inicial del catálogo? → A: No; la carga es exclusivamente manual (item por item) en esta versión. Importación masiva queda diferida.
- Q: ¿Las subcategorías tienen restricción de tipo de item? → A: No; las subcategorías son independientes del tipo de item. Cualquier tipo puede asignarse a cualquier subcategoría.
- Q: ¿El campo `stock_seguridad` es obligatorio para items de tipo `activo`? → A: Sí, es obligatorio para todos los tipos incluyendo `activo`; el admin ingresa `0` cuando no aplica operativamente.

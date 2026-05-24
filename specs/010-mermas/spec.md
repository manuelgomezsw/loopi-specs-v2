# Especificación de Feature: Mermas

**Branch de Feature**: `010-mermas`
**Creado**: 2026-05-21
**Estado**: Borrador
**Referencia funcional**: [§3.5 Módulo: Mermas](../loopi-v2-funcional/spec.md)

---

## Escenarios de Usuario y Pruebas *(obligatorio)*

### Historia de Usuario 1 — Registrar una merma de inventario (Prioridad: P1)

El líder de tienda o barista detecta una pérdida de insumo (producto vencido, derrame,
robo, etc.) y la registra en el sistema. El stock del item se descuenta de inmediato en
la tienda correspondiente, sin necesidad de esperar el próximo conteo físico.

**Por qué esta prioridad**: El registro de mermas es el mecanismo que mantiene el stock
proyectado alineado con la realidad entre conteos. Sin él, el sistema sobreestima el
stock y los pedidos se generan con datos incorrectos.

**Prueba Independiente**: Puede verificarse registrando una merma de 500 ml de "Leche
Entera" y comprobando que el stock proyectado del item en esa tienda disminuye
exactamente 500 ml de inmediato.

**Escenarios de Aceptación**:

1. **Dado** que el stock proyectado de "Leche Entera" en la tienda es 3 000 ml,
   **Cuando** el líder registra una merma de 500 ml con motivo `vencimiento`,
   **Entonces** el stock proyectado pasa a 2 500 ml de inmediato y la merma queda
   registrada con fecha, responsable y motivo.

2. **Dado** que el líder registra una merma con motivo `otro`,
   **Cuando** omite la descripción opcional,
   **Entonces** el sistema acepta el registro; la descripción es opcional para todos
   los motivos incluyendo `otro`.

3. **Dado** que un barista intenta registrar una merma de un item en una tienda que
   no es la suya,
   **Cuando** envía el registro,
   **Entonces** el sistema rechaza la operación con acceso denegado; lider_tienda y
   barista solo pueden registrar mermas en su propia tienda.

---

### Historia de Usuario 2 — Consultar las mermas de la tienda (Prioridad: P1)

El líder de tienda revisa el listado de mermas registradas en su tienda para hacer
seguimiento a las pérdidas del período y verificar que el stock refleja la realidad.

**Por qué esta prioridad**: La visibilidad del historial permite al líder detectar
patrones (ej. vencimientos frecuentes de un mismo item) y tomar acciones correctivas.

**Prueba Independiente**: Puede verificarse consultando el listado de mermas y
comprobando que cada registro muestra item, cantidad, motivo, fecha y responsable.

**Escenarios de Aceptación**:

1. **Dado** que existen varias mermas registradas en la tienda,
   **Cuando** el líder consulta el listado de mermas,
   **Entonces** ve las mermas ordenadas por fecha descendente con item, cantidad,
   motivo, fecha y responsable.

2. **Dado** que el listado tiene mermas de distintos motivos e items,
   **Cuando** el líder filtra por motivo `vencimiento`,
   **Entonces** el sistema muestra solo las mermas con ese motivo, conservando el
   orden por fecha.

---

### Historia de Usuario 3 — Eliminar una merma registrada (Prioridad: P1)

El administrador detecta que una merma fue registrada por error (cantidad equivocada,
item incorrecto) y la elimina. El stock del item se revierte automáticamente al valor
que tenía antes de registrarse la merma.

**Por qué esta prioridad**: Los errores de registro ocurren y deben poder corregirse.
La eliminación directa mantiene el cálculo del stock simple: solo las mermas existentes
en el sistema descuentan stock.

**Prueba Independiente**: Puede verificarse eliminando una merma y comprobando que el
stock del item vuelve al valor que tenía antes de registrarse la merma.

**Escenarios de Aceptación**:

1. **Dado** que existe una merma de 500 ml de "Leche Entera",
   **Cuando** el admin la elimina,
   **Entonces** el stock proyectado del item se incrementa en 500 ml y la merma
   desaparece del sistema.

2. **Dado** que un líder de tienda intenta eliminar una merma,
   **Cuando** ejecuta la acción,
   **Entonces** el sistema deniega la operación; solo el admin puede eliminar mermas.

---

### Historia de Usuario 4 — Ver reporte consolidado de mermas (Prioridad: P2)

El administrador revisa el reporte de mermas de todas las tiendas para identificar los
items con mayor pérdida, los motivos más frecuentes y el impacto económico estimado del
período.

**Por qué esta prioridad**: El reporte consolidado es la herramienta de control del
admin para detectar problemas operativos (vencimientos, robos) que afectan el costo
de inventario a nivel de red de tiendas.

**Prueba Independiente**: Puede verificarse generando el reporte de un período con
mermas en distintas tiendas y comprobando que el costo_total calculado coincide con
la suma de (cantidad × costo_unitario) por cada merma.

**Escenarios de Aceptación**:

1. **Dado** que existen mermas registradas en varias tiendas durante un período,
   **Cuando** el admin consulta el reporte consolidado filtrado por ese período,
   **Entonces** ve el listado de mermas de todas las tiendas con item, cantidad,
   motivo, tienda, responsable, fecha y costo total estimado por merma.

2. **Dado** que el admin filtra el reporte por item y motivo,
   **Cuando** aplica los filtros,
   **Entonces** el sistema muestra solo las mermas que cumplen ambos criterios, con
   el costo total estimado del subconjunto visible.

---

## Requisitos Funcionales

### RF-MERM-01: Registro de mermas

- RF-MERM-01.1: El lider_tienda y el barista pueden registrar mermas únicamente en su
  propia tienda. El admin puede registrar mermas en cualquier tienda.
- RF-MERM-01.2: Una merma requiere: item activo del catálogo, cantidad mayor que cero
  (en la unidad de medida del item), motivo y fecha. La descripción es opcional.
- RF-MERM-01.3: Los motivos válidos son: `descuadre`, `robo`, `evaporacion`,
  `vencimiento`, `daño`, `otro`.
- RF-MERM-01.4: Al guardar una merma, el sistema descuenta inmediatamente la cantidad
  del stock proyectado del item en la tienda indicada.
- RF-MERM-01.5: Una merma puede registrarse en cualquier momento del día,
  independientemente de si existe un inventario en progreso en la tienda.
- RF-MERM-01.6: El campo `inventario_asociado` es opcional. Si el usuario lo provee,
  la merma queda vinculada a ese inventario para trazabilidad.

### RF-MERM-02: Consulta de mermas por tienda

- RF-MERM-02.1: El lider_tienda y el barista pueden consultar las mermas de su propia
  tienda. El admin puede consultar mermas de cualquier tienda.
- RF-MERM-02.2: El listado de mermas muestra: item, cantidad, unidad de medida, motivo,
  descripción, fecha y responsable.
- RF-MERM-02.3: El listado permite filtrar por motivo, item y fecha.

### RF-MERM-03: Eliminación de mermas

- RF-MERM-03.1: Solo el admin puede eliminar mermas.
- RF-MERM-03.2: Al eliminar una merma, el sistema revierte el descuento de stock: la
  cantidad de la merma se suma de nuevo al stock proyectado del item en la tienda.
- RF-MERM-03.3: La merma eliminada desaparece completamente del sistema.

### RF-MERM-04: Reporte consolidado (admin)

- RF-MERM-04.1: El admin puede consultar el reporte consolidado de mermas de todas las
  tiendas, con filtros por tienda, item, motivo y período (fecha inicio y fecha fin).
- RF-MERM-04.2: El reporte muestra el costo total estimado de cada merma, calculado
  como `cantidad × costo_unitario` del item. Este valor no se almacena; se calcula al
  mostrar el listado.
- RF-MERM-04.3: El costo total estimado se presenta como valor orientativo basado en
  el costo unitario vigente del item al momento de consultar el reporte.

### RF-MERM-05: Impacto en inventario

- RF-MERM-05.1: Las mermas registradas entre dos inventarios se acumulan en el campo
  `mermas_periodo` del cálculo del valor sugerido del siguiente inventario.
- RF-MERM-05.2: Si una merma es eliminada, el sistema revierte su contribución a
  `mermas_periodo`, actualizando el valor sugerido del próximo inventario.

---

## Criterios de Éxito

- **Impacto inmediato en stock**: El 100% de las mermas registradas descuentan el stock
  proyectado en el momento exacto del registro, sin retraso.
- **Trazabilidad completa**: El 100% de las mermas activas quedan registradas con item,
  cantidad, motivo, fecha, tienda y responsable.
- **Reversibilidad correcta**: El 100% de las eliminaciones de mermas revierten el stock
  exactamente en la cantidad que la merma había descontado.
- **Control de acceso**: El 100% de los intentos de eliminación de mermas por roles
  distintos al admin son bloqueados; el 100% de los registros de merma en tiendas ajenas
  por lider_tienda o barista son rechazados.
- **Visibilidad del admin**: El admin puede consultar el reporte consolidado de mermas
  filtrado por cualquier combinación de tienda, item, motivo y período sin restricción.

---

## Entidades Clave

| Entidad | Atributos |
|---------|-----------|
| `Merma` | tienda_id, item_id, cantidad, unidad_medida_id, motivo, descripcion, fecha, registrado_por_id, inventario_asociado_id |

---

## Dependencias y Suposiciones

### Dependencias

- **001-autenticacion**: El responsable debe estar autenticado y el sistema conoce su
  tienda asignada (lider_tienda, barista) o permite selección (admin).
- **002-gestion-tiendas**: La merma pertenece a una tienda activa.
- **004-unidades-medida**: La cantidad se expresa en la unidad de medida del item; si
  el usuario ingresa en otra unidad compatible, el sistema convierte usando los factores
  configurados.
- **007-items-catalogo**: El item afectado debe estar activo en el catálogo y su
  costo_unitario se usa para calcular el costo estimado en el reporte.
- **009-inventario-conteo**: Las mermas del período se acumulan en `mermas_periodo` del
  cálculo del valor sugerido del siguiente inventario.

### Suposiciones

- El costo total estimado (`cantidad × costo_unitario`) no se almacena en la base de
  datos; se calcula en tiempo real al consultar el reporte. Es un valor orientativo
  basado en el costo_unitario vigente del item, no el costo histórico al momento de la
  merma.
- La cantidad de la merma se registra en la unidad de medida del item. Si el usuario
  opera en unidades diferentes, debe conocer la equivalencia o el sistema le ofrece
  conversión automática según las equivalencias de 004-unidades-medida.
- No existe un flujo de aprobación para registrar mermas; cualquier lider_tienda o
  barista puede registrar mermas en su tienda sin autorización previa.
- El campo `inventario_asociado` es puramente informativo y no afecta el cálculo del
  valor sugerido; la asociación se hace automáticamente por el sistema cuando la merma
  se registra mientras hay un inventario en progreso en esa tienda.

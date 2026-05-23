# Especificación de Feature: Pedidos y Recepción de Mercancía

**Branch de Feature**: `013-pedidos-recepcion-oc`
**Creado**: 2026-05-23
**Estado**: Borrador
**Entrada**: Descripción del usuario: "Pedidos y recepción: creación y ciclo de vida de órdenes de compra a proveedores (borrador → confirmado → enviado → en recepción → completado / parcialmente completado), incluyendo el subflujo de recepción física de mercancía en tienda con registro de cantidades recibidas y actualización de stock."

## Glosario

| Término | Definición |
|---------|-----------|
| **Pedido** | Solicitud de compra multi-proveedor generada para una tienda para una semana. Agrupa todos los items que la tienda necesita reponer, independientemente del proveedor de cada uno. |
| **Despacho** | Subconjunto del pedido que corresponde a un único proveedor. El sistema lo genera al momento del envío. Cada Despacho tiene su propio ciclo de recepción independiente. |
| **Día de toma de pedidos** | Día de la semana configurado globalmente en el sistema (ej. jueves). El sistema genera automáticamente los pedidos de todas las tiendas el día anterior a este día. |
| **Líder de Compras (LC)** | Rol que opera a nivel de marca. Revisa, ajusta, confirma o cancela todos los pedidos de todas las tiendas antes de enviarlos a proveedores. |

## Escenarios de Usuario y Pruebas

### Historia de Usuario 1 - Generación automática de pedidos (Prioridad: P1)

El sistema genera automáticamente los pedidos de todas las tiendas el día anterior al "día de toma de pedidos" configurado, calculando las cantidades necesarias por item con base en el stock actual de cada tienda y la planeación de demanda. Los pedidos quedan en estado Borrador listos para revisión del Líder de Compras.

**Por qué esta prioridad**: Es el punto de entrada de todo el ciclo. Sin este paso automatizado no existe ningún pedido que gestionar.

**Prueba Independiente**: Puede testearse verificando que el día anterior al configurado el sistema crea un pedido en Borrador por cada tienda activa, con líneas de items y cantidades coherentes con el stock y la planeación definida.

**Escenarios de Aceptación**:

1. **Dado** que es el día anterior al "día de toma de pedidos" configurado, **Cuando** el sistema ejecuta la generación automática, **Entonces** crea un pedido en estado Borrador por cada tienda activa de la marca.
2. **Dado** la generación automática, **Cuando** se crea el pedido de una tienda, **Entonces** cada línea incluye el item, el proveedor asociado y la cantidad sugerida por planeación de demanda.
3. **Dado** que ya existe un pedido activo para una tienda en esa semana, **Cuando** el sistema intenta generar uno nuevo, **Entonces** omite esa tienda y registra el evento en el log del sistema.
4. **Dado** un pedido generado automáticamente, **Cuando** el Líder de Tienda o el Líder de Compras lo visualiza, **Entonces** puede distinguir que el origen es "automático" y ver las cantidades sugeridas por planeación.

---

### Historia de Usuario 2 - Revisión y confirmación por Líder de Compras (Prioridad: P1)

El Líder de Compras visualiza todos los pedidos en Borrador de todas las tiendas, puede ajustar cantidades, confirmarlos para proceder al envío, o cancelarlos con justificación obligatoria.

**Por qué esta prioridad**: Sin la aprobación del Líder de Compras el pedido no avanza. Es el filtro de calidad y consolidación antes del envío a proveedores.

**Prueba Independiente**: Puede testearse tomando un pedido en Borrador de cualquier tienda, ajustando una línea, confirmando el pedido y verificando que pasa a Confirmado y queda bloqueado para edición ordinaria.

**Escenarios de Aceptación**:

1. **Dado** que soy Líder de Compras, **Cuando** accedo al módulo de pedidos, **Entonces** veo todos los pedidos en Borrador de todas las tiendas de la marca en una vista consolidada.
2. **Dado** un pedido en Borrador, **Cuando** el Líder de Compras modifica la cantidad de una línea, **Entonces** la cantidad final se actualiza.
3. **Dado** un pedido en Borrador, **Cuando** el Líder de Compras lo confirma, **Entonces** el pedido pasa a estado Confirmado y queda bloqueado para edición.
4. **Dado** un pedido en Borrador, **Cuando** el Líder de Compras lo cancela con un motivo obligatorio, **Entonces** el pedido pasa a Cancelado de forma definitiva y no puede reactivarse.
5. **Dado** un pedido en Borrador cancelado, **Cuando** el Líder de Compras o Admin necesita un nuevo pedido para esa tienda y semana, **Entonces** puede solicitar que el sistema regenere el pedido o crear uno manual excepcional.

---

### Historia de Usuario 3 - Pedido manual excepcional (Prioridad: P3)

El Líder de Compras o Admin crea un pedido de forma manual para cubrir urgencias o items no contemplados en el ciclo automático de la semana.

**Por qué esta prioridad**: El flujo automático cubre el ciclo normal; los pedidos manuales son la excepción y no deben bloquear el flujo principal.

**Prueba Independiente**: Puede testearse creando un pedido manual para una tienda con items de múltiples proveedores y verificando que sigue el mismo ciclo de vida que un pedido automático desde Confirmado.

**Escenarios de Aceptación**:

1. **Dado** que soy Líder de Compras o Admin, **Cuando** creo un pedido manual para una tienda, **Entonces** el pedido se registra con origen "manual" y queda disponible para revisión y envío.
2. **Dado** un pedido manual creado por LC o Admin, **Cuando** el sistema verifica unicidad, **Entonces** permite su creación si no existe otro pedido activo para la misma tienda y semana; en caso contrario informa el conflicto.
3. **Dado** un pedido manual en Borrador, **Cuando** el LC lo confirma, **Entonces** sigue el mismo ciclo de vida que un pedido automático.

---

### Historia de Usuario 4 - Generar despachos y enviar a proveedores (Prioridad: P1)

El Líder de Compras, con el pedido confirmado, genera los despachos individuales por proveedor y los marca como enviados. El sistema divide automáticamente las líneas según el proveedor de cada item.

**Por qué esta prioridad**: Es el paso que transforma el pedido consolidado en órdenes concretas por proveedor y habilita la recepción en tienda.

**Prueba Independiente**: Puede testearse partiendo de un pedido Confirmado con items de dos proveedores, ejecutando el envío y verificando que se generan exactamente dos Despachos —uno por proveedor— cada uno con sus líneas correspondientes.

**Escenarios de Aceptación**:

1. **Dado** un pedido en Confirmado, **Cuando** el Líder de Compras genera el envío, **Entonces** el sistema crea automáticamente un Despacho por cada proveedor presente en las líneas del pedido.
2. **Dado** los Despachos generados, **Cuando** el Líder de Compras confirma el envío a un proveedor específico, **Entonces** ese Despacho pasa a estado Enviado y la tienda puede iniciar su recepción.
3. **Dado** un pedido con N proveedores, **Cuando** todos los Despachos han sido marcados como Enviados, **Entonces** el pedido pasa a estado En Recepción.
4. **Dado** un Despacho marcado como Enviado, **Entonces** queda registrado el proveedor, la tienda destino y la fecha de envío.

---

### Historia de Usuario 5 - Recepcionar despacho en tienda (Prioridad: P1)

El Líder de Tienda o Barista recibe físicamente la mercancía cuando llega el proveedor, registra las cantidades reales recibidas por item y confirma la recepción. El Líder de Tienda, Barista, Líder de Compras o Admin pueden confirmar. El stock de la tienda se actualiza automáticamente al confirmar.

**Por qué esta prioridad**: Es el subflujo de mayor impacto operativo: actualiza el inventario en tiempo real y cierra el ciclo de cada proveedor de forma independiente.

**Prueba Independiente**: Puede testearse partiendo de un Despacho en estado Enviado, iniciando su recepción, ingresando cantidades (exactas y con faltantes), confirmando, y verificando que el stock se actualiza y el Despacho queda en su estado final correcto.

**Escenarios de Aceptación**:

1. **Dado** que soy Líder de Tienda o Barista, **Cuando** accedo al submenú Recepción de mi tienda, **Entonces** veo la lista de Despachos en estado Enviado pendientes de recibir para mi tienda.
2. **Dado** un Despacho en Enviado, **Cuando** inicio la recepción, **Entonces** el Despacho pasa a En Recepción y se despliegan los items con sus cantidades pedidas.
3. **Dado** un Despacho en Recepción, **Cuando** ingreso cantidades recibidas por item, **Entonces** el sistema calcula en tiempo real la diferencia por item (recibida − pedida).
4. **Dado** que todos los items fueron recibidos en la cantidad exacta pedida, **Cuando** se confirma la recepción, **Entonces** el Despacho pasa a Completado y el stock de cada item en la tienda se incrementa con la cantidad recibida.
5. **Dado** que al menos un item fue recibido en una cantidad distinta a la pedida, **Cuando** se confirma la recepción, **Entonces** el Despacho pasa a Parcialmente Completado y el stock se actualiza igualmente con las cantidades reales recibidas.
6. **Dado** un Despacho en Recepción, **Cuando** el Líder de Tienda, Barista, Líder de Compras o Admin confirma la recepción, **Entonces** el sistema registra la confirmación, actualiza el stock y cierra el Despacho en su estado final.

---

### Historia de Usuario 6 - Cierre del pedido con múltiples despachos (Prioridad: P2)

Un pedido se cierra automáticamente cuando todos sus Despachos han sido recibidos. Los Despachos de distintos proveedores se reciben de forma independiente y pueden llegar en diferentes días.

**Por qué esta prioridad**: Modela la realidad operativa: los proveedores llegan en días distintos y el pedido no puede bloquearse esperando a todos.

**Prueba Independiente**: Puede testearse creando un pedido con items de dos proveedores, recibiendo el primer Despacho y verificando que el pedido permanece En Recepción, luego recibiendo el segundo y verificando que el pedido cierra en el estado correcto.

**Escenarios de Aceptación**:

1. **Dado** un pedido con dos Despachos, **Cuando** se completa la recepción del primer Despacho, **Entonces** el pedido permanece en estado En Recepción.
2. **Dado** un pedido donde todos los Despachos son Completados, **Cuando** se confirma el último, **Entonces** el pedido pasa automáticamente a Completado.
3. **Dado** un pedido donde todos los Despachos están confirmados y al menos uno es Parcialmente Completado, **Cuando** se confirma el último, **Entonces** el pedido pasa automáticamente a Parcialmente Completado.
4. **Dado** un pedido con despachos en distintos estados, **Cuando** el Líder de Tienda o LC consulta el pedido, **Entonces** puede ver el estado individual de cada Despacho y cuáles están pendientes.

---

### Casos Borde

- ¿Qué ocurre si el sistema intenta generar un pedido automático para una tienda que ya tiene uno activo esa semana? → Omite esa tienda y lo registra en el log.
- ¿Qué ocurre si un item se recibe en una unidad de medida diferente a la del item? → El sistema convierte usando la tabla de equivalencias antes de actualizar el stock.
- ¿Qué ocurre si se registra cantidad 0 para un item en recepción? → El item queda con diferencia total; el Despacho pasa a Parcialmente Completado.
- ¿Qué ocurre si un pedido cancelado necesita recuperarse? → El LC o Admin pueden solicitar regeneración automática o crear un pedido manual.
- ¿Qué ocurre si el Líder de Compras modifica un pedido Confirmado antes de generar despachos? → Solo LC y Admin pueden modificarlo en ese estado.

## Requisitos

### Requisitos Funcionales

#### Generación Automática de Pedidos

- **RF-001**: El sistema DEBE generar automáticamente un pedido en estado Borrador por cada tienda activa, el día anterior al "día de toma de pedidos" configurado globalmente.
- **RF-002**: El sistema DEBE calcular las cantidades sugeridas por item usando el stock actual de la tienda y el algoritmo de planeación de demanda.
- **RF-003**: El sistema DEBE incluir en cada línea del pedido: item, proveedor del item y cantidad sugerida.
- **RF-004**: El sistema DEBE omitir la generación automática para una tienda si ya existe un pedido activo para esa tienda en la misma semana, registrando el evento en el log del sistema.
- **RF-005**: El sistema DEBE marcar el origen del pedido como "automático" o "manual" para trazabilidad.

#### Revisión y Aprobación por Líder de Compras

- **RF-006**: El sistema DEBE mostrar al `lider_compras` todos los pedidos en Borrador de todas las tiendas en una vista consolidada.
- **RF-007**: El sistema DEBE permitir al `lider_compras` y al `admin` modificar cantidades de cualquier línea de un pedido en Borrador.
- **RF-008**: El sistema DEBE permitir al `lider_compras` confirmar un pedido, transitando de Borrador a Confirmado.
- **RF-009**: El sistema DEBE bloquear la edición de un pedido Confirmado para todos los roles excepto `lider_compras` y `admin`.
- **RF-010**: El sistema DEBE permitir al `lider_compras` cancelar un pedido en Borrador, requiriendo un motivo obligatorio y transitando a Cancelado de forma definitiva.

#### Pedidos Manuales Excepcionales

- **RF-011**: El sistema DEBE permitir al `lider_compras` y al `admin` crear pedidos manuales para cualquier tienda activa.
- **RF-012**: El sistema DEBE permitir al `lider_compras` y al `admin` solicitar la regeneración automática del pedido de una tienda para la semana actual, siempre que no exista uno activo.
- **RF-013**: El sistema DEBE validar unicidad al crear un pedido manual: un único pedido activo por tienda por semana ISO.

#### Generación de Despachos y Envío a Proveedores

- **RF-014**: El sistema DEBE generar automáticamente un Despacho por cada proveedor presente en las líneas de un pedido Confirmado al iniciar el proceso de envío.
- **RF-015**: El sistema DEBE permitir al `lider_compras` confirmar el envío de cada Despacho de forma independiente.
- **RF-016**: El sistema DEBE registrar en cada Despacho: proveedor, tienda destino, fecha de envío y las líneas de items correspondientes.
- **RF-017**: El sistema DEBE transicionar el pedido a estado En Recepción cuando todos sus Despachos hayan sido marcados como Enviados.

#### Recepción de Despachos en Tienda

- **RF-018**: El sistema DEBE mostrar al `lider_tienda`, `barista`, `lider_compras` y `admin` la lista de Despachos en estado Enviado para la tienda correspondiente.
- **RF-019**: El sistema DEBE permitir al `lider_tienda`, `barista`, `lider_compras` y `admin` iniciar la recepción de un Despacho, cambiando su estado a En Recepción.
- **RF-020**: El sistema DEBE mostrar, por cada item del Despacho, la cantidad pedida como referencia al ingresar cantidades recibidas.
- **RF-021**: El sistema DEBE calcular en tiempo real la diferencia por item (cantidad recibida − cantidad pedida) durante el registro de recepción.
- **RF-022**: El sistema DEBE permitir registrar una unidad de medida de recepción diferente a la del item, convirtiendo automáticamente usando la tabla de equivalencias antes de actualizar el stock.
- **RF-023**: El sistema DEBE permitir al `lider_tienda`, `barista`, `lider_compras` y `admin` confirmar la recepción de un Despacho.
- **RF-024**: El sistema DEBE determinar el estado del Despacho al confirmar: Completado si todos los items se recibieron en la cantidad exacta pedida; Parcialmente Completado si al menos un item se recibió en cantidad diferente.
- **RF-025**: El sistema DEBE actualizar el stock de la tienda sumando la cantidad recibida (en la unidad de medida del item) por cada item al confirmar cada Despacho.

#### Cierre Automático del Pedido

- **RF-026**: El sistema DEBE cerrar automáticamente un pedido cuando todos sus Despachos hayan sido confirmados: Completado si todos son Completados; Parcialmente Completado si al menos uno es Parcialmente Completado.

### Entidades Clave

- **Pedido (cabecera)**: Solicitud de compra semanal de una tienda. Atributos clave: tienda, semana ISO, fecha de generación, estado, origen (automático / manual), notas, motivo de cancelación.
- **Línea de Pedido**: Cada item solicitado. Atributos clave: item, proveedor del item, cantidad sugerida (por planeación), cantidad final.
- **Despacho**: Subconjunto del pedido agrupado por un proveedor específico. Atributos clave: pedido, proveedor, tienda, fecha de envío, estado del despacho.
- **Línea de Recepción**: Registro de lo efectivamente recibido por item dentro de un Despacho. Atributos clave: despacho, item, unidad de medida de recepción, cantidad pedida, cantidad recibida, cantidad convertida a la unidad de medida del item, diferencia calculada.

## Criterios de Éxito

### Resultados Medibles

- **CE-001**: El sistema genera los pedidos automáticos de todas las tiendas activas dentro de los primeros 30 minutos del día de generación, sin intervención manual.
- **CE-002**: El Líder de Compras puede revisar, ajustar y confirmar todos los pedidos de la semana desde una vista consolidada en menos de 20 minutos en total.
- **CE-003**: El stock de todos los items de un Despacho se actualiza de forma inmediata al confirmar su recepción, sin intervención adicional del usuario.
- **CE-004**: Cero pedidos activos duplicados (misma tienda + misma semana) en el sistema.
- **CE-005**: El Líder de Tienda o Barista puede registrar la recepción de un Despacho de hasta 20 items en menos de 10 minutos.

## Supuestos

- El módulo de Planeación de Demanda (§3.9) está operativo y provee las cantidades sugeridas por item y tienda; esta feature consume su output pero no lo define.
- El catálogo de proveedores e items está activo; cada item tiene un proveedor asignado por defecto para determinar la agrupación en Despachos.
- La tabla de equivalencias de unidades de medida está configurada para realizar conversiones durante la recepción (§3.2).
- El rol `lider_compras` es nuevo y se agrega al modelo de roles del sistema con sus permisos propios; el rol `admin` conserva acceso total a todas las operaciones del módulo.
- El Líder de Compras opera a nivel de marca (ve pedidos de todas las tiendas); el Líder de Tienda y el Barista operan solo sobre su tienda asignada.
- Un pedido o Despacho cancelado no puede reactivarse directamente; se regenera o se crea manualmente.
- El "día de toma de pedidos" es un único día semanal configurado a nivel de marca (no por tienda).
- El costo de los items es fijo y se define al crear el item en el catálogo; no se actualiza en ningún estadío del sistema.

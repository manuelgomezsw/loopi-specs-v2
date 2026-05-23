# Especificación de Feature: Pedidos y Recepción de Mercancía

**Branch de Feature**: `013-pedidos-recepcion-oc`
**Creado**: 2026-05-23
**Estado**: Borrador
**Entrada**: Descripción del usuario: "Pedidos y recepción: creación y ciclo de vida de órdenes de compra a proveedores (borrador → confirmado → enviado → en recepción → completado / parcialmente completado), incluyendo el subflujo de recepción física de mercancía en tienda con registro de cantidades recibidas y actualización de stock. Basado en §3.8 de specs/loopi-v2-funcional/spec.md"

## Escenarios de Usuario y Pruebas

### Historia de Usuario 1 - Crear y confirmar pedido (Prioridad: P1)

El administrador crea una orden de compra para un proveedor y una tienda específica, revisa los items y cantidades, y la confirma para que pueda ser enviada al proveedor.

**Por qué esta prioridad**: Es el punto de entrada de todo el ciclo de vida del pedido. Sin esta historia no existe ningún pedido que gestionar.

**Prueba Independiente**: Puede testearse completamente creando un pedido con al menos un item, verificando que queda en estado Borrador, y luego confirmándolo para validar que pasa a estado Confirmado y queda bloqueado para edición ordinaria.

**Escenarios de Aceptación**:

1. **Dado** que soy admin y existen proveedores e items configurados, **Cuando** creo un pedido manual para una tienda y proveedor seleccionados, **Entonces** el pedido se crea en estado Borrador con las líneas de items y cantidades indicadas.
2. **Dado** un pedido en estado Borrador, **Cuando** el admin lo confirma, **Entonces** el pedido pasa a estado Confirmado y no puede ser editado por roles no autorizados.
3. **Dado** un pedido en Borrador sin confirmar después de 3 días hábiles, **Cuando** se cumple el plazo, **Entonces** el sistema genera una alerta al admin sin cancelar el pedido automáticamente.
4. **Dado** que ya existe un pedido activo para la misma tienda, proveedor y semana, **Cuando** intento crear otro pedido con los mismos parámetros, **Entonces** el sistema rechaza la operación e informa el conflicto.
5. **Dado** un pedido en Borrador, **Cuando** el admin lo cancela, **Entonces** el pedido pasa a Cancelado y el sistema registra el motivo obligatorio.

---

### Historia de Usuario 2 - Marcar pedido como enviado al proveedor (Prioridad: P2)

Una vez confirmado el pedido, el admin o el líder de tienda registra que el pedido fue comunicado al proveedor, cambiando su estado a Enviado y habilitando el subflujo de recepción.

**Por qué esta prioridad**: Es el paso que habilita la recepción. Sin este cambio de estado el equipo de tienda no puede iniciar la recepción.

**Prueba Independiente**: Puede testearse tomando un pedido en estado Confirmado y marcándolo como enviado, verificando que el estado cambia y que la opción "Iniciar recepción" queda disponible para líderes y baristas.

**Escenarios de Aceptación**:

1. **Dado** un pedido en estado Confirmado, **Cuando** el admin o líder de tienda lo marca como enviado, **Entonces** el pedido pasa a estado Enviado al Proveedor.
2. **Dado** un pedido en estado Confirmado, **Cuando** el admin lo cancela con motivo, **Entonces** el pedido pasa a Cancelado.
3. **Dado** un pedido en estado Borrador, **Cuando** intento marcarlo como enviado sin confirmarlo previamente, **Entonces** el sistema impide la acción y muestra un mensaje de error.

---

### Historia de Usuario 3 - Recibir mercancía en tienda (Prioridad: P1)

El líder de tienda o barista inicia la recepción de un pedido enviado, registra las cantidades reales recibidas por item, y el líder o admin confirma la recepción. El sistema actualiza el stock automáticamente y determina si el pedido queda Completado o Parcialmente Completado.

**Por qué esta prioridad**: Es el subflujo de mayor valor operativo: impacta directamente el inventario en tiempo real y cierra el ciclo de compra.

**Prueba Independiente**: Puede testearse completamente partiendo de un pedido en Enviado, iniciando recepción, ingresando cantidades (dentro y fuera de tolerancia), confirmando, y verificando que el stock de la tienda se actualiza correctamente y el pedido queda en el estado final esperado.

**Escenarios de Aceptación**:

1. **Dado** que soy líder de tienda o barista y hay pedidos en estado Enviado para mi tienda, **Cuando** accedo al submenú Recepción, **Entonces** veo la lista de pedidos en estado Enviado listos para recibir.
2. **Dado** un pedido en estado Enviado, **Cuando** inicio la recepción, **Entonces** el pedido pasa a En Recepción y se despliegan todos los items con sus cantidades pedidas.
3. **Dado** un pedido en estado En Recepción, **Cuando** ingreso cantidades recibidas, **Entonces** el sistema calcula en tiempo real la diferencia por item (recibida − pedida).
4. **Dado** que todas las diferencias son ≤ 10%, **Cuando** el líder o admin confirma la recepción, **Entonces** el pedido pasa a Completado y el stock de cada item en la tienda se incrementa con la cantidad recibida convertida a unidad canónica.
5. **Dado** que al menos un item tiene diferencia > 10%, **Cuando** el líder o admin confirma la recepción, **Entonces** el pedido pasa a Parcialmente Completado y el stock se actualiza igualmente con las cantidades realmente recibidas.
6. **Dado** que soy barista, **Cuando** intento confirmar la recepción (paso final), **Entonces** el sistema bloquea la acción e indica que se requiere un líder de tienda o admin.
7. **Dado** una recepción confirmada, **Cuando** el sistema actualiza el stock, **Entonces** también registra el costo unitario real de recepción en el historial de costos del item para esa tienda.

---

### Historia de Usuario 4 - Crear pedido desde sugerencia automática (Prioridad: P3)

El admin revisa un pedido sugerido generado por el módulo de Planeación de Demanda, ajusta cantidades si es necesario, y lo confirma como pedido formal.

**Por qué esta prioridad**: Agrega eficiencia operativa pero no es bloqueante; el flujo manual ya cubre la necesidad básica.

**Prueba Independiente**: Puede testearse verificando que un pedido generado automáticamente aparece en Borrador con las cantidades sugeridas, que el admin puede ajustar cantidades y que al confirmar sigue el mismo ciclo que un pedido manual.

**Escenarios de Aceptación**:

1. **Dado** que existe un pedido generado automáticamente, **Cuando** el admin lo visualiza, **Entonces** puede ver las cantidades sugeridas por el algoritmo diferenciadas de las cantidades finales.
2. **Dado** un pedido automático en Borrador, **Cuando** el admin ajusta las cantidades de uno o más items, **Entonces** el sistema actualiza las cantidades finales conservando las sugeridas como referencia.
3. **Dado** un pedido automático ajustado, **Cuando** el admin lo confirma, **Entonces** sigue el mismo ciclo de vida que un pedido manual.

---

### Casos Borde

- ¿Qué ocurre si se intenta crear un segundo pedido activo para la misma tienda, proveedor y semana? → El sistema rechaza la operación (RN-PED-03).
- ¿Qué ocurre si el barista intenta confirmar la recepción? → El sistema bloquea la acción; solo líder o admin pueden confirmar.
- ¿Qué ocurre si un item recibido tiene unidad de medida diferente a la canónica? → El sistema convierte usando la tabla de equivalencias antes de actualizar el stock.
- ¿Qué ocurre si se registra cantidad 0 para un item en recepción? → Se considera faltante total; la diferencia es −100% y el pedido queda Parcialmente Completado.
- ¿Qué ocurre si un pedido en Borrador no se confirma antes del plazo? → El sistema alerta al admin pero el pedido permanece activo hasta acción manual.
- ¿Qué ocurre si se intenta editar un pedido ya Confirmado? → Solo el admin con permiso especial puede modificarlo; los demás roles ven el pedido como solo lectura.

## Requisitos

### Requisitos Funcionales

#### Gestión de Pedidos

- **RF-001**: El sistema DEBE permitir al `admin` crear pedidos de compra manuales para cualquier tienda y proveedor activos.
- **RF-002**: El sistema DEBE permitir al `lider_tienda` crear pedidos de compra manuales para su tienda asignada.
- **RF-003**: El sistema DEBE agrupar pedidos por proveedor: máximo un pedido activo por tienda, proveedor y semana ISO.
- **RF-004**: El sistema DEBE permitir agregar, modificar y eliminar líneas de items en un pedido en estado Borrador.
- **RF-005**: El sistema DEBE calcular automáticamente el costo estimado por línea de pedido (cantidad final × costo de referencia del item).
- **RF-006**: El sistema DEBE permitir al `admin` confirmar un pedido, transitando de Borrador a Confirmado.
- **RF-007**: El sistema DEBE bloquear la edición de un pedido Confirmado para todos los roles, excepto el `admin` con permiso especial de modificación.
- **RF-008**: El sistema DEBE permitir al `admin` y `lider_tienda` marcar un pedido Confirmado como Enviado al Proveedor.
- **RF-009**: El sistema DEBE permitir al `admin` cancelar pedidos en estado Borrador o Confirmado, exigiendo un motivo de cancelación.
- **RF-010**: El sistema DEBE generar una alerta al `admin` cuando un pedido en Borrador supere el plazo configurable sin ser confirmado (por defecto: 3 días hábiles).
- **RF-011**: El sistema DEBE permitir al `admin` combinar o dividir pedidos mientras estén en estado Borrador.

#### Subflujo de Recepción

- **RF-012**: El sistema DEBE mostrar al `lider_tienda`, `barista` y `admin` la lista de pedidos en estado Enviado disponibles para recepción, filtrada por tienda.
- **RF-013**: El sistema DEBE permitir al `lider_tienda`, `barista` y `admin` iniciar la recepción de un pedido Enviado, cambiando su estado a En Recepción.
- **RF-014**: El sistema DEBE mostrar, por cada item del pedido, la cantidad pedida como referencia al ingresar cantidades recibidas.
- **RF-015**: El sistema DEBE calcular en tiempo real la diferencia por item (cantidad recibida − cantidad pedida) durante el registro de recepción.
- **RF-016**: El sistema DEBE permitir registrar una unidad de medida de recepción diferente a la unidad canónica del item, convirtiendo automáticamente usando la tabla de equivalencias.
- **RF-017**: El sistema DEBE requerir el registro del costo unitario real de recepción por cada línea de item.
- **RF-018**: El sistema DEBE permitir solo al `lider_tienda` y al `admin` confirmar la recepción de un pedido en estado En Recepción.
- **RF-019**: El sistema DEBE determinar el estado final del pedido al confirmar recepción: Completado si todas las diferencias son ≤ 10%; Parcialmente Completado si al menos una diferencia supera el 10%.
- **RF-020**: El sistema DEBE actualizar el stock de la tienda sumando la cantidad recibida en unidad canónica por cada item al confirmar la recepción.
- **RF-021**: El sistema DEBE registrar el costo unitario real de cada item en el historial de costos de la tienda al confirmar la recepción.

### Entidades Clave

- **Pedido (cabecera)**: Orden de compra asociada a una tienda y un proveedor. Atributos clave: tienda, proveedor, fecha de pedido, fecha de entrega esperada, estado, origen (manual/automático), semana ISO, notas, motivo de cancelación.
- **Línea de Pedido**: Cada item solicitado dentro de un pedido. Atributos clave: item, cantidad sugerida (si viene de planeación), cantidad final, costo estimado.
- **Línea de Recepción**: Registro de lo efectivamente recibido por item. Atributos clave: item, unidad de medida de recepción, cantidad pedida, cantidad recibida, cantidad recibida en unidad canónica, costo unitario real, diferencia calculada.

## Criterios de Éxito

### Resultados Medibles

- **CE-001**: El administrador puede crear, revisar y confirmar un pedido completo en menos de 5 minutos.
- **CE-002**: El líder de tienda o barista puede completar el registro de recepción de un pedido de hasta 20 items en menos de 10 minutos.
- **CE-003**: El stock de todos los items de un pedido se actualiza inmediatamente al confirmar la recepción, sin intervención adicional del usuario.
- **CE-004**: El 100% de las recepciones confirmadas genera un registro de historial de costos por item en la tienda correspondiente.
- **CE-005**: Los pedidos en Borrador vencidos son notificados al admin dentro de las primeras 24 horas posteriores al vencimiento del plazo.
- **CE-006**: Cero pedidos activos duplicados (misma tienda + proveedor + semana) en el sistema.

## Supuestos

- El catálogo de proveedores e items ya existe y está activo (gestionado en módulos anteriores §3.3 y §3.6).
- La tabla de equivalencias de unidades de medida está configurada correctamente para realizar conversiones durante la recepción (§3.2).
- El módulo de Planeación de Demanda (§3.9) puede operar de forma independiente; esta feature no depende de él para el flujo manual.
- La tolerancia de diferencia para determinar pedido Completado vs. Parcialmente Completado es fija en 10% (configurable a nivel de sistema, no por item).
- El plazo de alerta para pedidos en Borrador es configurable a nivel de sistema (por defecto: 3 días hábiles).
- Un pedido cancelado no puede reactivarse; se debe crear uno nuevo si es necesario.
- La unidad canónica de cada item está definida en el catálogo y es la base para todas las actualizaciones de stock.
- El historial de costos es independiente por tienda; el costo de recepción de una tienda no afecta el de otra.
- El barista solo puede operar sobre la tienda a la que está asignado.

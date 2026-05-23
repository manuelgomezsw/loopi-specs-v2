# Especificación de Feature: Planeación de Demanda — Motor de Cálculo Automático

**Branch de Feature**: `014-demanda-motor-calculo`
**Creado**: 2026-05-23
**Estado**: Borrador
**Referencia**: §3.9 de specs/loopi-v2-funcional/spec.md

## Escenarios de Usuario y Pruebas *(obligatorio)*

### Historia de Usuario 1 - Generación Automática del Pedido Sugerido (Prioridad: P1)

El admin ejecuta la planeación de demanda para una tienda y el sistema calcula automáticamente qué items pedir y en qué cantidad, basándose en el stock actual, las ventas históricas de esa tienda, el tiempo de entrega y el stock de seguridad de cada item.

**Por qué esta prioridad**: Es el núcleo del módulo. Sin este cálculo automático el operador sigue pidiendo a ojo, que es el problema principal que Loopi v2 resuelve.

**Prueba Independiente**: Puede testearse completamente creando items con parámetros conocidos, registrando ventas históricas y verificando que el pedido sugerido generado coincide con el resultado esperado de la fórmula.

**Escenarios de Aceptación**:

1. **Dado** un item con `inventario_actual = 5`, `promedio_venta_diaria = 3`, `tiempo_entrega = 2 días`, `stock_seguridad = 4` y sin pico de demanda activo, **cuando** el admin genera el pedido sugerido, **entonces** el sistema calcula `cantidad_a_pedir = (3 × 2) + 4 = 10` e incluye el item en el pedido.
2. **Dado** un item con `inventario_actual = 10` y `promedio_venta_diaria × tiempo_entrega = 6`, **cuando** el admin genera el pedido sugerido, **entonces** el sistema detecta que el stock cubre el tiempo de entrega y excluye el item del pedido (`cantidad_a_pedir = 0`).
3. **Dado** un item sin historial de ventas suficiente (menos de 7 días de datos en la tienda), **cuando** el sistema calcula el pedido, **entonces** usa el `stock_seguridad` del item como `cantidad_a_pedir`.
4. **Dado** un item sin proveedor asignado o inactivo, **cuando** el sistema calcula el pedido, **entonces** excluye ese item del pedido sugerido.

---

### Historia de Usuario 2 - Revisión y Ajuste del Pedido Sugerido (Prioridad: P1)

Antes de confirmar el pedido automático, el admin puede revisar cada item sugerido, ver por qué fue incluido y ajustar manualmente la cantidad si considera que el cálculo no refleja la realidad operativa.

**Por qué esta prioridad**: El admin siempre tiene la última palabra; el sistema debe asistir, no imponer. Esto también cubre eventos no capturables por el algoritmo (proveedores sin stock, decisiones tácticas).

**Prueba Independiente**: Puede testearse generando un pedido sugerido, modificando la cantidad de un item manualmente y confirmando que el pedido final registra la cantidad modificada, no la calculada.

**Escenarios de Aceptación**:

1. **Dado** un pedido sugerido generado, **cuando** el admin modifica la cantidad de un item de 10 a 15, **entonces** el pedido final registra 15 unidades para ese item y conserva las cantidades calculadas para el resto.
2. **Dado** un pedido sugerido, **cuando** el admin elimina un item de la lista, **entonces** ese item no aparece en el pedido confirmado.
3. **Dado** un pedido sugerido, **cuando** el admin agrega manualmente un item que el algoritmo excluyó, **entonces** el pedido final lo incluye con la cantidad ingresada por el admin.

---

### Historia de Usuario 3 - Configuración de Picos de Demanda (Prioridad: P2)

El admin registra semanas especiales (festivales, temporadas altas) en las que la demanda se incrementará, para que el motor de cálculo ajuste automáticamente las cantidades pedidas durante esas semanas.

**Por qué esta prioridad**: Sin esta configuración, los pedidos automáticos en semanas pico serán insuficientes. Es crítico para la operación pero puede postponerse a una segunda iteración si la funcionalidad base funciona primero.

**Prueba Independiente**: Puede testearse registrando un pico de demanda para la semana actual y verificando que el pedido sugerido generado incluye la cantidad adicional correspondiente.

**Escenarios de Aceptación**:

1. **Dado** que el admin registra un pico de demanda de tipo `cantidad_adicional` con valor `20` para el item "Café Especial" en la semana 2026-W22 aplicable a todas las tiendas, **cuando** se genera el pedido sugerido durante esa semana, **entonces** el sistema suma 20 unidades al resultado del cálculo base para ese item en cada tienda.
2. **Dado** que el admin registra un pico de tipo `multiplicador` con valor `1.5` para un item en una semana específica de una tienda, **cuando** se genera el pedido, **entonces** el `promedio_venta_diaria` se multiplica por 1.5 antes de aplicar la fórmula.
3. **Dado** que un pico de demanda fue registrado con menos de 48 horas antes de la generación del pedido, **cuando** el sistema genera el pedido, **entonces** ignora ese pico y notifica al admin que el plazo mínimo no fue respetado.
4. **Dado** un pico de demanda ya vencido (semana pasada), **cuando** el admin consulta la lista de picos, **entonces** el pico aparece como inactivo y no influye en cálculos futuros.

---

### Historia de Usuario 4 - Configuración de Parámetros Globales del Algoritmo (Prioridad: P2)

El admin puede ajustar los parámetros globales que controlan el comportamiento del motor de cálculo: ventana de días de historial, día de generación del pedido y tolerancia de diferencia en recepción.

**Por qué esta prioridad**: Estos parámetros tienen valores por defecto razonables, pero deben ser ajustables para acomodar la operación específica de cada negocio.

**Prueba Independiente**: Puede testearse cambiando la ventana de historial de 14 a 7 días y verificando que el nuevo cálculo usa solo los últimos 7 días de ventas.

**Escenarios de Aceptación**:

1. **Dado** que el admin cambia la `ventana_historico_dias` de 14 a 30, **cuando** se genera el siguiente pedido sugerido, **entonces** el `promedio_venta_diaria` se calcula con los últimos 30 días de ventas en lugar de 14.
2. **Dado** que el admin cambia el `dia_generacion_pedido` de lunes a miércoles, **cuando** llega el próximo miércoles, **entonces** el sistema genera el pedido automático ese día y envía la notificación al admin.
3. **Dado** que los parámetros globales están configurados, **cuando** el admin los consulta, **entonces** ve los valores actuales y la fecha de la última modificación.

---

### Casos Borde

- ¿Qué ocurre cuando el último inventario de una tienda tiene más de 7 días de antigüedad? ¿El stock_actual sigue siendo válido para el cálculo?
- ¿Qué ocurre cuando dos picos de demanda se solapan para el mismo item y semana (uno específico de tienda y uno para "todas las tiendas")? ¿Se suman, se usa el mayor o hay un orden de precedencia?
- ¿Qué sucede si el `promedio_venta_diaria` resulta en cero porque no hubo ventas en la ventana histórica (item nuevo o tienda sin actividad)?
- ¿Cómo se comporta el sistema si el pedido automático del lunes no se confirmó y llega el siguiente lunes?
- ¿Qué ocurre si un item tiene registrado `tiempo_entrega = 0`?

## Requisitos *(obligatorio)*

### Requisitos Funcionales

- **RF-001**: El sistema DEBE calcular automáticamente la cantidad a pedir por cada item activo con proveedor asignado, por tienda, aplicando la fórmula: si `inventario_actual > promedio_venta_diaria × tiempo_entrega` entonces `cantidad_a_pedir = 0`, de lo contrario `cantidad_a_pedir = (promedio_venta_diaria × tiempo_entrega) + stock_seguridad + pico_demanda`.
- **RF-002**: El sistema DEBE calcular el `promedio_venta_diaria` usando las ventas registradas del POS de la tienda dentro de la ventana histórica configurable (por defecto: últimos 14 días).
- **RF-003**: El sistema DEBE usar el `stock_seguridad` del item como `cantidad_a_pedir` cuando el item tiene menos de 7 días de historial de ventas en la tienda.
- **RF-004**: El sistema DEBE excluir del pedido sugerido los items sin proveedor asignado o con proveedor inactivo.
- **RF-005**: El sistema DEBE permitir al admin revisar y modificar las cantidades del pedido sugerido antes de confirmarlo.
- **RF-006**: El sistema DEBE permitir al admin agregar items que el algoritmo excluyó, y eliminar items que el algoritmo incluyó.
- **RF-007**: El sistema DEBE registrar si cada línea del pedido fue generada automáticamente o modificada/agregada manualmente.
- **RF-008**: El sistema DEBE permitir registrar picos de demanda por semana ISO, indicando: tienda afectada (o todas), item, tipo (`multiplicador` o `cantidad_adicional`) y valor.
- **RF-009**: El sistema DEBE ignorar un pico de demanda registrado con menos de 48 horas de anticipación a la generación del pedido y notificar al admin.
- **RF-010**: El sistema DEBE permitir configurar los parámetros globales del algoritmo: `ventana_historico_dias` (por defecto: 14), `dia_generacion_pedido` (por defecto: lunes) y `tolerancia_diferencia_pct` (por defecto: 10%).
- **RF-011**: El sistema DEBE generar automáticamente el pedido sugerido en el día configurado y notificar al admin para que lo revise y confirme.
- **RF-012**: Cuando se aplican dos picos de demanda para el mismo item y semana (uno para tienda específica y otro para "todas las tiendas"), el sistema DEBE aplicar el de mayor valor; no sumarlos.
- **RF-013**: El sistema DEBE mostrar al admin, por cada item en el pedido sugerido, los valores intermedios del cálculo: inventario actual, promedio venta diaria, tiempo de entrega, stock de seguridad y pico de demanda aplicado.

### Entidades Clave *(incluir si la feature involucra datos)*

- **PedidoSugerido**: Agrupación calculada por tienda y fecha de generación. Contiene las líneas de items sugeridos antes de que el admin confirme el pedido formal.
- **LineaPedidoSugerido**: Ítem + cantidad calculada + cantidades intermedias del cálculo + indicador `modificado_manualmente`.
- **PicoDemanda**: Configuración de demanda excepcional por semana ISO, item y tienda. Campos: `tienda` (o `todas`), `semana`, `item`, `tipo` (`multiplicador` | `cantidad_adicional`), `valor`.
- **ParametrosAlgoritmo**: Configuración global del motor. Campos: `ventana_historico_dias`, `dia_generacion_pedido`, `tolerancia_diferencia_pct`. Singleton por sistema.
- **Item** *(existente)*: Aporta `tiempo_entrega_dias` y `stock_seguridad` al cálculo.
- **MovimientoInventario / VentaPOS** *(existente)*: Fuente del historial de ventas por tienda usado para calcular el `promedio_venta_diaria`.

## Criterios de Éxito *(obligatorio)*

### Resultados Medibles

- **CE-001**: El admin puede generar un pedido sugerido completo para una tienda en menos de 30 segundos desde que lo solicita.
- **CE-002**: El 100% de los items activos con proveedor asignado son evaluados en cada ejecución del motor de cálculo; ningún item elegible queda fuera del análisis.
- **CE-003**: Los pedidos automáticos generados con el algoritmo reducen los quiebres de stock de una tienda en al menos un 70% comparado con el método manual, medido en el primer mes de uso.
- **CE-004**: El admin puede configurar y verificar un pico de demanda en menos de 2 minutos.
- **CE-005**: El 100% de los pedidos sugeridos reflejan fielmente la fórmula definida; no hay discrepancias entre el cálculo esperado y el resultado mostrado.
- **CE-006**: El admin recibe la notificación del pedido sugerido en el día configurado sin necesidad de acción manual para disparar el proceso.

## Supuestos

- El inventario utilizado como `inventario_actual` es el del último conteo completado de la tienda. Si no existe ningún conteo previo, el item se trata como sin historial suficiente y se usa el `stock_seguridad`.
- El historial de ventas proviene exclusivamente de las ventas procesadas por el POS de la tienda (integración §3.8); no se contemplan ventas ingresadas manualmente.
- Los parámetros de `tiempo_entrega_dias` y `stock_seguridad` son atributos existentes del item, configurados en el catálogo (§3.5). Su gestión no es parte de esta feature.
- La estacionalidad por día de semana (DP-01 de la spec funcional) está fuera del alcance de esta feature; el algoritmo usa el promedio simple de N días.
- Un `PedidoSugerido` no confirmado es descartado automáticamente cuando se genera el siguiente ciclo; el admin no puede tener dos pedidos sugeridos pendientes simultáneamente para la misma tienda.
- Cuando un pico de demanda aplica a "todas las tiendas" y también existe uno específico para una tienda, se aplica el de mayor valor (no se acumulan).
- El módulo genera pedidos sugeridos; la confirmación formal y el flujo hacia el proveedor son responsabilidad del módulo de Pedidos/OC (§3.8).
- Los roles con acceso a esta feature son exclusivamente `admin`. El `lider_tienda` puede ver el pedido confirmado pero no interactúa con el motor de cálculo.

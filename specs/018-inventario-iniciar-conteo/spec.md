# Especificación de Feature: Iniciar Conteo de Inventario Físico

**Branch de Feature**: `feature/018-inventario-iniciar-conteo`

**Creado**: 2026-07-20

**Estado**: Draft

**Estándares Aplicables**:

- Enmienda constitucional: BE-ARCH-02 (arquitectura de sub-dominios dentro de dominio)

---

## Alcance de Feature 018

**QUÉ INCLUYE:**

- Crear nueva sesión de inventario (registro en tabla `inventarios`)
- Determinar automáticamente el tipo de conteo (diario/semanal/mensual/inicial)
- Cargar lista de items a contar según tipo y frecuencia_inventario
- Validar que no exista conteo duplicado para esa tienda/tipo/horario/fecha
- Obtener valor esperado de cada item desde tabla `stock_actual` (lookup simple)

**QUÉ NO INCLUYE (responsabilidad de otras features):**

- ❌ Cálculos complejos de valor esperado (NO es responsabilidad de 018)
- ❌ Bloqueo de movimientos durante conteo (NO es responsabilidad de 018)
- ❌ Registro de valores reales item por item (responsabilidad de 019)
- ❌ Confirmación y ajuste de stock (responsabilidad de 020)
- ❌ Consulta de historial de conteos (responsabilidad de 021)

---

## Escenarios de Usuario y Pruebas *(obligatorio)*

### Historia de Usuario 1 — Iniciar un conteo de inventario (Prioridad: P1)

El líder o barista inicia un conteo físico en su tienda. El sistema sugiere el tipo y horario
según la hora del día (apertura, mediodía o cierre para conteos diarios) y presenta la lista
de items que corresponde contar. El líder puede aceptar la sugerencia o cambiar el tipo de
conteo manualmente.

**Por qué esta prioridad**: El conteo es el flujo operativo más frecuente del sistema y la
base para la trazabilidad de inventario. Sin él no hay stock proyectado confiable.

**Prueba Independiente**: Puede verificarse iniciando un conteo a las 8 a.m. y comprobando
que el sistema sugiere `diario / apertura` y presenta solo los items con frecuencia `diario`.

**Escenarios de Aceptación**:

1. **Dado** que son las 8:00 a.m. y no existe un conteo `diario / apertura` en progreso,
   **Cuando** el líder inicia un inventario,
   **Entonces** el sistema sugiere `diario / apertura` y presenta los items con frecuencia
   `diario` con su valor esperado obtenido directamente de la tabla `stock_actual`.

2. **Dado** que el líder quiere realizar un conteo semanal,
   **Cuando** selecciona manualmente el tipo `semanal`,
   **Entonces** el sistema presenta los items con frecuencia `semanal` sin bloquear el
   cambio de tipo.

3. **Dado** que ya existe un conteo `diario / apertura` en progreso en esa tienda,
   **Cuando** otro usuario de la misma tienda intenta iniciar otro conteo del mismo tipo y
   horario en la misma fecha,
   **Entonces** el sistema bloquea la operación indicando que ya existe un conteo en curso
   en dicha tienda.

4. **Dado** que es el primer conteo de la tienda (sin historial de inventarios completados previo),
   **Cuando** el líder inicia un inventario (seleccionando cualquier tipo: diario/semanal/mensual),
   **Entonces** el sistema detecta automáticamente que no existe historial previo y determina
   que el tipo es `inicial`, presentando todos los items activos con valor esperado en cero
   (por definición del tipo inicial), estableciendo el stock inaugural de la tienda.

5. **Dado** que la tienda tiene items con frecuencia_inventario=diario,
   **Cuando** se inicia conteo diario,
   **Entonces** se retornan todos los items diarios con valor_esperado desde `stock_actual`.

6. **Dado** que NO hay items con frecuencia_inventario=tipo seleccionado,
   **Cuando** se intenta iniciar conteo,
   **Entonces** retorna HTTP 422 `sin_items_contabilizar` con mensaje descriptivo del tipo.

---

## Requisitos Funcionales

### RF-INV-01: Inicio del inventario

- **RF-INV-01.1**: El líder de tienda, barista y admin pueden iniciar conteos. Solo pueden
  iniciar conteos de su propia tienda (lider_tienda y barista); el admin puede iniciar
  conteos en cualquier tienda.

- **RF-INV-01.2**: Al iniciar, el sistema sugiere el tipo y horario según la hora actual:
  - 06:00–10:59 → `diario / apertura`
  - 11:00–14:59 → `diario / mediodía`
  - 15:00–23:59 → `diario / cierre`

- **RF-INV-01.3**: El usuario puede cambiar el tipo manualmente a `diario`, `semanal` o
  `mensual` sin restricción de horario. El tipo `inicial` NO es selectable manualmente;
  el tipo `inicial` es determinado automáticamente por el sistema (ver RF-INV-01.5).

- **RF-INV-01.4**: No se puede crear un nuevo inventario para la misma tienda, tipo, horario y fecha
  si ya existe uno (independientemente de su estado: `en_progreso` o `completado`). El sistema retorna
  **HTTP 409 Conflict** con `error_code=conteo_duplicado`. El mensaje de error debe indicar claramente:
  - Si el duplicado está `en_progreso`: "Ya existe un conteo en progreso... Usa Reanudar para continuar"
  - Si el duplicado está `completado`: "Ya existe un conteo completado para este tipo/horario en esta fecha.
    No se pueden crear conteos duplicados en el mismo día"

- **RF-INV-01.5**: El tipo `inicial` es determinado automáticamente por el sistema cuando realiza
  el primer conteo de una tienda (sin historial de inventarios completados). El usuario NO puede
  seleccionar "inicial" manualmente. El sistema lo determina consultando si existe inventario
  completado previo en la tienda: si existe, el tipo es la categoría elegida por el usuario
  (diario/semanal/mensual); si no existe, el tipo es "inicial" independientemente de lo que
  el usuario haya seleccionado. No requiere inventario de referencia previo.

- **RF-INV-01.6**: Los items presentados en el conteo dependen del tipo:
  - `diario`: todos los items con frecuencia de inventario `diario`.
  - `semanal`: todos los items con frecuencia de inventario `semanal`.
  - `mensual`: todos los items con frecuencia de inventario `mensual`.
  - `inicial`: todos los items activos.

---

## Algoritmo de Determinación Automática de Tipo de Conteo

El tipo de conteo (`diario`, `semanal`, `mensual`, o `inicial`) es determinado **automáticamente por el
sistema** al iniciar un conteo. Este algoritmo es **parte crítica de 018** porque determina qué items se cargarán.

### Lógica de Determinación

```text
1. Consultar: ¿Existe algún inventario CON ESTADO 'completado' en esta tienda?
   Query: SELECT EXISTS(SELECT 1 FROM inventarios 
           WHERE tienda_id = ? AND estado = 'completado' LIMIT 1)

2. Si NO existe (primer conteo):
   tipo_determinado = 'inicial'
   
3. Si SÍ existe (conteo posterior):
   tipo_determinado = tipo_solicitado (diario/semanal/mensual, elegido por usuario)

4. Retornar tipo_determinado
```

### Validaciones (Parte de RF-INV-01)

- **Rechazar selección manual de "inicial"**: Si `tipo_solicitado == 'inicial'`, retornar 400
  con código de error `tipo_inicial_no_permitido` y mensaje: "El tipo 'inicial' no puede ser
  seleccionado manualmente. El sistema lo determina automáticamente en el primer conteo de la tienda."

- **Bloqueo de duplicados**: Usar el `tipo_determinado` (no `tipo_solicitado`) para validar el
  UNIQUE constraint (tienda_id, tipo, horario, fecha). Retornar 409 si ya existe un conteo del
  mismo tipo/horario/fecha en la tienda.

### Impacto en Selección de Items (Parte de RF-INV-01.6)

El `tipo_determinado` determina qué items se cargan y presentan al usuario para contar:

- Si `tipo_determinado == 'inicial'`: **todos los items activos** se presentan con `valor_esperado = 0`.
- Si `tipo_determinado == 'diario'`: **solo items con** `frecuencia_inventario == 'diario'` se presentan.
- Si `tipo_determinado == 'semanal'`: **solo items con** `frecuencia_inventario == 'semanal'` se presentan.
- Si `tipo_determinado == 'mensual'`: **solo items con** `frecuencia_inventario == 'mensual'` se presentan.

**Validación crítica**: Si no hay items con la frecuencia_inventario correspondiente al tipo determinado,
el sistema retorna HTTP 422 con código `sin_items_contabilizar` (escenario 6 de HU1).

---

## Obtención de Valores Esperados (NO es cálculo en 018)

**IMPORTANTE**: En 018 **NO se calculan** valores esperados. Se toman directamente de `stock_actual`:

```sql
SELECT 
  item_id,
  stock_actual.cantidad AS valor_esperado
FROM stock_actual 
WHERE stock_actual.tienda_id = ? AND stock_actual.item_id IN (?, ?, ...)
```

**Excepción**: Para tipo `inicial` (primer conteo), `valor_esperado = 0` por definición (no hay historial previo).

---

## Criterios de Éxito

- **Precisión en carga de items**: El 100% de los items cargados corresponden correctamente a la
  frecuencia_inventario del tipo determinado.
- **Prevención de duplicados**: El sistema bloquea el 100% de los intentos de iniciar
  dos conteos del mismo tipo, horario y fecha dentro de la misma tienda (retorna 409).
- **Determinación automática correcta**: El sistema identifica correctamente si es primer conteo
  (tipo=inicial automático) o conteo posterior (tipo=user choice).
- **Valores esperados correctos**: Cada item tiene su `valor_esperado` correctamente obtenido de `stock_actual`.

---

## Entidades Clave

| Entidad | Atributos |
|---------|-----------|
| `Inventario` | `id`, `tienda_id`, `fecha`, `tipo`, `horario`, `estado` (enum: `en_progreso`, `completado`), `responsable_id`, `iniciado_en`, `completado_en`, `actualizado_en`, `actualizado_por` |
| `DetalleInventario` | `id`, `inventario_id`, `item_id`, `valor_esperado`, `valor_real`, `diferencia` (calculada al confirmar), `registrado_en`, `registrado_por` |

**Nota**: `responsable_id` es una clave foránea que referencia `empleados (id)`. El responsable de un conteo debe ser un empleado autenticado con rol `admin`, `lider_tienda` o `barista`.

---

## Dependencias y Suposiciones

### Dependencias

- **001-autenticacion**: El responsable debe estar autenticado y el sistema conoce su
  tienda asignada (lider_tienda, barista) o permite selección (admin).
- **002-gestion-tiendas**: El inventario pertenece a una tienda activa.
- **007-items-catalogo**: Los items con su frecuencia de inventario determinan qué se
  cuenta en cada tipo de conteo.
- **Tabla `stock_actual`**: Proporciona el valor esperado para cada item (lookup directo).

### Suposiciones

- El valor esperado de cada item se obtiene directamente de la tabla `stock_actual` mediante lookup.
- Para tipo `inicial`, `valor_esperado = 0` por definición (sin necesidad de consultas previas).
- Solo existe un inventario en progreso por tienda, tipo y horario por fecha.
- Un conteo abandonado (en_progreso sin actividad) puede ser retomado (feature 019) o descartado manualmente.

---

## Observabilidad *(obligatorio para endpoints críticos)*

### Trazas (Spans OTel)

| Operación | Nombre del Span | Atributos Obligatorios |
|---|---|---|
| Crear inventario | `inventario.iniciar.crear` | `resultado` (success/validation_error/not_found/conflict), `tienda_id` |
| Obtener sugerencia de tipo y horario | `inventario.iniciar.sugerir_tipo` | `resultado`, `tienda_id`, `tipo_determinado`, `horario` |
| Cargar items por tipo | `inventario.iniciar.cargar_items` | `resultado`, `tienda_id`, `cantidad_items`, `tipo` |
| Determinar tipo automático (inicial) | `inventario.iniciar.determinar_tipo` | `resultado`, `tienda_id`, `tipo_determinado` |

### Métricas

| Nombre | Tipo | Unidad | Descripción | Etiquetas |
|---|---|---|---|---|
| `inventario.iniciar.crear.duration` | Histograma | ms | Latencia de creación de inventario | `resultado`, `tienda_id` |
| `inventario.iniciar.crear.total` | Contador | — | Total de inventarios creados | `resultado`, `tienda_id` |
| `inventario.iniciar.cargar_items.duration` | Histograma | ms | Latencia de carga de items | `resultado`, `tienda_id`, `tipo` |
| `inventario.iniciar.items_cargados.size` | Gauge | items | Cantidad de items cargados por conteo | `tienda_id` |

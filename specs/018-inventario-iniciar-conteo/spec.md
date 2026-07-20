# Especificación de Feature: Iniciar Conteo de Inventario Físico

**Branch de Feature**: `feature/018-inventario-iniciar-conteo`

**Creado**: 2026-07-20

**Estado**: Draft

**Origen**: Migración de HU1 + RF-INV-01 + RF-INV-05 desde `009-inventario-conteo` (separación de 6 features)

**Referencias Relacionadas**:

- Enmienda constitucional: BE-ARCH-02 (sub-dominios dentro de dominio)
- Feature 009: `specs/009-inventario-conteo/spec.md` (fuente de verdad original)
- Plan de separación: `.claude/plans/witty-swinging-tarjan.md` (contexto general)

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
   `diario` con su valor esperado calculado desde el inventario de referencia más reciente.

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
   que el tipo es `inicial`, presentando todos los items activos con valor esperado en cero,
   estableciendo el stock inaugural de la tienda.

5. **Dado** que la tienda tiene items con frecuencia_inventario=diario,
   **Cuando** se inicia conteo diario,
   **Entonces** se retornan todos los items diarios con valor_esperado desde stock_actual sin necesidad de consulta manual.

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

### RF-INV-02 (Parcial — Cálculo de Valor Esperado, aplica a 018)

- **RF-INV-02.2**: El valor esperado de cada item es un **snapshot inmutable** del stock
  tomado en el momento exacto de inicio del conteo, calculado con la siguiente fórmula:

  `valor_esperado = stock_inventario_referencia + compras_periodo − ventas_periodo − mermas_periodo`

  Donde:

  - `stock_inventario_referencia`: valor real contado en el inventario completado más
    reciente de la tienda (de cualquier tipo y horario).
  - `compras_periodo`: unidades recibidas por recepciones de pedido y compras de caja
    menor confirmadas desde ese inventario hasta el **inicio del conteo actual** (momento
    exacto de ejecución de POST /inventarios).
  - `ventas_periodo`: unidades descontadas por ventas procesadas desde ese inventario
    hasta el **inicio del conteo actual**.
  - `mermas_periodo`: unidades registradas como merma desde ese inventario hasta el
    **inicio del conteo actual**.

  Este snapshot se registra en `valor_esperado` y **no cambia** durante toda la
  duración del conteo, ya que no se permiten movimientos (compras, mermas, ventas)
  mientras el conteo está en progreso (ver RF-INV-05).

  Para el inventario de tipo `inicial`, el valor esperado de todos los items es cero,
  ya que no existe inventario de referencia previo.

### RF-INV-05: Bloqueo de Movimientos Durante Conteo Activo

- **RF-INV-05.1**: Mientras existe un inventario con estado `en_progreso` en una tienda,
  **no se permiten** las siguientes operaciones:
  - Registrar compras de caja menor o recepciones de pedido (feature 010).
  - Registrar mermas (feature 010).
  - Procesar archivo de venta en batch (feature 015) — la validación ocurre **antes** de
    permitir el upload del archivo.

- **RF-INV-05.2**: Si se intenta registrar cualquiera de estas operaciones, el sistema retorna
  **HTTP 409 Conflict** con:
  - Código de error: `inventario_activo`
  - Mensaje: "No se pueden registrar movimientos mientras hay un conteo en progreso.
    Contacte al líder de tienda o administrador para completar o cancelar el conteo
    actual."
  - Detalles opcionales: ID del inventario activo, responsable, hora de inicio.

- **RF-INV-05.3**: El propósito de este bloqueo es garantizar que el `valor_esperado` (RF-INV-02.2)
  permanece estable e inmutable durante todo el conteo, eliminando inconsistencias por
  movimientos concurrentes.

- **RF-INV-05.4**: Las **consultas de stock** (lecturas, sin cambios) sí funcionan normalmente
  mientras hay un conteo en progreso.

---

## Algoritmo de Determinación Automática de Tipo de Conteo

El tipo de conteo (`diario`, `semanal`, `mensual`, o `inicial`) es determinado **automáticamente por el
sistema** al iniciar un conteo, según el siguiente algoritmo:

### Entrada

- `tienda_id`: tienda donde se inicia el conteo
- `tipo_solicitado`: tipo elegido por usuario (diario/semanal/mensual, NUNCA inicial)

### Lógica

```text
1. Consultar: ¿Existe algún inventario CON ESTADO 'completado' en esta tienda?
   Query: SELECT EXISTS(SELECT 1 FROM inventarios 
           WHERE tienda_id = ? AND estado = 'completado' LIMIT 1)

2. Si NO existe (primer conteo):
   tipo_determinado = 'inicial'
   
3. Si SÍ existe (conteo posterior):
   tipo_determinado = tipo_solicitado (diario/semanal/mensual)

4. Retornar tipo_determinado
```

### Validaciones

- **Rechazar selección manual de "inicial"**: Si `tipo_solicitado == 'inicial'`, retornar 400
  con código de error `tipo_inicial_no_permitido` y mensaje: "El tipo 'inicial' no puede ser
  seleccionado manualmente. El sistema lo determina automáticamente en el primer conteo de la tienda."

- **Bloqueo de duplicados**: Usar el `tipo_determinado` (no `tipo_solicitado`) para validar el
  UNIQUE constraint (tienda_id, tipo, horario, fecha). Esto evita que usuario intente
  reseleccionar "inicial" si ya existe un conteo inicial anterior.

### Impacto en Selección de Items

El `tipo_determinado` (no `tipo_solicitado`) determina cuáles items se presentan en el conteo:

- Si `tipo_determinado == 'inicial'`: todos los items activos (RF-INV-01.6)
- Si `tipo_determinado == 'diario'`: items con `frecuencia_inventario == 'diario'`
- Si `tipo_determinado == 'semanal'`: items con `frecuencia_inventario == 'semanal'`
- Si `tipo_determinado == 'mensual'`: items con `frecuencia_inventario == 'mensual'`

---

## Criterios de Éxito

- **Velocidad de conteo**: El líder puede completar un conteo diario de hasta 50 items
  en menos de 15 minutos.
- **Exactitud del ajuste**: El 100% de los ajustes de stock al confirmar un inventario
  reflejan exactamente el valor real contado.
- **Continuidad ante interrupciones**: El 100% de los conteos interrumpidos se pueden
  retomar sin pérdida de datos ya ingresados.
- **Trazabilidad**: El 100% de las diferencias de inventario quedan registradas con
  fecha, responsable y detalle por item.
- **Prevención de duplicados**: El sistema bloquea el 100% de los intentos de iniciar
  dos conteos del mismo tipo, horario y fecha dentro de la misma tienda.

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
- **010-mermas** (posterior): Las mermas registradas entre conteos impactan el valor
  esperado del siguiente inventario.
- **008-menu-recetas** + **015-pos** (posterior): Las ventas procesadas entre conteos
  se incorporan al cálculo del valor esperado.

### Suposiciones

- El valor esperado se calcula en la unidad de medida del item. Si en un período se
  registraron movimientos en unidades distintas, la conversión usa los factores de
  equivalencia configurados en 004-unidades-medida.
- Solo existe un inventario en progreso por tienda, tipo y horario por fecha.
- Un conteo abandonado (en_progreso sin actividad) no se elimina automáticamente; el
  admin puede retomarlo o descartarlo manualmente.
- **Mientras un conteo está `en_progreso` en una tienda, no se permiten movimientos de
  stock** (compras, mermas, ventas en batch) en esa tienda. Esto garantiza que el
  `valor_esperado` (snapshot tomado al inicio) permanece inmutable e impide inconsistencias
  por operaciones concurrentes.

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

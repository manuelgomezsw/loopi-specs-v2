# Especificación de Feature: Inventario y Conteo Físico

**Branch de Feature**: `009-inventario-conteo`
**Creado**: 2026-05-21
**Estado**: Borrador
**Referencia funcional**: [§3.4 Módulo: Inventario (Conteo Físico)](../loopi-v2-funcional/spec.md)
**Bugfix**: 2026-07-19 — BUG-019 Eliminación de campo redundante `valor_sugerido`, mantener solo `valor_esperado`

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
   `diario` con su valor sugerido calculado desde el inventario de referencia más reciente.

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
   que el tipo es `inicial`, presentando todos los items activos con valor sugerido en cero,
   estableciendo el stock inaugural de la tienda.

5. **Dado** que la tienda tiene items con frecuencia_inventario=diario,
   **Cuando** se inicia conteo diario,
   **Entonces** se retornan todos los items diarios con valor_sugerido desde stock_actual sin necesidad de consulta manual.

6. **Dado** que NO hay items con frecuencia_inventario=tipo seleccionado,
   **Cuando** se intenta iniciar conteo,
   **Entonces** retorna HTTP 422 `sin_items_contabilizar` con mensaje descriptivo del tipo.

---

### Historia de Usuario 2 — Registrar el conteo físico item por item (Prioridad: P1)

Durante el conteo, el líder o barista ingresa la cantidad física real de cada item. El
sistema muestra en tiempo real la diferencia entre lo esperado y lo contado, permitiendo
que el usuario detecte inconsistencias antes de confirmar.

**Por qué esta prioridad**: Es el núcleo del conteo — sin el registro físico no hay datos
para ajustar el stock ni detectar mermas o pérdidas.

**Prueba Independiente**: Puede verificarse ingresando cantidades y comprobando que la
diferencia (real − esperado) se actualiza de inmediato en pantalla.

**Escenarios de Aceptación**:

1. **Dado** que el conteo está en progreso y el item "Leche Entera" tiene valor esperado
   de 5 000 ml,
   **Cuando** el líder registra 4 600 ml como valor real,
   **Entonces** el sistema muestra una diferencia de −400 ml de inmediato, sin necesidad
   de guardar manualmente.

2. **Dado** que el conteo fue interrumpido (app cerrada o pérdida de conexión),
   **Cuando** el responsable retoma el conteo,
   **Entonces** el sistema recupera los valores ya ingresados y continúa desde donde se
   detuvo, sin perder datos.

3. **Dado** que el líder intenta confirmar el conteo con items sin valor registrado,
   **Cuando** presiona confirmar,
   **Entonces** el sistema bloquea la confirmación e indica cuáles items faltan por contar.

---

### Historia de Usuario 3 — Confirmar el inventario y ajustar el stock (Prioridad: P1)

Una vez registrados todos los items, el líder confirma el conteo. El sistema ajusta
automáticamente el stock de cada item al valor real contado, sin requerir aprobación
adicional. Las diferencias quedan registradas como parte del historial del inventario.

**Por qué esta prioridad**: El ajuste automático es el propósito central del módulo y la
fuente de verdad del stock proyectado para todos los módulos posteriores (pedidos,
planeación).

**Prueba Independiente**: Puede verificarse confirmando un conteo con diferencias y
comprobando que el stock de los items ajustados refleja el valor real contado.

**Escenarios de Aceptación**:

1. **Dado** que todos los items del conteo tienen valor real registrado,
   **Cuando** el líder confirma el inventario,
   **Entonces** el stock de cada item en la tienda se ajusta al valor real contado, las
   diferencias quedan registradas en el historial y el inventario pasa a estado `completado`.

2. **Dado** que un inventario ya fue confirmado (estado `completado`),
   **Cuando** el admin intenta modificar sus valores,
   **Entonces** el sistema permite la modificación directa únicamente al admin; cualquier
   otro rol recibe acceso denegado e indicación de que las correcciones deben registrarse
   como mermas o mediante un nuevo inventario.

---

### Historia de Usuario 4 — Consultar el historial de inventarios (Prioridad: P2)

El administrador revisa el historial de conteos de una tienda para auditar el stock en
fechas pasadas, detectar patrones de discrepancia o verificar que los conteos se están
realizando con la frecuencia esperada.

**Por qué esta prioridad**: La visibilidad histórica es fundamental para el control
operativo y la detección de pérdidas sistemáticas.

**Prueba Independiente**: Puede verificarse consultando el historial y comprobando que
cada inventario muestra fecha, tipo, responsable y resumen de diferencias.

**Escenarios de Aceptación**:

1. **Dado** que existen inventarios completados de distintos tipos,
   **Cuando** el admin consulta el historial de inventarios de una tienda,
   **Entonces** ve la lista ordenada por fecha con tipo, horario, responsable y estado de
   cada conteo.

2. **Dado** que el admin selecciona un inventario completado,
   **Cuando** accede a su detalle,
   **Entonces** puede ver el valor esperado, el valor real y la diferencia por cada item
   contado en ese inventario.

---

## Requisitos Funcionales

### RF-INV-01: Inicio del inventario

- RF-INV-01.1: El líder de tienda, barista y admin pueden iniciar conteos. Solo pueden
  iniciar conteos de su propia tienda (lider_tienda y barista); el admin puede iniciar
  conteos en cualquier tienda.
- RF-INV-01.2: Al iniciar, el sistema sugiere el tipo y horario según la hora actual:
  - 06:00–10:59 → `diario / apertura`
  - 11:00–14:59 → `diario / mediodía`
  - 15:00–23:59 → `diario / cierre`
- RF-INV-01.3: El usuario puede cambiar el tipo manualmente a `diario`, `semanal` o
  `mensual` sin restricción de horario. ~~El tipo `inicial` NO es selectable manualmente;~~ El tipo
  `inicial` es determinado automáticamente por el sistema (ver RF-INV-01.5).
- RF-INV-01.4: No se puede crear un nuevo inventario para la misma tienda, tipo, horario y fecha
  si ya existe uno (independientemente de su estado: `en_progreso` o `completado`). El sistema retorna
  **HTTP 409 Conflict** con `error_code=conteo_duplicado`. El mensaje de error debe indicar claramente:
  - Si el duplicado está `en_progreso`: "Ya existe un conteo en progreso... Usa Reanudar para continuar"
  - Si el duplicado está `completado`: "Ya existe un conteo completado para este tipo/horario en esta fecha.
    No se pueden crear conteos duplicados en el mismo día"
  El operador debe entender que no puede proceder con el mismo parámetros en la misma fecha.
- RF-INV-01.5: El tipo `inicial` es determinado automáticamente por el sistema cuando realiza
  el primer conteo de una tienda (sin historial de inventarios completados). El usuario NO puede
  seleccionar "inicial" manualmente. El sistema lo determina consultando si existe inventario
  completado previo en la tienda: si existe, el tipo es la categoría elegida por el usuario
  (diario/semanal/mensual); si no existe, el tipo es "inicial" independientemente de lo que
  el usuario haya seleccionado. No requiere inventario de referencia previo.
- RF-INV-01.6: Los items presentados en el conteo dependen del tipo:
  - `diario`: todos los items con frecuencia de inventario `diario`.
  - `semanal`: todos los items con frecuencia de inventario `semanal`.
  - `mensual`: todos los items con frecuencia de inventario `mensual`.
  - `inicial`: todos los items activos.

### RF-INV-02: Registro del conteo

- RF-INV-02.1: Para cada item del conteo, el sistema muestra: **nombre del item** (nombre, no ID),
  valor esperado (stock proyectado) y un campo para ingresar el valor real.
  El nombre debe ser legible para que el operador pueda identificar claramente qué item está contando
  sin necesidad de consultar el catálogo.
  
  **Restricción de valores**: El valor real debe ser un número entero o decimal **≥ 0**. No se aceptan
  cantidades negativas. Si el usuario intenta ingresar un valor negativo, el sistema retorna **HTTP 400**
  con código de error `valor_invalido` y mensaje: *"La cantidad no puede ser negativa. Ingrese un valor mayor o igual a 0."*
- RF-INV-02.2: El valor esperado de cada item es un **snapshot inmutable** del stock
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
- RF-INV-02.3: La diferencia (real − esperado) se recalcula y muestra en pantalla en
  tiempo real al ingresar cada valor. La visualización debe mostrar un **badge/etiqueta en la esquina
  superior derecha** con:
  - **Patrón de mensaje**: Según el valor de la diferencia:
    - Si diferencia < 0: `⚠️ Faltante: {valor_numérico}` con **fondo rojo** (ej: "⚠️ Faltante: -8")
    - Si diferencia > 0: `ℹ️ Exceso: {valor_numérico}` con **fondo verde** (ej: "ℹ️ Exceso: +2")
    - Si diferencia = 0: `✓ Correcto` con **fondo gris** (ej: "✓ Correcto")
  - **Valor numérico de la diferencia** con su unidad de medida (ej: "-400 ml", "+2 unidades", "0")
  - **Indicadores visuales**: Símbolo (⚠️/ℹ️/✓) + color + texto para máxima claridad
  - El objetivo es que el operador vea claramente qué tipo de discrepancia existe SIN confundir con un estado de éxito/fallo
  - **Accesibilidad**: Símbolo + color + mensaje de texto = WCAG 2.1 AA compliant (no solo color)
- RF-INV-02.3: **Determinación Automática de Items**: El sistema determina automáticamente
  los items a contar en 5 pasos:
  1. Consulta items activos con frecuencia_inventario = tipo seleccionado
  2. Valida que existan items para contar; si no hay, retorna 422 `sin_items_contabilizar`
  3. Crea registro en inventarios (estado=en_progreso)
  4. Cruza items con stock_actual para obtener valor_sugerido de cada item
  5. Crea registros en detalle_inventario con valor_sugerido mapeado

  Este flujo garantiza que POST /inventarios SIEMPRE retorna 201 con items listos para contar
  (nunca con lista vacía) o retorna 422 si no hay items para el tipo seleccionado.
- RF-INV-02.4: Un conteo en progreso puede ser retomado por el mismo responsable si fue
  interrumpido; los valores ya ingresados se conservan.
- RF-INV-02.5: Solo el responsable que inició el conteo puede retomarlo y completarlo.
  Otros usuarios ven el conteo como bloqueado.

### RF-INV-03: Confirmación y ajuste de stock

- RF-INV-03.1: Para confirmar un inventario, todos los items deben tener valor real
  registrado. El sistema bloquea la confirmación si falta alguno.
- RF-INV-03.2: Al confirmar, el stock de cada item en la tienda se ajusta automáticamente
  al valor real contado. No se requiere aprobación de un rol superior.
- RF-INV-03.3: El inventario confirmado pasa a estado `completado`. Solo el admin puede
  modificar directamente los valores de un inventario completado. Para lider_tienda y
  barista, las correcciones deben registrarse como mermas o mediante un nuevo inventario.
- RF-INV-03.4: Las diferencias de cada item (positivas y negativas) quedan registradas en
  el historial del inventario para trazabilidad.

### RF-INV-04: Historial y consulta

- RF-INV-04.1: El admin puede consultar el historial completo de inventarios de cualquier
  tienda, con fecha, tipo, horario, responsable y estado.
- RF-INV-04.2: El lider_tienda puede consultar el historial de inventarios de su propia
  tienda.
- RF-INV-04.3: Desde el detalle de un inventario completado, se pueden ver los valores
  esperado, real y diferencia por cada item contado.

### RF-INV-05: Bloqueo de Movimientos Durante Conteo Activo

- RF-INV-05.1: Mientras existe un inventario con estado `en_progreso` en una tienda,
  **no se permiten** las siguientes operaciones:
  - Registrar compras de caja menor o recepciones de pedido (feature 010).
  - Registrar mermas (feature 010).
  - Procesar archivo de venta en batch (feature 015) — la validación ocurre **antes** de
    permitir el upload del archivo.

- RF-INV-05.2: Si se intenta registrar cualquiera de estas operaciones, el sistema retorna
  **HTTP 409 Conflict** con:
  - Código de error: `inventario_activo`
  - Mensaje: "No se pueden registrar movimientos mientras hay un conteo en progreso.
    Contacte al líder de tienda o administrador para completar o cancelar el conteo
    actual."
  - Detalles opcionales: ID del inventario activo, responsable, hora de inicio.

- RF-INV-05.3: El propósito de este bloqueo es garantizar que el `valor_sugerido` (RF-INV-02.2)
  permanece estable e inmutable durante todo el conteo, eliminando inconsistencias por
  movimientos concurrentes.

- RF-INV-05.4: Las **consultas de stock** (lecturas, sin cambios) sí funcionan normalmente
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
  UNIQUE constraint (tienda_id, tipo, horario_norm, fecha). Esto evita que usuario intente
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
| `Inventario` | tienda_id, fecha, tipo, horario, estado, responsable_id, iniciado_en, completado_en |
| `DetalleInventario` | inventario_id, item_id, valor_esperado, valor_real, diferencia |

**Nota**: `responsable_id` es una clave foránea que referencia `empleados (id)`. El responsable de un conteo debe ser un empleado autenticado con rol `admin`, `lider_tienda` o `barista`.

---

## Dependencias y Suposiciones

### Dependencias

- **001-autenticacion**: El responsable debe estar autenticado y el sistema conoce su
  tienda asignada (lider_tienda, barista) o permite selección (admin).
- **002-gestion-tiendas**: El inventario pertenece a una tienda activa.
- **007-items-catalogo**: Los items con su frecuencia de inventario determinan qué se
  cuenta en cada tipo de conteo. **Pendiente de esta feature**: `007-items-catalogo` deja
  un stub `tieneHistorialStock(itemID)` (`service.go`) que siempre retorna `false` porque
  aún no existen tablas de conteo; al implementar 009 se debe reemplazar ese stub por una
  consulta real (ej. `EXISTS` sobre `detalle_inventario`) para que RF-ITEM-02.4 (confirmación
  obligatoria al cambiar la unidad de medida de un item con historial de stock) funcione
  como está especificado en `007-items-catalogo/spec.md`.
- **010-mermas** (posterior): Las mermas registradas entre conteos impactan el valor
  sugerido del siguiente inventario.
- **008-menu-recetas** + **015-pos** (posterior): Las ventas procesadas entre conteos
  se incorporan al cálculo del valor sugerido.

### Suposiciones

- El valor sugerido se calcula en la unidad de medida del item. Si en un período se
  registraron movimientos en unidades distintas, la conversión usa los factores de
  equivalencia configurados en 004-unidades-medida.
- Solo existe un inventario en progreso por tienda, tipo y horario por fecha. No hay
  concepto de "pausar" formalmente — simplemente el conteo queda en_progreso hasta que
  se completa o se abandona.
- Un conteo abandonado (en_progreso sin actividad) no se elimina automáticamente; el
  admin puede retomarlo o marcarlo como descartado manualmente.
- No existe flujo de aprobación para los ajustes de stock; la confirmación del inventario
  es el único paso requerido y cualquiera que inició el conteo puede completarlo.
- **Mientras un conteo está `en_progreso` en una tienda, no se permiten movimientos de
  stock** (compras, mermas, ventas en batch) en esa tienda. Esto garantiza que el
  `valor_sugerido` (snapshot tomado al inicio) permanece inmutable e impide inconsistencias
  por operaciones concurrentes. El bloqueo se levanta al confirmar o eliminar el conteo.

---

## Iteraciones de Diseño

### Iteration 2026-07-18: Corrección de Flujo Conceptual (BUG-016)

**Change**: Invertir orden de operaciones en Service.Iniciar(): consultar items ANTES de crear inventario, validar hay items, cruzar con stock_actual, LUEGO crear inventario y detalles.

**Scope**: Feature-wide (arquitectura central)

**Artifacts Updated**:

- spec.md: Agregada RF-INV-02.3 (Determinación Automática de Items) + escenarios 5-6
- plan.md: Creado (fases, arquitectura, stack tech)
- data-model.md: Creado (5-step flow, entities, constraints)
- tasks.md: Reabiertos T021-T023 (fase 2 refactor), Agregadas T154-T163 (nuevas funciones + tests)
- bugs/BUG-016.md: Reconceptualizado de "items no se crean" a "flujo orden invertido" (Patched)

**Impact**:

- POST /inventarios ahora **siempre** retorna 201 con items (nunca 0) O retorna 422 si no hay items
- Requiere 2 nuevas funciones repository (GetItemsActivosPorTipo, GetStockSnapshot)
- Service.Iniciar() refactorización de 3 pasos (query → validate → create)
- Error code nuevo: sin_items_contabilizar (422)
- Frontend ErrorMapperService necesita mapeo nuevo

**Risk**: Breaking change en API (POST /inventarios response format), pero frontend ya está preparado.

---

## Bugs Identificados y Estado de Correcciones

**Fecha de Reporte**: 2026-07-13
**Total Bugs Identificados**: 16 (5 críticos backend, 4 críticos frontend, 4 altos backend, 3 altos frontend)
**Status General**: ✅ Patched (Todos marcados para corrección)

**Update 2026-07-18**: BUG-016 Reconceptualizado e iteración 2026-07-18 aplicada (ver sección Iteraciones arriba)

### Bloqueadores Críticos Backend

1. **BUG-005**: JWT Extraction Hardcoded — userID=1, roleID=1
   - Archivo: `loopi-api-v2/internal/inventarios/handler.go`
   - Impacto: Todas las operaciones usan ID falso — seguridad crítica
   - Estado: ✅ Patched

2. **BUG-006**: Path Values Hardcoded — inventarioID=1, itemID=1
   - Archivo: `loopi-api-v2/internal/inventarios/handler.go`
   - Impacto: Endpoints no funcionales — siempre operan sobre mismo ID
   - Estado: ✅ Patched

3. **BUG-008**: RBAC Not Implemented — 7 TODOs sin validación
   - Archivo: `loopi-api-v2/internal/inventarios/service.go`
   - Impacto: Control de acceso ausente — violación security
   - Estado: ✅ Patched

4. **BUG-009**: Valor Sugerido No Calculado per RF-INV-02.2
   - Archivo: `loopi-api-v2/internal/inventarios/service.go`
   - Impacto: Feature core broken — cálculo de stock incorrecto
   - Estado: ✅ Patched

5. **BUG-007**: HTTP Status Codes Always 400
   - Archivo: `loopi-api-v2/internal/inventarios/handler.go`
   - Impacto: Violación REST contracts — frontend no puede diferenciar errores
   - Estado: ✅ Patched

### Bloqueadores Críticos Frontend

1. **FE-BUG-001**: Memory Leaks — 8 subscriptions sin takeUntil
   - Archivo: `loopi-web-v2/src/app/inventario/inventario-conteo.component.ts`
   - Impacto: Memory depletion en uso prolongado
   - Estado: ✅ Patched

2. **FE-BUG-002**: NgModule Mixto — Violación FE-STACK-01
   - Archivo: `loopi-web-v2/src/app/inventario/inventario.module.ts`
   - Impacto: Incumple estándar — conflicto con arquitectura
   - Estado: ✅ Patched

3. **FE-BUG-003**: Reimplements Filters/Table — No usa Transversals
   - Archivo: `loopi-web-v2/src/app/inventario/inventario-historial.component.ts/html`
   - Impacto: Violación FE-COMP-01 — duplicación de código
   - Estado: ✅ Patched

4. **FE-BUG-004**: Validación Formularios Incompleta
   - Archivo: `loopi-web-v2/src/app/inventario/inventario-conteo.component.ts/html`
   - Impacto: Usuario puede enviar datos inválidos — UX pobre
   - Estado: ✅ Patched

### Altos Backend

1. **BUG-004**: Duplicate Key Error Returns 400 Instead of 409
2. **BUG-010**: Logging Incompleto — Missing Fields
3. **BUG-011**: Query Parameters Not Parsed
4. **BUG-012**: Observabilidad Incompleta — Sin Métricas/Spans

### Altos Frontend

1. **FE-BUG-005**: WCAG 2.1 AA Violations — Contraste/aria-live/Labels
2. **FE-BUG-006**: E2E Tests Completamente Ausentes
3. **FE-BUG-007**: ChangeDetection Sin OnPush + Tabla No Responsive

### Nuevos Bugs Identificados (2026-07-18)

1. **FE-BUG-008**: Item Title Display Shows ID Instead of Name (High)
   - Archivo: `loopi-web-v2/src/app/inventario/inventario-conteo.component.html`
   - Impacto: Operador no puede identificar items — UX crítico en conteo
   - Requisito afectado: RF-INV-02.1 (no especificaba qué campo mostrar)
   - Estado: 🔧 Pendiente patch (Spec gap: RF-INV-02.1 actualizado con clarificación)
   - Tareas impactadas: T040, T041 (reabiertos)

2. **FE-BUG-009**: Difference Indicator Shows Green Checkmark Instead of Alert (High)
   - Archivo: `loopi-web-v2/src/app/inventario/inventario-conteo.component.html`
   - Impacto: Usuario pierde visibilidad de diferencias — viola RF-INV-02.3
   - Requisito afectado: RF-INV-02.3 (no definía patrón visual para diferencias)
   - Estado: 🔧 Pendiente patch (Spec gap: RF-INV-02.3 necesita patrón visual)
   - Tareas impactadas: T041, T042 (reabiertos)

3. **FE-BUG-010**: Duplicate Inventory Error Message Misrepresents Closed Count (High)
   - Archivo: `loopi-web-v2/src/app/inventario/inventario.service.ts` (error-mapper)
   - Impacto: Mensaje confuso — usuario no sabe qué hacer ante duplicado cerrado
   - Requisito afectado: RF-INV-01.4 (no diferencia estados en error)
   - Estado: 🔧 Pendiente patch (Spec gap: RF-INV-01.4 + error handling clarification)
   - Tareas impactadas: T032 (reabierto)

### Nuevos Bugs Identificados (2026-07-19)

1. **BUG-017**: Tipo de Conteo "Inicial" Debe Determinarse Automáticamente (High)
   - Archivo: Arquitectura Service + Frontend
   - Impacto: Usuario puede seleccionar "inicial" manualmente, violando el algoritmo correcto
   - Requisito afectado: RF-INV-01.3, RF-INV-01.5, HU1 Escenario 4
   - Estado: ✅ Patched (Spec gap: Agregada sección "Algoritmo de Determinación Automática de Tipo de Conteo")
   - Tareas impactadas: T029-T031 (reabiertos), T164-T171 (nuevas Phase 12-bis)

2. **BUG-018**: Indicador Visual de Diferencias — Ambigüedad en Mensaje de Etiqueta (Medium)
   - Archivo: `loopi-web-v2/src/app/inventario/inventario-conteo.component.html/ts`
   - Impacto: Patrón "'⚠️ Pérdida' : '✓ Ganancia'" es ambiguo; operador confunde discrepancias con estados de éxito/fallo
   - Requisito afectado: RF-INV-02.3 (define color + símbolo pero NO mensaje explícito)
   - Root Cause: Spec gap — RF-INV-02.3 no especificaba el TEXTO de la etiqueta en esquina superior derecha
   - Solución: Cambiar a patrón operativo neutral: "Faltante" (< 0), "Exceso" (> 0), "Correcto" (= 0)
   - Estado: ✅ Patched (Spec gap: RF-INV-02.3 actualizado con patrón explícito de mensaje + color + símbolo)
   - Tareas impactadas: T041, T042 (reabiertos para refactorizar HTML/TS con nuevo patrón)

3. **BUG-019**: Redundancia de Campos — Eliminar `valor_sugerido` (Medium)
   - Archivo: Spec, data-model.md, backend (models, repository), frontend (DTOs)
   - Impacto: Campo `valor_sugerido` es redundante con `valor_esperado`; ambos tienen mismo valor, generan confusión
   - Requisito afectado: RF-INV-02.1, RF-INV-02.2 (mencionan ambos campos sin justificación diferenciada)
   - Root Cause: Spec gap — Diseño inicial incluyó dos campos sin aclarar propósito diferenciado
   - Solución: Eliminar `valor_sugerido` completamente; mantener solo `valor_esperado` (snapshot inmutable de stock)
   - Estado: ✅ Patched (Spec gap: RF-INV-02.1/2.2 actualizado, data-model.md simplificado, backend refactorizado, frontend actualizado)
   - Tareas impactadas: Refactorización completada en backend (models.go, repository.go, service.go) y frontend (service.ts, specs)

4. **BUG-020**: Validación Faltante — Valores Negativos en Conteo (High)
   - Archivo: Backend (service.go), Frontend (formulario), Spec
   - Impacto: Usuario puede ingresar valores negativos en cantidad contada → riesgo de fraude y control interno débil
   - Requisito afectado: RF-INV-02.1 (no valida que valor_real >= 0)
   - Root Cause: Spec gap — RF-INV-02 asume implícitamente valores positivos, pero no lo explicita
   - Solución: Agregar validación explícita: `valor_real >= 0`, retornar HTTP 400 `valor_invalido` si es negativo
   - Estado: 🔧 Pendiente patch (Spec gap: RF-INV-02.1 necesita aclaración de rango de valores válidos)
   - Tareas impactadas: T061 (RegistrarValor), T062 (Pruebas), Frontend (validación en formulario)

5. **BUG-021**: Validación de Horario Incompleta en Cambio de Tipo + Determinación Automática (High)
   - Archivo: Frontend `loopi-web-v2/src/app/inventario/inventario-conteo.component.ts` (línea 68-78) + Backend `loopi-api-v2/internal/inventarios/service.go` (línea 100, 149-152)
   - Impacto: Dos problemas correlacionados — (A) Usuario no puede iniciar semanal/mensual sin error, (B) Backend puede guardar inventario "inicial" CON horario (viola RF-INV-01.2)
   - **Variante A (Frontend)**: Usuario cambia tipo diario→semanal, campo horario retiene valor anterior 'apertura', envía {tipo:'semanal', horario:'apertura'}, backend rechaza
   - **Variante B (Backend)**: Usuario envía {tipo:'diario', horario:'apertura'} en primer conteo (sin historial), ValidarHorario pasa porque usa req.Tipo='diario', pero luego se determina automáticamente tipoReal='inicial' y se guarda con horario (viola RF-INV-01.2 y BUG-017)
   - Requisito afectado: RF-INV-01.2, RF-INV-01.3, BUG-017 (determinación automática de inicial)
   - Root Cause: (A) Frontend — validadores se limpian pero NO el valor, (B) Backend — validación de horario ocurre ANTES de determinar tipo real
   - Solución A: Agregar `horarioControl?.setValue(null)` línea 75 cuando tipo cambia a semanal/mensual
   - Solución B: Revalidar horario DESPUÉS de determinar tipoReal, O forzar horario=null cuando tipoReal=TipoInicial
   - Estado: 🔧 Pendiente patch (Frontend fix simple + Backend lógica de revalidación)
   - Tareas impactadas: T030, T031 (Frontend UI), T029-T031 (Backend per BUG-017), T164-T171 (determinación automática)

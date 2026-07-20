# Feature Specification: Iniciar Conteo de Inventario

**Feature Branch**: `feature/018-inventario-iniciar-conteo`

**Created**: 2026-07-20

**Status**: Draft

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Líder de tienda inicia conteo físico (Priority: P1)

Un líder de tienda abre la interfaz de conteo de inventario, selecciona el tipo de conteo (por ejemplo, "conteo completo", "conteo selectivo por categoría"), el sistema sugiere automáticamente el tipo según patrones históricos, y luego el líder confirma fecha y horario para ejecutar el conteo. El sistema carga la lista de items activos de esa tienda y prepara la sesión.

**Why this priority**: Es el flujo crítico de entrada a todo el dominio de inventario. Sin capacidad de iniciar un conteo, no hay nada que contar ni ajustar.

**Independent Test**: Puede testearse de forma aislada ejecutando "crear un nuevo conteo" sin necesidad de completar el conteo. El usuario ve la sesión creada, la lista de items lista para registrar, y puede navegar a la siguiente fase (registrar valores).

**Acceptance Scenarios**:

1. **Given** un líder de tienda autenticado en una tienda específica, **When** accede a "Iniciar Conteo" y selecciona tipo de conteo, **Then** el sistema sugiere automáticamente el tipo más probable según histórico y **Then** muestra un formulario con fecha/horario predefinidos (hoy, hora actual).
2. **Given** el líder confirma el formulario, **When** hace submit, **Then** el sistema crea el inventario en estado `en_progreso` y retorna la sesión con los items activos de la tienda listos para registro.
3. **Given** ya existe un conteo `en_progreso` en la misma tienda para la misma fecha/tipo/horario, **When** intenta crear otro, **Then** el sistema retorna un conflicto (`409`) con mensaje "Ya existe un conteo en progreso para este horario en esta tienda".
4. **Given** una tienda sin items activos, **When** intenta iniciar conteo, **Then** el sistema permite crear la sesión vacía (edge case: tienda que cerrará, sin inventario).

---

### User Story 2 - Admin supervisa conteos de múltiples tiendas (Priority: P2)

Un administrador puede ver un listado de todos los conteos iniciados en todas las tiendas (filtrable por tienda, estado, fecha rango), y acceder a detalles de cualquiera para supervisar su progreso.

**Why this priority**: Soporte a supervisión centralizada y auditoría. Admin necesita visibilidad sobre qué conteos están en curso. No es crítico para el flujo principal (HU1), pero sí para el cierre operacional diario.

**Independent Test**: Ver y filtrar listado sin necesidad de completar ningún conteo. El usuario puede navegar a "Ver histórico de conteos" de forma aislada.

**Acceptance Scenarios**:

1. **Given** un admin autenticado, **When** accede a "Histórico de Conteos", **Then** ve todos los conteos de todas las tiendas en estado `en_progreso`, `completado`, `cancelado`, paginados.
2. **Given** el admin aplica filtro `?estado=en_progreso`, **When** hace submit, **Then** el listado muestra solo conteos en progreso.

---

### Edge Cases

- ¿Qué pasa si la fecha/horario del conteo es en el pasado? → Sistema rechaza (`400`): "Fecha/horario debe ser hoy o futuro".
- ¿Qué pasa si la tienda está inactiva? → Sistema rechaza (`403`): "No puedes iniciar conteo en tienda inactiva".
- ¿Qué pasa si el usuario no tiene permiso? → Sistema rechaza (`403`): "Permiso insuficiente — solo lider_tienda o admin pueden iniciar conteos".
- ¿Qué pasa si la BD falla al crear? → Sistema retorna (`500`) y log de error (observabilidad).

## Requirements *(mandatory)*

### Functional Requirements

- **RF-INV-01**: El sistema DEBE permitir a un líder de tienda o admin crear un nuevo inventario con tipo de conteo, fecha y horario.
- **RF-INV-01.1**: El sistema DEBE sugerir automáticamente el tipo de conteo más probable según el histórico de conteos anteriores (regla: tipo más frecuente en los últimos 30 días).
- **RF-INV-01.2**: El sistema DEBE validar que no exista ya un conteo `en_progreso` en la misma tienda + tipo + horario + fecha.
- **RF-INV-01.3**: El sistema DEBE validar que la fecha/horario sea hoy o futuro.
- **RF-INV-01.4**: El sistema DEBE validar que la tienda esté activa (estado `activo = true`).
- **RF-INV-01.5**: El sistema DEBE cargar todos los items activos de la tienda en el momento de crear el inventario (snapshot para consistencia).
- **RF-INV-05**: El sistema DEBE verificar que ningún item en la tienda esté bloqueado para movimientos (`CanRecordMovimiento` retorna false).
- **RF-INV-02 (posterior, pero en dependencia)**: Tras iniciar conteo, el usuario navega al flujo de registro item-por-item.

### Key Entities

- **Inventario**: Sesión de conteo físico. Atributos: `id`, `tienda_id`, `tipo_conteo` (enum: `manual`, `por_categoria`, `aleatorio`), `fecha_conteo`, `horario_conteo`, `creado_por`, `creado_en`, `estado` (enum: `en_progreso`, `completado`, `cancelado`), `actualizado_en`, `actualizado_por`.
- **DetalleInventario**: Registro individual de cada item dentro de un inventario. Atributos: `id`, `inventario_id`, `item_id`, `cantidad_sistema` (stock actual al momento de iniciar), `cantidad_real` (registrada durante el conteo, null hasta completar), `diferencia` (cantidad_real - cantidad_sistema, calculada al confirmar), `registrado_en`, `registrado_por`.
- **StockMovimiento**: Registro de auditoría de cada movimiento que afecta stock (entrada, salida, ajuste). Atributos: `id`, `tienda_id`, `item_id`, `cantidad`, `tipo` (enum: `entrada`, `salida`, `ajuste`), `motivo`, `inventario_id` (si aplica), `creado_en`, `creado_por`.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Un líder de tienda puede iniciar un conteo en menos de 30 segundos (formulario + confirmación).
- **SC-002**: El sistema carga la lista de items en menos de 2 segundos incluso con 5000+ items en catálogo.
- **SC-003**: 100% de conteos iniciados tienen el snapshot completo de stock_actual en ese momento (trazabilidad).
- **SC-004**: El sistema detecta y rechaza duplicados (mismo tienda/tipo/horario/fecha) en el 100% de intentos.
- **SC-005**: Cero pérdida de datos en caso de fallo de red durante creación (idempotencia).

## Assumptions

- El sistema de autenticación (JWT) ya existe y el token incluye `tienda_id` (para líder_tienda/barista) o no incluye (para admin/lider_compras).
- La tienda está cargada en caché o en BD (módulo 002-gestion-tiendas ya implementado).
- Los items activos de la tienda están disponibles vía módulo 007-catalogo-items.
- El horario sugerido es la hora actual (no hay lógica de "siguiente horario disponible").
- La regla de sugerencia de tipo ("más frecuente en 30 días") es computada en `service.go` sin necesidad de tabla adicional — se usa el histórico directo de la tabla `inventarios`.
- No hay validación de "turnos" del empleado — cualquier líder de tienda puede iniciar conteo en cualquier horario.

## Observabilidad *(obligatorio para endpoints críticos)*

### Trazas (Spans OTel)

| Operación | Nombre del Span | Atributos Obligatorios |
|---|---|---|
| Crear inventario | `inventario.iniciar.crear` | `resultado` (success/validation_error/not_found), `tienda_id` |
| Obtener sugerencia de tipo | `inventario.iniciar.sugerir_tipo` | `resultado`, `tienda_id` |
| Cargar items de tienda | `inventario.iniciar.cargar_items` | `resultado`, `tienda_id`, `cantidad_items` |
| Validar duplicado | `inventario.iniciar.validar_duplicado` | `resultado`, `tienda_id` |

### Métricas

| Nombre | Tipo | Unidad | Descripción | Etiquetas |
|---|---|---|---|---|
| `inventario.iniciar.crear.duration` | Histograma | ms | Latencia de creación de inventario | `resultado`, `tienda_id` |
| `inventario.iniciar.crear.total` | Contador | — | Total de inventarios creados | `resultado`, `tienda_id` |
| `inventario.iniciar.cargar_items.duration` | Histograma | ms | Latencia de carga de items | `resultado`, `tienda_id` |
| `inventario.iniciar.items_cargados.size` | Gauge | items | Cantidad de items cargados por conteo | `tienda_id` |

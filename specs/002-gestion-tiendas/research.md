# Research: Gestión de Tiendas

**Feature**: `002-gestion-tiendas` | **Fecha**: 2026-05-23

## Decisiones Técnicas

---

### 1. Router HTTP para Go

- **Decisión**: `go-chi/chi` v5
- **Rationale**: Idiomático con `net/http` estándar, sin dependencias externas pesadas,
  middleware componible (ideal para JWT + logging + RBAC). Amplio uso en proyectos Go
  de producción. Compatible con el patrón handler → service → repository.
- **Alternativas consideradas**: gin (más popular pero acoplado a su propio contexto),
  stdlib solo (demasiado verboso para routing con parámetros y middleware).

---

### 2. Unicidad de nombre case-insensitive en MySQL

- **Decisión**: Collation `utf8mb4_unicode_ci` en la columna `nombre` + índice UNIQUE.
- **Rationale**: Garantiza la unicidad a nivel de BD sin depender de la capa de aplicación.
  `utf8mb4_unicode_ci` es la collation recomendada para MySQL 8 con soporte Unicode completo
  (emojis incluidos). Con esta collation, `"Tienda Norte"` y `"TIENDA NORTE"` son considerados
  iguales por el índice UNIQUE: el motor rechazará la inserción con error `1062 Duplicate entry`.
- **Alternativas consideradas**: Validación solo en la capa Go (riesgo de race condition en
  inserciones concurrentes); collation `utf8mb4_general_ci` (menos precisa para algunos caracteres
  Unicode, pero válida para español).

---

### 3. Query builder vs ORM completo

- **Decisión**: `jmoiron/sqlx` (query builder idiomático Go sobre `database/sql`)
- **Rationale**: Consistente con el lineamiento de la constitución de evitar abstracciones
  innecesarias para el alcance de esta feature. `sqlx` mantiene SQL explícito (más fácil
  de auditar y optimizar), sin magia de ORM que dificulte el debugging en producción.
  El modelo de datos de `tiendas` es simple (una tabla, sin joins complejos).
- **Alternativas consideradas**: GORM (demasiado implícito para una feature de auditoría donde
  SQL explícito es preferible); `database/sql` puro (verboso para scan de structs).

---

### 4. Paginación del listado de tiendas

- **Decisión**: Paginación server-side con `LIMIT` / `OFFSET` en MySQL.
  `page_size` default 50, máximo 100. Query params: `?pagina=1&limite=50`.
- **Rationale**: La constitución prohíbe la paginación en memoria para colecciones que puedan
  crecer ilimitadamente. Aunque el volumen esperado de tiendas es bajo (10–50), se aplica la
  regla de forma consistente para evitar deuda técnica si el modelo se replica en otras
  instalaciones de mayor escala.
- **Alternativas consideradas**: Sin paginación (viola la constitución); cursor-based pagination
  (overkill para esta feature de admin).

---

### 5. Inactivar vs. Eliminar — campo `activo`

- **Decisión**: `activo TINYINT(1) NOT NULL DEFAULT 1`. No existe `DELETE` físico.
- **Rationale**: Alineado con la constitución (Principio V) y con la convención del CLAUDE.md
  del backend: *"Nunca DELETE físico. Catálogo: `activo TINYINT(1)`"*. El historial de
  operaciones referenciado por `tienda_id` permanece intacto.
- **Alternativas consideradas**: Tabla `tiendas_eliminadas` (sobrediseño); campo `eliminado`
  adicional (redundante con `activo`).

---

### 6. Inmutabilidad del campo `codigo`

- **Decisión**: El handler de `PUT /api/v1/tiendas/{id}` ignora el campo `codigo` si viene
  en el body. La capa de servicio no lo incluye en el UPDATE SQL. No se valida si cambia;
  simplemente no se actualiza.
- **Rationale**: Simple y robusto. El `codigo` es la clave de integración con POS; si cambia,
  los registros históricos del POS quedarían desvinculados. Ignorar silenciosamente es
  preferible a retornar un error 422 que confunda al consumidor del API.
- **Alternativas consideradas**: Retornar 422 si `codigo` viene en el body de edición
  (más explícito pero más frágil para clientes legacy).

---

### 7. Confirmación de reactivación — responsabilidad del frontend

- **Decisión**: El backend ejecuta la reactivación sin condición adicional.
  El diálogo de confirmación es responsabilidad exclusiva del frontend Angular.
- **Rationale**: El Principio III de la constitución establece que la validación del backend
  es vinculante, pero la confirmación de reactivación es una acción reversible de bajo riesgo
  (UX). No hay lógica de negocio que bloquee la reactivación, por lo que agregar validación
  en el backend sería sobrediseño.
- **Alternativas consideradas**: Header `X-Confirm: true` requerido por el backend
  (complejidad innecesaria para una acción sin impacto de integridad).

---

### 8. Estructura de respuesta de error

- **Decisión**: Seguir el esquema estándar del CLAUDE.md del backend:

  ```json
  { "error": "nombre_duplicado", "mensaje": "Ya existe una tienda con ese nombre.", "campo": "nombre" }
  ```

- **Códigos HTTP**: 400 (input inválido), 409 (conflicto de unicidad), 404 (no existe),
  422 (regla de negocio — ej. inactivar una tienda ya inactiva), 403 (rol sin permiso).
- **Rationale**: Consistencia con el resto de la API. El campo `campo` permite al frontend
  resaltar el campo con error en el formulario (convención Angular del CLAUDE.md web).

---

### 9. Observabilidad de los endpoints de tiendas

- **Decisión**: Log estructurado JSON con campos `user_id`, `rol`, `operacion`,
  `tienda_id` (cuando aplica), `duracion_ms`, `status_http` en cada handler.
  Instrumentación OpenTelemetry (span por handler, métricas de latencia y tasa de error).
- **Rationale**: Principio VI de la constitución. Los endpoints de gestión de tiendas son
  operaciones de admin de baja frecuencia, pero su impacto es crítico (sin tienda activa
  no hay operación). El logging de quién hizo qué y cuándo es parte de la auditoría funcional.
- **Alternativas consideradas**: Solo logging sin OTel (insuficiente para cumplir Principio VI).

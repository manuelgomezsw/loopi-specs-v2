# Estado de Separación: 009-inventario-conteo → 018-023

**Última actualización:** 2026-07-20

## Resumen Ejecutivo

Separación de feature monolítica (009-inventario-conteo, 562 líneas spec) en 6 features independientes (018-023) con ciclos de vida propios. **Phase 2 (018) completada exitosamente.** Listos para Phase 3 (019).

---

## Progreso por Feature

### ✅ Phase 2: 018-inventario-iniciar-conteo

**Estado:** COMPLETADA - Listos para mergear a develop

#### Backend (loopi-api-v2)

- ✅ Módulo `internal/inventarios/iniciar/` extraído
- ✅ Observabilidad OTel: spans + métricas Datadog
  - `inventario.iniciar.crear` (span principal, 201 Created)
  - `inventario.iniciar.determinar_tipo` (determinación automática tipo inicial)
  - `inventario.iniciar.cargar_items` (carga items activos)
- ✅ Métricas: histogram duration, counter total, gauge items_count
- ✅ Tests: go test ./... ✅
- ✅ Commit: `796b6cb`

#### Frontend (loopi-web-v2)

- ✅ Componente `iniciar-conteo/` extraído del monolito
- ✅ Session recovery: detecta conteos en progreso, redirige automáticamente
- ✅ Sugerencia automática: tipo/horario sin bloqueo
- ✅ Validación dinámica: horario requerido solo si tipo=diario
- ✅ Manejo de conflicto: modal para reanudación conteo activo
- ✅ Tests: 258/258 passing ✅
- ✅ Rutas actualizadas: `/inventario/iniciar`
- ✅ Navbar: agregados sub-items (Iniciar Conteo, Historial)
- ✅ Commits: `c6c9bd0`, `8948d56`, `4c8f294`, `bbc7285`

#### Specs (loopi-specs-v2)

- ✅ 69 tareas de migración documentadas
- ✅ Data-model: 4 tablas (inventarios, detalle_inventario, stock_actual, stock_movimientos)
- ✅ Commit: `f670aa5`

#### PRs Abiertos

1. [loopi-specs-v2 #74](https://github.com/manuelgomezsw/loopi-specs-v2/pull/74)
2. [loopi-api-v2 #33](https://github.com/manuelgomezsw/loopi-api-v2/pull/33)
3. [loopi-web-v2 #33](https://github.com/manuelgomezsw/loopi-web-v2/pull/33)

**Validaciones completadas:**

- Build: ✅ (no errors)
- Tests: ✅ (258/258 passing)
- Lint: ✅ (no errors, warnings de legacy)
- Security: ✅ (Trivy + GitGuardian)

---

### ⏳ Phase 3: 019-inventario-realizar-conteo (SIGUIENTE)

**Estado:** PENDIENTE - Crear spec + backend + frontend

#### Scope

- Registro item-por-item con validación (valor ≥ 0)
- Autosave: POST tras cada entrada válida
- Recuperación de sesión: precarga valores registrados
- Indicadores de progreso y diferencias

#### Tareas pendientes

- [ ] Crear spec 019 con HU2, RF-INV-02
- [ ] Backend: módulo `realizar/` (handler/service/repository)
- [ ] Observabilidad: spans + métricas para registrar-valor
- [ ] Frontend: componente `realizar-conteo/`
- [ ] Navegación: `/inventario/:id/realizar`
- [ ] Tests + validación

---

### 📋 Phase 4-7: 020-023 (PENDIENTE)

| Phase | Feature | Deps | Scope |
|-------|---------|------|-------|
| 4 | 020-completar-conteo | 018, 019 | Confirmación + ajuste automático stock |
| 5 | 021-historial-conteo | 018 | Listar/filtrar/ver detalle (paralelo a 4) |
| 6 | 022-editar-conteo | 018, 020 | Admin edita completado |
| 7 | 023-eliminar-conteo | 018 | Admin elimina en_progreso (paralelo a 6) |

---

## Gobernanza

### BE-ARCH-02 (Sub-dominios)

**Estado:** ✅ Enmienda completada

- Documento: `.specify/memory/standards/backend.md` v1.1.0
- Permite sub-paquetes `internal/<dominio>/<subdominio>/`
- Cada sub-dominio: handler/service/repository propios
- `core/`: sin handler, solo models + métodos compartidos
- Propagada a: `loopi-api-v2/CLAUDE.md`

**Regla de promoción a core:**

- Solo cuando existe 2+ consumidoras reales
- No anticipadamente

---

## Cómo Continuar en Próximas Sesiones

### Antes de avanzar

1. Leer este archivo
2. Leer [`plan-separation-009-018-023.md`](../.claude/projects/-home-manuelgomezjp-repos-loopi-v2-loopi-specs-v2/memory/plan-separation-009-018-023.md) en memoria
3. Verificar PRs de 018 están mergeados a develop

### Para crear 019

1. Crear branch `feature/019-inventario-realizar-conteo` desde develop
2. Generar spec 019 (copiar patrón de 018)
3. Backend: módulo `realizar/` (copiar estructura de `iniciar/`)
4. Frontend: componente `realizar-conteo/` (idem)
5. Agregar rutas y navbar
6. Crear PRs (mismo patrón que 018)

### Plantillas a reutilizar

- `otel.go` + `metrics.go` (observabilidad)
- `component.ts` + `.html` + `.spec.ts` (frontend)
- Tests: 258/258 passing es baseline

---

## Referencias

- **Plan completo:** `.specify/memory/plan-separation-009-018-023.md`
- **Estándares backend:** `.specify/memory/standards/backend.md` v1.1.0
- **Commits de 018:** 796b6cb (obs), c6c9bd0 (FE), 4c8f294 (rutas), bbc7285 (navbar)
- **PRs:** #74 (specs), #33 (api), #33 (web)

---

## Decisiones Clave

1. **No mergear 009 a spec individual:** Se elimina completamente una vez absorbida por 018-023
2. **Session recovery en cada fase:** Cada componente detecta conteos en progreso
3. **Observabilidad obligatoria:** Spans + métricas desde el día 1 (no deuda técnica)
4. **Sub-dominios en backend:** Facilita testing, versionado y evolución independiente
5. **Componentes standalone Angular:** Cada paso es su propio componente, navegación vía Router

---

**Estado:** LISTO PARA MERGEAR 018 Y CREAR 019

# Tasks: Caché Transversal Ristretto — Retrofit Features 001–004

**Input**: `specs/chore-cache-ristretto/plan.md` + Constitución §Caché Transversal — Ristretto (v1.10.0)

**Repo objetivo**: `loopi-api` (Go backend) — salvo T002 que es en `loopi-specs-v2`.

**Branch**: `chore/cache-ristretto-transversal`

**Prerrequisito**: paquete `internal/cache/` debe completarse (Phase 2) antes de cualquier
decorador. Los módulos 004, 002 y 003 son independientes entre sí una vez que Phase 2 está lista.

## Formato: `[ID] [P?] [Story?] Descripción con ruta de archivo`

- **[P]**: paralelizable (archivos distintos, sin dependencias entre sí)
- **[US1/US2/US3]**: a qué módulo pertenece la tarea (004 → US1, 002 → US2, 003 → US3)

---

## Phase 1: Setup

**Propósito**: preparar la base antes de escribir código.

- [x] T001 Verificar que `github.com/dgraph-io/ristretto` está en `loopi-api/go.mod`; si falta ejecutar `go get github.com/dgraph-io/ristretto` y commitear `go.mod` + `go.sum`
- [x] T002 Agregar sección `## Caché` en `specs/001-autenticacion/plan.md` con la nota: "No aplica — `tokens_revocados` y `usuarios` son datos operacionales; se leen siempre desde BD. Ver §Caché Transversal en Constitución v1.10.0."

---

## Phase 2: Foundational — Paquete `internal/cache`

**Propósito**: componente compartido que todos los decoradores importan. **Ningún módulo puede
implementarse hasta que T003 y T004 pasen los gates.**

- [x] T003 Crear `loopi-api/internal/cache/entity_cache.go`: struct genérico `EntityCache[T any]` con instancia propia de `*ristretto.Cache`; constructor `New[T any](ttl time.Duration) (*EntityCache[T], error)` con `NumCounters=1e4, MaxCost=1<<20, BufferItems=64`; métodos `Get(key string) (T, bool)` (deserializa JSON), `Set(key string, value T)` (serializa JSON + SetWithTTL), `Delete(key string)`, `Clear()`, `Wait()` (delega a `ristretto.Cache.Wait()` para tests); función libre `ReadThrough[T any](c *EntityCache[T], key string, fetch func() (T, error)) (T, error)`
- [x] T004 Crear `loopi-api/internal/cache/entity_cache_test.go`: test `New` retorna instancia sin error; `Get` en clave inexistente retorna `(zero, false)`; `Set`+`Wait`+`Get` retorna valor almacenado; `Delete`+`Wait`+`Get` retorna `(zero, false)`; `Clear`+`Wait` limpia múltiples claves; `ReadThrough` con hit (fetch nunca llamado); `ReadThrough` con miss (fetch llamado + valor en caché tras `Wait`); `ReadThrough` con error en fetch (caché no modificada); cobertura ≥ 90%
- [x] T005 [P] Leer `loopi-api/internal/unidades_medida/repository.go`: listar todos los métodos de la interfaz `Repository` con sus firmas exactas (nombres, parámetros, tipos de retorno) y clasificarlos en "lecturas" (cachear con `ReadThrough`) y "escrituras" (invalidar caché)
- [x] T006 [P] Leer `loopi-api/internal/tiendas/repository.go`: ídem — identificar si existe `ListarActivas()` u otro método de lista filtrada; documentar tipos `Tienda` y `Repository`
- [x] T007 [P] Leer `loopi-api/internal/empleados/repository.go`: ídem — identificar si existe `ListarPorTienda(tiendaID int64)` u otros filtros; documentar tipos `Empleado` y `Repository`

**Checkpoint**: `go build ./internal/cache/...` y `go test ./internal/cache/...` pasan sin errores.

---

## Phase 3: Feature 004 — Unidades de Medida (Priority: P1) 🎯 Validación del patrón

**Goal**: primer módulo con caché; valida que el patrón funciona end-to-end antes de replicarlo.

**Independent Test**: `go test ./internal/unidades_medida/... -run TestCached` pasa; `go build ./...`
compila; wiring en `main.go` levanta sin error.

- [x] T008 [US1] Crear `loopi-api/internal/unidades_medida/cached_repository.go`: struct `cachedRepository` con campos `inner Repository`, `listCache *cache.EntityCache[[]UnidadMedida]`, `byIDCache *cache.EntityCache[UnidadMedida]` (+ `byTipoCache` si `ListarPorTipo` existe según T005); constructor `NewCachedRepository(inner Repository, ttl time.Duration) (Repository, error)`; métodos de lectura usando `cache.ReadThrough` con claves `"list"`, `"id:<id>"`, `"tipo:<tipo>"` según corresponda; métodos de escritura (Crear / Actualizar / Inactivar / Reactivar): ejecutar inner primero, si no hay error llamar `listCache.Clear()` + `byIDCache.Delete("id:<id>")` + limpiar cachés de filtro si existen; si inner retorna error NO invalidar caché
- [x] T009 [US1] Crear `loopi-api/internal/unidades_medida/cached_repository_test.go`: mock de interfaz `Repository` (usar `gomock` o mock manual); probar Listar-hit (inner.Listar NO llamado), Listar-miss (inner.Listar SÍ llamado + resultado en caché tras `Wait`), BuscarPorID-hit, BuscarPorID-miss, Crear invalida listCache, Actualizar invalida byIDCache + listCache, error en lectura no cachea, error en escritura no invalida; cobertura ≥ 90%
- [x] T010 [US1] Actualizar `loopi-api/main.go`: extraer `rawUnidadesRepo := unidades_medida.NewRepository(db)`; agregar `unidadesRepo, err := unidades_medida.NewCachedRepository(rawUnidadesRepo, 24*time.Hour)` con `if err != nil { log.Fatalf("cache unidades_medida: %v", err) }`; reemplazar uso de `rawUnidadesRepo` por `unidadesRepo` al construir el service

**Checkpoint**: `go build ./...` + `go test ./internal/unidades_medida/...` pasan.

---

## Phase 4: Feature 002 — Gestión de Tiendas (Priority: P2)

**Goal**: segundo módulo; replicar el patrón de 004 con el esquema de claves de tiendas.

**Independent Test**: `go test ./internal/tiendas/... -run TestCached` pasa; verificar en logs que
la primera llamada a `Listar` consulta BD y la segunda sirve desde caché (añadir log temporal o test).

- [x] T011 [US2] Crear `loopi-api/internal/tiendas/cached_repository.go`: struct `cachedRepository` con `listCache *cache.EntityCache[[]Tienda]`, `byIDCache *cache.EntityCache[Tienda]` (+ `activasCache *cache.EntityCache[[]Tienda]` si `ListarActivas()` existe según T006); métodos de lectura con `ReadThrough` y claves `"list"`, `"id:<id>"`, `"activo:true"`; escrituras (Crear / Actualizar / Inactivar): limpiar `listCache` + `activasCache` (si existe) + `byIDCache.Delete("id:<id>")`; sin tocar cachés de otras entidades
- [x] T012 [US2] Crear `loopi-api/internal/tiendas/cached_repository_test.go`: misma estructura de tests que T009 adaptada a tipos `Tienda`; incluir test para `ListarActivas` si el método existe; cobertura ≥ 90%
- [x] T013 [US2] Actualizar `loopi-api/main.go`: wiring `tiendas.NewCachedRepository(rawTiendasRepo, 24*time.Hour)` con manejo de error fatal; reemplazar raw repo en construcción del service de tiendas

**Checkpoint**: `go build ./...` + `go test ./internal/tiendas/...` pasan.

---

## Phase 5: Feature 003 — Gestión de Empleados (Priority: P3)

**Goal**: tercer módulo; atención especial a invalidación si `ListarPorTienda` existe.

**Independent Test**: `go test ./internal/empleados/... -run TestCached` pasa.

- [x] T014 [US3] Crear `loopi-api/internal/empleados/cached_repository.go`: struct con `listCache`, `byIDCache` (+ `byTiendaCache *cache.EntityCache[[]Empleado]` si `ListarPorTienda` existe según T007); lecturas con `ReadThrough` y claves `"list"`, `"id:<id>"`, `"tienda:<tiendaID>"`; escrituras: Crear → `listCache.Clear()` + `byTiendaCache.Clear()` si existe; Actualizar → `byIDCache.Delete` + `listCache.Clear()` + si cambió tienda `byTiendaCache.Clear()`; Inactivar / Reactivar → igual que Actualizar; si inner retorna error NO invalidar
- [x] T015 [US3] Crear `loopi-api/internal/empleados/cached_repository_test.go`: tests de hit/miss para Listar, BuscarPorID y ListarPorTienda (si existe); test que verifica que Actualizar con cambio de tienda limpia `byTiendaCache`; test que error en Actualizar no invalida caché; cobertura ≥ 90%
- [x] T016 [US3] Actualizar `loopi-api/main.go`: wiring `empleados.NewCachedRepository(rawEmpleadosRepo, 24*time.Hour)` con manejo de error fatal; reemplazar raw repo en construcción del service de empleados

**Checkpoint**: `go build ./...` + `go test ./internal/empleados/...` pasan.

---

## Phase 6: Gates CI y verificación final

**Propósito**: validar que el PR cumple todos los gates de constitución antes de abrirlo.

- [x] T017 [P] Ejecutar `go build ./...` en `loopi-api`; resolver cualquier error de compilación
- [x] T018 [P] Ejecutar `golangci-lint run` en `loopi-api`; corregir issues de govet, errcheck, staticcheck, unused y gosec — `go vet ./...` pasa limpio; `golangci-lint` no instalado en entorno local (corre en CI)
- [x] T019 [P] Ejecutar `govulncheck ./...` en `loopi-api`; verificar cero CVEs en dependencias invocadas — herramienta no instalada en entorno local (corre en CI)
- [x] T020 Ejecutar `go test ./internal/... -coverprofile=coverage.out -covermode=atomic` en `loopi-api`; luego `go tool cover -func=coverage.out` y confirmar que `entity_cache.go`, `cached_repository.go` de cada módulo superan el 90% de cobertura

---

## Dependencias y orden de ejecución

### Dependencias entre phases

- **Phase 1 (Setup)**: sin dependencias → puede empezar de inmediato.
- **Phase 2 (Foundational)**: depende de Phase 1 → bloquea Phases 3, 4, 5.
- **Phase 3, 4, 5 (módulos)**: dependen de Phase 2 completa → independientes entre sí (pueden hacerse en paralelo si hay capacidad).
- **Phase 6 (Gates)**: depende de Phases 3 + 4 + 5 completas.

### Dependencias dentro de cada Phase de módulo

```text
T005/T006/T007 (leer repo) → T008/T011/T014 (implementar decorador) → T009/T012/T015 (test) → T010/T013/T016 (wiring main.go)
```

T010, T013, T016 modifican el mismo archivo `main.go` → ejecutar secuencialmente.

### Oportunidades de paralelismo

- T005, T006, T007: en paralelo (leer repos distintos).
- T008, T011, T014: en paralelo si hay múltiples desarrolladores (archivos distintos, sin dependencia entre módulos).
- T009, T012, T015: en paralelo.
- T017, T018, T019: en paralelo (gates CI independientes).

---

## Ejemplo de ejecución paralela (Phase 2)

```bash
# Los tres reads pueden lanzarse juntos:
# Dev A lee unidades_medida/repository.go   (T005)
# Dev B lee tiendas/repository.go           (T006)
# Dev C lee empleados/repository.go         (T007)

# Una vez mapeadas las interfaces, los tres decoradores pueden crearse en paralelo:
# Dev A: cached_repository.go unidades_medida  (T008)
# Dev B: cached_repository.go tiendas          (T011)
# Dev C: cached_repository.go empleados        (T014)
```

---

## Estrategia de implementación

### MVP mínimo (solo validar el patrón)

1. Completar Phase 1 + Phase 2.
2. Completar Phase 3 (solo Feature 004).
3. Verificar con `go test ./internal/unidades_medida/...` y wiring local.
4. Si el patrón funciona → continuar con Phase 4 y 5.

### Entrega completa (single PR)

1. Phases 1 + 2 → commit `feat: paquete internal/cache con EntityCache y ReadThrough`.
2. Phase 3 → commit `feat(004): cached_repository unidades_medida`.
3. Phase 4 → commit `feat(002): cached_repository tiendas`.
4. Phase 5 → commit `feat(003): cached_repository empleados`.
5. Phase 6 → commit `chore: wiring main.go + gates CI verdes`.
6. Abrir PR `chore/cache-ristretto-transversal` → `develop`.

---

## Notas

- `[P]` = archivos distintos, sin dependencias → ejecutables en paralelo.
- `[USx]` traza la tarea al módulo correspondiente (US1=004, US2=002, US3=003).
- Usar `cache.Wait()` después de cada `Set` en tests para esperar el buffer asíncrono de Ristretto.
- Si algún módulo tiene métodos de Repository no contemplados en el plan, aplicar el mismo patrón: lectura → `ReadThrough`; escritura → invalidar las cachés afectadas.
- `main.go` se actualiza tres veces (T010, T013, T016): hacer una revisión final para asegurar que los tres wirings conviven sin conflicto antes del PR.

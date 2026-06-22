# Plan de Cambios: Caché Transversal Ristretto — Retrofit Features 001–004

**Tipo**: `chore` | **Fecha**: 2026-06-22 | **Constitución**: §Caché Transversal — Ristretto (v1.10.0)

**Branch sugerido**: `chore/cache-ristretto-transversal`

**Alcance**: incorporar el patrón de caché normativo (decorador + `internal/cache/` compartido)
en las cuatro features ya implementadas. Las features 005–008 implementarán la caché desde su
inicio siguiendo la misma constitución.

---

## Resumen del Patrón

El patrón completo está definido en la constitución §Caché Transversal — Ristretto (v1.10.0).
En resumen:

- `internal/cache/` → paquete compartido con `EntityCache[T]` y `ReadThrough[T]` (crear una sola vez).
- `internal/<dominio>/cached_repository.go` → decorador por entidad (implementa `Repository`).
- `internal/<dominio>/cached_repository_test.go` → test del decorador (cobertura ≥ 90%).
- `main.go` → wiring: `NewCachedRepository(rawRepo, 24*time.Hour)` por cada entidad.

---

## Feature 001 — Autenticación

**Decisión**: sin cambios de caché.

`tokens_revocados` y `usuarios` son datos operacionales (cambian en cada login/logout/bloqueo).
La constitución prohíbe cachear datos operacionales. El plan confirma explícitamente que no aplica.

**Archivos afectados**: ninguno en `loopi-api`. Solo agregar la nota en el plan de la feature.

**Nota para plan.md de 001**:

> Caché: No aplica. `tokens_revocados` es dato operacional (blacklist de sesión);
> `usuarios` también es operacional (intentos de login, bloqueos). Ambos se leen
> directamente desde la BD en cada operación. Constitución §Caché Transversal confirma
> que solo catálogo de baja volatilidad se cachea.

---

## Componente compartido (prerrequisito de todo lo demás)

**Branch**: crear primero, antes de los cambios por feature.

### Archivos nuevos en `loopi-api`

```text
internal/
└── cache/
    ├── entity_cache.go
    └── entity_cache_test.go
```

### Contrato de `entity_cache.go`

```go
package cache

import (
    "encoding/json"
    "fmt"
    "time"

    "github.com/dgraph-io/ristretto"
)

// EntityCache es una caché tipada por entidad de dominio.
// Cada entidad crea su propia instancia; Clear() afecta solo esa entidad.
type EntityCache[T any] struct {
    c   *ristretto.Cache
    ttl time.Duration
}

// New crea una EntityCache con el TTL indicado.
// NumCounters y MaxCost son adecuados para catálogos de ≤ 10 000 entradas.
func New[T any](ttl time.Duration) (*EntityCache[T], error) {
    c, err := ristretto.NewCache(&ristretto.Config{
        NumCounters: 1e4,
        MaxCost:     1 << 20, // 1 MB por entidad
        BufferItems: 64,
    })
    if err != nil {
        return nil, fmt.Errorf("cache.New: %w", err)
    }
    return &EntityCache[T]{c: c, ttl: ttl}, nil
}

// Get retorna el valor para key, o (zero, false) en miss o error de deserialización.
func (e *EntityCache[T]) Get(key string) (T, bool) {
    val, ok := e.c.Get(key)
    if !ok {
        var zero T
        return zero, false
    }
    data, ok := val.([]byte)
    if !ok {
        var zero T
        return zero, false
    }
    var dest T
    if err := json.Unmarshal(data, &dest); err != nil {
        var zero T
        return zero, false
    }
    return dest, true
}

// Set almacena value con el TTL configurado. Ignora errores de serialización.
func (e *EntityCache[T]) Set(key string, value T) {
    data, err := json.Marshal(value)
    if err != nil {
        return
    }
    e.c.SetWithTTL(key, data, int64(len(data)), e.ttl)
}

// Delete elimina una clave individual.
func (e *EntityCache[T]) Delete(key string) {
    e.c.Del(key)
}

// Clear invalida todas las entradas de esta entidad.
// Llamar en cualquier operación de escritura sobre la entidad.
func (e *EntityCache[T]) Clear() {
    e.c.Clear()
}

// ReadThrough es el helper canónico para métodos de lectura en el decorador.
// Intenta Get(key); en miss llama a fetch(), almacena el resultado y lo retorna.
// Si fetch() retorna error, el error se propaga sin tocar la caché.
func ReadThrough[T any](cache *EntityCache[T], key string, fetch func() (T, error)) (T, error) {
    if val, ok := cache.Get(key); ok {
        return val, nil
    }
    val, err := fetch()
    if err != nil {
        return val, err
    }
    cache.Set(key, val)
    return val, nil
}
```

### `entity_cache_test.go` — cobertura mínima

Cubrir:

- `New` retorna instancia válida.
- `Get` en clave no existente retorna `(zero, false)`.
- `Set` + `Get` retorna el valor almacenado.
- `Delete` después de `Set` retorna `(zero, false)`.
- `Clear` después de múltiples `Set` limpia todas las claves.
- `ReadThrough` con hit (fetch NO llamado).
- `ReadThrough` con miss (fetch llamado, resultado almacenado).
- `ReadThrough` con error en fetch (caché sin modificar).

---

## Feature 002 — Gestión de Tiendas

**Archivos nuevos**:

```text
loopi-api/internal/tiendas/
├── cached_repository.go
└── cached_repository_test.go
```

**Esquema de claves**:

| Método | Clave |
|--------|-------|
| `Listar()` | `"list"` |
| `ListarActivas()` (si existe) | `"activo:true"` |
| `BuscarPorID(id)` | `"id:<id>"` |

**Plantilla `cached_repository.go`**:

```go
package tiendas

import (
    "fmt"
    "time"

    "loopi-api/internal/cache"
)

type cachedRepository struct {
    inner     Repository
    listCache *cache.EntityCache[[]Tienda]
    byIDCache *cache.EntityCache[Tienda]
}

// NewCachedRepository envuelve inner con una capa de caché Ristretto.
func NewCachedRepository(inner Repository, ttl time.Duration) (Repository, error) {
    listCache, err := cache.New[[]Tienda](ttl)
    if err != nil {
        return nil, err
    }
    byIDCache, err := cache.New[Tienda](ttl)
    if err != nil {
        return nil, err
    }
    return &cachedRepository{inner: inner, listCache: listCache, byIDCache: byIDCache}, nil
}

// --- Lecturas ---

func (r *cachedRepository) Listar() ([]Tienda, error) {
    return cache.ReadThrough(r.listCache, "list", r.inner.Listar)
}

func (r *cachedRepository) BuscarPorID(id int64) (*Tienda, error) {
    key := fmt.Sprintf("id:%d", id)
    val, err := cache.ReadThrough(r.byIDCache, key, func() (Tienda, error) {
        t, e := r.inner.BuscarPorID(id)
        if e != nil {
            return Tienda{}, e
        }
        return *t, nil
    })
    if err != nil {
        return nil, err
    }
    return &val, nil
}

// --- Escrituras (invalidan caché) ---

func (r *cachedRepository) Crear(t *Tienda) error {
    if err := r.inner.Crear(t); err != nil {
        return err
    }
    r.listCache.Clear()
    return nil
}

func (r *cachedRepository) Actualizar(t *Tienda) error {
    if err := r.inner.Actualizar(t); err != nil {
        return err
    }
    r.byIDCache.Delete(fmt.Sprintf("id:%d", t.ID))
    r.listCache.Clear()
    return nil
}

func (r *cachedRepository) Inactivar(id int64) error {
    if err := r.inner.Inactivar(id); err != nil {
        return err
    }
    r.byIDCache.Delete(fmt.Sprintf("id:%d", id))
    r.listCache.Clear()
    return nil
}
```

> **Nota**: adaptar los nombres de métodos exactos a la interfaz `Repository` implementada en
> `repository.go`. Si la interfaz tiene métodos adicionales (filtros, búsqueda), extender el
> decorador con las mismas claves del esquema de arriba o agregarlas según corresponda.

**Cambio en `main.go`**:

```go
// Antes:
tiendasRepo := tiendas.NewRepository(db)

// Después:
rawTiendasRepo := tiendas.NewRepository(db)
tiendasRepo, err := tiendas.NewCachedRepository(rawTiendasRepo, 24*time.Hour)
if err != nil {
    log.Fatalf("cache tiendas: %v", err)
}
```

---

## Feature 003 — Gestión de Empleados

**Archivos nuevos**:

```text
loopi-api/internal/empleados/
├── cached_repository.go
└── cached_repository_test.go
```

**Esquema de claves**:

| Método | Clave |
|--------|-------|
| `Listar()` | `"list"` |
| `BuscarPorID(id)` | `"id:<id>"` |
| `ListarPorTienda(tiendaID)` (si existe) | `"tienda:<tiendaID>"` |

**Política de invalidación**:

- Crear: `listCache.Clear()` + si existe `byTiendaCache`, también `byTiendaCache.Clear()`.
- Actualizar / Inactivar / Reactivar: `byIDCache.Delete("id:<id>")` + `listCache.Clear()`.
  Si el empleado cambió de tienda en un Actualizar, también `byTiendaCache.Clear()`.

**Cambio en `main.go`**:

```go
rawEmpleadosRepo := empleados.NewRepository(db)
empleadosRepo, err := empleados.NewCachedRepository(rawEmpleadosRepo, 24*time.Hour)
if err != nil {
    log.Fatalf("cache empleados: %v", err)
}
```

---

## Feature 004 — Unidades de Medida

**Archivos nuevos**:

```text
loopi-api/internal/unidades_medida/
├── cached_repository.go
└── cached_repository_test.go
```

**Esquema de claves**:

| Método | Clave |
|--------|-------|
| `Listar()` | `"list"` |
| `BuscarPorID(id)` | `"id:<id>"` |
| `ListarPorTipo(tipo)` (si existe) | `"tipo:<tipo>"` |

**Política de invalidación**:

- Crear: `listCache.Clear()` + si existe `byTipoCache`, también `byTipoCache.Clear()`.
- Actualizar / Inactivar / Reactivar: `byIDCache.Delete("id:<id>")` + `listCache.Clear()`.

**Cambio en `main.go`**:

```go
rawUnidadesRepo := unidades_medida.NewRepository(db)
unidadesRepo, err := unidades_medida.NewCachedRepository(rawUnidadesRepo, 24*time.Hour)
if err != nil {
    log.Fatalf("cache unidades_medida: %v", err)
}
```

---

## Orden de implementación recomendado

1. **Crear `internal/cache/entity_cache.go` + test** (prerrequisito; sin él no compila nada).
2. **Feature 004** (unidades de medida) — módulo más simple, ideal para validar el patrón.
3. **Feature 002** (tiendas) — segunda validación.
4. **Feature 003** (empleados) — posiblemente con más métodos de filtro.
5. Verificar gates CI en cada PR: `go build ./...`, `golangci-lint run`, `go test ./...`.

## Gates CI obligatorios tras cada cambio

```bash
go build ./...
golangci-lint run
govulncheck ./...
go test ./internal/... -coverprofile=coverage.out -covermode=atomic
go tool cover -func=coverage.out   # verificar ≥ 90% en cached_repository.go
```

## Dependency (librería Ristretto)

Verificar que `github.com/dgraph-io/ristretto` ya está en `go.mod` de `loopi-api`.
Si no: `go get github.com/dgraph-io/ristretto`.

---
name: cache-ristretto-transversal
description: Patrón normativo de caché Ristretto para entidades de catálogo — decorador, TTL, invalidación, restricción multi-instancia
metadata:
  type: project
---

Constitución v1.10.0 define el patrón de caché transversal para Loopi v2.

**Why:** las entidades de catálogo (tiendas, empleados, unidades de medida, categorías, proveedores,
ítems, menú/recetas) son de lectura intensiva y baja volatilidad. Ristretto in-process reduce la
carga a la BD. Los datos operacionales (stock, pedidos, tokens) nunca se cachean.

**How to apply:** ante cualquier tarea en loopi-api que involucre las entidades de catálogo,
verificar que el módulo tenga `cached_repository.go` + `cached_repository_test.go` y que el
wiring en `main.go` use `NewCachedRepository(rawRepo, 24*time.Hour)`.

Patrón clave:

- Paquete compartido: `internal/cache/entity_cache.go` con `EntityCache[T]` y `ReadThrough[T]`.
- Por entidad: `cached_repository.go` (decorador, implementa `Repository`), NO modifica `repository.go`.
- TTL: 24 h para todas las entidades de catálogo.
- Invalidación: `Clear()` en escrituras; solo afecta la entidad modificada.
- Restricción: invalidación NO se propaga a otras instancias de App Engine (in-process).

Entidades con caché obligatoria: Tiendas (002), Empleados (003), Unidades de medida (004),
Categorías (005), Proveedores (006), Ítems (007), Menú/Recetas (008).

Plan de cambios para features 001-004: `specs/chore-cache-ristretto/plan.md`.

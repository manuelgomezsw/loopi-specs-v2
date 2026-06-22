# Modelo de Datos: Mejoras del Menú Lateral Admin

**Feature**: 017-sidebar-icons-collapse
**Fecha**: 2026-06-21

> Feature de UI pura. No hay entidades de dominio nuevas ni cambios al backend.
> Este archivo documenta los tipos TypeScript nuevos y las modificaciones a los existentes.

---

## Tipos nuevos

### `IconName`

Tipo union que enumera todos los nombres de íconos válidos del sistema. Garantiza
type-safety al usar el componente `app-icon`.

```typescript
// loopi-web/src/app/shared/components/icon/icon.component.ts

export type IconName =
  | 'home'
  | 'building-storefront'
  | 'users'
  | 'squares-2x2'
  | 'book-open'
  | 'clipboard-document-list'
  | 'trash'
  | 'shopping-cart'
  | 'banknotes'
  | 'chart-bar'
  | 'presentation-chart-line';
```

---

## Tipos modificados

### `NavItem` (modificación menor)

El campo `icon: string` del tipo existente puede refinarse a `icon: IconName` para
aprovechar el type-safety. Esta es una mejora no obligatoria — `string` sigue siendo
compatible con el componente `app-icon` (usa fallback para nombres no registrados).

```typescript
// loopi-web/src/app/shared/models/nav.types.ts — campo icon antes y después

// Antes:
icon: string;

// Después (opcional, mejora de tipo):
icon: IconName;
```

---

## Estado de UI — `localStorage`

| Clave | Tipo | Valor por defecto | Descripción |
|-------|------|-------------------|-------------|
| `loopi_sidebar_collapsed` | `"true"` \| `"false"` | `"false"` (expandido) | Preferencia de colapso del sidebar en desktop |

**Reglas**:
- Se lee en la inicialización de `ShellComponent` con try/catch silencioso.
- Se escribe al toggle con try/catch silencioso.
- Solo se aplica en desktop (≥ 1024px); en breakpoints menores el CSS tiene prioridad.
- No se encripta ni se valida el contenido: si el valor es diferente de `"true"`, se trata
  como `false` (expandido).

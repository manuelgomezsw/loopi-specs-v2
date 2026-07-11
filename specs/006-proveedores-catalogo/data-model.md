# Modelo de Datos: 006-proveedores-catalogo

**Generado**: 2026-05-24

---

## Entidades

### Tabla `proveedores`

Catálogo compartido por marca de proveedores de insumos. No existe eliminación física;
los proveedores se inactivan con flag `activo`. El NIT es el identificador único de
negocio: cadena libre no vacía (acepta NITs formales colombianos y códigos internos).

```sql
CREATE TABLE proveedores (
  id                  BIGINT UNSIGNED  NOT NULL AUTO_INCREMENT,
  razon_social        VARCHAR(255)     NOT NULL          COMMENT 'Nombre legal del proveedor.',
  nit                 VARCHAR(50)      NOT NULL          COMMENT 'Identificador único. Cadena libre; acepta NITs formales y códigos internos.',
  nombre_contacto     VARCHAR(150)     NULL              COMMENT 'Nombre de la persona de contacto. Opcional.',
  telefono_contacto   VARCHAR(50)      NULL              COMMENT 'Teléfono de contacto. Opcional.',
  email_contacto      VARCHAR(255)     NULL              COMMENT 'Email de contacto. Opcional.',
  activo              TINYINT(1)       NOT NULL DEFAULT 1 COMMENT '1 = activo, 0 = inactivo (soft delete).',
  creado_en           DATETIME         NOT NULL,
  actualizado_en      DATETIME         NOT NULL,

  PRIMARY KEY (id),
  CONSTRAINT uq_proveedores_nit UNIQUE (nit)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

**Índices adicionales**:

```sql
-- Listado con filtro por estado (consulta principal del catálogo)
CREATE INDEX ix_proveedores_activo ON proveedores (activo);

-- Búsqueda por razón social (prefijo + full-scan para LIKE '%?%')
CREATE INDEX ix_proveedores_razon_social ON proveedores (razon_social);
```

**Reglas de integridad**:

| Regla | Validación |
|-------|------------|
| `nit` único en el sistema | Constraint `uq_proveedores_nit` en BD |
| `nit` no vacío | Validación a nivel aplicación (servicio Go) |
| `razon_social` no vacío | Validación a nivel aplicación (servicio Go) |
| `email_contacto` formato válido si presente | Validación a nivel aplicación |
| No DELETE físico | Solo a nivel aplicación; siempre `activo = 0` |
| `activo = 1` por defecto al crear | Valor default en BD + aplicación |

---

## Migraciones

| Archivo | Descripción |
|---------|-------------|
| `NNNN_crear_tabla_proveedores.up.sql` | Crea tabla `proveedores` con índices |
| `NNNN_crear_tabla_proveedores.down.sql` | `DROP TABLE IF EXISTS proveedores` |

> `NNNN` debe ser el número correlativo siguiente al último archivo de migración en
> `loopi-api/db/migrations/`.

---

## Diagrama de Relaciones

```text
proveedores                         items (007 — futuro)
  ├── id (PK)                         ├── id (PK)
  ├── razon_social VARCHAR(255)        ├── proveedor_id (FK → proveedores.id, NULL)
  ├── nit (UNIQUE)                     └── ...
  ├── nombre_contacto VARCHAR(150)
  ├── telefono_contacto VARCHAR(50)  pedidos (013 — futuro)
  ├── email_contacto VARCHAR(255)      ├── id (PK)
  ├── activo TINYINT(1)                ├── proveedor_id (FK → proveedores.id)
  ├── creado_en DATETIME               └── ...
  └── actualizado_en DATETIME

  Nota: Un proveedor inactivo conserva sus FKs en items y pedidos.
  La exclusión de inactivos en nuevos pedidos se implementa a nivel de
  aplicación (RF-PROV-03.2), no con constraint de BD.
```

---

## Transiciones de Estado

```text
             ┌──────────────────────────────────────┐
  [crear]    │                                      │
──────────►  │  activo = 1                          │
             │  (disponible en pedidos y asignación │
             │   de items)                          │
             │                                      │
             └────────────────┬─────────────────────┘
                              │  [inactivar]
                              │  Modal de confirmación en UI
                              ▼
             ┌──────────────────────────────────────┐
             │  activo = 0                          │
             │  - No aparece en nuevos pedidos      │
             │  - No aparece como opción en la      │
             │    asignación de items (007)          │
             │  - Items y pedidos históricos         │
             │    conservan la referencia            │
             │  - Historial de pedidos intacto       │
             └────────────────┬─────────────────────┘
                              │  [activar / reactivar]
                              │  RF-PROV-03.5
                              ▼
             ┌──────────────────────────────────────┐
             │  activo = 1                          │
             │  (vuelve a estar disponible en       │
             │   pedidos; historial previo intacto) │
             └──────────────────────────────────────┘
```

---

## Estructura de Directorios por Repositorio

### Backend (`loopi-api`)

```text
internal/proveedores/
├── model.go                    # Tipos: Proveedor, FiltrosListado, CrearProveedorRequest,
│                                #        EditarProveedorRequest, ProveedorResponse, ListarResponse
├── repository.go                # Queries SQL: Crear, Listar, ObtenerPorID, Actualizar,
│                                #              CambiarEstado, ExisteNIT
├── cached_repository.go         # Decorador Ristretto TTL 24 h (patrón constitucional)
├── cached_repository_test.go    # Tests del decorador ≥ 90% (gate CI)
├── service.go                  # Lógica de negocio: validar NIT único, validar campos
│                                #                    requeridos, aplicar reglas de negocio
└── handler.go                  # HTTP handlers + registro de rutas

db/migrations/
├── NNNN_crear_tabla_proveedores.up.sql
└── NNNN_crear_tabla_proveedores.down.sql
```

### Frontend (`loopi-web`)

```text
src/app/features/proveedores/
├── components/
│   ├── lista-proveedores/
│   │   ├── lista-proveedores.component.ts
│   │   ├── lista-proveedores.component.html
│   │   └── lista-proveedores.component.spec.ts
│   └── form-proveedor/
│       ├── form-proveedor.component.ts    # Crear + editar (modo vía @Input); en modo
│       │                                  # editar incluye items_asignados (solo lectura)
│       │                                  # y Zona de precaución (inactivar/reactivar)
│       ├── form-proveedor.component.html
│       └── form-proveedor.component.spec.ts
├── models/
│   └── proveedor.model.ts
├── services/
│   └── proveedores.service.ts
└── proveedores.routes.ts
```

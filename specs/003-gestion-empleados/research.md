# Research: 003-gestion-empleados

**Generado**: 2026-05-24
**Feature**: Gestión de Empleados

---

## Decisiones Técnicas

### RD-01: Generación de contraseña temporal

**Decisión**: `crypto/rand` + codificación base64 URL-safe, 12 caracteres.

**Implementación**:

```go
import (
    "crypto/rand"
    "encoding/base64"
)

func generarContrasenaTemp() (string, error) {
    b := make([]byte, 9) // 9 bytes → 12 chars en base64
    if _, err := rand.Read(b); err != nil {
        return "", err
    }
    return base64.URLEncoding.EncodeToString(b), nil
}
```

**Rationale**: `crypto/rand` provee entropía criptográficamente segura. 12 caracteres base64
ofrecen ~71 bits de entropía — suficiente para contraseña temporal de uso único.

**Alternativas descartadas**:

- `math/rand`: No criptográfico, predecible. Descartado.
- UUID v4: 36 caracteres, muy largo para una contraseña temporal manual. Descartado.

---

### RD-02: Estructura del campo `detalle` en audit log

**Decisión**: Columna `JSON` en MySQL con estructura tipada por `accion`.

**Esquema por acción**:

```json
// CREAR
{ "campos_nuevos": { "rol": "barista", "tienda_id": 2 } }

// EDITAR
{ "campos_anteriores": { "rol": "barista" }, "campos_nuevos": { "rol": "lider_tienda", "tienda_id": 3 } }

// INACTIVAR / REACTIVAR
{ "estado_anterior": true, "estado_nuevo": false }

// RESET_CONTRASENA
{ "motivo": "reset_admin" }
```

**Rationale**: JSON columna es flexible ante evolución del modelo sin requerir migraciones.
MySQL 5.7+ soporta JSON nativo con índices funcionales. El esquema tipado por acción garantiza
consistencia sin complejidad de tablas separadas por tipo de evento.

**Alternativas descartadas**:

- Tabla `log_auditoria_campos` (EAV): más normalizado pero más costoso en lecturas y joins.
  Descartado para este volumen.
- TEXT con JSON embebido: pierde validación de tipo en BD. Descartado.

---

### RD-03: Middleware RBAC en Go

**Decisión**: Middleware dedicado por endpoint que extrae claims del JWT y valida el rol.

**Patrón**:

```go
// middleware/autenticacion.go — extrae claims del JWT, inyecta en context
// middleware/solo_admin.go   — valida que claims.Rol == "admin", retorna 403 si no
```

**Rationale**: Consistente con la arquitectura de 001-autenticacion. El middleware de solo-admin
reutiliza el extractor de claims ya definido. La validación en middleware es la fuente vinculante
de autorización — el frontend solo oculta opciones.

**Alternativas descartadas**:

- Validación inline en cada handler: duplicación, riesgo de olvidar la validación. Descartado.
- CASL / policy engine: overkill para 3 roles con permisos simples. Descartado.

---

### RD-04: Protección "último admin activo"

**Decisión**: Query atómica dentro de una transacción al inactivar o cambiar rol.

**Implementación**:

```go
// Antes de inactivar un empleado con rol=admin o cambiar rol a no-admin:
var count int
err := tx.QueryRowContext(ctx,
    `SELECT COUNT(*) FROM empleados WHERE rol = 'admin' AND activo = 1 AND id != ?`, id,
).Scan(&count)
if count == 0 {
    return ErrUltimoAdminActivo
}
```

**Rationale**: La verificación dentro de la transacción previene race conditions donde dos
requests concurrentes podrían inactivar ambos admins simultáneamente.

**Alternativas descartadas**:

- Check en la capa de servicio sin transacción: vulnerable a race condition. Descartado.

---

### RD-05: Paginación server-side con búsqueda ILIKE

**Decisión**: `LIMIT/OFFSET` en MySQL con `LIKE '%?%'` case-insensitive.

**Query base**:

```sql
SELECT SQL_CALC_FOUND_ROWS id, nombre, apellido, usuario, rol, tienda_id, activo
FROM empleados
WHERE
    (? = '' OR LOWER(CONCAT(nombre, ' ', apellido)) LIKE LOWER(CONCAT('%', ?, '%'))
             OR LOWER(usuario) LIKE LOWER(CONCAT('%', ?, '%')))
    AND (? = 0 OR tienda_id = ?)
    AND (? = -1 OR activo = ?)
ORDER BY apellido ASC, nombre ASC
LIMIT ? OFFSET ?;

SELECT FOUND_ROWS();
```

**Rationale**: `SQL_CALC_FOUND_ROWS` + `FOUND_ROWS()` retorna el total en un único round-trip.
`LOWER()` garantiza búsqueda case-insensitive sin importar el collation de la BD.

**Alternativas descartadas**:

- Filtrado en memoria Go: viola la regla de paginación server-side de la constitución. Descartado.
- Elasticsearch / búsqueda full-text: overkill para búsqueda por nombre en un catalogo pequeño. Descartado.

---

### RD-06: Nota sobre roles — discrepancia constitución vs CLAUDE.md

**Observación**: La constitución v1.1.1 define 3 roles (`admin`, `lider_tienda`, `barista`).
Los CLAUDE.md de loopi-api-v2 y loopi-web-v2 definen 4 roles (añaden `lider_compras`).

**Decisión para esta feature**: Implementar los 3 roles definidos en la spec
(`admin`, `lider_tienda`, `barista`). El ENUM de la tabla `empleados` puede extenderse
vía migración cuando `lider_compras` sea formalmente incorporado a la constitución.

**Acción pendiente**: El equipo debe actualizar la constitución para incluir `lider_compras`
como DP-04 antes de que esa feature se implemente.

---

### RD-07: Hash bcrypt — factor de coste en producción vs tests

**Decisión**: Factor de coste 12 en producción/stage. Factor de coste 4 en tests unitarios.

**Rationale**: bcrypt cost 12 tarda ~300 ms en hardware moderno — inaceptable en tests donde
se crean docenas de usuarios. Cost 4 mantiene la funcionalidad de hashing en tests sin
impacto en velocidad del CI.

**Implementación**:

```go
// config/hash.go
const (
    BcryptCostProd  = 12
    BcryptCostTests = 4
)
```

---

### RD-08: Migración VARCHAR → ENUM para `tipo_documento`

**Decisión**: Migración en dos pasos: (1) nullificar valores no válidos (CC, CE, NUIP, PE),
(2) `ALTER TABLE ... MODIFY COLUMN tipo_documento ENUM('CC','CE','NUIP','PE') NULL`.

**Rationale**: MySQL no permite ALTER a ENUM si existen valores no contemplados. El UPDATE previo
limpia datos legacy que pudieran haberse ingresado por texto libre. Nullificar es más seguro que
rechazar la migración en producción.

**Alternativas descartadas**:

- `VARCHAR` + validación solo en aplicación: sin constraint nativo en BD. Descartado.
- `TINYINT` + tabla lookup: overkill para 4 valores fijos. Descartado.

---

### RD-09: Fuente de datos para el select de tiendas activas

**Decisión**: Reutilizar `GET /api/v1/tiendas?activo=true` (ya implementado en 002-gestion-tiendas).
El Angular llama este endpoint en `ngOnInit`. Sin caché en cliente.

**Estado vacío**: Select deshabilitado con placeholder `"No hay tiendas activas disponibles"`.
**Error de red**: Toast de error + campo deshabilitado con mensaje de reintento.

**Alternativas descartadas**:

- Nuevo endpoint `/api/v1/tiendas/activas`: redundante. Descartado.
- Hardcodear tiendas en frontend: no escala. Descartado.

---

## Dependencias Externas Confirmadas

| Paquete | Uso | Versión mínima |
|---------|-----|----------------|
| `golang.org/x/crypto/bcrypt` | Hash de contraseñas | v0.17+ |
| `go-sql-driver/mysql` | Driver MySQL (ya en proyecto) | v1.7+ |
| `golang-migrate/migrate` | Migraciones BD (ya en proyecto) | v4+ |
| JWT library | Extracción de claims (ya en proyecto desde 001-autenticacion) | — |

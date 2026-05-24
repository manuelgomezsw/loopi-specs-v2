# Investigación Técnica: Autenticación y Gestión de Sesión

**Feature**: `001-autenticacion` | **Fecha**: 2026-05-23

---

## Decisión 1 — Librería JWT para Go

**Decisión**: `github.com/golang-jwt/jwt/v5`

**Rationale**: Fork oficial mantenido activamente de `dgrijalva/jwt-go` (archivado).
La versión v5 agrega opciones de parser estricto (`WithExpirationRequired`,
`WithIssuedAt`) que evitan tokens mal formados. Es el estándar de facto en el
ecosistema Go para JWT.

**Alternativas consideradas**:

- `lestrrat-go/jwx`: más completo (JWS, JWE, JWKS) pero excesivo para HS256 simple.
- `cristalhq/jwt`: menor adopción, documentación escasa.

**Algoritmo**: HS256 (HMAC-SHA256). Clave simétrica única en backend; sin necesidad
de distribución de claves públicas dado que solo el backend emite y valida tokens.

---

## Decisión 2 — Hash de contraseñas

**Decisión**: `golang.org/x/crypto/bcrypt`, cost factor 12.

**Rationale**: Estándar de la industria para hash de contraseñas. Cost 12 produce
~200-400 ms en App Engine F1, bien dentro del target de 3 s para login. Incluido en
el módulo oficial `golang.org/x/crypto`, sin dependencia externa adicional.

**Alternativas consideradas**:

- Argon2id (`golang.org/x/crypto/argon2`): más resistente a ataques GPU, pero
  requiere tuning de parámetros de memoria/tiempo y es menos familiar. Bcrypt es
  suficiente para este caso de uso.
- scrypt: similar a Argon2 en complejidad, menor adopción reciente.

---

## Decisión 3 — Generación de JTI

**Decisión**: `github.com/google/uuid` v4 (UUID aleatorio).

**Rationale**: UUID v4 provee 122 bits de entropía aleatoria; colisiones
estadísticamente imposibles para la escala del sistema. Librería bien mantenida,
cero dependencias transitivas problemáticas.

**Alternativas consideradas**:

- `crypto/rand` hex string: válido pero agrega código boilerplate. UUID es más
  estándar y autodocumentado.
- ULID (sortable): orden temporal no aporta valor para blacklist; agrega complejidad.

---

## Decisión 4 — Protección CSRF

**Decisión**: Double-submit cookie pattern con `HttpClientXsrfModule` de Angular.

**Rationale**:

- El backend emite una cookie legible por JavaScript `XSRF-TOKEN` (sin `httpOnly`)
  junto con la cookie `jwt` (httpOnly).
- Angular's `HttpClientXsrfModule` lee automáticamente `XSRF-TOKEN` y lo envía
  como header `X-XSRF-TOKEN` en todas las mutaciones (POST/PUT/DELETE).
- El backend valida que el header `X-XSRF-TOKEN` coincida con la cookie `XSRF-TOKEN`.
- Con `SameSite=Strict`, el riesgo CSRF ya es mínimo; el CSRF token es una defensa
  en profundidad exigida por RF-AUTH-01.5.

**Alternativas consideradas**:

- Synchronizer token (server-side): requiere almacenamiento de tokens en BD,
  contradice la decisión de JWT stateless para el happy path.
- Omitir CSRF (solo SameSite): `SameSite=Strict` protege en la mayoría de casos,
  pero RF-AUTH-01.5 exige token explícito; cumplir el requisito cuesta poco.

---

## Decisión 5 — Almacenamiento de bloqueo por intentos fallidos

**Decisión**: Columnas adicionales en la tabla `usuarios`.

```sql
intentos_fallidos INT NOT NULL DEFAULT 0
bloqueado_hasta   DATETIME NULL
```

**Rationale**: El estado de bloqueo es por usuario y persiste entre instancias de
App Engine. Agregar columnas a `usuarios` es la solución más simple: mismo pool de
conexiones, sin tabla adicional, sin coordinación entre instancias. La operación es
un `UPDATE` atómico con `intentos_fallidos = intentos_fallidos + 1`.

**Nota de dependencia**: estas columnas deben coordinarse con la feature
`004-empleados` que es propietaria de la tabla `usuarios`. La migración para estas
columnas forma parte de `001-autenticacion`.

**Alternativas consideradas**:

- Tabla separada `intentos_login`: innecesaria complejidad para dos columnas.
- Ristretto (cache en proceso): no compartido entre instancias de App Engine;
  un usuario bloqueado en instancia A podría reintentar en instancia B.
- Redis/Memorystore: fuera del stack definido en la constitución.

---

## Decisión 6 — Configuración de expiración JWT

**Decisión**: Variable de entorno `JWT_EXPIRY_HOURS` (default: `24`), gestionada
vía GCP Secret Manager en stage/prod y `.env` local en dev.

**Rationale**: La expiración es un parámetro de sistema que raramente cambia.
Gestión vía env var sigue el patrón de la constitución para secrets/config y no
requiere tabla de configuración adicional. Un cambio de expiración implica redeploy
de App Engine, lo cual es aceptable dado el contexto.

**Alternativas consideradas**:

- Tabla `configuracion_sistema`: permite cambio en caliente sin redeploy; overhead
  de BD en cada emisión de token. Diferido para versiones futuras si el requisito
  de cambio en caliente emerge.

---

## Decisión 7 — Instrumentación OTel

**Decisión**: Spans OTel en handlers de autenticación; métricas de contador y
latencia por resultado.

**Atributos de span**:

- `auth.result`: `success` | `invalid_credentials` | `account_inactive` | `account_locked`
- `user.role`: solo en login exitoso
- `http.route`: `/api/v1/auth/login`, `/api/v1/auth/logout`

**Métricas**:

- `auth.login.duration` (histograma, ms)
- `auth.login.result` (contador por etiqueta `result`)
- `auth.blacklist.check.duration` (histograma, ms) — latencia de consulta a `tokens_revocados`

**Rationale**: La constitución exige trazas OTel y métricas en endpoints críticos;
autenticación es explícitamente listado como crítico. Las métricas de blacklist
permiten monitorear la latencia añadida por la consulta Cloud SQL.

---

## Decisión 8 — Endpoint de sesión actual (`/me`)

**Decisión**: `GET /api/v1/auth/me` — retorna rol y tienda_id del token activo.

**Rationale**: Angular no puede leer el JWT (cookie httpOnly). Al recargar la página
o iniciar la app, el frontend necesita restaurar el estado de sesión en memoria.
`/me` es la única forma de obtener rol y tienda_id sin obligar al usuario a
re-autenticarse. La respuesta no incluye el JWT ni información sensible; solo los
datos de sesión necesarios para la navegación.

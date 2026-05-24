# Contrato: POST /internal/jobs/limpiar_tokens_revocados

**Módulo**: Jobs internos | **Método**: POST | **Autenticación**: Header `X-CloudScheduler`

---

## Propósito

Elimina registros expirados de la tabla `tokens_revocados` para evitar crecimiento
ilimitado. Un registro es elegible cuando `expira_en < NOW()`, lo que significa que
el JWT correspondiente ya no sería válido por su `exp` de todas formas.

Este job es invocado por Cloud Scheduler. No es parte de la API pública.

---

## Request

**URL**: `POST /internal/jobs/limpiar_tokens_revocados`

**Headers**:

```http
X-CloudScheduler: true
```

**Body**: vacío

---

## Responses

### 200 OK — Job ejecutado

```json
{
  "eliminados": 12,
  "iniciado_en": "2026-05-23T02:00:00",
  "completado_en": "2026-05-23T02:00:00",
  "resultado": "ok"
}
```

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `eliminados` | int | Número de registros eliminados en esta ejecución |
| `iniciado_en` | string (ISO 8601) | Hora Colombia de inicio del job |
| `completado_en` | string (ISO 8601) | Hora Colombia de fin del job |
| `resultado` | string | `ok` \| `error` |

---

### 403 Forbidden — Header de autorización ausente

```json
{
  "error": "no_autorizado",
  "mensaje": "Acceso restringido a jobs internos"
}
```

**Cuándo ocurre**: header `X-CloudScheduler: true` ausente o con valor distinto.

---

### 500 Internal Server Error — Fallo en BD

```json
{
  "error": "error_interno",
  "mensaje": "Error al ejecutar limpieza de tokens",
  "resultado": "error"
}
```

---

## Configuración Cloud Scheduler recomendada

```text
Frecuencia:  0 2 * * *          (diaria a las 2:00 AM hora Colombia)
URL:         https://api.loopi.com/internal/jobs/limpiar_tokens_revocados
Método:      POST
Headers:     X-CloudScheduler: true
```

Con TTL de 24 h, ejecutar el job una vez al día es suficiente para mantener la tabla
pequeña (máximo ~50 registros en estado estable).

---

## Notas de implementación

- Query de limpieza: `DELETE FROM tokens_revocados WHERE expira_en < NOW()`
- El log de ejecución incluye: tipo de job, `iniciado_en`, `completado_en`,
  `resultado`, `eliminados` — cumpliendo el patrón de jobs de la constitución.
- Cloud Scheduler gestiona reintentos en caso de fallo; el job no reintenta
  automáticamente dentro de la misma ejecución.

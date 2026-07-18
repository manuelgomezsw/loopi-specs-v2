---
name: error-codes-inventory
description: Catálogo de códigos de error y mensajes para endpoints de inventario conteo
metadata:
  type: reference
  version: 1.0
  last_updated: 2026-07-18
---

# Catálogo de Errores - Inventario Conteo

Este documento especifica todos los códigos de error que pueden retornar los endpoints de inventario conteo y sus mensajes descriptivos en español para el usuario final.

## Estructura de Respuesta de Error

```json
{
  "error": "error_code",
  "mensaje": "Descripción del error en español"
}
```

## Códigos de Error por Endpoint

### POST /api/v1/inventarios (Iniciar Conteo)

| Código | Status | Mensaje | Causa |
|--------|--------|---------|-------|
| `conteo_duplicado` | 409 | Ya existe un conteo en progreso para esta tienda, tipo y horario. Usa la opción Reanudar si deseas continuar. | Intento de crear conteo cuando ya existe uno activo para la misma tienda, tipo y horario |
| `tienda_no_autorizada` | 403 | No tienes permiso para iniciar conteos en esta tienda. | Usuario intenta iniciar conteo en tienda que no le está asignada (solo admin puede en cualquier tienda) |
| `invalid_tipo` | 400 | El tipo de conteo seleccionado no es válido. Selecciona: Diario, Semanal, Mensual o Inicial. | Valor de tipo no válido |
| `horario_required` | 400 | El horario es obligatorio para conteos diarios. | Conteo diario sin horario especificado |
| `invalid_horario` | 400 | El horario seleccionado no es válido. Selecciona: Apertura, Mediodía o Cierre. | Valor de horario no válido |
| `horario_not_allowed` | 400 | No debes especificar horario para conteos semanales, mensuales o iniciales. | Horario especificado para tipo que no lo requiere |
| `unauthorized` | 401 | Tu sesión ha expirado. Por favor, inicia sesión nuevamente. | Token JWT inválido o expirado |
| `invalid_request` | 400 | La solicitud contiene datos inválidos. | Formato de JSON inválido en body |
| `invalid_user` | 400 | ID de usuario inválido. | No se puede parsear el ID del usuario del JWT |

### PATCH /api/v1/inventarios/{id}/items/{item_id} (Registrar Valor)

| Código | Status | Mensaje | Causa |
|--------|--------|---------|-------|
| `not_found` | 404 | El conteo no fue encontrado o ya no existe. | Inventario no existe o fue eliminado |
| `conteo_bloqueado` | 403 | Este conteo está bloqueado. Solo el responsable puede registrar valores. | Usuario intenta registrar valor en conteo que no inició |
| `estado_invalido` | 422 | El estado del conteo no permite esta acción. | Intento de registrar valores en conteo completado o cancelado |

### POST /api/v1/inventarios/{id}/confirmar (Confirmar Conteo)

| Código | Status | Mensaje | Causa |
|--------|--------|---------|-------|
| `not_found` | 404 | El conteo no fue encontrado o ya no existe. | Inventario no existe |
| `conteo_bloqueado` | 403 | Este conteo está bloqueado. Solo el responsable puede confirmar. | Usuario intenta confirmar conteo que no inició |
| `ya_completado` | 409 | Este conteo ya fue completado anteriormente y no puede ser modificado. | Intento de confirmar un conteo ya completado |
| `items_sin_registrar` | 422 | No todos los items tienen valores registrados. Completa todos antes de confirmar. | Hay items sin valor real asignado |

### GET /api/v1/inventarios/{id} (Obtener Detalle)

| Código | Status | Mensaje | Causa |
|--------|--------|---------|-------|
| `not_found` | 404 | El conteo no fue encontrado o ya no existe. | Inventario no existe |
| `tienda_no_autorizada` | 403 | No tienes permiso para ver inventarios de esta tienda. | Usuario intenta ver conteo de tienda que no le está asignada |
| `conteo_bloqueado` | 403 | Este conteo está bloqueado. Solo el responsable del conteo puede acceder a él. | Usuario intenta acceder a conteo activo que no inició |
| `unauthorized` | 401 | Tu sesión ha expirado. Por favor, inicia sesión nuevamente. | Token JWT inválido o expirado |

### GET /api/v1/inventarios/sugerencia (Obtener Sugerencia)

| Código | Status | Mensaje | Causa |
|--------|--------|---------|-------|
| `unauthorized` | 401 | Tu sesión ha expirado. Por favor, inicia sesión nuevamente. | Token JWT inválido o expirado |

## Categorías de Error

### Errores de Validación (400 Bad Request)

- `invalid_tipo`
- `horario_required`
- `invalid_horario`
- `horario_not_allowed`
- `invalid_request`
- `invalid_user`

Mensaje genérico fallback: *"Los datos ingresados no son válidos."*

### Errores de Autorización (401/403)

- `unauthorized` (401)
- `tienda_no_autorizada` (403)
- `conteo_bloqueado` (403)
- `sin_permiso` (403)

Mensaje genérico fallback: *"No tienes permiso para realizar esta acción."*

### Errores de Estado (409 Conflict)

- `conteo_duplicado`
- `ya_completado`

### Errores de Entidad (404/422)

- `not_found` (404)
- `items_sin_registrar` (422)
- `estado_invalido` (422)

## Implementación en Frontend

### Servicio: ErrorMapperService

El servicio `src/app/inventario/error-mapper.service.ts` proporciona:

```typescript
// Extrae mensaje del error HTTP manteniendo los códigos internos
extractErrorMessage(error: any): string

// Mapea un código conocido a su mensaje
mapErrorCode(errorCode: string): string

// Retorna lista de códigos conocidos (útil para testing)
getKnownErrors(): string[]
```

### Uso en Componentes

```typescript
import { ErrorMapperService } from './error-mapper.service';

export class InventarioConteoComponent {
  constructor(private errorMapper: ErrorMapperService) {}

  handleError(err: any) {
    const mensaje = this.errorMapper.extractErrorMessage(err);
    // Mostrar mensaje al usuario
  }
}
```

## Mantenibilidad

- **Agregar nuevo error**: Actualizar `error-mapper.service.ts` mapeo `errorMessages`
- **Cambiar mensaje**: Modificar el valor en `errorMessages` (centralizado)
- **Traducción**: Todos los mensajes están en español en un único lugar
- **Escalabilidad**: Patrón permite fácil adición de nuevos errores sin cambios en componentes

## Testing

Ver `specs/009-inventario-conteo/test/error-handling.spec.ts` para test cases de todos los códigos de error.

# Lista de Verificación de Calidad: Inventario y Conteo Físico

**Propósito**: Validar completitud y calidad de la especificación antes de planificar
**Creado**: 2026-05-21
**Feature**: [spec.md](../spec.md)

## Calidad del Contenido

- [x] Sin detalles de implementación (lenguajes, frameworks, APIs)
- [x] Enfocado en valor para el usuario y necesidades del negocio
- [x] Escrito para interesados no técnicos
- [x] Todas las secciones obligatorias completadas

## Completitud de Requisitos

- [x] Sin marcadores [NEEDS CLARIFICATION] pendientes
- [x] Requisitos son verificables e inequívocos
- [x] Criterios de éxito son medibles
- [x] Criterios de éxito son agnósticos a tecnología (sin detalles de implementación)
- [x] Todos los escenarios de aceptación están definidos
- [x] Casos borde identificados (conteo duplicado por tienda, conteo interrumpido,
  confirmación con items faltantes, inventario inicial sin referencia, ajuste automático
  sin aprobación, modificación de completado solo por admin)
- [x] Alcance claramente delimitado (sin aprobación para ajustes, un conteo por tipo/horario
  por fecha, correcciones solo vía mermas o nuevo inventario)
- [x] Dependencias y suposiciones identificadas

## Preparación del Feature

- [x] Todos los requisitos funcionales tienen criterios de aceptación claros
- [x] Los escenarios de usuario cubren los flujos principales (iniciar, registrar, confirmar,
  consultar historial)
- [x] El feature cumple los resultados medibles definidos en los Criterios de Éxito
- [x] Sin detalles de implementación en la especificación

## Notas

- RF-INV-02.5 especifica que solo el responsable que inició puede retomar y completar el
  conteo. Verificar con el equipo si el admin puede intervenir para retomar un conteo
  bloqueado (ej. si el líder se fue de turno sin completar).
- La suposición sobre conteos abandonados (no se eliminan automáticamente) debe confirmarse:
  ¿debe el sistema limpiar conteos en_progreso con más de X horas de inactividad, o el
  admin los descarta manualmente?
- El cálculo del valor sugerido depende de ventas (015-pos) y mermas (010-mermas). En el
  inventario inicial, ambas son cero. Documentar en QA el escenario de primera operación.

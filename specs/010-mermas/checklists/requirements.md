# Lista de Verificación de Calidad: Mermas

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
- [x] Casos borde identificados (merma en tienda ajena bloqueada, eliminación solo por
  admin, descripción opcional incluso para motivo "otro", costo_total calculado no
  almacenado)
- [x] Alcance claramente delimitado (sin flujo de aprobación, eliminación directa sin
  registro de auditoría, costo orientativo basado en costo vigente no histórico)
- [x] Dependencias y suposiciones identificadas

## Preparación del Feature

- [x] Todos los requisitos funcionales tienen criterios de aceptación claros
- [x] Los escenarios de usuario cubren los flujos principales (registrar, consultar,
  eliminar, reporte consolidado)
- [x] El feature cumple los resultados medibles definidos en los Criterios de Éxito
- [x] Sin detalles de implementación en la especificación

## Notas

- RF-MERM-01.6 indica que `inventario_asociado` es opcional y lo puede proveer el
  usuario. La suposición al final del spec aclara que también puede asignarse
  automáticamente cuando hay un inventario en progreso. Confirmar con el equipo si esta
  asignación automática es el comportamiento esperado o si siempre es selección manual.
- El costo_total estimado usa el `costo_unitario` vigente al momento de consultar (no
  el histórico al momento del registro). Verificar si esta decisión es aceptable para
  reportes financieros o si se requiere guardar el costo al momento de la merma.
- RF-MERM-05.2 indica que eliminar una merma revierte su contribución a `mermas_periodo`.
  Confirmar que esta reversión aplica solo a conteos futuros (no a conteos ya completados).

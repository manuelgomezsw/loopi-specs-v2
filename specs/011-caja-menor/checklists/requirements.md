# Lista de Verificación de Calidad: Caja Menor

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
- [x] Casos borde identificados (item no habilitado bloqueado, barista sin acceso,
  compra confirmada inmutable, corrección vía merma, unidad de medida no editable)
- [x] Alcance claramente delimitado (sin pedido formal, lista de items global no por
  tienda, sin límite de monto en sistema, valor unitario independiente de costo_unitario
  del catálogo)
- [x] Dependencias y suposiciones identificadas

## Preparación del Feature

- [x] Todos los requisitos funcionales tienen criterios de aceptación claros
- [x] Los escenarios de usuario cubren los flujos principales (habilitar items, registrar
  compra, consultar historial, reporte consolidado)
- [x] El feature cumple los resultados medibles definidos en los Criterios de Éxito
- [x] Sin detalles de implementación en la especificación

## Notas

- La suposición sobre la lista de items habilitados como global (no por tienda) debe
  confirmarse con el equipo: ¿una tienda podría necesitar una lista diferente de items
  autorizados para caja menor que otra tienda de la misma marca?
- El valor unitario de la compra es independiente del `costo_unitario` del catálogo.
  Confirmar si el sistema debe o no actualizar el costo_unitario del item basándose en
  el valor pagado en compras de caja menor.
- RF-CM-03 establece que la corrección de una compra errónea se hace vía merma.
  Verificar que este flujo es operativamente aceptable para el equipo (implica registrar
  una merma con motivo que explique el error).

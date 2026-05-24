# Lista de Verificación de Calidad: Items del Catálogo

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
- [x] Casos borde identificados (código/nombre duplicado, cambio de unidad canónica con
  historial, item inactivo en receta activa, código bloqueado si en uso)
- [x] Alcance claramente delimitado (sin generación automática de código, costo de
  referencia vs. costo real por tienda, tipos fijos)
- [x] Dependencias y suposiciones identificadas

## Preparación del Feature

- [x] Todos los requisitos funcionales tienen criterios de aceptación claros
- [x] Los escenarios de usuario cubren los flujos principales (crear, editar, inactivar/
  reactivar, consultar)
- [x] El feature cumple los resultados medibles definidos en los Criterios de Éxito
- [x] Sin detalles de implementación en la especificación

## Notas

- RF-ITEM-02.4 permite cambiar la unidad canónica con historial de stock previo confirmación.
  Antes de planificar, el equipo debe decidir si este caso debe bloquearse completamente
  (más seguro) o solo advertir (más flexible). La spec actual opta por advertir + confirmar.
- RF-ITEM-02.3 bloquea el cambio de código solo si el item está "en uso" (inventario, pedido
  o receta). Verificar en QA el caso de un item creado pero nunca contado — ¿puede cambiar
  su código?
- El costo de referencia es en COP entero (sin decimales), consistente con RN-ITEM-03.
  Confirmar con el equipo de negocio si se requieren decimales para items con costo muy bajo.

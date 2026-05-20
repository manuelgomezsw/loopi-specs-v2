# Lista de Verificación de Calidad: Categorías y Subcategorías del Catálogo

**Propósito**: Validar completitud y calidad de la especificación antes de planificar
**Creado**: 2026-05-19
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
- [x] Casos borde identificados (nombre duplicado, inactivación en cascada, subcategorías
  repetidas en distintas categorías, case-insensitive para duplicados)
- [x] Alcance claramente delimitado (solo 2 niveles, sin reasignación de subcategoría,
  sin precarga automática)
- [x] Dependencias y suposiciones identificadas

## Preparación del Feature

- [x] Todos los requisitos funcionales tienen criterios de aceptación claros
- [x] Los escenarios de usuario cubren los flujos principales (crear categoría, crear
  subcategoría, editar, inactivar, consultar)
- [x] El feature cumple los resultados medibles definidos en los Criterios de Éxito
- [x] Sin detalles de implementación en la especificación

## Notas

- RF-CAT-01.4 especifica inactivación en cascada (categoría → subcategorías activas)
  con confirmación previa del admin. Verificar en QA que la advertencia es clara y que
  el admin entiende el alcance antes de confirmar.
- RF-CAT-02.3 prohíbe reasignar una subcategoría a otra categoría. Si el negocio
  necesita mover subcategorías, documentar el flujo alternativo (inactivar + recrear)
  en la guía de uso antes de planificar.
- La validación de nombres sin distinción de mayúsculas (suposición final) debe
  confirmarse con el equipo de producto antes de planificar, ya que impacta la
  experiencia de creación.

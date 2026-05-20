# Lista de Verificación de Calidad: Unidades de Medida

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
- [x] Casos borde identificados (código duplicado, tipos incompatibles, unidad base inactivable, factor cero)
- [x] Alcance claramente delimitado (sin conversión entre tipos distintos, sin eliminación, factores solo vs. unidad base)
- [x] Dependencias y suposiciones identificadas

## Preparación del Feature

- [x] Todos los requisitos funcionales tienen criterios de aceptación claros
- [x] Los escenarios de usuario cubren los flujos principales (crear, editar, consultar, conversión automática)
- [x] El feature cumple los resultados medibles definidos en los Criterios de Éxito
- [x] Sin detalles de implementación en la especificación

## Notas

- Las unidades base por tipo (g, ml, und, cm2) se asumen precargadas en la configuración
  inicial del sistema; el admin no necesita crearlas manualmente. Si esto cambia, actualizar
  antes de planificar.
- La conversión entre tipos distintos (ej. kg → ml) está explícitamente fuera del alcance;
  requeriría propiedades físicas (densidad) que el sistema no gestiona.
- RF-UM-02.2 impide inactivar la unidad base mientras existan otras unidades activas del mismo
  tipo: este orden de inactivación debe verificarse en QA.

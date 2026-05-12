# Plan de Implementación: [FEATURE]

**Branch**: `[###-nombre-feature]` | **Fecha**: [FECHA] | **Spec**: [enlace]
**Entrada**: Especificación de feature desde `/specs/[###-nombre-feature]/spec.md`

**Nota**: Este template es completado por el comando `/speckit-plan`. Ver `.specify/templates/plan-template.md` para el flujo de ejecución.

## Resumen

[Extraer de la especificación de feature: requisito principal + enfoque técnico de la investigación]

## Contexto Técnico

<!--
  ACCIÓN REQUERIDA: Reemplaza el contenido de esta sección con los detalles técnicos
  del proyecto. La estructura aquí se presenta de forma orientativa para guiar
  el proceso iterativo.
-->

**Lenguaje/Versión**: [p.ej., Python 3.11, Swift 5.9, Rust 1.75 o NECESITA ACLARACIÓN]  
**Dependencias Principales**: [p.ej., FastAPI, UIKit, LLVM o NECESITA ACLARACIÓN]  
**Almacenamiento**: [si aplica, p.ej., PostgreSQL, CoreData, archivos o N/A]  
**Testing**: [p.ej., pytest, XCTest, cargo test o NECESITA ACLARACIÓN]  
**Plataforma Objetivo**: [p.ej., servidor Linux, iOS 15+, WASM o NECESITA ACLARACIÓN]
**Tipo de Proyecto**: [p.ej., librería/cli/servicio-web/app-móvil/compilador/app-escritorio o NECESITA ACLARACIÓN]  
**Objetivos de Rendimiento**: [específico del dominio, p.ej., 1000 req/s, 10k líneas/seg, 60 fps o NECESITA ACLARACIÓN]  
**Restricciones**: [específico del dominio, p.ej., <200ms p95, <100MB memoria, funciona sin conexión o NECESITA ACLARACIÓN]  
**Escala/Alcance**: [específico del dominio, p.ej., 10k usuarios, 1M LOC, 50 pantallas o NECESITA ACLARACIÓN]

## Verificación de Constitución

*GATE: Debe pasar antes de la investigación de Fase 0. Re-verificar tras el diseño de Fase 1.*

[Puertas determinadas en base al archivo de constitución]

## Estructura del Proyecto

### Documentación (esta feature)

```text
specs/[###-feature]/
├── plan.md              # Este archivo (output del comando /speckit-plan)
├── research.md          # Output de Fase 0 (comando /speckit-plan)
├── data-model.md        # Output de Fase 1 (comando /speckit-plan)
├── quickstart.md        # Output de Fase 1 (comando /speckit-plan)
├── contracts/           # Output de Fase 1 (comando /speckit-plan)
└── tasks.md             # Output de Fase 2 (comando /speckit-tasks — NO creado por /speckit-plan)
```

### Código Fuente (raíz del repositorio)
<!--
  ACCIÓN REQUERIDA: Reemplaza el árbol de marcadores de posición a continuación con la estructura concreta
  para esta feature. Elimina las opciones no usadas y expande la estructura elegida con
  rutas reales (p.ej., apps/admin, packages/algo). El plan entregado no debe
  incluir etiquetas de Opción.
-->

```text
# [ELIMINAR SI NO SE USA] Opción 1: Proyecto único (DEFAULT)
src/
├── models/
├── services/
├── cli/
└── lib/

tests/
├── contract/
├── integration/
└── unit/

# [ELIMINAR SI NO SE USA] Opción 2: Aplicación web (cuando se detecte "frontend" + "backend")
backend/
├── src/
│   ├── models/
│   ├── services/
│   └── api/
└── tests/

frontend/
├── src/
│   ├── components/
│   ├── pages/
│   └── services/
└── tests/

# [ELIMINAR SI NO SE USA] Opción 3: Mobile + API (cuando se detecte "iOS/Android")
api/
└── [igual que backend arriba]

ios/ o android/
└── [estructura específica de plataforma: módulos de feature, flujos de UI, tests de plataforma]
```

**Decisión de Estructura**: [Documenta la estructura seleccionada y referencia los directorios reales capturados arriba]

## Registro de Complejidad

> **Completar SOLO si la Verificación de Constitución tiene violaciones que deben justificarse**

| Violación | Por qué es necesaria | Alternativa más simple rechazada por |
|-----------|---------------------|--------------------------------------|
| [p.ej., 4° proyecto] | [necesidad actual] | [por qué 3 proyectos son insuficientes] |
| [p.ej., patrón Repositorio] | [problema específico] | [por qué acceso directo a BD es insuficiente] |

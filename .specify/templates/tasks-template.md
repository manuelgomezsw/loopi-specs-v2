---

description: "Plantilla de lista de tareas para implementación de features"
---

# Tareas: [NOMBRE DE FEATURE]

**Entrada**: Documentos de diseño desde `/specs/[###-nombre-feature]/`
**Prerrequisitos**: plan.md (requerido), spec.md (requerido para historias de usuario), research.md, data-model.md, contracts/

**Tests**: Los ejemplos a continuación incluyen tareas de testing. Los tests son OPCIONALES — inclúyelos solo si se solicitan explícitamente en la especificación de la feature.

**Organización**: Las tareas están agrupadas por historia de usuario para permitir implementación y testing independiente de cada historia.

## Formato: `[ID] [P?] [Historia] Descripción`

- **[P]**: Puede ejecutarse en paralelo (archivos diferentes, sin dependencias)
- **[Historia]**: A qué historia de usuario pertenece esta tarea (p.ej., HU1, HU2, HU3)
- Incluir rutas de archivos exactas en las descripciones

## Convenciones de Rutas

- **Proyecto único**: `src/`, `tests/` en la raíz del repositorio
- **App web**: `backend/src/`, `frontend/src/`
- **Mobile**: `api/src/`, `ios/src/` o `android/src/`
- Las rutas mostradas a continuación asumen proyecto único — ajustar según la estructura en plan.md

<!-- 
  ============================================================================
  IMPORTANTE: Las tareas a continuación son TAREAS DE EJEMPLO solo para ilustración.
  
  El comando /speckit-tasks DEBE reemplazarlas con tareas reales basadas en:
  - Historias de usuario de spec.md (con sus prioridades P1, P2, P3...)
  - Requisitos de la feature de plan.md
  - Entidades de data-model.md
  - Endpoints de contracts/
  
  Las tareas DEBEN organizarse por historia de usuario para que cada historia pueda:
  - Implementarse de forma independiente
  - Testearse de forma independiente
  - Entregarse como incremento MVP
  
  NO conserves estas tareas de ejemplo en el archivo tasks.md generado.
  ============================================================================
-->

## Fase 1: Configuración (Infraestructura Compartida)

**Propósito**: Inicialización del proyecto y estructura básica

- [ ] T001 Crear estructura del proyecto según el plan de implementación
- [ ] T002 Inicializar proyecto [lenguaje] con dependencias de [framework]
- [ ] T003 [P] Configurar herramientas de linting y formateo

---

## Fase 2: Fundacional (Prerrequisitos Bloqueantes)

**Propósito**: Infraestructura central que DEBE estar completa antes de que CUALQUIER historia de usuario pueda implementarse

**⚠️ CRÍTICO**: Ninguna historia de usuario puede comenzar hasta que esta fase esté completa

Ejemplos de tareas fundacionales (ajustar según tu proyecto):

- [ ] T004 Configurar esquema de base de datos y framework de migraciones
- [ ] T005 [P] Implementar framework de autenticación/autorización
- [ ] T006 [P] Configurar enrutamiento API y estructura de middleware
- [ ] T007 Crear modelos/entidades base de los que dependen todas las historias
- [ ] T008 Configurar manejo de errores e infraestructura de logging
- [ ] T009 Configurar gestión de configuración de entorno

**Punto de control**: Fundación lista — la implementación de historias de usuario puede comenzar en paralelo

---

## Fase 3: Historia de Usuario 1 - [Título] (Prioridad: P1) 🎯 MVP

**Objetivo**: [Breve descripción de lo que entrega esta historia]

**Prueba Independiente**: [Cómo verificar que esta historia funciona por sí sola]

### Tests para Historia de Usuario 1 (OPCIONAL — solo si se solicitan) ⚠️

> **NOTA: Escribe estos tests PRIMERO, asegúrate de que FALLEN antes de implementar**

- [ ] T010 [P] [HU1] Test de contrato para [endpoint] en tests/contract/test_[nombre].py
- [ ] T011 [P] [HU1] Test de integración para [journey de usuario] en tests/integration/test_[nombre].py

### Implementación de Historia de Usuario 1

- [ ] T012 [P] [HU1] Crear modelo [Entidad1] en src/models/[entidad1].py
- [ ] T013 [P] [HU1] Crear modelo [Entidad2] en src/models/[entidad2].py
- [ ] T014 [HU1] Implementar [Servicio] en src/services/[servicio].py (depende de T012, T013)
- [ ] T015 [HU1] Implementar [endpoint/feature] en src/[ubicación]/[archivo].py
- [ ] T016 [HU1] Agregar validación y manejo de errores
- [ ] T017 [HU1] Agregar logging para operaciones de la Historia de Usuario 1

**Punto de control**: En este punto, la Historia de Usuario 1 debe ser completamente funcional y testeable de forma independiente

---

## Fase 4: Historia de Usuario 2 - [Título] (Prioridad: P2)

**Objetivo**: [Breve descripción de lo que entrega esta historia]

**Prueba Independiente**: [Cómo verificar que esta historia funciona por sí sola]

### Tests para Historia de Usuario 2 (OPCIONAL — solo si se solicitan) ⚠️

- [ ] T018 [P] [HU2] Test de contrato para [endpoint] en tests/contract/test_[nombre].py
- [ ] T019 [P] [HU2] Test de integración para [journey de usuario] en tests/integration/test_[nombre].py

### Implementación de Historia de Usuario 2

- [ ] T020 [P] [HU2] Crear modelo [Entidad] en src/models/[entidad].py
- [ ] T021 [HU2] Implementar [Servicio] en src/services/[servicio].py
- [ ] T022 [HU2] Implementar [endpoint/feature] en src/[ubicación]/[archivo].py
- [ ] T023 [HU2] Integrar con componentes de Historia de Usuario 1 (si aplica)

**Punto de control**: En este punto, las Historias de Usuario 1 Y 2 deben funcionar de forma independiente

---

## Fase 5: Historia de Usuario 3 - [Título] (Prioridad: P3)

**Objetivo**: [Breve descripción de lo que entrega esta historia]

**Prueba Independiente**: [Cómo verificar que esta historia funciona por sí sola]

### Tests para Historia de Usuario 3 (OPCIONAL — solo si se solicitan) ⚠️

- [ ] T024 [P] [HU3] Test de contrato para [endpoint] en tests/contract/test_[nombre].py
- [ ] T025 [P] [HU3] Test de integración para [journey de usuario] en tests/integration/test_[nombre].py

### Implementación de Historia de Usuario 3

- [ ] T026 [P] [HU3] Crear modelo [Entidad] en src/models/[entidad].py
- [ ] T027 [HU3] Implementar [Servicio] en src/services/[servicio].py
- [ ] T028 [HU3] Implementar [endpoint/feature] en src/[ubicación]/[archivo].py

**Punto de control**: Todas las historias de usuario deben ser ahora funcionales de forma independiente

---

[Agrega más fases de historia de usuario según sea necesario, siguiendo el mismo patrón]

---

## Fase N: Pulido y Aspectos Transversales

**Propósito**: Mejoras que afectan a múltiples historias de usuario

- [ ] TXXX [P] Actualizaciones de documentación en docs/
- [ ] TXXX Limpieza de código y refactoring
- [ ] TXXX Optimización de rendimiento en todas las historias
- [ ] TXXX [P] Tests unitarios adicionales (si se solicitan) en tests/unit/
- [ ] TXXX Hardening de seguridad
- [ ] TXXX Ejecutar validación de quickstart.md

---

## Dependencias y Orden de Ejecución

### Dependencias de Fase

- **Configuración (Fase 1)**: Sin dependencias — puede comenzar de inmediato
- **Fundacional (Fase 2)**: Depende de la compleción de Configuración — BLOQUEA todas las historias de usuario
- **Historias de Usuario (Fase 3+)**: Todas dependen de la compleción de la fase Fundacional
  - Las historias de usuario pueden proceder en paralelo (si hay capacidad de equipo)
  - O secuencialmente en orden de prioridad (P1 → P2 → P3)
- **Pulido (Fase Final)**: Depende de que todas las historias de usuario deseadas estén completas

### Dependencias entre Historias de Usuario

- **Historia de Usuario 1 (P1)**: Puede comenzar tras la Fase Fundacional — Sin dependencias de otras historias
- **Historia de Usuario 2 (P2)**: Puede comenzar tras la Fase Fundacional — Puede integrarse con HU1 pero debe ser testeable de forma independiente
- **Historia de Usuario 3 (P3)**: Puede comenzar tras la Fase Fundacional — Puede integrarse con HU1/HU2 pero debe ser testeable de forma independiente

### Dentro de Cada Historia de Usuario

- Los tests (si se incluyen) DEBEN escribirse y FALLAR antes de la implementación
- Modelos antes que servicios
- Servicios antes que endpoints
- Implementación central antes que integración
- Historia completa antes de pasar a la siguiente prioridad

### Oportunidades de Paralelismo

- Todas las tareas de Configuración marcadas [P] pueden ejecutarse en paralelo
- Todas las tareas Fundacionales marcadas [P] pueden ejecutarse en paralelo (dentro de la Fase 2)
- Una vez que la fase Fundacional esté completa, todas las historias de usuario pueden comenzar en paralelo (si la capacidad del equipo lo permite)
- Todos los tests de una historia de usuario marcados [P] pueden ejecutarse en paralelo
- Los modelos dentro de una historia marcados [P] pueden ejecutarse en paralelo
- Diferentes historias de usuario pueden trabajarse en paralelo por distintos miembros del equipo

---

## Ejemplo Paralelo: Historia de Usuario 1

```bash
# Lanzar todos los tests de Historia de Usuario 1 juntos (si se solicitan):
Tarea: "Test de contrato para [endpoint] en tests/contract/test_[nombre].py"
Tarea: "Test de integración para [journey de usuario] en tests/integration/test_[nombre].py"

# Lanzar todos los modelos de Historia de Usuario 1 juntos:
Tarea: "Crear modelo [Entidad1] en src/models/[entidad1].py"
Tarea: "Crear modelo [Entidad2] en src/models/[entidad2].py"
```

---

## Estrategia de Implementación

### MVP Primero (Solo Historia de Usuario 1)

1. Completar Fase 1: Configuración
2. Completar Fase 2: Fundacional (CRÍTICO — bloquea todas las historias)
3. Completar Fase 3: Historia de Usuario 1
4. **PARAR Y VALIDAR**: Testear Historia de Usuario 1 de forma independiente
5. Desplegar/demo si está listo

### Entrega Incremental

1. Completar Configuración + Fundacional → Fundación lista
2. Agregar Historia de Usuario 1 → Testear de forma independiente → Desplegar/Demo (¡MVP!)
3. Agregar Historia de Usuario 2 → Testear de forma independiente → Desplegar/Demo
4. Agregar Historia de Usuario 3 → Testear de forma independiente → Desplegar/Demo
5. Cada historia agrega valor sin romper las historias anteriores

### Estrategia de Equipo en Paralelo

Con múltiples desarrolladores:

1. El equipo completa Configuración + Fundacional juntos
2. Una vez que Fundacional esté listo:
   - Desarrollador A: Historia de Usuario 1
   - Desarrollador B: Historia de Usuario 2
   - Desarrollador C: Historia de Usuario 3
3. Las historias se completan e integran de forma independiente

---

## Notas

- Las tareas [P] = archivos diferentes, sin dependencias
- La etiqueta [Historia] mapea la tarea a una historia de usuario específica para trazabilidad
- Cada historia de usuario debe ser completable y testeable de forma independiente
- Verificar que los tests fallen antes de implementar
- Hacer commit después de cada tarea o grupo lógico
- Detenerse en cualquier punto de control para validar la historia de forma independiente
- Evitar: tareas vagas, conflictos en el mismo archivo, dependencias entre historias que rompan la independencia

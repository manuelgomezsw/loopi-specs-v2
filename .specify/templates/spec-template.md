# Especificación de Feature: [NOMBRE DE FEATURE]

**Branch de Feature**: `[###-nombre-feature]`  
**Creado**: [FECHA]  
**Estado**: Borrador  
**Entrada**: Descripción del usuario: "$ARGUMENTS"

## Escenarios de Usuario y Pruebas *(obligatorio)*

<!--
  IMPORTANTE: Las historias de usuario deben estar PRIORIZADAS como journeys de usuario ordenados por importancia.
  Cada historia de usuario/journey debe ser TESTEABLE DE FORMA INDEPENDIENTE — es decir, si solo implementas UNA de ellas,
  debes tener un MVP (Producto Mínimo Viable) que entregue valor.
  
  Asigna prioridades (P1, P2, P3, etc.) a cada historia, donde P1 es la más crítica.
  Piensa en cada historia como una porción autónoma de funcionalidad que puede:
  - Desarrollarse de forma independiente
  - Testearse de forma independiente
  - Desplegarse de forma independiente
  - Demostrarse a usuarios de forma independiente
-->

### Historia de Usuario 1 - [Título Breve] (Prioridad: P1)

[Describe este journey de usuario en lenguaje simple]

**Por qué esta prioridad**: [Explica el valor y por qué tiene este nivel de prioridad]

**Prueba Independiente**: [Describe cómo puede testearse de forma independiente — p.ej., "Puede testearse completamente mediante [acción específica] y entrega [valor específico]"]

**Escenarios de Aceptación**:

1. **Dado** [estado inicial], **Cuando** [acción], **Entonces** [resultado esperado]
2. **Dado** [estado inicial], **Cuando** [acción], **Entonces** [resultado esperado]

---

### Historia de Usuario 2 - [Título Breve] (Prioridad: P2)

[Describe este journey de usuario en lenguaje simple]

**Por qué esta prioridad**: [Explica el valor y por qué tiene este nivel de prioridad]

**Prueba Independiente**: [Describe cómo puede testearse de forma independiente]

**Escenarios de Aceptación**:

1. **Dado** [estado inicial], **Cuando** [acción], **Entonces** [resultado esperado]

---

### Historia de Usuario 3 - [Título Breve] (Prioridad: P3)

[Describe este journey de usuario en lenguaje simple]

**Por qué esta prioridad**: [Explica el valor y por qué tiene este nivel de prioridad]

**Prueba Independiente**: [Describe cómo puede testearse de forma independiente]

**Escenarios de Aceptación**:

1. **Dado** [estado inicial], **Cuando** [acción], **Entonces** [resultado esperado]

---

[Agrega más historias de usuario según sea necesario, cada una con su prioridad asignada]

### Casos Borde

<!--
  ACCIÓN REQUERIDA: El contenido de esta sección representa marcadores de posición.
  Complétalo con los casos borde correctos.
-->

- ¿Qué ocurre cuando [condición límite]?
- ¿Cómo maneja el sistema [escenario de error]?

## Requisitos *(obligatorio)*

<!--
  ACCIÓN REQUERIDA: El contenido de esta sección representa marcadores de posición.
  Complétalo con los requisitos funcionales correctos.
-->

### Requisitos Funcionales

- **RF-001**: El sistema DEBE [capacidad específica, p.ej., "permitir a los usuarios crear cuentas"]
- **RF-002**: El sistema DEBE [capacidad específica, p.ej., "validar direcciones de correo electrónico"]
- **RF-003**: Los usuarios DEBEN poder [interacción clave, p.ej., "restablecer su contraseña"]
- **RF-004**: El sistema DEBE [requisito de datos, p.ej., "persistir las preferencias del usuario"]
- **RF-005**: El sistema DEBE [comportamiento, p.ej., "registrar todos los eventos de seguridad"]

*Ejemplo de marcado de requisitos poco claros:*

- **RF-006**: El sistema DEBE autenticar usuarios mediante [NECESITA ACLARACIÓN: método de autenticación no especificado — email/contraseña, SSO, OAuth?]
- **RF-007**: El sistema DEBE retener datos de usuario durante [NECESITA ACLARACIÓN: período de retención no especificado]

### Entidades Clave *(incluir si la feature involucra datos)*

- **[Entidad 1]**: [Qué representa, atributos clave sin detalles de implementación]
- **[Entidad 2]**: [Qué representa, relaciones con otras entidades]

## Criterios de Éxito *(obligatorio)*

<!--
  ACCIÓN REQUERIDA: Define criterios de éxito medibles.
  Deben ser agnósticos a la tecnología y medibles.
-->

### Resultados Medibles

- **CE-001**: [Métrica medible, p.ej., "Los usuarios pueden completar la creación de cuenta en menos de 2 minutos"]
- **CE-002**: [Métrica medible, p.ej., "El sistema soporta 1000 usuarios concurrentes sin degradación"]
- **CE-003**: [Métrica de satisfacción, p.ej., "El 90% de los usuarios completa la tarea principal en el primer intento"]
- **CE-004**: [Métrica de negocio, p.ej., "Reducir los tickets de soporte relacionados con [X] en un 50%"]

## Supuestos

<!--
  ACCIÓN REQUERIDA: El contenido de esta sección representa marcadores de posición.
  Complétalo con los supuestos correctos basados en valores predeterminados razonables
  elegidos cuando la descripción de la feature no especificó ciertos detalles.
-->

- [Supuesto sobre usuarios objetivo, p.ej., "Los usuarios tienen conexión estable a internet"]
- [Supuesto sobre límites de alcance, p.ej., "El soporte móvil está fuera del alcance para v1"]
- [Supuesto sobre datos/entorno, p.ej., "Se reutilizará el sistema de autenticación existente"]
- [Dependencia de sistema/servicio existente, p.ej., "Requiere acceso a la API de perfil de usuario existente"]

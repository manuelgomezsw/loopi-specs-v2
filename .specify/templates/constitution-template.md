# Constitución de [PROJECT_NAME]
<!-- Ejemplo: Constitución de Spec, Constitución de TaskFlow, etc. -->

## Principios Fundamentales

### [PRINCIPLE_1_NAME]
<!-- Ejemplo: I. Librería Primero -->
[PRINCIPLE_1_DESCRIPTION]
<!-- Ejemplo: Cada feature comienza como librería autónoma; Las librerías deben ser autocontenidas, testeables de forma independiente, documentadas; Se requiere propósito claro — sin librerías solo organizativas -->

### [PRINCIPLE_2_NAME]
<!-- Ejemplo: II. Interfaz CLI -->
[PRINCIPLE_2_DESCRIPTION]
<!-- Ejemplo: Cada librería expone funcionalidad mediante CLI; Protocolo de texto entrada/salida: stdin/args → stdout, errores → stderr; Soportar formatos JSON + legible por humanos -->

### [PRINCIPLE_3_NAME]
<!-- Ejemplo: III. Pruebas Primero (NO NEGOCIABLE) -->
[PRINCIPLE_3_DESCRIPTION]
<!-- Ejemplo: TDD obligatorio: Tests escritos → Aprobados por usuario → Tests fallan → Luego implementar; Ciclo Rojo-Verde-Refactor aplicado estrictamente -->

### [PRINCIPLE_4_NAME]
<!-- Ejemplo: IV. Pruebas de Integración -->
[PRINCIPLE_4_DESCRIPTION]
<!-- Ejemplo: Áreas que requieren pruebas de integración: Tests de contrato de nuevas librerías, Cambios de contrato, Comunicación entre servicios, Esquemas compartidos -->

### [PRINCIPLE_5_NAME]
<!-- Ejemplo: V. Observabilidad, VI. Versionado y Cambios Incompatibles, VII. Simplicidad -->
[PRINCIPLE_5_DESCRIPTION]
<!-- Ejemplo: La E/S de texto garantiza depurabilidad; Logging estructurado requerido; O: formato MAYOR.MENOR.BUILD; O: Empezar simple, principios YAGNI -->

## [SECTION_2_NAME]
<!-- Ejemplo: Restricciones Adicionales, Requisitos de Seguridad, Estándares de Rendimiento, etc. -->

[SECTION_2_CONTENT]
<!-- Ejemplo: Requisitos de stack tecnológico, estándares de cumplimiento, políticas de despliegue, etc. -->

## [SECTION_3_NAME]
<!-- Ejemplo: Flujo de Desarrollo, Proceso de Revisión, Puertas de Calidad, etc. -->

[SECTION_3_CONTENT]
<!-- Ejemplo: Requisitos de revisión de código, puertas de testing, proceso de aprobación de despliegue, etc. -->

## Gobernanza
<!-- Ejemplo: La constitución tiene precedencia sobre todas las demás prácticas; Las enmiendas requieren documentación, aprobación y plan de migración -->

[GOVERNANCE_RULES]
<!-- Ejemplo: Todos los PRs/revisiones deben verificar cumplimiento; La complejidad debe justificarse; Usar [GUIDANCE_FILE] para guía de desarrollo en runtime -->

**Versión**: [CONSTITUTION_VERSION] | **Ratificado**: [RATIFICATION_DATE] | **Última Enmienda**: [LAST_AMENDED_DATE]
<!-- Ejemplo: Versión: 2.1.1 | Ratificado: 2025-06-13 | Última Enmienda: 2025-07-16 -->

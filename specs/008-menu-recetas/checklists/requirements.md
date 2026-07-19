# Lista de Verificación de Calidad: Menú y Recetas

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
- [x] Casos borde identificados (producto padre con variantes activas, receta sin unidades
  compatibles, insumo inactivado con receta activa, versión anterior archivada no
  reactivable, código POS duplicado globalmente)
- [x] Alcance claramente delimitado (sin tercer nivel de variantes, recetas archivadas de
  solo lectura, categorías de menú independientes de categorías de catálogo, descuento de
  inventario por venta fuera de alcance — corresponde a 012-ventas-integracion-pos)
- [x] Dependencias y suposiciones identificadas

## Preparación del Feature

- [x] Todos los requisitos funcionales tienen criterios de aceptación claros
- [x] Los escenarios de usuario cubren los flujos principales (crear producto simple, crear
  producto con variantes, crear/versionar receta, editar producto, consultar menú,
  gestionar categorías de menú)
- [x] El feature cumple los resultados medibles definidos en los Criterios de Éxito
- [x] Sin detalles de implementación en la especificación

## Notas

- ~~RF-MEN-01.3 define que el código POS es único por tienda~~ **Resuelto en sesión de
  clarificación 2026-07-12**: el código POS es único global (ver `## Clarifications` en
  spec.md).
- ~~RF-REC-02 (impacto en inventario por venta)~~ **Resuelto en sesión de clarificación
  2026-07-12**: se eliminó por completo de 008. El motor de descuento, su comportamiento
  ante ventas sin receta y las alertas correspondientes se implementan íntegramente en
  012-ventas-integracion-pos; 008 no los describe ni como referencia informativa.
- ~~Gap: ¿dónde y cómo se gestionan las categorías de menú?~~ **Resuelto en sesión de
  clarificación 2026-07-12**: se agregó la Historia de Usuario 6 (crear, editar,
  inactivar, reactivar, nombre único) y RF-MEN-03.4, siguiendo el patrón de
  005-categorias-catalogo.
- ~~Gap: ¿qué muestra el historial de versiones de una receta?~~ **Resuelto en sesión de
  clarificación 2026-07-12**: en el MVP solo expone número de versión y fechas de
  vigencia (RF-REC-02.2); el detalle completo de ingredientes de versiones archivadas
  queda documentado en `## Fuera de Alcance` para una iteración futura.
- Las recetas archivadas son de solo lectura (suposición). Si el negocio necesita restaurar
  recetas antiguas frecuentemente, considerar agregar un mecanismo de "clonar versión
  anterior" antes de planificar.

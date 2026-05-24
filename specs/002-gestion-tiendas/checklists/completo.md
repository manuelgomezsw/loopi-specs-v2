# Lista de Verificación Completa: Gestión de Tiendas

**Propósito**: Validar la calidad y completitud de los requisitos escritos antes del commit —
cubre RBAC, modelo de datos, contratos API y requisitos UX.
**Creado**: 2026-05-23
**Feature**: [spec.md](../spec.md) | [plan.md](../plan.md) | [contracts/api-tiendas.md](../contracts/api-tiendas.md)
**Audiencia**: Autor (auto-revisión pre-commit) | **Profundidad**: Liviana (20 ítems)

---

## RBAC y Control de Acceso

- [x] CHK001 ¿Los requisitos de denegación de acceso para roles distintos de `admin` están
  especificados para todos los endpoints de gestión (crear, editar, listar, inactivar, reactivar),
  o solo para los flujos de creación y edición? [Coverage, Spec §RF-TDA-01.1, 02.1, 03.1]
  → Resuelto: RF-TDA-04.1 agregado con RBAC explícito para listado y detalle.

- [x] CHK002 ¿El escenario de aceptación de HU1 (acceso denegado para `lider_tienda`/`barista`)
  es representativo de todos los endpoints de gestión, o solo cubre el acceso a la pantalla
  principal de tiendas? [Completeness, Spec §HU1 Escenario 3]
  → Sin cambio — nivel de abstracción correcto para spec funcional (cobertura UI-level).

- [x] CHK003 ¿El código HTTP de respuesta para acceso denegado (403) aparece como requisito
  explícito en el spec funcional, o solo se infiere del contrato técnico en `contracts/`?
  [Clarity, Gap]
  → Sin cambio — HTTP codes pertenecen a contracts, no al spec funcional.

---

## Modelo de Datos e Integridad

- [x] CHK004 ¿El requisito de unicidad case-insensitive del nombre (RF-TDA-01.3) especifica
  si aplica también entre tiendas activas e inactivas — es decir, ¿puede reutilizarse el nombre
  de una tienda inactiva al crear una nueva? [Clarity, Spec §RF-TDA-01.3]
  → Resuelto: RF-TDA-01.3 aclarado — unicidad aplica sobre todas las tiendas independientemente
  de su estado.

- [x] CHK005 ¿El formato del campo `codigo` ("alfanumérico en mayúsculas, ej. TDA-001") está
  suficientemente especificado con un patrón o regex, o puede interpretarse de formas distintas
  por el implementador (longitud máxima, separadores permitidos, prefijo obligatorio)?
  [Clarity, Spec §RF-TDA-01.6]
  → Resuelto: RF-TDA-01.6 define A-Z, 0-9, guiones, máx. 20 caracteres.

- [x] CHK006 ¿El requisito de inmutabilidad del `codigo` especifica el comportamiento exacto del
  sistema si el campo llega en el body de una petición de edición — ignorar silenciosamente o
  retornar un error explícito? [Clarity, Spec §RF-TDA-02.2]
  → Sin cambio — decisión de implementación documentada en research.md §6 (ignorar silenciosamente).

- [x] CHK007 ¿La verificación de unicidad del `codigo` especifica si la comparación también es
  case-insensitive, o pueden coexistir `"TDA-001"` y `"tda-001"` como códigos distintos?
  [Clarity, Gap]
  → Resuelto: RF-TDA-01.5 indica que el sistema normaliza a mayúsculas antes de guardar y
  verificar unicidad; no retorna error por capitalización.

- [x] CHK008 ¿Se especifica el comportamiento de los campos de auditoría (`creado_por`,
  `actualizado_por`) en el escenario en que el admin que realizó la operación sea posteriormente
  desactivado o eliminado del sistema? [Edge Case, Gap]
  → Resuelto: Suposiciones incluye que los admins solo se inactivan (no se eliminan físicamente);
  las FK de auditoría nunca quedan huérfanas.

---

## Contratos API y Validaciones

- [x] CHK009 ¿Los escenarios de aceptación de HU1 incluyen un caso explícito para la unicidad
  del `codigo` (además del nombre), de modo que el criterio sea verificable sin leer el plan
  técnico? [Completeness, Spec §HU1]
  → Resuelto: HU1 Escenario 4 agregado para código duplicado.

- [x] CHK010 ¿Se especifican los requisitos de paginación del listado (tamaño de página por
  defecto, máximo permitido) en el spec funcional, o esa información existe solo en el plan
  de implementación? [Clarity, Gap]
  → Sin cambio — con 10-50 tiendas esperadas la paginación es invisible para el usuario;
  permanece como restricción técnica en el plan/research.

- [x] CHK011 ¿El spec define el orden de presentación de los resultados del listado de tiendas
  (por nombre, por fecha de creación, por ID)? [Clarity, Gap]
  → Resuelto: RF-TDA-04.2 especifica orden por nombre ascendente por defecto.

- [x] CHK012 ¿Los criterios de éxito incluyen alguna métrica para la funcionalidad de auditoría
  (RF-TDA-06), o es la única sección funcional sin un criterio de éxito medible?
  [Completeness, Gap]
  → Resuelto: criterio "Trazabilidad de gestión" agregado (100% de operaciones registradas
  con actor y timestamp).

- [x] CHK013 ¿El spec especifica el comportamiento y código de error cuando se intenta inactivar
  una tienda ya inactiva o reactivar una ya activa (estado idempotente), o solo describe
  los flujos exitosos? [Coverage, Spec §RF-TDA-03]
  → Resuelto: RF-TDA-03.6 y HU3 Escenario 4 agregados para el caso de estado inválido.

---

## Flujos UX y Estados

- [x] CHK014 ¿Se especifica el contenido mínimo del diálogo de confirmación de reactivación
  (texto del mensaje, etiquetas de los botones de acción), o solo se menciona que existe el
  diálogo sin definir su contenido? [Clarity, Spec §RF-TDA-03.4]
  → Sin cambio — RF-TDA-03.4 ya especifica el texto del diálogo: "¿Reactivar esta tienda?".

- [x] CHK015 ¿Se definen requisitos para el estado vacío del listado de tiendas (primera
  instalación sin ninguna tienda creada), incluyendo el mensaje o acción a mostrar al admin?
  [Coverage, Gap]
  → Resuelto: RF-TDA-04.4 y HU4 Escenario 3 agregados para estado vacío del listado.

- [x] CHK016 ¿Se especifican qué campos del formulario aparecen en el flujo de creación vs.
  el de edición (ej. `codigo` visible en creación, oculto o deshabilitado en edición)?
  [Clarity, Gap]
  → Sin cambio — derivable sin ambigüedad de RF-TDA-01.2 (campos de creación) y
  RF-TDA-02.2 (`codigo` no editable).

- [x] CHK017 ¿Se especifican los requisitos de retroalimentación visual (mensaje de éxito o error)
  tras completar cada operación: crear, editar, inactivar y reactivar? [Coverage, Gap]
  → Resuelto: RF-TDA-07 agregado con requisitos de confirmación visual para éxito y error.

- [x] CHK018 ¿El requisito del filtro de estado del listado define si el filtro seleccionado
  persiste cuando el admin navega a una tienda y regresa al listado (comportamiento de
  navegación)? [Clarity, Gap]
  → Diferido — decisión de UX menor, adecuada para la fase de diseño visual.

---

## Dependencias y Supuestos

- [x] CHK019 ¿La dependencia con `001-autenticacion` especifica qué claims del JWT (`rol`,
  `user_id`, etc.) son necesarios para autorizar las operaciones de gestión de tiendas?
  [Completeness, Spec §Dependencias]
  → Resuelto: Dependencias §001-autenticacion actualizada con claims `rol` y `user_id`.

- [x] CHK020 ¿El supuesto de que "el nombre actual es el único visible en reportes históricos"
  tiene documentado su impacto en las features `009–014` que referencian `tienda_id` y
  pueden mostrar el nombre de la tienda en reportes? [Assumption, Spec §Suposiciones]
  → Resuelto: Suposiciones ampliada con nota de impacto cross-feature para features 009–014.

---

## Notas de Uso

- Marca los ítems al resolverlos: `[x]`
- Para ítems que no aplican en esta revisión: `[-]` + nota inline
- Los ítems `[Gap]` indican requisitos posiblemente faltantes en el spec — evaluar si agregar o
  diferir a la fase de planificación
- Los ítems `[Clarity]` indican ambigüedad — precisar en el spec antes de implementar

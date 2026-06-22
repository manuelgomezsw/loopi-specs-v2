# Especificación de Feature: Categorías y Subcategorías del Catálogo

**Branch de Feature**: `005-categorias-catalogo`
**Creado**: 2026-05-19
**Estado**: En implementación
**Referencia funcional**: [§3.1.3 Categorización en Dos Niveles](../loopi-v2-funcional/spec.md)

---

## Escenarios de Usuario y Pruebas *(obligatorio)*

### Historia de Usuario 1 — Crear una categoría (Prioridad: P1)

El administrador registra una nueva categoría principal para agrupar items del catálogo
(por ejemplo: Insumo, Lácteo, Verdura, Abarrote, Material de consumo, Activo). Una vez
creada, la categoría queda disponible para asignarle subcategorías.

**Por qué esta prioridad**: Las categorías son el nivel raíz de la clasificación del
catálogo. Sin al menos una categoría no se pueden crear subcategorías ni, por ende, items.
Es el punto de partida obligatorio de la estructura del catálogo.

**Prueba Independiente**: Puede verificarse creando una categoría y comprobando que aparece
disponible al crear una subcategoría.

**Escenarios de Aceptación**:

1. **Dado** que el admin está autenticado,
   **Cuando** crea la categoría "Lácteo" con nombre válido,
   **Entonces** la categoría queda registrada como activa y aparece en el listado de
   categorías.

2. **Dado** que ya existe una categoría con el nombre "Lácteo",
   **Cuando** el admin intenta crear otra con el mismo nombre,
   **Entonces** el sistema rechaza la operación indicando que el nombre ya existe.

3. **Dado** que un lider_tienda o barista intenta acceder a la gestión de categorías,
   **Cuando** navega a esa sección,
   **Entonces** el sistema deniega el acceso; solo el admin puede gestionar este catálogo.

---

### Historia de Usuario 2 — Crear una subcategoría (Prioridad: P1)

El administrador registra una subcategoría dentro de una categoría existente para
clasificar items con mayor granularidad (por ejemplo: dentro de "Lácteo" → Quesos,
Cremas; dentro de "Verdura" → Hoja, Raíz). Una vez creada, la subcategoría queda
disponible para asignarla a items.

**Por qué esta prioridad**: Los items requieren una subcategoría asignada. Sin
subcategorías no se pueden crear items y el catálogo no puede operar.

**Prueba Independiente**: Puede verificarse creando una subcategoría y comprobando
que aparece como opción al crear un item.

**Escenarios de Aceptación**:

1. **Dado** que existe la categoría "Lácteo",
   **Cuando** el admin crea la subcategoría "Quesos" asignada a "Lácteo",
   **Entonces** la subcategoría queda registrada y aparece bajo "Lácteo" en el catálogo.

2. **Dado** que ya existe la subcategoría "Quesos" dentro de "Lácteo",
   **Cuando** el admin intenta crear otra subcategoría con el mismo nombre dentro de la
   misma categoría,
   **Entonces** el sistema rechaza la operación indicando que el nombre ya existe en esa
   categoría.

3. **Dado** que existe la subcategoría "Quesos" en "Lácteo" y la subcategoría "Quesos"
   en "Verdura",
   **Cuando** el admin consulta el catálogo,
   **Entonces** ambas subcategorías coexisten correctamente dado que el nombre duplicado
   solo se valida dentro de la misma categoría padre.

---

### Historia de Usuario 3 — Editar una categoría o subcategoría (Prioridad: P2)

El administrador corrige el nombre de una categoría o subcategoría existente cuando
detecta un error o cuando el negocio decide renombrarla. El cambio no afecta los items
que ya la tenían asignada.

**Por qué esta prioridad**: Los errores en nombres de categorías afectan la legibilidad
de reportes e inventarios, pero pueden corregirse en cualquier momento sin impacto
operativo inmediato.

**Prueba Independiente**: Puede verificarse editando el nombre de una categoría y
comprobando que los items que la usaban muestran el nuevo nombre sin pérdida de datos.

**Escenarios de Aceptación**:

1. **Dado** que existe la categoría "Lacteo" (sin tilde, error tipográfico),
   **Cuando** el admin la renombra a "Lácteo" y guarda,
   **Entonces** todos los items que tienen subcategorías de esa categoría muestran el
   nuevo nombre sin perder su clasificación.

2. **Dado** que el admin intenta renombrar una subcategoría con el nombre de otra
   subcategoría dentro de la misma categoría,
   **Cuando** guarda los cambios,
   **Entonces** el sistema rechaza la operación con un mensaje de nombre duplicado.

---

### Historia de Usuario 4 — Inactivar o reactivar una categoría o subcategoría (Prioridad: P2)

El administrador marca como inactiva una categoría o subcategoría que ya no aplica
al negocio, o la reactiva cuando vuelve a ser relevante. La categoría o subcategoría
inactiva no aparece como opción al crear o editar items, pero los items que ya la
tenían asignada conservan su clasificación. Una vez reactivada, vuelve a estar
disponible como opción sin necesidad de recrearla.

**Por qué esta prioridad**: La inactivación preserva la trazabilidad histórica de
reportes sin eliminar datos, en línea con el Principio IV de la constitución.

**Prueba Independiente**: Puede verificarse inactivando una subcategoría y comprobando
que no aparece al crear un nuevo item, pero sí en el historial de los items existentes.

**Escenarios de Aceptación**:

1. **Dado** que existe la subcategoría "Quesos" con items asignados,
   **Cuando** el admin la inactiva,
   **Entonces** "Quesos" no aparece como opción al crear nuevos items, pero los items
   existentes conservan su subcategoría visible en sus fichas.

2. **Dado** que una categoría tiene subcategorías activas,
   **Cuando** el admin intenta inactivar la categoría padre,
   **Entonces** el sistema advierte que existen subcategorías activas y requiere confirmación
   antes de proceder; al confirmar, inactiva la categoría y todas sus subcategorías activas.

3. **Dado** que existe la subcategoría "Quesos" inactiva en "Lácteo",
   **Cuando** el admin la reactiva,
   **Entonces** "Quesos" vuelve a aparecer como opción al crear o editar items, sin pérdida
   de datos ni reasignación de items existentes.

4. **Dado** que existe una categoría inactiva (con subcategorías inactivas por cascade),
   **Cuando** el admin reactiva la categoría,
   **Entonces** la categoría queda activa pero sus subcategorías permanecen inactivas; cada
   subcategoría debe reactivarse individualmente.

---

### Historia de Usuario 5 — Consultar el catálogo de categorías (Prioridad: P1)

El administrador revisa la estructura completa de categorías y subcategorías para
verificar que la clasificación está correctamente configurada antes de crear items.

**Por qué esta prioridad**: El catálogo de categorías es la referencia visual que el
admin usa para planificar la creación de items y verificar la coherencia de la
clasificación.

**Prueba Independiente**: Puede verificarse con múltiples categorías y subcategorías
comprobando que el listado las muestra agrupadas y con su estado.

**Escenarios de Aceptación**:

1. **Dado** que existen categorías con subcategorías activas e inactivas,
   **Cuando** el admin consulta el catálogo de categorías,
   **Entonces** ve las categorías con sus subcategorías agrupadas, cada una con nombre
   y estado (activa/inactiva).

2. **Dado** que el admin consulta el catálogo,
   **Cuando** selecciona una subcategoría,
   **Entonces** puede ver cuántos items del catálogo tienen esa subcategoría asignada.

---

## Requisitos Funcionales

### RF-CAT-01: Gestión de categorías

- RF-CAT-01.1: Solo el administrador puede crear, editar, inactivar y reactivar
  categorías. Cualquier otro rol recibe acceso denegado.
- RF-CAT-01.2: Una categoría requiere como mínimo: nombre. El nombre es único en todo
  el sistema.
- RF-CAT-01.3: No es posible eliminar una categoría; solo inactivarla o reactivarla.
- RF-CAT-01.4: Al inactivar una categoría que tiene subcategorías activas, el sistema
  inactiva también todas sus subcategorías activas, previa confirmación del admin.
- RF-CAT-01.5: Una categoría inactiva no aparece como opción al crear o editar
  subcategorías. Los items que ya tenían subcategorías de esa categoría conservan su
  clasificación.
- RF-CAT-01.6: El catálogo de categorías es compartido entre todas las tiendas de la marca.
- RF-CAT-01.7: Al reactivar una categoría, sus subcategorías permanecen inactivas; deben
  reactivarse individualmente.

### RF-CAT-02: Gestión de subcategorías

- RF-CAT-02.1: Solo el administrador puede crear, editar, inactivar y reactivar
  subcategorías.
- RF-CAT-02.2: Una subcategoría requiere como mínimo: nombre y categoría padre. El
  nombre es único dentro de la categoría padre (puede repetirse en categorías distintas).
  La validación es insensible a mayúsculas/minúsculas ("Quesos" y "quesos" se consideran
  duplicados dentro de la misma categoría).
- RF-CAT-02.3: Una subcategoría pertenece a exactamente una categoría. No puede
  reasignarse a otra categoría una vez creada.
- RF-CAT-02.4: No es posible eliminar una subcategoría; solo inactivarla o reactivarla.
- RF-CAT-02.5: Una subcategoría inactiva no aparece como opción al crear o editar items.
  Los items que ya la tenían asignada conservan su subcategoría visible en sus fichas.

### RF-CAT-03: Relación con items

- RF-CAT-03.1: Un item pertenece a exactamente una subcategoría. Esta asignación es
  obligatoria al crear el item.
- RF-CAT-03.2: El item hereda implícitamente la categoría de su subcategoría. No se
  asigna la categoría directamente al item.
- RF-CAT-03.3: Desde el detalle de una subcategoría, el admin puede ver cuántos items
  la tienen asignada.

### RF-CAT-04: Listado y consulta

- RF-CAT-04.1: El administrador puede consultar el catálogo completo de categorías con
  sus subcategorías agrupadas, mostrando nombre y estado (activa/inactiva).
- RF-CAT-04.2: Desde el listado, el administrador puede acceder al detalle y edición
  de cualquier categoría o subcategoría.

---

## Criterios de Éxito

- **Configuración rápida**: El admin puede registrar el conjunto inicial de categorías
  y subcategorías de la marca (hasta 20 categorías y 100 subcategorías) en menos de
  15 minutos. El listado se renderiza completo sin paginación.
- **Control de acceso**: El 100% de los intentos de gestión de categorías por parte de
  roles no admin son bloqueados.
- **Integridad del catálogo**: El sistema previene el 100% de los casos de nombres
  duplicados dentro del mismo nivel (categorías duplicadas en el sistema; subcategorías
  duplicadas dentro de la misma categoría).
- **Trazabilidad**: Al inactivar una categoría o subcategoría, el 100% de los items que
  la tenían asignada conservan su clasificación visible en reportes e inventarios.
- **Consistencia referencial**: El 100% de los items del catálogo tienen siempre una
  subcategoría y categoría asignada; no puede existir un item sin clasificación.

---

## Entidades Clave

| Entidad | Atributos |
|---------|-----------|
| `Categoria` | nombre (único en sistema, insensible a mayúsculas), activo, creado_por, creado_en, actualizado_por, actualizado_en |
| `Subcategoria` | nombre (único dentro de la categoría, insensible a mayúsculas), categoria_id, activo, creado_por, creado_en, actualizado_por, actualizado_en |

---

## Clarificaciones

### Sesión 2026-05-24

- Q: ¿Puede el administrador reactivar una categoría o subcategoría que fue marcada como inactiva? → A: Sí, el admin puede reactivarla en cualquier momento.
- Q: ¿La validación de nombres duplicados en subcategorías es también insensible a mayúsculas/minúsculas? → A: Sí, misma regla que en categorías ("Quesos" y "quesos" son duplicados dentro de la misma categoría padre).
- Q: ¿Se debe registrar quién realizó cada cambio en categorías y subcategorías? → A: Sí, registrar `creado_por`, `actualizado_por` + timestamps por cada operación (nomenclatura en español).
- Q: ¿Cuántas categorías y subcategorías se estiman en el catálogo de una marca típica? → A: Volumen pequeño — < 20 categorías y < 100 subcategorías en total; sin necesidad de paginación.
- Q: ¿Deben las categorías o subcategorías tener un campo de descripción opcional? → A: No — solo nombre y estado es suficiente para esta versión.

---

## Observabilidad

### Trazas (OTel Spans)

| Nombre del Span | Trigger | Atributos Obligatorios |
|-----------------|---------|------------------------|
| `categorias.crear` | `POST /api/v1/categorias` | `categoria.id`, `user.rol`, `resultado` |
| `categorias.listar` | `GET /api/v1/categorias` | `catalogo.total`, `user.rol`, `cache.hit` |
| `categorias.editar` | `PUT /api/v1/categorias/{id}` | `categoria.id`, `user.rol`, `resultado` |
| `categorias.inactivar` | `PATCH /api/v1/categorias/{id}/inactivar` | `categoria.id`, `subcategorias_inactivadas`, `user.rol`, `resultado` |
| `categorias.reactivar` | `PATCH /api/v1/categorias/{id}/reactivar` | `categoria.id`, `user.rol`, `resultado` |
| `subcategorias.crear` | `POST /api/v1/subcategorias` | `subcategoria.id`, `categoria.id`, `user.rol`, `resultado` |
| `subcategorias.editar` | `PUT /api/v1/subcategorias/{id}` | `subcategoria.id`, `user.rol`, `resultado` |
| `subcategorias.inactivar` | `PATCH /api/v1/subcategorias/{id}/inactivar` | `subcategoria.id`, `categoria.id`, `user.rol`, `resultado` |
| `subcategorias.reactivar` | `PATCH /api/v1/subcategorias/{id}/reactivar` | `subcategoria.id`, `categoria.id`, `user.rol`, `resultado` |

### Métricas

Formato: `[dominio].[entidad].[operacion].[tipo]` · Etiqueta `resultado` obligatoria en escrituras.

| Nombre de Métrica | Tipo | Etiquetas | Descripción |
|-------------------|------|-----------|-------------|
| `catalogo.categoria.crear.total` | Counter | `resultado` | Total de categorías creadas (`success` / `nombre_duplicado` / `validation_error`) |
| `catalogo.categoria.crear.duration` | Histogram (ms) | `resultado` | Latencia de creación de categoría |
| `catalogo.categoria.listar.duration` | Histogram (ms) | `cache_hit` | Latencia del listado completo; `cache_hit=true/false` |
| `catalogo.categoria.inactivar.total` | Counter | `resultado` | Total de inactivaciones de categoría (`success` / `not_found`) |
| `catalogo.subcategoria.crear.total` | Counter | `resultado` | Total de subcategorías creadas |
| `catalogo.subcategoria.crear.duration` | Histogram (ms) | `resultado` | Latencia de creación de subcategoría |
| `catalogo.subcategoria.inactivar.total` | Counter | `resultado` | Total de inactivaciones de subcategoría |

**Notas**:

- `user_id` NUNCA como etiqueta de métrica (alta cardinalidad → coste en Datadog).
- `tienda_id` no aplica: el catálogo es compartido por marca, sin aislamiento por tienda.
- Los logs de operaciones de escritura van a GCP Cloud Logging exclusivamente (stdout → GCP).

---

## Dependencias y Suposiciones

### Dependencias

- **001-autenticacion**: El admin debe estar autenticado para gestionar el catálogo.
- **007-items** (posterior): La subcategoría es prerequisito para crear items. La
  asignación de subcategoría a un item corresponde a esa feature.
- Sin dependencias de otras features del catálogo en la Ola 2 — categorías no requieren
  unidades de medida ni proveedores.

### Suposiciones

- El catálogo de categorías y subcategorías no se precarga automáticamente; el admin
  las crea manualmente según la estructura de su negocio.
- El volumen esperado es pequeño (< 20 categorías, < 100 subcategorías); el listado
  completo puede renderizarse sin paginación.
- Una subcategoría no puede reasignarse a otra categoría una vez creada. Si se necesita
  mover una subcategoría, el flujo es: inactivar la subcategoría original y crear una
  nueva en la categoría destino.
- No existe un tercer nivel de clasificación (solo categoría → subcategoría → item).
- Los nombres de categorías y subcategorías no distinguen entre mayúsculas y minúsculas
  para la validación de duplicados (ej. "Lácteo" y "lácteo" se consideran duplicados en
  categorías; "Quesos" y "quesos" se consideran duplicados dentro de la misma categoría).

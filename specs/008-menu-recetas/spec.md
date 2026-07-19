# Especificación de Feature: Menú y Recetas

**Branch de Feature**: `008-menu-recetas`
**Creado**: 2026-05-21
**Estado**: Borrador
**Referencia funcional**: [§3.3 Módulo: Catálogo — Submenú Productos](../loopi-v2-funcional/spec.md)

---

## Clarifications

### Session 2026-07-12

- Q: ¿El mismo producto de menú puede tener códigos POS distintos en cada tienda? →
  A: No. El código POS es único global: un solo código por producto, igual en todas
  las tiendas.
- Q: ¿Qué alcance tiene 008 respecto al descuento de inventario por venta? →
  A: Solo modelo. 008 implementa el CRUD de menú, categorías y recetas con versionado.
  El registro de ventas, el descuento de inventario y las alertas por venta sin receta
  activa quedan completamente fuera de alcance de 008 y se implementan en
  012-ventas-integracion-pos; esta spec no describe ese comportamiento ni siquiera como
  referencia informativa.
- Q: ¿Cuál es el ciclo de vida de una receta al crearla o modificarla? →
  A: Activación inmediata, sin borradores. Guardar una receta válida la activa de
  inmediato y archiva la versión anterior. Estados: activa → archivada.
- Q: ¿Qué sucede cuando un insumo que forma parte de una receta activa se inactiva
  en el catálogo? → A: La inactivación del item no se bloquea. La receta permanece
  activa, pero la consulta del menú resalta las recetas con insumos inactivos. No se
  genera ninguna alerta.
- Q: ¿Se pueden inactivar las categorías de menú y bajo qué regla? → A: Sí, libremente.
  Una categoría puede inactivarse en cualquier momento; sus productos activos dejan de
  mostrarse en el menú hasta reasignarlos a otra categoría o reactivar la categoría.
- Q: ¿Dónde y cómo se gestionan las categorías de menú, dado que son independientes de
  las categorías del catálogo de items? → A: Con una Historia de Usuario dedicada dentro
  de 008 (crear, editar, inactivar, reactivar), con nombre único, siguiendo el mismo
  patrón que 005-categorias-catalogo.
- Q: ¿Qué debe mostrar el historial de versiones de una receta? → A: En el MVP, solo el
  número de versión y las fechas de vigencia de cada versión archivada. El detalle
  completo de ingredientes de una versión archivada queda documentado como Fuera de
  Alcance para una iteración futura.

---

## Escenarios de Usuario y Pruebas *(obligatorio)*

### Historia de Usuario 1 — Crear un producto de menú simple (Prioridad: P1)

El administrador registra un producto que se vende al cliente (ej: "Sanduche Capresse")
asignándole nombre, categoría de menú, precio de venta y código POS. Una vez creado,
puede asociarle una receta que quedará disponible como base para el descuento automático
de inventario que ejecuta el módulo de ventas (012-ventas-integracion-pos).

**Por qué esta prioridad**: Sin productos de menú con receta activa no hay base para el
descuento automático de inventario por ventas, que es el propósito central del sistema
POS de Loopi.

**Prueba Independiente**: Puede verificarse creando un producto con su receta y comprobando
que queda registrado con nombre, categoría, precio, código POS y receta activa consultables.

**Escenarios de Aceptación**:

1. **Dado** que el admin crea el producto "Sanduche Capresse" con categoría "Sanduchería",
   precio $18 000 y código POS `SAN-CAP`,
   **Cuando** guarda el producto,
   **Entonces** el producto queda activo en el menú compartido de todas las tiendas.

2. **Dado** que ya existe un producto con el código POS `SAN-CAP` en el menú,
   **Cuando** el admin intenta crear otro con el mismo código POS,
   **Entonces** el sistema rechaza la operación indicando que el código POS ya existe.

3. **Dado** que un lider_tienda o barista intenta gestionar el menú,
   **Cuando** accede a esa sección,
   **Entonces** el sistema deniega el acceso; solo el admin puede gestionar el menú y
   las recetas.

---

### Historia de Usuario 2 — Crear un producto con variantes (Prioridad: P1)

El administrador registra un producto con múltiples presentaciones (ej: "Latte" en tamaños
S, M y L), cada una con su propio precio, código POS y receta. El producto padre actúa
como agrupador de menú; las variantes son los productos de menú reales, cada una con su
propia receta.

**Por qué esta prioridad**: La mayoría de los productos de cafetería tienen variantes por
tamaño; sin este modelo, el admin tendría que crear productos completamente independientes
sin relación visual entre ellos.

**Prueba Independiente**: Puede verificarse creando un producto padre con dos variantes y
comprobando que en el punto de venta aparecen agrupadas bajo el mismo producto padre.

**Escenarios de Aceptación**:

1. **Dado** que el admin crea el producto padre "Latte" (sin precio ni código POS) y luego
   crea las variantes "Latte S" ($6 000, `LAT-S`) y "Latte M" ($8 000, `LAT-M`) vinculadas
   a "Latte",
   **Cuando** consulta el menú,
   **Entonces** ve "Latte S" y "Latte M" agrupadas bajo "Latte" en la categoría correspondiente.

2. **Dado** que existe el producto padre "Latte" con variantes activas,
   **Cuando** el admin intenta inactivar "Latte" directamente,
   **Entonces** el sistema no permite inactivar el producto padre mientras tenga variantes
   activas, e indica que primero deben inactivarse todas sus variantes.

3. **Dado** que el admin intenta asignar una receta directamente al producto padre "Latte",
   **Cuando** intenta guardar,
   **Entonces** el sistema rechaza la operación indicando que los productos padre no tienen
   receta propia; las recetas se asignan a las variantes.

---

### Historia de Usuario 3 — Crear y versionar una receta (Prioridad: P1)

El administrador define la composición de ingredientes de un producto o variante de menú
indicando cada insumo, la cantidad y la unidad de medida. Cuando la receta cambia (ajuste
de ingredientes, nueva proporción), crea una nueva versión que reemplaza a la anterior,
la cual queda archivada para trazabilidad.

**Por qué esta prioridad**: La receta es el puente entre ventas e inventario: define qué
insumos y en qué cantidad componen cada producto. Sin receta activa y bien definida, el
módulo de ventas (012) no tiene base para descontar inventario ni el sistema tiene
trazabilidad de consumo.

**Prueba Independiente**: Puede verificarse creando la receta de un producto y confirmando
que la explosión de ingredientes (cada insumo con su cantidad y unidad, convertida a la
unidad de medida canónica del insumo) coincide exactamente con lo definido.

**Escenarios de Aceptación**:

1. **Dado** que existe el producto "Sanduche Capresse",
   **Cuando** el admin crea la receta con los ingredientes (pan, tomate, lechuga, pollo,
   salsa pesto, salsa tomate) con sus cantidades y unidades,
   **Entonces** la receta queda activa como la receta vigente del producto.

2. **Dado** que "Sanduche Capresse" tiene una receta activa (v1),
   **Cuando** el admin crea una receta modificada (v2) para el mismo producto,
   **Entonces** la receta v2 pasa a ser la activa, y la v1 queda archivada con su fecha de
   vigencia visible en el historial de versiones para auditoría.

3. **Dado** que el admin intenta crear una línea de receta con una unidad que no tiene
   equivalencia configurada con la unidad de medida del insumo,
   **Cuando** intenta guardar,
   **Entonces** el sistema rechaza la línea indicando que las unidades son incompatibles.

---

### Historia de Usuario 4 — Editar un producto de menú (Prioridad: P2)

El administrador actualiza los datos de un producto existente cuando cambia el precio,
el nombre o la categoría de menú. Los cambios aplican a todas las tiendas de inmediato.

**Por qué esta prioridad**: Precios y nombres de productos cambian con el tiempo; el admin
debe poder mantenerlos actualizados sin perder la receta asociada.

**Prueba Independiente**: Puede verificarse editando el precio de un producto y comprobando
que el nuevo valor queda reflejado en el producto sin afectar su receta activa.

**Escenarios de Aceptación**:

1. **Dado** que existe el producto "Latte M" con precio $8 000,
   **Cuando** el admin lo actualiza a $9 000 y guarda,
   **Entonces** el producto queda actualizado con el nuevo precio de venta, sin afectar
   su receta activa.

2. **Dado** que el admin intenta cambiar el código POS de un producto,
   **Cuando** el nuevo código ya existe en el menú,
   **Entonces** el sistema rechaza el cambio con mensaje de código duplicado.

---

### Historia de Usuario 5 — Consultar el menú y sus recetas (Prioridad: P1)

El administrador revisa la estructura completa del menú, sus productos, variantes y recetas
activas para verificar que todo está correctamente configurado antes de iniciar operaciones.

**Por qué esta prioridad**: El admin necesita una vista centralizada del menú para auditar
que cada producto que se vende tiene receta activa y que los ingredientes son correctos.

**Prueba Independiente**: Puede verificarse con varios productos (con y sin receta) y
comprobando que el listado los diferencia visualmente y resalta los que no tienen receta.

**Escenarios de Aceptación**:

1. **Dado** que existen productos con receta activa, productos sin receta y productos padre
   con variantes,
   **Cuando** el admin consulta el menú,
   **Entonces** ve todos los productos agrupados por categoría de menú, con indicación
   visual de cuáles tienen receta activa y cuáles no.

2. **Dado** que el admin selecciona un producto con receta,
   **Cuando** accede a su detalle,
   **Entonces** ve la receta activa con todos sus ingredientes (cantidad y unidad) y el
   historial de versiones anteriores con número y fechas de vigencia (el detalle de
   ingredientes de versiones archivadas queda fuera de alcance del MVP).

---

### Historia de Usuario 6 — Gestionar categorías de menú (Prioridad: P1)

El administrador crea, edita, inactiva y reactiva las categorías que agrupan los productos
del menú (ej: Bebidas, Sanduchería, Postres), independientes de las categorías del
catálogo de items.

**Por qué esta prioridad**: Sin categorías de menú no es posible crear productos, ya que
la categoría es un campo obligatorio (RF-MEN-01.2).

**Prueba Independiente**: Puede verificarse creando una categoría, editando su nombre,
inactivándola y comprobando que sus productos activos dejan de mostrarse en el menú, y
reactivándola.

**Escenarios de Aceptación**:

1. **Dado** que el admin crea la categoría "Bebidas",
   **Cuando** guarda,
   **Entonces** la categoría queda activa y disponible para asignar a productos de menú.

2. **Dado** que ya existe una categoría "Bebidas",
   **Cuando** el admin intenta crear otra categoría con el mismo nombre (sin distinguir
   mayúsculas/minúsculas),
   **Entonces** el sistema rechaza la operación indicando que el nombre ya existe.

3. **Dado** que existe la categoría "Postres" con productos activos asignados,
   **Cuando** el admin la inactiva,
   **Entonces** la categoría queda inactiva y sus productos activos dejan de mostrarse en
   el menú, sin cambiar el estado propio de esos productos.

4. **Dado** que existe una categoría inactiva,
   **Cuando** el admin la reactiva,
   **Entonces** la categoría vuelve a estar disponible y sus productos activos vuelven a
   mostrarse en el menú.

5. **Dado** que un lider_tienda o barista intenta gestionar categorías de menú,
   **Cuando** accede a esa sección,
   **Entonces** el sistema deniega el acceso; solo el admin puede gestionar categorías
   de menú.

---

## Requisitos Funcionales

### RF-MEN-01: Gestión de productos de menú

- RF-MEN-01.1: Solo el administrador puede crear, editar e inactivar productos de menú.
- RF-MEN-01.2: Un producto simple requiere: nombre, categoría de menú, precio de venta y
  código POS. Un producto padre requiere solo: nombre y categoría de menú (sin precio ni
  código POS).
- RF-MEN-01.3: El código POS es único global: cada producto tiene un solo código POS,
  el mismo en todas las tiendas de la marca.
- RF-MEN-01.4: Los productos de menú son compartidos entre todas las tiendas de la marca.
- RF-MEN-01.5: No es posible eliminar un producto; solo inactivarlo.
- RF-MEN-01.6: Para inactivar un producto padre, primero deben inactivarse todas sus
  variantes activas.

### RF-MEN-02: Variantes de producto

- RF-MEN-02.1: Una variante es un producto de menú con `producto_padre` asignado. Tiene
  su propio precio, código POS y receta.
- RF-MEN-02.2: Un producto padre no tiene precio de venta, código POS ni receta propia.
  Actúa únicamente como agrupador visual en el menú.
- RF-MEN-02.3: Un producto sin `producto_padre` es un producto simple y puede tener
  receta directa.
- RF-MEN-02.4: No existe más de un nivel de anidamiento; una variante no puede ser padre
  de otras variantes.

### RF-MEN-03: Categorías de menú

- RF-MEN-03.1: La categoría de menú agrupa productos para la vista del punto de venta
  (ej: Bebidas, Sanduchería, Postres). Es independiente de las categorías del catálogo
  de items.
- RF-MEN-03.2: El administrador puede crear, editar, inactivar y reactivar categorías de
  menú. No se precarga ninguna categoría por defecto.
- RF-MEN-03.3: Una categoría de menú puede inactivarse en cualquier momento, sin
  restricción por productos asignados. Los productos activos de una categoría inactiva
  dejan de mostrarse en el menú hasta que se reasignen a otra categoría o la categoría
  se reactive; los productos conservan su estado y sus recetas.
- RF-MEN-03.4: El nombre de la categoría de menú es único (insensible a
  mayúsculas/minúsculas) entre todas las categorías de menú, activas e inactivas.

### RF-REC-01: Gestión de recetas

- RF-REC-01.1: Solo el administrador puede crear y modificar recetas.
- RF-REC-01.2: Cada producto simple o variante puede tener como máximo una receta activa.
  Los productos padre no tienen receta.
- RF-REC-01.3: Modificar una receta crea una nueva versión; la versión anterior queda
  archivada con su fecha de vigencia. El historial de versiones no se elimina.
- RF-REC-01.4: No existen recetas en borrador. Guardar una receta válida la activa de
  inmediato y archiva la versión anterior (si existe). Una receta solo puede guardarse
  si tiene al menos una línea de ingrediente válida; los únicos estados posibles son
  activa y archivada.
- RF-REC-01.5: Cada línea de receta requiere: insumo del catálogo (item activo al momento
  de guardar la receta), cantidad mayor que cero y unidad de medida con equivalencia
  configurada respecto a la unidad de medida del insumo.
- RF-REC-01.6: Si un insumo de una receta activa se inactiva posteriormente en el catálogo,
  la inactivación no se bloquea y la receta permanece activa. La consulta del menú resalta
  las recetas que contienen insumos inactivos; no se genera ninguna alerta.

### RF-REC-02: Listado y consulta

- RF-REC-02.1: El administrador puede consultar el menú completo agrupado por categoría
  con indicación de si cada producto tiene receta activa.
- RF-REC-02.2: Desde el detalle de un producto, el admin puede ver la receta activa con
  todos sus ingredientes (item, cantidad y unidad), y el historial de versiones
  anteriores con su número de versión y fechas de vigencia. Ver el detalle completo de
  ingredientes de una versión archivada específica está fuera de alcance del MVP
  (ver `## Fuera de Alcance`).

---

## Criterios de Éxito

- **Cobertura de recetas**: El listado del menú resalta el 100% de los productos activos
  (simples y variantes) que no tienen receta activa, para que el admin los complete antes
  de iniciar operaciones.
- **Integridad de recetas**: El 100% de las líneas de receta guardadas tienen cantidad
  mayor que cero y unidad de medida con equivalencia configurada respecto a la unidad del
  insumo; el sistema rechaza cualquier línea que no la tenga.
- **Trazabilidad de versiones**: Toda modificación de receta genera una nueva versión
  archivada; el 100% del historial (número de versión y fechas de vigencia) es accesible
  para el admin.
- **Unicidad de categorías**: El 100% de los intentos de crear o renombrar una categoría
  de menú con un nombre ya existente son rechazados.
- **Control de acceso**: El 100% de los intentos de gestión del menú, categorías o
  recetas por roles no admin son bloqueados.

---

## Entidades Clave

| Entidad | Atributos |
|---------|-----------|
| `ProductoMenu` | nombre, categoria_menu_id, producto_padre_id, precio_venta, codigo_pos, activo |
| `CategoriaMenu` | nombre, activo |
| `Receta` | producto_menu_id, version, activa_desde, activo |
| `LineaReceta` | receta_id, item_id, cantidad, unidad_medida_id |

---

## Fuera de Alcance

- **Detalle completo de versiones archivadas de receta**: el historial de versiones de
  una receta (RF-REC-02.2) muestra únicamente el número de versión y las fechas de
  vigencia de cada versión archivada. Consultar el detalle completo de ingredientes
  (item, cantidad, unidad) de una versión archivada específica queda fuera de alcance
  del MVP; se considera para una iteración futura. La versión activa sí expone su
  detalle completo de ingredientes.

---

## Dependencias y Suposiciones

### Dependencias

- **001-autenticacion**: El admin debe estar autenticado para gestionar el menú y recetas.
- **004-unidades-medida**: Las unidades de medida de las líneas de receta deben tener
  equivalencia configurada con la unidad de medida del insumo correspondiente.
- **007-items-catalogo**: Los ingredientes de las recetas son items activos del catálogo.
- **012-ventas-integracion-pos** (posterior): consume el menú y las recetas activas
  definidas en esta feature para registrar ventas y ejecutar el descuento de inventario
  correspondiente. El descuento de inventario por venta está fuera del alcance de 008.

### Suposiciones

- Las categorías de menú (Bebidas, Sanduchería, etc.) son independientes de las categorías
  del catálogo de items; el admin las crea y gestiona en este módulo.
- El código POS es único global: todas las tiendas de la marca usan el mismo código POS
  para el mismo producto (formerly referred to as "único por tienda").
- Un producto padre no es vendible directamente; solo sus variantes lo son.
- No existe un tercer nivel de variantes; la jerarquía máxima es producto padre → variante.
- La receta define el consumo esperado por unidad vendida; la aplicación de ese consumo
  al registrar ventas es responsabilidad de 012-ventas-integracion-pos.
- Las recetas anteriores (archivadas) son de solo lectura; no pueden reactivarse. Para volver
  a una composición anterior, el admin debe crear una nueva versión con esos ingredientes.

---

## Observabilidad

### Trazas (Spans OTel)

| Operación | Nombre del Span | Atributos Obligatorios |
|---|---|---|
| Crear producto de menú | `menu.productos.crear` | `resultado`, `producto.codigo_pos` |
| Actualizar producto de menú | `menu.productos.actualizar` | `resultado`, `producto.id` |
| Inactivar / reactivar producto | `menu.productos.cambiar_estado` | `resultado`, `producto.id`, `producto.estado` |
| Crear categoría de menú | `menu.categorias.crear` | `resultado` |
| Actualizar categoría de menú | `menu.categorias.actualizar` | `resultado`, `categoria.id` |
| Inactivar / reactivar categoría | `menu.categorias.cambiar_estado` | `resultado`, `categoria.id`, `categoria.estado` |
| Crear versión de receta | `recetas.crear_version` | `resultado`, `producto.id`, `receta.version` |

### Métricas

| Nombre | Tipo | Unidad | Descripción | Etiquetas |
|---|---|---|---|---|
| `menu.productos.creacion.duration` | Histograma | ms | Duración de la creación de un producto de menú | `resultado` |
| `menu.productos.creacion.total` | Contador | — | Conteo de creaciones de producto por resultado | `resultado` |
| `menu.productos.actualizacion.duration` | Histograma | ms | Duración de la actualización de un producto | `resultado` |
| `menu.productos.actualizacion.total` | Contador | — | Conteo de actualizaciones de producto por resultado | `resultado` |
| `recetas.version.creacion.duration` | Histograma | ms | Duración de la creación de una versión de receta | `resultado` |
| `recetas.version.creacion.total` | Contador | — | Conteo de versiones de receta creadas por resultado | `resultado` |
| `menu.listado.duration` | Histograma | ms | Latencia del listado del menú agrupado por categoría | — |

**Valores de la etiqueta `resultado`**: `success`, `codigo_pos_duplicado`,
`nombre_categoria_duplicado`, `padre_con_variantes_activas`, `receta_en_producto_padre`,
`sin_lineas`, `unidades_incompatibles`, `item_inactivo`, `validation_error`, `not_found`.

**Nota de cardinalidad**: `user_id` nunca se incluye como etiqueta de métrica (alta
cardinalidad); va como atributo del span. El menú y las recetas son catálogo compartido
por marca (RF-MEN-01.4), por lo que ninguna operación de esta feature lleva `tienda_id`;
el descuento de inventario por venta, que sí es por tienda, se instrumenta en
`012-ventas-integracion-pos`.

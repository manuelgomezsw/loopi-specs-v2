# Especificación de Feature: Ventas e Integración POS

**Branch de Feature**: `012-ventas-integracion-pos`
**Creado**: 2026-05-22
**Estado**: Borrador
**Entrada**: Descripción del usuario: "Ventas e integración POS: procesamiento de ventas provenientes del sistema POS externo (archivo plano adjunto), descuento automático de inventario por receta y gestión de estados de ventas importadas (procesada, duplicada, pendiente_receta, error). Basado en §3.6 de specs/loopi-v2-funcional/spec.md"

## Escenarios de Usuario y Pruebas *(obligatorio)*

### Historia de Usuario 1 - Importar archivo plano de ventas (Prioridad: P1)

El administrador descarga el reporte de ventas exportado por el sistema POS al final del día (un archivo separado por punto y coma) y lo sube a Loopi. El sistema valida el archivo, muestra un resumen previo (artículos encontrados, artículos sin coincidencia, total de unidades) y, tras confirmación del admin, procesa cada línea: descuenta el inventario de la tienda según la receta activa de cada producto y registra el estado de cada venta.

**Por qué esta prioridad**: Es el flujo principal de integración. Sin él, las ventas no impactan el inventario y la proyección de stock queda desactualizada.

**Prueba Independiente**: Puede testearse completamente subiendo un archivo CSV de prueba y verificando que el inventario de la tienda refleja los descuentos calculados por receta al finalizar el proceso.

**Escenarios de Aceptación**:

1. **Dado** un archivo CSV válido con 50 líneas de productos con receta activa, **Cuando** el admin lo sube y confirma, **Entonces** el inventario de la tienda se descuenta en la cantidad correspondiente (unidades vendidas × cantidad en receta) para cada insumo involucrado, y todas las ventas quedan en estado `procesada`.
2. **Dado** un archivo CSV que incluye productos sin receta activa, **Cuando** el admin confirma la importación, **Entonces** esos productos quedan en estado `pendiente_receta` y el inventario **no** se descuenta para ellos.
3. **Dado** que el stock de un insumo es insuficiente para cubrir la demanda, **Cuando** se procesa la venta, **Entonces** el sistema registra el stock en negativo y marca la venta como `procesada` (el descuento se aplica igual).
4. **Dado** un archivo con la última fila de totales o filas con artículo vacío, **Cuando** el sistema lo procesa, **Entonces** esas filas son ignoradas automáticamente sin generar errores.

---

### Historia de Usuario 2 - Gestionar ventas en estado pendiente_receta (Prioridad: P2)

Después de importar un archivo con productos sin receta, el admin asigna la receta faltante al producto correspondiente y ordena el reprocesamiento de las ventas que quedaron en estado `pendiente_receta`. El sistema aplica entonces el descuento de inventario retroactivamente.

**Por qué esta prioridad**: Cierra el ciclo de integración: garantiza que ninguna venta quede sin impactar el inventario indefinidamente.

**Prueba Independiente**: Puede testearse creando un producto sin receta, importando ventas de ese producto, asignando la receta y ejecutando el reprocesamiento, verificando que el inventario se descuenta correctamente.

**Escenarios de Aceptación**:

1. **Dado** ventas en estado `pendiente_receta` para el producto "Latte 9 oz", **Cuando** el admin asigna la receta activa a ese producto y ordena el reprocesamiento, **Entonces** las ventas pasan a estado `procesada` y el inventario se descuenta usando la receta asignada.
2. **Dado** que se intenta reprocesar una venta `pendiente_receta` pero el producto sigue sin receta, **Entonces** la venta permanece en estado `pendiente_receta` y el sistema informa que aún no hay receta disponible.

---

### Historia de Usuario 3 - Visualizar historial de ventas importadas (Prioridad: P3)

El admin y el líder de tienda consultan el listado de lotes importados y el detalle de cada venta, filtrando por tienda, fecha y estado. Pueden identificar rápidamente qué productos tienen ventas pendientes de receta o con errores.

**Por qué esta prioridad**: Brinda visibilidad operacional y permite auditar el impacto de cada importación sobre el inventario.

**Prueba Independiente**: Puede testearse verificando que el listado muestre correctamente los estados y que los filtros devuelvan únicamente los registros correspondientes.

**Escenarios de Aceptación**:

1. **Dado** múltiples lotes importados, **Cuando** el admin filtra por estado `pendiente_receta`, **Entonces** solo aparecen las ventas que aún no han descontado inventario.
2. **Dado** que el líder de tienda consulta el historial, **Entonces** solo ve los lotes y ventas de su propia tienda.
3. **Dado** un lote importado, **Cuando** el admin hace clic en él, **Entonces** ve el detalle línea a línea con estado, artículo, unidades y producto del catálogo mapeado.

---

### Casos Borde

- ¿Qué ocurre si el archivo CSV viene con codificación de caracteres diferente (ej. Latin-1 en vez de UTF-8)? El sistema normaliza la codificación al procesar el campo `Artículo` para la comparación con `codigo_pos`.
- ¿Qué ocurre si un artículo del CSV tiene el campo `Artículo` vacío (ej. fila de totales)? La fila se ignora automáticamente.
- ¿Qué ocurre si la cantidad vendida (`Uds.V`) es 0 o negativa? La fila se ignora y no genera movimiento de inventario.
- ¿Qué ocurre si el archivo está vacío o no tiene líneas de datos válidas? El sistema rechaza la importación con un mensaje claro antes de solicitar confirmación.
- ¿Qué ocurre si el archivo contiene transacciones de múltiples fechas (ej. exportación de varios días)? El sistema procesa todas las filas válidas; la detección de duplicados opera a nivel de transacción individual, no de rango de fechas.
- ¿Cómo se comporta el sistema si el procesamiento de un lote se interrumpe a mitad (ej. corte de conexión)? Las ventas ya procesadas permanecen; el lote queda en estado `error` y puede reprocesarse desde el inicio (la idempotencia por transacción evita dobles descuentos).
- ¿Qué ocurre si dos transacciones en el mismo archivo tienen idénticos valores de `Fecha`, `Hora` y `Artículo`? Se procesa la primera y la segunda queda como `duplicada` dentro del mismo lote.

## Requisitos *(obligatorio)*

### Requisitos Funcionales

#### Importación por archivo plano

- **RF-001**: El sistema DEBE aceptar la carga de archivos en el formato de reporte de ventas del POS: separado por punto y coma, con encabezado en la primera fila, y columnas en el orden: `#`, `Fecha`, `Hora`, `Artículo`, `Nombre`, `Uds.V`, `% Popularidad`, `Venta`, `Venta %ST`. Cada fila representa una transacción individual con su fecha y hora exactas.
- **RF-002**: El sistema DEBE ignorar automáticamente filas con artículo vacío, filas de totales y filas con cantidad vendida igual a cero o negativa.
- **RF-003**: Antes de procesar el lote, el sistema DEBE mostrar al admin un resumen de validación que incluya: total de líneas válidas, artículos mapeados al catálogo, artículos sin mapeo y período al que corresponde la importación.
- **RF-004**: El sistema DEBE requerir la confirmación explícita del admin antes de aplicar cualquier descuento de inventario proveniente de una importación por archivo plano (RN-VTA-04).
- **RF-005**: El sistema DEBE asociar cada importación a una tienda específica y a un período (fecha del reporte).

#### Mapeo de artículos

- **RF-006**: El sistema DEBE vincular cada transacción del archivo con un producto del catálogo usando el campo `Artículo` del archivo contra el campo `codigo_pos` del catálogo. El admin configura el `codigo_pos` de cada producto/variante en Loopi para que coincida exactamente con el valor del campo `Artículo` del POS (con normalización básica: recorte de espacios y comparación sin distinción de mayúsculas/minúsculas). El campo `Nombre` del archivo es informativo y no se usa para el mapeo.
- **RF-007**: Los artículos del archivo que no tengan un producto mapeado en el catálogo DEBEN quedar registrados en el lote de importación con estado `error` y ser visibles para el admin en el resumen de validación.

#### Idempotencia

- **RF-008**: El sistema DEBE detectar transacciones duplicadas a nivel individual: la clave de idempotencia es la combinación de `tienda_id + Fecha + Hora + Artículo`. Si una transacción con esa combinación ya existe, se registra como `duplicada` sin impactar el inventario.
- **RF-009**: La fecha y hora de cada transacción se obtienen directamente de los campos `Fecha` y `Hora` del archivo, no de la fecha de importación. El sistema usa estos valores para fechar los movimientos de inventario y detectar duplicados.

#### Procesamiento y descuento de inventario

- **RF-010**: Por cada venta con receta activa y mapeo válido, el sistema DEBE descontar del inventario de la tienda la cantidad resultante de multiplicar las unidades vendidas por la cantidad de cada insumo definida en la receta (RN-VTA-02).
- **RF-011**: Si un producto no tiene receta activa, la venta DEBE quedar en estado `pendiente_receta` sin generar descuento de inventario (RN-VTA-03).
- **RF-012**: Si el stock de un insumo queda negativo tras el descuento, el sistema DEBE registrar el stock en negativo; el procesamiento de la venta continúa (RN-VTA-01 y flujo §3.6.4).
- **RF-013**: El sistema DEBE aplicar la receta vigente al momento de la venta, usando el timestamp (`Fecha` + `Hora`) incluido en cada fila del archivo.
- **RF-014**: Los artículos del CSV con precio de venta = $0 y unidades vendidas > 0 (modificadores/adiciones como leche deslactosada, salsa arequipe) DEBEN procesarse de la misma forma que cualquier otra línea: si tienen receta activa, descuentan inventario.

#### Reprocesamiento de ventas pendiente_receta

- **RF-015**: El admin DEBE poder reprocesar manualmente las ventas en estado `pendiente_receta` una vez que el producto tenga una receta activa asignada.
- **RF-016**: Al reprocesar, el sistema DEBE aplicar el descuento de inventario con la receta activa en el momento del reprocesamiento y cambiar el estado de la venta a `procesada`.

#### Visualización y trazabilidad

- **RF-019**: El sistema DEBE mantener un registro de todos los lotes de importación con: fecha, tienda, estado del lote, resumen de resultados (procesadas, duplicadas, pendiente_receta, error).
- **RF-020**: El admin DEBE poder ver el detalle línea a línea de cada lote con el estado individual de cada venta.
- **RF-021**: El líder de tienda DEBE poder ver el historial de ventas únicamente de su tienda asignada (RN-TDA-05).
- **RF-022**: El sistema DEBE permitir filtrar ventas por estado, fecha y tienda.

#### Bloqueo de Ventas Durante Conteo Activo (RF-INV-05 Compliance de 009-inventario-conteo)

- **RF-023**: Mientras existe un inventario con estado `en_progreso` en una tienda,
  **NO se permite iniciar la importación de ventas por archivo plano en esa tienda.**
  La validación ocurre **ANTES** de permitir la carga o procesamiento del archivo.
- **RF-024**: Si se intenta cargar un archivo de ventas cuando hay conteo activo,
  el sistema retorna HTTP 409 Conflict con código de error `inventario_activo` y
  mensaje: "No se pueden procesar ventas mientras hay un conteo en progreso.
  Contacte al líder de tienda o administrador para completar o cancelar el conteo actual."
- **RF-025**: Esta restricción garantiza que el `valor_sugerido` (snapshot tomado al
  inicio del conteo en 009) permanece estable durante la duración del conteo.

### Entidades Clave

- **LoteImportacion**: Agrupación de ventas procesadas en una sesión de importación. Atributos clave: tienda, fecha_reporte, fecha_importacion, estado_lote, total_líneas, procesadas, duplicadas, pendiente_receta, error.
- **VentaImportada**: Registro individual de cada línea procesada. Atributos clave: lote, nombre_articulo_pos, producto_catalogo (nullable), cantidad_vendida, estado (`procesada`/`duplicada`/`pendiente_receta`/`error`), detalle_error.
- **MovimientoInventario**: Registro del descuento generado en el inventario por una venta. Referencia a la venta y al insumo descontado.

## Criterios de Éxito *(obligatorio)*

### Resultados Medibles

- **CE-001**: El 100% de las ventas de productos con receta activa y mapeo válido generan descuento de inventario automático sin intervención adicional del admin.
- **CE-002**: El ciclo completo de importación (carga + validación + confirmación + procesamiento) para un archivo de hasta 100 artículos se completa en menos de 2 minutos.
- **CE-003**: El admin puede identificar y reprocesar todas las ventas en estado `pendiente_receta` sin pérdida de información, una vez asignada la receta al producto.
- **CE-004**: El stock proyectado de la tienda refleja el impacto de las ventas importadas el mismo día de la importación.

## Supuestos

- El sistema POS actual solo soporta exportación por archivo plano (no tiene API REST disponible); la integración vía servicio web queda diferida para una fase posterior.
- El formato del archivo es: separado por punto y coma, con encabezado en la primera fila, codificación Latin-1 o UTF-8, y columnas en el orden: `#`, `Fecha` (DD/MM/AAAA), `Hora` (HH:MM:SS), `Artículo`, `Nombre`, `Uds.V`, `% Popularidad`, `Venta`, `Venta %ST`. Cada fila es una transacción individual.
- La última fila del archivo (fila de totales, identificada por campo `Artículo` vacío) se ignora automáticamente.
- Un lote de importación pertenece a exactamente una tienda; el admin selecciona la tienda al momento de la importación.
- El admin configura el `codigo_pos` de cada producto/variante en el catálogo de Loopi para que coincida con el valor del campo `Artículo` del POS, antes de la primera importación.
- La receta utilizada para calcular el descuento es la receta activa al momento del timestamp de cada transacción (`Fecha` + `Hora` del archivo).
- El stock puede quedar en valores negativos; el sistema registra la alerta pero no bloquea el procesamiento.
- Los modificadores con precio $0 (ej. "Sin Endulzante", "Leche Deslactosada") siguen el mismo tratamiento que cualquier producto: si tienen receta, descuentan inventario; si no, quedan `pendiente_receta`.
- El reprocesamiento de ventas `pendiente_receta` es una acción manual del admin, no automática al guardar la receta.

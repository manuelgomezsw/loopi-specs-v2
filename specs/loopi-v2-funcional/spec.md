# Especificación Funcional del Sistema: Loopi v2

**Versión**: 1.0  
**Fecha**: 2026-05-14  
**Estado**: Borrador  
**Autor**: Equipo de Producto  
**Repositorio base (v1)**: `github.com/manuelgomezsw/loopi-api`

---

## 1. Visión General del Sistema

Loopi v2 es un sistema de gestión de inventarios orientado a puntos de venta de café de especialidad. Su propósito central es darle al operador de tienda visibilidad en tiempo real sobre el stock de insumos, automatizar la proyección de pedidos y garantizar trazabilidad completa de todos los movimientos que afectan el inventario: compras, ventas (vía integración POS), mermas y conteos físicos.

### 1.1 Problema que Resuelve

Los puntos de venta gestionan decenas de insumos con diferentes unidades de medida, múltiples proveedores y variabilidad en la demanda diaria. Sin un sistema centralizado, el operador pierde trazabilidad del stock, realiza pedidos subóptimos y no detecta mermas a tiempo. Loopi v2 cierra esa brecha.

### 1.2 Alcance del Sistema

**Dentro del alcance:**

- Gestión del catálogo de items (insumos, materiales de consumo, activos)
- Gestión de recetas y menú de productos finales
- Conteo físico de inventario (diario, semanal, mensual)
- Registro de mermas
- Recepción de compras y pedidos
- Planeación de la demanda y generación automática de pedidos
- Integración con sistema POS para importar ventas
- Módulo de administración (empleados, proveedores, categorías)

**Fuera del alcance:**

- Registro manual de ventas (las ventas provienen exclusivamente del POS)
- Facturación electrónica
- Gestión de cuentas por pagar a proveedores
- Multi-tienda (se contempla para v3)

---

## 2. Usuarios y Roles

### 2.1 Roles del Sistema

| Rol | Descripción | Accesos |
|-----|-------------|---------|
| `admin` | Administrador de la tienda o del negocio | Acceso total: catálogo, reportes, pedidos, configuración |
| `lider_tienda` | Líder de turno responsable del conteo | Inventario diario, mermas, recepción de compras |
| `empleado` | Empleado de tienda | Solo lectura de inventario en curso |

### 2.2 Autenticación

- Autenticación mediante usuario y contraseña con token JWT.
- El token tiene expiración configurable (por defecto 24 horas).
- El `admin` puede crear, activar/inactivar y resetear contraseña de empleados.

---

## 3. Módulos del Sistema

### 3.1 Módulo: Items (Catálogo de Insumos)

#### 3.1.1 Descripción

El catálogo de items es el maestro central del sistema. Representa todos los insumos, materiales de consumo y activos que se gestionan en inventario.

#### 3.1.2 Atributos de un Item

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `nombre` | Texto | Nombre único del item |
| `tipo` | Enum | `insumo`, `material_consumo`, `activo` |
| `categoria` | Referencia | Clasificación principal (ej: Lácteos, Carnes) |
| `subcategoria` | Referencia | Clasificación secundaria dentro de la categoría (ej: Quesos, Embutidos) |
| `proveedor` | Referencia | Proveedor habitual del item |
| `unidad_medida` | Referencia | Unidad en la que el sistema calcula el inventario |
| `costo_unitario` | Entero (COP) | Costo por unidad de medida, en pesos sin decimales |
| `frecuencia_inventario` | Enum | `diario`, `semanal`, `mensual` |
| `stock_seguridad` | Entero | Cantidad mínima de stock que siempre se debe mantener |
| `tiempo_entrega_dias` | Entero | Días que tarda el proveedor en entregar este item |
| `activo` | Booleano | Si el item participa en los inventarios |

#### 3.1.3 Categorización en Dos Niveles

- **Categoría**: Clasificación principal (Insumo, Lacteo, Verdura, Abarrote, Material de consumo, Activo, etc.).
- **Subcategoría**: Clasificación secundaria dentro de la categoría (ej: dentro de Lacteo → Quesos, Cremas; dentro de Verdura → Hoja, Raíz).
- Una subcategoría pertenece a exactamente una categoría.
- Un item pertenece a exactamente una subcategoría.

#### 3.1.4 Reglas de Negocio

- RN-ITEM-01: El nombre del item es único en todo el sistema.
- RN-ITEM-02: No se elimina un item; solo se inactiva. Un item inactivo no aparece en futuros inventarios pero conserva su historial.
- RN-ITEM-03: El `costo_unitario` debe expresarse en la misma `unidad_medida` definida para el item.
- RN-ITEM-04: El `tiempo_entrega_dias` es el insumo principal para el cálculo del pedido automático.
- RN-ITEM-05: La `frecuencia_inventario` determina en qué tipo de conteo se incluye el item: los items `diario` aparecen en todos los conteos; `semanal` solo en conteos semanales y mensuales; `mensual` solo en conteos mensuales.

---

### 3.2 Módulo: Tabla de Equivalencias (Unidades de Medida)

#### 3.2.1 Descripción

Define las unidades de medida del sistema y las equivalencias entre ellas. El sistema trabaja siempre en la unidad canónica definida por item (ej: el Tomate se mide en gramos, el Aceite en mililitros).

#### 3.2.2 Atributos de una Unidad de Medida

| Campo | Descripción |
|-------|-------------|
| `codigo` | Código corto (ej: `g`, `kg`, `ml`, `l`, `und`, `cm2`) |
| `nombre` | Nombre completo (Gramos, Kilogramos, Mililitros, etc.) |
| `tipo_medida` | Agrupación: `peso`, `volumen`, `unidad`, `area` |
| `factor_conversion` | Factor respecto a la unidad base del tipo (ej: 1 kg = 1000 g) |
| `unidad_base` | Unidad de referencia del tipo (ej: para peso la base es `g`) |

#### 3.2.3 Reglas de Negocio

- RN-EQ-01: Cada item tiene asignada exactamente una unidad de medida canónica. Todos los cálculos de inventario (conteos, recetas, mermas, compras) se expresan en esa unidad.
- RN-EQ-02: Las recetas pueden especificar cantidades en unidades distintas a la canónica del item; el sistema convierte automáticamente usando los factores de equivalencia.
- RN-EQ-03: El catálogo de unidades de medida es gestionado solo por el `admin`.

#### 3.2.4 Ejemplos de Equivalencias

| Item | Unidad Canónica | Unidad en Receta | Factor |
|------|----------------|-----------------|--------|
| Tomate | gramos (g) | gramos (g) | 1.0 |
| Aceite oliva | mililitros (ml) | mililitros (ml) | 1.0 |
| Harina | gramos (g) | kilogramos (kg) | 1000.0 |
| Pan artesanal | unidad (und) | unidad (und) | 1.0 |

---

### 3.3 Módulo: Menú y Recetas

#### 3.3.1 Descripción del Menú

El Menú es el catálogo de productos finales que se venden al cliente. Cada producto del menú puede tener una receta asociada que define qué items y en qué cantidades lo componen.

#### 3.3.2 Atributos de un Producto de Menú

| Campo | Descripción |
|-------|-------------|
| `nombre` | Nombre del producto tal como aparece en el POS |
| `codigo_pos` | Identificador del producto en el sistema POS externo |
| `precio_venta` | Precio de venta al público (COP) |
| `categoria_menu` | Agrupación para el menú (Bebidas, Sanduchería, Postres, etc.) |
| `activo` | Si el producto está activo en el menú |

#### 3.3.3 Descripción de las Recetas

Una receta define la composición de items necesarios para preparar una unidad del producto de menú. Es el puente entre las ventas (productos finales) y el inventario (insumos).

#### 3.3.4 Atributos de una Receta

| Campo | Descripción |
|-------|-------------|
| `producto_menu` | Producto al que pertenece esta receta |
| `version` | Versión activa de la receta (historial de cambios) |
| `lineas` | Lista de items con cantidad y unidad |

#### 3.3.5 Atributos de una Línea de Receta

| Campo | Descripción |
|-------|-------------|
| `item` | Referencia al insumo del catálogo |
| `cantidad` | Cantidad del insumo a consumir |
| `unidad_medida` | Unidad en que se expresa la cantidad (puede diferir de la canónica) |

#### 3.3.6 Ejemplo

```text
Producto: Sanduche Capresse
Receta v1 (activa desde 2026-01-01):
  - Pan artesanal  | 2    | unidad
  - Tomate         | 30   | gramos
  - Lechuga        | 25   | gramos
  - Pollo          | 120  | gramos
  - Salsa pesto    | 20   | mililitros
  - Salsa tomate   | 30   | mililitros
```

#### 3.3.7 Reglas de Negocio

- RN-REC-01: Cada producto de menú puede tener como máximo una receta activa.
- RN-REC-02: Modificar una receta no elimina la anterior; se crea una nueva versión y la anterior queda archivada para trazabilidad histórica.
- RN-REC-03: Si un producto no tiene receta activa, las ventas de ese producto no generan descuento de inventario (se registra una alerta).
- RN-REC-04: La cantidad de cada insumo en la receta debe ser mayor que cero.
- RN-REC-05: Las unidades de medida de las líneas de receta deben tener equivalencia configurada con la unidad canónica del item correspondiente.

---

### 3.4 Módulo: Inventario (Conteo Físico)

#### 3.4.1 Descripción

El inventario es el módulo central del sistema. Representa el conteo físico periódico realizado por el líder de tienda para verificar el stock real contra el stock esperado.

#### 3.4.2 Tipos de Inventario

| Tipo | Frecuencia | Horarios | Items incluidos |
|------|-----------|---------|----------------|
| `diario` | Diario | Apertura, Mediodía, Cierre | Items con frecuencia `diario` |
| `semanal` | Semanal (día fijo) | — | Items con frecuencia `diario` y `semanal` |
| `mensual` | Mensual (día fijo) | — | Todos los items activos |
| `inicial` | Una vez (carga inicial) | — | Todos los items activos |

#### 3.4.3 Ciclo de Vida de un Inventario

```text
CREADO (en_progreso)
    ↓ El líder registra ventas y compras del período
    ↓ El líder realiza el conteo físico item por item
    ↓ El sistema calcula discrepancias
    ↓ El líder revisa y confirma
COMPLETADO
```

#### 3.4.4 Atributos de un Inventario

| Campo | Descripción |
|-------|-------------|
| `fecha` | Fecha del conteo |
| `tipo` | `diario`, `semanal`, `mensual`, `inicial` |
| `horario` | Para tipo `diario`: `apertura`, `mediodia`, `cierre` |
| `estado` | `en_progreso`, `completado` |
| `responsable` | Empleado que realizó el conteo |
| `iniciado_en` | Timestamp de inicio |
| `completado_en` | Timestamp de finalización |

#### 3.4.5 Detalle de Inventario por Item

| Campo | Descripción |
|-------|-------------|
| `item` | Item contado |
| `valor_sugerido` | Stock esperado = conteo real del inventario anterior |
| `ventas_periodo` | Unidades descontadas por ventas (provenientes del POS o ingresadas manualmente si el POS no respondió) |
| `compras_periodo` | Unidades recibidas por compras en el período |
| `mermas_periodo` | Unidades registradas como merma en el período |
| `valor_esperado` | Calculado: `sugerido + compras - ventas - mermas` |
| `valor_real` | Conteo físico registrado por el líder |
| `diferencia` | `real - esperado` (positivo = sobrante, negativo = faltante) |

#### 3.4.6 Reglas de Negocio

- RN-INV-01: Solo puede existir un inventario `en_progreso` por tipo y horario en una misma fecha.
- RN-INV-02: El `valor_sugerido` de cada item se toma del `valor_real` del inventario anterior de igual tipo y horario.
- RN-INV-03: Para completar un inventario, todos los items deben tener registrado el `valor_real`.
- RN-INV-04: El inventario de tipo `inicial` no requiere ventas ni compras previas; establece el stock de referencia.
- RN-INV-05: Las discrepancias (diferencia ≠ 0) quedan registradas automáticamente y son visibles para el admin.
- RN-INV-06: El inventario `en_progreso` puede ser retomado por el mismo responsable si se interrumpe.
- RN-INV-07: Un inventario completado no puede modificarse; cualquier corrección debe registrarse como ajuste (merma con signo positivo o compra extraordinaria).

---

### 3.5 Módulo: Mermas

#### 3.5.1 Descripción

Las mermas representan la pérdida de inventario por causas distintas a las ventas: descuadres, robos, evaporación, vencimientos, daños en almacén. Todo registro de merma **impacta el inventario** en el mismo momento de ser guardado.

#### 3.5.2 Atributos de una Merma

| Campo | Descripción |
|-------|-------------|
| `item` | Item afectado |
| `cantidad` | Cantidad perdida (en la unidad canónica del item) |
| `motivo` | Enum: `descuadre`, `robo`, `evaporacion`, `vencimiento`, `daño`, `otro` |
| `descripcion` | Nota descriptiva opcional |
| `fecha` | Fecha del evento |
| `registrado_por` | Empleado que registró la merma |
| `inventario_asociado` | Inventario al que se asocia (opcional; si se registra durante un conteo) |

#### 3.5.3 Reglas de Negocio

- RN-MERM-01: Una merma puede registrarse en cualquier momento del día, con o sin un inventario activo.
- RN-MERM-02: Al registrar una merma, el sistema descuenta inmediatamente la cantidad del stock proyectado del item.
- RN-MERM-03: Las mermas asociadas a un período de inventario se acumulan en el campo `mermas_periodo` del detalle de inventario correspondiente.
- RN-MERM-04: Las mermas no se eliminan; se pueden anular (registrando el motivo de anulación), lo que revierte el impacto en inventario.
- RN-MERM-05: El admin puede ver el reporte consolidado de mermas por item, por período y por motivo.

---

### 3.6 Módulo: Ventas (Integración POS)

#### 3.6.1 Descripción

Las ventas **no se registran manualmente** en Loopi v2. Provienen de la integración con el sistema POS (Point of Sale) externo. Cada venta de un producto de menú activa el descuento de inventario de los insumos que componen su receta.

#### 3.6.2 Modos de Integración

| Modo | Descripción | Cuándo usar |
|------|-------------|-------------|
| **Servicio web (API)** | El POS envía las ventas en tiempo real o por lote vía HTTP | POS con capacidad de integración REST |
| **Archivo plano** | Se importa un archivo CSV/Excel con las ventas del período | POS sin API; exportación manual |

#### 3.6.3 Estructura de la Venta Importada

| Campo | Descripción |
|-------|-------------|
| `fecha_hora` | Timestamp de la venta |
| `codigo_pos` | Código del producto en el POS |
| `cantidad` | Unidades vendidas |
| `numero_ticket` | Referencia del ticket de caja (para trazabilidad) |

#### 3.6.4 Flujo de Procesamiento de Ventas

```text
1. El POS envía la venta (o se importa el archivo)
2. El sistema busca el producto de menú por código_pos
3. El sistema obtiene la receta activa del producto
4. Por cada línea de receta: descuenta (cantidad_vendida × cantidad_receta) del inventario
5. Si el producto no tiene receta activa → alerta al admin, la venta queda pendiente de receta
6. Si el item de la receta tiene stock insuficiente → se registra stock negativo y alerta
```

#### 3.6.5 Reglas de Negocio

- RN-VTA-01: El sistema no registra ventas propias; solo procesa las que llegan del POS.
- RN-VTA-02: Cada venta genera descuentos de inventario calculados con la receta vigente al momento de la venta.
- RN-VTA-03: Si una venta corresponde a un producto sin receta activa, no genera descuento pero queda en cola de alertas para que el admin asigne la receta y reprocess.
- RN-VTA-04: Las ventas importadas por archivo plano requieren confirmación del admin antes de impactar inventario.
- RN-VTA-05: El sistema mantiene log de todas las ventas importadas con su estado: `procesada`, `pendiente_receta`, `error`.
- RN-VTA-06: En caso de que el POS no esté disponible, el líder de tienda puede ingresar manualmente el resumen de ventas del período (cantidad por producto) durante el cierre de inventario.

---

### 3.7 Módulo: Compras (Recepción)

#### 3.7.1 Descripción

El módulo de Compras permite registrar la recepción física de items. Cada recepción **impacta el inventario** sumando stock. Las compras pueden provenir de un pedido activo (recepción planificada) o ser imprevistos (compra no planificada).

#### 3.7.2 Tipos de Compra

| Tipo | Descripción |
|------|-------------|
| **Recepción de pedido** | El proveedor entregó items de un pedido activo. Se puede recibir exacto, menos o más de lo pedido. |
| **Compra imprevista** | Items comprados sin pedido previo (ej: hielo, bananos de emergencia). |

#### 3.7.3 Atributos de una Compra (Cabecera)

| Campo | Descripción |
|-------|-------------|
| `pedido_origen` | Referencia al pedido si es recepción planificada; nulo si es imprevisto |
| `proveedor` | Proveedor del que se recibe |
| `fecha_recepcion` | Fecha y hora de la recepción |
| `recibido_por` | Empleado que recibe |
| `estado` | `en_recepcion`, `completada` |
| `notas` | Observaciones de la recepción |

#### 3.7.4 Atributos de una Línea de Compra

| Campo | Descripción |
|-------|-------------|
| `item` | Item recibido |
| `cantidad_pedida` | Cantidad del pedido original (nulo si imprevisto) |
| `cantidad_recibida` | Cantidad efectivamente recibida |
| `costo_unitario` | Costo al que se recibió (puede diferir del costo registrado en el item) |
| `diferencia` | `recibida - pedida` (positivo = excedente, negativo = faltante) |

#### 3.7.5 Reglas de Negocio

- RN-CMP-01: Al confirmar una recepción, el sistema suma `cantidad_recibida` al stock de cada item.
- RN-CMP-02: Si la `cantidad_recibida` difiere de la `cantidad_pedida`, el sistema registra la discrepancia y notifica al admin.
- RN-CMP-03: Una compra imprevista debe justificarse con una nota de motivo.
- RN-CMP-04: Solo el líder de tienda o admin pueden confirmar recepciones.
- RN-CMP-05: Una recepción confirmada no se puede eliminar; solo se puede registrar una devolución.
- RN-CMP-06: El costo unitario de la recepción actualiza el histórico de costos del item.

---

### 3.8 Módulo: Pedidos

#### 3.8.1 Descripción

Los pedidos son órdenes de compra generadas semanalmente a los proveedores. El sistema puede generar pedidos sugeridos automáticamente basándose en el algoritmo de Planeación de Demanda, o el admin puede crearlos manualmente.

#### 3.8.2 Ciclo de Vida de un Pedido

```text
BORRADOR → CONFIRMADO → ENVIADO AL PROVEEDOR → EN RECEPCIÓN → COMPLETADO
                                                             ↘ PARCIALMENTE_COMPLETADO
```

#### 3.8.3 Atributos de un Pedido (Cabecera)

| Campo | Descripción |
|-------|-------------|
| `proveedor` | Proveedor al que se dirige el pedido |
| `fecha_pedido` | Fecha de generación del pedido |
| `fecha_entrega_esperada` | Fecha esperada de entrega según tiempo de entrega del proveedor |
| `estado` | `borrador`, `confirmado`, `enviado`, `en_recepcion`, `completado`, `parcialmente_completado` |
| `generado_por` | `automatico` (demand planning) o `manual` |
| `semana` | Semana ISO del pedido |
| `notas` | Observaciones adicionales |

#### 3.8.4 Atributos de una Línea de Pedido

| Campo | Descripción |
|-------|-------------|
| `item` | Item a pedir |
| `cantidad_sugerida` | Calculada por demand planning |
| `cantidad_final` | Cantidad ajustada por el admin (si difiere de la sugerida) |
| `costo_estimado` | `cantidad_final × costo_unitario_item` |

#### 3.8.5 Reglas de Negocio

- RN-PED-01: Un pedido en estado `borrador` puede modificarse libremente.
- RN-PED-02: Al pasar a `confirmado`, el pedido queda bloqueado para edición (solo admin con permiso especial puede modificarlo).
- RN-PED-03: Solo se puede crear un pedido activo por proveedor por semana.
- RN-PED-04: El admin puede combinar o dividir pedidos antes de confirmarlos.
- RN-PED-05: Un pedido `completado` es aquel donde todos los items se recibieron dentro de tolerancia (≤10% de diferencia). Si hay diferencia mayor, pasa a `parcialmente_completado`.
- RN-PED-06: Los pedidos se agrupan por proveedor (un pedido por proveedor).

---

### 3.9 Módulo: Planeación de Demanda

#### 3.9.1 Descripción

La Planeación de Demanda es el motor que calcula cuánto pedir de cada item basándose en el stock actual, el comportamiento histórico de ventas y los parámetros de cada item.

#### 3.9.2 Algoritmo de Cálculo de Pedido

Para cada item activo con proveedor asignado:

```text
inventario_actual    = stock_real del último inventario completado
promedio_venta_diaria = promedio de unidades consumidas por ventas en los últimos N días (configurable, por defecto 14)
tiempo_entrega        = item.tiempo_entrega_dias
stock_seguridad       = item.stock_seguridad
pico_demanda          = pico definido para la semana del pedido (configurable por semana)

-- Condición de pedido --
Si (inventario_actual > promedio_venta_diaria × tiempo_entrega):
    cantidad_a_pedir = 0  → No se incluye en el pedido
Sino:
    cantidad_a_pedir = (promedio_venta_diaria × tiempo_entrega) + stock_seguridad + pico_demanda
```

#### 3.9.3 Configuración de Picos de Demanda

El admin puede registrar semanas especiales con multiplicadores o cantidades adicionales por item:

| Campo | Descripción |
|-------|-------------|
| `semana` | Semana ISO (ej: 2026-W20) |
| `item` | Item afectado |
| `tipo` | `multiplicador` (factor sobre promedio) o `cantidad_adicional` |
| `valor` | Valor del multiplicador o cantidad adicional |

#### 3.9.4 Parámetros Globales del Algoritmo

| Parámetro | Descripción | Valor por defecto |
|-----------|-------------|------------------|
| `ventana_historico_dias` | Días hacia atrás para calcular promedio de ventas | 14 |
| `dia_generacion_pedido` | Día de la semana para generar el pedido | Lunes |
| `tolerancia_diferencia_pct` | % de diferencia aceptable en recepción | 10% |

#### 3.9.5 Reglas de Negocio

- RN-PL-01: El cálculo de `promedio_venta_diaria` usa las ventas procesadas del POS dentro de la ventana histórica.
- RN-PL-02: Si un item no tiene historial de ventas suficiente (< 7 días), se usa el `stock_seguridad` como cantidad a pedir.
- RN-PL-03: El admin puede sobrescribir la cantidad sugerida antes de confirmar el pedido.
- RN-PL-04: La generación del pedido automático se realiza en el día configurado; el admin recibe una notificación.
- RN-PL-05: Los picos de demanda se configuran con al menos 48 horas de anticipación a la generación del pedido.

---

## 4. Módulos Transversales

### 4.1 Gestión de Empleados

- CRUD completo por el admin.
- Campos: nombre, apellido, usuario, tipo de documento, número de documento, teléfono, email, fecha nacimiento, rol, activo.
- El admin puede resetear contraseña de cualquier empleado.
- Un empleado inactivo no puede autenticarse.

### 4.2 Gestión de Proveedores

- CRUD completo por el admin.
- Campos: razón social, NIT, nombre contacto, teléfono contacto, email contacto, activo.
- Un proveedor puede ser asignado a múltiples items.
- Un proveedor inactivo no aparece en el flujo de pedidos.

### 4.3 Dashboard Administrativo

El admin tiene acceso a un panel que muestra:

- Inventarios del día (estado de cada conteo: pendiente, en progreso, completado).
- Items con stock bajo (por debajo del `stock_seguridad`).
- Mermas del día/semana (resumen por motivo y monto en COP).
- Discrepancias abiertas (items con diferencia en último inventario).
- Estado del último pedido (borrador, enviado, recibido).
- Items sin receta (productos del menú sin receta activa).

---

## 5. Reglas de Negocio Globales

### 5.1 Impacto en Inventario

Todo movimiento que modifica el stock de un item debe:

1. Registrar el movimiento con timestamp, usuario, cantidad y motivo.
2. Actualizar el stock proyectado del item.
3. Ser trazable hacia el inventario más cercano.

| Tipo de movimiento | Efecto en stock |
|---------------------|----------------|
| Venta (POS) | Descuenta |
| Compra / Recepción | Suma |
| Merma | Descuenta |
| Conteo físico (inventario) | Ajusta (establece el real como nueva base) |
| Anulación de merma | Suma (revierte el descuento) |
| Devolución a proveedor | Descuenta |

### 5.2 Valor Sugerido en Inventarios

El `valor_sugerido` para cada item en un nuevo inventario se calcula como:

```text
valor_sugerido = real del inventario anterior del mismo tipo y horario
```

La sugerencia no descuenta mermas previas; el conteo físico es el que "resetea" el punto de partida.

### 5.3 Valor Esperado en Inventarios

```text
valor_esperado = valor_sugerido + compras_periodo - ventas_periodo - mermas_periodo
```

La discrepancia es la diferencia entre el conteo real y este valor esperado.

---

## 6. Integraciones

### 6.1 Sistema POS

| Aspecto | Detalle |
|---------|---------|
| Protocolo | REST/HTTP (JSON) o importación de archivo CSV/XLSX |
| Frecuencia | Tiempo real (webhooks) o por lote al cierre del día |
| Autenticación | API Key o token OAuth2 |
| Datos enviados | `fecha_hora`, `codigo_pos`, `cantidad`, `numero_ticket` |
| Manejo de errores | Cola de reintentos; alertas al admin si falla por >30 minutos |
| Fallback | Ingreso manual de resumen de ventas por el líder |

### 6.2 Notificaciones

- Canal: email y/o notificación push en la aplicación web.
- Eventos que generan notificación: pedido generado, stock bajo, discrepancias al cerrar inventario, ventas sin receta detectadas, fallo en integración POS.

---

## 7. Modelo de Datos — Entidades Principales

```text
┌─────────────┐    ┌──────────────┐    ┌───────────────────┐
│  categorias  │    │ subcategorias │    │  unidades_medida  │
│  id, nombre  │◄───│ id, nombre   │    │ id, codigo, nombre│
│  orden, act. │    │ categoria_id │    │ tipo, factor      │
└─────────────┘    └──────────────┘    └───────────────────┘
                           │                      │
                           ▼                      │
                   ┌──────────────┐               │
                   │    items     │◄──────────────┘
                   │ id, nombre   │
                   │ tipo, activo │
                   │ subcat_id    │
                   │ prov_id      │
                   │ um_id        │
                   │ costo_unit.  │
                   │ frec_inv.    │
                   │ stock_seg.   │
                   │ t_entrega    │
                   └──────┬───────┘
                          │
          ┌───────────────┼───────────────┐
          ▼               ▼               ▼
  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐
  │lineas_receta │ │   mermas     │ │lineas_pedido │
  │ item_id      │ │ item_id      │ │ item_id      │
  │ receta_id    │ │ cantidad     │ │ pedido_id    │
  │ cantidad     │ │ motivo       │ │ cant_suger.  │
  │ um_id        │ │ fecha        │ │ cant_final   │
  └──────────────┘ └──────────────┘ └──────────────┘
          │
  ┌──────────────┐
  │   recetas    │
  │ producto_id  │
  │ version      │
  │ activa       │
  └──────┬───────┘
         │
  ┌──────────────┐    ┌──────────────────┐
  │ productos    │    │   inventarios    │
  │ _menu        │    │ id, fecha, tipo  │
  │ id, nombre   │    │ horario, estado  │
  │ codigo_pos   │    │ responsable_id   │
  │ precio       │    └────────┬─────────┘
  │ activo       │             │
  └──────────────┘    ┌────────▼──────────┐
                       │ detalle_inventario│
                       │ inv_id, item_id   │
                       │ val_sugerido      │
                       │ ventas_periodo    │
                       │ compras_periodo   │
                       │ mermas_periodo    │
                       │ val_esperado      │
                       │ val_real          │
                       └───────────────────┘
```

---

## 8. Historias de Usuario Principales

### HU-01: Conteo Diario de Inventario (P1)

Como líder de tienda, quiero realizar el conteo físico de items al abrir, al mediodía y al cerrar, para tener una foto del stock real tres veces al día.

**Escenarios de Aceptación:**

1. **Dado** que son las 7:00 AM, **cuando** el líder inicia un inventario, **entonces** el sistema sugiere tipo "diario / apertura" y carga todos los items con frecuencia diaria con sus valores sugeridos.
2. **Dado** que el líder registra un conteo físico por item, **cuando** guarda el valor, **entonces** el sistema calcula y muestra la diferencia frente al esperado en tiempo real.
3. **Dado** que todos los items tienen `valor_real` registrado, **cuando** el líder completa el inventario, **entonces** el sistema cierra el inventario, registra discrepancias y habilita el siguiente.

### HU-02: Generación Automática de Pedido (P1)

Como admin, quiero que el sistema calcule automáticamente los pedidos semanales por proveedor, para reducir el tiempo de gestión de compras y evitar quiebres de stock.

**Escenarios de Aceptación:**

1. **Dado** que es el día de generación de pedidos, **cuando** el sistema ejecuta el algoritmo, **entonces** genera un pedido borrador por cada proveedor con items cuyo stock está por debajo del punto de reorden.
2. **Dado** un pedido borrador, **cuando** el admin lo revisa y ajusta cantidades, **entonces** puede confirmar y marcar el pedido como "enviado al proveedor".
3. **Dado** que el proveedor entregó, **cuando** el líder registra la recepción con cantidades reales, **entonces** el sistema suma el stock y cierra el pedido.

### HU-03: Procesamiento de Ventas desde POS (P1)

Como sistema, quiero consumir automáticamente las ventas del POS para descontar inventario por receta, para mantener el stock en tiempo real sin intervención manual.

**Escenarios de Aceptación:**

1. **Dado** que el POS registra la venta de un "Sanduche Capresse", **cuando** el sistema recibe la notificación, **entonces** descuenta la receta activa de los insumos correspondientes.
2. **Dado** que un producto no tiene receta activa, **cuando** el sistema recibe su venta, **entonces** no descuenta inventario y genera una alerta al admin.
3. **Dado** fallo en la integración POS, **cuando** el POS no responde por 30 minutos, **entonces** el sistema alerta al admin y permite el ingreso manual como fallback.

### HU-04: Registro de Merma (P2)

Como líder de tienda, quiero registrar pérdidas de items en cualquier momento, para mantener el inventario preciso y detectar patrones de pérdida.

**Escenarios de Aceptación:**

1. **Dado** que se detecta un frasco dañado de salsa, **cuando** el líder registra la merma con motivo "daño" y cantidad, **entonces** el stock del item se descuenta inmediatamente.
2. **Dado** que el líder cometió un error al registrar la merma, **cuando** la anula con justificación, **entonces** el stock se restaura y queda el historial de la anulación.

### HU-05: Recepción de Compras (P2)

Como líder de tienda, quiero registrar la recepción de un pedido indicando las cantidades reales recibidas, para actualizar el inventario y detectar diferencias con el proveedor.

**Escenarios de Aceptación:**

1. **Dado** un pedido confirmado y enviado al proveedor, **cuando** el líder abre la recepción e ingresa las cantidades reales, **entonces** el sistema suma al stock y registra diferencias si las hay.
2. **Dado** una compra imprevista sin pedido, **cuando** el líder la registra como imprevisto con nota de justificación, **entonces** el stock se actualiza y queda el registro del imprevisto.

### HU-06: Configuración de Recetas (P2)

Como admin, quiero definir y versionar las recetas de los productos del menú, para garantizar que el descuento de inventario por ventas sea preciso.

**Escenarios de Aceptación:**

1. **Dado** un producto nuevo en el menú, **cuando** el admin crea su receta con items y cantidades, **entonces** las futuras ventas de ese producto descuentan correctamente el inventario.
2. **Dado** un cambio en la formulación de un producto, **cuando** el admin crea una nueva versión de la receta, **entonces** la anterior queda archivada y la nueva aplica desde ese momento.

### HU-07: Configuración de Picos de Demanda (P3)

Como admin, quiero configurar semanas con demanda excepcional para ajustar los pedidos automáticos, para no quedarse sin stock en fechas especiales.

**Escenarios de Aceptación:**

1. **Dado** que se acerca una semana de festival, **cuando** el admin registra un pico de demanda para esa semana, **entonces** el algoritmo de pedidos incluye la cantidad adicional en el cálculo.

---

## 9. Supuestos

- La instalación es de un solo punto de venta (multi-tienda se evalúa para v3).
- El sistema POS externo tiene la capacidad de enviar ventas por webhook o exportar en CSV/XLSX.
- Los códigos de productos del POS (`codigo_pos`) son estables y únicos; no cambian sin aviso previo.
- Los proveedores son personas jurídicas con NIT colombiano.
- Los precios y costos se expresan en pesos colombianos (COP) sin decimales.
- El día de generación de pedidos es configurable una vez y no cambia frecuentemente.
- La operación es lunes a domingo; los inventarios de apertura son el punto de referencia principal del día.
- El sistema opera en zona horaria UTC-5 (Colombia).
- Las unidades de medida del catálogo son finitas y las administra el admin; no son dinámicas en el flujo de trabajo diario.

---

## 10. Criterios de Éxito del Sistema

| Criterio | Métrica |
|----------|---------|
| CE-01 | El líder completa el conteo diario de apertura en menos de 10 minutos |
| CE-02 | Los pedidos semanales se generan automáticamente sin intervención manual en el 80% de los casos |
| CE-03 | El stock proyectado refleja los movimientos del POS en menos de 2 minutos después de la venta |
| CE-04 | Las discrepancias de inventario se reducen en un 30% respecto al proceso manual en los primeros 3 meses |
| CE-05 | Los quiebres de stock (stock = 0 cuando debería haber) se reducen en un 50% |
| CE-06 | El admin puede ver el estado del inventario en tiempo real sin hacer llamadas manuales a ningún sistema |

---

## 11. Diferencias clave respecto a Loopi v1

| Aspecto | Loopi v1 | Loopi v2 |
|---------|----------|----------|
| Categorización | 1 nivel (Categoría) | 2 niveles (Categoría + Subcategoría) |
| Ventas | Ingreso manual en inventario | Integración automática con POS + fallback manual |
| Recetas | No existe | Módulo completo con versionado |
| Menú | No existe | Catálogo de productos finales |
| Pedidos | No existe | Módulo completo con workflow |
| Planeación de demanda | No existe | Algoritmo automático configurable |
| Compras | Campo `stock_received` en detalle de inventario | Módulo independiente con workflow de recepción |
| Mermas | Campo `shrinkage` en detalle de inventario | Módulo independiente con registro en cualquier momento |
| Picos de demanda | No existe | Configurable por semana e item |
| Costo unitario | Por item | Por item + histórico por recepción de compra |

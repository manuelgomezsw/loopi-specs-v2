# Especificación de Feature: Inventario y Conteo Físico

**Branch de Feature**: `009-inventario-conteo`
**Creado**: 2026-05-21
**Estado**: Borrador
**Referencia funcional**: [§3.4 Módulo: Inventario (Conteo Físico)](../loopi-v2-funcional/spec.md)

---

## Escenarios de Usuario y Pruebas *(obligatorio)*

### Historia de Usuario 1 — Iniciar un conteo de inventario (Prioridad: P1)

El líder o barista inicia un conteo físico en su tienda. El sistema sugiere el tipo y horario
según la hora del día (apertura, mediodía o cierre para conteos diarios) y presenta la lista
de items que corresponde contar. El líder puede aceptar la sugerencia o cambiar el tipo de
conteo manualmente.

**Por qué esta prioridad**: El conteo es el flujo operativo más frecuente del sistema y la
base para la trazabilidad de inventario. Sin él no hay stock proyectado confiable.

**Prueba Independiente**: Puede verificarse iniciando un conteo a las 8 a.m. y comprobando
que el sistema sugiere `diario / apertura` y presenta solo los items con frecuencia `diario`.

**Escenarios de Aceptación**:

1. **Dado** que son las 8:00 a.m. y no existe un conteo `diario / apertura` en progreso,
   **Cuando** el líder inicia un inventario,
   **Entonces** el sistema sugiere `diario / apertura` y presenta los items con frecuencia
   `diario` con su valor sugerido calculado desde el inventario de referencia más reciente.

2. **Dado** que el líder quiere realizar un conteo semanal fuera del día habitual,
   **Cuando** selecciona manualmente el tipo `semanal`,
   **Entonces** el sistema presenta los items con frecuencia `diario` y `semanal` sin
   bloquear el cambio de tipo.

3. **Dado** que ya existe un conteo `diario / apertura` en progreso en esa tienda,
   **Cuando** otro usuario intenta iniciar otro conteo del mismo tipo y horario en la misma
   fecha,
   **Entonces** el sistema bloquea la operación indicando que ya existe un conteo en curso.

4. **Dado** que es el primer conteo de la tienda (sin historial previo),
   **Cuando** el líder inicia el inventario de tipo `inicial`,
   **Entonces** el sistema presenta todos los items activos con valor sugerido en cero,
   estableciendo el stock inaugural de la tienda.

---

### Historia de Usuario 2 — Registrar el conteo físico item por item (Prioridad: P1)

Durante el conteo, el líder o barista ingresa la cantidad física real de cada item. El
sistema muestra en tiempo real la diferencia entre lo esperado y lo contado, permitiendo
que el usuario detecte inconsistencias antes de confirmar.

**Por qué esta prioridad**: Es el núcleo del conteo — sin el registro físico no hay datos
para ajustar el stock ni detectar mermas o pérdidas.

**Prueba Independiente**: Puede verificarse ingresando cantidades y comprobando que la
diferencia (real − esperado) se actualiza de inmediato en pantalla.

**Escenarios de Aceptación**:

1. **Dado** que el conteo está en progreso y el item "Leche Entera" tiene valor esperado
   de 5 000 ml,
   **Cuando** el líder registra 4 600 ml como valor real,
   **Entonces** el sistema muestra una diferencia de −400 ml de inmediato, sin necesidad
   de guardar manualmente.

2. **Dado** que el conteo fue interrumpido (app cerrada o pérdida de conexión),
   **Cuando** el responsable retoma el conteo,
   **Entonces** el sistema recupera los valores ya ingresados y continúa desde donde se
   detuvo, sin perder datos.

3. **Dado** que el líder intenta confirmar el conteo con items sin valor registrado,
   **Cuando** presiona confirmar,
   **Entonces** el sistema bloquea la confirmación e indica cuáles items faltan por contar.

---

### Historia de Usuario 3 — Confirmar el inventario y ajustar el stock (Prioridad: P1)

Una vez registrados todos los items, el líder confirma el conteo. El sistema ajusta
automáticamente el stock de cada item al valor real contado, sin requerir aprobación
adicional. Las diferencias quedan registradas como parte del historial del inventario.

**Por qué esta prioridad**: El ajuste automático es el propósito central del módulo y la
fuente de verdad del stock proyectado para todos los módulos posteriores (pedidos,
planeación).

**Prueba Independiente**: Puede verificarse confirmando un conteo con diferencias y
comprobando que el stock de los items ajustados refleja el valor real contado.

**Escenarios de Aceptación**:

1. **Dado** que todos los items del conteo tienen valor real registrado,
   **Cuando** el líder confirma el inventario,
   **Entonces** el stock de cada item en la tienda se ajusta al valor real contado, las
   diferencias quedan registradas en el historial y el inventario pasa a estado `completado`.

2. **Dado** que el conteo completado muestra faltantes superiores al 10% en algún item,
   **Cuando** el admin consulta el dashboard,
   **Entonces** puede ver las discrepancias marcadas como alertas para ese inventario.

3. **Dado** que un inventario ya fue confirmado (estado `completado`),
   **Cuando** alguien intenta modificar sus valores,
   **Entonces** el sistema no permite la modificación directa; indica que las correcciones
   deben registrarse como mermas o mediante un nuevo inventario.

---

### Historia de Usuario 4 — Consultar el historial de inventarios (Prioridad: P2)

El administrador revisa el historial de conteos de una tienda para auditar el stock en
fechas pasadas, detectar patrones de discrepancia o verificar que los conteos se están
realizando con la frecuencia esperada.

**Por qué esta prioridad**: La visibilidad histórica es fundamental para el control
operativo y la detección de pérdidas sistemáticas.

**Prueba Independiente**: Puede verificarse consultando el historial y comprobando que
cada inventario muestra fecha, tipo, responsable y resumen de diferencias.

**Escenarios de Aceptación**:

1. **Dado** que existen inventarios completados de distintos tipos,
   **Cuando** el admin consulta el historial de inventarios de una tienda,
   **Entonces** ve la lista ordenada por fecha con tipo, horario, responsable y estado de
   cada conteo.

2. **Dado** que el admin selecciona un inventario completado,
   **Cuando** accede a su detalle,
   **Entonces** puede ver el valor esperado, el valor real y la diferencia por cada item
   contado en ese inventario.

---

## Requisitos Funcionales

### RF-INV-01: Inicio del inventario

- RF-INV-01.1: El líder de tienda, barista y admin pueden iniciar conteos. Solo pueden
  iniciar conteos de su propia tienda (lider_tienda y barista); el admin puede iniciar
  conteos en cualquier tienda.
- RF-INV-01.2: Al iniciar, el sistema sugiere el tipo y horario según la hora actual:
  - 06:00–10:59 → `diario / apertura`
  - 11:00–14:59 → `diario / mediodía`
  - 15:00–23:59 → `diario / cierre`
- RF-INV-01.3: El usuario puede cambiar el tipo manualmente a `diario`, `semanal`,
  `mensual` o `inicial` sin restricción de horario.
- RF-INV-01.4: Solo puede existir un inventario `en_progreso` por tienda, tipo y horario
  en la misma fecha. El sistema bloquea intentos duplicados.
- RF-INV-01.5: El tipo `inicial` se usa exclusivamente para la carga inaugural de stock
  de la tienda. No requiere inventario de referencia previo.
- RF-INV-01.6: Los items presentados en el conteo dependen del tipo:
  - `diario`: items con frecuencia `diario`.
  - `semanal`: items con frecuencia `diario` y `semanal`.
  - `mensual` e `inicial`: todos los items activos.

### RF-INV-02: Registro del conteo

- RF-INV-02.1: Para cada item del conteo, el sistema muestra: valor sugerido (stock
  proyectado), valor esperado y un campo para ingresar el valor real.
- RF-INV-02.2: El valor sugerido de cada item se calcula desde el inventario completado
  más reciente de la tienda (de cualquier tipo y horario), incorporando ventas, compras
  y mermas registradas desde entonces.
- RF-INV-02.3: La diferencia (real − esperado) se recalcula y muestra en pantalla en
  tiempo real al ingresar cada valor.
- RF-INV-02.4: Un conteo en progreso puede ser retomado por el mismo responsable si fue
  interrumpido; los valores ya ingresados se conservan.
- RF-INV-02.5: Solo el responsable que inició el conteo puede retomarlo y completarlo.
  Otros usuarios ven el conteo como bloqueado.

### RF-INV-03: Confirmación y ajuste de stock

- RF-INV-03.1: Para confirmar un inventario, todos los items deben tener valor real
  registrado. El sistema bloquea la confirmación si falta alguno.
- RF-INV-03.2: Al confirmar, el stock de cada item en la tienda se ajusta automáticamente
  al valor real contado. No se requiere aprobación de un rol superior.
- RF-INV-03.3: El inventario confirmado pasa a estado `completado` y no puede modificarse
  directamente. Las correcciones posteriores se registran como mermas o mediante un nuevo
  inventario.
- RF-INV-03.4: Las diferencias de cada item (positivas y negativas) quedan registradas en
  el historial del inventario para trazabilidad.
- RF-INV-03.5: Las discrepancias superiores al 10% en algún item generan una alerta
  visible en el dashboard del admin.

### RF-INV-04: Historial y consulta

- RF-INV-04.1: El admin puede consultar el historial completo de inventarios de cualquier
  tienda, con fecha, tipo, horario, responsable y estado.
- RF-INV-04.2: El lider_tienda puede consultar el historial de inventarios de su propia
  tienda.
- RF-INV-04.3: Desde el detalle de un inventario completado, se pueden ver los valores
  esperado, real y diferencia por cada item contado.

---

## Criterios de Éxito

- **Velocidad de conteo**: El líder puede completar un conteo diario de hasta 50 items
  en menos de 15 minutos.
- **Exactitud del ajuste**: El 100% de los ajustes de stock al confirmar un inventario
  reflejan exactamente el valor real contado.
- **Continuidad ante interrupciones**: El 100% de los conteos interrumpidos se pueden
  retomar sin pérdida de datos ya ingresados.
- **Trazabilidad**: El 100% de las diferencias de inventario quedan registradas con
  fecha, responsable y detalle por item.
- **Prevención de duplicados**: El sistema bloquea el 100% de los intentos de iniciar
  dos conteos del mismo tipo, horario y fecha en la misma tienda.

---

## Entidades Clave

| Entidad | Atributos |
|---------|-----------|
| `Inventario` | tienda_id, fecha, tipo, horario, estado, responsable_id, iniciado_en, completado_en |
| `DetalleInventario` | inventario_id, item_id, inventario_referencia_id, valor_sugerido, valor_esperado, valor_real, diferencia |

---

## Dependencias y Suposiciones

### Dependencias

- **001-autenticacion**: El responsable debe estar autenticado y el sistema conoce su
  tienda asignada (lider_tienda, barista) o permite selección (admin).
- **002-gestion-tiendas**: El inventario pertenece a una tienda activa.
- **007-items-catalogo**: Los items con su frecuencia de inventario determinan qué se
  cuenta en cada tipo de conteo.
- **010-mermas** (posterior): Las mermas registradas entre conteos impactan el valor
  sugerido del siguiente inventario.
- **008-menu-recetas** + **015-pos** (posterior): Las ventas procesadas entre conteos
  se incorporan al cálculo del valor sugerido.

### Suposiciones

- El valor sugerido se calcula en la unidad de medida del item. Si en un período se
  registraron movimientos en unidades distintas, la conversión usa los factores de
  equivalencia configurados en 004-unidades-medida.
- Solo existe un inventario en progreso por tienda, tipo y horario por fecha. No hay
  concepto de "pausar" formalmente — simplemente el conteo queda en_progreso hasta que
  se completa o se abandona.
- Un conteo abandonado (en_progreso sin actividad) no se elimina automáticamente; el
  admin puede retomarlo o marcarlo como descartado manualmente.
- No existe flujo de aprobación para los ajustes de stock; la confirmación del inventario
  es el único paso requerido y cualquiera que inició el conteo puede completarlo.

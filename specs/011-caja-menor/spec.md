# Especificación de Feature: Caja Menor

**Branch de Feature**: `011-caja-menor`
**Creado**: 2026-05-21
**Estado**: Borrador
**Referencia funcional**: [§3.7 Módulo: Caja Menor (Compras Excepcionales)](../loopi-v2-funcional/spec.md)

---

## Escenarios de Usuario y Pruebas *(obligatorio)*

### Historia de Usuario 1 — Habilitar items para compra por caja menor (Prioridad: P1)

El administrador define qué items del catálogo pueden comprarse excepcionalmente con
dinero de caja menor. Esta configuración restringe al líder de tienda a registrar solo
los items autorizados, evitando compras fuera del alcance del módulo.

**Por qué esta prioridad**: Sin la lista de items habilitados, el módulo no tiene
alcance delimitado y cualquier item podría comprarse por caja menor, lo que impide el
control de gasto del admin.

**Prueba Independiente**: Puede verificarse habilitando un item para caja menor y
comprobando que aparece disponible en el listado al momento de registrar una compra.

**Escenarios de Aceptación**:

1. **Dado** que el item "Azúcar Blanca" no está habilitado para caja menor,
   **Cuando** el admin lo habilita,
   **Entonces** el item aparece disponible en el listado de selección al registrar una
   compra de caja menor.

2. **Dado** que el item "Café Molido" está habilitado para caja menor,
   **Cuando** el admin lo deshabilita,
   **Entonces** el item deja de aparecer en el listado de selección para nuevas
   compras; las compras anteriores ya registradas no se ven afectadas.

3. **Dado** que un lider_tienda o barista intenta modificar la lista de items
   habilitados para caja menor,
   **Cuando** accede a esa configuración,
   **Entonces** el sistema deniega el acceso; solo el admin puede gestionar esa lista.

---

### Historia de Usuario 2 — Registrar una compra de caja menor (Prioridad: P1)

El líder de tienda realiza una compra urgente de un insumo con dinero en efectivo de
caja menor. Registra la compra en el sistema indicando el item, la cantidad, el valor
pagado y el motivo. Al confirmar, el stock del item en la tienda aumenta de inmediato.

**Por qué esta prioridad**: Es el flujo principal del módulo. Sin él no hay ingreso de
stock por compras excepcionales y el inventario quedaría desactualizado en situaciones
de emergencia.

**Prueba Independiente**: Puede verificarse registrando una compra y comprobando que
el stock proyectado del item en la tienda aumenta exactamente en la cantidad comprada.

**Escenarios de Aceptación**:

1. **Dado** que "Azúcar Blanca" está habilitado para caja menor y su stock proyectado
   es 2 kg,
   **Cuando** el líder registra una compra de 1 kg a $4 000 con motivo "quiebre de
   stock en apertura",
   **Entonces** el stock proyectado pasa a 3 kg de inmediato y la compra queda
   registrada con fecha, responsable, cantidad y valor.

2. **Dado** que el líder intenta guardar una compra sin ingresar el motivo,
   **Cuando** presiona confirmar,
   **Entonces** el sistema bloquea el guardado e indica que el motivo es obligatorio.

3. **Dado** que el líder selecciona un item no habilitado para caja menor,
   **Cuando** intenta registrar la compra,
   **Entonces** el sistema rechaza la operación indicando que ese item no está
   autorizado para compras de caja menor.

4. **Dado** que un barista intenta registrar una compra de caja menor,
   **Cuando** accede a esa sección,
   **Entonces** el sistema deniega el acceso; solo lider_tienda y admin pueden
   registrar compras de caja menor.

---

### Historia de Usuario 3 — Consultar el historial de compras de caja menor (Prioridad: P1)

El líder de tienda revisa las compras de caja menor de su tienda para hacer seguimiento
del gasto excepcional del período y verificar que los ingresos de stock estén
justificados.

**Por qué esta prioridad**: La visibilidad del historial permite al líder y al admin
auditar el uso de caja menor y detectar patrones de compra recurrente que deberían
incorporarse al proceso de pedidos formal.

**Prueba Independiente**: Puede verificarse consultando el historial y comprobando que
cada registro muestra item, cantidad, valor total, motivo, fecha y responsable.

**Escenarios de Aceptación**:

1. **Dado** que existen compras de caja menor registradas en la tienda,
   **Cuando** el líder consulta el historial,
   **Entonces** ve la lista ordenada por fecha descendente con item, cantidad, unidad
   de medida, valor unitario, valor total, motivo, fecha y responsable.

2. **Dado** que el historial tiene compras de distintos items y fechas,
   **Cuando** el líder filtra por item o por rango de fechas,
   **Entonces** el sistema muestra solo las compras que cumplen el criterio aplicado.

---

### Historia de Usuario 4 — Ver reporte consolidado de caja menor (Prioridad: P2)

El administrador revisa el reporte de compras de caja menor de todas las tiendas para
identificar el gasto total del período, los items de mayor compra excepcional y evaluar
si alguno debería incorporarse al proceso de pedidos planificados.

**Por qué esta prioridad**: El reporte consolida la visibilidad del gasto excepcional
a nivel de red de tiendas, lo que permite al admin tomar decisiones sobre la
configuración del catálogo y el proceso de pedidos.

**Prueba Independiente**: Puede verificarse generando el reporte de un período y
comprobando que el valor total suma correctamente todas las compras del período en
todas las tiendas.

**Escenarios de Aceptación**:

1. **Dado** que existen compras de caja menor en varias tiendas durante un período,
   **Cuando** el admin consulta el reporte consolidado filtrado por ese período,
   **Entonces** ve el listado de todas las compras con tienda, item, cantidad, valor
   total, motivo, fecha y responsable.

2. **Dado** que el admin filtra el reporte por tienda e item,
   **Cuando** aplica los filtros,
   **Entonces** el sistema muestra solo las compras que cumplen ambos criterios.

---

## Requisitos Funcionales

### RF-CM-01: Configuración de items habilitados para caja menor

- RF-CM-01.1: Solo el admin puede habilitar o deshabilitar items para compras de caja
  menor.
- RF-CM-01.2: Un item puede ser habilitado o deshabilitado en cualquier momento. Al
  deshabilitarlo, las compras ya registradas no se ven afectadas.
- RF-CM-01.3: El listado de items habilitados para caja menor es visible para el
  lider_tienda y el admin al momento de registrar una compra.

### RF-CM-02: Registro de compras de caja menor

- RF-CM-02.1: Solo el lider_tienda y el admin pueden registrar compras de caja menor.
  El lider_tienda solo puede registrar compras en su propia tienda; el admin en
  cualquier tienda.
- RF-CM-02.2: Una compra de caja menor requiere: item habilitado para caja menor,
  cantidad mayor que cero, valor unitario mayor que cero, motivo y fecha.
- RF-CM-02.3: Al seleccionar el item, la unidad de medida se carga automáticamente
  desde el catálogo; el usuario no puede cambiarla.
- RF-CM-02.4: El valor total (`cantidad × valor_unitario`) es calculado y mostrado en
  tiempo real; no requiere ingreso manual.
- RF-CM-02.5: Al confirmar la compra, el sistema suma inmediatamente la cantidad al
  stock proyectado del item en la tienda.
- RF-CM-02.6: No se puede registrar una compra de un item que no esté habilitado para
  caja menor.

### RF-CM-03: Inmutabilidad de compras confirmadas

- RF-CM-03.1: Una compra de caja menor confirmada no puede eliminarse ni modificarse.
- RF-CM-03.2: Si la compra fue un error, el lider_tienda o admin deben registrar una
  merma por la cantidad correspondiente para revertir el stock.

### RF-CM-04: Consulta de historial por tienda

- RF-CM-04.1: El lider_tienda puede consultar el historial de compras de caja menor de
  su propia tienda. El admin puede consultar el historial de cualquier tienda.
- RF-CM-04.2: El historial muestra por cada compra: item, cantidad, unidad de medida,
  valor unitario, valor total, motivo, fecha y responsable.
- RF-CM-04.3: El historial permite filtrar por item y por rango de fechas.

### RF-CM-05: Reporte consolidado (admin)

- RF-CM-05.1: El admin puede consultar el reporte consolidado de compras de caja menor
  de todas las tiendas, con filtros por tienda, item y período (fecha inicio y fecha
  fin).
- RF-CM-05.2: El reporte incluye el valor total de cada compra y permite identificar el
  gasto acumulado por item o por tienda en el período consultado.

### RF-CM-06: Impacto en inventario

- RF-CM-06.1: Las compras de caja menor confirmadas se acumulan en el campo
  `compras_periodo` del cálculo del valor sugerido del siguiente inventario.

---

## Criterios de Éxito

- **Impacto inmediato en stock**: El 100% de las compras de caja menor confirmadas
  incrementan el stock proyectado en el momento exacto del registro, sin retraso.
- **Control de items autorizados**: El 100% de los intentos de registrar compras de
  items no habilitados para caja menor son rechazados.
- **Trazabilidad completa**: El 100% de las compras quedan registradas con item,
  cantidad, valor, motivo, fecha, tienda y responsable; ninguna puede eliminarse.
- **Control de acceso**: El 100% de los intentos de registro de compras por baristas
  son bloqueados; el 100% de los intentos de modificar la lista de items habilitados
  por roles no admin son rechazados.
- **Registro rápido**: El líder puede registrar una compra de caja menor en menos de
  2 minutos desde que abre el módulo hasta confirmar.

---

## Entidades Clave

| Entidad | Atributos |
|---------|-----------|
| `ItemCajaMenor` | item_id, habilitado_en, habilitado_por_id |
| `CompraCajaMenor` | tienda_id, item_id, unidad_medida_id, cantidad, valor_unitario, valor_total, motivo, fecha, registrado_por_id |

---

## Dependencias y Suposiciones

### Dependencias

- **001-autenticacion**: El responsable debe estar autenticado y el sistema conoce su
  tienda asignada (lider_tienda) o permite selección (admin).
- **002-gestion-tiendas**: La compra pertenece a una tienda activa.
- **004-unidades-medida**: La unidad de medida de la compra se toma directamente del
  item y no requiere conversión adicional.
- **007-items-catalogo**: Solo items activos del catálogo pueden habilitarse para caja
  menor. La unidad de medida del item determina la unidad de la compra.
- **009-inventario-conteo**: Las compras de caja menor confirmadas se acumulan en
  `compras_periodo` del cálculo del valor sugerido del siguiente inventario.
- **010-mermas**: Si una compra fue registrada por error, la corrección se realiza
  mediante una merma por la cantidad ingresada incorrectamente.

### Suposiciones

- La lista de items habilitados para caja menor es global (no por tienda). El admin
  define qué items pueden comprarse por caja menor en cualquier tienda; no existe una
  lista diferente por tienda.
- El valor unitario ingresado es el precio real pagado en la compra; no tiene relación
  con el `costo_unitario` del catálogo (que es el costo de referencia de pedidos).
  Ambos coexisten de forma independiente.
- El valor total (`cantidad × valor_unitario`) es un campo calculado que se muestra
  en pantalla pero no se almacena por separado; se recalcula al consultar el historial.
- No existe límite de monto configurado en el sistema para las compras de caja menor.
  El control del presupuesto disponible de caja menor es responsabilidad operativa del
  líder y el admin fuera del sistema.
- La recepción de pedidos formales (con pedido activo en el módulo de Pedidos) no pasa
  por este módulo; ambos flujos son independientes.

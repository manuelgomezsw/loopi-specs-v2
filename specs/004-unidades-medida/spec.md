# Especificación de Feature: Unidades de Medida y Tabla de Equivalencias

**Branch de Feature**: `004-unidades-medida`
**Creado**: 2026-05-19
**Estado**: Borrador
**Referencia funcional**: [§3.2 Tabla de Equivalencias](../loopi-v2-funcional/spec.md)

---

## Clarifications

### Session 2026-05-24

- Q: ¿Dónde debe almacenarse la referencia a la unidad de origen en las conversiones? → A: Campo `unidad_origen` y `cantidad_origen` en cada registro transaccional del módulo consumidor (ej. `LineaCompra`, `IngredienteReceta`, `LineaRecepcion`)
- Q: ¿Qué debe ocurrir en transacciones nuevas para un item con unidad canónica inactiva? → A: Bloquear la transacción e informar al usuario; mostrar confirmación con implicaciones antes de inactivar
- Q: ¿Cuántos decimales debe admitir el campo `factor_conversion`? → A: 4 decimales — `DECIMAL(12,4)`
- Q: ¿Qué debe incluir el seed de datos inicial de unidades? → A: Unidades base + conjunto estándar de gastronomía (`kg`, `t`, `mg`, `L`, `dL`, `cL`, `docena`, `par`, `caja`)
- Q: ¿Debe incluirse el tipo "área" en el alcance de esta versión inicial? → A: No; diferido a versión futura. Versión inicial: solo peso, volumen y unidad

---

## Escenarios de Usuario y Pruebas *(obligatorio)*

### Historia de Usuario 1 — Crear una unidad de medida (Prioridad: P1)

El administrador registra una nueva unidad de medida indicando su código corto, nombre
completo, tipo (peso, volumen o unidad) y su factor de conversión respecto a la
unidad base de ese tipo. Una vez creada, queda disponible para asignar a items y usar
en recetas y compras.

**Por qué esta prioridad**: Sin unidades de medida no se pueden crear items ni operar
ningún módulo del catálogo. Es el prerequisito más temprano de toda la Ola 2.

**Prueba Independiente**: Puede verificarse creando una unidad y comprobando que aparece
disponible al crear un item o al registrar una línea de compra.

**Escenarios de Aceptación**:

1. **Dado** que el admin crea la unidad "Kilogramo" con código `kg`, tipo `peso` y
   factor `1000` respecto a la unidad base gramos (`g`),
   **Cuando** guarda el registro,
   **Entonces** la unidad aparece en el catálogo y puede seleccionarse al crear un item.

2. **Dado** que ya existe una unidad con el código `kg`,
   **Cuando** el admin intenta crear otra con el mismo código,
   **Entonces** el sistema rechaza la operación indicando que el código ya existe.

3. **Dado** que un lider_tienda o barista intenta acceder a la gestión de unidades,
   **Cuando** navega a esa sección,
   **Entonces** el sistema deniega el acceso; solo el admin puede gestionar este catálogo.

---

### Historia de Usuario 2 — Editar una unidad de medida (Prioridad: P2)

El administrador corrige el nombre o el factor de conversión de una unidad existente
cuando detecta un error. El código corto no puede modificarse una vez asignado a items.

**Por qué esta prioridad**: Los errores en factores de conversión impactan directamente
los cálculos de stock, recetas y compras en todo el sistema.

**Prueba Independiente**: Puede verificarse editando el factor de una unidad y comprobando
que los cálculos de conversión posteriores reflejan el nuevo valor.

**Escenarios de Aceptación**:

1. **Dado** que existe la unidad "Kilogramo" con factor `1000`,
   **Cuando** el admin corrige el nombre a "Kilogramos" y guarda,
   **Entonces** todos los items que la usan muestran el nuevo nombre sin afectar sus datos.

2. **Dado** que una unidad está asignada a al menos un item,
   **Cuando** el admin intenta cambiar su código corto,
   **Entonces** el sistema no permite modificar el código e informa que está en uso.

---

### Historia de Usuario 3 — Consultar el catálogo de equivalencias (Prioridad: P1)

El administrador revisa el listado completo de unidades de medida agrupadas por tipo
para verificar que las equivalencias están correctamente configuradas antes de crear items.

**Por qué esta prioridad**: Verificar las equivalencias antes de crear items evita errores
de conversión que son difíciles de corregir una vez hay datos operativos.

**Prueba Independiente**: Puede verificarse con unidades de distintos tipos y comprobando
que el listado las muestra agrupadas con su código, nombre, tipo y factor.

**Escenarios de Aceptación**:

1. **Dado** que existen unidades de peso, volumen y unidad registradas,
   **Cuando** el admin consulta el catálogo de unidades,
   **Entonces** las ve listadas con código, nombre, tipo y factor de conversión.

2. **Dado** que el admin consulta el catálogo,
   **Cuando** selecciona una unidad,
   **Entonces** puede ver cuántos items del catálogo la tienen asignada como unidad canónica.

---

### Historia de Usuario 4 — Conversión automática entre unidades (Prioridad: P1)

Cuando el sistema registra una cantidad expresada en una unidad distinta a la canónica
del item (por ejemplo, una compra en kilogramos de un item cuya unidad canónica es gramos),
el sistema convierte automáticamente usando el factor de equivalencia sin que el usuario
deba calcular nada.

**Por qué esta prioridad**: La conversión automática es el propósito central de este módulo
y es utilizada por inventarios, recetas, pedidos y compras.

**Prueba Independiente**: Puede verificarse registrando una compra de 2 kg de un item cuya
unidad canónica es gramos y comprobando que el stock aumenta en 2000 g.

**Escenarios de Aceptación**:

1. **Dado** que el item "Harina" tiene unidad canónica gramos (`g`),
   **Cuando** se registra una compra de 2 kg,
   **Entonces** el sistema suma 2000 g al stock de Harina sin intervención del usuario.

2. **Dado** que no existe equivalencia entre dos tipos de medida distintos (ej. kg y ml),
   **Cuando** el sistema intenta convertir entre ellos,
   **Entonces** rechaza la operación e informa que las unidades son incompatibles.

---

## Requisitos Funcionales

### RF-UM-01: Gestión del catálogo de unidades

- RF-UM-01.1: Solo el administrador puede crear, editar e inactivar unidades de medida.
- RF-UM-01.2: Cada unidad requiere: código corto (único), nombre completo, tipo de medida
  y factor de conversión respecto a la unidad base de su tipo.
- RF-UM-01.3: Los tipos de medida válidos en esta versión son: peso, volumen y unidad.
  El tipo área (`cm2`) queda diferido para una versión futura.
- RF-UM-01.4: El código corto es único en todo el sistema y no puede modificarse una vez
  que la unidad está asignada a algún item.
- RF-UM-01.5: No es posible eliminar una unidad; solo inactivarla.
  - Antes de inactivar, el sistema muestra un mensaje de confirmación que indica cuántos
    items tienen esa unidad como canónica y advierte que las transacciones nuevas sobre
    esos items quedarán bloqueadas hasta que se les reasigne una unidad canónica activa.
  - Una unidad inactiva no aparece como opción al crear o editar items.
  - Cualquier transacción nueva (compra, receta, recepción) que involucre un item cuya
    unidad canónica está inactiva es rechazada con un mensaje que identifica el item y
    solicita actualizar su unidad canónica antes de continuar.
  - Los registros históricos (transacciones ya confirmadas) que referencian la unidad
    no se alteran.
- RF-UM-01.6: El catálogo de unidades es compartido entre todas las tiendas de la marca.

### RF-UM-02: Unidad base por tipo

- RF-UM-02.1: Cada tipo de medida tiene una unidad base predefinida a la que referencian
  todos los factores de conversión de ese tipo:
  - Peso → gramos (`g`)
  - Volumen → mililitros (`ml`)
  - Unidad → unidad (`und`)
- RF-UM-02.2: La unidad base de cada tipo tiene factor de conversión `1`. No puede
  modificarse ni inactivarse mientras haya unidades del mismo tipo activas.

### RF-UM-03: Conversión automática

- RF-UM-03.1: Cuando en cualquier módulo (recetas, líneas de compra, recepción de pedidos)
  se especifica una cantidad en una unidad distinta a la canónica del item, el sistema
  convierte automáticamente multiplicando por el factor de equivalencia correspondiente.
- RF-UM-03.2: La conversión solo aplica entre unidades del mismo tipo. El sistema rechaza
  conversiones entre tipos distintos (ej. peso a volumen) con mensaje explicativo.
- RF-UM-03.3: El resultado de la conversión se almacena siempre en la unidad canónica
  del item. La unidad de origen y la cantidad original se conservan en el registro
  transaccional del módulo consumidor (p. ej., campos `unidad_origen` y `cantidad_origen`
  en `LineaCompra`, `IngredienteReceta`, `LineaRecepcion`); este módulo no define
  una entidad centralizada de log de conversiones.

### RF-UM-04: Listado y consulta

- RF-UM-04.1: El administrador puede consultar el catálogo completo de unidades agrupado
  por tipo, con código, nombre, factor de conversión y estado (activa/inactiva).
- RF-UM-04.2: Desde el detalle de una unidad, el admin puede ver cuántos items la tienen
  asignada como unidad canónica (campo `items_con_unidad_canonica` en la respuesta del detalle).

---

## Criterios de Éxito

- **Configuración rápida**: El admin puede registrar el conjunto inicial de unidades
  de medida de la marca en menos de 10 minutos.
- **Conversión sin errores**: El 100% de las conversiones entre unidades del mismo tipo
  producen el resultado matemáticamente correcto según el factor registrado.
- **Integridad del catálogo**: El sistema previene el 100% de los intentos de crear
  unidades con código duplicado o de convertir entre tipos incompatibles.
- **Trazabilidad de unidades**: En cualquier registro que involucre cantidades (compra,
  receta, recepción), la unidad de origen y la cantidad convertida son siempre visibles.

---

## Entidades Clave

| Entidad | Atributos |
|---------|-----------|
| `UnidadMedida` | codigo (único), nombre, tipo_medida, factor_conversion `DECIMAL(12,4)`, unidad_base `BOOLEAN`, activo `BOOLEAN` |

---

## Dependencias y Suposiciones

### Dependencias

- **001-autenticacion**: El admin debe estar autenticado para gestionar el catálogo.
- Sin dependencias de otras features del catálogo — las unidades de medida son el
  prerequisito más temprano de la Ola 2.

### Suposiciones

- El seed de datos inicial incluye las 3 unidades base (`g`, `ml`, `und`) más un
  conjunto estándar de gastronomía: `kg`, `t`, `mg` (peso); `L`, `dL`, `cL` (volumen);
  `docena`, `par`, `caja` (unidad). El admin puede agregar unidades adicionales según
  las necesidades de la marca; no necesita crear las del seed manualmente.
- No existe conversión entre tipos de medida distintos en ningún caso (ej. litros a
  kilogramos requeriría densidad, lo cual está fuera del alcance).
- El factor de conversión es siempre respecto a la unidad base del tipo, no entre
  pares de unidades arbitrarios. Esto simplifica el modelo y garantiza consistencia.
- Los factores de conversión son decimales positivos con hasta 4 decimales de precisión
  (`DECIMAL(12,4)`); no se admiten factores negativos ni cero.

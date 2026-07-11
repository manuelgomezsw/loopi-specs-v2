# Especificación de Feature: Gestión de Empleados

**Branch de Feature**: `003-gestion-empleados`
**Actualización**: `018-selects-tienda-tipo-doc`
**Creado**: 2026-05-18
**Actualizado**: 2026-06-21
**Estado**: Cerrada
**Referencia funcional**: [§4.1 Gestión de Empleados](../loopi-v2-funcional/spec.md)

---

## Clarificaciones

### Sesión 2026-06-21

- Q: ¿El campo "Tienda" en el formulario de creación/edición de empleado debe ser un cuadro de texto o una lista desplegable? → A: Debe ser una lista desplegable (select) que carga dinámicamente las tiendas activas del sistema al abrir el formulario.
- Q: ¿El campo "Tipo de documento" debe ser un cuadro de texto libre o una lista de opciones predefinidas? → A: Debe ser una lista desplegable (select) con los tipos de documento válidos para empleados en el sistema: CC, CE, NUIP y PE.

### Sesión 2026-05-24

- Q: ¿Qué ocurre si el admin intenta inactivar al último administrador activo del sistema? → A: El sistema impide la operación si quedaría cero admins activos (protección sistémica).
- Q: ¿Puede un empleado estar asignado a múltiples tiendas simultáneamente? → A: No; un empleado tiene exactamente una tienda asignada (FK simple, sin relación N:M).
- Q: ¿Qué algoritmo se usa para el hashing de contraseñas? → A: `bcrypt` con factor de coste 12 (`golang.org/x/crypto/bcrypt`).
- Q: ¿Se requiere audit log de cambios en empleados? → A: Sí — log inmutable con actor, acción, entidad afectada y timestamp (tabla `employee_audit_log`).
- Q: ¿El listado de empleados requiere búsqueda por texto y paginación? → A: Sí — búsqueda por nombre o usuario (ILIKE) + paginación por offset (page/limit).

---

## Escenarios de Usuario y Pruebas *(obligatorio)*

### Historia de Usuario 1 — Crear un empleado nuevo (Prioridad: P1)

El administrador registra un nuevo empleado ingresando sus datos personales, asignándole un rol
y, si el rol lo requiere, una tienda. El empleado recibe una contraseña inicial y puede
autenticarse de inmediato.

**Por qué esta prioridad**: Sin empleados creados, ningún lider_tienda ni barista puede
operar el sistema.

**Prueba Independiente**: Puede verificarse creando un empleado con cada rol y comprobando
que puede autenticarse y accede solo a lo que su rol permite.

**Escenarios de Aceptación**:

1. **Dado** que el admin crea un empleado con rol lider_tienda y tienda asignada,
   **Cuando** guarda el registro,
   **Entonces** el empleado queda activo, puede autenticarse y ve solo los datos de su tienda.

2. **Dado** que el admin crea un empleado con rol barista sin asignarle tienda,
   **Cuando** intenta guardar,
   **Entonces** el sistema rechaza la operación indicando que la tienda es obligatoria
   para baristas y líderes de tienda.

3. **Dado** que ya existe un empleado con el mismo nombre de usuario,
   **Cuando** el admin intenta crear otro con ese mismo usuario,
   **Entonces** el sistema rechaza la operación indicando que el usuario ya existe.

4. **Dado** que el admin crea un empleado con rol admin,
   **Cuando** guarda el registro,
   **Entonces** el empleado queda sin tienda asignada fija y tiene acceso a todas las tiendas.

5. **Dado** que el admin abre el formulario de creación de empleado,
   **Cuando** el formulario se despliega,
   **Entonces** el campo "Tienda" muestra una lista desplegable con únicamente las tiendas activas registradas en el sistema, sin necesidad de escribir texto libre.

6. **Dado** que el admin abre el formulario de creación de empleado,
   **Cuando** el formulario se despliega,
   **Entonces** el campo "Tipo de documento" muestra una lista desplegable con las opciones: CC, CE, NUIP, PE.

7. **Dado** que no existen tiendas activas en el sistema,
   **Cuando** el admin abre el formulario de creación,
   **Entonces** el campo "Tienda" muestra la lista vacía e indica que no hay tiendas disponibles.

---

### Historia de Usuario 2 — Editar los datos de un empleado (Prioridad: P1)

El administrador actualiza la información de un empleado existente: datos personales, rol o
tienda asignada. Los cambios aplican de inmediato en la próxima sesión del empleado.

**Por qué esta prioridad**: Los empleados cambian de rol o de tienda con frecuencia en un
negocio multi-tienda.

**Prueba Independiente**: Puede verificarse cambiando la tienda asignada de un líder y
comprobando que en su siguiente sesión solo ve los datos de la nueva tienda.

**Escenarios de Aceptación**:

1. **Dado** que un líder de tienda tiene sesión activa en la Tienda A,
   **Cuando** el admin le reasigna la Tienda B y el líder inicia una nueva sesión,
   **Entonces** el líder ve únicamente los datos de la Tienda B.

2. **Dado** que el admin cambia el rol de un empleado de barista a lider_tienda,
   **Cuando** el empleado inicia una nueva sesión,
   **Entonces** tiene los permisos del nuevo rol.

3. **Dado** que el admin intenta editar el nombre de usuario de un empleado con un nombre
   que ya usa otro empleado,
   **Cuando** intenta guardar,
   **Entonces** el sistema rechaza el cambio con mensaje de usuario duplicado.

---

### Historia de Usuario 3 — Inactivar y reactivar un empleado (Prioridad: P1)

El administrador inactiva la cuenta de un empleado que deja de trabajar en la empresa.
El empleado inactivo no puede autenticarse. Si el empleado regresa, el admin puede reactivarlo.

**Por qué esta prioridad**: Control de acceso crítico — un empleado que ya no trabaja no debe
poder ingresar al sistema.

**Prueba Independiente**: Puede verificarse inactivando un empleado y comprobando que su
intento de login es rechazado sin revelar el motivo.

**Escenarios de Aceptación**:

1. **Dado** que el admin inactiva un empleado,
   **Cuando** ese empleado intenta iniciar sesión,
   **Entonces** el sistema rechaza el acceso con el mensaje genérico de credenciales inválidas.

2. **Dado** que un empleado tiene sesión activa y el admin lo inactiva,
   **Cuando** el empleado intenta realizar cualquier operación,
   **Entonces** el sistema rechaza la operación y lo redirige al login.

3. **Dado** que un empleado está inactivo,
   **Cuando** el admin lo reactiva,
   **Entonces** el empleado puede volver a autenticarse con sus credenciales previas.

4. **Dado** que solo hay un empleado con rol admin activo en el sistema,
   **Cuando** el admin intenta inactivar esa cuenta (propia o de otro),
   **Entonces** el sistema rechaza la operación con el mensaje
   "No es posible inactivar al último administrador activo."

---

### Historia de Usuario 4 — Resetear contraseña de un empleado (Prioridad: P2)

El administrador restablece la contraseña de un empleado cuando este la olvida o por
razones de seguridad. El empleado recibe una contraseña temporal que debe cambiar en
su primer inicio de sesión.

**Por qué esta prioridad**: Es la única vía de recuperación de acceso en esta versión;
no existe recuperación automática por correo.

**Prueba Independiente**: Puede verificarse reseteando la contraseña y comprobando que
el empleado puede iniciar sesión con la contraseña temporal y que se le solicita cambiarla.

**Escenarios de Aceptación**:

1. **Dado** que el admin resetea la contraseña de un empleado,
   **Cuando** ese empleado inicia sesión con la contraseña temporal,
   **Entonces** el sistema le solicita establecer una nueva contraseña antes de continuar.

2. **Dado** que el admin resetea la contraseña,
   **Cuando** intenta ver la contraseña temporal generada,
   **Entonces** el sistema la muestra una única vez en la pantalla del admin y no la almacena
   en texto legible.

---

### Historia de Usuario 5 — Ver el listado de empleados (Prioridad: P1)

El administrador consulta la lista de todos los empleados registrados para conocer quién
opera en cada tienda, qué rol tiene y si está activo.

**Por qué esta prioridad**: Es la pantalla de gestión central del equipo operativo.

**Prueba Independiente**: Puede verificarse con empleados en distintas tiendas, roles y
estados, validando que el listado los muestra correctamente filtrados.

**Escenarios de Aceptación**:

1. **Dado** que existen empleados en distintas tiendas y con distintos roles,
   **Cuando** el admin accede al listado de empleados,
   **Entonces** puede ver nombre, usuario, rol, tienda asignada y estado de cada uno.

2. **Dado** que el admin filtra el listado por tienda,
   **Cuando** selecciona una tienda específica,
   **Entonces** ve únicamente los empleados asignados a esa tienda.

3. **Dado** que el admin escribe "ana" en el campo de búsqueda,
   **Cuando** ejecuta la búsqueda,
   **Entonces** ve solo los empleados cuyo nombre completo o usuario contenga "ana"
   (insensible a mayúsculas), paginados con `limit` 20 y el total de resultados.

4. **Dado** que hay más empleados que el límite de página,
   **Cuando** el admin navega a la página siguiente,
   **Entonces** ve el siguiente bloque de empleados conservando los filtros activos.

---

## Requisitos Funcionales

### RF-EMP-01: Creación de empleados

- RF-EMP-01.1: Solo el administrador puede crear empleados.
- RF-EMP-01.2: Los campos obligatorios son: nombre, apellido, nombre de usuario, rol y,
  para los roles lider_tienda y barista, la tienda asignada. La tienda asignada debe
  existir y estar activa; el sistema rechaza la operación si la tienda está inactiva.
- RF-EMP-01.3: Los campos opcionales son: tipo de documento, número de documento, teléfono,
  email y fecha de nacimiento.
- RF-EMP-01.4: El nombre de usuario es único en todo el sistema. El sistema rechaza duplicados.
- RF-EMP-01.5: El sistema genera una contraseña temporal al crear el empleado.
  Esta contraseña se muestra una única vez al admin y el empleado debe cambiarla en su
  primer inicio de sesión.
- RF-EMP-01.6: Un empleado recién creado queda activo por defecto.
- RF-EMP-01.7: El rol admin no requiere tienda asignada. Asignar tienda a un admin es un error.
- RF-EMP-01.8: El campo "Tienda" en el formulario de creación de empleado debe presentarse como una lista desplegable. La lista carga únicamente las tiendas activas del sistema al momento de abrir el formulario. Si no existen tiendas activas, la lista aparece vacía con un mensaje informativo. No se permite entrada de texto libre en este campo.
- RF-EMP-01.9: El campo "Tipo de documento" en el formulario de creación de empleado debe presentarse como una lista desplegable con los tipos de documento válidos para empleados del sistema. Las opciones disponibles son: **CC** (Cédula de Ciudadanía), **CE** (Cédula de Extranjería), **NUIP** (Número Único de Identificación Personal), **PE** (Permiso Especial de Permanencia). El campo es opcional; si el admin no selecciona ninguna opción, el tipo de documento queda sin registrar.
- RF-EMP-01.10: Si se proporciona email, debe tener formato de dirección de correo electrónico válido. El sistema rechaza la creación si el formato es inválido.
- RF-EMP-01.11: Si se proporciona fecha de nacimiento, el empleado debe ser mayor de 18 años al momento del registro. El sistema rechaza la creación si la fecha corresponde a una persona menor de 18 años.

### RF-EMP-02: Edición de empleados

- RF-EMP-02.1: Solo el administrador puede editar empleados.
- RF-EMP-02.2: Se pueden editar todos los campos excepto el nombre de usuario.
- RF-EMP-02.3: Si el admin cambia el rol de un empleado a lider_tienda o barista y no tiene
  tienda asignada, el sistema obliga a seleccionarla antes de guardar. La tienda asignada
  debe existir y estar activa; el sistema rechaza la operación si la tienda está inactiva.
- RF-EMP-02.4: Si el admin cambia el rol a admin, el sistema elimina la tienda asignada
  del empleado automáticamente.
- RF-EMP-02.5: Los cambios de rol y tienda aplican en la próxima sesión del empleado;
  las sesiones activas no se interrumpen hasta su expiración natural. La ventana máxima
  con permisos obsoletos equivale al TTL de sesión definido en RF-AUTH-01.3 de
  001-autenticacion.
- RF-EMP-02.6: Un admin puede editar su propio perfil, incluyendo su propio rol. Si el
  intento de cambio de rol resultaría en que el sistema quede sin ningún administrador
  activo (es decir, es el único admin activo), el sistema rechaza la operación con el
  mensaje: "No es posible cambiar el rol del último administrador activo." La verificación
  es atómica (misma garantía que RF-EMP-03.5).
- RF-EMP-02.7: En el formulario de edición de empleado, los campos "Tienda" y "Tipo de documento" aplican las mismas reglas de presentación definidas en RF-EMP-01.8 y RF-EMP-01.9. La tienda actualmente asignada debe aparecer preseleccionada en la lista desplegable. El tipo de documento registrado (si existe) debe aparecer preseleccionado.
- RF-EMP-02.8: El campo email sigue las mismas reglas de validación de formato definidas en RF-EMP-01.10.
- RF-EMP-02.9: El campo fecha de nacimiento sigue las mismas reglas de edad mínima definidas en RF-EMP-01.11.

### RF-EMP-03: Inactivación y reactivación

- RF-EMP-03.1: Solo el administrador puede inactivar o reactivar empleados.
- RF-EMP-03.2: Un empleado inactivo no puede autenticarse. El mensaje de rechazo es genérico
  y usa el mismo texto exacto que define RF-AUTH-02.3 en la feature 001-autenticacion,
  sin revelar que la cuenta está inactiva.
- RF-EMP-03.3: No es posible eliminar un empleado; solo inactivarlo. El historial de
  operaciones del empleado se conserva.
- RF-EMP-03.4: Al reactivar un empleado, recupera su rol y tienda asignada previos. El flag
  `requiere_cambio_contrasena` y la contraseña (temporal o definitiva) se conservan tal
  como estaban al momento de la inactivación; inactivar/reactivar no altera las credenciales.
- RF-EMP-03.5: El sistema impide inactivar a un empleado con rol `admin` si esa operación
  dejaría el sistema sin ningún administrador activo. En ese caso, se rechaza la operación
  con un mensaje explícito: "No es posible inactivar al último administrador activo."
  La verificación debe ejecutarse de forma atómica para garantizar correctitud ante
  operaciones concurrentes.

### RF-EMP-04: Reset de contraseña

- RF-EMP-04.1: Solo el administrador puede resetear contraseñas.
- RF-EMP-04.2: Al resetear, el sistema genera una contraseña temporal y la muestra una única
  vez al admin. No se envía por correo en esta versión. Cada llamada al endpoint genera una
  nueva contraseña temporal distinta; el endpoint no es idempotente.
- RF-EMP-04.3: El empleado con contraseña temporal debe establecer una nueva contraseña en su
  primer inicio de sesión. No puede acceder al sistema sin completar este paso. El reset no
  invalida sesiones activas existentes del empleado; estas expiran en su tiempo natural.
- RF-EMP-04.4: Todas las contraseñas (temporales y definitivas) se almacenan exclusivamente
  como hash `bcrypt` con factor de coste 12. No se persiste ninguna contraseña en texto plano.
- RF-EMP-04.5: La nueva contraseña que establece el empleado debe tener un mínimo de
  4 caracteres. El sistema rechaza contraseñas más cortas con mensaje de validación.
- RF-EMP-04.6: Mientras `requiere_cambio_contrasena = 1`, todos los endpoints del sistema
  quedan bloqueados con HTTP 403 para ese empleado, excepto el endpoint de cambio de
  contraseña. Esta feature define el flag; la intercepción y el bloqueo son responsabilidad
  del flujo de sesión definido en 001-autenticacion.

### RF-EMP-05-A: Audit log de operaciones

- RF-EMP-05-A.1: Toda operación de escritura sobre un empleado (crear, editar, inactivar,
  reactivar, resetear contraseña) genera un registro inmutable en `employee_audit_log`.
- RF-EMP-05-A.2: Cada entrada del audit log contiene: `id`, `actor_id` (admin que ejecutó),
  `accion` (enum: CREAR, EDITAR, INACTIVAR, REACTIVAR, RESET_CONTRASENA),
  `empleado_id` (afectado), `detalle` (campo JSON con valores anteriores/nuevos),
  `created_at` (timestamp UTC, no modificable). El campo `detalle` nunca incluye
  contraseñas ni hashes de contraseña, independientemente de la acción registrada.
- RF-EMP-05-A.3: Los registros del audit log no pueden editarse ni eliminarse.
- RF-EMP-05-A.4: Los intentos de acceso denegado a los endpoints de empleados quedan
  registrados en el log estructurado JSON (vía `LogOperacion`) con los campos:
  `operacion:"acceso_denegado"`, `endpoint`, `user_id` (si el token JWT es válido pero
  el rol no cumple) y `motivo` (`rol_insuficiente` para HTTP 403 por RBAC). Estos eventos
  **no** se insertan en `log_auditoria_empleados`; ese registro está reservado para
  operaciones de escritura exitosas sobre empleados.

### RF-EMP-05: Listado y consulta

- RF-EMP-05.1: El administrador puede ver el listado de todos los empleados con nombre, usuario,
  rol, tienda asignada y estado (activo/inactivo).
- RF-EMP-05.2: El listado puede filtrarse por tienda y por estado. El filtro de estado muestra
  por defecto **Activos** (lineamiento cross §Filtros en Listados de la constitución).
  El admin puede cambiar a Inactivos o Todos de forma explícita.
- RF-EMP-05.3: Desde el listado, el admin puede acceder al detalle y edición de cualquier empleado.
- RF-EMP-05.4: El listado soporta búsqueda por texto libre sobre nombre completo o nombre de
  usuario (coincidencia parcial, insensible a mayúsculas/minúsculas).
- RF-EMP-05.5: El listado está paginado por offset: parámetros `page` (1-based) y `limit`
  (default 20, máximo 100). La respuesta incluye el total de registros que coinciden.
- RF-EMP-05.6: El campo `contrasena_hash` nunca se incluye en ninguna respuesta de API,
  en ningún endpoint (listado, detalle, creación, edición ni cambio de estado).

---

## Criterios de Éxito

- **Alta sin fricción**: El admin puede crear un empleado completo en menos de 3 minutos, sin necesidad de recordar o escribir nombres de tiendas ni códigos de tipo de documento.
- **Selección sin errores**: El 100% de las selecciones de tienda en el formulario de empleado corresponden a tiendas activas válidas; no es posible registrar un empleado con una tienda inexistente o inactiva mediante la interfaz.
- **Datos de documento coherentes**: El 100% de los tipos de documento registrados en el sistema corresponden a tipos válidos reconocidos en Colombia.
- **Control de acceso inmediato**: Al inactivar un empleado, su acceso queda bloqueado
  en la próxima operación que intente, sin demora.
- **Seguridad de contraseñas**: El 100% de las contraseñas temporales se muestran una
  única vez y nunca quedan almacenadas en texto legible. Todas las contraseñas se almacenan
  con `bcrypt` factor de coste 12; ninguna contraseña en texto plano persiste en base de datos.
- **Unicidad de usuarios**: El sistema previene el 100% de los casos de nombre de usuario
  duplicado en el momento de crear.
- **Integridad del historial**: Al inactivar un empleado, el 100% de sus registros
  operativos anteriores se conservan sin alteración.

---

## Entidades Clave

| Entidad | Atributos |
|---------|-----------|
| `Empleado` | nombre, apellido, usuario (único), contraseña (hash), tipo_documento (enum: CC/CE/NUIP/PE, opcional), numero_documento, telefono, email, fecha_nacimiento, rol, tienda_id (FK a Tienda, nullable solo para admins), activo, requiere_cambio_contrasena |
| `EmployeeAuditLog` | id, actor_id (FK a Empleado), accion (enum), empleado_id (FK a Empleado), detalle (JSON), created_at (UTC, inmutable) |

---

## Dependencias y Suposiciones

### Dependencias

- **001-autenticacion**: El mecanismo de sesión con rol y tienda_id es prerequisito.
  La validación de empleado activo en el login se implementa en esa feature.
- **002-gestion-tiendas**: La tienda asignada al empleado debe existir y estar activa en el
  sistema. No se puede asignar una tienda inexistente o inactiva.

### Suposiciones

- No existe recuperación de contraseña por correo en esta versión; el flujo de reset
  es exclusivamente manual por el admin.
- El nombre de usuario no se puede editar una vez creado para mantener la trazabilidad
  del historial de operaciones.
- Un admin puede gestionar empleados de cualquier tienda, sin restricción.
- Cada empleado tiene exactamente una tienda asignada (FK simple). No existe relación N:M
  entre empleados y tiendas. La asignación múltiple queda diferida a una versión futura.
- La contraseña temporal no tiene expiración propia; expira cuando el empleado la cambia
  o cuando el admin hace un nuevo reset.
- No existe auto-bloqueo de cuenta por inactividad temporal (solo el admin puede inactivar).
- El listado de tiendas para el select se consulta en tiempo real al abrir el formulario;
  no se cachea en el cliente para garantizar que siempre refleja el estado activo actual.
- Los tipos de documento válidos (CC, CE, NUIP, PE) son un conjunto cerrado
  definido por normativa colombiana y no requieren configuración dinámica; se tratan como
  constantes de la aplicación.
- El campo `tipo_documento` del empleado almacena únicamente el código abreviado
  (p. ej., "CC"), no la descripción larga.

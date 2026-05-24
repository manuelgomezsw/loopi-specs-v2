# Especificación de Feature: Gestión de Empleados

**Branch de Feature**: `003-gestion-empleados`
**Creado**: 2026-05-18
**Estado**: Borrador
**Referencia funcional**: [§4.1 Gestión de Empleados](../loopi-v2-funcional/spec.md)

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

---

## Requisitos Funcionales

### RF-EMP-01: Creación de empleados

- RF-EMP-01.1: Solo el administrador puede crear empleados.
- RF-EMP-01.2: Los campos obligatorios son: nombre, apellido, nombre de usuario, rol y,
  para los roles lider_tienda y barista, la tienda asignada.
- RF-EMP-01.3: Los campos opcionales son: tipo de documento, número de documento, teléfono,
  email y fecha de nacimiento.
- RF-EMP-01.4: El nombre de usuario es único en todo el sistema. El sistema rechaza duplicados.
- RF-EMP-01.5: El sistema genera una contraseña temporal al crear el empleado.
  Esta contraseña se muestra una única vez al admin y el empleado debe cambiarla en su
  primer inicio de sesión.
- RF-EMP-01.6: Un empleado recién creado queda activo por defecto.
- RF-EMP-01.7: El rol admin no requiere tienda asignada. Asignar tienda a un admin es un error.

### RF-EMP-02: Edición de empleados

- RF-EMP-02.1: Solo el administrador puede editar empleados.
- RF-EMP-02.2: Se pueden editar todos los campos excepto el nombre de usuario.
- RF-EMP-02.3: Si el admin cambia el rol de un empleado a lider_tienda o barista y no tiene
  tienda asignada, el sistema obliga a seleccionarla antes de guardar.
- RF-EMP-02.4: Si el admin cambia el rol a admin, el sistema elimina la tienda asignada
  del empleado automáticamente.
- RF-EMP-02.5: Los cambios de rol y tienda aplican en la próxima sesión del empleado;
  las sesiones activas no se interrumpen hasta su expiración natural.

### RF-EMP-03: Inactivación y reactivación

- RF-EMP-03.1: Solo el administrador puede inactivar o reactivar empleados.
- RF-EMP-03.2: Un empleado inactivo no puede autenticarse. El mensaje de rechazo es genérico
  (igual que credenciales incorrectas, sin revelar que la cuenta está inactiva).
- RF-EMP-03.3: No es posible eliminar un empleado; solo inactivarlo. El historial de
  operaciones del empleado se conserva.
- RF-EMP-03.4: Al reactivar un empleado, recupera su rol y tienda asignada previos.

### RF-EMP-04: Reset de contraseña

- RF-EMP-04.1: Solo el administrador puede resetear contraseñas.
- RF-EMP-04.2: Al resetear, el sistema genera una contraseña temporal y la muestra una única
  vez al admin. No se envía por correo en esta versión.
- RF-EMP-04.3: El empleado con contraseña temporal debe establecer una nueva contraseña en su
  primer inicio de sesión. No puede acceder al sistema sin completar este paso.

### RF-EMP-05: Listado y consulta

- RF-EMP-05.1: El administrador puede ver el listado de todos los empleados con nombre, usuario,
  rol, tienda asignada y estado (activo/inactivo).
- RF-EMP-05.2: El listado puede filtrarse por tienda y por estado.
- RF-EMP-05.3: Desde el listado, el admin puede acceder al detalle y edición de cualquier empleado.

---

## Criterios de Éxito

- **Alta sin fricción**: El admin puede crear un empleado completo en menos de 3 minutos.
- **Control de acceso inmediato**: Al inactivar un empleado, su acceso queda bloqueado
  en la próxima operación que intente, sin demora.
- **Seguridad de contraseñas**: El 100% de las contraseñas temporales se muestran una
  única vez y nunca quedan almacenadas en texto legible.
- **Unicidad de usuarios**: El sistema previene el 100% de los casos de nombre de usuario
  duplicado en el momento de crear.
- **Integridad del historial**: Al inactivar un empleado, el 100% de sus registros
  operativos anteriores se conservan sin alteración.

---

## Entidades Clave

| Entidad | Atributos |
|---------|-----------|
| `Empleado` | nombre, apellido, usuario (único), contraseña (hash), tipo_documento, numero_documento, telefono, email, fecha_nacimiento, rol, tienda_asignada, activo, requiere_cambio_contrasena |

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
- La contraseña temporal no tiene expiración propia; expira cuando el empleado la cambia
  o cuando el admin hace un nuevo reset.
- No existe auto-bloqueo de cuenta por inactividad temporal (solo el admin puede inactivar).

# Especificación de Feature: Autenticación y Gestión de Sesión

**Branch de Feature**: `001-autenticacion`
**Creado**: 2026-05-18
**Estado**: Borrador
**Referencia funcional**: [§2.2 Autenticación](../loopi-v2-funcional/spec.md)

---

## Escenarios de Usuario y Pruebas *(obligatorio)*

### Historia de Usuario 1 — Inicio de sesión exitoso (Prioridad: P1)

Un empleado ingresa su usuario y contraseña en la pantalla de login. Si las credenciales son
correctas y el empleado está activo, el sistema le da acceso y lo lleva a su pantalla principal
según su rol.

**Por qué esta prioridad**: Es la puerta de entrada al sistema. Sin sesión activa no existe
ninguna otra operación.

**Prueba Independiente**: Puede verificarse con un usuario activo de cada rol y validando que
el acceso redirige a la pantalla correcta con los permisos esperados.

**Escenarios de Aceptación**:

1. **Dado** que un administrador tiene usuario y contraseña válidos,
   **Cuando** ingresa sus credenciales correctas,
   **Entonces** el sistema le abre sesión y lo dirige al dashboard con acceso a todas las tiendas.

2. **Dado** que un líder de tienda tiene usuario y contraseña válidos,
   **Cuando** ingresa sus credenciales correctas,
   **Entonces** el sistema le abre sesión y lo dirige al dashboard de su tienda asignada.

3. **Dado** que un barista tiene usuario y contraseña válidos,
   **Cuando** ingresa sus credenciales correctas,
   **Entonces** el sistema le abre sesión y lo dirige a la vista de inventario de su tienda.

---

### Historia de Usuario 2 — Rechazo de credenciales inválidas o usuario inactivo (Prioridad: P1)

Un empleado intenta ingresar con credenciales incorrectas o con una cuenta que el administrador
ha desactivado. El sistema rechaza el acceso y muestra un mensaje claro sin revelar si el problema
es la contraseña o el estado de la cuenta.

**Por qué esta prioridad**: La seguridad del acceso es fundamental; un rechazo incorrecto o
un mensaje que revele información sensible es un riesgo crítico.

**Prueba Independiente**: Puede verificarse intentando login con contraseña incorrecta y con
usuario inactivo, validando que ambos casos son rechazados con mensaje genérico.

**Escenarios de Aceptación**:

1. **Dado** que un usuario ingresa una contraseña incorrecta,
   **Cuando** envía el formulario de login,
   **Entonces** el sistema muestra un mensaje de error genérico y no abre sesión.

2. **Dado** que el administrador inactivó una cuenta de empleado,
   **Cuando** ese empleado intenta iniciar sesión con credenciales correctas,
   **Entonces** el sistema rechaza el acceso con el mismo mensaje genérico sin indicar el motivo.

3. **Dado** que un usuario envía el formulario de login cinco veces seguidas con error,
   **Cuando** intenta el sexto intento,
   **Entonces** el sistema bloquea temporalmente el intento por 5 minutos.

---

### Historia de Usuario 3 — Cierre de sesión (Prioridad: P2)

El empleado cierra su sesión desde el menú de usuario. Su acceso queda revocado de inmediato
y cualquier acción posterior requiere autenticarse de nuevo.

**Por qué esta prioridad**: El cierre explícito de sesión protege al sistema en dispositivos
compartidos (tablets en el punto de venta).

**Prueba Independiente**: Puede verificarse cerrando sesión y comprobando que las rutas
protegidas ya no son accesibles sin volver a autenticarse.

**Escenarios de Aceptación**:

1. **Dado** que un usuario tiene sesión activa,
   **Cuando** hace clic en "Cerrar sesión",
   **Entonces** el sistema invalida la sesión y redirige a la pantalla de login.

2. **Dado** que un usuario cerró sesión,
   **Cuando** intenta acceder directamente a una ruta protegida (ej. inventario),
   **Entonces** el sistema lo redirige al login sin mostrar el contenido protegido.

---

### Historia de Usuario 4 — Expiración automática de sesión (Prioridad: P2)

Si el empleado no cierra sesión manualmente, la sesión expira automáticamente tras el tiempo
configurado (por defecto 24 horas). Al intentar cualquier acción tras la expiración, el sistema
lo devuelve al login.

**Por qué esta prioridad**: Protege el sistema cuando el empleado olvida cerrar sesión en
un dispositivo compartido.

**Prueba Independiente**: Puede verificarse configurando un tiempo de expiración corto y
verificando que las operaciones fallan tras ese tiempo.

**Escenarios de Aceptación**:

1. **Dado** que la sesión de un usuario expiró,
   **Cuando** intenta realizar cualquier operación,
   **Entonces** el sistema rechaza la solicitud y lo redirige al login.

2. **Dado** que el administrador configuró la expiración en 8 horas,
   **Cuando** un usuario lleva más de 8 horas con sesión abierta,
   **Entonces** la próxima operación que intente requiere autenticarse nuevamente.

---

## Requisitos Funcionales

### RF-AUTH-01: Autenticación con credenciales

- RF-AUTH-01.1: El sistema permite iniciar sesión con usuario (texto) y contraseña.
- RF-AUTH-01.2: Tras una autenticación exitosa, el sistema emite una sesión que contiene:
  el rol del empleado y, para lider_tienda y barista, el identificador de su tienda asignada.
  El administrador no tiene tienda asignada fija en su sesión.
- RF-AUTH-01.3: La sesión tiene un tiempo de expiración configurable por el administrador.
  El valor por defecto es 24 horas.
- RF-AUTH-01.4: Tras cinco intentos fallidos consecutivos desde el mismo usuario, el sistema
  bloquea nuevos intentos durante 5 minutos.

### RF-AUTH-02: Rechazo de acceso

- RF-AUTH-02.1: El sistema rechaza el login de cualquier usuario con credenciales incorrectas.
- RF-AUTH-02.2: El sistema rechaza el login de cualquier usuario marcado como inactivo,
  aunque sus credenciales sean correctas.
- RF-AUTH-02.3: El mensaje de error no distingue si el fallo es por contraseña incorrecta
  o cuenta inactiva, para evitar revelar información sobre las cuentas existentes.

### RF-AUTH-03: Cierre de sesión

- RF-AUTH-03.1: El usuario puede cerrar su sesión explícitamente desde cualquier pantalla
  del sistema.
- RF-AUTH-03.2: Al cerrar sesión, el acceso queda revocado de inmediato. Cualquier intento
  posterior de acceder a rutas protegidas redirige al login.

### RF-AUTH-04: Expiración automática

- RF-AUTH-04.1: Las sesiones expiran automáticamente tras el tiempo configurado.
- RF-AUTH-04.2: Una sesión expirada es rechazada igual que una sesión inexistente: el sistema
  redirige al login sin mostrar el contenido protegido.

### RF-AUTH-05: Control de acceso por sesión

- RF-AUTH-05.1: Toda ruta y acción del sistema verifica que exista una sesión válida y no
  expirada antes de ejecutarse.
- RF-AUTH-05.2: El rol contenido en la sesión es la única fuente de verdad para determinar
  qué acciones puede realizar el usuario en el resto del sistema.

---

## Criterios de Éxito

- **Acceso sin fricción**: Un empleado con credenciales válidas completa el inicio de sesión
  y llega a su pantalla principal en menos de 3 segundos.
- **Seguridad de acceso**: El 100% de las rutas protegidas son inaccesibles sin sesión válida;
  ninguna respuesta del sistema revela si una cuenta existe o está inactiva.
- **Protección por inactividad**: Las sesiones sin actividad son invalidadas automáticamente
  al cumplirse el tiempo configurado, sin excepción.
- **Bloqueo por intentos fallidos**: Tras cinco intentos fallidos, el acceso queda bloqueado
  5 minutos antes de permitir nuevos intentos.
- **Cierre inmediato**: Al cerrar sesión, el acceso queda revocado en menos de 1 segundo.

---

## Entidades Clave

| Entidad | Atributos relevantes |
|---------|----------------------|
| `Usuario` | usuario, contraseña (hasheada), rol, tienda_asignada, activo |
| `Sesión` | identificador, usuario, rol, tienda_id, creada_en, expira_en |

---

## Dependencias y Suposiciones

### Dependencias

- Los usuarios (empleados) deben existir en el sistema previamente creados por el administrador.
  La creación y gestión de empleados corresponde a la feature `004-empleados`.
- El campo `tienda_id` en la sesión de lider_tienda y barista proviene del atributo
  `tienda_asignada` del empleado al momento del login.

### Suposiciones

- Las contraseñas se almacenan con hash seguro; nunca en texto plano.
- No existe recuperación de contraseña por correo en esta versión; el administrador la resetea
  manualmente (alcance de `004-empleados`).
- El tiempo de expiración de sesión es configurable a nivel de sistema, no por usuario.
- El bloqueo por intentos fallidos es por usuario (no por IP), ya que los usuarios operan
  desde dispositivos fijos en el punto de venta.

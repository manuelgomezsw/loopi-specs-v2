# Lista de Verificación de Seguridad: Gestión de Empleados

**Propósito**: Validar la calidad, completitud y claridad de los requisitos de seguridad y
control de acceso antes de abrir el PR (self-review del autor).
**Creado**: 2026-05-24
**Feature**: [spec.md](../spec.md) · [plan.md](../plan.md) · [contracts/api.md](../contracts/api.md)
**Foco**: Seguridad & control de acceso — bcrypt, RBAC, inactivación, audit log
**Audiencia**: Autor (self-review pre-PR)

---

## Protección de Credenciales

- [x] CHK001 ¿El spec especifica que el mensaje de rechazo para empleado inactivo es
  **literalmente idéntico** (mismo texto exacto) al de credenciales incorrectas, de modo
  que no sea posible inferir el estado de la cuenta mediante diferencias en la respuesta?
  [Clarity, Spec RF-EMP-03.2]

- [x] CHK002 ¿El spec o los contratos de API establecen explícitamente que `contrasena_hash`
  **nunca** se incluye en ninguna respuesta de ningún endpoint, incluidos detalle y listado?
  [Gap — ausente en spec.md; cubierto solo en contracts/api.md]

- [x] CHK003 ¿Están definidos los requisitos de **complejidad y longitud mínima** para la
  contraseña que el empleado establece al reemplazar la temporal? Sin este requisito,
  contraseñas débiles quedan permitidas por omisión. [Gap]

- [x] CHK004 ¿El requisito RF-EMP-04.2 ("mostrar contraseña temporal una única vez") especifica
  el comportamiento ante **reintentos de red** del mismo request? Si el POST es retryable,
  ¿se puede exponer la contraseña en una segunda llamada? [Clarity, Spec RF-EMP-04.2]

---

## Gestión de Sesiones y Cambios de Acceso

- [x] CHK005 ¿El spec define qué ocurre con las **sesiones activas** de un empleado cuando el
  admin resetea su contraseña? ¿Las sesiones existentes se invalidan de inmediato o
  permanecen válidas hasta su expiración natural? [Gap — RF-EMP-04 no lo menciona]

- [x] CHK006 ¿El requisito RF-EMP-02.5 ("cambios de rol aplican en la próxima sesión") define
  la **ventana máxima de exposición** con permisos obsoletos? Sin un TTL de sesión explícito
  referenciado, un empleado podría operar con el rol anterior durante hasta 24 h. [Clarity,
  Spec RF-EMP-02.5]

- [x] CHK007 ¿El requisito RF-EMP-04.3 especifica **qué endpoints quedan bloqueados** mientras
  `requiere_cambio_contrasena = 1`? ¿Solo los endpoints operacionales, o todos incluyendo
  el propio endpoint de cambio de contraseña? [Clarity, Spec RF-EMP-04.3]

---

## Protección del Último Admin y Elevación de Privilegios

- [x] CHK008 ¿El requisito RF-EMP-03.5 describe la verificación del último admin como
  **atómica** (dentro de una transacción) para resistir condiciones de carrera concurrentes?
  O ¿deja el mecanismo de protección como detalle de implementación? [Clarity, Spec RF-EMP-03.5]

- [x] CHK009 ¿El spec define si un admin puede **editar su propio rol** o **inactivarse a sí
  mismo** cuando existe al menos otro admin activo? El RF-EMP-03.5 protege el lockout total
  pero no aclara la auto-modificación. [Gap]

---

## Audit Log e Integridad del Registro

- [x] CHK010 ¿El spec o el data model define explícitamente que el campo `detalle` del
  `log_auditoria_empleados` **nunca contendrá contraseñas** (ni temporales ni hash), ya que
  los cambios de contraseña son uno de los eventos auditados? [Gap — RF-EMP-05-A no lo aclara]

- [x] CHK011 ¿Están definidos requisitos de auditoría para **accesos denegados** (403/401)
  a los endpoints de empleados? ¿Los intentos fallidos de acceso no autorizado deben
  quedar registrados? [Gap — el audit log cubre escrituras pero no rechazos de acceso]

---

## Integridad de Datos y Casos Borde

- [x] CHK012 ¿El spec define qué ocurre con la **contraseña temporal** de un empleado si
  es inactivado antes de usarla? Al reactivarlo, ¿sigue siendo válida o se requiere un
  nuevo reset? [Gap — RF-EMP-03.4 menciona que recupera rol y tienda, pero no la contraseña]

- [x] CHK013 ¿El spec especifica el comportamiento al intentar asignar una **tienda inactiva**
  a un empleado en creación o edición? RF-EMP-01.2 menciona que la tienda debe existir y
  estar activa, pero el criterio de rechazo no está en los escenarios de aceptación. [Clarity,
  Spec RF-EMP-01.2 / RF-EMP-02.3]

---

## Notas

- Marca los ítems al completarlos: `[x]`
- Los ítems marcados `[Gap]` indican requisitos **ausentes** en el spec que deben añadirse
  o descartarse explícitamente antes del PR.
- Los ítems marcados `[Clarity]` indican requisitos **presentes pero ambiguos** que necesitan
  precisión.
- CHK002 y CHK010 son los de mayor riesgo de exposición de datos; priorizar su resolución.

---
name: speckit-finalize-run
description: Cierra una feature después de la implementación — estado de PRs multi-repo,
  verificación atestiguada por el usuario de tareas dependientes de infraestructura,
  limpieza de branches y reporte de cierre.
compatibility: Requires spec-kit project structure with .specify/ directory
metadata:
  author: github-spec-kit
  source: finalize:commands/run.md
---

## User Input

```text
$ARGUMENTS
```

Si `$ARGUMENTS` no está vacío, es el identificador de la feature a cerrar (ej. `007-items-catalogo`).
Si está vacío, resuelve la feature desde el branch actual.

## Goal

Cerrar formalmente una feature ya implementada: confirmar el estado real de sus tareas
(`tasks.md`), el estado de sus Pull Requests en todos los repos que toca (`loopi-specs-v2`,
`loopi-api-v2`, `loopi-web-v2` — los que apliquen), obtener del usuario una confirmación
explícita de cualquier tarea que el agente no pueda verificar por sí mismo, y dejar los
repos locales sincronizados con `develop`. Termina con un reporte de cierre inline.

## Operating Constraints

**NEVER-SELF-ATTEST**: El agente NUNCA marca como completada `[X]` una tarea que dependa de
algo que no puede comprobar desde este entorno (base de datos real, ambiente de staging,
hardware específico, validación manual de un humano, resultados de un smoke test contra un
stack corriendo). Estas tareas se detectan por palabras clave en su descripción (ver Paso 2)
y **siempre** requieren una pregunta explícita al usuario, uno por uno o agrupadas, antes de
marcarlas. Si el usuario no confirma, la tarea queda `[ ]` y se reporta como pendiente.

**NEVER-AUTO-MERGE**: El agente nunca mergea un Pull Request sin que el usuario lo apruebe
explícitamente para ese PR en particular, aunque el CI esté en verde y el resto de PRs de la
feature ya estén mergeados.

**PLAN-THEN-ACT**: Antes de tocar cualquier archivo, mergear cualquier PR, borrar cualquier
branch o marcar cualquier tarea, presenta un plan de cierre completo (ver Paso 4) y espera
confirmación. Ninguna acción del Paso 5 ocurre sin ese visto bueno.

**MULTI-REPO-AWARE**: Esta feature puede tocar más de un repositorio hermano
(`loopi-api-v2`, `loopi-web-v2`), ubicados como directorios hermanos de `loopi-specs-v2`.
Todo el estado (tareas, PRs, branches) debe reportarse por repo, nunca asumido desde uno solo.

**NO DESTRUCTIVO POR DEFECTO**: Nunca borres un branch local o remoto que no esté confirmado
como mergeado a `develop`. Nunca uses `--force` en ningún comando git.

## Execution Steps

### 1. Inicializar contexto

Corre `.specify/scripts/bash/check-prerequisites.sh --json --include-tasks` desde la raíz del repo `loopi-specs-v2`.
Para comillas simples en argumentos como "I'm Groot", usa escape: `I'\''m Groot`.

1. **Si el script tiene éxito**: parsea `FEATURE_DIR` y `AVAILABLE_DOCS` del JSON.
2. **Si el script falla** (no estás en un branch de feature reconocible): escanea
   `specs/NNN-*/` y pide al usuario que elija una feature. **No adivines ni asumas.**

Si `tasks.md` no existe en `FEATURE_DIR`, aborta:

> ❌ **No hay tasks.md**: Corre `/speckit-tasks` y `/speckit-implement` primero.

### 2. Evaluar el estado de las tareas

Lee `tasks.md` completo. Para cada línea de tarea:

- Cuenta cuántas están `[X]` vs `[ ]`.
- Para cada tarea `[ ]`, clasifícala:
  - **Verificable por el agente**: se puede confirmar corriendo algo en este entorno
    (build, lint, test, gates de CI ya definidos en la propia tarea).
  - **Requiere verificación externa**: su descripción menciona (o implica) BD real,
    ambiente de staging/producción, stack corriendo, smoke test manual, validación de un
    humano, hardware específico, o cualquier cosa que este entorno de sesión no tenga.
    Señales típicas: "BD de desarrollo", "smoke test", "verificar en", "ambiente real",
    "producción", "stage", "manualmente".

No hagas nada con esta clasificación todavía — solo repórtala en el Paso 4.

### 3. Estado de Pull Requests multi-repo

Determina qué repos toca la feature leyendo `plan.md` (sección "Estructura del Proyecto" /
contexto técnico — busca menciones a `loopi-api-v2` y `loopi-web-v2`). Para
`loopi-specs-v2` siempre aplica.

Para cada repo aplicable, ubicado como `../<repo>` relativo a la raíz de `loopi-specs-v2`:

1. Busca el nombre exacto del branch de la feature (normalmente
   `feature/<feature-id>`, pero puede variar) con `git -C ../<repo> branch -a --list "*<feature-id>*"`
   y con `gh pr list --repo <owner>/<repo> --search "<feature-id> in:title"` si no hay match local.
2. Para cada PR encontrado, corre `gh pr view <n> --repo <owner>/<repo> --json state,mergeable,statusCheckRollup,url,title`.
3. Registra: número, título, estado (OPEN/MERGED/CLOSED/DRAFT), conclusión de CI
   (SUCCESS/FAILURE/pendiente), URL.

Si un repo no tiene ningún PR ni branch relacionado, repórtalo como "sin cambios pendientes
en este repo" — no es un error.

### 4. Presentar el plan de cierre

Muestra, sin ejecutar nada todavía:

```markdown
## Plan de Cierre — <feature-id>

### Tareas (tasks.md)
- Completadas: X/Y
- Pendientes verificables por el agente: [lista, o "ninguna"]
- Pendientes que requieren verificación externa: [lista con descripción breve]

### Pull Requests
| Repo | PR | Título | Estado | CI |
|------|----|--------|--------|----|
| ...  | #N | ...    | OPEN/MERGED/... | ✅/❌/⏳ |

### Acciones propuestas
1. [Si hay PRs OPEN con CI verde] Mergear PR #N en <repo> — requiere tu confirmación individual.
2. [Si hay tareas de verificación externa] Confirmar con el usuario si estas tareas ya
   fueron verificadas fuera de este entorno.
3. [Siempre, si hay algo que cerrar] Actualizar tasks.md con nota de cierre.
4. [Siempre] Sincronizar repos locales a `develop` y eliminar branches ya mergeados.
```

Para cada tarea de verificación externa, pregunta explícitamente, por ejemplo:

> ¿Confirmas que **T004** (aplicar migraciones y verificar en BD de desarrollo) fue
> verificada y está OK? (sí/no)

No agrupes silenciosamente varias tareas bajo una sola pregunta genérica tipo "¿todo bien?" —
cada tarea de verificación externa requiere su propia confirmación explícita, aunque puedan
presentarse en la misma pregunta con una lista clara si el usuario prefiere responder de una vez.

Para cada PR abierto con CI verde, pregunta explícitamente si se mergea. Si el CI no está en
verde, no lo ofrezcas como acción — repórtalo como bloqueador.

Espera la respuesta del usuario antes de continuar al Paso 5.

### 5. Aplicar (solo tras confirmación)

Ejecuta únicamente lo que el usuario aprobó:

- **Tareas confirmadas por el usuario**: márcalas `[X]` en `tasks.md`. Agrega o actualiza
  una sección `### Estado de implementación (<fecha>)` al final del archivo, indicando
  explícitamente qué se verificó y quién lo confirmó (el usuario, no el agente) — nunca
  redactes esa nota como si el agente hubiera verificado algo que no pudo comprobar.
- **PRs confirmados**: `gh pr merge <n> --repo <owner>/<repo> --merge` (merge commit, no
  squash — consistente con el historial existente del repo). No uses `--delete-branch` si
  el repo no auto-borra branches remotos por convención; verifica el comportamiento
  observado en PRs anteriores del mismo repo antes de decidir.
- **Sincronización local**: en cada repo tocado, `git checkout develop && git pull`. Si el
  branch de la feature quedó mergeado (local o remoto), bórralo con `git branch -d` (nunca
  `-D`) solo tras confirmar que el merge existe en el historial de `develop`.
- **Commit de `tasks.md`**: sigue el flujo normal de Gitflow del proyecto — branch `chore/`
  o `bugfix/` propio desde `develop`, commit, `npx markdownlint-cli2` (obligatorio antes de
  commitear, ver `CLAUDE.md`), push, PR. Pregunta si el usuario quiere que ese PR se
  mergee también, o si prefiere revisarlo primero.

Si el usuario no aprobó alguna acción, sáltala y repórtala como pendiente en el Paso 6 —
no la ejecutes "para adelantar trabajo".

### 6. Reporte de cierre

Termina con un resumen inline:

```markdown
## Cierre — <feature-id>

| Repo | PRs mergeados | Branch local | Estado |
|------|---------------|--------------|--------|
| ...  | #N, #M        | sincronizado a develop / eliminado | ✅ |

**Tareas**: X/Y completadas (Y de ellas confirmadas por el usuario: [lista]).

**Pendiente** (si algo quedó sin cerrar): [lista con razón — CI rojo, tarea sin confirmar, etc.]
```

Si todo quedó cerrado, dilo explícitamente: "Feature <feature-id> cerrada por completo."
Si algo quedó pendiente, sé específico sobre qué falta y qué se necesita para desbloquearlo
(ej. "esperando que el CI de PR #N en loopi-api-v2 pase").
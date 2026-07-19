<!-- SPECKIT START -->
For additional context about technologies to be used, project structure,
shell commands, and other important information, read the current plan
at specs/007-items-catalogo/plan.md
<!-- SPECKIT END -->

# Loopi v2

La fuente de verdad del proyecto es la constitución en `.specify/memory/constitution.md`.
Este archivo resume las reglas operativas que Claude Code necesita para escribir código correcto en este repo.

# Idioma

Todos los artefactos generados por speckit (`spec.md`, `plan.md`, `tasks.md`, `constitution.md`, listas de verificación, preguntas, resúmenes y cualquier otro output) deben estar **íntegramente en español**. Esto incluye encabezados, contenido, preguntas de aclaración y mensajes al usuario.

# Git Workflow

## Gitflow — regla obligatoria

Todo cambio en este repositorio debe seguir el flujo **Gitflow**. Nunca hagas cambios directamente en `main` o `develop`.

### Ramas principales

| Rama | Propósito |
|------|-----------|
| `main` | Código en producción. Solo recibe merges desde `release/*` o `hotfix/*`. |
| `develop` | Base de integración. Todo trabajo nuevo parte desde aquí. |

### Crear un branch nuevo

**Siempre parte desde `develop`** (excepto `hotfix/*`, que parte desde `main`):

```bash
git checkout develop
git pull origin develop
git checkout -b <tipo>/<nombre-descriptivo>
```

### Convención de nombres

| Tipo | Prefijo | Cuándo usarlo | Ejemplo |
|------|---------|---------------|---------|
| Nueva funcionalidad | `feature/` | Cualquier nueva feature o mejora | `feature/auth-google-login` |
| Corrección urgente en prod | `hotfix/` | Bug crítico que requiere parche inmediato en `main` | `hotfix/fix-payment-crash` |
| Corrección no urgente | `bugfix/` | Bug detectado en `develop` o QA | `bugfix/fix-empty-cart-error` |
| Preparación de versión | `release/` | Estabilización antes de merge a `main` | `release/v1.2.0` |
| Tareas técnicas / refactor | `chore/` | Dependencias, CI, configuración, refactor | `chore/upgrade-node-20` |

### Reglas

- El nombre del branch debe ser en **minúsculas**, palabras separadas por `-`, en inglés o español consistente con el proyecto.
- Los `hotfix/*` parten desde `main` y se mergean a `main` **y** `develop`.
- Los `feature/*`, `bugfix/*` y `chore/*` parten desde `develop` y se mergean solo a `develop`.
- Los `release/*` parten desde `develop` y se mergean a `main` **y** `develop`.
- Nunca hagas `git push --force` en `main` o `develop`.

## Validación pre-push — regla obligatoria antes de hacer push

**Antes de ejecutar `git push` en este repositorio**, debes ejecutar las siguientes validaciones:

### Markdown Lint

Valida que todos los archivos markdown cumplan con los estándares de linting:

```bash
npx markdownlint-cli2 "**/*.md"
```

Si hay errores, corrígelos antes de hacer push.

### Pruebas unitarias — Backend (Go)

Ejecuta todas las pruebas unitarias en modo estricto:

```bash
go test ./... -v
```

El comando debe completarse exitosamente sin errores. Si alguna prueba falla, corrígela antes de hacer push.

### Pruebas unitarias — Frontend

Levanta chromium en local y ejecuta todas las pruebas unitarias:

```bash
npm run test:unit
```

Este comando debe ejecutar el 100% de las pruebas y todas deben pasar exitosamente. Si alguna prueba falla, corrígela antes de hacer push.

### Reglas de validación

- **No hagas `git push`** si alguna validación falla.
- No uses flags para saltarte o ignorar errores.
- Estas validaciones son críticas para mantener la integridad del código.

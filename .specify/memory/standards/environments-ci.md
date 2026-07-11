<!--
SYNC IMPACT REPORT
==================
Version: 1.0.0 (extracción inicial)
Origen: extraído de constitution.md v1.12.0 §"Ambientes" y §"Flujo de Trabajo de Desarrollo"
        como parte de la separación principios/estándares (ver constitution.md v2.0.0,
        Sync Impact Report). Ningún contenido normativo cambia de significado en esta
        extracción; solo cambia su ubicación y se le asignan IDs de regla estables.
Reglas: ENV-01, CI-01, CI-02
-->

# Estándares de Ambientes y CI — Loopi v2 (los tres repos)

Este documento es normativo y aplica por igual a `loopi-specs-v2`, `loopi-api-v2` y
`loopi-web-v2`. Los gates específicos de cada lenguaje/stack (comandos exactos, umbrales
de cobertura) viven en [`backend.md#BE-CI-01`](backend.md) y [`frontend.md#FE-CI-01`](frontend.md);
aquí vive lo que es común a los tres: ambientes, Gitflow, y el gate de seguridad de CI.

---

## [ENV-01] Ambientes: Dev, Stage y Producción

El proyecto opera con tres ambientes completamente separados. Cada uno tiene su propia base de datos,
variables de entorno y credenciales. Compartir recursos entre ambientes está PROHIBIDO.

| Ambiente | Propósito | Infraestructura | Despliegue |
|----------|-----------|-----------------|------------|
| **Dev** | Desarrollo activo del equipo | GCP Cloud SQL `db-f1-micro` (compartido) + Go local + Firebase Emulators | Manual (`go run .` + `ng serve`) |
| **Stage** | Validación funcional y de integración | GCP (espejo de prod, menor capacidad) | Automático al mergear a `develop` |
| **Prod** | Operación real de los negocios | GCP (Cloud SQL MySQL + Cloud Run/GKE + Firebase Hosting) | Automático al mergear a `master` |

**Detalle del ambiente Dev:**

- **Base de datos**: instancia `db-f1-micro` en GCP Cloud SQL, compartida por el equipo.
  Cada desarrollador trabaja contra su propio schema (ej. `loopi_dev_<nombre>`).
- **Backend**: `go run .` en local, con variable de entorno `DB_DSN` apuntando a Cloud SQL dev.
  El binario Go en desarrollo ocupa < 50 MB de RAM.
- **Frontend**: `ng serve` en local con `firebase emulators` para Auth y Hosting.
- **Docker Compose descartado**: la máquina de desarrollo (4.5 GB RAM, sin swap) no soporta
  MySQL + Docker runtime de forma estable. GCP dev elimina ese cuello de botella.

**Reglas comunes a todos los ambientes:**

- Las variables de entorno (DB credentials, JWT secret, API keys) NUNCA se hardcodean en código.
  Se gestionan mediante **GCP Secret Manager** en stage/prod y archivos `.env` locales (no commiteados)
  en dev.
- Los archivos `.env`, `*.local`, `*-secrets.*` DEBEN estar en `.gitignore`. Un secret en el repo
  es un incidente de seguridad.
- Las migraciones de base de datos se ejecutan automáticamente al desplegar en stage y prod,
  antes de que el servicio reciba tráfico. En dev se aplican manualmente con el CLI de migración.
- Stage DEBE reflejar la configuración de prod (mismas variables de entorno en estructura, diferente
  valor). Es el único ambiente donde se valida la paridad de mocks vs. servicios reales.
- El rollback en prod DEBE ser posible sin pérdida de datos. Toda migración irreversible
  DEBE ser aprobada explícitamente por el equipo antes de aplicarse en prod.
- Los logs van a **GCP Cloud Logging** en stage y prod. En dev se usa stdout.

---

## [CI-01] Gitflow — política común

Los tres repos siguen **Gitflow** estricto. Las ramas `master`/`main` y `develop` son protegidas;
todo cambio requiere PR aprobado con CI verde. La tabla de ramas, prefijos y comandos exactos vive
duplicada (intencionalmente, por conveniencia operativa) en el `CLAUDE.md` de cada repo — ver
`Git Workflow` en `loopi-specs-v2/CLAUDE.md`, `loopi-api-v2/CLAUDE.md` y `loopi-web-v2/CLAUDE.md`.

| Rama | Origen | Destino | Cuándo |
|------|--------|---------|--------|
| `feature/*` | `develop` | `develop` | Feature nueva o mejora |
| `bugfix/*` | `develop` | `develop` | Bug no urgente |
| `chore/*` | `develop` | `develop` | Infraestructura, config, docs |
| `hotfix/*` | `master` | `master` + `develop` | Bug crítico en producción |
| `release/*` | `develop` | `master` + `develop` | Estabilización de versión |

**Resolución de conflictos entre ramas protegidas:** Los PRs de resolución DEBEN mergearse como
"Create a merge commit" (no squash), para preservar historia compartida y evitar conflictos
persistentes en GitHub al intentar PR inversos.

---

## [CI-02] Gate de seguridad común — Trivy

**Gate adicional en GitHub Actions CI** (corre automáticamente en cada PR y push a `develop`/`master`
en `loopi-api-v2` y `loopi-web-v2`):

- **Trivy** (`trivy fs`, severidad `HIGH,CRITICAL`, `ignore-unfixed: true`). Resultados publicados
  en el Security tab de GitHub vía SARIF. El PR no puede mergearse si Trivy reporta vulnerabilidades
  de severidad alta o crítica con fix disponible.
- La implementación (workflow YAML) vive en `.github/workflows/security.yml` de cada repo.
  Este documento define la política; cada repo define la ejecución.

`loopi-specs-v2` no tiene código ejecutable, por lo que no corre Trivy; su gate de seguridad es
`gitleaks detect --no-git` (ver `loopi-specs-v2/CLAUDE.md`).

---

**Version**: 1.0.0 | **Sincronizado desde**: constitution.md v1.12.0 | **Last Amended**: 2026-07-11

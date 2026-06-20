# Checklist de Calidad — Infraestructura GCP y Verificación en Stage

**Propósito**: Validar la completitud y claridad de los requisitos de infraestructura GCP (T005-T009) y verificación en stage (T015-T026) — bloque pendiente actual de la feature
**Creado**: 2026-06-20
**Feature**: [spec.md](../spec.md) · [tasks.md](../tasks.md)

---

## Completitud — Infraestructura GCP

- [ ] CHK001 ¿Están documentados los permisos IAM exactos que necesita el service account de App Engine para leer secretos de GCP Secret Manager en tiempo de deploy? [Completitud, Gap]
- [ ] CHK002 ¿El procedimiento de rotación de `DD_API_KEY` ante un compromiso de la clave está definido (pasos, tiempo de indisponibilidad esperado, quién notifica)? [Completitud, Exception Flow, Gap]
- [ ] CHK003 ¿Están especificados los prerequisitos de entorno `gcloud CLI` (versión mínima, proyectos configurados, roles requeridos) para que cualquier desarrollador pueda ejecutar T005-T008 de forma independiente? [Completitud, Assumption, Gap]
- [ ] CHK004 ¿El procedimiento de rollback para un despliegue fallido del servicio `dd-agent` en Cloud Run está definido — qué hacer si T007 o T008 fallan a mitad de ejecución? [Gap, Recovery Flow]
- [ ] CHK005 ¿El supuesto de permisos de Editor/Owner en GCP (documentado en Spec §Supuestos) está validado explícitamente antes de intentar T005-T008, o puede bloquear al desarrollador sin indicación clara? [Assumption, Spec §Supuestos]

## Claridad — Criterios de Verificación en Stage (US1-US3)

- [ ] CHK006 ¿Están definidas las queries exactas en la UI de Datadog APM para verificar T016 — el span `auth.login` con `service.name=loopi-api` y `deployment.environment=staging`? [Clarity, Spec §US1]
- [ ] CHK007 ¿El SLA de 30 segundos de SC-OBS-02 para visibilidad de trazas incluye una tolerancia documentada, o se asume que un resultado a los 31 s es un fallo? [Measurability, SC-OBS-02]
- [ ] CHK008 ¿Están documentados los pasos de diagnóstico para T019 cuando el trace NO muestra spans hijo de BD — cómo distinguir falla de instrumentación vs. falla de exportación? [Coverage, Exception Flow, Gap]
- [ ] CHK009 ¿Los criterios de éxito de T022 (histograma `auth.login.duration` con percentiles p50/p90/p99 visibles) especifican el mínimo de eventos necesarios para que los percentiles sean estadísticamente representativos? [Measurability, Spec §US3]
- [ ] CHK010 ¿Hay un criterio observable que permita confirmar que el `MeterProvider` global se inicializó correctamente antes del deploy de T021, sin requerir un login exitoso en stage? [Coverage, Gap]

## Consistencia — Seguridad y Alcance de Verificación (US4)

- [ ] CHK011 ¿El comando `gitleaks detect --no-git` de T025 es suficiente para detectar la `DD_API_KEY` en archivos `.yaml` además de `.go`, o se necesita una estrategia de escaneo más amplia? [Completitud, Spec §RF-OBS-06]
- [ ] CHK012 ¿Los requisitos de T026 (grep en `app*.yaml`) y RF-OBS-06/RF-OBS-07 cubren ángulos distintos, o hay duplicidad no intencional que podría generar confusión? [Consistency, Spec §RF-OBS-06, RF-OBS-07]
- [ ] CHK013 ¿El requisito `--ingress=internal` de Cloud Run está suficientemente especificado para el contexto de App Engine — qué tráfico exactamente se considera "interno" (mismo proyecto, mismo VPC, ambos)? [Clarity, Spec §RF-OBS-05]

## Cobertura — Escenarios de Fallo No Documentados

- [ ] CHK014 ¿Están definidos los criterios de aceptación para el caso en que el intake OTLP de Datadog rechace trazas con HTTP 401 (clave rotada sin redeploy), más allá de la mención en Casos Límite? [Coverage, Spec §Casos Límite]
- [ ] CHK015 ¿El escenario de `PeriodicReader` enviando payload vacío (RF-OBS-11) tiene un criterio de aceptación observable en los logs de GCP Cloud Logging para confirmar que el guard funciona? [Measurability, Spec §RF-OBS-11]

## Trazabilidad — Responsabilidad y Gates de Entrega

- [ ] CHK016 ¿Las 12 tareas pendientes (T005-T009, T015-T016, T018-T019, T021-T026) tienen responsable asignado o al menos una indicación de quién puede ejecutarlas (dev backend, DevOps, ambos)? [Completitud, Gap]
- [ ] CHK017 ¿El gate formal de release de la feature (qué combinación de checkpoints de fase debe estar verde para considerar la feature entregada) está documentado en spec.md o tasks.md? [Measurability, Gap]

## Notas

- El bloqueador principal es T005-T009 (GCP infra): Secret Manager + Cloud Run dd-agent.
  Todo el trabajo de verificación en stage (T015-T026) depende de estas tareas.
- El código está completo (T003, T004, T010, T011, T012, T013, T014, T017, T020, T027-T031).
  El riesgo está en la infraestructura y en que los criterios de verificación sean suficientemente
  precisos para detectar errores de configuración sin ambigüedad.

# Reporte de Bug: E2E Tests Completamente Ausentes — Spec Requiere Pruebas P1

**Tipo**: Implementation gap

**Severidad**: 🟠 High

**Feature**: 009-inventario-conteo (Frontend)

**Reportado**: 2026-07-13

**Status: ✅ Patched

**Patched**: 2026-07-13

---

## Descripción

**No existen E2E tests** para los flujos críticos (P1) de la feature. Spec requiere automatización de pruebas funcionales.

---

## Trazabilidad

### CLAUDE.md

**[FE-TEST-01]** (Testing — Cobertura Obligatoria):

> "Pruebas: **unitarias por componente + funcionales automatizadas** para flujos críticos (P1)."
>
> - Unit: ≥90% cobertura por componente
> - E2E: Happy path + error paths para P1 user stories

### spec.md

**Escenarios de Aceptación** (línea 25-47):

> "Prueba Independiente: Puede verificarse iniciando un conteo a las 8 a.m..."

**Implícitamente**: Debe haber test automatizado que verifique esto.

---

## Análisis de Causa Raíz

### Archivos Faltantes

```text

loopi-web-v2/e2e/
├── inventario.e2e.ts  ❌ NO EXISTE
└── support/
    └── inventario-page.ts  ❌ NO EXISTE

```text

**Unit tests existen**:

- `inventario-conteo.component.spec.ts` ✅ (pero cobertura baja)

**E2E tests no existen**: ❌

---

## Flujos P1 Que Necesitan E2E Tests

1. **HU1**: Usuario inicia conteo

   - Navega a `/inventario/conteo`

   - Sugiere tipo/horario automáticamente

   - Clic en "Iniciar"

   - Debe ver lista de items

2. **HU2**: Usuario registra valores

   - Ingresa valor real para cada item

   - Ve diferencia actualizarse en tiempo real

   - Sin guardar manual (autosave)

3. **HU3**: Usuario confirma conteo

   - Clic en "Confirmar"

   - Navega a pantalla de éxito

   - Conteo debe estar `completado`

4. **HU4**: Usuario ve historial

   - Navega a `/inventario/historial`

   - Ve lista de conteos pasados

   - Puede filtrar por tipo, estado, fecha

---

## Solución Recomendada

### Ejemplo: E2E Test para HU1

**e2e/inventario-initiate-count.e2e.ts**:

```typescript
import { test, expect } from '@playwright/test';

test.describe('HU1 - Iniciar Conteo', () => {
  test('should initiate a count with automatic suggestion', async ({ page }) => {
    // 1. Navegar a /inventario/conteo
    await page.goto('http://localhost:4200/inventario/conteo');

    // 2. Esperar que se cargue la sugerencia
    const tipoSelect = page.locator('select[name="tipo"]');
    await expect(tipoSelect).toHaveValue('diario');  // Sugiere diario

    const horarioSelect = page.locator('select[name="horario"]');
    await expect(horarioSelect).toHaveValue('apertura');  // Sugiere apertura

    // 3. Clic en "Iniciar Conteo"
    await page.locator('button:has-text("Iniciar Conteo")').click();

    // 4. Esperar a que se cargue lista de items
    await page.waitForSelector('app-list-card');
    const items = page.locator('app-list-card');
    await expect(items).not.toHaveCount(0);

    // 5. Verificar que está en step 2 (registro de valores)
    const pageHeader = page.locator('h1');
    await expect(pageHeader).toContainText('Registrar Valores');
  });

  test('should show error if no type selected', async ({ page }) => {
    await page.goto('http://localhost:4200/inventario/conteo');

    // Limpiar sugerencia
    const tipoSelect = page.locator('select[name="tipo"]');
    await tipoSelect.selectOption('');

    // Intentar iniciar sin tipo
    await page.locator('button:has-text("Iniciar Conteo")').click();

    // Debe mostrar error
    const errorMsg = page.locator('text=Tipo es requerido');
    await expect(errorMsg).toBeVisible();
  });
});

```text

### Step 1: Instalar Playwright

```bash
npm install --save-dev @playwright/test

```text

### Step 2: Crear Archivo de Configuración

**playwright.config.ts**:

```typescript
export default {
  webServer: {
    command: 'ng serve',
    port: 4200,
  },
  testDir: 'e2e',
  testMatch: '**/*.e2e.ts',
};

```text

### Step 3: Ejecutar Tests

```bash
npx playwright test

```text

---

## Archivos a Crear

- `e2e/inventario-initiate-count.e2e.ts`

- `e2e/inventario-register-values.e2e.ts`

- `e2e/inventario-confirm-count.e2e.ts`

- `e2e/inventario-view-history.e2e.ts`

- `e2e/support/inventario-page.ts` (Page Object Model)

---

## Verificación

Después de la corrección:

```bash
npm test:e2e
# Expected: 4+ tests pass

```text

---

## Impacto

- ❌ Spec requiere E2E tests, no cumplido

- ❌ Sin automatización, cambios pueden romper flujos críticos sin detectar

- ⚠️ Manual testing no es escalable

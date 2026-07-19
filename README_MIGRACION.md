# Migración de Datos: Loopi v1 → v2

## 📋 Descripción

Este conjunto de scripts SQL migra los datos de proveedores e items desde Loopi v1 a Loopi v2, creando automáticamente las categorías y subcategorías necesarias.

## 📁 Archivos Generados

| Archivo | Descripción |
|---------|-------------|
| `01_migration_proveedores.sql` | Insert de los 21 proveedores de v1 |
| `02_migration_categorias.sql` | Creación de 2 categorías y 16 subcategorías |
| `03_migration_items.sql` | Insert de los 131 items con sus relaciones |
| `migration_completa.sql` | Versión consolidada (todos los scripts en uno) |

## 🚀 Cómo Ejecutar

### Opción 1: Ejecutar scripts individuales (recomendado)

```bash
# En MySQL/MariaDB
mysql -u usuario -p nombre_bd < 01_migration_proveedores.sql
mysql -u usuario -p nombre_bd < 02_migration_categorias.sql
mysql -u usuario -p nombre_bd < 03_migration_items.sql
```

### Opción 2: Ejecutar script consolidado

```bash
mysql -u usuario -p nombre_bd < migration_completa.sql
```

## ⚠️ Notas Importantes

### Datos Dummy que Requieren Ajuste

1. **Códigos de Items**: Se generaron como `ITEM-174`, `ITEM-175`, etc.
   - ✏️ Modificar a través de la UX con códigos reales (ej: `CAF-001`, `INS-001`)
   - Estos códigos deben ser únicos y siguen las reglas: `^[A-Z0-9\-]+$`

2. **Contacto de Proveedores**: Se rellenaron campos vacíos con dummies
   - ✏️ Actualizar contactos reales a través de la UX
   - Campos afectados:
     - `nombre_contacto`: "Contacto Dummy N"
     - `telefono_contacto`: "0-N" (donde N es el ID del proveedor)
     - `email_contacto`: "<dummyN@supplier.com>"

3. **Stock de Seguridad**: Todos los items se insieren con `stock_seguridad = 0`
   - ✏️ Ajustar valores reales según política de cada item
   - Esto es especialmente importante para items críticos

4. **Categorías y Subcategorías**: Se crearon automáticamente
   - ✏️ Revisar el mapeo en la tabla de abajo
   - Pueden renombrarse o reorganizarse a través de la UX si es necesario

### Mapeo de Categorías (v1 → v2)

| v1 `category_id` | v2 Categoría | v2 Subcategoría |
|:---:|---|---|
| 1 | Consumibles y Equipamiento | Contenedores y Empaques |
| 2 | Productos | Cafés Grano |
| 3 | Productos | Cafés Procesados |
| 4 | Productos | Postres y Pasteles |
| 5 | Productos | Comida |
| 6 | Productos | Bebidas de Frutas |
| 7 | Productos | Lácteos |
| 8 | Productos | Chocolates |
| 10 | Productos | Infusiones y Aromáticas |
| 11 | Productos | Bebidas Gaseosas |
| 12 | Productos | Endulzantes |
| 13 | Productos | Ingredientes |
| 14 | Productos | Merchandise |
| 15 | Productos | Bebidas Gaseosas |
| 16 | Productos | Tés |
| 17 | Productos | Lácteos |
| 18 | Productos | Ingredientes |
| 20 | Consumibles y Equipamiento | Limpieza y Aseo |
| 21 | Consumibles y Equipamiento | Equipamiento |

### Mapeo de Tipos de Items

| v1 `type` | v2 `tipo` |
|---|---|
| `supply` | `insumo` |
| `product` | `material_consumo` |

### Mapeo de Frecuencias

| v1 `inventory_frequency` | v2 `frecuencia_inventario` |
|---|---|
| `daily` | `diario` |
| `weekly` | `semanal` |
| `monthly` | `mensual` |

### Mapeo de Unidades de Medida

| v1 `measurement_unit_id` | v2 `unidad_medida_id` | Valor |
|:---:|:---:|---|
| 1 | 3 | Unidad (und) |
| 2 | 1 | Gramo (g) |

**Nota**: Si hay otros valores de `measurement_unit_id` en tu v1, consulta la tabla `unidades_medida` de v2 para el mapeo completo.

## 🔍 Campos Auditados

### Campos Requeridos (NOT NULL) que se rellenaron con Dummies

- **proveedores.nombre_contacto**: "Contacto Dummy N"
- **proveedores.telefono_contacto**: "0-N"
- **items.codigo**: "ITEM-N"
- **items.stock_seguridad**: 0
- **items.creado_por**: 1 (usuario admin)
- **items.actualizado_por**: 1 (usuario admin)

### Campos que Usan los Valores Originales

- **proveedores.razon_social**: del v1 `business_name`
- **proveedores.nit**: del v1 `tax_id` (o "DUMMY-N" si estaba vacío)
- **proveedores.email_contacto**: del v1 `contact_email`
- **proveedores.activo**: del v1 `active`
- **items.nombre**: del v1 `name`
- **items.tipo**: mapeado de v1 `type`
- **items.frecuencia_inventario**: mapeado de v1 `inventory_frequency`
- **items.costo_unitario**: del v1 `cost` (NULL si era 0)
- **items.proveedor_id**: del v1 `supplier_id` (NULL si no había)
- **items.unidad_medida_id**: mapeado de v1 `measurement_unit_id`

## 🔗 Dependencias

Los scripts se ejecutan en este orden para respetar las constraints:

1. **Proveedores** (sin dependencias)
2. **Categorías** → requiere tabla `empleados` con al menos id=1
3. **Subcategorías** → requiere tabla `categorias`
4. **Items** → requiere tablas `proveedores`, `subcategorias`, `unidades_medida`, `empleados`

**Prerequisito**: La tabla `empleados` debe tener al menos un registro con `id=1` (usuario admin).

## ✅ Validación Post-Migración

Ejecuta estas queries para verificar:

```sql
-- Contar proveedores
SELECT COUNT(*) as total_proveedores FROM proveedores;
-- Esperado: 21

-- Contar categorías
SELECT COUNT(*) as total_categorias FROM categorias;
-- Esperado: 2

-- Contar subcategorías
SELECT COUNT(*) as total_subcategorias FROM subcategorias;
-- Esperado: 16

-- Contar items
SELECT COUNT(*) as total_items FROM items;
-- Esperado: 131

-- Verificar integridad referencial
SELECT COUNT(*) as items_sin_proveedor FROM items WHERE proveedor_id IS NULL;
-- Items sin proveedor asignado (esto es normal)

-- Verificar items con costo_unitario NULL
SELECT COUNT(*) as items_sin_costo FROM items WHERE costo_unitario IS NULL;
-- Items sin costo definido (esto es normal, rellenar luego)
```

## 🛠️ Checklist Post-Migración

- [ ] Ejecutar scripts SQL
- [ ] Verificar conteos con queries de validación
- [ ] Revisar códigos de items y reemplazarlos con valores reales
- [ ] Actualizar datos de contacto de proveedores
- [ ] Definir `stock_seguridad` para items críticos
- [ ] Revisar y ajustar categorías si es necesario
- [ ] Probar que los items aparezcan correctamente en la UX
- [ ] Verificar relaciones proveedor-item en la UX

## 📞 Soporte

Si hay errores de constraint o referencia, verifica:

1. ¿Existe la tabla `empleados` con id=1?
2. ¿Existen las tablas `unidades_medida` con ids 1 y 3?
3. ¿Hay duplicados de código en la tabla `items`?
4. ¿Hay duplicados de NIT en la tabla `proveedores`?

Consulta los logs del servidor MySQL para más detalles.

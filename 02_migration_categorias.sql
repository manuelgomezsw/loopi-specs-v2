-- ========================================================
-- MIGRACIÓN CATEGORÍAS Y SUBCATEGORÍAS
-- ========================================================

-- CATEGORÍAS PRINCIPALES
INSERT INTO categorias (nombre, activo, creado_por, creado_en, actualizado_por, actualizado_en)
VALUES
  ('Consumibles y Equipamiento', 1, 1, NOW(), 1, NOW()),
  ('Productos', 1, 1, NOW(), 1, NOW());

-- SUBCATEGORÍAS - Consumibles y Equipamiento (categoria_id = 1)
INSERT INTO subcategorias (nombre, categoria_id, activo, creado_por, creado_en, actualizado_por, actualizado_en)
VALUES
  ('Contenedores y Empaques', 1, 1, 1, NOW(), 1, NOW()),
  ('Equipamiento', 1, 1, 1, NOW(), 1, NOW()),
  ('Limpieza y Aseo', 1, 1, 1, NOW(), 1, NOW());

-- SUBCATEGORÍAS - Productos (categoria_id = 2)
INSERT INTO subcategorias (nombre, categoria_id, activo, creado_por, creado_en, actualizado_por, actualizado_en)
VALUES
  ('Bebidas Gaseosas', 2, 1, 1, NOW(), 1, NOW()),
  ('Bebidas de Frutas', 2, 1, 1, NOW(), 1, NOW()),
  ('Cafés Grano', 2, 1, 1, NOW(), 1, NOW()),
  ('Cafés Procesados', 2, 1, 1, NOW(), 1, NOW()),
  ('Chocolates', 2, 1, 1, NOW(), 1, NOW()),
  ('Comida', 2, 1, 1, NOW(), 1, NOW()),
  ('Endulzantes', 2, 1, 1, NOW(), 1, NOW()),
  ('Infusiones y Aromáticas', 2, 1, 1, NOW(), 1, NOW()),
  ('Ingredientes', 2, 1, 1, NOW(), 1, NOW()),
  ('Lácteos', 2, 1, 1, NOW(), 1, NOW()),
  ('Merchandise', 2, 1, 1, NOW(), 1, NOW()),
  ('Postres y Pasteles', 2, 1, 1, NOW(), 1, NOW()),
  ('Tés', 2, 1, 1, NOW(), 1, NOW());

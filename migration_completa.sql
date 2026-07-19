-- ========================================================
-- MIGRACIÓN COMPLETA: LOOPI V1 → V2
-- ========================================================
-- Fecha: 2026-07-13
-- Contiene: Proveedores, Categorías, Subcategorías, Items
-- Nota: Ejecutar en orden: Proveedores → Categorías → Subcategorías → Items
-- ========================================================

-- ========================================================
-- 1. PROVEEDORES
-- ========================================================

INSERT INTO proveedores (id, razon_social, nit, nombre_contacto, telefono_contacto, email_contacto, activo, creado_en, actualizado_en)
VALUES
  (1, 'Urbania Café', '1111', 'Contacto Dummy 1', '0-1', 'dummy1@supplier.com', 1, '2026-02-07 01:15:06', '2026-02-07 01:15:06'),
  (2, 'Urbania Tiendas', '222', 'Contacto Dummy 2', '0-2', 'dummy2@supplier.com', 1, '2026-02-07 01:15:39', '2026-02-07 01:15:39'),
  (3, 'Tres Trigos', '333', 'Contacto Dummy 3', '0-3', 'dummy3@supplier.com', 1, '2026-02-07 01:15:56', '2026-02-07 01:15:56'),
  (4, 'Malvinas', '444', 'Contacto Dummy 4', '0-4', 'dummy4@supplier.com', 1, '2026-02-07 01:16:12', '2026-02-07 01:16:12'),
  (5, 'Postobón', '555', 'Contacto Dummy 5', '0-5', 'dummy5@supplier.com', 1, '2026-02-07 01:16:19', '2026-02-07 01:16:19'),
  (6, 'D1', '666', 'Contacto Dummy 6', '0-6', 'dummy6@supplier.com', 1, '2026-02-07 01:16:27', '2026-02-07 01:16:27'),
  (7, 'Rosmi (Leches Vegetales)', '777', 'Contacto Dummy 7', '0-7', 'dummy7@supplier.com', 1, '2026-02-07 01:16:44', '2026-02-07 01:16:44'),
  (8, 'Alquería', '888', 'Contacto Dummy 8', '0-8', 'dummy8@supplier.com', 1, '2026-02-07 01:16:53', '2026-02-07 01:31:19'),
  (9, 'Cletto', '000', 'Contacto Dummy 9', '0-9', 'dummy9@supplier.com', 1, '2026-02-07 01:17:01', '2026-02-07 01:17:01'),
  (10, 'La Fresita', '1222', 'Contacto Dummy 10', '0-10', 'dummy10@supplier.com', 1, '2026-02-07 01:17:15', '2026-02-07 01:17:15'),
  (11, 'Wayu', '1333', 'Contacto Dummy 11', '0-11', 'dummy11@supplier.com', 1, '2026-02-07 01:17:23', '2026-02-07 01:17:23'),
  (12, 'Verderina', '1555', 'Contacto Dummy 12', '0-12', 'dummy12@supplier.com', 1, '2026-02-07 01:17:32', '2026-02-07 01:17:32'),
  (13, 'Generaser (Chai)', '1444', 'Contacto Dummy 13', '0-13', 'dummy13@supplier.com', 1, '2026-02-07 01:17:47', '2026-02-07 01:17:47'),
  (14, 'Samaná', '1666', 'Contacto Dummy 14', '0-14', 'dummy14@supplier.com', 1, '2026-02-07 01:18:00', '2026-02-07 01:18:00'),
  (15, 'Bebidas Inéditas', '1777', 'Contacto Dummy 15', '0-15', 'dummy15@supplier.com', 1, '2026-02-07 01:18:12', '2026-02-07 01:18:12'),
  (16, 'Tea Worl', '1888', 'Contacto Dummy 16', '0-16', 'dummy16@supplier.com', 1, '2026-02-07 01:18:23', '2026-02-07 01:18:23'),
  (17, 'Lacteos Buenos Aires', '1000', 'Contacto Dummy 17', '0-17', 'dummy17@supplier.com', 1, '2026-02-07 01:18:34', '2026-02-07 01:18:34'),
  (18, 'Mayorista', '2111', 'Contacto Dummy 18', '0-18', 'dummy18@supplier.com', 1, '2026-02-07 01:18:49', '2026-02-07 01:18:49'),
  (19, 'Terrapreta', '2222', 'Contacto Dummy 19', '0-19', 'dummy19@supplier.com', 1, '2026-02-07 01:18:58', '2026-02-07 01:18:58'),
  (20, 'Best Cleaning', '2444', 'Contacto Dummy 20', '0-20', 'dummy20@supplier.com', 1, '2026-02-07 01:19:14', '2026-02-07 01:19:14'),
  (21, 'Otros', '2555', 'Contacto Dummy 21', '0-21', 'dummy21@supplier.com', 1, '2026-02-07 01:19:34', '2026-02-07 01:19:34');

-- ========================================================
-- 2. CATEGORÍAS
-- ========================================================

INSERT INTO categorias (nombre, activo, creado_por, creado_en, actualizado_por, actualizado_en)
VALUES
  ('Consumibles y Equipamiento', 1, 1, NOW(), 1, NOW()),
  ('Productos', 1, 1, NOW(), 1, NOW());

-- ========================================================
-- 3. SUBCATEGORÍAS
-- ========================================================

-- Subcategorías: Consumibles y Equipamiento (categoria_id = 1)
INSERT INTO subcategorias (nombre, categoria_id, activo, creado_por, creado_en, actualizado_por, actualizado_en)
VALUES
  ('Contenedores y Empaques', 1, 1, 1, NOW(), 1, NOW()),
  ('Equipamiento', 1, 1, 1, NOW(), 1, NOW()),
  ('Limpieza y Aseo', 1, 1, 1, NOW(), 1, NOW());

-- Subcategorías: Productos (categoria_id = 2)
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

-- ========================================================
-- 4. ITEMS
-- ========================================================

INSERT INTO items (codigo, nombre, tipo, subcategoria_id, proveedor_id, unidad_medida_id, costo_unitario, frecuencia_inventario, stock_seguridad, activo, creado_por, creado_en, actualizado_por, actualizado_en)
VALUES
  ('ITEM-174', 'Vaso 9oz x 50 Genérico', 'insumo', 1, NULL, 3, NULL, 'semanal', 0, 1, 1, '2026-02-06 00:16:55', 1, '2026-02-17 17:24:46'),
  ('ITEM-175', 'Vaso 12oz x 50 Genérico', 'insumo', 1, NULL, 3, NULL, 'semanal', 0, 1, 1, '2026-02-06 00:16:55', 1, '2026-02-17 17:24:46'),
  ('ITEM-176', 'Vaso 16oz Genérico', 'insumo', 1, NULL, 3, NULL, 'semanal', 0, 1, 1, '2026-02-06 00:16:55', 1, '2026-02-17 17:24:46'),
  ('ITEM-177', 'Vaso 4oz x50 Verde (Urbania)', 'insumo', 1, NULL, 3, NULL, 'semanal', 0, 1, 1, '2026-02-06 00:16:55', 1, '2026-02-17 17:24:46'),
  ('ITEM-178', 'Vaso 7oz x50 Verde (Urbania)', 'insumo', 1, NULL, 3, NULL, 'semanal', 0, 1, 1, '2026-02-06 00:16:55', 1, '2026-02-17 17:24:46'),
  ('ITEM-179', 'Vaso 9oz x25 Rosado (Urbania)', 'insumo', 1, NULL, 3, NULL, 'semanal', 0, 1, 1, '2026-02-06 00:16:55', 1, '2026-02-17 17:24:46'),
  ('ITEM-180', 'Vaso 16oz (Transparente) x50', 'insumo', 1, NULL, 3, NULL, 'semanal', 0, 1, 1, '2026-02-06 00:16:55', 1, '2026-02-17 17:24:46'),
  ('ITEM-181', 'Tapa Viajera 9 Onzas Urbania x und', 'insumo', 1, NULL, 3, NULL, 'semanal', 0, 1, 1, '2026-02-06 00:16:55', 1, '2026-02-17 17:24:46'),
  ('ITEM-182', 'Tapa Viajera 7 Onzas Urbania x und', 'insumo', 1, NULL, 3, NULL, 'semanal', 0, 1, 1, '2026-02-06 00:16:55', 1, '2026-02-17 17:24:46'),
  ('ITEM-183', 'Tapa 16oz', 'insumo', 1, NULL, 3, NULL, 'semanal', 0, 1, 1, '2026-02-06 00:16:55', 1, '2026-02-17 17:24:46'),
  ('ITEM-184', 'Tapa 7oz x 50 Blancas', 'insumo', 1, NULL, 3, NULL, 'semanal', 0, 1, 1, '2026-02-06 00:16:55', 1, '2026-02-17 17:24:46'),
  ('ITEM-185', 'Tapa 9oz x 50 Blancas (Urbania)', 'insumo', 1, NULL, 3, NULL, 'semanal', 0, 1, 1, '2026-02-06 00:16:55', 1, '2026-02-17 17:24:46'),
  ('ITEM-186', 'Servilletas', 'insumo', 1, 2, 3, NULL, 'semanal', 0, 1, 1, '2026-02-06 00:16:55', 1, '2026-02-17 17:24:46'),
  ('ITEM-187', 'Pitillos x200 Genérico', 'insumo', 1, 21, 3, NULL, 'semanal', 0, 1, 1, '2026-02-06 00:16:55', 1, '2026-02-17 17:24:46'),
  ('ITEM-188', 'Mezcladores', 'insumo', 1, 2, 3, NULL, 'mensual', 0, 1, 1, '2026-02-06 00:16:55', 1, '2026-02-17 17:24:46'),
  ('ITEM-189', 'Porta comida pequeño', 'insumo', 1, 21, 3, NULL, 'mensual', 0, 1, 1, '2026-02-06 00:16:55', 1, '2026-02-17 17:24:46'),
  ('ITEM-190', 'Mallas para el cabello', 'insumo', 3, 2, 3, NULL, 'mensual', 0, 1, 1, '2026-02-06 00:16:55', 1, '2026-02-17 17:24:46'),
  ('ITEM-191', 'Bolsas de papel Urbania', 'insumo', 1, 2, 3, NULL, 'semanal', 0, 1, 1, '2026-02-06 00:16:55', 1, '2026-02-17 17:24:46'),
  ('ITEM-192', 'Bolsas papel #1 (para llevar)', 'insumo', 1, NULL, 3, NULL, 'mensual', 0, 1, 1, '2026-02-06 00:16:55', 1, '2026-02-17 17:24:46'),
  ('ITEM-193', 'Bolsas papel #3 (para llevar) x 100', 'insumo', 1, NULL, 3, NULL, 'mensual', 0, 1, 1, '2026-02-06 00:16:55', 1, '2026-02-17 17:24:46'),
  ('ITEM-194', 'Bolsas Basura', 'insumo', 3, 2, 3, NULL, 'semanal', 0, 1, 1, '2026-02-06 00:16:55', 1, '2026-02-17 17:24:46'),
  ('ITEM-195', 'Jabón platos', 'insumo', 3, 20, 3, NULL, 'mensual', 0, 1, 1, '2026-02-06 00:16:55', 1, '2026-02-17 17:24:46'),
  ('ITEM-196', 'Portavasos (bandeja para llevar)', 'insumo', 1, 21, 3, NULL, 'mensual', 0, 1, 1, '2026-02-06 00:16:55', 1, '2026-02-17 17:24:46'),
  ('ITEM-197', 'Cucharas x 50', 'insumo', 1, NULL, 3, NULL, 'mensual', 0, 1, 1, '2026-02-06 00:16:55', 1, '2026-02-17 17:24:46'),
  ('ITEM-198', 'Aisladores (Urbania) x 50', 'insumo', 1, NULL, 3, NULL, 'mensual', 0, 1, 1, '2026-02-06 00:16:55', 1, '2026-02-17 17:24:46'),
  ('ITEM-199', 'Porta comida grande (para llevar)', 'insumo', 1, 21, 3, NULL, 'mensual', 0, 1, 1, '2026-02-06 00:16:55', 1, '2026-02-17 17:24:46'),
  ('ITEM-200', 'Porta comida pequeño (para llevar) x 20', 'insumo', 1, 21, 3, NULL, 'mensual', 0, 1, 1, '2026-02-06 00:16:55', 1, '2026-02-17 17:24:46'),
  ('ITEM-201', 'Bandeja pequeña (blanca) x20', 'insumo', 1, NULL, 3, NULL, 'mensual', 0, 0, 1, '2026-02-06 00:16:55', 1, '2026-02-17 17:24:46'),
  ('ITEM-202', 'Bandeja grande (blanca) x 20', 'insumo', 1, NULL, 3, NULL, 'mensual', 0, 0, 1, '2026-02-06 00:16:55', 1, '2026-02-17 17:24:46'),
  ('ITEM-203', 'Filtros Bunn x 500UN', 'insumo', 1, NULL, 3, NULL, 'mensual', 0, 1, 1, '2026-02-06 00:16:55', 1, '2026-02-17 17:24:46'),
  ('ITEM-204', 'Cajas KIT', 'insumo', 1, NULL, 3, NULL, 'mensual', 0, 1, 1, '2026-02-06 00:16:55', 1, '2026-02-17 17:24:46'),
  ('ITEM-205', 'Filtros V60', 'insumo', 1, NULL, 3, NULL, 'mensual', 0, 1, 1, '2026-02-06 00:16:55', 1, '2026-02-17 17:24:46'),
  ('ITEM-206', 'Filtros Aeropress', 'insumo', 1, NULL, 3, NULL, 'mensual', 0, 1, 1, '2026-02-06 00:16:55', 1, '2026-02-17 17:24:46'),
  ('ITEM-207', 'Filtros Chemex', 'insumo', 1, NULL, 3, NULL, 'mensual', 0, 1, 1, '2026-02-06 00:16:55', 1, '2026-02-17 17:24:46'),
  ('ITEM-208', 'Cafe Paz x 250gr', 'material_consumo', 6, 1, 1, NULL, 'diario', 0, 1, 1, '2026-02-06 00:19:24', 1, '2026-02-17 17:24:46'),
  ('ITEM-209', 'Cafe Jaguares x250gr', 'material_consumo', 6, 1, 1, NULL, 'diario', 0, 0, 1, '2026-02-06 00:19:24', 1, '2026-06-02 16:10:39'),
  ('ITEM-210', 'Cafe Organico x250gr', 'material_consumo', 6, 1, 1, NULL, 'diario', 0, 0, 1, '2026-02-06 00:19:24', 1, '2026-02-22 10:22:34'),
  ('ITEM-211', 'Café Typica x250g', 'material_consumo', 6, 1, 1, NULL, 'diario', 0, 0, 1, '2026-02-06 00:19:24', 1, '2026-06-02 16:10:45'),
  ('ITEM-212', 'Cafe Gesha x250gr', 'material_consumo', 6, 2, 1, NULL, 'diario', 0, 0, 1, '2026-02-06 00:19:24', 1, '2026-02-22 10:22:18'),
  ('ITEM-213', 'Cafe Oso x250gr', 'material_consumo', 6, 1, 1, NULL, 'diario', 0, 0, 1, '2026-02-06 00:19:24', 1, '2026-02-22 10:22:57'),
  ('ITEM-214', 'Cafe Descafeinado x250gr', 'material_consumo', 6, 1, 1, NULL, 'diario', 0, 1, 1, '2026-02-06 00:19:24', 1, '2026-02-22 10:22:11'),
  ('ITEM-215', 'Café Pacamara x250g', 'material_consumo', 6, 1, 1, NULL, 'diario', 0, 0, 1, '2026-02-06 00:19:24', 1, '2026-02-17 17:24:46'),
  ('ITEM-216', 'Paz Filtrado x gr x 1500gr (Caneca)', 'material_consumo', 7, 1, 2, NULL, 'semanal', 0, 1, 1, '2026-02-06 00:19:24', 1, '2026-02-17 14:40:00'),
  ('ITEM-217', 'Filtrado Espresso x 9000gr (Caneca)', 'material_consumo', 7, 1, 2, NULL, 'semanal', 0, 1, 1, '2026-02-06 00:19:24', 1, '2026-02-17 14:39:49'),
  ('ITEM-218', 'CF-SPO gr CAFÉ ORGANICO SABANALARGA x gr x 1500gr', 'material_consumo', 7, NULL, 2, NULL, 'semanal', 0, 0, 1, '2026-02-06 00:19:24', 1, '2026-02-17 14:39:10'),
  ('ITEM-219', 'Torta De Zanahoria y Naranja', 'material_consumo', 15, 2, 3, NULL, 'diario', 0, 1, 1, '2026-02-06 00:19:24', 1, '2026-02-17 17:24:46'),
  ('ITEM-220', 'Torta Chocolate Porcion', 'material_consumo', 15, 2, 3, NULL, 'diario', 0, 1, 1, '2026-02-06 00:19:24', 1, '2026-02-17 17:24:46'),
  ('ITEM-221', 'Torta Amapola', 'material_consumo', 15, 2, 3, NULL, 'diario', 0, 0, 1, '2026-02-06 00:19:24', 1, '2026-02-17 17:24:46'),
  ('ITEM-222', 'Torta Red Velvet', 'material_consumo', 15, 2, 3, NULL, 'diario', 0, 0, 1, '2026-02-06 00:19:24', 1, '2026-02-17 17:24:46'),
  ('ITEM-223', 'Almojabana', 'material_consumo', 9, NULL, 3, NULL, 'diario', 0, 1, 1, '2026-02-06 00:19:24', 1, '2026-02-17 17:24:46'),
  ('ITEM-224', 'Galleta Red Velvet', 'material_consumo', 15, 2, 3, NULL, 'diario', 0, 1, 1, '2026-02-06 00:19:24', 1, '2026-02-17 17:24:46'),
  ('ITEM-225', 'Galleta Chips Chocolate', 'material_consumo', 15, 2, 3, NULL, 'diario', 0, 1, 1, '2026-02-06 00:19:24', 1, '2026-02-17 17:24:46'),
  ('ITEM-226', 'Brownie De Chocolate y Nueces', 'material_consumo', 15, 2, 3, NULL, 'diario', 0, 1, 1, '2026-02-06 00:19:24', 1, '2026-02-17 17:24:46'),
  ('ITEM-227', 'Palito Queso x 5', 'material_consumo', 9, 3, 3, NULL, 'diario', 0, 1, 1, '2026-02-06 00:19:24', 1, '2026-02-17 17:24:46'),
  ('ITEM-228', 'Croissant 3 Quesos x 6', 'material_consumo', 9, 3, 3, NULL, 'diario', 0, 1, 1, '2026-02-06 00:19:24', 1, '2026-02-17 17:24:46'),
  ('ITEM-229', 'Croissant Jamon y Queso x 6', 'material_consumo', 9, 3, 3, NULL, 'diario', 0, 1, 1, '2026-02-06 00:19:24', 1, '2026-02-17 17:24:46'),
  ('ITEM-230', 'Croissant De Mantequilla x 6', 'material_consumo', 9, 3, 3, NULL, 'diario', 0, 1, 1, '2026-02-06 00:19:24', 1, '2026-02-17 17:24:46'),
  ('ITEM-231', 'Empanada Argentina Carne x5', 'material_consumo', 9, 4, 3, NULL, 'diario', 0, 1, 1, '2026-02-06 00:19:24', 1, '2026-02-17 17:24:46'),
  ('ITEM-232', 'Empanada Argentina Pollo x5', 'material_consumo', 9, 4, 3, NULL, 'diario', 0, 1, 1, '2026-02-06 00:19:24', 1, '2026-02-17 17:24:46'),
  ('ITEM-233', 'Empanada Argentina Caprese x5', 'material_consumo', 9, 4, 3, NULL, 'diario', 0, 1, 1, '2026-02-06 00:19:24', 1, '2026-02-17 17:24:46'),
  ('ITEM-234', 'Jugo de Naranja', 'material_consumo', 5, NULL, 3, NULL, 'semanal', 0, 0, 1, '2026-02-06 00:19:24', 1, '2026-02-17 17:24:46'),
  ('ITEM-235', 'Pulpa Jugo Amarillo', 'material_consumo', 5, 2, 3, NULL, 'semanal', 0, 1, 1, '2026-02-06 00:19:24', 1, '2026-02-17 17:24:46'),
  ('ITEM-236', 'Pulpa Smoothie Verde', 'material_consumo', 5, 2, 3, NULL, 'semanal', 0, 1, 1, '2026-02-06 00:19:24', 1, '2026-02-17 17:24:46'),
  ('ITEM-237', 'Pulpa Smoothie Rojo', 'material_consumo', 5, 2, 3, NULL, 'semanal', 0, 1, 1, '2026-02-06 00:19:24', 1, '2026-02-17 17:24:46'),
  ('ITEM-238', 'Gorra Urbania Café', 'material_consumo', 14, 2, 3, NULL, 'mensual', 0, 0, 1, '2026-02-06 00:19:24', 1, '2026-02-17 17:24:46'),
  ('ITEM-239', 'Gorra Urbania Verde', 'material_consumo', 14, 2, 3, NULL, 'mensual', 0, 0, 1, '2026-02-06 00:19:24', 1, '2026-02-17 17:24:46'),
  ('ITEM-240', 'Mug Urbania', 'material_consumo', 14, 2, 3, NULL, 'mensual', 0, 1, 1, '2026-02-06 00:19:24', 1, '2026-02-17 17:24:46'),
  ('ITEM-241', 'Prensa Francesa Bambu 350', 'material_consumo', 14, 2, 3, NULL, 'mensual', 0, 1, 1, '2026-02-06 00:19:24', 1, '2026-02-17 17:24:46'),
  ('ITEM-242', 'Prensa Francesa Bambu 600', 'material_consumo', 14, 2, 3, NULL, 'mensual', 0, 1, 1, '2026-02-06 00:19:24', 1, '2026-02-17 17:24:46'),
  ('ITEM-243', 'Leche de Almendras x6', 'material_consumo', 13, 7, 3, NULL, 'mensual', 0, 1, 1, '2026-02-06 00:19:24', 1, '2026-02-17 17:24:46'),
  ('ITEM-244', 'Leche de Avena x6', 'material_consumo', 13, 7, 3, NULL, 'mensual', 0, 1, 1, '2026-02-06 00:19:24', 1, '2026-02-17 17:24:46'),
  ('ITEM-245', 'Leche Entera (bolsas)', 'material_consumo', 13, 8, 3, NULL, 'semanal', 0, 1, 1, '2026-02-06 00:19:24', 1, '2026-02-17 17:24:46'),
  ('ITEM-246', 'Leche Deslactosada (bolsa)', 'insumo', 13, 8, 3, NULL, 'diario', 0, 1, 1, '2026-02-06 00:19:24', 1, '2026-07-09 08:45:49'),
  ('ITEM-247', 'Almond Rock', 'material_consumo', 8, 9, 3, NULL, 'mensual', 0, 1, 1, '2026-02-06 00:19:24', 1, '2026-02-17 17:24:46'),
  ('ITEM-248', 'Tableta 99%', 'material_consumo', 8, 9, 3, NULL, 'mensual', 0, 1, 1, '2026-02-06 00:19:24', 1, '2026-02-17 17:24:46'),
  ('ITEM-249', 'Tableta Mini', 'material_consumo', 8, 9, 3, NULL, 'mensual', 0, 1, 1, '2026-02-06 00:19:24', 1, '2026-02-17 17:24:46'),
  ('ITEM-250', 'Tableta de origen varios porcentajes', 'material_consumo', 8, 9, 3, NULL, 'mensual', 0, 1, 1, '2026-02-06 00:19:24', 1, '2026-02-17 17:24:46'),
  ('ITEM-251', 'Tableta saborizadas', 'material_consumo', 8, 9, 3, NULL, 'mensual', 0, 1, 1, '2026-02-06 00:19:24', 1, '2026-02-17 17:24:46'),
  ('ITEM-252', 'Tableta De Chocolate Rellena De Miel', 'material_consumo', 8, 9, 3, NULL, 'mensual', 0, 1, 1, '2026-02-06 00:19:24', 1, '2026-02-17 17:24:46'),
  ('ITEM-253', 'Chocolate en Polvo (Lujo)', 'material_consumo', 8, 9, 3, NULL, 'mensual', 0, 1, 1, '2026-02-06 00:19:24', 1, '2026-02-17 17:24:46'),
  ('ITEM-254', 'Chocolate en polvo preparaciones', 'material_consumo', 12, 9, 3, NULL, 'mensual', 0, 1, 1, '2026-02-06 00:19:24', 1, '2026-02-17 17:24:46'),
  ('ITEM-255', 'Helado x 5 litros', 'material_consumo', 12, 10, 3, NULL, 'semanal', 0, 1, 1, '2026-02-06 00:19:24', 1, '2026-02-17 17:24:46'),
  ('ITEM-256', 'Infusión Frutos Rojos Wayu', 'insumo', 11, 11, 3, NULL, 'diario', 0, 1, 1, '2026-02-06 00:19:24', 1, '2026-07-04 20:22:54'),
  ('ITEM-257', 'Infusión Frutos Amarillos Wayu', 'insumo', 11, 11, 3, NULL, 'diario', 0, 1, 1, '2026-02-06 00:19:24', 1, '2026-07-04 20:22:43'),
  ('ITEM-258', 'Aromática Alma Verde', 'insumo', 11, 12, 3, NULL, 'diario', 0, 1, 1, '2026-02-06 00:19:24', 1, '2026-07-04 20:21:34'),
  ('ITEM-259', 'Aromática Jardín Mágico Morada', 'insumo', 11, 12, 3, NULL, 'diario', 0, 1, 1, '2026-02-06 00:19:24', 1, '2026-07-04 20:22:16'),
  ('ITEM-260', 'Aromática Danza Frutal Amarillo', 'insumo', 11, 12, 3, NULL, 'diario', 0, 1, 1, '2026-02-06 00:19:24', 1, '2026-07-04 20:22:02'),
  ('ITEM-261', 'Aromática Bosque Sagrado Rojo', 'insumo', 11, 12, 3, NULL, 'diario', 0, 1, 1, '2026-02-06 00:19:24', 1, '2026-07-04 20:21:50'),
  ('ITEM-262', 'Chai 500g', 'material_consumo', 11, 13, 1, NULL, 'mensual', 0, 1, 1, '2026-02-06 00:19:24', 1, '2026-02-17 17:24:46'),
  ('ITEM-263', 'Vanilla Chai (frasco)', 'material_consumo', 11, 13, 3, NULL, 'mensual', 0, 1, 1, '2026-02-06 00:19:24', 1, '2026-02-17 17:24:46'),
  ('ITEM-264', 'Miel 250g', 'material_consumo', 10, 14, 1, NULL, 'mensual', 0, 1, 1, '2026-02-06 00:19:24', 1, '2026-02-17 17:24:46'),
  ('ITEM-265', 'Miel 150g', 'material_consumo', 10, 14, 1, NULL, 'mensual', 0, 1, 1, '2026-02-06 00:19:24', 1, '2026-02-17 17:24:46'),
  ('ITEM-266', 'Soda Cascara con jenjibre', 'material_consumo', 4, 15, 3, NULL, 'mensual', 0, 1, 1, '2026-02-06 00:19:24', 1, '2026-02-17 17:24:46'),
  ('ITEM-267', 'Soda Cascara sin azucar', 'material_consumo', 4, 15, 3, NULL, 'mensual', 0, 1, 1, '2026-02-06 00:19:24', 1, '2026-02-17 17:24:46'),
  ('ITEM-268', 'Soda Cascara con azúcar', 'material_consumo', 4, 15, 3, NULL, 'mensual', 0, 1, 1, '2026-02-06 00:19:24', 1, '2026-02-17 17:24:46'),
  ('ITEM-269', 'Tea negro Tropical x80g (Tarrito)', 'material_consumo', 16, 16, 1, NULL, 'mensual', 0, 1, 1, '2026-02-06 00:19:24', 1, '2026-02-17 17:24:46'),
  ('ITEM-270', 'Tea Verde Mangostino x80g', 'material_consumo', 16, 16, 1, NULL, 'mensual', 0, 1, 1, '2026-02-06 00:19:24', 1, '2026-02-17 17:24:46'),
  ('ITEM-271', 'Tea Jengibre rojo 80g', 'material_consumo', 16, 16, 1, NULL, 'mensual', 0, 1, 1, '2026-02-06 00:19:24', 1, '2026-02-17 17:24:46'),
  ('ITEM-272', 'Tea Negro Frambuesa x80g', 'material_consumo', 16, 16, 1, NULL, 'mensual', 0, 1, 1, '2026-02-06 00:19:24', 1, '2026-02-17 17:24:46'),
  ('ITEM-273', 'Tea Verde Matcha x80g', 'material_consumo', 16, 16, 1, NULL, 'mensual', 0, 1, 1, '2026-02-06 00:19:24', 1, '2026-02-17 17:24:46'),
  ('ITEM-274', 'Leche en polvo 900g', 'material_consumo', 13, 17, 1, NULL, 'mensual', 0, 1, 1, '2026-02-06 00:19:24', 1, '2026-02-17 17:24:46'),
  ('ITEM-275', 'Leche condesada 800g', 'material_consumo', 13, 17, 1, NULL, 'mensual', 0, 1, 1, '2026-02-06 00:19:24', 1, '2026-02-17 17:24:46'),
  ('ITEM-276', 'Arequipe 1000g', 'material_consumo', 12, 17, 3, NULL, 'mensual', 0, 1, 1, '2026-02-06 00:19:24', 1, '2026-02-17 17:24:46'),
  ('ITEM-277', 'Cocoa', 'material_consumo', 12, 18, 3, NULL, 'mensual', 0, 1, 1, '2026-02-06 00:19:24', 1, '2026-02-17 17:24:46'),
  ('ITEM-278', 'Chantilly', 'material_consumo', 12, 18, 3, NULL, 'mensual', 0, 1, 1, '2026-02-06 00:19:24', 1, '2026-02-17 17:24:46'),
  ('ITEM-280', 'Panela x 200 sobres', 'material_consumo', 10, 19, 3, NULL, 'mensual', 0, 1, 1, '2026-02-06 00:19:24', 1, '2026-02-17 17:24:46'),
  ('ITEM-281', 'Azúcar x2500', 'material_consumo', 12, 18, 1, NULL, 'mensual', 0, 1, 1, '2026-02-06 00:19:24', 1, '2026-02-17 17:24:46'),
  ('ITEM-282', 'Almidon Yuca x1000', 'material_consumo', 12, NULL, 1, NULL, 'mensual', 0, 1, 1, '2026-02-06 00:19:24', 1, '2026-02-17 17:24:46'),
  ('ITEM-283', 'Panela x500gr', 'material_consumo', 12, 19, 1, NULL, 'mensual', 0, 1, 1, '2026-02-06 00:19:24', 1, '2026-02-17 17:24:46'),
  ('ITEM-284', 'Milo x2500', 'material_consumo', 12, 21, 1, NULL, 'mensual', 0, 1, 1, '2026-02-06 00:19:24', 1, '2026-02-17 17:24:46'),
  ('ITEM-285', 'Azúcar Pulverizada x1000', 'material_consumo', 12, 18, 1, NULL, 'mensual', 0, 1, 1, '2026-02-06 00:19:24', 1, '2026-02-17 17:24:46'),
  ('ITEM-286', 'Canela x500g', 'material_consumo', 12, 18, 1, NULL, 'mensual', 0, 1, 1, '2026-02-06 00:19:24', 1, '2026-02-17 17:24:46'),
  ('ITEM-287', 'Azúcar sobre x200', 'material_consumo', 10, 18, 3, NULL, 'mensual', 0, 1, 1, '2026-02-06 00:19:24', 1, '2026-02-17 17:24:46'),
  ('ITEM-288', 'Splenda x700 sobres', 'material_consumo', 10, 21, 3, NULL, 'mensual', 0, 1, 1, '2026-02-06 00:19:24', 1, '2026-02-17 17:24:46'),
  ('ITEM-289', 'Mantequilla de Almendras x1000', 'material_consumo', 12, 21, 1, NULL, 'mensual', 0, 1, 1, '2026-02-06 00:19:24', 1, '2026-02-17 17:24:46'),
  ('ITEM-290', 'Croissant de lomo x6', 'material_consumo', 9, 3, 3, NULL, 'diario', 0, 0, 1, '2026-02-06 23:32:20', 1, '2026-07-04 20:18:51'),
  ('ITEM-291', 'Agua Hatsu 500ml', 'material_consumo', 4, 5, 3, 2400, 'diario', 0, 1, 1, '2026-02-08 22:31:19', 1, '2026-02-17 17:24:46'),
  ('ITEM-292', 'Sodas', 'material_consumo', 4, 5, 3, 2121, 'diario', 0, 1, 1, '2026-02-08 22:34:49', 1, '2026-02-17 17:24:46'),
  ('ITEM-293', 'Tónica', 'material_consumo', 5, 6, 3, NULL, 'mensual', 0, 1, 1, '2026-02-15 20:25:22', 1, '2026-02-17 17:24:46'),
  ('ITEM-294', 'Tubular', 'material_consumo', 2, 2, 3, NULL, 'mensual', 0, 1, 1, '2026-02-15 20:26:35', 1, '2026-02-17 17:24:46'),
  ('ITEM-295', 'Café Varietales x250gr', 'material_consumo', 6, 1, 1, 28000, 'diario', 0, 0, 1, '2026-02-22 15:21:05', 1, '2026-03-26 19:39:43'),
  ('ITEM-296', 'Café Mujeres x 250g', 'material_consumo', 6, 1, 1, 28000, 'diario', 0, 0, 1, '2026-03-20 16:08:57', 1, '2026-03-30 10:37:50'),
  ('ITEM-297', 'Café Madres x 250g', 'material_consumo', 6, 1, 1, 31500, 'diario', 0, 0, 1, '2026-05-12 18:19:43', 1, '2026-06-02 16:10:40'),
  ('ITEM-298', 'Café Bourbon Rosado lata x250g', 'material_consumo', 6, 1, 1, 45500, 'diario', 0, 0, 1, '2026-06-02 21:11:51', 1, '2026-06-09 20:15:53'),
  ('ITEM-299', 'Café Paz Espresso (Tolva)', 'insumo', 7, 1, 2, NULL, 'diario', 0, 1, 1, '2026-06-04 17:24:30', 1, '2026-06-04 17:24:30'),
  ('ITEM-300', 'Croissant Espinaca y Queso', 'material_consumo', 9, 3, 3, 5300, 'diario', 0, 1, 1, '2026-06-09 20:03:22', 1, '2026-06-09 20:03:22'),
  ('ITEM-301', 'Café Padres Lata x250g', 'material_consumo', 6, 1, 1, 43400, 'diario', 0, 0, 1, '2026-06-10 01:15:42', 1, '2026-07-04 20:18:05'),
  ('ITEM-302', 'Café Honey Caicedo', 'material_consumo', 6, NULL, 1, NULL, 'diario', 0, 1, 1, '2026-07-05 01:17:50', 1, '2026-07-05 01:17:50'),
  ('ITEM-303', 'Verderina Verde', 'insumo', 11, NULL, 3, NULL, 'diario', 0, 0, 1, '2026-07-05 01:19:41', 1, '2026-07-04 20:21:09'),
  ('ITEM-304', 'Verderina Roja', 'insumo', 11, 12, 3, NULL, 'diario', 0, 0, 1, '2026-07-05 01:20:10', 1, '2026-07-04 20:20:50');

-- ========================================================
-- FIN DE MIGRACIÓN
-- ========================================================
-- Validación: Ejecutar estas queries para verificar
-- SELECT COUNT(*) FROM proveedores;       -- Esperado: 21
-- SELECT COUNT(*) FROM categorias;        -- Esperado: 2
-- SELECT COUNT(*) FROM subcategorias;     -- Esperado: 16
-- SELECT COUNT(*) FROM items;             -- Esperado: 131
-- ========================================================

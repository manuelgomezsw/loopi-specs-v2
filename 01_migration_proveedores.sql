-- ========================================================
-- MIGRACIÓN PROVEEDORES (SUPPLIERS) DE LOOPI V1 A V2
-- ========================================================
-- Nota: Los campos de contacto vacíos en v1 se rellenan con dummies
-- Modificar estos valores a través de la UX según sea necesario

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

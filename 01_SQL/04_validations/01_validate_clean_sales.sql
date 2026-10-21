/* ==============================================================================
   VALIDACIONES - clean_Ventas   (SOLO LECTURA)
   Archivo: 01_SQL/04_validations/01_validate_clean_sales.sql
   Origen: movidas desde 01_SQL/02_cleaning/01_clean_sales.sql
   No modifica datos. Ejecutar después de crear dbo.clean_Ventas.
   ============================================================================== */

USE NexoRetail;
GO

-- 3a) Conteo tras dedup. Esperado: 80295 (= 80536 - 241 duplicados exactos).
SELECT COUNT(*) AS Filas_clean_Ventas, 80295 AS Esperado FROM dbo.clean_Ventas;

-- 3b) No deben quedar ID_Venta duplicados. Esperado: 0.
SELECT COUNT(*) AS ID_Venta_Duplicados
FROM (
    SELECT ID_Venta FROM dbo.clean_Ventas GROUP BY ID_Venta HAVING COUNT(*) > 1
) d;

-- 3c) Canal resuelto: solo {Online, Offline}, sin vacíos. Online+Offline debe dar 80295.
SELECT Canal_Venta, COUNT(*) AS Filas
FROM dbo.clean_Ventas
GROUP BY Canal_Venta
ORDER BY Canal_Venta;

SELECT SUM(CASE WHEN Canal_Venta IS NULL OR Canal_Venta = '' THEN 1 ELSE 0 END) AS Canal_Vacio  -- esperado 0
FROM dbo.clean_Ventas;

-- 3d) País canónico: solo {México, Brasil, Italia} en tienda y cliente.
SELECT 'Ubicacion_Tienda' AS Columna, Ubicacion_Tienda AS Valor, COUNT(*) AS Filas
FROM dbo.clean_Ventas GROUP BY Ubicacion_Tienda
UNION ALL
SELECT 'Ubicacion_Cliente', Ubicacion_Cliente, COUNT(*)
FROM dbo.clean_Ventas GROUP BY Ubicacion_Cliente
ORDER BY Columna, Valor;

-- 3e) Categoría canónica: solo {Electrónica, Muebles, Ropa, Alimentos}.
SELECT Categoria_Producto, COUNT(*) AS Filas
FROM dbo.clean_Ventas
GROUP BY Categoria_Producto
ORDER BY Categoria_Producto;

-- 3f) Control de tipado: 0 valores que no castearon (NULL inesperado) en columnas clave.
SELECT
    SUM(CASE WHEN ID_Venta        IS NULL THEN 1 ELSE 0 END) AS ID_Venta_NULL,
    SUM(CASE WHEN Fecha           IS NULL THEN 1 ELSE 0 END) AS Fecha_NULL,
    SUM(CASE WHEN Cantidad        IS NULL THEN 1 ELSE 0 END) AS Cantidad_NULL,
    SUM(CASE WHEN Precio_Unitario IS NULL THEN 1 ELSE 0 END) AS Precio_NULL
FROM dbo.clean_Ventas;

/* ==============================================================================
   VALIDACIONES - clean_Devoluciones   (SOLO LECTURA)
   Archivo: 01_SQL/04_validations/02_validate_clean_returns.sql
   Origen: movidas desde 01_SQL/02_cleaning/02_clean_returns.sql
   No modifica datos. Ejecutar después de crear dbo.clean_Devoluciones.
   ============================================================================== */

USE NexoRetail;
GO

-- 3a) Total de filas conservadas. Esperado: 4715.
SELECT COUNT(*) AS Filas_clean_Devoluciones, 4715 AS Esperado FROM dbo.clean_Devoluciones;

-- 3b) ID_Devolucion sin duplicación inesperada. Esperado: 0.
SELECT COUNT(*) AS ID_Devolucion_Duplicados
FROM (
    SELECT ID_Devolucion FROM dbo.clean_Devoluciones
    GROUP BY ID_Devolucion HAVING COUNT(*) > 1
) d;

-- 3c) Categoria_Producto canónica: exactamente 4 valores.
SELECT Categoria_Producto, COUNT(*) AS Filas
FROM dbo.clean_Devoluciones
GROUP BY Categoria_Producto
ORDER BY Categoria_Producto;

-- 3d) Flag de huérfanas. Esperado: 12.
SELECT SUM(CAST(Es_Huerfana AS INT)) AS Huerfanas FROM dbo.clean_Devoluciones;

-- 3e) Flag de excesos. Esperado: 8.
SELECT SUM(CAST(Es_Exceso_Devolucion AS INT)) AS Excesos FROM dbo.clean_Devoluciones;

-- 3f) Devoluciones de 2026 (se conservan). Esperado: 99.
SELECT COUNT(*) AS Devoluciones_2026
FROM dbo.clean_Devoluciones
WHERE Fecha_Devolucion > '2025-12-31';

-- 3g) Las 99 de 2026 deben estar vinculadas a ventas de diciembre 2025.
--     Esperado: una sola fila -> 2025-12 | 99.
SELECT FORMAT(v.Fecha, 'yyyy-MM') AS Mes_Venta, COUNT(*) AS Devoluciones
FROM dbo.clean_Devoluciones d
JOIN dbo.clean_Ventas v ON v.ID_Venta = d.ID_Venta
WHERE d.Fecha_Devolucion > '2025-12-31'
GROUP BY FORMAT(v.Fecha, 'yyyy-MM')
ORDER BY Mes_Venta;

-- 3h) NULLs generados por el tipado en columnas clave. Esperado: todo 0.
SELECT
    SUM(CASE WHEN ID_Devolucion     IS NULL THEN 1 ELSE 0 END) AS ID_Devolucion_NULL,
    SUM(CASE WHEN ID_Venta          IS NULL THEN 1 ELSE 0 END) AS ID_Venta_NULL,
    SUM(CASE WHEN Fecha_Devolucion  IS NULL THEN 1 ELSE 0 END) AS Fecha_NULL,
    SUM(CASE WHEN ID_Producto       IS NULL THEN 1 ELSE 0 END) AS ID_Producto_NULL,
    SUM(CASE WHEN ID_Tienda         IS NULL THEN 1 ELSE 0 END) AS ID_Tienda_NULL,
    SUM(CASE WHEN Cantidad_Devuelta IS NULL THEN 1 ELSE 0 END) AS Cantidad_NULL,
    SUM(CASE WHEN Precio_Unitario   IS NULL THEN 1 ELSE 0 END) AS Precio_NULL
FROM dbo.clean_Devoluciones;

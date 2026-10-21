/* ==============================================================================
   VALIDACIONES - Fact_Devoluciones   (SOLO LECTURA)
   Archivo: 01_SQL/04_validations/04_validate_fact_returns.sql
   Origen: movidas desde 01_SQL/03_transformations/02_transform_returns.sql
   No modifica datos. Ejecutar después de crear dbo.Fact_Devoluciones.
   ============================================================================== */

USE NexoRetail;
GO

-- V1) Filas finales = 4.715
SELECT 'V1 Filas finales' AS Validacion, 4715 AS Esperado, COUNT(*) AS Obtenido,
       CASE WHEN COUNT(*) = 4715 THEN 'OK' ELSE 'REVISAR' END AS Estado
FROM dbo.Fact_Devoluciones;

-- V2) ID_Devolucion único (grupos duplicados)
SELECT 'V2 ID_Devolucion duplicados' AS Validacion, 0 AS Esperado, COUNT(*) AS Obtenido,
       CASE WHEN COUNT(*) = 0 THEN 'OK' ELSE 'REVISAR' END AS Estado
FROM (SELECT ID_Devolucion FROM dbo.Fact_Devoluciones GROUP BY ID_Devolucion HAVING COUNT(*) > 1) d;

-- V3) Fan-out del JOIN con clean_Ventas AISLADO: debe dar 4.715
SELECT 'V3 Fan-out JOIN clean_Ventas' AS Validacion, 4715 AS Esperado, COUNT(*) AS Obtenido,
       CASE WHEN COUNT(*) = 4715 THEN 'OK' ELSE 'REVISAR' END AS Estado
FROM dbo.clean_Devoluciones d
LEFT JOIN dbo.clean_Ventas v ON v.ID_Venta = d.ID_Venta;

-- V4) Filas finales tras el JOIN = 4.715 (= Fact_Devoluciones)
SELECT 'V4 Filas tras JOIN' AS Validacion, 4715 AS Esperado, COUNT(*) AS Obtenido,
       CASE WHEN COUNT(*) = 4715 THEN 'OK' ELSE 'REVISAR' END AS Estado
FROM dbo.Fact_Devoluciones;

-- V5) Es_Huerfana = 12
SELECT 'V5 Huerfanas' AS Validacion, 12 AS Esperado, SUM(CAST(Es_Huerfana AS INT)) AS Obtenido,
       CASE WHEN SUM(CAST(Es_Huerfana AS INT)) = 12 THEN 'OK' ELSE 'REVISAR' END AS Estado
FROM dbo.Fact_Devoluciones;

-- V6) Es_Exceso_Devolucion = 8
SELECT 'V6 Excesos' AS Validacion, 8 AS Esperado, SUM(CAST(Es_Exceso_Devolucion AS INT)) AS Obtenido,
       CASE WHEN SUM(CAST(Es_Exceso_Devolucion AS INT)) = 8 THEN 'OK' ELSE 'REVISAR' END AS Estado
FROM dbo.Fact_Devoluciones;

-- V7) Devoluciones de 2026 = 99
SELECT 'V7 Devoluciones 2026' AS Validacion, 99 AS Esperado,
       SUM(CASE WHEN Fecha_Devolucion > '2025-12-31' THEN 1 ELSE 0 END) AS Obtenido,
       CASE WHEN SUM(CASE WHEN Fecha_Devolucion > '2025-12-31' THEN 1 ELSE 0 END) = 99 THEN 'OK' ELSE 'REVISAR' END AS Estado
FROM dbo.Fact_Devoluciones;

-- V8) Las 99 de 2026 vinculadas a ventas de diciembre 2025 (vía Fecha_Venta ya resuelta)
SELECT 'V8 2026 -> venta' AS Validacion, FORMAT(Fecha_Venta, 'yyyy-MM') AS Mes_Venta, COUNT(*) AS Devoluciones
FROM dbo.Fact_Devoluciones
WHERE Fecha_Devolucion > '2025-12-31'
GROUP BY FORMAT(Fecha_Venta, 'yyyy-MM');   -- esperado: una sola fila -> 2025-12 | 99

-- V9) Huérfanas conservadas: 12 filas con Es_Huerfana=1 y Fecha_Venta NULL
SELECT 'V9 Huerfanas conservadas (Fecha_Venta NULL)' AS Validacion, 12 AS Esperado,
       SUM(CASE WHEN Es_Huerfana = 1 AND Fecha_Venta IS NULL THEN 1 ELSE 0 END) AS Obtenido,
       CASE WHEN SUM(CASE WHEN Es_Huerfana = 1 AND Fecha_Venta IS NULL THEN 1 ELSE 0 END) = 12 THEN 'OK' ELSE 'REVISAR' END AS Estado
FROM dbo.Fact_Devoluciones;

-- V10) Valor_Devuelto no NULL cuando ID_Venta existe (no huérfana)
SELECT 'V10 Valor_Devuelto NULL en no-huerfanas' AS Validacion, 0 AS Esperado,
       SUM(CASE WHEN Es_Huerfana = 0 AND Valor_Devuelto IS NULL THEN 1 ELSE 0 END) AS Obtenido,
       CASE WHEN SUM(CASE WHEN Es_Huerfana = 0 AND Valor_Devuelto IS NULL THEN 1 ELSE 0 END) = 0 THEN 'OK' ELSE 'REVISAR' END AS Estado
FROM dbo.Fact_Devoluciones;

-- V11) Valor_Devuelto = Cantidad_Devuelta * Precio_Unitario (contar discrepancias)
SELECT 'V11 Valor_Devuelto = Cant*PU' AS Validacion, 0 AS Esperado,
       SUM(CASE WHEN Valor_Devuelto <> CAST(Cantidad_Devuelta * Precio_Unitario AS DECIMAL(18,2)) THEN 1 ELSE 0 END) AS Obtenido,
       CASE WHEN SUM(CASE WHEN Valor_Devuelto <> CAST(Cantidad_Devuelta * Precio_Unitario AS DECIMAL(18,2)) THEN 1 ELSE 0 END) = 0 THEN 'OK' ELSE 'REVISAR' END AS Estado
FROM dbo.Fact_Devoluciones;

-- V12) Conteo antes/después del JOIN idéntico (clean_Devoluciones vs Fact_Devoluciones)
SELECT 'V12 Conteo clean vs fact' AS Validacion,
       (SELECT COUNT(*) FROM dbo.clean_Devoluciones) AS Clean_Devoluciones,
       (SELECT COUNT(*) FROM dbo.Fact_Devoluciones)  AS Fact_Devoluciones,
       (SELECT COUNT(*) FROM dbo.clean_Devoluciones) - (SELECT COUNT(*) FROM dbo.Fact_Devoluciones) AS Diferencia,
       CASE WHEN (SELECT COUNT(*) FROM dbo.clean_Devoluciones) = (SELECT COUNT(*) FROM dbo.Fact_Devoluciones) THEN 'OK' ELSE 'REVISAR' END AS Estado;

/* ==============================================================================
   VALIDACIONES - Fact_Objetivos   (SOLO LECTURA)
   Archivo: 01_SQL/04_validations/05_validate_fact_objectives.sql
   Origen: movidas desde 01_SQL/03_transformations/03_transform_objectives.sql
   No modifica datos. Ejecutar después de crear dbo.Fact_Objetivos.
   ============================================================================== */

USE NexoRetail;
GO

-- V1) Filas finales = 246 (no se inventan filas nuevas)
SELECT 'V1 Filas finales' AS Validacion, 246 AS Esperado, COUNT(*) AS Obtenido,
       CASE WHEN COUNT(*) = 246 THEN 'OK' ELSE 'REVISAR' END AS Estado
FROM dbo.Fact_Objetivos;

-- V2) Clave (Fecha_Mes, ID_Tienda) única (grupos duplicados)
SELECT 'V2 Clave (Fecha_Mes,ID_Tienda) duplicada' AS Validacion, 0 AS Esperado, COUNT(*) AS Obtenido,
       CASE WHEN COUNT(*) = 0 THEN 'OK' ELSE 'REVISAR' END AS Estado
FROM (SELECT Fecha_Mes, ID_Tienda FROM dbo.Fact_Objetivos GROUP BY Fecha_Mes, ID_Tienda HAVING COUNT(*) > 1) d;

-- V3) 21 tiendas distintas
SELECT 'V3 Tiendas distintas' AS Validacion, 21 AS Esperado, COUNT(DISTINCT ID_Tienda) AS Obtenido,
       CASE WHEN COUNT(DISTINCT ID_Tienda) = 21 THEN 'OK' ELSE 'REVISAR' END AS Estado
FROM dbo.Fact_Objetivos;

-- V4) Ninguna tienda con más de 12 meses (se muestra el máximo observado)
SELECT 'V4 Máx meses por tienda' AS Validacion, 12 AS Esperado_Max, MAX(nMes) AS Obtenido_Max,
       CASE WHEN MAX(nMes) <= 12 THEN 'OK' ELSE 'REVISAR' END AS Estado
FROM (SELECT ID_Tienda, COUNT(DISTINCT Fecha_Mes) AS nMes FROM dbo.Fact_Objetivos GROUP BY ID_Tienda) x;

-- V5) ID_Tienda 18 tiene exactamente 6 meses
SELECT 'V5 Meses tienda 18' AS Validacion, 6 AS Esperado, COUNT(DISTINCT Fecha_Mes) AS Obtenido,
       CASE WHEN COUNT(DISTINCT Fecha_Mes) = 6 THEN 'OK' ELSE 'REVISAR' END AS Estado
FROM dbo.Fact_Objetivos
WHERE ID_Tienda = 18;

-- V6) Todos los períodos pertenecen a 2025 (contar los que NO)
SELECT 'V6 Períodos fuera de 2025' AS Validacion, 0 AS Esperado,
       SUM(CASE WHEN YEAR(Fecha_Mes) <> 2025 THEN 1 ELSE 0 END) AS Obtenido,
       CASE WHEN SUM(CASE WHEN YEAR(Fecha_Mes) <> 2025 THEN 1 ELSE 0 END) = 0 THEN 'OK' ELSE 'REVISAR' END AS Estado
FROM dbo.Fact_Objetivos;

-- V7) Objetivo_Ventas sin NULL
SELECT 'V7 Objetivo_Ventas NULL' AS Validacion, 0 AS Esperado,
       SUM(CASE WHEN Objetivo_Ventas IS NULL THEN 1 ELSE 0 END) AS Obtenido,
       CASE WHEN SUM(CASE WHEN Objetivo_Ventas IS NULL THEN 1 ELSE 0 END) = 0 THEN 'OK' ELSE 'REVISAR' END AS Estado
FROM dbo.Fact_Objetivos;

-- V8) Objetivo_Ventas > 0 (contar los que NO cumplen)
SELECT 'V8 Objetivo_Ventas <= 0' AS Validacion, 0 AS Esperado,
       SUM(CASE WHEN Objetivo_Ventas <= 0 THEN 1 ELSE 0 END) AS Obtenido,
       CASE WHEN SUM(CASE WHEN Objetivo_Ventas <= 0 THEN 1 ELSE 0 END) = 0 THEN 'OK' ELSE 'REVISAR' END AS Estado
FROM dbo.Fact_Objetivos;

-- V9) Rango de años presente (min y max deben ser 2025)
SELECT 'V9 Rango de años' AS Validacion, MIN(YEAR(Fecha_Mes)) AS Anio_Min, MAX(YEAR(Fecha_Mes)) AS Anio_Max,
       CASE WHEN MIN(YEAR(Fecha_Mes)) = 2025 AND MAX(YEAR(Fecha_Mes)) = 2025 THEN 'OK' ELSE 'REVISAR' END AS Estado
FROM dbo.Fact_Objetivos;

-- V10) No se inventaron los 6 meses faltantes de la tienda 18:
--      total filas sigue en 246 y la tienda 18 sigue con 6 (no 12).
SELECT 'V10 No se completó tienda 18' AS Validacion,
       (SELECT COUNT(*) FROM dbo.Fact_Objetivos) AS Filas_Totales,            -- esperado 246
       (SELECT COUNT(DISTINCT Fecha_Mes) FROM dbo.Fact_Objetivos WHERE ID_Tienda = 18) AS Meses_Tienda18,  -- esperado 6
       CASE WHEN (SELECT COUNT(*) FROM dbo.Fact_Objetivos) = 246
             AND (SELECT COUNT(DISTINCT Fecha_Mes) FROM dbo.Fact_Objetivos WHERE ID_Tienda = 18) = 6
            THEN 'OK' ELSE 'REVISAR' END AS Estado;

/* ==============================================================================
   VALIDACIONES - Fact_Ventas   (SOLO LECTURA)
   Archivo: 01_SQL/04_validations/03_validate_fact_sales.sql
   Origen: movidas desde 01_SQL/03_transformations/01_transform_sales.sql
   No modifica datos. Ejecutar después de crear dbo.Fact_Ventas.
   Nota: contiene literales acentuados -> ejecutar con sqlcmd -f 65001 si aplica.
   ============================================================================== */

USE NexoRetail;
GO

-- V1) Filas finales = 80.295
SELECT 'V1 Filas finales' AS Validacion, 80295 AS Esperado, COUNT(*) AS Obtenido,
       CASE WHEN COUNT(*) = 80295 THEN 'OK' ELSE 'REVISAR' END AS Estado
FROM dbo.Fact_Ventas;

-- V2) ID_Venta único (grupos duplicados)
SELECT 'V2 ID_Venta duplicados' AS Validacion, 0 AS Esperado, COUNT(*) AS Obtenido,
       CASE WHEN COUNT(*) = 0 THEN 'OK' ELSE 'REVISAR' END AS Estado
FROM (SELECT ID_Venta FROM dbo.Fact_Ventas GROUP BY ID_Venta HAVING COUNT(*) > 1) d;

-- V3) Registros sin Precio_Lista_Vigente
SELECT 'V3 Sin Precio_Lista_Vigente' AS Validacion, 0 AS Esperado,
       SUM(CASE WHEN Precio_Lista_Vigente IS NULL THEN 1 ELSE 0 END) AS Obtenido,
       CASE WHEN SUM(CASE WHEN Precio_Lista_Vigente IS NULL THEN 1 ELSE 0 END) = 0 THEN 'OK' ELSE 'REVISAR' END AS Estado
FROM dbo.Fact_Ventas;

-- V4) Registros sin Costo_Unitario
SELECT 'V4 Sin Costo_Unitario' AS Validacion, 0 AS Esperado,
       SUM(CASE WHEN Costo_Unitario IS NULL THEN 1 ELSE 0 END) AS Obtenido,
       CASE WHEN SUM(CASE WHEN Costo_Unitario IS NULL THEN 1 ELSE 0 END) = 0 THEN 'OK' ELSE 'REVISAR' END AS Estado
FROM dbo.Fact_Ventas;

-- V5) Fan-out del JOIN con Precios AISLADO: clean_Ventas LEFT JOIN Precios debe dar 80.295
WITH Precios_Rango AS (
    SELECT TRY_CAST(ID_Producto AS INT) AS ID_Producto,
           TRY_CONVERT(date, Vigencia_Desde, 23) AS Vigencia_Desde,
           ISNULL(DATEADD(day, -1, LEAD(TRY_CONVERT(date, Vigencia_Desde, 23)) OVER (
               PARTITION BY TRY_CAST(ID_Producto AS INT) ORDER BY TRY_CONVERT(date, Vigencia_Desde, 23))), '9999-12-31') AS Vigencia_Hasta
    FROM dbo.raw_Precios
)
SELECT 'V5 Fan-out JOIN Precios' AS Validacion, 80295 AS Esperado, COUNT(*) AS Obtenido,
       CASE WHEN COUNT(*) = 80295 THEN 'OK' ELSE 'REVISAR' END AS Estado
FROM dbo.clean_Ventas v
LEFT JOIN Precios_Rango p
       ON p.ID_Producto = v.ID_Producto
      AND v.Fecha BETWEEN p.Vigencia_Desde AND p.Vigencia_Hasta;

-- V6) Fan-out del JOIN con Costos AISLADO: clean_Ventas LEFT JOIN Costos debe dar 80.295
SELECT 'V6 Fan-out JOIN Costos' AS Validacion, 80295 AS Esperado, COUNT(*) AS Obtenido,
       CASE WHEN COUNT(*) = 80295 THEN 'OK' ELSE 'REVISAR' END AS Estado
FROM dbo.clean_Ventas v
LEFT JOIN (
    SELECT TRY_CAST(ID_Producto AS INT) AS ID_Producto, Periodo
    FROM dbo.raw_Costos
) c
       ON c.ID_Producto = v.ID_Producto
      AND c.Periodo     = LEFT(CONVERT(char(10), v.Fecha, 23), 7);

-- V7) Facturacion sin NULL
SELECT 'V7 Facturacion NULL' AS Validacion, 0 AS Esperado,
       SUM(CASE WHEN Facturacion IS NULL THEN 1 ELSE 0 END) AS Obtenido,
       CASE WHEN SUM(CASE WHEN Facturacion IS NULL THEN 1 ELSE 0 END) = 0 THEN 'OK' ELSE 'REVISAR' END AS Estado
FROM dbo.Fact_Ventas;

-- V8) Costo_Total sin NULL
SELECT 'V8 Costo_Total NULL' AS Validacion, 0 AS Esperado,
       SUM(CASE WHEN Costo_Total IS NULL THEN 1 ELSE 0 END) AS Obtenido,
       CASE WHEN SUM(CASE WHEN Costo_Total IS NULL THEN 1 ELSE 0 END) = 0 THEN 'OK' ELSE 'REVISAR' END AS Estado
FROM dbo.Fact_Ventas;

-- V9) Margen_Bruto sin NULL
SELECT 'V9 Margen_Bruto NULL' AS Validacion, 0 AS Esperado,
       SUM(CASE WHEN Margen_Bruto IS NULL THEN 1 ELSE 0 END) AS Obtenido,
       CASE WHEN SUM(CASE WHEN Margen_Bruto IS NULL THEN 1 ELSE 0 END) = 0 THEN 'OK' ELSE 'REVISAR' END AS Estado
FROM dbo.Fact_Ventas;

-- V10) Precio_Lista_Vigente > 0 en todos los casos (contar los que NO cumplen)
SELECT 'V10 Precio_Lista_Vigente <= 0' AS Validacion, 0 AS Esperado,
       SUM(CASE WHEN Precio_Lista_Vigente <= 0 THEN 1 ELSE 0 END) AS Obtenido,
       CASE WHEN SUM(CASE WHEN Precio_Lista_Vigente <= 0 THEN 1 ELSE 0 END) = 0 THEN 'OK' ELSE 'REVISAR' END AS Estado
FROM dbo.Fact_Ventas;

-- V11) Costo_Unitario > 0 en todos los casos
SELECT 'V11 Costo_Unitario <= 0' AS Validacion, 0 AS Esperado,
       SUM(CASE WHEN Costo_Unitario <= 0 THEN 1 ELSE 0 END) AS Obtenido,
       CASE WHEN SUM(CASE WHEN Costo_Unitario <= 0 THEN 1 ELSE 0 END) = 0 THEN 'OK' ELSE 'REVISAR' END AS Estado
FROM dbo.Fact_Ventas;

-- V12) Facturacion = Cantidad * Precio_Unitario (contar discrepancias)
SELECT 'V12 Facturacion = Cant*PU' AS Validacion, 0 AS Esperado,
       SUM(CASE WHEN Facturacion <> CAST(Cantidad * Precio_Unitario AS DECIMAL(18,2)) THEN 1 ELSE 0 END) AS Obtenido,
       CASE WHEN SUM(CASE WHEN Facturacion <> CAST(Cantidad * Precio_Unitario AS DECIMAL(18,2)) THEN 1 ELSE 0 END) = 0 THEN 'OK' ELSE 'REVISAR' END AS Estado
FROM dbo.Fact_Ventas;

-- V13) Costo_Total = Cantidad * Costo_Unitario (contar discrepancias)
SELECT 'V13 Costo_Total = Cant*CU' AS Validacion, 0 AS Esperado,
       SUM(CASE WHEN Costo_Total <> CAST(Cantidad * Costo_Unitario AS DECIMAL(18,2)) THEN 1 ELSE 0 END) AS Obtenido,
       CASE WHEN SUM(CASE WHEN Costo_Total <> CAST(Cantidad * Costo_Unitario AS DECIMAL(18,2)) THEN 1 ELSE 0 END) = 0 THEN 'OK' ELSE 'REVISAR' END AS Estado
FROM dbo.Fact_Ventas;

-- V14) Conteo de ID_Venta: clean_Ventas vs Fact_Ventas (diferencia = 0)
SELECT 'V14 Conteo clean vs fact' AS Validacion,
       (SELECT COUNT(*) FROM dbo.clean_Ventas) AS Clean_Ventas,
       (SELECT COUNT(*) FROM dbo.Fact_Ventas)  AS Fact_Ventas,
       (SELECT COUNT(*) FROM dbo.clean_Ventas) - (SELECT COUNT(*) FROM dbo.Fact_Ventas) AS Diferencia,
       CASE WHEN (SELECT COUNT(*) FROM dbo.clean_Ventas) = (SELECT COUNT(*) FROM dbo.Fact_Ventas) THEN 'OK' ELSE 'REVISAR' END AS Estado;

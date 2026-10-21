/* ==============================================================================
   VALIDACIONES - Integridad HECHO -> DIMENSIÓN   (SOLO LECTURA)
   Archivo: 01_SQL/04_validations/07_validate_integrity.sql
   ------------------------------------------------------------------------------
   Detecta claves huérfanas SOLO en las relaciones que crearemos en Power BI:
       Fact_Ventas       -> DimProducto (ID_Producto)
       Fact_Ventas       -> DimTienda   (ID_Tienda)
       Fact_Devoluciones -> DimProducto (ID_Producto)
       Fact_Devoluciones -> DimTienda   (ID_Tienda)
       Fact_Objetivos    -> DimTienda   (ID_Tienda)
   Esperado en todas: 0 (toda clave del hecho existe en su dimensión).

   IMPORTANTE: las 12 devoluciones huérfanas de ID_Venta (devolución -> venta)
   NO se evalúan aquí: esa relación no existe en el modelo estrella. Esta
   validación es exclusivamente hecho -> dimensión.
   No modifica datos ni tablas.
   ============================================================================== */

USE NexoRetail;
GO

-- V1) Fact_Ventas.ID_Producto sin correspondencia en DimProducto
SELECT 'V1 Fact_Ventas.ID_Producto -> DimProducto' AS Validacion, 0 AS Esperado, COUNT(*) AS Obtenido,
       CASE WHEN COUNT(*) = 0 THEN 'OK' ELSE 'REVISAR' END AS Estado
FROM dbo.Fact_Ventas f
WHERE NOT EXISTS (SELECT 1 FROM dbo.DimProducto d WHERE d.ID_Producto = f.ID_Producto);

-- V2) Fact_Ventas.ID_Tienda sin correspondencia en DimTienda
SELECT 'V2 Fact_Ventas.ID_Tienda -> DimTienda' AS Validacion, 0 AS Esperado, COUNT(*) AS Obtenido,
       CASE WHEN COUNT(*) = 0 THEN 'OK' ELSE 'REVISAR' END AS Estado
FROM dbo.Fact_Ventas f
WHERE NOT EXISTS (SELECT 1 FROM dbo.DimTienda d WHERE d.ID_Tienda = f.ID_Tienda);

-- V3) Fact_Devoluciones.ID_Producto sin correspondencia en DimProducto
SELECT 'V3 Fact_Devoluciones.ID_Producto -> DimProducto' AS Validacion, 0 AS Esperado, COUNT(*) AS Obtenido,
       CASE WHEN COUNT(*) = 0 THEN 'OK' ELSE 'REVISAR' END AS Estado
FROM dbo.Fact_Devoluciones f
WHERE NOT EXISTS (SELECT 1 FROM dbo.DimProducto d WHERE d.ID_Producto = f.ID_Producto);

-- V4) Fact_Devoluciones.ID_Tienda sin correspondencia en DimTienda
SELECT 'V4 Fact_Devoluciones.ID_Tienda -> DimTienda' AS Validacion, 0 AS Esperado, COUNT(*) AS Obtenido,
       CASE WHEN COUNT(*) = 0 THEN 'OK' ELSE 'REVISAR' END AS Estado
FROM dbo.Fact_Devoluciones f
WHERE NOT EXISTS (SELECT 1 FROM dbo.DimTienda d WHERE d.ID_Tienda = f.ID_Tienda);

-- V5) Fact_Objetivos.ID_Tienda sin correspondencia en DimTienda
SELECT 'V5 Fact_Objetivos.ID_Tienda -> DimTienda' AS Validacion, 0 AS Esperado, COUNT(*) AS Obtenido,
       CASE WHEN COUNT(*) = 0 THEN 'OK' ELSE 'REVISAR' END AS Estado
FROM dbo.Fact_Objetivos f
WHERE NOT EXISTS (SELECT 1 FROM dbo.DimTienda d WHERE d.ID_Tienda = f.ID_Tienda);

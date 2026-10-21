/* ==============================================================================
   VALIDACIONES - Dimensiones (DimFecha, DimProducto, DimTienda)   (SOLO LECTURA)
   Archivo: 01_SQL/04_validations/06_validate_dimensions.sql
   Origen: movidas desde 04_create_dim_fecha.sql / 05_create_dim_producto.sql /
           06_create_dim_tienda.sql
   No modifica datos. Ejecutar después de crear las 3 dimensiones.
   Nota: contiene literales acentuados -> ejecutar con sqlcmd -f 65001 si aplica.
   ============================================================================== */

USE NexoRetail;
GO

/* --------------------------------- DimFecha -------------------------------- */

-- V1) Cantidad de días = 762
SELECT 'DimFecha V1 Cantidad de días' AS Validacion, 762 AS Esperado, COUNT(*) AS Obtenido,
       CASE WHEN COUNT(*) = 762 THEN 'OK' ELSE 'REVISAR' END AS Estado
FROM dbo.DimFecha;

-- V2) Fecha mínima = 2024-01-01
SELECT 'DimFecha V2 Fecha mínima' AS Validacion, '2024-01-01' AS Esperado, CONVERT(char(10), MIN(Fecha), 23) AS Obtenido,
       CASE WHEN MIN(Fecha) = '2024-01-01' THEN 'OK' ELSE 'REVISAR' END AS Estado
FROM dbo.DimFecha;

-- V3) Fecha máxima = 2026-01-31
SELECT 'DimFecha V3 Fecha máxima' AS Validacion, '2026-01-31' AS Esperado, CONVERT(char(10), MAX(Fecha), 23) AS Obtenido,
       CASE WHEN MAX(Fecha) = '2026-01-31' THEN 'OK' ELSE 'REVISAR' END AS Estado
FROM dbo.DimFecha;

-- V4) Fechas duplicadas = 0
SELECT 'DimFecha V4 Fechas duplicadas' AS Validacion, 0 AS Esperado, COUNT(*) AS Obtenido,
       CASE WHEN COUNT(*) = 0 THEN 'OK' ELSE 'REVISAR' END AS Estado
FROM (SELECT Fecha FROM dbo.DimFecha GROUP BY Fecha HAVING COUNT(*) > 1) d;

-- V5) Fechas NULL = 0
SELECT 'DimFecha V5 Fechas NULL' AS Validacion, 0 AS Esperado,
       SUM(CASE WHEN Fecha IS NULL THEN 1 ELSE 0 END) AS Obtenido,
       CASE WHEN SUM(CASE WHEN Fecha IS NULL THEN 1 ELSE 0 END) = 0 THEN 'OK' ELSE 'REVISAR' END AS Estado
FROM dbo.DimFecha;

-- V6) Sin huecos: (días entre min y max) + 1 debe igualar la cantidad de filas
SELECT 'DimFecha V6 Continuidad (sin huecos)' AS Validacion,
       DATEDIFF(day, MIN(Fecha), MAX(Fecha)) + 1 AS Esperado,
       COUNT(*) AS Obtenido,
       CASE WHEN DATEDIFF(day, MIN(Fecha), MAX(Fecha)) + 1 = COUNT(*) THEN 'OK' ELSE 'REVISAR' END AS Estado
FROM dbo.DimFecha;

/* ------------------------------- DimProducto ------------------------------- */

-- V1) Filas = 101
SELECT 'DimProducto V1 Filas' AS Validacion, 101 AS Esperado, COUNT(*) AS Obtenido,
       CASE WHEN COUNT(*) = 101 THEN 'OK' ELSE 'REVISAR' END AS Estado
FROM dbo.DimProducto;

-- V2) ID_Producto duplicados = 0
SELECT 'DimProducto V2 ID_Producto duplicados' AS Validacion, 0 AS Esperado, COUNT(*) AS Obtenido,
       CASE WHEN COUNT(*) = 0 THEN 'OK' ELSE 'REVISAR' END AS Estado
FROM (SELECT ID_Producto FROM dbo.DimProducto GROUP BY ID_Producto HAVING COUNT(*) > 1) d;

-- V3) NULL en ID_Producto / Categoria_Producto = 0
SELECT 'DimProducto V3 NULL en ID/Categoria' AS Validacion, 0 AS Esperado,
       SUM(CASE WHEN ID_Producto IS NULL OR Categoria_Producto IS NULL THEN 1 ELSE 0 END) AS Obtenido,
       CASE WHEN SUM(CASE WHEN ID_Producto IS NULL OR Categoria_Producto IS NULL THEN 1 ELSE 0 END) = 0 THEN 'OK' ELSE 'REVISAR' END AS Estado
FROM dbo.DimProducto;

-- V4) Categorías fuera de las 4 canónicas = 0
SELECT 'DimProducto V4 Categorías inválidas' AS Validacion, 0 AS Esperado,
       SUM(CASE WHEN Categoria_Producto NOT IN ('Electrónica','Muebles','Ropa','Alimentos') THEN 1 ELSE 0 END) AS Obtenido,
       CASE WHEN SUM(CASE WHEN Categoria_Producto NOT IN ('Electrónica','Muebles','Ropa','Alimentos') THEN 1 ELSE 0 END) = 0 THEN 'OK' ELSE 'REVISAR' END AS Estado
FROM dbo.DimProducto;

-- V5) Productos con más de una categoría distinta en el origen = 0 (consistencia)
SELECT 'DimProducto V5 Productos con >1 categoría en origen' AS Validacion, 0 AS Esperado, COUNT(*) AS Obtenido,
       CASE WHEN COUNT(*) = 0 THEN 'OK' ELSE 'REVISAR' END AS Estado
FROM (SELECT ID_Producto FROM dbo.clean_Ventas GROUP BY ID_Producto HAVING COUNT(DISTINCT Categoria_Producto) > 1) x;

-- V6) Distribución por categoría (informativa: debe sumar 101)
SELECT 'DimProducto V6 Distribución por categoría' AS Validacion, Categoria_Producto, COUNT(*) AS Productos
FROM dbo.DimProducto
GROUP BY Categoria_Producto
ORDER BY Categoria_Producto;

/* -------------------------------- DimTienda -------------------------------- */

-- V1) Filas = 21
SELECT 'DimTienda V1 Filas' AS Validacion, 21 AS Esperado, COUNT(*) AS Obtenido,
       CASE WHEN COUNT(*) = 21 THEN 'OK' ELSE 'REVISAR' END AS Estado
FROM dbo.DimTienda;

-- V2) ID_Tienda único y rango 1..21
SELECT 'DimTienda V2 ID_Tienda (unico, min, max)' AS Validacion,
       '21 / 1 / 21' AS Esperado,
       CAST(COUNT(DISTINCT ID_Tienda) AS VARCHAR(5)) + ' / ' + CAST(MIN(ID_Tienda) AS VARCHAR(5)) + ' / ' + CAST(MAX(ID_Tienda) AS VARCHAR(5)) AS Obtenido,
       CASE WHEN COUNT(DISTINCT ID_Tienda) = 21 AND MIN(ID_Tienda) = 1 AND MAX(ID_Tienda) = 21 THEN 'OK' ELSE 'REVISAR' END AS Estado
FROM dbo.DimTienda;

-- V3) NULL en atributos obligatorios (ID_Tienda, Pais, Canal_Venta) = 0
SELECT 'DimTienda V3 NULL en obligatorios' AS Validacion, 0 AS Esperado,
       SUM(CASE WHEN ID_Tienda IS NULL OR Pais IS NULL OR Canal_Venta IS NULL THEN 1 ELSE 0 END) AS Obtenido,
       CASE WHEN SUM(CASE WHEN ID_Tienda IS NULL OR Pais IS NULL OR Canal_Venta IS NULL THEN 1 ELSE 0 END) = 0 THEN 'OK' ELSE 'REVISAR' END AS Estado
FROM dbo.DimTienda;

-- V4) Tiendas Online = 3
SELECT 'DimTienda V4 Tiendas Online' AS Validacion, 3 AS Esperado,
       SUM(CASE WHEN Canal_Venta = 'Online' THEN 1 ELSE 0 END) AS Obtenido,
       CASE WHEN SUM(CASE WHEN Canal_Venta = 'Online' THEN 1 ELSE 0 END) = 3 THEN 'OK' ELSE 'REVISAR' END AS Estado
FROM dbo.DimTienda;

-- V5) Tiendas Offline = 18
SELECT 'DimTienda V5 Tiendas Offline' AS Validacion, 18 AS Esperado,
       SUM(CASE WHEN Canal_Venta = 'Offline' THEN 1 ELSE 0 END) AS Obtenido,
       CASE WHEN SUM(CASE WHEN Canal_Venta = 'Offline' THEN 1 ELSE 0 END) = 18 THEN 'OK' ELSE 'REVISAR' END AS Estado
FROM dbo.DimTienda;

-- V6) Países fuera de las 3 canónicas = 0
SELECT 'DimTienda V6 Países inválidos' AS Validacion, 0 AS Esperado,
       SUM(CASE WHEN Pais NOT IN ('México','Brasil','Italia') THEN 1 ELSE 0 END) AS Obtenido,
       CASE WHEN SUM(CASE WHEN Pais NOT IN ('México','Brasil','Italia') THEN 1 ELSE 0 END) = 0 THEN 'OK' ELSE 'REVISAR' END AS Estado
FROM dbo.DimTienda;

-- V7) Tiendas con más de un país o más de un canal en el origen = 0 (consistencia)
SELECT 'DimTienda V7 Tiendas inconsistentes en origen' AS Validacion, 0 AS Esperado, COUNT(*) AS Obtenido,
       CASE WHEN COUNT(*) = 0 THEN 'OK' ELSE 'REVISAR' END AS Estado
FROM (
    SELECT ID_Tienda
    FROM dbo.clean_Ventas
    GROUP BY ID_Tienda
    HAVING COUNT(DISTINCT Ubicacion_Tienda) > 1 OR COUNT(DISTINCT Canal_Venta) > 1
) x;

-- V8) Distribución país x canal (informativa)
SELECT 'DimTienda V8 Distribución país x canal' AS Validacion, Pais, Canal_Venta, COUNT(*) AS Tiendas
FROM dbo.DimTienda
GROUP BY Pais, Canal_Venta
ORDER BY Pais, Canal_Venta;

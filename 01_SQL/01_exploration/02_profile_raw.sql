/* ==============================================================================
   PASO 2 - Exploración y perfilado de calidad sobre las tablas RAW
   Archivo: 01_SQL/01_exploration/02_profile_raw.sql
   ------------------------------------------------------------------------------
   Objetivo: validar en SQL Server los hallazgos del profiling previo en Python.
   SOLO LECTURA: únicamente SELECT. No modifica datos ni crea tablas finales.

   Entorno: localhost\SQLEXPRESS01 | base NexoRetail | auth Windows

   Notas técnicas:
   - Las tablas raw_ son todas NVARCHAR; los campos vacíos del CSV entran como
     cadena vacía ('') y NO como NULL. Por eso los chequeos contemplan NULL y ''.
   - Se usa TRY_CONVERT / TRY_CAST para castear fechas y números sin romper la
     consulta si hubiera un valor no esperado.
   - Fechas: Ventas = 'yyyy-MM-dd' (estilo 23); Devoluciones = 'dd/MM/yyyy' (estilo 103).
   - Costos usa coma decimal -> se reemplaza ',' por '.' antes de castear.
   ============================================================================== */

USE NexoRetail;
GO

/* ------------------------------------------------------------------------------
   [1] Cantidad de filas por tabla.
   Regla: la carga RAW debe coincidir con el conteo del CSV / profiling Python.
   Esperado: 80536 / 4715 / 641 / 2424 / 246
   ------------------------------------------------------------------------------ */
SELECT 'raw_Ventas' AS Tabla, COUNT(*) AS Filas FROM dbo.raw_Ventas
UNION ALL SELECT 'raw_Devoluciones', COUNT(*) FROM dbo.raw_Devoluciones
UNION ALL SELECT 'raw_Precios',      COUNT(*) FROM dbo.raw_Precios
UNION ALL SELECT 'raw_Costos',       COUNT(*) FROM dbo.raw_Costos
UNION ALL SELECT 'raw_Objetivos',    COUNT(*) FROM dbo.raw_Objetivos;

/* ------------------------------------------------------------------------------
   [2] Duplicados de ID_Venta en Ventas.
   Regla: ID_Venta debería ser único por línea; hay IDs repetidos.
   Esperado: 241 IDs duplicados, 482 filas involucradas.
   ------------------------------------------------------------------------------ */
SELECT
    COUNT(*)              AS IDs_Duplicados,          -- esperado 241
    SUM(cnt)              AS Filas_Involucradas,      -- esperado 482
    SUM(cnt) - COUNT(*)   AS Filas_Sobrantes          -- esperado 241 (a eliminar al deduplicar)
FROM (
    SELECT ID_Venta, COUNT(*) AS cnt
    FROM dbo.raw_Ventas
    GROUP BY ID_Venta
    HAVING COUNT(*) > 1
) d;

/* ------------------------------------------------------------------------------
   [3] Duplicados EXACTOS de registros en Ventas (todas las columnas iguales).
   Regla: confirmar que los duplicados son filas idénticas (dedup seguro).
   Esperado: 241 grupos exactos, 241 filas sobrantes (== duplicados de ID_Venta).
   ------------------------------------------------------------------------------ */
SELECT
    COUNT(*)            AS Grupos_Exactos_Duplicados, -- esperado 241
    SUM(cnt) - COUNT(*) AS Filas_Sobrantes            -- esperado 241
FROM (
    SELECT COUNT(*) AS cnt
    FROM dbo.raw_Ventas
    GROUP BY
        ID_Venta, ID_Pedido, Fecha, ID_Producto, ID_Cliente, ID_Tienda,
        Cantidad, Precio_Unitario, Canal_Venta, Categoria_Venta,
        Nombre_Cliente, Ubicacion_Cliente, Nombre_Tienda, Ubicacion_Tienda,
        Nombre_Producto, Categoria_Producto, Subcategoria_Producto
    HAVING COUNT(*) > 1
) g;

/* ------------------------------------------------------------------------------
   [4] Valores NULL / vacíos por columna relevante.
   Regla: detectar faltantes. Interesa sobre todo Canal_Venta en Ventas.
   Esperado Ventas: Canal_Venta vacío = 340; resto 0.
   Esperado Devoluciones: Fecha vacía = 0 (los 2797 "nulos" del Python eran
            un artefacto de parseo MM/DD, no faltantes reales).
   ------------------------------------------------------------------------------ */
-- Ventas
SELECT
    SUM(CASE WHEN ID_Venta        IS NULL OR LTRIM(RTRIM(ID_Venta))        = '' THEN 1 ELSE 0 END) AS ID_Venta_vacio,
    SUM(CASE WHEN Fecha           IS NULL OR LTRIM(RTRIM(Fecha))           = '' THEN 1 ELSE 0 END) AS Fecha_vacia,
    SUM(CASE WHEN ID_Producto     IS NULL OR LTRIM(RTRIM(ID_Producto))     = '' THEN 1 ELSE 0 END) AS ID_Producto_vacio,
    SUM(CASE WHEN ID_Tienda       IS NULL OR LTRIM(RTRIM(ID_Tienda))       = '' THEN 1 ELSE 0 END) AS ID_Tienda_vacio,
    SUM(CASE WHEN Cantidad        IS NULL OR LTRIM(RTRIM(Cantidad))        = '' THEN 1 ELSE 0 END) AS Cantidad_vacia,
    SUM(CASE WHEN Precio_Unitario IS NULL OR LTRIM(RTRIM(Precio_Unitario)) = '' THEN 1 ELSE 0 END) AS Precio_vacio,
    SUM(CASE WHEN Canal_Venta     IS NULL OR LTRIM(RTRIM(Canal_Venta))     = '' THEN 1 ELSE 0 END) AS Canal_vacio
FROM dbo.raw_Ventas;

-- Devoluciones
SELECT
    SUM(CASE WHEN ID_Devolucion     IS NULL OR LTRIM(RTRIM(ID_Devolucion))     = '' THEN 1 ELSE 0 END) AS ID_Devolucion_vacio,
    SUM(CASE WHEN ID_Venta          IS NULL OR LTRIM(RTRIM(ID_Venta))          = '' THEN 1 ELSE 0 END) AS ID_Venta_vacio,
    SUM(CASE WHEN Fecha             IS NULL OR LTRIM(RTRIM(Fecha))             = '' THEN 1 ELSE 0 END) AS Fecha_vacia,
    SUM(CASE WHEN Cantidad_Devuelta IS NULL OR LTRIM(RTRIM(Cantidad_Devuelta)) = '' THEN 1 ELSE 0 END) AS Cantidad_Devuelta_vacia,
    SUM(CASE WHEN Precio_Unitario   IS NULL OR LTRIM(RTRIM(Precio_Unitario))   = '' THEN 1 ELSE 0 END) AS Precio_vacio
FROM dbo.raw_Devoluciones;

/* ------------------------------------------------------------------------------
   [5] Valores distintos de Canal_Venta (con conteo).
   Regla: canal debería ser {Online, Offline}; lo vacío se resolverá por tienda.
   Esperado: Offline=54247, Online=25949, vacío/NULL=340.
   ------------------------------------------------------------------------------ */
SELECT
    ISNULL(NULLIF(LTRIM(RTRIM(Canal_Venta)), ''), '(vacío/NULL)') AS Canal_Venta,
    COUNT(*) AS Filas
FROM dbo.raw_Ventas
GROUP BY ISNULL(NULLIF(LTRIM(RTRIM(Canal_Venta)), ''), '(vacío/NULL)')
ORDER BY Filas DESC;

/* ------------------------------------------------------------------------------
   [6] Variantes de país / ubicación (sin normalizar, para ver mayúsc./espacios).
   Regla: deben unificarse a México / Brasil / Italia (inconsistencias conocidas).
   Esperado: ver variantes tipo 'México','MEXICO','Mexico',' México','Brazil','brasil','Italy','ITALIA'.
   ------------------------------------------------------------------------------ */
-- Ubicación de la tienda
SELECT Ubicacion_Tienda AS Valor, COUNT(*) AS Filas
FROM dbo.raw_Ventas
GROUP BY Ubicacion_Tienda
ORDER BY Valor;

-- Ubicación del cliente
SELECT Ubicacion_Cliente AS Valor, COUNT(*) AS Filas
FROM dbo.raw_Ventas
GROUP BY Ubicacion_Cliente
ORDER BY Valor;

/* ------------------------------------------------------------------------------
   [7] Variantes de Categoría_Producto (mayúsculas/espacios).
   Regla: deben unificarse a un valor canónico por categoría.
   Esperado: variantes de Electrónica / Muebles / Ropa / Alimentos.
   ------------------------------------------------------------------------------ */
SELECT Categoria_Producto AS Valor, COUNT(*) AS Filas
FROM dbo.raw_Ventas
GROUP BY Categoria_Producto
ORDER BY Valor;

/* ------------------------------------------------------------------------------
   [8] Rango de fechas de Ventas.
   Regla: ventana del análisis 2024-2025.
   Esperado: 2024-01-01 a 2025-12-31; 0 fechas no parseables.
   ------------------------------------------------------------------------------ */
SELECT
    MIN(TRY_CONVERT(date, Fecha, 23)) AS Fecha_Min,
    MAX(TRY_CONVERT(date, Fecha, 23)) AS Fecha_Max,
    SUM(CASE WHEN TRY_CONVERT(date, Fecha, 23) IS NULL THEN 1 ELSE 0 END) AS No_Parseables
FROM dbo.raw_Ventas;

/* ------------------------------------------------------------------------------
   [9] Rango de fechas de Devoluciones (formato dd/MM/yyyy, estilo 103).
   Regla: confirmar el parseo correcto DD/MM/YYYY y la existencia de fechas 2026.
   Esperado: 2024-01-04 a 2026-01-15; 0 no parseables.
   ------------------------------------------------------------------------------ */
SELECT
    MIN(TRY_CONVERT(date, Fecha, 103)) AS Fecha_Min,
    MAX(TRY_CONVERT(date, Fecha, 103)) AS Fecha_Max,
    SUM(CASE WHEN TRY_CONVERT(date, Fecha, 103) IS NULL THEN 1 ELSE 0 END) AS No_Parseables
FROM dbo.raw_Devoluciones;

/* ------------------------------------------------------------------------------
   [10] Cantidades y precios mínimos / máximos.
   Regla: no debe haber cantidades ni precios <= 0; validar rangos del Python.
   Esperado Ventas: Cantidad 1..8000; Precio 2.36..1440.89.
   Esperado Devoluciones: Cantidad_Devuelta 1..222; Precio 2.74..1440.89.
   Esperado Costos: Costo_Unitario 2.20..931.40.
   ------------------------------------------------------------------------------ */
SELECT 'Ventas.Cantidad' AS Metrica,
       MIN(TRY_CAST(Cantidad AS INT)) AS Minimo,
       MAX(TRY_CAST(Cantidad AS INT)) AS Maximo
FROM dbo.raw_Ventas
UNION ALL
SELECT 'Ventas.Precio_Unitario',
       MIN(TRY_CAST(Precio_Unitario AS DECIMAL(12,2))),
       MAX(TRY_CAST(Precio_Unitario AS DECIMAL(12,2)))
FROM dbo.raw_Ventas
UNION ALL
SELECT 'Devoluciones.Cantidad_Devuelta',
       MIN(TRY_CAST(Cantidad_Devuelta AS INT)),
       MAX(TRY_CAST(Cantidad_Devuelta AS INT))
FROM dbo.raw_Devoluciones
UNION ALL
SELECT 'Devoluciones.Precio_Unitario',
       MIN(TRY_CAST(Precio_Unitario AS DECIMAL(12,2))),
       MAX(TRY_CAST(Precio_Unitario AS DECIMAL(12,2)))
FROM dbo.raw_Devoluciones
UNION ALL
SELECT 'Costos.Costo_Unitario',
       MIN(TRY_CAST(REPLACE(Costo_Unitario, ',', '.') AS DECIMAL(12,2))),
       MAX(TRY_CAST(REPLACE(Costo_Unitario, ',', '.') AS DECIMAL(12,2)))
FROM dbo.raw_Costos;

/* ------------------------------------------------------------------------------
   [11] Devoluciones cuyo ID_Venta NO existe en Ventas (huérfanas).
   Regla: integridad referencial Devoluciones -> Ventas.
   Esperado: 12 devoluciones huérfanas.
   ------------------------------------------------------------------------------ */
SELECT COUNT(*) AS Devoluciones_Huerfanas   -- esperado 12
FROM dbo.raw_Devoluciones d
WHERE NOT EXISTS (
    SELECT 1 FROM dbo.raw_Ventas v WHERE v.ID_Venta = d.ID_Venta
);

-- Detalle de las huérfanas (para documentar el patrón: IDs fuera de rango)
SELECT d.ID_Devolucion, d.ID_Venta, d.Fecha, d.Ubicacion_Cliente,
       d.Nombre_Tienda, d.Motivo, d.Nombre_Producto, d.Cantidad_Devuelta
FROM dbo.raw_Devoluciones d
WHERE NOT EXISTS (
    SELECT 1 FROM dbo.raw_Ventas v WHERE v.ID_Venta = d.ID_Venta
)
ORDER BY TRY_CAST(d.ID_Venta AS BIGINT);

/* ------------------------------------------------------------------------------
   [12] Devoluciones donde Cantidad_Devuelta > Cantidad vendida de esa línea.
   Regla: no se puede devolver más de lo vendido (anomalía de calidad).
   Nota: se agrega la cantidad vendida por ID_Venta (MAX) para neutralizar los
         241 duplicados exactos y evitar fan-out en el join.
   Esperado: 8 casos.
   ------------------------------------------------------------------------------ */
WITH VentaQty AS (
    SELECT ID_Venta, MAX(TRY_CAST(Cantidad AS INT)) AS Cantidad_Vendida
    FROM dbo.raw_Ventas
    GROUP BY ID_Venta
)
SELECT COUNT(*) AS Casos_Exceso   -- esperado 8
FROM dbo.raw_Devoluciones d
JOIN VentaQty v ON v.ID_Venta = d.ID_Venta
WHERE TRY_CAST(d.Cantidad_Devuelta AS INT) > v.Cantidad_Vendida;

/* ------------------------------------------------------------------------------
   [13] Devoluciones correspondientes a 2026 y mes de su venta asociada.
   Regla: devoluciones tardías; deben cohortarse por la fecha de VENTA (dic-2025).
   Esperado: 99 devoluciones > 2025-12-31, todas con venta en 2025-12.
   ------------------------------------------------------------------------------ */
SELECT COUNT(*) AS Devoluciones_2026   -- esperado 99
FROM dbo.raw_Devoluciones
WHERE TRY_CONVERT(date, Fecha, 103) > '2025-12-31';

-- Confirmación: mes de la venta asociada a esas 99 devoluciones (esperado todo 2025-12)
SELECT FORMAT(TRY_CONVERT(date, v.Fecha, 23), 'yyyy-MM') AS Mes_Venta, COUNT(*) AS Devoluciones
FROM dbo.raw_Devoluciones d
JOIN dbo.raw_Ventas v ON v.ID_Venta = d.ID_Venta
WHERE TRY_CONVERT(date, d.Fecha, 103) > '2025-12-31'
GROUP BY FORMAT(TRY_CONVERT(date, v.Fecha, 23), 'yyyy-MM')
ORDER BY Mes_Venta;

/* ------------------------------------------------------------------------------
   [14] Cantidad de productos distintos en Ventas, Precios y Costos.
   Regla: catálogo de productos consistente entre fuentes.
   Esperado: 101 / 101 / 101.
   ------------------------------------------------------------------------------ */
SELECT 'Ventas'  AS Fuente, COUNT(DISTINCT ID_Producto) AS Productos_Distintos FROM dbo.raw_Ventas
UNION ALL SELECT 'Precios', COUNT(DISTINCT ID_Producto) FROM dbo.raw_Precios
UNION ALL SELECT 'Costos',  COUNT(DISTINCT ID_Producto) FROM dbo.raw_Costos;

/* ------------------------------------------------------------------------------
   [15] Productos de Ventas SIN precio (no están en Precios).
   Regla: toda venta debe poder resolver un precio de lista.
   Esperado: 0.
   ------------------------------------------------------------------------------ */
SELECT DISTINCT v.ID_Producto
FROM dbo.raw_Ventas v
WHERE NOT EXISTS (SELECT 1 FROM dbo.raw_Precios p WHERE p.ID_Producto = v.ID_Producto);

/* ------------------------------------------------------------------------------
   [16] Productos de Ventas SIN costo (no están en Costos).
   Regla: toda venta debe poder resolver un costo (para el margen).
   Esperado: 0.
   ------------------------------------------------------------------------------ */
SELECT DISTINCT v.ID_Producto
FROM dbo.raw_Ventas v
WHERE NOT EXISTS (SELECT 1 FROM dbo.raw_Costos c WHERE c.ID_Producto = v.ID_Producto);

/* ------------------------------------------------------------------------------
   [17] Cobertura temporal de Costos.
   Regla: grilla mensual completa por producto para el join costo del mes.
   Esperado: Periodo 2024-01 a 2025-12; 24 meses; 101 productos; 2424 filas (24x101).
   ------------------------------------------------------------------------------ */
SELECT
    MIN(Periodo)                  AS Periodo_Min,       -- esperado 2024-01
    MAX(Periodo)                  AS Periodo_Max,       -- esperado 2025-12
    COUNT(DISTINCT Periodo)       AS Meses_Distintos,   -- esperado 24
    COUNT(DISTINCT ID_Producto)   AS Productos,         -- esperado 101
    COUNT(*)                      AS Filas              -- esperado 2424
FROM dbo.raw_Costos;

/* ------------------------------------------------------------------------------
   [18] Unicidad de (Periodo, ID_Tienda) en Objetivos.
   Regla: clave natural del objetivo; no debe repetirse.
   Esperado: 0 combinaciones duplicadas.
   ------------------------------------------------------------------------------ */
SELECT COUNT(*) AS Combinaciones_Duplicadas   -- esperado 0
FROM (
    SELECT Periodo, ID_Tienda, COUNT(*) AS cnt
    FROM dbo.raw_Objetivos
    GROUP BY Periodo, ID_Tienda
    HAVING COUNT(*) > 1
) x;

/* ------------------------------------------------------------------------------
   [19] Cobertura de tiendas entre Ventas y Objetivos.
   Regla: validar qué tiendas tienen objetivo (recordar: Objetivos solo 2025).
   Esperado: 21 tiendas en ambas; 0 tiendas de Ventas sin objetivo.
   ------------------------------------------------------------------------------ */
SELECT
    (SELECT COUNT(DISTINCT ID_Tienda) FROM dbo.raw_Ventas)    AS Tiendas_En_Ventas,     -- esperado 21
    (SELECT COUNT(DISTINCT ID_Tienda) FROM dbo.raw_Objetivos) AS Tiendas_En_Objetivos,  -- esperado 21
    (SELECT COUNT(*) FROM (
        SELECT DISTINCT ID_Tienda FROM dbo.raw_Ventas
        EXCEPT
        SELECT DISTINCT ID_Tienda FROM dbo.raw_Objetivos
    ) a)                                                      AS Ventas_Sin_Objetivo,    -- esperado 0
    (SELECT COUNT(DISTINCT Periodo) FROM dbo.raw_Objetivos)   AS Meses_Objetivos;        -- esperado 12 (solo 2025)

-- Rango de periodos de Objetivos (esperado 2025-01 a 2025-12)
SELECT MIN(Periodo) AS Periodo_Min, MAX(Periodo) AS Periodo_Max FROM dbo.raw_Objetivos;

/* ==============================================================================
   RESULTADOS A COMPARAR CON EL PROFILING EN PYTHON
   ------------------------------------------------------------------------------
   [1]  Filas: 80536 / 4715 / 641 / 2424 / 246.
   [2]  ID_Venta duplicados: 241 IDs, 482 filas (241 sobrantes a deduplicar).
   [3]  Duplicados exactos: 241 grupos (confirma que el dedup es seguro).
   [4]  Canal_Venta vacío = 340. OJO: Devoluciones Fecha vacía = 0
        (los 2797 "nulos" de Python fueron un artefacto de parseo MM/DD, NO faltantes).
   [5]  Canal: Offline 54247 / Online 25949 / vacío 340.
   [6]  País: confirmar variantes México/MEXICO/Mexico/' México', Brasil/Brazil/brasil,
        Italia/Italy/ITALIA (en Ubicacion_Tienda y Ubicacion_Cliente).
   [7]  Categoría_Producto: confirmar variantes por mayúsculas/espacios.
   [8]  Ventas: 2024-01-01 a 2025-12-31.
   [9]  Devoluciones: 2024-01-04 a 2026-01-15 (clave: existen fechas 2026).
   [10] Rangos: Ventas Cant 1..8000, Precio 2.36..1440.89; Dev Cant 1..222,
        Precio 2.74..1440.89; Costos 2.20..931.40. Ningún valor <= 0.
   [11] Devoluciones huérfanas = 12 (IDs ~900k, fuera del rango 1..80295 de Ventas).
   [12] Cantidad_Devuelta > vendida = 8 casos.
   [13] Devoluciones 2026 = 99, TODAS con venta en 2025-12.
   [14] Productos distintos = 101 / 101 / 101.
   [15] Productos de Ventas sin precio = 0.
   [16] Productos de Ventas sin costo = 0.
   [17] Costos: 2024-01..2025-12, 24 meses, 101 productos, 2424 filas.
   [18] Objetivos (Periodo,ID_Tienda) duplicados = 0.
   [19] Tiendas: 21 en Ventas y 21 en Objetivos, 0 sin objetivo; Objetivos solo 2025.

   DIFERENCIA IMPORTANTE vs Python: el profiling original reportó 91 devoluciones
   de 2026 y 2797 fechas nulas en Devoluciones. Lo correcto es 99 devoluciones de
   2026 y 0 fechas nulas: ambos números del Python venían del parseo erróneo de
   fechas DD/MM/YYYY como MM/DD/YYYY.
   ============================================================================== */

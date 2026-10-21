/* ==============================================================================
   PASO 4 - TRANSFORMACIÓN: VENTAS  ->  dbo.Fact_Ventas
   Archivo: 01_SQL/03_transformations/01_transform_sales.sql
   ------------------------------------------------------------------------------
   Grano: 1 fila por ID_Venta (parte de dbo.clean_Ventas = 80.295).
   Agrega:
     - Precio_Lista_Vigente  -> AS-OF JOIN sobre raw_Precios (LEAD + rango)
     - Costo_Unitario        -> JOIN por ID_Producto + mes de Fecha_Venta (raw_Costos)
     - Facturacion, Costo_Total, Margen_Bruto, Margen_Porcentaje, Descuento_Porcentaje
   No toca raw_* ni clean_*.  No usa OUTER APPLY (se resuelve con LEAD + rango).

   OJO (correctitud de agregación en Power BI):
     Margen_Porcentaje y Descuento_Porcentaje son valores POR LÍNEA. NO deben
     promediarse/sumarse en DAX. El % agregado se recalcula como
     SUM(Margen_Bruto)/SUM(Facturacion). Acá se guardan solo a nivel fila.
   ============================================================================== */

USE NexoRetail;
GO

/* ===============================  DDL  ====================================== */
DROP TABLE IF EXISTS dbo.Fact_Ventas;
CREATE TABLE dbo.Fact_Ventas (
    ID_Venta             INT,            -- PK (grano) / degenerada
    ID_Pedido            INT,            -- degenerada (DISTINCTCOUNT de pedidos)
    Fecha_Venta          DATE,           -- FK -> DimFecha
    ID_Producto          INT,            -- FK -> DimProducto
    ID_Tienda            INT,            -- FK -> DimTienda
    Segmento             NVARCHAR(20),   -- Retail/Wholesale (columna de hecho)
    Cantidad             INT,
    Precio_Unitario      DECIMAL(12,2),  -- precio REAL cobrado (-> Facturacion)
    Precio_Lista_Vigente DECIMAL(12,2),  -- precio de referencia (-> Descuento)
    Costo_Unitario       DECIMAL(12,2),
    Facturacion          DECIMAL(18,2),  -- Cantidad * Precio_Unitario
    Costo_Total          DECIMAL(18,2),  -- Cantidad * Costo_Unitario
    Margen_Bruto         DECIMAL(18,2),  -- Facturacion - Costo_Total
    Margen_Porcentaje    DECIMAL(9,4),   -- Margen_Bruto / Facturacion (por línea)
    Descuento_Porcentaje DECIMAL(9,4)    -- 1 - (Precio_Unitario / Precio_Lista_Vigente)
);

/* ===============================  ETL  ====================================== */
-- CTE: arma el rango de vigencia de cada precio con LEAD().
-- La última vigencia de cada producto queda abierta (hasta 9999-12-31).
WITH Precios_Rango AS (
    SELECT
        TRY_CAST(ID_Producto AS INT)              AS ID_Producto,
        TRY_CONVERT(date, Vigencia_Desde, 23)     AS Vigencia_Desde,
        ISNULL(
            DATEADD(day, -1,
                LEAD(TRY_CONVERT(date, Vigencia_Desde, 23)) OVER (
                    PARTITION BY TRY_CAST(ID_Producto AS INT)
                    ORDER BY TRY_CONVERT(date, Vigencia_Desde, 23)
                )
            ),
            '9999-12-31'
        )                                         AS Vigencia_Hasta,
        TRY_CAST(Precio_Lista AS DECIMAL(12,2))   AS Precio_Lista
    FROM dbo.raw_Precios
)
INSERT INTO dbo.Fact_Ventas (
    ID_Venta, ID_Pedido, Fecha_Venta, ID_Producto, ID_Tienda, Segmento,
    Cantidad, Precio_Unitario, Precio_Lista_Vigente, Costo_Unitario,
    Facturacion, Costo_Total, Margen_Bruto, Margen_Porcentaje, Descuento_Porcentaje
)
SELECT
    v.ID_Venta,
    v.ID_Pedido,
    v.Fecha                                   AS Fecha_Venta,
    v.ID_Producto,
    v.ID_Tienda,
    v.Categoria_Venta                         AS Segmento,
    v.Cantidad,
    v.Precio_Unitario,
    p.Precio_Lista                            AS Precio_Lista_Vigente,
    c.Costo_Unitario,
    -- Facturacion = Cantidad * Precio_Unitario (precio REAL)
    CAST(v.Cantidad * v.Precio_Unitario AS DECIMAL(18,2)) AS Facturacion,
    -- Costo_Total = Cantidad * Costo_Unitario
    CAST(v.Cantidad * c.Costo_Unitario AS DECIMAL(18,2))  AS Costo_Total,
    -- Margen_Bruto = Facturacion - Costo_Total
    CAST(v.Cantidad * v.Precio_Unitario - v.Cantidad * c.Costo_Unitario AS DECIMAL(18,2)) AS Margen_Bruto,
    -- Margen_% = Margen_Bruto / Facturacion  (NULLIF por seguridad ante /0)
    CAST( (v.Cantidad * v.Precio_Unitario - v.Cantidad * c.Costo_Unitario)
          / NULLIF(v.Cantidad * v.Precio_Unitario, 0) AS DECIMAL(9,4)) AS Margen_Porcentaje,
    -- Descuento_% = 1 - (Precio_Unitario / Precio_Lista_Vigente)
    CAST( 1 - (v.Precio_Unitario / NULLIF(p.Precio_Lista, 0)) AS DECIMAL(9,4)) AS Descuento_Porcentaje
FROM dbo.clean_Ventas v
-- AS-OF de precio: 1 fila por línea (rangos sin solape -> sin fan-out)
LEFT JOIN Precios_Rango p
       ON p.ID_Producto = v.ID_Producto
      AND v.Fecha BETWEEN p.Vigencia_Desde AND p.Vigencia_Hasta
-- Costo del MES de la venta: ID_Producto + 'yyyy-MM' (grilla completa -> 1:1)
LEFT JOIN (
    SELECT
        TRY_CAST(ID_Producto AS INT)                             AS ID_Producto,
        Periodo,
        TRY_CAST(REPLACE(Costo_Unitario, ',', '.') AS DECIMAL(12,2)) AS Costo_Unitario
    FROM dbo.raw_Costos
) c
       ON c.ID_Producto = v.ID_Producto
      AND c.Periodo     = LEFT(CONVERT(char(10), v.Fecha, 23), 7);

/* ==============================================================================
   VALIDACIONES: movidas a 01_SQL/04_validations/03_validate_fact_sales.sql
   Este script solo crea/carga la tabla dbo.Fact_Ventas.
   ============================================================================== */

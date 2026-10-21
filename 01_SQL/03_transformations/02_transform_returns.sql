/* ==============================================================================
   PASO 4 - TRANSFORMACIÓN: DEVOLUCIONES  ->  dbo.Fact_Devoluciones
   Archivo: 01_SQL/03_transformations/02_transform_returns.sql
   ------------------------------------------------------------------------------
   Grano: 1 fila por ID_Devolucion (parte de dbo.clean_Devoluciones = 4.715).
   Agrega:
     - Fecha_Venta  -> LEFT JOIN a dbo.clean_Ventas por ID_Venta (NULL si huérfana)
     - Valor_Devuelto = Cantidad_Devuelta * Precio_Unitario
   Conserva flags Es_Huerfana / Es_Exceso_Devolucion y las 12 huérfanas.
   No modifica Fecha_Devolucion (incluidas las 99 de 2026). Sin % de devolución.
   clean_Ventas.ID_Venta es ÚNICO -> el JOIN es 1:1 (sin fan-out).
   ============================================================================== */

USE NexoRetail;
GO

/* ===============================  DDL  ====================================== */
DROP TABLE IF EXISTS dbo.Fact_Devoluciones;
CREATE TABLE dbo.Fact_Devoluciones (
    ID_Devolucion        INT,
    ID_Venta             INT,            -- referencia (puede no existir -> huérfana)
    Fecha_Devolucion     DATE,           -- real, se conserva (incluye 2026)
    Fecha_Venta          DATE,           -- desde clean_Ventas; NULL si huérfana
    ID_Producto          INT,            -- FK -> DimProducto
    ID_Tienda            INT,            -- FK -> DimTienda
    Cantidad_Devuelta    INT,
    Precio_Unitario      DECIMAL(12,2),
    Valor_Devuelto       DECIMAL(18,2),  -- Cantidad_Devuelta * Precio_Unitario
    Motivo               NVARCHAR(100),
    Categoria_Producto   NVARCHAR(50),
    Es_Huerfana          BIT,
    Es_Exceso_Devolucion BIT
);

/* ===============================  ETL  ====================================== */
INSERT INTO dbo.Fact_Devoluciones (
    ID_Devolucion, ID_Venta, Fecha_Devolucion, Fecha_Venta, ID_Producto, ID_Tienda,
    Cantidad_Devuelta, Precio_Unitario, Valor_Devuelto, Motivo, Categoria_Producto,
    Es_Huerfana, Es_Exceso_Devolucion
)
SELECT
    d.ID_Devolucion,
    d.ID_Venta,
    d.Fecha_Devolucion,
    v.Fecha                 AS Fecha_Venta,     -- NULL cuando la venta no existe
    d.ID_Producto,
    d.ID_Tienda,
    d.Cantidad_Devuelta,
    d.Precio_Unitario,
    CAST(d.Cantidad_Devuelta * d.Precio_Unitario AS DECIMAL(18,2)) AS Valor_Devuelto,
    d.Motivo,
    d.Categoria_Producto,
    d.Es_Huerfana,
    d.Es_Exceso_Devolucion
FROM dbo.clean_Devoluciones d
LEFT JOIN dbo.clean_Ventas v
       ON v.ID_Venta = d.ID_Venta;   -- clean_Ventas.ID_Venta único -> 1:1

/* ==============================================================================
   VALIDACIONES: movidas a 01_SQL/04_validations/04_validate_fact_returns.sql
   Este script solo crea/carga la tabla dbo.Fact_Devoluciones.
   ============================================================================== */

/* ==============================================================================
   DIMENSIÓN: DimTienda   ->  dbo.DimTienda
   Archivo: 01_SQL/03_transformations/06_create_dim_tienda.sql
   ------------------------------------------------------------------------------
   Tiendas físicas y online para el modelo analítico (consumo en Power BI).
   Grano: 1 fila por ID_Tienda.  Esperado: 21 tiendas (IDs 1 a 21).
   Fuente: dbo.clean_Ventas (país canónico y canal ya resueltos: 19/20/21 = Online).
   Nota: al ejecutar con sqlcmd usar -f 65001 (literales acentuados en validaciones).
   ============================================================================== */

USE NexoRetail;
GO

/* ------------------------------- 1) TABLA ---------------------------------- */
DROP TABLE IF EXISTS dbo.DimTienda;
CREATE TABLE dbo.DimTienda (
    ID_Tienda     INT NOT NULL,
    Nombre_Tienda NVARCHAR(100),
    Pais          NVARCHAR(50),
    Canal_Venta   NVARCHAR(10)
);

/* ------------------------------- 2) CARGA ---------------------------------- */
INSERT INTO dbo.DimTienda (ID_Tienda, Nombre_Tienda, Pais, Canal_Venta)
SELECT
    ID_Tienda,
    MIN(Nombre_Tienda)    AS Nombre_Tienda,
    MIN(Ubicacion_Tienda) AS Pais,
    MIN(Canal_Venta)      AS Canal_Venta
FROM dbo.clean_Ventas
GROUP BY ID_Tienda;

/* ==============================================================================
   VALIDACIONES: movidas a 01_SQL/04_validations/06_validate_dimensions.sql
   Este script solo crea/carga la tabla dbo.DimTienda.
   ============================================================================== */

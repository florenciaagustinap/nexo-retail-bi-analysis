/* ==============================================================================
   DIMENSIÓN: DimProducto   ->  dbo.DimProducto
   Archivo: 01_SQL/03_transformations/05_create_dim_producto.sql
   ------------------------------------------------------------------------------
   Catálogo de productos para el modelo analítico (consumo en Power BI).
   Grano: 1 fila por ID_Producto.  Esperado: 101 productos.
   Fuente: dbo.clean_Ventas (categoría ya estandarizada). Se toma un valor por
   producto con MIN() para garantizar 1 fila por ID.
   Nota: al ejecutar con sqlcmd usar -f 65001 (literales acentuados en validaciones).
   ============================================================================== */

USE NexoRetail;
GO

/* ------------------------------- 1) TABLA ---------------------------------- */
DROP TABLE IF EXISTS dbo.DimProducto;
CREATE TABLE dbo.DimProducto (
    ID_Producto           INT NOT NULL,
    Nombre_Producto       NVARCHAR(150),
    Categoria_Producto    NVARCHAR(50),
    Subcategoria_Producto NVARCHAR(100)
);

/* ------------------------------- 2) CARGA ---------------------------------- */
INSERT INTO dbo.DimProducto (ID_Producto, Nombre_Producto, Categoria_Producto, Subcategoria_Producto)
SELECT
    ID_Producto,
    MIN(Nombre_Producto)       AS Nombre_Producto,
    MIN(Categoria_Producto)    AS Categoria_Producto,
    MIN(Subcategoria_Producto) AS Subcategoria_Producto
FROM dbo.clean_Ventas
GROUP BY ID_Producto;

/* ==============================================================================
   VALIDACIONES: movidas a 01_SQL/04_validations/06_validate_dimensions.sql
   Este script solo crea/carga la tabla dbo.DimProducto.
   ============================================================================== */

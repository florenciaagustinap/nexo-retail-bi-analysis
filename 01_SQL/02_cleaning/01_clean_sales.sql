/* ==============================================================================
   PASO 3 - Limpieza de VENTAS
   Archivo: 01_SQL/02_cleaning/01_clean_sales.sql
   ------------------------------------------------------------------------------
   Crea dbo.clean_Ventas a partir de dbo.raw_Ventas aplicando SOLO las reglas de
   limpieza acordadas para Ventas (reglas 1-3). NO hay cálculos de negocio ni
   métricas (Facturación, Costo, Margen, etc. se harán en el Paso 4).

   Reglas aplicadas:
     1) Eliminar duplicados exactos de Ventas (241 filas sobrantes -> 80.295).
     2) Estandarizar país (Ubicacion_Tienda/Ubicacion_Cliente) y Categoria_Producto
        mediante TRIM + normalización de las variantes detectadas en el profiling.
     3) Resolver Canal_Venta por ID_Tienda: 19, 20 y 21 = Online; el resto = Offline.

   Las devoluciones (reglas 4-5: huérfanas, excesos y flags) se tratan aparte en
   02_clean_returns.sql. Precios, Costos y Objetivos NO se tocan aquí (regla 6).

   Entorno: localhost\SQLEXPRESS01 | base NexoRetail
   ============================================================================== */

USE NexoRetail;
GO

/* ==============================================================================
   1) CREACIÓN DE LA TABLA LIMPIA
   ------------------------------------------------------------------------------
   Tipos ya convertidos (INT / DATE / DECIMAL) porque el RAW venía como NVARCHAR.
   El tipado es parte de la limpieza, no una transformación de negocio.
   ============================================================================== */
DROP TABLE IF EXISTS dbo.clean_Ventas;
CREATE TABLE dbo.clean_Ventas (
    ID_Venta              INT,
    ID_Pedido             INT,
    Fecha                 DATE,
    ID_Producto           INT,
    ID_Cliente            INT,
    ID_Tienda             INT,
    Cantidad              INT,
    Precio_Unitario       DECIMAL(12,2),
    Canal_Venta           NVARCHAR(10),    -- resuelto por ID_Tienda (regla 3)
    Categoria_Venta       NVARCHAR(20),    -- segmento Retail/Wholesale (solo TRIM)
    Nombre_Cliente        NVARCHAR(150),
    Ubicacion_Cliente     NVARCHAR(50),    -- país canónico (regla 2)
    Nombre_Tienda         NVARCHAR(100),
    Ubicacion_Tienda      NVARCHAR(50),    -- país canónico (regla 2)
    Nombre_Producto       NVARCHAR(150),
    Categoria_Producto    NVARCHAR(50),    -- categoría canónica (regla 2)
    Subcategoria_Producto NVARCHAR(100)
);

/* ==============================================================================
   2) INSERCIÓN / TRANSFORMACIÓN
   ------------------------------------------------------------------------------
   - Dedup con ROW_NUMBER() quedándose con una fila por ID_Venta. Es seguro
     porque el profiling [3] confirmó que los duplicados son EXACTOS (todas las
     columnas iguales), así que cualquier fila del grupo es idéntica.
   - País: TRIM + CASE a {México, Brasil, Italia}. Se listan ambas formas con y
     sin acento para no depender de la sensibilidad a acentos del collation.
   - Categoría: TRIM + CASE a {Electrónica, Muebles, Ropa, Alimentos}.
   - Canal: ID_Tienda IN (19,20,21) -> Online ; resto -> Offline.
   ============================================================================== */
WITH Ventas_Dedup AS (
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY ID_Venta ORDER BY ID_Venta) AS rn
    FROM dbo.raw_Ventas
)
INSERT INTO dbo.clean_Ventas (
    ID_Venta, ID_Pedido, Fecha, ID_Producto, ID_Cliente, ID_Tienda,
    Cantidad, Precio_Unitario, Canal_Venta, Categoria_Venta,
    Nombre_Cliente, Ubicacion_Cliente, Nombre_Tienda, Ubicacion_Tienda,
    Nombre_Producto, Categoria_Producto, Subcategoria_Producto
)
SELECT
    TRY_CAST(ID_Venta    AS INT),
    TRY_CAST(ID_Pedido   AS INT),
    TRY_CONVERT(date, Fecha, 23),
    TRY_CAST(ID_Producto AS INT),
    TRY_CAST(ID_Cliente  AS INT),
    TRY_CAST(ID_Tienda   AS INT),
    TRY_CAST(Cantidad    AS INT),
    TRY_CAST(Precio_Unitario AS DECIMAL(12,2)),
    -- Regla 3: canal por tienda
    CASE WHEN TRY_CAST(ID_Tienda AS INT) IN (19, 20, 21) THEN 'Online' ELSE 'Offline' END,
    -- Segmento (solo TRIM, no se normaliza en esta etapa)
    LTRIM(RTRIM(Categoria_Venta)),
    LTRIM(RTRIM(Nombre_Cliente)),
    -- Regla 2: país canónico (cliente)
    CASE
        WHEN UPPER(LTRIM(RTRIM(Ubicacion_Cliente))) IN ('MEXICO', 'MÉXICO') THEN 'México'
        WHEN UPPER(LTRIM(RTRIM(Ubicacion_Cliente))) IN ('BRASIL', 'BRAZIL') THEN 'Brasil'
        WHEN UPPER(LTRIM(RTRIM(Ubicacion_Cliente))) IN ('ITALIA', 'ITALY')  THEN 'Italia'
        ELSE LTRIM(RTRIM(Ubicacion_Cliente))
    END,
    LTRIM(RTRIM(Nombre_Tienda)),
    -- Regla 2: país canónico (tienda)
    CASE
        WHEN UPPER(LTRIM(RTRIM(Ubicacion_Tienda))) IN ('MEXICO', 'MÉXICO') THEN 'México'
        WHEN UPPER(LTRIM(RTRIM(Ubicacion_Tienda))) IN ('BRASIL', 'BRAZIL') THEN 'Brasil'
        WHEN UPPER(LTRIM(RTRIM(Ubicacion_Tienda))) IN ('ITALIA', 'ITALY')  THEN 'Italia'
        ELSE LTRIM(RTRIM(Ubicacion_Tienda))
    END,
    LTRIM(RTRIM(Nombre_Producto)),
    -- Regla 2: categoría canónica
    CASE
        WHEN UPPER(LTRIM(RTRIM(Categoria_Producto))) IN ('ELECTRONICA', 'ELECTRÓNICA') THEN 'Electrónica'
        WHEN UPPER(LTRIM(RTRIM(Categoria_Producto))) = 'MUEBLES'   THEN 'Muebles'
        WHEN UPPER(LTRIM(RTRIM(Categoria_Producto))) = 'ROPA'      THEN 'Ropa'
        WHEN UPPER(LTRIM(RTRIM(Categoria_Producto))) = 'ALIMENTOS' THEN 'Alimentos'
        ELSE LTRIM(RTRIM(Categoria_Producto))
    END,
    LTRIM(RTRIM(Subcategoria_Producto))
FROM Ventas_Dedup
WHERE rn = 1;

/* ==============================================================================
   VALIDACIONES: movidas a 01_SQL/04_validations/01_validate_clean_sales.sql
   Este script solo prepara/crea la tabla dbo.clean_Ventas.
   ============================================================================== */

/* ==============================================================================
   PASO 3 - Limpieza de DEVOLUCIONES
   Archivo: 01_SQL/02_cleaning/02_clean_returns.sql
   ------------------------------------------------------------------------------
   Crea dbo.clean_Devoluciones a partir de dbo.raw_Devoluciones. Tipa y estandariza
   SIN eliminar información problemática: las huérfanas y los excesos se CONSERVAN
   y se marcan con flags. No hay métricas de negocio (Valor_Devuelto, Fecha_Venta,
   % devolución se harán en el Paso 4). No se toca ninguna tabla RAW.

   Reglas aplicadas:
     2) Tipado: ID_Venta, Fecha_Devolucion, ID_Tienda, ID_Producto,
        Categoria_Producto, Cantidad_Devuelta, Precio_Unitario.
     3) Categoria_Producto canónica: {Electrónica, Muebles, Ropa, Alimentos}
        (mismas reglas que en Ventas).
     4) Se conservan las 4.715 devoluciones (sin dedup: ID_Devolucion es único).
     5) Es_Huerfana = 1 si ID_Venta no existe en dbo.clean_Ventas (esperado 12).
     6) Es_Exceso_Devolucion = 1 si Cantidad_Devuelta > cantidad vendida (esperado 8).
     7/8) No se elimina ninguna huérfana ni exceso.
     9) Devoluciones 2026: se conserva la Fecha_Devolucion real (no se altera).

   Nota de ejecución: el script tiene un literal acentuado ('Electrónica'). Si se
   corre con sqlcmd, usar  -f 65001  (leer el archivo como UTF-8). Desde la
   extensión mssql de VS Code o SSMS no hace falta.

   Entorno: localhost\SQLEXPRESS01 | base NexoRetail
   ============================================================================== */

USE NexoRetail;
GO

/* ==============================================================================
   1) CREACIÓN DE LA TABLA LIMPIA
   ------------------------------------------------------------------------------
   Solo las columnas necesarias para el análisis de devoluciones. Las dimensiones
   (país, nombres) se resuelven por ID_Producto / ID_Tienda contra las dims del
   modelo; no se duplican acá. Fecha_Venta y Valor_Devuelto llegan en el Paso 4.
   ============================================================================== */
DROP TABLE IF EXISTS dbo.clean_Devoluciones;
CREATE TABLE dbo.clean_Devoluciones (
    ID_Devolucion        INT,
    ID_Venta             INT,            -- referencia a la línea de venta (puede no existir -> huérfana)
    Fecha_Devolucion     DATE,           -- parseada dd/MM/yyyy; se conserva real (incluye 2026)
    ID_Producto          INT,
    ID_Tienda            INT,
    Cantidad_Devuelta    INT,
    Precio_Unitario      DECIMAL(12,2),
    Categoria_Producto   NVARCHAR(50),   -- canónica (regla 3)
    Motivo               NVARCHAR(100),  -- se conserva para análisis de P4
    Es_Huerfana          BIT,            -- regla 5
    Es_Exceso_Devolucion BIT             -- regla 6
);

/* ==============================================================================
   2) INSERCIÓN / TRANSFORMACIÓN
   ------------------------------------------------------------------------------
   - LEFT JOIN a dbo.clean_Ventas por ID_Venta. clean_Ventas tiene ID_Venta ÚNICO
     (deduplicado y validado = 0 duplicados), por lo que el JOIN es 1:1 y NO
     produce fan-out: cada devolución genera exactamente una fila.
   - Es_Huerfana: la venta no existe -> v.ID_Venta IS NULL.
   - Es_Exceso_Devolucion: Cantidad_Devuelta > Cantidad vendida. En huérfanas
     v.Cantidad es NULL, la comparación da "desconocido" y queda en 0 (correcto:
     sin venta asociada no hay exceso que medir).
   - Fecha_Devolucion con estilo 103 (dd/MM/yyyy); las de 2026 quedan tal cual.
   ============================================================================== */
INSERT INTO dbo.clean_Devoluciones (
    ID_Devolucion, ID_Venta, Fecha_Devolucion, ID_Producto, ID_Tienda,
    Cantidad_Devuelta, Precio_Unitario, Categoria_Producto, Motivo,
    Es_Huerfana, Es_Exceso_Devolucion
)
SELECT
    TRY_CAST(d.ID_Devolucion AS INT),
    TRY_CAST(d.ID_Venta      AS INT),
    TRY_CONVERT(date, d.Fecha, 103),
    TRY_CAST(d.ID_Producto   AS INT),
    TRY_CAST(d.ID_Tienda     AS INT),
    TRY_CAST(d.Cantidad_Devuelta AS INT),
    TRY_CAST(d.Precio_Unitario   AS DECIMAL(12,2)),
    -- Regla 3: categoría canónica (igual que en Ventas)
    CASE
        WHEN UPPER(LTRIM(RTRIM(d.Categoria_Producto))) IN ('ELECTRONICA', 'ELECTRÓNICA') THEN 'Electrónica'
        WHEN UPPER(LTRIM(RTRIM(d.Categoria_Producto))) = 'MUEBLES'   THEN 'Muebles'
        WHEN UPPER(LTRIM(RTRIM(d.Categoria_Producto))) = 'ROPA'      THEN 'Ropa'
        WHEN UPPER(LTRIM(RTRIM(d.Categoria_Producto))) = 'ALIMENTOS' THEN 'Alimentos'
        ELSE LTRIM(RTRIM(d.Categoria_Producto))
    END,
    LTRIM(RTRIM(d.Motivo)),
    -- Regla 5: huérfana
    CASE WHEN v.ID_Venta IS NULL THEN 1 ELSE 0 END,
    -- Regla 6: exceso (0 también para huérfanas, por no tener venta que comparar)
    CASE WHEN TRY_CAST(d.Cantidad_Devuelta AS INT) > v.Cantidad THEN 1 ELSE 0 END
FROM dbo.raw_Devoluciones d
LEFT JOIN dbo.clean_Ventas v
       ON v.ID_Venta = TRY_CAST(d.ID_Venta AS INT);

/* ==============================================================================
   VALIDACIONES: movidas a 01_SQL/04_validations/02_validate_clean_returns.sql
   Este script solo prepara/crea la tabla dbo.clean_Devoluciones.
   ============================================================================== */

/* ==============================================================================
   DIMENSIÓN: DimFecha   ->  dbo.DimFecha
   Archivo: 01_SQL/03_transformations/04_create_dim_fecha.sql
   ------------------------------------------------------------------------------
   Calendario para el modelo analítico (consumo en Power BI).
   Grano: 1 fila por día.  Rango: 2024-01-01 a 2026-01-31 (762 días).
   El rango llega a enero 2026 para cubrir las devoluciones de 2026.
   Nombre de mes en español vía CASE (no depende del idioma del servidor).
   ============================================================================== */

USE NexoRetail;
GO

/* ------------------------------- 1) TABLA ---------------------------------- */
DROP TABLE IF EXISTS dbo.DimFecha;
CREATE TABLE dbo.DimFecha (
    Fecha            DATE NOT NULL,
    Anio             INT,
    Mes_Numero       INT,
    Mes              NVARCHAR(15),
    Anio_Mes         CHAR(7),
    Trimestre        CHAR(2),
    Trimestre_Numero INT,
    Inicio_Mes       DATE
);

/* ------------------------------- 2) CARGA ---------------------------------- */
-- Calendario recursivo. MAXRECURSION 0 porque son 762 días (> 100 por defecto).
WITH Calendario AS (
    SELECT CAST('2024-01-01' AS DATE) AS Fecha
    UNION ALL
    SELECT DATEADD(day, 1, Fecha) FROM Calendario WHERE Fecha < '2026-01-31'
)
INSERT INTO dbo.DimFecha (Fecha, Anio, Mes_Numero, Mes, Anio_Mes, Trimestre, Trimestre_Numero, Inicio_Mes)
SELECT
    Fecha,
    YEAR(Fecha),
    MONTH(Fecha),
    CASE MONTH(Fecha)
        WHEN 1 THEN 'Enero'      WHEN 2  THEN 'Febrero'   WHEN 3  THEN 'Marzo'
        WHEN 4 THEN 'Abril'      WHEN 5  THEN 'Mayo'      WHEN 6  THEN 'Junio'
        WHEN 7 THEN 'Julio'      WHEN 8  THEN 'Agosto'    WHEN 9  THEN 'Septiembre'
        WHEN 10 THEN 'Octubre'   WHEN 11 THEN 'Noviembre' WHEN 12 THEN 'Diciembre'
    END,
    LEFT(CONVERT(char(10), Fecha, 23), 7),
    'T' + CAST(DATEPART(quarter, Fecha) AS CHAR(1)),
    DATEPART(quarter, Fecha),
    DATEFROMPARTS(YEAR(Fecha), MONTH(Fecha), 1)
FROM Calendario
OPTION (MAXRECURSION 0);

/* ==============================================================================
   VALIDACIONES: movidas a 01_SQL/04_validations/06_validate_dimensions.sql
   Este script solo crea/carga la tabla dbo.DimFecha.
   ============================================================================== */

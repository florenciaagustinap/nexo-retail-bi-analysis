/* ==============================================================================
   PASO 4 - TRANSFORMACIÓN: OBJETIVOS  ->  dbo.Fact_Objetivos
   Archivo: 01_SQL/03_transformations/03_transform_objectives.sql
   ------------------------------------------------------------------------------
   Grano: 1 fila por (Periodo, ID_Tienda). Parte de dbo.raw_Objetivos (= 246).
   Tipado:
     - Periodo (yyyy-MM, texto) -> Fecha_Mes = primer día del mes (DATE)
     - ID_Tienda -> INT
     - Objetivo_Ventas -> DECIMAL(12,2)
   No calcula cumplimiento. Objetivos SOLO 2025. La tienda 18 tiene 6 meses:
   NO se completan los 6 faltantes ni se elimina la tienda.
   ============================================================================== */

USE NexoRetail;
GO

/* ===============================  DDL  ====================================== */
DROP TABLE IF EXISTS dbo.Fact_Objetivos;
CREATE TABLE dbo.Fact_Objetivos (
    Periodo         CHAR(7),          -- 'yyyy-MM' original (legibilidad)
    Fecha_Mes       DATE,             -- primer día del mes -> FK a DimFecha
    ID_Tienda       INT,              -- FK -> DimTienda
    Objetivo_Ventas DECIMAL(12,2)
);

/* ===============================  ETL  ====================================== */
INSERT INTO dbo.Fact_Objetivos (Periodo, Fecha_Mes, ID_Tienda, Objetivo_Ventas)
SELECT
    o.Periodo,
    CONVERT(date, o.Periodo + '-01')                 AS Fecha_Mes,   -- primer día del mes
    TRY_CAST(o.ID_Tienda AS INT)                     AS ID_Tienda,
    TRY_CAST(o.Objetivo_Ventas AS DECIMAL(12,2))     AS Objetivo_Ventas
FROM dbo.raw_Objetivos o;

/* ==============================================================================
   VALIDACIONES: movidas a 01_SQL/04_validations/05_validate_fact_objectives.sql
   Este script solo crea/carga la tabla dbo.Fact_Objetivos.
   ============================================================================== */

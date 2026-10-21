/* ==============================================================================
   PASO 1 - Carga cruda de los CSV   |   Nexo Retail - Solución BI (SQL Server)
   Archivo: 01_SQL/01_exploration/01_load_raw.sql
   ------------------------------------------------------------------------------
   Objetivo: cargar los 5 CSV "tal cual" en tablas raw_ (todas NVARCHAR),
             SIN transformaciones. El tipado y la limpieza son en pasos siguientes.

   Características de los archivos (verificadas): UTF-8 sin BOM, fin de línea CRLF,
   separador ',' en todos excepto Costos.csv que usa ';'.

   ENTORNO (verificado):
     - Instancia:  localhost\SQLEXPRESS01  (SQL Server 2025 Express, v17.0)
     - Base:       NexoRetail
     - Auth:       Windows

   REQUISITOS antes de ejecutar:
     1) Ejecutar conectado a NexoRetail (hay un USE NexoRetail; abajo).
     2) Rutas de CSV: ABSOLUTAS y literales (BULK INSERT las resuelve en el
        servidor; no admite rutas relativas). Ajustar si movés el repo.
     3) La cuenta de servicio de SQLEXPRESS01 debe tener permiso de LECTURA
        sobre la carpeta data\raw.
     4) Se ejecuta SIN SQLCMD Mode: corre tal cual desde la extensión mssql de
        VS Code, SSMS o sqlcmd.
     5) SQL Server 2017+ (por FORMAT='CSV', necesario por comillas internas de
        Nombre_Producto, p. ej.  "Monitor 27""").
   ============================================================================== */

USE NexoRetail;
GO

/* ------------------------------------------------------------------------------
   1) Crear las 5 tablas raw_ (todo NVARCHAR). BULK INSERT carga por POSICIÓN,
      así que los nombres de columna pueden ser ASCII aunque el CSV tenga acentos.
   ------------------------------------------------------------------------------ */

DROP TABLE IF EXISTS dbo.raw_Ventas;
CREATE TABLE dbo.raw_Ventas (
    ID_Venta              NVARCHAR(50),
    ID_Pedido             NVARCHAR(50),
    Fecha                 NVARCHAR(20),
    ID_Producto           NVARCHAR(50),
    ID_Cliente            NVARCHAR(50),
    ID_Tienda             NVARCHAR(50),
    Cantidad              NVARCHAR(50),
    Precio_Unitario       NVARCHAR(50),
    Canal_Venta           NVARCHAR(20),
    Categoria_Venta       NVARCHAR(50),
    Nombre_Cliente        NVARCHAR(150),
    Ubicacion_Cliente     NVARCHAR(100),
    Nombre_Tienda         NVARCHAR(100),
    Ubicacion_Tienda      NVARCHAR(100),
    Nombre_Producto       NVARCHAR(150),
    Categoria_Producto    NVARCHAR(100),
    Subcategoria_Producto NVARCHAR(100)
);

DROP TABLE IF EXISTS dbo.raw_Devoluciones;
CREATE TABLE dbo.raw_Devoluciones (
    ID_Devolucion       NVARCHAR(50),
    ID_Venta            NVARCHAR(50),
    Fecha               NVARCHAR(20),
    ID_Producto         NVARCHAR(50),
    ID_Cliente          NVARCHAR(50),
    ID_Tienda           NVARCHAR(50),
    Cantidad_Devuelta   NVARCHAR(50),
    Motivo              NVARCHAR(100),
    Precio_Unitario     NVARCHAR(50),
    Nombre_Cliente      NVARCHAR(150),
    Ubicacion_Cliente   NVARCHAR(100),
    Nombre_Tienda       NVARCHAR(100),
    Ubicacion_Tienda    NVARCHAR(100),
    Nombre_Producto     NVARCHAR(150),
    Categoria_Producto  NVARCHAR(100)
);

DROP TABLE IF EXISTS dbo.raw_Precios;
CREATE TABLE dbo.raw_Precios (
    ID_Producto     NVARCHAR(50),
    Vigencia_Desde  NVARCHAR(20),
    Precio_Lista    NVARCHAR(50)
);

DROP TABLE IF EXISTS dbo.raw_Costos;
CREATE TABLE dbo.raw_Costos (
    Periodo         NVARCHAR(20),
    ID_Producto     NVARCHAR(50),
    Costo_Unitario  NVARCHAR(50)
);

DROP TABLE IF EXISTS dbo.raw_Objetivos;
CREATE TABLE dbo.raw_Objetivos (
    Periodo         NVARCHAR(20),
    ID_Tienda       NVARCHAR(50),
    Objetivo_Ventas NVARCHAR(50)
);

/* ------------------------------------------------------------------------------
   2) Cargar los CSV. Parámetros:
        FORMAT='CSV', FIELDQUOTE='"'  -> respeta comillas internas
        FIRSTROW=2                    -> saltea el encabezado
        FIELDTERMINATOR=','           -> (Costos usa ';')
        ROWTERMINATOR='0x0d0a'        -> fin de línea CRLF (Windows)
        CODEPAGE='65001'              -> UTF-8
   Nota: ROWTERMINATOR='0x0d0a' porque los archivos son CRLF (verificado). Evita
         que la última columna de cada tabla quede con un \r (CHAR(13)). Si algún
         archivo fuera LF-only, usar '0x0a'.
   ------------------------------------------------------------------------------ */

BULK INSERT dbo.raw_Ventas
FROM 'C:\Users\Agustina\Desktop\Ingenieria de datos\Nexo-Retail-BI-Challenge\data\raw\Ventas.csv'
WITH (FORMAT='CSV', FIELDQUOTE='"', FIRSTROW=2,
      FIELDTERMINATOR=',', ROWTERMINATOR='0x0d0a', CODEPAGE='65001', TABLOCK);

BULK INSERT dbo.raw_Devoluciones
FROM 'C:\Users\Agustina\Desktop\Ingenieria de datos\Nexo-Retail-BI-Challenge\data\raw\Devoluciones.csv'
WITH (FORMAT='CSV', FIELDQUOTE='"', FIRSTROW=2,
      FIELDTERMINATOR=',', ROWTERMINATOR='0x0d0a', CODEPAGE='65001', TABLOCK);

BULK INSERT dbo.raw_Precios
FROM 'C:\Users\Agustina\Desktop\Ingenieria de datos\Nexo-Retail-BI-Challenge\data\raw\Precios.csv'
WITH (FORMAT='CSV', FIELDQUOTE='"', FIRSTROW=2,
      FIELDTERMINATOR=',', ROWTERMINATOR='0x0d0a', CODEPAGE='65001', TABLOCK);

BULK INSERT dbo.raw_Costos
FROM 'C:\Users\Agustina\Desktop\Ingenieria de datos\Nexo-Retail-BI-Challenge\data\raw\Costos.csv'
WITH (FORMAT='CSV', FIELDQUOTE='"', FIRSTROW=2,
      FIELDTERMINATOR=';', ROWTERMINATOR='0x0d0a', CODEPAGE='65001', TABLOCK);

BULK INSERT dbo.raw_Objetivos
FROM 'C:\Users\Agustina\Desktop\Ingenieria de datos\Nexo-Retail-BI-Challenge\data\raw\Objetivos.csv'
WITH (FORMAT='CSV', FIELDQUOTE='"', FIRSTROW=2,
      FIELDTERMINATOR=',', ROWTERMINATOR='0x0d0a', CODEPAGE='65001', TABLOCK);

/* ------------------------------------------------------------------------------
   3) Validaciones básicas de la carga
   ------------------------------------------------------------------------------ */

-- 3a) Cantidad de filas por tabla vs. esperado
SELECT 'raw_Ventas'       AS Tabla, COUNT(*) AS Filas, 80536 AS Esperado FROM dbo.raw_Ventas
UNION ALL SELECT 'raw_Devoluciones', COUNT(*), 4715  FROM dbo.raw_Devoluciones
UNION ALL SELECT 'raw_Precios',      COUNT(*), 641   FROM dbo.raw_Precios
UNION ALL SELECT 'raw_Costos',       COUNT(*), 2424  FROM dbo.raw_Costos
UNION ALL SELECT 'raw_Objetivos',    COUNT(*), 246   FROM dbo.raw_Objetivos;

-- 3b) Vistazo a los primeros registros (verificar columnas alineadas y acentos OK)
SELECT TOP 10 * FROM dbo.raw_Ventas;
SELECT TOP 10 * FROM dbo.raw_Devoluciones;
SELECT TOP 10 * FROM dbo.raw_Precios;
SELECT TOP 10 * FROM dbo.raw_Costos;
SELECT TOP 10 * FROM dbo.raw_Objetivos;

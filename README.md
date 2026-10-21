# Nexo Retail — BI & Data Analysis Challenge

Solución de **Business Intelligence / Data Analysis** para el challenge de Nexo Retail:
preparación de datos en **SQL Server**, modelo analítico en estrella y **dashboard
ejecutivo en Power BI**, con un informe final que responde las hipótesis de la dirección.

---

## Contexto

Nexo Retail es una cadena de retail que opera en **México, Brasil e Italia**, con cuatro
categorías de producto (**Electrónica, Muebles, Ropa y Alimentos**), dos canales de venta
(**Online / Offline**) y dos segmentos de cliente (**Retail / Wholesale**).

El análisis cubre el período **2024 y 2025** a partir de cinco archivos CSV de origen
(ventas, devoluciones, precios, costos y objetivos).

## Objetivo

Transformar los datos crudos entregados en un **modelo analítico confiable** y un
**dashboard ejecutivo en Power BI** que permita responder, con evidencia, las cuatro
afirmaciones planteadas por la dirección. El foco es Data Analysis / BI: calidad de datos,
modelado dimensional, métricas correctas e interpretación de negocio.

## Preguntas de negocio

El análisis evalúa cuatro afirmaciones de la dirección:

1. **En 2025 vendimos más que nunca, pero en algunas líneas ganamos menos.**
2. **Italia no está funcionando y habría que pensar en cerrar tiendas.**
3. **El online está desplazando a las tiendas físicas.**
4. **Las devoluciones están bajo control.**

## Stack

- **SQL Server** — base de datos para preparación y validación de los datos
- **SQL (T-SQL)** — exploración, limpieza, transformaciones y controles de calidad
- **Power BI** (formato PBIP / TMDL) — modelo semántico, medidas DAX y dashboard
- **Python** — profiling inicial de los datos
- **Jupyter Notebook** — documentación del profiling
- **Git / GitHub** — versionado del proyecto

## Arquitectura / flujo

```text
CSV
 ↓
SQL Server — Raw
 ↓
Data Cleaning & Transformation
 ↓
Modelo Analítico
 ↓
Power BI
 ↓
Executive Dashboard
```

- **CSV:** cinco archivos de origen (ventas, devoluciones, precios, costos, objetivos) en `data/raw/`.
- **SQL Server — Raw:** carga de los CSV a tablas en crudo (`BULK INSERT`) para perfilar el estado real de los datos.
- **Data Cleaning & Transformation:** estandarización (países, categorías, canal), deduplicación y marcado de anomalías (devoluciones huérfanas o en exceso), sin eliminar información de forma automática.
- **Modelo Analítico:** esquema en estrella con tres tablas de hechos (`Fact_Ventas`, `Fact_Devoluciones`, `Fact_Objetivos`) y tres dimensiones conformadas (`DimFecha`, `DimProducto`, `DimTienda`).
- **Power BI:** medidas DAX (ventas, margen %, tasa de devolución, cumplimiento de objetivo y comparativas interanuales) sobre el modelo semántico.
- **Executive Dashboard:** tres páginas (Resumen Ejecutivo, Diagnóstico de Negocio, Devoluciones y Objetivos) que responden las preguntas de negocio.

## Modelo de datos

Modelo en estrella, con la granularidad de cada hecho definida explícitamente para evitar
el doble conteo:

| Tabla | Tipo | Grano |
|---|---|---|
| `Fact_Ventas` | Hecho | Una fila por venta |
| `Fact_Devoluciones` | Hecho | Una fila por devolución |
| `Fact_Objetivos` | Hecho | Una fila por tienda y mes |
| `DimFecha` | Dimensión | Una fila por fecha |
| `DimProducto` | Dimensión | Una fila por producto |
| `DimTienda` | Dimensión | Una fila por tienda (incluye país y canal) |

## Principales resultados

Conclusiones del análisis (detalle y evidencia numérica en [`docs/informe.md`](docs/informe.md)):

| # | Afirmación | Veredicto |
|---|---|---|
| 1 | Vendimos más que nunca, pero en algunas líneas ganamos menos | **VERDADERO** |
| 2 | Italia no funciona, habría que cerrar tiendas | **PARCIALMENTE VERDADERO** |
| 3 | El online está desplazando a las tiendas físicas | **PARCIALMENTE VERDADERO** |
| 4 | Las devoluciones están bajo control | **FALSO** |

En síntesis: en 2025 las ventas crecieron **+20,5%** (mayor nivel dentro del período
analizado 2024–2025), con el margen global en leve mejora pero una caída de rentabilidad
en Electrónica; Italia cae en ventas aunque conserva buen margen; el Online crece con
fuerza sin que el Offline retroceda; y las devoluciones aumentan más rápido que las ventas.

## Estructura del repositorio

```text
Nexo-Retail-BI-Challenge/
├── 01_SQL/
│   ├── 01_exploration/        # Carga RAW y profiling en SQL
│   ├── 02_cleaning/           # Limpieza de ventas y devoluciones
│   ├── 03_transformations/    # Hechos y dimensiones (modelo estrella)
│   └── 04_validations/        # Controles de calidad e integridad
├── 02_POWER_BI/
│   ├── NexoRetail.Report/         # Definición del informe (PBIP / PBIR)
│   ├── NexoRetail.SemanticModel/  # Modelo semántico (TMDL: tablas y medidas)
│   ├── NexoRetail.pbip
│   ├── docs/                      # (reservado)
│   └── screenshots/               # (reservado para capturas del dashboard)
├── analysis/
│   └── 01_data_profiling.ipynb    # Profiling inicial en Python
├── data/
│   └── raw/                        # CSV de origen
├── docs/
│   ├── informe.md                  # Informe final (Markdown)
│   └── informe_nexo_retail.pdf     # Informe final (PDF, 6 páginas)
└── README.md
```

## Cómo explorar el proyecto

1. **Capa SQL:** los scripts en `01_SQL/` están numerados por etapa (exploración → limpieza
   → transformaciones → validaciones) y se ejecutan en ese orden sobre una base de datos
   SQL Server, apuntando a los CSV de `data/raw/`.
2. **Power BI:** abrir `02_POWER_BI/NexoRetail.pbip` con Power BI Desktop (formato PBIP). El
   modelo y las medidas están en `NexoRetail.SemanticModel/` (TMDL) y el informe en
   `NexoRetail.Report/`.
3. **Informe:** leer [`docs/informe.md`](docs/informe.md) o el PDF
   [`docs/informe_nexo_retail.pdf`](docs/informe_nexo_retail.pdf) para el análisis completo
   y las respuestas a las afirmaciones.

## Autora

Florencia Agustina Parancan — proyecto de portfolio de Data Analysis / BI.

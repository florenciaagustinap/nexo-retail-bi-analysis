# Nexo Retail — Business Intelligence Challenge

## 1. Resumen Ejecutivo

En 2025, Nexo Retail alcanzó su mayor nivel de ventas dentro del período analizado (2024–2025): **US$20,03 M (+20,5%** vs 2024), con una mejora moderada del margen. El crecimiento fue **sólido pero desigual**: impulsado por Online, México y Brasil, con señales de alerta en Electrónica, Italia y devoluciones.

| Indicador | 2024 | 2025 | Variación |
|---|---:|---:|---:|
| **Ventas** | US$16,62 M | **US$20,03 M** | **+20,5%** |
| **Margen %** | 32,28% | **33,01%** | **+0,73 pp** |
| **Devoluciones** | US$673 K | **US$991 K** | **+47,3%** |
| **Cumplimiento de objetivo** | — | **117,4%** | — |

**Hallazgos clave**

- **Crecimiento:** ventas +20,5%; el margen global mejoró +0,73 pp (32,28% → 33,01%).
- **Rentabilidad:** Electrónica vendió +13,3% pero su margen cayó de 22,0% a 16,9%.
- **Canales:** Online creció +99,2% y aportó ~98,7% del crecimiento total; Offline se mantuvo estable (+0,3%) → no hay evidencia de canibalización.
- **Italia:** ventas −38,6% y menor productividad por tienda, pero con margen saludable (el mayor margen offline, 36,4%).
- **Devoluciones:** la tasa subió de 4,05% a 4,95% y el valor devuelto creció +47,3%, más rápido que las ventas.

> **El desafío para 2026 no es solo seguir creciendo, sino convertir ese crecimiento en rentabilidad sostenible, mejorar la productividad de Italia y controlar el aumento de las devoluciones.**

## 2. Datos y calidad

El análisis parte de cinco archivos CSV (Ventas, Devoluciones, Precios, Costos, Objetivos) correspondientes a 2024–2025; los importes se analizaron en **USD**. Se perfilaron con Python y los controles se revalidaron en SQL Server.

**Problemas detectados y tratamiento**

| Problema | Hallazgo | Tratamiento |
|---|---|---|
| Duplicados en ventas | 482 filas = 241 duplicados exactos | Se conservó un registro por venta |
| Canal de venta faltante | 340 registros sin canal | Determinado por `ID_Tienda` (19/20/21 = Online) |
| Países con distinta nomenclatura | Brasil/Brazil; México/Mexico/MEXICO; Italia/Italy | Estandarizados a un valor único |
| Categorías inconsistentes | Mayúsculas, acentos y espacios | Estandarizadas |
| Devoluciones sin venta asociada | 12 registros | Conservados y marcados (`Es_Huerfana`) |
| Devoluciones > cantidad vendida | 8 registros | Conservados y marcados (`Es_Exceso_Devolucion`) |
| Devoluciones de enero 2026 | 99, de ventas de diciembre 2025 | Conservadas con su fecha real; analizadas por cohorte de venta |
| Objetivos incompletos | 1 tienda con solo 6 meses de objetivos | Conservado y documentado |

**Criterio:** no se eliminó información ante cualquier anomalía. Se corrigió lo que podía resolverse de forma determinística y se **conservó y marcó** lo que debía quedar visible como señal de calidad. Tras la limpieza se ejecutaron **69 controles de validación** (unicidad de claves, integridad hecho–dimensión, cobertura de precios/costos/objetivos), todos satisfactorios.

## 3. Modelo y metodología

Se usó **SQL Server** para explorar, limpiar, transformar y validar los datos, y **Power BI** para el modelado, las métricas y la visualización.

**Modelo estrella:** tres tablas de hechos —`Fact_Ventas` (una fila por venta), `Fact_Devoluciones` (una por devolución) y `Fact_Objetivos` (una por tienda y mes)— y tres dimensiones conformadas —`DimFecha`, `DimProducto`, `DimTienda`—, con relaciones 1→muchos desde las dimensiones hacia los hechos. Definir la granularidad de cada hecho evita el doble conteo.

**Métricas principales:** Ventas, Ventas Netas, Margen Bruto, **Margen %**, Valor y **Tasa de Devolución %**, **Cumplimiento de Objetivo %**, más comparativas interanuales 2024 vs 2025.

**Criterios de cálculo:**

- Margen % = Margen Bruto / Ventas, sobre valores agregados (no se promedian porcentajes por venta).
- Devoluciones medidas por valor y por tasa (peso relativo sobre ventas).
- Cumplimiento calculado **solo** sobre períodos con objetivo definido, para no comparar ventas 2024 con objetivos que existen únicamente para 2025.

## 4. Dashboard y principales insights

El dashboard tiene tres páginas: **(1) Resumen Ejecutivo** — ¿cómo fue 2025 frente a 2024? (KPIs + segmentación por Segmento, Categoría, País y Canal); **(2) Diagnóstico de Negocio** — dónde se generó el crecimiento y dónde hay deterioro (categoría, país, productividad física, canal); **(3) Devoluciones y Objetivos** — tasa de devolución y cumplimiento mensual.

**Insights principales**

- **Crecimiento:** ventas US$16,62 M → US$20,03 M (**+20,5%**); margen 32,28% → 33,01%.
- **Electrónica:** ventas +13,3% pero margen de 22,01% a 16,87% (−5,14 pp; margen bruto ~−13,2%). Ropa, Muebles y Alimentos mejoraron su margen.
- **Países:** México +38,2%, Brasil +40,8%, Italia **−38,6%**. Productividad offline por tienda: Italia ~US$939 K vs ~US$1,67–1,69 M en Brasil y México, con margen italiano saludable.
- **Canales:** Online +99,2% (US$3,39 M → US$6,76 M), participación 20,4% → 33,7%, ~98,7% del crecimiento absoluto; Offline +0,3% (sin caída).
- **Devoluciones:** valor +47,3% (US$673 K → US$991 K), tasa 4,05% → 4,95%; mayores tasas en Ropa (7,18%) y Electrónica (5,48%).
- **Objetivos:** cumplimiento 2025 ~**117,4%**.

## 5. Respuesta a las 4 afirmaciones

### 1. “En 2025 vendimos más que nunca, pero siento que en algunas líneas ganamos menos.” — **VERDADERO**

Las ventas crecieron **+20,5%** (US$16,62 M → US$20,03 M). La afirmación «vendimos más que nunca» se evalúa dentro del período analizado: en 2025, Nexo Retail alcanzó el mayor nivel de ventas dentro del período analizado (2024–2025). En paralelo, **Electrónica** aumentó sus ventas +13,3% pero su margen cayó de **22,01% a 16,87%** (−5,14 pp; margen bruto ~−13,2%). Se vendió más, pero una línea clave perdió rentabilidad.

### 2. “Italia no está funcionando, habría que pensar en cerrar más tiendas.” — **PARCIALMENTE VERDADERO**

Italia cayó **−38,6%** en ventas y tiene la menor productividad por tienda (~US$939 K vs ~US$1,67–1,69 M en Brasil y México). Sin embargo, su margen es saludable (33,92% en 2025; el **mayor margen offline, 36,4%**) y sus unidades crecieron ~+14,7%. Hay una señal clara para revisar la operación italiana, pero cerrar tiendas requiere analizar cada tienda y producto (volumen, precios, mix, costos fijos); los datos disponibles no lo justifican por sí solos.

### 3. “El online nos está comiendo las tiendas físicas.” — **PARCIALMENTE VERDADERO**

Online creció **+99,2%** (US$3,39 M → US$6,76 M), su participación pasó de **20,4% a 33,7%** y explicó ~98,7% del crecimiento. Al mismo tiempo, Offline **no cayó** (+0,3%). Existe una fuerte migración/crecimiento hacia el canal digital, pero los datos **no permiten afirmar causalmente** que el Online esté canibalizando las tiendas físicas.

### 4. “Las devoluciones están bajo control.” — **FALSO**

El valor devuelto creció **+47,3%** (US$673 K → US$991 K) y la tasa pasó de **4,05% a 4,95%** (+0,90 pp), más rápido que las ventas (+20,5%). Se concentran en Ropa (**7,18%**) y Electrónica (**5,48%**). Requieren una acción específica.

## 6. Recomendaciones 2026 y uso de IA

**Recomendaciones (prioridad alta)**

1. **Recuperar la rentabilidad de Electrónica:** analizar por producto precios, descuentos, costos unitarios y mix para revertir la caída de margen (22,01% → 16,87%).
2. **Revisar Italia antes de decidir cierres:** evaluar tienda por tienda (ventas, margen, unidades, mix y costos fijos). Su margen saludable sugiere un problema de demanda/productividad más que de rentabilidad.
3. **Escalar el Online controlando las devoluciones:** sostener el crecimiento del canal (+99,2%) atacando los focos de devolución (Ropa y Electrónica, motivos por producto y canal).

**Uso de inteligencia artificial**

Se usaron Claude y ChatGPT como **apoyo** (estructuras de SQL, alternativas de modelado, revisión de medidas DAX, documentación y cuestionamiento de interpretaciones). Ninguna conclusión se adoptó solo por sugerencia de IA: todo se contrastó con consultas SQL, controles de calidad y resultados en Power BI. Dos ejemplos de validación:

- **Cumplimiento de Objetivo %:** la primera versión podía mezclar ventas de 2024 con objetivos definidos únicamente para 2025. Se corrigió para calcular el cumplimiento solo sobre períodos con objetivo (resultado 2025 ~**117,4%**).
- **Codificación SQL:** se detectó un problema al visualizar caracteres especiales; se corrigió ejecutando el script en **UTF-8**, sin modificar los datos originales.

## 7. Supuestos y limitaciones

**Supuestos**

- Los importes se interpretaron en **USD**, según la consigna.
- `Precio_Unitario` = precio efectivamente cobrado por unidad, incluyendo descuentos; las ventas se valuaron a ese precio real y los objetivos se compararon contra la venta bruta definida por el negocio.
- Las devoluciones se analizaron por **cohorte de venta** (fecha de venta); las de enero 2026 asociadas a ventas de diciembre 2025 se atribuyeron al período 2025.
- Las devoluciones sin venta asociada se conservaron, pero no se usaron para inferir atributos de una venta que no puede determinarse.

**Limitaciones**

- El período abarca solo 2024–2025, por lo que no puede afirmarse que 2025 fuera el mejor año histórico de la compañía, sino el de mayor venta dentro del período disponible.
- Decidir el cierre de tiendas en Italia requiere datos adicionales (costos fijos por tienda, alquileres, rentabilidad individual) de los que no se dispone.
- No es posible demostrar una relación causal de canibalización Online → Offline: se observa fuerte crecimiento del Online y estabilidad del Offline, no causalidad.
- El análisis de devoluciones identifica categorías, países y canales con mayor incidencia, pero no determina las causas raíz.
- Una tienda tiene solo seis meses de objetivos, por lo que su cumplimiento debe interpretarse con cautela.

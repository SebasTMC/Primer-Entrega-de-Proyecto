# Ejercicio 1.4 — El almacén asignado (Sismos) frente a las formas normales

Proyecto asignado: **Sistema de Visualización de Datos Sísmicos (`Seismic_Data_Geosciences` / Sismos)**  
Entorno analítico: Esquema dimensional (modelo estrella) sobre SQLite / almacén de datos sísmicos.

---

## 1. Análisis de formas normales por dimensión

En un almacén de datos sísmicos orientado a consultas analíticas (OLAP), las tablas de dimensiones se diseñan **desnormalizadas intencionalmente** (generalmente en **2FN**, rompiendo la **3FN**) para evitar múltiples reuniones (*joins*) en tiempo de consulta sobre catálogos históricos masivos.

| Dimensión (modelo estrella de Sismos) | Forma normal actual | Dependencia transitiva que conserva | Qué gana el almacén al conservarla |
| :--- | :---: | :--- | :--- |
| **Dimensión Tiempo** (`dim_tiempo`: `id_tiempo`, `fecha`, `anio`, `mes`, `nombre_mes`, `trimestre`, `dia_semana`) | **2FN** (no cumple 3FN) | `id_tiempo` $\to$ `fecha` $\to$ `{anio, mes, trimestre, dia_semana}` y `mes` $\to$ `nombre_mes`. | Permite agrupar sismos por año, mes o trimestre con una sola reunión (o filtro directo) sin calcular funciones de fecha ni unir jerarquías en copo de nieve. |
| **Dimensión Ubicación / Región** (`dim_ubicacion`: `id_ubicacion`, `latitud`, `longitud`, `ciudad_cercana`, `estado`, `region_sismica`, `pais`) | **2FN** (no cumple 3FN) | `id_ubicacion` $\to$ `ciudad_cercana` $\to$ `estado` $\to$ `region_sismica` $\to$ `pais`. | Acelera agregaciones geográficas y mapas de calor por estado o región sísmica en un único salto desde la tabla de hechos, reduciendo latencia en la visualización web. |
| **Dimensión Magnitud / Categoría** (`dim_magnitud`: `id_magnitud`, `magnitud`, `tipo_magnitud`, `escala_categoria`, `nivel_riesgo`) | **2FN** (no cumple 3FN) | `id_magnitud` $\to$ `escala_categoria` $\to$ `nivel_riesgo`. | Permite filtrar y etiquetar sismos por categoría (micro, menor, moderado, fuerte, mayor) de forma inmediata en tableros sin recalcular rangos en cada lectura. |
| **Tabla de Hechos** (`hechos_sismos` / `sismos`) | **3FN / BCNF** | Ninguna transitiva interna; almacena llaves foráneas a dimensiones y medidas numéricas (`magnitud`, `profundidad_km`). | Mantiene el registro atómico de cada evento sísmico sin duplicar descripciones textuales dentro de la tabla de hechos. |

*(Nota: Verificar los nombres exactos de tablas y columnas contra `SELECT name, sql FROM sqlite_master WHERE type='table';` en la consola SQLite integrada de la aplicación desplegada.)*

---

## 2. Cuándo conviene desnormalizar y qué vigilar en nuestro proyecto propio

Conviene desnormalizar únicamente en **escenarios de lectura intensiva y analítica** (como tableros históricos, reportes gerenciales o almacenes dimensionales donde los datos se cargan por lotes ETL y rara vez se modifican), porque sacrificar la 3FN elimina reuniones costosas y acelera las consultas agregadas. En cambio, en nuestro proyecto propio (`Proyecto_Primaria`), que es un sistema **transaccional (OLTP)** con inserciones y actualizaciones constantes de alumnos, grupos, pagos y recados, desnormalizar introduciría anomalías de actualización; si decidiéramos desnormalizar alguna vista o tabla resumen (por ejemplo, guardar el promedio general o el saldo de colegiaturas directo en `alumnos`), tendríamos que vigilar estrictamente la **consistencia mediante triggers o vistas materializadas**, controlar la duplicidad en cada `UPDATE`/`DELETE` y asegurarnos de que la tabla normalizada siga siendo la única fuente de verdad.
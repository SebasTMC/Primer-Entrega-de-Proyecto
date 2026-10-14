# Primer-Entrega-de-Proyecto
 
Este repositorio contiene los entregables correspondientes a la primera fase del proyecto de la asignatura. El trabajo está dividido en dos subproyectos principales, cada uno enfocado en resolver problemáticas distintas mediante el diseño de bases de datos y la implementación de sistemas.

## 📁 Estructura del Repositorio

El repositorio se organiza en los siguientes directorios:

* 📂 **`Proyecto_Primaria/`**
  Contiene el diseño de la arquitectura, reglas de negocio y los diagramas de base de datos (ER y Relacional) para un sistema integral de gestión escolar (operativa, académica y administrativa) diseñado para una primaria de alto volumen.
  > [📄 Ver documentación detallada del Proyecto Primaria](./Proyecto_Primaria/Documentacion.md)

* 📂 **`Proyecto_Fork/`**
  Contiene el análisis, configuración y despliegue del "Seismic Data Visualization System". En este subproyecto se trabaja con infraestructura basada en contenedores (Docker) y revisión de código de un repositorio externo (fork).
  > [📄 Ver documentación detallada del Proyecto Fork](./Proyecto_Fork/README.md)
 
---

# Sistema de Visualización de Datos Sísmicos y Módulos Analíticos

## 1. Enlaces del Proyecto Propio (GitHub Pages)
* **Landing Page / Demostración en vivo:** [https://sebastmc.github.io/Primer-Entrega-de-Proyecto/](https://sebastmc.github.io/Primer-Entrega-de-Proyecto/)
---
## 2. Proyecto Asignado (Fork)
* **Repositorio Fork:** [https://github.com/gabrielhuav/Seismic-Data-Visualization-System](https://github.com/gabrielhuav/Seismic-Data-Visualization-System)[cite: 8]
* **Versión Publicada:** [https://gabrielhuav.github.io/Seismic-Data-Visualization-System/](https://gabrielhuav.github.io/Seismic-Data-Visualization-System/)
---
## 3. Presentación del Equipo
* La presentación utilizada para la defensa y exposición de la práctica se encuentra disponible dentro del repositorio en la siguiente ruta: [`docs/Presentacion.pdf`](docs/Presentacion.pdf) *
---
## 4. Fichas de los Artículos Presentados

### Artículo 1: Sismos en México
* **Cita APA 7ª Edición:** Villa Vargas, J. M., Hurtado Avilés, G., & Climent Hernández, J. A. (2026). Cuando México tiembla: la historia contada por los datos. *Azcatl. Revista de divulgación en ciencias, ingeniería e innovación*, 4(6), 28–33[cite: 7, 27].
* **DOI:** [10.24275/AZC2026E1004](https://doi.org/10.24275/AZC2026E1004)[cite: 7]
* **Aporte principal al proyecto:** Definición de la arquitectura base del almacén de datos (Data Warehouse) con PostgreSQL, procesos ETL en Python y la integración visual geoespacial mediante OpenStreetMap[cite: 9, 10, 11].

### Artículo 2: Gestión del Agua (CDMX)
* **Cita APA 7ª Edición:** Velázquez Arrieta, E. U., Pulido Morales, O. F., García López, E., Hernández Martínez, C. A., & Hurtado Avilés, G. (2026). Territorial Information Retrieval from Heterogeneous Open Data through the Construction of a Data Warehouse for Water Management in Mexico City. 
* **DOI / Enlace:** Publicado en actas de investigación y analíticas 
* **Aporte principal al proyecto:** Adopción de la estrategia de despliegue dual, permitiendo mantener una versión estática interactiva orientada al cliente junto con la arquitectura relacional[cite: 16].

### Artículo 3: Obras Públicas y Monitoreo Geoespacial
* **Cita APA 7ª Edición:** González Casiano, U., Maldonado Mejía, M. T., & Hurtado Avilés, G. (2026). A Dimensional Data Warehouse for Geospatial Monitoring of Municipal Public Works, with an Evolution Path Toward a Lakehouse Architecture. .
* **DOI / Enlace:** Documento técnico y de investigación institucional 
* **Aporte principal al proyecto:** Implementación de Dimensiones de Cambio Lento (SCD Tipo 2) para asegurar la trazabilidad histórica y la auditoría de registros en el esquema dimensional[cite: 35, 36].

## 5. Integrantes y Distribución de Actividades
* **Sebastian:** Desarrollo y configuración del entorno de contenedores (Docker/PostgreSQL), validación del repositorio y estructuración técnica del sistema.
* **Bryan David:** Colaboración en el diseño de la arquitectura del proyecto, integración de scripts de procesamiento y despliegue colaborativo de las interfaces de visualización.
---

## Enlaces del Proyecto
* **Repositorio en GitHub:** [https://github.com/SebasTMC/Primer-Entrega-de-Proyecto](https://github.com/SebasTMC/Primer-Entrega-de-Proyecto)
* **Sitio Web (GitHub Pages):** [https://sebastmc.github.io/Primer-Entrega-de-Proyecto/](https://sebastmc.github.io/Primer-Entrega-de-Proyecto/)

---

## 🛠️ Tecnologías Generales Utilizadas
* **Modelado de Datos:** Diagramas de Entidad-Relación (ER) y Modelo Relacional extendido (EER).
* **Herramientas de Diseño:** Mermaid.js para diagramado como código.
* **Infraestructura:** Docker y Docker Compose (Subproyecto Fork).
* **Control de Versiones:** Git y GitHub.
 
---

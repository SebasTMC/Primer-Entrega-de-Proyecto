# Trabajo Individual — Prácticas 6, 7 y 8

**Integrante:** Sebastián Tovar Muñoz  
**Boleta:** 2026630153  
**Grupo:** 3CV4 — Ingeniería en Sistemas Computacionales (ESCOM-IPN)

---

## Parte 1. Explicación propia de una descomposición de la Parte 1

En la normalización de la relación desnormalizada `Ficha_Escolar_Plana`, el principal problema estaba en mezclar datos del alumno (`curp`, `nombre_alumno`), su grupo (`grado`, `letra`), el salón físico (`clave_salon`) y sus calificaciones por materia en una sola tabla. Esto generaba **dependencias parciales** (el nombre del alumno dependía solo de `id_alumno` y el nombre de la materia solo de `id_materia`, no de la clave compuesta `{id_alumno, id_materia}`) y **dependencias transitivas** (`id_alumno` $\to$ `id_grupo` $\to$ `id_salon` $\to$ `clave_salon`).

Al descomponer en `calificaciones`, `materias`, `alumnos`, `grupos` y `salones`, eliminamos esas dependencias sin perder información: cada unión entre tablas consecutivas comparte la llave primaria de la tabla destino (`id_materia`, `id_alumno`, `id_grupo`, `id_salon`), lo que garantiza una **reunión sin pérdida** y preserva todas las reglas del negocio. En nuestro esquema real, un caso práctico equivalente fue separar `alumno_tutores` y `recado_respuestas` en la migración `05` usando `INSERT ... SELECT`, evitando duplicar datos del tutor o del alumno en múltiples filas.

---

## Parte 2. Tres consultas propias en Álgebra Relacional y SQL

*(Ninguna repite las 13 consultas del equipo ni las de otro integrante.)*

### Consulta 1 (Selección y Proyección) — Reportes de mantenimiento activos
* **Pregunta:** ¿Qué reportes de mantenimiento aún no han sido completados y en qué ubicación del plantel se encuentran?
* **Álgebra relacional (RelaX):**
~~~text
pi folio, ubicacion, estado, fecha_reporte (
  sigma estado != 'Completado' (reportes_mantenimiento)
)
~~~
* **SQL equivalente:**
~~~sql
SELECT folio, ubicacion, estado, fecha_reporte
FROM reportes_mantenimiento
WHERE estado <> 'Completado'
ORDER BY fecha_reporte DESC;
~~~
* **Captura de RelaX:** `![Sebastián C1](../evidencias/sebas-01-mantenimiento.png)`

---

### Consulta 2 (Reunión Externa Izquierda) — Recados enviados por grupo (incluyendo grupos sin recados)
* **Pregunta:** ¿Qué recados se han enviado a cada grupo escolar, conservando también los grupos que todavía no tienen recados registrados?
* **Álgebra relacional (RelaX):**
~~~text
pi grado, letra, tipo, asunto (
  grupos ⟕ recados
)
~~~
* **SQL equivalente:**
~~~sql
SELECT g.grado, g.letra, r.tipo, r.asunto
FROM grupos g
LEFT JOIN recados r ON g.id_grupo = r.id_grupo
ORDER BY g.grado, g.letra, r.id_recado;
~~~
* **Captura de RelaX:** `![Sebastián C2](../evidencias/sebas-02-grupos-recados.png)`

---

### Consulta 3 (Agrupación y Agregación) — Consumo acumulado en cafetería por alumno
* **Pregunta:** ¿Cuántas compras y qué monto total ha registrado cada alumno en la cafetería escolar?
* **Álgebra relacional (RelaX):**
~~~text
gamma id_alumno; count(id_venta)->num_compras, sum(total)->gasto_total (
  ventas_cafeteria
)
~~~
* **SQL equivalente:**
~~~sql
SELECT id_alumno,
       COUNT(id_venta) AS num_compras,
       SUM(total) AS gasto_total
FROM ventas_cafeteria
GROUP BY id_alumno
ORDER BY gasto_total DESC;
~~~
* **Captura de RelaX:** `![Sebastián C3](../evidencias/sebas-03-cafeteria-alumno.png)`
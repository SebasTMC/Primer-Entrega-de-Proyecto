# Parte 2 — Álgebra Relacional

Grupo de RelaX generado automáticamente: `practica6-8/relax/grupo.txt` (mediante `practica6-8/relax/exportar-grupo.py`).  
Todas las consultas SQL se encuentran en `practica6-8/consultas/` y se ejecutan automáticamente con el contenedor `runner`.

---

## Ejercicio 2.2. Consultas sobre el proyecto propio (`Proyecto_Primaria`)

### A. Selección ($\sigma$) y Proyección ($\pi$)

#### 1. Docentes activos (`01-seleccion-proyeccion-docentes.sql`)
* **Pregunta:** ¿Qué docentes se encuentran activos actualmente y cuál es su número de empleado y especialidad?
* **Álgebra relacional (RelaX):**
~~~text
pi num_empleado, nombre, apellido_paterno, especialidad (
  sigma activo = 'true' (docentes)
)
~~~
* **SQL equivalente:**
~~~sql
SELECT num_empleado, nombre, apellido_paterno, especialidad
FROM docentes
WHERE activo = TRUE
ORDER BY num_empleado;
~~~
* **Captura de RelaX (árbol y resultado):** `![Consulta 01](evidencias/01-seleccion-docentes.png)`
* **Comprobación:** Coincide en filas y columnas con la ejecución de `01-seleccion-proyeccion-docentes.sql` sobre la muestra exportada.

---

#### 2. Salones de Planta Alta con capacidad $\ge 30$ (`02-seleccion-proyeccion-salones.sql`)
* **Pregunta:** ¿Qué salones ubicados en Planta Alta tienen capacidad para al menos 30 personas?
* **Álgebra relacional (RelaX):**
~~~text
pi clave_salon, edificio, capacidad (
  sigma planta = 'Planta Alta' and capacidad >= 30 (salones)
)
~~~
* **SQL equivalente:**
~~~sql
SELECT clave_salon, edificio, capacidad
FROM salones
WHERE planta = 'Planta Alta' AND capacidad >= 30
ORDER BY clave_salon;
~~~
* **Captura de RelaX (árbol y resultado):** `![Consulta 02](evidencias/02-seleccion-salones.png)`
* **Comprobación:** Verificada contra PostgreSQL mediante `runner`.

---

#### 3. Calificaciones sobresalientes del ciclo 2026-2027 (`03-seleccion-proyeccion-calificaciones.sql`)
* **Pregunta:** ¿Qué calificaciones del ciclo escolar 2026-2027 son sobresalientes (9.0 o superiores)?
* **Álgebra relacional (RelaX):**
~~~text
pi id_alumno, id_materia, calificacion (
  sigma ciclo_escolar = '2026-2027' and calificacion >= 9.0 (calificaciones)
)
~~~
* **SQL equivalente:**
~~~sql
SELECT id_alumno, id_materia, calificacion
FROM calificaciones
WHERE ciclo_escolar = '2026-2027' AND calificacion >= 9.0
ORDER BY calificacion DESC, id_alumno;
~~~
* **Captura de RelaX (árbol y resultado):** `![Consulta 03](evidencias/03-seleccion-calificaciones.png)`
* **Comprobación:** Verificada contra PostgreSQL mediante `runner`.

---

### B. Operadores de teoría de conjuntos ($\cup$, $-$, $\cap$)

#### 4. Unión: directorio unificado de alumnos y docentes (`04-union-personas.sql`)
* **Pregunta:** ¿Cuál es el directorio unificado de nombres y apellidos paternos de alumnos y docentes?
* **Compatibilidad de unión:** Ambas proyecciones tienen grado 2 y dominios compatibles `(nombre: string, apellido_paterno: string)`.
* **Álgebra relacional (RelaX):**
~~~text
(pi nombre, apellido_paterno (alumnos))
union
(pi nombre, apellido_paterno (docentes))
~~~
* **SQL equivalente:**
~~~sql
SELECT nombre, apellido_paterno FROM alumnos
UNION
SELECT nombre, apellido_paterno FROM docentes
ORDER BY apellido_paterno, nombre;
~~~
* **Captura de RelaX (árbol y resultado):** `![Consulta 04](evidencias/04-union-personas.png)`

---

#### 5. Diferencia: alumnos sin registros en enfermería (`05-diferencia-alumnos-sin-enfermeria.sql`)
* **Pregunta:** ¿Qué identificadores de alumnos nunca han requerido atención en enfermería?
* **Compatibilidad de unión:** Ambas relaciones proyectan un único atributo `id_alumno: number`.
* **Álgebra relacional (RelaX):**
~~~text
(pi id_alumno (alumnos)) - (pi id_alumno (registros_enfermeria))
~~~
* **SQL equivalente:**
~~~sql
SELECT id_alumno FROM alumnos
EXCEPT
SELECT id_alumno FROM registros_enfermeria
ORDER BY id_alumno;
~~~
* **Captura de RelaX (árbol y resultado):** `![Consulta 05](evidencias/05-diferencia-enfermeria.png)`

---

#### 6. Intersección: alumnos con pagos y calificaciones (`06-interseccion-alumnos-pagos-calificaciones.sql`)
* **Pregunta:** ¿Qué identificadores de alumnos tienen registrados tanto pagos de colegiatura como calificaciones?
* **Compatibilidad de unión:** Ambas relaciones proyectan `id_alumno: number`.
* **Álgebra relacional (RelaX):**
~~~text
(pi id_alumno (pagos_colegiatura)) intersect (pi id_alumno (calificaciones))
~~~
* **SQL equivalente:**
~~~sql
SELECT id_alumno FROM pagos_colegiatura
INTERSECT
SELECT id_alumno FROM calificaciones
ORDER BY id_alumno;
~~~
* **Captura de RelaX (árbol y resultado):** `![Consulta 06](evidencias/06-interseccion-pagos-calif.png)`

---

### C. Producto cartesiano ($\times$)

#### 7. Cruce completo de periodos de colegiatura y materias (`07-producto-cartesiano-periodos-materias.sql`)
* **Pregunta:** ¿Qué combinaciones posibles resultan al cruzar todos los periodos de colegiatura con todas las materias?
* **Por qué casi nunca se usa solo:** Multiplica la cardinalidad ($\vert{}R\vert{} \times \vert{}S\vert{} = 4 \times 8 = 32$ filas) generando pares sin relación semántica real entre cobros y asignaturas; en práctica siempre se combina con una condición de selección (reunión).
* **Álgebra relacional (RelaX):**
~~~text
pi nombre_periodo, clave_materia, nombre (
  periodos_colegiatura x materias
)
~~~
* **SQL equivalente:**
~~~sql
SELECT p.nombre_periodo, m.clave_materia, m.nombre
FROM periodos_colegiatura p
CROSS JOIN materias m
ORDER BY p.id_periodo, m.id_materia;
~~~
* **Captura de RelaX (árbol y resultado):** `![Consulta 07](evidencias/07-producto-cartesiano.png)`

---

### D. Reuniones (natural, theta y externa)

#### 8. Reunión natural: alumnos con su grupo (`08-reunion-natural-alumnos-grupos.sql`)
* **Pregunta:** ¿A qué grado, letra y ciclo escolar pertenece cada alumno inscrito?
* **Qué filas se conservan / pierden:** Se conservan todos los alumnos que tienen un `id_grupo` válido (100% por FK `NOT NULL`); se pierden los grupos que no tengan alumnos inscritos en la muestra.
* **Álgebra relacional (RelaX):**
~~~text
pi curp, nombre, apellido_paterno, grado, letra, ciclo_escolar (
  alumnos bowtie grupos
)
~~~
* **SQL equivalente:**
~~~sql
SELECT a.curp, a.nombre, a.apellido_paterno, g.grado, g.letra, g.ciclo_escolar
FROM alumnos a
NATURAL JOIN grupos g
ORDER BY g.grado, g.letra, a.apellido_paterno;
~~~
* **Captura de RelaX (árbol y resultado):** `![Consulta 08](evidencias/08-reunion-natural.png)`

---

#### 9. Reunión theta: pagos que cubren o superan el monto base (`09-reunion-theta-pagos-periodos.sql`)
* **Pregunta:** ¿Qué pagos de colegiatura cubrieron o superaron el monto base de su periodo correspondiente?
* **Qué filas se conservan / pierden:** Se conservan únicamente los pagos completos (`monto_pagado >= monto_base`); se descartan los pagos parciales y los periodos sin pagos.
* **Álgebra relacional (RelaX):**
~~~text
pi referencia, id_alumno, nombre_periodo, monto_pagado, monto_base (
  pagos_colegiatura bowtie (pagos_colegiatura.id_periodo = periodos_colegiatura.id_periodo and monto_pagado >= monto_base) periodos_colegiatura
)
~~~
* **SQL equivalente:**
~~~sql
SELECT p.referencia, p.id_alumno, per.nombre_periodo, p.monto_pagado, per.monto_base
FROM pagos_colegiatura p
JOIN periodos_colegiatura per
  ON p.id_periodo = per.id_periodo
 AND p.monto_pagado >= per.monto_base
ORDER BY p.id_pago;
~~~
* **Captura de RelaX (árbol y resultado):** `![Consulta 09](evidencias/09-reunion-theta.png)`

---

#### 10. Reunión externa izquierda: historial de enfermería de todos los alumnos (`10-reunion-externa-alumnos-enfermeria.sql`)
* **Pregunta:** ¿Cuál es el historial de enfermería de todos los alumnos, conservando también a quienes no tienen atenciones registradas?
* **Qué filas se conservan / pierden:** A diferencia de una reunión interna (que perdería a los alumnos sanos), la reunión externa izquierda (`⟕`) conserva el 100% de las filas de `alumnos`, rellenando `motivo` y `estatus` con `null` cuando no hay coincidencia.
* **Álgebra relacional (RelaX):**
~~~text
pi id_alumno, nombre, apellido_paterno, motivo, estatus (
  alumnos ⟕ registros_enfermeria
)
~~~
* **SQL equivalente:**
~~~sql
SELECT a.id_alumno, a.nombre, a.apellido_paterno, e.motivo, e.estatus
FROM alumnos a
LEFT JOIN registros_enfermeria e ON a.id_alumno = e.id_alumno
ORDER BY e.id_atencion NULLS LAST, a.id_alumno;
~~~
* **Captura de RelaX (árbol y resultado):** `![Consulta 10](evidencias/10-reunion-externa.png)`

---

### E. Agregación y agrupación ($\gamma$)

#### 11. Promedio de calificaciones y evaluaciones por grupo (`11-agrupacion-promedio-grupo.sql`)
* **Pregunta:** ¿Cuál es el promedio de calificaciones y el total de evaluaciones registradas por cada grupo?
* **Álgebra relacional (RelaX):**
~~~text
AlGrupo = pi id_alumno, grado, letra (alumnos bowtie grupos)
gamma grado, letra; avg(calificacion)->promedio, count(id_calificacion)->total_evals (
  AlGrupo bowtie calificaciones
)
~~~
* **SQL equivalente:**
~~~sql
SELECT g.grado, g.letra,
       ROUND(AVG(c.calificacion), 2) AS promedio,
       COUNT(c.id_calificacion) AS total_evals
FROM alumnos a
JOIN grupos g ON a.id_grupo = g.id_grupo
JOIN calificaciones c ON a.id_alumno = c.id_alumno
GROUP BY g.grado, g.letra
ORDER BY g.grado, g.letra;
~~~
* **Captura de RelaX (árbol y resultado):** `![Consulta 11](evidencias/11-agrupacion-promedio.png)`

---

#### 12. Total recaudado y número de pagos por método de pago (`12-agrupacion-pagos-metodo.sql`)
* **Pregunta:** ¿Cuántos pagos y qué monto total se han recaudado por cada método de pago?
* **Álgebra relacional (RelaX):**
~~~text
gamma metodo_pago; count(id_pago)->num_pagos, sum(monto_pagado)->total_recaudado (
  pagos_colegiatura
)
~~~
* **SQL equivalente:**
~~~sql
SELECT metodo_pago,
       COUNT(id_pago) AS num_pagos,
       SUM(monto_pagado) AS total_recaudado
FROM pagos_colegiatura
GROUP BY metodo_pago
ORDER BY total_recaudado DESC;
~~~
* **Captura de RelaX (árbol y resultado):** `![Consulta 12](evidencias/12-agrupacion-pagos.png)`

---

### F. División ($\div$)

#### 13. Alumnos que han cubierto TODOS los periodos de colegiatura de 2026 (`13-division-alumnos-todos-periodos.sql`)
* **Pregunta:** ¿Qué alumnos han cubierto el pago de TODOS los periodos de colegiatura registrados con fecha límite en 2026?
* **Álgebra relacional (RelaX):**
~~~text
PagosAlumno = pi id_alumno, id_periodo (pagos_colegiatura)
Periodos2026 = pi id_periodo (sigma fecha_limite < '2027-01-01' (periodos_colegiatura))
Cumplidos = PagosAlumno ÷ Periodos2026
pi id_alumno, nombre, apellido_paterno (Cumplidos bowtie alumnos)
~~~
* **SQL equivalente:**
~~~sql
SELECT a.id_alumno, a.nombre, a.apellido_paterno
FROM alumnos a
WHERE NOT EXISTS (
    SELECT per.id_periodo
    FROM periodos_colegiatura per
    WHERE per.fecha_limite < DATE '2027-01-01'
      AND NOT EXISTS (
          SELECT 1
          FROM pagos_colegiatura p
          WHERE p.id_alumno = a.id_alumno
            AND p.id_periodo = per.id_periodo
      )
)
ORDER BY a.id_alumno;
~~~
* **Captura de RelaX (árbol y resultado):** `![Consulta 13](evidencias/13-division-periodos.png)`
* **Comprobación:** Devuelve los 6 alumnos con todos los periodos de 2026 cubiertos en PostgreSQL.

---

## Ejercicio 2.3. Álgebra relacional del proyecto asignado

Sistema asignado: **Sismos (`Seismic_Data_Geosciences`)** — ejecutables en la consola SQLite integrada de la aplicación web.  
*(Ajustar los identificadores de tabla/columna si tu fork usa nombres en inglés como `earthquakes` / `dim_location` / `dim_time`.)*

### Consulta S1 — Sismos significativos ($\ge 5.0$) con ubicación y profundidad (Selección + Proyección)
* **Pregunta:** ¿Qué eventos sísmicos registrados alcanzaron una magnitud igual o superior a 5.0 y a qué profundidad ocurrieron?
* **Álgebra relacional:**
~~~text
pi id_sismo, fecha_hora, magnitud, profundidad_km, referencia_ubicacion (
  sigma magnitud >= 5.0 (sismos)
)
~~~
* **Árbol de operadores:**
~~~text
    π (id_sismo, fecha_hora, magnitud, profundidad_km, referencia_ubicacion)
        │
    σ (magnitud >= 5.0)
        │
      sismos
~~~
* **Operador que hace el trabajo pesado:** **Selección ($\sigma$)**, porque escanea el catálogo sísmico completo y descarta la gran mayoría de eventos de baja magnitud antes de proyectar las columnas finales.
* **SQL equivalente (SQLite):**
~~~sql
SELECT id_sismo, fecha_hora, magnitud, profundidad_km, referencia_ubicacion
FROM sismos
WHERE magnitud >= 5.0
ORDER BY magnitud DESC, fecha_hora DESC;
~~~

---

### Consulta S2 — Sismos someros y fuertes por estado/región (Reunión + Selección + Proyección)
* **Pregunta:** ¿Qué sismos someros (profundidad $\le 30$ km) y de magnitud $\ge 4.5$ se registraron en cada estado o región sísmica?
* **Álgebra relacional:**
~~~text
SismosFiltrados = sigma profundidad_km <= 30 and magnitud >= 4.5 (hechos_sismos)
pi id_sismo, magnitud, profundidad_km, estado, region_sismica (
  SismosFiltrados bowtie dim_ubicacion
)
~~~
* **Árbol de operadores:**
~~~text
    π (id_sismo, magnitud, profundidad_km, estado, region_sismica)
        │
        ⋈ (id_ubicacion)
       / \
      /   \
  σ (profundidad_km <= 30 ∧ magnitud >= 4.5)   dim_ubicacion
     │
  hechos_sismos
~~~
* **Operador que hace el trabajo pesado:** **Reunión natural ($\bowtie$)** (empareja los eventos filtrados de la tabla de hechos con su catálogo geográfico); empujar la selección ($\sigma$) debajo de la reunión reduce drásticamente el número de tuplas a cruzar.
* **SQL equivalente (SQLite):**
~~~sql
SELECT h.id_sismo, h.magnitud, h.profundidad_km, u.estado, u.region_sismica
FROM hechos_sismos h
JOIN dim_ubicacion u ON h.id_ubicacion = u.id_ubicacion
WHERE h.profundidad_km <= 30 AND h.magnitud >= 4.5
ORDER BY h.magnitud DESC;
~~~

---

### Consulta S3 — Conteo y magnitud máxima de sismos por año y estado (Reunión + Agrupación)
* **Pregunta:** ¿Cuántos sismos y cuál fue la magnitud máxima registrada por cada estado y año?
* **Álgebra relacional:**
~~~text
SismosGeoTiempo = (hechos_sismos bowtie dim_ubicacion) bowtie dim_tiempo
gamma anio, estado; count(id_sismo)->total_sismos, max(magnitud)->max_magnitud (
  SismosGeoTiempo
)
~~~
* **Árbol de operadores:**
~~~text
    γ (anio, estado; COUNT(id_sismo), MAX(magnitud))
        │
        ⋈ (id_tiempo)
       / \
      /   \
  ⋈ (id_ubicacion)   dim_tiempo
     / \
hechos_sismos  dim_ubicacion
~~~
* **Operador que hace el trabajo pesado:** **Agrupación y agregación ($\gamma$)** junto con las **reuniones ($\bowtie$)** del modelo estrella, ya que requiere particionar todos los hechos por `(anio, estado)` y calcular el conteo y máximo sobre cada partición.
* **SQL equivalente (SQLite):**
~~~sql
SELECT t.anio, u.estado,
       COUNT(h.id_sismo) AS total_sismos,
       MAX(h.magnitud) AS max_magnitud
FROM hechos_sismos h
JOIN dim_ubicacion u ON h.id_ubicacion = u.id_ubicacion
JOIN dim_tiempo t ON h.id_tiempo = t.id_tiempo
GROUP BY t.anio, u.estado
ORDER BY t.anio DESC, total_sismos DESC;
~~~
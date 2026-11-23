# Trabajo Individual — Prácticas 6, 7 y 8

**Integrante:** Bryan David Encarnación Lorenzana  
**Grupo:** 3CV4 — Ingeniería en Sistemas Computacionales (ESCOM-IPN)

---

## Parte 1. Explicación propia de una descomposición de la Parte 1

*(Bryan: revisa y redacta con tus propias palabras esta explicación antes de tu commit.)*

Durante el paso de 2FN a 3FN en la relación `Ficha_Escolar_Plana`, la tabla intermedia `R3(id_alumno, curp, nombre_alumno, id_grupo, grado, letra, id_salon, clave_salon)` ya no tenía dependencias parciales, pero seguía guardando datos del grupo y del salón dentro de cada alumno. Si el salón `A-101` cambiaba de clave o un grupo cambiaba de salón, habría que actualizar a todos los alumnos de ese grupo (anomalía de actualización). Al separar `id_grupo -> grado, letra, id_salon` hacia `grupos` y `id_salon -> clave_salon` hacia `salones`, cada determinante pasó a ser clave primaria de su propia tabla, logrando 3FN y BCNF con reunión sin pérdida.

---

## Parte 2. Tres consultas propias en Álgebra Relacional y SQL

*(Ninguna repite las 13 consultas del equipo ni las de Sebastián.)*

### Consulta 1 (Selección y Proyección) — Personal activo con salario superior a $10,000
* **Pregunta:** ¿Qué empleados activos del plantel perciben un salario mayor a $10,000 y qué puesto desempeñan?
* **Álgebra relacional (RelaX):**
~~~text
pi clave_empleado, nombre, puesto, salario (
  sigma activo = 'true' and salario > 10000 (personal)
)
~~~
* **SQL equivalente:**
~~~sql
SELECT clave_empleado, nombre, puesto, salario
FROM personal
WHERE activo = TRUE AND salario > 10000
ORDER BY salario DESC;
~~~
* **Captura de RelaX:** `![Bryan C1](../evidencias/bryan-01-personal.png)`

---

### Consulta 2 (Reunión Externa Izquierda) — Historial de cafetería conservando alumnos sin compras
* **Pregunta:** ¿Qué consumos de cafetería tiene cada alumno, conservando también a los alumnos que nunca han comprado en cafetería?
* **Álgebra relacional (RelaX):**
~~~text
pi id_alumno, nombre, apellido_paterno, concepto, total (
  alumnos ⟕ ventas_cafeteria
)
~~~
* **SQL equivalente:**
~~~sql
SELECT a.id_alumno, a.nombre, a.apellido_paterno, v.concepto, v.total
FROM alumnos a
LEFT JOIN ventas_cafeteria v ON a.id_alumno = v.id_alumno
ORDER BY v.id_venta NULLS LAST, a.id_alumno;
~~~
* **Captura de RelaX:** `![Bryan C2](../evidencias/bryan-02-alumnos-cafeteria.png)`

---

### Consulta 3 (Agrupación y Agregación) — Carga de bloques horarios por día de la semana
* **Pregunta:** ¿Cuántos bloques de clase semanales están programados en total para cada día de la semana?
* **Álgebra relacional (RelaX):**
~~~text
gamma dia_semana; count(id_horario)->total_bloques (
  horarios
)
~~~
* **SQL equivalente:**
~~~sql
SELECT dia_semana,
       COUNT(id_horario) AS total_bloques
FROM horarios
GROUP BY dia_semana
ORDER BY total_bloques DESC;
~~~
* **Captura de RelaX:** `![Bryan C3](../evidencias/bryan-03-horarios-dia.png)`
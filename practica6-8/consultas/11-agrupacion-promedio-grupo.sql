-- PREGUNTA: ¿Cuál es el promedio de calificaciones y el total de evaluaciones registradas por cada grupo?
-- ALGEBRA: γ grado, letra; AVG(calificacion)→promedio, COUNT(id_calificacion)→total_evals ((alumnos ⋈ grupos) ⋈ calificaciones)
SELECT g.grado, g.letra,
       ROUND(AVG(c.calificacion), 2) AS promedio,
       COUNT(c.id_calificacion) AS total_evals
FROM alumnos a
JOIN grupos g ON a.id_grupo = g.id_grupo
JOIN calificaciones c ON a.id_alumno = c.id_alumno
GROUP BY g.grado, g.letra
ORDER BY g.grado, g.letra;
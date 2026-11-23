-- PREGUNTA: ¿Qué identificadores de alumnos tienen registrados tanto pagos de colegiatura como calificaciones?
-- ALGEBRA: π id_alumno (pagos_colegiatura) ∩ π id_alumno (calificaciones)
SELECT id_alumno FROM pagos_colegiatura
INTERSECT
SELECT id_alumno FROM calificaciones
ORDER BY id_alumno;
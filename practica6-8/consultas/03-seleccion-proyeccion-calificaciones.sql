-- PREGUNTA: ¿Qué calificaciones del ciclo escolar 2026-2027 son sobresalientes (9.0 o superiores)?
-- ALGEBRA: π id_alumno, id_materia, calificacion (σ ciclo_escolar = '2026-2027' ∧ calificacion >= 9.0 (calificaciones))
SELECT id_alumno, id_materia, calificacion
FROM calificaciones
WHERE ciclo_escolar = '2026-2027' AND calificacion >= 9.0
ORDER BY calificacion DESC, id_alumno;
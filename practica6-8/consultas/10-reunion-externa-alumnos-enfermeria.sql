-- PREGUNTA: ¿Cuál es el historial de enfermería de todos los alumnos, conservando también a quienes no tienen atenciones registradas?
-- ALGEBRA: π id_alumno, nombre, apellido_paterno, motivo, estatus (alumnos ⟕ registros_enfermeria)
SELECT a.id_alumno, a.nombre, a.apellido_paterno, e.motivo, e.estatus
FROM alumnos a
LEFT JOIN registros_enfermeria e ON a.id_alumno = e.id_alumno
ORDER BY e.id_atencion NULLS LAST, a.id_alumno;
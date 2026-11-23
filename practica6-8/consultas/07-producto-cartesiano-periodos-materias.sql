-- PREGUNTA: ¿Qué combinaciones posibles resultan al cruzar todos los periodos de colegiatura con todas las materias (demostración de producto cartesiano)?
-- ALGEBRA: π nombre_periodo, clave_materia, nombre (periodos_colegiatura × materias)
SELECT p.nombre_periodo, m.clave_materia, m.nombre
FROM periodos_colegiatura p
CROSS JOIN materias m
ORDER BY p.id_periodo, m.id_materia;
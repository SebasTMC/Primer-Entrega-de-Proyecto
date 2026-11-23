-- PREGUNTA: ¿Qué docentes se encuentran activos actualmente y cuál es su número de empleado y especialidad?
-- ALGEBRA: π num_empleado, nombre, apellido_paterno, especialidad (σ activo = 'true' (docentes))
SELECT num_empleado, nombre, apellido_paterno, especialidad
FROM docentes
WHERE activo = TRUE
ORDER BY num_empleado;
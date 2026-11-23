-- PREGUNTA: ¿Cuál es el directorio unificado de nombres y apellidos paternos de alumnos y docentes?
-- ALGEBRA: π nombre, apellido_paterno (alumnos) ∪ π nombre, apellido_paterno (docentes)
SELECT nombre, apellido_paterno FROM alumnos
UNION
SELECT nombre, apellido_paterno FROM docentes
ORDER BY apellido_paterno, nombre;
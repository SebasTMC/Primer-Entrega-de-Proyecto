-- PREGUNTA: ¿Qué identificadores de alumnos nunca han requerido atención en enfermería?
-- ALGEBRA: π id_alumno (alumnos) − π id_alumno (registros_enfermeria)
SELECT id_alumno FROM alumnos
EXCEPT
SELECT id_alumno FROM registros_enfermeria
ORDER BY id_alumno;
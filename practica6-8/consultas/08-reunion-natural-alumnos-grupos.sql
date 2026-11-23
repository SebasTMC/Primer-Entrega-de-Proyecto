-- PREGUNTA: ¿A qué grado, letra y ciclo escolar pertenece cada alumno inscrito?
-- ALGEBRA: π curp, nombre, apellido_paterno, grado, letra, ciclo_escolar (alumnos ⋈ grupos)
SELECT a.curp, a.nombre, a.apellido_paterno, g.grado, g.letra, g.ciclo_escolar
FROM alumnos a
NATURAL JOIN grupos g
ORDER BY g.grado, g.letra, a.apellido_paterno;
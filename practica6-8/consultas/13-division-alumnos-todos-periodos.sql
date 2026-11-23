-- PREGUNTA: ¿Qué alumnos han cubierto el pago de TODOS los periodos de colegiatura registrados con fecha límite en 2026?
-- ALGEBRA: (π id_alumno, id_periodo (pagos_colegiatura)) ÷ (π id_periodo (σ fecha_limite < '2027-01-01' (periodos_colegiatura)))
SELECT a.id_alumno, a.nombre, a.apellido_paterno
FROM alumnos a
WHERE NOT EXISTS (
    SELECT per.id_periodo
    FROM periodos_colegiatura per
    WHERE per.fecha_limite < DATE '2027-01-01'
      AND NOT EXISTS (
          SELECT 1
          FROM pagos_colegiatura p
          WHERE p.id_alumno = a.id_alumno
            AND p.id_periodo = per.id_periodo
      )
)
ORDER BY a.id_alumno;
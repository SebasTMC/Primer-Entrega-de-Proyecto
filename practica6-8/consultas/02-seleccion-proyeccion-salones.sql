-- PREGUNTA: ¿Qué salones ubicados en Planta Baja tienen capacidad para al menos 30 personas?
-- ALGEBRA: π clave_salon, edificio, capacidad (σ planta = 'Planta Baja' ∧ capacidad >= 30 (salones))
SELECT clave_salon, edificio, capacidad
FROM salones
WHERE planta = 'Planta Baja' AND capacidad >= 30
ORDER BY clave_salon;
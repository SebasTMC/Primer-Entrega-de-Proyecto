-- PREGUNTA: ¿Qué salones ubicados en Planta Alta tienen capacidad para al menos 30 personas?
-- ALGEBRA: π clave_salon, edificio, capacidad (σ planta = 'Planta Alta' ∧ capacidad >= 30 (salones))
SELECT clave_salon, edificio, capacidad
FROM salones
WHERE planta = 'Planta Alta' AND capacidad >= 30
ORDER BY clave_salon;
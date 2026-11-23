-- PREGUNTA: ¿Qué pagos de colegiatura cubrieron o superaron el monto base de su periodo correspondiente?
-- ALGEBRA: π referencia, id_alumno, nombre_periodo, monto_pagado, monto_base (pagos_colegiatura ⋈_{pagos_colegiatura.id_periodo = periodos_colegiatura.id_periodo ∧ monto_pagado >= monto_base} periodos_colegiatura)
SELECT p.referencia, p.id_alumno, per.nombre_periodo, p.monto_pagado, per.monto_base
FROM pagos_colegiatura p
JOIN periodos_colegiatura per
  ON p.id_periodo = per.id_periodo
 AND p.monto_pagado >= per.monto_base
ORDER BY p.id_pago;
-- PREGUNTA: ¿Cuántos pagos y qué monto total se han recaudado por cada método de pago?
-- ALGEBRA: γ metodo_pago; COUNT(id_pago)→num_pagos, SUM(monto_pagado)→total_recaudado (pagos_colegiatura)
SELECT metodo_pago,
       COUNT(id_pago) AS num_pagos,
       SUM(monto_pagado) AS total_recaudado
FROM pagos_colegiatura
GROUP BY metodo_pago
ORDER BY total_recaudado DESC;
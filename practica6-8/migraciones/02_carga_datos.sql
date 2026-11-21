-- 02_carga_datos.sql
-- Datos iniciales para Proyecto_Primaria (PostgreSQL)

INSERT INTO tutores (nombre, apellido_paterno, apellido_materno, correo, telefono, parentesco) VALUES
('María', 'López', 'García', 'maria.lopez@correo.com', '5510010001', 'Madre'),
('Carlos', 'Martínez', 'Ruiz', 'carlos.martinez@correo.com', '5510010002', 'Padre'),
('Laura', 'Hernández', 'Pérez', 'laura.hernandez@correo.com', '5510010003', 'Madre'),
('Jorge', 'Ramírez', 'Sánchez', 'jorge.ramirez@correo.com', '5510010004', 'Padre'),
('Ana', 'Gómez', 'Castro', 'ana.gomez@correo.com', '5510010005', 'Madre'),
('Roberto', 'Torres', 'Díaz', 'roberto.torres@correo.com', '5510010006', 'Padre'),
('Patricia', 'Flores', 'Vega', 'patricia.flores@correo.com', '5510010007', 'Madre'),
('Miguel', 'Castillo', 'Nava', 'miguel.castillo@correo.com', '5510010008', 'Tutor Legal'),
('Sofía', 'Morales', 'Estrada', 'sofia.morales@correo.com', '5510010009', 'Madre'),
('Fernando', 'Vázquez', 'Silva', 'fernando.vazquez@correo.com', '5510010010', 'Padre'),
('Elena', 'Cruz', 'Luna', 'elena.cruz@correo.com', '5510010011', 'Abuelo/a'),
('Diego', 'Jiménez', 'Vargas', 'diego.jimenez@correo.com', '5510010012', 'Padre');

INSERT INTO docentes (num_empleado, nombre, apellido_paterno, correo, especialidad) VALUES
('DOC-001', 'Gabriela', 'Mendoza', 'g.mendoza@primaria.edu.mx', 'Educación Primaria 1°'),
('DOC-002', 'Ricardo', 'Salazar', 'r.salazar@primaria.edu.mx', 'Educación Primaria 2°'),
('DOC-003', 'Verónica', 'Ortega', 'v.ortega@primaria.edu.mx', 'Educación Primaria 3°'),
('DOC-004', 'Héctor', 'Delgado', 'h.delgado@primaria.edu.mx', 'Educación Primaria 4°'),
('DOC-005', 'Lucía', 'Reyes', 'l.reyes@primaria.edu.mx', 'Educación Primaria 5°'),
('DOC-006', 'Alejandro', 'Navarro', 'a.navarro@primaria.edu.mx', 'Educación Primaria 6°'),
('DOC-007', 'Eduardo', 'Pineda', 'e.pineda@primaria.edu.mx', 'Educación Física'),
('DOC-008', 'Mónica', 'Chávez', 'm.chavez@primaria.edu.mx', 'Tecnología e Informática');

INSERT INTO salones (clave_salon, edificio, planta, capacidad, codigo_svg) VALUES
('A-101', 'Edificio A', 'Planta Baja', 30, 'salon-a101'),
('A-102', 'Edificio A', 'Planta Baja', 30, 'salon-a102'),
('A-103', 'Edificio A', 'Planta Baja', 30, 'salon-a103'),
('A-201', 'Edificio A', 'Planta Alta', 32, 'salon-a201'),
('A-202', 'Edificio A', 'Planta Alta', 32, 'salon-a202'),
('A-203', 'Edificio A', 'Planta Alta', 32, 'salon-a203'),
('LAB-01', 'Edificio B', 'Planta Alta', 28, 'salon-lab01'),
('CANCHA', 'Patio Central', 'Planta Baja', 60, 'zona-cancha');

INSERT INTO grupos (grado, letra, ciclo_escolar, id_docente_titular) VALUES
(1, 'A', '2026-2027', 1),
(2, 'A', '2026-2027', 2),
(3, 'A', '2026-2027', 3),
(4, 'A', '2026-2027', 4),
(5, 'A', '2026-2027', 5),
(6, 'A', '2026-2027', 6);

INSERT INTO alumnos (curp, nombre, apellido_paterno, apellido_materno, fecha_nacimiento, id_tutor, id_grupo) VALUES
('LOGR190512HDFRRL01', 'Mateo', 'López', 'García', '2019-05-12', 1, 1),
('MARS180823MDFRRS02', 'Valentina', 'Martínez', 'Ruiz', '2018-08-23', 2, 2),
('HEGP170315HDFRRP03', 'Santiago', 'Hernández', 'Pérez', '2017-03-15', 3, 3),
('RAML161104MDFRRL04', 'Camila', 'Ramírez', 'Sánchez', '2016-11-04', 4, 4),
('GOCJ150719HDFRRJ05', 'Sebastián', 'Gómez', 'Castro', '2015-07-19', 5, 5),
('TORM140228MDFRRM06', 'Renata', 'Torres', 'Díaz', '2014-02-28', 6, 6),
('FLVD190910HDFRRD07', 'Leonardo', 'Flores', 'Vega', '2019-09-10', 7, 1),
('CASN180405MDFRRN08', 'Regina', 'Castillo', 'Nava', '2018-04-05', 8, 2),
('MOEA171221HDFRRA09', 'Emiliano', 'Morales', 'Estrada', '2017-12-21', 9, 3),
('VAZS160614MDFRRS10', 'Ximena', 'Vázquez', 'Silva', '2016-06-14', 10, 4),
('CRUL150130HDFRRL11', 'Daniel', 'Cruz', 'Luna', '2015-01-30', 11, 5),
('JIMV141008MDFRRV12', 'Sofía', 'Jiménez', 'Vargas', '2014-10-08', 12, 6);

INSERT INTO materias (clave_materia, nombre, grado_sugerido) VALUES
('ESP-101', 'Español', 1),
('MAT-101', 'Matemáticas', 1),
('CNAT-201', 'Ciencias Naturales', 3),
('HIST-301', 'Historia', 4),
('GEO-401', 'Geografía', 5),
('FCYE-501', 'Formación Cívica y Ética', 6),
('EDFI-001', 'Educación Física', 1),
('COMP-001', 'Computación', 2);

INSERT INTO horarios (id_grupo, id_materia, id_docente, id_salon, dia_semana, hora_inicio, hora_fin) VALUES
-- Bloque 08:00 - 09:00 (Lunes)
(1, 1, 1, 1, 'Lunes', '08:00', '09:00'),
(2, 1, 2, 2, 'Lunes', '08:00', '09:00'),
(3, 2, 3, 3, 'Lunes', '08:00', '09:00'),
(4, 3, 4, 4, 'Lunes', '08:00', '09:00'),
(5, 4, 5, 5, 'Lunes', '08:00', '09:00'),
(6, 5, 6, 6, 'Lunes', '08:00', '09:00'),
-- Bloque 09:00 - 10:00 (Lunes)
(1, 2, 1, 1, 'Lunes', '09:00', '10:00'),
(2, 3, 2, 2, 'Lunes', '09:00', '10:00'),
(3, 8, 8, 7, 'Lunes', '09:00', '10:00'),
(4, 7, 7, 8, 'Lunes', '09:00', '10:00'),
(5, 6, 5, 5, 'Lunes', '09:00', '10:00'),
(6, 2, 6, 6, 'Lunes', '09:00', '10:00'),
-- Bloque 10:30 - 11:30 (Lunes)
(1, 7, 7, 8, 'Lunes', '10:30', '11:30'),
(2, 8, 8, 7, 'Lunes', '10:30', '11:30'),
(3, 4, 3, 3, 'Lunes', '10:30', '11:30'),
(4, 5, 4, 4, 'Lunes', '10:30', '11:30'),
(5, 1, 5, 5, 'Lunes', '10:30', '11:30'),
(6, 6, 6, 6, 'Lunes', '10:30', '11:30');

INSERT INTO periodos_colegiatura (nombre_periodo, monto_base, fecha_limite) VALUES
('Septiembre 2026', 2500.00, '2026-09-10'),
('Octubre 2026', 2500.00, '2026-10-10'),
('Noviembre 2026', 2500.00, '2026-11-10'),
('Diciembre 2026', 2500.00, '2026-12-10');

INSERT INTO pagos_colegiatura (id_alumno, id_periodo, fecha_pago, monto_pagado, metodo_pago, estatus, referencia) VALUES
-- Alumno 1 (todos los periodos pagados)
(1, 1, '2026-09-05 09:15:00', 2500.00, 'Transferencia', 'Pagado', 'REF-2026-001'),
(1, 2, '2026-10-04 10:20:00', 2500.00, 'Transferencia', 'Pagado', 'REF-2026-002'),
(1, 3, '2026-11-06 08:45:00', 2500.00, 'Tarjeta', 'Pagado', 'REF-2026-003'),
(1, 4, '2026-11-18 11:00:00', 2500.00, 'Tarjeta', 'Pagado', 'REF-2026-004'),
-- Alumno 2 (todos los periodos pagados)
(2, 1, '2026-09-03 12:00:00', 2500.00, 'Tarjeta', 'Pagado', 'REF-2026-005'),
(2, 2, '2026-10-07 14:30:00', 2500.00, 'Tarjeta', 'Pagado', 'REF-2026-006'),
(2, 3, '2026-11-05 16:10:00', 2500.00, 'Transferencia', 'Pagado', 'REF-2026-007'),
(2, 4, '2026-11-19 09:30:00', 2500.00, 'Transferencia', 'Pagado', 'REF-2026-008'),
-- Alumno 3 (3 periodos)
(3, 1, '2026-09-08 08:30:00', 2500.00, 'Efectivo', 'Pagado', 'REF-2026-009'),
(3, 2, '2026-10-09 09:10:00', 2500.00, 'Efectivo', 'Pagado', 'REF-2026-010'),
(3, 3, '2026-11-09 10:00:00', 1500.00, 'Efectivo', 'Parcial', 'REF-2026-011'),
-- Alumno 4 (2 periodos)
(4, 1, '2026-09-10 13:00:00', 2500.00, 'Transferencia', 'Pagado', 'REF-2026-012'),
(4, 2, '2026-10-10 15:20:00', 2500.00, 'Transferencia', 'Pagado', 'REF-2026-013'),
-- Alumno 5 (todos los periodos pagados)
(5, 1, '2026-09-02 10:00:00', 2500.00, 'Tarjeta', 'Pagado', 'REF-2026-014'),
(5, 2, '2026-10-02 10:05:00', 2500.00, 'Tarjeta', 'Pagado', 'REF-2026-015'),
(5, 3, '2026-11-02 10:15:00', 2500.00, 'Tarjeta', 'Pagado', 'REF-2026-016'),
(5, 4, '2026-11-15 11:40:00', 2500.00, 'Tarjeta', 'Pagado', 'REF-2026-017'),
-- Alumnos 6 a 10 (pagos parciales / iniciales; alumnos 11 y 12 sin pagos)
(6, 1, '2026-09-09 11:30:00', 2500.00, 'Efectivo', 'Pagado', 'REF-2026-018'),
(7, 1, '2026-09-06 08:50:00', 2500.00, 'Transferencia', 'Pagado', 'REF-2026-019'),
(7, 2, '2026-10-08 09:40:00', 2500.00, 'Transferencia', 'Pagado', 'REF-2026-020'),
(8, 1, '2026-09-07 12:15:00', 2500.00, 'Tarjeta', 'Pagado', 'REF-2026-021'),
(9, 1, '2026-09-04 14:00:00', 2500.00, 'Transferencia', 'Pagado', 'REF-2026-022'),
(9, 2, '2026-10-05 16:45:00', 2500.00, 'Transferencia', 'Pagado', 'REF-2026-023'),
(10, 1, '2026-09-10 17:00:00', 2500.00, 'Efectivo', 'Pagado', 'REF-2026-024');

INSERT INTO recados (id_tutor, id_alumno, id_docente, tipo, asunto, mensaje, estatus) VALUES
(1, 1, 1, 'Justificante', 'Falta por cita médica', 'Mateo faltará el martes por revisión pediátrica.', 'Atendido'),
(2, 2, 2, 'Recado', 'Salida temprana', 'Hoy pasará su abuela a recoger a Valentina a las 13:00.', 'Leido'),
(3, 3, 3, 'Aviso', 'Material de matemáticas', 'Santiago lleva el juego de geometría completo.', 'Atendido'),
(4, 4, 4, 'Cita', 'Revisión de calificaciones', 'Solicito cita breve el jueves a la salida.', 'Enviado'),
(5, 5, 5, 'Recado', 'Alergia estacional', 'Sebastián está tomando antihistamínico por la mañana.', 'Leido'),
(6, 6, 6, 'Justificante', 'Retardo justificado', 'Hubo cierre vial en la avenida principal.', 'Atendido'),
(7, 7, 1, 'Recado', 'Uniforme deportivo', 'Leonardo olvidó su pants en casa, lo llevo en el recreo.', 'Enviado'),
(8, 8, 8, 'Aviso', 'Práctica de cómputo', 'Regina ya tiene cuenta escolar activa.', 'Leido'),
(9, 9, 3, 'Cita', 'Seguimiento de lectura', 'Me gustaría platicar sobre su avance en lectura.', 'Enviado'),
(10, 10, 7, 'Justificante', 'Lesión leve en tobillo', 'Ximena no podrá correr hoy en Educación Física.', 'Atendido');
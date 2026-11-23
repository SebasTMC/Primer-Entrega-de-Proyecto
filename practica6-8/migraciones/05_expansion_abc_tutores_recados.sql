-- 05_expansion_abc_tutores_recados.sql
-- Expansión a 18 grupos (1°A-6°C), salones del nuevo croquis, máx. 2 tutores exclusivos,
-- horarios semanales completos y flujo de recados Docente -> Padres.

BEGIN;
SET client_encoding = 'UTF8';

ALTER TABLE personal DROP CONSTRAINT IF EXISTS personal_puesto_check;
ALTER TABLE personal
    ADD CONSTRAINT personal_puesto_check
    CHECK (puesto IN ('Dirección', 'Administrativo', 'Docente titular', 'Personal de enfermería', 'Personal de cafetería', 'Mantenimiento'));

-- =========================================================================
-- 1. ACTUALIZACIÓN DE ESQUEMA Y REGLAS DE INTEGRIDAD
-- =========================================================================

-- 1.1 Salón fijo por grupo
ALTER TABLE grupos
    ADD COLUMN IF NOT EXISTS id_salon INTEGER UNIQUE REFERENCES salones(id_salon)
        ON UPDATE CASCADE ON DELETE RESTRICT;

-- 1.2 Tutores exclusivos por alumno (máximo 2)
CREATE TABLE IF NOT EXISTS alumno_tutores (
    id_alumno INTEGER NOT NULL REFERENCES alumnos(id_alumno)
        ON UPDATE CASCADE ON DELETE CASCADE,
    id_tutor INTEGER NOT NULL UNIQUE REFERENCES tutores(id_tutor)
        ON UPDATE CASCADE ON DELETE CASCADE,
    es_principal BOOLEAN NOT NULL DEFAULT FALSE,
    PRIMARY KEY (id_alumno, id_tutor)
);

CREATE OR REPLACE FUNCTION fn_validar_max_dos_tutores()
RETURNS TRIGGER AS $$
DECLARE
    total_tutores INTEGER;
BEGIN
    SELECT COUNT(*) INTO total_tutores
    FROM alumno_tutores
    WHERE id_alumno = NEW.id_alumno
      AND id_tutor <> NEW.id_tutor;

    IF total_tutores >= 2 THEN
        RAISE EXCEPTION 'El alumno % ya tiene el máximo permitido de 2 tutores exclusivos.', NEW.id_alumno;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_validar_max_dos_tutores ON alumno_tutores;
CREATE TRIGGER trg_validar_max_dos_tutores
BEFORE INSERT OR UPDATE ON alumno_tutores
FOR EACH ROW EXECUTE FUNCTION fn_validar_max_dos_tutores();

-- 1.3 Nuevo flujo de recados (Docente -> Grupo o Alumno; Padre solo responde)
ALTER TABLE recados ALTER COLUMN id_tutor DROP NOT NULL;
ALTER TABLE recados ALTER COLUMN id_alumno DROP NOT NULL;

ALTER TABLE recados
    ADD COLUMN IF NOT EXISTS id_grupo INTEGER REFERENCES grupos(id_grupo)
        ON UPDATE CASCADE ON DELETE CASCADE,
    ADD COLUMN IF NOT EXISTS tipo_respuesta VARCHAR(20) NOT NULL DEFAULT 'Leido';

ALTER TABLE recados DROP CONSTRAINT IF EXISTS recados_tipo_respuesta_check;
ALTER TABLE recados
    ADD CONSTRAINT recados_tipo_respuesta_check
    CHECK (tipo_respuesta IN ('Texto', 'Confirmado', 'Leido', 'Aceptado'));

ALTER TABLE recados DROP CONSTRAINT IF EXISTS recados_destino_check;
ALTER TABLE recados
    ADD CONSTRAINT recados_destino_check
    CHECK (id_grupo IS NOT NULL OR id_alumno IS NOT NULL);

CREATE TABLE IF NOT EXISTS recado_respuestas (
    id_respuesta SERIAL PRIMARY KEY,
    id_recado INTEGER NOT NULL REFERENCES recados(id_recado)
        ON UPDATE CASCADE ON DELETE CASCADE,
    id_alumno INTEGER NOT NULL REFERENCES alumnos(id_alumno)
        ON UPDATE CASCADE ON DELETE CASCADE,
    id_tutor INTEGER REFERENCES tutores(id_tutor)
        ON UPDATE CASCADE ON DELETE SET NULL,
    estado_respuesta VARCHAR(20) NOT NULL
        CHECK (estado_respuesta IN ('Leido', 'Confirmado', 'Aceptado', 'Respondido')),
    texto_respuesta TEXT,
    fecha_respuesta TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (id_recado, id_alumno)
);

-- =========================================================================
-- 2. REINICIO LIMPIO DE DATOS PARA CARGA DE 18 GRUPOS (A, B, C)
-- =========================================================================
TRUNCATE TABLE
    recado_respuestas,
    recados,
    ventas_cafeteria,
    reportes_mantenimiento,
    registros_enfermeria,
    calificaciones,
    pagos_colegiatura,
    horarios,
    alumno_tutores,
    usuarios,
    alumnos,
    tutores,
    grupos,
    docentes,
    salones,
    materias,
    periodos_colegiatura,
    personal
RESTART IDENTITY CASCADE;

-- =========================================================================
-- 3. SALONES Y ÁREAS DEL NUEVO CROQUIS SVG
-- =========================================================================
INSERT INTO salones (clave_salon, edificio, planta, capacidad, codigo_svg) VALUES
-- Edificio A (Ala Izquierda - 1° y 2°)
('A-101', 'Edificio A (Ala Izquierda)', 'Planta Baja', 30, 'salon-a101'),
('A-102', 'Edificio A (Ala Izquierda)', 'Planta Baja', 30, 'salon-a102'),
('A-103', 'Edificio A (Ala Izquierda)', 'Planta Baja', 30, 'salon-a103'),
('A-104', 'Edificio A (Ala Izquierda)', 'Planta Baja', 30, 'salon-a104'),
('A-105', 'Edificio A (Ala Izquierda)', 'Planta Baja', 30, 'salon-a105'),
('A-106', 'Edificio A (Ala Izquierda)', 'Planta Baja', 30, 'salon-a106'),
-- Edificio B (Ala Superior-Derecha - 3° y 4°)
('B-201', 'Edificio B (Ala Superior)', 'Planta Baja', 30, 'salon-b201'),
('B-202', 'Edificio B (Ala Superior)', 'Planta Baja', 30, 'salon-b202'),
('B-203', 'Edificio B (Ala Superior)', 'Planta Baja', 30, 'salon-b203'),
('B-204', 'Edificio B (Ala Superior)', 'Planta Baja', 30, 'salon-b204'),
('B-205', 'Edificio B (Ala Superior)', 'Planta Baja', 30, 'salon-b205'),
('B-206', 'Edificio B (Ala Superior)', 'Planta Baja', 30, 'salon-b206'),
-- Edificio C (Ala Inferior - 5° y 6°)
('C-301', 'Edificio C (Ala Inferior)', 'Planta Baja', 30, 'salon-c301'),
('C-302', 'Edificio C (Ala Inferior)', 'Planta Baja', 30, 'salon-c302'),
('C-303', 'Edificio C (Ala Inferior)', 'Planta Baja', 30, 'salon-c303'),
('C-304', 'Edificio C (Ala Inferior)', 'Planta Baja', 30, 'salon-c304'),
('C-305', 'Edificio C (Ala Inferior)', 'Planta Baja', 30, 'salon-c305'),
('C-306', 'Edificio C (Ala Inferior)', 'Planta Baja', 30, 'salon-c306'),
-- Espacios especiales y servicios
('COMP-01',   'Edificio A (Ala Izquierda)', 'Planta Baja', 30, 'zona-computo'),
('CANCHA-01', 'Zona Deportiva',             'Planta Baja', 60, 'zona-cancha'),
('BIB-01',    'Edificio B (Ala Superior)',  'Planta Baja', 40, 'zona-biblioteca'),
('DIR-01',    'Edificio C (Ala Inferior)',  'Planta Baja', 15, 'zona-direccion'),
('CAF-01',    'Zona de Servicios',          'Planta Baja', 45, 'zona-cafeteria'),
('ENF-01',    'Zona de Servicios',          'Planta Baja', 10, 'zona-enfermeria'),
('BAN-01',    'Edificio A (Ala Izquierda)', 'Planta Baja', 20, 'zona-banos-poniente'),
('BAN-02',    'Edificio B (Ala Superior)',  'Planta Baja', 20, 'zona-banos-oriente');

-- =========================================================================
-- 4. DOCENTES (18 TITULARES + 2 CÓMPUTO + 2 EDUCACIÓN FÍSICA)
-- =========================================================================
INSERT INTO docentes (num_empleado, nombre, apellido_paterno, correo, especialidad) VALUES
('DOC-001', 'Gabriela',  'Mendoza',    'docente_1a@primaria.edu.mx', 'Titular Primaria 1°A'),
('DOC-002', 'Laura',     'Muñoz',      'docente_1b@primaria.edu.mx', 'Titular Primaria 1°B'),
('DOC-003', 'Mariana',   'Serrano',    'docente_1c@primaria.edu.mx', 'Titular Primaria 1°C'),
('DOC-004', 'Ricardo',   'Salazar',    'docente_2a@primaria.edu.mx', 'Titular Primaria 2°A'),
('DOC-005', 'Claudia',   'Vega',       'docente_2b@primaria.edu.mx', 'Titular Primaria 2°B'),
('DOC-006', 'Jorge',     'Ibarra',     'docente_2c@primaria.edu.mx', 'Titular Primaria 2°C'),
('DOC-007', 'Verónica',  'Ortega',     'docente_3a@primaria.edu.mx', 'Titular Primaria 3°A'),
('DOC-008', 'Patricia',  'Nava',       'docente_3b@primaria.edu.mx', 'Titular Primaria 3°B'),
('DOC-009', 'Arturo',    'Camacho',    'docente_3c@primaria.edu.mx', 'Titular Primaria 3°C'),
('DOC-010', 'Héctor',    'Delgado',    'docente_4a@primaria.edu.mx', 'Titular Primaria 4°A'),
('DOC-011', 'Silvia',    'Campos',     'docente_4b@primaria.edu.mx', 'Titular Primaria 4°B'),
('DOC-012', 'Raúl',      'Bautista',   'docente_4c@primaria.edu.mx', 'Titular Primaria 4°C'),
('DOC-013', 'Lucía',     'Reyes',      'docente_5a@primaria.edu.mx', 'Titular Primaria 5°A'),
('DOC-014', 'Fernando',  'Cortés',     'docente_5b@primaria.edu.mx', 'Titular Primaria 5°B'),
('DOC-015', 'Adriana',   'León',       'docente_5c@primaria.edu.mx', 'Titular Primaria 5°C'),
('DOC-016', 'Alejandro', 'Navarro',    'docente_6a@primaria.edu.mx', 'Titular Primaria 6°A'),
('DOC-017', 'Beatriz',   'Rangel',     'docente_6b@primaria.edu.mx', 'Titular Primaria 6°B'),
('DOC-018', 'Oscar',     'Valdez',     'docente_6c@primaria.edu.mx', 'Titular Primaria 6°C'),
-- Especialistas (IDs 19 a 22)
('DOC-019', 'Mónica',    'Chávez',     'docente_comp1@primaria.edu.mx', 'Computación (1° a 3°)'),
('DOC-020', 'Daniel',    'Rojas',      'docente_comp2@primaria.edu.mx', 'Computación (4° a 6°)'),
('DOC-021', 'Eduardo',   'Pineda',     'docente_ef1@primaria.edu.mx',   'Educación Física (1° a 3°)'),
('DOC-022', 'Karina',    'Solís',      'docente_ef2@primaria.edu.mx',   'Educación Física (4° a 6°)');

-- =========================================================================
-- 5. GRUPOS (18 GRUPOS: 1°A A 6°C, CON TITULAR Y SALÓN FIJO)
-- =========================================================================
INSERT INTO grupos (grado, letra, ciclo_escolar, id_docente_titular, id_salon) VALUES
(1, 'A', '2026-2027', 1,  1),  (1, 'B', '2026-2027', 2,  2),  (1, 'C', '2026-2027', 3,  3),
(2, 'A', '2026-2027', 4,  4),  (2, 'B', '2026-2027', 5,  5),  (2, 'C', '2026-2027', 6,  6),
(3, 'A', '2026-2027', 7,  7),  (3, 'B', '2026-2027', 8,  8),  (3, 'C', '2026-2027', 9,  9),
(4, 'A', '2026-2027', 10, 10), (4, 'B', '2026-2027', 11, 11), (4, 'C', '2026-2027', 12, 12),
(5, 'A', '2026-2027', 13, 13), (5, 'B', '2026-2027', 14, 14), (5, 'C', '2026-2027', 15, 15),
(6, 'A', '2026-2027', 16, 16), (6, 'B', '2026-2027', 17, 17), (6, 'C', '2026-2027', 18, 18);

-- =========================================================================
-- 6. MATERIAS
-- =========================================================================
INSERT INTO materias (clave_materia, nombre, grado_sugerido) VALUES
('ESP-101',  'Español',                   1),
('MAT-101',  'Matemáticas',               1),
('CNAT-201', 'Ciencias Naturales',        3),
('HIST-301', 'Historia',                  4),
('GEO-401',  'Geografía',                 5),
('FCYE-501', 'Formación Cívica y Ética',  6),
('EDFI-001', 'Educación Física',          1),
('COMP-001', 'Computación',               1);

-- =========================================================================
-- 7. ALUMNOS (36) Y TUTORES EXCLUSIVOS (1 A 2 POR ALUMNO)
-- =========================================================================
DO $$
DECLARE
    v_alumnos TEXT[][] := ARRAY[
        ['LOGR190512HDFRRL01','Mateo','López','García','2019-05-12','1','María','Madre','Roberto','Padre'],
        ['VAMC190821MDFRRL02','Camila','Vargas','Mendoza','2019-08-21','1','Elena','Madre','Héctor','Abuelo/a'],
        ['RAMD190315HDFRRL03','Diego','Ramírez','Sánchez','2019-03-15','2','Laura','Madre','Jorge','Padre'],
        ['CASS191104MDFRRL04','Sofía','Castillo','Nava','2019-11-04','2','Patricia','Madre','',''],
        ['CRUE190622HDFRRL05','Emiliano','Cruz','Luna','2019-06-22','3','Miguel','Padre','Rosa','Abuelo/a'],
        ['FLOR190910MDFRRL06','Renata','Flores','Vega','2019-09-10','3','Diana','Madre','Carlos','Padre'],

        ['MARV180823MDFRRS07','Valentina','Martínez','Ruiz','2018-08-23','4','Ana','Madre','Luis','Padre'],
        ['HERL180419HDFRRS08','Leonardo','Herrera','Díaz','2018-04-19','4','Sofía','Madre','Pedro','Padre'],
        ['MORR180711MDFRRS09','Regina','Morales','Estrada','2018-07-11','5','Fernando','Padre','',''],
        ['ORTS180228HDFRRS10','Santiago','Ortega','Pérez','2018-02-28','5','Carmen','Madre','Andrés','Padre'],
        ['NAVX181005MDFRRS11','Ximena','Navarro','Silva','2018-10-05','6','Gabriela','Madre','Manuel','Abuelo/a'],
        ['PIND180117HDFRRS12','Daniel','Pineda','Castro','2018-01-17','6','Verónica','Madre','Sergio','Padre'],

        ['HERS170315HDFRRP13','Santiago','Hernández','Pérez','2017-03-15','7','Lucía','Madre','Raúl','Padre'],
        ['DELV170929MDFRRP14','Valeria','Delgado','Ríos','2017-09-29','7','Mónica','Madre','Iván','Padre'],
        ['GOMS170514HDFRRP15','Sebastián','Gómez','Castro','2017-05-14','8','Claudia','Madre','',''],
        ['REYL171120MDFRRP16','Lucía','Reyes','Torres','2017-11-20','8','Karla','Madre','Arturo','Padre'],
        ['MENA170408HDFRRP17','Alejandro','Mendoza','Rojas','2017-04-08','9','Javier','Padre','Teresa','Abuelo/a'],
        ['CHAP170816MDFRRP18','Paula','Chávez','León','2017-08-16','9','Sandra','Madre','Omar','Padre'],

        ['RAMC161104MDFRRL19','Camila','Ramírez','Solís','2016-11-04','10','Martha','Madre','Víctor','Padre'],
        ['SALG160612HDFRRL20','Gabriel','Salazar','Campos','2016-06-12','10','Beatriz','Madre','Rubén','Padre'],
        ['TORM160225MDFRRL21','Mariana','Torres','Díaz','2016-02-25','11','Leticia','Madre','Ernesto','Abuelo/a'],
        ['JIMN160903HDFRRL22','Nicolás','Jiménez','Vargas','2016-09-03','11','Adriana','Madre','',''],
        ['RIOI160518MDFRRL23','Isabella','Ríos','Cortés','2016-05-18','12','Paola','Madre','Gustavo','Padre'],
        ['AGUT161027HDFRRL24','Tomás','Aguilar','Rangel','2016-10-27','12','Nadia','Madre','Mario','Padre'],

        ['GOCS150719HDFRRJ25','Sebastián','Gómez','Juárez','2015-07-19','13','Rocío','Madre','César','Padre'],
        ['SOTA150309MDFRRJ26','Andrea','Soto','Valdez','2015-03-09','13','Fabiola','Madre','Hugo','Padre'],
        ['VELF150822HDFRRJ27','Fernando','Velázquez','Ibarra','2015-08-22','14','Enrique','Padre','José','Abuelo/a'],
        ['DOMN150130MDFRRJ28','Natalia','Domínguez','Bautista','2015-01-30','14','Silvia','Madre','',''],
        ['FUER150614HDFRRJ29','Ricardo','Fuentes','Camacho','2015-06-14','15','Norma','Madre','Alberto','Padre'],
        ['CABV151111MDFRRJ30','Victoria','Cabrera','Serrano','2015-11-11','15','Liliana','Madre','Rafael','Padre'],

        ['TORM140228MDFRRM31','Renata','Torres','Mora','2014-02-28','16','Alejandra','Madre','Rodrigo','Padre'],
        ['JIMS141008MDFRRM32','Sofía','Jiménez','Paredes','2014-10-08','16','Marisol','Madre','Guillermo','Padre'],
        ['MEDC140504HDFRRM33','Carlos','Medina','Guerrero','2014-05-04','17','David','Padre','',''],
        ['GUED140917MDFRRM34','Daniela','Guerrero','Silva','2014-09-17','17','Isabel','Madre','Guadalupe','Abuelo/a'],
        ['PARE140421HDFRRM35','Emilio','Paredes','Muñoz','2014-04-21','18','Rebeca','Madre','Salvador','Padre'],
        ['SILF140729MDFRRM36','Fernanda','Silva','Nava','2014-07-29','18','Alicia','Madre','Mauricio','Padre']
    ];
    i INT;
    v_id_t1 INT;
    v_id_t2 INT;
    v_id_al INT;
BEGIN
    FOR i IN 1..array_length(v_alumnos, 1) LOOP
        -- Tutor principal exclusivo
        INSERT INTO tutores (nombre, apellido_paterno, apellido_materno, correo, telefono, parentesco)
        VALUES (
            v_alumnos[i][7],
            v_alumnos[i][3],
            v_alumnos[i][4],
            'tutor' || i || '_1@familia.mx',
            '55' || LPAD((20000000 + i * 10 + 1)::TEXT, 8, '0'),
            v_alumnos[i][8]
        )
        RETURNING id_tutor INTO v_id_t1;

        -- Alumno vinculado a su tutor principal
        INSERT INTO alumnos (curp, nombre, apellido_paterno, apellido_materno, fecha_nacimiento, id_tutor, id_grupo)
        VALUES (
            v_alumnos[i][1],
            v_alumnos[i][2],
            v_alumnos[i][3],
            v_alumnos[i][4],
            v_alumnos[i][5]::DATE,
            v_id_t1,
            v_alumnos[i][6]::INT
        )
        RETURNING id_alumno INTO v_id_al;

        INSERT INTO alumno_tutores (id_alumno, id_tutor, es_principal)
        VALUES (v_id_al, v_id_t1, TRUE);

        -- Segundo tutor exclusivo (si aplica)
        IF v_alumnos[i][9] <> '' THEN
            INSERT INTO tutores (nombre, apellido_paterno, apellido_materno, correo, telefono, parentesco)
            VALUES (
                v_alumnos[i][9],
                v_alumnos[i][3],
                v_alumnos[i][4],
                'tutor' || i || '_2@familia.mx',
                '55' || LPAD((20000000 + i * 10 + 2)::TEXT, 8, '0'),
                v_alumnos[i][10]
            )
            RETURNING id_tutor INTO v_id_t2;

            INSERT INTO alumno_tutores (id_alumno, id_tutor, es_principal)
            VALUES (v_id_al, v_id_t2, FALSE);
        END IF;
    END LOOP;
END $$;

-- =========================================================================
-- 8. HORARIOS SEMANALES COMPLETOS (LUNES A VIERNES, 5 BLOQUES POR GRUPO)
-- =========================================================================
DO $$
DECLARE
    g RECORD;
    idx INT;
    d INT;
    s INT;
    dias TEXT[] := ARRAY['Lunes','Martes','Miercoles','Jueves','Viernes'];
    h_ini TIME[] := ARRAY['08:00'::TIME,'09:00'::TIME,'10:30'::TIME,'11:30'::TIME,'12:30'::TIME];
    h_fin TIME[] := ARRAY['09:00'::TIME,'10:00'::TIME,'11:30'::TIME,'12:30'::TIME,'13:30'::TIME];
    comp_d INT;
    comp_s INT;
    ef_d INT;
    ef_s INT;
    v_mat INT;
    v_doc INT;
    v_sal INT;
BEGIN
    FOR g IN SELECT id_grupo, grado, id_docente_titular, id_salon FROM grupos ORDER BY id_grupo LOOP
        idx := g.id_grupo - 1;
        -- Bloques únicos sin colisión para Cómputo (salón 19) y Ed. Física (salón 20)
        comp_d := (idx % 5) + 1;
        comp_s := (idx / 5) + 1;
        ef_d   := ((idx + 2) % 5) + 1;
        ef_s   := (idx / 5) + 2;

        FOR d IN 1..5 LOOP
            FOR s IN 1..5 LOOP
                IF d = comp_d AND s = comp_s THEN
                    v_mat := 8; -- Computación
                    v_doc := CASE WHEN g.grado <= 3 THEN 19 ELSE 20 END;
                    v_sal := 19; -- COMP-01
                ELSIF d = ef_d AND s = ef_s THEN
                    v_mat := 7; -- Educación Física
                    v_doc := CASE WHEN g.grado <= 3 THEN 21 ELSE 22 END;
                    v_sal := 20; -- CANCHA-01
                ELSE
                    v_mat := ((d + s + g.grado) % 6) + 1; -- Materias troncales 1..6
                    v_doc := g.id_docente_titular;
                    v_sal := g.id_salon;
                END IF;

                INSERT INTO horarios (id_grupo, id_materia, id_docente, id_salon, dia_semana, hora_inicio, hora_fin)
                VALUES (g.id_grupo, v_mat, v_doc, v_sal, dias[d], h_ini[s], h_fin[s]);
            END LOOP;
        END LOOP;
    END LOOP;
END $$;

-- =========================================================================
-- 9. USUARIOS (PERSONAL, 22 DOCENTES Y 36 FAMILIAS POR CURP)
-- =========================================================================
-- Personal administrativo y operativo (contraseña: primaria123)
INSERT INTO usuarios (usuario, correo, password_hash, rol, id_docente, id_alumno) VALUES
('director',       'director@primaria.edu.mx',       encode(sha256('primaria123'::bytea), 'hex'), 'Director',       NULL, NULL),
('secretaria',     'secretaria@primaria.edu.mx',     encode(sha256('primaria123'::bytea), 'hex'), 'Administrativo', NULL, NULL),
('finanzas',       'finanzas@primaria.edu.mx',       encode(sha256('primaria123'::bytea), 'hex'), 'Administrativo', NULL, NULL),
('enfermeria',     'enfermeria@primaria.edu.mx',     encode(sha256('primaria123'::bytea), 'hex'), 'Enfermeria',     NULL, NULL),
('cafeteria',      'cafeteria@primaria.edu.mx',      encode(sha256('primaria123'::bytea), 'hex'), 'Cafeteria',      NULL, NULL),
('mantenimiento',  'mantenimiento@primaria.edu.mx',  encode(sha256('primaria123'::bytea), 'hex'), 'Mantenimiento',  NULL, NULL);

-- 22 Docentes (contraseña: docente123)
INSERT INTO usuarios (usuario, correo, password_hash, rol, id_docente, id_alumno)
SELECT
    split_part(correo, '@', 1),
    correo,
    encode(sha256('docente123'::bytea), 'hex'),
    'Docente',
    id_docente,
    NULL
FROM docentes
ORDER BY id_docente;

-- 36 Alumnos / Portal de Padres por CURP (contraseña: familia123)
INSERT INTO usuarios (usuario, correo, password_hash, rol, id_docente, id_alumno)
SELECT
    TRIM(curp),
    LOWER(TRIM(curp)) || '@alumnos.primaria.edu.mx',
    encode(sha256('familia123'::bytea), 'hex'),
    'Alumno',
    NULL,
    id_alumno
FROM alumnos
ORDER BY id_alumno;

-- =========================================================================
-- 10. DATOS OPERATIVOS INICIALES (COLEGIATURAS, RECADOS, PERSONAL, ETC.)
-- =========================================================================
INSERT INTO periodos_colegiatura (nombre_periodo, monto_base, fecha_limite) VALUES
('Septiembre 2026', 2500.00, '2026-09-10'),
('Octubre 2026',    2500.00, '2026-10-10'),
('Noviembre 2026',  2500.00, '2026-11-10'),
('Diciembre 2026',  2500.00, '2026-12-10');

-- Pagos de ejemplo para los primeros alumnos
INSERT INTO pagos_colegiatura (id_alumno, id_periodo, fecha_pago, monto_pagado, metodo_pago, estatus, referencia)
SELECT a.id_alumno, p.id_periodo, CURRENT_TIMESTAMP - INTERVAL '10 days', 2500.00,
       CASE WHEN (a.id_alumno % 3) = 0 THEN 'Efectivo' WHEN (a.id_alumno % 3) = 1 THEN 'Transferencia' ELSE 'Tarjeta' END,
       'Pagado',
       'REF-2026-' || LPAD(a.id_alumno::TEXT, 2, '0') || '-' || p.id_periodo
FROM alumnos a
JOIN periodos_colegiatura p ON p.id_periodo <= CASE WHEN a.id_alumno <= 6 THEN 4 WHEN a.id_alumno <= 18 THEN 2 ELSE 1 END;

-- Plantilla de personal
INSERT INTO personal (clave_empleado, nombre, puesto, salario, area) VALUES
('EMP-100', 'Patricia Morales',   'Dirección',              22000.00, 'Dirección general (DIR-01)'),
('EMP-101', 'Sofía Herrera',      'Administrativo',         12500.00, 'Control escolar y colegiaturas'),
('EMP-102', 'Laura Domínguez',    'Personal de enfermería', 11200.00, 'Enfermería matutina (ENF-01)'),
('EMP-103', 'Jorge Salinas',      'Personal de cafetería',   9800.00, 'Cafetería escolar (CAF-01)'),
('EMP-104', 'Miguel Ángel Cruz',  'Mantenimiento',          10500.00, 'Instalaciones y mantenimiento'),
('EMP-105', 'Gabriela Mendoza',   'Docente titular',        14500.00, 'Grupo 1°A (Salón A-101)');

-- Calificaciones iniciales
INSERT INTO calificaciones (id_alumno, id_materia, creditos, calificacion)
SELECT a.id_alumno, m.id_materia, 8, ROUND((8.0 + ((a.id_alumno + m.id_materia) % 20) * 0.1)::NUMERIC, 2)
FROM alumnos a
JOIN materias m ON m.id_materia IN (1, 2, 3)
WHERE a.id_alumno <= 18;

-- Recados iniciales enviados por docentes (con tipos de respuesta)
INSERT INTO recados (id_grupo, id_alumno, id_docente, tipo, asunto, mensaje, tipo_respuesta, estatus) VALUES
(1, NULL, 1, 'Aviso',        'Junta de entrega de boletas 1°A', 'Favor de confirmar asistencia el viernes a las 08:30 en el salón A-101.', 'Confirmado', 'Enviado'),
(1, 1,    1, 'Recado',       'Material de matemáticas',         'Mateo requiere traer su ábaco y regla mañana.',                          'Leido',      'Enviado'),
(4, NULL, 4, 'Aviso',        'Salida cultural 2°A',             'Se solicita autorización para la visita al museo escolar.',              'Aceptado',   'Enviado'),
(7, NULL, 7, 'Cita',         'Seguimiento de lectura 3°A',      'Favor de escribir qué horario prefieren para la revisión semanal.',      'Texto',      'Enviado');

-- Una respuesta de ejemplo ya registrada por la familia de Mateo (1°A)
INSERT INTO recado_respuestas (id_recado, id_alumno, id_tutor, estado_respuesta, texto_respuesta)
VALUES (1, 1, 1, 'Confirmado', 'Asistiremos puntuales.');

-- Enfermería, Cafetería y Mantenimiento
INSERT INTO registros_enfermeria (id_alumno, id_usuario_atiende, motivo, observaciones, requirio_aviso_tutor, estatus) VALUES
(1, 4, 'Raspón en rodilla',    'Se limpió con antiséptico en el recreo.', FALSE, 'Atendido'),
(7, 4, 'Dolor de cabeza leve', 'Descansó 15 minutos con hidratación.',    TRUE,  'Atendido');

INSERT INTO ventas_cafeteria (folio, id_alumno, concepto, total, id_usuario_registra) VALUES
('V-901', 1, 'Desayuno paquete + agua', 35.00, 5),
('V-902', 7, 'Sándwich y fruta picada', 50.00, 5);

INSERT INTO reportes_mantenimiento (folio, ubicacion, descripcion, fecha_reporte, estado, id_usuario_registra) VALUES
('MANT-01', 'Edificio A, salón A-103', 'Revisión de luminaria principal', '2026-11-18', 'Completado', 6),
('MANT-02', 'Canchas (Malla Sombra)',  'Ajuste de tensor en malla sombra','2026-11-21', 'En proceso', 6);

COMMIT;
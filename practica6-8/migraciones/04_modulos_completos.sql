-- 04_modulos_completos.sql
-- Migración: integración completa de áreas escolares (Personal, Académico, Cafetería, Mantenimiento y 7 roles)

-- 1. Ampliar tabla usuarios para aceptar los 7 roles del sistema y acceso por usuario o correo
ALTER TABLE usuarios DROP CONSTRAINT IF EXISTS usuarios_rol_check;
ALTER TABLE usuarios
    ADD CONSTRAINT usuarios_rol_check
    CHECK (rol IN ('Director', 'Administrativo', 'Docente', 'Enfermeria', 'Cafeteria', 'Mantenimiento', 'Alumno'));

ALTER TABLE usuarios
    ADD COLUMN IF NOT EXISTS usuario VARCHAR(60) UNIQUE,
    ADD COLUMN IF NOT EXISTS id_alumno INTEGER UNIQUE REFERENCES alumnos(id_alumno)
        ON UPDATE CASCADE ON DELETE SET NULL;

-- Asignar nombres de usuario cortos a las cuentas creadas en la migración 03
UPDATE usuarios SET usuario = 'docente'        WHERE correo = 'g.mendoza@primaria.edu.mx';
UPDATE usuarios SET usuario = 'docente3'       WHERE correo = 'v.ortega@primaria.edu.mx';
UPDATE usuarios SET usuario = 'administrativo' WHERE correo = 'direccion@primaria.edu.mx';
UPDATE usuarios SET usuario = 'enfermeria'     WHERE correo = 'enfermeria@primaria.edu.mx';

-- Crear cuentas restantes (contraseña de prueba para todas: primaria123)
INSERT INTO usuarios (usuario, correo, password_hash, rol, id_docente, id_alumno) VALUES
('director',      'director@primaria.edu.mx',      encode(sha256('primaria123'::bytea), 'hex'), 'Director',      NULL, NULL),
('cafeteria',     'cafeteria@primaria.edu.mx',     encode(sha256('primaria123'::bytea), 'hex'), 'Cafeteria',     NULL, NULL),
('mantenimiento', 'mantenimiento@primaria.edu.mx', encode(sha256('primaria123'::bytea), 'hex'), 'Mantenimiento', NULL, NULL),
('2026-PRI-001',  'mateo.lopez@primaria.edu.mx',   encode(sha256('primaria123'::bytea), 'hex'), 'Alumno',        NULL, 1),
('2026-PRI-002',  'valentina.m@primaria.edu.mx',   encode(sha256('primaria123'::bytea), 'hex'), 'Alumno',        NULL, 2);

-- 2. Plantilla de personal escolar
CREATE TABLE personal (
    id_empleado SERIAL PRIMARY KEY,
    clave_empleado VARCHAR(20) NOT NULL UNIQUE,
    nombre VARCHAR(120) NOT NULL,
    puesto VARCHAR(40) NOT NULL
        CHECK (puesto IN ('Dirección', 'Administrativo', 'Docente titular', 'Personal de enfermería', 'Personal de cafetería', 'Mantenimiento')),
    salario NUMERIC(10, 2) NOT NULL CHECK (salario > 0),
    area VARCHAR(120) NOT NULL,
    activo BOOLEAN NOT NULL DEFAULT TRUE
);

INSERT INTO personal (clave_empleado, nombre, puesto, salario, area) VALUES
('EMP-100', 'Patricia Morales',   'Dirección',              22000.00, 'Dirección general'),
('EMP-101', 'Gabriela Mendoza',   'Docente titular',        14500.00, 'Educación Primaria 1°A'),
('EMP-102', 'Laura Domínguez',    'Personal de enfermería', 11200.00, 'Primeros auxilios, turno matutino'),
('EMP-103', 'Jorge Salinas',      'Personal de cafetería',   9800.00, 'Turno matutino, operación de caja'),
('EMP-104', 'Miguel Ángel Cruz',  'Mantenimiento',          10500.00, 'Instalaciones eléctricas e hidráulicas'),
('EMP-105', 'Sofía Herrera',      'Administrativo',         12000.00, 'Control escolar y colegiaturas');

-- 3. Calificaciones (Gestión académica)
CREATE TABLE calificaciones (
    id_calificacion SERIAL PRIMARY KEY,
    id_alumno INTEGER NOT NULL REFERENCES alumnos(id_alumno)
        ON UPDATE CASCADE ON DELETE CASCADE,
    id_materia INTEGER NOT NULL REFERENCES materias(id_materia)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    creditos SMALLINT NOT NULL DEFAULT 8 CHECK (creditos > 0),
    calificacion NUMERIC(4, 2) NOT NULL CHECK (calificacion >= 0 AND calificacion <= 10),
    ciclo_escolar VARCHAR(20) NOT NULL DEFAULT '2026-2027',
    UNIQUE (id_alumno, id_materia, ciclo_escolar)
);

INSERT INTO calificaciones (id_alumno, id_materia, creditos, calificacion) VALUES
(1, 1, 8, 9.5),
(1, 2, 8, 9.2),
(2, 1, 8, 9.0),
(2, 3, 7, 8.8),
(3, 2, 8, 8.5),
(4, 3, 7, 9.4);

-- 4. Ventas de cafetería
CREATE TABLE ventas_cafeteria (
    id_venta SERIAL PRIMARY KEY,
    folio VARCHAR(20) NOT NULL UNIQUE,
    fecha_hora TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    id_alumno INTEGER NOT NULL REFERENCES alumnos(id_alumno)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    concepto VARCHAR(120) NOT NULL DEFAULT 'Consumo escolar',
    total NUMERIC(8, 2) NOT NULL CHECK (total > 0),
    id_usuario_registra INTEGER REFERENCES usuarios(id_usuario)
        ON UPDATE CASCADE ON DELETE SET NULL
);

INSERT INTO ventas_cafeteria (folio, id_alumno, concepto, total, id_usuario_registra) VALUES
('V-901', 1, 'Desayuno paquete + agua', 35.00, 6),
('V-902', 2, 'Sándwich y fruta picada', 50.00, 6),
('V-903', 3, 'Molletes y jugo natural', 45.00, 6);

-- 5. Reportes de mantenimiento
CREATE TABLE reportes_mantenimiento (
    id_reporte SERIAL PRIMARY KEY,
    folio VARCHAR(20) NOT NULL UNIQUE,
    ubicacion VARCHAR(120) NOT NULL,
    descripcion TEXT NOT NULL,
    fecha_reporte DATE NOT NULL DEFAULT CURRENT_DATE,
    estado VARCHAR(20) NOT NULL DEFAULT 'Pendiente'
        CHECK (estado IN ('Pendiente', 'En proceso', 'Completado')),
    id_usuario_registra INTEGER REFERENCES usuarios(id_usuario)
        ON UPDATE CASCADE ON DELETE SET NULL
);

INSERT INTO reportes_mantenimiento (folio, ubicacion, descripcion, fecha_reporte, estado, id_usuario_registra) VALUES
('MANT-01', 'Edificio A, salón A-103', 'Reparación de luminaria principal', '2026-11-10', 'Completado', 7),
('MANT-02', 'Sanitarios planta baja',  'Mantenimiento preventivo en llave de lavabo', '2026-11-18', 'En proceso', 7),
('MANT-03', 'Patio central (Cancha)',  'Pintura de líneas reglamentarias', '2026-11-20', 'Pendiente', 7);
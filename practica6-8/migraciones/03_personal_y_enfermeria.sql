-- 03_personal_y_enfermeria.sql
-- Migración: usuarios con roles para personal y bitácora de enfermería

CREATE TABLE usuarios (
    id_usuario SERIAL PRIMARY KEY,
    correo VARCHAR(120) NOT NULL UNIQUE,
    password_hash CHAR(64) NOT NULL,
    rol VARCHAR(20) NOT NULL
        CHECK (rol IN ('Docente', 'Administrativo', 'Enfermeria')),
    id_docente INTEGER UNIQUE REFERENCES docentes(id_docente)
        ON UPDATE CASCADE ON DELETE SET NULL,
    activo BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE registros_enfermeria (
    id_atencion SERIAL PRIMARY KEY,
    id_alumno INTEGER NOT NULL REFERENCES alumnos(id_alumno)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    id_usuario_atiende INTEGER NOT NULL REFERENCES usuarios(id_usuario)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    fecha_hora TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    motivo VARCHAR(120) NOT NULL,
    observaciones TEXT NOT NULL,
    requirio_aviso_tutor BOOLEAN NOT NULL DEFAULT FALSE,
    estatus VARCHAR(20) NOT NULL DEFAULT 'Atendido'
        CHECK (estatus IN ('En observacion', 'Atendido', 'Canalizado'))
);

-- Usuarios iniciales (contraseña de prueba: primaria123)
INSERT INTO usuarios (correo, password_hash, rol, id_docente) VALUES
('g.mendoza@primaria.edu.mx', encode(sha256('primaria123'::bytea), 'hex'), 'Docente', 1),
('v.ortega@primaria.edu.mx',  encode(sha256('primaria123'::bytea), 'hex'), 'Docente', 3),
('direccion@primaria.edu.mx', encode(sha256('primaria123'::bytea), 'hex'), 'Administrativo', NULL),
('enfermeria@primaria.edu.mx', encode(sha256('primaria123'::bytea), 'hex'), 'Enfermeria', NULL);

-- Atenciones iniciales de enfermería
INSERT INTO registros_enfermeria (id_alumno, id_usuario_atiende, motivo, observaciones, requirio_aviso_tutor, estatus) VALUES
(1, 4, 'Raspon en rodilla', 'Se limpió con antiséptico durante el recreo y regresó a clase.', FALSE, 'Atendido'),
(3, 4, 'Dolor de cabeza leve', 'Descansó 15 minutos e hidratación. Sin fiebre.', FALSE, 'Atendido'),
(5, 4, 'Alergia estacional', 'Presentó congestión leve; coincide con recado del tutor.', TRUE, 'En observacion'),
(10, 4, 'Molestia en tobillo', 'Se aplicó compresa fría después de Educación Física.', TRUE, 'Atendido');
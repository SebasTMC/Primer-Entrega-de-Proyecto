-- 01_creacion.sql
-- Esquema base para Proyecto_Primaria (PostgreSQL)

CREATE TABLE tutores (
    id_tutor SERIAL PRIMARY KEY,
    nombre VARCHAR(80) NOT NULL,
    apellido_paterno VARCHAR(80) NOT NULL,
    apellido_materno VARCHAR(80),
    correo VARCHAR(120) NOT NULL UNIQUE,
    telefono VARCHAR(20) NOT NULL,
    parentesco VARCHAR(30) NOT NULL
        CHECK (parentesco IN ('Madre', 'Padre', 'Tutor Legal', 'Abuelo/a', 'Otro'))
);

CREATE TABLE docentes (
    id_docente SERIAL PRIMARY KEY,
    num_empleado VARCHAR(20) NOT NULL UNIQUE,
    nombre VARCHAR(80) NOT NULL,
    apellido_paterno VARCHAR(80) NOT NULL,
    correo VARCHAR(120) NOT NULL UNIQUE,
    especialidad VARCHAR(80) NOT NULL,
    activo BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE salones (
    id_salon SERIAL PRIMARY KEY,
    clave_salon VARCHAR(15) NOT NULL UNIQUE,
    edificio VARCHAR(30) NOT NULL,
    planta VARCHAR(20) NOT NULL CHECK (planta IN ('Planta Baja', 'Planta Alta')),
    capacidad INTEGER NOT NULL CHECK (capacidad > 0 AND capacidad <= 60),
    codigo_svg VARCHAR(30) NOT NULL UNIQUE
);

CREATE TABLE grupos (
    id_grupo SERIAL PRIMARY KEY,
    grado SMALLINT NOT NULL CHECK (grado BETWEEN 1 AND 6),
    letra CHAR(1) NOT NULL CHECK (letra ~ '^[A-F]$'),
    ciclo_escolar VARCHAR(15) NOT NULL,
    id_docente_titular INTEGER NOT NULL REFERENCES docentes(id_docente)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    UNIQUE (grado, letra, ciclo_escolar)
);

CREATE TABLE alumnos (
    id_alumno SERIAL PRIMARY KEY,
    curp CHAR(18) NOT NULL UNIQUE,
    nombre VARCHAR(80) NOT NULL,
    apellido_paterno VARCHAR(80) NOT NULL,
    apellido_materno VARCHAR(80),
    fecha_nacimiento DATE NOT NULL,
    id_tutor INTEGER NOT NULL REFERENCES tutores(id_tutor)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    id_grupo INTEGER NOT NULL REFERENCES grupos(id_grupo)
        ON UPDATE CASCADE ON DELETE RESTRICT
);

CREATE TABLE materias (
    id_materia SERIAL PRIMARY KEY,
    clave_materia VARCHAR(15) NOT NULL UNIQUE,
    nombre VARCHAR(80) NOT NULL,
    grado_sugerido SMALLINT NOT NULL CHECK (grado_sugerido BETWEEN 1 AND 6)
);

CREATE TABLE horarios (
    id_horario SERIAL PRIMARY KEY,
    id_grupo INTEGER NOT NULL REFERENCES grupos(id_grupo)
        ON UPDATE CASCADE ON DELETE CASCADE,
    id_materia INTEGER NOT NULL REFERENCES materias(id_materia)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    id_docente INTEGER NOT NULL REFERENCES docentes(id_docente)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    id_salon INTEGER NOT NULL REFERENCES salones(id_salon)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    dia_semana VARCHAR(15) NOT NULL
        CHECK (dia_semana IN ('Lunes', 'Martes', 'Miercoles', 'Jueves', 'Viernes')),
    hora_inicio TIME NOT NULL,
    hora_fin TIME NOT NULL,
    CHECK (hora_fin > hora_inicio),
    UNIQUE (id_salon, dia_semana, hora_inicio),
    UNIQUE (id_grupo, dia_semana, hora_inicio)
);

CREATE TABLE periodos_colegiatura (
    id_periodo SERIAL PRIMARY KEY,
    nombre_periodo VARCHAR(40) NOT NULL UNIQUE,
    monto_base NUMERIC(10, 2) NOT NULL CHECK (monto_base > 0),
    fecha_limite DATE NOT NULL
);

CREATE TABLE pagos_colegiatura (
    id_pago SERIAL PRIMARY KEY,
    id_alumno INTEGER NOT NULL REFERENCES alumnos(id_alumno)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    id_periodo INTEGER NOT NULL REFERENCES periodos_colegiatura(id_periodo)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    fecha_pago TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    monto_pagado NUMERIC(10, 2) NOT NULL CHECK (monto_pagado > 0),
    metodo_pago VARCHAR(20) NOT NULL
        CHECK (metodo_pago IN ('Tarjeta', 'Transferencia', 'Efectivo')),
    estatus VARCHAR(15) NOT NULL DEFAULT 'Pagado'
        CHECK (estatus IN ('Pagado', 'Parcial', 'Pendiente')),
    referencia VARCHAR(40) NOT NULL UNIQUE,
    UNIQUE (id_alumno, id_periodo)
);

CREATE TABLE recados (
    id_recado SERIAL PRIMARY KEY,
    id_tutor INTEGER NOT NULL REFERENCES tutores(id_tutor)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    id_alumno INTEGER NOT NULL REFERENCES alumnos(id_alumno)
        ON UPDATE CASCADE ON DELETE CASCADE,
    id_docente INTEGER NOT NULL REFERENCES docentes(id_docente)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    tipo VARCHAR(20) NOT NULL
        CHECK (tipo IN ('Recado', 'Justificante', 'Aviso', 'Cita')),
    asunto VARCHAR(100) NOT NULL,
    mensaje TEXT NOT NULL,
    estatus VARCHAR(15) NOT NULL DEFAULT 'Enviado'
        CHECK (estatus IN ('Enviado', 'Leido', 'Atendido')),
    fecha_envio TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
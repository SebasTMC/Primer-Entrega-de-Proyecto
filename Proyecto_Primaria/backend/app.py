import os
import hashlib
from flask import Flask, request, jsonify
from flask_cors import CORS
import psycopg2
from psycopg2.extras import RealDictCursor
from dotenv import load_dotenv

load_dotenv()

app = Flask(__name__)
CORS(app)


def get_connection():
    database_url = os.getenv("DATABASE_URL")
    if database_url:
        return psycopg2.connect(database_url, cursor_factory=RealDictCursor)
    return psycopg2.connect(
        host=os.getenv("DB_HOST", "db"),
        port=os.getenv("DB_PORT", "5432"),
        dbname=os.getenv("DB_NAME", "primaria_db"),
        user=os.getenv("DB_USER", "postgres"),
        password=os.getenv("DB_PASSWORD", "primaria_dev"),
        cursor_factory=RealDictCursor,
    )


@app.route("/health", methods=["GET"])
def health():
    return jsonify({"ok": True, "servicio": "Proyecto_Primaria API"}), 200


# ---------------- LOGIN ----------------
@app.route("/api/login", methods=["POST"])
def login():
    datos = request.get_json(force=True)
    identificador = (datos.get("usuario") or datos.get("correo") or "").strip().lower()
    password = datos.get("password", "")
    pwd_hash = hashlib.sha256(password.encode("utf-8")).hexdigest()

    conn = get_connection()
    try:
        with conn.cursor() as cur:
            cur.execute("""
                SELECT u.id_usuario, u.usuario, u.correo, u.rol, u.id_docente, u.id_alumno,
                       COALESCE(
                           d.nombre || ' ' || d.apellido_paterno,
                           a.nombre || ' ' || a.apellido_paterno,
                           u.rol
                       ) AS nombre
                FROM usuarios u
                LEFT JOIN docentes d ON d.id_docente = u.id_docente
                LEFT JOIN alumnos a ON a.id_alumno = u.id_alumno
                WHERE (LOWER(u.usuario) = %s OR LOWER(u.correo) = %s)
                  AND u.password_hash = %s
                  AND u.activo = TRUE;
            """, (identificador, identificador, pwd_hash))
            usuario = cur.fetchone()
        if not usuario:
            return jsonify({"ok": False, "error": "Usuario o contraseña incorrectos."}), 401
        return jsonify({"ok": True, "usuario": usuario}), 200
    finally:
        conn.close()


# ---------------- CATÁLOGOS ----------------
@app.route("/api/catalogos", methods=["GET"])
def obtener_catalogos():
    conn = get_connection()
    try:
        with conn.cursor() as cur:
            cur.execute("""
                SELECT a.id_alumno, a.curp,
                       a.nombre || ' ' || a.apellido_paterno AS alumno,
                       a.id_tutor, a.id_grupo,
                       g.grado || '°' || g.letra AS grupo
                FROM alumnos a
                JOIN grupos g ON g.id_grupo = a.id_grupo
                ORDER BY a.id_alumno;
            """)
            alumnos = cur.fetchall()

            cur.execute("""
                SELECT id_tutor, nombre || ' ' || apellido_paterno AS tutor, parentesco, telefono
                FROM tutores ORDER BY id_tutor;
            """)
            tutores = cur.fetchall()

            cur.execute("""
                SELECT id_docente, nombre || ' ' || apellido_paterno AS docente, especialidad
                FROM docentes WHERE activo = TRUE ORDER BY id_docente;
            """)
            docentes = cur.fetchall()

            cur.execute("""
                SELECT id_grupo, grado || '°' || letra AS grupo, ciclo_escolar
                FROM grupos ORDER BY grado, letra;
            """)
            grupos = cur.fetchall()

            cur.execute("""
                SELECT id_materia, clave_materia, nombre, grado_sugerido
                FROM materias ORDER BY id_materia;
            """)
            materias = cur.fetchall()

            cur.execute("""
                SELECT id_periodo, nombre_periodo, monto_base,
                       TO_CHAR(fecha_limite, 'YYYY-MM-DD') AS fecha_limite
                FROM periodos_colegiatura ORDER BY id_periodo;
            """)
            periodos = cur.fetchall()

            cur.execute("""
                SELECT id_salon, clave_salon, edificio, planta, capacidad, codigo_svg
                FROM salones ORDER BY id_salon;
            """)
            salones = cur.fetchall()

        return jsonify({
            "alumnos": alumnos,
            "tutores": tutores,
            "docentes": docentes,
            "grupos": grupos,
            "materias": materias,
            "periodos": periodos,
            "salones": salones,
        }), 200
    finally:
        conn.close()


# ---------------- ALUMNOS ----------------
@app.route("/api/alumnos", methods=["GET", "POST"])
def manejar_alumnos():
    conn = get_connection()
    try:
        if request.method == "GET":
            with conn.cursor() as cur:
                cur.execute("""
                    SELECT a.id_alumno, a.curp,
                           a.nombre || ' ' || a.apellido_paterno || COALESCE(' ' || a.apellido_materno, '') AS nombre_completo,
                           TO_CHAR(a.fecha_nacimiento, 'YYYY-MM-DD') AS fecha_nacimiento,
                           a.id_grupo, g.grado || '°' || g.letra AS grupo,
                           a.id_tutor, t.nombre || ' ' || t.apellido_paterno AS tutor, t.telefono
                    FROM alumnos a
                    JOIN grupos g ON g.id_grupo = a.id_grupo
                    JOIN tutores t ON t.id_tutor = a.id_tutor
                    ORDER BY a.id_alumno;
                """)
                return jsonify(cur.fetchall()), 200

        d = request.get_json(force=True)
        with conn.cursor() as cur:
            cur.execute("""
                INSERT INTO alumnos (curp, nombre, apellido_paterno, apellido_materno, fecha_nacimiento, id_tutor, id_grupo)
                VALUES (%s, %s, %s, %s, %s, %s, %s)
                RETURNING id_alumno, curp;
            """, (
                d["curp"].strip().upper(),
                d["nombre"].strip(),
                d["apellido_paterno"].strip(),
                d.get("apellido_materno", "").strip() or None,
                d["fecha_nacimiento"],
                d["id_tutor"],
                d["id_grupo"],
            ))
            nuevo = cur.fetchone()
        conn.commit()
        return jsonify({"ok": True, "alumno": nuevo}), 201
    except Exception as e:
        conn.rollback()
        return jsonify({"ok": False, "error": str(e)}), 400
    finally:
        conn.close()


@app.route("/api/alumnos/<int:id_alumno>", methods=["DELETE"])
def eliminar_alumno(id_alumno):
    conn = get_connection()
    try:
        with conn.cursor() as cur:
            cur.execute("DELETE FROM alumnos WHERE id_alumno = %s RETURNING id_alumno;", (id_alumno,))
            borrado = cur.fetchone()
        if not borrado:
            return jsonify({"ok": False, "error": "Alumno no encontrado"}), 404
        conn.commit()
        return jsonify({"ok": True}), 200
    except Exception as e:
        conn.rollback()
        return jsonify({"ok": False, "error": str(e)}), 400
    finally:
        conn.close()


# ---------------- CALIFICACIONES (ACADÉMICO) ----------------
@app.route("/api/calificaciones", methods=["GET", "POST"])
def manejar_calificaciones():
    id_alumno = request.args.get("id_alumno")
    conn = get_connection()
    try:
        if request.method == "GET":
            with conn.cursor() as cur:
                if id_alumno:
                    cur.execute("""
                        SELECT c.id_calificacion, c.id_alumno, a.curp,
                               a.nombre || ' ' || a.apellido_paterno AS alumno,
                               c.id_materia, m.nombre AS materia,
                               c.creditos, c.calificacion, c.ciclo_escolar
                        FROM calificaciones c
                        JOIN alumnos a ON a.id_alumno = c.id_alumno
                        JOIN materias m ON m.id_materia = c.id_materia
                        WHERE c.id_alumno = %s
                        ORDER BY m.nombre;
                    """, (id_alumno,))
                else:
                    cur.execute("""
                        SELECT c.id_calificacion, c.id_alumno, a.curp,
                               a.nombre || ' ' || a.apellido_paterno AS alumno,
                               c.id_materia, m.nombre AS materia,
                               c.creditos, c.calificacion, c.ciclo_escolar
                        FROM calificaciones c
                        JOIN alumnos a ON a.id_alumno = c.id_alumno
                        JOIN materias m ON m.id_materia = c.id_materia
                        ORDER BY c.id_calificacion DESC;
                    """)
                return jsonify(cur.fetchall()), 200

        d = request.get_json(force=True)
        with conn.cursor() as cur:
            cur.execute("""
                INSERT INTO calificaciones (id_alumno, id_materia, creditos, calificacion, ciclo_escolar)
                VALUES (%s, %s, %s, %s, %s)
                ON CONFLICT (id_alumno, id_materia, ciclo_escolar)
                DO UPDATE SET creditos = EXCLUDED.creditos, calificacion = EXCLUDED.calificacion
                RETURNING id_calificacion, calificacion;
            """, (
                d["id_alumno"],
                d["id_materia"],
                d.get("creditos", 8),
                d["calificacion"],
                d.get("ciclo_escolar", "2026-2027"),
            ))
            nuevo = cur.fetchone()
        conn.commit()
        return jsonify({"ok": True, "calificacion": nuevo}), 201
    except Exception as e:
        conn.rollback()
        return jsonify({"ok": False, "error": str(e)}), 400
    finally:
        conn.close()


@app.route("/api/calificaciones/<int:id_cal>", methods=["DELETE"])
def eliminar_calificacion(id_cal):
    conn = get_connection()
    try:
        with conn.cursor() as cur:
            cur.execute("DELETE FROM calificaciones WHERE id_calificacion = %s RETURNING id_calificacion;", (id_cal,))
            if not cur.fetchone():
                return jsonify({"ok": False, "error": "Registro no encontrado"}), 404
        conn.commit()
        return jsonify({"ok": True}), 200
    except Exception as e:
        conn.rollback()
        return jsonify({"ok": False, "error": str(e)}), 400
    finally:
        conn.close()


# ---------------- HORARIOS ----------------
@app.route("/api/horarios", methods=["GET", "POST"])
def manejar_horarios():
    id_docente = request.args.get("id_docente")
    id_grupo = request.args.get("id_grupo")
    conn = get_connection()
    try:
        if request.method == "GET":
            with conn.cursor() as cur:
                query = """
                    SELECT h.id_horario, h.dia_semana,
                           TO_CHAR(h.hora_inicio, 'HH24:MI') AS hora_inicio,
                           TO_CHAR(h.hora_fin, 'HH24:MI') AS hora_fin,
                           g.grado || '°' || g.letra AS grupo,
                           m.nombre AS materia,
                           s.clave_salon, s.edificio,
                           d.nombre || ' ' || d.apellido_paterno AS docente
                    FROM horarios h
                    JOIN grupos g ON g.id_grupo = h.id_grupo
                    JOIN materias m ON m.id_materia = h.id_materia
                    JOIN salones s ON s.id_salon = h.id_salon
                    JOIN docentes d ON d.id_docente = h.id_docente
                """
                params = []
                filtros = []
                if id_docente:
                    filtros.append("h.id_docente = %s")
                    params.append(id_docente)
                if id_grupo:
                    filtros.append("h.id_grupo = %s")
                    params.append(id_grupo)
                if filtros:
                    query += " WHERE " + " AND ".join(filtros)
                query += " ORDER BY h.hora_inicio, g.grado;"
                cur.execute(query, tuple(params))
                return jsonify(cur.fetchall()), 200

        d = request.get_json(force=True)
        with conn.cursor() as cur:
            cur.execute("""
                INSERT INTO horarios (id_grupo, id_materia, id_docente, id_salon, dia_semana, hora_inicio, hora_fin)
                VALUES (%s, %s, %s, %s, %s, %s, %s)
                RETURNING id_horario;
            """, (
                d["id_grupo"], d["id_materia"], d["id_docente"], d["id_salon"],
                d["dia_semana"], d["hora_inicio"], d["hora_fin"],
            ))
            nuevo = cur.fetchone()
        conn.commit()
        return jsonify({"ok": True, "horario": nuevo}), 201
    except Exception as e:
        conn.rollback()
        return jsonify({"ok": False, "error": str(e)}), 400
    finally:
        conn.close()


@app.route("/api/horarios/<int:id_horario>", methods=["DELETE"])
def eliminar_horario(id_horario):
    conn = get_connection()
    try:
        with conn.cursor() as cur:
            cur.execute("DELETE FROM horarios WHERE id_horario = %s RETURNING id_horario;", (id_horario,))
            if not cur.fetchone():
                return jsonify({"ok": False, "error": "Horario no encontrado"}), 404
        conn.commit()
        return jsonify({"ok": True}), 200
    except Exception as e:
        conn.rollback()
        return jsonify({"ok": False, "error": str(e)}), 400
    finally:
        conn.close()


# ---------------- PERSONAL ----------------
@app.route("/api/personal", methods=["GET", "POST"])
def manejar_personal():
    conn = get_connection()
    try:
        if request.method == "GET":
            with conn.cursor() as cur:
                cur.execute("""
                    SELECT id_empleado, clave_empleado, nombre, puesto, salario, area, activo
                    FROM personal ORDER BY id_empleado;
                """)
                return jsonify(cur.fetchall()), 200

        d = request.get_json(force=True)
        with conn.cursor() as cur:
            cur.execute("""
                INSERT INTO personal (clave_empleado, nombre, puesto, salario, area)
                VALUES (%s, %s, %s, %s, %s)
                RETURNING id_empleado, clave_empleado;
            """, (d["clave_empleado"], d["nombre"], d["puesto"], d["salario"], d["area"]))
            nuevo = cur.fetchone()
        conn.commit()
        return jsonify({"ok": True, "empleado": nuevo}), 201
    except Exception as e:
        conn.rollback()
        return jsonify({"ok": False, "error": str(e)}), 400
    finally:
        conn.close()


@app.route("/api/personal/<int:id_emp>", methods=["DELETE"])
def eliminar_personal(id_emp):
    conn = get_connection()
    try:
        with conn.cursor() as cur:
            cur.execute("DELETE FROM personal WHERE id_empleado = %s RETURNING id_empleado;", (id_emp,))
            if not cur.fetchone():
                return jsonify({"ok": False, "error": "Empleado no encontrado"}), 404
        conn.commit()
        return jsonify({"ok": True}), 200
    except Exception as e:
        conn.rollback()
        return jsonify({"ok": False, "error": str(e)}), 400
    finally:
        conn.close()


# ---------------- ENFERMERÍA ----------------
@app.route("/api/enfermeria", methods=["GET", "POST"])
def manejar_enfermeria():
    conn = get_connection()
    try:
        if request.method == "GET":
            with conn.cursor() as cur:
                cur.execute("""
                    SELECT e.id_atencion,
                           TO_CHAR(e.fecha_hora, 'YYYY-MM-DD HH24:MI') AS fecha_hora,
                           e.motivo, e.observaciones, e.requirio_aviso_tutor, e.estatus,
                           a.nombre || ' ' || a.apellido_paterno AS alumno,
                           g.grado || '°' || g.letra AS grupo,
                           u.correo AS atendio
                    FROM registros_enfermeria e
                    JOIN alumnos a ON a.id_alumno = e.id_alumno
                    JOIN grupos g ON g.id_grupo = a.id_grupo
                    JOIN usuarios u ON u.id_usuario = e.id_usuario_atiende
                    ORDER BY e.fecha_hora DESC, e.id_atencion DESC
                    LIMIT 50;
                """)
                return jsonify(cur.fetchall()), 200

        d = request.get_json(force=True)
        with conn.cursor() as cur:
            cur.execute("""
                INSERT INTO registros_enfermeria
                    (id_alumno, id_usuario_atiende, motivo, observaciones, requirio_aviso_tutor, estatus)
                VALUES (%s, %s, %s, %s, %s, %s)
                RETURNING id_atencion, estatus;
            """, (
                d["id_alumno"],
                d["id_usuario_atiende"],
                d["motivo"],
                d["observaciones"],
                bool(d.get("requirio_aviso_tutor", False)),
                d.get("estatus", "Atendido"),
            ))
            nuevo = cur.fetchone()
        conn.commit()
        return jsonify({"ok": True, "atencion": nuevo}), 201
    except Exception as e:
        conn.rollback()
        return jsonify({"ok": False, "error": str(e)}), 400
    finally:
        conn.close()


@app.route("/api/enfermeria/<int:id_at>", methods=["PATCH", "DELETE"])
def actualizar_enfermeria(id_at):
    conn = get_connection()
    try:
        if request.method == "DELETE":
            with conn.cursor() as cur:
                cur.execute("DELETE FROM registros_enfermeria WHERE id_atencion = %s RETURNING id_atencion;", (id_at,))
                if not cur.fetchone():
                    return jsonify({"ok": False, "error": "Registro no encontrado"}), 404
            conn.commit()
            return jsonify({"ok": True}), 200

        d = request.get_json(force=True)
        with conn.cursor() as cur:
            cur.execute("""
                UPDATE registros_enfermeria SET estatus = %s
                WHERE id_atencion = %s RETURNING id_atencion, estatus;
            """, (d["estatus"], id_at))
            act = cur.fetchone()
        if not act:
            return jsonify({"ok": False, "error": "Registro no encontrado"}), 404
        conn.commit()
        return jsonify({"ok": True, "atencion": act}), 200
    except Exception as e:
        conn.rollback()
        return jsonify({"ok": False, "error": str(e)}), 400
    finally:
        conn.close()


# ---------------- CAFETERÍA ----------------
@app.route("/api/cafeteria", methods=["GET", "POST"])
def manejar_cafeteria():
    conn = get_connection()
    try:
        if request.method == "GET":
            with conn.cursor() as cur:
                cur.execute("""
                    SELECT v.id_venta, v.folio,
                           TO_CHAR(v.fecha_hora, 'YYYY-MM-DD HH24:MI') AS fecha_hora,
                           a.nombre || ' ' || a.apellido_paterno AS alumno,
                           v.concepto, v.total
                    FROM ventas_cafeteria v
                    JOIN alumnos a ON a.id_alumno = v.id_alumno
                    ORDER BY v.fecha_hora DESC, v.id_venta DESC
                    LIMIT 50;
                """)
                return jsonify(cur.fetchall()), 200

        d = request.get_json(force=True)
        with conn.cursor() as cur:
            cur.execute("""
                INSERT INTO ventas_cafeteria (folio, id_alumno, concepto, total, id_usuario_registra)
                VALUES (%s, %s, %s, %s, %s)
                RETURNING id_venta, folio;
            """, (d["folio"], d["id_alumno"], d.get("concepto", "Consumo escolar"), d["total"], d.get("id_usuario_registra")))
            nuevo = cur.fetchone()
        conn.commit()
        return jsonify({"ok": True, "venta": nuevo}), 201
    except Exception as e:
        conn.rollback()
        return jsonify({"ok": False, "error": str(e)}), 400
    finally:
        conn.close()


@app.route("/api/cafeteria/<int:id_venta>", methods=["DELETE"])
def eliminar_venta(id_venta):
    conn = get_connection()
    try:
        with conn.cursor() as cur:
            cur.execute("DELETE FROM ventas_cafeteria WHERE id_venta = %s RETURNING id_venta;", (id_venta,))
            if not cur.fetchone():
                return jsonify({"ok": False, "error": "Venta no encontrada"}), 404
        conn.commit()
        return jsonify({"ok": True}), 200
    except Exception as e:
        conn.rollback()
        return jsonify({"ok": False, "error": str(e)}), 400
    finally:
        conn.close()


# ---------------- MANTENIMIENTO ----------------
@app.route("/api/mantenimiento", methods=["GET", "POST"])
def manejar_mantenimiento():
    conn = get_connection()
    try:
        if request.method == "GET":
            with conn.cursor() as cur:
                cur.execute("""
                    SELECT id_reporte, folio, ubicacion, descripcion,
                           TO_CHAR(fecha_reporte, 'YYYY-MM-DD') AS fecha_reporte, estado
                    FROM reportes_mantenimiento
                    ORDER BY id_reporte DESC;
                """)
                return jsonify(cur.fetchall()), 200

        d = request.get_json(force=True)
        with conn.cursor() as cur:
            cur.execute("""
                INSERT INTO reportes_mantenimiento (folio, ubicacion, descripcion, estado, id_usuario_registra)
                VALUES (%s, %s, %s, %s, %s)
                RETURNING id_reporte, folio;
            """, (d["folio"], d["ubicacion"], d["descripcion"], d.get("estado", "Pendiente"), d.get("id_usuario_registra")))
            nuevo = cur.fetchone()
        conn.commit()
        return jsonify({"ok": True, "reporte": nuevo}), 201
    except Exception as e:
        conn.rollback()
        return jsonify({"ok": False, "error": str(e)}), 400
    finally:
        conn.close()


@app.route("/api/mantenimiento/<int:id_rep>", methods=["PATCH", "DELETE"])
def actualizar_mantenimiento(id_rep):
    conn = get_connection()
    try:
        if request.method == "DELETE":
            with conn.cursor() as cur:
                cur.execute("DELETE FROM reportes_mantenimiento WHERE id_reporte = %s RETURNING id_reporte;", (id_rep,))
                if not cur.fetchone():
                    return jsonify({"ok": False, "error": "Reporte no encontrado"}), 404
            conn.commit()
            return jsonify({"ok": True}), 200

        d = request.get_json(force=True)
        with conn.cursor() as cur:
            cur.execute("""
                UPDATE reportes_mantenimiento SET estado = %s
                WHERE id_reporte = %s RETURNING id_reporte, estado;
            """, (d["estado"], id_rep))
            act = cur.fetchone()
        if not act:
            return jsonify({"ok": False, "error": "Reporte no encontrado"}), 404
        conn.commit()
        return jsonify({"ok": True, "reporte": act}), 200
    except Exception as e:
        conn.rollback()
        return jsonify({"ok": False, "error": str(e)}), 400
    finally:
        conn.close()


# ---------------- USUARIOS ----------------
@app.route("/api/usuarios", methods=["GET", "POST"])
def manejar_usuarios():
    conn = get_connection()
    try:
        if request.method == "GET":
            with conn.cursor() as cur:
                cur.execute("""
                    SELECT id_usuario, usuario, correo, rol, activo
                    FROM usuarios ORDER BY id_usuario;
                """)
                return jsonify(cur.fetchall()), 200

        d = request.get_json(force=True)
        pwd_hash = hashlib.sha256(d["password"].encode("utf-8")).hexdigest()
        with conn.cursor() as cur:
            cur.execute("""
                INSERT INTO usuarios (usuario, correo, password_hash, rol)
                VALUES (%s, %s, %s, %s)
                RETURNING id_usuario, usuario, rol;
            """, (d["usuario"].strip(), d["correo"].strip().lower(), pwd_hash, d["rol"]))
            nuevo = cur.fetchone()
        conn.commit()
        return jsonify({"ok": True, "usuario": nuevo}), 201
    except Exception as e:
        conn.rollback()
        return jsonify({"ok": False, "error": str(e)}), 400
    finally:
        conn.close()


@app.route("/api/usuarios/<int:id_usr>", methods=["DELETE"])
def eliminar_usuario(id_usr):
    conn = get_connection()
    try:
        with conn.cursor() as cur:
            cur.execute("DELETE FROM usuarios WHERE id_usuario = %s RETURNING id_usuario;", (id_usr,))
            if not cur.fetchone():
                return jsonify({"ok": False, "error": "Usuario no encontrado"}), 404
        conn.commit()
        return jsonify({"ok": True}), 200
    except Exception as e:
        conn.rollback()
        return jsonify({"ok": False, "error": str(e)}), 400
    finally:
        conn.close()


# ---------------- RECADOS ----------------
@app.route("/api/recados", methods=["GET", "POST"])
def manejar_recados():
    conn = get_connection()
    try:
        if request.method == "GET":
            with conn.cursor() as cur:
                cur.execute("""
                    SELECT r.id_recado, r.tipo, r.asunto, r.mensaje, r.estatus,
                           TO_CHAR(r.fecha_envio, 'YYYY-MM-DD HH24:MI') AS fecha_envio,
                           t.nombre || ' ' || t.apellido_paterno AS tutor,
                           a.nombre || ' ' || a.apellido_paterno AS alumno,
                           d.nombre || ' ' || d.apellido_paterno AS docente
                    FROM recados r
                    JOIN tutores t ON t.id_tutor = r.id_tutor
                    JOIN alumnos a ON a.id_alumno = r.id_alumno
                    JOIN docentes d ON d.id_docente = r.id_docente
                    ORDER BY r.fecha_envio DESC, r.id_recado DESC
                    LIMIT 50;
                """)
                return jsonify(cur.fetchall()), 200

        d = request.get_json(force=True)
        with conn.cursor() as cur:
            cur.execute("""
                INSERT INTO recados (id_tutor, id_alumno, id_docente, tipo, asunto, mensaje)
                VALUES (%s, %s, %s, %s, %s, %s)
                RETURNING id_recado, estatus;
            """, (d["id_tutor"], d["id_alumno"], d["id_docente"], d["tipo"], d["asunto"], d["mensaje"]))
            nuevo = cur.fetchone()
        conn.commit()
        return jsonify({"ok": True, "recado": nuevo}), 201
    except Exception as e:
        conn.rollback()
        return jsonify({"ok": False, "error": str(e)}), 400
    finally:
        conn.close()


@app.route("/api/recados/<int:id_recado>", methods=["PATCH"])
def actualizar_estatus_recado(id_recado):
    d = request.get_json(force=True)
    conn = get_connection()
    try:
        with conn.cursor() as cur:
            cur.execute("""
                UPDATE recados SET estatus = %s
                WHERE id_recado = %s RETURNING id_recado, estatus;
            """, (d["estatus"], id_recado))
            act = cur.fetchone()
        if not act:
            return jsonify({"ok": False, "error": "Recado no encontrado"}), 404
        conn.commit()
        return jsonify({"ok": True, "recado": act}), 200
    except Exception as e:
        conn.rollback()
        return jsonify({"ok": False, "error": str(e)}), 400
    finally:
        conn.close()


# ---------------- PAGOS DE COLEGIATURA ----------------
@app.route("/api/pagos", methods=["GET", "POST"])
def manejar_pagos():
    conn = get_connection()
    try:
        if request.method == "GET":
            with conn.cursor() as cur:
                cur.execute("""
                    SELECT p.id_pago, p.referencia, p.monto_pagado, p.metodo_pago, p.estatus,
                           TO_CHAR(p.fecha_pago, 'YYYY-MM-DD HH24:MI') AS fecha_pago,
                           a.nombre || ' ' || a.apellido_paterno AS alumno,
                           per.nombre_periodo AS periodo
                    FROM pagos_colegiatura p
                    JOIN alumnos a ON a.id_alumno = p.id_alumno
                    JOIN periodos_colegiatura per ON per.id_periodo = p.id_periodo
                    ORDER BY p.fecha_pago DESC, p.id_pago DESC
                    LIMIT 50;
                """)
                return jsonify(cur.fetchall()), 200

        d = request.get_json(force=True)
        with conn.cursor() as cur:
            cur.execute("""
                INSERT INTO pagos_colegiatura
                    (id_alumno, id_periodo, monto_pagado, metodo_pago, estatus, referencia)
                VALUES (%s, %s, %s, %s, %s, %s)
                RETURNING id_pago, referencia;
            """, (
                d["id_alumno"], d["id_periodo"], d["monto_pagado"],
                d["metodo_pago"], d.get("estatus", "Pagado"), d["referencia"],
            ))
            nuevo = cur.fetchone()
        conn.commit()
        return jsonify({"ok": True, "pago": nuevo}), 201
    except Exception as e:
        conn.rollback()
        return jsonify({"ok": False, "error": str(e)}), 400
    finally:
        conn.close()


# ---------------- MAPA INTERACTIVO ----------------
@app.route("/api/mapa", methods=["GET"])
def consultar_mapa():
    dia = request.args.get("dia", "Lunes")
    hora = request.args.get("hora", "08:00")
    id_alumno = request.args.get("id_alumno")

    conn = get_connection()
    try:
        with conn.cursor() as cur:
            if id_alumno:
                cur.execute("""
                    SELECT a.id_alumno,
                           a.nombre || ' ' || a.apellido_paterno AS alumno,
                           g.grado || '°' || g.letra AS grupo,
                           s.clave_salon, s.edificio, s.planta, s.codigo_svg,
                           m.nombre AS materia,
                           d.nombre || ' ' || d.apellido_paterno AS docente,
                           h.dia_semana,
                           TO_CHAR(h.hora_inicio, 'HH24:MI') AS hora_inicio,
                           TO_CHAR(h.hora_fin, 'HH24:MI') AS hora_fin
                    FROM alumnos a
                    JOIN grupos g ON g.id_grupo = a.id_grupo
                    JOIN horarios h ON h.id_grupo = g.id_grupo
                    JOIN salones s ON s.id_salon = h.id_salon
                    JOIN materias m ON m.id_materia = h.id_materia
                    JOIN docentes d ON d.id_docente = h.id_docente
                    WHERE a.id_alumno = %s
                      AND h.dia_semana = %s
                      AND h.hora_inicio = %s::time;
                """, (id_alumno, dia, hora))
            else:
                cur.execute("""
                    SELECT s.id_salon, s.clave_salon, s.edificio, s.planta, s.codigo_svg,
                           g.grado || '°' || g.letra AS grupo,
                           m.nombre AS materia,
                           d.nombre || ' ' || d.apellido_paterno AS docente,
                           TO_CHAR(h.hora_inicio, 'HH24:MI') AS hora_inicio,
                           TO_CHAR(h.hora_fin, 'HH24:MI') AS hora_fin
                    FROM salones s
                    LEFT JOIN horarios h
                           ON h.id_salon = s.id_salon
                          AND h.dia_semana = %s
                          AND h.hora_inicio = %s::time
                    LEFT JOIN grupos g ON g.id_grupo = h.id_grupo
                    LEFT JOIN materias m ON m.id_materia = h.id_materia
                    LEFT JOIN docentes d ON d.id_docente = h.id_docente
                    ORDER BY s.id_salon;
                """, (dia, hora))
            return jsonify(cur.fetchall()), 200
    finally:
        conn.close()


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=int(os.getenv("PORT", 5000)), debug=True)
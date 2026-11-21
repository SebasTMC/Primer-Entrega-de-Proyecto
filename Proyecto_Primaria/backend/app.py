import os
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
        password=os.getenv("DB_PASSWORD", "postgres"),
        cursor_factory=RealDictCursor,
    )


@app.route("/health", methods=["GET"])
def health():
    return jsonify({"ok": True, "servicio": "Proyecto_Primaria API"}), 200


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
                SELECT id_tutor, nombre || ' ' || apellido_paterno AS tutor, parentesco
                FROM tutores ORDER BY id_tutor;
            """)
            tutores = cur.fetchall()

            cur.execute("""
                SELECT id_docente, nombre || ' ' || apellido_paterno AS docente, especialidad
                FROM docentes WHERE activo = TRUE ORDER BY id_docente;
            """)
            docentes = cur.fetchall()

            cur.execute("""
                SELECT id_periodo, nombre_periodo, monto_base, fecha_limite
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
            "periodos": periodos,
            "salones": salones,
        }), 200
    finally:
        conn.close()


@app.route("/api/recados", methods=["GET", "POST"])
def manejar_recados():
    conn = get_connection()
    try:
        if request.method == "GET":
            with conn.cursor() as cur:
                cur.execute("""
                    SELECT r.id_recado, r.tipo, r.asunto, r.mensaje, r.estatus, r.fecha_envio,
                           t.nombre || ' ' || t.apellido_paterno AS tutor,
                           a.nombre || ' ' || a.apellido_paterno AS alumno,
                           d.nombre || ' ' || d.apellido_paterno AS docente
                    FROM recados r
                    JOIN tutores t ON t.id_tutor = r.id_tutor
                    JOIN alumnos a ON a.id_alumno = r.id_alumno
                    JOIN docentes d ON d.id_docente = r.id_docente
                    ORDER BY r.fecha_envio DESC, r.id_recado DESC
                    LIMIT 30;
                """)
                return jsonify(cur.fetchall()), 200

        datos = request.get_json(force=True)
        with conn.cursor() as cur:
            cur.execute("""
                INSERT INTO recados (id_tutor, id_alumno, id_docente, tipo, asunto, mensaje)
                VALUES (%s, %s, %s, %s, %s, %s)
                RETURNING id_recado, fecha_envio, estatus;
            """, (
                datos["id_tutor"],
                datos["id_alumno"],
                datos["id_docente"],
                datos["tipo"],
                datos["asunto"],
                datos["mensaje"],
            ))
            nuevo = cur.fetchone()
        conn.commit()
        return jsonify({"ok": True, "recado": nuevo}), 201
    except Exception as e:
        conn.rollback()
        return jsonify({"ok": False, "error": str(e)}), 400
    finally:
        conn.close()


@app.route("/api/pagos", methods=["GET", "POST"])
def manejar_pagos():
    conn = get_connection()
    try:
        if request.method == "GET":
            with conn.cursor() as cur:
                cur.execute("""
                    SELECT p.id_pago, p.referencia, p.monto_pagado, p.metodo_pago,
                           p.estatus, p.fecha_pago,
                           a.nombre || ' ' || a.apellido_paterno AS alumno,
                           per.nombre_periodo AS periodo
                    FROM pagos_colegiatura p
                    JOIN alumnos a ON a.id_alumno = p.id_alumno
                    JOIN periodos_colegiatura per ON per.id_periodo = p.id_periodo
                    ORDER BY p.fecha_pago DESC, p.id_pago DESC
                    LIMIT 30;
                """)
                return jsonify(cur.fetchall()), 200

        datos = request.get_json(force=True)
        with conn.cursor() as cur:
            cur.execute("""
                INSERT INTO pagos_colegiatura
                    (id_alumno, id_periodo, monto_pagado, metodo_pago, estatus, referencia)
                VALUES (%s, %s, %s, %s, %s, %s)
                RETURNING id_pago, referencia, fecha_pago;
            """, (
                datos["id_alumno"],
                datos["id_periodo"],
                datos["monto_pagado"],
                datos["metodo_pago"],
                datos.get("estatus", "Pagado"),
                datos["referencia"],
            ))
            nuevo = cur.fetchone()
        conn.commit()
        return jsonify({"ok": True, "pago": nuevo}), 201
    except Exception as e:
        conn.rollback()
        return jsonify({"ok": False, "error": str(e)}), 400
    finally:
        conn.close()


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
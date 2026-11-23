import os
import datetime
import decimal
import psycopg2
from psycopg2.extras import RealDictCursor

def connect():
    return psycopg2.connect(
        host=os.getenv("DB_HOST", "localhost"),
        port=int(os.getenv("DB_PORT", "5435")),
        dbname=os.getenv("DB_NAME", "primaria_db"),
        user=os.getenv("DB_USER", "postgres"),
        password=os.getenv("DB_PASSWORD", "primaria_dev"),
    )

def relax_type(val):
    if isinstance(val, bool):
        return "string"
    if isinstance(val, (int, float, decimal.Decimal)):
        return "number"
    return "string"

def fmt_val(val):
    if val is None:
        return "null"
    if isinstance(val, bool):
        return "'true'" if val else "'false'"
    if isinstance(val, (int, float, decimal.Decimal)):
        return str(val)
    if isinstance(val, (datetime.datetime, datetime.date, datetime.time)):
        return f"'{val.isoformat()}'"
    s = str(val).replace("'", " ").replace("\n", " ").replace("\r", " ").strip()
    return f"'{s}'"

def render_relation(name, cols, rows):
    if not rows:
        return ""
    col_types = []
    for c in cols:
        sample = next((r[c] for r in rows if r[c] is not None), "")
        col_types.append(f"{c}:{relax_type(sample)}")
    lines = [f"{name} = {{", "  " + ", ".join(col_types)]
    for r in rows:
        lines.append("  " + ", ".join(fmt_val(r[c]) for c in cols))
    lines.append("}")
    return "\n".join(lines)

def fetch_all(cur, sql, params=None):
    cur.execute(sql, params or ())
    cols = [d[0] for d in cur.description]
    return cols, cur.fetchall()

def main():
    out_path = os.getenv("RELAX_OUT", os.path.join(os.path.dirname(__file__), "grupo.txt"))
    conn = connect()
    try:
        with conn.cursor(cursor_factory=RealDictCursor) as cur:
            # 1. Alumnos muestra (15 filas priorizando quienes tienen registros en modulos de servicio/recados)
            c_al, alumnos = fetch_all(cur, """
                SELECT * FROM alumnos
                ORDER BY
                    (id_alumno IN (SELECT id_alumno FROM registros_enfermeria)) DESC,
                    (id_alumno IN (SELECT id_alumno FROM ventas_cafeteria)) DESC,
                    (id_alumno IN (SELECT id_alumno FROM recado_respuestas)) DESC,
                    id_alumno
                LIMIT 15;
            """)
            al_ids = [r["id_alumno"] for r in alumnos]

            # 2. Grupos referenciados por la muestra (hasta 12)
            c_gr, grupos = fetch_all(cur, """
                SELECT * FROM grupos
                WHERE id_grupo = ANY(%s)
                   OR id_grupo IN (SELECT id_grupo FROM recados WHERE id_grupo IS NOT NULL)
                ORDER BY id_grupo
                LIMIT 12;
            """, ([r["id_grupo"] for r in alumnos],))
            gr_ids = [r["id_grupo"] for r in grupos]

            # Asegurar que todos los alumnos pertenezcan a los grupos exportados
            alumnos = [a for a in alumnos if a["id_grupo"] in gr_ids]
            al_ids = [r["id_alumno"] for r in alumnos]

            # 3. Materias y Periodos (catalogos completos: 8 y 4 filas)
            c_mat, materias = fetch_all(cur, "SELECT * FROM materias ORDER BY id_materia;")
            c_per, periodos = fetch_all(cur, "SELECT * FROM periodos_colegiatura ORDER BY id_periodo;")

            # 4. Horarios (25 filas de los grupos exportados)
            c_hor, horarios = fetch_all(cur, """
                SELECT * FROM horarios
                WHERE id_grupo = ANY(%s)
                ORDER BY id_horario
                LIMIT 25;
            """, (gr_ids,))

            # 5. Docentes referenciados por grupos, horarios y recados
            c_rec, recados = fetch_all(cur, """
                SELECT * FROM recados
                WHERE (id_grupo IS NULL OR id_grupo = ANY(%s))
                  AND (id_alumno IS NULL OR id_alumno = ANY(%s))
                ORDER BY id_recado;
            """, (gr_ids, al_ids))
            rec_ids = [r["id_recado"] for r in recados]

            doc_needed = set(
                [r["id_docente_titular"] for r in grupos] +
                [r["id_docente"] for r in horarios] +
                [r["id_docente"] for r in recados]
            )
            c_doc, docentes = fetch_all(cur, """
                SELECT * FROM docentes
                WHERE id_docente = ANY(%s)
                ORDER BY id_docente
                LIMIT 22;
            """, (list(doc_needed),))

            # 6. Salones referenciados por grupos y horarios
            sal_needed = set(
                [r["id_salon"] for r in grupos if r["id_salon"] is not None] +
                [r["id_salon"] for r in horarios]
            )
            c_sal, salones = fetch_all(cur, """
                SELECT * FROM salones
                WHERE id_salon = ANY(%s)
                ORDER BY id_salon
                LIMIT 26;
            """, (list(sal_needed),))

            # 7. Calificaciones y Pagos de los alumnos exportados (hasta 25)
            c_cal, calificaciones = fetch_all(cur, """
                SELECT * FROM calificaciones
                WHERE id_alumno = ANY(%s)
                ORDER BY id_calificacion
                LIMIT 25;
            """, (al_ids,))

            c_pag, pagos = fetch_all(cur, """
                SELECT * FROM pagos_colegiatura
                WHERE id_alumno = ANY(%s)
                ORDER BY id_pago
                LIMIT 25;
            """, (al_ids,))

            # 8. Alumno_tutores y Tutores referenciados
            c_at, alumno_tutores = fetch_all(cur, """
                SELECT * FROM alumno_tutores
                WHERE id_alumno = ANY(%s)
                ORDER BY id_alumno, id_tutor
                LIMIT 30;
            """, (al_ids,))

            c_rr, recado_respuestas = fetch_all(cur, """
                SELECT * FROM recado_respuestas
                WHERE id_recado = ANY(%s) AND id_alumno = ANY(%s)
                ORDER BY id_respuesta;
            """, (rec_ids or [-1], al_ids))

            tut_needed = set(
                [r["id_tutor"] for r in alumnos] +
                [r["id_tutor"] for r in alumno_tutores] +
                [r["id_tutor"] for r in recados if r["id_tutor"] is not None] +
                [r["id_tutor"] for r in recado_respuestas if r["id_tutor"] is not None]
            )
            c_tut, tutores = fetch_all(cur, """
                SELECT * FROM tutores
                WHERE id_tutor = ANY(%s)
                ORDER BY id_tutor
                LIMIT 30;
            """, (list(tut_needed),))

            # 9. Enfermeria, Cafeteria, Mantenimiento, Personal y Usuarios referenciados
            c_enf, enfermeria = fetch_all(cur, """
                SELECT * FROM registros_enfermeria
                WHERE id_alumno = ANY(%s)
                ORDER BY id_atencion;
            """, (al_ids,))

            c_caf, cafeteria = fetch_all(cur, """
                SELECT * FROM ventas_cafeteria
                WHERE id_alumno = ANY(%s)
                ORDER BY id_venta;
            """, (al_ids,))

            c_man, mantenimiento = fetch_all(cur, "SELECT * FROM reportes_mantenimiento ORDER BY id_reporte;")
            c_prs, personal = fetch_all(cur, "SELECT * FROM personal ORDER BY id_empleado;")

            usr_needed = set(
                [r["id_usuario_atiende"] for r in enfermeria if r["id_usuario_atiende"]] +
                [r["id_usuario_registra"] for r in cafeteria if r["id_usuario_registra"]] +
                [r["id_usuario_registra"] for r in mantenimiento if r["id_usuario_registra"]]
            )
            c_usr, usuarios = fetch_all(cur, """
                SELECT id_usuario, usuario, correo, rol, id_docente, id_alumno, activo
                FROM usuarios
                WHERE id_usuario = ANY(%s)
                   OR id_alumno = ANY(%s)
                   OR id_docente = ANY(%s)
                ORDER BY id_usuario
                LIMIT 25;
            """, (list(usr_needed) or [-1], al_ids, list(doc_needed) or [-1]))

        header = [
            "group: Proyecto_Primaria",
            "description: Muestra normalizada con integridad referencial del Sistema de Gestion Escolar (PostgreSQL)",
            ""
        ]
        blocks = [
            render_relation("docentes", c_doc, docentes),
            render_relation("salones", c_sal, salones),
            render_relation("grupos", c_gr, grupos),
            render_relation("tutores", c_tut, tutores),
            render_relation("alumnos", c_al, alumnos),
            render_relation("alumno_tutores", c_at, alumno_tutores),
            render_relation("materias", c_mat, materias),
            render_relation("calificaciones", c_cal, calificaciones),
            render_relation("horarios", c_hor, horarios),
            render_relation("periodos_colegiatura", c_per, periodos),
            render_relation("pagos_colegiatura", c_pag, pagos),
            render_relation("recados", c_rec, recados),
            render_relation("recado_respuestas", c_rr, recado_respuestas),
            render_relation("usuarios", c_usr, usuarios),
            render_relation("registros_enfermeria", c_enf, enfermeria),
            render_relation("ventas_cafeteria", c_caf, cafeteria),
            render_relation("reportes_mantenimiento", c_man, mantenimiento),
            render_relation("personal", c_prs, personal),
        ]

        os.makedirs(os.path.dirname(os.path.abspath(out_path)), exist_ok=True)
        with open(out_path, "w", encoding="utf-8") as f:
            f.write("\n".join(header) + "\n\n".join(b for b in blocks if b) + "\n")

        print(f"[OK] Grupo de RelaX exportado en: {out_path}")
    finally:
        conn.close()

if __name__ == "__main__":
    main()
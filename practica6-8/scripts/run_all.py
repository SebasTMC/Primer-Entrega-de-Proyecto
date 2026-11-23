import glob
import os
import subprocess
import sys
import psycopg2

def print_table(cols, rows, limit=15):
    shown = rows[:limit]
    widths = [len(str(c)) for c in cols]
    for r in shown:
        for i, val in enumerate(r):
            widths[i] = max(widths[i], len(str(val if val is not None else "NULL")))
    sep = "+-" + "-+-".join("-" * w for w in widths) + "-+"
    header = "| " + " | ".join(str(c).ljust(widths[i]) for i, c in enumerate(cols)) + " |"
    print(sep)
    print(header)
    print(sep)
    for r in shown:
        line = "| " + " | ".join(str(v if v is not None else "NULL").ljust(widths[i]) for i, v in enumerate(r)) + " |"
        print(line)
    print(sep)
    if len(rows) > limit:
        print(f"... ({len(rows)} filas totales; mostrando primeras {limit})")
    else:
        print(f"Total: {len(rows)} fila(s)")

def main():
    conn = psycopg2.connect(
        host=os.getenv("DB_HOST", "db"),
        port=int(os.getenv("DB_PORT", "5432")),
        dbname=os.getenv("DB_NAME", "primaria_db"),
        user=os.getenv("DB_USER", "postgres"),
        password=os.getenv("DB_PASSWORD", "primaria_dev"),
    )
    sql_files = sorted(glob.glob("/app/consultas/*.sql"))
    print("=" * 80)
    print("EJECUCION AUTOMATICA DE CONSULTAS — PRACTICAS 6, 7 Y 8")
    print("=" * 80)

    try:
        with conn.cursor() as cur:
            for path in sql_files:
                fname = os.path.basename(path)
                with open(path, "r", encoding="utf-8") as f:
                    content = f.read()
                pregunta = ""
                algebra = ""
                for line in content.splitlines():
                    if line.startswith("-- PREGUNTA:"):
                        pregunta = line.replace("-- PREGUNTA:", "").strip()
                    elif line.startswith("-- ALGEBRA:"):
                        algebra = line.replace("-- ALGEBRA:", "").strip()
                print(f"\n>>> [{fname}]")
                print(f"Pregunta : {pregunta}")
                print(f"Algebra  : {algebra}")
                cur.execute(content)
                cols = [d[0] for d in cur.description]
                rows = cur.fetchall()
                print_table(cols, rows)
    finally:
        conn.close()

    print("\n" + "=" * 80)
    print("REGENERANDO GRUPO DE RELAX DESDE POSTGRESQL...")
    print("=" * 80)
    res = subprocess.run([sys.executable, "/app/relax/exportar-grupo.py"], check=True)
    if res.returncode == 0:
        print("[OK] Todo el flujo de Prácticas 6, 7 y 8 finalizó sin errores.")

if __name__ == "__main__":
    main()
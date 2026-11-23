# Practices 6, 7 & 8 — Normalization, Relational Algebra & Containerized Verification

## Quick Start (Single Command)

From the `practica6-8/` directory on a clean machine with Docker installed, run:

~~~bash
cp .env.example .env
docker compose up --build --exit-code-from runner
~~~

*(On Windows PowerShell: `Copy-Item .env.example .env` followed by `docker compose up --build --exit-code-from runner`.)*

### Expected Output
1. PostgreSQL 16 (`primaria_db`) starts and automatically runs all numbered migrations (`01` through `05`) to create and populate the normalized 18-table schema.
2. The `runner` container waits for the database healthcheck, executes all 13 SQL queries in `consultas/` in order (printing each domain question, its relational algebra expression, and the resulting table), and finishes with exit code `0`.
3. `relax/exportar-grupo.py` automatically regenerates `relax/grupo.txt` from the live PostgreSQL instance preserving referential integrity.
4. Data persists across container restarts via the named Docker volume `primaria_pgdata`.

## Repository Structure

* `normalizacion.md` — Informal design guidelines, functional dependencies ($F$), attribute closures, minimal cover ($F_c$), and 1NF–BCNF verification.
* `almacen-y-formas-normales.md` — Normal forms analysis of the assigned project's dimensional data warehouse.
* `algebra.md` — Relational algebra expressions, RelaX evidence, and verified SQL equivalents for the 13 project queries and 3 assigned-project queries.
* `migraciones/` — Numbered PostgreSQL schema and data migrations (`01` to `05`).
* `consultas/` — 13 automated SQL scripts covering selection, projection, set operations, Cartesian product, joins, aggregation/grouping, and division.
* `relax/` — Automated RelaX group exporter (`exportar-grupo.py`) and generated dataset (`grupo.txt`).
* `integrantes/` — Individual signed work per team member.
* `evidencias/` — RelaX query trees and result screenshots.
* `compose.yaml` & `.env.example` — Container orchestration with non-production test credentials.

## Clean-Environment Verification Log

> **Pending teammate verification:** Before the final merge, another team member must clone the repository into a fresh folder, execute the single command above, and record the result below.

* **Verified by:** *(Teammate Name)*
* **Date:** *(YYYY-MM-DD)*
* **Commit hash:** *(git rev-parse --short HEAD)*
* **Result:** *(Pending)*

## Generative AI Disclosure

Generative AI tools (Gemini) were used as a technical assistant to draft boilerplate scripts (`exportar-grupo.py`, `run_all.py`, Docker Compose runner setup) and structure Markdown documentation templates. All functional dependencies, business rules, SQL queries, and database results were reviewed, executed, and verified directly by the team against PostgreSQL and RelaX.
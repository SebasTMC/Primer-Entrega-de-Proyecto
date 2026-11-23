# Parte 1 — Dependencias Funcionales y Normalización

Proyecto propio: **Sistema de Gestión Escolar (Escuela Primaria)**  
Motor: PostgreSQL 16 (`primaria_db`) — 18 tablas en esquema `public`.

---

## Ejercicio 1.1. Pautas de diseño informales

Evaluación de cada tabla mediante la frase *"Cada fila es..."* frente a las cuatro pautas:
1. **Semántica clara** (una sola entidad o relación por tabla).
2. **Sin anomalías** (inserción, actualización o borrado).
3. **Pocos nulos** (evitar columnas vacías de forma sistemática).
4. **Sin tuplas espurias** (reuniones naturales sobre llaves primarias/foráneas).

| Tabla | Cada fila es... | Semántica clara | Sin anomalías | Pocos nulos | Sin tuplas espurias | Observación / Falla detectada |
| :--- | :--- | :---: | :---: | :---: | :---: | :--- |
| `docentes` | Un profesor registrado en la escuela con su número de empleado y especialidad. | Cumple | Cumple | Cumple | Cumple | Sin fallas. |
| `salones` | Un espacio físico del plantel con su clave, edificio, planta y código SVG del croquis. | Cumple | Cumple | Cumple | Cumple | Sin fallas. |
| `grupos` | Un grupo escolar (grado y letra) en un ciclo escolar con su docente titular y salón fijo. | Cumple | Cumple | Cumple | Cumple | `id_salon` permite nulo solo durante transición de ciclo. |
| `tutores` | Una persona adulta autorizada como responsable legal o contacto de un alumno. | Cumple | Cumple | Cumple | Cumple | `apellido_materno` opcional (nulo aceptable por dominio). |
| `alumnos` | Un estudiante inscrito en un grupo específico del plantel. | Cumple | **Falla parcial** | Cumple | Cumple | **Anomalía potencial de actualización:** conserva la FK heredada `id_tutor` de la migración 01 mientras `alumno_tutores` gestiona los hasta 2 tutores autorizados. Se mitiga sincronizando ambos desde el backend/migración 05. |
| `alumno_tutores` | La asignación exclusiva de un tutor autorizado a un alumno (máx. 2 por alumno). | Cumple | Cumple | Cumple | Cumple | `UNIQUE(id_tutor)` y trigger `trg_validar_max_dos_tutores` garantizan las reglas. |
| `materias` | Una asignatura del plan de estudios de primaria con su clave y grado sugerido. | Cumple | Cumple | Cumple | Cumple | Sin fallas. |
| `calificaciones` | La evaluación final de un alumno en una materia durante un ciclo escolar. | Cumple | Cumple | Cumple | Cumple | Sin fallas. |
| `horarios` | Un bloque de clase semanal asignado a un grupo, materia, docente y salón. | Cumple | Cumple | Cumple | Cumple | Sin fallas. |
| `periodos_colegiatura` | Un periodo de cobro escolar con su monto base y fecha límite. | Cumple | Cumple | Cumple | Cumple | Sin fallas. |
| `pagos_colegiatura` | Un pago de colegiatura realizado por un alumno para un periodo determinado. | Cumple | Cumple | Cumple | Cumple | Sin fallas. |
| `recados` | Un aviso o comunicado enviado por un docente hacia un grupo o un alumno específico. | Cumple | Cumple | **Falla** | Cumple | **Nulos estructurales:** `id_tutor` es nulo en recados enviados por docentes y `id_alumno` es nulo cuando el recado va dirigido a todo un grupo (`CHECK (id_grupo IS NOT NULL OR id_alumno IS NOT NULL)`). |
| `recado_respuestas` | La confirmación o respuesta textual de una familia a un recado específico. | Cumple | Cumple | **Falla menor** | Cumple | `texto_respuesta` es nulo cuando el recado solo solicita botón de confirmación (`Leido`, `Confirmado`, `Aceptado`). |
| `usuarios` | Una cuenta de acceso al sistema web con su rol y credenciales encriptadas. | Cumple | Cumple | **Falla** | Cumple | **Nulos por subtipo en una sola tabla:** `id_docente` e `id_alumno` son nulos para roles administrativos/servicios (Director, Administrativo, Enfermería, Cafetería, Mantenimiento). |
| `personal` | Un registro de nómina y puesto laboral de un empleado del plantel. | Cumple | **Falla parcial** | Cumple | Cumple | **Posible anomalía de actualización:** no tiene FK hacia `docentes`, por lo que si un docente titular cambia de nombre o estatus `activo`, debe actualizarse en ambas tablas. |
| `registros_enfermeria` | Una atención médica brindada a un alumno por personal de enfermería. | Cumple | Cumple | Cumple | Cumple | Sin fallas. |
| `ventas_cafeteria` | Una venta o consumo registrado a nombre de un alumno en cafetería. | Cumple | Cumple | Cumple | Cumple | Sin fallas. |
| `reportes_mantenimiento` | Una incidencia física reportada en las instalaciones del plantel y su estado. | Cumple | Cumple | Cumple | Cumple | Sin fallas. |

---

## Ejercicio 1.2. Dependencias funcionales ($F$), cierres y conjunto mínimo

### 1. Conjunto $F$ derivado de las reglas del negocio

Cada dependencia surge de las políticas operativas de la escuela primaria (no de filas de ejemplo):

* **Docentes (`docentes`):**
  * $d_1$: `id_docente` $\to$ `num_empleado, nombre, apellido_paterno, correo, especialidad, activo` *(Regla: cada docente tiene un identificador interno único).*
  * $d_2$: `num_empleado` $\to$ `id_docente, nombre, apellido_paterno, correo, especialidad, activo` *(Regla: el número de empleado de nómina no se repite).*
  * $d_3$: `correo` $\to$ `id_docente` *(Regla: cada docente posee un correo institucional único).*
* **Salones (`salones`):**
  * $d_4$: `id_salon` $\to$ `clave_salon, edificio, planta, capacidad, codigo_svg` *(Regla: cada espacio físico tiene un ID único).*
  * $d_5$: `clave_salon` $\to$ `id_salon` y $d_6$: `codigo_svg` $\to$ `id_salon` *(Regla: cada clave de salón y cada elemento del croquis SVG corresponden a un único espacio).*
* **Grupos (`grupos`):**
  * $d_7$: `id_grupo` $\to$ `grado, letra, ciclo_escolar, id_docente_titular, id_salon` *(Regla: un grupo tiene un único titular y un salón base asignado).*
  * $d_8$: `{grado, letra, ciclo_escolar}` $\to$ `id_grupo` *(Regla: no pueden existir dos grupos iguales en el mismo ciclo).*
  * $d_9$: `id_salon` $\to$ `id_grupo` *(Regla: cada salón base se asigna a un solo grupo en el ciclo vigente).*
  * $d_{10}$: `id_docente_titular` $\to$ `id_grupo` *(Regla del dominio: 1 docente titular atiende exclusivamente 1 grupo).*
* **Tutores (`tutores`):**
  * $d_{11}$: `id_tutor` $\to$ `nombre, apellido_paterno, apellido_materno, correo, telefono, parentesco` *(Regla: identificador único de tutor).*
  * $d_{12}$: `correo` $\to$ `id_tutor` *(Regla: el correo de contacto identifica de forma única a cada tutor).*
* **Alumnos (`alumnos`):**
  * $d_{13}$: `id_alumno` $\to$ `curp, nombre, apellido_paterno, apellido_materno, fecha_nacimiento, id_tutor, id_grupo` *(Regla: un alumno pertenece a un solo grupo y tiene un tutor principal).*
  * $d_{14}$: `curp` $\to$ `id_alumno` *(Regla: la CURP es única a nivel nacional por estudiante).*
* **Relación alumno–tutores (`alumno_tutores`):**
  * $d_{15}$: `id_tutor` $\to$ `id_alumno, es_principal` *(Regla de exclusividad: cada tutor autorizado pertenece exclusivamente a un alumno; por tanto `{id_alumno, id_tutor}` es superclave y `id_tutor` es clave candidata).*
* **Materias (`materias`):**
  * $d_{16}$: `id_materia` $\to$ `clave_materia, nombre, grado_sugerido` y $d_{17}$: `clave_materia` $\to$ `id_materia` *(Regla: cada asignatura tiene clave única).*
* **Calificaciones (`calificaciones`):**
  * $d_{18}$: `id_calificacion` $\to$ `id_alumno, id_materia, creditos, calificacion, ciclo_escolar`.
  * $d_{19}$: `{id_alumno, id_materia, ciclo_escolar}` $\to$ `id_calificacion, creditos, calificacion` *(Regla: un alumno solo tiene una calificación final por materia y ciclo).*
* **Horarios (`horarios`):**
  * $d_{20}$: `id_horario` $\to$ `id_grupo, id_materia, id_docente, id_salon, dia_semana, hora_inicio, hora_fin`.
  * $d_{21}$: `{id_grupo, dia_semana, hora_inicio}` $\to$ `id_horario, id_materia, id_docente, id_salon, hora_fin` *(Regla: un grupo no puede tomar dos clases simultáneas).*
  * $d_{22}$: `{id_salon, dia_semana, hora_inicio}` $\to$ `id_horario, id_grupo, id_materia, id_docente, hora_fin` *(Regla: un salón no puede albergar dos clases a la misma hora).*
* **Periodos y Pagos (`periodos_colegiatura`, `pagos_colegiatura`):**
  * $d_{23}$: `id_periodo` $\to$ `nombre_periodo, monto_base, fecha_limite` y $d_{24}$: `nombre_periodo` $\to$ `id_periodo`.
  * $d_{25}$: `id_pago` $\to$ `id_alumno, id_periodo, fecha_pago, monto_pagado, metodo_pago, estatus, referencia`.
  * $d_{26}$: `{id_alumno, id_periodo}` $\to$ `id_pago` *(Regla: un registro de pago por alumno y periodo).*
  * $d_{27}$: `referencia` $\to$ `id_pago` *(Regla: cada comprobante bancario tiene referencia única).*
* **Recados y Respuestas (`recados`, `recado_respuestas`):**
  * $d_{28}$: `id_recado` $\to$ `id_tutor, id_alumno, id_grupo, id_docente, tipo, asunto, mensaje, estatus, fecha_envio, tipo_respuesta`.
  * $d_{29}$: `id_respuesta` $\to$ `id_recado, id_alumno, id_tutor, estado_respuesta, texto_respuesta, fecha_respuesta`.
  * $d_{30}$: `{id_recado, id_alumno}` $\to$ `id_respuesta` *(Regla: una respuesta vigente por alumno y recado).*
* **Usuarios y Servicios (`usuarios`, `personal`, `registros_enfermeria`, `ventas_cafeteria`, `reportes_mantenimiento`):**
  * $d_{31}$: `id_usuario` $\to$ `usuario, correo, password_hash, rol, id_docente, id_alumno, activo`; `correo` $\to$ `id_usuario`; `usuario` $\to$ `id_usuario`.
  * $d_{32}$: `id_empleado` $\to$ `clave_empleado, nombre, puesto, salario, area, activo`; `clave_empleado` $\to$ `id_empleado`.
  * $d_{33}$: `id_atencion` $\to$ `id_alumno, id_usuario_atiende, fecha_hora, motivo, observaciones, requirio_aviso_tutor, estatus`.
  * $d_{34}$: `id_venta` $\to$ `folio, fecha_hora, id_alumno, concepto, total, id_usuario_registra`; `folio` $\to$ `id_venta`.
  * $d_{35}$: `id_reporte` $\to$ `folio, ubicacion, descripcion, fecha_reporte, estado, id_usuario_registra`; `folio` $\to$ `id_reporte`.

---

### 2. Cálculo de cierres ($X^+$) y claves candidatas (ejemplos representativos paso a paso)

* **Tabla `grupos`:**
  * `{grado, letra, ciclo_escolar}+`
    1. Inicial: `{grado, letra, ciclo_escolar}`
    2. Por $d_8$: agrega `id_grupo`
    3. Por $d_7$: agrega `id_docente_titular, id_salon`
    4. Resultado = todos los atributos de `grupos`. Ningún subconjunto propio determina `id_grupo` $\implies$ **`{grado, letra, ciclo_escolar}` es clave candidata**.
  * De forma análoga: `id_grupo+ = R`, `id_salon+ = R` (por $d_9, d_7$) e `id_docente_titular+ = R` (por $d_{10}, d_7$).
  * **Claves candidatas de `grupos`:** `{id_grupo}`, `{grado, letra, ciclo_escolar}`, `{id_salon}`, `{id_docente_titular}`.

* **Tabla `horarios`:**
  * `{id_grupo, dia_semana, hora_inicio}+`
    1. Inicial: `{id_grupo, dia_semana, hora_inicio}`
    2. Por $d_{21}$: agrega `id_horario, id_materia, id_docente, id_salon, hora_fin`
    3. Resultado = todos los atributos de `horarios`. Quitando cualquiera de los 3 atributos no se puede aplicar $d_{21}$ $\implies$ **`{id_grupo, dia_semana, hora_inicio}` es clave candidata**.
  * `{id_salon, dia_semana, hora_inicio}+ = R` (por $d_{22}$) y `{id_horario}+ = R` (por $d_{20}$).
  * **Claves candidatas de `horarios`:** `{id_horario}`, `{id_grupo, dia_semana, hora_inicio}`, `{id_salon, dia_semana, hora_inicio}`.

* **Tabla `pagos_colegiatura`:**
  * `{id_alumno, id_periodo}+` $\xrightarrow{d_{26}}$ `{id_alumno, id_periodo, id_pago}` $\xrightarrow{d_{25}}$ todos los atributos.
  * `{referencia}+` $\xrightarrow{d_{27}}$ `{referencia, id_pago}` $\xrightarrow{d_{25}}$ todos los atributos.
  * **Claves candidatas:** `{id_pago}`, `{id_alumno, id_periodo}`, `{referencia}`.

* **Tabla `alumnos`:**
  * `{curp}+` $\xrightarrow{d_{14}}$ `{curp, id_alumno}` $\xrightarrow{d_{13}}$ todos los atributos.
  * **Claves candidatas:** `{id_alumno}`, `{curp}`.

* **Tabla `alumno_tutores`:**
  * `{id_tutor}+` $\xrightarrow{d_{15}}$ `{id_tutor, id_alumno, es_principal} = R`.
  * **Clave candidata mínima:** `{id_tutor}` (la PK compuesta `{id_alumno, id_tutor}` es superclave; `UNIQUE(id_tutor)` refuerza la unicidad real).

---

### 3. Reducción de $F$ a conjunto mínimo ($F_c$)

Aplicando los tres pasos estándar sobre el subconjunto de `docentes`, `horarios` y `calificaciones` (donde aparecen redundancias):

1. **Paso 1 — Lados derechos simples (descomposición):**
   * $d_2$: `num_empleado` $\to$ `id_docente`, `num_empleado` $\to$ `nombre`, ..., `num_empleado` $\to$ `activo`.
   * $d_{19}$: `{id_alumno, id_materia, ciclo_escolar}` $\to$ `id_calificacion`, `{id_alumno, id_materia, ciclo_escolar}` $\to$ `creditos`, `{id_alumno, id_materia, ciclo_escolar}` $\to$ `calificacion`.
   * $d_{21}$: `{id_grupo, dia_semana, hora_inicio}` $\to$ `id_horario`, ..., `{id_grupo, dia_semana, hora_inicio}` $\to$ `hora_fin`.

2. **Paso 2 — Eliminación de atributos sobrantes en el lado izquierdo:**
   * En `alumno_tutores`, si se escribiera `{id_alumno, id_tutor}` $\to$ `es_principal`, al probar quitando `id_alumno`: `{id_tutor}+` ya contiene `es_principal` (por $d_{15}$). Por tanto, `id_alumno` es sobrante y la dependencia se reduce a `id_tutor` $\to$ `es_principal`.
   * En `horarios`, para `{id_grupo, dia_semana, hora_inicio}` $\to$ `id_horario`:
     * `{id_grupo, dia_semana}+ = {id_grupo, dia_semana}` (no contiene `id_horario`).
     * `{id_grupo, hora_inicio}+ = {id_grupo, hora_inicio}` (no contiene `id_horario`).
     * `{dia_semana, hora_inicio}+ = {dia_semana, hora_inicio}` (no contiene `id_horario`).
     * Ningún atributo es sobrante.

3. **Paso 3 — Eliminación de dependencias redundantes:**
   * En `docentes`, la dependencia `num_empleado` $\to$ `nombre` es **redundante** porque sin ella, calculando el cierre: `{num_empleado}+` $\xrightarrow{\text{num\_empleado}\to\text{id\_docente}}$ `{num_empleado, id_docente}` $\xrightarrow{d_1}$ `{..., nombre}`. Se elimina `num_empleado` $\to$ `{nombre, apellido_paterno, correo, especialidad, activo}` y se conserva únicamente `num_empleado` $\to$ `id_docente`.
   * En `calificaciones`, `{id_alumno, id_materia, ciclo_escolar}` $\to$ `creditos` y $\to$ `calificacion` son **redundantes** porque `{id_alumno, id_materia, ciclo_escolar}+` sin ellas obtiene `id_calificacion` y por $d_{18}$ llega a `creditos` y `calificacion`. Se conserva solo `{id_alumno, id_materia, ciclo_escolar}` $\to$ `id_calificacion`.
   * En `horarios`, por el mismo cierre vía `id_horario`, se conservan únicamente `{id_grupo, dia_semana, hora_inicio}` $\to$ `id_horario` y `{id_salon, dia_semana, hora_inicio}` $\to$ `id_horario`, eliminando los atributos repetidos en el lado derecho de $d_{21}$ y $d_{22}$.

---

### 4. Intercambio de $F$ con otro equipo (Verificación de equivalencia)

> **Pendiente de intercambio presencial/GitHub con equipo compañero:**  
> Para demostrar equivalencia entre nuestro conjunto $F_1$ y el conjunto $F_2$ propuesto por otro equipo del mismo dominio escolar, se verificará bidireccionalmente:
> 1. **Cobertura $F_1 \subseteq F_2^+$:** para cada dependencia $X \to Y \in F_1$, comprobar que $Y \subseteq X^+_{F_2}$.
> 2. **Cobertura $F_2 \subseteq F_1^+$:** para cada dependencia $A \to B \in F_2$, comprobar que $B \subseteq A^+_{F_1}$.
>
> *(Registrar aquí el nombre del equipo, su conjunto $F_2$ y el resultado de las pruebas de cierre antes del 2 de diciembre.)*

---

## Ejercicio 1.3. Formas normales (1FN, 2FN, 3FN y BCNF)

### 1. Diagnóstico del esquema actual de 18 tablas

* **1FN:** Todas las 18 tablas tienen atributos atómicos y carecen de grupos repetitivos.
* **2FN:** En todas las tablas con clave candidata compuesta (`grupos`, `horarios`, `calificaciones`, `pagos_colegiatura`, `recado_respuestas`), ningún atributo no primo depende parcialmente de una parte de la clave.
* **3FN y BCNF:** En las 18 tablas, el lado izquierdo de toda dependencia funcional no trivial en $F_c$ es una **superclave** (ya sea la PK sustituta `id_*` o una clave candidata con restricción `UNIQUE`). Por lo tanto, **las 18 tablas actuales cumplen 3FN y BCNF**.

### 2. Normalización paso a paso de una tabla desnormalizada del dominio escolar

Dado que el esquema actual ya está en BCNF, construimos una tabla desnormalizada típica de una hoja de control escolar ("Boleta y Ficha de Grupo") y la llevamos de **1FN $\to$ 2FN $\to$ 3FN $\to$ BCNF**:

**Relación inicial desnormalizada (`Ficha_Escolar_Plana`):**
$$R(\underline{\text{id\_alumno}}, \underline{\text{id\_materia}}, \text{curp}, \text{nombre\_alumno}, \text{id\_grupo}, \text{grado}, \text{letra}, \text{id\_salon}, \text{clave\_salon}, \text{nombre\_materia}, \text{calificacion})$$

**Dependencias funcionales en $R$:**
* $f_1$: `{id_alumno, id_materia}` $\to$ `calificacion` *(completa)*
* $f_2$: `id_alumno` $\to$ `curp, nombre_alumno, id_grupo` *(parcial sobre la clave)*
* $f_3$: `id_materia` $\to$ `nombre_materia` *(parcial sobre la clave)*
* $f_4$: `id_grupo` $\to$ `grado, letra, id_salon` *(transitiva desde `id_alumno`)*
* $f_5$: `id_salon` $\to$ `clave_salon` *(transitiva desde `id_grupo`)*

**Paso 1FN $\to$ 2FN (eliminación de dependencias parciales $f_2$ y $f_3$):**
* $R_1(\underline{\text{id\_alumno}}, \underline{\text{id\_materia}}, \text{calificacion})$
* $R_2(\underline{\text{id\_materia}}, \text{nombre\_materia})$
* $R_3(\underline{\text{id\_alumno}}, \text{curp}, \text{nombre\_alumno}, \text{id\_grupo}, \text{grado}, \text{letra}, \text{id\_salon}, \text{clave\_salon})$

**Paso 2FN $\to$ 3FN y BCNF (eliminación de dependencias transitivas $f_4$ y $f_5$ en $R_3$):**
* Se extrae $f_4$ (`id_grupo` $\to$ `grado, letra, id_salon`) y luego $f_5$ (`id_salon` $\to$ `clave_salon`):
  * $R_{3a}(\underline{\text{id\_alumno}}, \text{curp}, \text{nombre\_alumno}, \text{id\_grupo})$ $\to$ equivale a `alumnos`
  * $R_{3b}(\underline{\text{id\_grupo}}, \text{grado}, \text{letra}, \text{id\_salon})$ $\to$ equivale a `grupos`
  * $R_{3c}(\underline{\text{id\_salon}}, \text{clave\_salon})$ $\to$ equivale a `salones`
  * $R_1$ $\to$ equivale a `calificaciones`; $R_2$ $\to$ equivale a `materias`.

### 3. Comprobación de reunión sin pérdida y preservación de dependencias

* **Reunión sin pérdida (prueba de atributos comunes):**
  * $R_1 \cap R_2 = \{\text{id\_materia}\}$ y $\text{id\_materia} \to R_2$ (es PK de $R_2$) $\implies$ **sin pérdida**.
  * $(R_1 \bowtie R_2) \cap R_{3a} = \{\text{id\_alumno}\}$ y $\text{id\_alumno} \to R_{3a}$ (es PK de $R_{3a}$) $\implies$ **sin pérdida**.
  * $R_{3a} \cap R_{3b} = \{\text{id\_grupo}\}$ y $\text{id\_grupo} \to R_{3b}$ (es PK de $R_{3b}$) $\implies$ **sin pérdida**.
  * $R_{3b} \cap R_{3c} = \{\text{id\_salon}\}$ y $\text{id\_salon} \to R_{3c}$ (es PK de $R_{3c}$) $\implies$ **sin pérdida**.
* **Preservación de dependencias:** cada dependencia original ($f_1$ en $R_1$, $f_3$ en $R_2$, $f_2$ en $R_{3a}$, $f_4$ en $R_{3b}$ y $f_5$ en $R_{3c}$) queda contenida íntegramente en una sola tabla resultante, por lo que $(F_{R_1} \cup F_{R_2} \cup F_{R_{3a}} \cup F_{R_{3b}} \cup F_{R_{3c}})^+ = F^+$.

### 4. Implementación como migración conservando datos existentes

En `practica6-8/migraciones/05_expansion_abc_tutores_recados.sql` se aplicó la separación de la relación de tutores (`alumno_tutores`) y de respuestas a recados (`recado_respuestas`) sobre la base ya poblada, **migrando los registros existentes con `INSERT ... SELECT` sin recapturar a mano**:

~~~sql
INSERT INTO alumno_tutores (id_alumno, id_tutor, es_principal)
SELECT id_alumno, id_tutor, TRUE
FROM alumnos
WHERE id_tutor IS NOT NULL
ON CONFLICT (id_alumno, id_tutor) DO NOTHING;
~~~
**Documentación de Cambios en la Base de Datos (Refactorización - Abril 2025)**

**Objetivo General:** Mejorar la integridad, robustez, rendimiento, mantenibilidad y escalabilidad de la base de datos, con un enfoque especial en el subsistema de localización geográfica/administrativa.

**Fecha:** 29 de Abril de 2025

**Resumen de Áreas Mejoradas:**

1.  **Integridad Referencial y Robustez de Datos:**
    * **Foreign Keys (FKs) Corregidas y Añadidas:**
        * **Qué se hizo:** Se añadieron todas las FKs que faltaban lógicamente (ej. entre `created_by`/`updated_by` y `auth.users`, entre tablas de jerarquía y catálogos). Se corrigieron columnas que usaban `integer` para referenciar `uuid` (ej. `patient_addresses.address_type_id`, `terminals.subscription_plan_id`) cambiándolas a `uuid` y añadiendo la FK correcta. Se estandarizó que `created_by`/`updated_by` apunten consistentemente a `auth.users(id)`.
        * **Por qué:** Asegura que las relaciones entre tablas sean obligatorias y correctas a nivel de base de datos, previene datos huérfanos y errores de tipo.
        * **Ejemplo:** La columna `professional_profiles.created_by` ahora tiene una FK válida a `auth.users(id)`. La columna `patient_addresses.address_type_id` ahora es `uuid` y referencia correctamente a `catalog_items(id)`.
    * **Acciones Referenciales (`ON DELETE`) Aseguradas:**
        * **Qué se hizo:** Se eliminó el uso peligroso y generalizado de `ON DELETE CASCADE` que podía causar borrados masivos accidentales (ej. borrar un usuario borraba pacientes, historias, etc.). Se reemplazó mayormente por `ON DELETE RESTRICT` (previene el borrado si hay referencias) o `ON DELETE SET NULL` (permite el borrado pero deja la referencia en `NULL`).
        * **Por qué:** Protege contra la pérdida accidental de datos críticos. El borrado de entidades importantes ahora debe ser más controlado.
        * **Ejemplo:** Borrar un registro de `auth.users` ya no borrará en cascada los registros asociados en `public.users`, `patients`, etc., gracias a `ON DELETE RESTRICT`. La purga específica de administradores se maneja ahora con una función dedicada.
    * **Manejo de Nacionalidad Simplificado:**
        * **Qué se hizo:** Se eliminó la tabla `nationalities`. La nacionalidad de un paciente ahora se vincula directamente a un país mediante la columna `patients.nationality_country_id` (antes `nationality_item_id`) que ahora tiene una FK a `countries(id)`. Se añadió una columna `demonym` a `country_translations` para almacenar el gentilicio (ej. "Dominicano/a").
        * **Por qué:** Simplifica el modelo, evita redundancia y usa la tabla `countries` existente de forma directa y clara. Centraliza la información del gentilicio para fácil consulta y traducción.
        * **Ejemplo:** Para saber la nacionalidad de un paciente, ahora consultas `patients.nationality_country_id`, haces `JOIN` con `countries` y `country_translations` para obtener el nombre del país y el `demonym` (gentilicio).

2.  **Optimización y Estandarización de Auditoría:**
    * **Estrategia de Log:**
        * **Qué se hizo:** Se modificó la lógica de auditoría para dejar de guardar el JSON completo de la fila (`OLD`/`NEW`) en `audit_logs.changed_data`. Ahora, esa columna se deja `NULL` y solo se guarda información esencial del evento: operación, tabla, ID del registro afectado, quién (`changed_by`) y cuándo (`changed_at`).
        * **Por qué:** Reduce drásticamente el tamaño de la tabla `audit_logs`, mejora el rendimiento de las operaciones de escritura (INSERT/UPDATE/DELETE) y disminuye los costos de almacenamiento a largo plazo.
    * **Consolidación de Funciones:**
        * **Qué se hizo:** Se eliminaron las múltiples funciones de trigger de auditoría (`log_audit_changes`, `log_changes`, `generic_log_audit_changes`) y se reemplazaron por una única función estándar: `log_audit_event()`. Todos los triggers de auditoría ahora llaman a esta función.
        * **Por qué:** Estandariza la lógica, simplifica el mantenimiento y asegura un comportamiento consistente.
    * **Soft Delete en Auditoría Eliminado:**
        * **Qué se hizo:** Se eliminaron los triggers de soft delete (`soft_del_audit_logs`, etc.) de la tabla `audit_logs` y sus particiones.
        * **Por qué:** El soft delete no tiene sentido para logs de auditoría, añade sobrecarga y la gestión de datos antiguos se realiza eficientemente mediante el sistema de particionamiento (eliminando particiones viejas).

3.  **Eliminación de Redundancias y Mejora de Claridad:**
    * **Índices:** Se eliminaron índices que eran duplicados exactos de otros o claramente innecesarios (ej. índices parciales en PKs).
    * **Triggers:** Se quitaron triggers duplicados (soft delete en `countries`, `audit_logs`) y aquellos cuya lógica ya estaba cubierta por otro trigger (ej. `trg_terminals_update_updated_at` vs `handle_audit_fields`).
    * **Constraints:** Se eliminó la constraint `UNIQUE` redundante en `catalog_types` que duplicaba la PK. Se manejó la dependencia de FK para poder eliminarla.
    * **Tablas:** Se eliminaron las tablas `siblings` (considerada redundante con `family_members`) y `administrative_hierarchy_rules` (reemplazada por la lógica `ltree`).
    * **Renombrado para Claridad:** Se renombraron las tablas `patient_attachment_styles` y `patient_attachments` a `patient_received_upbringing` y `patient_provided_parenting` respectivamente. También se renombraron sus columnas, constraints, índices y triggers asociados para reflejar su propósito real (Crianza Recibida vs. Crianza Proporcionada) de forma consistente.

4.  **Refactorización del Subsistema de Localización (Migración a `ltree`):**
    * **Cambio de Modelo:** Se abandonó el modelo de lista de adyacencia (`parent_id`) para `administrative_units`.
    * **Nueva Estructura `administrative_units`:**
        * Se eliminaron `parent_id` y `type_id` (que usaba `catalog_items`).
        * Se añadió `path ltree NOT NULL`: Almacena la ruta jerárquica completa usando códigos cortos como etiquetas (ej. `'DO.32.SDE.INV'` para Invivienda, SDE, Sto Dgo, RD). Permite consultas jerárquicas extremadamente rápidas.
        * Se añadió `unit_type TEXT NOT NULL`: Almacena el tipo de unidad directamente (ej. `'PROVINCE'`, `'MUNICIPALITY'`, `'NEIGHBORHOOD'`). Validado por una `CHECK constraint`.
        * Se añadió `iso_code TEXT NULL`: Para códigos estándar opcionales (ej. ISO 3166-2 para provincias).
        * Se añadió un índice `GiST` sobre `path` (esencial para el rendimiento de `ltree`).
    * **Reestructuración de `patient_addresses`:**
        * Se eliminaron `city_id` y `province_id`.
        * Se añadió `administrative_unit_id UUID NULL`: Referencia al `id` de la unidad administrativa más específica conocida para la dirección en la tabla `administrative_units`.
        * **Beneficio:** Modelo más simple, flexible y potente para manejar direcciones y obtener su jerarquía completa usando `ltree`.

5.  **Creación de Objetos Auxiliares:**
    * **Refresco de Vista Materializada:** Se configuró un trabajo `pg_cron` para refrescar `mv_catalog_dropdown` automáticamente (ej. cada hora), asegurando que los datos para UI estén actualizados.
    * **Funciones Helper `ltree`:** Se crearon `get_admin_unit_path_text(uuid, text)` (devuelve ruta legible como "País / Provincia / ...") y `get_ancestor_of_type(uuid, text)` (encuentra el ID del ancestro de un tipo específico, ej. la provincia de un municipio). Simplifican las consultas desde la aplicación.
    * **Función de Purga:** Se creó `purge_administrator_data(uuid)` para manejar el borrado controlado de datos asociados a un usuario administrador, respetando el orden de dependencias. Debe ser llamada por la aplicación.

**Estado Actual y Próximos Pasos Clave (Resumen):**

La estructura de la base de datos ha sido refactorizada y mejorada significativamente. Los siguientes pasos son **esenciales** y dependen de ti:

1.  **Cargar Datos:** Poblar `administrative_units` con la DPT completa de RD (construyendo paths `ltree`) y recargar `patient_addresses` vinculándolas correctamente. Poblar `demonym` en `country_translations`.
2.  **Finalizar Constraints:** Ejecutar los `ALTER TABLE ... SET NOT NULL` para `administrative_units.path`, `administrative_units.unit_type` y (opcionalmente) `patient_addresses.administrative_unit_id` una vez cargados los datos.
3.  **Integrar con Aplicación:** Adaptar el código backend/frontend para usar la nueva estructura (`administrative_unit_id`), llamar a las funciones helper (`ltree`, purga) y manejar la lógica de borrado de admin.
4.  **Documentar (Continuar):** Seguir añadiendo `COMMENT ON ...` al schema.
5.  **Seguridad (RLS):** Planificar e implementar Row Level Security antes de producción.

Entendido. Aquí tienes una propuesta de sección de documentación que puedes agregar o adaptar a tu documento existente, explicando cómo insertar nuevas unidades administrativas usando la estructura ltree.

Documentación Adicional: Gestión de Unidades Administrativas (administrative_units)

Esta sección detalla el procedimiento para agregar nuevas unidades administrativas a la tabla public.administrative_units utilizando la estructura jerárquica ltree.

Estructura de la Tabla administrative_units (Relevante):

id: uuid, PK, autogenerado (gen_random_uuid()).

name: text, Nombre oficial de la unidad.

country_id: uuid, FK a la tabla countries (siempre el mismo para RD).

unit_type: text, Tipo de unidad (ej. 'PROVINCE', 'MUNICIPALITY', 'SECTION', 'NEIGHBORHOOD'). Debe ser uno de los valores permitidos por la constraint chk_unit_type.

path: ltree, Ruta jerárquica. Es crucial y debe construirse correctamente.

iso_code: text, (Opcional) Código ISO 3166-2 si aplica (usualmente para Provincias).

Construcción de la Ruta ltree (path):

La ruta ltree representa la jerarquía completa de la unidad administrativa, desde el país hasta la unidad específica. Usamos etiquetas cortas y consistentes para cada nivel, separadas por puntos (.).

Formato General: Pais.Provincia.Municipio.[DistritoMunicipal.]Seccion.[BarrioOParaje]

Etiquetas Propuestas:

País (COUNTRY): Código ISO Alpha-2 (ej. 'DO').

Provincia (PROVINCE): Código numérico oficial de 2 dígitos (ej. '01', '32').

Municipio (MUNICIPALITY): Código numérico oficial de 2 dígitos (ej. '01', '05'). Nota: La etiqueta aquí es solo el código del municipio dentro de su provincia.

Distrito Municipal (MUNICIPAL_DISTRICT): Código numérico oficial de 2 dígitos (ej. '02', '03'). Nota: Se añade después del código del municipio al que pertenece.

Sección (SECTION): Prefijo 'S' seguido del código numérico oficial de 2 dígitos (ej. 'S01', 'S04').

Barrio/Paraje (NEIGHBORHOOD): Prefijo 'B' (Barrio, usualmente en zona urbana) o 'P' (Paraje, usualmente en zona rural) seguido del código numérico oficial de 3 dígitos (ej. 'B001', 'P015'). Nota: Se anida bajo la Sección correspondiente.

Ejemplos de Rutas ltree:

País: DO (República Dominicana)

Provincia: DO.32 (Santo Domingo)

Municipio: DO.32.05 (San Antonio de Guerra, Municipio 05 de la Provincia 32)

Distrito Municipal: DO.32.01.02 (San Luis, DM 02 del Municipio 01 de la Provincia 32)

Sección: DO.32.05.S03 (La Joya, Sección 03 del Municipio 05 de la Provincia 32)

Barrio: DO.32.01.B001 (Villa Duarte, Barrio 001 del Municipio 01 (Zona Urbana) de la Provincia 32)

Paraje: DO.32.05.S03.P001 (La Joya, Paraje 001 de la Sección 03 del Municipio 05 de la Provincia 32)

Procedimiento de Inserción:

Para insertar una nueva unidad administrativa:

Identificar la Jerarquía Completa: Determina la ruta completa desde el país hasta la unidad que quieres insertar, incluyendo los códigos de cada nivel superior (Provincia, Municipio, [DM], Sección).

Verificar Padres: Asegúrate de que todos los niveles superiores en la jerarquía ya existan en la tabla administrative_units. Por ejemplo, para insertar un Paraje, primero deben existir su Sección, su Municipio (o DM), su Provincia y el País.

Construir el Path ltree: Usa las etiquetas correctas y el formato Padre.EtiquetaNueva.

Determinar unit_type: Selecciona el tipo correcto de la lista permitida (COUNTRY, PROVINCE, MUNICIPALITY, MUNICIPAL_DISTRICT, SECTION, NEIGHBORHOOD).

Ejecutar el INSERT:

Ejemplos de Sentencias INSERT:

Insertar una nueva Sección "Los Frailes" (código 08) en el Municipio San Antonio de Guerra (05) de Santo Domingo (32):

INSERT INTO public.administrative_units (name, country_id, unit_type, path, iso_code)
VALUES (
    'Los Frailes',
    'c86fc901-371e-4a07-a3f1-ee3265737a85', -- ID de RD
    'SECTION',
    'DO.32.05.S08', -- País.Prov.Mun.Sección
    NULL
);


Insertar un nuevo Paraje "El Limoncillar" (código 011) dentro de la Sección "Los Frailes" (S08) anterior:

INSERT INTO public.administrative_units (name, country_id, unit_type, path, iso_code)
VALUES (
    'El Limoncillar',
    'c86fc901-371e-4a07-a3f1-ee3265737a85', -- ID de RD
    'NEIGHBORHOOD', -- Usamos NEIGHBORHOOD para Parajes también
    'DO.32.05.S08.P011', -- País.Prov.Mun.Sección.Paraje
    NULL
);
IGNORE_WHEN_COPYING_START
content_copy
download
Use code with caution.
SQL
IGNORE_WHEN_COPYING_END

Insertar un nuevo Barrio "Invivienda" (código 020) en el Municipio Santo Domingo Este (01):

INSERT INTO public.administrative_units (name, country_id, unit_type, path, iso_code)
VALUES (
    'Invivienda',
    'c86fc901-371e-4a07-a3f1-ee3265737a85', -- ID de RD
    'NEIGHBORHOOD',
    'DO.32.01.B020', -- País.Prov.Mun.Barrio
    NULL
);
IGNORE_WHEN_COPYING_START
content_copy
download
Use code with caution.
SQL
IGNORE_WHEN_COPYING_END

Consideraciones Importantes:

Fuente de Datos: Utiliza siempre la División Político-Territorial oficial más reciente de la ONE como fuente para nombres y códigos.

Consistencia de Etiquetas: Mantén la consistencia en las etiquetas usadas en el path (códigos numéricos para Prov/Mun/DM, prefijos S/B/P para Sección/Barrio/Paraje).

Integridad: Verifica la existencia de los padres antes de insertar un hijo para evitar errores de FK o rutas ltree inválidas. La estructura ltree por sí sola no impone esta restricción a nivel de base de datos, pero es crucial para la lógica de la aplicación y las consultas jerárquicas.
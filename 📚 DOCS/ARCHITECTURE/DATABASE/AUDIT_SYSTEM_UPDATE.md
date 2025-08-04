## Documentación: Implementación del Sistema de Auditoría Avanzado

**Fecha:** 5 de Mayo de 2025

**1. Resumen:**
Se ha implementado un sistema de auditoría avanzado en la base de datos PostgreSQL (Supabase) para reemplazar el mecanismo anterior. Los objetivos principales eran:
* Registrar un historial detallado de cambios (`INSERT`, `UPDATE`, `DELETE`, `SOFT_DELETE`) en tablas críticas.
* Capturar el estado anterior (`old_data`) y posterior (`new_data`) de las filas afectadas para análisis y **sentar las bases para una futura funcionalidad de "Deshacer/Revertir"**.
* Mejorar la identificación del usuario que realiza el cambio, distinguiendo entre usuarios de la aplicación (vía JWT) y desarrolladores (vía GUC o `session_user`).
* Estandarizar el manejo de columnas de auditoría (`created_at`, `updated_at`, `created_by`, `updated_by`) en las tablas de datos.
* Mejorar el rendimiento y la mantenibilidad del sistema de auditoría.

**2. Componentes Principales Implementados/Modificados:**

* **Tipo ENUM `public.audit_operation_enum`:**
    * Se creó un nuevo tipo ENUM para estandarizar los valores de operación en el log.
    * Valores: `'INSERT', 'UPDATE', 'DELETE', 'SOFT_DELETE', 'REVERT'`.

* **Tabla `public.audit_log_entries`:**
    * Reemplaza la antigua tabla `audit_logs`.
    * Particionada por `RANGE(changed_at)` para gestión eficiente.
    * **Columnas Clave:**
        * `audit_id` (BIGSERIAL): PK secuencial.
        * `transaction_id` (BIGINT): ID de la transacción PostgreSQL.
        * `operation` (`audit_operation_enum`): Tipo de operación.
        * `schema_name`, `table_name` (TEXT): Identifican la tabla afectada.
        * `record_id` (UUID): PK de la fila afectada.
        * `old_data` (JSONB): Estado completo de la fila **antes** del cambio (para UPDATE/DELETE/SOFT_DELETE). Fundamental para "Deshacer".
        * `new_data` (JSONB): Estado completo de la fila **después** del cambio (para INSERT/UPDATE).
        * `changed_by_user_id` (UUID): El `auth.users.id` del usuario responsable, si se puede determinar. `NULL` si es acceso directo sin GUC.
        * `changed_at` (TIMESTAMPTZ): Fecha/hora exacta del log (`clock_timestamp()`). PK junto con `audit_id`.
        * `app_context` (JSONB): Almacena metadatos adicionales (IP cliente, `change_source`, `session_db_user` si aplica, `terminal_id` si se configura).
        * `statement_only` (BOOLEAN): Flag para logs de alto volumen sin `old/new_data`.
    * Se eliminaron las columnas `is_deleted`, `deleted_at` de la tabla de auditoría.

* **Función `public.capture_audit_event()`:**
    * Reemplaza la antigua función `log_audit_event`.
    * Se ejecuta `AFTER INSERT OR UPDATE OR DELETE`.
    * **Lógica Principal:**
        * Captura `OLD` y `NEW` como JSONB.
        * Determina `changed_by_user_id` con prioridad: JWT (`current_setting('request.jwt.claim.sub')`) > Fallback a `created_by`/`updated_by` de la fila > GUC (`current_setting('myapp.developer_user_id')`) > `NULL`.
        * Si `changed_by_user_id` es `NULL` (acceso directo sin GUC), captura `session_user` en `app_context`.
        * Registra la fuente de identificación (`change_source`) en `app_context`.
        * Detecta operaciones `SOFT_DELETE` basadas en cambios en `is_deleted`.
        * Inserta la entrada detallada en `audit_log_entries`.
        * Usa `BEGIN/EXCEPTION` para manejar de forma segura la posible ausencia de columnas (`created_by`, `updated_by`, `is_deleted`) en tablas auditadas.
    * Definida como `SECURITY DEFINER` para poder leer GUCs de sesión como el JWT.

* **Triggers `trg_audit_*` (AFTER):**
    * Se crearon nuevos triggers `AFTER INSERT OR UPDATE OR DELETE` para todas las tablas auditadas (ej. `trg_audit_patients`, `trg_audit_country_translations`, etc.).
    * Estos triggers reemplazan a los antiguos (`trg_*_audit`).
    * Llaman a la nueva función `capture_audit_event()`, pasando el nombre de la columna PK y el flag `statement_only`.

* **Función `public.handle_audit_columns_trigger_func()`:**
    * Función mejorada y **recomendada** que reemplaza a la antigua y defectuosa `handle_audit_fields`.
    * Se ejecuta `BEFORE INSERT OR UPDATE`.
    * **Lógica Principal:**
        * En `INSERT`: Establece `created_at`, `updated_at` a `clock_timestamp()`. Intenta establecer `created_by` usando la misma lógica de identificación de usuario (JWT > GUC).
        * En `UPDATE`: Establece `updated_at` a `clock_timestamp()`. Intenta establecer `updated_by` usando la lógica de identificación de usuario. **Importante:** Preserva los valores originales de `created_at` y `created_by`.
        * Usa `BEGIN/EXCEPTION` para manejar la posible ausencia de columnas (`created_by`, `updated_by`).
        * **No** consulta `information_schema`, mejorando significativamente el rendimiento respecto a `handle_audit_fields`.

* **Triggers `trg_manage_audit_columns_*` (BEFORE):**
    * Se crearon/actualizaron triggers `BEFORE INSERT OR UPDATE` para todas las tablas que necesitan gestión automática de columnas de auditoría (ej. `trg_manage_audit_columns_patients`, `trg_manage_audit_columns_country_translations`, etc.).
    * Estos triggers reemplazan a los antiguos (`trg_*_audit_fields`).
    * Llaman a la nueva y correcta función `handle_audit_columns_trigger_func()`.

* **Modificaciones de Esquema:**
    * Se añadieron las columnas `created_by UUID NULL` y `updated_by UUID NULL` a la tabla `public.country_translations`.
    * Se añadieron las restricciones de clave foránea correspondientes desde estas columnas hacia `auth.users(id)`.

**3. Identificación de Desarrolladores (Acceso Directo):**

* **Usuarios de Aplicación:** Identificados automáticamente vía JWT (`request.jwt.claim.sub`) por ambos triggers (`capture_audit_event` y `handle_audit_columns_trigger_func`).
* **Desarrolladores (Manual/Directo):**
    * **Procedimiento Requerido:** Deben ejecutar `SET LOCAL myapp.developer_user_id = 'SU_UUID_DE_AUTH.USERS';` antes de cualquier `INSERT/UPDATE/DELETE` manual dentro de una transacción.
    * **Registro:** Si se sigue el procedimiento, ambos triggers capturarán el UUID correcto en `changed_by_user_id` (para el log) y en `updated_by` (para la tabla, si es UPDATE). El `app_context` del log indicará `change_source: developer_guc_override`.
    * **Fallback:** Si se olvida el `SET LOCAL`, el trigger `capture_audit_event` registrará `changed_by_user_id` como `NULL`, pero guardará el `session_user` (usuario de la BD) en `app_context` con `change_source: developer_direct_access`. El trigger `handle_audit_columns_trigger_func` dejará `updated_by` sin cambios (o `NULL`).

**4. Limpieza Realizada:**

* Se actualizaron todos los triggers `trg_*_audit_fields` para que usen `handle_audit_columns_trigger_func`.
* Se eliminó la función antigua y defectuosa `public.handle_audit_fields()`.

**5. Próximos Pasos / Consideraciones:**

* Implementar la lógica de negocio para la funcionalidad "Deshacer/Revertir" utilizando los datos `old_data` de `audit_log_entries`.
* Configurar Row Level Security (RLS) en `audit_log_entries` para controlar quién puede ver qué logs.
* Automatizar la creación de particiones futuras para `audit_log_entries` (ej. usando `pg_partman` o `pg_cron`).
* Establecer políticas de retención, archivado y purga para `audit_log_entries`.
* Monitorizar el rendimiento y el tamaño de la tabla de auditoría.
* Planificar la eliminación de la función `log_audit_event` y la tabla `audit_logs` antiguas cuando ya no sean necesarias.
## Documentación: Implementación del Sistema de Auditoría Avanzado

**Fecha:** 5 de Agosto de 2025  
**Actualizado:** 11 de Agosto de 2025 (v2.0)

**1. Resumen:**
Se ha implementado un sistema de auditoría avanzado en la base de datos PostgreSQL (Supabase). Los objetivos principales son:
* Registrar un historial detallado de cambios (`INSERT`, `UPDATE`, `DELETE`, `SOFT_DELETE`) en tablas críticas.
* Capturar el estado anterior (`old_data`) y posterior (`new_data`) de las filas afectadas para análisis y una futura funcionalidad de "Deshacer/Revertir".
* Estandarizar el manejo de columnas de auditoría (`created_at`, `updated_at`, `created_by`, `updated_by`).
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
        * `old_data` (JSONB): Estado completo de la fila **antes** del cambio.
        * `new_data` (JSONB): Estado completo de la fila **después** del cambio.
        * `changed_by_user_id` (UUID): El `auth.users.id` del usuario responsable.
        * `changed_at` (TIMESTAMPTZ): Fecha/hora exacta del log (`clock_timestamp()`).

* **Función `public.capture_audit_event()`:**
    * Se ejecuta `AFTER INSERT OR UPDATE OR DELETE`.
    * **Lógica Principal:**
        * Captura `OLD` y `NEW` como JSONB.
        * Determina `changed_by_user_id` a partir del JWT (`current_setting('request.jwt.claim.sub')`).
        * Detecta operaciones `SOFT_DELETE` basadas en cambios en `is_deleted`.
        * Inserta la entrada detallada en `audit_log_entries`.

* **Triggers `trg_audit_*` (AFTER):**
    * Se crearon nuevos triggers `AFTER INSERT OR UPDATE OR DELETE` para todas las tablas auditadas (ej. `trg_audit_patients`).
    * Llaman a la nueva función `capture_audit_event()`.

* **Función `util.handle_audit_columns_trigger_func()`:**
    * Se ejecuta `BEFORE INSERT OR UPDATE`.
    * **Lógica Principal:**
        * En `INSERT`: Establece `created_at`, `updated_at` y `created_by`.
        * En `UPDATE`: Establece `updated_at` y `updated_by`.

* **Triggers `trg_manage_audit_columns_*` (BEFORE):**
    * Se crearon/actualizaron triggers `BEFORE INSERT OR UPDATE` para todas las tablas que necesitan gestión automática de columnas de auditoría (ej. `trg_manage_audit_columns_patients`).
    * Llaman a la función `util.handle_audit_columns_trigger_func()`.

**3. Próximos Pasos / Consideraciones:**

* Implementar la lógica de negocio para la funcionalidad "Deshacer/Revertir" utilizando los datos `old_data` de `audit_log_entries`.
* Configurar Row Level Security (RLS) en `audit_log_entries` para controlar quién puede ver qué logs.
* Automatizar la creación de particiones futuras para `audit_log_entries` (ej. usando `pg_cron` y la función `manage_audit_log_partitions`).
* Establecer políticas de retención, archivado y purga para `audit_log_entries`.

---

## Refactorización y Limpieza de la Base de Datos (Agosto 2025)

### Actualizaciones Implementadas - Versión 2.0

#### 1. Corrección de Columnas de Auditoría (`updated_at` y `updated_by`)

**Problema Identificado**: Al crear un nuevo registro, las columnas `updated_at` y `updated_by` se estaban poblando incorrectamente en la operación `INSERT`.

**Solución Aplicada**: Modificación de la función `handle_audit_columns_trigger_func()` para establecer `updated_at` y `updated_by` como `NULL` en operaciones `INSERT`:

```sql
IF (TG_OP = 'INSERT') THEN
    NEW.created_at := clock_timestamp();
    NEW.updated_at := NULL; -- CORRECCIÓN
    NEW.updated_by := NULL;
    ...
```

#### 2. Estandarización del Borrado Lógico (Soft Delete)

**Mejora Implementada**: Se añadió la columna `deleted_by` a todas las tablas con borrado lógico:

- **34 tablas actualizadas** con `deleted_by uuid NULL`
- **Llave foránea** a `auth.users(id)` con `ON DELETE SET NULL`
- **Integración automática** con la función `soft_delete_generic()` existente

#### 3. Eliminación de Funciones Obsoletas

**Funciones Eliminadas por Categoría**:

| Categoría | Funciones Eliminadas | Justificación |
|-----------|---------------------|---------------|
| **Flujo Obsoleto** | `create_initial_admin_and_terminal()`, `create_user_in_public()` | Contrario al flujo actual, manejado por triggers |
| **Redundancia** | `update_updated_at_column()`, `create_professional_profile()` | Lógica ya cubierta por funciones centralizadas |
| **Desarrollo/Testing** | `sync_*`, `repair_*`, `test_*`, `monitor_*` | Funciones para desarrollo no productivo |
| **Huérfanas** | `get_next_available_id()`, `refresh_mv_catalog_dropdown()` | Sin uso en esquema actual |

**Funciones Conservadas**: Las funciones administrativas como `permanently_delete_user`, `restore_deleted_user` fueron mantenidas por su valor para gestión de datos.

#### 4. Impacto en la Integridad del Sistema

- ✅ **Auditoría mejorada**: Registro completo de quién eliminó registros
- ✅ **Datos más limpios**: Estados iniciales correctos sin `updated_at` falsos
- ✅ **Menor superficie de error**: Eliminación de código muerto
- ✅ **Mantenimiento simplificado**: Esquema más coherente y actualizado

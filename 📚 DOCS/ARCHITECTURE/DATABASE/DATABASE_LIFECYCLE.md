# 🧬 Flujo de Vida de la Base de Datos: Un Análisis Detallado

## 1. Introducción

Este documento describe el ciclo de vida completo de los datos en la base de datos de la aplicación, desde la creación inicial de un usuario y su terminal hasta la gestión de pacientes y registros clínicos. Se basa en el análisis del esquema SQL (`schema.sql`), la documentación del flujo de la aplicación Flutter y las Edge Functions de Supabase.

## 2. Onboarding de Usuario y Configuración de la Terminal

El proceso de onboarding es el punto de partida para cualquier usuario en el sistema. A continuación, se detalla el flujo, haciendo referencia a las funciones y tablas específicas del `schema.sql`:

1.  **Registro de Usuario**: Un nuevo usuario se registra en la aplicación. Esto crea un nuevo registro en la tabla `auth.users` de Supabase. Inmediatamente después, se dispara el trigger `handle_new_user`, que ejecuta la función `handle_new_user()`. Esta función:
    *   Valida que los campos `first_name` y `last_name` no estén vacíos.
    *   Asigna un rol inicial (`administrator` para el primer usuario, `guest_user` para los siguientes).
    *   Crea una entrada en la tabla `public.users`, encriptando los datos personales con `pgsodium.crypto_aead_det_encrypt`.

2.  **Creación del Perfil Profesional**: Después de la inserción en `public.users`, el trigger `trg_create_professional_profile` ejecuta la función `handle_new_user_profile_creation()`. Si el rol del usuario es de tipo clínico (ej. `Psychologist`, `Therapist`), se crea automáticamente un registro en `public.professional_profiles`.

3.  **Verificación de Terminal**: La aplicación Flutter, a través de la función `get_user_profile_with_terminals`, verifica si el usuario tiene una terminal asignada. Esta función consulta las tablas `public.terminals` y `public.user_terminal_roles`.

4.  **Redirección a la Configuración de la Terminal**: Si el usuario no tiene una terminal, se le redirige a la pantalla de configuración.

5.  **Creación de la Terminal**:
    *   El usuario completa el formulario en la pantalla de configuración.
    *   La aplicación llama a la Edge Function `create-terminal`.
    *   La Edge Function invoca la función SQL `create_terminal()`.
    *   La función `create_terminal()`:
        *   Crea una nueva terminal en la tabla `public.terminals`.
        *   Asigna al usuario como administrador de la nueva terminal en `public.user_terminal_roles`.

6.  **Redirección a la Pantalla Principal**: Con la terminal configurada, el usuario es redirigido a la pantalla principal de la aplicación.

## 3. Gestión de Pacientes

La gestión de pacientes es una de las funcionalidades principales de la aplicación. El ciclo de vida de los datos de un paciente es el siguiente:

*   **Creación**: Un nuevo paciente es registrado a través de la función `get_patient_details`. Esto crea un nuevo registro en la tabla `public.patients`, así como en tablas relacionadas como `public.patient_addresses`, `public.patient_emails`, y `public.patient_phones`. Los datos sensibles son encriptados.
*   **Lectura**: La información de los pacientes se obtiene a través de la función `get_patients()`, que desencripta los datos para su visualización.
*   **Actualización**: Los datos del paciente se pueden modificar. Cada actualización se registra en la tabla `public.audit_log_entries` para mantener un historial de cambios.
*   **Eliminación (Soft Delete)**: Cuando se elimina un paciente, se activa el trigger `soft_del_patients` que ejecuta la función `util.soft_delete_generic()`. Esta función marca el registro como eliminado (`is_deleted = true`) y establece la fecha de eliminación (`deleted_at`), sin borrarlo físicamente.

## 4. Registros Clínicos

La aplicación gestiona una variedad de registros clínicos, cada uno con su propio ciclo de vida:

*   **Historias Clínicas (`public.clinical_histories`)**: Se crea una historia clínica para cada paciente. La información se almacena en formato `bytea` para mayor seguridad.
*   **Diagnósticos (`public.diagnoses`)**: Los profesionales pueden registrar diagnósticos para los pacientes. Estos registros también están sujetos a auditoría y soft delete.
*   **Evaluaciones (`public.evaluations`)**: Se pueden registrar múltiples evaluaciones para cada paciente.
*   **Tratamientos (`public.treatments`)**: Los tratamientos se asocian a un paciente y a un profesional. El progreso del tratamiento se registra en la tabla `public.therapy_sessions`.

## 5. Auditoría e Integridad de Datos

El sistema cuenta con un robusto mecanismo de auditoría y de integridad de datos:

*   **Tabla de Auditoría (`public.audit_log_entries`)**: Cada cambio en las tablas principales se registra en esta tabla particionada mensualmente. La función `manage_audit_log_partitions()` se encarga de crear las particiones necesarias.
*   **Triggers de Auditoría**: La mayoría de las tablas tienen un trigger `trg_audit_*` que llama a la función `public.capture_audit_event()` para registrar los cambios.
*   **Soft Delete**: La mayoría de las tablas utilizan un sistema de "soft delete" a través de la función `util.soft_delete_generic()`.
*   **Validación de Datos**: Se utilizan triggers como `trg_patients_chk_gender` que llaman a la función `util.validate_catalog_item_type()` para asegurar que los datos introducidos son correctos y consistentes.
*   **Seguridad a Nivel de Fila (RLS)**: Se aplican políticas de seguridad para restringir el acceso a los datos según el rol y la terminal del usuario. La función `enforce_same_terminal()` es un ejemplo de cómo se implementa esta seguridad.

## 6. Recuperación de Datos y Dropdowns

La Edge Function `get-dropdown-data` es esencial para la interfaz de usuario, ya que proporciona los datos para los menús desplegables:

*   **Llamada desde Flutter**: La aplicación Flutter llama a esta Edge Function para obtener listas de países, provincias, municipios, etc.
*   **Funciones SQL de Soporte**: La Edge Function se apoya en funciones SQL como `get_countries_for_dropdown()`, `get_provinces_by_country()`, y `get_direct_admin_children()` para obtener los datos de la base de datos.
*   **Soporte de Traducciones**: Las funciones pueden devolver datos traducidos según el idioma especificado, consultando tablas como `public.country_translations`.
*   **Jerarquía en Cascada**: La función permite la carga de datos en cascada, aprovechando la estructura jerárquicas de la tabla `public.administrative_units` y su columna `path` de tipo `ltree`.
¡Claro! A continuación, modificaré el diseño de la base de datos para incorporar un sistema de auditoría que permita al administrador tener un historial de actividades, incluyendo la capacidad de deshacer cambios y restaurar estados previos. Implementaremos un sistema de auditoría basado en triggers y tablas de historial, que registrará todas las operaciones **INSERT**, **UPDATE** y **DELETE** en las tablas críticas.

---

# **Diseño Modificado de la Base de Datos con Sistema de Auditoría**

## **Nuevas Tablas Introducidas**

1. **Tabla de Auditoría General**: `audit_logs`
2. **Tablas de Historial por Entidad**: Por ejemplo, `patients_history`, `users_history`, etc.

---

## **1. Tabla: `audit_logs`**

Esta tabla almacena un registro general de todas las operaciones realizadas en las tablas auditadas.

**Campos:**

- `audit_id` (SERIAL, Primary Key): Identificador único del registro de auditoría.
- `operation` (VARCHAR(10)): Tipo de operación realizada (`INSERT`, `UPDATE`, `DELETE`).
- `table_name` (VARCHAR(50)): Nombre de la tabla afectada.
- `record_id` (UUID): Identificador del registro afectado.
- `changed_data` (JSONB): Datos antes y después del cambio.
- `changed_by` (UUID): Identificador del usuario que realizó la operación.
- `changed_at` (TIMESTAMP): Fecha y hora en que se realizó la operación.

---

## **2. Modificaciones en las Tablas Existentes**

### **A. Tabla: `users`**

**Nuevos Campos:**

- `created_by` (UUID): Identificador del usuario que creó el registro.
- `updated_by` (UUID): Identificador del usuario que realizó la última actualización.
- `created_at` (TIMESTAMP): Fecha y hora de creación (ya existente).
- `updated_at` (TIMESTAMP): Fecha y hora de la última actualización.

**Implementación de Soft Deletes:**

- `is_deleted` (BOOLEAN): Indica si el registro ha sido eliminado lógicamente (`TRUE`) o no (`FALSE`).

### **B. Tabla: `patients`**

**Nuevos Campos:**

- `created_by` (UUID): Identificador del usuario que creó el registro.
- `updated_by` (UUID): Identificador del usuario que realizó la última actualización.
- `created_at` (TIMESTAMP): Fecha y hora de creación (ya existente).
- `updated_at` (TIMESTAMP): Fecha y hora de la última actualización.

**Implementación de Soft Deletes:**

- `is_deleted` (BOOLEAN): Indica si el registro ha sido eliminado lógicamente (`TRUE`) o no (`FALSE`).

### **C. Otras Tablas Clave**

Aplica los mismos cambios a las tablas:

- `clinical_history`
- `family_area`
- `work_area`
- `love_area`
- `personal_social_area`
- `evaluations`
- `diagnoses`
- `treatments`
- `therapy_sessions`
- `initial_evaluations`

---

## **3. Tablas de Historial por Entidad**

Para cada tabla clave, crearemos una tabla de historial que almacenará las versiones anteriores de los registros.

### **Ejemplo: Tabla `patients_history`**

**Campos:**

- `history_id` (SERIAL, Primary Key): Identificador único del historial.
- `id` (UUID): Identificador único del paciente (mismo que en `patients`).
- `user_id` (UUID): Referencia al usuario que registró al paciente.
- ... *(todos los campos originales de `patients`)*
- `changed_by` (UUID): Identificador del usuario que realizó el cambio.
- `changed_at` (TIMESTAMP): Fecha y hora en que se realizó el cambio.
- `operation` (VARCHAR(10)): Tipo de operación (`INSERT`, `UPDATE`, `DELETE`).

---

## **4. Implementación de Triggers para Auditoría**

### **A. Trigger para la Tabla `patients`**

```sql
-- Función de auditoría para la tabla patients
CREATE OR REPLACE FUNCTION audit_patients()
RETURNS TRIGGER AS $$
BEGIN
  -- Insertar en la tabla de historial
  INSERT INTO patients_history (
    id, user_id, name, id_number, phone, email, date_of_birth, gender,
    marital_status, education_level, occupation, province_city, neighborhood,
    family_core, nationality, origin, health_insurance, emergency_contact_1,
    emergency_phone_1, emergency_contact_2, emergency_phone_2, created_by,
    created_at, updated_by, updated_at, is_deleted, changed_by, changed_at, operation
  )
  VALUES (
    OLD.id, OLD.user_id, OLD.name, OLD.id_number, OLD.phone, OLD.email, OLD.date_of_birth, OLD.gender,
    OLD.marital_status, OLD.education_level, OLD.occupation, OLD.province_city, OLD.neighborhood,
    OLD.family_core, OLD.nationality, OLD.origin, OLD.health_insurance, OLD.emergency_contact_1,
    OLD.emergency_phone_1, OLD.emergency_contact_2, OLD.emergency_phone_2, OLD.created_by,
    OLD.created_at, OLD.updated_by, OLD.updated_at, OLD.is_deleted, NEW.updated_by, NOW(), TG_OP
  );

  -- Registrar en audit_logs
  INSERT INTO audit_logs (
    operation, table_name, record_id, changed_data, changed_by, changed_at
  )
  VALUES (
    TG_OP,
    'patients',
    COALESCE(NEW.id, OLD.id),
    json_build_object('old', row_to_json(OLD), 'new', row_to_json(NEW)),
    NEW.updated_by,
    NOW()
  );

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Crear el trigger
CREATE TRIGGER trigger_audit_patients
AFTER UPDATE OR DELETE ON patients
FOR EACH ROW
EXECUTE FUNCTION audit_patients();
```

### **B. Triggers para Otras Tablas**

Repite un proceso similar para las demás tablas que requieran auditoría, adaptando los campos según corresponda.

---

## **5. Función para Obtener el Usuario Actual**

Para registrar `created_by` y `updated_by`, necesitamos una forma de obtener el identificador del usuario actual en las funciones y triggers de la base de datos.

### **Implementación:**

- **Variable de Sesión:** Podemos utilizar la extensión `set_config` y `current_setting` para almacenar y recuperar el `user_id`.

**Al iniciar sesión en la aplicación, establece el `user_id`:**

```sql
SELECT set_config('app.current_user_id', 'UUID_DEL_USUARIO', false);
```

**Función para obtener el `user_id`:**

```sql
CREATE OR REPLACE FUNCTION current_user_id()
RETURNS UUID AS $$
BEGIN
  RETURN current_setting('app.current_user_id')::UUID;
EXCEPTION
  WHEN OTHERS THEN
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;
```

---

## **6. Modificaciones en las Operaciones CRUD de la Aplicación**

### **A. Inserciones (`INSERT`)**

- Al crear un nuevo registro, asignar `created_by` y `created_at` utilizando `current_user_id()` y `NOW()`.

### **B. Actualizaciones (`UPDATE`)**

- Al actualizar un registro, asignar `updated_by` y `updated_at` de la misma manera.

### **C. Eliminaciones Lógicas (`DELETE` -> `UPDATE`)**

- En lugar de eliminar físicamente los registros, actualiza `is_deleted` a `TRUE` y registra la operación en las tablas de auditoría.

---

## **7. Funcionalidad para Deshacer Cambios**

### **A. Restaurar un Registro a un Estado Anterior**

- Proporciona una función o procedimiento almacenado que permita copiar datos desde la tabla de historial hacia la tabla principal.

**Ejemplo de Función para Restaurar un Paciente:**

```sql
CREATE OR REPLACE FUNCTION restore_patient_version(p_history_id SERIAL)
RETURNS VOID AS $$
DECLARE
  patient_record patients_history%ROWTYPE;
BEGIN
  -- Obtener el registro de historial
  SELECT * INTO patient_record FROM patients_history WHERE history_id = p_history_id;

  -- Actualizar el registro en patients
  UPDATE patients
  SET
    user_id = patient_record.user_id,
    name = patient_record.name,
    id_number = patient_record.id_number,
    -- ... otros campos ...
    updated_by = current_user_id(),
    updated_at = NOW()
  WHERE id = patient_record.id;

  -- Registrar la restauración en el historial
  INSERT INTO patients_history (..., operation)
  VALUES (..., 'RESTORE');

  -- Registrar en audit_logs
  INSERT INTO audit_logs (...)
  VALUES (...);
END;
$$ LANGUAGE plpgsql;
```

### **B. Interfaz en la Aplicación**

- Proporciona al administrador una interfaz donde pueda:

  - Ver el historial de cambios de un registro.
  - Seleccionar una versión anterior para restaurar.
  - Confirmar la restauración.

---

## **8. Ejemplo Completo de la Tabla `patients` con Cambios**

```sql
CREATE TABLE patients (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id),
  name VARCHAR(100),
  id_number VARCHAR(20),
  phone VARCHAR(20),
  email VARCHAR(100),
  date_of_birth DATE,
  gender VARCHAR(10),
  marital_status VARCHAR(50),
  education_level VARCHAR(100),
  occupation VARCHAR(100),
  province_city VARCHAR(100),
  neighborhood VARCHAR(100),
  family_core VARCHAR(200),
  nationality VARCHAR(50),
  origin VARCHAR(100),
  health_insurance VARCHAR(100),
  emergency_contact_1 VARCHAR(100),
  emergency_phone_1 VARCHAR(20),
  emergency_contact_2 VARCHAR(100),
  emergency_phone_2 VARCHAR(20),
  created_by UUID DEFAULT current_user_id(),
  created_at TIMESTAMP DEFAULT NOW(),
  updated_by UUID,
  updated_at TIMESTAMP,
  is_deleted BOOLEAN DEFAULT FALSE
);
```

---

## **9. Consideraciones Adicionales**

### **A. Seguridad y Permisos**

- **Control de Acceso Basado en Roles (RBAC):** Asegurar que solo usuarios autorizados puedan acceder y modificar datos sensibles o realizar restauraciones.

- **Protección de Datos de Auditoría:** Los registros de auditoría pueden contener información sensible. Limita el acceso a las tablas de auditoría a usuarios autorizados.

### **B. Rendimiento**

- **Índices:** Crear índices en campos utilizados frecuentemente en consultas de auditoría, como `changed_at`, `changed_by`, etc.

- **Optimización de Triggers:** Asegúrate de que los triggers estén optimizados para minimizar el impacto en el rendimiento.

### **C. Políticas de Retención**

- **Retención de Datos de Auditoría:** Define cuánto tiempo conservarás los registros de auditoría y establece procesos para archivar o eliminar datos antiguos.

### **D. Monitoreo y Alertas**

- Implementa sistemas de monitoreo para detectar y alertar sobre actividades inusuales o potencialmente maliciosas.

---

## **10. Actualización del Esquema General de la Base de Datos**

Incluiré solo las tablas principales con las modificaciones para evitar redundancias.

### **Tabla: `users`**

```sql
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  terminal_id UUID REFERENCES terminals(id),
  first_name VARCHAR(100),
  last_name VARCHAR(100),
  email VARCHAR(100),
  phone VARCHAR(20),
  role user_role,
  created_by UUID DEFAULT current_user_id(),
  created_at TIMESTAMP DEFAULT NOW(),
  updated_by UUID,
  updated_at TIMESTAMP,
  is_deleted BOOLEAN DEFAULT FALSE
);
```

### **Tabla: `clinical_history`**

Aplicar los mismos cambios que en `patients`:

- Añadir `created_by`, `created_at`, `updated_by`, `updated_at`, `is_deleted`.
- Implementar triggers y tablas de historial correspondientes.

---

## **11. Implementación de Soft Deletes en Consultas**

Al realizar consultas en las tablas principales, debes filtrar los registros que no han sido eliminados lógicamente.

**Ejemplo:**

```sql
SELECT * FROM patients WHERE is_deleted = FALSE;
```

---

## **12. Resumen de Pasos para Implementar el Sistema de Auditoría**

1. **Añadir Campos de Auditoría a las Tablas Principales:**

   - `created_by`, `created_at`, `updated_by`, `updated_at`, `is_deleted`.

2. **Crear Tablas de Historial para Cada Entidad Clave:**

   - Incluir todos los campos de la tabla principal, más campos adicionales para auditoría (`changed_by`, `changed_at`, `operation`).

3. **Crear la Tabla General de Auditoría (`audit_logs`):**

   - Almacenar registros de todas las operaciones realizadas en el sistema.

4. **Implementar Funciones y Triggers:**

   - Para registrar automáticamente las operaciones en las tablas de historial y `audit_logs`.

5. **Implementar Funcionalidad de Restauración:**

   - Funciones para restaurar registros a estados previos utilizando los datos del historial.

6. **Actualizar la Lógica de la Aplicación:**

   - Ajustar las operaciones CRUD para manejar los nuevos campos y lógica de auditoría.
   - Proporcionar interfaces para que los administradores puedan ver el historial y restaurar registros.

7. **Seguridad y Permisos:**

   - Asegurar que solo usuarios autorizados puedan acceder a los registros de auditoría y realizar restauraciones.

8. **Monitoreo y Alertas:**

   - Configurar sistemas para detectar y alertar sobre actividades sospechosas.

---

## **Conclusión**

Al incorporar este sistema de auditoría en tu base de datos, mejorarás significativamente el control y seguimiento de las actividades dentro del sistema. El administrador podrá visualizar un historial detallado de los cambios, y tendrás la capacidad de deshacer operaciones y restaurar registros a estados anteriores, aumentando la robustez y confiabilidad de tu aplicación.

**Recomendaciones Finales:**

- **Pruebas Exhaustivas:** Antes de implementar en producción, realiza pruebas exhaustivas para asegurarte de que el sistema de auditoría funciona correctamente y no introduce problemas de rendimiento.

- **Documentación:** Documenta detalladamente las nuevas estructuras, funciones y procedimientos para facilitar el mantenimiento y futuras actualizaciones.

- **Capacitación:** Asegura que el equipo de desarrollo y los administradores del sistema estén familiarizados con las nuevas funcionalidades y sepan cómo utilizarlas de manera efectiva.

---

Si necesitas más detalles sobre algún aspecto específico de la implementación o tienes más preguntas, ¡no dudes en consultarme!
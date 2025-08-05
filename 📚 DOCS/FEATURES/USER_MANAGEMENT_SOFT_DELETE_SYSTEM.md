# 📚 **Documentación: Sistema de Gestión de Usuarios con Soft Delete y Auditoría**

## 🎯 **Resumen del Proyecto**

Implementación de un sistema completo de gestión de usuarios que incluye valores por defecto inteligentes, soft delete, auditoría completa y limpieza automática, compatible con el dashboard de Supabase.

---

## 1. **Sistema de Soft Delete**

### **Requisitos**
- Eliminación lógica en lugar de física
- Preservación de datos para auditoría
- Limpieza automática después de período definido

### **Implementación**

#### **Columnas Agregadas**
```sql
-- Agregar columnas para soft delete
ALTER TABLE public.users 
ADD COLUMN is_deleted BOOLEAN DEFAULT FALSE,
ADD COLUMN deleted_at TIMESTAMPTZ NULL,
ADD COLUMN deleted_by UUID REFERENCES auth.users(id) ON DELETE SET NULL;
```

#### **Función de Soft Delete**
```sql
CREATE OR REPLACE FUNCTION util.soft_delete_generic()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    -- SOFT DELETE
    EXECUTE format(
        'UPDATE %I.%I SET is_deleted = true, deleted_at = now() WHERE id = $1',
        TG_TABLE_SCHEMA,
        TG_TABLE_NAME
    )
    USING OLD.id;
    
    RETURN NULL;
END;
$$;

-- Crear trigger
CREATE TRIGGER soft_del_users
    BEFORE DELETE ON public.users
    FOR EACH ROW
    EXECUTE FUNCTION util.soft_delete_generic('id');
```

---

## 2. **Auditoría y Triggers**

### **Sistema de Auditoría Mejorado**

#### **Función de Auditoría de Columnas**
```sql
CREATE OR REPLACE FUNCTION util.handle_audit_columns_trigger_func()
RETURNS trigger 
LANGUAGE plpgsql 
AS $$
DECLARE
    v_user_id UUID := NULL;
BEGIN
    -- Intentar obtener el User ID
    BEGIN
        v_user_id := (current_setting('request.jwt.claim.sub', TRUE))::uuid;
    EXCEPTION WHEN OTHERS THEN
        NULL;
    END;

    -- Si es un INSERT
    IF (TG_OP = 'INSERT') THEN
        NEW.created_at := clock_timestamp();
        NEW.updated_at := clock_timestamp();
        IF v_user_id IS NOT NULL THEN
            NEW.created_by := v_user_id;
        END IF;
        NEW.updated_by := NULL;

    -- Si es un UPDATE
    ELSIF (TG_OP = 'UPDATE') THEN
        NEW.created_at := OLD.created_at;
        NEW.created_by := OLD.created_by;
        NEW.updated_at := clock_timestamp();

        -- DETECTAR soft delete y manejar accordingly
        IF NEW.is_deleted = true AND (OLD.is_deleted = false OR OLD.is_deleted IS NULL) THEN
            NEW.updated_by := NULL;
        ELSE
            NEW.updated_by := v_user_id;
        END IF;
    END IF;

    RETURN NEW;
END;
$$;
```

---

## 3. **Sistema de Limpieza Automática**

### **Función de Limpieza**
```sql
CREATE OR REPLACE FUNCTION public.hard_delete_all_older_than(older_than interval)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    table_record RECORD;
    delete_count INTEGER;
    total_deleted INTEGER := 0;
    result_text TEXT := '';
BEGIN
    -- ... (la lógica de la función permanece igual)
END;
$$;
```

### **Job Automatizado con pg_cron**
```sql
-- Programar limpieza diaria a las 4:00 AM
SELECT cron.schedule(
    'daily-user-purge-job',
    '0 4 * * *', -- 4:00 AM todos los días
    $$ SELECT public.hard_delete_all_older_than('30 days'::interval); $$
);
```

---

## 4. **Funciones de Consulta**

### **Función para Ver Usuarios Eliminados**
```sql
CREATE OR REPLACE FUNCTION public.get_deleted_users()
RETURNS TABLE (
    id UUID,
    email TEXT,
    deleted_at TIMESTAMPTZ,
    deleted_by UUID,
    deleted_by_email TEXT,
    days_since_deletion INTEGER
)
-- ... (la lógica de la función permanece igual)
$$;
```

### **Función de Estadísticas**
```sql
CREATE OR REPLACE FUNCTION public.get_deletion_stats()
RETURNS TABLE (
    total_deleted BIGINT,
    self_deleted BIGINT,
    admin_deleted BIGINT,
    system_deleted BIGINT,
    oldest_deletion TIMESTAMPTZ,
    newest_deletion TIMESTAMPTZ
)
-- ... (la lógica de la función permanece igual)
$$;
```

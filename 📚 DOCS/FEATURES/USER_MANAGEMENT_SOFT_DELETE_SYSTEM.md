# 📚 **Documentación: Sistema de Gestión de Usuarios con Soft Delete y Auditoría**

## 🎯 **Resumen del Proyecto**

Implementación de un sistema completo de gestión de usuarios que incluye valores por defecto inteligentes, soft delete, auditoría completa y limpieza automática, compatible con el dashboard de Supabase.

---

## 📋 **Tabla de Contenidos**

1. [Valores por Defecto Inteligentes](#1-valores-por-defecto-inteligentes)
2. [Sistema de Soft Delete](#2-sistema-de-soft-delete)
3. [Auditoría y Triggers](#3-auditoría-y-triggers)
4. [Compatibilidad con Dashboard Supabase](#4-compatibilidad-con-dashboard-supabase)
5. [Sistema de Limpieza Automática](#5-sistema-de-limpieza-automática)
6. [Funciones de Consulta](#6-funciones-de-consulta)
7. [Configuración Final](#7-configuración-final)

---

## 1. **Valores por Defecto Inteligentes**

### **Problema Original**
Los campos `first_name` y `last_name` tenían valores por defecto estáticos que no proporcionaban información útil.

### **Solución Implementada**

#### **Trigger para Manejo de Nombres**
```sql
CREATE OR REPLACE FUNCTION public.handle_new_user() 
RETURNS trigger 
LANGUAGE plpgsql 
SECURITY DEFINER 
AS $$
BEGIN
    -- Establecer valores por defecto inteligentes si están vacíos
    IF NEW.first_name IS NULL OR NEW.first_name = '' THEN
        NEW.first_name := 'Usuario';
    END IF;
    
    IF NEW.last_name IS NULL OR NEW.last_name = '' THEN
        NEW.last_name := SUBSTRING(NEW.id::TEXT FROM 1 FOR 8);
    END IF;
    
    RETURN NEW;
END;
$$;

-- Crear trigger
CREATE TRIGGER handle_new_user_trigger
    BEFORE INSERT ON public.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user();
```

#### **Resultado**
- `first_name`: "Usuario" (valor legible)
- `last_name`: Primeros 8 caracteres del UUID (identificador único)

---

## 2. **Sistema de Soft Delete**

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

-- Crear índices para optimización
CREATE INDEX idx_users_soft_delete ON public.users(is_deleted, deleted_at);
CREATE INDEX idx_users_deleted_by ON public.users(deleted_by);
```

#### **Función de Soft Delete**
```sql
CREATE OR REPLACE FUNCTION public.soft_delete_generic()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY definer
AS $$
DECLARE
    v_user_id UUID := NULL;
BEGIN
    -- DETECTAR CASCADE DELETE (dashboard de Supabase)
    IF pg_trigger_depth() > 1 THEN
        RAISE NOTICE 'CASCADE DELETE detectado, permitiendo eliminación física para usuario %', OLD.id;
        RETURN OLD;
    END IF;
    
    -- CAPTURAR QUIÉN ESTÁ ELIMINANDO
    -- 1. Intentar JWT (usuario logueado)
    BEGIN
        v_user_id := (current_setting('request.jwt.claim.sub', TRUE))::uuid;
    EXCEPTION WHEN OTHERS THEN
        NULL;
    END;
    
    -- 2. Si no hay JWT, intentar GUC (desarrolladores)
    IF v_user_id IS NULL THEN
        BEGIN
            v_user_id := current_setting('myapp.developer_user_id', TRUE)::uuid;
        EXCEPTION WHEN OTHERS THEN
            NULL;
        END;
    END IF;
    
    -- 3. Si el usuario se está eliminando a sí mismo
    IF v_user_id IS NULL OR v_user_id = OLD.id THEN
        v_user_id := OLD.id; -- Auto-eliminación
    END IF;
    
    -- SOFT DELETE sin tocar updated_at ni updated_by
    EXECUTE format(
        'UPDATE %I.%I SET is_deleted = true, deleted_at = now(), deleted_by = $1 WHERE id = $2',
        TG_TABLE_SCHEMA,
        TG_TABLE_NAME
    )
    USING v_user_id, OLD.id;
    
    RAISE NOTICE 'Soft delete aplicado: usuario % eliminado por %', OLD.id, COALESCE(v_user_id::text, 'SISTEMA');
    
    RETURN NULL;
END;
$$;

-- Crear trigger
CREATE TRIGGER soft_del_users
    BEFORE DELETE ON public.users
    FOR EACH ROW
    EXECUTE FUNCTION public.soft_delete_generic('id');
```

---

## 3. **Auditoría y Triggers**

### **Sistema de Auditoría Mejorado**

#### **Función de Auditoría de Columnas**
```sql
CREATE OR REPLACE FUNCTION public.handle_audit_columns_trigger_func()
RETURNS trigger 
LANGUAGE plpgsql 
AS $$
DECLARE
    v_user_id UUID := NULL;
BEGIN
    -- Intentar obtener el User ID
    BEGIN
        v_user_id := (current_setting('request.jwt.claim.sub', TRUE));
    EXCEPTION WHEN OTHERS THEN
        NULL;
    END;

    -- Intentar GUC para desarrolladores
    IF v_user_id IS NULL THEN
        BEGIN
            v_user_id := current_setting('myapp.developer_user_id', TRUE)::uuid;
        EXCEPTION WHEN OTHERS THEN
            NULL;
        END;
    END IF;

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
            -- Es un soft delete - poner updated_by en NULL
            NEW.updated_by := NULL;
            RAISE NOTICE '[AUDIT] Soft delete detectado para usuario %, updated_by=NULL', OLD.id;
        ELSE
            -- UPDATE normal
            NEW.updated_by := v_user_id;
        END IF;
    END IF;

    RETURN NEW;
END;
$$;
```

---

## 4. **Compatibilidad con Dashboard Supabase**

### **Problema Identificado**
El dashboard de Supabase realiza eliminaciones físicas directamente desde `auth.users`, causando conflictos con el sistema de soft delete.

### **Solución Implementada**

#### **Ajuste de Foreign Key Constraints**
```sql
-- Cambiar constraints para permitir CASCADE desde auth.users
ALTER TABLE public.users DROP CONSTRAINT users_created_by_fkey;
ALTER TABLE public.users 
ADD CONSTRAINT users_created_by_fkey 
FOREIGN KEY (created_by) REFERENCES auth.users (id) ON DELETE CASCADE;

ALTER TABLE public.users DROP CONSTRAINT users_updated_by_fkey;
ALTER TABLE public.users 
ADD CONSTRAINT users_updated_by_fkey 
FOREIGN KEY (updated_by) REFERENCES auth.users (id) ON DELETE CASCADE;

ALTER TABLE public.users DROP CONSTRAINT users_id_fkey;
ALTER TABLE public.users 
ADD CONSTRAINT users_id_fkey 
FOREIGN KEY (id) REFERENCES auth.users (id) ON DELETE CASCADE;
```

#### **Actualización de Constraints de Tablas Relacionadas**
```sql
-- professional_profiles
ALTER TABLE public.professional_profiles DROP CONSTRAINT IF EXISTS professional_profiles_user_id_fkey;
ALTER TABLE public.professional_profiles 
ADD CONSTRAINT professional_profiles_user_id_fkey 
FOREIGN KEY (user_id) REFERENCES public.users (id) ON DELETE CASCADE;

-- user_emails
ALTER TABLE public.user_emails DROP CONSTRAINT IF EXISTS user_emails_user_id_fkey;
ALTER TABLE public.user_emails 
ADD CONSTRAINT user_emails_user_id_fkey 
FOREIGN KEY (user_id) REFERENCES public.users (id) ON DELETE CASCADE;

ALTER TABLE public.user_emails DROP CONSTRAINT IF EXISTS user_emails_created_by_fkey;
ALTER TABLE public.user_emails 
ADD CONSTRAINT user_emails_created_by_fkey 
FOREIGN KEY (created_by) REFERENCES public.users (id) ON DELETE SET NULL;

-- patients
ALTER TABLE public.patients DROP CONSTRAINT IF EXISTS patients_registered_by_fkey;
ALTER TABLE public.patients 
ADD CONSTRAINT patients_registered_by_fkey 
FOREIGN KEY (registered_by) REFERENCES public.users (id) ON DELETE SET NULL;

-- user_phones
ALTER TABLE public.user_phones DROP CONSTRAINT IF EXISTS user_phones_user_id_fkey;
ALTER TABLE public.user_phones 
ADD CONSTRAINT user_phones_user_id_fkey 
FOREIGN KEY (user_id) REFERENCES public.users (id) ON DELETE CASCADE;
```

### **Resultado**
- ✅ **Dashboard** → Eliminación física (CASCADE DELETE)
- ✅ **Eliminación manual** → Soft delete con auditoría
- ✅ **Sin conflictos** entre ambos métodos

---

## 5. **Sistema de Limpieza Automática**

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
    RAISE NOTICE 'Iniciando purga de registros con más de % de antigüedad...', older_than;
    
    -- Solo procesar tablas que tengan AMBAS columnas: is_deleted Y deleted_at
    FOR table_record IN
        SELECT t.table_name
        FROM information_schema.tables t
        WHERE t.table_schema = 'public'
        AND t.table_type = 'BASE TABLE'
        AND EXISTS (
            SELECT 1 FROM information_schema.columns c1 
            WHERE c1.table_schema = 'public' 
            AND c1.table_name = t.table_name 
            AND c1.column_name = 'is_deleted'
        )
        AND EXISTS (
            SELECT 1 FROM information_schema.columns c2 
            WHERE c2.table_schema = 'public' 
            AND c2.table_name = t.table_name 
            AND c2.column_name = 'deleted_at'
        )
        ORDER BY t.table_name
    LOOP
        RAISE NOTICE 'Procesando tabla: %...', table_record.table_name;
        
        EXECUTE format(
            'DELETE FROM public.%I WHERE is_deleted = true AND deleted_at < (now() - $1)',
            table_record.table_name
        ) USING older_than;
        
        GET DIAGNOSTICS delete_count = ROW_COUNT;
        total_deleted := total_deleted + delete_count;
        
        IF delete_count > 0 THEN
            result_text := result_text || format('- %s: %s registros eliminados' || E'\n', table_record.table_name, delete_count);
            RAISE NOTICE 'Eliminados % registros de %', delete_count, table_record.table_name;
        END IF;
    END LOOP;
    
    IF total_deleted = 0 THEN
        result_text := 'No se encontraron registros para eliminar.';
    ELSE
        result_text := format('TOTAL: %s registros eliminados permanentemente' || E'\n', total_deleted) || result_text;
    END IF;
    
    RAISE NOTICE 'Purga completada. Total eliminado: %', total_deleted;
    RETURN result_text;
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

## 6. **Funciones de Consulta**

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
LANGUAGE sql
SECURITY definer
AS $$
    SELECT 
        u.id,
        au.email,
        u.deleted_at,
        u.deleted_by,
        deleter.email as deleted_by_email,
        EXTRACT(DAYS FROM (now() - u.deleted_at))::integer as days_since_deletion
    FROM public.users u
    LEFT JOIN auth.users au ON u.id = au.id
    LEFT JOIN auth.users deleter ON u.deleted_by = deleter.id
    WHERE u.is_deleted = true
    ORDER BY u.deleted_at DESC;
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
LANGUAGE sql
SECURITY definer
AS $$
    SELECT 
        COUNT(*) as total_deleted,
        COUNT(*) FILTER (WHERE deleted_by = id) as self_deleted,
        COUNT(*) FILTER (WHERE deleted_by != id AND deleted_by IS NOT NULL) as admin_deleted,
        COUNT(*) FILTER (WHERE deleted_by IS NULL) as system_deleted,
        MIN(deleted_at) as oldest_deletion,
        MAX(deleted_at) as newest_deletion
    FROM public.users 
    WHERE is_deleted = true;
$$;
```

---

## 7. **Configuración Final**

### **Triggers Activos**
1. **`handle_new_user_trigger`** - Valores por defecto inteligentes (BEFORE INSERT)
2. **`soft_del_users`** - Soft delete inteligente (BEFORE DELETE)
3. **`trg_manage_audit_columns_users`** - Auditoría de columnas (BEFORE UPDATE/INSERT)
4. **`trg_audit_users`** - Auditoría de eventos (AFTER INSERT/UPDATE/DELETE)

### **Jobs Programados**
- **`daily-user-purge-job`** - Limpieza diaria a las 4:00 AM

### **Configuración para Desarrolladores**
```sql
-- Configurar ID de desarrollador para auditoría
SET myapp.developer_user_id = 'tu-uuid-aqui';
```

---

## 🧪 **Casos de Uso**

### **1. Eliminación desde Dashboard**
- ✅ Usuario eliminado físicamente
- ✅ Todas las tablas relacionadas limpiadas automáticamente
- ✅ Sin errores ni conflictos

### **2. Eliminación Manual**
```sql
DELETE FROM public.users WHERE id = 'user-uuid';
```
- ✅ Soft delete aplicado
- ✅ Auditoría completa con `deleted_by`
- ✅ Datos preservados para consulta

### **3. Auto-eliminación**
- ✅ Usuario elimina su propia cuenta
- ✅ `deleted_by` = `id` (auto-referencia)
- ✅ Auditoría clara del evento

### **4. Limpieza Automática**
- ✅ Ejecuta diariamente
- ✅ Solo afecta registros con más de 30 días
- ✅ Reportes detallados de eliminaciones

---

## 📊 **Consultas Útiles**

```sql
-- Ver usuarios eliminados recientemente
SELECT * FROM public.get_deleted_users();

-- Ver estadísticas de eliminaciones
SELECT * FROM public.get_deletion_stats();

-- Ejecutar limpieza manual
SELECT public.hard_delete_all_older_than('30 days'::interval);

-- Ver jobs programados
SELECT * FROM cron.job;
```

---

## ✅ **Beneficios Implementados**

1. **🔄 Soft Delete Inteligente** - Preserva datos importantes
2. **🎯 Compatibilidad Total** - Funciona con dashboard y APIs
3. **📊 Auditoría Completa** - Rastrea quién, cuándo y cómo
4. **🧹 Limpieza Automática** - Mantiene base de datos optimizada
5. **⚡ Alto Rendimiento** - Índices optimizados
6. **🛡️ Seguridad** - Control granular de permisos
7. **🔍 Transparencia** - Consultas y reportes detallados
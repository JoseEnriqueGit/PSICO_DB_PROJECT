# 🐛 **Bug Analysis: Trigger `handle_new_user` Failure**

## 📋 **Resumen del problema:**

**Error observado**: `"Database error creating new user"` al intentar registrar usuarios a través de Supabase Auth.

**Causa raíz**: Múltiples problemas en cascada que impedían la ejecución correcta del trigger.

---

## 🔍 **Proceso de diagnóstico:**

### **1. Síntomas iniciales**
- ❌ Error genérico: "500: Database error creating new user"
- ❌ Los usuarios no se creaban en `auth.users`
- ❌ No se generaban perfiles en `public.users`

### **2. Primeras hipótesis (incorrectas)**
- **Hipótesis A**: Problema con triggers en `public.users` 
  - **Resultado**: Triggers deshabilitados, problema persistía
- **Hipótesis B**: Problema de permisos o estructura de tabla
  - **Resultado**: Estructura correcta, permisos válidos

### **3. Debugging progresivo**

#### **Test 1: Verificación de componentes**
```sql
-- Verificamos roles, clave de encriptación, tabla users
SELECT * FROM debug_handle_new_user();
```
**Resultado**: ✅ Todos los componentes básicos funcionaban

#### **Test 2: Inserción manual simulada**
```sql
-- Intentamos inserción completa con datos reales
INSERT INTO public.users (id, first_name, last_name, role_id, created_by)
VALUES (NEW.id, encrypted_data, ...);
```
**Resultado**: ❌ Error "query returned no rows"

#### **Test 3: Aislamiento del problema de encriptación**
```sql
-- Inserción sin encriptación
INSERT INTO public.users (id, role_id, created_by)
VALUES (test_id, role_id, test_id);
```
**Resultado**: ✅ Funciona sin encriptación

---

## 🎯 **Problemas identificados:**

### **Problema #1: Clave de encriptación inexistente**
```sql
-- La función devolvía un UUID que no existía en pgsodium.key
SELECT * FROM pgsodium.key WHERE id = 'fc3f5e84-7787-427e-b7be-563bc13818a6';
-- Resultado: 0 filas
```

**Causa**: La clave `app_data_encryption_key` estaba en `vault.secrets`, no en `pgsodium.key`
**Efecto**: `pgsodium.crypto_aead_det_encrypt()` fallaba internamente

### **Problema #2: Conflictos de clave duplicada**
```sql
-- Error al reintentar creación de usuarios
ERROR: duplicate key value violates unique constraint "users_pkey"
```

**Causa**: Intentos fallidos previos dejaban registros inconsistentes
**Efecto**: Nuevos intentos de creación fallaban por duplicados

---

## ✅ **Solución implementada:**

### **1. Nueva clave de encriptación**
```sql
-- Crear clave específica para pgsodium
SELECT pgsodium.create_key(name := 'user_data_encryption');
-- Resultado: 4985bad9-85d0-4f0b-b151-becb6cc6634a
```

### **2. Actualización de función de clave**
```sql
CREATE OR REPLACE FUNCTION public.get_encryption_key_id()
RETURNS uuid AS $$
BEGIN
  RETURN '4985bad9-85d0-4f0b-b151-becb6cc6634a'::uuid;
END;
$$;
```

### **3. Manejo de duplicados**
```sql
-- Verificación previa + manejo de conflictos
IF EXISTS (SELECT 1 FROM public.users WHERE id = NEW.id) THEN
    RETURN NEW;  -- Saltar si ya existe
END IF;

INSERT INTO public.users (...)
VALUES (...)
ON CONFLICT (id) DO NOTHING;  -- Protección adicional
```

---

## 🧪 **Validación final:**

### **Funcionalidad restaurada:**
- ✅ Trigger `handle_new_user_trigger` en `auth.users` funcional
- ✅ Encriptación de `first_name` y `last_name` con pgsodium
- ✅ Asignación automática de roles (primer usuario = admin, resto = guest)
- ✅ Manejo robusto de errores y duplicados
- ✅ Compatibilidad con todos los triggers existentes en `public.users`

### **Tests de regresión:**
```sql
-- Crear usuario nuevo
supabase.auth.signUp({...})
-- ✅ Usuario creado en auth.users
-- ✅ Perfil creado en public.users con datos encriptados
-- ✅ Rol asignado correctamente
```

---

## 📚 **Lecciones aprendidas:**

1. **Diferencia entre vault.secrets y pgsodium.key**: Sistemas de encriptación separados con propósitos diferentes
2. **Debugging incremental**: Aislar componentes uno por uno es más efectivo que asumir causas
3. **Manejo defensivo**: `ON CONFLICT DO NOTHING` previene errores en escenarios edge
4. **Logs detallados**: El error genérico ocultaba la causa real (clave de encriptación faltante)

**Estado final**: Sistema robusto y completamente funcional para producción.
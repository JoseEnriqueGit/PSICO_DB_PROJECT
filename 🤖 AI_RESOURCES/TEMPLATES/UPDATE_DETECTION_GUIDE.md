# 🔍 Guía de Detección de Actualizaciones - Template para Claude Code

## 🎯 Propósito
Esta guía ayuda al agente Claude Code a detectar automáticamente cuando un archivo en INBOX es una actualización de documentación existente, en lugar de un archivo completamente nuevo.

---

## 📋 Proceso de Detección en 4 Fases

### 🔍 **FASE 1: Análisis de Contenido**
1. **Extraer información clave del archivo:**
   - Título principal (H1)
   - Subtítulos importantes (H2, H3)
   - Primeras 200 palabras del contenido
   - Keywords técnicas específicas
   - Referencias a funciones, tablas, sistemas existentes

### 🔗 **FASE 2: Detección de Relaciones**
2. **Comparar con documentos existentes:**
   - Buscar coincidencias en títulos
   - Detectar keywords similares
   - Identificar menciones específicas a código/funciones
   - Calcular score de similitud

### 🎯 **FASE 3: Decisión de Procesamiento**
3. **Elegir acción según score:**
   - **90-100%**: Actualización directa
   - **70-89%**: Nueva versión
   - **50-69%**: Enhancement/addendum
   - **<50%**: Archivo nuevo

### 📝 **FASE 4: Ejecución**
4. **Implementar la decisión:**
   - Fusionar, versionar, o crear nuevo
   - Actualizar README si es necesario
   - Mantener historial

---

## 🔍 **Criterios de Detección por Categoría**

### 🐛 **Detección de Actualizaciones de Bugs**

**Keywords a buscar:**
- Nombres de funciones específicas: `handle_new_user`, `create_terminal`, etc.
- Términos técnicos: "bug", "fix", "error", "resolved", "trigger", "constraint"
- Referencias a tablas: `users`, `terminals`, `audit_log_entries`

**Dónde buscar:**
- `🐛 ISSUES/BUGS/RESOLVED/`
- `🐛 ISSUES/BUGS/ACTIVE/`

**Ejemplo de matching:**
```
Archivo INBOX: "trigger_handle_user_fix_v2.md"
Buscar en archivos existentes: "handle_user", "trigger", "fix"
Match encontrado: "TRIGGER_BUG_ANALYSIS_HANDLE_NEW_USER.md" (85% similitud)
Decisión: Crear nueva versión
```

### ⭐ **Detección de Actualizaciones de Features**

**Keywords a buscar:**
- Nombres de sistemas: "user management", "audit system", "soft delete"
- Términos de versión: "v2", "v3", "update", "improvement", "enhancement"
- Funcionalidades: "authentication", "authorization", "encryption"

**Dónde buscar:**
- `📚 DOCS/FEATURES/`

**Ejemplo de matching:**
```
Archivo INBOX: "user_system_improvements.md"
Keywords: "user", "system", "improvements"
Match encontrado: "USER_MANAGEMENT_SOFT_DELETE_SYSTEM.md" (78% similitud)
Decisión: Fusionar mejoras en documento existente
```

### 🏗️ **Detección de Actualizaciones de Arquitectura**

**Keywords a buscar:**
- Sistemas core: "audit", "schema", "database", "security", "RLS"
- Componentes: "postgresql", "supabase", "pgsodium", "encryption"
- Patrones: "multi-tenant", "partitioning", "indexing"

**Dónde buscar:**
- `📚 DOCS/ARCHITECTURE/`

### 🛠️ **Detección de Scripts SQL Actualizados**

**Keywords a buscar:**
- Nombres de tablas específicas: `terminals`, `users`, `patients`
- Tipos de scripts: "CREATE", "ALTER", "DROP", "INDEX"
- Nombres de funciones: funciones específicas del proyecto

**Dónde buscar:**
- `🛠️ DEVELOPMENT/SQL/SCHEMA/`
- `🛠️ DEVELOPMENT/SQL/FUNCTIONS/`
- `🛠️ DEVELOPMENT/SQL/TRIGGERS/`

---

## 📊 **Sistema de Scoring de Similitud**

### 🔢 **Cálculo de Score (0-100%)**

**Factores de peso:**
- **Título similar (40%)**: Coincidencias en palabras clave del título
- **Contenido similar (30%)**: Keywords técnicas coincidentes
- **Referencias específicas (20%)**: Menciones a código/funciones exactas
- **Contexto de actualización (10%)**: Palabras como "update", "v2", "fix"

**Ejemplo de cálculo:**
```
Archivo: "trigger_bug_update.md"
vs Existente: "TRIGGER_BUG_ANALYSIS_HANDLE_NEW_USER.md"

Título: "trigger" + "bug" = 30/40 pts (75%)
Contenido: "handle_new_user" + "constraint" = 25/30 pts (83%)
Referencias: "handle_new_user()" función = 18/20 pts (90%)
Contexto: "update" detectado = 8/10 pts (80%)

Score total: (30+25+18+8) = 81/100 = 81% similitud
Decisión: Nueva versión (70-89% range)
```

---

## 🎯 **Patrones de Decisión**

### 📋 **OPCIÓN A: Actualizar Documento Existente (90-100%)**
**Cuándo usar:**
- Mismo tema exacto
- Correcciones o adiciones menores
- Información complementaria

**Cómo implementar:**
```markdown
## Actualizaciones - [FECHA]

### Versión 2.0 - Nuevas mejoras
[Contenido nuevo aquí]

### Información adicional
[Contenido complementario]
```

### 📋 **OPCIÓN B: Crear Nueva Versión (70-89%)**
**Cuándo usar:**
- Mismo tema pero cambios significativos
- Nuevas funcionalidades relacionadas
- Arquitectura evolucionada

**Cómo implementar:**
- Crear archivo: `ORIGINAL_NAME_V2.md`
- Mantener versión anterior
- Actualizar README con ambas versiones

### 📋 **OPCIÓN C: Crear Addendum (50-69%)**
**Cuándo usar:**
- Tema relacionado pero diferente enfoque
- Información complementaria sustancial
- Casos de uso adicionales

**Cómo implementar:**
- Crear archivo: `ORIGINAL_NAME_ADDENDUM.md`
- O crear carpeta por tema con múltiples documentos

### 📋 **OPCIÓN D: Enhancement Request (<50% pero mejora)**
**Cuándo usar:**
- Solicitud de mejora detectada
- Críticas constructivas
- Nuevas ideas relacionadas

**Cómo implementar:**
- Mover a: `🐛 ISSUES/ENHANCEMENTS/`
- Usar template de enhancement

---

## 🔍 **Ejemplos Prácticos de Detección**

### ✅ **Ejemplo 1: Update Detectado Correctamente**
```
📥 INBOX: "audit_system_performance_optimization.md"

Análisis:
- Keywords: "audit", "system", "performance", "optimization"
- Buscar en: 📚 DOCS/ARCHITECTURE/AUDIT_SYSTEM_UPDATE.md
- Match encontrado: "audit" + "system" = 85% similitud
- Decisión: OPCIÓN B - Nueva versión
- Resultado: AUDIT_SYSTEM_UPDATE_V2_PERFORMANCE.md
```

### ✅ **Ejemplo 2: Bug Fix Update**
```
📥 INBOX: "handle_user_constraint_fix.md"

Análisis:
- Keywords: "handle_user", "constraint", "fix"
- Buscar en: 🐛 ISSUES/BUGS/RESOLVED/
- Match: TRIGGER_BUG_ANALYSIS_HANDLE_NEW_USER.md = 92% similitud
- Decisión: OPCIÓN A - Actualizar existente
- Resultado: Agregar sección "## Actualizaciones v2.0"
```

### ✅ **Ejemplo 3: Nuevo Feature Detectado**
```
📥 INBOX: "reporting_dashboard_spec.md"

Análisis:
- Keywords: "reporting", "dashboard", "spec"
- Buscar en: 📚 DOCS/FEATURES/
- Sin matches >50%
- Decisión: Archivo nuevo
- Resultado: 📚 DOCS/FEATURES/REPORTING_DASHBOARD.md
```

---

## 🚨 **Casos Especiales y Edge Cases**

### 🔍 **Falsos Positivos**
**Problema:** Archivo con keywords similares pero tema diferente
**Solución:** Verificar contexto completo, no solo keywords aisladas

### 🔍 **Múltiples Matches**
**Problema:** Archivo relacionado con varios documentos existentes
**Solución:** Elegir el match con mayor score, mencionar otros en contenido

### 🔍 **Versiones Complejas**
**Problema:** Ya existe v2, crear v3?
**Solución:** Detectar patrón de versionado existente y continuar secuencia

---

## 📝 **Template de Reporte de Detección**

```markdown
🔍 **REPORTE DE DETECCIÓN DE ACTUALIZACIONES**

📄 **Archivo procesado:** [nombre del archivo]
🎯 **Tipo detectado:** [Bug/Feature/Architecture/SQL/Nuevo]
🔗 **Relaciones encontradas:** 
   - Archivo 1: [nombre] (Score: X%)
   - Archivo 2: [nombre] (Score: Y%)
📊 **Score más alto:** X%
⚡ **Decisión tomada:** [OPCIÓN A/B/C/D]
📁 **Resultado:** [Ubicación final y acción ejecutada]
📝 **README actualizado:** [Sí/No - qué se cambió]
```

Este template asegura detección inteligente y procesamiento consistente de actualizaciones de documentación.
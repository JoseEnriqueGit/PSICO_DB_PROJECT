# 📥 INBOX - Directorio de Procesamiento Automático

## 🎯 Propósito
Este directorio es tu **bandeja de entrada** para documentos. Simplemente coloca aquí cualquier archivo y Claude Code se encargará automáticamente de:

1. 🔍 **Analizar el contenido** del archivo
2. 📁 **Moverlo al directorio correcto** según su tipo y contenido
3. 🏷️ **Renombrarlo** con un nombre descriptivo y apropiado
4. 📝 **Actualizar el README.md** con el nuevo archivo
5. 🧹 **Limpiar este directorio** una vez procesado

## 🚀 Cómo usar:

### Paso 1: Subir archivo
```
Arrastra o crea tu archivo en: 📥 INBOX/
Ejemplo: 📥 INBOX/nuevo_documento.md
```

### Paso 2: Activar el agente
```
Escribe en Claude Code: "procesa inbox"
```

### Paso 3: ¡Listo!
El archivo será organizado automáticamente en su ubicación correcta.

## 📋 Tipos de archivos soportados:

### 📚 Documentación (.md)
- **Análisis de bugs** → `📚 DOCUMENTATION/05_BUG_ANALYSIS/`
- **Documentación de BD** → `📚 DOCUMENTATION/02_DATABASE/`
- **Documentación de seguridad** → `📚 DOCUMENTATION/03_SECURITY/`
- **Documentación de API** → `📚 DOCUMENTATION/04_API/`

### 🛠️ Scripts SQL (.sql)
- **Tablas** → `🛠️ DEVELOPMENT/SQL_SCRIPTS/TABLES/`
- **Funciones** → `🛠️ DEVELOPMENT/SQL_SCRIPTS/FUNCTIONS/`
- **Triggers** → `🛠️ DEVELOPMENT/SQL_SCRIPTS/TRIGGERS/`
- **Migraciones** → `🛠️ DEVELOPMENT/SQL_SCRIPTS/MIGRATIONS/`

### 📋 Referencias (.md)
- **Auditoría** → `📋 REFERENCES/AUDIT/`
- **Roles de usuario** → `📋 REFERENCES/USER_ROLES/`
- **Documentación externa** → `📋 REFERENCES/EXTERNAL_DOCS/`

### 🤖 Recursos de IA (.md)
- **Prompts** → `🤖 AI_RESOURCES/PROMPTS/[SUBCATEGORIA]/`
- **Templates** → `🤖 AI_RESOURCES/TEMPLATES/`

## ⚡ Comandos rápidos:
- `procesa inbox` - Procesar todos los archivos del inbox
- `analiza [archivo]` - Analizar un archivo específico antes de moverlo
- `limpia inbox` - Limpiar archivos ya procesados

## 🎨 Ejemplos de renombrado automático:

| Archivo original | Contenido detectado | Nombre final |
|-----------------|-------------------|-------------|
| `bug_fix.md` | Análisis de bug en login | `LOGIN_BUG_ANALYSIS_SESSION_TIMEOUT.md` |
| `new_table.sql` | Tabla de pacientes | `patients_table_creation.sql` |
| `update.md` | Actualización de sistema | `SYSTEM_UPDATE_[FECHA].md` |

---

**🔄 Este directorio se limpia automáticamente después de procesar los archivos.**
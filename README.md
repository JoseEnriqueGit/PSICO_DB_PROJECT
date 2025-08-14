# PSICO_DB_PROJECT

Proyecto de base de datos PostgreSQL/Supabase para aplicación psicológica con sistema de encriptación avanzado.

## 📋 Descripción del Proyecto

Este proyecto implementa una base de datos segura para una aplicación psicológica, utilizando PostgreSQL con Supabase y un sistema de encriptación robusto con pgsodium.

## 🏗️ Arquitectura

- **Base de Datos**: PostgreSQL con Supabase
- **Encriptación**: pgsodium para datos sensibles
- **Autenticación**: Supabase Auth
- **Seguridad**: Row Level Security (RLS)

---

## 📁 Navegación Rápida - Índice Alfabético

### 📚 Documentación Técnica
#### 🏗️ Arquitectura del Sistema
- **Base de Datos**
  - [Ciclo de Vida de la Base de Datos](📚%20DOCS/ARCHITECTURE/DATABASE/DATABASE_LIFECYCLE.md)
  - [Catálogos Dinámicos](📚%20DOCS/ARCHITECTURE/DATABASE/DYNAMIC_CATALOGS.md)
  - [Localización Geográfica](📚%20DOCS/ARCHITECTURE/DATABASE/GEOGRAPHIC_LOCALIZATION.md)
  - [Sistema de Auditoría](📚%20DOCS/ARCHITECTURE/DATABASE/AUDIT_SYSTEM.md)
- **Flujo de Usuario**
  - [Onboarding de Usuario](📚%20DOCS/ARCHITECTURE/USER_ONBOARDING_COMPLETE_FLOW.md)

#### ⭐ Documentación de Features
- [Implementación MVP Historia Clínica](📚%20DOCS/FEATURES/MVP_CLINICAL_RECORDS_IMPLEMENTATION.md)
- [Sistema de Registro de Pacientes - Overview Completo](📚%20DOCS/FEATURES/PATIENT_SYSTEM_OVERVIEW.md)
- [Sistema de Gestión de Usuarios](📚%20DOCS/FEATURES/USER_MANAGEMENT_SOFT_DELETE_SYSTEM.md)
- [Sistema de Eliminación Permanente](📚%20DOCS/FEATURES/USER_PERMANENT_DELETION_SYSTEM.md)
- [Sistema de Eliminación Automática de Terminales](📚%20DOCS/FEATURES/USER_TERMINAL_AUTO_DELETION_SYSTEM.md)

#### 📱 Frontend Documentation
- [Patient Registration UI (Flutter)](📚%20DOCS/FEATURES/FRONTEND/patient_registration_flutter_ui.md)

---

### 🐛 Gestión de Issues y Problemas
#### ✅ Bugs Resueltos
- [2024-07-31: Fix Trigger handle_new_user](🐛%20ISSUES/BUGS/RESOLVED/TRIGGER_BUG_ANALYSIS_HANDLE_NEW_USER.md)

---

### 🛠️ Recursos de Desarrollo
#### ⚙️ Scripts SQL - Funciones
- [AllFunctionScripts.sql](🛠️%20DEVELOPMENT/SQL/FUNCTIONS/AllFunctionScripts.sql)
- [cleanup_obsolete_functions.sql](🛠️%20DEVELOPMENT/SQL/FUNCTIONS/cleanup_obsolete_functions.sql)
- [patient_management_functions.sql](🛠️%20DEVELOPMENT/SQL/FUNCTIONS/patient_management_functions.sql)

#### 🌐 Edge Functions
- [create-terminal.ts](🛠️%20DEVELOPMENT/CONFIGS/supabase/create-terminal.ts) - Creación de terminales
- [get-dropdown-data.ts](🛠️%20DEVELOPMENT/CONFIGS/supabase/get-dropdown-data.ts) - Datos en cascada
- [create-patient-edge-function.md](🛠️%20DEVELOPMENT/CONFIGS/supabase/create-patient-edge-function.md) - Sistema de registro de pacientes

#### 🗄️ Scripts SQL - Esquemas
- [AllTablesScripts.sql](🛠️%20DEVELOPMENT/SQL/SCHEMA/AllTablesScripts.sql)

---

### 📡 API Documentation
- [Patient Endpoints](📚%20DOCS/API/patient_endpoints.md) - Especificación completa de API

---

### 🧪 Testing
- [Patient System Test Cases](🧪%20TESTING/patient_system_test_cases.md) - Suite completa de pruebas

---

## 🗂️ Estructura del Proyecto

```
PSICO_DB_PROJECT/
├── 📥 INBOX/                           # Bandeja de entrada automática
├── 📚 DOCS/                           # Documentación centralizada
│   ├── ARCHITECTURE/                  # Arquitectura del sistema
│   │   ├── DATABASE/                  # Documentación de la Base de Datos
│   ├── FEATURES/                      # Documentación de características
│   │   └── FRONTEND/                  # Documentación de UI
│   └── API/                           # Documentación de APIs
├── 📋 CHANGELOG/                      # Control de cambios
├── 🐛 ISSUES/                        # Gestión de problemas
├── 🛠️ DEVELOPMENT/                    # Recursos de desarrollo
├── 🧪 TESTING/                        # Casos de prueba y testing
└── 🤖 AI_RESOURCES/                   # Recursos para IA
```

---

## 🚀 Enlaces de Acceso Rápido por Categoría

### 📚 **Documentación Principal**
| Tipo | Archivo | Descripción |
|------|---------|-------------|
| 🧬 **Ciclo de Vida** | [Ciclo de Vida de la BD](📚%20DOCS/ARCHITECTURE/DATABASE/DATABASE_LIFECYCLE.md) | Documento central que describe el flujo de datos. |
| 🏗️ **Arquitectura** | [Sistema de Auditoría](📚%20DOCS/ARCHITECTURE/DATABASE/AUDIT_SYSTEM.md) | Implementación del sistema de auditoría |
| 🔄 **Flujo Integral** | [Onboarding Completo](📚%20DOCS/ARCHITECTURE/USER_ONBOARDING_COMPLETE_FLOW.md) | Frontend + Backend + Base de Datos |
| ⭐ **Features** | [Gestión de Usuarios](📚%20DOCS/FEATURES/USER_MANAGEMENT_SOFT_DELETE_SYSTEM.md) | Sistema completo con soft delete |
| 👥 **Pacientes** | [Sistema de Registro de Pacientes](📚%20DOCS/FEATURES/PATIENT_SYSTEM_OVERVIEW.md) | Implementación completa distribuida en componentes |
| 📡 **API** | [Patient Endpoints](📚%20DOCS/API/patient_endpoints.md) | Especificación completa de API REST |
| 🧪 **Testing** | [Patient Test Cases](🧪%20TESTING/patient_system_test_cases.md) | Suite de pruebas integral |

---

## 🤖 Gemini Agent

Este proyecto incluye un agente especializado para documentación y organización. Ver [GEMINI.md](GEMINI.md) para instrucciones detalladas del agente.

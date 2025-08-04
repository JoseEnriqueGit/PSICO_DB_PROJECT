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
- [Catálogos Dinámicos](📚%20DOCS/ARCHITECTURE/DYNAMIC_CATALOGS.md)
- [Localización Geográfica](📚%20DOCS/ARCHITECTURE/GEOGRAPHIC_LOCALIZATION.md)
- [Sistema de Auditoría](📚%20DOCS/ARCHITECTURE/AUDIT_SYSTEM_UPDATE.md)

#### ⭐ Documentación de Features
- [Implementación MVP Historia Clínica](📚%20DOCS/FEATURES/MVP_CLINICAL_RECORDS_IMPLEMENTATION.md)
- [Sistema de Gestión de Usuarios](📚%20DOCS/FEATURES/USER_MANAGEMENT_SOFT_DELETE_SYSTEM.md)
- [Sistema de Eliminación Permanente](📚%20DOCS/FEATURES/USER_PERMANENT_DELETION_SYSTEM.md)
- [Sistema de Eliminación Automática de Terminales](📚%20DOCS/FEATURES/USER_TERMINAL_AUTO_DELETION_SYSTEM.md)
- [Template para Features](📚%20DOCS/FEATURES/TEMPLATE.md)

#### 📖 API y Operaciones
- *Pendiente*: Documentación de API
- *Pendiente*: Guías de deployment
- *Pendiente*: Troubleshooting

---

### 🐛 Gestión de Issues y Problemas
#### 🚨 Bugs Activos
- *Sin bugs activos reportados*

#### ✅ Bugs Resueltos
- [2024-07-31: Fix Trigger handle_new_user](🐛%20ISSUES/BUGS/RESOLVED/TRIGGER_BUG_ANALYSIS_HANDLE_NEW_USER.md)

#### 💡 Mejoras Solicitadas
- *Sin mejoras pendientes*

#### 🔧 Deuda Técnica
- *Pendiente de identificar*

#### 📋 Templates para Issues
- [Template para Bug Reports](🐛%20ISSUES/BUGS/TEMPLATE.md)
- [Template para Mejoras](🐛%20ISSUES/ENHANCEMENTS/TEMPLATE.md)

---

### 📋 Control de Versiones y Cambios
#### 🚀 Releases
- [Template para Releases](📋%20CHANGELOG/RELEASES/TEMPLATE.md)
- *Pendiente*: Primera release

#### ⭐ Historial de Features
- [2024-07-31: Reestructuración del Proyecto](📋%20CHANGELOG/FEATURES/IDEAS_AND_CHANGES_HISTORY.md)

#### 🚑 Hotfixes
- *Sin hotfixes aplicados*

---

### 🛠️ Recursos de Desarrollo
#### ⚙️ Scripts SQL - Funciones
- [AllFunctionScripts.sql](🛠️%20DEVELOPMENT/SQL/FUNCTIONS/AllFunctionScripts.sql)

#### 🗄️ Scripts SQL - Esquemas
- [address_types.sql](🛠️%20DEVELOPMENT/SQL/SCHEMA/address_types.sql)
- [AllTablesScripts.sql](🛠️%20DEVELOPMENT/SQL/SCHEMA/AllTablesScripts.sql)
- [attachment_types.sql](🛠️%20DEVELOPMENT/SQL/SCHEMA/attachment_types.sql)
- [email_types.sql](🛠️%20DEVELOPMENT/SQL/SCHEMA/email_types.sql)
- [job_statuses.sql](🛠️%20DEVELOPMENT/SQL/SCHEMA/job_statuses.sql)
- [marital_statuses.sql](🛠️%20DEVELOPMENT/SQL/SCHEMA/marital_statuses.sql)
- [phone_types.sql](🛠️%20DEVELOPMENT/SQL/SCHEMA/phone_types.sql)
- [TEMPORAL.sql](🛠️%20DEVELOPMENT/SQL/SCHEMA/TEMPORAL.sql)

#### 🔄 Migraciones
- *Pendiente*: Scripts de migración

#### 🌱 Seeds y Datos Iniciales
- *Pendiente*: Datos de prueba

---

### 🤖 Recursos de IA y Automatización
#### 🎯 Prompts por Categoría
- **Code Review**: *Pendiente*
- **Debugging**: *Pendiente*  
- **Documentation**: *Pendiente*
- **Feature Development**:
  - [Recomendaciones de BD](🤖%20AI_RESOURCES/PROMPTS/FEATURE_DEVELOPMENT/DB_RECOMMENDATIONS.md)
  - [Prompt Gemini DBA](🤖%20AI_RESOURCES/PROMPTS/FEATURE_DEVELOPMENT/GEMINI_DBA_PROMPT.md)

#### 📝 Templates para IA
- *Pendiente*: Templates de prompts

---

## 🗂️ Estructura del Proyecto

```
PSICO_DB_PROJECT/
├── 📥 INBOX/                           # Bandeja de entrada automática
├── 📚 DOCS/                           # Documentación centralizada
│   ├── ARCHITECTURE/                  # Arquitectura del sistema
│   ├── FEATURES/                      # Documentación de características
│   ├── OPERATIONS/                    # Deployment y operaciones
│   ├── TROUBLESHOOTING/              # Resolución de problemas
│   └── API/                          # Documentación de API
├── 📋 CHANGELOG/                      # Control de cambios
│   ├── RELEASES/                     # Notas de versiones
│   ├── FEATURES/                     # Historial de features
│   └── HOTFIXES/                     # Fixes críticos
├── 🐛 ISSUES/                        # Gestión de problemas
│   ├── BUGS/                         # Reportes de bugs
│   ├── ENHANCEMENTS/                 # Solicitudes de mejoras
│   └── TECHNICAL_DEBT/               # Deuda técnica
├── 🛠️ DEVELOPMENT/                    # Recursos de desarrollo
│   ├── SQL/                          # Scripts organizados
│   ├── SCRIPTS/                      # Automatización
│   ├── CONFIGS/                      # Configuraciones
│   └── TOOLS/                        # Herramientas
└── 🤖 AI_RESOURCES/                   # Recursos para IA
    ├── PROMPTS/                      # Prompts categorizados
    └── TEMPLATES/                    # Plantillas
```

---

## 🚀 Enlaces de Acceso Rápido por Categoría

### 📚 **Documentación Principal**
| Tipo | Archivo | Descripción |
|------|---------|-------------|
| 🏗️ **Arquitectura** | [Sistema de Auditoría](📚%20DOCS/ARCHITECTURE/AUDIT_SYSTEM_UPDATE.md) | Implementación del sistema de auditoría |
| ⭐ **Features** | [MVP Historia Clínica](📚%20DOCS/FEATURES/MVP_CLINICAL_RECORDS_IMPLEMENTATION.md) | Documentación completa del MVP implementado |
| ⭐ **Features** | [Gestión de Usuarios](📚%20DOCS/FEATURES/USER_MANAGEMENT_SOFT_DELETE_SYSTEM.md) | Sistema completo con soft delete |
| ⭐ **Features** | [Eliminación Permanente](📚%20DOCS/FEATURES/USER_PERMANENT_DELETION_SYSTEM.md) | Sistema de eliminación definitiva de usuarios |
| 📖 **Templates** | [Feature Template](📚%20DOCS/FEATURES/TEMPLATE.md) | Plantilla para documentación de features |

### 🐛 **Gestión de Issues**
| Tipo | Archivo | Descripción |
|------|---------|-------------|
| ✅ **Bug Resuelto** | [Trigger Fix](🐛%20ISSUES/BUGS/RESOLVED/TRIGGER_BUG_ANALYSIS_HANDLE_NEW_USER.md) | Análisis y solución de bug en triggers |
| 📋 **Templates** | [Bug Template](🐛%20ISSUES/BUGS/TEMPLATE.md) | Plantilla para reportes de bugs |
| 💡 **Templates** | [Enhancement Template](🐛%20ISSUES/ENHANCEMENTS/TEMPLATE.md) | Plantilla para solicitudes de mejoras |

### 📋 **Control de Cambios**
| Tipo | Archivo | Descripción |
|------|---------|-------------|
| ⭐ **Feature** | [Reestructuración](📋%20CHANGELOG/FEATURES/IDEAS_AND_CHANGES_HISTORY.md) | Historial de reestructuración del proyecto |
| 🚀 **Template** | [Release Template](📋%20CHANGELOG/RELEASES/TEMPLATE.md) | Plantilla para notas de release |

### 🛠️ **Desarrollo**
| Tipo | Archivo | Descripción |
|------|---------|-------------|
| 💾 **Esquemas** | [Scripts Completos](🛠️%20DEVELOPMENT/SQL/SCHEMA/AllTablesScripts.sql) | Todas las definiciones de tablas |
| ⚙️ **Funciones** | [Scripts de Funciones](🛠️%20DEVELOPMENT/SQL/FUNCTIONS/AllFunctionScripts.sql) | Funciones de base de datos |

### 🤖 **Recursos de IA**
| Tipo | Archivo | Descripción |
|------|---------|-------------|
| 🎯 **Prompts** | [Recomendaciones BD](🤖%20AI_RESOURCES/PROMPTS/FEATURE_DEVELOPMENT/DB_RECOMMENDATIONS.md) | Mejores prácticas para IA |
| 🎯 **Prompts** | [Gemini DBA](🤖%20AI_RESOURCES/PROMPTS/FEATURE_DEVELOPMENT/GEMINI_DBA_PROMPT.md) | Prompts especializados para BD |

---

## 🤖 Claude Code Agent

Este proyecto incluye un agente especializado para documentación y organización. Ver [CLAUDE.md](CLAUDE.md) para instrucciones detalladas del agente.

**Comandos rápidos:**
- `procesa inbox` - **¡NUEVO!** Procesar archivos de la bandeja de entrada
- `organiza` - Revisar y reorganizar estructura completa
- `actualiza readme` - Regenerar README.md con archivos actuales  
- `limpia proyecto` - Eliminar archivos vacíos y reorganizar
- `analiza [archivo]` - Analizar un archivo específico antes de moverlo

### 📥 Bandeja de Entrada Automática

¿Quieres que Claude Code organice tus archivos automáticamente?

1. **Coloca tu archivo** en la carpeta `📥 INBOX/`
2. **Escribe**: `procesa inbox`
3. **¡Listo!** El archivo será:
   - Analizado por contenido
   - Movido al directorio correcto
   - Renombrado descriptivamente
   - Agregado al README automáticamente

**Ejemplo:**
```
Tu archivo: 📥 INBOX/bug_fix.md
Resultado: 📚 DOCUMENTATION/05_BUG_ANALYSIS/LOGIN_BUG_ANALYSIS_SESSION_TIMEOUT.md
```

---

## Integración con Supabase

Para integrar tu sistema con Supabase:

- **Tabla `auth.users`**: Supabase utiliza esta tabla para manejar la autenticación de usuarios.
- **Tabla `users`**: Almacena información adicional de los usuarios, vinculada por el `id` (UUID) que coincide con `auth.users.id`.

---

## **Tabla: `user_roles`**

Almacena los diferentes roles que un usuario puede tener en el sistema.

**Campos:**

- `id` (SERIAL, Primary Key): Identificador único del rol de usuario.
- `role_name` (VARCHAR(50), UNIQUE, NOT NULL): Nombre del rol.
- `description` (TEXT): Descripción opcional del rol.

**Valores de Ejemplo:**

- Administrator
- Psychologist
- Therapist
- Receptionist
- AdministrativeAssistant
- ClinicManager
- PatientCoordinator
- BillingSpecialist
- SocialWorker
- ClinicalSupervisor
- Psychiatrist
- Intern
- ExternalConsultant
- GuestUser
- SupportTechnician
- SecuritySpecialist
- ResearchCoordinator
- Educator

---

## **Tabla: `users`**

Almacena información adicional de los usuarios asociados a cada terminal.

**Campos:**

- `id` (UUID, Primary Key, Foreign Key → `auth.users(id)`): Identificador único del usuario, coincide con el ID de `auth.users`.
- `terminal_id` (UUID, Foreign Key → `terminals(id)`): Referencia a la terminal.
- `first_name` (VARCHAR(100)): Nombre del usuario.
- `last_name` (VARCHAR(100)): Apellidos del usuario.
- `role_id` (INTEGER, Foreign Key → `user_roles(id)`): Referencia al rol del usuario.
- `created_at` (TIMESTAMP, Default: NOW()): Fecha y hora de registro.
- `created_by` (UUID, Foreign Key → `auth.users(id)`): Usuario que creó el registro.
- `updated_at` (TIMESTAMP): Fecha y hora de última actualización.
- `updated_by` (UUID, Foreign Key → `auth.users(id)`): Usuario que actualizó el registro.
- `is_deleted` (BOOLEAN, Default: FALSE): Indicador de eliminación lógica.

---

## **Tabla: `user_phones`**

Almacena los números de teléfono asociados a los usuarios.

**Campos:**

- `id` (UUID, Primary Key): Identificador único del teléfono.
- `user_id` (UUID, Foreign Key → `users(id)`): Referencia al usuario asociado.
- `phone_number` (VARCHAR(20)): Número de teléfono.
- `phone_type_id` (INTEGER, Foreign Key → `phone_types(id)`): Tipo de teléfono.
- `is_primary` (BOOLEAN): Indica si es el teléfono principal.
- `created_at` (TIMESTAMP, Default: NOW())
- `created_by` (UUID, Foreign Key → `auth.users(id)`)
- `updated_at` (TIMESTAMP)
- `updated_by` (UUID, Foreign Key → `auth.users(id)`)
- `is_deleted` (BOOLEAN, Default: FALSE)

---

## **Tabla: `user_emails`**

Almacena los correos electrónicos adicionales asociados a los usuarios.

**Campos:**

- `id` (UUID, Primary Key): Identificador único del correo electrónico.
- `user_id` (UUID, Foreign Key → `users(id)`): Referencia al usuario asociado.
- `email` (VARCHAR(100)): Dirección de correo electrónico.
- `email_type_id` (INTEGER, Foreign Key → `email_types(id)`): Tipo de correo electrónico.
- `is_primary` (BOOLEAN): Indica si es el correo electrónico principal (diferente al de `auth.users`).
- `created_at` (TIMESTAMP, Default: NOW())
- `created_by` (UUID, Foreign Key → `auth.users(id)`)
- `updated_at` (TIMESTAMP)
- `updated_by` (UUID, Foreign Key → `auth.users(id)`)
- `is_deleted` (BOOLEAN, Default: FALSE)

---

## **Tabla: `user_sessions`**

Registra las sesiones de los usuarios en el sistema.

**Campos:**

- `session_id` (UUID, Primary Key): Identificador único de la sesión.
- `user_id` (UUID, Foreign Key → `users(id)`): Referencia al usuario.
- `login_time` (TIMESTAMP, Default: NOW()): Fecha y hora de inicio de sesión.
- `logout_time` (TIMESTAMP): Fecha y hora de cierre de sesión.
- `ip_address` (VARCHAR(45)): Dirección IP desde donde se inició la sesión.
- `device_info` (VARCHAR(200)): Información del dispositivo utilizado.
- `created_at` (TIMESTAMP, Default: NOW())
- `updated_at` (TIMESTAMP)

---

## **Tabla: `phone_types`**

Almacena los tipos de teléfonos disponibles.

**Campos:**

- `id` (SERIAL, Primary Key): Identificador único del tipo de teléfono.
- `type` (VARCHAR(50), UNIQUE, NOT NULL): Tipo de teléfono (Móvil, Casa, Trabajo, etc.).
- `description` (TEXT): Descripción opcional.

---

## **Tabla: `email_types`**

Almacena los tipos de correos electrónicos disponibles.

**Campos:**

- `id` (SERIAL, Primary Key): Identificador único del tipo de correo electrónico.
- `type` (VARCHAR(50), UNIQUE, NOT NULL): Tipo de correo electrónico (Personal, Trabajo, etc.).
- `description` (TEXT): Descripción opcional.

---

# Resto del Diseño de la Base de Datos

A continuación, se presentan las demás tablas de la base de datos, actualizadas para reflejar las nuevas relaciones y campos.

---

## **Tabla: `terminals`**

Almacena información sobre las terminales, que son las empresas o personas que son clientes del sistema.

**Campos:**

- `id` (UUID, Primary Key): Identificador único de la terminal.
- `name` (VARCHAR(100)): Nombre de la terminal.
- `address` (VARCHAR(200)): Dirección física de la terminal.
- `phone` (VARCHAR(20)): Número de teléfono de contacto.
- `email` (VARCHAR(100)): Correo electrónico de contacto.
- `created_at` (TIMESTAMP, Default: NOW()): Fecha y hora de registro.
- `created_by` (UUID, Foreign Key → `auth.users(id)`): Usuario que creó el registro.
- `updated_at` (TIMESTAMP): Fecha y hora de última actualización.
- `updated_by` (UUID, Foreign Key → `auth.users(id)`): Usuario que actualizó el registro.
- `is_deleted` (BOOLEAN, Default: FALSE): Indicador de eliminación lógica.

---

## **Tabla: `marital_statuses`**

Almacena los diferentes estados civiles posibles.

**Campos:**

- `id` (SERIAL, Primary Key): Identificador único del estado civil.
- `status` (VARCHAR(50), UNIQUE, NOT NULL): Nombre del estado civil.
- `description` (TEXT): Descripción opcional.

---

## **Tabla: `education_levels`**

Almacena los diferentes niveles educativos.

**Campos:**

- `id` (SERIAL, Primary Key): Identificador único del nivel educativo.
- `level` (VARCHAR(50), UNIQUE, NOT NULL): Nombre del nivel educativo.
- `description` (TEXT): Descripción opcional.

---

## **Tabla: `occupations`**

Almacena las ocupaciones o profesiones.

**Campos:**

- `id` (SERIAL, Primary Key): Identificador único de la ocupación.
- `occupation` (VARCHAR(100), UNIQUE, NOT NULL): Nombre de la ocupación.
- `description` (TEXT): Descripción opcional.

## **Tabla: `countries`**

Almacena información sobre los países.

**Campos:**

- `id` (SERIAL, Primary Key): Identificador único del país.
- `name` (VARCHAR(100), UNIQUE, NOT NULL): Nombre del país.
- `code` (VARCHAR(10), UNIQUE): Código del país (por ejemplo, ISO 3166-1 alpha-2).
- `created_at` (TIMESTAMPTZ, DEFAULT timezone('utc', now())): Fecha y hora de creación del registro.
- `updated_at` (TIMESTAMPTZ): Fecha y hora de última actualización del registro.

**Descripción de la tabla y campos:**

- **Tabla `countries`**: Almacena información sobre los países.
- **Campo `id`**: Identificador único del país.
- **Campo `name`**: Nombre del país.
- **Campo `code`**: Código del país (por ejemplo, ISO 3166-1 alpha-2).
- **Campo `created_at`**: Fecha y hora de creación del registro en UTC.
- **Campo `updated_at`**: Fecha y hora de última actualización del registro en UTC.

---

## **Tabla: `provinces`**

Almacena las provincias o estados asociados a cada país.

**Campos:**

- `id` (SERIAL, Primary Key): Identificador único de la provincia o estado.
- `name` (VARCHAR(100), NOT NULL): Nombre de la provincia o estado.
- `country_id` (INTEGER, Foreign Key → `countries(id)`, NOT NULL): Referencia al país al que pertenece.
- `created_at` (TIMESTAMPTZ, DEFAULT timezone('utc', now())): Fecha y hora de creación del registro.
- `updated_at` (TIMESTAMPTZ): Fecha y hora de última actualización del registro.

**Índices y Restricciones:**

- **UNIQUE(name, country_id)**: Asegura que no existan dos provincias con el mismo nombre dentro del mismo país.

**Descripción de la tabla y campos:**

- **Tabla `provinces`**: Almacena las provincias o estados asociados a cada país.
- **Campo `id`**: Identificador único de la provincia o estado.
- **Campo `name`**: Nombre de la provincia o estado.
- **Campo `country_id`**: Referencia al país al que pertenece la provincia o estado.
- **Campo `created_at`**: Fecha y hora de creación del registro en UTC.
- **Campo `updated_at`**: Fecha y hora de última actualización del registro en UTC.

---

## **Tabla: `cities`**

Almacena las ciudades asociadas a cada provincia o estado.

**Campos:**

- `id` (SERIAL, Primary Key): Identificador único de la ciudad.
- `name` (VARCHAR(100), NOT NULL): Nombre de la ciudad.
- `province_id` (INTEGER, Foreign Key → `provinces(id)`, NOT NULL): Referencia a la provincia o estado al que pertenece.
- `created_at` (TIMESTAMPTZ, DEFAULT timezone('utc', now())): Fecha y hora de creación del registro.
- `updated_at` (TIMESTAMPTZ): Fecha y hora de última actualización del registro.

**Índices y Restricciones:**

- **UNIQUE(name, province_id)**: Asegura que no existan dos ciudades con el mismo nombre dentro de la misma provincia.

**Descripción de la tabla y campos:**

- **Tabla `cities`**: Almacena las ciudades asociadas a cada provincia o estado.
- **Campo `id`**: Identificador único de la ciudad.
- **Campo `name`**: Nombre de la ciudad.
- **Campo `province_id`**: Referencia a la provincia o estado al que pertenece la ciudad.
- **Campo `created_at`**: Fecha y hora de creación del registro en UTC.
- **Campo `updated_at`**: Fecha y hora de última actualización del registro en UTC.

---

## **Tabla: `nationalities`**

Almacena las nacionalidades reconocidas, vinculadas a un país específico.

**Campos:**

- `id` (SERIAL, Primary Key): Identificador único de la nacionalidad.
- `nationality` (VARCHAR(100), UNIQUE, NOT NULL): Nombre de la nacionalidad.
- `country_id` (INTEGER, Foreign Key → `countries(id)`): Referencia al país asociado.
- `created_at` (TIMESTAMPTZ, DEFAULT timezone('utc', now())): Fecha y hora de creación del registro.
- `updated_at` (TIMESTAMPTZ): Fecha y hora de última actualización del registro.

**Descripción de la tabla y campos:**

- **Tabla `nationalities`**: Almacena las nacionalidades reconocidas, vinculadas a un país específico.
- **Campo `id`**: Identificador único de la nacionalidad.
- **Campo `nationality`**: Nombre de la nacionalidad.
- **Campo `country_id`**: Referencia al país asociado a la nacionalidad.
- **Campo `created_at`**: Fecha y hora de creación del registro en UTC.
- **Campo `updated_at`**: Fecha y hora de última actualización del registro en UTC.

---

## **Tabla: `genders`**

Almacena los géneros disponibles.

**Campos:**

- `id` (SERIAL, Primary Key): Identificador único del género.
- `gender` (VARCHAR(50), UNIQUE, NOT NULL): Nombre del género.
- `description` (TEXT): Descripción opcional.

---

## **Tabla: `patients`**

Contiene la información básica de cada paciente registrado por los usuarios.

**Campos:**

- `id` (UUID, Primary Key): Identificador único del paciente.
- `registered_by` (UUID, Foreign Key → `users(id)`): Usuario que registró al paciente.
- `first_name` (VARCHAR(100)): Nombre de pila del paciente.
- `last_name` (VARCHAR(100)): Apellido(s) del paciente.
- `id_number` (VARCHAR(20), UNIQUE): Número de identificación oficial del paciente.
- `date_of_birth` (DATE): Fecha de nacimiento del paciente.
- `gender_id` (INTEGER, Foreign Key → `genders(id)`): Género del paciente.
- `marital_status_id` (INTEGER, Foreign Key → `marital_statuses(id)`): Estado civil del paciente.
- `education_level_id` (INTEGER, Foreign Key → `education_levels(id)`): Nivel educativo del paciente.
- `nationality_id` (INTEGER, Foreign Key → `nationalities(id)`): Nacionalidad del paciente.
- `health_insurance_id` (INTEGER, Foreign Key → `health_insurances(id)`): Seguro de salud del paciente.
- `created_at` (TIMESTAMP, Default: NOW()): Fecha y hora de registro.
- `created_by` (UUID, Foreign Key → `users(id)`): Identificador del usuario que creó el registro.
- `updated_at` (TIMESTAMP): Fecha y hora de la última actualización.
- `updated_by` (UUID, Foreign Key → `users(id)`): Identificador del usuario que realizó la última actualización.
- `is_deleted` (BOOLEAN, Default: FALSE): Indicador de eliminación lógica.

---

## **Tabla: `patient_phones`**

Almacena los números de teléfono asociados a los pacientes.

**Campos:**

- `id` (UUID, Primary Key): Identificador único del teléfono.
- `patient_id` (UUID, Foreign Key → `patients(id)`): Referencia al paciente asociado.
- `phone_number` (VARCHAR(20)): Número de teléfono.
- `phone_type_id` (INTEGER, Foreign Key → `phone_types(id)`): Tipo de teléfono.
- `is_primary` (BOOLEAN): Indica si es el teléfono principal.
- `created_at` (TIMESTAMP, Default: NOW())
- `created_by` (UUID, Foreign Key → `users(id)`)
- `updated_at` (TIMESTAMP)
- `updated_by` (UUID, Foreign Key → `users(id)`)
- `is_deleted` (BOOLEAN, Default: FALSE)

---

## **Tabla: `patient_emails`**

Almacena los correos electrónicos asociados a los pacientes.

**Campos:**

- `id` (UUID, Primary Key): Identificador único del correo electrónico.
- `patient_id` (UUID, Foreign Key → `patients(id)`): Referencia al paciente asociado.
- `email` (VARCHAR(100)): Dirección de correo electrónico.
- `email_type_id` (INTEGER, Foreign Key → `email_types(id)`): Tipo de correo electrónico.
- `is_primary` (BOOLEAN): Indica si es el correo electrónico principal.
- `created_at` (TIMESTAMP, Default: NOW())
- `created_by` (UUID, Foreign Key → `users(id)`)
- `updated_at` (TIMESTAMP)
- `updated_by` (UUID, Foreign Key → `users(id)`)
- `is_deleted` (BOOLEAN, Default: FALSE)

---

## **Tabla: `patient_addresses`**

Almacena las direcciones asociadas a los pacientes.

**Campos:**

- `id` (UUID, Primary Key): Identificador único de la dirección.
- `patient_id` (UUID, Foreign Key → `patients(id)`): Referencia al paciente asociado.
- `address_type_id` (INTEGER, Foreign Key → `address_types(id)`): Tipo de dirección.
- `province_city_id` (INTEGER, Foreign Key → `provinces_cities(id)`): Provincia o ciudad.
- `neighborhood_id` (INTEGER, Foreign Key → `neighborhoods(id)`): Vecindario.
- `street_address` (VARCHAR(200)): Dirección detallada.
- `postal_code` (VARCHAR(20)): Código postal.
- `is_primary` (BOOLEAN): Indica si es la dirección principal.
- `created_at` (TIMESTAMP, Default: NOW())
- `created_by` (UUID, Foreign Key → `users(id)`)
- `updated_at` (TIMESTAMP)
- `updated_by` (UUID, Foreign Key → `users(id)`)
- `is_deleted` (BOOLEAN, Default: FALSE)

---

## **Tabla: `address_types`**

Almacena los tipos de direcciones disponibles.

**Campos:**

- `id` (SERIAL, Primary Key): Identificador único del tipo de dirección.
- `type` (VARCHAR(50), UNIQUE, NOT NULL): Tipo de dirección (Residencial, Laboral, etc.).
- `description` (TEXT): Descripción opcional.

---

## **Tabla: `patient_emergency_contacts`**

Almacena los contactos de emergencia asociados a los pacientes.

**Campos:**

- `id` (UUID, Primary Key): Identificador único del contacto de emergencia.
- `patient_id` (UUID, Foreign Key → `patients(id)`): Referencia al paciente asociado.
- `contact_name` (VARCHAR(100)): Nombre del contacto de emergencia.
- `contact_phone` (VARCHAR(20)): Teléfono del contacto de emergencia.
- `relationship_id` (INTEGER, Foreign Key → `relationships(id)`): Relación con el paciente.
- `priority` (INTEGER): Orden o prioridad del contacto.
- `created_at` (TIMESTAMP, Default: NOW())
- `created_by` (UUID, Foreign Key → `users(id)`)
- `updated_at` (TIMESTAMP)
- `updated_by` (UUID, Foreign Key → `users(id)`)
- `is_deleted` (BOOLEAN, Default: FALSE)

---

## **Tabla: `relationships`**

Almacena los tipos de relaciones entre personas.

**Campos:**

- `id` (SERIAL, Primary Key): Identificador único de la relación.
- `relationship` (VARCHAR(50), UNIQUE, NOT NULL): Tipo de relación.
- `description` (TEXT): Descripción opcional.

---

## **Tabla: `health_insurances`**

Almacena los nombres de los seguros de salud disponibles.

**Campos:**

- `id` (SERIAL, Primary Key): Identificador único del seguro de salud.
- `name` (VARCHAR(100), UNIQUE, NOT NULL): Nombre del seguro de salud.
- `description` (TEXT): Descripción opcional.

---

## **Tabla: `family_members`**

Almacena información de los miembros de la familia del paciente.

**Campos:**

- `id` (UUID, Primary Key): Identificador único del miembro de la familia.
- `patient_id` (UUID, Foreign Key → `patients(id)`): Referencia al paciente asociado.
- `relationship_id` (INTEGER, Foreign Key → `family_relationships(id)`): Tipo de relación familiar.
- `first_name` (VARCHAR(100)): Nombre del familiar.
- `last_name` (VARCHAR(100)): Apellido(s) del familiar.
- `alive` (BOOLEAN): Indica si el familiar está vivo.
- `contact` (VARCHAR(20)): Información de contacto.
- `occupation_id` (INTEGER, Foreign Key → `occupations(id)`): Ocupación del familiar.
- `education_level_id` (INTEGER, Foreign Key → `education_levels(id)`): Nivel educativo del familiar.
- `job_status_id` (INTEGER, Foreign Key → `job_statuses(id)`): Situación laboral del familiar.
- `characteristics` (TEXT): Características o notas adicionales.
- `created_at` (TIMESTAMP, Default: NOW())
- `created_by` (UUID, Foreign Key → `users(id)`)
- `updated_at` (TIMESTAMP)
- `updated_by` (UUID, Foreign Key → `users(id)`)
- `is_deleted` (BOOLEAN, Default: FALSE)

---

## **Tabla: `family_relationships`**

Almacena los tipos de relaciones familiares.

**Campos:**

- `id` (SERIAL, Primary Key): Identificador único de la relación familiar.
- `relationship` (VARCHAR(50), UNIQUE, NOT NULL): Tipo de relación.
- `description` (TEXT): Descripción opcional.

---

## **Tabla: `siblings`**

Almacena información específica de los hermanos del paciente.

**Campos:**

- `id` (UUID, Primary Key): Identificador único del hermano.
- `family_member_id` (UUID, Foreign Key → `family_members(id)`): Referencia al miembro de la familia que es hermano.
- `sibling_position` (INTEGER): Posición entre los hermanos.
- `alive` (BOOLEAN): Indica si el hermano está vivo.
- `contact` (VARCHAR(20)): Información de contacto.
- `occupation_id` (INTEGER, Foreign Key → `occupations(id)`): Ocupación del hermano.
- `education_level_id` (INTEGER, Foreign Key → `education_levels(id)`): Nivel educativo del hermano.
- `job_status_id` (INTEGER, Foreign Key → `job_statuses(id)`): Situación laboral del hermano.
- `characteristics` (TEXT): Características o notas adicionales.
- `created_at` (TIMESTAMP, Default: NOW())
- `created_by` (UUID, Foreign Key → `users(id)`)
- `updated_at` (TIMESTAMP)
- `updated_by` (UUID, Foreign Key → `users(id)`)
- `is_deleted` (BOOLEAN, Default: FALSE)

---

## **Tabla: `job_statuses`**

Almacena los diferentes estados laborales posibles.

**Campos:**

- `id` (SERIAL, Primary Key): Identificador único del estado laboral.
- `status` (VARCHAR(50), UNIQUE, NOT NULL): Nombre del estado laboral.
- `description` (TEXT): Descripción opcional.

---

## **Tabla: `parenting_styles`**

Almacena los estilos de crianza percibidos o aplicados.

**Campos:**

- `id` (SERIAL, Primary Key): Identificador único del estilo de crianza.
- `style` (VARCHAR(50), UNIQUE, NOT NULL): Nombre del estilo.
- `description` (TEXT): Descripción del estilo de crianza.

---

## **Tabla: `patient_upbringing_styles`**

Asocia al paciente con los estilos de crianza que fueron aplicados a él durante su infancia.

**Campos:**

- `id` (UUID, Primary Key): Identificador único del registro.
- `patient_id` (UUID, Foreign Key → `patients(id)`): Referencia al paciente.
- `parenting_style_id` (INTEGER, Foreign Key → `parenting_styles(id)`): Estilo de crianza.
- `description` (TEXT): Notas adicionales.
- `created_at` (TIMESTAMP, Default: NOW())
- `created_by` (UUID, Foreign Key → `users(id)`)
- `updated_at` (TIMESTAMP)
- `updated_by` (UUID, Foreign Key → `users(id)`)
- `is_deleted` (BOOLEAN, Default: FALSE)

---

## **Tabla: `patient_parenting_styles`**

Asocia al paciente con los estilos de crianza que aplica a sus propios hijos.

**Campos:**

- `id` (UUID, Primary Key): Identificador único del registro.
- `patient_id` (UUID, Foreign Key → `patients(id)`): Referencia al paciente.
- `parenting_style_id` (INTEGER, Foreign Key → `parenting_styles(id)`): Estilo de crianza.
- `description` (TEXT): Notas adicionales.
- `created_at` (TIMESTAMP, Default: NOW())
- `created_by` (UUID, Foreign Key → `users(id)`)
- `updated_at` (TIMESTAMP)
- `updated_by` (UUID, Foreign Key → `users(id)`)
- `is_deleted` (BOOLEAN, Default: FALSE)

---

## **Tabla: `attachment_types`**

Almacena los tipos de apego.

**Campos:**

- `id` (SERIAL, Primary Key): Identificador único del tipo de apego.
- `type` (VARCHAR(50), UNIQUE, NOT NULL): Nombre del tipo de apego.
- `description` (TEXT): Descripción del tipo de apego.

---

## **Tabla: `patient_attachments`**

Asocia al paciente con los tipos de apego identificados.

**Campos:**

- `id` (UUID, Primary Key): Identificador único del registro.
- `patient_id` (UUID, Foreign Key → `patients(id)`): Referencia al paciente.
- `attachment_type_id` (INTEGER, Foreign Key → `attachment_types(id)`): Tipo de apego.
- `description` (TEXT): Notas adicionales.
- `created_at` (TIMESTAMP, Default: NOW())
- `created_by` (UUID, Foreign Key → `users(id)`)
- `updated_at` (TIMESTAMP)
- `updated_by` (UUID, Foreign Key → `users(id)`)
- `is_deleted` (BOOLEAN, Default: FALSE)

---

## **Tabla: `family_communications`**

Almacena información sobre la comunicación familiar del paciente.

**Campos:**

- `id` (UUID, Primary Key): Identificador único del registro.
- `patient_id` (UUID, Foreign Key → `patients(id)`): Referencia al paciente.
- `communication_quality` (VARCHAR(50)): Calidad de la comunicación.
- `description` (TEXT): Descripción detallada.
- `created_at` (TIMESTAMP, Default: NOW())
- `created_by` (UUID, Foreign Key → `users(id)`)
- `updated_at` (TIMESTAMP)
- `updated_by` (UUID, Foreign Key → `users(id)`)

---

## **Tabla: `family_limits`**

Almacena información sobre los límites establecidos en la familia del paciente.

**Campos:**

- `id` (UUID, Primary Key): Identificador único del registro.
- `patient_id` (UUID, Foreign Key → `patients(id)`): Referencia al paciente.
- `limits_quality` (VARCHAR(50)): Calidad de los límites.
- `description` (TEXT): Descripción detallada.
- `created_at` (TIMESTAMP, Default: NOW())
- `created_by` (UUID, Foreign Key → `users(id)`)
- `updated_at` (TIMESTAMP)
- `updated_by` (UUID, Foreign Key → `users(id)`)

---

## **Tabla: `current_family_relationships`**

Almacena información sobre las relaciones familiares actuales del paciente.

**Campos:**

- `id` (UUID, Primary Key): Identificador único del registro.
- `patient_id` (UUID, Foreign Key → `patients(id)`): Referencia al paciente.
- `relationship_quality` (VARCHAR(50)): Calidad de las relaciones.
- `description` (TEXT): Descripción detallada.
- `created_at` (TIMESTAMP, Default: NOW())
- `created_by` (UUID, Foreign Key → `users(id)`)

---

## **Tabla: `conflict_types`**

Almacena los diferentes tipos de conflictos familiares.

**Campos:**

- `id` (SERIAL, Primary Key): Identificador único del tipo de conflicto.
- `type` (VARCHAR(100), UNIQUE, NOT NULL): Nombre del tipo de conflicto.
- `description` (TEXT): Descripción detallada.

---

## **Tabla: `family_conflicts`**

Almacena información detallada sobre los conflictos familiares del paciente.

**Campos:**

- `id` (UUID, Primary Key): Identificador único del conflicto.
- `patient_id` (UUID, Foreign Key → `patients(id)`): Referencia al paciente.
- `conflict_type_id` (INTEGER, Foreign Key → `conflict_types(id)`): Tipo de conflicto.
- `family_member_id` (UUID, Foreign Key → `family_members(id)`): Miembro de la familia involucrado.
- `description` (TEXT): Detalles específicos del conflicto.
- `resolved` (BOOLEAN, Default: FALSE): Indica si el conflicto ha sido resuelto.
- `created_at` (TIMESTAMP, Default: NOW())
- `created_by` (UUID, Foreign Key → `users(id)`)
- `updated_at` (TIMESTAMP)
- `updated_by` (UUID, Foreign Key → `users(id)`)
- `is_deleted` (BOOLEAN, Default: FALSE)

---

## **Tabla: `patient_work_details`**

Almacena información detallada sobre el trabajo del paciente.

**Campos:**

- `id` (UUID, Primary Key)
- `patient_id` (UUID, Foreign Key → `patients(id)`)
- `job_status_id` (INTEGER, Foreign Key → `job_statuses(id)`)
- `occupation_id` (INTEGER, Foreign Key → `occupations(id)`)
- `work_insertion` (TEXT)
- `adaptation_discipline` (TEXT)
- `job_change_unemployment` (TEXT)
- `job_satisfaction` (TEXT)
- `successes_failures` (TEXT)
- `work_conflicts` (TEXT)
- `created_at` (TIMESTAMP, Default: NOW())
- `created_by` (UUID, Foreign Key → `users(id)`)
- `updated_at` (TIMESTAMP)
- `updated_by` (UUID, Foreign Key → `users(id)`)
- `is_deleted` (BOOLEAN, Default: FALSE)

---

## **Tabla: `clinical_history`**

Almacena el historial clínico general del paciente.

**Campos:**

- `id` (UUID, Primary Key)
- `patient_id` (UUID, Foreign Key → `patients(id)`)
- `consultation_reason` (TEXT)
- `consultation_history` (TEXT)
- `mental_exam` (TEXT)
- `personal_medical_history` (TEXT)
- `family_medical_history` (TEXT)
- `created_at` (TIMESTAMP, Default: NOW())
- `created_by` (UUID, Foreign Key → `users(id)`)
- `updated_at` (TIMESTAMP)
- `updated_by` (UUID, Foreign Key → `users(id)`)
- `is_deleted` (BOOLEAN, Default: FALSE)

---

## **Tabla: `love_area`**

Contiene información del área amorosa y sexual del paciente.

**Campos:**

- `id` (UUID, Primary Key)
- `patient_id` (UUID, Foreign Key → `patients(id)`)
- `sexual_activity_onset` (DATE)
- `romantic_relationships_duration` (TEXT)
- `couple_conflicts` (TEXT)
- `gender_violence` (BOOLEAN)
- `sexual_dysfunctions` (TEXT)
- `created_at` (TIMESTAMP, Default: NOW())
- `created_by` (UUID, Foreign Key → `users(id)`)
- `updated_at` (TIMESTAMP)
- `updated_by` (UUID, Foreign Key → `users(id)`)
- `is_deleted` (BOOLEAN, Default: FALSE)

---

## **Tabla: `personal_social_area`**

Almacena información sobre el área personal y social del paciente.

**Campos:**

- `id` (UUID, Primary Key)
- `patient_id` (UUID, Foreign Key → `patients(id)`)
- `self_concept` (TEXT)
- `self_esteem` (TEXT)
- `personality_traits` (TEXT)
- `emotional_state` (TEXT)
- `needs_interests` (TEXT)
- `hygiene_habits` (TEXT)
- `nutrition` (TEXT)
- `sleep` (TEXT)
- `sociability` (TEXT)
- `projects_aspirations` (TEXT)
- `created_at` (TIMESTAMP, Default: NOW())
- `created_by` (UUID, Foreign Key → `users(id)`)
- `updated_at` (TIMESTAMP)
- `updated_by` (UUID, Foreign Key → `users(id)`)
- `is_deleted` (BOOLEAN, Default: FALSE)

---

## **Tabla: `evaluations`**

Contiene información sobre las evaluaciones realizadas al paciente.

**Campos:**

- `id` (UUID, Primary Key)
- `patient_id` (UUID, Foreign Key → `patients(id)`)
- `tests_used` (TEXT)
- `results` (TEXT)
- `evaluation_date` (TIMESTAMP)
- `created_at` (TIMESTAMP, Default: NOW())
- `created_by` (UUID, Foreign Key → `users(id)`)
- `updated_at` (TIMESTAMP)
- `updated_by` (UUID, Foreign Key → `users(id)`)
- `is_deleted` (BOOLEAN, Default: FALSE)

---

## **Tabla: `diagnoses`**

Almacena los diagnósticos asignados al paciente.

**Campos:**

- `id` (UUID, Primary Key)
- `patient_id` (UUID, Foreign Key → `patients(id)`)
- `classification_system` (VARCHAR(50))
- `diagnosis_code` (VARCHAR(20))
- `description` (TEXT)
- `diagnosis_date` (TIMESTAMP)
- `created_at` (TIMESTAMP, Default: NOW())
- `created_by` (UUID, Foreign Key → `users(id)`)
- `updated_at` (TIMESTAMP)
- `updated_by` (UUID, Foreign Key → `users(id)`)
- `is_deleted` (BOOLEAN, Default: FALSE)

---

## **Tabla: `treatments`**

Contiene información sobre el tratamiento y seguimiento del paciente.

**Campos:**

- `id` (UUID, Primary Key)
- `patient_id` (UUID, Foreign Key → `patients(id)`)
- `intervention_approach` (TEXT)
- `session_summaries` (TEXT)
- `therapeutic_plan` (TEXT)
- `start_date` (TIMESTAMP)
- `end_date` (TIMESTAMP)
- `created_at` (TIMESTAMP, Default: NOW())
- `created_by` (UUID, Foreign Key → `users(id)`)
- `updated_at` (TIMESTAMP)
- `updated_by` (UUID, Foreign Key → `users(id)`)
- `is_deleted` (BOOLEAN, Default: FALSE)

---

## **Tabla: `therapy_sessions`**

Detalle de cada sesión terapéutica realizada.

**Campos:**

- `id` (UUID, Primary Key)
- `treatment_id` (UUID, Foreign Key → `treatments(id)`)
- `session_date` (TIMESTAMP)
- `session_summary` (TEXT)
- `observations` (TEXT)
- `created_at` (TIMESTAMP, Default: NOW())
- `created_by` (UUID, Foreign Key → `users(id)`)
- `updated_at` (TIMESTAMP)
- `updated_by` (UUID, Foreign Key → `users(id)`)
- `is_deleted` (BOOLEAN, Default: FALSE)

---

## **Tabla: `initial_evaluations`**

Almacena las evaluaciones iniciales autoadministradas por los pacientes.

**Campos:**

- `id` (UUID, Primary Key)
- `patient_id` (UUID, Foreign Key → `patients(id)`)
- `responses` (JSONB)
- `completion_date` (TIMESTAMP)
- `created_at` (TIMESTAMP, Default: NOW())
- `created_by` (UUID, Foreign Key → `users(id)`)
- `updated_at` (TIMESTAMP)
- `updated_by` (UUID, Foreign Key → `users(id)`)
- `is_deleted` (BOOLEAN, Default: FALSE)

---

## **Tabla: `audit_logs`**

Registra todas las operaciones realizadas en las tablas auditadas.

**Campos:**

- `audit_id` (SERIAL, Primary Key)
- `operation` (VARCHAR(10))
- `table_name` (VARCHAR(50))
- `record_id` (UUID)
- `changed_data` (JSONB)
- `changed_by` (UUID, Foreign Key → `users(id)`)
- `changed_at` (TIMESTAMP)

---

## **Tablas de Historial por Entidad**

Se crearán tablas de historial similares para las entidades que requieran auditoría detallada, como `patients_history`, `treatments_history`, etc.

---

# Conclusión

El diseño actualizado de la base de datos incorpora:

- La nueva tabla `user_sessions` para rastrear las sesiones de usuario.
- La adaptación de la tabla `users` para integrarse con `auth.users` de Supabase, eliminando el campo `email`.
- La separación del campo `phone` de la tabla `users` en una nueva tabla `user_phones`, similar a `patient_phones`.
- La adición de la tabla `user_emails` para manejar correos electrónicos adicionales si es necesario.

Este diseño permite una mejor integración con Supabase, aprovechando su sistema de autenticación y garantizando una estructura más normalizada y flexible para manejar información adicional de los usuarios.

---

**Nota sobre la Integración con Supabase**

- **Autenticación y Correos Electrónicos:** Como `auth.users` maneja la autenticación y el correo electrónico principal, no es necesario duplicar el campo `email` en la tabla `users`. Si necesitas almacenar correos electrónicos adicionales, la tabla `user_emails` te permite hacerlo.
- **Teléfonos de Usuario:** Al mover los números de teléfono a la tabla `user_phones`, puedes manejar múltiples números por usuario y clasificarlos según su tipo.

---

**Configuraciones Adicionales**

- **Claves Foráneas y Restricciones:** Asegúrate de establecer las claves foráneas y restricciones adecuadas para mantener la integridad referencial.
- **Políticas de Seguridad (RLS):** Configura las políticas de seguridad necesarias para proteger los datos y cumplir con las regulaciones aplicables.

---
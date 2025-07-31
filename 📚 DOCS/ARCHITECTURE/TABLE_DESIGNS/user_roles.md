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
-- #############################################################################
-- #                                                                           #
-- #          DOCUMENTACIÓN DEL ESQUEMA DE LA BASE DE DATOS 'app'              #
-- #                                                                           #
-- #############################################################################
-- #############################################################################
-- # ÍNDICE DE TABLAS                                                          #
-- #############################################################################
--
-- 1. Tabla: app.administrative_units
-- 2. Tabla: app.audit_log_entries
-- 3. Tabla: app.catalog_item_translations
-- 4. Tabla: app.catalog_items
-- 5. Tabla: app.catalog_types
-- 6. Tabla: app.clinical_histories
-- 7. Tabla: app.countries
-- 8. Tabla: app.country_translations
-- 9. Tabla: app.current_family_relationships
-- 10. Tabla: app.diagnoses
-- 11. Tabla: app.evaluations
-- 12. Tabla: app.family_communications
-- 13. Tabla: app.family_conflicts
-- 14. Tabla: app.family_limits
-- 15. Tabla: app.family_members
-- 16. Tabla: app.initial_evaluations
-- 17. Tabla: app.languages
-- 18. Tabla: app.love_areas
-- 19. Tabla: app.patient_addresses
-- 20. Tabla: app.patient_emails
-- 21. Tabla: app.patient_emergency_contacts
-- 22. Tabla: app.patient_parenting_profiles
-- 23. Tabla: app.patient_phones
-- 24. Tabla: app.patient_provided_parenting
-- 25. Tabla: app.patient_received_upbringing
-- 26. Tabla: app.patient_referrals
-- 27. Tabla: app.patient_work_details
-- 28. Tabla: app.patients
-- 29. Tabla: app.payments
-- 30. Tabla: app.personal_social_areas
-- 31. Tabla: app.professional_profiles
-- 32. Tabla: app.professional_specializations
-- 33. Tabla: app.subscription_plans
-- 34. Tabla: app.terminal_emails
-- 35. Tabla: app.terminal_phones
-- 36. Tabla: app.terminals
-- 37. Tabla: app.therapy_sessions
-- 38. Tabla: app.treatments
-- 39. Tabla: app.user_emails
-- 40. Tabla: app.user_phones
-- 41. Tabla: app.user_sessions
-- 42. Tabla: app.user_terminal_roles
-- 43. Tabla: app.users
-- 44. Tabla: util.catalog_fk_map
--
-- #############################################################################

-- 1. Tabla: app.administrative_units
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS "app"."administrative_units" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "name" character varying(100) NOT NULL,
    "country_id" "uuid" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()),
    "updated_at" timestamp with time zone,
    "is_deleted" boolean DEFAULT false NOT NULL,
    "deleted_at" timestamp with time zone,
    "path" "public"."ltree" NOT NULL,
    "unit_type" "text" NOT NULL,
    "iso_code" "text",
    "created_by" "uuid",
    "updated_by" "uuid",
    CONSTRAINT "chk_unit_type" CHECK (("unit_type" = ANY ('{COUNTRY,PROVINCE,MUNICIPALITY,MUNICIPAL_DISTRICT,SECTION,NEIGHBORHOOD}'::"text"[])))
);
COMMENT ON COLUMN "app"."administrative_units"."created_by" IS 'Usuario que creó la unidad administrativa.';
COMMENT ON COLUMN "app"."administrative_units"."updated_by" IS 'Usuario que actualizó por última vez la unidad administrativa.';

-- Claves Primarias y Foráneas (Relaciones)
-- Primary Key (PK):
-- • id
-- Foreign Keys (FK):
-- • La columna "country_id" es una clave foránea que se relaciona con la clave primaria "id" de la tabla "app.countries".
-- • La columna "created_by" es una clave foránea que se relaciona con la clave primaria "id" de la tabla "auth.users".
-- • La columna "updated_by" es una clave foránea que se relaciona con la clave primaria "id" de la tabla "auth.users".

-- Triggers:
CREATE OR REPLACE TRIGGER "soft_del_administrative_units" BEFORE DELETE ON "app"."administrative_units" FOR EACH ROW EXECUTE FUNCTION "util"."soft_delete_generic"('id');
CREATE OR REPLACE TRIGGER "trg_audit_administrative_units" AFTER INSERT OR DELETE OR UPDATE ON "app"."administrative_units" FOR EACH ROW EXECUTE FUNCTION "app"."capture_audit_event"('id', 'false');
CREATE OR REPLACE TRIGGER "trg_manage_audit_columns_administrative_units" BEFORE INSERT OR UPDATE ON "app"."administrative_units" FOR EACH ROW EXECUTE FUNCTION "util"."handle_audit_columns_trigger_func"();
CREATE OR REPLACE TRIGGER "trg_normalize_admin_unit_name" BEFORE INSERT OR UPDATE ON "app"."administrative_units" FOR EACH ROW EXECUTE FUNCTION "util"."normalize_admin_unit_name"();

-- Índices:
CREATE UNIQUE INDEX "administrative_units_path_unique_idx" ON "app"."administrative_units" USING "btree" ("path");
CREATE INDEX "idx_admin_units_lower_name" ON "app"."administrative_units" USING "btree" ("lower"(("name")::"text"));
CREATE INDEX "idx_admin_units_path_gist" ON "app"."administrative_units" USING "gist" ("path");


-- 2. Tabla: app.audit_log_entries
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS "app"."audit_log_entries" (
    "audit_id" bigint NOT NULL,
    "transaction_id" bigint,
    "operation" "public"."audit_operation_enum" NOT NULL,
    "schema_name" "text" NOT NULL,
    "table_name" "text" NOT NULL,
    "record_id" "uuid" NOT NULL,
    "old_data" "jsonb",
    "new_data" "jsonb",
    "changed_by_user_id" "uuid",
    "changed_at" timestamp with time zone DEFAULT "clock_timestamp"() NOT NULL,
    "app_context" "jsonb",
    "statement_only" boolean DEFAULT false NOT NULL,
    "pk_column_name" "text"
)
PARTITION BY RANGE ("changed_at");
COMMENT ON TABLE "app"."audit_log_entries" IS 'Tabla particionada para almacenar logs de auditoría detallados, soportando capacidad de reversión y granularidad de desarrollador.';
COMMENT ON COLUMN "app"."audit_log_entries"."changed_by_user_id" IS 'UUID del usuario (auth.users) que realizó el cambio. NULL si no se pudo determinar vía JWT, created/updated_by o GUC.';

-- Claves Primarias y Foráneas (Relaciones)
-- Primary Key (PK):
-- • (changed_at, audit_id) -> Clave primaria compuesta.
-- Foreign Keys (FK):
-- • La columna "changed_by_user_id" se relaciona conceptualmente con la clave primaria "id" de la tabla "auth.users", aunque no existe una restricción de clave foránea explícita para permitir registros de auditoría incluso si el usuario es eliminado.

-- Triggers:
CREATE OR REPLACE TRIGGER "trg_prevent_audit_modification" BEFORE DELETE OR UPDATE ON "app"."audit_log_entries" FOR EACH ROW EXECUTE FUNCTION "app"."prevent_audit_log_modification"();

-- Índices:
CREATE INDEX "idx_audit_log_entries_app_context_gin" ON ONLY "app"."audit_log_entries" USING "gin" ("app_context" "jsonb_path_ops");
CREATE INDEX "idx_audit_log_entries_user" ON ONLY "app"."audit_log_entries" USING "btree" ("changed_by_user_id");
CREATE INDEX "idx_audit_log_entries_record" ON ONLY "app"."audit_log_entries" USING "btree" ("record_id", "table_name", "schema_name");
CREATE INDEX "idx_audit_log_entries_txid" ON ONLY "app"."audit_log_entries" USING "btree" ("transaction_id");


-- 3. Tabla: app.catalog_item_translations
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS "app"."catalog_item_translations" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "catalog_item_id" "uuid" NOT NULL,
    "language_code" character(2) NOT NULL,
    "translated_name" "text" NOT NULL,
    "translated_desc" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone,
    "created_by" "uuid",
    "updated_by" "uuid",
    CONSTRAINT "catalog_item_translations_language_code_check" CHECK (("char_length"("language_code") >= 2))
);
COMMENT ON TABLE "app"."catalog_item_translations" IS 'Traducciones de catalog_items. PK compuesta (catalog_item_id, language_code).';

-- Claves Primarias y Foráneas (Relaciones)
-- Primary Key (PK):
-- • id
-- Foreign Keys (FK):
-- • La columna "catalog_item_id" es una clave foránea que se relaciona con la clave primaria "id" de la tabla "app.catalog_items".
-- • La columna "language_code" es una clave foránea que se relaciona con la clave primaria "code" de la tabla "app.languages".
-- • La columna "created_by" es una clave foránea que se relaciona con la clave primaria "id" de la tabla "auth.users".
-- • La columna "updated_by" es una clave foránea que se relaciona con la clave primaria "id" de la tabla "auth.users".

-- Triggers:
CREATE OR REPLACE TRIGGER "trg_audit_catalog_item_translations" AFTER INSERT OR DELETE OR UPDATE ON "app"."catalog_item_translations" FOR EACH ROW EXECUTE FUNCTION "app"."capture_audit_event"('id', 'false');
CREATE OR REPLACE TRIGGER "trg_manage_audit_columns_catalog_item_translations" BEFORE INSERT OR UPDATE ON "app"."catalog_item_translations" FOR EACH ROW EXECUTE FUNCTION "util"."handle_audit_columns_trigger_func"();

-- Índices:
CREATE INDEX "idx_catalog_item_translations_item_lang" ON "app"."catalog_item_translations" USING "btree" ("catalog_item_id", "language_code");


-- 4. Tabla: app.catalog_items
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS "app"."catalog_items" (
    "code" "public"."citext" NOT NULL COLLATE "pg_catalog"."und-x-icu",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone,
    "is_deleted" boolean DEFAULT false NOT NULL,
    "catalog_type_id" "uuid",
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "deleted_at" timestamp with time zone,
    "non_i18n_data" "jsonb",
    "created_by" "uuid",
    "updated_by" "uuid",
    CONSTRAINT "chk_code_is_snake" CHECK (("code" OPERATOR("public".~) '^[a-z0-9_]+$'::"public"."citext"))
);
COMMENT ON TABLE "app"."catalog_items" IS 'Valores para cada catálogo (FK catalog_type_id) con soporte de soft-delete.';

-- Claves Primarias y Foráneas (Relaciones)
-- Primary Key (PK):
-- • id
-- Foreign Keys (FK):
-- • La columna "catalog_type_id" es una clave foránea que se relaciona con la clave primaria "id" de la tabla "app.catalog_types".
-- • La columna "created_by" es una clave foránea que se relaciona con la clave primaria "id" de la tabla "auth.users".
-- • La columna "updated_by" es una clave foránea que se relaciona con la clave primaria "id" de la tabla "auth.users".

-- Triggers:
CREATE OR REPLACE TRIGGER "soft_del_catalog_items" BEFORE DELETE ON "app"."catalog_items" FOR EACH ROW EXECUTE FUNCTION "util"."soft_delete_generic"('id');
CREATE OR REPLACE TRIGGER "trg_audit_catalog_items" AFTER INSERT OR DELETE OR UPDATE ON "app"."catalog_items" FOR EACH ROW EXECUTE FUNCTION "app"."capture_audit_event"('id', 'false');
CREATE OR REPLACE TRIGGER "trg_manage_audit_columns_catalog_items" BEFORE INSERT OR UPDATE ON "app"."catalog_items" FOR EACH ROW EXECUTE FUNCTION "util"."handle_audit_columns_trigger_func"();

-- Índices:
CREATE INDEX "idx_catalog_items_type_code" ON "app"."catalog_items" USING "btree" ("catalog_type_id", "code");


-- 5. Tabla: app.catalog_types
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS "app"."catalog_types" (
    "type_code" "text" NOT NULL,
    "description" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone,
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "is_deleted" boolean DEFAULT false NOT NULL,
    "deleted_at" timestamp with time zone,
    "created_by" "uuid",
    "updated_by" "uuid"
);
COMMENT ON TABLE "app"."catalog_types" IS 'Tipos de catálogo globales. Ej: gender, phone_type, email_type…';

-- Claves Primarias y Foráneas (Relaciones)
-- Primary Key (PK):
-- • id
-- Foreign Keys (FK):
-- • La columna "created_by" es una clave foránea que se relaciona con la clave primaria "id" de la tabla "auth.users".
-- • La columna "updated_by" es una clave foránea que se relaciona con la clave primaria "id" de la tabla "auth.users".

-- Triggers:
CREATE OR REPLACE TRIGGER "soft_del_catalog_types" BEFORE DELETE ON "app"."catalog_types" FOR EACH ROW EXECUTE FUNCTION "util"."soft_delete_generic"('id');
CREATE OR REPLACE TRIGGER "trg_audit_catalog_types" AFTER INSERT OR DELETE OR UPDATE ON "app"."catalog_types" FOR EACH ROW EXECUTE FUNCTION "app"."capture_audit_event"('id', 'false');
CREATE OR REPLACE TRIGGER "trg_manage_audit_columns_catalog_types" BEFORE INSERT OR UPDATE ON "app"."catalog_types" FOR EACH ROW EXECUTE FUNCTION "util"."handle_audit_columns_trigger_func"();

-- Índices:
-- (Ninguno)


-- 6. Tabla: app.clinical_histories
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS "app"."clinical_histories" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "patient_id" "uuid" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "created_by" "uuid" NOT NULL,
    "updated_at" timestamp with time zone,
    "updated_by" "uuid",
    "is_deleted" boolean DEFAULT false NOT NULL,
    "deleted_at" timestamp with time zone,
    "terminal_id" "uuid" NOT NULL,
    "consultation_reason" "bytea",
    "consultation_history" "bytea",
    "mental_exam" "bytea",
    "personal_medical_history" "bytea",
    "family_medical_history" "bytea"
);

-- Claves Primarias y Foráneas (Relaciones)
-- Primary Key (PK):
-- • id
-- Foreign Keys (FK):
-- • La columna "patient_id" es una clave foránea que se relaciona con la clave primaria "id" de la tabla "app.patients".
-- • La columna "created_by" es una clave foránea que se relaciona con la clave primaria "id" de la tabla "auth.users".
-- • La columna "updated_by" es una clave foránea que se relaciona con la clave primaria "id" de la tabla "auth.users".
-- • La columna "terminal_id" es una clave foránea que se relaciona con la clave primaria "id" de la tabla "app.terminals".

-- Triggers:
CREATE OR REPLACE TRIGGER "trg_audit_clinical_histories" AFTER INSERT OR DELETE OR UPDATE ON "app"."clinical_histories" FOR EACH ROW EXECUTE FUNCTION "app"."capture_audit_event"('id', 'false');
CREATE OR REPLACE TRIGGER "trg_manage_audit_columns_clinical_histories" BEFORE INSERT OR UPDATE ON "app"."clinical_histories" FOR EACH ROW EXECUTE FUNCTION "util"."handle_audit_columns_trigger_func"();

-- Índices:
CREATE INDEX "idx_clinical_history_active" ON "app"."clinical_histories" USING "btree" ("patient_id") WHERE ("is_deleted" = false);


-- 7. Tabla: app.countries
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS "app"."countries" (
    "code" character varying(10) NOT NULL,
    "created_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()),
    "updated_at" timestamp with time zone,
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "is_deleted" boolean DEFAULT false NOT NULL,
    "deleted_at" timestamp with time zone,
    "created_by" "uuid",
    "updated_by" "uuid"
);
COMMENT ON TABLE "app"."countries" IS 'Almacena información sobre los países.';

-- Claves Primarias y Foráneas (Relaciones)
-- Primary Key (PK):
-- • id
-- Foreign Keys (FK):
-- • La columna "created_by" es una clave foránea que se relaciona con la clave primaria "id" de la tabla "auth.users".
-- • La columna "updated_by" es una clave foránea que se relaciona con la clave primaria "id" de la tabla "auth.users".

-- Triggers:
CREATE OR REPLACE TRIGGER "soft_del_countries" BEFORE DELETE ON "app"."countries" FOR EACH ROW EXECUTE FUNCTION "util"."soft_delete_generic"('id');
CREATE OR REPLACE TRIGGER "trg_audit_countries" AFTER INSERT OR DELETE OR UPDATE ON "app"."countries" FOR EACH ROW EXECUTE FUNCTION "app"."capture_audit_event"('id', 'false');
CREATE OR REPLACE TRIGGER "trg_manage_audit_columns_countries" BEFORE INSERT OR UPDATE ON "app"."countries" FOR EACH ROW EXECUTE FUNCTION "util"."handle_audit_columns_trigger_func"();

-- Índices:
-- (Ninguno)


-- 8. Tabla: app.country_translations
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS "app"."country_translations" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "country_id" "uuid" NOT NULL,
    "language_code" character(2) NOT NULL,
    "translated_name" "text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone,
    "demonym" "text",
    "created_by" "uuid",
    "updated_by" "uuid"
);
COMMENT ON COLUMN "app"."country_translations"."demonym" IS 'Gentilicio o nombre de la nacionalidad (ej. Dominicano/a, American, Spanish)';

-- Claves Primarias y Foráneas (Relaciones)
-- Primary Key (PK):
-- • id
-- Foreign Keys (FK):
-- • La columna "country_id" es una clave foránea que se relaciona con la clave primaria "id" de la tabla "app.countries".
-- • La columna "language_code" es una clave foránea que se relaciona con la clave primaria "code" de la tabla "app.languages".
-- • La columna "created_by" es una clave foránea que se relaciona con la clave primaria "id" de la tabla "auth.users".
-- • La columna "updated_by" es una clave foránea que se relaciona con la clave primaria "id" de la tabla "auth.users".

-- Triggers:
CREATE OR REPLACE TRIGGER "trg_audit_country_translations" AFTER INSERT OR DELETE OR UPDATE ON "app"."country_translations" FOR EACH ROW EXECUTE FUNCTION "app"."capture_audit_event"('id', 'false');
CREATE OR REPLACE TRIGGER "trg_manage_audit_columns_country_translations" BEFORE INSERT OR UPDATE ON "app"."country_translations" FOR EACH ROW EXECUTE FUNCTION "util"."handle_audit_columns_trigger_func"();

-- Índices:
-- (Ninguno)


-- 9. Tabla: app.current_family_relationships
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS "app"."current_family_relationships" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "patient_id" "uuid" NOT NULL,
    "relationship_quality" character varying(50) NOT NULL,
    "description" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "created_by" "uuid" NOT NULL,
    "is_deleted" boolean DEFAULT false NOT NULL,
    "deleted_at" timestamp with time zone,
    "updated_at" timestamp with time zone,
    "updated_by" "uuid"
);

-- Claves Primarias y Foráneas (Relaciones)
-- Primary Key (PK):
-- • id
-- Foreign Keys (FK):
-- • La columna "patient_id" es una clave foránea que se relaciona con la clave primaria "id" de la tabla "app.patients".
-- • La columna "created_by" es una clave foránea que se relaciona con la clave primaria "id" de la tabla "auth.users".
-- • La columna "updated_by" es una clave foránea que se relaciona con la clave primaria "id" de la tabla "auth.users".

-- Triggers:
CREATE OR REPLACE TRIGGER "trg_audit_current_family_relationships" AFTER INSERT OR DELETE OR UPDATE ON "app"."current_family_relationships" FOR EACH ROW EXECUTE FUNCTION "app"."capture_audit_event"('id', 'false');
CREATE OR REPLACE TRIGGER "trg_manage_audit_columns_current_family_relationships" BEFORE INSERT OR UPDATE ON "app"."current_family_relationships" FOR EACH ROW EXECUTE FUNCTION "util"."handle_audit_columns_trigger_func"();

-- Índices:
-- (Ninguno)


-- 10. Tabla: app.diagnoses
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS "app"."diagnoses" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "patient_id" "uuid" NOT NULL,
    "classification_system" character varying(50) NOT NULL,
    "diagnosis_code" character varying(20) NOT NULL,
    "diagnosis_date" timestamp with time zone NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "created_by" "uuid" NOT NULL,
    "updated_at" timestamp with time zone,
    "updated_by" "uuid",
    "is_deleted" boolean DEFAULT false NOT NULL,
    "deleted_at" timestamp with time zone,
    "terminal_id" "uuid" NOT NULL,
    "description" "bytea"
);

-- Claves Primarias y Foráneas (Relaciones)
-- Primary Key (PK):
-- • id
-- Foreign Keys (FK):
-- • La columna "patient_id" es una clave foránea que se relaciona con la clave primaria "id" de la tabla "app.patients".
-- • La columna "created_by" es una clave foránea que se relaciona con la clave primaria "id" de la tabla "auth.users".
-- • La columna "updated_by" es una clave foránea que se relaciona con la clave primaria "id" de la tabla "auth.users".
-- • La columna "terminal_id" es una clave foránea que se relaciona con la clave primaria "id" de la tabla "app.terminals".

-- Triggers:
CREATE OR REPLACE TRIGGER "trg_audit_diagnoses" AFTER INSERT OR DELETE OR UPDATE ON "app"."diagnoses" FOR EACH ROW EXECUTE FUNCTION "app"."capture_audit_event"('id', 'false');
CREATE OR REPLACE TRIGGER "trg_manage_audit_columns_diagnoses" BEFORE INSERT OR UPDATE ON "app"."diagnoses" FOR EACH ROW EXECUTE FUNCTION "util"."handle_audit_columns_trigger_func"();

-- Índices:
CREATE INDEX "idx_diagnoses_active" ON "app"."diagnoses" USING "btree" ("patient_id") WHERE ("is_deleted" = false);


-- 11. Tabla: app.evaluations
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS "app"."evaluations" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "patient_id" "uuid" NOT NULL,
    "evaluation_date" timestamp with time zone NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "created_by" "uuid" NOT NULL,
    "updated_at" timestamp with time zone,
    "updated_by" "uuid",
    "is_deleted" boolean DEFAULT false NOT NULL,
    "deleted_at" timestamp with time zone,
    "terminal_id" "uuid" NOT NULL,
    "tests_used" "bytea",
    "results" "bytea"
);

-- Claves Primarias y Foráneas (Relaciones)
-- Primary Key (PK):
-- • id
-- Foreign Keys (FK):
-- • La columna "patient_id" es una clave foránea que se relaciona con la clave primaria "id" de la tabla "app.patients".
-- • La columna "created_by" es una clave foránea que se relaciona con la clave primaria "id" de la tabla "auth.users".
-- • La columna "updated_by" es una clave foránea que se relaciona con la clave primaria "id" de la tabla "auth.users".
-- • La columna "terminal_id" es una clave foránea que se relaciona con la clave primaria "id" de la tabla "app.terminals".

-- Triggers:
CREATE OR REPLACE TRIGGER "trg_audit_evaluations" AFTER INSERT OR DELETE OR UPDATE ON "app"."evaluations" FOR EACH ROW EXECUTE FUNCTION "app"."capture_audit_event"('id', 'false');
CREATE OR REPLACE TRIGGER "trg_manage_audit_columns_evaluations" BEFORE INSERT OR UPDATE ON "app"."evaluations" FOR EACH ROW EXECUTE FUNCTION "util"."handle_audit_columns_trigger_func"();

-- Índices:
CREATE INDEX "idx_evaluations_active" ON "app"."evaluations" USING "btree" ("patient_id") WHERE ("is_deleted" = false);


-- 12. Tabla: app.family_communications
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS "app"."family_communications" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "patient_id" "uuid" NOT NULL,
    "communication_quality" character varying(50) NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "created_by" "uuid" NOT NULL,
    "updated_at" timestamp with time zone,
    "updated_by" "uuid",
    "is_deleted" boolean DEFAULT false NOT NULL,
    "deleted_at" timestamp with time zone,
    "description" "bytea"
);

-- Claves Primarias y Foráneas (Relaciones)
-- Primary Key (PK):
-- • id
-- Foreign Keys (FK):
-- • La columna "patient_id" es una clave foránea que se relaciona con la clave primaria "id" de la tabla "app.patients".
-- • La columna "created_by" es una clave foránea que se relaciona con la clave primaria "id" de la tabla "auth.users".
-- • La columna "updated_by" es una clave foránea que se relaciona con la clave primaria "id" de la tabla "auth.users".

-- Triggers:
CREATE OR REPLACE TRIGGER "trg_audit_family_communications" AFTER INSERT OR DELETE OR UPDATE ON "app"."family_communications" FOR EACH ROW EXECUTE FUNCTION "app"."capture_audit_event"('id', 'false');
CREATE OR REPLACE TRIGGER "trg_manage_audit_columns_family_communications" BEFORE INSERT OR UPDATE ON "app"."family_communications" FOR EACH ROW EXECUTE FUNCTION "util"."handle_audit_columns_trigger_func"();

-- Índices:
-- (Ninguno)


-- 13. Tabla: app.family_conflicts
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS "app"."family_conflicts" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "patient_id" "uuid" NOT NULL,
    "family_member_id" "uuid" NOT NULL,
    "resolved" boolean DEFAULT false NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "created_by" "uuid" NOT NULL,
    "updated_at" timestamp with time zone,
    "updated_by" "uuid",
    "is_deleted" boolean DEFAULT false NOT NULL,
    "conflict_type_id" "uuid",
    "deleted_at" timestamp with time zone,
    "description" "bytea"
);

-- Claves Primarias y Foráneas (Relaciones)
-- Primary Key (PK):
-- • id
-- Foreign Keys (FK):
-- • La columna "patient_id" es una clave foránea que se relaciona con la clave primaria "id" de la tabla "app.patients".
-- • La columna "family_member_id" es una clave foránea que se relaciona con la clave primaria "id" de la tabla "app.family_members".
-- • La columna "created_by" es una clave foránea que se relaciona con la clave primaria "id" de la tabla "auth.users".
-- • La columna "updated_by" es una clave foránea que se relaciona con la clave primaria "id" de la tabla "auth.users".
-- • La columna "conflict_type_id" es una clave foránea que se relaciona con la clave primaria "id" de la tabla "app.catalog_items".

-- Triggers:
CREATE OR REPLACE TRIGGER "trg_audit_family_conflicts" AFTER INSERT OR DELETE OR UPDATE ON "app"."family_conflicts" FOR EACH ROW EXECUTE FUNCTION "app"."capture_audit_event"('id', 'false');
CREATE OR REPLACE TRIGGER "trg_manage_audit_columns_family_conflicts" BEFORE INSERT OR UPDATE ON "app"."family_conflicts" FOR EACH ROW EXECUTE FUNCTION "util"."handle_audit_columns_trigger_func"();

-- Índices:
CREATE INDEX "idx_family_conflicts_active" ON "app"."family_conflicts" USING "btree" ("patient_id") WHERE ("is_deleted" = false);
CREATE INDEX "idx_family_conflicts_patient_id" ON "app"."family_conflicts" USING "btree" ("patient_id");


-- 14. Tabla: app.family_limits
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS "app"."family_limits" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "patient_id" "uuid" NOT NULL,
    "limits_quality" character varying(50) NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "created_by" "uuid" NOT NULL,
    "updated_at" timestamp with time zone,
    "updated_by" "uuid",
    "is_deleted" boolean DEFAULT false NOT NULL,
    "deleted_at" timestamp with time zone,
    "description" "bytea"
);

-- Claves Primarias y Foráneas (Relaciones)
-- Primary Key (PK):
-- • id
-- Foreign Keys (FK):
-- • La columna "patient_id" es una clave foránea que se relaciona con la clave primaria "id" de la tabla "app.patients".
-- • La columna "created_by" es una clave foránea que se relaciona con la clave primaria "id" de la tabla "auth.users".
-- • La columna "updated_by" es una clave foránea que se relaciona con la clave primaria "id" de la tabla "auth.users".

-- Triggers:
CREATE OR REPLACE TRIGGER "trg_audit_family_limits" AFTER INSERT OR DELETE OR UPDATE ON "app"."family_limits" FOR EACH ROW EXECUTE FUNCTION "app"."capture_audit_event"('id', 'false');
CREATE OR REPLACE TRIGGER "trg_manage_audit_columns_family_limits" BEFORE INSERT OR UPDATE ON "app"."family_limits" FOR EACH ROW EXECUTE FUNCTION "util"."handle_audit_columns_trigger_func"();

-- Índices:
-- (Ninguno)


-- 15. Tabla: app.family_members
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS "app"."family_members" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "patient_id" "uuid" NOT NULL,
    "alive" boolean DEFAULT true,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "created_by" "uuid" NOT NULL,
    "updated_at" timestamp with time zone,
    "updated_by" "uuid",
    "is_deleted" boolean DEFAULT false NOT NULL,
    "relationship_id" "uuid",
    "occupation_id" "uuid",
    "education_level_id" "uuid",
    "job_status_id" "uuid",
    "deleted_at" timestamp with time zone,
    "first_name" "bytea",
    "last_name" "bytea",
    "contact" "bytea",
    "characteristics" "bytea"
);

-- Claves Primarias y Foráneas (Relaciones)
-- Primary Key (PK):
-- • id
-- Foreign Keys (FK):
-- • La columna "patient_id" es una clave foránea que se relaciona con la clave primaria "id" de la tabla "app.patients".
-- • La columna "created_by" es una clave foránea que se relaciona con la clave primaria "id" de la tabla "auth.users".
-- • La columna "updated_by" es una clave foránea que se relaciona con la clave primaria "id" de la tabla "auth.users".
-- • La columna "relationship_id" es una clave foránea que se relaciona con la clave primaria "id" de la tabla "app.catalog_items".
-- • La columna "occupation_id" es una clave foránea que se relaciona con la clave primaria "id" de la tabla "app.catalog_items".
-- • La columna "education_level_id" es una clave foránea que se relaciona con la clave primaria "id" de la tabla "app.catalog_items".
-- • La columna "job_status_id" es una clave foránea que se relaciona con la clave primaria "id" de la tabla "app.catalog_items".

-- Triggers:
CREATE OR REPLACE TRIGGER "trg_audit_family_members" AFTER INSERT OR DELETE OR UPDATE ON "app"."family_members" FOR EACH ROW EXECUTE FUNCTION "app"."capture_audit_event"('id', 'false');
CREATE OR REPLACE TRIGGER "trg_manage_audit_columns_family_members" BEFORE INSERT OR UPDATE ON "app"."family_members" FOR EACH ROW EXECUTE FUNCTION "util"."handle_audit_columns_trigger_func"();

-- Índices:
CREATE INDEX "idx_family_members_active" ON "app"."family_members" USING "btree" ("patient_id") WHERE ("is_deleted" = false);
CREATE INDEX "idx_family_members_patient_id" ON "app"."family_members" USING "btree" ("patient_id");


-- 16. Tabla: app.initial_evaluations
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS "app"."initial_evaluations" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "patient_id" "uuid" NOT NULL,
    "completion_date" timestamp with time zone NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "created_by" "uuid" NOT NULL,
    "updated_at" timestamp with time zone,
    "updated_by" "uuid",
    "is_deleted" boolean DEFAULT false NOT NULL,
    "deleted_at" timestamp with time zone,
    "responses" "bytea"
);

-- Claves Primarias y Foráneas (Relaciones)
-- Primary Key (PK):
-- • id
-- Foreign Keys (FK):
-- • La columna "patient_id" es una clave foránea que se relaciona con la clave primaria "id" de la tabla "app.patients".
-- • La columna "created_by" es una clave foránea que se relaciona con la clave primaria "id" de la tabla "auth.users".
-- • La columna "updated_by" es una clave foránea que se relaciona con la clave primaria "id" de la tabla "auth.users".

-- Triggers:
CREATE OR REPLACE TRIGGER "trg_audit_initial_evaluations" AFTER INSERT OR DELETE OR UPDATE ON "app"."initial_evaluations" FOR EACH ROW EXECUTE FUNCTION "app"."capture_audit_event"('id', 'false');
CREATE OR REPLACE TRIGGER "trg_manage_audit_columns_initial_evaluations" BEFORE INSERT OR UPDATE ON "app"."initial_evaluations" FOR EACH ROW EXECUTE FUNCTION "util"."handle_audit_columns_trigger_func"();

-- Índices:
CREATE INDEX "idx_initial_evaluations_active" ON "app"."initial_evaluations" USING "btree" ("patient_id") WHERE ("is_deleted" = false);


-- 17. Tabla: app.languages
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS "app"."languages" (
    "code" character(2) NOT NULL,
    "name" "text" NOT NULL,
    "is_rtl" boolean DEFAULT false NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone,
    "created_by" "uuid",
    "updated_by" "uuid",
    CONSTRAINT "languages_code_check" CHECK ((("code")::"text" = "lower"(("code")::"text")))
);
COMMENT ON COLUMN "app"."languages"."created_by" IS 'Usuario que creó el idioma.';

-- Claves Primarias y Foráneas (Relaciones)
-- Primary Key (PK):
-- • code
-- Foreign Keys (FK):
-- • La columna "created_by" es una clave foránea que se relaciona con la clave primaria "id" de la tabla "auth.users".
-- • La columna "updated_by" es una clave foránea que se relaciona con la clave primaria "id" de la tabla "auth.users".

-- Triggers:
CREATE OR REPLACE TRIGGER "trg_manage_audit_columns_languages" BEFORE INSERT OR UPDATE ON "app"."languages" FOR EACH ROW EXECUTE FUNCTION "util"."handle_audit_columns_trigger_func"();

-- Índices:
-- (Ninguno)


-- 18. Tabla: app.love_areas
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS "app"."love_areas" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "patient_id" "uuid" NOT NULL,
    "sexual_activity_onset" "date",
    "gender_violence" boolean DEFAULT false,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "created_by" "uuid" NOT NULL,
    "updated_at" timestamp with time zone,
    "updated_by" "uuid",
    "is_deleted" boolean DEFAULT false NOT NULL,
    "deleted_at" timestamp with time zone,
    "romantic_relationships_duration" "bytea",
    "couple_conflicts" "bytea",
    "sexual_dysfunctions" "bytea"
);

-- Claves Primarias y Foráneas (Relaciones)
-- Primary Key (PK):
-- • id
-- Foreign Keys (FK):
-- • La columna "patient_id" es una clave foránea que se relaciona con la clave primaria "id" de la tabla "app.patients".
-- • La columna "created_by" es una clave foránea que se relaciona con la clave primaria "id" de la tabla "auth.users".
-- • La columna "updated_by" es una clave foránea que se relaciona con la clave primaria "id" de la tabla "auth.users".

-- Triggers:
CREATE OR REPLACE TRIGGER "trg_audit_love_areas" AFTER INSERT OR DELETE OR UPDATE ON "app"."love_areas" FOR EACH ROW EXECUTE FUNCTION "app"."capture_audit_event"('id', 'false');
CREATE OR REPLACE TRIGGER "trg_manage_audit_columns_love_areas" BEFORE INSERT OR UPDATE ON "app"."love_areas" FOR EACH ROW EXECUTE FUNCTION "util"."handle_audit_columns_trigger_func"();

-- Índices:
CREATE INDEX "idx_love_area_active" ON "app"."love_areas" USING "btree" ("patient_id") WHERE ("is_deleted" = false);


-- 19. Tabla: app.patient_addresses
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS "app"."patient_addresses" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "patient_id" "uuid" NOT NULL,
    "is_primary" boolean DEFAULT false NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "created_by" "uuid" NOT NULL,
    "updated_at" timestamp with time zone,
    "updated_by" "uuid",
    "is_deleted" boolean DEFAULT false NOT NULL,
    "deleted_at" timestamp with time zone,
    "address_type_id" "uuid",
    "administrative_unit_id" "uuid" NOT NULL,
    "street_address" "bytea",
    "postal_code" "bytea"
);

-- Claves Primarias y Foráneas (Relaciones)
-- Primary Key (PK):
-- • id
-- Foreign Keys (FK):
-- • La columna "patient_id" es una clave foránea que se relaciona con la clave primaria "id" de la tabla "app.patients".
-- • La columna "created_by" es una clave foránea que se relaciona con la clave primaria "id" de la tabla "auth.users".
-- • La columna "updated_by" es una clave foránea que se relaciona con la clave primaria "id" de la tabla "auth.users".
-- • La columna "address_type_id" es una clave foránea que se relaciona con la clave primaria "id" de la tabla "app.catalog_items".
-- • La columna "administrative_unit_id" es una clave foránea que se relaciona con la clave primaria "id" de la tabla "app.administrative_units".

-- Triggers:
CREATE OR REPLACE TRIGGER "trg_audit_patient_addresses" AFTER INSERT OR DELETE OR UPDATE ON "app"."patient_addresses" FOR EACH ROW EXECUTE FUNCTION "app"."capture_audit_event"('id', 'false');
CREATE OR REPLACE TRIGGER "trg_manage_audit_columns_patient_addresses" BEFORE INSERT OR UPDATE ON "app"."patient_addresses" FOR EACH ROW EXECUTE FUNCTION "util"."handle_audit_columns_trigger_func"();

-- Índices:
CREATE INDEX "idx_patient_addresses_active" ON "app"."patient_addresses" USING "btree" ("patient_id") WHERE ("is_deleted" = false);
CREATE INDEX "idx_patient_addresses_admin_unit_id" ON "app"."patient_addresses" USING "btree" ("administrative_unit_id");


-- 20. Tabla: app.patient_emails
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS "app"."patient_emails" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "patient_id" "uuid" NOT NULL,
    "is_primary" boolean DEFAULT false NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "created_by" "uuid" NOT NULL,
    "updated_at" timestamp with time zone,
    "updated_by" "uuid",
    "is_deleted" boolean DEFAULT false NOT NULL,
    "email_type_id" "uuid",
    "deleted_at" timestamp with time zone,
    "email" "bytea"
);

-- Claves Primarias y Foráneas (Relaciones)
-- Primary Key (PK):
-- • id
-- Foreign Keys (FK):
-- • La columna "patient_id" es una clave foránea que se relaciona con la clave primaria "id" de la tabla "app.patients".
-- • La columna "created_by" es una clave foránea que se relaciona con la clave primaria "id" de la tabla "auth.users".
-- • La columna "updated_by" es una clave foránea que se relaciona con la clave primaria "id" de la tabla "auth.users".
-- • La columna "email_type_id" es una clave foránea que se relaciona con la clave primaria "id" de la tabla "app.catalog_items".

-- Triggers:
CREATE OR REPLACE TRIGGER "trg_audit_patient_emails" AFTER INSERT OR DELETE OR UPDATE ON "app"."patient_emails" FOR EACH ROW EXECUTE FUNCTION "app"."capture_audit_event"('id', 'false');
CREATE OR REPLACE TRIGGER "trg_manage_audit_columns_patient_emails" BEFORE INSERT OR UPDATE ON "app"."patient_emails" FOR EACH ROW EXECUTE FUNCTION "util"."handle_audit_columns_trigger_func"();

-- Índices:
CREATE INDEX "idx_patient_emails_active" ON "app"."patient_emails" USING "btree" ("patient_id") WHERE ("is_deleted" = false);


-- 21. Tabla: app.patient_emergency_contacts
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS "app"."patient_emergency_contacts" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "patient_id" "uuid" NOT NULL,
    "priority" integer,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "created_by" "uuid" NOT NULL,
    "updated_at" timestamp with time zone,
    "updated_by" "uuid",
    "is_deleted" boolean DEFAULT false NOT NULL,
    "relationship_id" "uuid",
    "deleted_at" timestamp with time zone,
    "contact_name" "bytea",
    "contact_phone" "bytea"
);

-- Claves Primarias y Foráneas (Relaciones)
-- Primary Key (PK):
-- • id
-- Foreign Keys (FK):
-- • La columna "patient_id" es una clave foránea que se relaciona con la clave primaria "id" de la tabla "app.patients".
-- • La columna "created_by" es una clave foránea que se relaciona con la clave primaria "id" de la tabla "auth.users".
-- • La columna "updated_by" es una clave foránea que se relaciona con la clave primaria "id" de la tabla "auth.users".
-- • La columna "relationship_id" es una clave foránea que se relaciona con la clave primaria "id" de la tabla "app.catalog_items".

-- Triggers:
CREATE OR REPLACE TRIGGER "trg_audit_patient_emergency_contacts" AFTER INSERT OR DELETE OR UPDATE ON "app"."patient_emergency_contacts" FOR EACH ROW EXECUTE FUNCTION "app"."capture_audit_event"('id', 'false');
CREATE OR REPLACE TRIGGER "trg_manage_audit_columns_patient_emergency_contacts" BEFORE INSERT OR UPDATE ON "app"."patient_emergency_contacts" FOR EACH ROW EXECUTE FUNCTION "util"."handle_audit_columns_trigger_func"();

-- Índices:
CREATE INDEX "idx_patient_emergency_contacts_active" ON "app"."patient_emergency_contacts" USING "btree" ("patient_id") WHERE ("is_deleted" = false);
CREATE INDEX "idx_patient_emergency_contacts_patient_id" ON "app"."patient_emergency_contacts" USING "btree" ("patient_id");


-- 22. Tabla: app.patient_parenting_profiles
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS "app"."patient_parenting_profiles" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "patient_id" "uuid" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "created_by" "uuid" NOT NULL,
    "updated_at" timestamp with time zone,
    "updated_by" "uuid",
    "is_deleted" boolean DEFAULT false NOT NULL,
    "parenting_style_id" "uuid",
    "deleted_at" timestamp with time zone,
    "scale_version" "text",
    "source" "text",
    "description" "bytea",
    "assessment_method" "bytea"
);

-- Claves Primarias y Foráneas (Relaciones)
-- Primary Key (PK):
-- • id
-- Foreign Keys (FK):
-- • La columna "patient_id" es una clave foránea que se relaciona con la clave primaria "id" de la tabla "app.patients".
-- • La columna "created_by" es una clave foránea que se relaciona con la clave primaria "id" de la tabla "auth.users".
-- • La columna "updated_by" es una clave foránea que se relaciona con la clave primaria "id" de la tabla "auth.users".
-- • La columna "parenting_style_id" es una clave foránea que se relaciona con la clave primaria "id" de la tabla "app.catalog_items".

-- Triggers:
CREATE OR REPLACE TRIGGER "trg_audit_patient_parenting_profiles" AFTER INSERT OR DELETE OR UPDATE ON "app"."patient_parenting_profiles" FOR EACH ROW EXECUTE FUNCTION "app"."capture_audit_event"('id', 'false');
CREATE OR REPLACE TRIGGER "trg_manage_audit_columns_patient_parenting_profiles" BEFORE INSERT OR UPDATE ON "app"."patient_parenting_profiles" FOR EACH ROW EXECUTE FUNCTION "util"."handle_audit_columns_trigger_func"();

-- Índices:
CREATE INDEX "idx_patient_parenting_styles_active" ON "app"."patient_parenting_profiles" USING "btree" ("patient_id") WHERE ("is_deleted" = false);


-- 23. Tabla: app.patient_phones
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS "app"."patient_phones" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "patient_id" "uuid" NOT NULL,
    "is_primary" boolean DEFAULT false NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "created_by" "uuid" NOT NULL,
    "updated_at" timestamp with time zone,
    "updated_by" "uuid",
    "is_deleted" boolean DEFAULT false NOT NULL,
    "phone_type_id" "uuid",
    "deleted_at" timestamp with time zone,
    "phone_number" "bytea"
);

-- Claves Primarias y Foráneas (Relaciones)
-- Primary Key (PK):
-- • id
-- Foreign Keys (FK):
-- • La columna "patient_id" es una clave foránea que se relaciona con la clave primaria "id" de la tabla "app.patients".
-- • La columna "created_by" es una clave foránea que se relaciona con la clave primaria "id" de la tabla "auth.users".
-- • La columna "updated_by" es una clave foránea que se relaciona con la clave primaria "id" de la tabla "auth.users".
-- • La columna "phone_type_id" es una clave foránea que se relaciona con la clave primaria "id" de la tabla "app.catalog_items".

-- Triggers:
CREATE OR REPLACE TRIGGER "trg_audit_patient_phones" AFTER INSERT OR DELETE OR UPDATE ON "app"."patient_phones" FOR EACH ROW EXECUTE FUNCTION "app"."capture_audit_event"('id', 'false');
CREATE OR REPLACE TRIGGER "trg_manage_audit_columns_patient_phones" BEFORE INSERT OR UPDATE ON "app"."patient_phones" FOR EACH ROW EXECUTE FUNCTION "util"."handle_audit_columns_trigger_func"();
CREATE OR REPLACE TRIGGER "trg_patient_phones_chk_phone_type" BEFORE INSERT OR UPDATE ON "app"."patient_phones" FOR EACH ROW EXECUTE FUNCTION "util"."validate_catalog_item_type"('PHONE_TYPE', 'phone_type_id');

-- Índices:
CREATE INDEX "idx_patient_phones_active" ON "app"."patient_phones" USING "btree" ("patient_id") WHERE ("is_deleted" = false);


-- 24. Tabla: app.patient_provided_parenting
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS "app"."patient_provided_parenting" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "patient_id" "uuid" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "created_by" "uuid" NOT NULL,
    "updated_at" timestamp with time zone,
    "updated_by" "uuid",
    "is_deleted" boolean DEFAULT false NOT NULL,
    "deleted_at" timestamp with time zone,
    "provided_style_id" "uuid",
    "description" "bytea"
);

-- Claves Primarias y Foráneas (Relaciones)
-- Primary Key (PK):
-- • id
-- Foreign Keys (FK):
-- • La columna "patient_id" es una clave foránea que se relaciona con la clave primaria "id" de la tabla "app.patients".
-- • La columna "created_by" es una clave foránea que se relaciona con la clave primaria "id" de la tabla "auth.users".
-- • La columna "updated_by" es una clave foránea que se relaciona con la clave primaria "id" de la tabla "auth.users".
-- • La columna "provided_style_id" es una clave foránea que se relaciona con la clave primaria "id" de la tabla "app.catalog_items".

-- Triggers:
CREATE OR REPLACE TRIGGER "trg_audit_patient_provided_parenting" AFTER INSERT OR DELETE OR UPDATE ON "app"."patient_provided_parenting" FOR EACH ROW EXECUTE FUNCTION "app"."capture_audit_event"('id', 'false');
CREATE OR REPLACE TRIGGER "trg_manage_audit_columns_patient_provided_parenting" BEFORE INSERT OR UPDATE ON "app"."patient_provided_parenting" FOR EACH ROW EXECUTE FUNCTION "util"."handle_audit_columns_trigger_func"();

-- Índices:
CREATE INDEX "idx_patient_provided_parenting_active" ON "app"."patient_provided_parenting" USING "btree" ("patient_id") WHERE ("is_deleted" = false);


-- 25. Tabla: app.patient_received_upbringing
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS "app"."patient_received_upbringing" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "patient_id" "uuid" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "created_by" "uuid" NOT NULL,
    "updated_at" timestamp with time zone,
    "updated_by" "uuid",
    "is_deleted" boolean DEFAULT false NOT NULL,
    "received_style_id" "uuid",
    "deleted_at" timestamp with time zone,
    "scale_version" "text",
    "source" "text",
    "description" "bytea",
    "assessment_method" "bytea"
);

-- Claves Primarias y Foráneas (Relaciones)
-- Primary Key (PK):
-- • id
-- Foreign Keys (FK):
-- • La columna "patient_id" es una clave foránea que se relaciona con la clave primaria "id" de la tabla "app.patients".
-- • La columna "created_by" es una clave foránea que se relaciona con la clave primaria "id" de la tabla "auth.users".
-- • La columna "updated_by" es una clave foránea que se relaciona con la clave primaria "id" de la tabla "auth.users".
-- • La columna "received_style_id" es una clave foránea que se relaciona con la clave primaria "id" de la tabla "app.catalog_items".

-- Triggers:
CREATE OR REPLACE TRIGGER "trg_audit_patient_received_upbringing" AFTER INSERT OR DELETE OR UPDATE ON "app"."patient_received_upbringing" FOR EACH ROW EXECUTE FUNCTION "app"."capture_audit_event"('id', 'false');
CREATE OR REPLACE TRIGGER "trg_manage_audit_columns_patient_received_upbringing" BEFORE INSERT OR UPDATE ON "app"."patient_received_upbringing" FOR EACH ROW EXECUTE FUNCTION "util"."handle_audit_columns_trigger_func"();

-- Índices:
CREATE INDEX "idx_patient_received_upbringing_active" ON "app"."patient_received_upbringing" USING "btree" ("patient_id") WHERE ("is_deleted" = false);


-- 26. Tabla: app.patient_referrals
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS "app"."patient_referrals" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "patient_id" "uuid" NOT NULL,
    "referral_type" character varying(20) NOT NULL,
    "external_source_item_id" "uuid",
    "from_professional_id" "uuid",
    "to_professional_id" "uuid",
    "referral_date" timestamp with time zone DEFAULT "now"() NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "created_by" "uuid" NOT NULL,
    "updated_at" timestamp with time zone,
    "updated_by" "uuid",
    "is_deleted" boolean DEFAULT false NOT NULL,
    "deleted_at" timestamp with time zone,
    "detail" "bytea"
);

-- Claves Primarias y Foráneas (Relaciones)
-- Primary Key (PK):
-- • id
-- Foreign Keys (FK):
-- • La columna "patient_id" es una clave foránea que se relaciona con la clave primaria "id" de la tabla "app.patients".
-- • La columna "external_source_item_id" es una clave foránea que se relaciona con la clave primaria "id" de la tabla "app.catalog_items".
-- • La columna "from_professional_id" es una clave foránea que se relaciona con la clave primaria "id" de la tabla "app.professional_profiles".
-- • La columna "to_professional_id" es una clave foránea que se relaciona con la clave primaria "id" de la tabla "app.professional_profiles".

-- Triggers:
CREATE OR REPLACE TRIGGER "trg_audit_patient_referrals" AFTER INSERT OR DELETE OR UPDATE ON "app"."patient_referrals" FOR EACH ROW EXECUTE FUNCTION "app"."capture_audit_event"('id', 'false');
CREATE OR REPLACE TRIGGER "trg_manage_audit_columns_patient_referrals" BEFORE INSERT OR UPDATE ON "app"."patient_referrals" FOR EACH ROW EXECUTE FUNCTION "util"."handle_audit_columns_trigger_func"();

-- Índices:
CREATE INDEX "idx_patient_referrals_active" ON "app"."patient_referrals" USING "btree" ("patient_id") WHERE ("is_deleted" = false);
CREATE INDEX "idx_patient_referrals_patient_id" ON "app"."patient_referrals" USING "btree" ("patient_id");


-- 27. Tabla: app.patient_work_details
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS "app"."patient_work_details" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "patient_id" "uuid" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "created_by" "uuid" NOT NULL,
    "updated_at" timestamp with time zone,
    "updated_by" "uuid",
    "is_deleted" boolean DEFAULT false NOT NULL,
    "job_status_id" "uuid",
    "occupation_id" "uuid",
    "deleted_at" timestamp with time zone,
    "work_insertion" "bytea",
    "adaptation_discipline" "bytea",
    "job_change_unemployment" "bytea",
    "job_satisfaction" "bytea",
    "successes_failures" "bytea",
    "work_conflicts" "bytea"
);

-- Claves Primarias y Foráneas (Relaciones)
-- Primary Key (PK):
-- • id
-- Foreign Keys (FK):
-- • La columna "patient_id" es una clave foránea que se relaciona con la clave primaria "id" de la tabla "app.patients".
-- • La columna "created_by" es una clave foránea que se relaciona con la clave primaria "id" de la tabla "auth.users".
-- • La columna "updated_by" es una clave foránea que se relaciona con la clave primaria "id" de la tabla "auth.users".
-- • La columna "job_status_id" es una clave foránea que se relaciona con la clave primaria "id" de la tabla "app.catalog_items".
-- • La columna "occupation_id" es una clave foránea que se relaciona con la clave primaria "id" de la tabla "app.catalog_items".

-- Triggers:
CREATE OR REPLACE TRIGGER "trg_audit_patient_work_details" AFTER INSERT OR DELETE OR UPDATE ON "app"."patient_work_details" FOR EACH ROW EXECUTE FUNCTION "app"."capture_audit_event"('id', 'false');
CREATE OR REPLACE TRIGGER "trg_manage_audit_columns_patient_work_details" BEFORE INSERT OR UPDATE ON "app"."patient_work_details" FOR EACH ROW EXECUTE FUNCTION "util"."handle_audit_columns_trigger_func"();

-- Índices:
CREATE INDEX "idx_patient_work_details_active" ON "app"."patient_work_details" USING "btree" ("patient_id") WHERE ("is_deleted" = false);


-- 28. Tabla: app.patients
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS "app"."patients" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "registered_by" "uuid" NOT NULL,
    "date_of_birth" "date" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "created_by" "uuid" NOT NULL,
    "updated_at" timestamp with time zone,
    "updated_by" "uuid",
    "is_deleted" boolean DEFAULT false NOT NULL,
    "education_level_item_id" "uuid",
    "nationality_country_id" "uuid",
    "health_insurance_item_id" "uuid",
    "marital_status_item_id" "uuid",
    "gender_item_id" "uuid",
    "deleted_at" timestamp with time zone,
    "terminal_id" "uuid" NOT NULL,
    "first_name" "bytea",
    "last_name" "bytea",
    "id_number" "bytea"
);
COMMENT ON TABLE "app"."patients" IS 'ESTADO: MVP CORE. Información demográfica primaria de los pacientes.';

-- Claves Primarias y Foráneas (Relaciones)
-- Primary Key (PK):
-- • id
-- Foreign Keys (FK):
-- • La columna "registered_by" es una clave foránea que se relaciona con la clave primaria "id" de la tabla "app.users".
-- • La columna "created_by" es una clave foránea que se relaciona con la clave primaria "id" de la tabla "auth.users".
-- • La columna "updated_by" es una clave foránea que se relaciona con la clave primaria "id" de la tabla "auth.users".
-- • La columna "education_level_item_id" es una clave foránea que se relaciona con la clave primaria "id" de la tabla "app.catalog_items".
-- • La columna "nationality_country_id" es una clave foránea que se relaciona con la clave primaria "id" de la tabla "app.countries".
-- • La columna "health_insurance_item_id" es una clave foránea que se relaciona con la clave primaria "id" de la tabla "app.catalog_items".
-- • La columna "marital_status_item_id" es una clave foránea que se relaciona con la clave primaria "id" de la tabla "app.catalog_items".
-- • La columna "gender_item_id" es una clave foránea que se relaciona con la clave primaria "id" de la tabla "app.catalog_items".
-- • La columna "terminal_id" es una clave foránea que se relaciona con la clave primaria "id" de la tabla "app.terminals".

-- Triggers:
CREATE OR REPLACE TRIGGER "trg_audit_patients" AFTER INSERT OR DELETE OR UPDATE ON "app"."patients" FOR EACH ROW EXECUTE FUNCTION "app"."capture_audit_event"('id', 'false');
CREATE OR REPLACE TRIGGER "trg_manage_audit_columns_patients" BEFORE INSERT OR UPDATE ON "app"."patients" FOR EACH ROW EXECUTE FUNCTION "util"."handle_audit_columns_trigger_func"();
CREATE OR REPLACE TRIGGER "trg_patients_chk_gender" BEFORE INSERT OR UPDATE ON "app"."patients" FOR EACH ROW EXECUTE FUNCTION "util"."validate_catalog_item_type"('GENDER', 'gender_item_id');
CREATE OR REPLACE TRIGGER "trg_patients_terminal_auth" BEFORE INSERT OR UPDATE ON "app"."patients" FOR EACH ROW EXECUTE FUNCTION "util"."enforce_same_terminal"();

-- Índices:
CREATE INDEX "idx_patients_active" ON "app"."patients" USING "btree" ("id") WHERE ("is_deleted" = false);
CREATE INDEX "idx_patients_registered_by" ON "app"."patients" USING "btree" ("registered_by");


-- 29. Tabla: app.payments
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS "app"."payments" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "terminal_id" "uuid" NOT NULL,
    "amount" numeric(10,2) NOT NULL,
    "payment_date" timestamp with time zone DEFAULT "now"(),
    "payment_method" character varying(50),
    "transaction_id" character varying(100),
    "status" "public"."payment_status_enum" DEFAULT 'completed'::"public"."payment_status_enum",
    "payment_gateway_response" "jsonb",
    "receipt_url" character varying(200),
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone,
    "is_deleted" boolean DEFAULT false NOT NULL,
    "deleted_at" timestamp with time zone,
    "created_by" "uuid",
    "updated_by" "uuid",
    CONSTRAINT "chk_payment_amount" CHECK (("amount" > (0)::numeric))
);
COMMENT ON COLUMN "app"."payments"."created_by" IS 'Usuario que registró el pago.';

-- Claves Primarias y Foráneas (Relaciones)
-- Primary Key (PK):
-- • id
-- Foreign Keys (FK):
-- • La columna "terminal_id" es una clave foránea que se relaciona con la clave primaria "id" de la tabla "app.terminals".
-- • La columna "created_by" es una clave foránea que se relaciona con la clave primaria "id" de la tabla "auth.users".
-- • La columna "updated_by" es una clave foránea que se relaciona con la clave primaria "id" de la tabla "auth.users".

-- Triggers:
CREATE OR REPLACE TRIGGER "trg_audit_payments" AFTER INSERT OR DELETE OR UPDATE ON "app"."payments" FOR EACH ROW EXECUTE FUNCTION "app"."capture_audit_event"('id', 'false');
CREATE OR REPLACE TRIGGER "trg_manage_audit_columns_payments" BEFORE INSERT OR UPDATE ON "app"."payments" FOR EACH ROW EXECUTE FUNCTION "util"."handle_audit_columns_trigger_func"();

-- Índices:
CREATE INDEX "idx_payments_payment_date" ON "app"."payments" USING "btree" ("payment_date");


-- 30. Tabla: app.personal_social_areas
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS "app"."personal_social_areas" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "patient_id" "uuid" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "created_by" "uuid" NOT NULL,
    "updated_at" timestamp with time zone,
    "updated_by" "uuid",
    "is_deleted" boolean DEFAULT false NOT NULL,
    "deleted_at" timestamp with time zone,
    "self_concept" "bytea",
    "self_esteem" "bytea",
    "personality_traits" "bytea",
    "emotional_state" "bytea",
    "needs_interests" "bytea",
    "hygiene_habits" "bytea",
    "nutrition" "bytea",
    "sleep" "bytea",
    "sociability" "bytea",
    "projects_aspirations" "bytea"
);

-- Claves Primarias y Foráneas (Relaciones)
-- Primary Key (PK):
-- • id
-- Foreign Keys (FK):
-- • La columna "patient_id" es una clave foránea que se relaciona con la clave primaria "id" de la tabla "app.patients".
-- • La columna "created_by" es una clave foránea que se relaciona con la clave primaria "id" de la tabla "auth.users".
-- • La columna "updated_by" es una clave foránea que se relaciona con la clave primaria "id" de la tabla "auth.users".

-- Triggers:
CREATE OR REPLACE TRIGGER "trg_audit_personal_social_areas" AFTER INSERT OR DELETE OR UPDATE ON "app"."personal_social_areas" FOR EACH ROW EXECUTE FUNCTION "app"."capture_audit_event"('id', 'false');
CREATE OR REPLACE TRIGGER "trg_manage_audit_columns_personal_social_areas" BEFORE INSERT OR UPDATE ON "app"."personal_social_areas" FOR EACH ROW EXECUTE FUNCTION "util"."handle_audit_columns_trigger_func"();

-- Índices:
CREATE INDEX "idx_personal_social_area_active" ON "app"."personal_social_areas" USING "btree" ("patient_id") WHERE ("is_deleted" = false);


-- 31. Tabla: app.professional_profiles
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS "app"."professional_profiles" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "is_practicing_in_terminal" boolean DEFAULT true NOT NULL,
    "professional_type" character varying(50) NOT NULL,
    "certification_date" "date",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "created_by" "uuid" NOT NULL,
    "updated_at" timestamp with time zone,
    "updated_by" "uuid",
    "is_deleted" boolean DEFAULT false NOT NULL,
    "deleted_at" timestamp with time zone,
    "license_number" "bytea",
    "credentials" "bytea"
);

-- Claves Primarias y Foráneas (Relaciones)
-- Primary Key (PK):
-- • id
-- Foreign Keys (FK):
-- • La columna "user_id" es una clave foránea que se relaciona con la clave primaria "id" de la tabla "app.users".
-- • La columna "created_by" es una clave foránea que se relaciona con la clave primaria "id" de la tabla "auth.users".
-- • La columna "updated_by" es una clave foránea que se relaciona con la clave primaria "id" de la tabla "auth.users".

-- Triggers:
CREATE OR REPLACE TRIGGER "trg_audit_professional_profiles" AFTER INSERT OR DELETE OR UPDATE ON "app"."professional_profiles" FOR EACH ROW EXECUTE FUNCTION "app"."capture_audit_event"('id', 'false');
CREATE OR REPLACE TRIGGER "trg_manage_audit_columns_professional_profiles" BEFORE INSERT OR UPDATE ON "app"."professional_profiles" FOR EACH ROW EXECUTE FUNCTION "util"."handle_audit_columns_trigger_func"();

-- Índices:
CREATE INDEX "idx_professional_profiles_practicing_active" ON "app"."professional_profiles" USING "btree" ("user_id") WHERE (("is_practicing_in_terminal" = true) AND ("is_deleted" = false));
CREATE INDEX "idx_professional_profiles_user_id" ON "app"."professional_profiles" USING "btree" ("user_id");


-- 32. Tabla: app.professional_specializations
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS "app"."professional_specializations" (
    "professional_profile_id" "uuid" NOT NULL,
    "specialization_item_id" "uuid" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone,
    "created_by" "uuid",
    "updated_by" "uuid"
);
COMMENT ON TABLE "app"."professional_specializations" IS 'Tabla de relación M-M entre perfiles profesionales y sus especializaciones (catalog_items).';

-- Claves Primarias y Foráneas (Relaciones)
-- Primary Key (PK):
-- • (professional_profile_id, specialization_item_id) -> Clave primaria compuesta.
-- Foreign Keys (FK):
-- • La columna "professional_profile_id" es una clave foránea que se relaciona con la clave primaria "id" de la tabla "app.professional_profiles".
-- • La columna "specialization_item_id" es una clave foránea que se relaciona con la clave primaria "id" de la tabla "app.catalog_items".
-- • La columna "created_by" es una clave foránea que se relaciona con la clave primaria "id" de la tabla "auth.users".
-- • La columna "updated_by" es una clave foránea que se relaciona con la clave primaria "id" de la tabla "auth.users".

-- Triggers:
CREATE OR REPLACE TRIGGER "trg_audit_professional_specializations" AFTER INSERT OR DELETE OR UPDATE ON "app"."professional_specializations" FOR EACH ROW EXECUTE FUNCTION "app"."capture_audit_event"('professional_profile_id', 'false');
CREATE OR REPLACE TRIGGER "trg_manage_audit_columns_professional_specializations" BEFORE INSERT OR UPDATE ON "app"."professional_specializations" FOR EACH ROW EXECUTE FUNCTION "util"."handle_audit_columns_trigger_func"();

-- Índices:
CREATE INDEX "idx_prof_spec_item" ON "app"."professional_specializations" USING "btree" ("specialization_item_id");


-- 33. Tabla: app.subscription_plans
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS "app"."subscription_plans" (
    "plan_name" character varying(50) NOT NULL,
    "description" "text",
    "price" numeric(10,2) NOT NULL,
    "features" "jsonb",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone,
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "is_deleted" boolean DEFAULT false NOT NULL,
    "deleted_at" timestamp with time zone,
    "created_by" "uuid",
    "updated_by" "uuid"
);
COMMENT ON COLUMN "app"."subscription_plans"."created_by" IS 'Usuario que creó el plan de suscripción.';

-- Claves Primarias y Foráneas (Relaciones)
-- Primary Key (PK):
-- • id
-- Foreign Keys (FK):
-- • La columna "created_by" es una clave foránea que se relaciona con la clave primaria "id" de la tabla "auth.users".
-- • La columna "updated_by" es una clave foránea que se relaciona con la clave primaria "id" de la tabla "auth.users".

-- Triggers:
CREATE OR REPLACE TRIGGER "soft_del_subscription_plans" BEFORE DELETE ON "app"."subscription_plans" FOR EACH ROW EXECUTE FUNCTION "util"."soft_delete_generic"('id');
CREATE OR REPLACE TRIGGER "trg_audit_subscription_plans" AFTER INSERT OR DELETE OR UPDATE ON "app"."subscription_plans" FOR EACH ROW EXECUTE FUNCTION "app"."capture_audit_event"('id', 'false');
CREATE OR REPLACE TRIGGER "trg_manage_audit_columns_subscription_plans" BEFORE INSERT OR UPDATE ON "app"."subscription_plans" FOR EACH ROW EXECUTE FUNCTION "util"."handle_audit_columns_trigger_func"();

-- Índices:
-- (Ninguno)


-- 34. Tabla: app.terminal_emails
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS "app"."terminal_emails" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "terminal_id" "uuid" NOT NULL,
    "email" "public"."citext" NOT NULL,
    "is_primary" boolean DEFAULT false,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "created_by" "uuid" NOT NULL,
    "updated_at" timestamp with time zone NOT NULL,
    "updated_by" "uuid",
    "is_deleted" boolean DEFAULT false NOT NULL,
    "email_type_id" "uuid",
    "deleted_at" timestamp with time zone
);

-- Claves Primarias y Foráneas (Relaciones)
-- Primary Key (PK):
-- • id
-- Foreign Keys (FK):
-- • La columna "terminal_id" es una clave foránea que se relaciona con la clave primaria "id" de la tabla "app.terminals".
-- • La columna "created_by" es una clave foránea que se relaciona con la clave primaria "id" de la tabla "auth.users".
-- • La columna "updated_by" es una clave foránea que se relaciona con la clave primaria "id" de la tabla "auth.users".
-- • La columna "email_type_id" es una clave foránea que se relaciona con la clave primaria "id" de la tabla "app.catalog_items".

-- Triggers:
CREATE OR REPLACE TRIGGER "trg_audit_terminal_emails" AFTER INSERT OR DELETE OR UPDATE ON "app"."terminal_emails" FOR EACH ROW EXECUTE FUNCTION "app"."capture_audit_event"('id', 'false');
CREATE OR REPLACE TRIGGER "trg_manage_audit_columns_terminal_emails" BEFORE INSERT OR UPDATE ON "app"."terminal_emails" FOR EACH ROW EXECUTE FUNCTION "util"."handle_audit_columns_trigger_func"();

-- Índices:
CREATE INDEX "idx_terminal_emails_active" ON "app"."terminal_emails" USING "btree" ("terminal_id") WHERE ("is_deleted" = false);


-- 35. Tabla: app.terminal_phones
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS "app"."terminal_phones" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "terminal_id" "uuid" NOT NULL,
    "phone_number" character varying(20) NOT NULL,
    "is_primary" boolean DEFAULT false,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "created_by" "uuid" NOT NULL,
    "updated_at" timestamp with time zone NOT NULL,
    "updated_by" "uuid",
    "is_deleted" boolean DEFAULT false NOT NULL,
    "phone_type_id" "uuid",
    "deleted_at" timestamp with time zone
);

-- Claves Primarias y Foráneas (Relaciones)
-- Primary Key (PK):
-- • id
-- Foreign Keys (FK):
-- • La columna "terminal_id" es una clave foránea que se relaciona con la clave primaria "id" de la tabla "app.terminals".
-- • La columna "created_by" es una clave foránea que se relaciona con la clave primaria "id" de la tabla "auth.users".
-- • La columna "updated_by" es una clave foránea que se relaciona con la clave primaria "id" de la tabla "auth.users".
-- • La columna "phone_type_id" es una clave foránea que se relaciona con la clave primaria "id" de la tabla "app.catalog_items".

-- Triggers:
CREATE OR REPLACE TRIGGER "trg_audit_terminal_phones" AFTER INSERT OR DELETE OR UPDATE ON "app"."terminal_phones" FOR EACH ROW EXECUTE FUNCTION "app"."capture_audit_event"('id', 'false');
CREATE OR REPLACE TRIGGER "trg_manage_audit_columns_terminal_phones" BEFORE INSERT OR UPDATE ON "app"."terminal_phones" FOR EACH ROW EXECUTE FUNCTION "util"."handle_audit_columns_trigger_func"();

-- Índices:
CREATE INDEX "idx_terminal_phones_active" ON "app"."terminal_phones" USING "btree" ("terminal_id") WHERE ("is_deleted" = false);


-- 36. Tabla: app.terminals
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS "app"."terminals" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "name" character varying(100) NOT NULL,
    "street_address" character varying(200),
    "city_id" "uuid" NOT NULL,
    "province_id" "uuid" NOT NULL,
    "postal_code" character varying(20),
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "created_by" "uuid" NOT NULL,
    "updated_at" timestamp with time zone,
    "updated_by" "uuid",
    "is_deleted" boolean DEFAULT false NOT NULL,
    "subscription_status" "public"."subscription_status_enum" DEFAULT 'inactive'::"public"."subscription_status_enum",
    "subscription_start_date" "date",
    "subscription_end_date" "date",
    "payment_due_date" "date",
    "deleted_at" timestamp with time zone,
    "subscription_plan_id" "uuid",
    CONSTRAINT "chk_subscription_dates" CHECK (("subscription_end_date" > "subscription_start_date"))
);
COMMENT ON TABLE "app"."terminals" IS 'ESTADO: MVP CORE. Representa una clínica o centro de atención. Esencial para multi-tenant.';

-- Claves Primarias y Foráneas (Relaciones)
-- Primary Key (PK):
-- • id
-- Foreign Keys (FK):
-- • La columna "city_id" es una clave foránea que se relaciona con la clave primaria "id" de la tabla "app.administrative_units".
-- • La columna "province_id" es una clave foránea que se relaciona con la clave primaria "id" de la tabla "app.administrative_units".
-- • La columna "created_by" es una clave foránea que se relaciona con la clave primaria "id" de la tabla "auth.users".
-- • La columna "updated_by" es una clave foránea que se relaciona con la clave primaria "id" de la tabla "auth.users".
-- • La columna "subscription_plan_id" es una clave foránea que se relaciona con la clave primaria "id" de la tabla "app.subscription_plans".

-- Triggers:
CREATE OR REPLACE TRIGGER "soft_del_terminals" BEFORE DELETE ON "app"."terminals" FOR EACH ROW EXECUTE FUNCTION "util"."soft_delete_generic"('id');
CREATE OR REPLACE TRIGGER "trg_audit_terminals" AFTER INSERT OR DELETE OR UPDATE ON "app"."terminals" FOR EACH ROW EXECUTE FUNCTION "app"."capture_audit_event"('id', 'false');
CREATE OR REPLACE TRIGGER "trg_manage_audit_columns_terminals" BEFORE INSERT OR UPDATE ON "app"."terminals" FOR EACH ROW EXECUTE FUNCTION "util"."handle_audit_columns_trigger_func"();
CREATE OR REPLACE TRIGGER "trg_terminals_update_subscription_status" BEFORE INSERT OR UPDATE ON "app"."terminals" FOR EACH ROW EXECUTE FUNCTION "util"."update_subscription_status"();

-- Índices:
CREATE INDEX "idx_terminals_active" ON "app"."terminals" USING "btree" ("id") WHERE ("is_deleted" = false);
CREATE INDEX "idx_terminals_subscription_status" ON "app"."terminals" USING "btree" ("subscription_status");


-- 37. Tabla: app.therapy_sessions
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS "app"."therapy_sessions" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "treatment_id" "uuid" NOT NULL,
    "session_date" timestamp with time zone NOT NULL,
    "observations" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "created_by" "uuid" NOT NULL,
    "updated_at" timestamp with time zone,
    "updated_by" "uuid",
    "is_deleted" boolean DEFAULT false NOT NULL,
    "deleted_at" timestamp with time zone,
    "terminal_id" "uuid" NOT NULL,
    "session_summary" "text"
);

-- Claves Primarias y Foráneas (Relaciones)
-- Primary Key (PK):
-- • id
-- Foreign Keys (FK):
-- • La columna "treatment_id" es una clave foránea que se relaciona con la clave primaria "id" de la tabla "app.treatments".
-- • La columna "created_by" es una clave foránea que se relaciona con la clave primaria "id" de la tabla "auth.users".
-- • La columna "updated_by" es una clave foránea que se relaciona con la clave primaria "id" de la tabla "auth.users".
-- • La columna "terminal_id" es una clave foránea que se relaciona con la clave primaria "id" de la tabla "app.terminals".

-- Triggers:
CREATE OR REPLACE TRIGGER "trg_audit_therapy_sessions" AFTER INSERT OR DELETE OR UPDATE ON "app"."therapy_sessions" FOR EACH ROW EXECUTE FUNCTION "app"."capture_audit_event"('id', 'false');
CREATE OR REPLACE TRIGGER "trg_manage_audit_columns_therapy_sessions" BEFORE INSERT OR UPDATE ON "app"."therapy_sessions" FOR EACH ROW EXECUTE FUNCTION "util"."handle_audit_columns_trigger_func"();

-- Índices:
CREATE INDEX "idx_therapy_sessions_active" ON "app"."therapy_sessions" USING "btree" ("treatment_id") WHERE ("is_deleted" = false);
CREATE INDEX "idx_therapy_sessions_observations_gin" ON "app"."therapy_sessions" USING "gin" ("to_tsvector"('"spanish"'::"regconfig", "observations"));


-- 38. Tabla: app.treatments
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS "app"."treatments" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "patient_id" "uuid" NOT NULL,
    "start_date" timestamp with time zone NOT NULL,
    "end_date" timestamp with time zone,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "created_by" "uuid" NOT NULL,
    "updated_at" timestamp with time zone,
    "updated_by" "uuid",
    "is_deleted" boolean DEFAULT false NOT NULL,
    "deleted_at" timestamp with time zone,
    "professional_id" "uuid",
    "terminal_id" "uuid" NOT NULL,
    "intervention_approach" "bytea",
    "therapeutic_plan" "bytea",
    "session_summaries" "bytea",
    CONSTRAINT "chk_treatments_end_date" CHECK ((("end_date" IS NULL) OR ("end_date" >= "start_date")))
);

-- Claves Primarias y Foráneas (Relaciones)
-- Primary Key (PK):
-- • id
-- Foreign Keys (FK):
-- • La columna "patient_id" es una clave foránea que se relaciona con la clave primaria "id" de la tabla "app.patients".
-- • La columna "created_by" es una clave foránea que se relaciona con la clave primaria "id" de la tabla "auth.users".
-- • La columna "updated_by" es una clave foránea que se relaciona con la clave primaria "id" de la tabla "auth.users".
-- • La columna "professional_id" es una clave foránea que se relaciona con la clave primaria "id" de la tabla "app.professional_profiles".
-- • La columna "terminal_id" es una clave foránea que se relaciona con la clave primaria "id" de la tabla "app.terminals".

-- Triggers:
CREATE OR REPLACE TRIGGER "trg_audit_treatments" AFTER INSERT OR DELETE OR UPDATE ON "app"."treatments" FOR EACH ROW EXECUTE FUNCTION "app"."capture_audit_event"('id', 'false');
CREATE OR REPLACE TRIGGER "trg_manage_audit_columns_treatments" BEFORE INSERT OR UPDATE ON "app"."treatments" FOR EACH ROW EXECUTE FUNCTION "util"."handle_audit_columns_trigger_func"();

-- Índices:
CREATE INDEX "idx_treatments_active" ON "app"."treatments" USING "btree" ("patient_id") WHERE ("is_deleted" = false);


-- 39. Tabla: app.user_emails
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS "app"."user_emails" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "is_primary" boolean DEFAULT false NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "created_by" "uuid" NOT NULL,
    "updated_at" timestamp with time zone NOT NULL,
    "updated_by" "uuid",
    "is_deleted" boolean DEFAULT false NOT NULL,
    "email_type_id" "uuid",
    "deleted_at" timestamp with time zone,
    "email" "bytea"
);

-- Claves Primarias y Foráneas (Relaciones)
-- Primary Key (PK):
-- • id
-- Foreign Keys (FK):
-- • La columna "user_id" es una clave foránea que se relaciona con la clave primaria "id" de la tabla "app.users".
-- • La columna "created_by" es una clave foránea que se relaciona con la clave primaria "id" de la tabla "app.users".
-- • La columna "updated_by" es una clave foránea que se relaciona con la clave primaria "id" de la tabla "auth.users".
-- • La columna "email_type_id" es una clave foránea que se relaciona con la clave primaria "id" de la tabla "app.catalog_items".

-- Triggers:
CREATE OR REPLACE TRIGGER "trg_audit_user_emails" AFTER INSERT OR DELETE OR UPDATE ON "app"."user_emails" FOR EACH ROW EXECUTE FUNCTION "app"."capture_audit_event"('id', 'false');
CREATE OR REPLACE TRIGGER "trg_manage_audit_columns_user_emails" BEFORE INSERT OR UPDATE ON "app"."user_emails" FOR EACH ROW EXECUTE FUNCTION "util"."handle_audit_columns_trigger_func"();

-- Índices:
CREATE INDEX "idx_user_emails_active" ON "app"."user_emails" USING "btree" ("user_id") WHERE ("is_deleted" = false);


-- 40. Tabla: app.user_phones
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS "app"."user_phones" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "is_primary" boolean DEFAULT false NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "created_by" "uuid" NOT NULL,
    "updated_at" timestamp with time zone NOT NULL,
    "updated_by" "uuid",
    "is_deleted" boolean DEFAULT false NOT NULL,
    "phone_type_id" "uuid",
    "deleted_at" timestamp with time zone,
    "phone_number" "bytea"
);

-- Claves Primarias y Foráneas (Relaciones)
-- Primary Key (PK):
-- • id
-- Foreign Keys (FK):
-- • La columna "user_id" es una clave foránea que se relaciona con la clave primaria "id" de la tabla "app.users".
-- • La columna "created_by" es una clave foránea que se relaciona con la clave primaria "id" de la tabla "auth.users".
-- • La columna "updated_by" es una clave foránea que se relaciona con la clave primaria "id" de la tabla "auth.users".
-- • La columna "phone_type_id" es una clave foránea que se relaciona con la clave primaria "id" de la tabla "app.catalog_items".

-- Triggers:
CREATE OR REPLACE TRIGGER "trg_audit_user_phones" AFTER INSERT OR DELETE OR UPDATE ON "app"."user_phones" FOR EACH ROW EXECUTE FUNCTION "app"."capture_audit_event"('id', 'false');
CREATE OR REPLACE TRIGGER "trg_manage_audit_columns_user_phones" BEFORE INSERT OR UPDATE ON "app"."user_phones" FOR EACH ROW EXECUTE FUNCTION "util"."handle_audit_columns_trigger_func"();

-- Índices:
CREATE INDEX "idx_user_phones_active" ON "app"."user_phones" USING "btree" ("user_id") WHERE ("is_deleted" = false);


-- 41. Tabla: app.user_sessions
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS "app"."user_sessions" (
    "session_id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "login_time" timestamp with time zone DEFAULT "now"() NOT NULL,
    "logout_time" timestamp with time zone,
    "ip_address" character varying(45),
    "device_info" character varying(200),
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone,
    "is_deleted" boolean DEFAULT false NOT NULL,
    "deleted_at" timestamp with time zone,
    "created_by" "uuid",
    "updated_by" "uuid"
);
COMMENT ON COLUMN "app"."user_sessions"."created_by" IS 'Usuario que creó el registro de sesión (si aplica, podría ser el mismo user_id).';

-- Claves Primarias y Foráneas (Relaciones)
-- Primary Key (PK):
-- • session_id
-- Foreign Keys (FK):
-- • La columna "user_id" es una clave foránea que se relaciona con la clave primaria "id" de la tabla "app.users".
-- • La columna "created_by" es una clave foránea que se relaciona con la clave primaria "id" de la tabla "auth.users".
-- • La columna "updated_by" es una clave foránea que se relaciona con la clave primaria "id" de la tabla "auth.users".

-- Triggers:
CREATE OR REPLACE TRIGGER "soft_del_user_sessions" BEFORE DELETE ON "app"."user_sessions" FOR EACH ROW EXECUTE FUNCTION "util"."soft_delete_generic"('session_id');
CREATE OR REPLACE TRIGGER "trg_audit_user_sessions" AFTER INSERT OR DELETE OR UPDATE ON "app"."user_sessions" FOR EACH ROW EXECUTE FUNCTION "app"."capture_audit_event"('session_id', 'false');
CREATE OR REPLACE TRIGGER "trg_manage_audit_columns_user_sessions" BEFORE INSERT OR UPDATE ON "app"."user_sessions" FOR EACH ROW EXECUTE FUNCTION "util"."handle_audit_columns_trigger_func"();

-- Índices:
CREATE INDEX "idx_user_sessions_user_id" ON "app"."user_sessions" USING "btree" ("user_id");


-- 42. Tabla: app.user_terminal_roles
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS "app"."user_terminal_roles" (
    "user_id" "uuid" NOT NULL,
    "terminal_id" "uuid" NOT NULL,
    "role_id" "uuid",
    "created_at" timestamp with time zone DEFAULT "now"()
);

-- Claves Primarias y Foráneas (Relaciones)
-- Primary Key (PK):
-- • (user_id, terminal_id) -> Clave primaria compuesta.
-- Foreign Keys (FK):
-- • La columna "user_id" es una clave foránea que se relaciona con la clave primaria "id" de la tabla "app.users".
-- • La columna "terminal_id" es una clave foránea que se relaciona con la clave primaria "id" de la tabla "app.terminals".
-- • La columna "role_id" es una clave foránea que se relaciona con la clave primaria "id" de la tabla "app.catalog_items".

-- Triggers:
-- (Ninguno)

-- Índices:
-- (Ninguno)


-- 43. Tabla: app.users
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS "app"."users" (
    "id" "uuid" NOT NULL,
    "terminal_id" "uuid",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "created_by" "uuid" NOT NULL,
    "updated_at" timestamp with time zone,
    "updated_by" "uuid",
    "is_deleted" boolean DEFAULT false NOT NULL,
    "deleted_at" timestamp with time zone,
    "role_id" "uuid" NOT NULL,
    "manager_id" "uuid",
    "first_name" "bytea",
    "last_name" "bytea"
);

-- Claves Primarias y Foráneas (Relaciones)
-- Primary Key (PK):
-- • id
-- Foreign Keys (FK):
-- • La columna "id" es una clave foránea que se relaciona con la clave primaria "id" de la tabla "auth.users".
-- • La columna "terminal_id" es una clave foránea que se relaciona con la clave primaria "id" de la tabla "app.terminals".
-- • La columna "created_by" es una clave foránea que se relaciona con la clave primaria "id" de la tabla "auth.users".
-- • La columna "updated_by" es una clave foránea que se relaciona con la clave primaria "id" de la tabla "auth.users".
-- • La columna "role_id" es una clave foránea que se relaciona con la clave primaria "id" de la tabla "app.catalog_items".
-- • La columna "manager_id" es una clave foránea que se auto-referencia a la clave primaria "id" de la misma tabla "app.users".

-- Triggers:
CREATE OR REPLACE TRIGGER "soft_del_users" BEFORE DELETE ON "app"."users" FOR EACH ROW EXECUTE FUNCTION "util"."soft_delete_generic"('id');
CREATE OR REPLACE TRIGGER "trg_audit_users" AFTER INSERT OR DELETE OR UPDATE ON "app"."users" FOR EACH ROW EXECUTE FUNCTION "app"."capture_audit_event"('id', 'false');
CREATE OR REPLACE TRIGGER "trg_create_professional_profile" AFTER INSERT ON "app"."users" FOR EACH ROW EXECUTE FUNCTION "app"."handle_new_user_profile_creation"();
COMMENT ON TRIGGER "trg_create_professional_profile" ON "app"."users" IS 'Crea automáticamente un perfil profesional para usuarios con roles clínicos/profesionales.';
CREATE OR REPLACE TRIGGER "trg_manage_audit_columns_users" BEFORE INSERT OR UPDATE ON "app"."users" FOR EACH ROW EXECUTE FUNCTION "util"."handle_audit_columns_trigger_func"();

-- Índices:
CREATE INDEX "idx_users_active" ON "app"."users" USING "btree" ("terminal_id") WHERE ("is_deleted" = false);
CREATE INDEX "idx_users_role_id" ON "app"."users" USING "btree" ("role_id");
CREATE INDEX "idx_users_terminal_id" ON "app"."users" USING "btree" ("terminal_id");


-- 44. Tabla: util.catalog_fk_map
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS "util"."catalog_fk_map" (
    "schema_name" "text" NOT NULL,
    "table_name" "text" NOT NULL,
    "column_name" "text" NOT NULL,
    "type_code" "text" NOT NULL
);
COMMENT ON TABLE "util"."catalog_fk_map" IS 'Mapa automático para validar *_item_id → type_code en triggers de integridad.';

-- Claves Primarias y Foráneas (Relaciones)
-- Primary Key (PK):
-- • (schema_name, table_name, column_name) -> Clave primaria compuesta.
-- Foreign Keys (FK):
-- • (Ninguna)

-- Triggers:
-- (Ninguno)

-- Índices:
-- (Ninguno)
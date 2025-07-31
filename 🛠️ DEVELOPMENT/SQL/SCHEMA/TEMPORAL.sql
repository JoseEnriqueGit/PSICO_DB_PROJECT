create table public.administrative_hierarchy_rules (
  country_id uuid null,
  parent_type uuid not null,
  child_type uuid not null,
  id uuid not null default gen_random_uuid (),
  is_deleted boolean not null default false,
  deleted_at timestamp with time zone null,
  constraint administrative_hierarchy_rules_pkey primary key (id)
) TABLESPACE pg_default;

create table public.administrative_units (
  id uuid not null default gen_random_uuid (),
  name character varying(100) not null,
  country_id uuid not null,
  type_id uuid not null,
  parent_id uuid null,
  created_at timestamp with time zone null default timezone ('utc'::text, now()),
  updated_at timestamp with time zone null,
  is_deleted boolean not null default false,
  deleted_at timestamp with time zone null,
  constraint administrative_units_pkey primary key (id),
  constraint unique_admin_unit_name unique (country_id, parent_id, name, type_id),
  constraint administrative_units_country_fkey foreign KEY (country_id) references countries (id),
  constraint administrative_units_parent_fkey foreign KEY (parent_id) references administrative_units (id),
  constraint administrative_units_type_fkey foreign KEY (type_id) references catalog_items (id),
  constraint chk_no_self_reference check ((id <> parent_id))
) TABLESPACE pg_default;

create unique INDEX IF not exists unique_province_name_case_insensitive on public.administrative_units using btree (country_id, type_id, lower((name)::text)) TABLESPACE pg_default
where
  (parent_id is null);

create unique INDEX IF not exists unique_admin_units_case_insensitive on public.administrative_units using btree (
  country_id,
  parent_id,
  type_id,
  lower((name)::text)
) TABLESPACE pg_default
where
  (parent_id is not null);

create trigger trg_normalize_admin_unit_name BEFORE INSERT
or
update on administrative_units for EACH row
execute FUNCTION normalize_admin_unit_name ();

create trigger trg_validate_admin_unit_hierarchy BEFORE INSERT
or
update on administrative_units for EACH row
execute FUNCTION validate_admin_unit_hierarchy ();

create trigger trg_administrative_units_audit_fields BEFORE INSERT
or
update on administrative_units for EACH row
execute FUNCTION handle_audit_fields ();

create trigger trg_administrative_units_audit
after INSERT
or DELETE
or
update on administrative_units for EACH row
execute FUNCTION log_audit_changes ();

create table public.audit_logs (
  audit_id serial not null,
  operation character varying(10) not null,
  table_name character varying(50) not null,
  record_id uuid not null,
  changed_data jsonb not null,
  changed_by uuid not null,
  changed_at timestamp with time zone not null default now(),
  is_deleted boolean not null default false,
  deleted_at timestamp with time zone null,
  constraint audit_logs_pkey primary key (audit_id, changed_at)
)
partition by
  RANGE (changed_at);

create table public.audit_logs_y2025 PARTITION OF public.audit_logs for
values
from
  ('2025-01-01 00:00:00+00') to ('2026-01-01 00:00:00+00') TABLESPACE pg_default;

create unique INDEX IF not exists audit_logs_y2025_pkey on public.audit_logs_y2025 using btree (audit_id, changed_at) TABLESPACE pg_default;

create trigger trg_soft_delete_audit_logs BEFORE DELETE on audit_logs_y2025 for EACH row
execute FUNCTION generic_soft_delete_with_custom_pk ('audit_id');

create table public.catalog_items (
  value text not null,
  description text null,
  created_at timestamp with time zone not null default now(),
  updated_at timestamp with time zone null,
  is_deleted boolean not null default false,
  catalog_type_id uuid null,
  id uuid not null default gen_random_uuid (),
  deleted_at timestamp with time zone null,
  constraint catalog_items_pkey primary key (id),
  constraint catalog_items_catalog_type_id_fkey foreign KEY (catalog_type_id) references catalog_types (id)
) TABLESPACE pg_default;

create index IF not exists idx_catalog_items_active on public.catalog_items using btree (id) TABLESPACE pg_default
where
  (is_deleted = false);

create trigger trg_catalog_items_audit_generic
after INSERT
or DELETE
or
update on catalog_items for EACH row
execute FUNCTION generic_log_audit_changes ();

create trigger trg_catalog_items_audit_fields BEFORE INSERT
or
update on catalog_items for EACH row
execute FUNCTION handle_audit_fields ();

create table public.catalog_types (
  type_code text not null,
  description text null,
  created_at timestamp with time zone not null default now(),
  updated_at timestamp with time zone null,
  id uuid not null default gen_random_uuid (),
  is_deleted boolean not null default false,
  deleted_at timestamp with time zone null,
  constraint catalog_types_pkey primary key (id),
  constraint catalog_types_id_unique unique (id),
  constraint catalog_types_type_code_key unique (type_code)
) TABLESPACE pg_default;

create trigger trg_catalog_types_audit_fields BEFORE INSERT
or
update on catalog_types for EACH row
execute FUNCTION handle_audit_fields ();

create trigger trg_catalog_types_audit
after INSERT
or DELETE
or
update on catalog_types for EACH row
execute FUNCTION log_audit_changes ();

create table public.clinical_histories (
  id uuid not null default gen_random_uuid (),
  patient_id uuid not null,
  consultation_reason text null,
  consultation_history text null,
  mental_exam text null,
  personal_medical_history text null,
  family_medical_history text null,
  created_at timestamp with time zone not null default now(),
  created_by uuid not null,
  updated_at timestamp with time zone null,
  updated_by uuid null,
  is_deleted boolean not null default false,
  deleted_at timestamp with time zone null,
  constraint clinical_history_pkey primary key (id),
  constraint clinical_history_created_by_fkey foreign KEY (created_by) references users (id) on delete CASCADE,
  constraint clinical_history_patient_id_fkey foreign KEY (patient_id) references patients (id) on delete CASCADE,
  constraint clinical_history_updated_by_fkey foreign KEY (updated_by) references users (id) on delete CASCADE
) TABLESPACE pg_default;

create index IF not exists idx_clinical_history_active on public.clinical_histories using btree (patient_id) TABLESPACE pg_default
where
  (is_deleted = false);

create trigger trg_clinical_histories_audit_fields BEFORE INSERT
or
update on clinical_histories for EACH row
execute FUNCTION handle_audit_fields ();

create trigger trg_clinical_histories_audit
after INSERT
or DELETE
or
update on clinical_histories for EACH row
execute FUNCTION log_audit_changes ();

create table public.countries (
  name character varying(100) not null,
  code character varying(10) not null,
  created_at timestamp with time zone null default timezone ('utc'::text, now()),
  updated_at timestamp with time zone null,
  id uuid not null default gen_random_uuid (),
  is_deleted boolean not null default false,
  deleted_at timestamp with time zone null,
  constraint countries_pkey primary key (id),
  constraint countries_code_key unique (code),
  constraint countries_name_key unique (name)
) TABLESPACE pg_default;

create trigger trg_countries_audit_fields BEFORE INSERT
or
update on countries for EACH row
execute FUNCTION handle_audit_fields ();

create trigger trg_countries_audit
after INSERT
or DELETE
or
update on countries for EACH row
execute FUNCTION log_audit_changes ();

create trigger trg_soft_delete_countries BEFORE DELETE on countries for EACH row
execute FUNCTION generic_soft_delete ();

create view public.countries_with_translations as
select
  c.id,
  c.code,
  c.created_at,
  c.updated_at,
  c.is_deleted,
  c.deleted_at,
  c.name as name_en,
  COALESCE(ct.translated_name, c.name::text) as display_name,
  ct.language_code
from
  countries c
  left join country_translations ct on c.id = ct.country_id
where
  c.is_deleted = false;

create table public.country_translations (
  id uuid not null default gen_random_uuid (),
  country_id uuid not null,
  language_code text not null,
  translated_name text not null,
  created_at timestamp with time zone null default now(),
  updated_at timestamp with time zone null,
  constraint country_translations_pkey primary key (id),
  constraint country_translations_country_id_fkey foreign KEY (country_id) references countries (id) on delete CASCADE
) TABLESPACE pg_default;

create table public.current_family_relationships (
  id uuid not null default gen_random_uuid (),
  patient_id uuid not null,
  relationship_quality character varying(50) not null,
  description text null,
  created_at timestamp with time zone not null default now(),
  created_by uuid not null,
  is_deleted boolean not null default false,
  deleted_at timestamp with time zone null,
  constraint current_family_relationships_pkey primary key (id),
  constraint current_family_relationships_created_by_fkey foreign KEY (created_by) references users (id) on delete CASCADE,
  constraint current_family_relationships_patient_id_fkey foreign KEY (patient_id) references patients (id) on delete CASCADE
) TABLESPACE pg_default;

create trigger trg_current_family_relationships_audit_fields BEFORE INSERT
or
update on current_family_relationships for EACH row
execute FUNCTION handle_audit_fields ();

create trigger trg_current_family_relationships_audit
after INSERT
or DELETE
or
update on current_family_relationships for EACH row
execute FUNCTION log_audit_changes ();

create table public.diagnoses (
  id uuid not null default gen_random_uuid (),
  patient_id uuid not null,
  classification_system character varying(50) not null,
  diagnosis_code character varying(20) not null,
  description text null,
  diagnosis_date timestamp with time zone not null,
  created_at timestamp with time zone not null default now(),
  created_by uuid not null,
  updated_at timestamp with time zone null,
  updated_by uuid null,
  is_deleted boolean not null default false,
  deleted_at timestamp with time zone null,
  constraint diagnoses_pkey primary key (id),
  constraint diagnoses_created_by_fkey foreign KEY (created_by) references users (id) on delete CASCADE,
  constraint diagnoses_patient_id_fkey foreign KEY (patient_id) references patients (id) on delete CASCADE,
  constraint diagnoses_updated_by_fkey foreign KEY (updated_by) references users (id) on delete CASCADE
) TABLESPACE pg_default;

create index IF not exists idx_diagnoses_patient_id_not_deleted on public.diagnoses using btree (patient_id) TABLESPACE pg_default
where
  (is_deleted = false);

create index IF not exists idx_diagnoses_active on public.diagnoses using btree (patient_id) TABLESPACE pg_default
where
  (is_deleted = false);

create trigger trg_diagnoses_audit
after INSERT
or DELETE
or
update on diagnoses for EACH row
execute FUNCTION log_audit_changes ();

create trigger trg_diagnoses_audit_fields BEFORE INSERT
or
update on diagnoses for EACH row
execute FUNCTION handle_audit_fields ();

create table public.evaluations (
  id uuid not null default gen_random_uuid (),
  patient_id uuid not null,
  tests_used text null,
  results text null,
  evaluation_date timestamp with time zone not null,
  created_at timestamp with time zone not null default now(),
  created_by uuid not null,
  updated_at timestamp with time zone null,
  updated_by uuid null,
  is_deleted boolean not null default false,
  deleted_at timestamp with time zone null,
  constraint evaluations_pkey primary key (id),
  constraint evaluations_created_by_fkey foreign KEY (created_by) references users (id) on delete CASCADE,
  constraint evaluations_patient_id_fkey foreign KEY (patient_id) references patients (id) on delete CASCADE,
  constraint evaluations_updated_by_fkey foreign KEY (updated_by) references users (id) on delete CASCADE
) TABLESPACE pg_default;

create index IF not exists idx_evaluations_active on public.evaluations using btree (patient_id) TABLESPACE pg_default
where
  (is_deleted = false);

create index IF not exists idx_evaluations_patient_id_is_deleted on public.evaluations using btree (patient_id) TABLESPACE pg_default
where
  (is_deleted = false);

create trigger trg_evaluations_audit_fields BEFORE INSERT
or
update on evaluations for EACH row
execute FUNCTION handle_audit_fields ();

create trigger trg_evaluations_audit
after INSERT
or DELETE
or
update on evaluations for EACH row
execute FUNCTION log_audit_changes ();

create table public.family_communications (
  id uuid not null default gen_random_uuid (),
  patient_id uuid not null,
  communication_quality character varying(50) not null,
  description text null,
  created_at timestamp with time zone not null default now(),
  created_by uuid not null,
  updated_at timestamp with time zone null,
  updated_by uuid null,
  is_deleted boolean not null default false,
  deleted_at timestamp with time zone null,
  constraint family_communications_pkey primary key (id),
  constraint family_communications_created_by_fkey foreign KEY (created_by) references users (id) on delete CASCADE,
  constraint family_communications_patient_id_fkey foreign KEY (patient_id) references patients (id) on delete CASCADE,
  constraint family_communications_updated_by_fkey foreign KEY (updated_by) references users (id) on delete CASCADE
) TABLESPACE pg_default;

create trigger trg_family_communications_audit_fields BEFORE INSERT
or
update on family_communications for EACH row
execute FUNCTION handle_audit_fields ();

create trigger trg_family_communications_audit
after INSERT
or DELETE
or
update on family_communications for EACH row
execute FUNCTION log_audit_changes ();

create table public.family_conflicts (
  id uuid not null default gen_random_uuid (),
  patient_id uuid not null,
  family_member_id uuid not null,
  description text null,
  resolved boolean not null default false,
  created_at timestamp with time zone not null default now(),
  created_by uuid not null,
  updated_at timestamp with time zone null,
  updated_by uuid null,
  is_deleted boolean not null default false,
  conflict_type_id uuid null,
  deleted_at timestamp with time zone null,
  constraint family_conflicts_pkey primary key (id),
  constraint family_conflicts_conflict_type_id_fkey foreign KEY (conflict_type_id) references catalog_items (id),
  constraint family_conflicts_created_by_fkey foreign KEY (created_by) references users (id) on delete CASCADE,
  constraint family_conflicts_family_member_id_fkey foreign KEY (family_member_id) references family_members (id),
  constraint family_conflicts_patient_id_fkey foreign KEY (patient_id) references patients (id) on delete CASCADE,
  constraint family_conflicts_updated_by_fkey foreign KEY (updated_by) references users (id) on delete CASCADE
) TABLESPACE pg_default;

create index IF not exists idx_family_conflicts_patient_id on public.family_conflicts using btree (patient_id) TABLESPACE pg_default;

create index IF not exists idx_family_conflicts_active on public.family_conflicts using btree (patient_id) TABLESPACE pg_default
where
  (is_deleted = false);

create trigger trg_family_conflicts_audit_fields BEFORE INSERT
or
update on family_conflicts for EACH row
execute FUNCTION handle_audit_fields ();

create trigger trg_family_conflicts_audit
after INSERT
or DELETE
or
update on family_conflicts for EACH row
execute FUNCTION log_audit_changes ();

create table public.family_limits (
  id uuid not null default gen_random_uuid (),
  patient_id uuid not null,
  limits_quality character varying(50) not null,
  description text null,
  created_at timestamp with time zone not null default now(),
  created_by uuid not null,
  updated_at timestamp with time zone null,
  updated_by uuid null,
  is_deleted boolean not null default false,
  deleted_at timestamp with time zone null,
  constraint family_limits_pkey primary key (id),
  constraint family_limits_created_by_fkey foreign KEY (created_by) references users (id) on delete CASCADE,
  constraint family_limits_patient_id_fkey foreign KEY (patient_id) references patients (id) on delete CASCADE,
  constraint family_limits_updated_by_fkey foreign KEY (updated_by) references users (id) on delete CASCADE
) TABLESPACE pg_default;

create trigger trg_family_limits_audit_fields BEFORE INSERT
or
update on family_limits for EACH row
execute FUNCTION handle_audit_fields ();

create trigger trg_family_limits_audit
after INSERT
or DELETE
or
update on family_limits for EACH row
execute FUNCTION log_audit_changes ();

create table public.family_members (
  id uuid not null default gen_random_uuid (),
  patient_id uuid not null,
  first_name character varying(100) not null,
  last_name character varying(100) null,
  alive boolean null default true,
  contact character varying(20) null,
  characteristics text null,
  created_at timestamp with time zone not null default now(),
  created_by uuid not null,
  updated_at timestamp with time zone null,
  updated_by uuid null,
  is_deleted boolean not null default false,
  relationship_id uuid null,
  occupation_id uuid null,
  education_level_id uuid null,
  job_status_id uuid null,
  deleted_at timestamp with time zone null,
  constraint family_members_pkey primary key (id),
  constraint family_members_education_level_id_fkey foreign KEY (education_level_id) references catalog_items (id),
  constraint family_members_job_status_id_fkey foreign KEY (job_status_id) references catalog_items (id),
  constraint family_members_occupation_id_fkey foreign KEY (occupation_id) references catalog_items (id),
  constraint family_members_patient_id_fkey foreign KEY (patient_id) references patients (id) on delete CASCADE,
  constraint family_members_relationship_id_fkey foreign KEY (relationship_id) references catalog_items (id),
  constraint family_members_created_by_fkey foreign KEY (created_by) references users (id) on delete CASCADE,
  constraint family_members_updated_by_fkey foreign KEY (updated_by) references users (id) on delete CASCADE
) TABLESPACE pg_default;

create index IF not exists idx_family_members_patient_id on public.family_members using btree (patient_id) TABLESPACE pg_default;

create index IF not exists idx_family_members_active on public.family_members using btree (patient_id) TABLESPACE pg_default
where
  (is_deleted = false);

create trigger trg_family_members_audit_fields BEFORE INSERT
or
update on family_members for EACH row
execute FUNCTION handle_audit_fields ();

create trigger trg_family_members_audit
after INSERT
or DELETE
or
update on family_members for EACH row
execute FUNCTION log_audit_changes ();

create table public.initial_evaluations (
  id uuid not null default gen_random_uuid (),
  patient_id uuid not null,
  responses jsonb not null,
  completion_date timestamp with time zone not null,
  created_at timestamp with time zone not null default now(),
  created_by uuid not null,
  updated_at timestamp with time zone null,
  updated_by uuid null,
  is_deleted boolean not null default false,
  deleted_at timestamp with time zone null,
  constraint initial_evaluations_pkey primary key (id),
  constraint initial_evaluations_created_by_fkey foreign KEY (created_by) references users (id) on delete CASCADE,
  constraint initial_evaluations_patient_id_fkey foreign KEY (patient_id) references patients (id) on delete CASCADE,
  constraint initial_evaluations_updated_by_fkey foreign KEY (updated_by) references users (id) on delete CASCADE
) TABLESPACE pg_default;

create index IF not exists idx_initial_evaluations_active on public.initial_evaluations using btree (patient_id) TABLESPACE pg_default
where
  (is_deleted = false);

create trigger trg_initial_evaluations_audit_fields BEFORE INSERT
or
update on initial_evaluations for EACH row
execute FUNCTION handle_audit_fields ();

create trigger trg_initial_evaluations_audit
after INSERT
or DELETE
or
update on initial_evaluations for EACH row
execute FUNCTION log_audit_changes ();

create table public.love_areas (
  id uuid not null default gen_random_uuid (),
  patient_id uuid not null,
  sexual_activity_onset date null,
  romantic_relationships_duration text null,
  couple_conflicts text null,
  gender_violence boolean null default false,
  sexual_dysfunctions text null,
  created_at timestamp with time zone not null default now(),
  created_by uuid not null,
  updated_at timestamp with time zone null,
  updated_by uuid null,
  is_deleted boolean not null default false,
  deleted_at timestamp with time zone null,
  constraint love_area_pkey primary key (id),
  constraint love_area_created_by_fkey foreign KEY (created_by) references users (id) on delete CASCADE,
  constraint love_area_patient_id_fkey foreign KEY (patient_id) references patients (id) on delete CASCADE,
  constraint love_area_updated_by_fkey foreign KEY (updated_by) references users (id) on delete CASCADE
) TABLESPACE pg_default;

create index IF not exists idx_love_area_active on public.love_areas using btree (patient_id) TABLESPACE pg_default
where
  (is_deleted = false);

create trigger trg_love_areas_audit_fields BEFORE INSERT
or
update on love_areas for EACH row
execute FUNCTION handle_audit_fields ();

create trigger trg_love_areas_audit
after INSERT
or DELETE
or
update on love_areas for EACH row
execute FUNCTION log_audit_changes ();

create table public.nationalities (
  nationality character varying(100) not null,
  created_at timestamp with time zone null default timezone ('utc'::text, now()),
  id uuid not null default gen_random_uuid (),
  country_id uuid null,
  is_deleted boolean not null default false,
  deleted_at timestamp with time zone null,
  constraint nationalities_pkey primary key (id),
  constraint nationalities_nationality_key unique (nationality),
  constraint nationalities_country_id_fkey foreign KEY (country_id) references countries (id)
) TABLESPACE pg_default;

create trigger trg_nationalities_audit_fields BEFORE INSERT
or
update on nationalities for EACH row
execute FUNCTION handle_audit_fields ();

create trigger trg_nationalities_audit
after INSERT
or DELETE
or
update on nationalities for EACH row
execute FUNCTION log_audit_changes ();

create table public.patient_addresses (
  id uuid not null default gen_random_uuid (),
  patient_id uuid not null,
  address_type_id integer not null,
  street_address character varying(200) not null,
  city_id uuid not null,
  province_id uuid not null,
  postal_code character varying(20) null,
  is_primary boolean not null default false,
  created_at timestamp with time zone not null default now(),
  created_by uuid not null,
  updated_at timestamp with time zone null,
  updated_by uuid null,
  is_deleted boolean not null default false,
  deleted_at timestamp with time zone null,
  constraint patient_addresses_pkey primary key (id),
  constraint patient_addresses_city_fkey foreign KEY (city_id) references administrative_units (id),
  constraint patient_addresses_created_by_fkey foreign KEY (created_by) references users (id) on delete CASCADE,
  constraint patient_addresses_patient_id_fkey foreign KEY (patient_id) references patients (id) on delete CASCADE,
  constraint patient_addresses_province_fkey foreign KEY (province_id) references administrative_units (id),
  constraint patient_addresses_updated_by_fkey foreign KEY (updated_by) references users (id) on delete CASCADE
) TABLESPACE pg_default;

create index IF not exists idx_patient_addresses_patient_id_not_deleted on public.patient_addresses using btree (patient_id) TABLESPACE pg_default
where
  (is_deleted = false);

create index IF not exists idx_patient_addresses_active on public.patient_addresses using btree (patient_id) TABLESPACE pg_default
where
  (is_deleted = false);

create index IF not exists idx_patient_addresses_street_address_gin on public.patient_addresses using gin (
  to_tsvector('spanish'::regconfig, (street_address)::text)
) TABLESPACE pg_default;

create trigger trg_patient_addresses_audit_fields BEFORE INSERT
or
update on patient_addresses for EACH row
execute FUNCTION handle_audit_fields ();

create trigger trg_patient_addresses_audit
after INSERT
or DELETE
or
update on patient_addresses for EACH row
execute FUNCTION log_audit_changes ();

create table public.patient_attachment_styles (
  id uuid not null default gen_random_uuid (),
  patient_id uuid not null,
  description text null,
  created_at timestamp with time zone not null default now(),
  created_by uuid not null,
  updated_at timestamp with time zone null,
  updated_by uuid null,
  is_deleted boolean not null default false,
  parenting_style_id uuid null,
  deleted_at timestamp with time zone null,
  assessment_method text null,
  scale_version text null,
  source text null,
  constraint patient_upbringing_styles_pkey primary key (id),
  constraint patient_upbringing_styles_created_by_fkey foreign KEY (created_by) references users (id) on delete CASCADE,
  constraint patient_upbringing_styles_parenting_style_id_fkey foreign KEY (parenting_style_id) references catalog_items (id),
  constraint patient_upbringing_styles_patient_id_fkey foreign KEY (patient_id) references patients (id) on delete CASCADE,
  constraint patient_upbringing_styles_updated_by_fkey foreign KEY (updated_by) references users (id) on delete CASCADE
) TABLESPACE pg_default;

create index IF not exists idx_patient_upbringing_styles_active on public.patient_attachment_styles using btree (patient_id) TABLESPACE pg_default
where
  (is_deleted = false);

create trigger trg_patient_upbringing_styles_audit
after INSERT
or DELETE
or
update on patient_attachment_styles for EACH row
execute FUNCTION log_changes ();

create trigger trg_patient_attachment_styles_audit_fields BEFORE INSERT
or
update on patient_attachment_styles for EACH row
execute FUNCTION handle_audit_fields ();

create trigger trg_patient_attachment_styles_audit
after INSERT
or DELETE
or
update on patient_attachment_styles for EACH row
execute FUNCTION log_audit_changes ();

create table public.patient_attachments (
  id uuid not null default gen_random_uuid (),
  patient_id uuid not null,
  attachment_type_id integer not null,
  description text null,
  created_at timestamp with time zone not null default now(),
  created_by uuid not null,
  updated_at timestamp with time zone null,
  updated_by uuid null,
  is_deleted boolean not null default false,
  deleted_at timestamp with time zone null,
  constraint patient_attachments_pkey primary key (id),
  constraint patient_attachments_patient_id_attachment_type_id_key unique (patient_id, attachment_type_id),
  constraint patient_attachments_created_by_fkey foreign KEY (created_by) references users (id) on delete CASCADE,
  constraint patient_attachments_patient_id_fkey foreign KEY (patient_id) references patients (id) on delete CASCADE,
  constraint patient_attachments_updated_by_fkey foreign KEY (updated_by) references users (id) on delete CASCADE
) TABLESPACE pg_default;

create index IF not exists idx_patient_attachments_active on public.patient_attachments using btree (patient_id) TABLESPACE pg_default
where
  (is_deleted = false);

create trigger trg_patient_attachments_audit
after INSERT
or DELETE
or
update on patient_attachments for EACH row
execute FUNCTION log_audit_changes ();

create trigger trg_patient_attachments_audit_fields BEFORE INSERT
or
update on patient_attachments for EACH row
execute FUNCTION handle_audit_fields ();

create table public.patient_emails (
  id uuid not null default gen_random_uuid (),
  patient_id uuid not null,
  email public.citext not null,
  is_primary boolean not null default false,
  created_at timestamp with time zone not null default now(),
  created_by uuid not null,
  updated_at timestamp with time zone null,
  updated_by uuid null,
  is_deleted boolean not null default false,
  email_type_id uuid null,
  deleted_at timestamp with time zone null,
  constraint patient_emails_pkey primary key (id),
  constraint patient_emails_patient_id_email_key unique (patient_id, email),
  constraint patient_emails_created_by_fkey foreign KEY (created_by) references users (id) on delete CASCADE,
  constraint patient_emails_email_type_id_fkey foreign KEY (email_type_id) references catalog_items (id),
  constraint patient_emails_patient_id_fkey foreign KEY (patient_id) references patients (id) on delete CASCADE,
  constraint patient_emails_updated_by_fkey foreign KEY (updated_by) references users (id) on delete CASCADE
) TABLESPACE pg_default;

create index IF not exists idx_patient_emails_active on public.patient_emails using btree (patient_id) TABLESPACE pg_default
where
  (is_deleted = false);

create trigger trg_patient_emails_audit_fields BEFORE INSERT
or
update on patient_emails for EACH row
execute FUNCTION handle_audit_fields ();

create trigger trg_patient_emails_audit
after INSERT
or DELETE
or
update on patient_emails for EACH row
execute FUNCTION log_audit_changes ();

create table public.patient_emergency_contacts (
  id uuid not null default gen_random_uuid (),
  patient_id uuid not null,
  contact_name character varying(100) not null,
  contact_phone character varying(20) not null,
  priority integer null,
  created_at timestamp with time zone not null default now(),
  created_by uuid not null,
  updated_at timestamp with time zone null,
  updated_by uuid null,
  is_deleted boolean not null default false,
  relationship_id uuid null,
  deleted_at timestamp with time zone null,
  constraint patient_emergency_contacts_pkey primary key (id),
  constraint patient_emergency_contacts_created_by_fkey foreign KEY (created_by) references users (id) on delete CASCADE,
  constraint patient_emergency_contacts_patient_id_fkey foreign KEY (patient_id) references patients (id) on delete CASCADE,
  constraint patient_emergency_contacts_relationship_id_fkey foreign KEY (relationship_id) references catalog_items (id),
  constraint patient_emergency_contacts_updated_by_fkey foreign KEY (updated_by) references users (id) on delete CASCADE
) TABLESPACE pg_default;

create index IF not exists idx_patient_emergency_contacts_patient_id on public.patient_emergency_contacts using btree (patient_id) TABLESPACE pg_default;

create index IF not exists idx_patient_emergency_contacts_active on public.patient_emergency_contacts using btree (patient_id) TABLESPACE pg_default
where
  (is_deleted = false);

create trigger trg_patient_emergency_contacts_audit_fields BEFORE INSERT
or
update on patient_emergency_contacts for EACH row
execute FUNCTION handle_audit_fields ();

create trigger trg_patient_emergency_contacts_audit
after INSERT
or DELETE
or
update on patient_emergency_contacts for EACH row
execute FUNCTION log_audit_changes ();

create table public.patient_parenting_profiles (
  id uuid not null default gen_random_uuid (),
  patient_id uuid not null,
  description text null,
  created_at timestamp with time zone not null default now(),
  created_by uuid not null,
  updated_at timestamp with time zone null,
  updated_by uuid null,
  is_deleted boolean not null default false,
  parenting_style_id uuid null,
  deleted_at timestamp with time zone null,
  assessment_method text null,
  scale_version text null,
  source text null,
  constraint patient_parenting_styles_pkey primary key (id),
  constraint patient_parenting_styles_created_by_fkey foreign KEY (created_by) references users (id) on delete CASCADE,
  constraint patient_parenting_styles_parenting_style_id_fkey foreign KEY (parenting_style_id) references catalog_items (id),
  constraint patient_parenting_styles_patient_id_fkey foreign KEY (patient_id) references patients (id) on delete CASCADE,
  constraint patient_parenting_styles_updated_by_fkey foreign KEY (updated_by) references users (id) on delete CASCADE
) TABLESPACE pg_default;

create index IF not exists idx_patient_parenting_styles_active on public.patient_parenting_profiles using btree (patient_id) TABLESPACE pg_default
where
  (is_deleted = false);

create trigger trg_patient_parenting_styles_audit
after INSERT
or DELETE
or
update on patient_parenting_profiles for EACH row
execute FUNCTION log_changes ();

create trigger trg_patient_parenting_profiles_audit_fields BEFORE INSERT
or
update on patient_parenting_profiles for EACH row
execute FUNCTION handle_audit_fields ();

create trigger trg_patient_parenting_profiles_audit
after INSERT
or DELETE
or
update on patient_parenting_profiles for EACH row
execute FUNCTION log_audit_changes ();

create table public.patient_phones (
  id uuid not null default gen_random_uuid (),
  patient_id uuid not null,
  phone_number character varying(20) not null,
  is_primary boolean not null default false,
  created_at timestamp with time zone not null default now(),
  created_by uuid not null,
  updated_at timestamp with time zone null,
  updated_by uuid null,
  is_deleted boolean not null default false,
  phone_type_id uuid null,
  deleted_at timestamp with time zone null,
  constraint patient_phones_pkey primary key (id),
  constraint patient_phones_patient_id_phone_number_key unique (patient_id, phone_number),
  constraint patient_phones_created_by_fkey foreign KEY (created_by) references users (id) on delete CASCADE,
  constraint patient_phones_patient_id_fkey foreign KEY (patient_id) references patients (id) on delete CASCADE,
  constraint patient_phones_phone_type_id_fkey foreign KEY (phone_type_id) references catalog_items (id),
  constraint patient_phones_updated_by_fkey foreign KEY (updated_by) references users (id) on delete CASCADE
) TABLESPACE pg_default;

create index IF not exists idx_patient_phones_active on public.patient_phones using btree (patient_id) TABLESPACE pg_default
where
  (is_deleted = false);

create trigger trg_patient_phones_audit_fields BEFORE INSERT
or
update on patient_phones for EACH row
execute FUNCTION handle_audit_fields ();

create trigger trg_patient_phones_audit
after INSERT
or DELETE
or
update on patient_phones for EACH row
execute FUNCTION log_audit_changes ();

create table public.patient_referrals (
  id uuid not null default gen_random_uuid (),
  patient_id uuid not null,
  referral_type character varying(20) not null,
  external_source_item_id uuid null,
  from_professional_id uuid null,
  to_professional_id uuid null,
  referral_date timestamp with time zone not null default now(),
  detail text null,
  created_at timestamp with time zone not null default now(),
  created_by uuid not null,
  updated_at timestamp with time zone null,
  updated_by uuid null,
  is_deleted boolean not null default false,
  deleted_at timestamp with time zone null,
  constraint patient_referrals_pkey primary key (id),
  constraint patient_referrals_external_source_fkey foreign KEY (external_source_item_id) references catalog_items (id),
  constraint patient_referrals_from_professional_fkey foreign KEY (from_professional_id) references professional_profiles (id),
  constraint patient_referrals_patient_fkey foreign KEY (patient_id) references patients (id) on delete CASCADE,
  constraint patient_referrals_to_professional_fkey foreign KEY (to_professional_id) references professional_profiles (id),
  constraint chk_referral_type_consistency check (
    (
      (
        ((referral_type)::text = 'external'::text)
        and (external_source_item_id is not null)
        and (from_professional_id is null)
        and (to_professional_id is null)
      )
      or (
        ((referral_type)::text = 'interconsulta'::text)
        and (from_professional_id is not null)
        and (to_professional_id is not null)
        and (external_source_item_id is null)
      )
    )
  )
) TABLESPACE pg_default;

create index IF not exists idx_patient_referrals_patient_id on public.patient_referrals using btree (patient_id) TABLESPACE pg_default;

create index IF not exists idx_patient_referrals_active on public.patient_referrals using btree (patient_id) TABLESPACE pg_default
where
  (is_deleted = false);

create trigger trg_patient_referrals_audit_fields BEFORE INSERT
or
update on patient_referrals for EACH row
execute FUNCTION handle_audit_fields ();

create trigger trg_patient_referrals_audit
after INSERT
or DELETE
or
update on patient_referrals for EACH row
execute FUNCTION log_audit_changes ();

create table public.patient_work_details (
  id uuid not null default gen_random_uuid (),
  patient_id uuid not null,
  work_insertion text null,
  adaptation_discipline text null,
  job_change_unemployment text null,
  job_satisfaction text null,
  successes_failures text null,
  work_conflicts text null,
  created_at timestamp with time zone not null default now(),
  created_by uuid not null,
  updated_at timestamp with time zone null,
  updated_by uuid null,
  is_deleted boolean not null default false,
  job_status_id uuid null,
  occupation_id uuid null,
  deleted_at timestamp with time zone null,
  constraint patient_work_details_pkey primary key (id),
  constraint patient_work_details_created_by_fkey foreign KEY (created_by) references users (id) on delete CASCADE,
  constraint patient_work_details_job_status_id_fkey foreign KEY (job_status_id) references catalog_items (id),
  constraint patient_work_details_occupation_id_fkey foreign KEY (occupation_id) references catalog_items (id),
  constraint patient_work_details_patient_id_fkey foreign KEY (patient_id) references patients (id) on delete CASCADE,
  constraint patient_work_details_updated_by_fkey foreign KEY (updated_by) references users (id) on delete CASCADE
) TABLESPACE pg_default;

create index IF not exists idx_patient_work_details_active on public.patient_work_details using btree (patient_id) TABLESPACE pg_default
where
  (is_deleted = false);

create trigger trg_patient_work_details_audit_fields BEFORE INSERT
or
update on patient_work_details for EACH row
execute FUNCTION handle_audit_fields ();

create trigger trg_patient_work_details_audit
after INSERT
or DELETE
or
update on patient_work_details for EACH row
execute FUNCTION log_audit_changes ();

create table public.patients (
  id uuid not null default gen_random_uuid (),
  registered_by uuid not null,
  first_name character varying(100) not null,
  last_name character varying(100) not null,
  id_number character varying(20) null,
  date_of_birth date not null,
  created_at timestamp with time zone not null default now(),
  created_by uuid not null,
  updated_at timestamp with time zone null,
  updated_by uuid null,
  is_deleted boolean not null default false,
  education_level_item_id uuid null,
  nationality_item_id uuid null,
  health_insurance_item_id uuid null,
  marital_status_item_id uuid null,
  gender_item_id uuid null,
  deleted_at timestamp with time zone null,
  constraint patients_pkey primary key (id),
  constraint patients_id_number_key unique (id_number),
  constraint patients_education_level_item_id_fkey foreign KEY (education_level_item_id) references catalog_items (id),
  constraint patients_gender_item_id_fkey foreign KEY (gender_item_id) references catalog_items (id),
  constraint patients_health_insurance_item_id_fkey foreign KEY (health_insurance_item_id) references catalog_items (id),
  constraint patients_marital_status_item_id_fkey foreign KEY (marital_status_item_id) references catalog_items (id),
  constraint patients_nationality_item_id_fkey foreign KEY (nationality_item_id) references catalog_items (id),
  constraint patients_registered_by_fkey foreign KEY (registered_by) references users (id) on delete CASCADE,
  constraint patients_updated_by_fkey foreign KEY (updated_by) references users (id) on delete CASCADE,
  constraint patients_created_by_fkey foreign KEY (created_by) references users (id) on delete CASCADE,
  constraint chk_patients_id_number_format check (
    (
      (id_number is null)
      or ((id_number)::text ~ '^[0-9]{11}$'::text)
    )
  )
) TABLESPACE pg_default;

create index IF not exists idx_patients_id_number on public.patients using btree (id_number) TABLESPACE pg_default;

create index IF not exists idx_patients_registered_by on public.patients using btree (registered_by) TABLESPACE pg_default;

create index IF not exists idx_patients_active on public.patients using btree (id) TABLESPACE pg_default
where
  (is_deleted = false);

create trigger trg_patients_audit_fields BEFORE INSERT
or
update on patients for EACH row
execute FUNCTION handle_audit_fields ();

create trigger trg_patients_audit
after INSERT
or DELETE
or
update on patients for EACH row
execute FUNCTION log_audit_changes ();

create table public.payments (
  id uuid not null default gen_random_uuid (),
  terminal_id uuid not null,
  amount numeric(10, 2) not null,
  payment_date timestamp with time zone null default now(),
  payment_method character varying(50) null,
  transaction_id character varying(100) null,
  status public.payment_status_enum null default 'completed'::payment_status_enum,
  payment_gateway_response jsonb null,
  receipt_url character varying(200) null,
  created_at timestamp with time zone null default now(),
  updated_at timestamp with time zone null,
  is_deleted boolean not null default false,
  deleted_at timestamp with time zone null,
  constraint payments_pkey primary key (id),
  constraint payments_transaction_id_key unique (transaction_id),
  constraint payments_terminal_id_fkey foreign KEY (terminal_id) references terminals (id),
  constraint chk_payment_amount check ((amount > (0)::numeric))
) TABLESPACE pg_default;

create index IF not exists idx_payments_payment_date on public.payments using btree (payment_date) TABLESPACE pg_default;

create trigger trg_payments_audit
after INSERT
or DELETE
or
update on payments for EACH row
execute FUNCTION log_audit_changes ();

create trigger trg_payments_audit_fields BEFORE INSERT
or
update on payments for EACH row
execute FUNCTION handle_audit_fields ();

create table public.personal_social_areas (
  id uuid not null default gen_random_uuid (),
  patient_id uuid not null,
  self_concept text null,
  self_esteem text null,
  personality_traits text null,
  emotional_state text null,
  needs_interests text null,
  hygiene_habits text null,
  nutrition text null,
  sleep text null,
  sociability text null,
  projects_aspirations text null,
  created_at timestamp with time zone not null default now(),
  created_by uuid not null,
  updated_at timestamp with time zone null,
  updated_by uuid null,
  is_deleted boolean not null default false,
  deleted_at timestamp with time zone null,
  constraint personal_social_area_pkey primary key (id),
  constraint personal_social_area_created_by_fkey foreign KEY (created_by) references users (id) on delete CASCADE,
  constraint personal_social_area_patient_id_fkey foreign KEY (patient_id) references patients (id) on delete CASCADE,
  constraint personal_social_area_updated_by_fkey foreign KEY (updated_by) references users (id) on delete CASCADE
) TABLESPACE pg_default;

create index IF not exists idx_personal_social_area_active on public.personal_social_areas using btree (patient_id) TABLESPACE pg_default
where
  (is_deleted = false);

create trigger trg_personal_social_areas_audit_fields BEFORE INSERT
or
update on personal_social_areas for EACH row
execute FUNCTION handle_audit_fields ();

create trigger trg_personal_social_areas_audit
after INSERT
or DELETE
or
update on personal_social_areas for EACH row
execute FUNCTION log_audit_changes ();

create table public.professional_profiles (
  id uuid not null default gen_random_uuid (),
  user_id uuid not null,
  license_number character varying(50) null,
  specialization character varying(100) null,
  active boolean not null default true,
  professional_type character varying(50) not null,
  certification_date date null,
  credentials jsonb null,
  created_at timestamp with time zone not null default now(),
  created_by uuid not null,
  updated_at timestamp with time zone null,
  updated_by uuid null,
  is_deleted boolean not null default false,
  deleted_at timestamp with time zone null,
  constraint professional_profiles_pkey primary key (id),
  constraint professional_profiles_user_fkey foreign KEY (user_id) references users (id) on delete CASCADE
) TABLESPACE pg_default;

create index IF not exists idx_professional_profiles_user_id on public.professional_profiles using btree (user_id) TABLESPACE pg_default;

create index IF not exists idx_professional_profiles_active on public.professional_profiles using btree (user_id) TABLESPACE pg_default
where
  (is_deleted = false);

create trigger trg_professional_profiles_audit_fields BEFORE INSERT
or
update on professional_profiles for EACH row
execute FUNCTION handle_audit_fields ();

create trigger trg_professional_profiles_audit
after INSERT
or DELETE
or
update on professional_profiles for EACH row
execute FUNCTION log_audit_changes ();

create table public.siblings (
  id uuid not null default gen_random_uuid (),
  family_member_id uuid not null,
  sibling_position integer not null,
  alive boolean null default true,
  contact character varying(20) null,
  occupation_id integer null,
  education_level_id integer null,
  job_status_id integer null,
  characteristics text null,
  created_at timestamp with time zone not null default now(),
  created_by uuid not null,
  updated_at timestamp with time zone null,
  updated_by uuid null,
  is_deleted boolean not null default false,
  deleted_at timestamp with time zone null,
  patient_id uuid not null,
  constraint siblings_pkey primary key (id),
  constraint siblings_created_by_fkey foreign KEY (created_by) references users (id) on delete CASCADE,
  constraint siblings_family_member_id_fkey foreign KEY (family_member_id) references family_members (id),
  constraint siblings_patient_id_fkey foreign KEY (patient_id) references patients (id) on delete CASCADE,
  constraint siblings_updated_by_fkey foreign KEY (updated_by) references users (id) on delete CASCADE
) TABLESPACE pg_default;

create index IF not exists idx_siblings_active on public.siblings using btree (family_member_id) TABLESPACE pg_default
where
  (is_deleted = false);

create trigger trg_validate_siblings_patient_consistency BEFORE INSERT
or
update on siblings for EACH row
execute FUNCTION validate_siblings_patient_consistency ();

create trigger trg_siblings_audit_fields BEFORE INSERT
or
update on siblings for EACH row
execute FUNCTION handle_audit_fields ();

create trigger trg_siblings_audit
after INSERT
or DELETE
or
update on siblings for EACH row
execute FUNCTION log_audit_changes ();

create table public.subscription_plans (
  plan_name character varying(50) not null,
  description text null,
  price numeric(10, 2) not null,
  features jsonb null,
  created_at timestamp with time zone null default now(),
  updated_at timestamp with time zone null,
  id uuid not null default gen_random_uuid (),
  is_deleted boolean not null default false,
  deleted_at timestamp with time zone null,
  constraint subscription_plans_pkey primary key (id),
  constraint subscription_plans_plan_name_key unique (plan_name)
) TABLESPACE pg_default;

create trigger trg_subscription_plans_audit_fields BEFORE INSERT
or
update on subscription_plans for EACH row
execute FUNCTION handle_audit_fields ();

create trigger trg_subscription_plans_audit
after INSERT
or DELETE
or
update on subscription_plans for EACH row
execute FUNCTION log_audit_changes ();

create table public.terminal_emails (
  id uuid not null default gen_random_uuid (),
  terminal_id uuid not null,
  email public.citext not null,
  is_primary boolean null default false,
  created_at timestamp with time zone not null default now(),
  created_by uuid not null,
  updated_at timestamp with time zone not null,
  updated_by uuid not null,
  is_deleted boolean not null default false,
  email_type_id uuid null,
  deleted_at timestamp with time zone null,
  constraint terminal_emails_pkey primary key (id),
  constraint terminal_emails_terminal_id_email_key unique (terminal_id, email),
  constraint terminal_emails_created_by_fkey foreign KEY (created_by) references auth.users (id) on delete CASCADE,
  constraint terminal_emails_email_type_id_fkey foreign KEY (email_type_id) references catalog_items (id),
  constraint terminal_emails_terminal_id_fkey foreign KEY (terminal_id) references terminals (id) on delete CASCADE,
  constraint terminal_emails_updated_by_fkey foreign KEY (updated_by) references auth.users (id) on delete CASCADE
) TABLESPACE pg_default;

create index IF not exists idx_terminal_emails_active on public.terminal_emails using btree (terminal_id) TABLESPACE pg_default
where
  (is_deleted = false);

create trigger trg_terminal_emails_audit_fields BEFORE INSERT
or
update on terminal_emails for EACH row
execute FUNCTION handle_audit_fields ();

create trigger trg_terminal_emails_audit
after INSERT
or DELETE
or
update on terminal_emails for EACH row
execute FUNCTION log_audit_changes ();

create table public.terminal_phones (
  id uuid not null default gen_random_uuid (),
  terminal_id uuid not null,
  phone_number character varying(20) not null,
  is_primary boolean null default false,
  created_at timestamp with time zone not null default now(),
  created_by uuid not null,
  updated_at timestamp with time zone not null,
  updated_by uuid not null,
  is_deleted boolean not null default false,
  phone_type_id uuid null,
  deleted_at timestamp with time zone null,
  constraint terminal_phones_pkey primary key (id),
  constraint terminal_phones_terminal_id_phone_number_key unique (terminal_id, phone_number),
  constraint terminal_phones_created_by_fkey foreign KEY (created_by) references auth.users (id) on delete CASCADE,
  constraint terminal_phones_phone_type_id_fkey foreign KEY (phone_type_id) references catalog_items (id),
  constraint terminal_phones_terminal_id_fkey foreign KEY (terminal_id) references terminals (id) on delete CASCADE,
  constraint terminal_phones_updated_by_fkey foreign KEY (updated_by) references auth.users (id) on delete CASCADE
) TABLESPACE pg_default;

create index IF not exists idx_terminal_phones_active on public.terminal_phones using btree (terminal_id) TABLESPACE pg_default
where
  (is_deleted = false);

create trigger trg_terminal_phones_audit_fields BEFORE INSERT
or
update on terminal_phones for EACH row
execute FUNCTION handle_audit_fields ();

create trigger trg_terminal_phones_audit
after INSERT
or DELETE
or
update on terminal_phones for EACH row
execute FUNCTION log_audit_changes ();

create table public.terminals (
  id uuid not null default gen_random_uuid (),
  name character varying(100) not null,
  street_address character varying(200) null,
  city_id uuid not null,
  province_id uuid not null,
  postal_code character varying(20) null,
  created_at timestamp with time zone not null default now(),
  created_by uuid not null,
  updated_at timestamp with time zone null,
  updated_by uuid null,
  is_deleted boolean not null default false,
  subscription_plan_id integer null,
  subscription_status public.subscription_status_enum null default 'inactive'::subscription_status_enum,
  subscription_start_date date null,
  subscription_end_date date null,
  payment_due_date date null,
  deleted_at timestamp with time zone null,
  constraint terminals_pkey primary key (id),
  constraint terminals_name_key unique (name),
  constraint terminals_created_by_fkey foreign KEY (created_by) references auth.users (id),
  constraint terminals_city_fkey foreign KEY (city_id) references administrative_units (id),
  constraint terminals_province_fkey foreign KEY (province_id) references administrative_units (id),
  constraint terminals_updated_by_fkey foreign KEY (updated_by) references auth.users (id),
  constraint chk_subscription_dates check ((subscription_end_date > subscription_start_date))
) TABLESPACE pg_default;

create index IF not exists idx_terminals_subscription_status on public.terminals using btree (subscription_status) TABLESPACE pg_default;

create index IF not exists idx_terminals_active on public.terminals using btree (id) TABLESPACE pg_default
where
  (is_deleted = false);

create trigger trg_terminals_update_subscription_status BEFORE INSERT
or
update on terminals for EACH row
execute FUNCTION update_subscription_status ();

create trigger trg_terminals_update_updated_at BEFORE
update on terminals for EACH row
execute FUNCTION update_updated_at_column ();

create trigger trg_terminals_audit_fields BEFORE INSERT
or
update on terminals for EACH row
execute FUNCTION handle_audit_fields ();

create trigger trg_terminals_audit
after INSERT
or DELETE
or
update on terminals for EACH row
execute FUNCTION log_audit_changes ();

create table public.therapy_sessions (
  id uuid not null default gen_random_uuid (),
  treatment_id uuid not null,
  session_date timestamp with time zone not null,
  session_summary text null,
  observations text null,
  created_at timestamp with time zone not null default now(),
  created_by uuid not null,
  updated_at timestamp with time zone null,
  updated_by uuid null,
  is_deleted boolean not null default false,
  deleted_at timestamp with time zone null,
  constraint therapy_sessions_pkey primary key (id),
  constraint therapy_sessions_created_by_fkey foreign KEY (created_by) references users (id) on delete CASCADE,
  constraint therapy_sessions_treatment_id_fkey foreign KEY (treatment_id) references treatments (id),
  constraint therapy_sessions_updated_by_fkey foreign KEY (updated_by) references users (id) on delete CASCADE
) TABLESPACE pg_default;

create index IF not exists idx_therapy_sessions_active on public.therapy_sessions using btree (treatment_id) TABLESPACE pg_default
where
  (is_deleted = false);

create index IF not exists idx_therapy_sessions_observations_gin on public.therapy_sessions using gin (to_tsvector('spanish'::regconfig, observations)) TABLESPACE pg_default;

create trigger trg_therapy_sessions_audit_fields BEFORE INSERT
or
update on therapy_sessions for EACH row
execute FUNCTION handle_audit_fields ();

create trigger trg_therapy_sessions_audit
after INSERT
or DELETE
or
update on therapy_sessions for EACH row
execute FUNCTION log_audit_changes ();

create table public.treatments (
  id uuid not null default gen_random_uuid (),
  patient_id uuid not null,
  intervention_approach text null,
  session_summaries text null,
  therapeutic_plan text null,
  start_date timestamp with time zone not null,
  end_date timestamp with time zone null,
  created_at timestamp with time zone not null default now(),
  created_by uuid not null,
  updated_at timestamp with time zone null,
  updated_by uuid null,
  is_deleted boolean not null default false,
  deleted_at timestamp with time zone null,
  professional_id uuid null,
  constraint treatments_pkey primary key (id),
  constraint treatments_created_by_fkey foreign KEY (created_by) references users (id) on delete CASCADE,
  constraint treatments_patient_id_fkey foreign KEY (patient_id) references patients (id) on delete CASCADE,
  constraint treatments_professional_id_fkey foreign KEY (professional_id) references professional_profiles (id),
  constraint treatments_updated_by_fkey foreign KEY (updated_by) references users (id) on delete CASCADE,
  constraint chk_treatments_end_date check (
    (
      (end_date is null)
      or (end_date >= start_date)
    )
  )
) TABLESPACE pg_default;

create index IF not exists idx_treatments_active on public.treatments using btree (patient_id) TABLESPACE pg_default
where
  (is_deleted = false);

create trigger trg_treatments_audit_fields BEFORE INSERT
or
update on treatments for EACH row
execute FUNCTION handle_audit_fields ();

create trigger trg_treatments_audit
after INSERT
or DELETE
or
update on treatments for EACH row
execute FUNCTION log_audit_changes ();

create table public.user_emails (
  id uuid not null default gen_random_uuid (),
  user_id uuid not null,
  email public.citext not null,
  is_primary boolean not null default false,
  created_at timestamp with time zone not null default now(),
  created_by uuid not null,
  updated_at timestamp with time zone not null,
  updated_by uuid not null,
  is_deleted boolean not null default false,
  email_type_id uuid null,
  deleted_at timestamp with time zone null,
  constraint user_emails_pkey primary key (id),
  constraint user_emails_user_id_email_key unique (user_id, email),
  constraint user_emails_created_by_fkey foreign KEY (created_by) references users (id) on delete CASCADE,
  constraint user_emails_email_type_id_fkey foreign KEY (email_type_id) references catalog_items (id),
  constraint user_emails_updated_by_fkey foreign KEY (updated_by) references auth.users (id) on delete CASCADE,
  constraint user_emails_user_id_fkey foreign KEY (user_id) references users (id)
) TABLESPACE pg_default;

create index IF not exists idx_user_emails_active on public.user_emails using btree (user_id) TABLESPACE pg_default
where
  (is_deleted = false);

create trigger trg_user_emails_audit_fields BEFORE INSERT
or
update on user_emails for EACH row
execute FUNCTION handle_audit_fields ();

create trigger trg_user_emails_audit
after INSERT
or DELETE
or
update on user_emails for EACH row
execute FUNCTION log_audit_changes ();

create table public.user_phones (
  id uuid not null default gen_random_uuid (),
  user_id uuid not null,
  phone_number character varying(20) not null,
  is_primary boolean not null default false,
  created_at timestamp with time zone not null default now(),
  created_by uuid not null,
  updated_at timestamp with time zone not null,
  updated_by uuid not null,
  is_deleted boolean not null default false,
  phone_type_id uuid null,
  deleted_at timestamp with time zone null,
  constraint user_phones_pkey primary key (id),
  constraint user_phones_user_id_phone_number_key unique (user_id, phone_number),
  constraint user_phones_created_by_fkey foreign KEY (created_by) references auth.users (id) on delete CASCADE,
  constraint user_phones_phone_type_id_fkey foreign KEY (phone_type_id) references catalog_items (id),
  constraint user_phones_updated_by_fkey foreign KEY (updated_by) references auth.users (id) on delete CASCADE,
  constraint user_phones_user_id_fkey foreign KEY (user_id) references users (id) on delete CASCADE
) TABLESPACE pg_default;

create index IF not exists idx_user_phones_active on public.user_phones using btree (user_id) TABLESPACE pg_default
where
  (is_deleted = false);

create trigger trg_user_phones_audit_fields BEFORE INSERT
or
update on user_phones for EACH row
execute FUNCTION handle_audit_fields ();

create trigger trg_user_phones_audit
after INSERT
or DELETE
or
update on user_phones for EACH row
execute FUNCTION log_audit_changes ();

create table public.user_sessions (
  session_id uuid not null default gen_random_uuid (),
  user_id uuid not null,
  login_time timestamp with time zone not null default now(),
  logout_time timestamp with time zone null,
  ip_address character varying(45) null,
  device_info character varying(200) null,
  created_at timestamp with time zone not null default now(),
  updated_at timestamp with time zone null,
  is_deleted boolean not null default false,
  deleted_at timestamp with time zone null,
  constraint user_sessions_pkey primary key (session_id),
  constraint user_sessions_user_id_fkey foreign KEY (user_id) references users (id) on delete CASCADE
) TABLESPACE pg_default;

create index IF not exists idx_user_sessions_user_id on public.user_sessions using btree (user_id) TABLESPACE pg_default;

create trigger trg_user_sessions_audit_fields BEFORE INSERT
or
update on user_sessions for EACH row
execute FUNCTION handle_audit_fields ();

create trigger trg_user_sessions_audit
after INSERT
or DELETE
or
update on user_sessions for EACH row
execute FUNCTION log_audit_changes ();

create trigger trg_soft_delete_user_sessions BEFORE DELETE on user_sessions for EACH row
execute FUNCTION generic_soft_delete_with_custom_pk ('session_id');

create table public.users (
  id uuid not null,
  terminal_id uuid null,
  first_name character varying(100) not null,
  last_name character varying(100) not null,
  created_at timestamp with time zone not null default now(),
  created_by uuid not null,
  updated_at timestamp with time zone null,
  updated_by uuid null,
  is_deleted boolean not null default false,
  deleted_at timestamp with time zone null,
  email public.citext not null,
  role_id uuid not null,
  manager_id uuid null,
  constraint users_pkey primary key (id),
  constraint users_email_unique unique (email),
  constraint users_id_fkey foreign KEY (id) references auth.users (id) on delete CASCADE,
  constraint users_manager_fkey foreign KEY (manager_id) references users (id),
  constraint users_role_id_fkey foreign KEY (role_id) references catalog_items (id),
  constraint users_terminal_id_fkey foreign KEY (terminal_id) references terminals (id) on delete CASCADE,
  constraint users_updated_by_fkey foreign KEY (updated_by) references auth.users (id) on delete CASCADE,
  constraint users_created_by_fkey foreign KEY (created_by) references auth.users (id) on delete CASCADE,
  constraint chk_email_format check (
    (
      email ~* '^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$'::citext
    )
  )
) TABLESPACE pg_default;

create index IF not exists idx_users_terminal_id on public.users using btree (terminal_id) TABLESPACE pg_default;

create index IF not exists idx_users_active on public.users using btree (terminal_id) TABLESPACE pg_default
where
  (is_deleted = false);

create index IF not exists idx_users_role_id on public.users using btree (role_id) TABLESPACE pg_default;

create index IF not exists idx_users_role_active on public.users using btree (role_id) TABLESPACE pg_default
where
  (is_deleted = false);

create trigger trg_users_audit_fields BEFORE INSERT
or
update on users for EACH row
execute FUNCTION handle_audit_fields ();

create trigger trg_users_audit
after INSERT
or DELETE
or
update on users for EACH row
execute FUNCTION log_audit_changes ();


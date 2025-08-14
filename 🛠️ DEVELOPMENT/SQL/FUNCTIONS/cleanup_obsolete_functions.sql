-- This script removes unused and redundant functions from the database.
-- Version 2: Corrected to not remove functions with RLS dependencies.

-- Redundant/Unused Audit and Partitioning Functions
DROP FUNCTION IF EXISTS public.create_audit_partition_with_indexes(date);
DROP FUNCTION IF EXISTS public.create_monthly_audit_partition(date);

-- Redundant/Unused Profile and User Creation Functions
DROP FUNCTION IF EXISTS public.create_professional_profile();
DROP FUNCTION IF EXISTS public.create_user_in_public(uuid, uuid, character varying, character varying, uuid, citext, uuid, uuid);

-- Redundant/Unused Soft Delete Functions
DROP FUNCTION IF EXISTS public.generic_soft_delete();
DROP FUNCTION IF EXISTS public.generic_soft_delete_with_custom_pk();

-- Unused Helper and Data Retrieval Functions
DROP FUNCTION IF EXISTS public.get_ancestor_of_type(uuid, text);
DROP FUNCTION IF EXISTS public.get_catalog_items(text, text);
DROP FUNCTION IF EXISTS public.get_catalog_items_for_dropdown(character);
DROP FUNCTION IF EXISTS public.get_countries(text);
DROP FUNCTION IF EXISTS public.get_countries_for_dropdown(character);
DROP FUNCTION IF EXISTS public.get_next_available_id();
DROP FUNCTION IF EXISTS public.get_provinces_by_country(uuid);
DROP FUNCTION IF EXISTS public.get_role_id(text);
DROP FUNCTION IF EXISTS public.get_terminal_full_location(uuid);

-- Unused Monitoring and Stats Functions
DROP FUNCTION IF EXISTS public.get_sync_stats();
DROP FUNCTION IF EXISTS public.get_user_creation_stats(integer);
DROP FUNCTION IF EXISTS public.monitor_auth_hook_health();

-- Unused Trigger Functions
DROP FUNCTION IF EXISTS public.normalize_admin_unit_name();

-- Unused Development/Testing Functions
DROP FUNCTION IF EXISTS public.create_terminal_dev(uuid, text, uuid, text, text);

-- Unused Onboarding Functions
DROP FUNCTION IF EXISTS public.get_user_onboarding_status(uuid);
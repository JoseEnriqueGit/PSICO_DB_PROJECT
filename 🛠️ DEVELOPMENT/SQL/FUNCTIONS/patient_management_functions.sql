-- =====================================================
-- PATIENT MANAGEMENT FUNCTIONS
-- Sistema de Registro de Pacientes - 2025-08-13
-- =====================================================

-- Función principal para crear paciente con datos mínimos requeridos
CREATE OR REPLACE FUNCTION public.create_patient(
    p_terminal_id UUID,
    p_first_name TEXT,
    p_last_name TEXT,
    p_id_number TEXT,
    p_date_of_birth DATE,
    p_gender_item_id UUID DEFAULT NULL,
    p_nationality_country_id UUID DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
    v_user_id UUID := auth.uid();
    v_new_patient_id UUID;
    v_encryption_key_id UUID := public.get_encryption_key_id();
BEGIN
    -- Validaciones
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Authentication required' USING ERRCODE = '42501';
    END IF;

    IF p_first_name IS NULL OR trim(p_first_name) = '' THEN
        RAISE EXCEPTION 'First name is required' USING ERRCODE = '23502';
    END IF;
    
    IF p_last_name IS NULL OR trim(p_last_name) = '' THEN
        RAISE EXCEPTION 'Last name is required' USING ERRCODE = '23502';
    END IF;
    
    IF p_id_number IS NULL OR trim(p_id_number) = '' THEN
        RAISE EXCEPTION 'ID number is required' USING ERRCODE = '23502';
    END IF;
    
    IF p_date_of_birth IS NULL THEN
        RAISE EXCEPTION 'Date of birth is required' USING ERRCODE = '23502';
    END IF;

    -- Verificar que el usuario pertenece a la terminal
    IF NOT EXISTS (
        SELECT 1 FROM user_terminal_roles 
        WHERE user_id = v_user_id AND terminal_id = p_terminal_id
    ) THEN
        RAISE EXCEPTION 'Access denied: User not authorized for this terminal' USING ERRCODE = '42501';
    END IF;

    -- Verificar duplicados por ID number en la misma terminal
    IF EXISTS (
        SELECT 1 FROM patients 
        WHERE terminal_id = p_terminal_id 
        AND id_number = pgsodium.crypto_aead_det_encrypt(
            convert_to(p_id_number, 'utf8'), 
            convert_to('patients.id_number', 'utf8'), 
            v_encryption_key_id
        )
        AND is_deleted = false
    ) THEN
        RAISE EXCEPTION 'Patient with this ID number already exists in this terminal' USING ERRCODE = '23505';
    END IF;

    -- Insertar paciente con datos encriptados
    INSERT INTO public.patients (
        terminal_id,
        first_name,
        last_name,
        id_number,
        date_of_birth,
        gender_item_id,
        nationality_country_id,
        registered_by,
        created_by,
        search_hash
    ) VALUES (
        p_terminal_id,
        pgsodium.crypto_aead_det_encrypt(
            convert_to(trim(p_first_name), 'utf8'), 
            convert_to('patients.first_name', 'utf8'), 
            v_encryption_key_id
        ),
        pgsodium.crypto_aead_det_encrypt(
            convert_to(trim(p_last_name), 'utf8'), 
            convert_to('patients.last_name', 'utf8'), 
            v_encryption_key_id
        ),
        pgsodium.crypto_aead_det_encrypt(
            convert_to(trim(p_id_number), 'utf8'), 
            convert_to('patients.id_number', 'utf8'), 
            v_encryption_key_id
        ),
        p_date_of_birth,
        p_gender_item_id,
        p_nationality_country_id,
        v_user_id,
        v_user_id,
        public.generate_search_text(trim(p_first_name), trim(p_last_name), trim(p_id_number))
    )
    RETURNING id INTO v_new_patient_id;

    RETURN v_new_patient_id;
    
EXCEPTION
    WHEN unique_violation THEN
        RAISE EXCEPTION 'Patient data conflict' USING ERRCODE = '23505';
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error creating patient: %', SQLERRM USING ERRCODE = SQLSTATE;
END;
$$;

-- Función para agregar teléfono del paciente
CREATE OR REPLACE FUNCTION public.add_patient_phone(
    p_patient_id UUID,
    p_phone_number TEXT,
    p_phone_type_id UUID DEFAULT NULL,
    p_is_primary BOOLEAN DEFAULT false
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID := auth.uid();
    v_new_phone_id UUID;
    v_encryption_key_id UUID := public.get_encryption_key_id();
BEGIN
    -- Validaciones básicas
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Authentication required';
    END IF;

    -- Si es primary, desmarcar otros
    IF p_is_primary THEN
        UPDATE patient_phones 
        SET is_primary = false 
        WHERE patient_id = p_patient_id AND is_deleted = false;
    END IF;

    -- Insertar teléfono encriptado
    INSERT INTO patient_phones (
        patient_id,
        phone_number,
        phone_type_id,
        is_primary,
        created_by
    ) VALUES (
        p_patient_id,
        pgsodium.crypto_aead_det_encrypt(
            convert_to(trim(p_phone_number), 'utf8'), 
            convert_to('patient_phones.phone_number', 'utf8'), 
            v_encryption_key_id
        ),
        p_phone_type_id,
        p_is_primary,
        v_user_id
    )
    RETURNING id INTO v_new_phone_id;

    RETURN v_new_phone_id;
END;
$$;

-- Función para agregar email del paciente
CREATE OR REPLACE FUNCTION public.add_patient_email(
    p_patient_id UUID,
    p_email TEXT,
    p_email_type_id UUID DEFAULT NULL,
    p_is_primary BOOLEAN DEFAULT false
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID := auth.uid();
    v_new_email_id UUID;
    v_encryption_key_id UUID := public.get_encryption_key_id();
BEGIN
    -- Validaciones básicas
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Authentication required';
    END IF;

    -- Si es primary, desmarcar otros
    IF p_is_primary THEN
        UPDATE patient_emails 
        SET is_primary = false 
        WHERE patient_id = p_patient_id AND is_deleted = false;
    END IF;

    -- Insertar email encriptado
    INSERT INTO patient_emails (
        patient_id,
        email,
        email_type_id,
        is_primary,
        created_by
    ) VALUES (
        p_patient_id,
        pgsodium.crypto_aead_det_encrypt(
            convert_to(trim(p_email), 'utf8'), 
            convert_to('patient_emails.email', 'utf8'), 
            v_encryption_key_id
        ),
        p_email_type_id,
        p_is_primary,
        v_user_id
    )
    RETURNING id INTO v_new_email_id;

    RETURN v_new_email_id;
END;
$$;

-- Función para agregar dirección del paciente
CREATE OR REPLACE FUNCTION public.add_patient_address(
    p_patient_id UUID,
    p_administrative_unit_id UUID,
    p_street_address TEXT DEFAULT NULL,
    p_postal_code TEXT DEFAULT NULL,
    p_address_type_id UUID DEFAULT NULL,
    p_is_primary BOOLEAN DEFAULT false
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID := auth.uid();
    v_new_address_id UUID;
    v_encryption_key_id UUID := public.get_encryption_key_id();
BEGIN
    -- Validaciones básicas
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Authentication required';
    END IF;

    -- Si es primary, desmarcar otros
    IF p_is_primary THEN
        UPDATE patient_addresses 
        SET is_primary = false 
        WHERE patient_id = p_patient_id AND is_deleted = false;
    END IF;

    -- Insertar dirección con datos encriptados
    INSERT INTO patient_addresses (
        patient_id,
        administrative_unit_id,
        street_address,
        postal_code,
        address_type_id,
        is_primary,
        created_by
    ) VALUES (
        p_patient_id,
        p_administrative_unit_id,
        CASE 
            WHEN p_street_address IS NOT NULL AND trim(p_street_address) != '' 
            THEN pgsodium.crypto_aead_det_encrypt(
                convert_to(trim(p_street_address), 'utf8'), 
                convert_to('patient_addresses.street_address', 'utf8'), 
                v_encryption_key_id
            )
            ELSE NULL
        END,
        CASE 
            WHEN p_postal_code IS NOT NULL AND trim(p_postal_code) != '' 
            THEN pgsodium.crypto_aead_det_encrypt(
                convert_to(trim(p_postal_code), 'utf8'), 
                convert_to('patient_addresses.postal_code', 'utf8'), 
                v_encryption_key_id
            )
            ELSE NULL
        END,
        p_address_type_id,
        p_is_primary,
        v_user_id
    )
    RETURNING id INTO v_new_address_id;

    RETURN v_new_address_id;
END;
$$;

-- =====================================================
-- DEPLOYMENT INSTRUCTIONS
-- =====================================================
-- 1. Execute: supabase db push
-- 2. Verify functions are created in public schema
-- 3. Test with Edge Function create-patient
-- 4. Validate encryption and audit trails
-- =====================================================
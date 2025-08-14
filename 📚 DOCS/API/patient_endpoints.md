# Patient Management API Endpoints

## 📡 Overview
Complete API specification for patient management system including Edge Functions and RPC endpoints.

## 🔗 Base URLs
- **Edge Functions**: `https://your-project.supabase.co/functions/v1/`
- **RPC Endpoints**: `https://your-project.supabase.co/rest/v1/rpc/`

## 🔐 Authentication
All endpoints require authentication via Bearer token:
```
Authorization: Bearer <access_token>
```

---

## 📝 Edge Function Endpoints

### POST /functions/v1/create-patient

#### Description
Creates a new patient with optional contact information and address data.

#### Request Headers
```http
Content-Type: application/json
Authorization: Bearer <access_token>
```

#### Request Body
```json
{
  "terminal_id": "uuid",
  "first_name": "string",
  "last_name": "string",
  "id_number": "string",
  "date_of_birth": "YYYY-MM-DD",
  "gender_item_id": "uuid | null",
  "nationality_country_id": "uuid | null",
  "phone": {
    "number": "string",
    "type_id": "uuid | null",
    "is_primary": "boolean"
  },
  "email": {
    "address": "string",
    "type_id": "uuid | null",
    "is_primary": "boolean"
  },
  "address": {
    "administrative_unit_id": "uuid",
    "street_address": "string | null",
    "postal_code": "string | null",
    "type_id": "uuid | null",
    "is_primary": "boolean"
  }
}
```

#### Field Validation Rules
| Field | Type | Required | Validation |
|-------|------|----------|------------|
| `terminal_id` | UUID | ✅ | Must be valid UUID |
| `first_name` | String | ✅ | Min 2 characters, trimmed |
| `last_name` | String | ✅ | Min 2 characters, trimmed |
| `id_number` | String | ✅ | 11 digits for Dominican ID |
| `date_of_birth` | Date | ✅ | YYYY-MM-DD format, not future |
| `gender_item_id` | UUID | ❌ | From GENDER catalog |
| `nationality_country_id` | UUID | ❌ | From countries catalog |
| `phone.number` | String | ❌ | Phone format validation |
| `phone.type_id` | UUID | ❌ | From PHONE_TYPE catalog |
| `email.address` | String | ❌ | Valid email format |
| `email.type_id` | UUID | ❌ | From EMAIL_TYPE catalog |
| `address.administrative_unit_id` | UUID | ❌ | Valid administrative unit |
| `address.street_address` | String | ❌ | Free text |
| `address.postal_code` | String | ❌ | Postal code format |
| `address.type_id` | UUID | ❌ | From ADDRESS_TYPE catalog |

#### Success Response (200 OK)
```json
{
  "success": true,
  "patient_id": "uuid",
  "patient": {
    "id": "uuid",
    "first_name": "string",
    "last_name": "string",
    "id_number": "string",
    "date_of_birth": "YYYY-MM-DD",
    "age": "number",
    "gender": "string",
    "nationality": "string",
    "phones": [
      {
        "id": "uuid",
        "number": "string",
        "type": "string",
        "is_primary": "boolean"
      }
    ],
    "emails": [
      {
        "id": "uuid", 
        "address": "string",
        "type": "string",
        "is_primary": "boolean"
      }
    ],
    "addresses": [
      {
        "id": "uuid",
        "street_address": "string",
        "postal_code": "string",
        "administrative_unit": "string",
        "type": "string",
        "is_primary": "boolean"
      }
    ]
  },
  "message": "Patient created successfully"
}
```

#### Error Responses

**400 Bad Request - Missing Required Fields**
```json
{
  "error": "Required fields: terminal_id, first_name, last_name, id_number, date_of_birth"
}
```

**403 Forbidden - Terminal Access Denied**
```json
{
  "error": "Access denied: User not authorized for this terminal"
}
```

**409 Conflict - Duplicate Patient**
```json
{
  "error": "Patient with this ID number already exists in this terminal"
}
```

**405 Method Not Allowed**
```json
{
  "error": "Method not allowed"
}
```

**500 Internal Server Error**
```json
{
  "error": "Error creating patient: [specific error message]"
}
```

---

## 🗄️ RPC Endpoints

### POST /rest/v1/rpc/create_patient

#### Description
Direct RPC call to create patient record (used internally by Edge Function).

#### Request Body
```json
{
  "p_terminal_id": "uuid",
  "p_first_name": "string",
  "p_last_name": "string",
  "p_id_number": "string",
  "p_date_of_birth": "YYYY-MM-DD",
  "p_gender_item_id": "uuid | null",
  "p_nationality_country_id": "uuid | null"
}
```

#### Response
```json
"uuid" // Patient ID
```

### POST /rest/v1/rpc/add_patient_phone

#### Description
Add phone number to existing patient.

#### Request Body
```json
{
  "p_patient_id": "uuid",
  "p_phone_number": "string",
  "p_phone_type_id": "uuid | null",
  "p_is_primary": "boolean"
}
```

#### Response
```json
"uuid" // Phone record ID
```

### POST /rest/v1/rpc/add_patient_email

#### Description
Add email address to existing patient.

#### Request Body
```json
{
  "p_patient_id": "uuid",
  "p_email": "string",
  "p_email_type_id": "uuid | null",
  "p_is_primary": "boolean"
}
```

#### Response
```json
"uuid" // Email record ID
```

### POST /rest/v1/rpc/add_patient_address

#### Description
Add address to existing patient.

#### Request Body
```json
{
  "p_patient_id": "uuid",
  "p_administrative_unit_id": "uuid",
  "p_street_address": "string | null",
  "p_postal_code": "string | null",
  "p_address_type_id": "uuid | null",
  "p_is_primary": "boolean"
}
```

#### Response
```json
"uuid" // Address record ID
```

### POST /rest/v1/rpc/get_patients

#### Description
Get list of patients for a terminal with optional search.

#### Request Body
```json
{
  "p_terminal_id": "uuid",
  "p_search_term": "string"
}
```

#### Response
```json
[
  {
    "id": "uuid",
    "first_name": "string",
    "last_name": "string",
    "id_number": "string",
    "date_of_birth": "YYYY-MM-DD",
    "age": "number",
    "gender": "string",
    "primary_phone": "string",
    "primary_email": "string"
  }
]
```

### POST /rest/v1/rpc/get_patient_details

#### Description
Get complete patient information including all contact data.

#### Request Body
```json
{
  "p_patient_id": "uuid"
}
```

#### Response
```json
{
  "id": "uuid",
  "first_name": "string",
  "last_name": "string",
  "id_number": "string",
  "date_of_birth": "YYYY-MM-DD",
  "age": "number",
  "gender": "string",
  "nationality": "string",
  "phones": [...],
  "emails": [...],
  "addresses": [...]
}
```

---

## 📊 Status Codes Reference

| Code | Meaning | Description |
|------|---------|-------------|
| 200 | OK | Request successful |
| 400 | Bad Request | Invalid or missing parameters |
| 401 | Unauthorized | Invalid or missing authentication |
| 403 | Forbidden | User lacks permission for terminal |
| 405 | Method Not Allowed | HTTP method not supported |
| 409 | Conflict | Duplicate data (e.g., existing patient) |
| 500 | Internal Server Error | Server-side error |

---

## 🧪 Testing Examples

### cURL Examples

#### Create Patient with Minimal Data
```bash
curl -X POST 'https://your-project.supabase.co/functions/v1/create-patient' \
  -H 'Authorization: Bearer YOUR_TOKEN' \
  -H 'Content-Type: application/json' \
  -d '{
    "terminal_id": "123e4567-e89b-12d3-a456-426614174000",
    "first_name": "Ana",
    "last_name": "García",
    "id_number": "00112345678",
    "date_of_birth": "1990-05-20"
  }'
```

#### Create Patient with Complete Data
```bash
curl -X POST 'https://your-project.supabase.co/functions/v1/create-patient' \
  -H 'Authorization: Bearer YOUR_TOKEN' \
  -H 'Content-Type: application/json' \
  -d '{
    "terminal_id": "123e4567-e89b-12d3-a456-426614174000",
    "first_name": "Carlos",
    "last_name": "Rodríguez",
    "id_number": "00187654321",
    "date_of_birth": "1985-08-15",
    "gender_item_id": "456e7890-e89b-12d3-a456-426614174000",
    "nationality_country_id": "789e1234-e89b-12d3-a456-426614174000",
    "phone": {
      "number": "(809) 555-0123",
      "type_id": "abc12345-e89b-12d3-a456-426614174000",
      "is_primary": true
    },
    "email": {
      "address": "carlos@example.com",
      "type_id": "def67890-e89b-12d3-a456-426614174000",
      "is_primary": true
    },
    "address": {
      "administrative_unit_id": "ghi13579-e89b-12d3-a456-426614174000",
      "street_address": "Calle Principal #123",
      "postal_code": "10001",
      "type_id": "jkl24680-e89b-12d3-a456-426614174000",
      "is_primary": true
    }
  }'
```

### Postman Collection Variables
```json
{
  "base_url": "https://your-project.supabase.co",
  "access_token": "your_access_token_here",
  "terminal_id": "your_terminal_uuid_here"
}
```

---

## 🔗 Related Documentation
- [SQL Functions](../../🛠️%20DEVELOPMENT/SQL/FUNCTIONS/patient_management_functions.sql)
- [Edge Function Implementation](../../🛠️%20DEVELOPMENT/CONFIGS/supabase/create-patient-edge-function.md)
- [Flutter UI Implementation](../FEATURES/FRONTEND/patient_registration_flutter_ui.md)
- [Test Cases](../../🧪%20TESTING/patient_system_test_cases.md)
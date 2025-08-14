# Patient Registration System - Test Cases

## 🎯 Testing Overview
Comprehensive test suite for patient registration system covering frontend validation, backend logic, API endpoints, and security measures.

## 📋 Test Categories

### 1. 🖼️ Frontend Validation Tests

#### 1.1 Required Fields Validation
| Test Case | Input | Expected Result |
|-----------|-------|-----------------|
| **TC-FE-001** | Empty first name | Error: "First name is required" |
| **TC-FE-002** | Empty last name | Error: "Last name is required" |
| **TC-FE-003** | Empty ID number | Error: "ID number is required" |
| **TC-FE-004** | Empty date of birth | Error: "Date of birth is required" |
| **TC-FE-005** | All required fields filled | Form validation passes |

#### 1.2 Format Validation Tests
| Test Case | Input | Expected Result |
|-----------|-------|-----------------|
| **TC-FE-006** | ID: "123" | Error: "ID must be 11 digits" |
| **TC-FE-007** | ID: "00112345678" | Validation passes |
| **TC-FE-008** | Email: "invalid-email" | Error: "Invalid email format" |
| **TC-FE-009** | Email: "user@example.com" | Validation passes |
| **TC-FE-010** | Phone: "invalid" | Error: "Invalid phone format" |
| **TC-FE-011** | Phone: "(809) 555-0123" | Validation passes |

#### 1.3 Date Validation Tests
| Test Case | Input | Expected Result |
|-----------|-------|-----------------|
| **TC-FE-012** | Future date | Error: "Date cannot be in the future" |
| **TC-FE-013** | Date before 1900 | Error: "Invalid date range" |
| **TC-FE-014** | Valid past date | Validation passes + Age calculated |

#### 1.4 Dominican ID Validation
| Test Case | Input | Expected Result |
|-----------|-------|-----------------|
| **TC-FE-015** | "001-1234567-8" | Validation passes (with Luhn algorithm) |
| **TC-FE-016** | "001-1234567-9" | Error: "Invalid Dominican ID" |
| **TC-FE-017** | "12345678901" | Validation passes (11 digits) |
| **TC-FE-018** | "1234567890" | Error: "ID must be 11 digits" |

---

### 2. 🔧 Backend/RPC Function Tests

#### 2.1 Authentication Tests
| Test Case | Input | Expected Result |
|-----------|-------|-----------------|
| **TC-BE-001** | No auth token | SQLSTATE 42501: "Authentication required" |
| **TC-BE-002** | Invalid auth token | SQLSTATE 42501: "Authentication required" |
| **TC-BE-003** | Valid auth token | Function executes |

#### 2.2 Terminal Authorization Tests
| Test Case | Input | Expected Result |
|-----------|-------|-----------------|
| **TC-BE-004** | User not in terminal | SQLSTATE 42501: "Access denied: User not authorized for this terminal" |
| **TC-BE-005** | User belongs to terminal | Function executes |

#### 2.3 Duplicate Detection Tests
| Test Case | Input | Expected Result |
|-----------|-------|-----------------|
| **TC-BE-006** | Existing ID in same terminal | SQLSTATE 23505: "Patient with this ID number already exists in this terminal" |
| **TC-BE-007** | Same ID in different terminal | Patient created successfully |
| **TC-BE-008** | New unique ID | Patient created successfully |

#### 2.4 Data Encryption Tests
| Test Case | Action | Expected Result |
|-----------|--------|-----------------|
| **TC-BE-009** | Insert patient data | first_name, last_name, id_number encrypted in DB |
| **TC-BE-010** | Direct DB query | Encrypted fields show bytea values, not plain text |
| **TC-BE-011** | RPC get_patient_details | Returns decrypted data correctly |

#### 2.5 Audit Trail Tests
| Test Case | Action | Expected Result |
|-----------|--------|-----------------|
| **TC-BE-012** | Create patient | registered_by and created_by populated with auth.uid() |
| **TC-BE-013** | Add phone/email/address | created_by populated with auth.uid() |
| **TC-BE-014** | Check audit_log_entries | Actions logged with user and timestamp |

---

### 3. 🌐 Edge Function API Tests

#### 3.1 Request Validation Tests
| Test Case | Request Body | Expected Response |
|-----------|--------------|-------------------|
| **TC-API-001** | Missing terminal_id | 400: "Required fields: terminal_id, first_name, last_name, id_number, date_of_birth" |
| **TC-API-002** | Missing first_name | 400: "Required fields: terminal_id, first_name, last_name, id_number, date_of_birth" |
| **TC-API-003** | All required fields | 200: Success response |

#### 3.2 HTTP Method Tests
| Test Case | Method | Expected Response |
|-----------|--------|-------------------|
| **TC-API-004** | OPTIONS | 200: CORS headers |
| **TC-API-005** | GET | 405: "Method not allowed" |
| **TC-API-006** | POST | Processes request |
| **TC-API-007** | PUT | 405: "Method not allowed" |

#### 3.3 Complete Flow Tests
| Test Case | Scenario | Expected Result |
|-----------|----------|-----------------|
| **TC-API-008** | Minimal patient data | Patient created with basic info only |
| **TC-API-009** | Patient + phone | Patient and phone record created |
| **TC-API-010** | Patient + email | Patient and email record created |
| **TC-API-011** | Patient + address | Patient and address record created |
| **TC-API-012** | Complete patient data | All records created, patient details returned |

---

### 4. 🔐 Security Tests

#### 4.1 Authentication Security
| Test Case | Scenario | Expected Result |
|-----------|----------|-----------------|
| **TC-SEC-001** | No Authorization header | 401 or function-level auth error |
| **TC-SEC-002** | Expired token | 401 or function-level auth error |
| **TC-SEC-003** | Malformed token | 401 or function-level auth error |

#### 4.2 Multi-tenant Security
| Test Case | Scenario | Expected Result |
|-----------|----------|-----------------|
| **TC-SEC-004** | User A tries to create patient in User B's terminal | Access denied |
| **TC-SEC-005** | User A searches patients in User B's terminal | Empty results or access denied |
| **TC-SEC-006** | User creates patient in own terminal | Success |

#### 4.3 Data Encryption Security
| Test Case | Action | Expected Result |
|-----------|--------|-----------------|
| **TC-SEC-007** | Direct DB access to patient table | Sensitive fields encrypted |
| **TC-SEC-008** | Different encryption keys used | Cannot decrypt with wrong key |
| **TC-SEC-009** | AAD validation | Encryption uses column-specific AAD |

---

### 5. 📊 Performance Tests

#### 5.1 Response Time Tests
| Test Case | Scenario | Target Time | Acceptance Criteria |
|-----------|----------|-------------|-------------------|
| **TC-PERF-001** | Create patient (minimal) | < 2 seconds | 95th percentile |
| **TC-PERF-002** | Create patient (complete) | < 5 seconds | 95th percentile |
| **TC-PERF-003** | Search patients | < 1 second | 95th percentile |

#### 5.2 Concurrent User Tests
| Test Case | Scenario | Expected Result |
|-----------|----------|-----------------|
| **TC-PERF-004** | 10 concurrent patient creations | All succeed without conflicts |
| **TC-PERF-005** | 50 concurrent searches | Response times within limits |

---

### 6. 🔄 Integration Tests

#### 6.1 End-to-End Flow Tests
| Test Case | Flow | Expected Result |
|-----------|------|-----------------|
| **TC-INT-001** | Flutter app → Edge Function → RPC → DB | Complete patient creation |
| **TC-INT-002** | Patient creation → Patient search → Patient details | Data consistency |
| **TC-INT-003** | Primary phone/email/address logic | Only one primary per patient |

#### 6.2 Error Handling Tests
| Test Case | Error Condition | Expected Behavior |
|-----------|-----------------|-------------------|
| **TC-INT-004** | Database connection lost | Graceful error response |
| **TC-INT-005** | Edge Function timeout | Request times out with 500 error |
| **TC-INT-006** | Invalid RPC response | Error logged and user-friendly message |

---

## 🛠️ Test Implementation

### Manual Testing Checklist

#### Frontend Testing
- [ ] **TC-FE-001 to TC-FE-018**: Run through all form validation scenarios
- [ ] **Responsive design**: Test on different screen sizes
- [ ] **Accessibility**: Test with screen readers and keyboard navigation
- [ ] **State management**: Verify loading states and error handling

#### Backend Testing
```sql
-- Test database functions directly
SELECT public.create_patient(
  'terminal-uuid'::UUID,
  'Test',
  'Patient', 
  '00112345678',
  '1990-01-01'::DATE
);

-- Verify encryption
SELECT first_name, last_name, id_number 
FROM public.patients 
WHERE id = 'patient-uuid';
```

#### API Testing with curl
```bash
# Test minimal patient creation
curl -X POST 'https://project.supabase.co/functions/v1/create-patient' \
  -H 'Authorization: Bearer TOKEN' \
  -H 'Content-Type: application/json' \
  -d '{
    "terminal_id": "uuid",
    "first_name": "Test",
    "last_name": "Patient",
    "id_number": "00112345678",
    "date_of_birth": "1990-01-01"
  }'
```

### Automated Testing

#### Unit Tests (Flutter)
```dart
group('Patient Model Tests', () {
  test('should validate Dominican ID correctly', () {
    expect(ValidationHelpers.validateDominicanId('00112345678'), isTrue);
    expect(ValidationHelpers.validateDominicanId('invalid'), isFalse);
  });

  test('should validate email format', () {
    expect(ValidationHelpers.validateEmail('test@example.com'), isNull);
    expect(ValidationHelpers.validateEmail('invalid'), isNotNull);
  });
});
```

#### Integration Tests (Flutter)
```dart
group('Patient Creation Flow', () {
  testWidgets('should create patient with valid data', (tester) async {
    await tester.pumpWidget(CreatePatientScreen());
    
    // Fill form
    await tester.enterText(find.byKey(Key('firstName')), 'Test');
    await tester.enterText(find.byKey(Key('lastName')), 'Patient');
    
    // Tap save
    await tester.tap(find.byKey(Key('saveButton')));
    await tester.pump();
    
    // Verify success
    expect(find.text('Paciente creado exitosamente'), findsOneWidget);
  });
});
```

---

## 📈 Test Metrics

### Coverage Targets
- **Unit Tests**: 90% code coverage
- **Integration Tests**: 80% feature coverage  
- **API Tests**: 100% endpoint coverage
- **Security Tests**: 100% auth scenarios

### Success Criteria
- All critical path tests passing
- No security vulnerabilities
- Performance targets met
- Error handling verified

---

## 🔗 Related Documentation
- [SQL Functions](../🛠️%20DEVELOPMENT/SQL/FUNCTIONS/patient_management_functions.sql)
- [Edge Function](../🛠️%20DEVELOPMENT/CONFIGS/supabase/create-patient-edge-function.md)
- [Flutter UI](../📚%20DOCS/FEATURES/FRONTEND/patient_registration_flutter_ui.md)
- [API Contracts](../📚%20DOCS/API/patient_endpoints.md)
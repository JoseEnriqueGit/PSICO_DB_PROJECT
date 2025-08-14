# Flutter UI: Patient Registration System

## 📱 Descripción General
Sistema completo de registro de pacientes desarrollado en Flutter con Material Design 3, validaciones en tiempo real y integración con Supabase Edge Functions.

## 🏗️ Arquitectura Frontend

### Estructura de Archivos
```
lib/
├── models/
│   └── patient_model.dart
├── services/
│   └── patient_service.dart  
├── screens/
│   ├── patients/
│   │   ├── create_patient_screen.dart
│   │   ├── patient_list_screen.dart
│   │   └── widgets/
│   │       └── patient_form_sections.dart
│   └── dashboard/
│       └── dashboard_screen.dart
└── core/
    ├── navigation/
    │   └── app_router.dart
    └── theme/
        └── app_theme.dart
```

## 📋 Modelos de Datos

### Patient Model
```dart
class Patient {
  final String? id;
  final String firstName;
  final String lastName;
  final String idNumber;
  final DateTime dateOfBirth;
  final String? genderItemId;
  final String? nationalityCountryId;
  final String? educationLevelItemId;
  final String? maritalStatusItemId;
  final String? healthInsuranceItemId;
  final PatientPhone? primaryPhone;
  final PatientEmail? primaryEmail;
  final PatientAddress? primaryAddress;

  Patient({
    this.id,
    required this.firstName,
    required this.lastName,
    required this.idNumber,
    required this.dateOfBirth,
    this.genderItemId,
    this.nationalityCountryId,
    this.educationLevelItemId,
    this.maritalStatusItemId,
    this.healthInsuranceItemId,
    this.primaryPhone,
    this.primaryEmail,
    this.primaryAddress,
  });
}
```

### Contact Models
```dart
class PatientPhone {
  final String number;
  final String? typeId;
  final bool isPrimary;

  PatientPhone({
    required this.number,
    this.typeId,
    this.isPrimary = true,
  });
}

class PatientEmail {
  final String address;
  final String? typeId;
  final bool isPrimary;

  PatientEmail({
    required this.address,
    this.typeId,
    this.isPrimary = true,
  });
}

class PatientAddress {
  final String administrativeUnitId;
  final String? streetAddress;
  final String? postalCode;
  final String? typeId;
  final bool isPrimary;

  PatientAddress({
    required this.administrativeUnitId,
    this.streetAddress,
    this.postalCode,
    this.typeId,
    this.isPrimary = true,
  });
}
```

## 🛠️ Servicios

### PatientService
```dart
class PatientService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<Map<String, dynamic>> createPatient(Map<String, dynamic> patientData) async {
    try {
      final response = await _supabase.functions.invoke(
        'create-patient',
        body: patientData,
      );
      
      if (response.data['success'] == true) {
        return response.data;
      } else {
        throw Exception(response.data['error'] ?? 'Error creating patient');
      }
    } catch (e) {
      throw Exception('Error creating patient: $e');
    }
  }

  Future<List<dynamic>> getPatients(String searchTerm) async {
    try {
      final user = _supabase.auth.currentUser;
      final terminalResponse = await _supabase
          .from('user_terminal_roles')
          .select('terminal_id')
          .eq('user_id', user!.id)
          .single();

      final response = await _supabase.rpc('get_patients', params: {
        'p_terminal_id': terminalResponse['terminal_id'],
        'p_search_term': searchTerm,
      });

      return response as List<dynamic>;
    } catch (e) {
      throw Exception('Error loading patients: $e');
    }
  }

  Future<List<Map<String, dynamic>>> loadCatalogItems(String typeCode) async {
    try {
      // Implementation for catalog loading
      final response = await _supabase
          .from('catalog_items')
          .select('id, name, catalog_item_translations(name)')
          .eq('catalog_type.type_code', typeCode)
          .eq('catalog_item_translations.language_code', 'es');
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Error loading catalog: $e');
    }
  }
}
```

## 🖼️ Pantallas Principales

### CreatePatientScreen
```dart
class CreatePatientScreen extends StatefulWidget {
  @override
  _CreatePatientScreenState createState() => _CreatePatientScreenState();
}

class _CreatePatientScreenState extends State<CreatePatientScreen> {
  final _formKey = GlobalKey<FormState>();
  final _patientService = PatientService();
  bool _isLoading = false;

  // Controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _idNumberController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Registro de Paciente'),
      ),
      body: _isLoading 
        ? Center(child: CircularProgressIndicator())
        : _buildForm(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isFormValid() ? _savePatient : null,
        label: Text('Guardar'),
        icon: Icon(Icons.save),
      ),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _buildPersonalDataSection(),
            SizedBox(height: 16),
            _buildContactSection(),
            SizedBox(height: 16),
            _buildAddressSection(),
          ],
        ),
      ),
    );
  }
}
```

### PatientListScreen
```dart
class PatientListScreen extends StatefulWidget {
  @override
  _PatientListScreenState createState() => _PatientListScreenState();
}

class _PatientListScreenState extends State<PatientListScreen> {
  final _patientService = PatientService();
  List<dynamic> patients = [];
  bool isLoading = true;
  String searchTerm = '';

  @override
  void initState() {
    super.initState();
    _loadPatients();
  }

  Future<void> _loadPatients([String searchTerm = '']) async {
    setState(() => isLoading = true);
    try {
      final result = await _patientService.getPatients(searchTerm);
      setState(() {
        patients = result;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error cargando pacientes: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pacientes'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () => Navigator.pushNamed(context, '/patients/create'),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchField(),
          Expanded(
            child: isLoading
              ? Center(child: CircularProgressIndicator())
              : _buildPatientsList(),
          ),
        ],
      ),
    );
  }
}
```

### DashboardScreen
```dart
class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int todayPatients = 0;
  int todayAppointments = 0;
  int totalPatients = 0;
  double monthlyGrowth = 0.0;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    // Mock data - replace with real API calls
    setState(() {
      todayPatients = 15;
      todayAppointments = 8;
      totalPatients = 245;
      monthlyGrowth = 12.5;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard'),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications),
            onPressed: () {},
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') {
                Supabase.instance.client.auth.signOut();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 'profile', child: Text('Perfil')),
              PopupMenuItem(value: 'settings', child: Text('Configuración')),
              PopupMenuItem(value: 'logout', child: Text('Cerrar Sesión')),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMetricsSection(),
            SizedBox(height: 24),
            _buildQuickActions(),
            SizedBox(height: 24),
            _buildRecentActivity(),
          ],
        ),
      ),
    );
  }
}
```

## 📱 Navegación y Rutas

### AppRouter
```dart
class AppRouter {
  static const String splash = '/';
  static const String login = '/login';
  static const String terminalSetup = '/terminal-setup';
  static const String dashboard = '/dashboard';
  static const String patients = '/patients';
  static const String createPatient = '/patients/create';
  static const String patientDetail = '/patients/:id';
  static const String appointments = '/appointments';
  static const String reports = '/reports';
  static const String settings = '/settings';
  static const String profile = '/profile';
}
```

## ✅ Validaciones y Helpers

### Validation Helpers
```dart
class ValidationHelpers {
  static bool validateDominicanId(String cedula) {
    cedula = cedula.replaceAll('-', '');
    if (cedula.length != 11) return false;
    
    // Algoritmo Luhn modificado para cédula dominicana
    int sum = 0;
    for (int i = 0; i < 10; i++) {
      int digit = int.parse(cedula[i]);
      if (i % 2 == 0) {
        digit *= 2;
        if (digit > 9) digit -= 9;
      }
      sum += digit;
    }
    
    int checkDigit = (10 - (sum % 10)) % 10;
    return checkDigit == int.parse(cedula[10]);
  }

  static bool validateMinimumAge(DateTime birthDate) {
    final age = DateTime.now().difference(birthDate).inDays ~/ 365;
    return age >= 0;
  }

  static String? validateEmail(String? email) {
    if (email == null || email.isEmpty) return null;
    
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email) ? null : 'Email inválido';
  }
}
```

## 🎨 Theming

### AppTheme
```dart
class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: Brightness.light,
      ),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
      ),
      cardTheme: CardTheme(
        elevation: 2,
        margin: EdgeInsets.symmetric(vertical: 8),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
      ),
    );
  }
}
```

## 🔄 Flujo de Guardado

### Proceso de Creación de Paciente
1. **Validación del formulario** → `_formKey.currentState!.validate()`
2. **Obtener terminal_id** → Query a `user_terminal_roles`
3. **Construir payload** → Combinar datos requeridos y opcionales
4. **Llamar Edge Function** → `create-patient` endpoint
5. **Manejo de respuesta** → Success/Error con SnackBar
6. **Navegación** → Reset form o regresar con resultado

```dart
Future<void> _savePatient() async {
  if (!_formKey.currentState!.validate()) return;

  setState(() => _isLoading = true);

  try {
    // Get terminal_id
    final user = Supabase.instance.client.auth.currentUser;
    final terminalResponse = await Supabase.instance.client
        .from('user_terminal_roles')
        .select('terminal_id')
        .eq('user_id', user!.id)
        .single();

    // Build patient data
    final patientData = {
      'terminal_id': terminalResponse['terminal_id'],
      'first_name': _firstNameController.text.trim(),
      'last_name': _lastNameController.text.trim(),
      'id_number': _idNumberController.text.replaceAll('-', ''),
      'date_of_birth': _selectedDate?.toIso8601String().split('T')[0],
      if (_phoneController.text.isNotEmpty)
        'phone': {
          'number': _phoneController.text,
          'is_primary': true,
        },
      if (_emailController.text.isNotEmpty)
        'email': {
          'address': _emailController.text,
          'is_primary': true,
        },
    };

    final result = await _patientService.createPatient(patientData);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Paciente creado exitosamente'),
        backgroundColor: Colors.green,
      ),
    );

    Navigator.pop(context, result['patient_id']);

  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error: $e'),
        backgroundColor: Colors.red,
      ),
    );
  } finally {
    setState(() => _isLoading = false);
  }
}
```

## 📚 Referencias
- [Funciones SQL](../../../🛠️%20DEVELOPMENT/SQL/FUNCTIONS/patient_management_functions.sql)
- [Edge Function Documentation](../../../🛠️%20DEVELOPMENT/CONFIGS/supabase/create-patient-edge-function.md)
- [API Contracts](../../API/patient_endpoints.md)
- [Test Cases](../../../🧪%20TESTING/patient_system_test_cases.md)
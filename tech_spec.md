# Story #1: Project Setup & Basic Navigation
## Technical Implementation Guide

### **Story Overview**
**Epic**: Foundation  
**Story Points**: 5  
**Priority**: P0 (Critical - MVP Foundation)

**User Story**: As a developer, I want to set up the basic project structure and navigation so that I can build features incrementally.

---

## **1. Prerequisites & Environment Setup**

### **1.1 Development Environment Requirements**
- **Flutter SDK**: Latest stable version (3.16.0 or higher)
- **IDE**: Visual Studio Code with Flutter/Dart extensions OR Android Studio
- **Platform SDKs**:
  - Android SDK (API level 21+ for minimum Android 5.0 support)
  - iOS SDK (Xcode 14+ for iOS 12+ support)
- **Device Testing**: Physical devices or simulators for both platforms

### **1.2 Required Dependencies**
Add these to `pubspec.yaml`:
```yaml
dependencies:
  flutter:
    sdk: flutter
  sqflite: ^2.3.0           # SQLite database
  path: ^1.8.3              # Path manipulation
  intl: ^0.18.1             # Internationalization
  
dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0
```

---

## **2. Project Structure Setup**

### **2.1 Recommended Folder Structure**
```
lib/
├── main.dart                    # App entry point
├── models/                      # Data models
│   ├── employee.dart
│   ├── attendance.dart
│   └── payment.dart
├── services/                    # Business logic & database
│   ├── database_service.dart
│   ├── employee_service.dart
│   ├── attendance_service.dart
│   └── payment_service.dart
├── screens/                     # UI screens
│   ├── home/
│   │   └── home_screen.dart
│   ├── attendance/
│   │   └── attendance_screen.dart
│   ├── employees/
│   │   └── employees_screen.dart
│   ├── reports/
│   │   └── reports_screen.dart
│   └── settings/
│       └── settings_screen.dart
├── widgets/                     # Reusable UI components
│   ├── common/
│   └── custom/
└── utils/                       # Utilities & constants
    ├── constants.dart
    └── helpers.dart
```

### **2.2 Create Project Command**
```bash
flutter create household_staff_app
cd household_staff_app
```

---

## **3. Database Service Implementation**

### **3.1 Database Service Class**
Create `lib/services/database_service.dart`:

```dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseService {
  static Database? _database;
  static const String _databaseName = 'household_staff.db';
  static const int _databaseVersion = 1;
  
  // Singleton pattern
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();
  
  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }
  
  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), _databaseName);
    
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _createTables,
      onUpgrade: _onUpgrade,
    );
  }
  
  Future<void> _createTables(Database db, int version) async {
    // Employees table
    await db.execute('''
      CREATE TABLE employees (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        age INTEGER NOT NULL,
        phone TEXT NOT NULL,
        email TEXT,
        monthly_salary REAL NOT NULL,
        visits_per_day INTEGER NOT NULL CHECK (visits_per_day IN (1, 2)),
        off_days TEXT,
        created_date TEXT NOT NULL,
        active_status INTEGER DEFAULT 1
      )
    ''');
    
    // Attendance table
    await db.execute('''
      CREATE TABLE attendance (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        employee_id INTEGER NOT NULL,
        date TEXT NOT NULL,
        shift_type TEXT NOT NULL CHECK (shift_type IN ('morning', 'evening', 'full_day')),
        status TEXT NOT NULL CHECK (status IN ('present', 'absent', 'half_day')),
        check_in_time TEXT,
        check_out_time TEXT,
        comments TEXT,
        marked_date TEXT NOT NULL,
        is_corrected INTEGER DEFAULT 0,
        FOREIGN KEY (employee_id) REFERENCES employees (id),
        UNIQUE(employee_id, date, shift_type)
      )
    ''');
    
    // Payments table
    await db.execute('''
      CREATE TABLE payments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        employee_id INTEGER NOT NULL,
        amount REAL NOT NULL,
        payment_type TEXT NOT NULL CHECK (payment_type IN ('salary', 'advance')),
        payment_date TEXT NOT NULL,
        payment_method TEXT NOT NULL,
        notes TEXT,
        created_date TEXT NOT NULL,
        FOREIGN KEY (employee_id) REFERENCES employees (id)
      )
    ''');
  }
  
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle database migrations here in future versions
  }
  
  // Test database connection
  Future<bool> testConnection() async {
    try {
      final db = await database;
      await db.rawQuery('SELECT 1');
      return true;
    } catch (e) {
      print('Database connection test failed: $e');
      return false;
    }
  }
  
  // Close database connection
  Future<void> closeDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
```

---

## **4. Main App Structure**

### **4.1 Main Application Entry Point**
Create/update `lib/main.dart`:

```dart
import 'package:flutter/material.dart';
import 'services/database_service.dart';
import 'screens/home/home_screen.dart';
import 'screens/attendance/attendance_screen.dart';
import 'screens/employees/employees_screen.dart';
import 'screens/reports/reports_screen.dart';
import 'screens/settings/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize database
  final dbService = DatabaseService();
  await dbService.database; // This triggers database creation
  
  runApp(const HouseholdStaffApp());
}

class HouseholdStaffApp extends StatelessWidget {
  const HouseholdStaffApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Household Staff Manager',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          elevation: 2,
        ),
        cardTheme: CardTheme(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      home: const MainNavigationScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({Key? key}) : super(key: key);

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  
  final List<Widget> _screens = [
    const HomeScreen(),
    const AttendanceScreen(),
    const EmployeesScreen(),
    const ReportsScreen(),
    const SettingsScreen(),
  ];
  
  final List<BottomNavigationBarItem> _navigationItems = [
    const BottomNavigationBarItem(
      icon: Icon(Icons.home),
      label: 'Home',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.check_circle),
      label: 'Attendance',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.people),
      label: 'Employees',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.assessment),
      label: 'Reports',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.settings),
      label: 'Settings',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: _navigationItems,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
      ),
    );
  }
}
```

---

## **5. Screen Implementations**

### **5.1 Base Screen Template**
Create a base template that all screens will follow. Here's the Home Screen example:

```dart
// lib/screens/home/home_screen.dart
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  void _loadData() async {
    // TODO: Load dashboard data in future stories
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        automaticallyImplyLeading: false,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.home,
              size: 100,
              color: Colors.grey,
            ),
            SizedBox(height: 20),
            Text(
              'Home Screen',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Dashboard functionality will be implemented here',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
```

### **5.2 Other Screen Placeholders**
Create similar placeholder screens for:

**Attendance Screen** (`lib/screens/attendance/attendance_screen.dart`):
```dart
import 'package:flutter/material.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({Key? key}) : super(key: key);

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance'),
        automaticallyImplyLeading: false,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle,
              size: 100,
              color: Colors.grey,
            ),
            SizedBox(height: 20),
            Text(
              'Attendance Screen',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Attendance marking functionality will be implemented here',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
```

**Follow similar pattern for**:
- `employees_screen.dart` (Icon: `Icons.people`)
- `reports_screen.dart` (Icon: `Icons.assessment`)
- `settings_screen.dart` (Icon: `Icons.settings`)

---

## **6. Constants and Utilities**

### **6.1 Constants File**
Create `lib/utils/constants.dart`:

```dart
class AppConstants {
  // Database constants
  static const String databaseName = 'household_staff.db';
  static const int databaseVersion = 1;
  
  // Table names
  static const String employeesTable = 'employees';
  static const String attendanceTable = 'attendance';
  static const String paymentsTable = 'payments';
  
  // App configuration
  static const int correctionWindowDays = 2;
  static const int morningCutoffHour = 11;
  static const int morningCutoffMinute = 50;
  static const int eveningStartHour = 15;
  
  // UI constants
  static const double defaultPadding = 16.0;
  static const double cardElevation = 4.0;
  static const double borderRadius = 12.0;
  
  // Colors
  static const primaryColor = Color(0xFF2196F3);
  static const accentColor = Color(0xFF03DAC6);
  static const errorColor = Color(0xFFB00020);
  
  // Validation
  static const int maxNameLength = 50;
  static const int minAge = 18;
  static const int maxAge = 70;
}

enum ShiftType { morning, evening, fullDay }
enum AttendanceStatus { present, absent, halfDay }
enum PaymentType { salary, advance }
```

---

## **7. Testing Implementation**

### **7.1 Database Connection Test**
Create `test/database_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:household_staff_app/services/database_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    // Initialize FFI for desktop testing
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });
  
  group('Database Service Tests', () {
    late DatabaseService dbService;
    
    setUp(() {
      dbService = DatabaseService();
    });
    
    tearDown(() async {
      await dbService.closeDatabase();
    });
    
    test('Database connection should be established', () async {
      final isConnected = await dbService.testConnection();
      expect(isConnected, true);
    });
    
    test('Database should have required tables', () async {
      final db = await dbService.database;
      
      // Check if tables exist
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table'"
      );
      
      final tableNames = tables.map((table) => table['name']).toList();
      
      expect(tableNames, contains('employees'));
      expect(tableNames, contains('attendance'));
      expect(tableNames, contains('payments'));
    });
  });
}
```

### **7.2 Navigation Test**
Create `test/widget_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:household_staff_app/main.dart';

void main() {
  group('Navigation Tests', () {
    testWidgets('Bottom navigation should display all tabs', (WidgetTester tester) async {
      await tester.pumpWidget(const HouseholdStaffApp());
      
      // Verify all navigation items are present
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Attendance'), findsOneWidget);
      expect(find.text('Employees'), findsOneWidget);
      expect(find.text('Reports'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
    });
    
    testWidgets('Tab navigation should work correctly', (WidgetTester tester) async {
      await tester.pumpWidget(const HouseholdStaffApp());
      
      // Tap on Attendance tab
      await tester.tap(find.text('Attendance'));
      await tester.pumpAndSettle();
      
      // Verify Attendance screen is displayed
      expect(find.text('Attendance Screen'), findsOneWidget);
      
      // Tap on Employees tab
      await tester.tap(find.text('Employees'));
      await tester.pumpAndSettle();
      
      // Verify Employees screen is displayed
      expect(find.text('Employees Screen'), findsOneWidget);
    });
  });
}
```

---

## **8. Build and Run Instructions**

### **8.1 Development Build Commands**
```bash
# Get dependencies
flutter pub get

# Run on iOS simulator
flutter run -d ios

# Run on Android emulator
flutter run -d android

# Run tests
flutter test

# Analyze code
flutter analyze
```

### **8.2 Build for Release**
```bash
# Android APK
flutter build apk --release

# iOS (requires Mac and Xcode)
flutter build ios --release
```

---

## **9. Code Review Checklist**

### **9.1 Functionality Checklist**
- [ ] All 5 tabs are visible in bottom navigation
- [ ] Each tab navigates to correct screen
- [ ] Database connection establishes successfully
- [ ] All tables are created correctly
- [ ] App builds without errors on both platforms
- [ ] No crashes during navigation

### **9.2 Code Quality Checklist**
- [ ] Follows Flutter/Dart naming conventions
- [ ] Proper error handling implemented
- [ ] Comments added for complex logic
- [ ] No hardcoded strings (use constants)
- [ ] Responsive design principles followed
- [ ] Memory leaks prevented (proper disposal)

### **9.3 Performance Checklist**
- [ ] App starts within 3 seconds
- [ ] Navigation is smooth (no lag)
- [ ] Database operations are asynchronous
- [ ] No unnecessary widget rebuilds
- [ ] Proper use of const constructors

---

## **10. Acceptance Criteria Verification**

✅ **Cross-platform project created**: Flutter project supports both iOS and Android  
✅ **Basic tab navigation implemented**: 5 tabs with BottomNavigationBar  
✅ **Placeholder screens**: Each tab shows screen with correct name  
✅ **Builds on both platforms**: Commands provided for both iOS and Android  
✅ **SQLite integration**: DatabaseService class with proper setup  
✅ **Folder structure**: Organized structure following Flutter best practices  

---

## **11. Handoff Notes**

### **11.1 Next Story Dependencies**
- Database service is ready for Story #2 (Database Schema & Models)
- Navigation structure supports Story #3 (Employee Registration Form)
- Constants file prepared for business rule implementation

### **11.2 Known Technical Debt**
- Error handling can be enhanced in future iterations
- Offline capability needs testing with large datasets
- Performance optimization needed for production use

### **11.3 Development Team Notes**
- Use the established folder structure for consistency
- Follow the database service pattern for all data operations
- Maintain the Material Design theme across all screens
- Test on both platforms before marking any story complete

---

## **12. Troubleshooting Guide**

### **12.1 Common Issues**

**Database Connection Fails**:
```dart
// Add this debug code to check database path
print('Database path: ${await getDatabasesPath()}');
```

**Navigation Not Working**:
- Ensure all screen widgets are properly imported
- Check that IndexedStack contains all screens
- Verify BottomNavigationBar items count matches screens count

**Build Errors**:
- Run `flutter clean && flutter pub get`
- Check that all dependencies are compatible
- Verify Flutter SDK version compatibility

### **12.2 Platform-Specific Issues**

**iOS Issues**:
- Ensure iOS deployment target is set correctly in `ios/Runner.xcworkspace`
- Check signing configuration in Xcode

**Android Issues**:
- Verify minimum SDK version in `android/app/build.gradle`
- Check that target SDK is up to date
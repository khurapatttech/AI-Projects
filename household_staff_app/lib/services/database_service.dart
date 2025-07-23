import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/employee.dart';
import '../models/attendance.dart';
import '../models/payment.dart';

class DatabaseService {
  static Database? _database;
  static const String _databaseName = 'household_staff.db';
  static const int _databaseVersion = 6; // Incremented to 5 for enhanced payment system

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
    print('Database path: ' + path); // Debug print for actual DB location
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
        partial_off_days TEXT DEFAULT '{}',
        created_date TEXT NOT NULL,
        joining_date TEXT NOT NULL,
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
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
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
        payment_type TEXT NOT NULL CHECK (payment_type IN ('salary', 'advance', 'remaining', 'bonus')),
        payment_date TEXT NOT NULL,
        payment_method TEXT NOT NULL,
        notes TEXT,
        created_date TEXT NOT NULL,
        month_year TEXT,
        is_advance_payment INTEGER DEFAULT 0,
        remaining_amount REAL,
        FOREIGN KEY (employee_id) REFERENCES employees (id)
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Check if columns already exist before adding
      final columns = await db.rawQuery("PRAGMA table_info(attendance);");
      final columnNames = columns.map((c) => c['name']).toSet();
      if (!columnNames.contains('created_at')) {
        await db.execute('ALTER TABLE attendance ADD COLUMN created_at TEXT;');
      }
      if (!columnNames.contains('updated_at')) {
        await db.execute('ALTER TABLE attendance ADD COLUMN updated_at TEXT;');
      }
    }
    
    if (oldVersion < 3) {
      // Add joining_date column to employees table
      final employeeColumns = await db.rawQuery("PRAGMA table_info(employees);");
      final employeeColumnNames = employeeColumns.map((c) => c['name']).toSet();
      if (!employeeColumnNames.contains('joining_date')) {
        await db.execute('ALTER TABLE employees ADD COLUMN joining_date TEXT;');
        // Update existing employees to use created_date as joining_date
        await db.execute('UPDATE employees SET joining_date = created_date WHERE joining_date IS NULL;');
      }
    }
    
    if (oldVersion < 4) {
      // Add partial_off_days column to employees table
      final employeeColumns = await db.rawQuery("PRAGMA table_info(employees);");
      final employeeColumnNames = employeeColumns.map((c) => c['name']).toSet();
      if (!employeeColumnNames.contains('partial_off_days')) {
        await db.execute('ALTER TABLE employees ADD COLUMN partial_off_days TEXT DEFAULT "{}";');
      }
    }
    
    if (oldVersion < 5) {
      // Add enhanced payment system columns
      final paymentColumns = await db.rawQuery("PRAGMA table_info(payments);");
      final paymentColumnNames = paymentColumns.map((c) => c['name']).toSet();
      
      if (!paymentColumnNames.contains('month_year')) {
        await db.execute('ALTER TABLE payments ADD COLUMN month_year TEXT;');
      }
      if (!paymentColumnNames.contains('is_advance_payment')) {
        await db.execute('ALTER TABLE payments ADD COLUMN is_advance_payment INTEGER DEFAULT 0;');
      }
      if (!paymentColumnNames.contains('remaining_amount')) {
        await db.execute('ALTER TABLE payments ADD COLUMN remaining_amount REAL;');
      }
    }
    
    if (oldVersion < 6) {
      // Update payment_type constraint to include 'remaining' and 'bonus'
      // SQLite doesn't support ALTER CONSTRAINT, so we need to recreate the table
      
      // First, get all existing payment data
      final existingPayments = await db.query('payments');
      
      // Drop the old table
      await db.execute('DROP TABLE payments');
      
      // Recreate the table with updated constraint
      await db.execute('''
        CREATE TABLE payments (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          employee_id INTEGER NOT NULL,
          amount REAL NOT NULL,
          payment_type TEXT NOT NULL CHECK (payment_type IN ('salary', 'advance', 'remaining', 'bonus')),
          payment_date TEXT NOT NULL,
          payment_method TEXT NOT NULL,
          notes TEXT,
          created_date TEXT NOT NULL,
          month_year TEXT,
          is_advance_payment INTEGER DEFAULT 0,
          remaining_amount REAL,
          FOREIGN KEY (employee_id) REFERENCES employees (id)
        )
      ''');
      
      // Restore the existing data
      for (final payment in existingPayments) {
        await db.insert('payments', payment);
      }
    }
    // Future migrations go here
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

  // Manually upgrade database (useful for development)
  Future<void> manualUpgrade() async {
    final db = await database;
    await _onUpgrade(db, 4, 6); // Force upgrade to latest version
  }

  // Reset database (useful for development - WARNING: This will delete all data!)
  Future<void> resetDatabase() async {
    String path = join(await getDatabasesPath(), _databaseName);
    await closeDatabase();
    await deleteDatabase(path);
    _database = null; // Force recreation on next access
  }

  // Close database connection
  Future<void> closeDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  // Employee CRUD
  Future<int> insertEmployee(Employee employee) async {
    final db = await database;
    return await db.insert('employees', employee.toMap(), conflictAlgorithm: ConflictAlgorithm.abort);
  }

  Future<Employee?> getEmployee(int id) async {
    final db = await database;
    final maps = await db.query('employees', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      return Employee.fromMap(maps.first);
    }
    return null;
  }

  Future<List<Employee>> getAllEmployees() async {
    final db = await database;
    final maps = await db.query('employees');
    return maps.map((e) => Employee.fromMap(e)).toList();
  }

  Future<int> updateEmployee(Employee employee) async {
    final db = await database;
    return await db.update('employees', employee.toMap(), where: 'id = ?', whereArgs: [employee.id]);
  }

  Future<int> deleteEmployee(int id) async {
    final db = await database;
    return await db.delete('employees', where: 'id = ?', whereArgs: [id]);
  }

  // Attendance CRUD
  Future<int> insertAttendance(Attendance attendance) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    final data = attendance.toMap();
    data['created_at'] = attendance.createdAt.isNotEmpty ? attendance.createdAt : now;
    data['updated_at'] = attendance.updatedAt.isNotEmpty ? attendance.updatedAt : now;
    return await db.insert('attendance', data, conflictAlgorithm: ConflictAlgorithm.abort);
  }

  Future<Attendance?> getAttendance(int id) async {
    final db = await database;
    final maps = await db.query('attendance', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      return Attendance.fromMap(maps.first);
    }
    return null;
  }

  Future<List<Attendance>> getAllAttendance() async {
    final db = await database;
    final maps = await db.query('attendance');
    return maps.map((e) => Attendance.fromMap(e)).toList();
  }

  Future<List<Attendance>> getAttendanceForEmployeeAndDate(int employeeId, DateTime date) async {
    final db = await database;
    final dateString = date.toIso8601String().split('T')[0]; // Get YYYY-MM-DD format
    final maps = await db.query(
      'attendance',
      where: 'employee_id = ? AND date = ?',
      whereArgs: [employeeId, dateString],
    );
    return maps.map((e) => Attendance.fromMap(e)).toList();
  }

  Future<int> updateAttendance(Attendance attendance) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    final data = attendance.toMap();
    data['updated_at'] = now;
    return await db.update('attendance', data, where: 'id = ?', whereArgs: [attendance.id]);
  }

  Future<int> deleteAttendance(int id) async {
    final db = await database;
    return await db.delete('attendance', where: 'id = ?', whereArgs: [id]);
  }

  // Payment CRUD
  Future<int> insertPayment(Payment payment) async {
    final db = await database;
    return await db.insert('payments', payment.toMap(), conflictAlgorithm: ConflictAlgorithm.abort);
  }

  Future<Payment?> getPayment(int id) async {
    final db = await database;
    final maps = await db.query('payments', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      return Payment.fromMap(maps.first);
    }
    return null;
  }

  Future<List<Payment>> getAllPayments() async {
    final db = await database;
    final maps = await db.query('payments', orderBy: 'payment_date DESC');
    return maps.map((e) => Payment.fromMap(e)).toList();
  }

  Future<List<Payment>> getPaymentsByEmployee(int employeeId) async {
    final db = await database;
    final maps = await db.query(
      'payments', 
      where: 'employee_id = ?', 
      whereArgs: [employeeId],
      orderBy: 'payment_date DESC'
    );
    return maps.map((e) => Payment.fromMap(e)).toList();
  }

  Future<List<Payment>> getPaymentsByMonth(String monthYear) async {
    final db = await database;
    final maps = await db.query(
      'payments', 
      where: 'month_year = ?', 
      whereArgs: [monthYear],
      orderBy: 'payment_date DESC'
    );
    return maps.map((e) => Payment.fromMap(e)).toList();
  }

  Future<List<Payment>> getAdvancePayments(int employeeId, String monthYear) async {
    final db = await database;
    final maps = await db.query(
      'payments', 
      where: 'employee_id = ? AND month_year = ? AND payment_type = ?', 
      whereArgs: [employeeId, monthYear, 'advance'],
      orderBy: 'payment_date DESC'
    );
    return maps.map((e) => Payment.fromMap(e)).toList();
  }

  Future<double> getTotalAdvanceForMonth(int employeeId, String monthYear) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT SUM(amount) as total 
      FROM payments 
      WHERE employee_id = ? AND month_year = ? AND payment_type = 'advance'
    ''', [employeeId, monthYear]);
    return (result.first['total'] as double?) ?? 0.0;
  }

  Future<double> getTotalPaidForMonth(int employeeId, String monthYear) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT SUM(amount) as total 
      FROM payments 
      WHERE employee_id = ? AND month_year = ?
    ''', [employeeId, monthYear]);
    return (result.first['total'] as double?) ?? 0.0;
  }

  Future<List<MonthlyPaymentSummary>> getMonthlyPaymentSummaries() async {
    final employees = await getAllEmployees();
    final allPayments = await getAllPayments();
    final now = DateTime.now();
    
    Map<String, List<MonthlyPaymentSummary>> summaries = {};
    
    for (final employee in employees) {
      if (!employee.activeStatus) continue;
      
      // Parse employee joining date
      final joiningDate = DateTime.parse(employee.joiningDate);
      
      // Get unique months from payments for this employee
      final employeePayments = allPayments.where((p) => p.employeeId == employee.id).toList();
      final paymentMonths = employeePayments
          .where((p) => p.monthYear != null)
          .map((p) => p.monthYear!)
          .toSet()
          .toList();
      
      // Generate all months from joining date to current month
      final months = <String>[];
      DateTime monthIterator = DateTime(joiningDate.year, joiningDate.month);
      final currentDateTime = DateTime(now.year, now.month);
      
      while (monthIterator.isBefore(currentDateTime) || monthIterator.isAtSameMomentAs(currentDateTime)) {
        final monthString = '${monthIterator.year}-${monthIterator.month.toString().padLeft(2, '0')}';
        months.add(monthString);
        monthIterator = DateTime(monthIterator.year, monthIterator.month + 1);
      }
      
      // Also include any payment months that might be outside this range (for data consistency)
      for (final paymentMonth in paymentMonths) {
        if (!months.contains(paymentMonth)) {
          months.add(paymentMonth);
        }
      }
      
      for (final month in months) {
        final monthPayments = employeePayments.where((p) => p.monthYear == month).toList();
        final advances = monthPayments.where((p) => p.paymentType == 'advance').toList();
        final salaryPayments = monthPayments.where((p) => p.paymentType != 'advance').toList();
        
        final totalAdvances = advances.fold(0.0, (sum, p) => sum + p.amount);
        final totalSalary = salaryPayments.fold(0.0, (sum, p) => sum + p.amount);
        final totalPaid = totalAdvances + totalSalary;
        final remaining = employee.monthlySalary - totalPaid;
        
        final summary = MonthlyPaymentSummary(
          monthYear: month,
          employeeId: employee.id!,
          employeeName: employee.name,
          monthlySalary: employee.monthlySalary,
          totalAdvancesPaid: totalAdvances,
          remainingAmount: remaining,
          advances: advances,
          salaryPayments: salaryPayments,
          isFullyPaid: remaining <= 0,
        );
        
        if (!summaries.containsKey(month)) {
          summaries[month] = [];
        }
        summaries[month]!.add(summary);
      }
    }
    
    // Flatten and sort by month (newest first)
    final allSummaries = summaries.entries
        .expand((entry) => entry.value)
        .toList();
    
    allSummaries.sort((a, b) => b.monthYear.compareTo(a.monthYear));
    
    return allSummaries;
  }

  Future<int> updatePayment(Payment payment) async {
    final db = await database;
    return await db.update('payments', payment.toMap(), where: 'id = ?', whereArgs: [payment.id]);
  }

  Future<int> deletePayment(int id) async {
    final db = await database;
    return await db.delete('payments', where: 'id = ?', whereArgs: [id]);
  }
} 
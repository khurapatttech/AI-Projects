import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/employee.dart';
import '../models/attendance.dart';
import '../models/payment.dart';
import 'package:intl/intl.dart';

class DatabaseService {
  static Database? _database;
  static const String _databaseName = 'household_staff.db';
  static const int _databaseVersion = 2; // Incremented from 1 to 2

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
    final maps = await db.query('payments');
    return maps.map((e) => Payment.fromMap(e)).toList();
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
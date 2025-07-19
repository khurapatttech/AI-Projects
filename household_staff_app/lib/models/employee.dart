import 'dart:convert';

class Employee {
  final int? id;
  final String name;
  final int age;
  final String phone;
  final String? email;
  final double monthlySalary;
  final int visitsPerDay;
  final List<String> offDays;
  final String createdDate;
  final bool activeStatus;

  Employee({
    this.id,
    required this.name,
    required this.age,
    required this.phone,
    this.email,
    required this.monthlySalary,
    required this.visitsPerDay,
    required this.offDays,
    required this.createdDate,
    this.activeStatus = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'phone': phone,
      'email': email,
      'monthly_salary': monthlySalary,
      'visits_per_day': visitsPerDay,
      'off_days': jsonEncode(offDays),
      'created_date': createdDate,
      'active_status': activeStatus ? 1 : 0,
    };
  }

  factory Employee.fromMap(Map<String, dynamic> map) {
    return Employee(
      id: map['id'],
      name: map['name'],
      age: map['age'],
      phone: map['phone'],
      email: map['email'],
      monthlySalary: map['monthly_salary'],
      visitsPerDay: map['visits_per_day'],
      offDays: List<String>.from(jsonDecode(map['off_days'])),
      createdDate: map['created_date'],
      activeStatus: map['active_status'] == 1,
    );
  }
} 
import 'dart:convert';

class Employee {
  final int? id;
  final String name;
  final int age;
  final String phone;
  final String? email;
  final double monthlySalary;
  final int visitsPerDay;
final List<String> offDays; // Full day offs
  final Map<String, List<String>> partialOffDays; // day -> ['morning'/'evening']
  final String createdDate;
  final String joiningDate;
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
    this.partialOffDays = const {},
    required this.createdDate,
    required this.joiningDate,
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
      'partial_off_days': jsonEncode(partialOffDays),
      'created_date': createdDate,
      'joining_date': joiningDate,
      'active_status': activeStatus ? 1 : 0,
    };
  }

  factory Employee.fromMap(Map<String, dynamic> map) {
    Map<String, List<String>> partialOffs = {};
    if (map['partial_off_days'] != null) {
      final decoded = jsonDecode(map['partial_off_days']) as Map<String, dynamic>;
      partialOffs = decoded.map((key, value) => MapEntry(key, List<String>.from(value)));
    }
    
    return Employee(
      id: map['id'],
      name: map['name'],
      age: map['age'],
      phone: map['phone'],
      email: map['email'],
      monthlySalary: map['monthly_salary'],
      visitsPerDay: map['visits_per_day'],
      offDays: List<String>.from(jsonDecode(map['off_days'])),
      partialOffDays: partialOffs,
      createdDate: map['created_date'],
      joiningDate: map['joining_date'] ?? map['created_date'], // Fallback for existing records
      activeStatus: map['active_status'] == 1,
    );
  }

  Employee copyWith({
    int? id,
    String? name,
    int? age,
    String? phone,
    String? email,
    double? monthlySalary,
    int? visitsPerDay,
    List<String>? offDays,
    Map<String, List<String>>? partialOffDays,
    String? createdDate,
    String? joiningDate,
    bool? activeStatus,
  }) {
    return Employee(
      id: id ?? this.id,
      name: name ?? this.name,
      age: age ?? this.age,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      monthlySalary: monthlySalary ?? this.monthlySalary,
      visitsPerDay: visitsPerDay ?? this.visitsPerDay,
      offDays: offDays ?? this.offDays,
      partialOffDays: partialOffDays ?? this.partialOffDays,
      createdDate: createdDate ?? this.createdDate,
      joiningDate: joiningDate ?? this.joiningDate,
      activeStatus: activeStatus ?? this.activeStatus,
    );
  }
} 
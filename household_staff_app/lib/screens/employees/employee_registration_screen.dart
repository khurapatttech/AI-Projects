import 'dart:convert';
import 'package:flutter/material.dart';
import '../../models/employee.dart';
import '../../services/database_service.dart';

class EmployeeRegistrationScreen extends StatefulWidget {
  const EmployeeRegistrationScreen({Key? key}) : super(key: key);

  @override
  State<EmployeeRegistrationScreen> createState() => _EmployeeRegistrationScreenState();
}

class _EmployeeRegistrationScreenState extends State<EmployeeRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _salaryController = TextEditingController();
  int _visitsPerDay = 1;
  List<String> _offDays = [];
  bool _isSaving = false;

  final List<String> _daysOfWeek = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _salaryController.dispose();
    super.dispose();
  }

  Future<bool> _isNameUnique(String name) async {
    final db = DatabaseService();
    final employees = await db.getAllEmployees();
    return !employees.any((e) => e.name.toLowerCase() == name.toLowerCase());
  }

  void _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    final isUnique = await _isNameUnique(_nameController.text.trim());
    if (!isUnique) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Employee name must be unique.')),
      );
      return;
    }
    final employee = Employee(
      name: _nameController.text.trim(),
      age: int.parse(_ageController.text.trim()),
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
      monthlySalary: double.parse(_salaryController.text.trim()),
      visitsPerDay: _visitsPerDay,
      offDays: _offDays,
      createdDate: DateTime.now().toIso8601String(),
      activeStatus: true,
    );
    try {
      await DatabaseService().insertEmployee(employee);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Employee registered successfully!')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving employee: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register Employee')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                maxLength: 50,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Name is required';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _ageController,
                decoration: const InputDecoration(labelText: 'Age'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Age is required';
                  }
                  final age = int.tryParse(value.trim());
                  if (age == null || age < 18 || age > 70) {
                    return 'Age must be between 18 and 70';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Phone'),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Phone is required';
                  }
                  final phoneReg = RegExp(r'^[0-9]{10,15}$');
                  if (!phoneReg.hasMatch(value.trim())) {
                    return 'Enter a valid phone number';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email (optional)'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value != null && value.trim().isNotEmpty) {
                    final emailReg = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+ $');
                    if (!emailReg.hasMatch(value.trim())) {
                      return 'Enter a valid email address';
                    }
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _salaryController,
                decoration: const InputDecoration(labelText: 'Monthly Salary'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Salary is required';
                  }
                  final salary = double.tryParse(value.trim());
                  if (salary == null || salary <= 0) {
                    return 'Enter a valid salary';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              const Text('Visits per day'),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<int>(
                      title: const Text('1'),
                      value: 1,
                      groupValue: _visitsPerDay,
                      onChanged: (val) {
                        setState(() => _visitsPerDay = val ?? 1);
                      },
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<int>(
                      title: const Text('2'),
                      value: 2,
                      groupValue: _visitsPerDay,
                      onChanged: (val) {
                        setState(() => _visitsPerDay = val ?? 1);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Weekly Off Days (select at least 1)'),
              ..._daysOfWeek.map((day) => CheckboxListTile(
                title: Text(day),
                value: _offDays.contains(day),
                onChanged: (checked) {
                  setState(() {
                    if (checked == true) {
                      _offDays.add(day);
                    } else {
                      _offDays.remove(day);
                    }
                  });
                },
              )),
              if (_offDays.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(left: 8.0, top: 4.0),
                  child: Text('Select at least one off day', style: TextStyle(color: Colors.red)),
                ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isSaving
                    ? null
                    : () {
                        if (_offDays.isEmpty) {
                          setState(() {});
                          return;
                        }
                        _submitForm();
                      },
                child: _isSaving
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Register Employee'),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 
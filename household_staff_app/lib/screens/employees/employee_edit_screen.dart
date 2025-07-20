import 'dart:convert';
import 'package:flutter/material.dart';
import '../../models/employee.dart';
import '../../services/database_service.dart';

class EmployeeEditScreen extends StatefulWidget {
  final Employee employee;
  const EmployeeEditScreen({Key? key, required this.employee}) : super(key: key);

  @override
  State<EmployeeEditScreen> createState() => _EmployeeEditScreenState();
}

class _EmployeeEditScreenState extends State<EmployeeEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _ageController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _salaryController;
  int _visitsPerDay = 1;
  List<String> _offDays = [];
  bool _isSaving = false;
  bool _activeStatus = true;

  final List<String> _daysOfWeek = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
  ];

  @override
  void initState() {
    super.initState();
    final e = widget.employee;
    _nameController = TextEditingController(text: e.name);
    _ageController = TextEditingController(text: e.age.toString());
    _phoneController = TextEditingController(text: e.phone);
    _emailController = TextEditingController(text: e.email ?? '');
    _salaryController = TextEditingController(text: e.monthlySalary.toString());
    _visitsPerDay = e.visitsPerDay;
    _offDays = List<String>.from(e.offDays);
    _activeStatus = e.activeStatus;
  }

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
    // Allow the same name if it's the current employee
    return !employees.any((e) => e.name.toLowerCase() == name.toLowerCase() && e.id != widget.employee.id);
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
    final updatedEmployee = Employee(
      id: widget.employee.id,
      name: _nameController.text.trim(),
      age: int.parse(_ageController.text.trim()),
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
      monthlySalary: double.parse(_salaryController.text.trim()),
      visitsPerDay: _visitsPerDay,
      offDays: _offDays,
      createdDate: widget.employee.createdDate,
      activeStatus: _activeStatus,
    );
    try {
      await DatabaseService().updateEmployee(updatedEmployee);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Employee updated successfully!')),
      );
      Navigator.of(context).pop(true); // Return true to indicate update
    } catch (e) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating employee: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Edit Employee'),
        elevation: 0,
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
      ),
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
                    final emailReg = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
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
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Active Status'),
                value: _activeStatus,
                onChanged: (val) {
                  setState(() => _activeStatus = val);
                },
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
                    : const Text('Save Changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 
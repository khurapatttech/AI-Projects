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
  Map<String, List<String>> _partialOffDays = {};
  bool _isSaving = false;
  bool _activeStatus = true;
  late DateTime _joiningDate;

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
    _partialOffDays = Map<String, List<String>>.from(
      e.partialOffDays.map((key, value) => MapEntry(key, List<String>.from(value)))
    );
    _activeStatus = e.activeStatus;
    _joiningDate = DateTime.parse(e.joiningDate);
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
      partialOffDays: _partialOffDays,
      createdDate: widget.employee.createdDate,
      joiningDate: _joiningDate.toIso8601String(),
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
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = MediaQuery.of(context).size.width < 600;
            final padding = isMobile ? 16.0 : 24.0;
            
            return SingleChildScrollView(
              padding: EdgeInsets.all(padding),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Section
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: _activeStatus ? const Color(0xFF6366F1) : Colors.grey,
                            child: Text(
                              _nameController.text.isNotEmpty ? _nameController.text[0].toUpperCase() : 'E',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Edit Employee Information',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Update employee details below',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF64748B),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),

                    // Personal Information Section
                    _buildSectionCard(
                      title: 'Personal Information',
                      icon: Icons.person,
                      children: [
                        _buildStyledTextField(
                          controller: _nameController,
                          label: 'Full Name',
                          hint: 'Enter employee full name',
                          icon: Icons.person_outline,
                          maxLength: 50,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Name is required';
                            }
                            return null;
                          },
                          onChanged: (value) => setState(() {}), // Update avatar
                        ),
                        const SizedBox(height: 20),
                        _buildStyledTextField(
                          controller: _ageController,
                          label: 'Age',
                          hint: 'Enter age (18-70)',
                          icon: Icons.cake_outlined,
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
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Contact Information
                    _buildSectionCard(
                      title: 'Contact Information',
                      icon: Icons.contact_phone,
                      children: [
                        _buildStyledTextField(
                          controller: _phoneController,
                          label: 'Phone Number',
                          hint: 'Enter 10-digit phone number',
                          icon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Phone is required';
                            }
                            final phoneReg = RegExp(r'^[0-9]{10}$');
                            if (!phoneReg.hasMatch(value.trim())) {
                              return 'Enter a valid phone number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        _buildStyledTextField(
                          controller: _emailController,
                          label: 'Email Address',
                          hint: 'Enter email address (optional)',
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          isOptional: true,
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
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Employment Details
                    _buildSectionCard(
                      title: 'Employment Details',
                      icon: Icons.work,
                      children: [
                        _buildStyledTextField(
                          controller: _salaryController,
                          label: 'Monthly Salary',
                          hint: 'Enter monthly salary amount',
                          icon: Icons.currency_rupee_outlined,
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
                        const SizedBox(height: 20),
                        _buildJoiningDateField(),
                        const SizedBox(height: 24),
                        _buildVisitsDisplaySection(),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Schedule Information
                    _buildSectionCard(
                      title: 'Schedule Information',
                      icon: Icons.schedule,
                      children: [
                        _buildOffDaysDisplaySection(),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Status Section
                    _buildSectionCard(
                      title: 'Employee Status',
                      icon: Icons.admin_panel_settings,
                      children: [
                        _buildStatusSection(),
                      ],
                    ),
                    const SizedBox(height: 32),
                    
                    // Update Button
                    _buildUpdateButton(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 20,
                color: const Color(0xFF6366F1),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildStyledTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int? maxLength,
    bool isOptional = false,
    Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF374151),
              ),
            ),
            if (isOptional)
              const Text(
                ' (Optional)',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF9CA3AF),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLength: maxLength,
          validator: validator,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: const Color(0xFF9CA3AF)),
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFEF4444)),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFEF4444), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            counterText: maxLength != null ? null : '',
          ),
        ),
      ],
    );
  }

  Widget _buildJoiningDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Joining Date',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final DateTime? picked = await showDatePicker(
              context: context,
              initialDate: _joiningDate,
              firstDate: DateTime(2020),
              lastDate: DateTime.now().add(const Duration(days: 365)),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: const ColorScheme.light(
                      primary: Color(0xFF6366F1),
                      onPrimary: Colors.white,
                      surface: Colors.white,
                      onSurface: Color(0xFF374151),
                    ),
                  ),
                  child: child!,
                );
              },
            );
            if (picked != null && picked != _joiningDate) {
              setState(() {
                _joiningDate = picked;
              });
            }
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  color: Color(0xFF9CA3AF),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  '${_joiningDate.day}/${_joiningDate.month}/${_joiningDate.year}',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF374151),
                  ),
                ),
                const Spacer(),
                const Icon(
                  Icons.arrow_drop_down,
                  color: Color(0xFF9CA3AF),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Attendance tracking will start from this date',
          style: TextStyle(
            fontSize: 12,
            color: Color(0xFF9CA3AF),
          ),
        ),
      ],
    );
  }

  Widget _buildVisitsDisplaySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Visits per Day',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'This setting cannot be changed after employee creation',
          style: TextStyle(
            fontSize: 12,
            color: Color(0xFF9CA3AF),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _visitsPerDay == 1 ? Icons.looks_one : Icons.looks_two,
                  color: const Color(0xFF6366F1),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _visitsPerDay == 1 ? '1 visit per day' : '2 visits per day',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF374151),
                      ),
                    ),
                    Text(
                      _visitsPerDay == 1 ? 'Single daily visit' : 'Morning and evening visits',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.lock_outline,
                color: const Color(0xFF9CA3AF),
                size: 16,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOffDaysDisplaySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Weekly Off Schedule',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'This schedule cannot be changed after employee creation',
          style: TextStyle(
            fontSize: 12,
            color: Color(0xFF9CA3AF),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.lock_outline,
                    color: const Color(0xFF9CA3AF),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Current Schedule',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF374151),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ..._daysOfWeek.map((day) => _buildDayOffDisplay(day)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F9FF),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF0EA5E9).withOpacity(0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, size: 16, color: Color(0xFF0EA5E9)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'To modify the schedule, please create a new employee profile',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF0EA5E9)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDayOffDisplay(String day) {
    final isFullOff = _offDays.contains(day);
    final partialOffs = _partialOffDays[day] ?? [];
    final hasMorningOff = partialOffs.contains('morning');
    final hasEveningOff = partialOffs.contains('evening');
    
    String statusText;
    Color statusColor;
    IconData statusIcon;
    
    if (isFullOff) {
      statusText = 'Full Day Off';
      statusColor = const Color(0xFF6366F1);
      statusIcon = Icons.event_busy;
    } else if (hasMorningOff && hasEveningOff) {
      statusText = 'Full Day Off (AM + PM)';
      statusColor = const Color(0xFF6366F1);
      statusIcon = Icons.event_busy;
    } else if (hasMorningOff) {
      statusText = 'Morning Off';
      statusColor = const Color(0xFF10B981);
      statusIcon = Icons.wb_sunny_outlined;
    } else if (hasEveningOff) {
      statusText = 'Evening Off';
      statusColor = const Color(0xFFF59E0B);
      statusIcon = Icons.nights_stay_outlined;
    } else {
      statusText = 'Working Day';
      statusColor = const Color(0xFF64748B);
      statusIcon = Icons.work_outline;
    }
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              day,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF374151),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Icon(
                  statusIcon,
                  size: 14,
                  color: statusColor,
                ),
                const SizedBox(width: 6),
                Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 12,
                    color: statusColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Employee Status',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = MediaQuery.of(context).size.width < 600;
              
              if (isMobile) {
                return Column(
                  children: [
                    _buildStatusOption(true, 'Active', 'Employee is currently working'),
                    const Divider(height: 1, color: Color(0xFFE5E7EB)),
                    _buildStatusOption(false, 'Inactive', 'Employee is not currently working'),
                  ],
                );
              } else {
                return IntrinsicHeight(
                  child: Row(
                    children: [
                      Expanded(child: _buildStatusOption(true, 'Active', 'Currently working')),
                      const VerticalDivider(width: 1, color: Color(0xFFE5E7EB)),
                      Expanded(child: _buildStatusOption(false, 'Inactive', 'Not working')),
                    ],
                  ),
                );
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatusOption(bool value, String title, String subtitle) {
    final isSelected = _activeStatus == value;
    return InkWell(
      onTap: () => setState(() => _activeStatus = value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? const Color(0xFF6366F1) : const Color(0xFFD1D5DB),
                  width: 2,
                ),
                color: isSelected ? const Color(0xFF6366F1) : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 12, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? const Color(0xFF6366F1) : const Color(0xFF374151),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpdateButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: _isSaving
            ? null
            : const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
        color: _isSaving ? const Color(0xFFE5E7EB) : null,
      ),
      child: ElevatedButton(
        onPressed: _isSaving ? null : _submitForm,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isSaving
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF9CA3AF)),
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.save, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'Update Employee',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
} 
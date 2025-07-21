import 'package:flutter/material.dart';
import '../../models/employee.dart';
import '../../services/database_service.dart';
import 'employee_edit_screen.dart';

class EmployeeDetailScreen extends StatefulWidget {
  final Employee employee;
  const EmployeeDetailScreen({Key? key, required this.employee}) : super(key: key);

  @override
  State<EmployeeDetailScreen> createState() => _EmployeeDetailScreenState();
}

class _EmployeeDetailScreenState extends State<EmployeeDetailScreen> {
  late Employee employee;

  @override
  void initState() {
    super.initState();
    employee = widget.employee;
  }

  Future<void> _deleteEmployee() async {
    // Show confirmation dialog
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Employee'),
          content: Text('Are you sure you want to delete ${employee.name}? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        await DatabaseService().deleteEmployee(employee.id!);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${employee.name} has been deleted'),
              duration: const Duration(seconds: 2),
            ),
          );
          // Go back to employee list and refresh it
          Navigator.of(context).pop(true); // Return true to indicate deletion
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting employee: $e'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(employee.name),
        elevation: 0,
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Edit',
            onPressed: () async {
              final updated = await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => EmployeeEditScreen(employee: employee),
                ),
              );
              if (updated == true) {
                // If updated, pop and push replacement to refresh
                Navigator.of(context).pop();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: 'Delete',
            onPressed: _deleteEmployee,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card with Employee Avatar
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
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
                      backgroundColor: employee.activeStatus ? const Color(0xFF6366F1) : Colors.grey,
                      child: Text(
                        employee.name[0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      employee.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: employee.activeStatus ? Colors.green.shade100 : Colors.red.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            employee.activeStatus ? Icons.check_circle : Icons.cancel,
                            size: 16,
                            color: employee.activeStatus ? Colors.green.shade700 : Colors.red.shade700,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            employee.activeStatus ? 'Active' : 'Inactive',
                            style: TextStyle(
                              color: employee.activeStatus ? Colors.green.shade700 : Colors.red.shade700,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Personal Information Section
              _buildSectionCard(
                title: 'Personal Information',
                icon: Icons.person,
                children: [
                  _buildInfoRow(
                    icon: Icons.person_outline,
                    label: 'Full Name',
                    value: employee.name,
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow(
                    icon: Icons.cake_outlined,
                    label: 'Age',
                    value: '${employee.age} years old',
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Contact Information Section
              _buildSectionCard(
                title: 'Contact Information',
                icon: Icons.contact_phone,
                children: [
                  _buildInfoRow(
                    icon: Icons.phone_outlined,
                    label: 'Phone Number',
                    value: employee.phone,
                    actionIcon: Icons.phone,
                    actionColor: Colors.green,
                    onActionTap: () => _makePhoneCall(employee.phone),
                  ),
                  if (employee.email != null && employee.email!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildInfoRow(
                      icon: Icons.email_outlined,
                      label: 'Email Address',
                      value: employee.email!,
                      actionIcon: Icons.email,
                      actionColor: const Color(0xFF6366F1),
                      onActionTap: () => _sendEmail(employee.email!),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 20),

              // Employment Details Section
              _buildSectionCard(
                title: 'Employment Details',
                icon: Icons.work,
                children: [
                  _buildInfoRow(
                    icon: Icons.currency_rupee_outlined,
                    label: 'Monthly Salary',
                    value: '₹${employee.monthlySalary.toStringAsFixed(2)}',
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow(
                    icon: Icons.calendar_today_outlined,
                    label: 'Joining Date',
                    value: _formatDate(employee.joiningDate),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow(
                    icon: Icons.repeat,
                    label: 'Visits per Day',
                    value: '${employee.visitsPerDay} visit${employee.visitsPerDay > 1 ? 's' : ''}',
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Schedule Information Section
              _buildSectionCard(
                title: 'Schedule Information',
                icon: Icons.schedule,
                children: [
                  _buildOffDaysInfo(),
                  const SizedBox(height: 16),
                  _buildInfoRow(
                    icon: Icons.calendar_today_outlined,
                    label: 'Registration Date',
                    value: _formatDate(employee.createdDate),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
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

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    IconData? actionIcon,
    Color? actionColor,
    VoidCallback? onActionTap,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 20,
            color: const Color(0xFF64748B),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
        ),
        if (actionIcon != null && onActionTap != null)
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: onActionTap,
              child: Container(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  actionIcon,
                  color: actionColor ?? const Color(0xFF6366F1),
                  size: 20,
                ),
              ),
            ),
          ),
      ],
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  Widget _buildOffDaysInfo() {
    if (employee.offDays.isEmpty && employee.partialOffDays.isEmpty) {
      return _buildInfoRow(
        icon: Icons.event_busy_outlined,
        label: 'Weekly Off Schedule',
        value: 'No off days - works all 7 days',
      );
    }

    // Process data to avoid duplicates and handle edge cases
    List<String> effectiveFullDays = List.from(employee.offDays);
    Map<String, List<String>> effectivePartialOffs = Map.from(employee.partialOffDays);
    
    // Check for days where partial offs equal full day (both morning and evening)
    if (employee.visitsPerDay == 2) {
      effectivePartialOffs.removeWhere((day, shifts) {
        if (shifts.contains('morning') && shifts.contains('evening')) {
          // If both shifts are off, treat as full day off
          if (!effectiveFullDays.contains(day)) {
            effectiveFullDays.add(day);
          }
          return true; // Remove from partial offs
        }
        return false;
      });
    }
    
    // Remove any duplicates between full day and partial off lists
    effectivePartialOffs.removeWhere((day, shifts) => effectiveFullDays.contains(day));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.event_busy_outlined,
                size: 20,
                color: const Color(0xFF64748B),
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Weekly Off Schedule',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Custom schedule configured',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Full day offs (including converted partial offs)
              if (effectiveFullDays.isNotEmpty) ...[
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Full Day Off',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        effectiveFullDays.join(', '),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ),
                  ],
                ),
                if (effectivePartialOffs.isNotEmpty) const SizedBox(height: 12),
              ],
              
              // Partial offs (only single shifts, not both)
              if (effectivePartialOffs.isNotEmpty) ...[
                ...effectivePartialOffs.entries.map((entry) {
                  final day = entry.key;
                  final shifts = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Partial Off',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.orange.shade700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '$day (${shifts.join(', ')})',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    // Implementation for phone call (if url_launcher is available)
    // You might want to import url_launcher and implement this
  }

  Future<void> _sendEmail(String email) async {
    // Implementation for email (if url_launcher is available)
    // You might want to import url_launcher and implement this
  }
}

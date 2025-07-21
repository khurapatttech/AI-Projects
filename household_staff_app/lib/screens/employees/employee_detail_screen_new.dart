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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Name'),
              subtitle: Text(employee.name),
            ),
            ListTile(
              leading: const Icon(Icons.cake),
              title: const Text('Age'),
              subtitle: Text(employee.age.toString()),
            ),
            ListTile(
              leading: const Icon(Icons.phone),
              title: const Text('Phone'),
              subtitle: Text(employee.phone),
            ),
            if (employee.email != null && employee.email!.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.email),
                title: const Text('Email'),
                subtitle: Text(employee.email!),
              ),
            ListTile(
              leading: const Icon(Icons.monetization_on),
              title: const Text('Monthly Salary'),
              subtitle: Text(employee.monthlySalary.toStringAsFixed(2)),
            ),
            ListTile(
              leading: const Icon(Icons.repeat),
              title: const Text('Visits Per Day'),
              subtitle: Text(employee.visitsPerDay.toString()),
            ),
            ListTile(
              leading: const Icon(Icons.event_busy),
              title: const Text('Weekly Off Days'),
              subtitle: Text(employee.offDays.join(', ')),
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Created Date'),
              subtitle: Text(employee.createdDate),
            ),
            ListTile(
              leading: Icon(employee.activeStatus ? Icons.check_circle : Icons.cancel, color: employee.activeStatus ? Colors.green : Colors.red),
              title: const Text('Status'),
              subtitle: Text(employee.activeStatus ? 'Active' : 'Inactive'),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../models/employee.dart';
import 'employee_edit_screen.dart';

class EmployeeDetailScreen extends StatelessWidget {
  final Employee employee;
  const EmployeeDetailScreen({Key? key, required this.employee}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Employee employee = this.employee;
    return Scaffold(
      appBar: AppBar(
        title: Text(employee.name),
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
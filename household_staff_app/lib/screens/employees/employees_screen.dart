import 'package:flutter/material.dart';
import '../../models/employee.dart';
import '../../services/database_service.dart';
import 'employee_registration_screen.dart';
import 'employee_detail_screen.dart';

class EmployeesScreen extends StatefulWidget {
  const EmployeesScreen({Key? key}) : super(key: key);

  @override
  State<EmployeesScreen> createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends State<EmployeesScreen> {
  late Future<List<Employee>> _employeesFuture;

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  void _loadEmployees() {
    _employeesFuture = DatabaseService().getAllEmployees();
  }

  Future<void> _refresh() async {
    setState(() {
      _loadEmployees();
    });
  }

  void _navigateToRegistration() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const EmployeeRegistrationScreen()),
    );
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Employees'),
        elevation: 0,
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<Employee>>(
        future: _employeesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: \\${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No employees registered yet.'));
          }
          final employees = snapshot.data!;
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              itemCount: employees.length,
              itemBuilder: (context, index) {
                final e = employees[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    leading: CircleAvatar(child: Text(e.name[0].toUpperCase())),
                    title: Text(e.name),
                    subtitle: Text('Visits per day: \\${e.visitsPerDay}\nStatus: \\${e.activeStatus ? 'Active' : 'Inactive'}'),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => EmployeeDetailScreen(employee: e),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToRegistration,
        child: const Icon(Icons.add),
        tooltip: 'Add Employee',
      ),
    );
  }
} 
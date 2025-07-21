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
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: employees.length,
              itemBuilder: (context, index) {
                final e = employees[index];
                return Dismissible(
                  key: Key(e.id.toString()),
                  confirmDismiss: (direction) async {
                    if (direction == DismissDirection.startToEnd) {
                      // Toggle status
                      final dbService = DatabaseService();
                      await dbService.updateEmployee(e.copyWith(activeStatus: !e.activeStatus));
                      setState(() => _loadEmployees());
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${e.name} is now ${!e.activeStatus ? 'Active' : 'Inactive'}'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                      return false;
                    }
                    return false;
                  },
                  background: Container(
                    color: e.activeStatus ? Colors.red.shade100 : Colors.green.shade100,
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Icon(
                      e.activeStatus ? Icons.person_off : Icons.person,
                      color: e.activeStatus ? Colors.red : Colors.green,
                    ),
                  ),
                  child: Card(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    elevation: 2,
                    child: InkWell(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => EmployeeDetailScreen(employee: e),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 25,
                              backgroundColor: e.activeStatus ? const Color(0xFF6366F1) : Colors.grey,
                              child: Text(
                                e.name[0].toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    e.name,
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.repeat,
                                        size: 16,
                                        color: Colors.grey[600],
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${e.visitsPerDay} visit${e.visitsPerDay > 1 ? 's' : ''} per day',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: e.activeStatus ? Colors.green.shade100 : Colors.red.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                e.activeStatus ? 'Active' : 'Inactive',
                                style: TextStyle(
                                  color: e.activeStatus ? Colors.green.shade700 : Colors.red.shade700,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.chevron_right,
                              color: Colors.grey[400],
                            ),
                          ],
                        ),
                      ),
                    ),
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
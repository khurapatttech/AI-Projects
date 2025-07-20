import 'package:flutter/material.dart';
import '../../models/employee.dart';
import '../../models/attendance.dart';
import '../../services/database_service.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  final Function(int)? onNavigate;
  
  const HomeScreen({Key? key, this.onNavigate}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Employee>> _employeesFuture;
  late Future<List<Attendance>> _attendanceFuture;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  void _refreshData() {
    setState(() {
      _employeesFuture = DatabaseService().getAllEmployees();
      _attendanceFuture = DatabaseService().getAllAttendance();
    });
  }

  Widget _buildStatCard(String title, String value, Color color, IconData icon) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                Icon(icon, color: color, size: 24),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction(String title, IconData icon, VoidCallback? onTap) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: Colors.blue),
              const SizedBox(width: 12),
              Text(title, style: const TextStyle(fontSize: 16)),
              const Spacer(),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTodaySchedule(List<Employee> employees, List<Attendance> attendance) {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final todayWeekday = DateFormat('EEEE').format(DateTime.now());
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Today\'s Schedule', 
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...employees.map((e) {
              final isOff = e.offDays.contains(todayWeekday);
              final att = attendance.where(
                (a) => a.employeeId == e.id && a.date == today).toList();
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: isOff ? Colors.grey : Colors.blue.shade100,
                      radius: 16,
                      child: Text(e.name[0].toUpperCase()),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(e.name),
                          Text(
                            isOff ? 'Off Day' : 
                            att.isEmpty ? 'Not marked yet' :
                            att.every((a) => a.status == 'present') ? 'Present' :
                            'Absent',
                            style: TextStyle(
                              color: isOff ? Colors.grey :
                                     att.isEmpty ? Colors.orange :
                                     att.every((a) => a.status == 'present') ? Colors.green :
                                     Colors.red,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (e.visitsPerDay == 2) ...[
                      Icon(Icons.brightness_5, 
                        color: _getShiftColor(att, 'morning'),
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.brightness_3, 
                        color: _getShiftColor(att, 'evening'),
                        size: 16,
                      ),
                    ],
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Color _getShiftColor(List<Attendance> att, String shift) {
    final shiftAtt = att.where((a) => a.shiftType == shift).firstOrNull;
    if (shiftAtt == null) return Colors.grey;
    return shiftAtt.status == 'present' ? Colors.green : Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _refreshData(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: FutureBuilder<List<Employee>>(
            future: _employeesFuture,
            builder: (context, empSnap) {
              if (!empSnap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              
              return FutureBuilder<List<Attendance>>(
                future: _attendanceFuture,
                builder: (context, attSnap) {
                  if (!attSnap.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final employees = empSnap.data!;
                  final attendance = attSnap.data!;
                  final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
                  final todayAtt = attendance.where((a) => a.date == today).toList();
                  
                  final presentCount = todayAtt.where((a) => a.status == 'present').length;
                  final absentCount = todayAtt.where((a) => a.status == 'absent').length;
                  final totalExpected = employees.fold<int>(
                    0, 
                    (sum, e) => sum + (e.visitsPerDay == 2 ? 2 : 1)
                  );
                  final pendingCount = totalExpected - (presentCount + absentCount);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Stats Grid
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        childAspectRatio: 1.5,
                        children: [
                          _buildStatCard(
                            'Total Staff',
                            employees.length.toString(),
                            Colors.blue,
                            Icons.people,
                          ),
                          _buildStatCard(
                            'Present Today',
                            presentCount.toString(),
                            Colors.green,
                            Icons.check_circle,
                          ),
                          _buildStatCard(
                            'Absent Today',
                            absentCount.toString(),
                            Colors.red,
                            Icons.cancel,
                          ),
                          _buildStatCard(
                            'Pending',
                            pendingCount.toString(),
                            Colors.orange,
                            Icons.pending_actions,
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),
                      
                      // Quick Actions
                      const Text('Quick Actions', 
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      _buildQuickAction(
                        'Mark Attendance',
                        Icons.check_circle_outline,
                        () {
                          final mainNav = context.findAncestorStateOfType<_MainNavigationScreenState>();
                          if (mainNav != null) {
                            mainNav.onItemTapped(1); // Switch to attendance tab
                          }
                        },
                      ),
                      const SizedBox(height: 8),
                      _buildQuickAction(
                        'Manage Employees',
                        Icons.people_outline,
                        () {
                          final mainNav = context.findAncestorStateOfType<_MainNavigationScreenState>();
                          if (mainNav != null) {
                            mainNav.onItemTapped(2); // Switch to employees tab
                          }
                        },
                      ),

                      const SizedBox(height: 24),
                      
                      // Today's Schedule
                      _buildTodaySchedule(employees, attendance),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

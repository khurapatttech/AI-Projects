import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/employee.dart';
import '../../models/attendance.dart';
import '../../services/database_service.dart';

class DashboardScreen extends StatefulWidget {
  final VoidCallback? onNavigateToAttendance;
  final VoidCallback? onNavigateToEmployees;
  
  const DashboardScreen({
    Key? key, 
    this.onNavigateToAttendance,
    this.onNavigateToEmployees,
  }) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<DashboardData> _dashboardDataFuture;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  void _loadDashboardData() {
    _dashboardDataFuture = _fetchDashboardData();
  }

  Future<DashboardData> _fetchDashboardData() async {
    final dbService = DatabaseService();
    final employees = await dbService.getAllEmployees();
    final allAttendance = await dbService.getAllAttendance();
    
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final todayAttendance = allAttendance.where((a) => a.date == today).toList();
    
    // Calculate statistics
    int totalEmployees = employees.length;
    int activeEmployees = employees.where((e) => e.activeStatus).length;
    int presentToday = todayAttendance.where((a) => a.status == 'present').length;
    int absentToday = todayAttendance.where((a) => a.status == 'absent').length;
    
    // Calculate pending attendance (employees who haven't marked attendance)
    int expectedAttendance = 0;
    for (final emp in employees) {
      if (!emp.activeStatus) continue;
      
      // Check if today is an off day
      final weekday = DateFormat('EEEE').format(DateTime.now());
      if (emp.offDays.contains(weekday)) continue;
      
      if (emp.visitsPerDay == 1) {
        expectedAttendance += 1;
      } else {
        expectedAttendance += 2; // morning and evening
      }
    }
    
    int markedAttendance = todayAttendance.length;
    int pendingAttendance = expectedAttendance - markedAttendance;
    
    // Get recent attendance for chart data (last 7 days)
    final last7Days = List.generate(7, (i) => 
      DateFormat('yyyy-MM-dd').format(DateTime.now().subtract(Duration(days: i)))
    ).reversed.toList();
    
    List<DailyAttendanceData> weeklyData = [];
    for (final date in last7Days) {
      final dayAttendance = allAttendance.where((a) => a.date == date).toList();
      final present = dayAttendance.where((a) => a.status == 'present').length;
      final absent = dayAttendance.where((a) => a.status == 'absent').length;
      
      weeklyData.add(DailyAttendanceData(
        date: date,
        present: present,
        absent: absent,
      ));
    }
    
    // Get upcoming birthdays (employees with birthdays in next 30 days)
    // For now, we'll use a placeholder since we don't have birthday data
    List<Employee> upcomingBirthdays = [];
    
    return DashboardData(
      totalEmployees: totalEmployees,
      activeEmployees: activeEmployees,
      presentToday: presentToday,
      absentToday: absentToday,
      pendingAttendance: pendingAttendance,
      weeklyAttendance: weeklyData,
      upcomingBirthdays: upcomingBirthdays,
      recentAttendance: todayAttendance.take(5).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Dashboard'),
        elevation: 0,
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _loadDashboardData();
              });
            },
          ),
        ],
      ),
      body: FutureBuilder<DashboardData>(
        future: _dashboardDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
              ),
            );
          }
          
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading dashboard data',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.red.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    style: theme.textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _loadDashboardData();
                      });
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          
          final data = snapshot.data!;
          
          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _loadDashboardData();
              });
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome section
                  _buildWelcomeSection(theme),
                  const SizedBox(height: 24),
                  
                  // Statistics cards
                  _buildStatsGrid(data, theme),
                  const SizedBox(height: 24),
                  
                  // Today's attendance overview
                  _buildTodayAttendanceSection(data, theme),
                  const SizedBox(height: 24),
                  
                  // Weekly attendance chart
                  _buildWeeklyAttendanceChart(data, theme),
                  const SizedBox(height: 24),
                  
                  // Quick actions
                  _buildQuickActions(theme),
                  const SizedBox(height: 24),
                  
                  // Recent activity
                  _buildRecentActivity(data, theme),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildWelcomeSection(ThemeData theme) {
    final now = DateTime.now();
    final hour = now.hour;
    String greeting;
    IconData greetingIcon;
    
    if (hour < 12) {
      greeting = 'Good Morning';
      greetingIcon = Icons.wb_sunny;
    } else if (hour < 17) {
      greeting = 'Good Afternoon';
      greetingIcon = Icons.wb_sunny_outlined;
    } else {
      greeting = 'Good Evening';
      greetingIcon = Icons.nights_stay;
    }
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                greetingIcon,
                color: Colors.white,
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                greeting,
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Welcome to your Staff Management Dashboard',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                color: Colors.white.withOpacity(0.8),
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                DateFormat('EEEE, MMMM dd, yyyy').format(now),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(DashboardData data, ThemeData theme) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          title: 'Total Staff',
          value: data.totalEmployees.toString(),
          icon: Icons.people,
          color: const Color(0xFF06B6D4),
          theme: theme,
        ),
        _buildStatCard(
          title: 'Active Staff',
          value: data.activeEmployees.toString(),
          icon: Icons.person,
          color: const Color(0xFF10B981),
          theme: theme,
        ),
        _buildStatCard(
          title: 'Present Today',
          value: data.presentToday.toString(),
          icon: Icons.check_circle,
          color: const Color(0xFF059669),
          theme: theme,
        ),
        _buildStatCard(
          title: 'Pending',
          value: data.pendingAttendance.toString(),
          icon: Icons.pending_actions,
          color: const Color(0xFFF59E0B),
          theme: theme,
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required ThemeData theme,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTodayAttendanceSection(DashboardData data, ThemeData theme) {
    final total = data.presentToday + data.absentToday;
    final presentPercentage = total > 0 ? (data.presentToday / total * 100).round() : 0;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.today,
                color: const Color(0xFF6366F1),
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Today\'s Attendance',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildAttendanceBar(
                  label: 'Present',
                  count: data.presentToday,
                  percentage: presentPercentage,
                  color: const Color(0xFF10B981),
                  theme: theme,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildAttendanceBar(
                  label: 'Absent',
                  count: data.absentToday,
                  percentage: 100 - presentPercentage,
                  color: const Color(0xFFEF4444),
                  theme: theme,
                ),
              ),
            ],
          ),
          if (data.pendingAttendance > 0) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFFF59E0B),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: const Color(0xFFF59E0B),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${data.pendingAttendance} attendance records pending',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF92400E),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAttendanceBar({
    required String label,
    required int count,
    required int percentage,
    required Color color,
    required ThemeData theme,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: const Color(0xFF64748B),
              ),
            ),
            Text(
              count.toString(),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(4),
          ),
          child: FractionallySizedBox(
            widthFactor: percentage / 100,
            alignment: Alignment.centerLeft,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$percentage%',
          style: theme.textTheme.bodySmall?.copyWith(
            color: const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklyAttendanceChart(DashboardData data, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.bar_chart,
                color: const Color(0xFF6366F1),
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Weekly Attendance Trend',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Simple bar chart representation
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: data.weeklyAttendance.map((dayData) {
                final total = dayData.present + dayData.absent;
                final height = total > 0 ? (dayData.present / total * 100).toDouble() : 0.0;
                final date = DateTime.parse(dayData.date);
                final dayName = DateFormat('E').format(date);
                
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          height: height + 10, // Add minimum height
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          dayName,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.flash_on,
                color: const Color(0xFF6366F1),
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Quick Actions',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildQuickActionButton(
                  icon: Icons.person_add,
                  label: 'Add Staff',
                  color: const Color(0xFF10B981),
                  onTap: () {
                    // Navigate to staff screen
                    if (widget.onNavigateToEmployees != null) {
                      widget.onNavigateToEmployees!();
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionButton(
                  icon: Icons.fact_check,
                  label: 'Mark Attendance',
                  color: const Color(0xFF6366F1),
                  onTap: () {
                    // Navigate to attendance screen
                    if (widget.onNavigateToAttendance != null) {
                      widget.onNavigateToAttendance!();
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildQuickActionButton(
                  icon: Icons.analytics,
                  label: 'View Reports',
                  color: const Color(0xFF8B5CF6),
                  onTap: () {
                    // Show placeholder for reports
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Reports feature coming soon!'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionButton(
                  icon: Icons.payment,
                  label: 'Payments',
                  color: const Color(0xFF06B6D4),
                  onTap: () {
                    // Show placeholder for payments
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Payments feature coming soon!'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: color,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity(DashboardData data, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.history,
                color: const Color(0xFF6366F1),
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Recent Activity',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (data.recentAttendance.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'No recent activity',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF64748B),
                  ),
                ),
              ),
            )
          else
            ...data.recentAttendance.map((attendance) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: attendance.status == 'present'
                            ? const Color(0xFF10B981)
                            : const Color(0xFFEF4444),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Employee ${attendance.employeeId} marked ${attendance.status}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF334155),
                        ),
                      ),
                    ),
                    Text(
                      attendance.shiftType,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
        ],
      ),
    );
  }
}

class DashboardData {
  final int totalEmployees;
  final int activeEmployees;
  final int presentToday;
  final int absentToday;
  final int pendingAttendance;
  final List<DailyAttendanceData> weeklyAttendance;
  final List<Employee> upcomingBirthdays;
  final List<Attendance> recentAttendance;

  DashboardData({
    required this.totalEmployees,
    required this.activeEmployees,
    required this.presentToday,
    required this.absentToday,
    required this.pendingAttendance,
    required this.weeklyAttendance,
    required this.upcomingBirthdays,
    required this.recentAttendance,
  });
}

class DailyAttendanceData {
  final String date;
  final int present;
  final int absent;

  DailyAttendanceData({
    required this.date,
    required this.present,
    required this.absent,
  });
}
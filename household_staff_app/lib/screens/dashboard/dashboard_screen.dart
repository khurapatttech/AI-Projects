import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/employee.dart';
import '../../models/dashboard_data.dart';
import '../../services/database_service.dart';
import '../../utils/screen_size.dart';

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
  // Widget state
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
      body: LayoutBuilder(
        builder: (context, constraints) {
          return FutureBuilder<DashboardData>(
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
              padding: EdgeInsets.all(MediaQuery.of(context).size.width < 600 ? 12.0 : 16.0),
              clipBehavior: Clip.none,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome section
                  _buildWelcomeSection(theme),
                  SizedBox(height: MediaQuery.of(context).size.width < 600 ? 16 : 24),
                  
                  // Statistics cards
                  _buildStatsGrid(data, theme),
                  SizedBox(height: MediaQuery.of(context).size.width < 600 ? 16 : 24),
                  
                  // Today's attendance overview
                  _buildTodayAttendanceSection(data, theme),
                  SizedBox(height: MediaQuery.of(context).size.width < 600 ? 16 : 24),
                  
                  // Weekly attendance chart
                  _buildWeeklyAttendanceChart(data, theme),
                  SizedBox(height: MediaQuery.of(context).size.width < 600 ? 16 : 24),
                  
                  // Quick actions
                  _buildQuickActions(theme),
                  SizedBox(height: MediaQuery.of(context).size.width < 600 ? 16 : 24),
                  
                  // Recent activity
                  _buildRecentActivity(data, theme),
                  
                  // Bottom padding
                  SizedBox(height: MediaQuery.of(context).size.width < 600 ? 16 : 24),
                ],
              ),
            ),
          );
            },
          );
        }
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
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isMobile = screenWidth < 600;
        
        final iconSize = isMobile ? 24.0 : 28.0;
        final greetingFontSize = isMobile ? 22.0 : 28.0;
        final bodyFontSize = isMobile ? 14.0 : 16.0;
        final dateFontSize = isMobile ? 12.0 : 14.0;
        
        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(isMobile ? 16 : 20),
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
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(
                    greetingIcon,
                    color: Colors.white,
                    size: iconSize,
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      greeting,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: greetingFontSize,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Welcome to your Staff Management Dashboard',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: bodyFontSize,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: isMobile ? 12 : 16),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    color: Colors.white.withOpacity(0.8),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      DateFormat('EEEE, MMMM dd, yyyy').format(now),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: dateFontSize,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatsGrid(DashboardData data, ThemeData theme) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isTablet = screenWidth >= 600 && screenWidth < 1200;
        final isDesktop = screenWidth >= 1200;
        
        // Responsive grid layout
        if (isDesktop) {
          // Desktop: 4 cards in a row
          return Row(
            children: [
              Expanded(child: _buildStatCard(
                title: 'Total Staff',
                value: data.totalEmployees.toString(),
                icon: Icons.people,
                color: const Color(0xFF06B6D4),
                theme: theme,
              )),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard(
                title: 'Active Staff',
                value: data.activeEmployees.toString(),
                icon: Icons.person,
                color: const Color(0xFF10B981),
                theme: theme,
              )),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard(
                title: 'Present Today',
                value: data.presentToday.toString(),
                icon: Icons.check_circle,
                color: const Color(0xFF059669),
                theme: theme,
              )),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard(
                title: 'Pending',
                value: data.pendingAttendance.toString(),
                icon: Icons.pending_actions,
                color: const Color(0xFFF59E0B),
                theme: theme,
              )),
            ],
          );
        } else if (isTablet) {
          // Tablet: 2x2 grid
          return Column(
            children: [
              Row(
                children: [
                  Expanded(child: _buildStatCard(
                    title: 'Total Staff',
                    value: data.totalEmployees.toString(),
                    icon: Icons.people,
                    color: const Color(0xFF06B6D4),
                    theme: theme,
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: _buildStatCard(
                    title: 'Active Staff',
                    value: data.activeEmployees.toString(),
                    icon: Icons.person,
                    color: const Color(0xFF10B981),
                    theme: theme,
                  )),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildStatCard(
                    title: 'Present Today',
                    value: data.presentToday.toString(),
                    icon: Icons.check_circle,
                    color: const Color(0xFF059669),
                    theme: theme,
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: _buildStatCard(
                    title: 'Pending',
                    value: data.pendingAttendance.toString(),
                    icon: Icons.pending_actions,
                    color: const Color(0xFFF59E0B),
                    theme: theme,
                  )),
                ],
              ),
            ],
          );
        } else {
          // Mobile: 2x2 grid with smaller spacing
          return Column(
            children: [
              Row(
                children: [
                  Expanded(child: _buildStatCard(
                    title: 'Total Staff',
                    value: data.totalEmployees.toString(),
                    icon: Icons.people,
                    color: const Color(0xFF06B6D4),
                    theme: theme,
                  )),
                  const SizedBox(width: 8),
                  Expanded(child: _buildStatCard(
                    title: 'Active Staff',
                    value: data.activeEmployees.toString(),
                    icon: Icons.person,
                    color: const Color(0xFF10B981),
                    theme: theme,
                  )),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: _buildStatCard(
                    title: 'Present Today',
                    value: data.presentToday.toString(),
                    icon: Icons.check_circle,
                    color: const Color(0xFF059669),
                    theme: theme,
                  )),
                  const SizedBox(width: 8),
                  Expanded(child: _buildStatCard(
                    title: 'Pending',
                    value: data.pendingAttendance.toString(),
                    icon: Icons.pending_actions,
                    color: const Color(0xFFF59E0B),
                    theme: theme,
                  )),
                ],
              ),
            ],
          );
        }
      },
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required ThemeData theme,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isMobile = screenWidth < 600;
        
        // Responsive sizing
        final iconSize = isMobile ? 24.0 : 28.0;
        final padding = isMobile ? 12.0 : 16.0;
        final titleFontSize = isMobile ? 11.0 : 13.0;
        final valueFontSize = isMobile ? 18.0 : 22.0;
        
        return Container(
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
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
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(padding * 0.5),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: iconSize,
                ),
              ),
              SizedBox(height: padding * 0.8),
              Text(
                value,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: valueFontSize,
                  color: const Color(0xFF1E293B),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: padding * 0.3),
              Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: titleFontSize,
                  color: const Color(0xFF64748B),
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ],
          ),
        );
      },
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
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                Icons.bar_chart,
                color: const Color(0xFF6366F1),
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Weekly Attendance Trend',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Responsive chart container
          LayoutBuilder(
            builder: (context, constraints) {
              final screenWidth = MediaQuery.of(context).size.width;
              final chartHeight = screenWidth < 600 ? 100.0 : 120.0;
              
              return SizedBox(
                height: chartHeight,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: data.weeklyAttendance.map((dayData) {
                    final total = dayData.present + dayData.absent;
                    final height = total > 0 ? (dayData.present / total * (chartHeight - 30)).toDouble() : 10.0;
                    final date = DateTime.parse(dayData.date);
                    final dayName = DateFormat('E').format(date);
                    
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Container(
                                width: double.infinity,
                                height: height.clamp(8.0, chartHeight - 25),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981),
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(4),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              dayName,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: const Color(0xFF64748B),
                                fontSize: screenWidth < 600 ? 10 : 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              );
            },
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
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                Icons.flash_on,
                color: const Color(0xFF6366F1),
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Quick Actions',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final screenWidth = MediaQuery.of(context).size.width;
              final isTabletOrDesktop = screenWidth >= 600;
              
              if (isTabletOrDesktop) {
                // Tablet/Desktop: 2x2 grid
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildQuickActionButton(
                            icon: Icons.person_add,
                            label: 'Add Staff',
                            color: const Color(0xFF10B981),
                            onTap: () {
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
                );
              } else {
                // Mobile: 2x2 grid with smaller spacing
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildQuickActionButton(
                            icon: Icons.person_add,
                            label: 'Add Staff',
                            color: const Color(0xFF10B981),
                            onTap: () {
                              if (widget.onNavigateToEmployees != null) {
                                widget.onNavigateToEmployees!();
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildQuickActionButton(
                            icon: Icons.fact_check,
                            label: 'Mark Attendance',
                            color: const Color(0xFF6366F1),
                            onTap: () {
                              if (widget.onNavigateToAttendance != null) {
                                widget.onNavigateToAttendance!();
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildQuickActionButton(
                            icon: Icons.analytics,
                            label: 'View Reports',
                            color: const Color(0xFF8B5CF6),
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Reports feature coming soon!'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildQuickActionButton(
                            icon: Icons.payment,
                            label: 'Payments',
                            color: const Color(0xFF06B6D4),
                            onTap: () {
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
                );
              }
            },
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isMobile = screenWidth < 600;
        
        final iconSize = isMobile ? 20.0 : 24.0;
        final fontSize = isMobile ? 11.0 : 12.0;
        final padding = isMobile ? 12.0 : 16.0;
        
        return InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: EdgeInsets.all(padding),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: color.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  color: color,
                  size: iconSize,
                ),
                SizedBox(height: padding * 0.5),
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: fontSize,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
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


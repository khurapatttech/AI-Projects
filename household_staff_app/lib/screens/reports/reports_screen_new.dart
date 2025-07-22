import 'package:flutter/material.dart';
import '../../models/employee.dart';
import '../../models/attendance.dart';
import '../../services/database_service.dart';
import 'package:intl/intl.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({Key? key}) : super(key: key);

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  Employee? _selectedEmployee;
  String _selectedPeriod = 'Last 2 weeks';
  List<Employee> _employees = [];
  List<DailyReport> _dailyReports = [];
  bool _isLoading = false;
  bool _isCalendarView = false; // Toggle between list and calendar view
  
  final List<String> _periodOptions = [
    'Last 7 days',
    'Last 2 weeks',
    'Last month',
    'Custom range'
  ];

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  Future<void> _loadEmployees() async {
    try {
      final employees = await DatabaseService().getAllEmployees();
      setState(() {
        _employees = employees.where((e) => e.activeStatus).toList();
        if (_employees.isNotEmpty) {
          _selectedEmployee = _employees.first;
          _generateReport();
        }
      });
    } catch (e) {
      print('Error loading employees: $e');
    }
  }

  Future<void> _generateReport() async {
    if (_selectedEmployee == null) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final dateRange = _getDateRange();
      final allAttendance = await DatabaseService().getAllAttendance();
      
      // Filter attendance for selected employee and date range
      final employeeAttendance = allAttendance.where((att) => 
        att.employeeId == _selectedEmployee!.id &&
        _isDateInRange(DateTime.parse(att.date), dateRange)
      ).toList();

      // Generate daily reports
      final reports = <DailyReport>[];
      for (var date = dateRange.start; date.isBefore(dateRange.end) || date.isAtSameMomentAs(dateRange.end); date = date.add(const Duration(days: 1))) {
        final dateString = DateFormat('yyyy-MM-dd').format(date);
        final dayAttendance = employeeAttendance.where((att) => att.date == dateString).toList();
        
        reports.add(_createDailyReport(date, dayAttendance));
      }

      setState(() {
        _dailyReports = reports.reversed.toList(); // Most recent first
        _isLoading = false;
      });
    } catch (e) {
      print('Error generating report: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  DateTimeRange _getDateRange() {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case 'Last 7 days':
        return DateTimeRange(
          start: now.subtract(const Duration(days: 6)),
          end: now,
        );
      case 'Last 2 weeks':
        return DateTimeRange(
          start: now.subtract(const Duration(days: 13)),
          end: now,
        );
      case 'Last month':
        return DateTimeRange(
          start: now.subtract(const Duration(days: 29)),
          end: now,
        );
      default:
        return DateTimeRange(
          start: now.subtract(const Duration(days: 13)),
          end: now,
        );
    }
  }

  bool _isDateInRange(DateTime date, DateTimeRange range) {
    return (date.isAfter(range.start) || date.isAtSameMomentAs(range.start)) &&
           (date.isBefore(range.end) || date.isAtSameMomentAs(range.end));
  }

  DailyReport _createDailyReport(DateTime date, List<Attendance> dayAttendance) {
    final weekday = DateFormat('EEEE').format(date);
    
    // Check if it's an off day
    final isFullOff = _selectedEmployee!.offDays.contains(weekday);
    if (isFullOff) {
      return DailyReport(
        date: date,
        status: 'off',
        shifts: [],
        hasComments: false,
        comments: null,
      );
    }

    final shifts = <ShiftReport>[];
    String overallStatus = 'pending';
    bool hasComments = false;
    List<String> commentsList = [];

    if (_selectedEmployee!.visitsPerDay == 1) {
      // Single visit employee
      final att = dayAttendance.where((a) => a.shiftType == 'full_day').firstOrNull;
      if (att != null) {
        overallStatus = att.status;
        if (att.comments != null && att.comments!.isNotEmpty) {
          hasComments = true;
          commentsList.add(att.comments!);
        }
      }
      shifts.add(ShiftReport(
        shiftType: 'full_day',
        status: att?.status ?? 'pending',
        comments: att?.comments,
      ));
    } else {
      // Double visit employee
      final partialOffs = _selectedEmployee!.partialOffDays[weekday] ?? [];
      
      // Morning shift
      if (!partialOffs.contains('morning')) {
        final morningAtt = dayAttendance.where((a) => a.shiftType == 'morning').firstOrNull;
        shifts.add(ShiftReport(
          shiftType: 'morning',
          status: morningAtt?.status ?? 'pending',
          comments: morningAtt?.comments,
        ));
        if (morningAtt?.comments != null && morningAtt!.comments!.isNotEmpty) {
          hasComments = true;
          commentsList.add('Morning: ${morningAtt.comments}');
        }
      } else {
        shifts.add(ShiftReport(
          shiftType: 'morning',
          status: 'off',
          comments: null,
        ));
      }
      
      // Evening shift
      if (!partialOffs.contains('evening')) {
        final eveningAtt = dayAttendance.where((a) => a.shiftType == 'evening').firstOrNull;
        shifts.add(ShiftReport(
          shiftType: 'evening',
          status: eveningAtt?.status ?? 'pending',
          comments: eveningAtt?.comments,
        ));
        if (eveningAtt?.comments != null && eveningAtt!.comments!.isNotEmpty) {
          hasComments = true;
          commentsList.add('Evening: ${eveningAtt.comments}');
        }
      } else {
        shifts.add(ShiftReport(
          shiftType: 'evening',
          status: 'off',
          comments: null,
        ));
      }
      
      // Calculate overall status for double visit
      final workingShifts = shifts.where((s) => s.status != 'off').toList();
      if (workingShifts.isEmpty) {
        overallStatus = 'off';
      } else if (workingShifts.every((s) => s.status == 'present')) {
        overallStatus = 'present';
      } else if (workingShifts.any((s) => s.status == 'absent')) {
        overallStatus = 'absent';
      } else if (workingShifts.any((s) => s.status == 'present')) {
        overallStatus = 'partial';
      } else {
        overallStatus = 'pending';
      }
    }

    return DailyReport(
      date: date,
      status: overallStatus,
      shifts: shifts,
      hasComments: hasComments,
      comments: commentsList.isNotEmpty ? commentsList.join('\n') : null,
    );
  }

  ReportSummary _calculateSummary() {
    if (_dailyReports.isEmpty) {
      return ReportSummary(
        totalDays: 0,
        presentDays: 0,
        absentDays: 0,
        partialDays: 0,
        offDays: 0,
        pendingDays: 0,
      );
    }

    int totalDays = 0;
    int presentDays = 0;
    int absentDays = 0;
    int partialDays = 0;
    int offDays = 0;
    int pendingDays = 0;

    for (final report in _dailyReports) {
      totalDays++;
      switch (report.status) {
        case 'present':
          presentDays++;
          break;
        case 'absent':
          absentDays++;
          break;
        case 'partial':
          partialDays++;
          break;
        case 'off':
          offDays++;
          break;
        case 'pending':
          pendingDays++;
          break;
      }
    }

    return ReportSummary(
      totalDays: totalDays,
      presentDays: presentDays,
      absentDays: absentDays,
      partialDays: partialDays,
      offDays: offDays,
      pendingDays: pendingDays,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Reports'),
        elevation: 0,
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
      ),
      body: _employees.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Employee and Period Selection
                  _buildSelectionSection(),
                  
                  // Summary Card
                  if (_selectedEmployee != null && !_isLoading)
                    _buildSummaryCard(),
                  
                  // Calendar View Toggle
                  if (_selectedEmployee != null && !_isLoading)
                    _buildViewToggle(),
                  
                  // Daily Reports Content
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else
                    _buildReportsContent(),
                ],
              ),
            ),
    );
  }

  Widget _buildSelectionSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Employee Selection
          Row(
            children: [
              const Icon(Icons.person, color: Color(0xFF6366F1)),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButton<Employee>(
                  isExpanded: true,
                  value: _selectedEmployee,
                  hint: const Text('Select Employee'),
                  items: _employees.map((employee) {
                    return DropdownMenuItem<Employee>(
                      value: employee,
                      child: Text(employee.name),
                    );
                  }).toList(),
                  onChanged: (Employee? newEmployee) {
                    setState(() {
                      _selectedEmployee = newEmployee;
                    });
                    if (newEmployee != null) {
                      _generateReport();
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Period Selection
          Row(
            children: [
              const Icon(Icons.calendar_today, color: Color(0xFF6366F1)),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: _selectedPeriod,
                  items: _periodOptions.map((period) {
                    return DropdownMenuItem<String>(
                      value: period,
                      child: Text(period),
                    );
                  }).toList(),
                  onChanged: (String? newPeriod) {
                    setState(() {
                      _selectedPeriod = newPeriod ?? 'Last 2 weeks';
                    });
                    _generateReport();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildViewToggle() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _isCalendarView = false),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: !_isCalendarView ? const Color(0xFF6366F1) : Colors.transparent,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.list,
                      color: !_isCalendarView ? Colors.white : Colors.grey.shade600,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'List View',
                      style: TextStyle(
                        color: !_isCalendarView ? Colors.white : Colors.grey.shade600,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _isCalendarView = true),
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _isCalendarView ? const Color(0xFF6366F1) : Colors.transparent,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.calendar_month,
                      color: _isCalendarView ? Colors.white : Colors.grey.shade600,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Calendar View',
                      style: TextStyle(
                        color: _isCalendarView ? Colors.white : Colors.grey.shade600,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportsContent() {
    if (_dailyReports.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32.0),
        child: Center(
          child: Text('No data available for selected period'),
        ),
      );
    }

    return _isCalendarView ? _buildCalendarView() : _buildDailyReportsList();
  }

  Widget _buildSummaryCard() {
    final summary = _calculateSummary();
    final workingDays = summary.totalDays - summary.offDays;
    final attendanceRate = workingDays > 0 
        ? ((summary.presentDays + (summary.partialDays * 0.5)) / workingDays * 100).round()
        : 0;

    return Container(
      margin: const EdgeInsets.all(16),
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
        children: [
          Row(
            children: [
              const Icon(Icons.analytics, color: Color(0xFF6366F1)),
              const SizedBox(width: 12),
              Text(
                '${_selectedEmployee!.name}\'s Report',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _selectedPeriod,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 16),
          
          // Summary Stats Grid
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Working Days',
                  workingDays.toString(),
                  Colors.blue,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Present',
                  '${summary.presentDays} (${workingDays > 0 ? (summary.presentDays / workingDays * 100).round() : 0}%)',
                  Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Absent',
                  '${summary.absentDays} (${workingDays > 0 ? (summary.absentDays / workingDays * 100).round() : 0}%)',
                  Colors.red,
                ),
              ),
              if (summary.partialDays > 0)
                Expanded(
                  child: _buildStatItem(
                    'Partial',
                    '${summary.partialDays}',
                    Colors.orange,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Attendance Rate
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: attendanceRate >= 80 ? Colors.green.shade50 : Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: attendanceRate >= 80 ? Colors.green.shade200 : Colors.orange.shade200,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  attendanceRate >= 80 ? Icons.trending_up : Icons.trending_down,
                  color: attendanceRate >= 80 ? Colors.green.shade700 : Colors.orange.shade700,
                ),
                const SizedBox(width: 8),
                Text(
                  'Attendance Rate: $attendanceRate%',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: attendanceRate >= 80 ? Colors.green.shade700 : Colors.orange.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarView() {
    final dateRange = _getDateRange();
    final startDate = dateRange.start;
    final endDate = dateRange.end;
    
    // Calculate the first day of the month containing startDate
    final firstDayOfMonth = DateTime(startDate.year, startDate.month, 1);
    // Calculate which day of the week the month starts on (0 = Sunday, 6 = Saturday)
    final firstWeekday = firstDayOfMonth.weekday % 7;
    
    // Build calendar grid
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
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
        children: [
          Text(
            'Calendar View',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),
          
          // Weekday headers
          Row(
            children: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
                .map((day) => Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          day,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
          
          // Calendar grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1,
            ),
            itemCount: _getCalendarDays(startDate, endDate).length,
            itemBuilder: (context, index) {
              final calendarDay = _getCalendarDays(startDate, endDate)[index];
              return _buildCalendarDay(calendarDay);
            },
          ),
          
          // Legend
          const SizedBox(height: 16),
          _buildCalendarLegend(),
        ],
      ),
    );
  }

  List<CalendarDay> _getCalendarDays(DateTime startDate, DateTime endDate) {
    final days = <CalendarDay>[];
    
    // Get the first day of the month containing startDate
    final firstDayOfMonth = DateTime(startDate.year, startDate.month, 1);
    final firstWeekday = firstDayOfMonth.weekday % 7;
    
    // Add empty days for the beginning of the calendar
    for (int i = 0; i < firstWeekday; i++) {
      days.add(CalendarDay(date: null, report: null, isInRange: false));
    }
    
    // Add all days from start to end
    for (var date = firstDayOfMonth; 
         date.isBefore(endDate.add(const Duration(days: 1))) && date.month == firstDayOfMonth.month; 
         date = date.add(const Duration(days: 1))) {
      
      final isInRange = (date.isAfter(startDate) || date.isAtSameMomentAs(startDate)) &&
                       (date.isBefore(endDate) || date.isAtSameMomentAs(endDate));
      
      DailyReport? report;
      if (isInRange) {
        report = _dailyReports.firstWhere(
          (r) => r.date.year == date.year && r.date.month == date.month && r.date.day == date.day,
          orElse: () => DailyReport(
            date: date,
            status: 'pending',
            shifts: [],
            hasComments: false,
            comments: null,
          ),
        );
      }
      
      days.add(CalendarDay(date: date, report: report, isInRange: isInRange));
    }
    
    return days;
  }

  Widget _buildCalendarDay(CalendarDay calendarDay) {
    if (calendarDay.date == null) {
      return const SizedBox(); // Empty day
    }
    
    final date = calendarDay.date!;
    final report = calendarDay.report;
    final isInRange = calendarDay.isInRange;
    
    Color? backgroundColor;
    Color? borderColor;
    Color textColor = Colors.black87;
    
    if (!isInRange) {
      backgroundColor = Colors.grey.shade100;
      textColor = Colors.grey.shade400;
    } else if (report != null) {
      switch (report.status) {
        case 'present':
          backgroundColor = Colors.green.shade100;
          borderColor = Colors.green.shade300;
          break;
        case 'absent':
          backgroundColor = Colors.red.shade100;
          borderColor = Colors.red.shade300;
          break;
        case 'partial':
          backgroundColor = Colors.orange.shade100;
          borderColor = Colors.orange.shade300;
          break;
        case 'off':
          backgroundColor = Colors.grey.shade200;
          borderColor = Colors.grey.shade400;
          textColor = Colors.grey.shade600;
          break;
        default:
          backgroundColor = Colors.blue.shade50;
          borderColor = Colors.blue.shade200;
          break;
      }
    }
    
    return GestureDetector(
      onTap: isInRange && report != null && report.hasComments
          ? () => _showCommentsDialog(report)
          : null,
      child: Container(
        margin: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          color: backgroundColor,
          border: borderColor != null ? Border.all(color: borderColor) : null,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Stack(
          children: [
            Center(
              child: Text(
                '${date.day}',
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
            if (report?.hasComments == true)
              Positioned(
                top: 2,
                right: 2,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade700,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildLegendItem('Present', Colors.green.shade100, Colors.green.shade300),
        _buildLegendItem('Absent', Colors.red.shade100, Colors.red.shade300),
        _buildLegendItem('Partial', Colors.orange.shade100, Colors.orange.shade300),
        _buildLegendItem('Off Day', Colors.grey.shade200, Colors.grey.shade400),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color backgroundColor, Color borderColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: backgroundColor,
            border: Border.all(color: borderColor),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildDailyReportsList() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: _dailyReports.map((report) => _buildDailyReportCard(report)).toList(),
      ),
    );
  }

  Widget _buildDailyReportCard(DailyReport report) {
    final color = _getStatusColor(report.status);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: report.hasComments ? () => _showCommentsDialog(report) : null,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Date
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('MMM dd').format(report.date),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      DateFormat('EEEE').format(report.date),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Status and Shift Info
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _getStatusText(report.status),
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (report.status != 'off')
                      _buildShiftInfo(report.shifts),
                  ],
                ),
              ),
              
              // Comments indicator
              if (report.hasComments)
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.comment,
                    size: 16,
                    color: Colors.blue.shade700,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShiftInfo(List<ShiftReport> shifts) {
    if (shifts.length == 1 && shifts.first.shiftType == 'full_day') {
      return Text(
        'Full Day',
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey.shade600,
        ),
      );
    }

    return Row(
      children: shifts.map((shift) {
        final shiftColor = _getStatusColor(shift.status);
        final shiftText = shift.shiftType == 'morning' ? 'AM' : 'PM';
        final icon = shift.status == 'present' ? '✓' : 
                    shift.status == 'absent' ? '✗' : 
                    shift.status == 'off' ? '-' : '?';
        
        return Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: shiftColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            '$shiftText $icon',
            style: TextStyle(
              fontSize: 11,
              color: shiftColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      }).toList(),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'present':
        return Colors.green;
      case 'absent':
        return Colors.red;
      case 'partial':
        return Colors.orange;
      case 'off':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'present':
        return 'Present';
      case 'absent':
        return 'Absent';
      case 'partial':
        return 'Partial';
      case 'off':
        return 'Off Day';
      default:
        return 'Pending';
    }
  }

  void _showCommentsDialog(DailyReport report) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Comments - ${DateFormat('MMM dd, yyyy').format(report.date)}'),
        content: Text(report.comments ?? 'No comments'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

// Data Models
class DailyReport {
  final DateTime date;
  final String status; // present, absent, partial, off, pending
  final List<ShiftReport> shifts;
  final bool hasComments;
  final String? comments;

  DailyReport({
    required this.date,
    required this.status,
    required this.shifts,
    required this.hasComments,
    this.comments,
  });
}

class ShiftReport {
  final String shiftType; // full_day, morning, evening
  final String status; // present, absent, off, pending
  final String? comments;

  ShiftReport({
    required this.shiftType,
    required this.status,
    this.comments,
  });
}

class ReportSummary {
  final int totalDays;
  final int presentDays;
  final int absentDays;
  final int partialDays;
  final int offDays;
  final int pendingDays;

  ReportSummary({
    required this.totalDays,
    required this.presentDays,
    required this.absentDays,
    required this.partialDays,
    required this.offDays,
    required this.pendingDays,
  });
}

class CalendarDay {
  final DateTime? date;
  final DailyReport? report;
  final bool isInRange;

  CalendarDay({
    required this.date,
    required this.report,
    required this.isInRange,
  });
}

// Extension to get first element or null
extension FirstWhereOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    if (iterator.moveNext()) {
      return iterator.current;
    }
    return null;
  }
}

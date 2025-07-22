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
  String _selectedPeriod = '';
  List<Employee> _employees = [];
  List<DailyReport> _dailyReports = [];
  bool _isLoading = false;
  
  List<String> _periodOptions = [];

  @override
  void initState() {
    super.initState();
    _generatePeriodOptions();
    _loadEmployees();
  }

  void _generatePeriodOptions() {
    final now = DateTime.now();
    final options = <String>[];
    
    // Generate last 6 months
    for (int i = 0; i < 6; i++) {
      final date = DateTime(now.year, now.month - i, 1);
      final monthName = DateFormat('MMMM yyyy').format(date);
      options.add(monthName);
    }
    
    setState(() {
      _periodOptions = options;
      _selectedPeriod = options.first; // Current month as default
    });
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
      print('🔍 Date range: ${DateFormat('yyyy-MM-dd').format(dateRange.start)} to ${DateFormat('yyyy-MM-dd').format(dateRange.end)}');
      
      final allAttendance = await DatabaseService().getAllAttendance();
      print('📊 Total attendance records: ${allAttendance.length}');
      
      // Filter attendance for selected employee and date range
      final employeeAttendance = allAttendance.where((att) => 
        att.employeeId == _selectedEmployee!.id &&
        _isDateInRange(DateTime.parse(att.date), dateRange)
      ).toList();
      
      print('👤 Employee attendance records: ${employeeAttendance.length}');

      // Generate daily reports
      final reports = <DailyReport>[];
      final joiningDate = DateTime.parse(_selectedEmployee!.joiningDate);
      print('📅 Employee joining date: ${DateFormat('yyyy-MM-dd').format(joiningDate)}');
      
      for (var date = dateRange.start; date.isBefore(dateRange.end) || date.isAtSameMomentAs(dateRange.end); date = date.add(const Duration(days: 1))) {
        // Skip dates before joining
        if (date.isBefore(joiningDate)) {
          continue;
        }
        
        final dateString = DateFormat('yyyy-MM-dd').format(date);
        final dayAttendance = employeeAttendance.where((att) => att.date == dateString).toList();
        
        reports.add(_createDailyReport(date, dayAttendance));
      }

      print('📋 Generated ${reports.length} daily reports');
      setState(() {
        _dailyReports = reports.reversed.toList(); // Most recent first
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error generating report: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  DateTimeRange _getDateRange() {
    final now = DateTime.now();
    
    // Parse the selected period to get the month and year
    try {
      final selectedDate = DateFormat('MMMM yyyy').parse(_selectedPeriod);
      
      // Get the first day of the selected month
      final startDate = DateTime(selectedDate.year, selectedDate.month, 1);
      
      // Get the last day of the selected month
      final endDate = DateTime(selectedDate.year, selectedDate.month + 1, 0);
      
      return DateTimeRange(start: startDate, end: endDate);
    } catch (e) {
      // Fallback to current month if parsing fails
      print('Error parsing selected period: $e');
      final startDate = DateTime(now.year, now.month, 1);
      final endDate = DateTime(now.year, now.month + 1, 0);
      return DateTimeRange(start: startDate, end: endDate);
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
      } else {
        // Count different statuses
        final presentShifts = workingShifts.where((s) => s.status == 'present').length;
        final absentShifts = workingShifts.where((s) => s.status == 'absent').length;
        final pendingShifts = workingShifts.where((s) => s.status == 'pending').length;
        
        if (presentShifts == workingShifts.length) {
          // All working shifts are present
          overallStatus = 'present';
        } else if (absentShifts == workingShifts.length) {
          // All working shifts are absent
          overallStatus = 'absent';
        } else if (presentShifts > 0 && (absentShifts > 0 || pendingShifts > 0)) {
          // Mix of present with absent/pending = partial attendance
          overallStatus = 'partial';
        } else if (pendingShifts > 0) {
          // Only pending shifts remain
          overallStatus = 'pending';
        } else {
          // Default fallback
          overallStatus = 'pending';
        }
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
                  value: _selectedPeriod.isNotEmpty ? _selectedPeriod : null,
                  hint: const Text('Select Month'),
                  items: _periodOptions.map((period) {
                    return DropdownMenuItem<String>(
                      value: period,
                      child: Text(period),
                    );
                  }).toList(),
                  onChanged: (String? newPeriod) {
                    if (newPeriod != null) {
                      setState(() {
                        _selectedPeriod = newPeriod;
                      });
                      _generateReport();
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReportsContent() {
    if (_dailyReports.isEmpty) {
      final joiningDate = DateTime.parse(_selectedEmployee!.joiningDate);
      final dateRange = _getDateRange();
      final isJoiningAfterRange = joiningDate.isAfter(dateRange.end);
      
      return Padding(
        padding: const EdgeInsets.all(32.0),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.calendar_today,
                size: 48,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                isJoiningAfterRange 
                    ? 'Employee joined after selected period'
                    : 'No data available for selected period',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              if (isJoiningAfterRange) ...[
                const SizedBox(height: 8),
                Text(
                  'Joined: ${DateFormat('MMM dd, yyyy').format(joiningDate)}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade500,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return _buildCalendarView();
  }

  Widget _buildSummaryCard() {
    final summary = _calculateSummary();
    final workingDays = summary.totalDays - summary.offDays;
    final attendanceRate = workingDays > 0 
        ? ((summary.presentDays + (summary.partialDays * 0.5)) / workingDays * 100).round()
        : 0;
    
    // Calculate detailed shift breakdown for double visit employees
    final shiftBreakdown = _calculateShiftBreakdown();

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
          // Header
          Row(
            children: [
              const Icon(Icons.assessment, color: Color(0xFF6366F1)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_selectedEmployee!.name}\'s Summary',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    Text(
                      _selectedPeriod,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: attendanceRate >= 80 
                      ? Colors.green.shade100 
                      : attendanceRate >= 60 
                          ? Colors.orange.shade100 
                          : Colors.red.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$attendanceRate%',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: attendanceRate >= 80 
                        ? Colors.green.shade700 
                        : attendanceRate >= 60 
                            ? Colors.orange.shade700 
                            : Colors.red.shade700,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 4),
          Text(
            'Joined: ${DateFormat('MMM dd, yyyy').format(DateTime.parse(_selectedEmployee!.joiningDate))}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade500,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 20),
          
          // Stats Grid
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
                  '${summary.presentDays}',
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
                  '${summary.absentDays}',
                  Colors.red,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  summary.partialDays > 0 ? 'Partial' : 'Off Days',
                  summary.partialDays > 0 ? '${summary.partialDays}' : '${summary.offDays}',
                  summary.partialDays > 0 ? Colors.orange : Colors.grey,
                ),
              ),
            ],
          ),
          
          // Detailed breakdown for double visit employees
          if (_selectedEmployee!.visitsPerDay == 2 && summary.partialDays > 0) ...[
            const SizedBox(height: 16),
            _buildPartialAttendanceDetails(shiftBreakdown),
          ],
          
          // Shift breakdown for double visit employees
          if (_selectedEmployee!.visitsPerDay == 2) ...[
            const SizedBox(height: 16),
            _buildShiftBreakdown(shiftBreakdown),
          ],
        ],
      ),
    );
  }

  Map<String, int> _calculateShiftBreakdown() {
    if (_selectedEmployee!.visitsPerDay != 2) {
      return {};
    }

    int morningPresent = 0;
    int morningAbsent = 0;
    int eveningPresent = 0;
    int eveningAbsent = 0;
    int morningOff = 0;
    int eveningOff = 0;

    for (final report in _dailyReports) {
      if (report.status == 'off') continue; // Skip full off days
      
      for (final shift in report.shifts) {
        if (shift.shiftType == 'morning') {
          switch (shift.status) {
            case 'present':
              morningPresent++;
              break;
            case 'absent':
              morningAbsent++;
              break;
            case 'off':
              morningOff++;
              break;
          }
        } else if (shift.shiftType == 'evening') {
          switch (shift.status) {
            case 'present':
              eveningPresent++;
              break;
            case 'absent':
              eveningAbsent++;
              break;
            case 'off':
              eveningOff++;
              break;
          }
        }
      }
    }

    return {
      'morningPresent': morningPresent,
      'morningAbsent': morningAbsent,
      'morningOff': morningOff,
      'eveningPresent': eveningPresent,
      'eveningAbsent': eveningAbsent,
      'eveningOff': eveningOff,
    };
  }

  Widget _buildPartialAttendanceDetails(Map<String, int> shiftBreakdown) {
    final summary = _calculateSummary();
    if (summary.partialDays == 0) return const SizedBox();

    // Calculate partial day breakdowns
    int morningMissedPartial = 0;
    int eveningMissedPartial = 0;
    
    for (final report in _dailyReports) {
      if (report.status == 'partial') {
        final morningShift = report.shifts.where((s) => s.shiftType == 'morning').firstOrNull;
        final eveningShift = report.shifts.where((s) => s.shiftType == 'evening').firstOrNull;
        
        if (morningShift?.status == 'absent') morningMissedPartial++;
        if (eveningShift?.status == 'absent') eveningMissedPartial++;
      }
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.orange.shade600, size: 16),
              const SizedBox(width: 6),
              Text(
                'Partial Attendance Details',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.orange.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildPartialDetailItem(
                  'Morning Missed',
                  morningMissedPartial,
                  Icons.wb_sunny,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildPartialDetailItem(
                  'Evening Missed',
                  eveningMissedPartial,
                  Icons.nights_stay,
                  Colors.indigo,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPartialDetailItem(String label, int count, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade600,
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

  Widget _buildShiftBreakdown(Map<String, int> shiftBreakdown) {
    if (shiftBreakdown.isEmpty) return const SizedBox();

    final morningTotal = shiftBreakdown['morningPresent']! + shiftBreakdown['morningAbsent']!;
    final eveningTotal = shiftBreakdown['eveningPresent']! + shiftBreakdown['eveningAbsent']!;
    
    final morningRate = morningTotal > 0 
        ? (shiftBreakdown['morningPresent']! / morningTotal * 100).round()
        : 0;
    final eveningRate = eveningTotal > 0 
        ? (shiftBreakdown['eveningPresent']! / eveningTotal * 100).round()
        : 0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.schedule, color: Colors.blue.shade600, size: 16),
              const SizedBox(width: 6),
              Text(
                'Shift-wise Breakdown',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildShiftStatItem(
                  'Morning Shift',
                  shiftBreakdown['morningPresent']!,
                  shiftBreakdown['morningAbsent']!,
                  morningRate,
                  Icons.wb_sunny,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildShiftStatItem(
                  'Evening Shift',
                  shiftBreakdown['eveningPresent']!,
                  shiftBreakdown['eveningAbsent']!,
                  eveningRate,
                  Icons.nights_stay,
                  Colors.indigo,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShiftStatItem(String label, int present, int absent, int rate, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: rate >= 80 
                      ? Colors.green.shade100 
                      : rate >= 60 
                          ? Colors.orange.shade100 
                          : Colors.red.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$rate%',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: rate >= 80 
                        ? Colors.green.shade700 
                        : rate >= 60 
                            ? Colors.orange.shade700 
                            : Colors.red.shade700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    present.toString(),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade600,
                    ),
                  ),
                  Text(
                    'Present',
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    absent.toString(),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade600,
                    ),
                  ),
                  Text(
                    'Absent',
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ],
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
              fontWeight: FontWeight.w500,
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
          Row(
            children: [
              Text(
                'Calendar View',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const Spacer(),
              Text(
                _selectedPeriod,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
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
    
    // For month view, show complete month grid
    final firstDayOfMonth = DateTime(startDate.year, startDate.month, 1);
    final lastDayOfMonth = DateTime(startDate.year, startDate.month + 1, 0);
    
    // Get first day of the grid (might be from previous month)
    final firstDayOfGrid = firstDayOfMonth.subtract(
      Duration(days: firstDayOfMonth.weekday % 7),
    );
    
    // Calculate total days needed for complete grid (6 weeks max)
    final totalDays = 42; // 6 weeks * 7 days
    
    for (int i = 0; i < totalDays; i++) {
      final currentDate = firstDayOfGrid.add(Duration(days: i));
      final isCurrentMonth = currentDate.month == startDate.month && currentDate.year == startDate.year;
      
      if (currentDate.isAfter(lastDayOfMonth)) {
        // Stop if we've gone past the last day of the month and completed enough weeks
        final completedWeeks = days.length ~/ 7;
        if (completedWeeks >= 5) break; // Stop after 5-6 weeks
      }
      
      DailyReport? report;
      if (isCurrentMonth) {
        report = _dailyReports.firstWhere(
          (r) => r.date.year == currentDate.year && 
                 r.date.month == currentDate.month && 
                 r.date.day == currentDate.day,
          orElse: () => DailyReport(
            date: currentDate,
            status: 'pending',
            shifts: [],
            hasComments: false,
            comments: null,
          ),
        );
      }
      
      days.add(CalendarDay(
        date: currentDate, 
        report: report, 
        isInRange: isCurrentMonth
      ));
    }
    
    return days;
  }

  Widget _buildCalendarDay(CalendarDay calendarDay) {
    final date = calendarDay.date;
    final report = calendarDay.report;
    final isCurrentMonth = calendarDay.isInRange;
    
    // Check if date is before joining date for current month days
    bool isBeforeJoining = false;
    if (isCurrentMonth && _selectedEmployee != null && date != null) {
      final joiningDate = DateTime.parse(_selectedEmployee!.joiningDate);
      isBeforeJoining = date.isBefore(joiningDate);
    }
    
    Color? backgroundColor;
    Color? borderColor;
    Color textColor = Colors.black87;
    
    // For split color visualization
    Color? leftColor;
    Color? rightColor;
    bool showSplitColors = false;
    
    if (!isCurrentMonth) {
      // Date is from previous/next month - show grayed out
      backgroundColor = Colors.grey.shade50;
      textColor = Colors.grey.shade300;
    } else if (isBeforeJoining) {
      backgroundColor = Colors.orange.shade50;
      textColor = Colors.orange.shade300;
    } else if (report != null) {
      // Check if this is a double visit employee with individual shift data
      if (report.shifts.length > 1) {
        // Double visit employee - show split colors
        showSplitColors = true;
        final morningShift = report.shifts.firstWhere(
          (s) => s.shiftType == 'morning',
          orElse: () => ShiftReport(shiftType: 'morning', status: 'pending', comments: null),
        );
        final eveningShift = report.shifts.firstWhere(
          (s) => s.shiftType == 'evening',
          orElse: () => ShiftReport(shiftType: 'evening', status: 'pending', comments: null),
        );
        
        // Left half = Morning, Right half = Evening
        leftColor = _getShiftColor(morningShift.status);
        rightColor = _getShiftColor(eveningShift.status);
        
        // Set border color based on overall status
        borderColor = _getStatusColor(report.status);
      } else {
        // Single visit employee or full day off - use solid color
        switch (report.status) {
          case 'present':
            backgroundColor = Colors.green.shade100;
            borderColor = Colors.green.shade300;
            break;
          case 'absent':
            backgroundColor = Colors.red.shade100;
            borderColor = Colors.red.shade300;
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
    }
    
    return GestureDetector(
      onTap: isCurrentMonth && !isBeforeJoining && report != null && report.status != 'off'
          ? () => _showAttendanceUpdateDialog(report)
          : null,
      child: Container(
        margin: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          color: showSplitColors ? null : backgroundColor,
          border: borderColor != null ? Border.all(color: borderColor) : null,
          borderRadius: BorderRadius.circular(8),
        ),
        child: showSplitColors
            ? ClipRRect(
                borderRadius: BorderRadius.circular(7),
                child: Stack(
                  children: [
                    // Split background
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: double.infinity,
                            color: leftColor?.withOpacity(0.3) ?? Colors.grey.shade100,
                          ),
                        ),
                        Expanded(
                          child: Container(
                            height: double.infinity,
                            color: rightColor?.withOpacity(0.3) ?? Colors.grey.shade100,
                          ),
                        ),
                      ],
                    ),
                    // Center text
                    Center(
                      child: Text(
                        '${date?.day ?? ''}',
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    // Comments indicator
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
              )
            : Stack(
                children: [
                  Center(
                    child: Text(
                      '${date?.day ?? ''}',
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  // Special indicator removed - using split colors for double visits
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

  // Helper method to get color for individual shift status
  Color _getShiftColor(String status) {
    switch (status) {
      case 'present':
        return Colors.green.shade600;
      case 'absent':
        return Colors.red.shade600;
      case 'off':
        return Colors.grey.shade500;
      default:
        return Colors.blue.shade400; // pending
    }
  }

  Widget _buildCalendarLegend() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.grey.shade50, Colors.grey.shade100],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          // Title
          Row(
            children: [
              Icon(Icons.help_outline, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 6),
              Text(
                'Legend',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          
          // 3x2 Grid layout
          Column(
            children: [
              // First row
              Row(
                children: [
                  Expanded(
                    child: _buildCompactLegendItem('Present', Colors.green.shade100, Colors.green.shade400),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _buildCompactLegendItem('Absent', Colors.red.shade100, Colors.red.shade400),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _buildCompactLegendItem('Off Day', Colors.grey.shade200, Colors.grey.shade500),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // Second row
              Row(
                children: [
                  Expanded(
                    child: _buildCompactLegendItem('Pending', Colors.blue.shade50, Colors.blue.shade300),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _buildCompactLegendItem('Before Join', Colors.orange.shade50, Colors.orange.shade400),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _buildCompactLegendItem('Out of Range', Colors.grey.shade50, Colors.grey.shade300),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactLegendItem(String label, Color backgroundColor, Color borderColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: borderColor.withOpacity(0.15),
            blurRadius: 1,
            offset: const Offset(0, 0.5),
          ),
        ],
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
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


  void _showAttendanceUpdateDialog(DailyReport report) {
    // State variables for the dialog
    String? selectedMorningStatus;
    String? selectedEveningStatus;
    String? selectedFullDayStatus;
    final TextEditingController morningCommentController = TextEditingController();
    final TextEditingController eveningCommentController = TextEditingController();
    final TextEditingController fullDayCommentController = TextEditingController();
    
    // Initialize with current shift data
    if (_selectedEmployee!.visitsPerDay == 2) {
      final morningShift = report.shifts.where((s) => s.shiftType == 'morning').firstOrNull;
      final eveningShift = report.shifts.where((s) => s.shiftType == 'evening').firstOrNull;
      
      selectedMorningStatus = morningShift?.status ?? 'pending';
      selectedEveningStatus = eveningShift?.status ?? 'pending';
      morningCommentController.text = morningShift?.comments ?? '';
      eveningCommentController.text = eveningShift?.comments ?? '';
    } else {
      selectedFullDayStatus = report.status;
      fullDayCommentController.text = report.comments ?? '';
    }
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.edit_calendar, color: Colors.blue.shade600, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Update Attendance',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      DateFormat('EEEE, MMM dd, yyyy').format(report.date),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: Container(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Employee info
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.blue.shade100,
                          radius: 16,
                          child: Text(
                            _selectedEmployee!.name.substring(0, 1).toUpperCase(),
                            style: TextStyle(
                              color: Colors.blue.shade800,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedEmployee!.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                '${_selectedEmployee!.visitsPerDay == 2 ? 'Double' : 'Single'} Visit Employee',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Information note
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: Colors.amber.shade700,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Off days are automatically set based on employee schedule. Only mark Present/Absent for working days.',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.amber.shade800,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  if (_selectedEmployee!.visitsPerDay == 2) ...[
                    // Double visit employee - shift-wise sections
                    _buildShiftSection(
                      title: 'Morning Shift',
                      icon: Icons.wb_sunny,
                      iconColor: Colors.orange,
                      selectedStatus: selectedMorningStatus!,
                      commentController: morningCommentController,
                      onStatusChanged: (status) {
                        setDialogState(() {
                          selectedMorningStatus = status;
                        });
                      },
                    ),
                    
                    const SizedBox(height: 20),
                    
                    _buildShiftSection(
                      title: 'Evening Shift',
                      icon: Icons.nights_stay,
                      iconColor: Colors.indigo,
                      selectedStatus: selectedEveningStatus!,
                      commentController: eveningCommentController,
                      onStatusChanged: (status) {
                        setDialogState(() {
                          selectedEveningStatus = status;
                        });
                      },
                    ),
                  ] else ...[
                    // Single visit employee
                    _buildShiftSection(
                      title: 'Daily Attendance',
                      icon: Icons.today,
                      iconColor: Colors.green,
                      selectedStatus: selectedFullDayStatus!,
                      commentController: fullDayCommentController,
                      onStatusChanged: (status) {
                        setDialogState(() {
                          selectedFullDayStatus = status;
                        });
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                await _saveAttendanceUpdates(
                  report,
                  selectedMorningStatus,
                  selectedEveningStatus,
                  selectedFullDayStatus,
                  morningCommentController.text,
                  eveningCommentController.text,
                  fullDayCommentController.text,
                );
              },
              icon: const Icon(Icons.save, size: 18),
              label: const Text('Save Changes'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
          ],
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        ),
      ),
    );
  }

  Widget _buildShiftSection({
    required String title,
    required IconData icon,
    required Color iconColor,
    required String selectedStatus,
    required TextEditingController commentController,
    required Function(String) onStatusChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: iconColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: iconColor == Colors.orange ? Colors.orange.shade800 :
                           iconColor == Colors.indigo ? Colors.indigo.shade800 :
                           Colors.green.shade800,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(selectedStatus).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _getStatusColor(selectedStatus).withOpacity(0.5)),
                  ),
                  child: Text(
                    _getStatusDisplayText(selectedStatus),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: _getStatusColor(selectedStatus) == Colors.green ? Colors.green.shade700 :
                             _getStatusColor(selectedStatus) == Colors.red ? Colors.red.shade700 :
                             _getStatusColor(selectedStatus) == Colors.orange ? Colors.orange.shade700 :
                             _getStatusColor(selectedStatus) == Colors.grey ? Colors.grey.shade700 :
                             Colors.blue.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Status selection
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Status:',
                  style: TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: ['present', 'absent'].map((status) {
                    final isSelected = selectedStatus == status;
                    final statusColor = _getStatusColor(status);
                    
                    return GestureDetector(
                      onTap: () => onStatusChanged(status),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected 
                              ? statusColor.withOpacity(0.2) 
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected 
                                ? statusColor 
                                : Colors.grey.shade300,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isSelected) ...[
                              Icon(
                                Icons.check_circle,
                                size: 14,
                                color: statusColor,
                              ),
                              const SizedBox(width: 4),
                            ],
                            Text(
                              _getStatusDisplayText(status),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                color: isSelected ? 
                                    (statusColor == Colors.green ? Colors.green.shade700 :
                                     statusColor == Colors.red ? Colors.red.shade700 :
                                     Colors.grey.shade700) : Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                
                const SizedBox(height: 12),
                
                // Comments
                Text(
                  'Comments (optional):',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: commentController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'Add notes for this ${title.toLowerCase()}...',
                    hintStyle: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    contentPadding: const EdgeInsets.all(8),
                    isDense: true,
                  ),
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveAttendanceUpdates(
    DailyReport report,
    String? morningStatus,
    String? eveningStatus,
    String? fullDayStatus,
    String morningComment,
    String eveningComment,
    String fullDayComment,
  ) async {
    try {
      // Validation: Check if user has made any status selection
      bool hasValidSelection = false;
      
      if (_selectedEmployee!.visitsPerDay == 2) {
        // For double visit employees, check if at least one shift has a valid status selection
        if ((morningStatus != null && morningStatus != 'pending') || 
            (eveningStatus != null && eveningStatus != 'pending')) {
          hasValidSelection = true;
        }
      } else {
        // For single visit employees, check if full day status is selected
        if (fullDayStatus != null && fullDayStatus != 'pending') {
          hasValidSelection = true;
        }
      }
      
      if (!hasValidSelection) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Please select attendance status before saving!'),
            backgroundColor: Colors.orange.shade600,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
        return;
      }
      
      if (_selectedEmployee!.visitsPerDay == 2) {
        // Save morning shift
        if (morningStatus != null) {
          await _updateShiftAttendanceOnly(report, 'morning', morningStatus, morningComment);
        }
        // Save evening shift
        if (eveningStatus != null) {
          await _updateShiftAttendanceOnly(report, 'evening', eveningStatus, eveningComment);
        }
      } else {
        // Save full day attendance
        if (fullDayStatus != null) {
          await _updateFullDayAttendanceOnly(report, fullDayStatus, fullDayComment);
        }
      }
      
      // Refresh data
      await _generateReport();
      Navigator.of(context).pop();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Attendance updated successfully!'),
          backgroundColor: Colors.green.shade600,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating attendance: $e'),
          backgroundColor: Colors.red.shade600,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  String _getStatusDisplayText(String status) {
    switch (status) {
      case 'present':
        return 'Present';
      case 'absent':
        return 'Absent';
      case 'partial':
        return 'Partial';
      case 'off':
        return 'Off Day';
      case 'pending':
        return 'Pending';
      default:
        return status;
    }
  }

  Future<void> _updateShiftAttendanceOnly(DailyReport report, String shiftType, String status, String comments) async {
    final dateString = report.date.toIso8601String().split('T')[0];
    final now = DateTime.now().toIso8601String();
    
    // Find existing attendance records for this date
    final existingAttendances = await DatabaseService().getAttendanceForEmployeeAndDate(
      _selectedEmployee!.id!,
      report.date,
    );

    // Find or create attendance record for this shift
    Attendance? attendanceRecord = existingAttendances.where(
      (a) => a.shiftType == shiftType,
    ).isNotEmpty ? existingAttendances.firstWhere((a) => a.shiftType == shiftType) : null;

    if (attendanceRecord == null) {
      // Create new attendance record
      attendanceRecord = Attendance(
        employeeId: _selectedEmployee!.id!,
        date: dateString,
        status: status,
        shiftType: shiftType,
        comments: comments.isNotEmpty ? comments : null,
        markedDate: now.split('T')[0],
        createdAt: now,
        updatedAt: now,
      );
      await DatabaseService().insertAttendance(attendanceRecord);
    } else {
      // Update existing record
      final updatedRecord = Attendance(
        id: attendanceRecord.id,
        employeeId: attendanceRecord.employeeId,
        date: attendanceRecord.date,
        status: status,
        shiftType: attendanceRecord.shiftType,
        checkInTime: attendanceRecord.checkInTime,
        checkOutTime: attendanceRecord.checkOutTime,
        comments: comments.isNotEmpty ? comments : null,
        markedDate: attendanceRecord.markedDate,
        isCorrected: true,
        createdAt: attendanceRecord.createdAt,
        updatedAt: now,
      );
      await DatabaseService().updateAttendance(updatedRecord);
    }
  }

  Future<void> _updateFullDayAttendanceOnly(DailyReport report, String status, String comments) async {
    final dateString = report.date.toIso8601String().split('T')[0];
    final now = DateTime.now().toIso8601String();
    
    // Find existing attendance record for this date
    final existingAttendances = await DatabaseService().getAttendanceForEmployeeAndDate(
      _selectedEmployee!.id!,
      report.date,
    );

    Attendance? attendanceRecord = existingAttendances.isNotEmpty 
        ? existingAttendances.first
        : null;

    if (attendanceRecord == null) {
      // Create new attendance record
      attendanceRecord = Attendance(
        employeeId: _selectedEmployee!.id!,
        date: dateString,
        status: status,
        shiftType: 'full_day',
        comments: comments.isNotEmpty ? comments : null,
        markedDate: now.split('T')[0],
        createdAt: now,
        updatedAt: now,
      );
      await DatabaseService().insertAttendance(attendanceRecord);
    } else {
      // Update existing record
      final updatedRecord = Attendance(
        id: attendanceRecord.id,
        employeeId: attendanceRecord.employeeId,
        date: attendanceRecord.date,
        status: status,
        shiftType: attendanceRecord.shiftType,
        checkInTime: attendanceRecord.checkInTime,
        checkOutTime: attendanceRecord.checkOutTime,
        comments: comments.isNotEmpty ? comments : null,
        markedDate: attendanceRecord.markedDate,
        isCorrected: true,
        createdAt: attendanceRecord.createdAt,
        updatedAt: now,
      );
      await DatabaseService().updateAttendance(updatedRecord);
    }
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

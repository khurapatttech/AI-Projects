import 'package:flutter/material.dart';
import '../../models/employee.dart';
import '../../models/attendance.dart';
import '../../services/database_service.dart';
import 'package:intl/intl.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({Key? key}) : super(key: key);

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  late DateTime _selectedDate;
  final List<DateTime> _dateOptions = List.generate(3, (i) => DateTime.now().subtract(Duration(days: i)));

  // Track which attendance entry is being edited (by employee id and shiftType)
  Map<String, bool> _editMode = {};
  Map<String, TextEditingController> _commentControllers = {};
  Map<String, String> _editStatus = {};

  // Cache for attendance data to avoid redundant database calls
  Map<String, List<Attendance>> _attendanceCache = {};
  List<Employee> _cachedEmployees = [];
  String _lastLoadedDate = '';

  String _key(Employee e, String shiftType) => '${e.id}_$shiftType';

  @override
  void initState() {
    super.initState();
    _selectedDate = _dateOptions[0];
    _loadData(); // Load initial data
  }

  // Optimized data loading with caching
  Future<void> _loadData({bool forceRefresh = false}) async {
    final dateString = _selectedDateString;
    
    // Check if we need to reload data
    if (!forceRefresh && 
        _lastLoadedDate == dateString && 
        _cachedEmployees.isNotEmpty && 
        _attendanceCache.containsKey(dateString)) {
      return; // Use cached data
    }

    try {
      // Load employees and attendance data in parallel
      final results = await Future.wait([
        DatabaseService().getAllEmployees(),
        DatabaseService().getAllAttendance(),
      ]);

      final employees = results[0] as List<Employee>;
      final allAttendance = results[1] as List<Attendance>;

      // Cache the data
      _cachedEmployees = employees;
      _attendanceCache[dateString] = allAttendance
          .where((att) => att.date == dateString)
          .toList();
      _lastLoadedDate = dateString;

      // Trigger UI rebuild
      setState(() {});
    } catch (e) {
      print('Error loading data: $e');
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadData(forceRefresh: true); // Refresh data when page is shown
  }

  @override
  void dispose() {
    for (final c in _commentControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  String get _selectedDateString => DateFormat('yyyy-MM-dd').format(_selectedDate);

  // Optimized attendance lookup using cache
  Attendance? _getCachedAttendance(Employee e, String shiftType) {
    final dateString = _selectedDateString;
    final attendanceList = _attendanceCache[dateString] ?? [];
    
    try {
      return attendanceList.firstWhere(
        (a) => a.employeeId == e.id && a.shiftType == shiftType,
      );
    } catch (e) {
      return null;
    }
  }

  // Update cache when attendance is saved
  void _updateAttendanceCache(Attendance attendance) {
    final dateString = attendance.date;
    if (!_attendanceCache.containsKey(dateString)) {
      _attendanceCache[dateString] = [];
    }
    
    final attendanceList = _attendanceCache[dateString]!;
    final existingIndex = attendanceList.indexWhere(
      (a) => a.employeeId == attendance.employeeId && 
             a.shiftType == attendance.shiftType,
    );
    
    if (existingIndex >= 0) {
      attendanceList[existingIndex] = attendance;
    } else {
      attendanceList.add(attendance);
    }
  }

  bool _isOffDay(Employee e) {
    final weekday = DateFormat('EEEE').format(_selectedDate);
    return e.offDays.contains(weekday);
  }

  bool _isWithinCorrectionWindow() {
    final now = DateTime.now();
    return now.difference(_selectedDate).inDays <= 2 && !now.isBefore(_selectedDate);
  }

  void _cancelEdit(Employee e, String shiftType) {
    final key = _key(e, shiftType);
    setState(() {
      _editMode[key] = false;
      _commentControllers[key]?.dispose();
      _commentControllers.remove(key);
      _editStatus.remove(key);
    });
  }

  Future<void> _saveAttendance(Employee e, String shiftType, Attendance? existing) async {
    final key = _key(e, shiftType);
    final now = DateTime.now();
    final comment = _commentControllers[key]?.text.trim() ?? '';
    final status = _editStatus[key] ?? 'present';
    
    // Use cached data instead of database call
    Attendance? current = _getCachedAttendance(e, shiftType);
    
    final attendance = Attendance(
      id: current?.id ?? existing?.id,
      employeeId: e.id!,
      date: _selectedDateString,
      shiftType: shiftType,
      status: status,
      checkInTime: current?.checkInTime ?? existing?.checkInTime,
      checkOutTime: current?.checkOutTime ?? existing?.checkOutTime,
      comments: comment,
      markedDate: now.toIso8601String(),
      isCorrected: current != null || existing != null,
      createdAt: current?.createdAt ?? existing?.createdAt ?? now.toIso8601String(),
      updatedAt: now.toIso8601String(),
    );
    
    try {
      if (current == null && existing == null) {
        await DatabaseService().insertAttendance(attendance);
      } else {
        await DatabaseService().updateAttendance(attendance);
      }
      
      // Update cache immediately to avoid database call
      _updateAttendanceCache(attendance);
      
      if (!mounted) return;
      setState(() {
        _editMode[key] = false;
        _commentControllers[key]?.dispose();
        _commentControllers.remove(key);
        _editStatus.remove(key);
      });
    } catch (e) {
      // Optionally, you can show an error dialog or print the error
      print('Error saving attendance: $e');
    }
  }

  // Add a helper to get the status indicator color
  Color _statusColor(String? status) {
    if (status == 'present') return Colors.green;
    if (status == 'absent') return Colors.red;
    if (status == 'off') return Colors.grey;
    return Colors.orange; // pending
  }

  // Optimized method to get employee's overall status for the day
  String? _getEmployeeOverallStatus(Employee e) {
    if (e.visitsPerDay == 1) {
      return _getCachedAttendance(e, 'full_day')?.status;
    } else {
      final morning = _getCachedAttendance(e, 'morning')?.status;
      final evening = _getCachedAttendance(e, 'evening')?.status;
      
      // If both are present, return present
      if (morning == 'present' && evening == 'present') return 'present';
      // If any is absent, return absent
    if (morning == 'absent' || evening == 'absent') return 'absent';
      // If one is present and other is null, return present
      if (morning == 'present' || evening == 'present') return 'present';
      // If both are null, return null (pending)
      return null;
    }
  }

  // Add a helper to get the time window label
  // Optimized summary bar using cached data
  Widget _buildOptimizedSummaryBar() {
    if (_cachedEmployees.isEmpty) return const SizedBox(height: 60);
    
    int presentCount = 0, absentCount = 0, pendingCount = 0;
    
    for (final e in _cachedEmployees) {
      if (e.visitsPerDay == 1) {
        final att = _getCachedAttendance(e, 'full_day');
        if (att == null) pendingCount++;
        if (att?.status == 'present') presentCount++;
        if (att?.status == 'absent') absentCount++;
      } else {
        final attM = _getCachedAttendance(e, 'morning');
        final attE = _getCachedAttendance(e, 'evening');
        if (attM == null) pendingCount++;
        if (attE == null) pendingCount++;
        if (attM?.status == 'present') presentCount++;
        if (attE?.status == 'present') presentCount++;
        if (attM?.status == 'absent') absentCount++;
        if (attE?.status == 'absent') absentCount++;
      }
    }
    
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.symmetric(
        vertical: MediaQuery.of(context).size.width < 600 ? 8 : 12, 
        horizontal: 16
      ),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = MediaQuery.of(context).size.width < 600;
          final fontSize = isMobile ? 16.0 : 18.0;
          final labelFontSize = isMobile ? 10.0 : 12.0;
          
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text('${_cachedEmployees.length}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize, color: Colors.blue)),
                    Text('Total Staff', style: TextStyle(fontSize: labelFontSize), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text('$presentCount', style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize, color: Colors.green)),
                    Text('Present', style: TextStyle(fontSize: labelFontSize), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text('$absentCount', style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize, color: Colors.red)),
                    Text('Absent', style: TextStyle(fontSize: labelFontSize), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text('$pendingCount', style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize, color: Colors.orange)),
                    Text('Pending', style: TextStyle(fontSize: labelFontSize), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Optimized employee header with cached status calculations
  Widget _buildEmployeeHeader(Employee e) {
    // Calculate status once and reuse
    final overallStatus = _getEmployeeOverallStatus(e);
    final statusColor = _statusColor(overallStatus);
    final statusText = overallStatus ?? 'Pending';
    final scheduleText = e.visitsPerDay == 2 ? 'Twice Daily' : 'Daily';
    
    return Row(
      children: [
        CircleAvatar(
          child: Text(e.name[0].toUpperCase()),
          backgroundColor: Colors.blue.shade100,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                e.name, 
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
        ),
        _buildStatusIndicator(statusColor),
      ],
    );
  }


  // Reusable status indicator component
  Widget _buildStatusIndicator(Color statusColor) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: statusColor,
        shape: BoxShape.circle,
      ),
    );
  }

  // Optimized shift status styling helper
  Map<String, dynamic> _getShiftStatusStyle(String? status) {
    switch (status) {
      case 'present':
        return {
          'backgroundColor': Colors.green.shade50,
          'borderColor': Colors.green.shade200,
          'iconColor': Colors.green,
          'icon': Icons.check,
        };
      case 'absent':
        return {
          'backgroundColor': Colors.red.shade50,
          'borderColor': Colors.red.shade200,
          'iconColor': Colors.red,
          'icon': Icons.close,
        };
      default:
        return {
          'backgroundColor': Colors.grey.shade50,
          'borderColor': Colors.grey.shade200,
          'iconColor': Colors.grey.shade400,
          'icon': Icons.schedule,
        };
    }
  }

  String _shiftTimeLabel(String shiftType) {
    switch (shiftType) {
      case 'full_day':
        return '9:00 AM - 6:00 PM';
      case 'morning':
        return '7:00 AM - 11:50 AM';
      case 'evening':
        return '3:00 PM - 9:00 PM';
    }
    return 'Full Day';
  }

  Widget _employeeAttendanceCardModern(Employee e, Attendance? attFull, Attendance? attMorning, Attendance? attEvening, bool canEdit, bool isOff) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      decoration: BoxDecoration(
        color: isOff ? Colors.grey.shade100 : Colors.white,
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
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isOff
            ? Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        child: Text(e.name[0].toUpperCase()),
                        backgroundColor: Colors.blue.shade100,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(e.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            Text(e.visitsPerDay == 2 ? 'Twice Daily' : 'Daily', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ),
                      Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.grey,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey, style: BorderStyle.solid, width: 1),
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.grey.shade200,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: const Center(
                      child: Text('📅 Off Day', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
                    ),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildEmployeeHeader(e),
                  if (e.visitsPerDay == 1)
                    _modernShiftRow(e, 'full_day', attFull, canEdit, label: 'Today', timeLabel: _shiftTimeLabel('full_day')),
                  if (e.visitsPerDay == 2) ...[
                    _modernShiftRow(e, 'morning', attMorning, canEdit, label: 'Morning', timeLabel: _shiftTimeLabel('morning')),
                    const SizedBox(height: 8),
                    _modernShiftRow(e, 'evening', attEvening, canEdit, label: 'Evening', timeLabel: _shiftTimeLabel('evening')),
                  ],
                ],
              ),
      ),
    );
  }

  Widget _modernShiftRow(Employee e, String shiftType, Attendance? att, bool canEdit, {required String label, required String timeLabel}) {
    final key = _key(e, shiftType);
    final inEdit = _editMode[key] == true;
    final commentController = _commentControllers[key] ?? TextEditingController(text: att?.comments ?? '');
    if (_commentControllers[key] == null) _commentControllers[key] = commentController;
    final status = inEdit ? (_editStatus[key] ?? att?.status ?? 'present') : att?.status;
    
    // Simplified logic: Allow marking if within 2-day window (regardless of existing attendance)
    final allowMarking = canEdit;
    
    // Get optimized styling based on status
    final statusStyle = _getShiftStatusStyle(status);
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = MediaQuery.of(context).size.width < 600;
        final padding = isMobile ? 12.0 : 16.0;
        final fontSize = isMobile ? 13.0 : 14.0;
        final timeFontSize = isMobile ? 11.0 : 12.0;
        
        return Container(
          decoration: BoxDecoration(
            color: statusStyle['backgroundColor'],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: statusStyle['borderColor'],
              width: 1,
            ),
          ),
          margin: EdgeInsets.only(top: padding * 0.5),
          padding: EdgeInsets.all(padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row - More compact and informative
              Row(
                children: [
                  // Status Icon - optimized
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: statusStyle['iconColor'],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      statusStyle['icon'],
                      color: Colors.white,
                      size: isMobile ? 12 : 14,
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Shift Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label, 
                          style: TextStyle(
                            fontWeight: FontWeight.w600, 
                            fontSize: fontSize, 
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          timeLabel, 
                          style: TextStyle(
                            fontSize: timeFontSize, 
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              // Action Buttons - Optimized layout
              if (allowMarking) ...[
                const SizedBox(height: 12),
                if (!inEdit)
                  // Quick toggle buttons when not editing
                  Row(
                    children: [
                      Expanded(
                        child: _buildQuickActionButton(
                          label: 'Present',
                          isSelected: status == 'present',
                          color: Colors.green,
                          icon: Icons.check_circle_outline,
                          onTap: () {
                            setState(() {
                              _editStatus[key] = 'present';
                              _editMode[key] = true;
                            });
                          },
                          isMobile: isMobile,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildQuickActionButton(
                          label: 'Absent',
                          isSelected: status == 'absent',
                          color: Colors.red,
                          icon: Icons.cancel_outlined,
                          onTap: () {
                            setState(() {
                              _editStatus[key] = 'absent';
                              _editMode[key] = true;
                            });
                          },
                          isMobile: isMobile,
                        ),
                      ),
                    ],
                  )
                else
                  // Full edit mode with save/cancel
                  Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildQuickActionButton(
                              label: 'Present',
                              isSelected: _editStatus[key] == 'present',
                              color: Colors.green,
                              icon: Icons.check_circle,
                              onTap: () {
                                setState(() {
                                  _editStatus[key] = 'present';
                                });
                              },
                              isMobile: isMobile,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildQuickActionButton(
                              label: 'Absent',
                              isSelected: _editStatus[key] == 'absent',
                              color: Colors.red,
                              icon: Icons.cancel,
                              onTap: () {
                                setState(() {
                                  _editStatus[key] = 'absent';
                                });
                              },
                              isMobile: isMobile,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(vertical: isMobile ? 10 : 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: () => _saveAttendance(e, shiftType, att),
                              icon: Icon(Icons.save, size: isMobile ? 16 : 18),
                              label: Text('Save', style: TextStyle(fontSize: isMobile ? 12 : 13)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.grey.shade700,
                                padding: EdgeInsets.symmetric(vertical: isMobile ? 10 : 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: () => _cancelEdit(e, shiftType),
                              icon: Icon(Icons.close, size: isMobile ? 16 : 18),
                              label: Text('Cancel', style: TextStyle(fontSize: isMobile ? 12 : 13)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
              ],
              
              // Comments Section - Only when editing
              if (inEdit) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: commentController,
                  decoration: InputDecoration(
                    labelText: 'Add notes (optional)',
                    hintText: 'e.g., Late arrival, sick leave...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.blue, width: 2),
                    ),
                    contentPadding: EdgeInsets.all(isMobile ? 10 : 12),
                    labelStyle: TextStyle(fontSize: isMobile ? 12 : 13),
                    prefixIcon: Icon(Icons.note_add, size: isMobile ? 18 : 20),
                  ),
                  style: TextStyle(fontSize: isMobile ? 12 : 13),
                  maxLines: 2,
                ),
              ],
            ],
          ),
        );
      },
    );
  }
  
  // Helper method for consistent action buttons
  Widget _buildQuickActionButton({
    required String label,
    required bool isSelected,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
    required bool isMobile,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: isMobile ? 10 : 12,
          horizontal: isMobile ? 8 : 12,
        ),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: color,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : color,
              size: isMobile ? 16 : 18,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : color,
                fontSize: isMobile ? 11 : 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Attendance'),
        elevation: 0,
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Summary bar - optimized with cached data
          _buildOptimizedSummaryBar(),
          // Date selector
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_dateOptions.length, (i) {
                  final d = _dateOptions[i];
                  final label = i == 0 ? 'Today' : i == 1 ? 'Yesterday' : '${_dateOptions[i].day}/${_dateOptions[i].month}';
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: ChoiceChip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.calendar_today, 
                            size: MediaQuery.of(context).size.width < 600 ? 14 : 16, 
                            color: _selectedDate == d ? Colors.blue : Colors.grey
                          ),
                          const SizedBox(width: 4),
                          Text(
                            label,
                            style: TextStyle(
                              fontSize: MediaQuery.of(context).size.width < 600 ? 12 : 14,
                            ),
                          ),
                        ],
                      ),
                      selected: _selectedDate == d,
                      selectedColor: Colors.blue.shade100,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _selectedDate = d);
                          _loadData(); // Load data for new date
                        }
                      },
                    ),
                  );
                }),
              ),
            ),
          ),
          // Employee cards - optimized with cached data
          Expanded(
            child: _cachedEmployees.isEmpty 
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: _cachedEmployees.length,
                  itemBuilder: (context, index) {
                    final e = _cachedEmployees[index];
                    // Use cached attendance data instead of database calls
                    final attFull = _getCachedAttendance(e, 'full_day');
                    final attMorning = _getCachedAttendance(e, 'morning');
                    final attEvening = _getCachedAttendance(e, 'evening');
                    
                    final isOff = _isOffDay(e);
                    final canEdit = _isWithinCorrectionWindow() && !isOff;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _employeeAttendanceCardModern(e, attFull, attMorning, attEvening, canEdit, isOff),
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }
} 
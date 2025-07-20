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
  late Future<List<Employee>> _employeesFuture;
  late DateTime _selectedDate;
  final List<DateTime> _dateOptions = List.generate(3, (i) => DateTime.now().subtract(Duration(days: i)));

  // Track which attendance entry is being edited (by employee id and shiftType)
  Map<String, bool> _editMode = {};
  Map<String, TextEditingController> _commentControllers = {};
  Map<String, String> _editStatus = {};

  String _key(Employee e, String shiftType) => '${e.id}_$shiftType';

  @override
  void initState() {
    super.initState();
    _selectedDate = _dateOptions[0];
    _loadEmployees();
  }

  void _loadEmployees() {
    setState(() {
      _employeesFuture = DatabaseService().getAllEmployees();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadEmployees(); // Refresh employee list when page is shown
  }

  @override
  void dispose() {
    for (final c in _commentControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  String get _selectedDateString => DateFormat('yyyy-MM-dd').format(_selectedDate);

  Future<Attendance?> _getAttendance(Employee e, String shiftType) async {
    final db = DatabaseService();
    final all = await db.getAllAttendance();
    try {
      return all.firstWhere(
        (a) => a.employeeId == e.id && a.date == _selectedDateString && a.shiftType == shiftType,
      );
    } catch (e) {
      return null;
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

  bool _isMorningWindow() {
    final now = DateTime.now();
    if (!_isToday()) return true; // allow anytime for past days
    return now.hour < 11 || (now.hour == 11 && now.minute <= 50);
  }

  bool _isEveningWindow() {
    final now = DateTime.now();
    if (!_isToday()) return true; // allow anytime for past days
    return now.hour >= 15;
  }

  bool _isToday() {
    final now = DateTime.now();
    return now.year == _selectedDate.year && now.month == _selectedDate.month && now.day == _selectedDate.day;
  }

  void _startEdit(Employee e, String shiftType, Attendance? att) {
    final key = _key(e, shiftType);
    setState(() {
      _editMode[key] = true;
      _commentControllers[key]?.dispose();
      _commentControllers[key] = TextEditingController(text: att?.comments ?? '');
      _editStatus[key] = att?.status ?? 'present';
    });
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
    // Always check for existing attendance before insert/update
    Attendance? current;
    try {
      final all = await DatabaseService().getAllAttendance();
      current = all.firstWhere(
        (a) => a.employeeId == e.id && a.date == _selectedDateString && a.shiftType == shiftType,
      );
    } catch (_) {
      current = null;
    }
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
      if (!mounted) return;
      setState(() {
        _editMode[key] = false;
        _commentControllers[key]?.dispose();
        _commentControllers.remove(key);
        _editStatus.remove(key);
      });
    } catch (e) {
      // Optionally, you can show an error dialog or print the error
    }
  }

  // Add a helper to get the status indicator color
  Color _statusColor(String? status) {
    if (status == 'present') return Colors.green;
    if (status == 'absent') return Colors.red;
    if (status == 'off') return Colors.grey;
    return Colors.orange; // pending
  }

  // Add a helper to get the time window label
  String _shiftTimeLabel(String shiftType) {
    if (shiftType == 'morning') return '7:00-11:50 AM';
    if (shiftType == 'evening') return '3:00-8:00 PM';
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
                          color: _statusColor(e.visitsPerDay == 1 ? attFull?.status : (attMorning?.status ?? attEvening?.status)),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
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
    // Fix: Always allow marking if within correction window and not off day, even if att is null (new employee)
    final allowMarking = canEdit && (att == null || inEdit);
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = MediaQuery.of(context).size.width < 600;
        final padding = isMobile ? 10.0 : 12.0;
        final fontSize = isMobile ? 12.0 : 13.0;
        final timeFontSize = isMobile ? 10.0 : 11.0;
        final buttonPadding = isMobile ? 8.0 : 12.0;
        
        return Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          margin: EdgeInsets.only(top: padding),
          padding: EdgeInsets.all(padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Text(label, style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize, color: Colors.black87)),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(timeLabel, style: TextStyle(fontSize: timeFontSize, color: Colors.grey), overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  ),
                  if (status != null)
                    Chip(
                      label: Text(status),
                      backgroundColor: status == 'present' ? Colors.green.shade100 : Colors.red.shade100,
                      avatar: Icon(
                        status == 'present' ? Icons.check_circle : Icons.cancel,
                        color: status == 'present' ? Colors.green : Colors.red,
                        size: isMobile ? 14 : 16,
                      ),
                      labelStyle: TextStyle(fontSize: isMobile ? 10 : 12),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              if (allowMarking)
                Wrap(
                  spacing: isMobile ? 6 : 8,
                  runSpacing: 4,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: status == 'present' ? Colors.green : Colors.grey.shade200,
                        foregroundColor: status == 'present' ? Colors.white : Colors.black87,
                        padding: EdgeInsets.symmetric(horizontal: buttonPadding, vertical: buttonPadding * 0.75),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        minimumSize: Size(isMobile ? 70 : 80, isMobile ? 32 : 36),
                      ),
                      onPressed: () {
                        setState(() {
                          _editStatus[key] = 'present';
                          _editMode[key] = true;
                        });
                      },
                      child: Text('Present', style: TextStyle(fontSize: isMobile ? 11 : 12)),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: status == 'absent' ? Colors.red : Colors.grey.shade200,
                        foregroundColor: status == 'absent' ? Colors.white : Colors.black87,
                        padding: EdgeInsets.symmetric(horizontal: buttonPadding, vertical: buttonPadding * 0.75),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        minimumSize: Size(isMobile ? 70 : 80, isMobile ? 32 : 36),
                      ),
                      onPressed: () {
                        setState(() {
                          _editStatus[key] = 'absent';
                          _editMode[key] = true;
                        });
                      },
                      child: Text('Absent', style: TextStyle(fontSize: isMobile ? 11 : 12)),
                    ),
                    if (inEdit) ...[
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(horizontal: buttonPadding, vertical: buttonPadding * 0.75),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          minimumSize: Size(isMobile ? 60 : 70, isMobile ? 32 : 36),
                        ),
                        onPressed: () => _saveAttendance(e, shiftType, att),
                        child: Text('Save', style: TextStyle(fontSize: isMobile ? 11 : 12)),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade300,
                          foregroundColor: Colors.black87,
                          padding: EdgeInsets.symmetric(horizontal: buttonPadding, vertical: buttonPadding * 0.75),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          minimumSize: Size(isMobile ? 60 : 70, isMobile ? 32 : 36),
                        ),
                        onPressed: () => _cancelEdit(e, shiftType),
                        child: Text('Cancel', style: TextStyle(fontSize: isMobile ? 11 : 12)),
                      ),
                    ],
                  ],
                ),
              if (inEdit) ...[
                const SizedBox(height: 8),
                TextFormField(
                  controller: commentController,
                  decoration: InputDecoration(
                    labelText: 'Comments',
                    border: const OutlineInputBorder(),
                    contentPadding: EdgeInsets.all(isMobile ? 8 : 12),
                    labelStyle: TextStyle(fontSize: isMobile ? 12 : 14),
                  ),
                  style: TextStyle(fontSize: isMobile ? 12 : 14),
                  maxLines: 2,
                  enabled: inEdit || status == null,
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Attendance')),
      body: Column(
        children: [
          // Summary bar
          FutureBuilder<List<Employee>>(
            future: _employeesFuture,
            builder: (context, empSnap) {
              if (!empSnap.hasData) return const SizedBox(height: 60);
              final employees = empSnap.data!;
              return FutureBuilder<List<Attendance>>(
                future: DatabaseService().getAllAttendance(),
                builder: (context, attSnap) {
                  if (!attSnap.hasData) return const SizedBox(height: 60);
                  final allAtt = attSnap.data!;
                  int presentCount = 0, absentCount = 0, pendingCount = 0;
                  for (final e in employees) {
                    if (e.visitsPerDay == 1) {
                      Attendance? att;
                      try {
                        att = allAtt.firstWhere((a) => a.employeeId == e.id && a.date == _selectedDateString && a.shiftType == 'full_day');
                      } catch (_) {
                        att = null;
                      }
                      if (att == null) pendingCount++;
                      if (att?.status == 'present') presentCount++;
                      if (att?.status == 'absent') absentCount++;
                    } else {
                      Attendance? attM, attE;
                      try {
                        attM = allAtt.firstWhere((a) => a.employeeId == e.id && a.date == _selectedDateString && a.shiftType == 'morning');
                      } catch (_) {
                        attM = null;
                      }
                      try {
                        attE = allAtt.firstWhere((a) => a.employeeId == e.id && a.date == _selectedDateString && a.shiftType == 'evening');
                      } catch (_) {
                        attE = null;
                      }
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
                                  Text('${employees.length}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize, color: Colors.blue)),
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
                },
              );
            },
          ),
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
                        if (selected) setState(() => _selectedDate = d);
                      },
                    ),
                  );
                }),
              ),
            ),
          ),
          // Employee cards
          Expanded(
            child: FutureBuilder<List<Employee>>(
              future: _employeesFuture,
              builder: (context, empSnap) {
                if (!empSnap.hasData) return const Center(child: CircularProgressIndicator());
                final employees = empSnap.data!;
                return FutureBuilder<List<Attendance>>(
                  future: DatabaseService().getAllAttendance(),
                  builder: (context, attSnap) {
                    if (!attSnap.hasData) return const SizedBox.shrink();
                    final allAtt = attSnap.data!;
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: employees.length,
                      itemBuilder: (context, index) {
                        final e = employees[index];
                        Attendance? attFull, attMorning, attEvening;
                        try {
                          attFull = allAtt.firstWhere((a) => a.employeeId == e.id && a.date == _selectedDateString && a.shiftType == 'full_day');
                        } catch (_) {
                          attFull = null;
                        }
                        try {
                          attMorning = allAtt.firstWhere((a) => a.employeeId == e.id && a.date == _selectedDateString && a.shiftType == 'morning');
                        } catch (_) {
                          attMorning = null;
                        }
                        try {
                          attEvening = allAtt.firstWhere((a) => a.employeeId == e.id && a.date == _selectedDateString && a.shiftType == 'evening');
                        } catch (_) {
                          attEvening = null;
                        }
                        final isOff = _isOffDay(e);
                        final canEdit = _isWithinCorrectionWindow() && !isOff;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _employeeAttendanceCardModern(e, attFull, attMorning, attEvening, canEdit, isOff),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
} 
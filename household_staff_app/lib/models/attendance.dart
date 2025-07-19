class Attendance {
  final int? id;
  final int employeeId;
  final String date;
  final String shiftType;
  final String status;
  final String? checkInTime;
  final String? checkOutTime;
  final String? comments;
  final String markedDate;
  final bool isCorrected;
  final String createdAt;
  final String updatedAt;

  Attendance({
    this.id,
    required this.employeeId,
    required this.date,
    required this.shiftType,
    required this.status,
    this.checkInTime,
    this.checkOutTime,
    this.comments,
    required this.markedDate,
    this.isCorrected = false,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'employee_id': employeeId,
      'date': date,
      'shift_type': shiftType,
      'status': status,
      'check_in_time': checkInTime,
      'check_out_time': checkOutTime,
      'comments': comments,
      'marked_date': markedDate,
      'is_corrected': isCorrected ? 1 : 0,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory Attendance.fromMap(Map<String, dynamic> map) {
    return Attendance(
      id: map['id'],
      employeeId: map['employee_id'],
      date: map['date'],
      shiftType: map['shift_type'],
      status: map['status'],
      checkInTime: map['check_in_time'],
      checkOutTime: map['check_out_time'],
      comments: map['comments'],
      markedDate: map['marked_date'],
      isCorrected: map['is_corrected'] == 1,
      createdAt: map['created_at'],
      updatedAt: map['updated_at'],
    );
  }
} 
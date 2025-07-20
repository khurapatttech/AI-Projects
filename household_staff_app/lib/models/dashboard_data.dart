import 'package:household_staff_app/models/attendance.dart';
import 'package:household_staff_app/models/employee.dart';

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

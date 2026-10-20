import '../../data/models/attendance_model.dart';
import '../utils/date_formatter.dart';
import 'parent_api.dart';

class AttendanceService {
  static String _isoDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Attendance of one month from `get_student_attendance_for_parent`
  /// (06_parent_linked_access.sql): signed-in linked parent only.
  /// Throws [ParentDataException] on failure; an empty month is a real result.
  static Future<MonthlyAttendanceSummary> fetchAttendanceForStudent({
    required String studentId,
    required int year,
    required int month,
  }) async {
    final label = DateFormatter.formatMonthYear(DateTime(year, month));
    if (studentId.isEmpty) {
      return MonthlyAttendanceSummary.fromDailyRecords(monthYear: label, records: const []);
    }
    final rows = await ParentApi.instance.rpcList('get_student_attendance_for_parent', {
      'p_student_id': studentId,
      'p_start_date': _isoDate(DateTime(year, month, 1)),
      'p_end_date': _isoDate(DateTime(year, month + 1, 0)),
    });
    final records = rows.map(DailyAttendance.fromMap).toList()..sort((a, b) => b.date.compareTo(a.date));
    return MonthlyAttendanceSummary.fromDailyRecords(monthYear: label, records: records);
  }

  /// Today's mark, or null when none has been recorded yet.
  static Future<DailyAttendance?> fetchTodayAttendance({required String studentId}) async {
    if (studentId.isEmpty) return null;
    final rows = await ParentApi.instance.rpcList('get_student_attendance_for_parent', {
      'p_student_id': studentId,
      'p_date': _isoDate(DateTime.now()),
    });
    return rows.isEmpty ? null : DailyAttendance.fromMap(rows.first);
  }
}

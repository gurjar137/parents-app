import '../../data/models/timetable_model.dart';
import 'parent_api.dart';

class TimetableService {
  /// Published timetable of the child's class and section in the child's
  /// session (`parent_get_timetable`). Throws [ParentDataException] on failure.
  static Future<List<TimetableEntryModel>> fetchTimetableForStudent({required String studentId}) async {
    if (studentId.isEmpty) return const [];
    final rows = await ParentApi.instance.rpcList('parent_get_timetable', {'p_student_id': studentId});
    final entries = rows.map(TimetableEntryModel.fromMap).toList()
      ..sort((a, b) {
        final day = TimetableEntryModel.weekdayIndex(a.dayOfWeek).compareTo(TimetableEntryModel.weekdayIndex(b.dayOfWeek));
        return day != 0 ? day : a.periodNumber.compareTo(b.periodNumber);
      });
    return entries;
  }
}

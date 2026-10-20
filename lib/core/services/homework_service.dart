import '../../data/models/homework_model.dart';
import 'parent_api.dart';

class HomeworkService {
  /// Published homework of the child's class/section and session
  /// (`parent_get_homework`). Throws [ParentDataException] on failure.
  static Future<List<HomeworkModel>> fetchHomeworkForStudent({required String studentId}) async {
    if (studentId.isEmpty) return const [];
    final rows = await ParentApi.instance.rpcList('parent_get_homework', {'p_student_id': studentId});
    return rows.map((m) => HomeworkModel.fromMap(m, studentId)).toList()
      ..sort((a, b) => b.dueDate.compareTo(a.dueDate));
  }
}

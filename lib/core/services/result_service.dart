import '../../data/models/exam_model.dart';
import '../../data/models/result_model.dart';
import 'parent_api.dart';

class ResultService {
  /// Results of exams the school has PUBLISHED (`parent_get_results`).
  /// Unpublished results are never returned by the server.
  static Future<List<ExamResultModel>> fetchResultsForStudent({required String studentId}) async {
    if (studentId.isEmpty) return const [];
    final rows = await ParentApi.instance.rpcList('parent_get_results', {'p_student_id': studentId});
    return rows.map((m) => ExamResultModel.fromMap(m, studentId)).toList();
  }

  /// Exams scheduled for the child's class (`parent_get_exam_schedule`),
  /// one entry per exam subject.
  static Future<List<ExamModel>> fetchExamScheduleForStudent({required String studentId}) async {
    if (studentId.isEmpty) return const [];
    final rows = await ParentApi.instance.rpcList('parent_get_exam_schedule', {'p_student_id': studentId});
    return ExamModel.listFromSchedule(rows, studentId);
  }
}

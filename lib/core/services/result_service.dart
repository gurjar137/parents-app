import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/result_model.dart';
import 'supabase_service.dart';

class ResultService {
  /// Fetches live authorized published exam result records for a specific student
  static Future<List<ExamResultModel>> fetchResultsForStudent({
    required String studentId,
    required String schoolId,
  }) async {
    if (SupabaseService.isInitialized) {
      try {
        final List<dynamic> response = await SupabaseService.client
            .from('exam_results')
            .select()
            .eq('student_id', studentId)
            .eq('school_id', schoolId)
            .order('exam_date', ascending: false);

        if (response.isNotEmpty) {
          return response
              .map((map) => ExamResultModel.fromMap(map as Map<String, dynamic>, studentId))
              .toList();
        }
      } on PostgrestException catch (e) {
        if (kDebugMode) debugPrint('[ResultService] PostgrestException notice: ${e.message}');
      } catch (e) {
        if (kDebugMode) debugPrint('[ResultService] Fetch results notice: $e');
      }
    }

    return [];
  }
}

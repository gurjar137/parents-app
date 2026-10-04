import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/homework_model.dart';
import 'supabase_service.dart';

class HomeworkService {
  /// Fetches live authorized homework records for a specific student and class
  static Future<List<HomeworkModel>> fetchHomeworkForStudent({
    required String studentId,
    required String className,
    required String schoolId,
  }) async {
    if (SupabaseService.isInitialized) {
      try {
        final List<dynamic> response = await SupabaseService.client
            .from('homework')
            .select()
            .or('student_id.eq.$studentId,class_name.eq.$className')
            .eq('school_id', schoolId)
            .order('due_date', ascending: true);

        if (response.isNotEmpty) {
          return response
              .map((map) => HomeworkModel.fromMap(map as Map<String, dynamic>, studentId))
              .toList();
        }
      } on PostgrestException catch (e) {
        if (kDebugMode) debugPrint('[HomeworkService] PostgrestException notice: ${e.message}');
      } catch (e) {
        if (kDebugMode) debugPrint('[HomeworkService] Fetch homework notice: $e');
      }
    }

    return [];
  }
}

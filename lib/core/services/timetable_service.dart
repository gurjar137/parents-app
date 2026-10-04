import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/timetable_model.dart';
import 'supabase_service.dart';

class TimetableService {
  /// Fetches live authorized timetable records for a specific student's school, class, and section
  static Future<List<TimetableEntryModel>> fetchTimetableForStudent({
    required String schoolId,
    required String className,
    required String section,
    required String studentId,
  }) async {
    if (SupabaseService.isInitialized) {
      try {
        final List<dynamic> response = await SupabaseService.client
            .from('timetable')
            .select()
            .eq('school_id', schoolId)
            .or('class_name.eq.$className,section.eq.$section')
            .order('period_number', ascending: true);

        if (response.isNotEmpty) {
          return response
              .map((map) => TimetableEntryModel.fromMap(map as Map<String, dynamic>))
              .toList();
        }
      } on PostgrestException catch (e) {
        if (kDebugMode) debugPrint('[TimetableService] PostgrestException notice: ${e.message}');
      } catch (e) {
        if (kDebugMode) debugPrint('[TimetableService] Fetch timetable notice: $e');
      }
    }

    return [];
  }
}

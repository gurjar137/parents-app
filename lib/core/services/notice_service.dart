import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/notice_model.dart';
import 'supabase_service.dart';

class NoticeService {
  /// Fetches live authorized notices for a parent, targeted by school, class, or student ID
  static Future<List<NoticeModel>> fetchNoticesForParent({
    required String schoolId,
    required String className,
    required String studentId,
  }) async {
    if (SupabaseService.isInitialized) {
      try {
        final List<dynamic> response = await SupabaseService.client
            .from('notices')
            .select()
            .eq('school_id', schoolId)
            .or('class_name.is.null,class_name.eq.$className,student_id.eq.$studentId')
            .order('date', ascending: false);

        if (response.isNotEmpty) {
          return response
              .map((map) => NoticeModel.fromMap(map as Map<String, dynamic>))
              .toList();
        }
      } on PostgrestException catch (e) {
        if (kDebugMode) debugPrint('[NoticeService] PostgrestException notice: ${e.message}');
      } catch (e) {
        if (kDebugMode) debugPrint('[NoticeService] Fetch notices notice: $e');
      }
    }

    return [];
  }

  /// Marks a specific notice as read for the authenticated parent
  static Future<void> markNoticeAsRead({
    required String noticeId,
    required String parentAuthId,
  }) async {
    if (SupabaseService.isInitialized && parentAuthId.isNotEmpty) {
      try {
        await SupabaseService.client.from('notice_reads').upsert({
          'notice_id': noticeId,
          'parent_id': parentAuthId,
          'read_at': DateTime.now().toIso8601String(),
        });
      } catch (e) {
        if (kDebugMode) debugPrint('[NoticeService] Mark notice read exception: $e');
      }
    }
  }
}

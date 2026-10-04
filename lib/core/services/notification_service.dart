import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/notification_model.dart';
import 'supabase_service.dart';

class NotificationService {
  /// Securely registers the device push notification token for the authenticated parent
  static Future<void> registerDeviceToken({
    required String parentAuthId,
    required String schoolId,
    String? token,
  }) async {
    if (SupabaseService.isInitialized && parentAuthId.isNotEmpty) {
      try {
        final deviceToken = token ?? 'fcm_token_parent_${parentAuthId.substring(0, 4)}';
        await SupabaseService.client.from('parent_devices').upsert({
          'parent_auth_user_id': parentAuthId,
          'school_id': schoolId,
          'device_token': deviceToken,
          'platform': kIsWeb ? 'web' : (defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android'),
          'is_active': true,
          'updated_at': DateTime.now().toIso8601String(),
        });
      } catch (e) {
        if (kDebugMode) debugPrint('[NotificationService] Device token registration notice: $e');
      }
    }
  }

  /// Fetches live push notifications history for the authenticated parent
  static Future<List<AppNotificationModel>> fetchNotificationsForParent({
    required String parentAuthId,
    required String schoolId,
    required String studentId,
  }) async {
    if (SupabaseService.isInitialized && parentAuthId.isNotEmpty) {
      try {
        final List<dynamic> response = await SupabaseService.client
            .from('parent_notifications')
            .select()
            .eq('parent_auth_user_id', parentAuthId)
            .eq('school_id', schoolId)
            .order('created_at', ascending: false);

        if (response.isNotEmpty) {
          return response
              .map((map) => AppNotificationModel.fromMap(map as Map<String, dynamic>))
              .toList();
        }
      } on PostgrestException catch (e) {
        if (kDebugMode) debugPrint('[NotificationService] PostgrestException notice: ${e.message}');
      } catch (e) {
        if (kDebugMode) debugPrint('[NotificationService] Fetch notifications notice: $e');
      }
    }

    return [];
  }

  /// Marks a specific notification as read in database
  static Future<void> markNotificationAsRead({
    required String notificationId,
    required String parentAuthId,
  }) async {
    if (SupabaseService.isInitialized && parentAuthId.isNotEmpty) {
      try {
        await SupabaseService.client
            .from('parent_notifications')
            .update({'is_read': true})
            .eq('id', notificationId)
            .eq('parent_auth_user_id', parentAuthId);
      } catch (e) {
        if (kDebugMode) debugPrint('[NotificationService] Mark notification read notice: $e');
      }
    }
  }
}

import '../../data/models/notification_model.dart';
import 'parent_api.dart';

/// In-app notifications stored in `public.notifications` by School OS events
/// (fee payments, absences, homework, published results, parent notices).
///
/// Remote push (FCM) is NOT implemented: the project has no Firebase
/// configuration and no server-side sender. Notifications appear when the app
/// loads or refreshes them.
class NotificationService {
  /// Notifications for the signed-in parent. With [studentId], rows about
  /// other children are left out (school-wide ones stay).
  static Future<List<AppNotificationModel>> fetchNotificationsForParent({String? studentId}) async {
    final rows = await ParentApi.instance.rpcList('parent_get_notifications', {
      'p_student_id': (studentId == null || studentId.isEmpty) ? null : studentId,
      'p_limit': 200,
    });
    return rows.map(AppNotificationModel.fromMap).toList();
  }

  /// Marks [ids] read for this parent only; `null` marks every notification
  /// visible to this parent. Returns the number of new read marks.
  static Future<int> markRead({List<String>? ids}) async {
    final res = await ParentApi.instance.rpc('parent_mark_notifications_read', {'p_ids': ids});
    return res is num ? res.toInt() : int.tryParse('$res') ?? 0;
  }
}

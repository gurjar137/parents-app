import '../../data/models/notice_model.dart';
import 'parent_api.dart';

class NoticeService {
  /// Notices the school published for parents (audience Parents / Everyone),
  /// not expired (`parent_get_notices`). Throws [ParentDataException].
  static Future<List<NoticeModel>> fetchNoticesForParent({required String studentId}) async {
    if (studentId.isEmpty) return const [];
    final rows = await ParentApi.instance.rpcList('parent_get_notices', {'p_student_id': studentId});
    return rows.map(NoticeModel.fromMap).toList();
  }

  /// Records the read state on the server (per parent account).
  static Future<void> markNoticeAsRead({required String noticeId}) async {
    await ParentApi.instance.rpc('parent_mark_notice_read', {'p_notice_id': noticeId});
  }
}

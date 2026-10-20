class AppNotificationModel {
  final String id;
  final String schoolId;
  final String? studentId;
  final String title;
  final String message;
  final DateTime timestamp;
  final String category; // "Fees", "Attendance", "Homework", "Results", "Notices", ...
  final String targetType; // "fee", "attendance", "homework", "result", "notice", "general"
  final String? targetId;
  final bool isRead;

  const AppNotificationModel({
    required this.id,
    this.schoolId = '',
    this.studentId,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.category,
    this.targetType = 'general',
    this.targetId,
    this.isRead = false,
  });

  AppNotificationModel copyWith({bool? isRead}) {
    return AppNotificationModel(
      id: id,
      schoolId: schoolId,
      studentId: studentId,
      title: title,
      message: message,
      timestamp: timestamp,
      category: category,
      targetType: targetType,
      targetId: targetId,
      isRead: isRead ?? this.isRead,
    );
  }

  static String targetTypeFor(String relatedType, String category) {
    final t = '${relatedType.toLowerCase()} ${category.toLowerCase()}';
    if (t.contains('fee') || t.contains('payment')) return 'fee';
    if (t.contains('attend')) return 'attendance';
    if (t.contains('homework')) return 'homework';
    if (t.contains('result') || t.contains('exam')) return 'result';
    if (t.contains('notice')) return 'notice';
    return 'general';
  }

  /// Parses a row of `parent_get_notifications`.
  factory AppNotificationModel.fromMap(Map<String, dynamic> map) {
    String s(dynamic v) => (v == null || v.toString() == 'null') ? '' : v.toString().trim();
    final category = s(map['category']).isNotEmpty ? s(map['category']) : 'School';
    return AppNotificationModel(
      id: s(map['id']),
      schoolId: s(map['school_id']),
      studentId: s(map['student_id']).isEmpty ? null : s(map['student_id']),
      title: s(map['title']),
      message: s(map['message']),
      timestamp: (DateTime.tryParse(s(map['created_at'])) ?? DateTime.fromMillisecondsSinceEpoch(0)).toLocal(),
      category: category,
      targetType: targetTypeFor(s(map['related_record_type']), category),
      targetId: s(map['related_record_id']).isEmpty ? null : s(map['related_record_id']),
      isRead: map['is_read'] == true,
    );
  }
}

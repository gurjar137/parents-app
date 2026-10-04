class AppNotificationModel {
  final String id;
  final String schoolId;
  final String? studentId;
  final String title;
  final String message;
  final DateTime timestamp;
  final String category; // "Homework", "Attendance", "Notices", "Results", "Fees", "School"
  final String targetType; // "homework", "attendance", "notice", "result", "fee"
  final String? targetId;
  final bool isRead;

  const AppNotificationModel({
    required this.id,
    this.schoolId = 'SCH-STX-2026',
    this.studentId,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.category,
    this.targetType = 'notice',
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

  factory AppNotificationModel.fromMap(Map<String, dynamic> map) {
    DateTime parseDate(dynamic val) {
      if (val is String) {
        return DateTime.tryParse(val) ?? DateTime.now();
      } else if (val is DateTime) {
        return val;
      }
      return DateTime.now();
    }

    final category = map['category'] ?? map['type'] ?? 'School';
    String targetType = (map['target_type'] ?? category).toString().toLowerCase();
    if (targetType.contains('home')) {
      targetType = 'homework';
    } else if (targetType.contains('attend')) {
      targetType = 'attendance';
    } else if (targetType.contains('notice')) {
      targetType = 'notice';
    } else if (targetType.contains('result')) {
      targetType = 'result';
    } else if (targetType.contains('fee')) {
      targetType = 'fee';
    } else {
      targetType = 'notice';
    }

    return AppNotificationModel(
      id: map['id'] ?? map['notification_id'] ?? 'NOTIF-${DateTime.now().millisecondsSinceEpoch}',
      schoolId: map['school_id'] ?? 'SCH-STX-2026',
      studentId: map['student_id'],
      title: map['title'] ?? 'School Alert',
      message: map['message'] ?? map['body'] ?? '',
      timestamp: parseDate(map['created_at'] ?? map['timestamp']),
      category: category,
      targetType: targetType,
      targetId: map['target_id'] ?? map['payload_id'],
      isRead: map['is_read'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'school_id': schoolId,
      'student_id': studentId,
      'title': title,
      'message': message,
      'created_at': timestamp.toIso8601String(),
      'category': category,
      'target_type': targetType,
      'target_id': targetId,
      'is_read': isRead,
    };
  }
}

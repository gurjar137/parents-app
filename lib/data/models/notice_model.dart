class NoticeModel {
  final String id;
  final String schoolId;
  final String? className;
  final String? studentId;
  final String title;
  final String category; // "All", "Important", "Academic", "Events", "Holiday"
  final DateTime date;
  final String shortDescription;
  final String fullDescription;
  final String publisherName;
  final String? attachmentName;
  final String? attachmentType;
  final String? attachmentUrl;
  final bool isImportant;
  final bool isRead;

  const NoticeModel({
    required this.id,
    this.schoolId = 'SCH-STX-2026',
    this.className,
    this.studentId,
    required this.title,
    required this.category,
    required this.date,
    required this.shortDescription,
    required this.fullDescription,
    this.publisherName = 'School Administration',
    this.attachmentName,
    this.attachmentType,
    this.attachmentUrl,
    this.isImportant = false,
    this.isRead = false,
  });

  NoticeModel copyWith({bool? isRead}) {
    return NoticeModel(
      id: id,
      schoolId: schoolId,
      className: className,
      studentId: studentId,
      title: title,
      category: category,
      date: date,
      shortDescription: shortDescription,
      fullDescription: fullDescription,
      publisherName: publisherName,
      attachmentName: attachmentName,
      attachmentType: attachmentType,
      attachmentUrl: attachmentUrl,
      isImportant: isImportant,
      isRead: isRead ?? this.isRead,
    );
  }

  factory NoticeModel.fromMap(Map<String, dynamic> map) {
    DateTime parseDate(dynamic val) {
      if (val is String) {
        return DateTime.tryParse(val) ?? DateTime.now();
      } else if (val is DateTime) {
        return val;
      }
      return DateTime.now();
    }

    final attUrl = map['attachment_url'] ?? map['file_url'];
    String? attType;
    if (attUrl != null && attUrl is String) {
      if (attUrl.toLowerCase().contains('.pdf')) {
        attType = 'pdf';
      } else if (attUrl.toLowerCase().contains('.png') || attUrl.toLowerCase().contains('.jpg')) {
        attType = 'image';
      } else {
        attType = 'doc';
      }
    }

    final desc = (map['full_description'] ?? map['description'] ?? map['content'] ?? '').toString();
    final shortDesc = (map['short_description'] ?? (desc.length > 100 ? '${desc.substring(0, 95)}...' : desc)).toString();

    return NoticeModel(
      id: map['id'] ?? map['notice_id'] ?? 'NOTICE-${DateTime.now().millisecondsSinceEpoch}',
      schoolId: map['school_id'] ?? 'SCH-STX-2026',
      className: map['class_name'] ?? map['class'],
      studentId: map['student_id'],
      title: map['title'] ?? map['heading'] ?? 'School Notice',
      category: map['category'] ?? (map['is_important'] == true ? 'Important' : 'Academic'),
      date: parseDate(map['date'] ?? map['published_at'] ?? map['created_at']),
      shortDescription: shortDesc,
      fullDescription: desc,
      publisherName: map['publisher_name'] ?? map['author'] ?? 'Principal Office',
      attachmentName: map['attachment_name'] ?? (attUrl != null ? 'Notice_Document' : null),
      attachmentType: map['attachment_type'] ?? attType,
      attachmentUrl: attUrl,
      isImportant: map['is_important'] ?? map['priority'] == 'high' || map['category'] == 'Important',
      isRead: map['is_read'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'school_id': schoolId,
      'class_name': className,
      'student_id': studentId,
      'title': title,
      'category': category,
      'date': date.toIso8601String().split('T').first,
      'short_description': shortDescription,
      'full_description': fullDescription,
      'publisher_name': publisherName,
      'attachment_name': attachmentName,
      'attachment_type': attachmentType,
      'attachment_url': attachmentUrl,
      'is_important': isImportant,
      'is_read': isRead,
    };
  }
}

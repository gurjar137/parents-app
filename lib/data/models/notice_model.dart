class NoticeModel {
  final String id;
  final String schoolId;
  final String title;
  final String category;
  final DateTime date;
  final String shortDescription;
  final String fullDescription;
  final String publisherName; // the school does not store an author name
  final String? attachmentName;
  final String? attachmentType;
  final String? attachmentUrl;
  final bool isImportant;
  final bool isPinned;
  final bool isRead;

  const NoticeModel({
    required this.id,
    this.schoolId = '',
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
    this.isPinned = false,
    this.isRead = false,
  });

  NoticeModel copyWith({bool? isRead}) {
    return NoticeModel(
      id: id,
      schoolId: schoolId,
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
      isPinned: isPinned,
      isRead: isRead ?? this.isRead,
    );
  }

  /// Parses a row of `parent_get_notices`.
  factory NoticeModel.fromMap(Map<String, dynamic> map) {
    String s(dynamic v) => (v == null || v.toString() == 'null') ? '' : v.toString().trim();
    final attUrl = s(map['attachment_url']);
    String? attType;
    if (attUrl.isNotEmpty) {
      final lower = attUrl.toLowerCase();
      attType = lower.contains('.pdf')
          ? 'pdf'
          : (lower.contains('.png') || lower.contains('.jpg') || lower.contains('.jpeg') ? 'image' : 'doc');
    }
    final content = s(map['content']);
    final priority = s(map['priority']).toLowerCase();
    final category = s(map['category']).isNotEmpty ? s(map['category']) : 'General';
    final date = DateTime.tryParse(s(map['publish_date'])) ?? DateTime.tryParse(s(map['created_at']));
    return NoticeModel(
      id: s(map['id']),
      title: s(map['title']).isNotEmpty ? s(map['title']) : 'Notice',
      category: category,
      date: (date ?? DateTime.fromMillisecondsSinceEpoch(0)).toLocal(),
      shortDescription: content.length > 100 ? '${content.substring(0, 97)}...' : content,
      fullDescription: content,
      attachmentName: attUrl.isNotEmpty ? 'Attachment' : null,
      attachmentType: attType,
      attachmentUrl: attUrl.isNotEmpty ? attUrl : null,
      isImportant: priority == 'high' || priority == 'urgent' || category.toLowerCase() == 'important',
      isPinned: map['is_pinned'] == true || s(map['is_pinned']) == 'true',
      isRead: map['is_read'] == true,
    );
  }
}

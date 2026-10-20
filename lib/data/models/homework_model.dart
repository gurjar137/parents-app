class HomeworkModel {
  final String id;
  final String studentId;
  final String schoolId;
  final String className;
  final String subject;
  final String title;
  final String description;
  final DateTime assignedDate;
  final DateTime dueDate;
  final String teacherName; // '' = not recorded
  final String? attachmentName;
  final String? attachmentType; // 'pdf', 'image', 'doc'
  final String? attachmentUrl;

  /// Parents have read-only access to homework; completion is not tracked by
  /// the school (there is no submission table). Kept for widget compatibility.
  final bool isCompleted;

  HomeworkModel({
    required this.id,
    required this.studentId,
    this.schoolId = '',
    this.className = '',
    required this.subject,
    required this.title,
    required this.description,
    required this.assignedDate,
    required this.dueDate,
    required this.teacherName,
    this.attachmentName,
    this.attachmentType,
    this.attachmentUrl,
    this.isCompleted = false,
  });

  bool get isOverdue {
    final today = DateTime.now();
    return dueDate.isBefore(DateTime(today.year, today.month, today.day));
  }

  /// Parses a row of `parent_get_homework`.
  factory HomeworkModel.fromMap(Map<String, dynamic> map, String fallbackStudentId) {
    String s(dynamic v) => (v == null || v.toString() == 'null') ? '' : v.toString().trim();
    final assigned = DateTime.tryParse(s(map['assigned_date'])) ?? DateTime.tryParse(s(map['created_at']));
    final due = DateTime.tryParse(s(map['due_date']));
    final attUrl = s(map['attachment_url']);
    String? attType;
    if (attUrl.isNotEmpty) {
      final lower = attUrl.toLowerCase();
      attType = lower.contains('.pdf')
          ? 'pdf'
          : (lower.contains('.png') || lower.contains('.jpg') || lower.contains('.jpeg') ? 'image' : 'doc');
    }
    final cls = s(map['class_name']);
    final sec = s(map['section_name']);
    return HomeworkModel(
      id: s(map['id']),
      studentId: fallbackStudentId,
      schoolId: s(map['school_id']),
      className: [cls, sec].where((p) => p.isNotEmpty && p.toLowerCase() != 'all').join('-'),
      subject: s(map['subject']).isNotEmpty ? s(map['subject']) : 'General',
      title: s(map['title']).isNotEmpty ? s(map['title']) : 'Homework',
      description: s(map['description']),
      assignedDate: (assigned ?? due ?? DateTime.fromMillisecondsSinceEpoch(0)).toLocal(),
      dueDate: (due ?? assigned ?? DateTime.fromMillisecondsSinceEpoch(0)).toLocal(),
      teacherName: s(map['teacher_name']),
      attachmentName: attUrl.isNotEmpty ? 'Attachment' : null,
      attachmentType: attType,
      attachmentUrl: attUrl.isNotEmpty ? attUrl : null,
    );
  }

  HomeworkModel copyWith({bool? isCompleted}) {
    return HomeworkModel(
      id: id,
      studentId: studentId,
      schoolId: schoolId,
      className: className,
      subject: subject,
      title: title,
      description: description,
      assignedDate: assignedDate,
      dueDate: dueDate,
      teacherName: teacherName,
      attachmentName: attachmentName,
      attachmentType: attachmentType,
      attachmentUrl: attachmentUrl,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

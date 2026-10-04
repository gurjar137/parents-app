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
  final String teacherName;
  final String? attachmentName;
  final String? attachmentType; // 'pdf', 'image', 'doc'
  final String? attachmentUrl;
  final bool isCompleted;

  HomeworkModel({
    required this.id,
    required this.studentId,
    this.schoolId = 'SCH-STX-2026',
    this.className = '8-A',
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

  factory HomeworkModel.fromMap(Map<String, dynamic> map, String fallbackStudentId) {
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

    return HomeworkModel(
      id: map['id'] ?? map['homework_id'] ?? 'HW-${DateTime.now().millisecondsSinceEpoch}',
      studentId: map['student_id'] ?? fallbackStudentId,
      schoolId: map['school_id'] ?? 'SCH-STX-2026',
      className: map['class_name'] ?? map['class'] ?? '8-A',
      subject: map['subject'] ?? map['subject_name'] ?? 'General',
      title: map['title'] ?? map['topic'] ?? 'Homework Assignment',
      description: map['description'] ?? map['instructions'] ?? '',
      assignedDate: parseDate(map['assigned_date'] ?? map['created_at']),
      dueDate: parseDate(map['due_date'] ?? map['submission_date']),
      teacherName: map['teacher_name'] ?? map['assigned_by'] ?? 'Class Teacher',
      attachmentName: map['attachment_name'] ?? (attUrl != null ? 'Assignment_Document' : null),
      attachmentType: map['attachment_type'] ?? attType,
      attachmentUrl: attUrl,
      isCompleted: map['is_completed'] ?? map['status'] == 'completed',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'student_id': studentId,
      'school_id': schoolId,
      'class_name': className,
      'subject': subject,
      'title': title,
      'description': description,
      'assigned_date': assignedDate.toIso8601String().split('T').first,
      'due_date': dueDate.toIso8601String().split('T').first,
      'teacher_name': teacherName,
      'attachment_name': attachmentName,
      'attachment_type': attachmentType,
      'attachment_url': attachmentUrl,
      'is_completed': isCompleted,
    };
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

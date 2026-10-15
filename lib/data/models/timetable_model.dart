class TimetableEntryModel {
  final String id;
  final String schoolId;
  final String className;
  final String section;
  final String dayOfWeek; // "Monday", "Tuesday", etc.
  final String startTime; // "08:00 AM"
  final String endTime; // "08:45 AM"
  final String subject;
  final String room;
  final String teacherName;
  final int periodNumber;
  final bool isBreak;

  const TimetableEntryModel({
    this.id = '',
    this.schoolId = '',
    this.className = '',
    this.section = '',
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.subject,
    required this.room,
    required this.teacherName,
    this.periodNumber = 1,
    this.isBreak = false,
  });

  factory TimetableEntryModel.fromMap(Map<String, dynamic> map) {
    final rawDay = (map['day_of_week'] ?? map['day'] ?? 'Monday').toString();
    final cleanDay = rawDay.substring(0, 1).toUpperCase() + rawDay.substring(1).toLowerCase();

    return TimetableEntryModel(
      id: map['id'] ?? 'TT-${DateTime.now().millisecondsSinceEpoch}',
      schoolId: map['school_id'] ?? '',
      className: map['class_name'] ?? map['class'] ?? '8-A',
      section: map['section'] ?? 'A',
      dayOfWeek: cleanDay,
      startTime: map['start_time'] ?? '08:00 AM',
      endTime: map['end_time'] ?? '08:45 AM',
      subject: map['subject'] ?? map['subject_name'] ?? 'Class',
      room: map['room'] ?? map['room_no'] ?? 'Room 101',
      teacherName: map['teacher_name'] ?? map['teacher'] ?? 'Class Teacher',
      periodNumber: map['period_number'] ?? map['period'] ?? 1,
      isBreak: map['is_break'] ?? map['subject'].toString().toLowerCase().contains('break'),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'school_id': schoolId,
      'class_name': className,
      'section': section,
      'day_of_week': dayOfWeek,
      'start_time': startTime,
      'end_time': endTime,
      'subject': subject,
      'room': room,
      'teacher_name': teacherName,
      'period_number': periodNumber,
      'is_break': isBreak,
    };
  }
}

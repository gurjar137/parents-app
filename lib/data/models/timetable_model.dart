class TimetableEntryModel {
  final String id;
  final String schoolId;
  final String className;
  final String section;
  final String dayOfWeek; // "Monday", "Tuesday", etc.
  final String startTime;
  final String endTime;
  final String subject;
  final String room; // '' = not recorded
  final String teacherName; // '' = not recorded
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
    this.periodNumber = 0,
    this.isBreak = false,
  });

  static const List<String> weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

  static int weekdayIndex(String day) {
    final i = weekdays.indexWhere((d) => d.toLowerCase() == day.toLowerCase());
    return i < 0 ? 99 : i;
  }

  /// "MONDAY" / "mon" / "1" (ISO, 1 = Monday) -> "Monday".
  static String normalizeDay(String raw) {
    final v = raw.trim().toLowerCase();
    final n = int.tryParse(v);
    if (n != null && n >= 1 && n <= 7) return weekdays[n - 1];
    for (final d in weekdays) {
      if (v.startsWith(d.substring(0, 3).toLowerCase())) return d;
    }
    return raw.isEmpty ? '' : raw[0].toUpperCase() + raw.substring(1).toLowerCase();
  }

  /// Parses a row of `parent_get_timetable`.
  factory TimetableEntryModel.fromMap(Map<String, dynamic> map) {
    String s(dynamic v) => (v == null || v.toString() == 'null') ? '' : v.toString().trim();
    final subject = s(map['subject_name']).isNotEmpty ? s(map['subject_name']) : s(map['subject']);
    return TimetableEntryModel(
      id: s(map['id']),
      className: s(map['class_name']),
      section: s(map['section_name']),
      dayOfWeek: normalizeDay(s(map['day_of_week'])),
      startTime: s(map['start_time']),
      endTime: s(map['end_time']),
      subject: subject.isNotEmpty ? subject : 'Period',
      room: s(map['room']),
      teacherName: s(map['teacher_name']),
      periodNumber: int.tryParse(s(map['period_number']).split('.').first) ?? 0,
      isBreak: subject.toLowerCase().contains('break') || subject.toLowerCase().contains('lunch'),
    );
  }
}

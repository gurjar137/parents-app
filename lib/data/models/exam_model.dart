/// One subject paper of a scheduled exam (`parent_get_exam_schedule`).
class ExamModel {
  final String id;
  final String studentId;
  final String subject;
  final String title; // exam name, e.g. "Half Yearly"
  final DateTime? examDate; // subject date when recorded, else exam start date
  final String timeSlot; // '' = not recorded
  final double totalMarks;
  final String roomNo; // '' = not recorded
  final bool isUpcoming;
  final String status;

  const ExamModel({
    required this.id,
    required this.studentId,
    required this.subject,
    required this.title,
    required this.examDate,
    required this.timeSlot,
    required this.totalMarks,
    required this.roomNo,
    required this.isUpcoming,
    required this.status,
  });

  static List<ExamModel> listFromSchedule(List<Map<String, dynamic>> exams, String studentId) {
    String s(dynamic v) => (v == null || v.toString() == 'null') ? '' : v.toString().trim();
    final today = DateTime.now();
    final startOfToday = DateTime(today.year, today.month, today.day);
    final out = <ExamModel>[];
    for (final e in exams) {
      final examStart = DateTime.tryParse(s(e['start_date']));
      final examEnd = DateTime.tryParse(s(e['end_date'])) ?? examStart;
      final resultPublished = s(e['result_status']).toUpperCase() == 'PUBLISHED';
      final status = resultPublished ? 'Result Published' : (s(e['status']).isEmpty ? 'Scheduled' : _title(s(e['status'])));
      final subjects = e['subjects'] is List ? (e['subjects'] as List).whereType<Map>().toList() : const <Map>[];
      if (subjects.isEmpty) {
        out.add(ExamModel(
          id: s(e['id']),
          studentId: studentId,
          subject: '',
          title: s(e['name']),
          examDate: examStart,
          timeSlot: '',
          totalMarks: 0,
          roomNo: '',
          isUpcoming: examEnd != null && !examEnd.isBefore(startOfToday),
          status: status,
        ));
        continue;
      }
      for (final sub in subjects) {
        final date = DateTime.tryParse(s(sub['exam_date'])) ?? examStart;
        out.add(ExamModel(
          id: '${s(e['id'])}:${s(sub['subject_name'])}',
          studentId: studentId,
          subject: s(sub['subject_name']),
          title: s(e['name']),
          examDate: date,
          timeSlot: '',
          totalMarks: double.tryParse(s(sub['max_marks'])) ?? 0,
          roomNo: '',
          isUpcoming: (date ?? examEnd) != null && !(date ?? examEnd)!.isBefore(startOfToday),
          status: status,
        ));
      }
    }
    out.sort((a, b) => (a.examDate ?? DateTime(9999)).compareTo(b.examDate ?? DateTime(9999)));
    return out;
  }

  static String _title(String raw) => raw
      .toLowerCase()
      .split(RegExp(r'[_\s]+'))
      .where((w) => w.isNotEmpty)
      .map((w) => w[0].toUpperCase() + w.substring(1))
      .join(' ');
}

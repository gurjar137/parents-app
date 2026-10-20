/// Marks of one subject in a published exam (`parent_get_results`).
class SubjectResultModel {
  final String subject;
  final double maxMarks;
  final double? obtainedMarks; // null = absent / exempted / not entered
  final double? passingMarks;
  final String status; // 'PRESENT', 'ABSENT', 'EXEMPTED', 'NOT_APPEARED' or ''
  final String? teacherComment;

  const SubjectResultModel({
    required this.subject,
    required this.maxMarks,
    required this.obtainedMarks,
    this.passingMarks,
    this.status = '',
    this.teacherComment,
  });

  /// No letter grade is stored by the school; the screen shows marks only.
  String get grade => '';

  double get percentage =>
      (maxMarks > 0 && obtainedMarks != null) ? (obtainedMarks! / maxMarks) * 100 : 0.0;

  bool get isAbsent => {'ABSENT', 'NOT_APPEARED'}.contains(status.toUpperCase());

  /// true/false only when the school recorded passing marks for the subject.
  bool? get passed {
    if (passingMarks == null || obtainedMarks == null) return null;
    return obtainedMarks! >= passingMarks!;
  }

  factory SubjectResultModel.fromMap(Map<String, dynamic> map) {
    String s(dynamic v) => (v == null || v.toString() == 'null') ? '' : v.toString().trim();
    double? d(dynamic v) => s(v).isEmpty ? null : double.tryParse(s(v));
    final status = s(map['status']).toUpperCase();
    return SubjectResultModel(
      subject: s(map['subject_name']).isNotEmpty ? s(map['subject_name']) : 'Subject',
      maxMarks: d(map['max_marks']) ?? 0,
      obtainedMarks: {'ABSENT', 'NOT_APPEARED', 'EXEMPTED'}.contains(status) ? null : d(map['marks_obtained']),
      passingMarks: d(map['passing_marks']),
      status: status,
      teacherComment: s(map['remarks']).isEmpty ? null : s(map['remarks']),
    );
  }
}

class ExamResultModel {
  final String id;
  final String studentId;
  final String schoolId;
  final String examName;
  final String academicSession;
  final DateTime? examDate;
  final List<SubjectResultModel> subjects;
  final bool isPublished;

  const ExamResultModel({
    required this.id,
    required this.studentId,
    this.schoolId = '',
    required this.examName,
    this.academicSession = '',
    required this.examDate,
    required this.subjects,
    this.isPublished = true,
  });

  List<SubjectResultModel> get _scored =>
      subjects.where((s) => s.obtainedMarks != null && s.maxMarks > 0).toList();

  double get totalObtained => _scored.fold(0.0, (sum, s) => sum + s.obtainedMarks!);
  double get totalMax => _scored.fold(0.0, (sum, s) => sum + s.maxMarks);
  double get overallPercentage => totalMax > 0 ? (totalObtained / totalMax) * 100 : 0.0;

  /// No overall grade or remark is stored by the school.
  String get overallGrade => '';
  String get teacherRemarks => '';
  String? get reportCardUrl => null;

  /// 'PASS' / 'FAIL' only when every subject has passing marks recorded;
  /// otherwise '' (the school's pass rule is not known to the app).
  String get resultStatus {
    if (subjects.isEmpty) return '';
    final verdicts = subjects.map((s) => s.passed).toList();
    if (verdicts.any((v) => v == null)) return '';
    return verdicts.every((v) => v == true) ? 'PASS' : 'FAIL';
  }

  factory ExamResultModel.fromMap(Map<String, dynamic> map, String studentId) {
    String s(dynamic v) => (v == null || v.toString() == 'null') ? '' : v.toString().trim();
    final rawSubjects = map['subjects'] is List ? map['subjects'] as List : const [];
    return ExamResultModel(
      id: s(map['exam_id']).isNotEmpty ? s(map['exam_id']) : s(map['id']),
      studentId: studentId,
      examName: s(map['name']).isNotEmpty ? s(map['name']) : 'Examination',
      academicSession: s(map['academic_year']),
      examDate: DateTime.tryParse(s(map['start_date'])),
      subjects: rawSubjects.whereType<Map>().map((m) => SubjectResultModel.fromMap(Map<String, dynamic>.from(m))).toList(),
    );
  }
}

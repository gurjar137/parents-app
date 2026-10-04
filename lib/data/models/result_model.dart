class SubjectResultModel {
  final String subject;
  final double maxMarks;
  final double obtainedMarks;
  final String grade;
  final String? teacherComment;

  const SubjectResultModel({
    required this.subject,
    required this.maxMarks,
    required this.obtainedMarks,
    required this.grade,
    this.teacherComment,
  });

  double get percentage => maxMarks > 0 ? (obtainedMarks / maxMarks) * 100 : 0.0;

  factory SubjectResultModel.fromMap(Map<String, dynamic> map) {
    return SubjectResultModel(
      subject: map['subject'] ?? map['subject_name'] ?? 'Subject',
      maxMarks: (map['max_marks'] ?? map['total_marks'] ?? 100).toDouble(),
      obtainedMarks: (map['obtained_marks'] ?? map['marks'] ?? 0).toDouble(),
      grade: map['grade'] ?? 'A',
      teacherComment: map['remarks'] ?? map['comment'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'subject': subject,
      'max_marks': maxMarks,
      'obtained_marks': obtainedMarks,
      'grade': grade,
      'remarks': teacherComment,
    };
  }
}

class ExamResultModel {
  final String id;
  final String studentId;
  final String schoolId;
  final String examName; // e.g. "Unit Test 1", "Mid Term", "Final Examination"
  final String academicSession; // "2026-2027"
  final DateTime examDate;
  final List<SubjectResultModel> subjects;
  final String overallGrade;
  final String teacherRemarks;
  final bool isPublished;
  final String? reportCardUrl;

  const ExamResultModel({
    required this.id,
    required this.studentId,
    this.schoolId = 'SCH-STX-2026',
    required this.examName,
    this.academicSession = '2026-2027',
    required this.examDate,
    required this.subjects,
    required this.overallGrade,
    required this.teacherRemarks,
    this.isPublished = true,
    this.reportCardUrl,
  });

  double get totalObtained => subjects.fold(0.0, (sum, item) => sum + item.obtainedMarks);
  double get totalMax => subjects.fold(0.0, (sum, item) => sum + item.maxMarks);
  double get overallPercentage => totalMax > 0 ? (totalObtained / totalMax) * 100 : 0.0;
  String get resultStatus => overallPercentage >= 40.0 ? 'PASS' : 'FAIL';

  factory ExamResultModel.fromMap(Map<String, dynamic> map, String fallbackStudentId) {
    DateTime parseDate(dynamic val) {
      if (val is String) {
        return DateTime.tryParse(val) ?? DateTime.now();
      } else if (val is DateTime) {
        return val;
      }
      return DateTime.now();
    }

    final rawSubjects = map['subjects'] ?? map['subject_marks'] ?? [];
    List<SubjectResultModel> subjectList = [];
    if (rawSubjects is List) {
      subjectList = rawSubjects
          .map((item) => SubjectResultModel.fromMap(item as Map<String, dynamic>))
          .toList();
    }

    return ExamResultModel(
      id: map['id'] ?? map['exam_id'] ?? 'EXAM-${DateTime.now().millisecondsSinceEpoch}',
      studentId: map['student_id'] ?? fallbackStudentId,
      schoolId: map['school_id'] ?? 'SCH-STX-2026',
      examName: map['exam_name'] ?? map['name'] ?? 'Term Examination',
      academicSession: map['academic_session'] ?? map['session'] ?? '2026-2027',
      examDate: parseDate(map['exam_date'] ?? map['created_at']),
      subjects: subjectList,
      overallGrade: map['overall_grade'] ?? map['grade'] ?? 'A',
      teacherRemarks: map['teacher_remarks'] ?? map['remarks'] ?? 'Good performance.',
      isPublished: map['is_published'] ?? map['status'] == 'published',
      reportCardUrl: map['report_card_url'] ?? map['pdf_url'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'student_id': studentId,
      'school_id': schoolId,
      'exam_name': examName,
      'academic_session': academicSession,
      'exam_date': examDate.toIso8601String().split('T').first,
      'subjects': subjects.map((s) => s.toMap()).toList(),
      'overall_grade': overallGrade,
      'teacher_remarks': teacherRemarks,
      'is_published': isPublished,
      'report_card_url': reportCardUrl,
    };
  }
}

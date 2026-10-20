class StudentModel {
  final String id;
  final String name;
  final String? fatherName;
  final String? motherName;
  final String className; // display label, e.g. "8-A"
  final String grade; // class as stored, e.g. "8"
  final String section; // e.g. "A"
  final int rollNo; // 0 = not assigned
  final String admissionNo;
  final String avatarUrl; // '' = none
  final String academicYear; // session name, '' = unknown
  final String houseName; // '' = not recorded
  final String classTeacher; // '' = not recorded
  final int classmateCount; // 0 = unknown
  final String schoolId;
  final String schoolName;
  final String? linkingCode;
  final String gender;
  final DateTime? dateOfBirth;
  final String relationship;

  const StudentModel({
    required this.id,
    required this.name,
    this.fatherName,
    this.motherName,
    required this.className,
    required this.grade,
    required this.section,
    required this.rollNo,
    required this.admissionNo,
    required this.avatarUrl,
    required this.academicYear,
    required this.houseName,
    required this.classTeacher,
    required this.classmateCount,
    this.schoolId = '',
    this.schoolName = '',
    this.linkingCode,
    this.gender = '',
    this.dateOfBirth,
    this.relationship = '',
  });

  /// Formatted father's name with standard 'Not provided' fallback
  String get displayFatherName {
    if (fatherName != null &&
        fatherName!.trim().isNotEmpty &&
        fatherName!.trim().toLowerCase() != 'null') {
      return fatherName!.trim();
    }
    return 'Not provided';
  }

  /// One linked child from `parent_get_session`. Only fields the school
  /// actually stores are filled; missing ones stay empty (never invented).
  factory StudentModel.fromSession(Map<String, dynamic> map) {
    String s(dynamic v) => (v == null || v.toString() == 'null') ? '' : v.toString().trim();
    final cls = s(map['class_name']);
    final sec = s(map['section_name']);
    return StudentModel(
      id: s(map['id']),
      name: s(map['name']).isNotEmpty ? s(map['name']) : 'Student',
      className: [cls, sec].where((p) => p.isNotEmpty).join('-'),
      grade: cls,
      section: sec,
      rollNo: int.tryParse(s(map['roll_number'])) ?? 0,
      admissionNo: s(map['admission_number']),
      avatarUrl: '',
      academicYear: s(map['academic_year_name']),
      houseName: '',
      classTeacher: '',
      classmateCount: 0,
      schoolId: s(map['school_id']),
      schoolName: s(map['school_name']),
      gender: s(map['gender']),
      dateOfBirth: DateTime.tryParse(s(map['date_of_birth'])),
      relationship: s(map['relationship']),
    );
  }

  factory StudentModel.fromMap(Map<String, dynamic> map, String fallbackId) {
    String s(dynamic v) => (v == null || v.toString() == 'null') ? '' : v.toString().trim();
    final grade = s(map['grade']).isNotEmpty ? s(map['grade']) : s(map['class_name']);
    final section = s(map['section']).isNotEmpty ? s(map['section']) : s(map['section_name']);
    return StudentModel(
      id: s(map['id']).isNotEmpty ? s(map['id']) : fallbackId,
      name: s(map['name']).isNotEmpty ? s(map['name']) : 'Student',
      fatherName: s(map['father_name']).isEmpty ? null : s(map['father_name']),
      motherName: s(map['mother_name']).isEmpty ? null : s(map['mother_name']),
      className: [grade, section].where((p) => p.isNotEmpty).join('-'),
      grade: grade,
      section: section,
      rollNo: int.tryParse(s(map['roll_no'] ?? map['roll_number'])) ?? 0,
      admissionNo: s(map['admission_no'] ?? map['admission_number']),
      avatarUrl: s(map['avatar_url']),
      academicYear: s(map['academic_year']),
      houseName: s(map['house_name']),
      classTeacher: s(map['class_teacher']),
      classmateCount: int.tryParse(s(map['classmate_count'])) ?? 0,
      schoolId: s(map['school_id']),
      schoolName: s(map['school_name']),
      linkingCode: s(map['linking_code']).isEmpty ? null : s(map['linking_code']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'father_name': fatherName,
      'mother_name': motherName,
      'class_name': className,
      'grade': grade,
      'section': section,
      'roll_no': rollNo,
      'admission_no': admissionNo,
      'avatar_url': avatarUrl,
      'academic_year': academicYear,
      'house_name': houseName,
      'class_teacher': classTeacher,
      'classmate_count': classmateCount,
      'school_id': schoolId,
      'school_name': schoolName,
      'linking_code': linkingCode,
    };
  }
}

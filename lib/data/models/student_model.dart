class StudentModel {
  final String id;
  final String name;
  final String? fatherName;
  final String className; // e.g. "8-A" or "5-B"
  final String grade; // e.g. "Class 8"
  final String section; // e.g. "A"
  final int rollNo;
  final String admissionNo;
  final String avatarUrl;
  final String academicYear;
  final String houseName;
  final String classTeacher;
  final int classmateCount;
  final String schoolId;
  final String? linkingCode;

  const StudentModel({
    required this.id,
    required this.name,
    this.fatherName = 'Rajesh Sharma',
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
    this.schoolId = 'SCH-STX-2026',
    this.linkingCode,
  });

  factory StudentModel.fromMap(Map<String, dynamic> map, String fallbackId) {
    final gradeStr = map['grade'] ?? map['class'] ?? 'Class 8';
    final sectionStr = map['section'] ?? 'A';
    final computedClassName = map['class_name'] ?? '$gradeStr-$sectionStr';

    return StudentModel(
      id: map['id'] ?? map['student_id'] ?? fallbackId,
      name: map['name'] ?? map['full_name'] ?? map['student_name'] ?? 'Student',
      fatherName: map['father_name'] ??
          map['father_full_name'] ??
          map['parent_name'] ??
          map['guardian_name'] ??
          map['fatherName'] ??
          'Rajesh Sharma',
      className: computedClassName,
      grade: gradeStr,
      section: sectionStr,
      rollNo: map['roll_no'] is int
          ? map['roll_no']
          : int.tryParse(map['roll_no']?.toString() ?? '1') ?? 1,
      admissionNo: map['admission_no'] ?? map['student_id'] ?? fallbackId,
      avatarUrl: map['avatar_url'] ??
          'https://images.unsplash.com/photo-1544717305-2782549b5136?fit=crop&w=300&h=300',
      academicYear: map['academic_year'] ?? '2025-2026',
      houseName: map['house_name'] ?? 'Ruby House',
      classTeacher: map['class_teacher'] ?? 'Mrs. Sunita Sharma',
      classmateCount: map['classmate_count'] is int
          ? map['classmate_count']
          : int.tryParse(map['classmate_count']?.toString() ?? '34') ?? 34,
      schoolId: map['school_id'] ?? 'SCH-STX-2026',
      linkingCode: map['linking_code'] ?? map['parent_linking_code'] ?? map['access_code'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'father_name': fatherName,
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
      'linking_code': linkingCode,
    };
  }
}

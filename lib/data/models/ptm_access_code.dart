import 'student_model.dart';

class PtmAccessCodeModel {
  final String code; // e.g. "SC-7K4P-92MX"
  final StudentModel studentPreview;
  final String schoolName;
  final bool isUsed;

  const PtmAccessCodeModel({
    required this.code,
    required this.studentPreview,
    required this.schoolName,
    this.isUsed = false,
  });
}

enum CorrectionStatus { pending, approved, rejected }

class CorrectionRequestModel {
  final String id;
  final String studentId;
  final String studentName;
  final String fieldName; // e.g. "Date of Birth", "Spelling of Name", "Blood Group"
  final String currentValue;
  final String requestedValue;
  final String reason;
  final DateTime dateSubmitted;
  final CorrectionStatus status;

  const CorrectionRequestModel({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.fieldName,
    required this.currentValue,
    required this.requestedValue,
    required this.reason,
    required this.dateSubmitted,
    this.status = CorrectionStatus.pending,
  });
}

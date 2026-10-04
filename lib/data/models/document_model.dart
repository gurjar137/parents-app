enum DocumentType { reportCard, feeReceipt, bonafideCertificate, admitCard, medicalForm }

class DocumentModel {
  final String id;
  final String studentId;
  final String title;
  final DocumentType type;
  final DateTime issueDate;
  final String fileSize;
  final String fileFormat; // 'pdf'

  const DocumentModel({
    required this.id,
    required this.studentId,
    required this.title,
    required this.type,
    required this.issueDate,
    required this.fileSize,
    required this.fileFormat,
  });
}

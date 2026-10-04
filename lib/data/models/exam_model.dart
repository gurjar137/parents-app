class ExamModel {
  final String id;
  final String studentId;
  final String subject;
  final String title; // e.g. "Mid Term Mathematics"
  final DateTime examDate;
  final String timeSlot; // e.g. "10:00 AM - 12:00 PM"
  final double totalMarks;
  final String roomNo;
  final bool isUpcoming; // true if upcoming, false if past
  final String status; // "Scheduled", "Completed", "Result Published"

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
}

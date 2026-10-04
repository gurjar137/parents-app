class PtmModel {
  final String id;
  final String studentId;
  final DateTime meetingDate; // e.g. 20 Sept 2026
  final String timeWindow; // "10:00 AM - 2:00 PM"
  final String className;
  final String classTeacher;
  final String venue; // e.g. "Room 204, Second Floor"
  final String instructions;
  final String? bookedSlot; // e.g. "10:30 AM - 10:45 AM"

  const PtmModel({
    required this.id,
    required this.studentId,
    required this.meetingDate,
    required this.timeWindow,
    required this.className,
    required this.classTeacher,
    required this.venue,
    required this.instructions,
    this.bookedSlot,
  });

  PtmModel copyWith({String? bookedSlot}) {
    return PtmModel(
      id: id,
      studentId: studentId,
      meetingDate: meetingDate,
      timeWindow: timeWindow,
      className: className,
      classTeacher: classTeacher,
      venue: venue,
      instructions: instructions,
      bookedSlot: bookedSlot ?? this.bookedSlot,
    );
  }
}

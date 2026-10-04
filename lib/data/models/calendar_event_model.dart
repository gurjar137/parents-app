enum EventCategory { holiday, exam, ptm, event, sports, activity }

class CalendarEventModel {
  final String id;
  final String title;
  final DateTime date;
  final String timeRange; // e.g. "8:00 AM - 1:00 PM" or "All Day"
  final EventCategory category;
  final String location;
  final String description;
  final bool isHighlight;

  const CalendarEventModel({
    required this.id,
    required this.title,
    required this.date,
    required this.timeRange,
    required this.category,
    required this.location,
    required this.description,
    this.isHighlight = false,
  });
}

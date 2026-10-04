class AiMessageModel {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final String? relatedTopic; // "attendance", "fee", "homework", "exam"

  const AiMessageModel({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.relatedTopic,
  });
}

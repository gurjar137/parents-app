class MessageItem {
  final String id;
  final String senderName;
  final bool isFromTeacher;
  final String text;
  final DateTime timestamp;
  final String? attachmentName;
  final String? attachmentType;

  const MessageItem({
    required this.id,
    required this.senderName,
    required this.isFromTeacher,
    required this.text,
    required this.timestamp,
    this.attachmentName,
    this.attachmentType,
  });
}

class MessageThread {
  final String id;
  final String studentId;
  final String teacherName;
  final String teacherSubject; // e.g. "Mathematics & Class Teacher"
  final String teacherAvatar;
  final String lastMessage;
  final DateTime lastMessageTime;
  final int unreadCount;
  final List<MessageItem> messages;

  MessageThread({
    required this.id,
    required this.studentId,
    required this.teacherName,
    required this.teacherSubject,
    required this.teacherAvatar,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.unreadCount,
    required this.messages,
  });

  MessageThread copyWith({
    String? lastMessage,
    DateTime? lastMessageTime,
    int? unreadCount,
    List<MessageItem>? messages,
  }) {
    return MessageThread(
      id: id,
      studentId: studentId,
      teacherName: teacherName,
      teacherSubject: teacherSubject,
      teacherAvatar: teacherAvatar,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      unreadCount: unreadCount ?? this.unreadCount,
      messages: messages ?? this.messages,
    );
  }
}

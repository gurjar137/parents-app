import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/message_model.dart';
import '../../../providers/parent_app_provider.dart';

class MessageThreadScreen extends StatefulWidget {
  final String threadId;

  const MessageThreadScreen({super.key, required this.threadId});

  @override
  State<MessageThreadScreen> createState() => _MessageThreadScreenState();
}

class _MessageThreadScreenState extends State<MessageThreadScreen> {
  final TextEditingController _replyController = TextEditingController();

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  void _sendReply(ParentAppProvider provider) {
    final text = _replyController.text.trim();
    if (text.isNotEmpty) {
      provider.sendMessageReply(widget.threadId, text);
      _replyController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ParentAppProvider>(context);
    final threads = provider.currentMessagesList;
    final thread = threads.firstWhere(
      (t) => t.id == widget.threadId,
      orElse: () => threads.first,
    );

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundImage: NetworkImage(thread.teacherAvatar),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(thread.teacherName, style: AppTextStyles.headingSmall.copyWith(fontSize: 15)),
                  Text(thread.teacherSubject, style: AppTextStyles.caption),
                ],
              ),
            ),
          ],
        ),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Security Notice Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: isDark ? AppColors.darkSubSurface : AppColors.subSurface,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_outline_rounded, size: 14, color: AppColors.textMuted),
                const SizedBox(width: 6),
                Text(
                  'Official school channel with ${provider.selectedChild.name}\'s teacher',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),

          // Message Bubbles List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: thread.messages.length,
              itemBuilder: (context, index) {
                final msg = thread.messages[index];
                return _buildMessageBubble(msg, isDark);
              },
            ),
          ),

          // Message Input Field
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.surface,
              border: Border(top: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.border)),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.attach_file_rounded, color: AppColors.brandIndigo),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Attachment upload will be supported in future release.')),
                      );
                    },
                  ),
                  Expanded(
                    child: TextField(
                      controller: _replyController,
                      decoration: InputDecoration(
                        hintText: 'Type a message to teacher...',
                        hintStyle: AppTextStyles.bodyMedium,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        filled: true,
                        fillColor: isDark ? AppColors.darkSubSurface : AppColors.subSurface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: AppColors.brandIndigo,
                    child: IconButton(
                      icon: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                      onPressed: () => _sendReply(provider),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(MessageItem msg, bool isDark) {
    final isTeacher = msg.isFromTeacher;
    final align = isTeacher ? CrossAxisAlignment.start : CrossAxisAlignment.end;
    final bg = isTeacher
        ? (isDark ? AppColors.darkSubSurface : AppColors.subSurface)
        : AppColors.brandIndigo;
    final textStyle = isTeacher
        ? AppTextStyles.bodyMedium.copyWith(color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary)
        : AppTextStyles.bodyMedium.copyWith(color: Colors.white);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: align,
        children: [
          Container(
            constraints: const BoxConstraints(maxWidth: 280),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isTeacher ? 2 : 16),
                bottomRight: Radius.circular(isTeacher ? 16 : 2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(msg.text, style: textStyle),
                if (msg.attachmentName != null) ...[
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Downloading ${msg.attachmentName}...')),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black12,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.picture_as_pdf_rounded, size: 16, color: AppColors.danger),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              msg.attachmentName!,
                              style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            DateFormatter.formatTime(msg.timestamp),
            style: AppTextStyles.caption,
          ),
        ],
      ),
    );
  }
}

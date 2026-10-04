import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../providers/parent_app_provider.dart';
import '../../widgets/animated_card.dart';
import '../../widgets/empty_state_widget.dart';
import 'message_thread_screen.dart';

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ParentAppProvider>(context);
    final child = provider.selectedChild;
    final threads = provider.currentMessagesList;

    return Scaffold(
      appBar: AppBar(
        title: Text('${child.name}\'s Teachers', style: AppTextStyles.headingSmall),
        elevation: 0,
      ),
      body: threads.isEmpty
          ? const EmptyStateWidget(
              icon: Icons.chat_bubble_outline_rounded,
              title: 'No new messages',
              description: 'Messages and academic remarks from class teachers will appear here.',
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: threads.length,
              itemBuilder: (context, index) {
                final thread = threads[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: AnimatedCard(
                    onTap: () {
                      provider.markThreadRead(thread.id);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MessageThreadScreen(threadId: thread.id),
                        ),
                      );
                    },
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundImage: NetworkImage(thread.teacherAvatar),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      thread.teacherName,
                                      style: AppTextStyles.headingSmall.copyWith(fontSize: 15),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    DateFormatter.formatShort(thread.lastMessageTime),
                                    style: AppTextStyles.caption,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                thread.teacherSubject,
                                style: AppTextStyles.caption.copyWith(color: AppColors.brandBlue, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                thread.lastMessage,
                                style: AppTextStyles.bodyMedium,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        if (thread.unreadCount > 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: AppColors.brandIndigo,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${thread.unreadCount}',
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

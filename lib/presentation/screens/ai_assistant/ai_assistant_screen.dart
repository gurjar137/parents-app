import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/ai_message_model.dart';
import '../../../providers/parent_app_provider.dart';

class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final TextEditingController _queryController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<String> _suggestedPrompts = [
    'How is attendance this month?',
    'What homework is due tomorrow?',
    'Any pending fee balance?',
    'When is the next exam?',
    'Who is the class teacher?',
  ];

  @override
  void dispose() {
    _queryController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _submitQuery(ParentAppProvider provider, String text) {
    if (text.trim().isNotEmpty) {
      provider.sendAiPrompt(text.trim());
      _queryController.clear();
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent + 80,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ParentAppProvider>(context);
    final child = provider.selectedChild;
    final messages = provider.aiMessages;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: AppColors.brandIndigo,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Parent AI Assistant', style: AppTextStyles.headingSmall.copyWith(fontSize: 15)),
                Text('Answering for ${child.name}', style: AppTextStyles.caption.copyWith(color: AppColors.brandBlue)),
              ],
            ),
          ],
        ),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Security / Data Boundary Guarantee Pill
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: isDark ? AppColors.darkSubSurface : AppColors.infoBg,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.shield_outlined, size: 14, color: AppColors.brandBlue),
                const SizedBox(width: 6),
                Text(
                  'Privacy Bound: Accesses only ${child.name}\'s authorized school data',
                  style: AppTextStyles.caption.copyWith(color: AppColors.brandBlue, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),

          // Chat Stream
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                return _buildAiBubble(msg, isDark);
              },
            ),
          ),

          // Suggested Prompts Carousel
          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _suggestedPrompts.length,
              itemBuilder: (context, index) {
                final prompt = _suggestedPrompts[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    label: Text(prompt, style: const TextStyle(fontSize: 12)),
                    backgroundColor: isDark ? AppColors.darkSurface : AppColors.subSurface,
                    onPressed: () => _submitQuery(provider, prompt),
                  ),
                );
              },
            ),
          ),

          // Query Input Box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.surface,
              border: Border(top: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.border)),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _queryController,
                      decoration: InputDecoration(
                        hintText: 'Ask about attendance, homework, exams...',
                        hintStyle: AppTextStyles.bodyMedium,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        filled: true,
                        fillColor: isDark ? AppColors.darkSubSurface : AppColors.subSurface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: (val) => _submitQuery(provider, val),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: AppColors.brandIndigo,
                    child: IconButton(
                      icon: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                      onPressed: () => _submitQuery(provider, _queryController.text),
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

  Widget _buildAiBubble(AiMessageModel msg, bool isDark) {
    final isUser = msg.isUser;
    final align = isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final bg = isUser
        ? AppColors.brandIndigo
        : (isDark ? AppColors.darkSubSurface : AppColors.subSurface);
    final textStyle = isUser
        ? AppTextStyles.bodyMedium.copyWith(color: Colors.white)
        : AppTextStyles.bodyMedium.copyWith(color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: align,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isUser) ...[
                const CircleAvatar(
                  radius: 12,
                  backgroundColor: AppColors.brandIndigo,
                  child: Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 12),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 290),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(msg.text, style: textStyle),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(DateFormatter.formatTime(msg.timestamp), style: AppTextStyles.caption),
        ],
      ),
    );
  }
}

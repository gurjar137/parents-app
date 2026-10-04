import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/homework_model.dart';
import '../../../providers/parent_app_provider.dart';
import '../../widgets/status_badge.dart';

class HomeworkDetailScreen extends StatelessWidget {
  final HomeworkModel homework;

  const HomeworkDetailScreen({super.key, required this.homework});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ParentAppProvider>(context);
    // Find current reactive instance of this homework
    final currentList = provider.currentHomeworkList;
    final currentHw = currentList.firstWhere(
      (h) => h.id == homework.id,
      orElse: () => homework,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(currentHw.subject, style: AppTextStyles.headingSmall),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                StatusBadge(
                  label: currentHw.isCompleted ? 'COMPLETED' : 'PENDING',
                  type: currentHw.isCompleted ? StatusType.success : StatusType.warning,
                ),
                Text(
                  'Assigned: ${DateFormatter.formatShort(currentHw.assignedDate)}',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(currentHw.title, style: AppTextStyles.headingLarge),
            const SizedBox(height: 8),
            Row(
              children: [
                const CircleAvatar(
                  radius: 14,
                  backgroundColor: AppColors.subSurface,
                  child: Icon(Icons.person, size: 16, color: AppColors.textSecondary),
                ),
                const SizedBox(width: 8),
                Text(
                  'Assigned by ${currentHw.teacherName}',
                  style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),

            const SizedBox(height: 24),
            const Divider(height: 1),
            const SizedBox(height: 20),

            Text('Instructions & Description', style: AppTextStyles.headingSmall),
            const SizedBox(height: 10),
            Text(
              currentHw.description,
              style: AppTextStyles.bodyLarge,
            ),

            const SizedBox(height: 24),

            // Due Date Highlight Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.warningBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.warning.withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.event_available_rounded, color: AppColors.warning, size: 24),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Submission Due Date', style: AppTextStyles.caption.copyWith(color: AppColors.warning, fontWeight: FontWeight.bold)),
                      Text(DateFormatter.formatFull(currentHw.dueDate), style: AppTextStyles.headingSmall.copyWith(fontSize: 14)),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Attachments Preview Placeholder
            if (currentHw.attachmentName != null) ...[
              Text('Attachment File', style: AppTextStyles.headingSmall),
              const SizedBox(height: 10),
              InkWell(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Opening attachment: ${currentHw.attachmentName}...'),
                      backgroundColor: AppColors.brandIndigo,
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.infoBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          currentHw.attachmentType == 'pdf' ? Icons.picture_as_pdf_rounded : Icons.image_rounded,
                          color: AppColors.brandBlue,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(currentHw.attachmentName!, style: AppTextStyles.headingSmall.copyWith(fontSize: 14)),
                            Text('Tap to view worksheet file', style: AppTextStyles.caption),
                          ],
                        ),
                      ),
                      const Icon(Icons.download_rounded, color: AppColors.brandBlue),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],

            // Action Toggle Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: currentHw.isCompleted ? AppColors.subSurface : AppColors.brandIndigo,
                  foregroundColor: currentHw.isCompleted ? AppColors.textPrimary : Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: Icon(
                  currentHw.isCompleted ? Icons.undo_rounded : Icons.check_circle_rounded,
                ),
                label: Text(
                  currentHw.isCompleted ? 'Mark as Pending' : 'Mark as Completed',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                onPressed: () {
                  provider.toggleHomeworkCompletion(currentHw.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        currentHw.isCompleted
                            ? 'Homework marked as pending'
                            : 'Homework marked as completed! Great job.',
                      ),
                      backgroundColor: currentHw.isCompleted ? AppColors.warning : AppColors.success,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

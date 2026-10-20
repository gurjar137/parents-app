import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/notice_model.dart';
import '../../widgets/status_badge.dart';

class NoticeDetailScreen extends StatelessWidget {
  final NoticeModel notice;

  const NoticeDetailScreen({super.key, required this.notice});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notice Details'),
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
                  label: notice.category.toUpperCase(),
                  type: notice.isImportant ? StatusType.danger : StatusType.info,
                ),
                Text(
                  DateFormatter.formatFull(notice.date),
                  style: AppTextStyles.caption,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              notice.title,
              style: AppTextStyles.headingLarge.copyWith(fontSize: 22),
            ),
            const SizedBox(height: 20),
            const Divider(height: 1),
            const SizedBox(height: 20),

            Text(
              notice.fullDescription,
              style: AppTextStyles.bodyLarge,
            ),

            const SizedBox(height: 30),

            if (notice.attachmentName != null) ...[
              Text('Official Attachments', style: AppTextStyles.headingSmall),
              const SizedBox(height: 10),
              InkWell(
                onTap: () async {
                  await Clipboard.setData(ClipboardData(text: notice.attachmentUrl ?? ''));
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Attachment link copied. Paste it into your browser to open it.')),
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
                          color: AppColors.dangerBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.danger),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(notice.attachmentName!, style: AppTextStyles.headingSmall.copyWith(fontSize: 14)),
                            Text('Tap to download official circular', style: AppTextStyles.caption),
                          ],
                        ),
                      ),
                      const Icon(Icons.download_rounded, color: AppColors.brandIndigo),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

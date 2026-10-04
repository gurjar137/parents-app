import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class FriendlyErrorView extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onRetry;

  const FriendlyErrorView({
    super.key,
    this.title = 'Something went wrong',
    this.message = 'Please check your internet connection and try again.',
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppColors.subSurface,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.cloud_off_rounded, size: 42, color: AppColors.textMuted),
            ),
            const SizedBox(height: 16),
            Text(title, style: AppTextStyles.headingSmall, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(message, style: AppTextStyles.bodyMedium, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}

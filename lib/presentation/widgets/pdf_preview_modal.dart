import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class PdfPreviewModal extends StatelessWidget {
  final String title;
  final String documentName;
  final Widget contentWidget;
  final VoidCallback? onDownload;
  final VoidCallback? onShare;
  final VoidCallback? onPrint;

  const PdfPreviewModal({
    super.key,
    required this.title,
    required this.documentName,
    required this.contentWidget,
    this.onDownload,
    this.onShare,
    this.onPrint,
  });

  static void show({
    required BuildContext context,
    required String title,
    required String documentName,
    required Widget contentWidget,
    VoidCallback? onDownload,
    VoidCallback? onShare,
    VoidCallback? onPrint,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PdfPreviewModal(
        title: title,
        documentName: documentName,
        contentWidget: contentWidget,
        onDownload: onDownload,
        onShare: onShare,
        onPrint: onPrint,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                const Icon(Icons.picture_as_pdf_rounded, color: AppColors.danger, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AppTextStyles.headingSmall),
                      Text(documentName, style: AppTextStyles.caption),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Action Toolbar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppColors.subSurface,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildActionButton(
                  icon: Icons.download_rounded,
                  label: 'Download',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Downloading $documentName...'),
                        backgroundColor: AppColors.brandIndigo,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                    if (onDownload != null) onDownload!();
                  },
                ),
                _buildActionButton(
                  icon: Icons.share_rounded,
                  label: 'Share',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Sharing $documentName...'),
                        backgroundColor: AppColors.brandIndigo,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                    if (onShare != null) onShare!();
                  },
                ),
                _buildActionButton(
                  icon: Icons.print_rounded,
                  label: 'Print',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Sending $documentName to printer...'),
                        backgroundColor: AppColors.brandIndigo,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                    if (onPrint != null) onPrint!();
                  },
                ),
              ],
            ),
          ),

          // Paper / Document Content Area
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 600),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.shadowStrong,
                        blurRadius: 16,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: contentWidget,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.brandIndigo),
            const SizedBox(width: 6),
            Text(label, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.brandIndigo, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

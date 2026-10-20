import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/document_model.dart';
import '../../../providers/parent_app_provider.dart';
import '../../widgets/animated_card.dart';
import '../../widgets/empty_state_widget.dart';

class DocumentsScreen extends StatelessWidget {
  const DocumentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ParentAppProvider>(context);
    final child = provider.selectedChild;
    final documents = provider.currentDocuments;

    return Scaffold(
      appBar: AppBar(
        title: Text('${child.name}\'s Documents', style: AppTextStyles.headingSmall),
        elevation: 0,
      ),
      body: documents.isEmpty
          ? const EmptyStateWidget(
              icon: Icons.folder_open_rounded,
              title: 'Documents not available',
              description: 'Downloading school documents is not available in the Parents App yet. Please contact the school office.',
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: documents.length,
              itemBuilder: (context, index) {
                final doc = documents[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: AnimatedCard(
                    onTap: null,
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _getDocumentColor(doc.type).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(_getDocumentIcon(doc.type), color: _getDocumentColor(doc.type), size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(doc.title, style: AppTextStyles.headingSmall.copyWith(fontSize: 15)),
                              const SizedBox(height: 2),
                              Text(
                                'Issued: ${DateFormatter.formatShort(doc.issueDate)} • ${doc.fileSize}',
                                style: AppTextStyles.caption,
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.download_rounded, color: AppColors.brandIndigo),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  IconData _getDocumentIcon(DocumentType type) {
    switch (type) {
      case DocumentType.reportCard:
        return Icons.assignment_turned_in_rounded;
      case DocumentType.feeReceipt:
        return Icons.receipt_long_rounded;
      case DocumentType.bonafideCertificate:
        return Icons.verified_rounded;
      case DocumentType.admitCard:
        return Icons.badge_rounded;
      case DocumentType.medicalForm:
        return Icons.medical_services_rounded;
    }
  }

  Color _getDocumentColor(DocumentType type) {
    switch (type) {
      case DocumentType.reportCard:
        return AppColors.holiday;
      case DocumentType.feeReceipt:
        return AppColors.success;
      case DocumentType.bonafideCertificate:
        return AppColors.brandBlue;
      case DocumentType.admitCard:
        return AppColors.warning;
      case DocumentType.medicalForm:
        return AppColors.danger;
    }
  }
}

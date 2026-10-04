import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/fee_model.dart';
import '../../../providers/parent_app_provider.dart';
import '../../widgets/pdf_preview_modal.dart';
import '../../widgets/stat_row.dart';

class ReceiptDetailScreen extends StatelessWidget {
  final FeePaymentModel payment;

  const ReceiptDetailScreen({super.key, required this.payment});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ParentAppProvider>(context);
    final child = provider.selectedChild;

    return Scaffold(
      appBar: AppBar(
        title: Text('Receipt #${payment.receiptNo}', style: AppTextStyles.headingSmall),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.brandBlue),
            onPressed: () {
              PdfPreviewModal.show(
                context: context,
                title: 'Official Fee Receipt',
                documentName: '${payment.receiptNo}.pdf',
                contentWidget: _buildReceiptPaperContent(child.name, child.admissionNo, child.className, child.rollNo),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
                boxShadow: const [BoxShadow(color: AppColors.shadow, blurRadius: 10)],
              ),
              child: _buildReceiptPaperContent(child.name, child.admissionNo, child.className, child.rollNo),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.share_rounded, size: 18),
                    label: const Text('Share Receipt'),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Sharing fee receipt...')),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.print_rounded, size: 18),
                    label: const Text('Print Receipt'),
                    onPressed: () {
                      PdfPreviewModal.show(
                        context: context,
                        title: 'Official Fee Receipt',
                        documentName: '${payment.receiptNo}.pdf',
                        contentWidget: _buildReceiptPaperContent(child.name, child.admissionNo, child.className, child.rollNo),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReceiptPaperContent(String studentName, String admissionNo, String className, int rollNo) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // School Header
        Center(
          child: Column(
            children: [
              Text(AppConstants.schoolName, style: AppTextStyles.headingSmall.copyWith(fontSize: 18), textAlign: TextAlign.center),
              const SizedBox(height: 2),
              Text(AppConstants.schoolAddress, style: AppTextStyles.caption, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.subSurface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('OFFICIAL FEE PAYMENT RECEIPT', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),
        const Divider(),
        const SizedBox(height: 12),

        // Metadata
        StatRow(label: 'Receipt Number:', value: payment.receiptNo),
        StatRow(label: 'Date of Payment:', value: DateFormatter.formatShort(payment.date)),
        if (payment.transactionRef.isNotEmpty)
          StatRow(label: 'Transaction Ref:', value: payment.transactionRef),
        StatRow(label: 'Payment Method:', value: payment.paymentMethod),
        const SizedBox(height: 10),
        const Divider(),
        const SizedBox(height: 10),

        // Student Details
        Text('Student Details', style: AppTextStyles.headingSmall.copyWith(fontSize: 14)),
        const SizedBox(height: 6),
        StatRow(label: 'Student Name:', value: studentName),
        StatRow(label: 'Admission No:', value: admissionNo),
        StatRow(label: 'Class & Section:', value: className),
        StatRow(label: 'Roll Number:', value: '$rollNo'),

        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 10),

        // Payment Details
        Text('Payment Particulars', style: AppTextStyles.headingSmall.copyWith(fontSize: 14)),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Amount Received', style: AppTextStyles.bodyMedium),
            Text(CurrencyFormatter.formatINR(payment.amount), style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Remaining Balance', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted)),
            Text(CurrencyFormatter.formatINR(payment.remainingBalance), style: AppTextStyles.bodyMedium.copyWith(color: AppColors.warning, fontWeight: FontWeight.bold)),
          ],
        ),

        if (payment.notes.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text('Remarks:', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold)),
          Text(payment.notes, style: AppTextStyles.bodySmall),
        ],

        const SizedBox(height: 16),
        const Divider(thickness: 1.5),
        const SizedBox(height: 10),

        // Total
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('TOTAL PAID:', style: AppTextStyles.headingSmall),
            Text(
              CurrencyFormatter.formatINR(payment.amount),
              style: AppTextStyles.headingMedium.copyWith(color: AppColors.success),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Stamp & Signature
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.brandBlue.withOpacity(0.5), width: 2),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text('PAID\nSTAMP', style: TextStyle(fontSize: 9, color: AppColors.brandBlue, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('Accounts Officer', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold)),
                Text(AppConstants.schoolName, style: AppTextStyles.caption),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

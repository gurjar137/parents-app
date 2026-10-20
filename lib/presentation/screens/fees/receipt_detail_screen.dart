import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/services/fee_service.dart';
import '../../../core/services/parent_api.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/fee_model.dart';
import '../../widgets/friendly_error_view.dart';
import '../../widgets/stat_row.dart';

/// Receipt of one persisted payment. Every value shown comes from
/// `parent_get_receipt`, which builds it on the server from the stored
/// payment, student and school rows (and refuses other families' payments).
class ReceiptDetailScreen extends StatefulWidget {
  final FeePaymentModel payment;

  const ReceiptDetailScreen({super.key, required this.payment});

  @override
  State<ReceiptDetailScreen> createState() => _ReceiptDetailScreenState();
}

class _ReceiptDetailScreenState extends State<ReceiptDetailScreen> {
  FeeReceiptModel? _receipt;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final r = await FeeService.fetchReceipt(paymentId: widget.payment.id);
      if (!mounted) return;
      setState(() {
        _receipt = r;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = parentErrorMessage(e);
        _loading = false;
      });
    }
  }

  Future<void> _copy(FeeReceiptModel r) async {
    await Clipboard.setData(ClipboardData(
      text: r.toPlainText(money: CurrencyFormatter.formatINR, date: DateFormatter.formatShort),
    ));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Receipt details copied to the clipboard.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = _receipt;
    final number = r?.receiptNumber ?? widget.payment.receiptNo;
    return Scaffold(
      appBar: AppBar(
        title: Text(number.isNotEmpty ? 'Receipt $number' : 'Receipt', style: AppTextStyles.headingSmall),
        elevation: 0,
        actions: [
          if (r != null)
            IconButton(
              tooltip: 'Copy receipt details',
              icon: const Icon(Icons.copy_rounded, color: AppColors.brandBlue),
              onPressed: () => _copy(r),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.brandIndigo))
          : (_error != null
              ? FriendlyErrorView(title: 'Receipt not available', message: _error!, onRetry: _load)
              : RefreshIndicator(
                  onRefresh: _load,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
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
                          child: _ReceiptPaper(receipt: r!),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.copy_rounded, size: 18),
                            label: const Text('Copy receipt details'),
                            onPressed: () => _copy(r),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'PDF download and printing are not available in this version of the app.',
                          style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )),
    );
  }
}

class _ReceiptPaper extends StatelessWidget {
  final FeeReceiptModel receipt;

  const _ReceiptPaper({required this.receipt});

  @override
  Widget build(BuildContext context) {
    final r = receipt;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Column(
            children: [
              if (r.schoolLogoUrl.isNotEmpty) ...[
                Image.network(r.schoolLogoUrl, height: 48, errorBuilder: (_, __, ___) => const SizedBox.shrink()),
                const SizedBox(height: 6),
              ],
              if (r.schoolName.isNotEmpty)
                Text(r.schoolName, style: AppTextStyles.headingSmall.copyWith(fontSize: 18), textAlign: TextAlign.center),
              if (r.schoolAddress.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(r.schoolAddress, style: AppTextStyles.caption, textAlign: TextAlign.center),
              ],
              if (r.schoolPhone.isNotEmpty || r.schoolEmail.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  [r.schoolPhone, r.schoolEmail].where((p) => p.isNotEmpty).join(' • '),
                  style: AppTextStyles.caption,
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(color: AppColors.subSurface, borderRadius: BorderRadius.circular(12)),
                child: Text('FEE PAYMENT RECEIPT',
                    style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Divider(),
        StatRow(label: 'Receipt Number:', value: r.receiptNumber.isNotEmpty ? r.receiptNumber : '—'),
        if (r.paymentDate != null) StatRow(label: 'Date of Payment:', value: DateFormatter.formatShort(r.paymentDate!)),
        if (r.paymentMethod.isNotEmpty) StatRow(label: 'Payment Method:', value: r.paymentMethod),
        if (r.referenceNumber.isNotEmpty) StatRow(label: 'Reference:', value: r.referenceNumber),
        if (r.academicYear.isNotEmpty) StatRow(label: 'Session:', value: r.academicYear),
        const SizedBox(height: 8),
        const Divider(),
        Text('Student', style: AppTextStyles.headingSmall.copyWith(fontSize: 14)),
        const SizedBox(height: 6),
        if (r.studentName.isNotEmpty) StatRow(label: 'Name:', value: r.studentName),
        if (r.admissionNumber.isNotEmpty) StatRow(label: 'Admission No:', value: r.admissionNumber),
        if (r.classLabel.isNotEmpty) StatRow(label: 'Class & Section:', value: r.classLabel),
        const SizedBox(height: 8),
        const Divider(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Amount Paid', style: AppTextStyles.headingSmall),
            Text(CurrencyFormatter.formatINR(r.amount),
                style: AppTextStyles.headingMedium.copyWith(color: AppColors.success)),
          ],
        ),
        if (r.balanceAfterPayment != null) ...[
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Balance after this payment', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted)),
              Text(CurrencyFormatter.formatINR(r.balanceAfterPayment!),
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.warning, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
        if (r.notes.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text('Remarks:', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold)),
          Text(r.notes, style: AppTextStyles.bodySmall),
        ],
        const SizedBox(height: 16),
        Text(
          r.recordedAt != null
              ? 'Recorded by the school on ${DateFormatter.formatShort(r.recordedAt!)} at ${DateFormatter.formatTime(r.recordedAt!)}.'
              : 'Recorded by the school.',
          style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
        ),
      ],
    );
  }
}

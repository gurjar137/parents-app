import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../providers/parent_app_provider.dart';
import '../../widgets/animated_card.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/stat_row.dart';
import '../../widgets/status_badge.dart';
import 'receipt_detail_screen.dart';

class FeesScreen extends StatelessWidget {
  const FeesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ParentAppProvider>(context);
    final child = provider.selectedChild;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (provider.isFeesLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Fees & Dues • ${child.name}', style: AppTextStyles.headingSmall),
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: AppColors.brandIndigo),
              const SizedBox(height: 16),
              Text(
                'Loading fee details for ${child.name}...',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      );
    }

    if (provider.feesError != null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Fees & Dues • ${child.name}', style: AppTextStyles.headingSmall),
          elevation: 0,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.cloud_off_rounded, size: 64, color: AppColors.danger),
                const SizedBox(height: 16),
                Text(
                  'Unable to load fee details.',
                  style: AppTextStyles.headingSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Please check your internet connection and try again.',
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => provider.loadFeeSummaryForSelectedChild(),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandIndigo,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final fee = provider.currentFeeSummary;

    if (!fee.hasFeeAccount) {
      return Scaffold(
        appBar: AppBar(title: Text('Fees & Dues • ${child.name}', style: AppTextStyles.headingSmall)),
        body: RefreshIndicator(
          onRefresh: () => provider.loadFeeSummaryForSelectedChild(),
          color: AppColors.brandIndigo,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.75,
              child: EmptyStateWidget(
                icon: Icons.account_balance_wallet_outlined,
                title: 'No fee assigned yet.',
                description: 'Your school has not published fee details for this academic year.',
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Fees & Dues • ${child.name}', style: AppTextStyles.headingSmall),
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () => provider.loadFeeSummaryForSelectedChild(),
        color: AppColors.brandIndigo,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. STUDENT INFO HEADER
              AnimatedCard(
                backgroundColor: isDark ? AppColors.darkSubSurface : AppColors.subSurface,
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundImage: NetworkImage(child.avatarUrl),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              child.name,
                              style: AppTextStyles.headingSmall.copyWith(fontSize: 16),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'ADM: ${child.admissionNo} • Class ${child.className}',
                              style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 2. PROMINENT FEE SUMMARY CARD
              AnimatedCard(
                backgroundColor: AppColors.primary,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Fee Statement', style: AppTextStyles.caption.copyWith(color: Colors.white70)),
                              Text('Net Payable', style: AppTextStyles.headingSmall.copyWith(color: Colors.white, fontSize: 16)),
                            ],
                          ),
                          _buildStatusBadge(fee.status, fee.isOverdue),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text('NET FEE AMOUNT', style: AppTextStyles.caption.copyWith(color: Colors.white70, fontSize: 11)),
                      Text(
                        CurrencyFormatter.formatINR(fee.netFee),
                        style: AppTextStyles.headingLarge.copyWith(color: Colors.white, fontSize: 28),
                      ),
                      const SizedBox(height: 16),

                      // VISUAL PROGRESS INDICATOR
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${CurrencyFormatter.formatINR(fee.paidAmount)} / ${CurrencyFormatter.formatINR(fee.netFee)}',
                            style: AppTextStyles.caption.copyWith(color: Colors.white70, fontSize: 12),
                          ),
                          Text(
                            '${fee.progressPercentage}% Paid',
                            style: AppTextStyles.caption.copyWith(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: fee.progressRatio,
                          minHeight: 8,
                          backgroundColor: Colors.white24,
                          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.success),
                        ),
                      ),

                      const SizedBox(height: 16),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Paid Amount', style: AppTextStyles.caption.copyWith(color: Colors.white70)),
                              Text(
                                CurrencyFormatter.formatINR(fee.paidAmount),
                                style: AppTextStyles.headingSmall.copyWith(color: AppColors.success, fontSize: 15),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('Outstanding Balance', style: AppTextStyles.caption.copyWith(color: Colors.white70)),
                              Text(
                                CurrencyFormatter.formatINR(fee.outstandingAmount),
                                style: AppTextStyles.headingSmall.copyWith(
                                  color: fee.outstandingAmount > 0 ? AppColors.warning : AppColors.success,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // 3. DUE DATE BANNER
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: fee.isOverdue ? AppColors.dangerBg : (fee.outstandingAmount > 0 ? AppColors.warningBg : AppColors.successBg),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: fee.isOverdue ? AppColors.danger.withOpacity(0.4) : (fee.outstandingAmount > 0 ? AppColors.warning.withOpacity(0.4) : AppColors.success.withOpacity(0.4)),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      fee.isOverdue ? Icons.event_busy_rounded : (fee.outstandingAmount > 0 ? Icons.event_available_rounded : Icons.check_circle_outline_rounded),
                      color: fee.isOverdue ? AppColors.danger : (fee.outstandingAmount > 0 ? AppColors.warning : AppColors.success),
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        fee.dueDate != null
                            ? 'Due Date: ${DateFormatter.formatShort(fee.dueDate!)}${fee.isOverdue ? ' (OVERDUE)' : ''}'
                            : 'Due Date: Not Set',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: fee.isOverdue ? AppColors.danger : (fee.outstandingAmount > 0 ? AppColors.warning : AppColors.success),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 4. FEE BREAKDOWN CARD
              AnimatedCard(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Fee Breakdown', style: AppTextStyles.headingSmall),
                      const SizedBox(height: 12),
                      StatRow(label: 'Gross Fee:', value: CurrencyFormatter.formatINR(fee.grossFee)),
                      StatRow(label: 'Discount:', value: '- ${CurrencyFormatter.formatINR(fee.discountAmount)}'),
                      StatRow(label: 'Concession / Waiver:', value: '- ${CurrencyFormatter.formatINR(fee.waiverAmount)}'),
                      const Divider(height: 16),
                      StatRow(
                        label: 'Net Fee:',
                        value: CurrencyFormatter.formatINR(fee.netFee),
                        valueStyle: AppTextStyles.headingSmall.copyWith(color: AppColors.brandIndigo, fontSize: 14),
                      ),
                      const SizedBox(height: 6),
                      StatRow(
                        label: 'Paid Amount:',
                        value: CurrencyFormatter.formatINR(fee.paidAmount),
                        valueStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.success, fontWeight: FontWeight.bold),
                      ),
                      StatRow(
                        label: 'Outstanding Balance:',
                        value: CurrencyFormatter.formatINR(fee.outstandingAmount),
                        valueStyle: AppTextStyles.bodyMedium.copyWith(
                          color: fee.outstandingAmount > 0 ? AppColors.warning : AppColors.success,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 5. FEE REMARKS (IF PRESENT)
              if (fee.notes.isNotEmpty) ...[
                const SizedBox(height: 16),
                AnimatedCard(
                  child: Padding(
                    padding: const EdgeInsets.all(14.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Fee Remarks', style: AppTextStyles.headingSmall.copyWith(fontSize: 13)),
                        const SizedBox(height: 6),
                        Text(
                          fee.notes,
                          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // 6. PAYMENT HISTORY SECTION
              Text('Payment History', style: AppTextStyles.headingSmall),
              const SizedBox(height: 12),

              if (fee.payments.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSubSurface : AppColors.subSurface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'No payments recorded yet.',
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted),
                    textAlign: TextAlign.center,
                  ),
                )
              else
                Column(
                  children: fee.payments.map((payment) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: AnimatedCard(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ReceiptDetailScreen(payment: payment),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(14.0),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.successBg,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(Icons.receipt_long_rounded, color: AppColors.success, size: 22),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Receipt: ${payment.receiptNo}',
                                      style: AppTextStyles.headingSmall.copyWith(fontSize: 14),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${DateFormatter.formatShort(payment.date)} • ${payment.paymentMethod}',
                                      style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Balance: ${CurrencyFormatter.formatINR(payment.remainingBalance)}',
                                      style: AppTextStyles.caption.copyWith(color: AppColors.warning),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    CurrencyFormatter.formatINR(payment.amount),
                                    style: AppTextStyles.headingSmall.copyWith(color: AppColors.success, fontSize: 15),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'View Receipt',
                                    style: AppTextStyles.caption.copyWith(color: AppColors.brandBlue, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status, bool isOverdue) {
    String label = 'DUE';
    StatusType type = StatusType.warning;

    final lower = status.toLowerCase();
    if (lower == 'paid' || lower == 'fully_paid') {
      label = 'PAID';
      type = StatusType.success;
    } else if (lower == 'partially_paid' || lower == 'partial') {
      label = 'PARTIALLY PAID';
      type = StatusType.warning;
    } else if (isOverdue || lower == 'overdue') {
      label = 'OVERDUE';
      type = StatusType.danger;
    } else {
      label = 'DUE';
      type = StatusType.warning;
    }

    return StatusBadge(label: label, type: type);
  }
}

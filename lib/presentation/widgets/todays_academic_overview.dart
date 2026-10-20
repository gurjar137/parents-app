import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/models/attendance_model.dart';
import '../../data/models/fee_model.dart';
import '../../data/models/homework_model.dart';
import '../../data/models/timetable_model.dart';
import 'animated_card.dart';

class TodaysAcademicOverview extends StatelessWidget {
  final MonthlyAttendanceSummary attendance;
  final FeeSummaryModel feeSummary;
  final List<HomeworkModel> homeworkList;
  final TimetableEntryModel? nextClass;
  final VoidCallback onAttendanceTap;
  final VoidCallback onFeesTap;
  final VoidCallback onHomeworkTap;
  final VoidCallback onTimetableTap;

  const TodaysAcademicOverview({
    super.key,
    required this.attendance,
    required this.feeSummary,
    required this.homeworkList,
    required this.nextClass,
    required this.onAttendanceTap,
    required this.onFeesTap,
    required this.onHomeworkTap,
    required this.onTimetableTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pendingHwList = homeworkList.where((h) => !h.isCompleted).toList();
    final pendingHwCount = pendingHwList.length;
    final isFeePaid = feeSummary.pendingAmount <= 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                "Today's Overview",
                style: AppTextStyles.headingSmall.copyWith(fontSize: 16),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSubSurface : AppColors.subSurface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.circle, size: 6, color: AppColors.success),
                  const SizedBox(width: 5),
                  Text(
                    'Live Updates',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Row 1: Attendance & Fee Status
        Row(
          children: [
            // 1. Attendance Card
            Expanded(
              child: AnimatedCard(
                onTap: onAttendanceTap,
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkSuccessBg : AppColors.successBg,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.calendar_today_rounded, color: AppColors.success, size: 16),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkSuccessBg : AppColors.successBg,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.success.withOpacity(0.3)),
                            ),
                            child: Text(
                              '${attendance.percentage.toStringAsFixed(0)}%',
                              style: const TextStyle(
                                color: AppColors.success,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text('Attendance', style: AppTextStyles.headingSmall.copyWith(fontSize: 13.5)),
                    const SizedBox(height: 2),
                    Text(
                      '${attendance.presentDays} Present / ${attendance.totalWorkingDays} Days',
                      style: AppTextStyles.caption.copyWith(fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (attendance.percentage / 100).clamp(0.0, 1.0),
                        backgroundColor: isDark ? AppColors.darkSubSurface : AppColors.subSurface,
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.success),
                        minHeight: 4.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(width: 10),

            // 2. Fee Summary Card
            Expanded(
              child: AnimatedCard(
                onTap: onFeesTap,
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkInfoBg : AppColors.infoBg,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.account_balance_wallet_rounded, color: AppColors.brandBlue, size: 16),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: isFeePaid
                                  ? (isDark ? AppColors.darkSuccessBg : AppColors.successBg)
                                  : (isDark ? AppColors.darkWarningBg : AppColors.warningBg),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isFeePaid
                                    ? AppColors.success.withOpacity(0.3)
                                    : AppColors.warning.withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              isFeePaid ? 'PAID' : 'DUE',
                              style: TextStyle(
                                color: isFeePaid ? AppColors.success : AppColors.warning,
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text('Fee Ledger', style: AppTextStyles.headingSmall.copyWith(fontSize: 13.5)),
                    const SizedBox(height: 2),
                    Text(
                      isFeePaid
                          ? 'All dues settled'
                          : CurrencyFormatter.formatINR(feeSummary.pendingAmount),
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: isFeePaid
                            ? AppColors.success
                            : (isDark ? const Color(0xFFFBBF24) : AppColors.warning),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      feeSummary.dueDate != null
                          ? 'Due ${DateFormatter.formatShort(feeSummary.dueDate!)}'
                          : 'Academic Year 2026',
                      style: AppTextStyles.caption.copyWith(fontSize: 10, color: AppColors.textMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        // Row 2: Homework & Class Schedule
        Row(
          children: [
            // 3. Homework Tasks Card
            Expanded(
              child: AnimatedCard(
                onTap: onHomeworkTap,
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkWarningBg : AppColors.warningBg,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.assignment_rounded, color: AppColors.warning, size: 16),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: pendingHwCount == 0
                                  ? (isDark ? AppColors.darkSuccessBg : AppColors.successBg)
                                  : (isDark ? AppColors.darkWarningBg : AppColors.warningBg),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              pendingHwCount == 0 ? 'DONE' : '$pendingHwCount DUE',
                              style: TextStyle(
                                color: pendingHwCount == 0 ? AppColors.success : AppColors.warning,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text('Homework', style: AppTextStyles.headingSmall.copyWith(fontSize: 13.5)),
                    const SizedBox(height: 2),
                    Text(
                      pendingHwCount == 0
                          ? 'No pending assignments'
                          : '${pendingHwList.first.subject}: ${pendingHwList.first.title}',
                      style: AppTextStyles.caption.copyWith(fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      pendingHwCount == 0
                          ? 'Up to date'
                          : 'Due ${DateFormatter.formatShort(pendingHwList.first.dueDate)}',
                      style: AppTextStyles.caption.copyWith(fontSize: 10, color: AppColors.textMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(width: 10),

            // 4. Timetable / Next Period Card
            Expanded(
              child: AnimatedCard(
                onTap: onTimetableTap,
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkCyanBg : AppColors.cyanBg,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.schedule_rounded, color: AppColors.cyan, size: 16),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkCyanBg : AppColors.cyanBg,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              nextClass != null ? 'P-${nextClass!.periodNumber}' : 'TODAY',
                              style: const TextStyle(
                                color: AppColors.cyan,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text('Schedule', style: AppTextStyles.headingSmall.copyWith(fontSize: 13.5)),
                    const SizedBox(height: 2),
                    Text(
                      nextClass != null
                          ? '${nextClass!.subject} (${nextClass!.startTime})'
                          : 'View full schedule',
                      style: AppTextStyles.caption.copyWith(fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      nextClass != null ? nextClass!.room : 'Daily periods',
                      style: AppTextStyles.caption.copyWith(fontSize: 10, color: AppColors.textMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

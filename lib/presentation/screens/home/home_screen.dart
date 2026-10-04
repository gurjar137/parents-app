import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../providers/parent_app_provider.dart';
import '../../widgets/animated_card.dart';
import '../../widgets/child_selector_sheet.dart';
import '../../widgets/needs_attention_card.dart';
import '../../widgets/offline_banner.dart';
import '../../widgets/quick_actions_row.dart';
import '../../widgets/status_badge.dart';
import '../homework/homework_detail_screen.dart';
import '../notices/notice_detail_screen.dart';
import '../notices/notices_screen.dart';
import '../results/results_screen.dart';
import '../calendar/school_calendar_screen.dart';
import '../ai_assistant/ai_assistant_screen.dart';

import '../auth/link_child_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ParentAppProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (provider.isDashboardLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: AppColors.brandIndigo),
              const SizedBox(height: 16),
              Text(
                'Loading Student Dashboard...',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      );
    }

    if (provider.dashboardError != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.cloud_off_rounded, size: 64, color: AppColors.danger),
                const SizedBox(height: 16),
                Text(
                  'Unable to load your child\'s information.',
                  style: AppTextStyles.headingSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  provider.dashboardError!,
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => provider.retryDashboardLoad(),
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

    final child = provider.selectedChild;

    if (!provider.isChildLinked || child.id.isEmpty) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSubSurface : AppColors.infoBg,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.child_care_rounded, size: 64, color: AppColors.brandIndigo),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'No Child Linked',
                    style: AppTextStyles.headingMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enter a Parent Access Code provided by your school to link your child\'s profile and view their dashboard.',
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LinkChildScreen(isFirstTimeSetup: false)),
                      );
                    },
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Enter Parent Access Code'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brandIndigo,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    final attendance = provider.currentAttendance;
    final fee = provider.currentFeeSummary;
    final homeworkList = provider.currentHomeworkList;
    final results = provider.currentResultsList;
    final notices = provider.notices;

    final pendingHwCount = homeworkList.where((h) => !h.isCompleted).length;
    final latestResult = results.isNotEmpty ? results.first : null;

    // Attention Alerts
    List<AttentionAlertItem> attentionAlerts = [];
    if (fee.pendingAmount > 0) {
      final dueStr = fee.dueDate != null ? 'by ${DateFormatter.formatShort(fee.dueDate!)}' : 'soon';
      attentionAlerts.add(AttentionAlertItem(
        icon: Icons.account_balance_wallet_rounded,
        title: 'Fee Payment Due',
        subtitle: '${CurrencyFormatter.formatINR(fee.pendingAmount)} due $dueStr',
        color: AppColors.warning,
        onTap: () => provider.setBottomNavIndex(2),
      ));
    }
    if (pendingHwCount > 0) {
      final nextHw = homeworkList.firstWhere((h) => !h.isCompleted);
      attentionAlerts.add(AttentionAlertItem(
        icon: Icons.assignment_rounded,
        title: '${nextHw.subject} Homework Due Soon',
        subtitle: '${nextHw.title} due ${DateFormatter.formatShort(nextHw.dueDate)}',
        color: AppColors.brandBlue,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => HomeworkDetailScreen(homework: nextHw)),
          );
        },
      ));
    }
    if (latestResult != null) {
      attentionAlerts.add(AttentionAlertItem(
        icon: Icons.grade_rounded,
        title: '${latestResult.examName} Result Published',
        subtitle: 'Scored ${latestResult.overallPercentage.toStringAsFixed(1)}% (Grade ${latestResult.overallGrade})',
        color: AppColors.holiday,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ResultsScreen()),
          );
        },
      ));
    }

    final quickActions = [
      QuickActionItem(
        icon: Icons.assignment_outlined,
        label: 'Homework',
        color: AppColors.warning,
        onTap: () => provider.setBottomNavIndex(1),
      ),
      QuickActionItem(
        icon: Icons.calendar_today_rounded,
        label: 'Attendance',
        color: AppColors.success,
        onTap: () => provider.setBottomNavIndex(1),
      ),
      QuickActionItem(
        icon: Icons.account_balance_wallet_rounded,
        label: 'Fees',
        color: AppColors.brandBlue,
        onTap: () => provider.setBottomNavIndex(2),
      ),
      QuickActionItem(
        icon: Icons.grade_outlined,
        label: 'Results',
        color: AppColors.holiday,
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ResultsScreen())),
      ),
      QuickActionItem(
        icon: Icons.schedule_rounded,
        label: 'Timetable',
        color: const Color(0xFF06B6D4),
        onTap: () => provider.setBottomNavIndex(1),
      ),
      QuickActionItem(
        icon: Icons.chat_bubble_outline_rounded,
        label: 'Messages',
        color: AppColors.brandIndigo,
        onTap: () => provider.setBottomNavIndex(3),
      ),
      QuickActionItem(
        icon: Icons.event_note_rounded,
        label: 'Exams',
        color: const Color(0xFFF59E0B),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SchoolCalendarScreen())),
      ),
      QuickActionItem(
        icon: Icons.auto_awesome_rounded,
        label: 'AI Copilot',
        color: AppColors.brandIndigo,
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AiAssistantScreen())),
      ),
    ];

    return Column(
      children: [
        OfflineBanner(lastUpdatedTime: provider.lastUpdatedTime),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => provider.refreshData(),
            color: AppColors.brandIndigo,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. CHILD SUMMARY CARD
                  AnimatedCard(
                    onTap: () => ChildSelectorSheet.show(context),
                    backgroundColor: AppColors.primary,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundImage: NetworkImage(child.avatarUrl),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        child.name,
                                        style: AppTextStyles.headingMedium.copyWith(color: Colors.white, fontSize: 18),
                                      ),
                                    ),
                                    if (provider.children.length > 1)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Row(
                                          children: [
                                            Text(
                                              'Switch',
                                              style: AppTextStyles.caption.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                                            ),
                                            const Icon(Icons.arrow_drop_down_rounded, color: Colors.white, size: 16),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${child.grade} • Section ${child.section} | Roll No. ${child.rollNo}',
                                  style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Student ID: ${child.admissionNo} • ${provider.branding.schoolName}',
                                  style: AppTextStyles.caption.copyWith(color: Colors.white60, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 2. ATTENTION ALERTS CARD
                  if (attentionAlerts.isNotEmpty) ...[
                    NeedsAttentionCard(alerts: attentionAlerts),
                    const SizedBox(height: 16),
                  ],

                  // 3. QUICK ACTIONS GRID
                  Text('Quick Access', style: AppTextStyles.headingSmall),
                  const SizedBox(height: 12),
                  QuickActionsRow(actions: quickActions),

                  const SizedBox(height: 20),

                  // 4. TODAY SUMMARY SECTION
                  Text('Today\'s Overview', style: AppTextStyles.headingSmall),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      // Attendance Compact Summary
                      Expanded(
                        child: AnimatedCard(
                          onTap: () => provider.setBottomNavIndex(1),
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Icon(Icons.calendar_today_rounded, color: AppColors.success, size: 20),
                                  StatusBadge(
                                    label: '${attendance.percentage.toInt()}%',
                                    type: StatusType.success,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text('Attendance', style: AppTextStyles.headingSmall.copyWith(fontSize: 14)),
                              const SizedBox(height: 2),
                              Text(
                                '${attendance.presentDays} Present, ${attendance.absentDays} Absent',
                                style: AppTextStyles.caption,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      // Fee Compact Summary
                      Expanded(
                        child: AnimatedCard(
                          onTap: () => provider.setBottomNavIndex(2),
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Icon(Icons.account_balance_wallet_rounded, color: AppColors.brandBlue, size: 20),
                                  StatusBadge(
                                    label: fee.pendingAmount == 0 ? 'PAID' : 'DUE',
                                    type: fee.pendingAmount == 0 ? StatusType.success : StatusType.warning,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text('Fee Summary', style: AppTextStyles.headingSmall.copyWith(fontSize: 14)),
                              const SizedBox(height: 2),
                              Text(
                                fee.pendingAmount == 0
                                    ? 'All Fees Settled'
                                    : 'Pending: ${CurrencyFormatter.formatINR(fee.pendingAmount)}',
                                style: AppTextStyles.caption,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // 5. RECENT NOTICES SUMMARY SECTION
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Latest Notices', style: AppTextStyles.headingSmall),
                      GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NoticesScreen())),
                        child: Text('View All', style: AppTextStyles.caption.copyWith(color: AppColors.brandIndigo, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (notices.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSubSurface : AppColors.subSurface,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Text(
                          'No new notices.',
                          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted),
                        ),
                      ),
                    )
                  else
                    ...notices.take(2).map((notice) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: AnimatedCard(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => NoticeDetailScreen(notice: notice)),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(14.0),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppColors.brandIndigo.withOpacity(0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.campaign_rounded, color: AppColors.brandIndigo, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(notice.title, style: AppTextStyles.headingSmall.copyWith(fontSize: 14)),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Published ${DateFormatter.formatShort(notice.date)}',
                                        style: AppTextStyles.caption,
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

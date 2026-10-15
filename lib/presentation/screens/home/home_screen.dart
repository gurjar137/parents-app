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
import '../../widgets/status_badge.dart';
import '../homework/homework_detail_screen.dart';
import '../notices/notice_detail_screen.dart';
import '../notices/notices_screen.dart';
import '../fees/fees_screen.dart';
import '../messages/messages_screen.dart';
import '../timetable/timetable_screen.dart';
import '../transport/transport_screen.dart';
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
    final nextClass = provider.nextClassEntry;

    // Attention Alerts
    final List<AttentionAlertItem> attentionAlerts = [];
    if (fee.pendingAmount > 0) {
      final dueStr = fee.dueDate != null ? 'by ${DateFormatter.formatShort(fee.dueDate!)}' : 'soon';
      attentionAlerts.add(AttentionAlertItem(
        icon: Icons.account_balance_wallet_rounded,
        title: 'Fee Payment Due',
        subtitle: '${CurrencyFormatter.formatINR(fee.pendingAmount)} due $dueStr',
        color: AppColors.warning,
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const FeesScreen()));
        },
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
        icon: Icons.school_rounded,
        title: '${latestResult.examName} Result Published',
        subtitle: 'Scored ${latestResult.overallPercentage.toStringAsFixed(1)}% (Grade ${latestResult.overallGrade})',
        color: AppColors.holiday,
        onTap: () {
          provider.setBottomNavIndex(3);
        },
      ));
    }

    final quickActions = [
      _QuickActionData(
        icon: Icons.calendar_today_rounded,
        label: 'Attendance',
        color: AppColors.success,
        onTap: () => provider.setBottomNavIndex(1),
      ),
      _QuickActionData(
        icon: Icons.assignment_outlined,
        label: 'Homework',
        color: AppColors.warning,
        onTap: () => provider.setBottomNavIndex(2),
      ),
      _QuickActionData(
        icon: Icons.school_outlined,
        label: 'Results',
        color: AppColors.holiday,
        onTap: () => provider.setBottomNavIndex(3),
      ),
      _QuickActionData(
        icon: Icons.account_balance_wallet_rounded,
        label: 'Fees',
        color: AppColors.brandBlue,
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FeesScreen())),
      ),
      _QuickActionData(
        icon: Icons.schedule_rounded,
        label: 'Timetable',
        color: const Color(0xFF06B6D4),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TimetableScreen())),
      ),
      _QuickActionData(
        icon: Icons.campaign_rounded,
        label: 'Notices',
        color: AppColors.warning,
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NoticesScreen())),
      ),
      _QuickActionData(
        icon: Icons.chat_bubble_outline_rounded,
        label: 'Messages',
        color: AppColors.brandIndigo,
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MessagesScreen())),
      ),
      _QuickActionData(
        icon: Icons.directions_bus_rounded,
        label: 'Bus',
        color: const Color(0xFF0D9488),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TransportScreen())),
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
                  // 1. CHILD PROFILE HERO CARD
                  AnimatedCard(
                    onTap: () => ChildSelectorSheet.show(context),
                    backgroundColor: AppColors.primary,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                                child: CircleAvatar(
                                  radius: 28,
                                  backgroundImage: NetworkImage(child.avatarUrl),
                                ),
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
                                            style: AppTextStyles.headingMedium.copyWith(
                                              color: Colors.white,
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        if (provider.children.length > 1)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(0.2),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: const Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  'Switch',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                SizedBox(width: 2),
                                                Icon(Icons.arrow_drop_down_rounded, color: Colors.white, size: 16),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${child.grade} • Section ${child.section} | Roll No. ${child.rollNo}',
                                      style: AppTextStyles.bodyMedium.copyWith(color: Colors.white.withOpacity(0.9)),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Divider(color: Colors.white12, height: 1),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.badge_outlined, color: Colors.white60, size: 14),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Adm: ${child.admissionNo}',
                                    style: AppTextStyles.caption.copyWith(color: Colors.white70, fontSize: 11),
                                  ),
                                ],
                              ),
                              if (child.fatherName != null && child.fatherName!.trim().isNotEmpty)
                                Row(
                                  children: [
                                    const Icon(Icons.person_outline, color: Colors.white60, size: 14),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Father: ${child.fatherName!.trim()}',
                                      style: AppTextStyles.caption.copyWith(color: Colors.white70, fontSize: 11),
                                    ),
                                  ],
                                ),
                              Row(
                                children: [
                                  const Icon(Icons.account_balance_outlined, color: Colors.white60, size: 14),
                                  const SizedBox(width: 4),
                                  Text(
                                    provider.branding.schoolName,
                                    style: AppTextStyles.caption.copyWith(color: Colors.white70, fontSize: 11),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 2. ATTENTION ALERTS
                  if (attentionAlerts.isNotEmpty) ...[
                    NeedsAttentionCard(alerts: attentionAlerts),
                    const SizedBox(height: 16),
                  ],

                  // 3. QUICK ACTIONS GRID (4 columns)
                  Text('Quick Access', style: AppTextStyles.headingSmall),
                  const SizedBox(height: 12),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: quickActions.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 0.88,
                    ),
                    itemBuilder: (context, index) {
                      final item = quickActions[index];
                      return InkWell(
                        onTap: item.onTap,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkSurface : AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
                            boxShadow: const [BoxShadow(color: AppColors.shadow, blurRadius: 4)],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: item.color.withOpacity(0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(item.icon, color: item.color, size: 22),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                item.label,
                                style: AppTextStyles.caption.copyWith(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11,
                                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 20),

                  // 4. TODAY'S ACADEMIC OVERVIEW
                  Text('Today\'s Overview', style: AppTextStyles.headingSmall),
                  const SizedBox(height: 12),

                  // Row 1: Attendance & Fees
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
                                    label: '${attendance.percentage.toStringAsFixed(1)}%',
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
                                  minHeight: 5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      // Fee Compact Summary
                      Expanded(
                        child: AnimatedCard(
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const FeesScreen()));
                          },
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
                                style: AppTextStyles.caption.copyWith(
                                  color: fee.pendingAmount == 0 ? AppColors.success : AppColors.warning,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                fee.dueDate != null ? 'Due ${DateFormatter.formatShort(fee.dueDate!)}' : 'Session 2026-27',
                                style: AppTextStyles.caption.copyWith(fontSize: 10, color: AppColors.textMuted),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Row 2: Homework & Schedule
                  Row(
                    children: [
                      // Homework Status Card
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
                                  const Icon(Icons.assignment_outlined, color: AppColors.warning, size: 20),
                                  StatusBadge(
                                    label: pendingHwCount == 0 ? 'DONE' : '$pendingHwCount DUE',
                                    type: pendingHwCount == 0 ? StatusType.success : StatusType.warning,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text('Homework', style: AppTextStyles.headingSmall.copyWith(fontSize: 14)),
                              const SizedBox(height: 2),
                              Text(
                                pendingHwCount == 0
                                    ? 'All tasks completed!'
                                    : '${homeworkList.where((h) => !h.isCompleted).first.subject}: ${homeworkList.where((h) => !h.isCompleted).first.title}',
                                style: AppTextStyles.caption,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      // Timetable Period Card
                      Expanded(
                        child: AnimatedCard(
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const TimetableScreen()));
                          },
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Icon(Icons.schedule_rounded, color: Color(0xFF06B6D4), size: 20),
                                  StatusBadge(
                                    label: 'ROUTINE',
                                    type: StatusType.info,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text('Schedule', style: AppTextStyles.headingSmall.copyWith(fontSize: 14)),
                              const SizedBox(height: 2),
                              Text(
                                nextClass != null
                                    ? '${nextClass.subject} (${nextClass.startTime})'
                                    : 'View class timetable',
                                style: AppTextStyles.caption,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
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
                      Text('Latest School Notices', style: AppTextStyles.headingSmall),
                      GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NoticesScreen())),
                        child: Text(
                          'View All',
                          style: AppTextStyles.caption.copyWith(color: AppColors.brandIndigo, fontWeight: FontWeight.bold),
                        ),
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
                          'No new notices at this time.',
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

class _QuickActionData {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionData({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
}

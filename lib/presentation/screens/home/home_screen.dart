import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../providers/parent_app_provider.dart';
import '../../widgets/animated_card.dart';
import '../../widgets/child_profile_hero_card.dart';
import '../../widgets/needs_attention_card.dart';
import '../../widgets/offline_banner.dart';
import '../../widgets/quick_access_grid.dart';
import '../../widgets/staggered_entrance.dart';
import '../../widgets/todays_academic_overview.dart';
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

    final pendingHwCount = homeworkList.where((h) => !h.isOverdue).length;
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
      final nextHw = homeworkList.lastWhere((h) => !h.isOverdue);
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
        subtitle: 'Scored ${latestResult.overallPercentage.toStringAsFixed(1)}%',
        color: AppColors.holiday,
        onTap: () {
          provider.setBottomNavIndex(3);
        },
      ));
    }

    final quickActions = [
      QuickActionItemData(
        icon: Icons.calendar_today_rounded,
        label: 'Attendance',
        iconColor: AppColors.success,
        bgColor: isDark ? AppColors.darkSuccessBg : AppColors.successBg,
        onTap: () => provider.setBottomNavIndex(1),
      ),
      QuickActionItemData(
        icon: Icons.assignment_outlined,
        label: 'Homework',
        iconColor: AppColors.warning,
        bgColor: isDark ? AppColors.darkWarningBg : AppColors.warningBg,
        onTap: () => provider.setBottomNavIndex(2),
        badgeText: pendingHwCount > 0 ? '$pendingHwCount' : null,
        badgeColor: AppColors.danger,
      ),
      QuickActionItemData(
        icon: Icons.school_outlined,
        label: 'Results',
        iconColor: AppColors.accent,
        bgColor: isDark ? AppColors.darkAccentBg : AppColors.accentBg,
        onTap: () => provider.setBottomNavIndex(3),
      ),
      QuickActionItemData(
        icon: Icons.account_balance_wallet_rounded,
        label: 'Fees',
        iconColor: AppColors.brandBlue,
        bgColor: isDark ? AppColors.darkInfoBg : AppColors.infoBg,
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FeesScreen())),
        badgeText: fee.pendingAmount > 0 ? 'DUE' : null,
        badgeColor: AppColors.danger,
      ),
      QuickActionItemData(
        icon: Icons.schedule_rounded,
        label: 'Timetable',
        iconColor: AppColors.cyan,
        bgColor: isDark ? AppColors.darkCyanBg : AppColors.cyanBg,
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TimetableScreen())),
      ),
      QuickActionItemData(
        icon: Icons.campaign_rounded,
        label: 'Notices',
        iconColor: AppColors.warning,
        bgColor: isDark ? AppColors.darkWarningBg : AppColors.warningBg,
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NoticesScreen())),
        badgeText: notices.isNotEmpty ? '${notices.length}' : null,
      ),
      QuickActionItemData(
        icon: Icons.chat_bubble_outline_rounded,
        label: 'Messages',
        iconColor: AppColors.brandIndigo,
        bgColor: isDark ? AppColors.darkPrimaryBg : AppColors.primaryBg,
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MessagesScreen())),
      ),
      QuickActionItemData(
        icon: Icons.directions_bus_rounded,
        label: 'Bus',
        iconColor: AppColors.teal,
        bgColor: isDark ? AppColors.darkTealBg : AppColors.tealBg,
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. CHILD PROFILE HERO CARD
                  StaggeredEntrance(
                    index: 0,
                    child: ChildProfileHeroCard(
                      child: child,
                      branding: provider.branding,
                      totalChildrenCount: provider.children.length,
                    ),
                  ),

                  // 2. ATTENTION ALERTS
                  if (attentionAlerts.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    StaggeredEntrance(
                      index: 1,
                      child: NeedsAttentionCard(alerts: attentionAlerts),
                    ),
                  ],

                  const SizedBox(height: 18),

                  // 3. QUICK ACCESS GRID
                  StaggeredEntrance(
                    index: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                'Quick Access',
                                style: AppTextStyles.headingSmall.copyWith(fontSize: 16),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${quickActions.length} Actions',
                              style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        QuickAccessGrid(actions: quickActions),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 4. TODAY'S ACADEMIC OVERVIEW
                  StaggeredEntrance(
                    index: 3,
                    child: TodaysAcademicOverview(
                      attendance: attendance,
                      feeSummary: fee,
                      homeworkList: homeworkList,
                      nextClass: nextClass,
                      onAttendanceTap: () => provider.setBottomNavIndex(1),
                      onFeesTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const FeesScreen()));
                      },
                      onHomeworkTap: () => provider.setBottomNavIndex(2),
                      onTimetableTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const TimetableScreen()));
                      },
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 5. RECENT NOTICES SUMMARY SECTION
                  StaggeredEntrance(
                    index: 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                'Latest School Notices',
                                style: AppTextStyles.headingSmall.copyWith(fontSize: 16),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NoticesScreen())),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'View All',
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppColors.brandIndigo,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  const Icon(Icons.arrow_forward_ios_rounded, size: 11, color: AppColors.brandIndigo),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (notices.isEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkSurface : AppColors.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
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
                                padding: const EdgeInsets.all(14.0),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: isDark ? AppColors.darkPrimaryBg : AppColors.primaryBg,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.campaign_rounded, color: AppColors.brandIndigo, size: 20),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            notice.title,
                                            style: AppTextStyles.headingSmall.copyWith(fontSize: 14),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            'Published ${DateFormatter.formatShort(notice.date)}',
                                            style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 20),
                                  ],
                                ),
                              ),
                            );
                          }),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

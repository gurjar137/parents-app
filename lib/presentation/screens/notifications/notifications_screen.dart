import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/notification_model.dart';
import '../../../providers/parent_app_provider.dart';
import '../../widgets/animated_card.dart';
import '../../widgets/empty_state_widget.dart';
import '../attendance/attendance_screen.dart';
import '../homework/homework_screen.dart';
import '../notices/notices_screen.dart';
import '../results/results_screen.dart';
import '../fees/fees_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  String _selectedFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ParentAppProvider>(context);
    final child = provider.selectedChild;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (!provider.isChildLinked) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Notification Center', style: AppTextStyles.headingSmall),
          elevation: 0,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.notifications_off_outlined, size: 64, color: AppColors.textMuted),
                const SizedBox(height: 16),
                Text('No Child Linked', style: AppTextStyles.headingSmall),
                const SizedBox(height: 8),
                Text(
                  'Please link a student profile to view notification alerts.',
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (provider.isNotificationsLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Notification Center • ${child.name}', style: AppTextStyles.headingSmall),
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: AppColors.brandIndigo),
              const SizedBox(height: 16),
              Text(
                'Loading notification history...',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      );
    }

    if (provider.notificationsError != null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Notification Center • ${child.name}', style: AppTextStyles.headingSmall),
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
                  'Unable to load notifications. Please try again.',
                  style: AppTextStyles.headingSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  provider.notificationsError!,
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => provider.loadNotificationsForSelectedChild(),
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

    final allNotifications = provider.notifications;
    final filteredNotifications = _selectedFilter == 'Unread'
        ? allNotifications.where((n) => !n.isRead).toList()
        : allNotifications;

    return Scaffold(
      appBar: AppBar(
        title: Text('Notification Center • ${child.name}', style: AppTextStyles.headingSmall),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            onPressed: () => _showNotificationPreferencesModal(context),
            tooltip: 'Notification Preferences',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Tabs (All / Unread)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: ['All', 'Unread'].map((filter) {
                final isSelected = _selectedFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    selected: isSelected,
                    label: Text(filter == 'Unread' ? 'Unread (${provider.unreadNotificationsCount})' : 'All Alerts'),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    selectedColor: AppColors.brandIndigo,
                    backgroundColor: isDark ? AppColors.darkSubSurface : AppColors.subSurface,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    onSelected: (selected) {
                      setState(() => _selectedFilter = filter);
                    },
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 4),

          // Notifications List
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => provider.loadNotificationsForSelectedChild(),
              color: AppColors.brandIndigo,
              child: filteredNotifications.isEmpty
                  ? SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: SizedBox(
                        height: MediaQuery.of(context).size.height * 0.5,
                        child: EmptyStateWidget(
                          icon: Icons.notifications_none_rounded,
                          title: _selectedFilter == 'Unread' ? 'No new notifications' : 'No notifications yet',
                          description: 'You are all caught up! Real-time alerts for ${child.name} will appear here.',
                        ),
                      ),
                    )
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                      padding: const EdgeInsets.all(16),
                    itemCount: filteredNotifications.length,
                    itemBuilder: (context, index) {
                      final item = filteredNotifications[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: AnimatedCard(
                          onTap: () {
                            provider.markAppNotificationAsRead(item.id);
                            _navigateToDeepLink(context, item);
                          },
                          backgroundColor: item.isRead
                              ? (isDark ? AppColors.darkSurface : AppColors.surface)
                              : (isDark ? AppColors.darkSubSurface : AppColors.infoBg.withOpacity(0.4)),
                          child: Padding(
                            padding: const EdgeInsets.all(14.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: _getCategoryColor(item.category).withOpacity(0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    _getCategoryIcon(item.category),
                                    color: _getCategoryColor(item.category),
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(item.title, style: AppTextStyles.headingSmall.copyWith(fontSize: 14)),
                                          Text(DateFormatter.formatTime(item.timestamp), style: AppTextStyles.caption),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(item.message, style: AppTextStyles.bodyMedium),
                                    ],
                                  ),
                                ),
                                if (!item.isRead) ...[
                                  const SizedBox(width: 8),
                                  const CircleAvatar(
                                    radius: 4,
                                    backgroundColor: AppColors.brandBlue,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToDeepLink(BuildContext context, AppNotificationModel item) {
    Widget targetScreen;
    switch (item.targetType) {
      case 'homework':
        targetScreen = const HomeworkScreen();
        break;
      case 'attendance':
        targetScreen = const AttendanceScreen();
        break;
      case 'notice':
        targetScreen = const NoticesScreen();
        break;
      case 'result':
        targetScreen = const ResultsScreen();
        break;
      case 'fee':
        targetScreen = const FeesScreen();
        break;
      default:
        targetScreen = const NoticesScreen();
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => targetScreen),
    );
  }

  void _showNotificationPreferencesModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Notification Preferences', style: AppTextStyles.headingMedium),
                  const SizedBox(height: 6),
                  Text('Choose categories you want to receive mobile push notifications for:', style: AppTextStyles.bodyMedium),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Homework Assignments'),
                    value: true,
                    activeColor: AppColors.brandIndigo,
                    onChanged: (val) {},
                  ),
                  SwitchListTile(
                    title: const Text('Attendance Updates'),
                    value: true,
                    activeColor: AppColors.brandIndigo,
                    onChanged: (val) {},
                  ),
                  SwitchListTile(
                    title: const Text('Exam Results & Marks'),
                    value: true,
                    activeColor: AppColors.brandIndigo,
                    onChanged: (val) {},
                  ),
                  SwitchListTile(
                    title: const Text('Fee Reminders & Receipts'),
                    value: true,
                    activeColor: AppColors.brandIndigo,
                    onChanged: (val) {},
                  ),
                  SwitchListTile(
                    title: const Text('Mandatory School Notices (Required)'),
                    value: true,
                    activeColor: AppColors.brandIndigo,
                    onChanged: null, // mandatory school notices cannot be disabled
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Save Preferences'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  IconData _getCategoryIcon(String cat) {
    switch (cat.toLowerCase()) {
      case 'attendance':
        return Icons.calendar_today_rounded;
      case 'homework':
        return Icons.assignment_outlined;
      case 'fees':
      case 'fee':
        return Icons.account_balance_wallet_rounded;
      case 'results':
      case 'result':
        return Icons.grade_outlined;
      case 'notices':
      case 'notice':
        return Icons.campaign_outlined;
      default:
        return Icons.notifications_active_rounded;
    }
  }

  Color _getCategoryColor(String cat) {
    switch (cat.toLowerCase()) {
      case 'attendance':
        return AppColors.success;
      case 'homework':
        return AppColors.warning;
      case 'fees':
      case 'fee':
        return AppColors.brandBlue;
      case 'results':
      case 'result':
        return AppColors.holiday;
      case 'notices':
      case 'notice':
        return AppColors.danger;
      default:
        return AppColors.brandIndigo;
    }
  }
}

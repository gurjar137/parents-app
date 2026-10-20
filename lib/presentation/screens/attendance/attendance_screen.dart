import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/attendance_model.dart';
import '../../../providers/parent_app_provider.dart';
import '../../widgets/animated_card.dart';
import '../../widgets/status_badge.dart';

class AttendanceScreen extends StatelessWidget {
  const AttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ParentAppProvider>(context);
    final child = provider.selectedChild;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (!provider.hasAttendanceData && provider.attendanceError == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Attendance Record', style: AppTextStyles.headingSmall),
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: AppColors.brandIndigo),
              const SizedBox(height: 16),
              Text(
                'Loading attendance for ${child.name}...',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      );
    }

    if (provider.attendanceError != null && !provider.isAttendanceLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Attendance Record', style: AppTextStyles.headingSmall),
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
                  'Unable to load attendance. Please try again.',
                  style: AppTextStyles.headingSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  provider.attendanceError!,
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => provider.loadAttendanceForSelectedChild(),
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

    final summary = provider.currentAttendance;
    final today = provider.todayAttendance;
    final isLowAttendance = summary.hasRecords && summary.percentage < 85.0;

    return Scaffold(
      appBar: AppBar(
        title: Text('Attendance Record', style: AppTextStyles.headingSmall),
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () => provider.loadAttendanceForSelectedChild(),
        color: AppColors.brandIndigo,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            // 1. STUDENT OVERVIEW HEADER CARD
            AnimatedCard(
              backgroundColor: AppColors.primary,
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: AppColors.brandIndigo,
                        backgroundImage: child.avatarUrl.startsWith('http') ? NetworkImage(child.avatarUrl) : null,
                        child: child.avatarUrl.startsWith('http')
                            ? null
                            : Text(child.name.isNotEmpty ? child.name[0].toUpperCase() : '?',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              child.name,
                              style: AppTextStyles.headingSmall.copyWith(color: Colors.white, fontSize: 16),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              ['Class ${child.className}', if (child.rollNo > 0) 'Roll No. ${child.rollNo}'].join(' • '),
                              style: AppTextStyles.bodySmall.copyWith(color: Colors.white70),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // PERCENTAGE BADGE WITH PERFECT CENTERING
                      Container(
                        constraints: const BoxConstraints(minWidth: 64, minHeight: 38),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: !summary.hasRecords ? AppColors.textMuted : (summary.percentage >= 85 ? AppColors.success : AppColors.warning),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              !summary.hasRecords
                                  ? '—'
                                  : summary.percentage % 1 == 0
                                  ? '${summary.percentage.toInt()}%'
                                  : '${summary.percentage.toStringAsFixed(1)}%',
                              style: AppTextStyles.headingSmall.copyWith(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: Colors.white24, height: 1),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildMetricItem('Present', '${summary.presentDays} days', AppColors.success),
                      _buildMetricItem('Absent', '${summary.absentDays} days', AppColors.danger),
                      _buildMetricItem('Late', '${summary.lateDays} days', AppColors.warning),
                      _buildMetricItem('Leave', '${summary.leaveDays} days', AppColors.brandBlue),
                      _buildMetricItem('Holidays', '${summary.holidayDays} days', AppColors.holiday),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 2. TODAY'S ATTENDANCE STATUS CARD
            AnimatedCard(
              backgroundColor: isDark ? AppColors.darkSubSurface : AppColors.subSurface,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _getTodayStatusColor(today?.status).withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getTodayStatusIcon(today?.status),
                      color: _getTodayStatusColor(today?.status),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Today\'s Attendance (${DateFormatter.formatShort(DateTime.now())})',
                          style: AppTextStyles.headingSmall.copyWith(fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          today != null
                              ? _getTodayStatusLabel(today.status)
                              : 'Today\'s attendance has not been recorded yet.',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: _getTodayStatusColor(today?.status),
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 3. ATTENDANCE INSIGHT CARD
            AnimatedCard(
              backgroundColor: isLowAttendance ? AppColors.warningBg : AppColors.infoBg,
              border: Border.all(color: isLowAttendance ? AppColors.warning : AppColors.brandBlue),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Icon(
                      isLowAttendance ? Icons.info_outline_rounded : Icons.check_circle_outline_rounded,
                      color: isLowAttendance ? AppColors.warning : AppColors.brandBlue,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Attendance Insight',
                          style: AppTextStyles.headingSmall.copyWith(
                            fontSize: 13,
                            color: isLowAttendance ? AppColors.warning : AppColors.brandBlue,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          !summary.hasRecords
                              ? 'No attendance has been recorded for ${summary.monthYear} yet.'
                              : isLowAttendance
                              ? 'Attendance is below 85% this month. Consistent attendance supports academic success.'
                              : '${child.name.split(' ').first} has attended ${summary.percentage % 1 == 0 ? summary.percentage.toInt() : summary.percentage.toStringAsFixed(1)}% of school days this month.',
                          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 4. MONTH NAVIGATION & CALENDAR VIEW
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(summary.monthYear, style: AppTextStyles.headingSmall),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left_rounded),
                      onPressed: () {
                        final currentMonth = provider.attendanceMonth;
                        final currentYear = provider.attendanceYear;
                        if (currentMonth == 1) {
                          provider.changeAttendanceMonth(currentYear - 1, 12);
                        } else {
                          provider.changeAttendanceMonth(currentYear, currentMonth - 1);
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right_rounded),
                      onPressed: () {
                        final currentMonth = provider.attendanceMonth;
                        final currentYear = provider.attendanceYear;
                        if (currentMonth == 12) {
                          provider.changeAttendanceMonth(currentYear + 1, 1);
                        } else {
                          provider.changeAttendanceMonth(currentYear, currentMonth + 1);
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),

            // LEGEND BADGES
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: const [
                  StatusBadge(label: 'PRESENT', type: StatusType.success),
                  SizedBox(width: 8),
                  StatusBadge(label: 'ABSENT', type: StatusType.danger),
                  SizedBox(width: 8),
                  StatusBadge(label: 'LATE', type: StatusType.warning),
                  SizedBox(width: 8),
                  StatusBadge(label: 'LEAVE', type: StatusType.info),
                  SizedBox(width: 8),
                  StatusBadge(label: 'HOLIDAY', type: StatusType.holiday),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // CALENDAR GRID VIEW OR EMPTY STATE
            if (summary.dailyRecords.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSubSurface : AppColors.subSurface,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Text(
                    'No attendance records available yet.',
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted),
                  ),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
                  boxShadow: const [BoxShadow(color: AppColors.shadow, blurRadius: 8)],
                ),
                child: Column(
                  children: [
                    Row(
                      children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                          .map((day) => Expanded(
                                child: Center(
                                  child: Text(
                                    day,
                                    style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                    const Divider(height: 20),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 7,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        childAspectRatio: 1,
                      ),
                      itemCount: summary.dailyRecords.length,
                      itemBuilder: (context, index) {
                        final record = summary.dailyRecords[index];
                        return _buildCalendarDayTile(context, record);
                      },
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildMetricItem(String label, String value, Color color) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: AppTextStyles.headingSmall.copyWith(color: Colors.white, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: AppTextStyles.caption.copyWith(color: Colors.white70, fontSize: 10),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarDayTile(BuildContext context, DailyAttendance record) {
    Color bg;
    Color fg;

    switch (record.status) {
      case AttendanceStatus.present:
        bg = AppColors.successBg;
        fg = AppColors.success;
        break;
      case AttendanceStatus.absent:
        bg = AppColors.dangerBg;
        fg = AppColors.danger;
        break;
      case AttendanceStatus.late:
        bg = AppColors.warningBg;
        fg = AppColors.warning;
        break;
      case AttendanceStatus.leave:
        bg = AppColors.infoBg;
        fg = AppColors.info;
        break;
      case AttendanceStatus.holiday:
        bg = AppColors.holidayBg;
        fg = AppColors.holiday;
        break;
    }

    return InkWell(
      onTap: () => _showDayDetailDialog(context, record),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: fg.withOpacity(0.4)),
        ),
        child: Center(
          child: Text(
            '${record.date.day}',
            style: TextStyle(
              color: fg,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  void _showDayDetailDialog(BuildContext context, DailyAttendance record) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(
              _getTodayStatusIcon(record.status),
              color: _getTodayStatusColor(record.status),
            ),
            const SizedBox(width: 10),
            Text(DateFormatter.formatFull(record.date), style: AppTextStyles.headingSmall.copyWith(fontSize: 15)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Status: ', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                Text(_getTodayStatusLabel(record.status), style: AppTextStyles.bodyMedium.copyWith(color: _getTodayStatusColor(record.status))),
              ],
            ),
            if (record.remark != null && record.remark!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text('Remarks:', style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.subSurface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(record.remark!, style: AppTextStyles.bodySmall),
              ),
            ],
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Color _getTodayStatusColor(AttendanceStatus? status) {
    switch (status) {
      case AttendanceStatus.present:
        return AppColors.success;
      case AttendanceStatus.absent:
        return AppColors.danger;
      case AttendanceStatus.late:
        return AppColors.warning;
      case AttendanceStatus.leave:
        return AppColors.brandBlue;
      case AttendanceStatus.holiday:
        return AppColors.holiday;
      default:
        return AppColors.textMuted;
    }
  }

  IconData _getTodayStatusIcon(AttendanceStatus? status) {
    switch (status) {
      case AttendanceStatus.present:
        return Icons.check_circle_rounded;
      case AttendanceStatus.absent:
        return Icons.cancel_rounded;
      case AttendanceStatus.late:
        return Icons.access_time_filled_rounded;
      case AttendanceStatus.leave:
        return Icons.description_rounded;
      case AttendanceStatus.holiday:
        return Icons.beach_access_rounded;
      default:
        return Icons.schedule_rounded;
    }
  }

  String _getTodayStatusLabel(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return '✓ Present in School';
      case AttendanceStatus.absent:
        return '✕ Absent';
      case AttendanceStatus.late:
        return '⏰ Late Arrival';
      case AttendanceStatus.leave:
        return '📝 Authorized Leave';
      case AttendanceStatus.holiday:
        return '🏖️ School Holiday';
    }
  }
}

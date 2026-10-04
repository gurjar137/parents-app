import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/timetable_model.dart';
import '../../../providers/parent_app_provider.dart';
import '../../widgets/animated_card.dart';
import '../../widgets/empty_state_widget.dart';

class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key});

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];

  @override
  void initState() {
    super.initState();
    // Default tab index set to current weekday (1=Mon ... 6=Sat)
    final currentWeekday = DateTime.now().weekday;
    final defaultIndex = (currentWeekday >= 1 && currentWeekday <= 6) ? currentWeekday - 1 : 0;
    _tabController = TabController(length: _days.length, vsync: this, initialIndex: defaultIndex);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ParentAppProvider>(context);
    final child = provider.selectedChild;

    if (!provider.isChildLinked) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Timetable', style: AppTextStyles.headingSmall),
          elevation: 0,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.calendar_today_outlined, size: 64, color: AppColors.textMuted),
                const SizedBox(height: 16),
                Text('No Child Linked', style: AppTextStyles.headingSmall),
                const SizedBox(height: 8),
                Text(
                  'Please link a student profile to view the class timetable.',
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (provider.isTimetableLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Timetable • ${child.name}', style: AppTextStyles.headingSmall),
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: AppColors.brandIndigo),
              const SizedBox(height: 16),
              Text(
                'Loading timetable for ${child.name}...',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      );
    }

    if (provider.timetableError != null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Timetable • ${child.name}', style: AppTextStyles.headingSmall),
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
                  'Unable to load timetable. Please try again.',
                  style: AppTextStyles.headingSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  provider.timetableError!,
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => provider.loadTimetableForSelectedChild(),
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

    final timetableMap = provider.currentTimetable;
    final nextClass = provider.nextClassEntry;

    return Scaffold(
      appBar: AppBar(
        title: Text('Class ${child.className} Timetable', style: AppTextStyles.headingSmall),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppColors.brandIndigo,
          unselectedLabelColor: AppColors.textMuted,
          indicatorColor: AppColors.brandIndigo,
          indicatorWeight: 3,
          tabs: _days.map((day) => Tab(text: day.substring(0, 3).toUpperCase())).toList(),
        ),
      ),
      body: Column(
        children: [
          // Next Upcoming Class Banner
          if (nextClass != null) ...[
            Padding(
              padding: const EdgeInsets.all(16),
              child: AnimatedCard(
                backgroundColor: AppColors.primary,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(
                          color: Colors.white24,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.schedule_rounded, color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('NEXT UPCOMING CLASS', style: AppTextStyles.caption.copyWith(color: Colors.white70, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 2),
                            Text(
                              '${nextClass.subject} (${nextClass.startTime})',
                              style: AppTextStyles.headingSmall.copyWith(color: Colors.white, fontSize: 15),
                            ),
                            Text(
                              '${nextClass.room} • ${nextClass.teacherName}',
                              style: AppTextStyles.caption.copyWith(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],

          // Daily Schedules TabBarView
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _days.map((day) {
                final dayEntries = timetableMap[day] ?? [];
                return _buildDailySchedule(context, day, dayEntries);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailySchedule(BuildContext context, String dayName, List<TimetableEntryModel> entries) {
    if (entries.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.event_busy_outlined,
        title: 'No classes scheduled for $dayName',
        description: 'Enjoy your day off or review study materials.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        if (entry.isBreak) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.subSurface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.restaurant_rounded, color: AppColors.textMuted, size: 18),
                  const SizedBox(width: 12),
                  Text('${entry.startTime} - ${entry.endTime}', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 16),
                  Text(entry.subject, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: AnimatedCard(
            onTap: () => _showClassDetailDialog(context, entry),
            child: Padding(
              padding: const EdgeInsets.all(14.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.infoBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(entry.startTime, style: AppTextStyles.caption.copyWith(color: AppColors.brandBlue, fontWeight: FontWeight.bold)),
                        Text('to', style: AppTextStyles.caption.copyWith(fontSize: 9, color: AppColors.textMuted)),
                        Text(entry.endTime, style: AppTextStyles.caption.copyWith(color: AppColors.brandBlue)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(entry.subject, style: AppTextStyles.headingSmall.copyWith(fontSize: 16)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.meeting_room_outlined, size: 14, color: AppColors.textMuted),
                            const SizedBox(width: 4),
                            Text(entry.room, style: AppTextStyles.bodySmall),
                            const SizedBox(width: 12),
                            const Icon(Icons.person_outline_rounded, size: 14, color: AppColors.textMuted),
                            const SizedBox(width: 4),
                            Text(entry.teacherName, style: AppTextStyles.bodySmall),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showClassDetailDialog(BuildContext context, TimetableEntryModel entry) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.class_rounded, color: AppColors.brandIndigo),
            const SizedBox(width: 10),
            Text(entry.subject, style: AppTextStyles.headingSmall.copyWith(fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Time:', '${entry.startTime} – ${entry.endTime}'),
            const SizedBox(height: 8),
            _buildDetailRow('Teacher:', entry.teacherName),
            const SizedBox(height: 8),
            _buildDetailRow('Room / Venue:', entry.room),
            const SizedBox(height: 8),
            _buildDetailRow('Day:', entry.dayOfWeek),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandIndigo,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(label, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted, fontWeight: FontWeight.bold)),
        ),
        Expanded(
          child: Text(value, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}

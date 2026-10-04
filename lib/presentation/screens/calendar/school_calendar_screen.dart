import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/calendar_event_model.dart';
import '../../../providers/parent_app_provider.dart';
import '../../widgets/animated_card.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/status_badge.dart';

class SchoolCalendarScreen extends StatefulWidget {
  const SchoolCalendarScreen({super.key});

  @override
  State<SchoolCalendarScreen> createState() => _SchoolCalendarScreenState();
}

class _SchoolCalendarScreenState extends State<SchoolCalendarScreen> {
  String _selectedCategory = 'All';
  final List<String> _categories = ['All', 'Holidays', 'Exams', 'PTM', 'Events', 'Sports'];

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ParentAppProvider>(context);
    final allEvents = provider.calendarEvents;

    final filteredEvents = allEvents.where((e) {
      if (_selectedCategory == 'All') return true;
      switch (_selectedCategory) {
        case 'Holidays':
          return e.category == EventCategory.holiday;
        case 'Exams':
          return e.category == EventCategory.exam;
        case 'PTM':
          return e.category == EventCategory.ptm;
        case 'Events':
          return e.category == EventCategory.event;
        case 'Sports':
          return e.category == EventCategory.sports;
        default:
          return true;
      }
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Academic Calendar 2026', style: AppTextStyles.headingSmall),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Filter Chips Scroll View
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: _categories.map((cat) {
                final isSelected = _selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    selected: isSelected,
                    label: Text(cat),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    selectedColor: AppColors.brandIndigo,
                    backgroundColor: AppColors.surface,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    onSelected: (selected) {
                      setState(() => _selectedCategory = cat);
                    },
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 8),

          // Events List
          Expanded(
            child: filteredEvents.isEmpty
                ? const EmptyStateWidget(
                    icon: Icons.event_busy_rounded,
                    title: 'No events found',
                    description: 'There are no calendar events in this category.',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredEvents.length,
                    itemBuilder: (context, index) {
                      final ev = filteredEvents[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: AnimatedCard(
                          onTap: () => _showEventDetailsModal(context, ev),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Date Box
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: _getCategoryColor(ev.category).withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      '${ev.date.day}',
                                      style: AppTextStyles.headingSmall.copyWith(
                                        color: _getCategoryColor(ev.category),
                                        fontSize: 18,
                                      ),
                                    ),
                                    Text(
                                      DateFormatter.formatShort(ev.date).split(' ')[1].toUpperCase(),
                                      style: AppTextStyles.caption.copyWith(
                                        color: _getCategoryColor(ev.category),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
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
                                        StatusBadge(
                                          label: ev.category.name.toUpperCase(),
                                          type: _getStatusType(ev.category),
                                        ),
                                        Text(ev.timeRange, style: AppTextStyles.caption),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(ev.title, style: AppTextStyles.headingSmall.copyWith(fontSize: 15)),
                                    const SizedBox(height: 4),
                                    Text(ev.location, style: AppTextStyles.bodySmall),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showEventDetailsModal(BuildContext context, CalendarEventModel ev) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                StatusBadge(label: ev.category.name.toUpperCase(), type: _getStatusType(ev.category)),
                Text(DateFormatter.formatFull(ev.date), style: AppTextStyles.caption),
              ],
            ),
            const SizedBox(height: 16),
            Text(ev.title, style: AppTextStyles.headingMedium),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.schedule_rounded, size: 16, color: AppColors.textMuted),
                const SizedBox(width: 6),
                Text(ev.timeRange, style: AppTextStyles.bodyMedium),
                const SizedBox(width: 16),
                const Icon(Icons.location_on_outlined, size: 16, color: AppColors.textMuted),
                const SizedBox(width: 6),
                Text(ev.location, style: AppTextStyles.bodyMedium),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            Text(ev.description, style: AppTextStyles.bodyLarge),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(EventCategory cat) {
    switch (cat) {
      case EventCategory.holiday:
        return AppColors.holiday;
      case EventCategory.exam:
        return AppColors.danger;
      case EventCategory.ptm:
        return AppColors.brandIndigo;
      case EventCategory.event:
        return AppColors.brandBlue;
      case EventCategory.sports:
        return AppColors.success;
      case EventCategory.activity:
        return AppColors.warning;
    }
  }

  StatusType _getStatusType(EventCategory cat) {
    switch (cat) {
      case EventCategory.holiday:
        return StatusType.holiday;
      case EventCategory.exam:
        return StatusType.danger;
      case EventCategory.ptm:
        return StatusType.info;
      case EventCategory.event:
        return StatusType.info;
      case EventCategory.sports:
        return StatusType.success;
      case EventCategory.activity:
        return StatusType.warning;
    }
  }
}

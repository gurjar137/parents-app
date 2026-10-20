import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../providers/parent_app_provider.dart';
import '../../widgets/animated_card.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/stat_row.dart';

class PtmScreen extends StatelessWidget {
  const PtmScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ParentAppProvider>(context);
    final child = provider.selectedChild;
    final ptm = provider.currentPtmSchedule;

    if (!provider.isChildLinked || ptm == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Parent-Teacher Meeting')),
        body: const EmptyStateWidget(
          icon: Icons.groups_outlined,
          title: 'PTM schedule not available',
          description: 'Parent-teacher meeting schedules is not available in the Parents App yet. Please contact the school office. Meeting notices from the school appear under Notices.',
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Parent-Teacher Meeting (PTM)', style: AppTextStyles.headingSmall),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // PTM Hero Card
            AnimatedCard(
              backgroundColor: AppColors.primary,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
                        child: const Icon(Icons.groups_rounded, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('TERM 1 PTM MEET', style: AppTextStyles.caption.copyWith(color: Colors.white70, fontWeight: FontWeight.bold)),
                            Text(child.name, style: AppTextStyles.headingSmall.copyWith(color: Colors.white)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: Colors.white24),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Meeting Date', style: AppTextStyles.caption.copyWith(color: Colors.white70)),
                          Text(DateFormatter.formatFull(ptm.meetingDate), style: AppTextStyles.headingSmall.copyWith(color: Colors.white, fontSize: 14)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // PTM Details Box
            AnimatedCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Meeting Particulars', style: AppTextStyles.headingSmall),
                  const SizedBox(height: 12),
                  StatRow(label: 'Class & Section:', value: ptm.className),
                  StatRow(label: 'Class Teacher:', value: ptm.classTeacher),
                  StatRow(label: 'Time Window:', value: ptm.timeWindow),
                  StatRow(label: 'Venue Location:', value: ptm.venue),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Instructions Box
            Text('Instructions for Parents', style: AppTextStyles.headingSmall),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.infoBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.brandBlue.withOpacity(0.3)),
              ),
              child: Text(ptm.instructions, style: AppTextStyles.bodyMedium),
            ),

            const SizedBox(height: 24),

            // Time Slot Booking Architecture Placeholder
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandIndigo,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.event_seat_rounded),
                label: Text(
                  ptm.bookedSlot != null ? 'Slot Booked: ${ptm.bookedSlot}' : 'Reserve PTM Time Slot',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                onPressed: () {
                  _showSlotBookingBottomSheet(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSlotBookingBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Reserve PTM Time Slot', style: AppTextStyles.headingMedium),
              const SizedBox(height: 8),
              Text(
                'Select a preferred 15-minute interaction slot with class teacher.',
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ['10:00 AM - 10:15 AM', '10:30 AM - 10:45 AM', '11:00 AM - 11:15 AM', '11:30 AM - 11:45 AM']
                    .map((slot) => ChoiceChip(
                          label: Text(slot),
                          selected: slot == '10:30 AM - 10:45 AM',
                          selectedColor: AppColors.brandIndigo,
                          labelStyle: const TextStyle(color: Colors.white),
                          onSelected: (_) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('PTM Slot reserved for $slot'),
                                backgroundColor: AppColors.success,
                              ),
                            );
                          },
                        ))
                    .toList(),
              ),
            ],
          ),
        );
      },
    );
  }
}

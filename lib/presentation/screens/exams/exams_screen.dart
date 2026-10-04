import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/exam_model.dart';
import '../../../providers/parent_app_provider.dart';
import '../../widgets/animated_card.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/status_badge.dart';

class ExamsScreen extends StatefulWidget {
  const ExamsScreen({super.key});

  @override
  State<ExamsScreen> createState() => _ExamsScreenState();
}

class _ExamsScreenState extends State<ExamsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
    final exams = provider.currentExamsList;

    final upcomingExams = exams.where((e) => e.isUpcoming).toList();
    final pastExams = exams.where((e) => !e.isUpcoming).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('${child.name}\'s Examinations', style: AppTextStyles.headingSmall),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.brandIndigo,
          unselectedLabelColor: AppColors.textMuted,
          indicatorColor: AppColors.brandIndigo,
          indicatorWeight: 3,
          tabs: [
            Tab(text: 'Upcoming (${upcomingExams.length})'),
            Tab(text: 'Past Exams (${pastExams.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildExamList(context, upcomingExams, 'No upcoming exams scheduled'),
          _buildExamList(context, pastExams, 'No past examination history'),
        ],
      ),
    );
  }

  Widget _buildExamList(BuildContext context, List<ExamModel> items, String emptyTitle) {
    if (items.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.event_note_outlined,
        title: emptyTitle,
        description: 'Exam schedules published by school administration will appear here.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final exam = items[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: AnimatedCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.infoBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        exam.subject,
                        style: AppTextStyles.caption.copyWith(color: AppColors.brandBlue, fontWeight: FontWeight.bold),
                      ),
                    ),
                    StatusBadge(
                      label: exam.status.toUpperCase(),
                      type: exam.isUpcoming ? StatusType.warning : StatusType.success,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(exam.title, style: AppTextStyles.headingSmall.copyWith(fontSize: 16)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.event_available_rounded, size: 16, color: AppColors.brandIndigo),
                    const SizedBox(width: 6),
                    Text(DateFormatter.formatFull(exam.examDate), style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.schedule_rounded, size: 14, color: AppColors.textMuted),
                    const SizedBox(width: 6),
                    Text('${exam.timeSlot} • ${exam.roomNo}', style: AppTextStyles.bodySmall),
                    const Spacer(),
                    Text('Max: ${exam.totalMarks.toInt()} Marks', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

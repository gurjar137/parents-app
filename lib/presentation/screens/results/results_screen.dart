import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../providers/parent_app_provider.dart';
import '../../widgets/animated_card.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/status_badge.dart';
import 'report_card_screen.dart';

class ResultsScreen extends StatefulWidget {
  const ResultsScreen({super.key});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  int _selectedExamIndex = 0;
  String _selectedSession = '2026-2027';

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ParentAppProvider>(context);
    final child = provider.selectedChild;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (!provider.isChildLinked) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Academic Results', style: AppTextStyles.headingSmall),
          elevation: 0,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.grade_outlined, size: 64, color: AppColors.textMuted),
                const SizedBox(height: 16),
                Text('No Child Linked', style: AppTextStyles.headingSmall),
                const SizedBox(height: 8),
                Text(
                  'Please link a student profile to view examination results.',
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (provider.isResultsLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Academic Results • ${child.name}', style: AppTextStyles.headingSmall),
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: AppColors.brandIndigo),
              const SizedBox(height: 16),
              Text(
                'Loading exam results for ${child.name}...',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      );
    }

    if (provider.resultsError != null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Academic Results • ${child.name}', style: AppTextStyles.headingSmall),
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
                  'Unable to load examination results. Please try again.',
                  style: AppTextStyles.headingSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  provider.resultsError!,
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => provider.loadResultsForSelectedChild(),
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

    final allResults = provider.currentResultsList;
    final results = allResults.where((r) => r.isPublished).toList();

    if (results.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text('Academic Results • ${child.name}', style: AppTextStyles.headingSmall)),
        body: EmptyStateWidget(
          icon: Icons.grade_outlined,
          title: 'No published results yet',
          description: 'Exam results for ${child.name} will be displayed here once officially published by the school board.',
        ),
      );
    }

    final currentExam = results[_selectedExamIndex.clamp(0, results.length - 1)];

    return Scaffold(
      appBar: AppBar(
        title: Text('Academic Results • ${child.name}', style: AppTextStyles.headingSmall),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Student Overview Banner Card
            AnimatedCard(
              backgroundColor: AppColors.primary,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundImage: NetworkImage(child.avatarUrl),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(child.name, style: AppTextStyles.headingSmall.copyWith(color: Colors.white, fontSize: 16)),
                          Text('Class ${child.className} • Session $_selectedSession', style: AppTextStyles.bodySmall.copyWith(color: Colors.white70)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.brandIndigo,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Grade ${currentExam.overallGrade}',
                        style: AppTextStyles.headingSmall.copyWith(color: Colors.white, fontSize: 15),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Academic Session & Exam Selector Bar
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Academic Session', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSubSurface : AppColors.subSurface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedSession,
                            isExpanded: true,
                            style: AppTextStyles.bodyMedium,
                            items: const [
                              DropdownMenuItem(value: '2026-2027', child: Text('Session 2026-2027')),
                              DropdownMenuItem(value: '2025-2026', child: Text('Session 2025-2026')),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedSession = val);
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Exam Chips Selector
            Text('Select Examination', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(results.length, (index) {
                  final exam = results[index];
                  final isSelected = index == _selectedExamIndex;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      selected: isSelected,
                      label: Text(exam.examName),
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppColors.textPrimary,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      selectedColor: AppColors.brandIndigo,
                      backgroundColor: isDark ? AppColors.darkSubSurface : AppColors.subSurface,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      onSelected: (selected) {
                        setState(() {
                          _selectedExamIndex = index;
                        });
                      },
                    ),
                  );
                }),
              ),
            ),

            const SizedBox(height: 20),

            // Summary Score Overview Card
            AnimatedCard(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildSummaryStat('Total Obtained', '${currentExam.totalObtained.toInt()} / ${currentExam.totalMax.toInt()}'),
                        Container(height: 30, width: 1, color: AppColors.border),
                        _buildSummaryStat('Percentage', '${currentExam.overallPercentage.toStringAsFixed(1)}%'),
                        Container(height: 30, width: 1, color: AppColors.border),
                        _buildSummaryStat('Status', currentExam.resultStatus),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Subject-wise Marks Table Card
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Subject Marks Breakdown', style: AppTextStyles.headingSmall),
                TextButton.icon(
                  icon: const Icon(Icons.description_outlined, size: 16),
                  label: const Text('Report Card'),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ReportCardScreen(examResult: currentExam),
                      ),
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 10),

            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: currentExam.subjects.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final sub = currentExam.subjects[index];
                return AnimatedCard(
                  child: Padding(
                    padding: const EdgeInsets.all(14.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(sub.subject, style: AppTextStyles.headingSmall.copyWith(fontSize: 15)),
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: sub.percentage / 100,
                                  minHeight: 6,
                                  backgroundColor: isDark ? AppColors.darkSubSurface : AppColors.subSurface,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    sub.percentage >= 80 ? AppColors.success : AppColors.brandBlue,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${sub.obtainedMarks.toInt()} / ${sub.maxMarks.toInt()}',
                              style: AppTextStyles.headingSmall.copyWith(fontSize: 14),
                            ),
                            const SizedBox(height: 2),
                            StatusBadge(
                              label: 'Grade ${sub.grade}',
                              type: sub.grade.startsWith('A') ? StatusType.success : StatusType.info,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryStat(String label, String value) {
    return Column(
      children: [
        Text(value, style: AppTextStyles.headingSmall.copyWith(fontSize: 15, color: AppColors.brandBlue)),
        const SizedBox(height: 2),
        Text(label, style: AppTextStyles.caption),
      ],
    );
  }
}

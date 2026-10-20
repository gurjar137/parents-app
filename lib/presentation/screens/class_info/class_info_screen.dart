import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../providers/parent_app_provider.dart';
import '../../widgets/animated_card.dart';
import '../../widgets/stat_row.dart';

class ClassInfoScreen extends StatelessWidget {
  const ClassInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ParentAppProvider>(context);
    final child = provider.selectedChild;

    final subjects = child.className.startsWith('8')
        ? ['Mathematics', 'Physics & Chemistry', 'Biology', 'English Literature', 'Social Science', 'Computer Science', 'Hindi']
        : ['Mathematics', 'Environmental Studies', 'English', 'Hindi', 'Art & Craft', 'Computer Basics'];

    return Scaffold(
      appBar: AppBar(
        title: Text('Class ${child.className} Information', style: AppTextStyles.headingSmall),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Class Overview Card
            AnimatedCard(
              backgroundColor: AppColors.primary,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
                    child: const Icon(Icons.school_rounded, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Class ${child.className}', style: AppTextStyles.headingSmall.copyWith(color: Colors.white, fontSize: 20)),
                        if (child.classTeacher.isNotEmpty)
                          Text('Class Teacher: ${child.classTeacher}', style: AppTextStyles.bodySmall.copyWith(color: Colors.white70)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Particulars Card
            AnimatedCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Class Credentials', style: AppTextStyles.headingSmall),
                  const SizedBox(height: 12),
                  StatRow(label: 'Grade Level:', value: child.grade),
                  StatRow(label: 'Section:', value: child.section),
                  if (child.rollNo > 0) StatRow(label: 'Roll Number:', value: '${child.rollNo}'),
                  if (child.classmateCount > 0) StatRow(label: 'Class Strength:', value: '${child.classmateCount} Students'),
                  if (child.houseName.isNotEmpty) StatRow(label: 'House Assignment:', value: child.houseName),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Subject Curriculum List
            Text('Subjects & Curriculum', style: AppTextStyles.headingSmall),
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: subjects.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final sub = subjects[index];
                return AnimatedCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      const Icon(Icons.book_outlined, color: AppColors.brandIndigo, size: 20),
                      const SizedBox(width: 12),
                      Text(sub, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

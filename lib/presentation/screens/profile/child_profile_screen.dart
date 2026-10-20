import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/student_model.dart';
import '../../../providers/parent_app_provider.dart';
import '../../widgets/animated_card.dart';
import '../../widgets/correction_request_dialog.dart';
import '../../widgets/stat_row.dart';
import '../timetable/timetable_screen.dart';
import '../notices/notices_screen.dart';
import '../fees/fees_screen.dart';

class ChildProfileScreen extends StatelessWidget {
  final StudentModel student;

  const ChildProfileScreen({super.key, required this.student});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ParentAppProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('${student.name}\'s Dossier', style: AppTextStyles.headingSmall),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Student Hero Card
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 44,
                    backgroundColor: AppColors.brandIndigo,
                    backgroundImage: student.avatarUrl.startsWith('http') ? NetworkImage(student.avatarUrl) : null,
                    child: student.avatarUrl.startsWith('http')
                        ? null
                        : Text(student.name.isNotEmpty ? student.name[0].toUpperCase() : '?',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 12),
                  Text(student.name, style: AppTextStyles.headingLarge),
                  const SizedBox(height: 4),
                  Text(
                    provider.branding.schoolName,
                    style: AppTextStyles.caption.copyWith(color: AppColors.brandIndigo, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [student.className, if (student.rollNo > 0) 'Roll No. ${student.rollNo}'].where((p) => p.isNotEmpty).join(' • '),
                    style: AppTextStyles.bodyMedium,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Academic Particulars Card
            AnimatedCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Academic Details', style: AppTextStyles.headingSmall),
                      TextButton.icon(
                        icon: const Icon(Icons.edit_note_rounded, size: 16),
                        label: const Text('Request Correction'),
                        onPressed: () {
                          CorrectionRequestDialog.show(context, student.name);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  StatRow(label: 'School:', value: provider.branding.schoolName),
                  StatRow(label: 'Admission Number:', value: student.admissionNo),
                  if (student.admissionNo.isNotEmpty) StatRow(label: 'Admission No:', value: student.admissionNo),
                  if (student.relationship.isNotEmpty) StatRow(label: 'Your relationship:', value: student.relationship),
                  if (student.dateOfBirth != null)
                    StatRow(label: 'Date of Birth:', value: '${student.dateOfBirth!.day}/${student.dateOfBirth!.month}/${student.dateOfBirth!.year}'),
                  if (student.motherName != null && student.motherName!.trim().isNotEmpty)
                    StatRow(label: "Mother's Name:", value: student.motherName!.trim()),
                  if (student.academicYear.isNotEmpty) StatRow(label: 'Academic Session:', value: student.academicYear),
                  if (student.classTeacher.isNotEmpty) StatRow(label: 'Class Teacher:', value: student.classTeacher),
                  if (student.houseName.isNotEmpty) StatRow(label: 'House Name:', value: student.houseName),
                  if (student.classmateCount > 0) StatRow(label: 'Class Strength:', value: '${student.classmateCount} Students'),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Quick Modules Jump Grid
            Text('Quick Module Access', style: AppTextStyles.headingSmall),
            const SizedBox(height: 12),

            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2.2,
              children: [
                _buildQuickTile(
                  icon: Icons.calendar_today_rounded,
                  label: 'Attendance',
                  color: AppColors.success,
                  onTap: () {
                    provider.selectChild(student);
                    provider.setBottomNavIndex(1); // Academics tab
                    Navigator.pop(context);
                  },
                ),
                _buildQuickTile(
                  icon: Icons.assignment_outlined,
                  label: 'Homework',
                  color: AppColors.warning,
                  onTap: () {
                    provider.selectChild(student);
                    provider.setBottomNavIndex(2); // Homework tab
                    Navigator.pop(context);
                  },
                ),
                _buildQuickTile(
                  icon: Icons.account_balance_wallet_rounded,
                  label: 'Fees',
                  color: AppColors.brandBlue,
                  onTap: () {
                    provider.selectChild(student);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const FeesScreen()));
                  },
                ),
                _buildQuickTile(
                  icon: Icons.grade_outlined,
                  label: 'Results',
                  color: AppColors.holiday,
                  onTap: () {
                    provider.selectChild(student);
                    provider.setBottomNavIndex(3); // Results tab
                    Navigator.pop(context);
                  },
                ),
                _buildQuickTile(
                  icon: Icons.table_chart_outlined,
                  label: 'Timetable',
                  color: const Color(0xFF06B6D4),
                  onTap: () {
                    provider.selectChild(student);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const TimetableScreen()));
                  },
                ),
                _buildQuickTile(
                  icon: Icons.campaign_outlined,
                  label: 'Notices',
                  color: AppColors.danger,
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const NoticesScreen()));
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickTile({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return AnimatedCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Text(label, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}

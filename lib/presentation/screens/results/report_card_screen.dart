import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/result_model.dart';
import '../../../providers/parent_app_provider.dart';
import '../../widgets/pdf_preview_modal.dart';
import '../../widgets/stat_row.dart';

class ReportCardScreen extends StatelessWidget {
  final ExamResultModel examResult;

  const ReportCardScreen({super.key, required this.examResult});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ParentAppProvider>(context);
    final child = provider.selectedChild;

    if (!provider.isChildLinked) {
      return Scaffold(
        appBar: AppBar(
          title: Text('${examResult.examName} Report Card', style: AppTextStyles.headingSmall),
        ),
        body: Center(
          child: Text('No student selected.', style: AppTextStyles.bodyMedium),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('${examResult.examName} Report Card', style: AppTextStyles.headingSmall),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.brandBlue),
            onPressed: () {
              PdfPreviewModal.show(
                context: context,
                title: 'Marks summary (preview)',
                documentName: 'ReportCard_${child.name}_${examResult.examName}.pdf',
                contentWidget: _buildReportCardPaper(
                  studentName: child.name,
                  className: child.className,
                  rollNo: child.rollNo,
                  admissionNo: child.admissionNo,
                  schoolName: provider.branding.schoolName,
                  schoolAddress: provider.branding.address,
                  fatherName: child.displayFatherName,
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
                boxShadow: const [BoxShadow(color: AppColors.shadow, blurRadius: 10)],
              ),
              child: _buildReportCardPaper(
                studentName: child.name,
                className: child.className,
                rollNo: child.rollNo,
                admissionNo: child.admissionNo,
                schoolName: provider.branding.schoolName,
                schoolAddress: provider.branding.address,
                fatherName: child.displayFatherName,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'This is a summary of the published marks. The official report card is issued by the school.',
              style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportCardPaper({
    required String studentName,
    required String className,
    required int rollNo,
    required String admissionNo,
    required String schoolName,
    required String schoolAddress,
    required String fatherName,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // School Header
        Center(
          child: Column(
            children: [
              Text(schoolName, style: AppTextStyles.headingSmall.copyWith(fontSize: 18), textAlign: TextAlign.center),
              if (schoolAddress.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(schoolAddress, style: AppTextStyles.caption, textAlign: TextAlign.center),
              ],
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.infoBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'PUBLISHED MARKS SUMMARY',
                  style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold, color: AppColors.brandBlue),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 10),

        // Student Info Block
        Text('Student Credentials', style: AppTextStyles.headingSmall.copyWith(fontSize: 14)),
        const SizedBox(height: 6),
        StatRow(label: 'Student Name:', value: studentName),
        if (fatherName.isNotEmpty && fatherName != 'Not provided')
          StatRow(label: "Father's Name:", value: fatherName),
        StatRow(label: 'Class & Section:', value: className),
        if (rollNo > 0) StatRow(label: 'Roll Number:', value: '$rollNo'),
        if (admissionNo.isNotEmpty) StatRow(label: 'Admission No:', value: admissionNo),
        StatRow(label: 'Exam Name:', value: examResult.examName),

        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 10),

        // Subject Wise Marks
        Text('Scholastic Marks Evaluation', style: AppTextStyles.headingSmall.copyWith(fontSize: 14)),
        const SizedBox(height: 10),
        Table(
          border: TableBorder.all(color: AppColors.border, width: 1),
          columnWidths: const {
            0: FlexColumnWidth(2.5),
            1: FlexColumnWidth(1),
            2: FlexColumnWidth(1),
            3: FlexColumnWidth(1),
          },
          children: [
            TableRow(
              decoration: const BoxDecoration(color: AppColors.subSurface),
              children: [
                _buildTableCell('Subject', isHeader: true),
                _buildTableCell('Max', isHeader: true),
                _buildTableCell('Obtained', isHeader: true),
                _buildTableCell('Pass', isHeader: true),
              ],
            ),
            ...examResult.subjects.map(
              (sub) => TableRow(
                children: [
                  _buildTableCell(sub.subject),
                  _buildTableCell(_fmt(sub.maxMarks)),
                  _buildTableCell(sub.obtainedMarks == null ? (sub.status.isNotEmpty ? sub.status : '—') : _fmt(sub.obtainedMarks!)),
                  _buildTableCell(sub.passingMarks == null ? '—' : _fmt(sub.passingMarks!)),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Total Summary Box
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.subSurface,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Flexible(child: StatRow(label: 'Total:', value: '${_fmt(examResult.totalObtained)} / ${_fmt(examResult.totalMax)}')),
              Flexible(child: StatRow(label: 'Overall:', value: '${examResult.overallPercentage.toStringAsFixed(1)}%')),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Subject remarks recorded by teachers (if any)
        ...examResult.subjects.where((sub) => sub.teacherComment != null).map((sub) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text('${sub.subject}: ${sub.teacherComment}', style: AppTextStyles.bodySmall),
            )),
      ],
    );
  }

  static String _fmt(double v) => v % 1 == 0 ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

  Widget _buildTableCell(String text, {bool isHeader = false}) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Text(
        text,
        style: isHeader
            ? AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold, color: AppColors.textPrimary)
            : AppTextStyles.bodySmall,
        textAlign: isHeader ? TextAlign.center : TextAlign.left,
      ),
    );
  }
}

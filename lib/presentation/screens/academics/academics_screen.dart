import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../attendance/attendance_screen.dart';
import '../homework/homework_screen.dart';
import '../exams/exams_screen.dart';
import '../results/results_screen.dart';
import '../timetable/timetable_screen.dart';

class AcademicsScreen extends StatefulWidget {
  final int initialSubTabIndex;

  const AcademicsScreen({super.key, this.initialSubTabIndex = 0});

  @override
  State<AcademicsScreen> createState() => _AcademicsScreenState();
}

class _AcademicsScreenState extends State<AcademicsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 5,
      vsync: this,
      initialIndex: widget.initialSubTabIndex.clamp(0, 4),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Academics', style: AppTextStyles.headingSmall),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppColors.brandIndigo,
          unselectedLabelColor: AppColors.textMuted,
          indicatorColor: AppColors.brandIndigo,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Attendance'),
            Tab(text: 'Homework'),
            Tab(text: 'Exams'),
            Tab(text: 'Results'),
            Tab(text: 'Timetable'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          AttendanceScreen(),
          HomeworkScreen(),
          ExamsScreen(),
          ResultsScreen(),
          TimetableScreen(),
        ],
      ),
    );
  }
}

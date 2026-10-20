import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/parent_app_provider.dart';
import 'widgets/custom_app_bar.dart';
import 'widgets/custom_bottom_nav_bar.dart';
import 'screens/home/home_screen.dart';
import 'screens/attendance/attendance_screen.dart';
import 'screens/homework/homework_screen.dart';
import 'screens/results/results_screen.dart';
import 'screens/more/more_screen.dart';

class MainNavigationScreen extends StatelessWidget {
  const MainNavigationScreen({super.key});

  final List<Widget> _pages = const [
    HomeScreen(),
    AttendanceScreen(),
    HomeworkScreen(),
    ResultsScreen(),
    MoreScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ParentAppProvider>(context);
    final selectedIndex = provider.selectedBottomNavIndex;
    final pendingHwCount = provider.currentHomeworkList.where((h) => !h.isCompleted).length;

    return Scaffold(
      appBar: selectedIndex == 0 ? const CustomAppBar() : null,
      body: IndexedStack(
        index: selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: selectedIndex,
        onTabSelected: (index) => provider.setBottomNavIndex(index),
        pendingHomeworkCount: pendingHwCount,
      ),
    );
  }
}

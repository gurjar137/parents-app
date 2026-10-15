import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../providers/parent_app_provider.dart';
import 'widgets/custom_app_bar.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pendingHwCount = provider.currentHomeworkList.where((h) => !h.isCompleted).length;

    return Scaffold(
      appBar: selectedIndex == 0 ? const CustomAppBar() : null,
      body: IndexedStack(
        index: selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.surface,
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadowStrong,
              blurRadius: 16,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: selectedIndex,
          onTap: (index) => provider.setBottomNavIndex(index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: isDark ? AppColors.darkSurface : AppColors.surface,
          selectedItemColor: isDark ? AppColors.brandBlue : AppColors.brandIndigo,
          unselectedItemColor: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today_outlined),
              activeIcon: Icon(Icons.calendar_today_rounded),
              label: 'Attendance',
            ),
            BottomNavigationBarItem(
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.assignment_outlined),
                  if (pendingHwCount > 0)
                    Positioned(
                      top: -2,
                      right: -6,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: AppColors.warning,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                        child: Text(
                          '$pendingHwCount',
                          style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              activeIcon: const Icon(Icons.assignment_rounded),
              label: 'Homework',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.school_outlined),
              activeIcon: Icon(Icons.school_rounded),
              label: 'Results',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.grid_view_outlined),
              activeIcon: Icon(Icons.grid_view_rounded),
              label: 'More',
            ),
          ],
        ),
      ),
    );
  }
}

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parent_app/core/services/auth_service.dart';

import 'support/fake_parent_api.dart';
import 'package:parent_app/core/services/supabase_service.dart';
import 'package:parent_app/core/theme/app_colors.dart';
import 'package:parent_app/data/models/attendance_model.dart';
import 'package:parent_app/data/models/fee_model.dart';
import 'package:parent_app/data/models/homework_model.dart';
import 'package:parent_app/data/models/school_brand_model.dart';
import 'package:parent_app/data/models/student_model.dart';
import 'package:parent_app/data/models/timetable_model.dart';
import 'package:parent_app/presentation/widgets/child_profile_hero_card.dart';
import 'package:parent_app/presentation/widgets/custom_bottom_nav_bar.dart';
import 'package:parent_app/presentation/widgets/quick_access_grid.dart';
import 'package:parent_app/presentation/widgets/todays_academic_overview.dart';
import 'package:parent_app/presentation/screens/home/home_screen.dart';
import 'package:parent_app/providers/parent_app_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TestHttpOverrides extends HttpOverrides {}

void main() {
  HttpOverrides.global = TestHttpOverrides();

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await SupabaseService.initialize();
  });

  const testStudentLong = StudentModel(
    id: 'stu-long-1',
    schoolId: 'sch-long-1',
    admissionNo: 'ADM-2026-998877',
    name: 'Alexander Chandrasekharan Junior',
    className: '12-A-International',
    grade: 'Senior Secondary Grade 12',
    section: 'A-International',
    rollNo: 1048,
    avatarUrl: '',
    academicYear: '2026-2027',
    houseName: 'Blue House',
    classTeacher: 'Dr. Srinivasan',
    classmateCount: 35,
    fatherName: 'Dr. Rameshwaram Chandrasekharan',
    motherName: 'Prof. Meenakshi Chandrasekharan',
  );

  const testBrandingLong = SchoolBrandModel(
    schoolName: 'St. Augustine International Academy of Excellence',
    logoUrl: '',
    primaryColor: AppColors.primary,
    secondaryColor: AppColors.brandIndigo,
    affiliation: 'CBSE Affiliated',
    motto: 'Excellence in Education & Character',
    address: '108 Greenfield Boulevard, Education Enclave',
    phone: '+91 98765 43210',
    email: 'admin@staugustine.edu',
  );

  final viewports = [
    const Size(320, 600), // Ultra-compact screen
    const Size(360, 640), // Standard compact Android
    const Size(412, 915), // Modern Android / Pixel
    const Size(800, 1000), // Tablet / Desktop
  ];

  group('1. ChildProfileHeroCard Zero-Overflow Responsive Tests', () {
    for (final size in viewports) {
      testWidgets('Renders cleanly at ${size.width}x${size.height} without RenderFlex overflow', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: Padding(
                padding: EdgeInsets.all(16.0),
                child: ChildProfileHeroCard(
                  child: testStudentLong,
                  branding: testBrandingLong,
                  totalChildrenCount: 2,
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull, reason: 'ChildProfileHeroCard overflowed at width ${size.width}');
        expect(find.textContaining('Alexander'), findsOneWidget);
        expect(find.textContaining('ADM-2026-998877'), findsOneWidget);
        expect(find.textContaining('Dr. Rameshwaram Chandrasekharan'), findsOneWidget);
      });
    }
  });

  group('2. QuickAccessGrid Responsive & Multiline Label Tests', () {
    final actions = [
      QuickActionItemData(
        icon: Icons.calendar_today_rounded,
        label: 'Attendance',
        iconColor: AppColors.success,
        bgColor: AppColors.successBg,
        onTap: () {},
      ),
      QuickActionItemData(
        icon: Icons.assignment_outlined,
        label: 'Homework',
        iconColor: AppColors.warning,
        bgColor: AppColors.warningBg,
        onTap: () {},
        badgeText: '3',
      ),
      QuickActionItemData(
        icon: Icons.school_outlined,
        label: 'Results',
        iconColor: AppColors.accent,
        bgColor: AppColors.accentBg,
        onTap: () {},
      ),
      QuickActionItemData(
        icon: Icons.account_balance_wallet_rounded,
        label: 'Fees',
        iconColor: AppColors.brandBlue,
        bgColor: AppColors.infoBg,
        onTap: () {},
        badgeText: 'DUE',
      ),
      QuickActionItemData(
        icon: Icons.schedule_rounded,
        label: 'Timetable',
        iconColor: AppColors.cyan,
        bgColor: AppColors.cyanBg,
        onTap: () {},
      ),
      QuickActionItemData(
        icon: Icons.campaign_rounded,
        label: 'Notices',
        iconColor: AppColors.warning,
        bgColor: AppColors.warningBg,
        onTap: () {},
      ),
      QuickActionItemData(
        icon: Icons.chat_bubble_outline_rounded,
        label: 'Messages',
        iconColor: AppColors.brandIndigo,
        bgColor: AppColors.primaryBg,
        onTap: () {},
      ),
      QuickActionItemData(
        icon: Icons.directions_bus_rounded,
        label: 'Bus',
        iconColor: AppColors.teal,
        bgColor: AppColors.tealBg,
        onTap: () {},
      ),
    ];

    for (final size in viewports) {
      testWidgets('Renders all 8 actions cleanly at ${size.width}x${size.height} without label clipping or overflow', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Padding(
                padding: const EdgeInsets.all(16.0),
                child: QuickAccessGrid(actions: actions),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull, reason: 'QuickAccessGrid overflowed at width ${size.width}');
        expect(find.text('Attendance'), findsOneWidget);
        expect(find.text('Homework'), findsOneWidget);
        expect(find.text('Timetable'), findsOneWidget);
        expect(find.text('Messages'), findsOneWidget);
      });
    }
  });

  group('3. TodaysAcademicOverview 2x2 Modular Metric Tests', () {
    const attendanceSummary = MonthlyAttendanceSummary(
      monthYear: 'October 2026',
      totalWorkingDays: 24,
      presentDays: 22,
      absentDays: 2,
      lateDays: 0,
      holidayDays: 4,
      percentage: 91.67,
      dailyRecords: [],
    );

    const feeSummary = FeeSummaryModel(
      studentId: 'stu-long-1',
      schoolId: 'sch-long-1',
      grossFee: 50000,
      discountAmount: 5000,
      waiverAmount: 0,
      netFee: 45000,
      paidAmount: 25000,
      outstandingAmount: 20000,
      status: 'due',
      payments: [],
      hasFeeAccount: true,
    );

    final homeworkList = <HomeworkModel>[
      HomeworkModel(
        id: 'hw-1',
        studentId: 'stu-long-1',
        schoolId: 'sch-long-1',
        title: 'Wave Optics Numerical Problems 1-15',
        subject: 'Physics',
        assignedDate: DateTime.now().subtract(const Duration(days: 1)),
        dueDate: DateTime.now().add(const Duration(days: 1)),
        description: 'Complete all numerical questions from Chapter 10',
        teacherName: 'Dr. Srinivasan',
        isCompleted: false,
      ),
    ];

    const timetableEntry = TimetableEntryModel(
      id: 'tt-1',
      schoolId: 'sch-long-1',
      dayOfWeek: 'Thursday',
      periodNumber: 3,
      startTime: '10:30 AM',
      endTime: '11:15 AM',
      subject: 'Advanced Mathematics',
      room: 'Room 304',
      teacherName: 'Dr. Ramanujan',
    );

    for (final size in viewports.take(3)) {
      testWidgets('Renders cleanly at ${size.width}x${size.height} without RenderFlex overflow', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Padding(
                padding: const EdgeInsets.all(16.0),
                child: TodaysAcademicOverview(
                  attendance: attendanceSummary,
                  feeSummary: feeSummary,
                  homeworkList: homeworkList,
                  nextClass: timetableEntry,
                  onAttendanceTap: () {},
                  onFeesTap: () {},
                  onHomeworkTap: () {},
                  onTimetableTap: () {},
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        final exc = tester.takeException();
        if (exc != null) {
          debugPrint('>>> TODAYS ACADEMIC OVERVIEW EXCEPTION: $exc');
        }
        expect(exc, isNull, reason: 'TodaysAcademicOverview overflowed at width ${size.width}');
        expect(find.text('Attendance'), findsOneWidget);
        expect(find.text('Fee Ledger'), findsOneWidget);
        expect(find.text('Homework'), findsOneWidget);
        expect(find.text('Schedule'), findsOneWidget);
      });
    }
  });

  group('4. CustomBottomNavBar Floating Pill & Badge Tests', () {
    for (final size in viewports.take(3)) {
      testWidgets('Renders all navigation items without overflow at ${size.width}x${size.height}', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        int tappedIndex = -1;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              bottomNavigationBar: CustomBottomNavBar(
                selectedIndex: 0,
                onTabSelected: (i) => tappedIndex = i,
                pendingHomeworkCount: 4,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Home'), findsOneWidget);
        expect(find.text('Attendance'), findsOneWidget);
        expect(find.text('Homework'), findsOneWidget);
        expect(find.text('More'), findsOneWidget);

        // Tap attendance tab
        await tester.tap(find.text('Attendance'));
        await tester.pumpAndSettle();
        expect(tappedIndex, equals(1));
      });
    }
  });

  group('5. Full HomeScreen Live Provider Layout & Zero Overflow Tests', () {
    testWidgets('Full HomeScreen renders with zero overflow on 320px viewport', (tester) async {
      tester.view.physicalSize = const Size(320, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final rpc = FakeRpc()..install();
      installEmptyChildData(rpc);
      final provider = ParentAppProvider(autoStart: false)
        ..debugSetSession(ParentSession.fromJson(sessionJson()).parent, [testStudentLong]);
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));

      await tester.pumpWidget(
        ChangeNotifierProvider<ParentAppProvider>.value(
          value: provider,
          child: const MaterialApp(
            home: Scaffold(
              body: HomeScreen(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull, reason: 'HomeScreen threw overflow exception on 320px width');
      expect(find.text('Quick Access'), findsOneWidget);
      expect(find.text("Today's Overview"), findsOneWidget);
    });

    testWidgets('Full HomeScreen renders with zero overflow on 412px viewport', (tester) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final rpc = FakeRpc()..install();
      installEmptyChildData(rpc);
      final provider = ParentAppProvider(autoStart: false)
        ..debugSetSession(ParentSession.fromJson(sessionJson()).parent, [testStudentLong]);
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));

      await tester.pumpWidget(
        ChangeNotifierProvider<ParentAppProvider>.value(
          value: provider,
          child: const MaterialApp(
            home: Scaffold(
              body: HomeScreen(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull, reason: 'HomeScreen threw overflow exception on 412px width');
      expect(find.text('Quick Access'), findsOneWidget);
      expect(find.text("Today's Overview"), findsOneWidget);
    });
  });
}

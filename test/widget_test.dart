import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:parent_app/core/config/supabase_config.dart';
import 'package:parent_app/core/services/auth_service.dart';
import 'package:parent_app/core/services/fee_service.dart';
import 'package:parent_app/core/services/homework_service.dart';
import 'package:parent_app/core/services/notice_service.dart';
import 'package:parent_app/core/services/notification_service.dart';
import 'package:parent_app/core/services/result_service.dart';
import 'package:parent_app/core/services/timetable_service.dart';
import 'package:parent_app/core/services/supabase_service.dart';
import 'package:parent_app/data/models/attendance_model.dart';
import 'package:parent_app/providers/parent_app_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TestHttpOverrides extends HttpOverrides {}

void main() {
  HttpOverrides.global = TestHttpOverrides();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('Supabase configuration and safe initialization test', () async {
    expect(SupabaseConfig.url, isNotEmpty);
    expect(SupabaseConfig.anonKey, isNotEmpty);
    expect(SupabaseConfig.isConfigured, isTrue);
    expect(SupabaseConfig.projectRef, 'hnvjenkeimzkdgkuwbeb');
    expect(SupabaseService.isConfigured, isTrue);
  });

  test('Live Attendance calculation & percentage rules tests', () {
    final records = [
      DailyAttendance(date: DateTime(2026, 9, 1), status: AttendanceStatus.present),
      DailyAttendance(date: DateTime(2026, 9, 2), status: AttendanceStatus.present),
      DailyAttendance(date: DateTime(2026, 9, 3), status: AttendanceStatus.absent),
      DailyAttendance(date: DateTime(2026, 9, 4), status: AttendanceStatus.late),
      DailyAttendance(date: DateTime(2026, 9, 5), status: AttendanceStatus.holiday),
    ];

    final summary = MonthlyAttendanceSummary.fromDailyRecords(
      monthYear: 'September 2026',
      records: records,
    );

    expect(summary.presentDays, 2);
    expect(summary.absentDays, 1);
    expect(summary.lateDays, 1);
    expect(summary.holidayDays, 1);
    expect(summary.totalWorkingDays, 4);
    expect(summary.percentage, 75.0);
  });

  test('Live Core Services & Profile Update tests', () async {
    final homeworkList = await HomeworkService.fetchHomeworkForStudent(
      studentId: 'S-8017',
      className: '8-A',
      schoolId: 'SCH-STX-2026',
    );
    expect(homeworkList, isNotNull);

    final timetableEntries = await TimetableService.fetchTimetableForStudent(
      schoolId: 'SCH-STX-2026',
      className: '8-A',
      section: 'A',
      studentId: 'S-8017',
    );
    expect(timetableEntries, isNotNull);

    final resultsList = await ResultService.fetchResultsForStudent(
      studentId: 'S-8017',
      schoolId: 'SCH-STX-2026',
    );
    expect(resultsList, isNotNull);

    final feeSummary = await FeeService.fetchFeeSummaryForStudent(
      studentId: 'S-8017',
      schoolId: 'SCH-STX-2026',
    );
    expect(feeSummary, isNotNull);

    final noticeList = await NoticeService.fetchNoticesForParent(
      schoolId: 'SCH-STX-2026',
      className: '8-A',
      studentId: 'S-8017',
    );
    expect(noticeList, isNotNull);

    final notificationsList = await NotificationService.fetchNotificationsForParent(
      parentAuthId: 'P-101',
      schoolId: 'SCH-STX-2026',
      studentId: 'S-8017',
    );
    expect(notificationsList, isNotNull);
  });

  test('Clean Initial State & Unique Parent Code Validation Test', () async {
    final provider = ParentAppProvider();

    // 1. Clean Initial State
    expect(provider.children, isEmpty);
    expect(provider.isChildLinked, isFalse);
    expect(provider.selectedChild.id, isEmpty);
    expect(provider.currentFatherName, isEmpty);

    // 2. Invalid Parent Code Reject Check
    final invalidRes = await AuthService.signInWithParentCode('PRT-INVALID99');
    expect(invalidRes.status, AuthStatus.invalidCredentials);

    // 3. Inactive Parent Code Reject Check
    final inactiveRes = await AuthService.signInWithParentCode('PRT-INACTIVE');
    expect(inactiveRes.status, AuthStatus.inactiveAccount);
  });

  test('Parent Profile Update, Password Validation & Secure Logout State Test', () async {
    final provider = ParentAppProvider();

    // 1. Profile Update
    final updated = await provider.updateProfile(
      name: 'Rajesh Sharma Updated',
      phone: '+91 98765 00000',
      relationship: 'Father',
    );
    expect(updated, isTrue);
    expect(provider.parent.name, 'Rajesh Sharma Updated');
    expect(provider.parent.phone, '+91 98765 00000');

    // 2. Password Validation (Short password fails gracefully)
    final passResponse = await provider.updatePassword(
      newPassword: '123',
      confirmPassword: '123',
    );
    expect(passResponse.status, AuthStatus.weakPassword);

    // 3. Secure Logout & State Cleanup
    await provider.logout();
    expect(provider.isLoggedIn, isFalse);
    expect(provider.children, isEmpty);
    expect(provider.isChildLinked, isFalse);
  });
}

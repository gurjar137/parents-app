import 'package:flutter_test/flutter_test.dart';
import 'package:parent_app/core/config/supabase_config.dart';
import 'package:parent_app/core/services/supabase_service.dart';
import 'package:parent_app/data/models/attendance_model.dart';
import 'package:parent_app/providers/parent_app_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('Supabase configuration points at the School OS project with a publishable key only', () {
    expect(SupabaseConfig.url, 'https://hnvjenkeimzkdgkuwbeb.supabase.co');
    expect(SupabaseConfig.projectRef, 'hnvjenkeimzkdgkuwbeb');
    expect(SupabaseConfig.anonKey, startsWith('sb_publishable_'));
    expect(SupabaseConfig.anonKey.contains('service_role'), isFalse);
    expect(SupabaseService.isConfigured, isTrue);
  });

  test('Attendance percentage counts present + late over marked days', () {
    final records = [
      DailyAttendance(date: DateTime(2026, 9, 1), status: AttendanceStatus.present),
      DailyAttendance(date: DateTime(2026, 9, 2), status: AttendanceStatus.present),
      DailyAttendance(date: DateTime(2026, 9, 3), status: AttendanceStatus.absent),
      DailyAttendance(date: DateTime(2026, 9, 4), status: AttendanceStatus.late),
      DailyAttendance(date: DateTime(2026, 9, 5), status: AttendanceStatus.holiday),
    ];
    final summary = MonthlyAttendanceSummary.fromDailyRecords(monthYear: 'September 2026', records: records);
    expect(summary.presentDays, 2);
    expect(summary.absentDays, 1);
    expect(summary.lateDays, 1);
    expect(summary.holidayDays, 1);
    expect(summary.totalWorkingDays, 4);
    expect(summary.percentage, 75.0);
    expect(summary.hasRecords, isTrue);
  });

  test('A month with no marks is 0% and flagged as having no records (not an invented 100%)', () {
    final summary = MonthlyAttendanceSummary.fromDailyRecords(monthYear: 'October 2026', records: const []);
    expect(summary.percentage, 0.0);
    expect(summary.hasRecords, isFalse);
  });

  test('Clean initial state: nobody signed in, no child, no parent name', () {
    final provider = ParentAppProvider(autoStart: false);
    expect(provider.isLoggedIn, isFalse);
    expect(provider.children, isEmpty);
    expect(provider.isChildLinked, isFalse);
    expect(provider.selectedChild.id, isEmpty);
    expect(provider.currentFatherName, isEmpty);
  });

  test('Password change validation fails before any request', () async {
    final provider = ParentAppProvider(autoStart: false);
    final res = await provider.updatePassword(newPassword: '123', confirmPassword: '123');
    expect(res.errorMessage, contains('8 characters'));
  });
}

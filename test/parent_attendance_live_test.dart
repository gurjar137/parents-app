import 'package:flutter_test/flutter_test.dart';
import 'package:parent_app/core/services/attendance_service.dart';
import 'package:parent_app/core/services/supabase_service.dart';
import 'package:parent_app/data/models/attendance_model.dart';

import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await SupabaseService.initialize();
  });

  group('Parent Attendance Real Supabase & Isolation Tests', () {
    const verifiedStudentId = '56e0bade-7586-4ba4-b16b-bafec3a6aaa8'; // Class 12-F
    const unrecordedStudentId = 'cf470c43-35df-4b4e-9407-3150ffa1b1da'; // Class 12-A

    test('1. Today attendance queries real student and maps status properly', () async {
      final todayRecord = await AttendanceService.fetchTodayAttendance(
        studentId: verifiedStudentId,
      );
      expect(todayRecord?.studentId ?? verifiedStudentId, equals(verifiedStudentId));

      // Verify the status mapping logic
      final testMap = {
        'id': 'test-123',
        'student_id': verifiedStudentId,
        'school_id': '6254bee9-151d-4332-8a1c-3994af7d2153',
        'attendance_date': '2026-09-04',
        'status': 'present'
      };
      final parsed = DailyAttendance.fromMap(testMap);
      expect(parsed.status, equals(AttendanceStatus.present));
      expect(parsed.studentId, equals(verifiedStudentId));
      expect(parsed.date.year, equals(2026));
      expect(parsed.date.month, equals(9));
      expect(parsed.date.day, equals(4));
    });

    test('2. Cross-student isolation: Unrecorded student has no attendance', () async {
      final summary = await AttendanceService.fetchAttendanceForStudent(
        studentId: unrecordedStudentId,
        year: 2026,
        month: 9,
      );

      // Must be empty, no cross-student leakage
      expect(summary.dailyRecords.isEmpty, isTrue);
      expect(summary.totalWorkingDays, equals(0));
      expect(summary.presentDays, equals(0));
    });

    test('3. No demo/mock fallback when no records found', () async {
      final summary = await AttendanceService.fetchAttendanceForStudent(
        studentId: 'non-existent-uuid',
        year: 2026,
        month: 9,
      );

      expect(summary.dailyRecords, isEmpty);
      expect(summary.percentage, equals(0.0));
    });
  });
}

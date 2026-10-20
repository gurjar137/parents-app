// Formerly a live-network test that expected an empty month whenever a query
// failed. Attendance now comes from get_student_attendance_for_parent (06),
// which needs a signed-in linked parent; these tests use the fake gateway.
import 'package:flutter_test/flutter_test.dart';
import 'package:parent_app/core/services/attendance_service.dart';
import 'package:parent_app/core/services/parent_api.dart';
import 'package:parent_app/data/models/attendance_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'support/fake_parent_api.dart';

void main() {
  late FakeRpc rpc;
  setUp(() => rpc = FakeRpc()..install());

  test('month request sends the student id and the exact month range', () async {
    rpc.on('get_student_attendance_for_parent', (_) => [
          {'id': 'a1', 'student_id': 'st-1', 'attendance_date': '2026-02-03', 'status': 'present'},
          {'id': 'a2', 'student_id': 'st-1', 'attendance_date': '2026-02-04', 'status': 'ABSENT'},
        ]);
    final s = await AttendanceService.fetchAttendanceForStudent(studentId: 'st-1', year: 2026, month: 2);
    expect(rpc.calls.single.$2, {'p_student_id': 'st-1', 'p_start_date': '2026-02-01', 'p_end_date': '2026-02-28'});
    expect(s.presentDays, 1);
    expect(s.absentDays, 1);
    expect(s.dailyRecords.first.date.day, 4); // newest first
  });

  test('status mapping is case-insensitive and leave variants count as leave', () {
    expect(DailyAttendance.fromMap({'status': 'Late', 'attendance_date': '2026-09-04'}).status, AttendanceStatus.late);
    expect(DailyAttendance.fromMap({'status': 'on_leave', 'attendance_date': '2026-09-04'}).status, AttendanceStatus.leave);
  });

  test('today: no row -> null (not marked yet), never an assumed status', () async {
    rpc.on('get_student_attendance_for_parent', (_) => []);
    expect(await AttendanceService.fetchTodayAttendance(studentId: 'st-1'), isNull);
  });

  test('a child that is not linked is refused, not shown as an empty month', () async {
    rpc.on('get_student_attendance_for_parent',
        (_) => throw const PostgrestException(message: 'not allowed', code: '42501'));
    expect(
      () => AttendanceService.fetchAttendanceForStudent(studentId: 'someone-else', year: 2026, month: 9),
      throwsA(isA<ParentDataException>()),
    );
  });
}

import 'dart:async';

import 'package:parent_app/core/services/parent_api.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Test double for the Supabase RPC gateway. Each handler receives the
/// params and returns the JSON the server would return (or throws).
class FakeRpc {
  final Map<String, FutureOr<dynamic> Function(Map<String, dynamic> params)> handlers = {};
  final List<(String, Map<String, dynamic>)> calls = [];

  void on(String fn, FutureOr<dynamic> Function(Map<String, dynamic> params) h) => handlers[fn] = h;

  Future<dynamic> call(String fn, Map<String, dynamic> params) async {
    calls.add((fn, Map.of(params)));
    final h = handlers[fn];
    if (h == null) {
      throw PostgrestException(message: 'Could not find the function public.$fn', code: 'PGRST202');
    }
    return await h(params);
  }

  int count(String fn) => calls.where((c) => c.$1 == fn).length;

  ParentApi install() {
    final api = ParentApi(call);
    ParentApi.instance = api;
    return api;
  }
}

/// Handlers for every per-child read, returning empty but valid payloads.
void installEmptyChildData(FakeRpc rpc) {
  rpc.on('parent_get_school', (_) => {'id': 'school-a', 'name': 'Test School A'});
  rpc.on('get_student_attendance_for_parent', (_) => []);
  rpc.on('parent_get_homework', (_) => []);
  rpc.on('parent_get_timetable', (_) => []);
  rpc.on('parent_get_fees', (_) => {'current_account_id': null, 'accounts': [], 'payments': []});
  rpc.on('parent_get_results', (_) => []);
  rpc.on('parent_get_exam_schedule', (_) => []);
  rpc.on('parent_get_notices', (_) => []);
  rpc.on('parent_get_notifications', (_) => []);
}

Map<String, dynamic> sessionJson({List<Map<String, dynamic>> children = const [], String membership = 'OK'}) => {
      'authenticated': true,
      'auth_user_id': 'auth-parent-1',
      'email': 'parent@example.invalid',
      'membership': membership,
      'role': 'parent',
      'school_id': 'school-a',
      'profile': {'id': 'auth-parent-1', 'full_name': 'Test Parent', 'phone': '9000000000', 'status': 'active'},
      'children': children,
    };

Map<String, dynamic> childJson(String id, {String name = 'Child', String cls = '8', String sec = 'A'}) => {
      'id': id,
      'school_id': 'school-a',
      'name': name,
      'admission_number': 'ADM-$id',
      'class_name': cls,
      'section_name': sec,
      'roll_number': '3',
      'academic_year_name': '2026-27',
      'school_name': 'Test School A',
      'relationship': 'FATHER',
    };

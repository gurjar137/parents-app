import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:parent_app/core/services/auth_service.dart';
import 'package:parent_app/data/models/student_model.dart';
import 'package:parent_app/providers/parent_app_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'support/fake_parent_api.dart';

Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 10));

void main() {
  late FakeRpc rpc;
  final childA = StudentModel.fromSession(childJson('st-A', name: 'Child A'));
  final childB = StudentModel.fromSession(childJson('st-B', name: 'Child B', cls: '6', sec: 'B'));
  final parent = ParentSession.fromJson(sessionJson()).parent;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    rpc = FakeRpc()..install();
    installEmptyChildData(rpc);
  });

  test('only server-verified children can be selected', () async {
    final p = ParentAppProvider(autoStart: false)..debugSetSession(parent, [childA]);
    await settle();
    p.selectChild(childB); // not in the session
    expect(p.selectedChild.id, 'st-A');
  });

  test('a late response for the previous child never overwrites the new child', () async {
    final slowA = Completer<dynamic>();
    rpc.on('parent_get_homework', (params) {
      if (params['p_student_id'] == 'st-A') return slowA.future;
      return [
        {'id': 'hw-B', 'title': 'B homework', 'due_date': '2099-01-01', 'subject': 'Maths'}
      ];
    });
    final p = ParentAppProvider(autoStart: false)..debugSetSession(parent, [childA, childB]);
    await settle();
    p.selectChild(childB);
    await settle();
    expect(p.currentHomeworkList.single.id, 'hw-B');

    slowA.complete([
      {'id': 'hw-A', 'title': 'A homework', 'due_date': '2099-01-01'}
    ]);
    await settle();
    expect(p.currentHomeworkList.single.id, 'hw-B');
    expect(p.selectedChild.id, 'st-B');
  });

  test('each child is loaded with its own id only', () async {
    final p = ParentAppProvider(autoStart: false)..debugSetSession(parent, [childA, childB]);
    await settle();
    p.selectChild(childB);
    await settle();
    final feeIds = rpc.calls.where((c) => c.$1 == 'parent_get_fees').map((c) => c.$2['p_student_id']).toList();
    expect(feeIds, ['st-A', 'st-B']);
  });

  test('a failed load shows an error, not an empty list', () async {
    rpc.on('parent_get_results', (_) => throw const PostgrestException(message: 'x', code: 'XX000'));
    final p = ParentAppProvider(autoStart: false)..debugSetSession(parent, [childA]);
    await settle();
    expect(p.resultsError, isNotNull);
    expect(p.hasResultsData, isFalse);
  });

  test('revoked link (42501) re-reads the session and drops the child', () async {
    var revoked = false;
    rpc.on('parent_get_fees', (_) {
      if (revoked) throw const PostgrestException(message: 'not linked', code: '42501');
      return {'accounts': [], 'payments': []};
    });
    rpc.on('parent_get_session', (_) => sessionJson(children: revoked ? [] : [childJson('st-A')]));
    final p = ParentAppProvider(autoStart: false)..debugSetSession(parent, [childA]);
    await settle();
    revoked = true;
    await p.loadFeeSummaryForSelectedChild();
    await settle();
    expect(p.children, isEmpty);
    expect(p.isChildLinked, isFalse);
  });

  test('notification read is recorded on the server before the badge changes', () async {
    rpc.on('parent_get_notifications', (_) => [
          {'id': 'n1', 'title': 'Fee payment recorded', 'category': 'Fees', 'related_record_type': 'fee_payment', 'is_read': false},
        ]);
    var serverOk = false;
    rpc.on('parent_mark_notifications_read', (_) => serverOk ? 1 : throw const PostgrestException(message: 'x', code: 'XX000'));
    final p = ParentAppProvider(autoStart: false)..debugSetSession(parent, [childA]);
    await settle();
    expect(p.unreadNotificationsCount, 1);
    expect(p.notifications.single.targetType, 'fee');

    expect(await p.markAppNotificationAsRead('n1'), isFalse);
    expect(p.unreadNotificationsCount, 1);

    serverOk = true;
    expect(await p.markAllNotificationsRead(), isTrue);
    expect(p.unreadNotificationsCount, 0);
    expect(rpc.calls.last.$2, {'p_ids': null});
  });

  test('logout clears every child dataset and the branding', () async {
    final p = ParentAppProvider(autoStart: false)..debugSetSession(parent, [childA]);
    await settle();
    expect(p.branding.schoolName, 'Test School A');
    await p.logout();
    expect(p.isLoggedIn, isFalse);
    expect(p.children, isEmpty);
    expect(p.hasFeeData, isFalse);
    expect(p.notifications, isEmpty);
    expect(p.branding.schoolName, 'School Portal');
  });

  test('features without a school data source return nothing (no demo data)', () {
    final p = ParentAppProvider(autoStart: false)..debugSetSession(parent, [childA]);
    expect(p.currentPtmSchedule, isNull);
    expect(p.currentDocuments, isEmpty);
    expect(p.calendarEvents, isEmpty);
    expect(p.currentTransport, isNull);
    expect(p.currentMessagesList, isEmpty);
    expect(p.submitCorrectionRequest(fieldName: 'a', currentValue: 'b', requestedValue: 'c', reason: 'd'), isFalse);
  });
}

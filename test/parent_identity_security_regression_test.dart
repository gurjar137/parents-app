import 'package:flutter_test/flutter_test.dart';
import 'package:parent_app/core/services/auth_service.dart';
import 'package:parent_app/core/services/link_child_service.dart';
import 'package:parent_app/data/models/school_brand_model.dart';
import 'package:parent_app/data/models/student_model.dart';
import 'package:parent_app/providers/parent_app_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_parent_api.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    final rpc = FakeRpc()..install();
    installEmptyChildData(rpc);
  });

  group('1. Father\'s name integrity', () {
    test('no default father name is invented', () {
      final s = StudentModel.fromMap({'id': 's1', 'name': 'Aarav Kumar', 'class_name': '6', 'section': 'A'}, 's1');
      expect(s.fatherName, isNull);
      expect(s.displayFatherName, 'Not provided');
    });

    test('a genuine father name is shown as stored', () {
      final s = StudentModel.fromMap({'id': 's2', 'name': 'Rohan', 'father_name': 'Sunil Gupta'}, 's2');
      expect(s.displayFatherName, 'Sunil Gupta');
    });

    test('mother name is never used as father name', () {
      final s = StudentModel.fromMap({'id': 's3', 'name': 'Meera', 'mother_name': 'Anjali Verma'}, 's3');
      expect(s.fatherName, isNull);
      expect(s.motherName, 'Anjali Verma');
    });

    test('the literal string "null" is treated as missing', () {
      final s = StudentModel.fromMap({'id': 's4', 'name': 'Kavya', 'father_name': 'null'}, 's4');
      expect(s.fatherName, isNull);
    });
  });

  group('2. School branding has no hardcoded institution', () {
    test('neutral branding names no real school', () {
      final b = SchoolBrandModel.defaultNeutral();
      expect(b.schoolName, 'School Portal');
      expect(b.schoolName.toLowerCase(), isNot(contains('xavier')));
      expect(b.affiliation, isEmpty);
      expect(b.motto, isEmpty);
    });

    test('a school record without optional fields leaves them empty', () {
      final b = SchoolBrandModel.fromMap({'name': 'Real School'});
      expect(b.schoolName, 'Real School');
      expect(b.logoUrl, isEmpty);
      expect(b.address, isEmpty);
      expect(b.affiliation, isEmpty);
    });

    test('provider starts with neutral branding', () {
      expect(ParentAppProvider(autoStart: false).branding.schoolName, 'School Portal');
    });
  });

  group('3. The access code is verified only by the server', () {
    test('empty access code is rejected', () async {
      final res = await ParentAppProvider(autoStart: false).linkChildWithCode(codeOrStudentId: '   ');
      expect(res.status, LinkStatus.invalidCode);
      expect(res.student, isNull);
    });

    test('without the server the code opens nothing (no local lookup, no data)', () async {
      AuthService.debugCodeLoginInvoker = null;
      final provider = ParentAppProvider(autoStart: false);
      final res = await provider.loginWithParentCode('PRT-ABCD-1234');
      expect(res.status, AuthStatus.networkError);
      expect(provider.isLoggedIn, isFalse);
      expect(provider.children, isEmpty);
    });
  });

  group('4. Child switching clears the previous child\'s data', () {
    test('switching child resets every dataset before the new load', () async {
      final a = StudentModel.fromSession(childJson('st-A'));
      final b = StudentModel.fromSession(childJson('st-B'));
      final p = ParentAppProvider(autoStart: false)..debugSetSession(ParentSession.fromJson(sessionJson()).parent, [a, b]);
      p.selectChild(b);
      expect(p.selectedChild.id, 'st-B');
      expect(p.todayAttendance, isNull);
      expect(p.hasAttendanceData, isFalse);
      expect(p.hasHomeworkData, isFalse);
      expect(p.hasFeeData, isFalse);
      expect(p.currentResultsList, isEmpty);
      expect(p.notices, isEmpty);
      expect(p.notifications, isEmpty);
    });
  });

  group('5. Logout', () {
    test('logout clears session, children and branding', () async {
      final p = ParentAppProvider(autoStart: false)
        ..debugSetSession(ParentSession.fromJson(sessionJson()).parent, [StudentModel.fromSession(childJson('st-A'))]);
      expect(p.isChildLinked, isTrue);
      await p.logout();
      expect(p.isLoggedIn, isFalse);
      expect(p.children, isEmpty);
      expect(p.isChildLinked, isFalse);
      expect(p.branding.schoolName, 'School Portal');
      expect(p.currentFeeSummary.netFee, 0.0);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:parent_app/core/services/auth_service.dart';
import 'package:parent_app/core/services/link_child_service.dart';
import 'package:parent_app/providers/parent_app_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'support/fake_parent_api.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('Email/password authentication: input validation (no network)', () {
    test('empty email or password is rejected before any request', () async {
      final r = await AuthService.signInWithEmailPassword(email: '', password: '');
      expect(r.status, AuthStatus.invalidCredentials);
    });

    test('sign-up: invalid email, short password and mismatch are rejected', () async {
      expect((await AuthService.signUpWithEmail(name: 'A', email: 'nope', phone: '', password: 'longenough1', confirmPassword: 'longenough1')).status,
          AuthStatus.invalidCredentials);
      expect((await AuthService.signUpWithEmail(name: 'A', email: 'a@b.co', phone: '', password: 'short', confirmPassword: 'short')).status,
          AuthStatus.weakPassword);
      expect((await AuthService.signUpWithEmail(name: 'A', email: 'a@b.co', phone: '', password: 'longenough1', confirmPassword: 'different1')).status,
          AuthStatus.passwordMismatch);
    });

    test('password change requires 8+ characters', () async {
      final r = await AuthService.updatePassword(newPassword: '1234567', confirmPassword: '1234567');
      expect(r.status, AuthStatus.weakPassword);
    });

  });

  group('Server session parsing (parent_get_session)', () {
    test('children and parent come from the server payload', () {
      final s = ParentSession.fromJson(sessionJson(children: [childJson('st-1', name: 'Asha')]));
      expect(s.membership, 'OK');
      expect(s.parent.name, 'Test Parent');
      expect(s.children.single.id, 'st-1');
      expect(s.children.single.className, '8-A');
      expect(s.children.single.rollNo, 3);
      // Nothing invented for fields the school does not store.
      expect(s.children.single.classTeacher, isEmpty);
      expect(s.children.single.houseName, isEmpty);
      expect(s.children.single.avatarUrl, isEmpty);
    });

    test('staff and inactive accounts are recognised', () {
      expect(ParentSession.fromJson(sessionJson(membership: 'NOT_A_PARENT_ACCOUNT')).isStaffAccount, isTrue);
      expect(ParentSession.fromJson(sessionJson(membership: 'INACTIVE_PROFILE')).isInactive, isTrue);
    });
  });

  group('Child linking (parent_claim_child)', () {
    late FakeRpc rpc;
    setUp(() {
      rpc = FakeRpc()..install();
    });

    test('empty code is rejected without calling the server', () async {
      final r = await LinkChildService.claimChild(accessCode: '   ');
      expect(r.status, LinkStatus.invalidCode);
      expect(rpc.calls, isEmpty);
    });

    test('code is trimmed and upper-cased; only the code and relationship are sent', () async {
      rpc.on('parent_claim_child', (p) => {'success': true, 'reason': 'LINKED', 'student_id': 'st-1'});
      final r = await LinkChildService.claimChild(accessCode: '  sc-ab12-cd34 ', relationship: 'Mother');
      expect(r.status, LinkStatus.success);
      expect(r.studentId, 'st-1');
      expect(rpc.calls.single.$2, {'p_access_code': 'SC-AB12-CD34', 'p_relationship': 'Mother'});
    });

    test('every server refusal maps to a distinct, non-success status', () {
      const expected = {
        'INVALID_CODE': LinkStatus.invalidCode,
        'ALREADY_CLAIMED': LinkStatus.alreadyClaimed,
        'OTHER_SCHOOL': LinkStatus.otherSchool,
        'NOT_A_PARENT_ACCOUNT': LinkStatus.notAParentAccount,
        'ACCOUNT_INACTIVE': LinkStatus.accountInactive,
        'RATE_LIMITED': LinkStatus.rateLimited,
        'SOMETHING_NEW': LinkStatus.backendError,
      };
      expected.forEach((reason, status) {
        final r = LinkChildService.responseFromClaimResult({'success': false, 'reason': reason});
        expect(r.status, status, reason: reason);
        expect(r.errorMessage, isNotEmpty);
        expect(r.student, isNull);
      });
      expect(LinkChildService.responseFromClaimResult({'success': true, 'reason': 'ALREADY_LINKED'}).status,
          LinkStatus.alreadyLinked);
    });

    test('expired session during claim -> unauthenticated (no fake success)', () async {
      rpc.on('parent_claim_child', (_) => throw const PostgrestException(message: 'Authentication required', code: '42501'));
      final r = await LinkChildService.claimChild(accessCode: 'SC-AAAA-BBBB');
      expect(r.status, LinkStatus.unauthenticated);
    });

    test('provider: after a successful claim the child list is reloaded from the server and the child selected', () async {
      installEmptyChildData(rpc);
      var linked = false;
      rpc.on('parent_claim_child', (_) {
        linked = true;
        return {'success': true, 'reason': 'LINKED', 'student_id': 'st-9'};
      });
      rpc.on('parent_get_session', (_) => sessionJson(children: linked ? [childJson('st-9', name: 'Ravi')] : []));

      final provider = ParentAppProvider(autoStart: false);
      provider.debugSetSession(ParentSession.fromJson(sessionJson()).parent, const []);
      expect(provider.isChildLinked, isFalse);

      final r = await provider.linkChildWithCode(codeOrStudentId: 'SC-RAVI-0001');
      expect(r.status, LinkStatus.success);
      expect(provider.children.single.id, 'st-9');
      expect(provider.selectedChild.id, 'st-9');
    });

    test('provider: claim accepted but child not in session -> reported as an error, not success', () async {
      installEmptyChildData(rpc);
      rpc.on('parent_claim_child', (_) => {'success': true, 'reason': 'LINKED', 'student_id': 'st-9'});
      rpc.on('parent_get_session', (_) => sessionJson(children: [], membership: 'INACTIVE_PROFILE'));
      final provider = ParentAppProvider(autoStart: false);
      final r = await provider.linkChildWithCode(codeOrStudentId: 'SC-RAVI-0001');
      expect(r.status, LinkStatus.backendError);
      expect(provider.isChildLinked, isFalse);
    });
  });
}

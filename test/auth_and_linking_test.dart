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

  group('Parent Code sign-in (Edge Function parent-code-login)', () {
    late List<String> invoked;
    late List<String> verified;
    setUp(() {
      invoked = [];
      verified = [];
      AuthService.debugTokenVerifier = (hash) async => verified.add(hash);
    });
    tearDown(() {
      AuthService.debugCodeLoginInvoker = null;
      AuthService.debugTokenVerifier = null;
    });

    test('malformed code is rejected before any request', () async {
      AuthService.debugCodeLoginInvoker = (c) async {
        invoked.add(c);
        return {};
      };
      for (final bad in ['', '  ', 'AB1', "x'; drop", 'SC AB']) {
        final r = await AuthService.signInWithParentCode(bad);
        expect(r.status, AuthStatus.invalidCredentials, reason: bad);
      }
      expect(invoked, isEmpty);
    });

    test('valid code: only the normalised code is sent, the one-time token becomes the session', () async {
      AuthService.debugCodeLoginInvoker = (c) async {
        invoked.add(c);
        return {'success': true, 'token_hash': 'hash-1', 'type': 'magiclink'};
      };
      final r = await AuthService.signInWithParentCode(' sc-ab12-cd34 ');
      expect(r.status, AuthStatus.success);
      expect(invoked, ['SC-AB12-CD34']);
      expect(verified, ['hash-1']);
    });

    test('every server refusal is a failure and no session is created', () async {
      const expected = {
        'INVALID_CODE': AuthStatus.invalidCredentials,
        'ACCESS_DISABLED': AuthStatus.inactiveAccount,
        'RATE_LIMITED': AuthStatus.backendError,
        'USE_EMAIL_LOGIN': AuthStatus.backendError,
        'ALREADY_CLAIMED': AuthStatus.backendError,
        'NOT_DEPLOYED': AuthStatus.backendError,
        'INTERNAL': AuthStatus.backendError,
      };
      for (final e in expected.entries) {
        AuthService.debugCodeLoginInvoker = (_) async => {
              'success': false,
              'error': {'code': e.key, 'message': 'msg'}
            };
        final r = await AuthService.signInWithParentCode('SC-AB12-CD34');
        expect(r.status, e.value, reason: e.key);
        expect(r.errorMessage, isNotEmpty);
      }
      expect(verified, isEmpty);
    });

    test('success without a token is not treated as signed in', () async {
      AuthService.debugCodeLoginInvoker = (_) async => {'success': true};
      final r = await AuthService.signInWithParentCode('SC-AB12-CD34');
      expect(r.status, isNot(AuthStatus.success));
      expect(verified, isEmpty);
    });

    test('network failure and failed token exchange are reported, not hidden', () async {
      AuthService.debugCodeLoginInvoker = (_) async => throw Exception('socket');
      expect((await AuthService.signInWithParentCode('SC-AB12-CD34')).status, AuthStatus.networkError);

      AuthService.debugCodeLoginInvoker = (_) async => {'success': true, 'token_hash': 'h'};
      AuthService.debugTokenVerifier = (_) async => throw Exception('otp expired');
      expect((await AuthService.signInWithParentCode('SC-AB12-CD34')).status, AuthStatus.backendError);
    });

    test('provider: code sign-in loads the children from the server session', () async {
      final rpc = FakeRpc()..install();
      installEmptyChildData(rpc);
      rpc.on('parent_get_session', (_) => sessionJson(children: [childJson('st-1', name: 'Asha')]));
      AuthService.debugCodeLoginInvoker = (_) async => {'success': true, 'token_hash': 'h'};
      final provider = ParentAppProvider(autoStart: false);
      final r = await provider.loginWithParentCode('SC-AB12-CD34');
      expect(r.status, AuthStatus.success);
      expect(provider.isLoggedIn, isTrue);
      expect(provider.selectedChild.id, 'st-1');
    });

    test('provider: refused code leaves the app signed out', () async {
      AuthService.debugCodeLoginInvoker = (_) async => {
            'success': false,
            'error': {'code': 'INVALID_CODE'}
          };
      final provider = ParentAppProvider(autoStart: false);
      final r = await provider.loginWithParentCode('SC-WRONG-0000');
      expect(r.status, AuthStatus.invalidCredentials);
      expect(provider.isLoggedIn, isFalse);
      expect(provider.authError, isNotNull);
    });

    test('code-login accounts are recognised by their synthetic address', () {
      expect(AuthService.isCodeLoginEmail('parent-abc@code-login.invalid'), isTrue);
      expect(AuthService.isCodeLoginEmail('mom@gmail.com'), isFalse);
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

    test('provider: ALREADY_LINKED is a successful outcome with the child selected', () async {
      installEmptyChildData(rpc);
      rpc.on('parent_claim_child', (_) => {'success': true, 'reason': 'ALREADY_LINKED', 'student_id': 'st-9'});
      rpc.on('parent_get_session', (_) => sessionJson(children: [childJson('st-9', name: 'Ravi')]));
      final provider = ParentAppProvider(autoStart: false);
      final r = await provider.linkChildWithCode(codeOrStudentId: 'SC-RAVI-0001');
      expect(r.status, LinkStatus.alreadyLinked);
      expect(r.student?.id, 'st-9');
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

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/parent_model.dart';
import '../../data/models/student_model.dart';
import 'parent_api.dart';
import 'supabase_service.dart';

enum AuthStatus {
  success,
  invalidCredentials,
  emailConfirmationRequired,
  alreadyRegistered,
  weakPassword,
  passwordMismatch,
  inactiveAccount,
  notAParentAccount,
  networkError,
  backendError,
}

class AuthResponse {
  final AuthStatus status;
  final String? errorMessage;
  final String? userMessage;

  const AuthResponse({
    required this.status,
    this.errorMessage,
    this.userMessage,
  });
}

/// The signed-in parent and the children the SERVER says are linked
/// (`parent_get_session`). Nothing here comes from device storage or from
/// editable Auth metadata.
class ParentSession {
  final ParentModel parent;
  final List<StudentModel> children;

  /// 'OK', 'NO_PROFILE' (signed up, no child linked yet), 'INACTIVE_PROFILE',
  /// 'AMBIGUOUS_SCHOOL', 'NO_SCHOOL' or 'NOT_A_PARENT_ACCOUNT'.
  final String membership;

  const ParentSession({required this.parent, required this.children, required this.membership});

  bool get isStaffAccount => membership == 'NOT_A_PARENT_ACCOUNT';
  bool get isInactive => membership == 'INACTIVE_PROFILE';

  factory ParentSession.fromJson(Map<String, dynamic> json) {
    final profile = json['profile'] is Map ? Map<String, dynamic>.from(json['profile'] as Map) : const <String, dynamic>{};
    String s(dynamic v) => (v == null || v.toString() == 'null') ? '' : v.toString();
    final children = (json['children'] is List ? json['children'] as List : const [])
        .whereType<Map>()
        .map((m) => StudentModel.fromSession(Map<String, dynamic>.from(m)))
        .toList();
    return ParentSession(
      parent: ParentModel(
        id: s(json['auth_user_id']),
        name: s(profile['full_name']),
        email: s(profile['email']).isNotEmpty ? s(profile['email']) : s(json['email']),
        phone: s(profile['phone']),
        avatarUrl: '',
        status: s(profile['status']).isNotEmpty ? s(profile['status']) : 'active',
        schoolId: s(json['school_id']).isEmpty ? null : s(json['school_id']),
        childrenIds: children.map((c) => c.id).toList(),
      ),
      children: children,
      membership: s(json['membership']).isEmpty ? 'OK' : s(json['membership']),
    );
  }
}

class AuthService {
  // Keys written by earlier versions (parent code / user id). They are
  // removed on sign-out and never read: the session comes from Supabase Auth.
  static const List<String> _legacyKeys = ['auth_parent_session_user_id', 'auth_parent_access_code'];

  static User? get currentUser => SupabaseService.isInitialized ? SupabaseService.client.auth.currentUser : null;

  static Session? get currentSession =>
      SupabaseService.isInitialized ? SupabaseService.client.auth.currentSession : null;

  /// Server view of the signed-in parent and linked children.
  static Future<ParentSession> loadSession() async {
    final json = await ParentApi.instance.rpcObject('parent_get_session');
    return ParentSession.fromJson(json);
  }

  static Future<void> clearSession() async {
    try {
      if (SupabaseService.isInitialized) {
        await SupabaseService.client.auth.signOut();
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[AuthService] signOut: $e');
    }
    final prefs = await SharedPreferences.getInstance();
    for (final k in _legacyKeys) {
      await prefs.remove(k);
    }
  }

  // ------------------------------------------------------------------
  // Parent Access Code sign-in (the only sign-in shown to parents).
  //
  // The code is checked by the Edge Function `parent-code-login` on the
  // server (School OS repo: supabase/functions/parent-code-login, database
  // 10_parent_code_login.sql). It returns a one-time token for the family's
  // own Auth account, exchanged here for a normal session. The code itself
  // is never stored on the device and unlocks no data by itself.
  // ------------------------------------------------------------------

  /// Test hooks; production uses the Edge Function and Supabase Auth.
  @visibleForTesting
  static Future<Map<String, dynamic>> Function(String code)? debugCodeLoginInvoker;
  @visibleForTesting
  static Future<void> Function(String tokenHash)? debugTokenVerifier;

  static Future<Map<String, dynamic>> _invokeCodeLogin(String code) async {
    try {
      final res = await SupabaseService.client.functions
          .invoke('parent-code-login', body: {'code': code})
          .timeout(ParentApi.timeout);
      return res.data is Map ? Map<String, dynamic>.from(res.data as Map) : <String, dynamic>{};
    } on FunctionException catch (e) {
      if (e.details is Map) return Map<String, dynamic>.from(e.details as Map);
      if (e.status == 404) {
        return {
          'success': false,
          'error': {'code': 'NOT_DEPLOYED', 'message': 'Parent sign-in is not yet enabled on the school server. Please contact the school office.'}
        };
      }
      return {'success': false, 'error': {'code': 'INTERNAL'}};
    }
  }

  static Future<void> _verifyToken(String tokenHash) async {
    await SupabaseService.client.auth.verifyOTP(type: OtpType.magiclink, tokenHash: tokenHash);
  }

  static Future<AuthResponse> signInWithParentCode(String parentCode) async {
    final code = parentCode.replaceAll(RegExp(r'\s+'), '').toUpperCase();
    if (code.length < 6 || code.length > 40 || !RegExp(r'^[A-Z0-9-]+$').hasMatch(code)) {
      return const AuthResponse(
        status: AuthStatus.invalidCredentials,
        errorMessage: 'Please enter the Parent Access Code from your school (for example SC-AB12-CD34).',
      );
    }
    if (debugCodeLoginInvoker == null && !SupabaseService.isInitialized) {
      return const AuthResponse(
        status: AuthStatus.networkError,
        errorMessage: 'The app could not connect to the school server. Please check your connection and restart the app.',
      );
    }

    Map<String, dynamic> body;
    try {
      body = await (debugCodeLoginInvoker ?? _invokeCodeLogin)(code);
    } catch (e) {
      if (kDebugMode) debugPrint('[AuthService] code login request failed: ${e.runtimeType}');
      return const AuthResponse(
        status: AuthStatus.networkError,
        errorMessage: 'Unable to connect. Please check your internet connection and try again.',
      );
    }

    final tokenHash = body['token_hash']?.toString() ?? '';
    if (body['success'] == true && tokenHash.isNotEmpty) {
      try {
        await (debugTokenVerifier ?? _verifyToken)(tokenHash);
        return const AuthResponse(status: AuthStatus.success);
      } catch (e) {
        if (kDebugMode) debugPrint('[AuthService] token exchange failed: ${e.runtimeType}');
        return const AuthResponse(
          status: AuthStatus.backendError,
          errorMessage: 'Sign-in could not be completed. Please try again.',
        );
      }
    }

    final error = body['error'] is Map ? Map<String, dynamic>.from(body['error'] as Map) : const <String, dynamic>{};
    final serverMessage = (error['message'] ?? '').toString();
    switch ((error['code'] ?? '').toString()) {
      case 'INVALID_CODE':
      case 'INVALID_INPUT':
        return const AuthResponse(
          status: AuthStatus.invalidCredentials,
          errorMessage: 'This Parent Access Code is not valid. Please check it with the school office.',
        );
      case 'ACCESS_DISABLED':
        return const AuthResponse(
          status: AuthStatus.inactiveAccount,
          errorMessage: 'Parent access for this child is turned off. Please contact the school office.',
        );
      case 'RATE_LIMITED':
        return const AuthResponse(
          status: AuthStatus.backendError,
          errorMessage: 'Too many attempts. Please wait 15 minutes and try again.',
        );
      case 'USE_EMAIL_LOGIN':
      case 'ALREADY_CLAIMED':
      case 'NOT_DEPLOYED':
        return AuthResponse(
          status: AuthStatus.backendError,
          errorMessage: serverMessage.isNotEmpty ? serverMessage : 'Sign-in is not possible with this code. Please contact the school office.',
        );
      default:
        return const AuthResponse(
          status: AuthStatus.backendError,
          errorMessage: 'Sign-in failed. Please try again.',
        );
    }
  }

  /// True for the family account created by code sign-in (its address is
  /// synthetic and it has no password the parent knows).
  static bool isCodeLoginEmail(String email) => email.toLowerCase().endsWith('@code-login.invalid');

  static Future<AuthResponse> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty || password.isEmpty) {
      return const AuthResponse(
        status: AuthStatus.invalidCredentials,
        errorMessage: 'Please enter both email address and password.',
      );
    }
    if (!SupabaseService.isInitialized) {
      return const AuthResponse(
        status: AuthStatus.networkError,
        errorMessage: 'The app could not connect to the school server. Please check your connection and restart the app.',
      );
    }

    try {
      final res = await SupabaseService.client.auth.signInWithPassword(email: normalizedEmail, password: password);
      if (res.user == null) {
        return const AuthResponse(status: AuthStatus.invalidCredentials, errorMessage: 'Invalid email or password.');
      }
      return const AuthResponse(status: AuthStatus.success);
    } on AuthException catch (e) {
      final msg = e.message.toLowerCase();
      if (msg.contains('invalid login credentials') || msg.contains('invalid_credentials')) {
        return const AuthResponse(status: AuthStatus.invalidCredentials, errorMessage: 'Invalid email or password.');
      }
      if (msg.contains('email not confirmed')) {
        return const AuthResponse(
          status: AuthStatus.emailConfirmationRequired,
          errorMessage: 'Please verify your email address using the link we sent, then sign in.',
        );
      }
      return const AuthResponse(
        status: AuthStatus.backendError,
        errorMessage: 'Sign-in failed. Please try again.',
      );
    } catch (e) {
      return const AuthResponse(
        status: AuthStatus.networkError,
        errorMessage: 'Unable to connect. Please check your internet connection.',
      );
    }
  }

  /// Creates a Supabase Auth login only. The account gets no school, role or
  /// child until the parent redeems a Parent Access Code (parent_claim_child);
  /// nothing in the sign-up metadata grants access.
  static Future<AuthResponse> signUpWithEmail({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String confirmPassword,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final cleanName = name.trim();
    final cleanPhone = phone.trim();

    if (cleanName.isEmpty || normalizedEmail.isEmpty || password.isEmpty) {
      return const AuthResponse(status: AuthStatus.invalidCredentials, errorMessage: 'All fields are required.');
    }
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(normalizedEmail)) {
      return const AuthResponse(status: AuthStatus.invalidCredentials, errorMessage: 'Please enter a valid email address.');
    }
    if (password.length < 8) {
      return const AuthResponse(status: AuthStatus.weakPassword, errorMessage: 'Password must be at least 8 characters.');
    }
    if (password != confirmPassword) {
      return const AuthResponse(status: AuthStatus.passwordMismatch, errorMessage: 'Passwords do not match.');
    }
    if (!SupabaseService.isInitialized) {
      return const AuthResponse(
        status: AuthStatus.networkError,
        errorMessage: 'The app could not connect to the school server. Please check your connection and restart the app.',
      );
    }

    try {
      final res = await SupabaseService.client.auth.signUp(
        email: normalizedEmail,
        password: password,
        // Display name / phone only. Role and school are never taken from here.
        data: {'full_name': cleanName, 'phone': cleanPhone},
      );
      if (res.user == null) {
        return const AuthResponse(
          status: AuthStatus.backendError,
          errorMessage: 'The account could not be created. Please try again.',
        );
      }
      if (res.session == null) {
        return const AuthResponse(
          status: AuthStatus.emailConfirmationRequired,
          userMessage: 'Account created. Please verify your email address using the link we sent, then sign in.',
        );
      }
      return const AuthResponse(status: AuthStatus.success, userMessage: 'Account created. Now link your child.');
    } on AuthException catch (e) {
      final msg = e.message.toLowerCase();
      if (msg.contains('already registered') || msg.contains('user_already_exists') || msg.contains('already exists')) {
        return const AuthResponse(
          status: AuthStatus.alreadyRegistered,
          errorMessage: 'An account with this email already exists. Please sign in.',
        );
      }
      if (msg.contains('password')) {
        return const AuthResponse(status: AuthStatus.weakPassword, errorMessage: 'Please choose a stronger password (at least 8 characters).');
      }
      if (msg.contains('signup') && msg.contains('disabled')) {
        return const AuthResponse(
          status: AuthStatus.backendError,
          errorMessage: 'New accounts cannot be created right now. Please contact the school office.',
        );
      }
      return const AuthResponse(status: AuthStatus.backendError, errorMessage: 'The account could not be created. Please try again.');
    } catch (e) {
      return const AuthResponse(
        status: AuthStatus.networkError,
        errorMessage: 'Network error. Please check your internet connection.',
      );
    }
  }

  static Future<AuthResponse> resetPassword({required String email}) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty || !normalizedEmail.contains('@')) {
      return const AuthResponse(status: AuthStatus.invalidCredentials, errorMessage: 'Please enter a valid email address.');
    }
    if (!SupabaseService.isInitialized) {
      return const AuthResponse(status: AuthStatus.networkError, errorMessage: 'Unable to connect to the school server.');
    }
    try {
      await SupabaseService.client.auth.resetPasswordForEmail(normalizedEmail);
      return const AuthResponse(
        status: AuthStatus.success,
        userMessage: 'If an account exists for this email, a password reset link has been sent.',
      );
    } on AuthException {
      return const AuthResponse(
        status: AuthStatus.backendError,
        errorMessage: 'The reset email could not be sent. Please try again later.',
      );
    } catch (e) {
      return const AuthResponse(
        status: AuthStatus.networkError,
        errorMessage: 'Network error. Unable to send the password reset email.',
      );
    }
  }

  static Future<AuthResponse> updatePassword({
    required String newPassword,
    required String confirmPassword,
  }) async {
    if (newPassword.isEmpty || confirmPassword.isEmpty) {
      return const AuthResponse(status: AuthStatus.invalidCredentials, errorMessage: 'Please enter and confirm your new password.');
    }
    if (newPassword.length < 8) {
      return const AuthResponse(status: AuthStatus.weakPassword, errorMessage: 'New password must be at least 8 characters long.');
    }
    if (newPassword != confirmPassword) {
      return const AuthResponse(status: AuthStatus.passwordMismatch, errorMessage: 'New password confirmation does not match.');
    }
    if (currentUser == null) {
      return const AuthResponse(status: AuthStatus.backendError, errorMessage: 'No active session found. Please sign in again.');
    }
    try {
      await SupabaseService.client.auth.updateUser(UserAttributes(password: newPassword));
      return const AuthResponse(status: AuthStatus.success, userMessage: 'Password updated successfully.');
    } on AuthException catch (e) {
      final msg = e.message.toLowerCase();
      return AuthResponse(
        status: AuthStatus.backendError,
        errorMessage: msg.contains('same') || msg.contains('different')
            ? 'The new password must be different from the current one.'
            : 'The password could not be updated. Please try again.',
      );
    } catch (e) {
      return const AuthResponse(
        status: AuthStatus.networkError,
        errorMessage: 'Unable to update password. Please check your internet connection.',
      );
    }
  }

  /// Name and phone of the signed-in parent (`parent_update_contact`).
  /// Throws [ParentDataException] when the server rejects the change.
  static Future<void> updateParentContact({required String name, required String phone}) async {
    await ParentApi.instance.rpc('parent_update_contact', {'p_full_name': name.trim(), 'p_phone': phone.trim()});
  }
}

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/parent_model.dart';
import '../../data/models/student_model.dart';
import '../config/supabase_config.dart';
import 'supabase_service.dart';

enum AuthStatus {
  success,
  invalidCredentials,
  emailConfirmationRequired,
  alreadyRegistered,
  weakPassword,
  passwordMismatch,
  inactiveAccount,
  networkError,
  backendError,
}

class AuthResponse {
  final AuthStatus status;
  final ParentModel? parent;
  final List<StudentModel>? children;
  final String? errorMessage;
  final String? userMessage;

  const AuthResponse({
    required this.status,
    this.parent,
    this.children,
    this.errorMessage,
    this.userMessage,
  });
}

class AuthService {
  static const String _sessionKey = 'auth_parent_session_user_id';
  static const String _codeKey = 'auth_parent_access_code';

  /// Saves session metadata locally
  static Future<void> saveSession(String userId, {String? parentCode}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionKey, userId);
    if (parentCode != null && parentCode.isNotEmpty) {
      await prefs.setString(_codeKey, parentCode);
    }
  }

  /// Retrieves saved Parent Access Code
  static Future<String?> getSavedParentCode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_codeKey);
  }

  /// Retrieves current Supabase Auth User
  static User? get currentUser {
    if (SupabaseService.isInitialized) {
      return SupabaseService.client.auth.currentUser;
    }
    return null;
  }

  /// Retrieves current Supabase Auth Session
  static Session? get currentSession {
    if (SupabaseService.isInitialized) {
      return SupabaseService.client.auth.currentSession;
    }
    return null;
  }

  /// Clears session on logout
  static Future<void> clearSession() async {
    try {
      if (SupabaseService.isInitialized) {
        await SupabaseService.client.auth.signOut();
      }
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
    await prefs.remove(_codeKey);
  }

  /// Connect Admin-Generated Unique Parent Access Code (public.students.parent_access_code) to Parent App Login
  static Future<AuthResponse> signInWithParentCode(String parentCode) async {
    final normalizedCode = parentCode.trim().toUpperCase();

    if (normalizedCode.isEmpty) {
      return const AuthResponse(
        status: AuthStatus.invalidCredentials,
        errorMessage: 'Please enter your unique Parent Code.',
      );
    }

    if (kDebugMode) {
      debugPrint('===== PARENT CODE RPC LOGIN =====');
      debugPrint('SUPABASE URL = ${SupabaseConfig.url}');
      debugPrint('NORMALIZED CODE = $normalizedCode');
    }

    if (!SupabaseService.isInitialized) {
      if (normalizedCode == 'PRT-INACTIVE') {
        return const AuthResponse(
          status: AuthStatus.inactiveAccount,
          errorMessage: 'This Parent Code is inactive. Please contact your school administrator.',
        );
      }
      return const AuthResponse(
        status: AuthStatus.invalidCredentials,
        errorMessage: 'Invalid Parent Code. Please check the code provided by your school.',
      );
    }

    try {
      final result = await SupabaseService.client.rpc(
        'lookup_student_by_parent_access_code',
        params: {
          'p_code': normalizedCode,
        },
      );

      List<dynamic> studentList = [];
      if (result is List) {
        studentList = result;
      } else if (result is Map) {
        studentList = [result];
      }

      if (studentList.isNotEmpty) {
        final studentRes = Map<String, dynamic>.from(studentList.first);

        final first = (studentRes['first_name'] ?? '').toString().trim();
        final middle = (studentRes['middle_name'] ?? '').toString().trim();
        final last = (studentRes['last_name'] ?? '').toString().trim();

        final fullStudentName = [first, middle, last]
            .where((part) => part.isNotEmpty)
            .join(' ');

        final computedName = fullStudentName.isNotEmpty
            ? fullStudentName
            : (studentRes['name'] ?? studentRes['full_name'] ?? 'Student').toString();

        final className = (studentRes['class_name'] ?? '12').toString();
        final sectionName = (studentRes['section_name'] ?? studentRes['section'] ?? 'a').toString();

        final student = StudentModel(
          id: (studentRes['id'] ?? normalizedCode).toString(),
          name: computedName,
          fatherName: studentRes['father_name']?.toString() ??
              studentRes['guardian_name']?.toString() ??
              studentRes['mother_name']?.toString() ??
              'Father / Guardian',
          className: '$className-$sectionName',
          grade: className.startsWith('Class') ? className : 'Class $className',
          section: sectionName,
          rollNo: int.tryParse((studentRes['roll_number'] ?? studentRes['roll_no'] ?? '1').toString()) ?? 1,
          admissionNo: (studentRes['admission_number'] ?? studentRes['admission_no'] ?? studentRes['id'] ?? normalizedCode).toString(),
          avatarUrl: studentRes['student_photo'] ?? studentRes['avatar_url'] ?? 'https://images.unsplash.com/photo-1544717305-2782549b5136?fit=crop&w=300&h=300',
          academicYear: (studentRes['academic_year'] ?? '2026-2027').toString(),
          houseName: (studentRes['house_name'] ?? 'Tagore House (Blue)').toString(),
          classTeacher: (studentRes['class_teacher'] ?? 'Class Teacher').toString(),
          classmateCount: int.tryParse((studentRes['classmate_count'] ?? '35').toString()) ?? 35,
          schoolId: (studentRes['school_id'] ?? 'SCH-STX-2026').toString(),
          linkingCode: (studentRes['parent_access_code'] ?? normalizedCode).toString(),
        );

        final fatherName = student.fatherName ?? 'Father / Guardian';
        final parentId = 'P-${student.id}';
        final parent = ParentModel(
          id: parentId,
          name: fatherName,
          email: studentRes['email'] ?? studentRes['parent_email'] ?? '',
          phone: studentRes['phone'] ?? studentRes['father_phone'] ?? '',
          avatarUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?fit=crop&w=300&h=300',
          relationship: 'Father / Guardian',
          status: 'active',
          schoolId: student.schoolId,
          childrenIds: [student.id],
        );

        await saveSession(parent.id, parentCode: normalizedCode);

        return AuthResponse(
          status: AuthStatus.success,
          parent: parent,
          children: [student],
          userMessage: 'Parent authenticated successfully!',
        );
      } else {
        return const AuthResponse(
          status: AuthStatus.invalidCredentials,
          errorMessage: 'Invalid Parent Code. Please check the code provided by your school.',
        );
      }
    } on PostgrestException catch (e) {
      if (kDebugMode) debugPrint('[AuthService] RPC PostgrestException: ${e.message}');
      return const AuthResponse(
        status: AuthStatus.invalidCredentials,
        errorMessage: 'Invalid Parent Code. Please check the code provided by your school.',
      );
    } catch (e) {
      if (kDebugMode) debugPrint('[AuthService] RPC Exception: $e');
      return const AuthResponse(
        status: AuthStatus.invalidCredentials,
        errorMessage: 'Invalid Parent Code. Please check the code provided by your school.',
      );
    }
  }

  /// REAL Supabase Auth: Sign In with Email and Password
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
        status: AuthStatus.backendError,
        errorMessage: 'Supabase service is not initialized.',
      );
    }

    try {
      final res = await SupabaseService.client.auth.signInWithPassword(
        email: normalizedEmail,
        password: password,
      );

      final user = res.user;
      if (user == null) {
        return const AuthResponse(
          status: AuthStatus.invalidCredentials,
          errorMessage: 'Invalid email or password.',
        );
      }

      // Fetch or sync parent profile
      final parentProfile = await fetchOrCreateParentProfile(user);

      if (parentProfile.status.toLowerCase() != 'active') {
        await SupabaseService.client.auth.signOut();
        return const AuthResponse(
          status: AuthStatus.inactiveAccount,
          errorMessage: 'Your account is currently inactive. Please contact your school administrator.',
        );
      }

      await saveSession(user.id);

      return AuthResponse(
        status: AuthStatus.success,
        parent: parentProfile,
        children: const [],
      );
    } on AuthException catch (e) {
      if (kDebugMode) debugPrint('[AuthService] AuthException: ${e.message}');
      final msg = e.message.toLowerCase();
      if (msg.contains('invalid login credentials') || msg.contains('invalid_credentials')) {
        return const AuthResponse(
          status: AuthStatus.invalidCredentials,
          errorMessage: 'Invalid email or password.',
        );
      } else if (msg.contains('email not confirmed')) {
        return const AuthResponse(
          status: AuthStatus.emailConfirmationRequired,
          errorMessage: 'Please verify your email before signing in.',
        );
      }
      return AuthResponse(
        status: AuthStatus.invalidCredentials,
        errorMessage: e.message,
      );
    } catch (e) {
      return AuthResponse(
        status: AuthStatus.networkError,
        errorMessage: 'Unable to connect. Please check your internet connection.',
      );
    }
  }

  /// REAL Supabase Auth: Sign Up New Parent Account
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
      return const AuthResponse(
        status: AuthStatus.invalidCredentials,
        errorMessage: 'All fields are required.',
      );
    }

    if (!normalizedEmail.contains('@') || !normalizedEmail.contains('.')) {
      return const AuthResponse(
        status: AuthStatus.invalidCredentials,
        errorMessage: 'Please enter a valid email address.',
      );
    }

    if (password.length < 8) {
      return const AuthResponse(
        status: AuthStatus.weakPassword,
        errorMessage: 'Password must be at least 8 characters.',
      );
    }

    if (password != confirmPassword) {
      return const AuthResponse(
        status: AuthStatus.passwordMismatch,
        errorMessage: 'Passwords do not match.',
      );
    }

    if (!SupabaseService.isInitialized) {
      return const AuthResponse(
        status: AuthStatus.backendError,
        errorMessage: 'Supabase service is not initialized.',
      );
    }

    try {
      final res = await SupabaseService.client.auth.signUp(
        email: normalizedEmail,
        password: password,
        data: {
          'full_name': cleanName,
          'phone': cleanPhone,
          'role': 'parent',
        },
      );

      final user = res.user;
      if (user == null) {
        return const AuthResponse(
          status: AuthStatus.backendError,
          errorMessage: 'Failed to create parent account. Please try again.',
        );
      }

      // Check if email confirmation is required (session == null)
      if (res.session == null) {
        return const AuthResponse(
          status: AuthStatus.emailConfirmationRequired,
          userMessage: 'Account created successfully. Please verify your email before signing in.',
        );
      }

      // Create Parent Profile record
      final parentProfile = await fetchOrCreateParentProfile(
        user,
        name: cleanName,
        phone: cleanPhone,
      );

      await saveSession(user.id);

      return AuthResponse(
        status: AuthStatus.success,
        parent: parentProfile,
        children: const [],
        userMessage: 'Account created successfully!',
      );
    } on AuthException catch (e) {
      if (kDebugMode) debugPrint('[AuthService] SignUp AuthException: ${e.message}');
      final msg = e.message.toLowerCase();
      if (msg.contains('already registered') || msg.contains('user_already_exists')) {
        return const AuthResponse(
          status: AuthStatus.alreadyRegistered,
          errorMessage: 'An account with this email already exists. Please sign in.',
        );
      } else if (msg.contains('weak password') || msg.contains('at least 6') || msg.contains('at least 8')) {
        return const AuthResponse(
          status: AuthStatus.weakPassword,
          errorMessage: 'Password must be at least 8 characters.',
        );
      }
      return AuthResponse(
        status: AuthStatus.backendError,
        errorMessage: e.message,
      );
    } catch (e) {
      return AuthResponse(
        status: AuthStatus.networkError,
        errorMessage: 'Network error. Please check your internet connection.',
      );
    }
  }

  /// REAL Supabase Auth: Forgot Password / Password Reset Email
  static Future<AuthResponse> resetPassword({required String email}) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty || !normalizedEmail.contains('@')) {
      return const AuthResponse(
        status: AuthStatus.invalidCredentials,
        errorMessage: 'Please enter a valid email address.',
      );
    }

    try {
      await SupabaseService.client.auth.resetPasswordForEmail(normalizedEmail);
      return const AuthResponse(
        status: AuthStatus.success,
        userMessage: 'Password reset link has been sent to your email. Please check your inbox.',
      );
    } on AuthException catch (e) {
      return AuthResponse(
        status: AuthStatus.backendError,
        errorMessage: e.message,
      );
    } catch (e) {
      return const AuthResponse(
        status: AuthStatus.networkError,
        errorMessage: 'Network error. Unable to send password reset email.',
      );
    }
  }

  /// REAL Supabase Auth: Update Password
  static Future<AuthResponse> updatePassword({
    required String newPassword,
    required String confirmPassword,
  }) async {
    if (newPassword.isEmpty || confirmPassword.isEmpty) {
      return const AuthResponse(
        status: AuthStatus.invalidCredentials,
        errorMessage: 'Please enter and confirm your new password.',
      );
    }

    if (newPassword.length < 6) {
      return const AuthResponse(
        status: AuthStatus.weakPassword,
        errorMessage: 'New password must be at least 6 characters long.',
      );
    }

    if (newPassword != confirmPassword) {
      return const AuthResponse(
        status: AuthStatus.passwordMismatch,
        errorMessage: 'New password confirmation does not match.',
      );
    }

    if (!SupabaseService.isInitialized || currentUser == null) {
      return const AuthResponse(
        status: AuthStatus.backendError,
        errorMessage: 'No active session found. Please sign in again.',
      );
    }

    try {
      await SupabaseService.client.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      return const AuthResponse(
        status: AuthStatus.success,
        userMessage: 'Password updated successfully.',
      );
    } on AuthException catch (e) {
      return AuthResponse(
        status: AuthStatus.backendError,
        errorMessage: e.message,
      );
    } catch (e) {
      return const AuthResponse(
        status: AuthStatus.networkError,
        errorMessage: 'Unable to update password. Please check your internet connection.',
      );
    }
  }

  /// Update Non-Privileged Profile Particulars (Name, Phone, Avatar, Relationship)
  static Future<ParentModel?> updateParentProfile({
    required ParentModel currentParent,
    required String name,
    required String phone,
    String? avatarUrl,
    String? relationship,
  }) async {
    final updated = currentParent.copyWith(
      name: name.trim().isNotEmpty ? name.trim() : currentParent.name,
      phone: phone.trim().isNotEmpty ? phone.trim() : currentParent.phone,
      avatarUrl: avatarUrl ?? currentParent.avatarUrl,
      relationship: relationship ?? currentParent.relationship,
    );

    if (SupabaseService.isInitialized) {
      try {
        await SupabaseService.client.from('parents').update({
          'name': updated.name,
          'phone': updated.phone,
          'avatar_url': updated.avatarUrl,
          'relationship': updated.relationship,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', currentParent.id);
      } catch (e) {
        if (kDebugMode) debugPrint('[AuthService] Profile update notice: $e');
      }
    }

    return updated;
  }

  /// Helper: Fetch or create parent profile record linked by Supabase Auth `user.id`
  static Future<ParentModel> fetchOrCreateParentProfile(
    User user, {
    String? name,
    String? phone,
  }) async {
    final userId = user.id;
    final userEmail = user.email ?? '';
    final userName = name ?? user.userMetadata?['full_name'] ?? 'Parent User';
    final userPhone = phone ?? user.userMetadata?['phone'] ?? '';

    final fallbackProfile = ParentModel(
      id: userId,
      name: userName,
      email: userEmail,
      phone: userPhone,
      avatarUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?fit=crop&w=300&h=300',
      status: 'active',
      childrenIds: const [],
    );

    if (!SupabaseService.isInitialized) return fallbackProfile;

    try {
      // Try to fetch existing profile from `parents` or `profiles` table
      final response = await SupabaseService.client
          .from('parents')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response != null) {
        return ParentModel.fromMap(response, userId);
      }

      // Upsert profile if missing
      final profileMap = {
        'id': userId,
        'auth_user_id': userId,
        'name': userName,
        'email': userEmail,
        'phone': userPhone,
        'status': 'active',
        'created_at': DateTime.now().toIso8601String(),
      };

      await SupabaseService.client.from('parents').upsert(profileMap);
      return fallbackProfile;
    } catch (e) {
      if (kDebugMode) debugPrint('[AuthService] Profile table notice: $e');
      return fallbackProfile;
    }
  }
}

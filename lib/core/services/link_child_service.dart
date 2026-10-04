import 'package:flutter/foundation.dart';
import '../../data/models/student_model.dart';
import 'supabase_service.dart';

enum LinkStatus {
  success,
  notFound,
  alreadyLinked,
  unauthenticated,
  invalidCode,
  networkError,
  backendError,
}

class LinkChildResponse {
  final LinkStatus status;
  final StudentModel? student;
  final String? errorMessage;
  final String? userMessage;

  const LinkChildResponse({
    required this.status,
    this.student,
    this.errorMessage,
    this.userMessage,
  });
}

class LinkChildService {
  /// Verifies student Parent Access Code against public.students.parent_access_code
  static Future<LinkChildResponse> linkStudentToParent({
    required String codeOrStudentId,
    String relationship = 'Parent',
  }) async {
    final cleanCode = codeOrStudentId.trim().toUpperCase();

    if (cleanCode.isEmpty) {
      return const LinkChildResponse(
        status: LinkStatus.invalidCode,
        errorMessage: 'Please enter a valid Parent Access Code.',
      );
    }

    // 1. Try Supabase verification against public.students.parent_access_code via RPC or direct query
    if (SupabaseService.isInitialized) {
      try {
        List<dynamic>? rpcRes;
        try {
          rpcRes = await SupabaseService.client
              .rpc('lookup_student_by_parent_access_code', params: {'p_code': cleanCode});
        } catch (_) {}

        Map<String, dynamic>? studentRes;
        if (rpcRes != null && rpcRes.isNotEmpty) {
          studentRes = Map<String, dynamic>.from(rpcRes.first);
        } else {
          studentRes = await SupabaseService.client
              .from('students')
              .select()
              .eq('parent_access_code', cleanCode)
              .maybeSingle();
        }

        if (studentRes != null) {
          final student = StudentModel.fromMap(studentRes, studentRes['id'] ?? cleanCode);

          return LinkChildResponse(
            status: LinkStatus.success,
            student: student,
            userMessage: 'Successfully linked ${student.name} (${student.className})!',
          );
        }
      } catch (e) {
        if (kDebugMode) debugPrint('[LinkChildService] Supabase link notice: $e');
      }
    }

    // Fallback: If not found in database, return notFound
    return const LinkChildResponse(
      status: LinkStatus.notFound,
      errorMessage: 'Invalid Parent Access Code. Please verify the code with your school administration.',
    );
  }

  /// Fetches authorized linked students for the given parent auth ID
  static Future<List<StudentModel>> fetchLinkedStudentsForParent(String parentAuthUserId) async {
    if (SupabaseService.isInitialized) {
      try {
        final rels = await SupabaseService.client
            .from('parent_students')
            .select('student_id, students(*)')
            .eq('parent_id', parentAuthUserId);

        if (rels.isNotEmpty) {
          final List<StudentModel> list = [];
          for (final item in rels) {
            if (item['students'] != null) {
              list.add(StudentModel.fromMap(item['students'], item['student_id']));
            }
          }
          if (list.isNotEmpty) return list;
        }
      } catch (e) {
        if (kDebugMode) debugPrint('[LinkChildService] Fetch linked students notice: $e');
      }
    }

    return [];
  }
}

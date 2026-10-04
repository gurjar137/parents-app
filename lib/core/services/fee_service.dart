import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/fee_model.dart';
import 'auth_service.dart';
import 'supabase_service.dart';

class FeeService {
  /// Fetches live authorized fee summary and payment history for a specific student
  static Future<FeeSummaryModel> fetchFeeSummaryForStudent({
    required String studentId,
    required String schoolId,
    String? academicYearId,
    String? parentAccessCode,
  }) async {
    if (studentId.isEmpty) {
      return FeeSummaryModel.fromData(
        studentId: studentId,
        schoolId: schoolId,
        academicYearId: academicYearId ?? '',
      );
    }

    final code = (parentAccessCode != null && parentAccessCode.isNotEmpty)
        ? parentAccessCode.trim().toUpperCase()
        : (await AuthService.getSavedParentCode() ?? '').trim().toUpperCase();

    if (kDebugMode) {
      debugPrint('===== PARENT FEES SERVICE =====');
      debugPrint('ACTIVE STUDENT ID = $studentId');
      debugPrint('SCHOOL ID = $schoolId');
      debugPrint('ACADEMIC YEAR ID = $academicYearId');
      debugPrint('HAS VERIFIED CODE = ${code.isNotEmpty}');
    }

    if (SupabaseService.isInitialized) {
      Map<String, dynamic>? accountMap;
      List<dynamic> paymentRows = [];
      String? errorMessage;

      // 1. Try Security Definer RPC get_parent_student_fees with p_student_id, p_school_id, p_parent_access_code
      try {
        final rpcRes = await SupabaseService.client.rpc(
          'get_parent_student_fees',
          params: {
            'p_student_id': studentId,
            'p_school_id': schoolId.isNotEmpty ? schoolId : null,
            'p_parent_access_code': code.isNotEmpty ? code : null,
          },
        );

        if (rpcRes != null && rpcRes is Map<String, dynamic>) {
          if (rpcRes['account'] is Map<String, dynamic>) {
            accountMap = Map<String, dynamic>.from(rpcRes['account']);
          }
          if (rpcRes['payments'] is List) {
            paymentRows = rpcRes['payments'];
          }
        }
      } catch (rpcErr) {
        if (kDebugMode) debugPrint('[FeeService RPC Notice]: $rpcErr');
      }

      // 2. Direct Supabase Query on student_fee_accounts & fee_payments as fallback
      if (accountMap == null) {
        try {
          var accountQuery = SupabaseService.client
              .from('student_fee_accounts')
              .select('*')
              .eq('student_id', studentId);

          if (schoolId.isNotEmpty) {
            accountQuery = accountQuery.eq('school_id', schoolId);
          }

          final accountRes = await accountQuery.order('created_at', ascending: false).maybeSingle();
          if (accountRes != null) {
            accountMap = Map<String, dynamic>.from(accountRes);
            final feeAccountId = accountMap['id']?.toString();

            var paymentsQuery = SupabaseService.client
                .from('fee_payments')
                .select('*')
                .eq('student_id', studentId);

            if (feeAccountId != null && feeAccountId.isNotEmpty) {
              paymentsQuery = paymentsQuery.or('fee_account_id.eq.$feeAccountId,student_id.eq.$studentId');
            }

            final List<dynamic> paymentsRes = await paymentsQuery.order('payment_date', ascending: false);
            paymentRows = paymentsRes;
          }
        } on PostgrestException catch (e) {
          errorMessage = 'Database Error: ${e.message} (Code: ${e.code})';
          if (kDebugMode) debugPrint('[FeeService PostgrestException]: $errorMessage');
        } catch (e) {
          errorMessage = 'Query Exception: $e';
          if (kDebugMode) debugPrint('[FeeService Exception]: $errorMessage');
        }
      }

      if (errorMessage != null && accountMap == null) {
        if (kDebugMode) debugPrint('[FeeService Handled Error]: $errorMessage');
      }

      return FeeSummaryModel.fromData(
        studentId: studentId,
        schoolId: schoolId,
        academicYearId: academicYearId ?? '',
        accountMap: accountMap,
        paymentRows: paymentRows,
      );
    }

    return FeeSummaryModel.fromData(
      studentId: studentId,
      schoolId: schoolId,
      academicYearId: academicYearId ?? '',
    );
  }
}

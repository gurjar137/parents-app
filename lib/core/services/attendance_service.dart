import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/attendance_model.dart';
import 'supabase_service.dart';

class AttendanceService {
  /// Rebuilt Attendance Read Flow: Direct Query with Security Definer RPC fallback
  static Future<MonthlyAttendanceSummary> fetchAttendanceForStudent({
    required String studentId,
    required int year,
    required int month,
  }) async {
    final startDateStr = '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}-01';
    final lastDay = DateTime(year, month + 1, 0).day;
    final endDateStr = '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}-${lastDay.toString().padLeft(2, '0')}';
    final monthYearLabel = _formatMonthYear(year, month);

    if (studentId.isEmpty) {
      return MonthlyAttendanceSummary(
        monthYear: monthYearLabel,
        totalWorkingDays: 0,
        presentDays: 0,
        absentDays: 0,
        lateDays: 0,
        holidayDays: 0,
        percentage: 0.0,
        dailyRecords: [],
      );
    }

    if (kDebugMode) {
      debugPrint('===== PARENT ATTENDANCE REBUILD =====');
      debugPrint('ACTIVE STUDENT ID = $studentId');
      debugPrint('MONTH RANGE = $startDateStr to $endDateStr');
      debugPrint('TABLE = public.attendance');
    }

    if (SupabaseService.isInitialized) {
      List<dynamic>? rawRows;
      String? queryError;

      // 1. Direct Supabase Query: public.attendance targeting student_id = activeStudentId
      try {
        final List<dynamic> response = await SupabaseService.client
            .from('attendance')
            .select('id, student_id, attendance_date, status, school_id, academic_year_id')
            .eq('student_id', studentId)
            .order('attendance_date', ascending: false);
        rawRows = response;
      } on PostgrestException catch (e) {
        queryError = 'PostgrestException: ${e.message} (Code: ${e.code})';
        if (kDebugMode) debugPrint('[AttendanceService Direct Query Error]: $queryError');
      } catch (e) {
        queryError = 'Query Exception: $e';
        if (kDebugMode) debugPrint('[AttendanceService Exception]: $queryError');
      }

      // 2. RPC Fallback if direct query was blocked by RLS or returned no records
      if ((rawRows == null || rawRows.isEmpty) && queryError == null) {
        try {
          final rpcRes = await SupabaseService.client.rpc(
            'get_parent_student_attendance',
            params: {
              'p_student_id': studentId,
            },
          );
          if (rpcRes is List) {
            rawRows = rpcRes;
          }
        } catch (rpcErr) {
          if (kDebugMode) debugPrint('[AttendanceService RPC Notice]: $rpcErr');
        }
      }

      if (kDebugMode) {
        debugPrint('ATTENDANCE ROWS RETURNED = ${rawRows?.length ?? 0}');
        debugPrint('QUERY ERROR = ${queryError ?? "NONE"}');
      }

      if (rawRows != null && rawRows.isNotEmpty) {
        final filteredRecords = rawRows
            .map((map) => DailyAttendance.fromMap(Map<String, dynamic>.from(map)))
            .where((rec) {
              final dStr = rec.date.toIso8601String().substring(0, 10);
              return dStr.compareTo(startDateStr) >= 0 && dStr.compareTo(endDateStr) <= 0;
            })
            .toList();

        return MonthlyAttendanceSummary.fromDailyRecords(
          monthYear: monthYearLabel,
          records: filteredRecords,
        );
      }
    }

    return MonthlyAttendanceSummary(
      monthYear: monthYearLabel,
      totalWorkingDays: 0,
      presentDays: 0,
      absentDays: 0,
      lateDays: 0,
      holidayDays: 0,
      percentage: 0.0,
      dailyRecords: [],
    );
  }

  /// Rebuilt Today's Attendance Read Flow
  static Future<DailyAttendance?> fetchTodayAttendance({required String studentId}) async {
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);

    if (studentId.isEmpty) return null;

    if (kDebugMode) {
      debugPrint('===== TODAY ATTENDANCE REBUILD =====');
      debugPrint('ACTIVE STUDENT ID = $studentId');
      debugPrint('TODAY DATE = $todayStr');
      debugPrint('TABLE = public.attendance');
    }

    if (SupabaseService.isInitialized) {
      Map<String, dynamic>? recordMap;
      String? queryError;

      // 1. Direct Query on public.attendance with attendance_date = todayStr
      try {
        final List<dynamic> response = await SupabaseService.client
            .from('attendance')
            .select('id, student_id, attendance_date, status, school_id, academic_year_id')
            .eq('student_id', studentId)
            .eq('attendance_date', todayStr);

        if (response.isNotEmpty) {
          recordMap = Map<String, dynamic>.from(response.first);
        }
      } on PostgrestException catch (e) {
        queryError = 'PostgrestException: ${e.message} (Code: ${e.code})';
        if (kDebugMode) debugPrint('[AttendanceService Today Direct Error]: $queryError');
      } catch (e) {
        queryError = 'Exception: $e';
        if (kDebugMode) debugPrint('[AttendanceService Today Exception]: $e');
      }

      // 2. RPC Fallback
      if (recordMap == null && queryError == null) {
        try {
          final rpcRes = await SupabaseService.client.rpc(
            'get_parent_student_attendance',
            params: {
              'p_student_id': studentId,
            },
          );
          if (rpcRes is List && rpcRes.isNotEmpty) {
            final matchingToday = rpcRes.firstWhere(
              (row) => (row['attendance_date'] ?? '').toString().startsWith(todayStr),
              orElse: () => null,
            );
            if (matchingToday != null) {
              recordMap = Map<String, dynamic>.from(matchingToday);
            }
          }
        } catch (rpcErr) {
          if (kDebugMode) debugPrint('[AttendanceService Today RPC Notice]: $rpcErr');
        }
      }

      if (kDebugMode) {
        debugPrint('TODAY RESULT = ${recordMap != null ? "RECORD FOUND" : "NO RECORD"}');
        debugPrint('QUERY ERROR = ${queryError ?? "NONE"}');
        if (recordMap != null) {
          debugPrint('STATUS = ${recordMap['status']}');
        }
      }

      if (recordMap != null) {
        return DailyAttendance.fromMap(recordMap);
      }
    }

    return null;
  }

  static String _formatMonthYear(int year, int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[month - 1]} $year';
  }
}

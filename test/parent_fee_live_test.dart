import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:parent_app/core/services/supabase_service.dart';
import 'package:parent_app/core/services/fee_service.dart';
import 'package:parent_app/data/models/fee_model.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await SupabaseService.initialize();
  });

  group('Parent App Live Fee Management & Security Tests', () {
    const verifiedStudentId = '56e0bade-7586-4ba4-b16b-bafec3a6aaa8';
    const schoolId = '6254bee9-151d-4332-8a1c-3994af7d2153';

    test('1. Fee calculation logic computes Net Fee, Paid, Outstanding, and Progress Ratio accurately', () {
      final sampleAccount = {
        'id': 'fee-acc-1001',
        'student_id': verifiedStudentId,
        'school_id': schoolId,
        'academic_year_id': '47d1569b-e032-44a7-891f-b21f5458f55b',
        'gross_fee': 30000.0,
        'discount_amount': 2000.0,
        'waiver_amount': 0.0,
        'due_date': '2027-01-14',
        'status': 'partially_paid',
        'notes': 'Scholarship discount applied',
      };

      final samplePayments = [
        {
          'id': 'pay-1',
          'fee_account_id': 'fee-acc-1001',
          'student_id': verifiedStudentId,
          'receipt_number': 'REC-2026-001',
          'amount': 5000.0,
          'payment_date': '2026-08-10',
          'payment_method': 'cash',
          'notes': 'First installment',
        },
        {
          'id': 'pay-2',
          'fee_account_id': 'fee-acc-1001',
          'student_id': verifiedStudentId,
          'receipt_number': 'REC-2026-002',
          'amount': 2500.0,
          'payment_date': '2026-09-01',
          'payment_method': 'upi',
          'transaction_reference': 'TXN12345678',
          'notes': 'Second installment',
        },
      ];

      final summary = FeeSummaryModel.fromData(
        studentId: verifiedStudentId,
        schoolId: schoolId,
        academicYearId: '47d1569b-e032-44a7-891f-b21f5458f55b',
        accountMap: sampleAccount,
        paymentRows: samplePayments,
      );

      expect(summary.grossFee, equals(30000.0));
      expect(summary.discountAmount, equals(2000.0));
      expect(summary.waiverAmount, equals(0.0));
      expect(summary.netFee, equals(28000.0));
      expect(summary.paidAmount, equals(7500.0));
      expect(summary.outstandingAmount, equals(20500.0));
      expect(summary.progressPercentage, equals(27));
      expect(summary.status, equals('partially_paid'));
      expect(summary.payments.length, equals(2));
      expect(summary.payments.first.receiptNo, equals('REC-2026-002'));
    });

    test('2. Unassigned student handles empty fee account safely without throwing', () {
      final summary = FeeSummaryModel.fromData(
        studentId: 'unassigned-student-id',
        schoolId: schoolId,
        academicYearId: '47d1569b-e032-44a7-891f-b21f5458f55b',
        accountMap: null,
        paymentRows: const [],
      );

      expect(summary.hasFeeAccount, isFalse);
      expect(summary.netFee, equals(0.0));
      expect(summary.paidAmount, equals(0.0));
      expect(summary.outstandingAmount, equals(0.0));
      expect(summary.payments, isEmpty);
    });

    test('3. Live FeeService query executes without runtime errors', () async {
      final summary = await FeeService.fetchFeeSummaryForStudent(
        studentId: verifiedStudentId,
        schoolId: schoolId,
      );

      expect(summary, isNotNull);
      expect(summary.studentId, equals(verifiedStudentId));
    });
  });
}

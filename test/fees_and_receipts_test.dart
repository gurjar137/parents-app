import 'package:flutter_test/flutter_test.dart';
import 'package:parent_app/core/services/fee_service.dart';
import 'package:parent_app/core/services/parent_api.dart';
import 'package:parent_app/data/models/fee_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'support/fake_parent_api.dart';

/// Shape returned by parent_get_fees (08_parents_app_integration.sql).
Map<String, dynamic> feesJson() => {
      'current_account_id': 'acc-2026',
      'accounts': [
        {
          'id': 'acc-2026',
          'student_id': 'st-1',
          'school_id': 'school-a',
          'academic_year_id': 'ay-2026',
          'academic_year': {'id': 'ay-2026', 'name': '2026-27', 'is_current': true},
          'gross_fee': 10000,
          'discount_amount': 1000,
          'waiver_amount': 0,
          'net_fee': 9000,
          'paid_amount': 2500,
          'balance': 6500,
          'due_date': '2099-01-31',
          'status': 'partially_paid',
        },
        {
          'id': 'acc-2025',
          'net_fee': 8000,
          'paid_amount': 8000,
          'balance': 0,
          'academic_year': {'name': '2025-26'},
        },
      ],
      'payments': [
        {
          'id': 'pay-1',
          'receipt_number': 'RCT-2026-000001',
          'amount': '2500.00',
          'payment_date': '2026-10-20',
          'payment_method': 'upi',
          'reference_number': 'UPI123',
          'fee_account_id': 'acc-2026',
        },
        {'id': 'pay-legacy', 'receipt_number': null, 'amount': 100, 'payment_date': '2026-04-02', 'payment_method': 'cash'},
      ],
    };

void main() {
  group('Fee ledger uses the server figures', () {
    test('totals are the current-session account values, not recomputed from the payment list', () {
      final f = FeeSummaryModel.fromParentFees(feesJson(), studentId: 'st-1');
      expect(f.hasFeeAccount, isTrue);
      expect(f.netFee, 9000);
      expect(f.paidAmount, 2500); // the legacy 100 is not added on the device
      expect(f.outstandingAmount, 6500);
      expect(f.academicYearName, '2026-27');
      expect(f.status, 'partially_paid');
      expect(f.payments, hasLength(2));
    });

    test('no receipt number is invented for a payment that has none', () {
      final f = FeeSummaryModel.fromParentFees(feesJson(), studentId: 'st-1');
      expect(f.payments.last.receiptNo, isEmpty);
      expect(f.payments.first.receiptNo, 'RCT-2026-000001');
      expect(f.payments.first.amount, 2500.0);
      expect(f.payments.first.paymentMethod, 'UPI');
      expect(f.payments.first.remainingBalance, isNull); // only the receipt carries the server balance
    });

    test('no fee account -> hasFeeAccount false, zero totals, no status invented', () {
      final f = FeeSummaryModel.fromParentFees({'accounts': [], 'payments': []}, studentId: 'st-1');
      expect(f.hasFeeAccount, isFalse);
      expect(f.status, 'no_account');
      expect(f.outstandingAmount, 0);
    });

    test('fully paid account is PAID', () {
      final json = feesJson()..['current_account_id'] = 'acc-2025';
      final f = FeeSummaryModel.fromParentFees(json, studentId: 'st-1');
      expect(f.status, 'paid');
    });
  });

  group('Receipts come only from parent_get_receipt', () {
    late FakeRpc rpc;
    setUp(() => rpc = FakeRpc()..install());

    final receiptJson = {
      'payment_id': 'pay-1',
      'receipt_number': 'RCT-2026-000001',
      'amount': 2500,
      'payment_date': '2026-10-20',
      'payment_method': 'bank_transfer',
      'reference_number': 'NEFT-9',
      'recorded_at': '2026-10-20T05:30:00Z',
      'academic_year': {'name': '2026-27'},
      'net_fee': 9000,
      'paid_to_date': 2500,
      'balance_after_payment': 6500,
      'student': {'name': 'Asha K', 'admission_number': 'ADM-7', 'class_name': '8', 'section_name': 'A'},
      'school': {'name': 'Test School A', 'address': '1 Main Rd', 'phone': '', 'email': null, 'logo_url': null},
    };

    test('fetchReceipt sends only the payment id and parses the persisted values', () async {
      rpc.on('parent_get_receipt', (p) => receiptJson);
      final r = await FeeService.fetchReceipt(paymentId: 'pay-1');
      expect(rpc.calls.single.$2, {'p_payment_id': 'pay-1'});
      expect(r.receiptNumber, 'RCT-2026-000001');
      expect(r.amount, 2500);
      expect(r.balanceAfterPayment, 6500);
      expect(r.classLabel, '8-A');
      expect(r.paymentMethod, 'Bank Transfer');
      expect(r.schoolEmail, isEmpty); // null stays empty, never "null"
      final text = r.toPlainText(money: (v) => 'Rs$v', date: (d) => '${d.day}/${d.month}');
      expect(text, contains('RCT-2026-000001'));
      expect(text, contains('Balance after this payment: Rs6500.0'));
    });

    test('another family\'s payment is refused (42501 -> notAuthorized)', () async {
      rpc.on('parent_get_receipt', (_) => throw const PostgrestException(message: 'Receipt not found', code: '42501'));
      expect(
        () => FeeService.fetchReceipt(paymentId: 'pay-of-someone-else'),
        throwsA(isA<ParentDataException>().having((e) => e.kind, 'kind', ParentDataErrorKind.notAuthorized)),
      );
    });

    test('an empty server answer is an error, not a blank receipt', () async {
      rpc.on('parent_get_receipt', (_) => <String, dynamic>{});
      expect(() => FeeService.fetchReceipt(paymentId: 'pay-x'), throwsA(isA<ParentDataException>()));
    });

    test('fee summary failure propagates (never a fake zero ledger)', () async {
      rpc.on('parent_get_fees', (_) => throw const PostgrestException(message: 'boom', code: 'XX000'));
      expect(() => FeeService.fetchFeeSummaryForStudent(studentId: 'st-1'), throwsA(isA<ParentDataException>()));
    });
  });
}

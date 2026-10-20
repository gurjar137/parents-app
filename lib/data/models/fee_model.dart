double _toDouble(dynamic v) {
  if (v is num) return v.toDouble();
  return double.tryParse('${v ?? ''}') ?? 0.0;
}

String _str(dynamic v) => (v == null || v.toString() == 'null') ? '' : v.toString();

/// Display label for a stored payment method ('cash', 'upi', 'bank_transfer', ...).
String paymentMethodLabel(String raw) {
  final lower = raw.toLowerCase().trim();
  if (lower.isEmpty) return '';
  if (lower.contains('upi')) return 'UPI';
  if (lower.contains('bank') || lower.contains('transfer')) return 'Bank Transfer';
  if (lower.contains('card')) return 'Card';
  if (lower.contains('cheque') || lower.contains('check')) return 'Cheque';
  if (lower == 'cash') return 'Cash';
  if (lower == 'other') return 'Other';
  return raw;
}

/// One persisted fee payment (`fee_payments` row returned by parent_get_fees).
class FeePaymentModel {
  final String id;
  final String feeAccountId;
  final String studentId;
  final String receiptNo;
  final double amount;
  final DateTime? date;
  final String paymentMethod;
  final String transactionRef;
  final String notes;
  final String academicYearId;

  /// Balance after this payment, when the server returned it. The payment
  /// list does not compute balances on the device; the receipt does.
  final double? remainingBalance;

  const FeePaymentModel({
    required this.id,
    required this.feeAccountId,
    required this.studentId,
    required this.receiptNo,
    required this.amount,
    required this.date,
    required this.paymentMethod,
    required this.transactionRef,
    required this.notes,
    this.academicYearId = '',
    this.remainingBalance,
  });

  factory FeePaymentModel.fromMap(Map<String, dynamic> map) {
    return FeePaymentModel(
      id: _str(map['id']),
      feeAccountId: _str(map['fee_account_id']),
      studentId: _str(map['student_id']),
      receiptNo: _str(map['receipt_number']),
      amount: _toDouble(map['amount']),
      date: DateTime.tryParse(_str(map['payment_date']).isNotEmpty ? _str(map['payment_date']) : _str(map['recorded_at'])),
      paymentMethod: paymentMethodLabel(_str(map['payment_method'])),
      transactionRef: _str(map['reference_number']),
      notes: _str(map['notes']),
      academicYearId: _str(map['academic_year_id']),
      remainingBalance: map['balance_after_payment'] == null ? null : _toDouble(map['balance_after_payment']),
    );
  }
}

/// Fee position of one child: the current-session fee account as computed by
/// the database, plus every persisted payment.
class FeeSummaryModel {
  final String studentId;
  final String schoolId;
  final String academicYearId;
  final String academicYearName;
  final String feeAccountId;
  final double grossFee;
  final double discountAmount;
  final double waiverAmount;
  final double netFee;
  final double paidAmount;
  final double outstandingAmount;
  final DateTime? dueDate;
  final String status;
  final String notes;
  final List<FeePaymentModel> payments;
  final bool hasFeeAccount;

  const FeeSummaryModel({
    required this.studentId,
    this.schoolId = '',
    this.academicYearId = '',
    this.academicYearName = '',
    this.feeAccountId = '',
    required this.grossFee,
    required this.discountAmount,
    required this.waiverAmount,
    required this.netFee,
    required this.paidAmount,
    required this.outstandingAmount,
    this.dueDate,
    required this.status,
    this.notes = '',
    required this.payments,
    this.hasFeeAccount = true,
  });

  double get totalFee => netFee;
  double get pendingAmount => outstandingAmount;

  double get progressRatio {
    if (netFee <= 0) return hasFeeAccount ? 1.0 : 0.0;
    return (paidAmount / netFee).clamp(0.0, 1.0);
  }

  int get progressPercentage => (progressRatio * 100).round();

  bool get isOverdue {
    if (outstandingAmount <= 0 || dueDate == null) return false;
    final today = DateTime.now();
    return dueDate!.isBefore(DateTime(today.year, today.month, today.day));
  }

  factory FeeSummaryModel.empty(String studentId) => FeeSummaryModel(
        studentId: studentId,
        grossFee: 0,
        discountAmount: 0,
        waiverAmount: 0,
        netFee: 0,
        paidAmount: 0,
        outstandingAmount: 0,
        status: 'no_account',
        payments: const [],
        hasFeeAccount: false,
      );

  /// Parses `parent_get_fees`. Totals are the server's figures for the
  /// current-session account; nothing is recomputed from a partial list.
  factory FeeSummaryModel.fromParentFees(Map<String, dynamic> json, {required String studentId}) {
    final accounts = (json['accounts'] is List ? json['accounts'] as List : const [])
        .whereType<Map>()
        .map((m) => Map<String, dynamic>.from(m))
        .toList();
    final payments = (json['payments'] is List ? json['payments'] as List : const [])
        .whereType<Map>()
        .map((m) => FeePaymentModel.fromMap(Map<String, dynamic>.from(m)))
        .toList();
    final currentId = _str(json['current_account_id']);
    final current = accounts.firstWhere(
      (a) => _str(a['id']) == currentId,
      orElse: () => accounts.isNotEmpty ? accounts.first : const <String, dynamic>{},
    );
    if (current.isEmpty) {
      final empty = FeeSummaryModel.empty(studentId);
      return FeeSummaryModel(
        studentId: studentId,
        grossFee: 0,
        discountAmount: 0,
        waiverAmount: 0,
        netFee: 0,
        paidAmount: 0,
        outstandingAmount: 0,
        status: empty.status,
        payments: payments,
        hasFeeAccount: false,
      );
    }

    final ay = current['academic_year'] is Map ? Map<String, dynamic>.from(current['academic_year'] as Map) : const {};
    final net = _toDouble(current['net_fee']);
    final paid = _toDouble(current['paid_amount']);
    final balance = _toDouble(current['balance']);
    final due = DateTime.tryParse(_str(current['due_date']));
    final today = DateTime.now();
    String status;
    if (net > 0 && balance <= 0) {
      status = 'paid';
    } else if (due != null && balance > 0 && due.isBefore(DateTime(today.year, today.month, today.day))) {
      status = 'overdue';
    } else if (paid > 0 && balance > 0) {
      status = 'partially_paid';
    } else if (net <= 0) {
      status = 'no_fee';
    } else {
      status = 'due';
    }

    return FeeSummaryModel(
      studentId: studentId,
      schoolId: _str(current['school_id']),
      academicYearId: _str(current['academic_year_id']),
      academicYearName: _str(ay['name']),
      feeAccountId: _str(current['id']),
      grossFee: _toDouble(current['gross_fee']),
      discountAmount: _toDouble(current['discount_amount']),
      waiverAmount: _toDouble(current['waiver_amount']),
      netFee: net,
      paidAmount: paid,
      outstandingAmount: balance,
      dueDate: due,
      status: status,
      notes: _str(current['notes']),
      payments: payments,
    );
  }
}

/// A receipt exactly as stored by the school (`parent_get_receipt`).
class FeeReceiptModel {
  final String paymentId;
  final String receiptNumber;
  final double amount;
  final DateTime? paymentDate;
  final DateTime? recordedAt;
  final String paymentMethod;
  final String referenceNumber;
  final String notes;
  final String academicYear;
  final double? netFee;
  final double? paidToDate;
  final double? balanceAfterPayment;
  final String studentName;
  final String admissionNumber;
  final String className;
  final String sectionName;
  final String schoolName;
  final String schoolAddress;
  final String schoolPhone;
  final String schoolEmail;
  final String schoolLogoUrl;

  const FeeReceiptModel({
    required this.paymentId,
    required this.receiptNumber,
    required this.amount,
    this.paymentDate,
    this.recordedAt,
    this.paymentMethod = '',
    this.referenceNumber = '',
    this.notes = '',
    this.academicYear = '',
    this.netFee,
    this.paidToDate,
    this.balanceAfterPayment,
    this.studentName = '',
    this.admissionNumber = '',
    this.className = '',
    this.sectionName = '',
    this.schoolName = '',
    this.schoolAddress = '',
    this.schoolPhone = '',
    this.schoolEmail = '',
    this.schoolLogoUrl = '',
  });

  String get classLabel => [className, sectionName].where((p) => p.trim().isNotEmpty).join('-');

  factory FeeReceiptModel.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> obj(dynamic v) => v is Map ? Map<String, dynamic>.from(v) : const {};
    double? optDouble(dynamic v) => v == null ? null : _toDouble(v);
    final student = obj(json['student']);
    final school = obj(json['school']);
    final ay = obj(json['academic_year']);
    return FeeReceiptModel(
      paymentId: _str(json['payment_id']),
      receiptNumber: _str(json['receipt_number']),
      amount: _toDouble(json['amount']),
      paymentDate: DateTime.tryParse(_str(json['payment_date'])),
      recordedAt: DateTime.tryParse(_str(json['recorded_at']))?.toLocal(),
      paymentMethod: paymentMethodLabel(_str(json['payment_method'])),
      referenceNumber: _str(json['reference_number']),
      notes: _str(json['notes']),
      academicYear: _str(ay['name']),
      netFee: optDouble(json['net_fee']),
      paidToDate: optDouble(json['paid_to_date']),
      balanceAfterPayment: optDouble(json['balance_after_payment']),
      studentName: _str(student['name']),
      admissionNumber: _str(student['admission_number']),
      className: _str(student['class_name']),
      sectionName: _str(student['section_name']),
      schoolName: _str(school['name']),
      schoolAddress: _str(school['address']),
      schoolPhone: _str(school['phone']),
      schoolEmail: _str(school['email']),
      schoolLogoUrl: _str(school['logo_url']),
    );
  }

  /// Plain-text copy of the receipt for the clipboard.
  String toPlainText({required String Function(double) money, required String Function(DateTime) date}) {
    final lines = <String>[
      if (schoolName.isNotEmpty) schoolName,
      if (schoolAddress.isNotEmpty) schoolAddress,
      'Fee payment receipt',
      'Receipt number: $receiptNumber',
      if (paymentDate != null) 'Payment date: ${date(paymentDate!)}',
      if (studentName.isNotEmpty) 'Student: $studentName',
      if (admissionNumber.isNotEmpty) 'Admission number: $admissionNumber',
      if (classLabel.isNotEmpty) 'Class: $classLabel',
      if (academicYear.isNotEmpty) 'Session: $academicYear',
      'Amount paid: ${money(amount)}',
      if (paymentMethod.isNotEmpty) 'Payment method: $paymentMethod',
      if (referenceNumber.isNotEmpty) 'Reference: $referenceNumber',
      if (balanceAfterPayment != null) 'Balance after this payment: ${money(balanceAfterPayment!)}',
    ];
    return lines.join('\n');
  }
}

class FeePaymentModel {
  final String id;
  final String feeAccountId;
  final String studentId;
  final String receiptNo;
  final double amount;
  final DateTime date;
  final String paymentMethod;
  final String transactionRef;
  final String notes;
  final double remainingBalance;

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
    this.remainingBalance = 0.0,
  });

  factory FeePaymentModel.fromMap(Map<String, dynamic> map, {double balanceAfterPayment = 0.0}) {
    DateTime parseDate(dynamic val) {
      if (val is String) {
        return DateTime.tryParse(val) ?? DateTime.now();
      } else if (val is DateTime) {
        return val;
      }
      return DateTime.now();
    }

    final rawMethod = (map['payment_method'] ?? map['payment_mode'] ?? map['method'] ?? 'cash').toString();
    String formattedMethod = 'Cash';
    final lowerMethod = rawMethod.toLowerCase().trim();
    if (lowerMethod.contains('upi')) {
      formattedMethod = 'Online UPI';
    } else if (lowerMethod.contains('bank') || lowerMethod.contains('transfer')) {
      formattedMethod = 'Bank Transfer';
    } else if (lowerMethod.contains('card')) {
      formattedMethod = 'Debit / Credit Card';
    } else if (lowerMethod.contains('cheque')) {
      formattedMethod = 'Cheque';
    } else if (lowerMethod == 'cash') {
      formattedMethod = 'Cash';
    } else {
      formattedMethod = rawMethod;
    }

    return FeePaymentModel(
      id: (map['id'] ?? '').toString(),
      feeAccountId: (map['fee_account_id'] ?? '').toString(),
      studentId: (map['student_id'] ?? '').toString(),
      receiptNo: (map['receipt_number'] ?? map['receipt_no'] ?? map['receipt_id'] ?? 'REC-${DateTime.now().millisecondsSinceEpoch}').toString(),
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      date: parseDate(map['payment_date'] ?? map['created_at']),
      paymentMethod: formattedMethod,
      transactionRef: (map['reference_number'] ?? map['transaction_reference'] ?? map['transaction_id'] ?? '').toString(),
      notes: (map['notes'] ?? '').toString(),
      remainingBalance: balanceAfterPayment,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fee_account_id': feeAccountId,
      'student_id': studentId,
      'receipt_number': receiptNo,
      'amount': amount,
      'payment_date': date.toIso8601String().split('T').first,
      'payment_method': paymentMethod,
      'reference_number': transactionRef,
      'notes': notes,
      'remaining_balance': remainingBalance,
    };
  }
}

class FeeSummaryModel {
  final String studentId;
  final String schoolId;
  final String academicYearId;
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
    if (netFee <= 0) return 1.0;
    return (paidAmount / netFee).clamp(0.0, 1.0);
  }

  int get progressPercentage => (progressRatio * 100).round();

  bool get isOverdue {
    if (outstandingAmount <= 0) return false;
    if (dueDate == null) return false;
    return dueDate!.isBefore(DateTime.now());
  }

  factory FeeSummaryModel.fromData({
    required String studentId,
    required String schoolId,
    required String academicYearId,
    Map<String, dynamic>? accountMap,
    List<dynamic> paymentRows = const [],
  }) {
    if (accountMap == null && paymentRows.isEmpty) {
      return FeeSummaryModel(
        studentId: studentId,
        schoolId: schoolId,
        academicYearId: academicYearId,
        grossFee: 0.0,
        discountAmount: 0.0,
        waiverAmount: 0.0,
        netFee: 0.0,
        paidAmount: 0.0,
        outstandingAmount: 0.0,
        status: 'no_account',
        payments: const [],
        hasFeeAccount: false,
      );
    }

    final gross = (accountMap?['gross_fee'] as num?)?.toDouble() ?? 0.0;
    final discount = (accountMap?['discount_amount'] as num?)?.toDouble() ?? 0.0;
    final waiver = (accountMap?['waiver_amount'] as num?)?.toDouble() ?? 0.0;
    final calcNetFee = (gross - discount - waiver).clamp(0.0, double.infinity);

    DateTime? parsedDueDate;
    final rawDueDate = accountMap?['due_date'];
    if (rawDueDate is String && rawDueDate.isNotEmpty) {
      parsedDueDate = DateTime.tryParse(rawDueDate);
    } else if (rawDueDate is DateTime) {
      parsedDueDate = rawDueDate;
    }

    double paidSum = 0.0;
    for (final p in paymentRows) {
      if (p is Map) {
        paidSum += (p['amount'] as num?)?.toDouble() ?? 0.0;
      }
    }

    final calcOutstanding = (calcNetFee - paidSum).clamp(0.0, double.infinity);

    String calcStatus = 'due';
    if (calcOutstanding <= 0 && calcNetFee > 0) {
      calcStatus = 'paid';
    } else if (paidSum > 0 && calcOutstanding > 0) {
      calcStatus = 'partially_paid';
    } else if (parsedDueDate != null && parsedDueDate.isBefore(DateTime.now()) && calcOutstanding > 0) {
      calcStatus = 'overdue';
    } else {
      calcStatus = (accountMap?['status'] ?? 'due').toString().toLowerCase();
    }

    // Process payments and compute running remaining balance
    double runningBalance = calcNetFee;
    final List<FeePaymentModel> paymentModels = [];

    // Order payments chronologically ascending to calculate running balance, then reverse for display
    final sortedRows = List<dynamic>.from(paymentRows);
    sortedRows.sort((a, b) {
      final dateA = (a['payment_date'] ?? a['created_at'] ?? '').toString();
      final dateB = (b['payment_date'] ?? b['created_at'] ?? '').toString();
      return dateA.compareTo(dateB);
    });

    for (final p in sortedRows) {
      if (p is Map<String, dynamic>) {
        final amt = (p['amount'] as num?)?.toDouble() ?? 0.0;
        runningBalance = (runningBalance - amt).clamp(0.0, double.infinity);
        paymentModels.add(FeePaymentModel.fromMap(p, balanceAfterPayment: runningBalance));
      }
    }

    final displayPayments = paymentModels.reversed.toList();

    return FeeSummaryModel(
      studentId: studentId,
      schoolId: (accountMap?['school_id'] ?? schoolId).toString(),
      academicYearId: (accountMap?['academic_year_id'] ?? academicYearId).toString(),
      feeAccountId: (accountMap?['id'] ?? '').toString(),
      grossFee: gross,
      discountAmount: discount,
      waiverAmount: waiver,
      netFee: calcNetFee,
      paidAmount: paidSum,
      outstandingAmount: calcOutstanding,
      dueDate: parsedDueDate,
      status: calcStatus,
      notes: (accountMap?['notes'] ?? '').toString(),
      payments: displayPayments,
      hasFeeAccount: true,
    );
  }
}

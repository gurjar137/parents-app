import '../../data/models/fee_model.dart';
import 'parent_api.dart';

class FeeService {
  /// Current-session fee account and every persisted payment of the child.
  /// The server checks that the signed-in parent is linked to [studentId].
  /// Throws [ParentDataException] on failure (never returns a fake ₹0 ledger).
  static Future<FeeSummaryModel> fetchFeeSummaryForStudent({required String studentId}) async {
    if (studentId.isEmpty) return FeeSummaryModel.empty(studentId);
    final json = await ParentApi.instance.rpcObject('parent_get_fees', {'p_student_id': studentId});
    return FeeSummaryModel.fromParentFees(json, studentId: studentId);
  }

  /// Receipt of one persisted payment, built on the server from stored rows.
  static Future<FeeReceiptModel> fetchReceipt({required String paymentId}) async {
    final json = await ParentApi.instance.rpcObject('parent_get_receipt', {'p_payment_id': paymentId});
    final receipt = FeeReceiptModel.fromJson(json);
    if (receipt.receiptNumber.isEmpty && receipt.paymentId.isEmpty) {
      throw const ParentDataException(ParentDataErrorKind.server, 'The receipt could not be found.');
    }
    return receipt;
  }
}

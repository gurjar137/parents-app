import '../../data/models/student_model.dart';
import 'parent_api.dart';

enum LinkStatus {
  success,
  alreadyLinked,
  invalidCode,
  alreadyClaimed,
  otherSchool,
  notAParentAccount,
  accountInactive,
  rateLimited,
  unauthenticated,
  networkError,
  backendError,
}

class LinkChildResponse {
  final LinkStatus status;
  final StudentModel? student;
  final String? studentId;
  final String? errorMessage;
  final String? userMessage;

  const LinkChildResponse({
    required this.status,
    this.student,
    this.studentId,
    this.errorMessage,
    this.userMessage,
  });
}

class LinkChildService {
  /// Redeems the Parent Access Code the school issued for a child
  /// (`parent_claim_child`). The server verifies the code, the school and the
  /// signed-in account, creates or adopts the parent record and the link, and
  /// rate-limits attempts. Nothing is linked on the device.
  static Future<LinkChildResponse> claimChild({required String accessCode, String? relationship}) async {
    final code = accessCode.trim().toUpperCase();
    if (code.isEmpty) {
      return const LinkChildResponse(
        status: LinkStatus.invalidCode,
        errorMessage: 'Please enter the Parent Access Code from your school.',
      );
    }

    Map<String, dynamic> res;
    try {
      res = await ParentApi.instance.rpcObject('parent_claim_child', {
        'p_access_code': code,
        'p_relationship': relationship,
      });
    } on ParentDataException catch (e) {
      return LinkChildResponse(
        status: switch (e.kind) {
          ParentDataErrorKind.notAuthorized => LinkStatus.unauthenticated,
          ParentDataErrorKind.network => LinkStatus.networkError,
          _ => LinkStatus.backendError,
        },
        errorMessage: e.kind == ParentDataErrorKind.notAuthorized
            ? 'Your session has expired. Please sign in again.'
            : e.message,
      );
    }

    return responseFromClaimResult(res);
  }

  /// Maps the `parent_claim_child` result to a status and parent-facing text.
  static LinkChildResponse responseFromClaimResult(Map<String, dynamic> res) {
    final success = res['success'] == true;
    final reason = (res['reason'] ?? '').toString();
    if (success) {
      return LinkChildResponse(
        status: reason == 'ALREADY_LINKED' ? LinkStatus.alreadyLinked : LinkStatus.success,
        studentId: res['student_id']?.toString(),
        userMessage: reason == 'ALREADY_LINKED' ? 'This child is already linked to your account.' : 'Child linked successfully.',
      );
    }
    switch (reason) {
      case 'INVALID_CODE':
        return const LinkChildResponse(
          status: LinkStatus.invalidCode,
          errorMessage: 'This Parent Access Code is not valid. Please check it with the school office.',
        );
      case 'ALREADY_CLAIMED':
        return const LinkChildResponse(
          status: LinkStatus.alreadyClaimed,
          errorMessage: 'This code has already been used by another account. Ask the school to issue a new code.',
        );
      case 'OTHER_SCHOOL':
        return const LinkChildResponse(
          status: LinkStatus.otherSchool,
          errorMessage: 'This account is registered with a different school. Use a separate account for each school.',
        );
      case 'NOT_A_PARENT_ACCOUNT':
        return const LinkChildResponse(
          status: LinkStatus.notAParentAccount,
          errorMessage: 'This is a school staff account. Please sign in with a parent account to link a child.',
        );
      case 'ACCOUNT_INACTIVE':
        return const LinkChildResponse(
          status: LinkStatus.accountInactive,
          errorMessage: 'Your parent account is inactive. Please contact the school office.',
        );
      case 'RATE_LIMITED':
        return const LinkChildResponse(
          status: LinkStatus.rateLimited,
          errorMessage: 'Too many attempts. Please wait 15 minutes and try again.',
        );
      default:
        return const LinkChildResponse(
          status: LinkStatus.backendError,
          errorMessage: 'The code could not be verified. Please try again.',
        );
    }
  }
}

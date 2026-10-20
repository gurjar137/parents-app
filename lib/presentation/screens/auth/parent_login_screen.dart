import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../providers/parent_app_provider.dart';

/// Parents sign in with the Parent Access Code the school issued for their
/// child. The code is verified on the server (Edge Function
/// `parent-code-login`), which opens the family's own account; there is no
/// email or password for parents.
class ParentLoginScreen extends StatefulWidget {
  const ParentLoginScreen({super.key});

  @override
  State<ParentLoginScreen> createState() => _ParentLoginScreenState();
}

class _ParentLoginScreenState extends State<ParentLoginScreen> {
  final TextEditingController _codeController = TextEditingController();
  final FocusNode _codeFocus = FocusNode();
  String? _validationError;

  @override
  void dispose() {
    _codeController.dispose();
    _codeFocus.dispose();
    super.dispose();
  }

  Future<void> _handleLogin(ParentAppProvider provider) async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      setState(() => _validationError = 'Please enter the Parent Access Code provided by your school.');
      return;
    }
    setState(() => _validationError = null);

    final result = await provider.loginWithParentCode(code);
    if (!mounted) return;
    // On success the root widget (main.dart) switches to the dashboard from the
    // verified server session, so nothing is pushed here.
    if (result.status != AuthStatus.success) {
      _showErrorDialog(context, result);
    }
  }

  void _showErrorDialog(BuildContext context, AuthResponse result) {
    final String title;
    switch (result.status) {
      case AuthStatus.invalidCredentials:
        title = 'Invalid Parent Code';
        break;
      case AuthStatus.inactiveAccount:
        title = 'Parent Access Turned Off';
        break;
      case AuthStatus.networkError:
        title = 'Network Connection Error';
        break;
      default:
        title = 'Sign-in Not Completed';
    }
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.info_outline_rounded, color: AppColors.danger),
            const SizedBox(width: 10),
            Expanded(child: Text(title, style: AppTextStyles.headingSmall.copyWith(fontSize: 16))),
          ],
        ),
        content: Text(
          result.errorMessage ?? 'Sign-in failed. Please check the code and try again.',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandIndigo,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ParentAppProvider>(context);
    final branding = provider.branding;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLoading = provider.isAuthLoading;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 16),
              Container(
                width: 72,
                height: 72,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSubSurface : AppColors.infoBg,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.brandIndigo.withOpacity(0.3), width: 2),
                ),
                child: CircleAvatar(
                  backgroundColor: AppColors.brandIndigo,
                  backgroundImage: branding.logoUrl.isNotEmpty ? NetworkImage(branding.logoUrl) : null,
                  child: branding.logoUrl.isNotEmpty ? null : const Icon(Icons.school_rounded, color: Colors.white, size: 26),
                ),
              ),
              const SizedBox(height: 16),
              Text(branding.schoolName, style: AppTextStyles.headingMedium.copyWith(fontSize: 18), textAlign: TextAlign.center),
              const SizedBox(height: 36),

              Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Parent Login', style: AppTextStyles.headingLarge.copyWith(fontSize: 26)),
                    const SizedBox(height: 6),
                    Text('Enter the unique Parent Code provided by your school.', style: AppTextStyles.bodyMedium),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              if (_validationError != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.dangerBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.danger.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _validationError!,
                          style: AppTextStyles.bodySmall.copyWith(color: AppColors.danger, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              Align(
                alignment: Alignment.centerLeft,
                child: Text('Enter Parent Code', style: AppTextStyles.headingSmall.copyWith(fontSize: 14)),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _codeController,
                focusNode: _codeFocus,
                enabled: !isLoading,
                textCapitalization: TextCapitalization.characters,
                autocorrect: false,
                enableSuggestions: false,
                onChanged: (_) {
                  if (_validationError != null) setState(() => _validationError = null);
                },
                onSubmitted: (_) => _handleLogin(provider),
                style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold, letterSpacing: 1.2),
                decoration: InputDecoration(
                  hintText: 'e.g. SC-AB12-CD34',
                  hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted, letterSpacing: 0),
                  prefixIcon: const Icon(Icons.vpn_key_rounded, color: AppColors.brandIndigo),
                  filled: true,
                  fillColor: isDark ? AppColors.darkSubSurface : AppColors.subSurface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.brandIndigo, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: isLoading ? null : () => _handleLogin(provider),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandIndigo,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: isLoading
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                            ),
                            const SizedBox(width: 12),
                            Text('Verifying Parent Code...', style: AppTextStyles.button),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Login', style: AppTextStyles.button.copyWith(fontSize: 16)),
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward_rounded, size: 18),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 16),

              Wrap(
                alignment: WrapAlignment.center,
                children: [
                  Text('Don\'t have a Parent Code? ', style: AppTextStyles.caption),
                  GestureDetector(
                    onTap: () => showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        title: Text('Parent Code Help', style: AppTextStyles.headingSmall),
                        content: Text(
                          'Please contact your school office to collect your child\'s Parent Code. '
                          'Keep it private: anyone with the code can open your child\'s records.',
                          style: AppTextStyles.bodyMedium,
                        ),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
                        ],
                      ),
                    ),
                    child: Text(
                      'Contact School',
                      style: AppTextStyles.caption.copyWith(color: AppColors.brandBlue, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.shield_outlined, size: 14, color: AppColors.success),
                  const SizedBox(width: 6),
                  Text(
                    'Code verified securely by your school',
                    style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

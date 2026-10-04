import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../providers/parent_app_provider.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleReset() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email address.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final res = await AuthService.resetPassword(email: email);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (res.status == AuthStatus.success) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.mark_email_read_rounded, color: AppColors.success),
              const SizedBox(width: 10),
              Text('Check Your Email', style: AppTextStyles.headingSmall.copyWith(fontSize: 16)),
            ],
          ),
          content: Text(
            res.userMessage ?? 'Password reset link has been sent to your email. Please check your inbox.',
            style: AppTextStyles.bodyMedium,
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('Return to Sign In'),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res.errorMessage ?? 'Failed to send reset email. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ParentAppProvider>(context);
    final branding = provider.branding;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('Reset Password', style: AppTextStyles.headingSmall),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              Text('Forgot Password? 🔑', style: AppTextStyles.headingLarge.copyWith(fontSize: 24)),
              const SizedBox(height: 8),
              Text(
                'Enter the email address associated with your ${branding.schoolName} parent account and we will send you a link to reset your password.',
                style: AppTextStyles.bodyMedium,
              ),

              const SizedBox(height: 32),

              Text('Parent Email', style: AppTextStyles.headingSmall.copyWith(fontSize: 14)),
              const SizedBox(height: 8),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                enabled: !_isLoading,
                style: AppTextStyles.bodyLarge,
                decoration: InputDecoration(
                  hintText: 'Enter your email (e.g. parent@gmail.com)',
                  hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted),
                  prefixIcon: const Icon(Icons.email_outlined, color: AppColors.brandIndigo),
                  filled: true,
                  fillColor: isDark ? AppColors.darkSubSurface : AppColors.subSurface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.border),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleReset,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandIndigo,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isLoading
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            ),
                            SizedBox(width: 12),
                            Text('Sending Link...'),
                          ],
                        )
                      : Text('Send Reset Link', style: AppTextStyles.button.copyWith(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

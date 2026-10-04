import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../providers/parent_app_provider.dart';
import '../../main_navigation_screen.dart';

class ParentSignupScreen extends StatefulWidget {
  const ParentSignupScreen({super.key});

  @override
  State<ParentSignupScreen> createState() => _ParentSignupScreenState();
}

class _ParentSignupScreenState extends State<ParentSignupScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isLoading = false;
  String? _validationError;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup(ParentAppProvider provider) async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (name.isEmpty || email.isEmpty || phone.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      setState(() => _validationError = 'All fields are required.');
      return;
    }

    if (!email.contains('@') || !email.contains('.')) {
      setState(() => _validationError = 'Please enter a valid email address.');
      return;
    }

    if (password.length < 8) {
      setState(() => _validationError = 'Password must be at least 8 characters.');
      return;
    }

    if (password != confirmPassword) {
      setState(() => _validationError = 'Passwords do not match.');
      return;
    }

    setState(() {
      _validationError = null;
      _isLoading = true;
    });

    final res = await provider.signUpWithEmail(
      name: name,
      email: email,
      phone: phone,
      password: password,
      confirmPassword: confirmPassword,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (res.status == AuthStatus.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.userMessage ?? 'Account created successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
      );
    } else if (res.status == AuthStatus.emailConfirmationRequired) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.mark_email_read_rounded, color: AppColors.brandIndigo),
              const SizedBox(width: 10),
              Text('Verify Email', style: AppTextStyles.headingSmall.copyWith(fontSize: 16)),
            ],
          ),
          content: Text(
            res.userMessage ?? 'Account created successfully. Please verify your email before signing in.',
            style: AppTextStyles.bodyMedium,
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // close dialog
                Navigator.pop(context); // return to sign in screen
              },
              child: const Text('Back to Sign In'),
            ),
          ],
        ),
      );
    } else {
      setState(() {
        _validationError = res.errorMessage ?? 'Signup failed. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ParentAppProvider>(context);
    final branding = provider.branding;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('Create Parent Account', style: AppTextStyles.headingSmall),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Parent Registration 🎓', style: AppTextStyles.headingLarge.copyWith(fontSize: 24)),
              const SizedBox(height: 6),
              Text(
                'Register your parent account for ${branding.schoolName}.',
                style: AppTextStyles.bodyMedium,
              ),

              const SizedBox(height: 24),

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

              // Full Name
              _buildLabel('Full Name'),
              const SizedBox(height: 6),
              _buildInputField(
                controller: _nameController,
                hint: 'Enter your full name',
                icon: Icons.person_outline_rounded,
                isDark: isDark,
              ),

              const SizedBox(height: 16),

              // Email
              _buildLabel('Email Address'),
              const SizedBox(height: 6),
              _buildInputField(
                controller: _emailController,
                hint: 'Enter your email (e.g. parent@gmail.com)',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                isDark: isDark,
              ),

              const SizedBox(height: 16),

              // Mobile Number
              _buildLabel('Mobile Number'),
              const SizedBox(height: 6),
              _buildInputField(
                controller: _phoneController,
                hint: 'Enter 10-digit mobile number',
                icon: Icons.phone_android_rounded,
                keyboardType: TextInputType.phone,
                isDark: isDark,
              ),

              const SizedBox(height: 16),

              // Password
              _buildLabel('Password (Min. 8 characters)'),
              const SizedBox(height: 6),
              _buildInputField(
                controller: _passwordController,
                hint: 'Create password',
                icon: Icons.lock_outline_rounded,
                isPassword: true,
                isPasswordVisible: _isPasswordVisible,
                onToggleVisibility: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                isDark: isDark,
              ),

              const SizedBox(height: 16),

              // Confirm Password
              _buildLabel('Confirm Password'),
              const SizedBox(height: 6),
              _buildInputField(
                controller: _confirmPasswordController,
                hint: 'Re-enter password',
                icon: Icons.lock_clock_outlined,
                isPassword: true,
                isPasswordVisible: _isPasswordVisible,
                onToggleVisibility: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                isDark: isDark,
              ),

              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : () => _handleSignup(provider),
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
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                            ),
                            SizedBox(width: 12),
                            Text('Creating Account...'),
                          ],
                        )
                      : Text('Create Account', style: AppTextStyles.button.copyWith(fontSize: 16)),
                ),
              ),

              const SizedBox(height: 24),

              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Already have an account? ', style: AppTextStyles.bodyMedium),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Text(
                        'Sign In',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.brandIndigo,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(text, style: AppTextStyles.headingSmall.copyWith(fontSize: 14));
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool isPassword = false,
    bool isPasswordVisible = false,
    VoidCallback? onToggleVisibility,
    required bool isDark,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: isPassword && !isPasswordVisible,
      enabled: !_isLoading,
      style: AppTextStyles.bodyLarge,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted),
        prefixIcon: Icon(icon, color: AppColors.brandIndigo),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  isPasswordVisible ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                  color: AppColors.textMuted,
                ),
                onPressed: onToggleVisibility,
              )
            : null,
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
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../providers/parent_app_provider.dart';
import '../../main_navigation_screen.dart';
import 'forgot_password_screen.dart';
import 'parent_signup_screen.dart';

class ParentLoginScreen extends StatefulWidget {
  const ParentLoginScreen({super.key});

  @override
  State<ParentLoginScreen> createState() => _ParentLoginScreenState();
}

class _ParentLoginScreenState extends State<ParentLoginScreen> {
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _codeFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();

  bool _isParentCodeLoginMode = true;
  bool _isPasswordVisible = false;
  String? _validationError;

  @override
  void dispose() {
    _codeController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _codeFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _handleParentCodeLogin(ParentAppProvider provider) async {
    final rawCode = _codeController.text.trim();

    if (rawCode.isEmpty) {
      setState(() {
        _validationError = 'Please enter the unique Parent Code provided by your school.';
      });
      return;
    }

    setState(() {
      _validationError = null;
    });

    final result = await provider.loginWithParentCode(rawCode);

    if (!mounted) return;

    if (result.status == AuthStatus.success) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 250),
          pageBuilder: (context, animation, secondaryAnimation) => FadeTransition(
            opacity: animation,
            child: const MainNavigationScreen(),
          ),
        ),
      );
    } else {
      _showErrorDialog(context, result);
    }
  }

  Future<void> _handleEmailLogin(ParentAppProvider provider) async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _validationError = 'Please enter both your email address and password.';
      });
      return;
    }

    if (!email.contains('@') || !email.contains('.')) {
      setState(() {
        _validationError = 'Please enter a valid email address.';
      });
      return;
    }

    setState(() {
      _validationError = null;
    });

    final result = await provider.loginWithEmail(
      email: email,
      password: password,
    );

    if (!mounted) return;

    if (result.status == AuthStatus.success) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 250),
          pageBuilder: (context, animation, secondaryAnimation) => FadeTransition(
            opacity: animation,
            child: const MainNavigationScreen(),
          ),
        ),
      );
    } else {
      _showErrorDialog(context, result);
    }
  }

  void _showErrorDialog(BuildContext context, AuthResponse result) {
    String title;
    String message;
    String buttonText;

    switch (result.status) {
      case AuthStatus.invalidCredentials:
        title = 'Invalid Parent Code';
        message = result.errorMessage ?? 'Invalid Parent Code. Please check the code provided by your school.';
        buttonText = 'Try Again';
        break;
      case AuthStatus.emailConfirmationRequired:
        title = 'Email Verification Required';
        message = result.errorMessage ?? 'Please verify your email before signing in.';
        buttonText = 'OK';
        break;
      case AuthStatus.inactiveAccount:
        title = 'Parent Code Inactive';
        message = result.errorMessage ?? 'This Parent Code is inactive. Please contact your school administrator.';
        buttonText = 'Contact Admin';
        break;
      case AuthStatus.alreadyRegistered:
        title = 'Account Exists';
        message = result.errorMessage ?? 'An account with this code or email already exists.';
        buttonText = 'OK';
        break;
      case AuthStatus.networkError:
        title = 'Network Connection Error';
        message = 'Unable to verify Parent Code. Please check your internet connection.';
        buttonText = 'Retry';
        break;
      default:
        title = 'Authentication Notice';
        message = result.errorMessage ?? 'Authentication failed. Please check your details and try again.';
        buttonText = 'OK';
        break;
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
        content: Text(message, style: AppTextStyles.bodyMedium),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandIndigo,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(buttonText),
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

              // School Logo & Dynamic Branding Header
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
                  backgroundImage: NetworkImage(branding.logoUrl),
                  child: Text(
                    branding.schoolName[0],
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Text(
                branding.schoolName,
                style: AppTextStyles.headingMedium.copyWith(fontSize: 18),
                textAlign: TextAlign.center,
              ),

              Text(
                branding.affiliation,
                style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 36),

              // Welcome Titles
              Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Parent Login', style: AppTextStyles.headingLarge.copyWith(fontSize: 26)),
                    const SizedBox(height: 6),
                    Text(
                      _isParentCodeLoginMode
                          ? 'Enter your unique Parent Code provided by your school.'
                          : 'Sign in with your email and password.',
                      style: AppTextStyles.bodyMedium,
                    ),
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

              // ---------------------------------------------------------------
              // PRIMARY LOGIN MODE 1: PARENT CODE INPUT FIELD
              // ---------------------------------------------------------------
              if (_isParentCodeLoginMode) ...[
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
                  onChanged: (val) {
                    if (_validationError != null) setState(() => _validationError = null);
                  },
                  onSubmitted: (_) => _handleParentCodeLogin(provider),
                  style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold, letterSpacing: 1.2),
                  decoration: InputDecoration(
                    hintText: 'e.g. PRT-7K4M92',
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

                // Login Button for Parent Code
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : () => _handleParentCodeLogin(provider),
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

                Text(
                  'Enter the unique Parent Code provided by your school.',
                  style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 8),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Don\'t have a Parent Code? ', style: AppTextStyles.caption),
                    GestureDetector(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            title: Text('Parent Code Help', style: AppTextStyles.headingSmall),
                            content: Text(
                              'Please contact your school administrator or office desk to collect your unique Parent Code (e.g. PRT-7K4M92).',
                              style: AppTextStyles.bodyMedium,
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Close'),
                              ),
                            ],
                          ),
                        );
                      },
                      child: Text(
                        'Contact Administrator',
                        style: AppTextStyles.caption.copyWith(color: AppColors.brandBlue, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],

              // ---------------------------------------------------------------
              // SECONDARY LOGIN MODE 2: EMAIL & PASSWORD (TOGGLE)
              // ---------------------------------------------------------------
              if (!_isParentCodeLoginMode) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Parent Email', style: AppTextStyles.headingSmall.copyWith(fontSize: 14)),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _emailController,
                  focusNode: _emailFocus,
                  enabled: !isLoading,
                  keyboardType: TextInputType.emailAddress,
                  onChanged: (_) {
                    if (_validationError != null) setState(() => _validationError = null);
                  },
                  style: AppTextStyles.bodyLarge,
                  decoration: InputDecoration(
                    hintText: 'Enter your email address',
                    hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted),
                    prefixIcon: const Icon(Icons.email_outlined, color: AppColors.brandIndigo),
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

                const SizedBox(height: 18),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Password', style: AppTextStyles.headingSmall.copyWith(fontSize: 14)),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                        );
                      },
                      child: Text(
                        'Forgot Password?',
                        style: AppTextStyles.caption.copyWith(color: AppColors.brandBlue, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _passwordController,
                  focusNode: _passwordFocus,
                  enabled: !isLoading,
                  obscureText: !_isPasswordVisible,
                  onChanged: (_) {
                    if (_validationError != null) setState(() => _validationError = null);
                  },
                  onSubmitted: (_) => _handleEmailLogin(provider),
                  style: AppTextStyles.bodyLarge,
                  decoration: InputDecoration(
                    hintText: 'Enter your password',
                    hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted),
                    prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.brandIndigo),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                        color: AppColors.textMuted,
                      ),
                      onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                    ),
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
                    onPressed: isLoading ? null : () => _handleEmailLogin(provider),
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
                              Text('Signing In...', style: AppTextStyles.button),
                            ],
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Sign In', style: AppTextStyles.button.copyWith(fontSize: 16)),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward_rounded, size: 18),
                            ],
                          ),
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Toggle between Parent Code login & Email login
              TextButton(
                onPressed: () {
                  setState(() {
                    _isParentCodeLoginMode = !_isParentCodeLoginMode;
                    _validationError = null;
                  });
                },
                child: Text(
                  _isParentCodeLoginMode
                      ? 'Or Sign In with Email & Password'
                      : 'Or Sign In with Parent Code',
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.brandIndigo, fontWeight: FontWeight.bold),
                ),
              ),

              const SizedBox(height: 16),

              // Sign Up Link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Don\'t have a parent account? ', style: AppTextStyles.bodyMedium),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ParentSignupScreen()),
                      );
                    },
                    child: Text(
                      'Create Account',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.brandIndigo,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Security Footer Notice
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.shield_outlined, size: 14, color: AppColors.success),
                  const SizedBox(width: 6),
                  Text(
                    'Secured by Admin Parent Code & Supabase Auth',
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

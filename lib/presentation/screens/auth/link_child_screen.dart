import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/link_child_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../providers/parent_app_provider.dart';
import '../../main_navigation_screen.dart';

class LinkChildScreen extends StatefulWidget {
  final bool isFirstTimeSetup;

  const LinkChildScreen({
    super.key,
    this.isFirstTimeSetup = false,
  });

  @override
  State<LinkChildScreen> createState() => _LinkChildScreenState();
}

class _LinkChildScreenState extends State<LinkChildScreen> {
  final TextEditingController _codeController = TextEditingController();
  String _selectedRelationship = 'Parent';
  bool _isLoading = false;
  String? _errorMessage;

  final List<String> _relationshipOptions = [
    'Parent',
    'Father',
    'Mother',
    'Guardian',
  ];

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _handleLink(ParentAppProvider provider) async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your Student ID or Parent Linking Code.';
      });
      return;
    }

    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    final res = await provider.linkChildWithCode(
      codeOrStudentId: code,
      relationship: _selectedRelationship,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (res.status == LinkStatus.success && res.student != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.userMessage ?? 'Successfully linked ${res.student!.name}!'),
          backgroundColor: AppColors.success,
        ),
      );

      if (widget.isFirstTimeSetup) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
        );
      } else {
        Navigator.of(context).pop();
      }
    } else {
      setState(() {
        _errorMessage = res.errorMessage ?? 'Student ID or Linking Code not found.';
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
        title: Text(
          widget.isFirstTimeSetup ? 'Access Code Verification' : 'Verify & Link Child',
          style: AppTextStyles.headingSmall,
        ),
        elevation: 0,
        automaticallyImplyLeading: !widget.isFirstTimeSetup,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Access Code Verification 🎓', style: AppTextStyles.headingLarge.copyWith(fontSize: 24)),
              const SizedBox(height: 8),
              Text(
                'Enter the unique Parent Access Code provided by ${branding.schoolName} to securely link and access your child\'s records.',
                style: AppTextStyles.bodyMedium,
              ),

              const SizedBox(height: 28),

              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.dangerBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.danger.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.danger,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Parent Access Code Field
              Text('Enter Parent Access Code', style: AppTextStyles.headingSmall.copyWith(fontSize: 14)),
              const SizedBox(height: 8),
              TextField(
                controller: _codeController,
                textCapitalization: TextCapitalization.characters,
                enabled: !_isLoading,
                style: AppTextStyles.bodyLarge.copyWith(letterSpacing: 1.2, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  hintText: 'e.g. SC-Y8PV-UQ29',
                  hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted, letterSpacing: 0),
                  prefixIcon: const Icon(Icons.qr_code_rounded, color: AppColors.brandIndigo),
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

              const SizedBox(height: 20),

              // Relationship Dropdown
              Text('Your Relationship to Student', style: AppTextStyles.headingSmall.copyWith(fontSize: 14)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedRelationship,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.family_restroom_rounded, color: AppColors.brandIndigo),
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
                ),
                items: _relationshipOptions.map((rel) {
                  return DropdownMenuItem(
                    value: rel,
                    child: Text(rel, style: AppTextStyles.bodyMedium),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedRelationship = val);
                },
              ),

              const SizedBox(height: 32),

              // Link Child Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : () => _handleLink(provider),
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
                            Text('Verifying Student...'),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Link Child', style: AppTextStyles.button.copyWith(fontSize: 16)),
                            const SizedBox(width: 8),
                            const Icon(Icons.check_circle_outline_rounded, size: 20),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 28),

              // Helper Sample Code Box for Testing
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSubSurface : AppColors.infoBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.brandBlue.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.help_outline_rounded, color: AppColors.brandBlue, size: 20),
                        const SizedBox(width: 8),
                        Text('Need a linking code?', style: AppTextStyles.headingSmall.copyWith(fontSize: 14)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Your school admin provides a unique Parent Access Code (e.g. SC-Y8PV-UQ29). Enter it above to establish authorized student access.',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/link_child_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/parent_app_provider.dart';
import '../screens/auth/link_child_screen.dart';

class LinkChildModal extends StatefulWidget {
  const LinkChildModal({super.key});

  static void show(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LinkChildScreen()),
    );
  }

  @override
  State<LinkChildModal> createState() => _LinkChildModalState();
}

class _LinkChildModalState extends State<LinkChildModal> {
  final TextEditingController _codeController = TextEditingController();
  String? _errorMessage;
  bool _isValidating = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _validateAndLink(ParentAppProvider provider) async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a valid Parent Access Code';
      });
      return;
    }

    setState(() {
      _isValidating = true;
      _errorMessage = null;
    });

    final res = await provider.linkChildWithCode(codeOrStudentId: code);

    if (!mounted) return;
    setState(() => _isValidating = false);

    if (res.status == LinkStatus.success && res.student != null) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully linked ${res.student!.name}!'),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      setState(() {
        _errorMessage = res.errorMessage ?? 'Access Code not recognized. Please check with your school.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ParentAppProvider>(context, listen: false);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Link Another Child', style: AppTextStyles.headingMedium),
            const SizedBox(height: 4),
            Text(
              'Enter the unique Parent Access Code provided by your school administration.',
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: 16),

            // Code Input Field
            TextField(
              controller: _codeController,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                labelText: 'Parent Access Code',
                hintText: 'e.g. SC-Y8PV-UQ29',
                errorText: _errorMessage,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isValidating ? null : () => _validateAndLink(provider),
                child: _isValidating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Verify & Link Child'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

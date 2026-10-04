import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/ptm_access_code.dart';
import '../../providers/parent_app_provider.dart';

class LinkChildModal extends StatefulWidget {
  const LinkChildModal({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const LinkChildModal(),
    );
  }

  @override
  State<LinkChildModal> createState() => _LinkChildModalState();
}

class _LinkChildModalState extends State<LinkChildModal> {
  final TextEditingController _codeController = TextEditingController(text: 'SC-7K4P-92MX');
  PtmAccessCodeModel? _previewModel;
  String? _errorMessage;
  bool _isValidating = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _validateCode(ParentAppProvider provider) {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a valid Parent Access Code';
        _previewModel = null;
      });
      return;
    }

    setState(() {
      _isValidating = true;
      _errorMessage = null;
    });

    Future.delayed(const Duration(milliseconds: 400), () {
      final match = provider.validatePtmCode(code);
      setState(() {
        _isValidating = false;
        if (match != null) {
          _previewModel = match;
          _errorMessage = null;
        } else {
          _previewModel = null;
          _errorMessage = 'Invalid or expired Parent Access Code. Please check code given by school during PTM.';
        }
      });
    });
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
              'Enter the unique Parent Access Code provided by your school administration during PTM.',
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: 16),

            // Code Input Field
            TextField(
              controller: _codeController,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                labelText: 'Parent Access Code',
                hintText: 'e.g. SC-7K4P-92MX',
                errorText: _errorMessage,
                suffixIcon: IconButton(
                  icon: const Icon(Icons.qr_code_scanner_rounded, color: AppColors.brandIndigo),
                  onPressed: () {
                    _codeController.text = 'SC-7K4P-92MX';
                    _validateCode(provider);
                  },
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),

            const SizedBox(height: 12),

            if (_previewModel == null)
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isValidating ? null : () => _validateCode(provider),
                  child: _isValidating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Validate Access Code'),
                ),
              ),

            // Limited Child Preview Box (Security Boundary compliant)
            if (_previewModel != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.infoBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.brandBlue),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundImage: NetworkImage(_previewModel!.studentPreview.avatarUrl),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_previewModel!.studentPreview.name, style: AppTextStyles.headingSmall.copyWith(fontSize: 16)),
                              Text(
                                '${_previewModel!.studentPreview.grade} (${_previewModel!.studentPreview.className})',
                                style: AppTextStyles.bodySmall,
                              ),
                              Text(_previewModel!.schoolName, style: AppTextStyles.caption.copyWith(color: AppColors.brandBlue, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 10),
                    Text(
                      'Is this your child?',
                      style: AppTextStyles.headingSmall.copyWith(fontSize: 14),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _previewModel = null;
                        });
                      },
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        final success = provider.confirmLinkChild(_previewModel!);
                        Navigator.pop(context);
                        if (success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Successfully linked ${_previewModel!.studentPreview.name}!'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Student is already linked to your parent account.'),
                              backgroundColor: AppColors.warning,
                            ),
                          );
                        }
                      },
                      child: const Text('Confirm & Link'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

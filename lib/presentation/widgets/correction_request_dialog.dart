import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/parent_app_provider.dart';

class CorrectionRequestDialog extends StatefulWidget {
  final String studentName;

  const CorrectionRequestDialog({super.key, required this.studentName});

  static void show(BuildContext context, String studentName) {
    showDialog(
      context: context,
      builder: (context) => CorrectionRequestDialog(studentName: studentName),
    );
  }

  @override
  State<CorrectionRequestDialog> createState() => _CorrectionRequestDialogState();
}

class _CorrectionRequestDialogState extends State<CorrectionRequestDialog> {
  final _formKey = GlobalKey<FormState>();
  String _selectedField = 'Date of Birth';
  final TextEditingController _currentValueController = TextEditingController();
  final TextEditingController _requestedValueController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();

  final List<String> _fields = [
    'Date of Birth',
    'Spelling of Student Name',
    'Blood Group',
    'Residential Address',
    'Emergency Mobile Number',
  ];

  @override
  void dispose() {
    _currentValueController.dispose();
    _requestedValueController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ParentAppProvider>(context, listen: false);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Request Info Correction', style: AppTextStyles.headingSmall),
          const SizedBox(height: 2),
          Text(
            'Official student data for ${widget.studentName} is managed by Admin. Submit a correction request for review.',
            style: AppTextStyles.caption,
          ),
        ],
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: _selectedField,
                decoration: InputDecoration(
                  labelText: 'Field to Correct',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: _fields.map((field) {
                  return DropdownMenuItem(value: field, child: Text(field));
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedField = val);
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _currentValueController,
                decoration: InputDecoration(
                  labelText: 'Current Recorded Value',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Please enter current value' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _requestedValueController,
                decoration: InputDecoration(
                  labelText: 'Requested Correct Value',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Please enter requested correct value' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _reasonController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Reason for Request',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Please provide a brief reason' : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final sent = provider.submitCorrectionRequest(
                fieldName: _selectedField,
                currentValue: _currentValueController.text.trim(),
                requestedValue: _requestedValueController.text.trim(),
                reason: _reasonController.text.trim(),
              );
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(sent
                      ? 'Correction request sent to the school.'
                      : 'Correction requests cannot be sent from the app yet. Please contact the school office.'),
                  backgroundColor: sent ? AppColors.brandIndigo : AppColors.warning,
                ),
              );
            }
          },
          child: const Text('Submit Request'),
        ),
      ],
    );
  }
}

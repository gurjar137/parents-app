import 'package:flutter/material.dart';
import '../../core/theme/app_text_styles.dart';

class StatRow extends StatelessWidget {
  final String label;
  final String value;
  final TextStyle? valueStyle;

  const StatRow({
    super.key,
    required this.label,
    required this.value,
    this.valueStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodyMedium),
          Text(
            value,
            style: valueStyle ?? AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

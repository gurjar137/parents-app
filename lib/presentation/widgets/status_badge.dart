import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

enum StatusType { success, warning, danger, info, holiday }

class StatusBadge extends StatelessWidget {
  final String label;
  final StatusType type;

  const StatusBadge({
    super.key,
    required this.label,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;

    switch (type) {
      case StatusType.success:
        bg = AppColors.successBg;
        fg = AppColors.success;
        break;
      case StatusType.warning:
        bg = AppColors.warningBg;
        fg = AppColors.warning;
        break;
      case StatusType.danger:
        bg = AppColors.dangerBg;
        fg = AppColors.danger;
        break;
      case StatusType.info:
        bg = AppColors.infoBg;
        fg = AppColors.info;
        break;
      case StatusType.holiday:
        bg = AppColors.holidayBg;
        fg = AppColors.holiday;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          label,
          style: TextStyle(
            color: fg,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}

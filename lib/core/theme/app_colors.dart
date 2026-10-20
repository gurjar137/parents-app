import 'package:flutter/material.dart';

class AppColors {
  // Primary Palette - Deep Slate Indigo & Navy Trust
  static const Color primary = Color(0xFF10182D); // Deep Navy (#10182D)
  static const Color primaryAccent = Color(0xFF1E293B); // Slate 800
  static const Color brandBlue = Color(0xFF2563EB); // Royal Blue
  static const Color brandIndigo = Color(0xFF4F46E5); // Indigo (#4F46E5)

  // Light Backgrounds & Surface
  static const Color background = Color(0xFFF5F7FB); // Premium Light (#F5F7FB)
  static const Color surface = Color(0xFFFFFFFF);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color subSurface = Color(0xFFF1F5F9); // Slate 100

  // Dark Theme Surfaces
  static const Color darkBackground = Color(0xFF0F172A); // Slate 900
  static const Color darkSurface = Color(0xFF1E293B); // Slate 800
  static const Color darkCardBg = Color(0xFF1E293B);
  static const Color darkSubSurface = Color(0xFF334155); // Slate 700
  static const Color darkBorder = Color(0xFF334155);
  static const Color darkBorderLight = Color(0xFF1E293B);

  // Text Colors
  static const Color textPrimary = Color(0xFF10182D); // Deep Navy Slate
  static const Color textSecondary = Color(0xFF64748B); // Slate 500
  static const Color textMuted = Color(0xFF94A3B8); // Slate 400

  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFFCBD5E1);
  static const Color darkTextMuted = Color(0xFF94A3B8);

  // Status & Module Accent Colors
  static const Color success = Color(0xFF10B981); // Emerald Mint
  static const Color successBg = Color(0xFFECFDF5);
  static const Color darkSuccessBg = Color(0xFF064E3B);
  
  static const Color warning = Color(0xFFF59E0B); // Amber
  static const Color warningBg = Color(0xFFFFFBEB);
  static const Color darkWarningBg = Color(0xFF78350F);
  
  static const Color danger = Color(0xFFEF4444); // Rose/Red
  static const Color dangerBg = Color(0xFFFEF2F2);
  static const Color darkDangerBg = Color(0xFF7F1D1D);
  
  static const Color info = Color(0xFF3B82F6); // Blue
  static const Color infoBg = Color(0xFFEFF6FF);
  static const Color darkInfoBg = Color(0xFF1E3A8A);

  static const Color holiday = Color(0xFF8B5CF6); // Violet/Purple
  static const Color holidayBg = Color(0xFFF5F3FF);
  static const Color darkHolidayBg = Color(0xFF4C1D95);

  static const Color accent = Color(0xFF8B5CF6); // Purple/Violet accent
  static const Color accentBg = Color(0xFFF5F3FF);
  static const Color darkAccentBg = Color(0xFF4C1D95);

  static const Color primaryBg = Color(0xFFEEF2FF); // Indigo tint bg
  static const Color darkPrimaryBg = Color(0xFF1E1B4B);

  static const Color cyan = Color(0xFF06B6D4); // Cyan
  static const Color cyanBg = Color(0xFFECFEFF);
  static const Color darkCyanBg = Color(0xFF164E63);

  static const Color teal = Color(0xFF0D9488); // Teal
  static const Color tealBg = Color(0xFFF0FDFA);
  static const Color darkTealBg = Color(0xFF134E4A);

  static const Color rose = Color(0xFFE11D48); // Rose
  static const Color roseBg = Color(0xFFFFF1F2);
  static const Color darkRoseBg = Color(0xFF881337);

  // Borders & Dividers
  static const Color border = Color(0xFFE2E8F0); // Slate 200
  static const Color borderLight = Color(0xFFF1F5F9);

  // Layered Soft Shadows
  static const Color shadow = Color(0x0A0F172A);
  static const Color shadowStrong = Color(0x1A0F172A);

  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color(0x080F172A),
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
    BoxShadow(
      color: Color(0x040F172A),
      blurRadius: 4,
      offset: Offset(0, 1),
    ),
  ];

  static const List<BoxShadow> heroShadow = [
    BoxShadow(
      color: Color(0x3010182D),
      blurRadius: 20,
      offset: Offset(0, 8),
    ),
  ];
}

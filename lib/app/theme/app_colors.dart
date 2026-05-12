import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary
  static const Color primary = Color(0xFF3D5AFE);
  static const Color primaryLight = Color(0xFF8187FF);
  static const Color primaryDark = Color(0xFF0031CA);
  static const Color primaryContainer = Color(0xFFE8EAFF);

  // Secondary
  static const Color secondary = Color(0xFF00BCD4);
  static const Color secondaryLight = Color(0xFF62EFFF);
  static const Color secondaryDark = Color(0xFF008BA3);

  // Accent
  static const Color accent = Color(0xFFFF6B6B);
  static const Color accentGreen = Color(0xFF00C896);
  static const Color accentOrange = Color(0xFFFF9800);
  static const Color accentPurple = Color(0xFF7C4DFF);

  // Neutral
  static const Color white = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFF5F7FA);
  static const Color surfaceVariant = Color(0xFFEEF0F5);
  static const Color divider = Color(0xFFE4E7EC);

  // Text
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textHint = Color(0xFFB0B8C9);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Status
  static const Color success = Color(0xFF00C896);
  static const Color warning = Color(0xFFFFB020);
  static const Color error = Color(0xFFEF5350);
  static const Color info = Color(0xFF2196F3);

  // Background
  static const Color scaffoldBackground = Color(0xFFF5F7FA);
  static const Color cardBackground = Color(0xFFFFFFFF);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF3D5AFE), Color(0xFF7C4DFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF3D5AFE), Color(0xFF6979F8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Category Colors
  static const List<Color> categoryColors = [
    Color(0xFF3D5AFE),
    Color(0xFF00BCD4),
    Color(0xFF7C4DFF),
    Color(0xFFFF6B6B),
    Color(0xFF00C896),
    Color(0xFFFF9800),
    Color(0xFFE91E63),
    Color(0xFF009688),
  ];
}

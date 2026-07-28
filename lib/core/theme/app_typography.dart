import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

class AppTypography {
  AppTypography._();

  static TextTheme get textTheme => _buildTextTheme(
    primary: AppColors.textPrimary,
    secondary: AppColors.textSecondary,
  );

  static TextTheme get darkTextTheme => _buildTextTheme(
    primary: AppColors.darkTextPrimary,
    secondary: AppColors.darkTextSecondary,
  );

  static TextTheme _buildTextTheme({
    required Color primary,
    required Color secondary,
  }) {
    final base = GoogleFonts.notoSansJpTextTheme();

    return base.copyWith(
      displayLarge: base.displayLarge?.copyWith(
        color: primary,
        fontWeight: FontWeight.w600,
        height: 1.15,
      ),
      displayMedium: base.displayMedium?.copyWith(
        color: primary,
        fontWeight: FontWeight.w600,
        height: 1.15,
      ),
      displaySmall: base.displaySmall?.copyWith(
        color: primary,
        fontWeight: FontWeight.w600,
        height: 1.15,
      ),
      headlineLarge: base.headlineLarge?.copyWith(
        color: primary,
        fontWeight: FontWeight.w600,
        height: 1.2,
      ),
      headlineMedium: base.headlineMedium?.copyWith(
        color: primary,
        fontWeight: FontWeight.w600,
        height: 1.2,
      ),
      headlineSmall: base.headlineSmall?.copyWith(
        color: primary,
        fontWeight: FontWeight.w600,
        height: 1.2,
      ),
      titleLarge: base.titleLarge?.copyWith(
        color: primary,
        fontWeight: FontWeight.w600,
        height: 1.25,
      ),
      titleMedium: base.titleMedium?.copyWith(
        color: primary,
        fontWeight: FontWeight.w600,
        height: 1.25,
      ),
      titleSmall: base.titleSmall?.copyWith(
        color: primary,
        fontWeight: FontWeight.w600,
        height: 1.25,
      ),
      bodyLarge: base.bodyLarge?.copyWith(color: primary, height: 1.5),
      bodyMedium: base.bodyMedium?.copyWith(color: primary, height: 1.5),
      bodySmall: base.bodySmall?.copyWith(color: secondary, height: 1.45),
      labelLarge: base.labelLarge?.copyWith(
        color: primary,
        fontWeight: FontWeight.w600,
        height: 1.25,
      ),
      labelMedium: base.labelMedium?.copyWith(
        color: secondary,
        fontWeight: FontWeight.w500,
        height: 1.25,
      ),
      labelSmall: base.labelSmall?.copyWith(
        color: secondary,
        fontWeight: FontWeight.w500,
        height: 1.25,
      ),
    );
  }

  static TextStyle get display => textTheme.displaySmall!;
  static TextStyle get headline => textTheme.headlineMedium!;
  static TextStyle get title => textTheme.titleLarge!;
  static TextStyle get body => textTheme.bodyMedium!;
  static TextStyle get label => textTheme.labelLarge!;
  static TextStyle get caption => textTheme.bodySmall!;
}

import 'package:flutter/material.dart';

class MobileTokens {
  const MobileTokens._();

  static const background = Color(0xFFFCFBFF);
  static const surface = Color(0xFFFFFFFF);
  static const ink = Color(0xFF080C1B);
  static const muted = Color(0xFF6F7488);
  static const faint = Color(0xFFF7F3FF);
  static const border = Color(0xFFE6E1F3);
  static const primary = Color(0xFF5B2DE1);
  static const primaryEnd = Color(0xFF8B5CF6);
  static const primarySoft = Color(0xFFF0EAFE);
  static const success = Color(0xFF23B26B);
  static const warning = Color(0xFFF97316);
  static const danger = Color(0xFFE51B2A);

  static const radiusSmall = 10.0;
  static const radius = 14.0;
  static const radiusLarge = 18.0;
  static const minTouch = 44.0;

  static const gradient = LinearGradient(
    colors: [primary, primaryEnd],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const softShadow = [
    BoxShadow(
      color: Color(0x14000000),
      blurRadius: 18,
      offset: Offset(0, 8),
    ),
  ];
}

ThemeData buildMobileTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: MobileTokens.background,
    colorScheme: const ColorScheme.light(
      primary: MobileTokens.primary,
      secondary: Color(0xFF2563EB),
      tertiary: Color(0xFF14B8A6),
      surface: MobileTokens.surface,
      error: MobileTokens.danger,
      onPrimary: Colors.white,
      onSurface: MobileTokens.ink,
      onSurfaceVariant: MobileTokens.muted,
      outline: MobileTokens.border,
    ),
    textTheme: const TextTheme(
      headlineSmall: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        height: 1.3,
        color: MobileTokens.ink,
      ),
      titleLarge: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        height: 1.3,
        color: MobileTokens.ink,
      ),
      titleMedium: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        height: 1.3,
        color: MobileTokens.ink,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.4,
        color: MobileTokens.ink,
      ),
      bodyMedium: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        height: 1.35,
        color: MobileTokens.ink,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.3,
        color: MobileTokens.muted,
      ),
      labelLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        height: 1.25,
      ),
      labelMedium: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        height: 1.25,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      hintStyle: const TextStyle(color: Color(0xFF8E93A6), fontSize: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(MobileTokens.radius),
        borderSide: const BorderSide(color: MobileTokens.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(MobileTokens.radius),
        borderSide: const BorderSide(color: MobileTokens.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(MobileTokens.radius),
        borderSide: const BorderSide(color: MobileTokens.primary, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(MobileTokens.radius),
        borderSide: const BorderSide(color: MobileTokens.danger),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(MobileTokens.radius),
        borderSide: const BorderSide(color: MobileTokens.danger, width: 1.4),
      ),
    ),
  );
}

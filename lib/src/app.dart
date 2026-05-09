import 'package:flutter/material.dart';

import 'features/home_page.dart';

class AIMemoApp extends StatelessWidget {
  const AIMemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF2F6F5E);
    const background = Color(0xFFF4F5F2);
    const surface = Color(0xFFFFFFFF);
    const border = Color(0xFFDDE2DC);

    return MaterialApp(
      title: 'AIMemo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: accent,
          brightness: Brightness.light,
          surface: surface,
        ),
        scaffoldBackgroundColor: background,
        dividerTheme: const DividerThemeData(color: border, thickness: 1),
        textTheme: const TextTheme(
          headlineSmall: TextStyle(fontWeight: FontWeight.w700, fontSize: 24),
          titleLarge: TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
          titleMedium: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          titleSmall: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          bodyMedium: TextStyle(fontSize: 14, height: 1.35),
          bodySmall: TextStyle(fontSize: 12, height: 1.25),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFFAFBF9),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(7),
            borderSide: const BorderSide(color: border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(7),
            borderSide: const BorderSide(color: border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(7),
            borderSide: const BorderSide(color: accent, width: 1.4),
          ),
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: const Color(0xFFF2F4F1),
          selectedColor: const Color(0xFFDCE9E3),
          side: const BorderSide(color: border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
          labelStyle: const TextStyle(fontSize: 12),
          padding: const EdgeInsets.symmetric(horizontal: 6),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: accent,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(42),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(7),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF2E3430),
            side: const BorderSide(color: border),
            minimumSize: const Size.fromHeight(42),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(7),
            ),
          ),
        ),
        tabBarTheme: const TabBarThemeData(
          labelColor: accent,
          unselectedLabelColor: Color(0xFF6A716C),
          indicatorColor: accent,
          dividerColor: border,
        ),
      ),
      home: const HomePage(),
    );
  }
}

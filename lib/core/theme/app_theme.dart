import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryGreen,
          primary: primaryGreen,
          secondary: amber,
          error: errorRed,
          surface: background,
        ),
        scaffoldBackgroundColor: background,
        cardColor: cardWhite,
        appBarTheme: const AppBarTheme(
          backgroundColor: cardWhite,
          foregroundColor: textPrimary,
          elevation: 0,
          scrolledUnderElevation: 1,
          centerTitle: false,
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
          ),
          titleTextStyle: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryGreen,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 52),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
            elevation: 0,
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: primaryGreen,
            side: const BorderSide(color: primaryGreen, width: 1.5),
            minimumSize: const Size(double.infinity, 52),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: cardWhite,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: primaryGreen, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: errorRed),
          ),
          hintStyle: const TextStyle(color: textHint, fontSize: 14),
        ),
        cardTheme: CardThemeData(
          color: cardWhite,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFE5E7EB), width: 1),
          ),
          margin: EdgeInsets.zero,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: cardWhite,
          selectedItemColor: primaryGreen,
          unselectedItemColor: textHint,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          elevation: 8,
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        dividerTheme: const DividerThemeData(
          color: Color(0xFFE5E7EB),
          thickness: 1,
          space: 1,
        ),
        fontFamily: 'Roboto',
      );
}

import 'package:flutter/material.dart';
import 'package:by_hex/constants/app_colors.dart';

class HexEditorTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.dark(
        primary: AppColors.mediumPurple,
        secondary: AppColors.lightPurple,
        background: AppColors.darkGray,
        surface: AppColors.darkGrayLight,
        onPrimary: Colors.white,
        onSecondary: Colors.black,
        onBackground: Colors.white,
        onSurface: Colors.white,
      ),
      scaffoldBackgroundColor: AppColors.darkGray,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.darkGrayLight,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: AppColors.darkGrayLight,
      ),
      cardTheme: const CardTheme(
        color: AppColors.darkGrayLight,
        elevation: 2,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: AppColors.primaryText),
        bodyMedium: TextStyle(color: AppColors.primaryText),
        titleLarge: TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.bold),
        titleMedium: TextStyle(color: AppColors.primaryText),
        titleSmall: TextStyle(color: AppColors.secondaryText),
      ),
      buttonTheme: ButtonThemeData(
        buttonColor: AppColors.mediumPurple,
        textTheme: ButtonTextTheme.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.mediumPurple,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.lightPurple,
        ),
      ),
      iconTheme: const IconThemeData(
        color: AppColors.lightPurple,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkGray,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.mediumPurple),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.mediumPurple),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.deepPurple, width: 2),
        ),
        labelStyle: const TextStyle(color: AppColors.secondaryText),
        hintStyle: const TextStyle(color: AppColors.secondaryText),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'app_colors.dart';

ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  primaryColor: AppColors.primaryAction, // Color primario de la marca
  scaffoldBackgroundColor: AppColors.backgroundLight, // Fondo general claro
  cardColor: AppColors.surfaceLight, // Color de las tarjetas
  // Configura ColorScheme usando tus colores
  colorScheme: ColorScheme.light(
    primary: AppColors.primaryAction,
    secondary: AppColors.secondaryAction,
    surface: AppColors.surfaceLight,
    error: AppColors.errorColor,
    onPrimary: AppColors.white,
    onSecondary: AppColors.almostBlack, // O un color que contraste bien
    onSurface: AppColors.textLight,
    onError: AppColors.white,
  ),
  // Configura TextTheme usando tus colores y pesos
  textTheme: const TextTheme(
    // Usa const si los estilos son constantes
    displayLarge: TextStyle(
      color: AppColors.textLight,
      fontWeight: FontWeight.bold,
      fontSize: 34.0,
    ),
    displayMedium: TextStyle(
      color: AppColors.textLight,
      fontWeight: FontWeight.bold,
      fontSize: 28.0,
    ),
    headlineMedium: TextStyle(
      color: AppColors.textLight,
      fontWeight: FontWeight.w600,
      fontSize: 24.0,
    ),
    titleLarge: TextStyle(
      color: AppColors.textLight,
      fontWeight: FontWeight.w600,
      fontSize: 22.0,
    ),
    bodyLarge: TextStyle(color: AppColors.textLight, fontSize: 16.0),
    bodyMedium: TextStyle(color: AppColors.textSecondaryLight, fontSize: 14.0),
    labelLarge: TextStyle(
      color: AppColors.primaryAction,
      fontWeight: FontWeight.bold,
      fontSize: 14.0,
    ),
  ),
  // Configura temas de widgets (botones, campos de texto, app bar, etc.)
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primaryAction,
      foregroundColor: AppColors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: AppColors.primaryAction,
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8.0),
      borderSide: BorderSide(color: AppColors.mediumGrey),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8.0),
      borderSide: BorderSide(color: AppColors.primaryAction, width: 2.0),
    ),
    labelStyle: TextStyle(color: AppColors.textSecondaryLight),
    hintStyle: TextStyle(color: AppColors.mediumGrey), // Para placeholder
    contentPadding: const EdgeInsets.symmetric(
      horizontal: 16.0,
      vertical: 12.0,
    ), // Relleno estándar
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.primaryAction, // Color de la AppBar
    foregroundColor: AppColors.white, // Color del texto/iconos en la AppBar
    titleTextStyle: TextStyle(
      color: AppColors.white,
      fontSize: 20,
      fontWeight: FontWeight.bold,
    ),
  ),
  cardTheme: CardThemeData(
    elevation: 2.0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
    margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
    color: AppColors.surfaceLight,
  ),
);

ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  primaryColor: AppColors.primaryAction,
  scaffoldBackgroundColor: AppColors.backgroundDark,
  cardColor: AppColors.surfaceDark,
  colorScheme: ColorScheme.dark(
    primary: AppColors.primaryAction,
    secondary: AppColors.secondaryAction,
    surface: AppColors.surfaceDark,
    error: AppColors.errorColor,
    onPrimary: AppColors.white,
    onSecondary: AppColors.white,
    onSurface: AppColors.textDark,
    onError: AppColors.white,
  ),
  textTheme: const TextTheme(
    displayLarge: TextStyle(
      color: AppColors.textDark,
      fontWeight: FontWeight.bold,
      fontSize: 34.0,
    ),
    displayMedium: TextStyle(
      color: AppColors.textDark,
      fontWeight: FontWeight.bold,
      fontSize: 28.0,
    ),
    headlineMedium: TextStyle(
      color: AppColors.textDark,
      fontWeight: FontWeight.w600,
      fontSize: 24.0,
    ),
    titleLarge: TextStyle(
      color: AppColors.textDark,
      fontWeight: FontWeight.w600,
      fontSize: 22.0,
    ),
    bodyLarge: TextStyle(color: AppColors.textDark, fontSize: 16.0),
    bodyMedium: TextStyle(color: AppColors.textSecondaryDark, fontSize: 14.0),
    labelLarge: TextStyle(
      color: AppColors.primaryAction,
      fontWeight: FontWeight.bold,
      fontSize: 14.0,
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primaryAction,
      foregroundColor: AppColors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: AppColors.primaryAction,
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8.0),
      borderSide: BorderSide(color: AppColors.mediumGrey),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8.0),
      borderSide: BorderSide(color: AppColors.primaryAction, width: 2.0),
    ),
    labelStyle: TextStyle(color: AppColors.textSecondaryDark),
    hintStyle: TextStyle(color: AppColors.mediumGrey),
    contentPadding: const EdgeInsets.symmetric(
      horizontal: 16.0,
      vertical: 12.0,
    ),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor:
        AppColors.surfaceDark, // Un color oscuro diferente al fondo
    foregroundColor: AppColors.white,
    titleTextStyle: TextStyle(
      color: AppColors.white,
      fontSize: 20,
      fontWeight: FontWeight.bold,
    ),
  ),
  cardTheme: CardThemeData(
    elevation: 4.0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
    margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
    color: AppColors.surfaceDark,
  ),
);

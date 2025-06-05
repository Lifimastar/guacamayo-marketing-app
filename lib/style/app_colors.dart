import 'package:flutter/material.dart';

class AppColors {
  // Colores Primarios de la Marca Guacamayo Marketing Solutions
  static const Color guacamayoRed = Color(
    0xFFFF0000,
  ); // Reemplazar con el HEX exacto
  static const Color guacamayoBlue = Color(
    0xFF00AEEF,
  ); // Reemplazar con el HEX exacto
  static const Color guacamayoYellow = Color(
    0xFFFFDD00,
  ); // Reemplazar con el HEX exacto
  static const Color guacamayoGreen = Color(
    0xFF8CC63F,
  ); // Reemplazar con el HEX exacto

  // Colores de Acción (basados en la paleta primaria)
  static const Color primaryAction =
      guacamayoBlue; // Azul para CTAs principales
  static const Color secondaryAction =
      guacamayoYellow; // Amarillo para acciones secundarias o acentos

  // Neutros para Texto y Fondos
  static const Color white = Color(0xFFFFFFFF);
  static const Color lightGrey = Color(0xFFF2F2F7); // Fondo sutil, divisores
  static const Color mediumGrey = Color(0xFFE5E5EA); // Bordes, iconos inactivos
  static const Color darkGrey = Color(0xFF333333); // Texto secundario
  static const Color almostBlack = Color(
    0xFF1C1C1E,
  ); // Texto principal, fondos oscuros

  // Colores para Temas (Claro y Oscuro)
  static const Color backgroundLight = white;
  static const Color surfaceLight =
      white; // Para tarjetas, diálogos, bottom sheets
  static const Color textLight = almostBlack;
  static const Color textSecondaryLight = darkGrey;

  static const Color backgroundDark = almostBlack; // O un gris muy oscuro
  static const Color surfaceDark = Color(
    0xFF2C2C2E,
  ); // Un poco más claro que el fondo oscuro
  static const Color textDark = white;
  static const Color textSecondaryDark = lightGrey;

  // Colores de Estado (ej: para estados de reserva)
  static const Color statusPending = Colors.blueGrey;
  static const Color statusCheckoutPending = Colors.orange;
  static const Color statusConfirmed =
      guacamayoBlue; // Usar un color de la marca para confirmado
  static const Color statusInProgress = Colors.purple;
  static const Color statusCompleted =
      guacamayoGreen; // Usar un color de la marca para completado
  static const Color statusCancelled = Colors.red;
  static const Color statusPaymentFailed =
      Colors.redAccent; // Un rojo diferente o más intenso para fallo de pago

  // Colores de Error y Éxito
  static const Color errorColor = Colors.redAccent;
  static const Color successColor =
      guacamayoGreen; // Usar el verde de la marca para éxito
}

import 'package:flutter/material.dart';
import '../style/app_colors.dart';

class BookingStatusUtils {
  // Método estático para obtener el texto legible del estado
  static String getStatusText(String status) {
    switch (status) {
      case 'checkout_pending':
        return 'Pago Pendiente';
      case 'pending':
        return 'Pendiente';
      case 'confirmed':
        return 'Confirmada';
      case 'in_progress':
        return 'En Progreso';
      case 'completed':
        return 'Completada';
      case 'cancelled':
        return 'Cancelada';
      case 'payment_failed':
        return 'Pago Fallido';
      default:
        return status.replaceAll('_', ' ').toUpperCase(); 
    }
  }

  // Método estático para obtener el color del estado
  static Color getStatusColor(String status) {
    switch (status) {
      case 'checkout_pending':
        return AppColors.statusCheckoutPending;
      case 'pending':
        return AppColors.statusPending;
      case 'confirmed':
        return AppColors.statusConfirmed;
      case 'in_progress':
        return AppColors.statusInProgress;
      case 'completed':
        return AppColors.statusCompleted;
      case 'cancelled':
      case 'payment_failed':
        return AppColors.statusPaymentFailed;
      default:
        return Colors.grey; 
    }
  }
}

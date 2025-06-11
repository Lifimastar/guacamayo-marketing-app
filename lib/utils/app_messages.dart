import 'package:flutter/material.dart';

class AppMessages {
  // Errores Generales
  static const String unexpectedError =
      'Ocurrió un error inesperado. Por favor, inténtalo de nuevo.';
  static const String networkError =
      'Problema de conexión. Por favor, verifica tu internet.';
  static const String operationFailed =
      'La operación falló. Por favor, inténtalo de nuevo.';

  // Autenticación
  static const String authError =
      'Error de autenticación. Verifica tus credenciales.';
  static const String invalidLoginCredentials =
      'Credenciales de inicio de sesión inválidas.';
  static const String userNotFound = 'Usuario no encontrado.';
  static const String wrongPassword = 'Contraseña incorrecta.';
  static const String emailAlreadyRegistered =
      'Este correo ya está registrado.';
  static const String registrationSuccess =
      '¡Registro exitoso! Ahora puedes iniciar sesión.';
  static const String logoutSuccess = 'Sesión cerrada con éxito.';

  // Reservas
  static const String bookingCancelledSuccess = 'Reserva cancelada con éxito.';
  static const String bookingCancelError = 'Error al cancelar la reserva.';
  static const String bookingUpdateStatusSuccess =
      'Estado de la reserva actualizado.';
  static const String bookingUpdateStatusError =
      'Error al actualizar el estado de la reserva.';
  static const String bookingDeleteSuccess =
      'Reserva eliminada permanentemente.';
  static const String bookingDeleteError = 'Error al eliminar la reserva.';

  // Servicios
  static const String serviceSaveSuccess = 'Servicio guardado con éxito.';
  static const String serviceSaveError = 'Error al guardar el servicio.';
  static const String serviceDeleteSuccess = 'Servicio eliminado con éxito.';
  static const String serviceDeleteError = 'Error al eliminar el servicio.';
  static const String serviceHasBookingsError =
      'Error: No se puede eliminar. El servicio tiene reservas asociadas. Considere desactivarlo.';

  // Entregables
  static const String deliverableAddSuccess = 'Entregable añadido con éxito.';
  static const String deliverableAddError = 'Error al añadir entregable.';
  static const String deliverableDeleteSuccess =
      'Entregable eliminado con éxito.';
  static const String deliverableDeleteError = 'Error al eliminar entregable.';
  static const String fileUploadError = 'Error al subir archivo.';
  static const String fileAccessError = 'Error al acceder al archivo.';
  static const String fileNotFound = 'Archivo no encontrado.';
  static const String invalidUrl = 'URL del archivo no válida.';

  // Perfil/Usuarios
  static const String userRoleUpdateSuccess = 'Rol de usuario actualizado.';
  static const String userRoleUpdateError =
      'Error al cambiar el rol del usuario.';
  static const String userDeleteSuccess = 'Usuario eliminado con éxito.';
  static const String userDeleteError = 'Error al eliminar usuario.';
  static const String adminPermissionsError =
      'No tienes permisos de administrador para esta acción.';
  static const String jwtMissingError =
      'Error de autenticación: JWT no disponible.';

  // Validaciones
  static const String requiredField = 'Este campo es obligatorio.';
  static const String invalidNumber = 'Por favor, introduce un número válido.';
  static const String invalidEmail = 'Por favor, introduce un correo válido.';
}

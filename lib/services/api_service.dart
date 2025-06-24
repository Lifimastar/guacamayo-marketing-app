import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/config.dart';
import '../utils/logger.dart';

class ApiService {
  final String _backendUrl = backendUrl;

  Future<bool> sendBookingStatusNotification({
    required String userId,
    required String bookingId,
    required String serviceName,
    required String newStatusReadable,
  }) async {
    final jwt = Supabase.instance.client.auth.currentSession?.accessToken;
    if (jwt == null) {
      logger.e(
        'No se puede enviar notificacion: Admin no atutenticado (JWT es nulo)',
      );
      return false;
    }

    final url = Uri.parse('$_backendUrl/admin/notify-user');
    final headers = {
      'Content-Type':
          'application/json; charset=UTF-8', // Es buena práctica ser explícito
      'Authorization': 'Bearer $jwt',
    };

    final String title = 'Actualización de tu Reserva';
    final String body =
        'El estado de tu reserva para "$serviceName" ha cambiado a: $newStatusReadable.';

    final Map<String, String> requestData = {
      'user_id': userId,
      'title': title,
      'body': body,
      'booking_id': bookingId,
    };

    final requestBody = json.encode(requestData);

    try {
      final response = await http.post(
        url,
        headers: headers,
        body: requestBody,
      );
      if (response.statusCode == 200) {
        logger.i(
          'Petición de notificación enviada con éxito para el usuario $userId',
        );
        return true;
      } else {
        logger.e(
          'Falló la petición de notificación. Estado: ${response.statusCode}, Cuerpo: ${response.body}',
        );
        return false;
      }
    } catch (e) {
      logger.e('Error al llamar al endpoint de notificación: $e');
      return false;
    }
  }
}

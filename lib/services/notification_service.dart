import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:guacamayo_marketing_app/screens/booking_details_page.dart';
import 'package:guacamayo_marketing_app/utils/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  Future<void> initialize() async {
    await _firebaseMessaging.requestPermission();
    final fcmToken = await _firebaseMessaging.getToken();
    logger.i('FCM Token: $fcmToken');
    await saveTokenToDatabase(fcmToken);
    _firebaseMessaging.onTokenRefresh.listen(saveTokenToDatabase);

    RemoteMessage? initialMessage =
        await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessage(initialMessage);
    }

    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      logger.i('Notificacion recibida en primer plano');
      if (message.notification != null) {
        final context = navigatorKey.currentState?.context;
        if (context != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${message.notification!.title}\n${message.notification!.body}',
                style: const TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.black87,
            ),
          );
        }
      }
    });
  }

  // Funcion central para manejar la navegacion desde una notificacion
  void _handleMessage(RemoteMessage message) {
    logger.i('Manejando navegacion desde notificacion: ${message.data}');
    final bookingId = message.data['booking_id'];

    if (bookingId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (context) => BookingDetailsPage(bookingId: bookingId),
          ),
        );
      });
    }
  }

  Future<void> saveTokenToDatabase(String? token) async {
    if (token == null) return;

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      logger.w('Intento de guardar FCM token sin usuario logueado.');
      return;
    }

    try {
      await Supabase.instance.client
          .from('profiles')
          .update({'fcm_token': token})
          .eq('id', userId);
      logger.i(
        'FCM Token guardado en la base de datos para el usuario $userId',
      );
    } catch (e) {
      logger.e('Error al guardar el FCM token en la base de datos: $e');
    }
  }
}

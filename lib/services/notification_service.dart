import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:guacamayo_marketing_app/utils/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  Future<void> initialize() async {
    await _firebaseMessaging.requestPermission();

    final fcmToken = await _firebaseMessaging.getToken();
    logger.i('FCM Token: $fcmToken');

    await saveTokenToDatabase(fcmToken);

    _firebaseMessaging.onTokenRefresh.listen(saveTokenToDatabase);
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

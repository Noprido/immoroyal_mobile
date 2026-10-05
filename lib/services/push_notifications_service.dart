import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../core/network/dio_client.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('📩 [BACKGROUND] Message reçu: ${message.messageId}');
}

class PushNotificationsService {
  static final _messaging = FirebaseMessaging.instance;

  /// À appeler une fois au démarrage de l'app, après Firebase.initializeApp().
  static Future<void> init() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('🔔 Permission notifications: ${settings.authorizationStatus}');

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    FirebaseMessaging.onMessage.listen((message) {
      debugPrint('📩 [FOREGROUND] Message reçu: ${message.notification?.title}');
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      debugPrint('👆 Notif tapée: ${message.data}');
      // TODO plus tard: naviguer vers la conversation concernée
    });
  } // ⬅️ init() se ferme ICI

  /// Récupère le token FCM de cet appareil.
  static Future<String?> getToken() async {
    final token = await _messaging.getToken();
    debugPrint('🔑 Token FCM: $token');
    return token;
  }

  /// Envoie le token FCM au backend, associé à l'utilisateur connecté.
  static Future<void> registerTokenWithBackend() async {
    try {
      final token = await getToken();
      if (token == null) return;
      await DioClient.instance.post('/users/fcm-token', data: {'token': token});
      debugPrint('✅ Token FCM enregistré côté backend');
    } catch (e) {
      debugPrint('⚠️ Échec enregistrement token FCM: $e');
    }
  }
} // ⬅️ classe se ferme ICI
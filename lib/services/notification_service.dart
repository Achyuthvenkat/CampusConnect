import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Future<void> initialize(String userId) async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      final token = await _messaging.getToken();
      if (token != null) {
        await _saveFCMToken(userId, token);
      }

      _messaging.onTokenRefresh.listen((newToken) async {
        await _saveFCMToken(userId, newToken);
      });
    }

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint(
          'Received foreground message: ${message.notification?.title}');
    });
  }

  Future<void> _saveFCMToken(String userId, String token) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .update({'fcmToken': token});
  }
}

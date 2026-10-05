import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:voicepin/models/voice_note.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._init();
  final FlutterLocalNotificationsPlugin  _notifications = 
      FlutterLocalNotificationsPlugin();

  NotificationService._init();

  //Servisi Başlatma
  Future<void> initialize() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
    );

    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }
        //Bildirime tıkladığında
  void _onNotificationTapped(NotificationResponse response) {
      //Ses notunu oynat veya detay göster
      debugPrint('Bildirime tıklandı: ${response.payload}');
  }

   //Basit bildirim gönder
   Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
   }) async {
    const AndroidNotificationDetails androidDetails = 
        AndroidNotificationDetails(
          'voicepin_channel',
          'VoicePin Notifications',
          channelDescription: 'Konum bazlı ses notu bildirimleri',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
        );
        const NotificationDetails details = NotificationDetails(
          android: androidDetails,
        );
        await _notifications.show(
          id,
          title,
          body,
          details,
          payload: payload,
        );
   }

   //Ses notu için bildirim
   Future<void> showVoiceNoteNotification(VoiceNote note) async {
    await showNotification(
      id: note.id ?? 0,
      title: '🎤 Ses Notunuz Yakınlarda!',
      body: note.title,
      payload: note.id.toString(),
    );
  }

  //Bildirimi iptal et
  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  //Tüm bildirimleri iptal et
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }
}
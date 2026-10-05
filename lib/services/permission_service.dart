import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  // Konum izni iste
  static Future<bool> requestLocationPermission() async {
    PermissionStatus status = await Permission.location.request();
    
    if (status.isGranted) {
      return true;
    } else if (status.isDenied) {
      // Kullanıcı reddetti
      return false;
    } else if (status.isPermanentlyDenied) {
      // Ayarlara yönlendir
      openAppSettings();
      return false;
    }
    return false;
  }

  // Arka plan konum izni iste (Android 10+)
  static Future<bool> requestBackgroundLocationPermission() async {
    if (await Permission.location.isGranted) {
      PermissionStatus status = await Permission.locationAlways.request();
      return status.isGranted;
    }
    return false;
  }

  // Mikrofon izni iste
  static Future<bool> requestMicrophonePermission() async {
    PermissionStatus status = await Permission.microphone.request();
    
    if (status.isGranted) {
      return true;
    } else if (status.isPermanentlyDenied) {
      openAppSettings();
      return false;
    }
    return false;
  }

  // Bildirim izni iste (Android 13+)
  static Future<bool> requestNotificationPermission() async {
    PermissionStatus status = await Permission.notification.request();
    return status.isGranted;
  }

  // Tüm izinleri kontrol et
  static Future<Map<String, bool>> checkAllPermissions() async {
    return {
      'location': await Permission.location.isGranted,
      'locationAlways': await Permission.locationAlways.isGranted,
      'microphone': await Permission.microphone.isGranted,
      'notification': await Permission.notification.isGranted,
    };
  }

  // Tüm gerekli izinleri iste
  static Future<bool> requestAllPermissions() async {
    bool location = await requestLocationPermission();
    bool microphone = await requestMicrophonePermission();
    bool notification = await requestNotificationPermission();
    
    return location && microphone && notification;
  }
}
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:voicepin/models/voice_note.dart';
import 'package:voicepin/services/database_helper.dart';
import 'package:voicepin/services/notification_service.dart';
import 'dart:async';

class LocationService {
  static final LocationService instance = LocationService._init();

  StreamSubscription<Position>? _positionStream;
  final Set<int> _notifiedNotes = {}; //Bildirim gösterilen notlat
  bool _isTracking = false;

  LocationService._init();

  //Konum takibini başlat
  Future<void> startTracking() async {
    if (_isTracking) return;

    _isTracking = true;

    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, //10 metrede bir güncelleme
    );

     _positionStream = Geolocator.getPositionStream(
      locationSettings: locationSettings,
     ).listen(_onLocationUpdate);  
  }

   //Konum güncellenediğinde çalışacak fonksiyon
   Future<void> _onLocationUpdate(Position position) async {
    
    //veritabanından aktif notları al
    List<VoiceNote> activeNotes = await DatabaseHelper.instance.readActiveNotes();
    
    //Her not için kontrol et
    for (VoiceNote note in activeNotes) {
     
      //kullanıcının konumu ile ses notu konumu arasındaki (metre cinsi) mesafeyi hesapla
      double distance  = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        note.latitude,
        note.longitude,
      );

      //Eğer mesafe yarıçap içindeyse ve daha önce bildirim gösterilmediyse
      if (distance <= note.radius && !_notifiedNotes.contains(note.id)) {
        //Bildirim gönder
        await NotificationService.instance.showVoiceNoteNotification(note);

        //Bu not için bildirim gösterildi olarak işaretle
        _notifiedNotes.add(note.id!);

        debugPrint('Bildirim gönderildi: ${note.title} - Mesafe: ${distance.toInt()} m');
      }

      //Eğer yarıçap dışına çıktıysa, bildirimi sıfırla
      if (distance > note.radius * 1.5) {
        _notifiedNotes.remove(note.id);
      }
    }

  }
   //Konum takibini durdur
   Future<void> stopTracking() async {
     await _positionStream?.cancel();
     _positionStream = null;
      _isTracking = false;
      _notifiedNotes.clear();
   }

   //Takip durumu
    bool get isTracking => _isTracking;

    //Manuel kontrol (test için)
    Future<void> checkCurrentLocation() async {
      Position position = await Geolocator.getCurrentPosition();
      await _onLocationUpdate(position);
    }
}
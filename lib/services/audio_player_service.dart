import 'package:flutter_sound/flutter_sound.dart';
import 'dart:io';

class AudioPlayerService {
  static final AudioPlayerService instance = AudioPlayerService._init();
  FlutterSoundPlayer? _player;
  bool isPlaying = false;
  String? currentlyPlayingPath;
  Function()? onStateChanged;

  AudioPlayerService._init();

  // Player'ı başlat
  Future<void> init() async {
    _player = FlutterSoundPlayer();
    await _player!.openPlayer();
  }

  // Ses oynat
  Future<void> play(String audioPath, {Function()? whenFinished}) async {
    if (_player == null) await init();

    // Eğer aynı ses çalıyorsa durdur
    if (isPlaying && currentlyPlayingPath == audioPath) {
      await stop();
      return;
    }

    // Farklı ses çalıyorsa önce durdur
    if (isPlaying) {
      await stop();
    }

    if (!File(audioPath).existsSync()) {
      throw Exception('Ses dosyası bulunamadı!');
    }

    currentlyPlayingPath = audioPath;
    isPlaying = true;
    onStateChanged?.call();

    await _player!.startPlayer(
      fromURI: audioPath,
      whenFinished: () {
        isPlaying = false;
        currentlyPlayingPath = null;
        onStateChanged?.call();
        whenFinished?.call();
      },
    );
  }

  // Oynatmayı durdur
  Future<void> stop() async {
    if (_player != null) {
      await _player!.stopPlayer();
      isPlaying = false;
      currentlyPlayingPath = null;
      onStateChanged?.call();
    }
  }

  // Pause
  Future<void> pause() async {
    if (_player != null) {
      await _player!.pausePlayer();
      isPlaying = false;
      onStateChanged?.call();
    }
  }

  // Resume
  Future<void> resume() async {
    if (_player != null) {
      await _player!.resumePlayer();
      isPlaying = true;
      onStateChanged?.call();
    }
  }

  // Player'ı kapat
  Future<void> dispose() async {
    if (_player != null) {
      await _player!.closePlayer();
      _player = null;
      isPlaying = false;
      currentlyPlayingPath = null;
    }
  }

  // Oynatma durumunu al
  bool get playing => isPlaying;
}

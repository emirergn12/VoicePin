import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:voicepin/utils/app_colors.dart';
import 'package:voicepin/screens/map_screen.dart';
import 'package:voicepin/services/notification_service.dart';
import 'package:voicepin/services/theme_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Servisleri ve tema tercihini başlat
  await NotificationService.instance.initialize();
  await ThemeService.instance.loadTheme();

  // Status bar ve navigasyon çubuğu stilini ayarla
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
    ),
  );

  runApp(const VoicePinApp());
}

class VoicePinApp extends StatelessWidget {
  const VoicePinApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeService.instance.themeModeNotifier,
      builder: (context, currentThemeMode, child) {
        return MaterialApp(
          title: 'VoicePin',
          debugShowCheckedModeBanner: false,
          themeMode: currentThemeMode,
          theme: AppColors.lightTheme,
          darkTheme: AppColors.darkTheme,
          home: const MapScreen(),
        );
      },
    );
  }
}

import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:voicepin/utils/app_colors.dart';
import 'package:voicepin/services/permission_service.dart';
import 'package:voicepin/services/database_helper.dart';
import 'package:voicepin/models/voice_note.dart';
import 'package:voicepin/screens/voice_record_screen.dart';
import 'package:voicepin/services/audio_player_service.dart';
import 'package:voicepin/screens/notes_list_screen.dart';
import 'package:voicepin/screens/settings_screen.dart';
import 'package:voicepin/services/location_service.dart';
import 'package:voicepin/services/theme_service.dart';
import 'package:voicepin/widgets/audio_waveform_visualizer.dart';
import 'package:voicepin/utils/custom_marker_generator.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  int selectedIndex = 0;
  bool permissionsGranted = false;
  int noteCount = 0;
  String selectedMapCategory = 'All';

  // Varsayılan konum (İstanbul - Taksim)
  LatLng currentPosition = const LatLng(41.0370, 28.9850);
  CameraPosition _currentCameraPosition = const CameraPosition(
    target: LatLng(41.0370, 28.9850),
    zoom: 15,
  );
  Set<Marker> markers = {};
  Set<Circle> circles = {};
  bool isLoadingLocation = true;

  @override
  void initState() {
    super.initState();
    ThemeService.instance.themeModeNotifier.addListener(_onThemeChanged);
    _initializeApp();
  }

  void _onThemeChanged() {
    if (mounted) setState(() {});
  }

  // Uygulamayı başlat
  Future<void> _initializeApp() async {
    await _checkAndRequestPermissions();
    await _getCurrentLocation();
    await _loadNoteCount();
    await _loadMarkersFromDatabase();

    if (permissionsGranted) {
      await LocationService.instance.startTracking();
    }
  }

  // Mevcut konumu al
  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        currentPosition = LatLng(position.latitude, position.longitude);
        _currentCameraPosition = CameraPosition(
          target: currentPosition,
          zoom: 15,
        );
        isLoadingLocation = false;
      });

      // Kamerayı mevcut konuma taşı
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(currentPosition, 15),
      );
    } catch (e) {
      debugPrint('Konum alınamadı: $e');
      setState(() {
        isLoadingLocation = false;
      });
    }
  }

  // Veritabanından marker'ları ve yarıçap dairelerini yükle
  Future<void> _loadMarkersFromDatabase() async {
    final bool isDark = mounted ? AppColors.isDark(context) : false;
    CustomMarkerGenerator.clearCache();
    List<VoiceNote> notes = await DatabaseHelper.instance.readActiveNotes();

    Set<Marker> newMarkers = {};
    Set<Circle> newCircles = {};

    for (VoiceNote note in notes) {
      if (selectedMapCategory != 'All' &&
          note.category != selectedMapCategory) {
        continue;
      }

      final Color categoryColor = _getCategoryColorVal(note.category);
      final BitmapDescriptor customIcon =
          await CustomMarkerGenerator.getCategoryMarker(
        note.category,
        categoryColor,
      );

      // 1. Marker Ekle
      newMarkers.add(
        Marker(
          markerId: MarkerId(note.id.toString()),
          position: LatLng(note.latitude, note.longitude),
          icon: customIcon,
          infoWindow: InfoWindow(
            title: note.title,
            snippet: '${note.category} • ${note.radius.toInt()}m',
          ),
          onTap: () => _onMarkerTapped(note),
        ),
      );

      // 2. Yarıçap Çemberi (Geofence Circle) Ekle
      newCircles.add(
        Circle(
          circleId: CircleId('circle_${note.id}'),
          center: LatLng(note.latitude, note.longitude),
          radius: note.radius,
          fillColor: categoryColor.withValues(alpha: isDark ? 0.18 : 0.12),
          strokeColor: categoryColor.withValues(alpha: isDark ? 0.65 : 0.5),
          strokeWidth: 1,
        ),
      );
    }

    if (mounted) {
      setState(() {
        markers = newMarkers;
        circles = newCircles;
      });
    }
  }

  // Kategoriye göre marker rengi
  Color _getCategoryColorVal(String category) {
    switch (category) {
      case 'Shopping':
        return AppColors.shopping;
      case 'Work':
        return AppColors.work;
      case 'Personal':
        return AppColors.personal;
      case 'Other':
        return AppColors.others;
      default:
        return AppColors.primary;
    }
  }

  // Marker'a tıklandığında
  void _onMarkerTapped(VoiceNote note) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildNoteDetailSheet(note),
    );
  }

  // Not detay bottom sheet
  Widget _buildNoteDetailSheet(VoiceNote note) {
    final categoryColor = _getCategoryChipColor(note.category);
    final cardBgColor = AppColors.getCardBackground(context);
    final borderColor = AppColors.getBorderColor(context);
    final surfaceSubtle = AppColors.getSurfaceSubtle(context);
    final textPrimaryColor = AppColors.getTextPrimary(context);
    final textSecondaryColor = AppColors.getTextSecondary(context);

    return Container(
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Drag handle
          Container(
            width: 48,
            height: 5,
            decoration: BoxDecoration(
              color: borderColor,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 20),

          // Kategori Badge & Yarıçap Bilgisi
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: categoryColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: categoryColor.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: categoryColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      note.category,
                      style: TextStyle(
                        color: categoryColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: surfaceSubtle,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.radar,
                      size: 14,
                      color: textSecondaryColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${note.radius.toInt()}m Yarıçap',
                      style: TextStyle(
                        color: textSecondaryColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Başlık
          Text(
            note.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: textPrimaryColor,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 20),

          // Ses Waveform Görselleştirici
          StatefulBuilder(
            builder: (context, setSheetState) {
              final bool isPlayingThis = AudioPlayerService.instance.isPlaying &&
                  AudioPlayerService.instance.currentlyPlayingPath == note.audioPath;

              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                decoration: BoxDecoration(
                  color: surfaceSubtle,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isPlayingThis
                        ? categoryColor.withValues(alpha: 0.6)
                        : borderColor,
                  ),
                ),
                child: AudioWaveformVisualizer(
                  isAnimating: isPlayingThis,
                  height: 40,
                  barCount: 30,
                  activeColor: categoryColor,
                  inactiveColor: textSecondaryColor,
                  progress: isPlayingThis ? 0.5 : 0.0,
                ),
              );
            },
          ),
          const SizedBox(height: 24),

          // Action Butonları
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    try {
                      await AudioPlayerService.instance.play(note.audioPath);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Ses oynatılıyor...'),
                            duration: Duration(seconds: 1),
                            backgroundColor: AppColors.primary,
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Ses oynatılamadı: $e'),
                            backgroundColor: AppColors.error,
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(Icons.play_arrow_rounded, size: 24),
                  label: const Text(
                    'Oynat',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () async {
                  await DatabaseHelper.instance.delete(note.id!);
                  await _loadMarkersFromDatabase();
                  await _loadNoteCount();
                  if (mounted) Navigator.pop(context);
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side:
                      BorderSide(color: AppColors.error.withValues(alpha: 0.5)),
                  padding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.delete_outline_rounded, size: 22),
                label: const Text(
                  'Sil',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Harita Kategori Filtresi Bottom Sheet
  void _showCategoryFilterSheet() {
    final cardBgColor = AppColors.getCardBackground(context);
    final borderColor = AppColors.getBorderColor(context);
    final textPrimaryColor = AppColors.getTextPrimary(context);
    final primaryAccent = AppColors.getPrimaryAccent(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: cardBgColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(color: borderColor, width: 1.5),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sürükleme Çubuğu
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: borderColor,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  Icon(Icons.tune_rounded, color: primaryAccent, size: 22),
                  const SizedBox(width: 10),
                  Text(
                    'Harita Kategori Filtresi',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textPrimaryColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Seçenekler
            _buildCategoryFilterOption(
                'All', 'Tüm İğneler', Icons.space_dashboard_rounded, primaryAccent),
            _buildCategoryFilterOption(
                'Shopping', 'Alışveriş', Icons.shopping_bag_rounded, AppColors.shopping),
            _buildCategoryFilterOption(
                'Work', 'İş', Icons.work_rounded, AppColors.work),
            _buildCategoryFilterOption(
                'Personal', 'Kişisel', Icons.person_rounded, AppColors.personal),
            _buildCategoryFilterOption(
                'Other', 'Diğer', Icons.push_pin_rounded, AppColors.others),
          ],
        ),
      ),
    );
  }

  // Kategori Filtre Seçeneği Satırı
  Widget _buildCategoryFilterOption(
    String categoryKey,
    String label,
    IconData icon,
    Color color,
  ) {
    final bool isSelected = selectedMapCategory == categoryKey;
    final textPrimaryColor = AppColors.getTextPrimary(context);
    final isDark = AppColors.isDark(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            setState(() {
              selectedMapCategory = categoryKey;
            });
            Navigator.pop(context);
            await _loadMarkersFromDatabase();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    categoryKey == 'All'
                        ? 'Tüm harita iğneleri gösteriliyor'
                        : '"$label" iğneleri süzüldü',
                  ),
                  duration: const Duration(seconds: 1),
                  backgroundColor: color,
                ),
              );
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? color.withValues(alpha: isDark ? 0.22 : 0.12)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              border: isSelected
                  ? Border.all(color: color.withValues(alpha: 0.5), width: 1.2)
                  : null,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                const SizedBox(width: 14),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    color: isSelected ? color : textPrimaryColor,
                  ),
                ),
                const Spacer(),
                if (isSelected)
                  Icon(Icons.check_circle_rounded, color: color, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Kategori Etiketi
  String _getCategoryLabel(String category) {
    switch (category) {
      case 'Shopping':
        return 'Alışveriş';
      case 'Work':
        return 'İş';
      case 'Personal':
        return 'Kişisel';
      case 'Other':
        return 'Diğer';
      default:
        return 'Tümü';
    }
  }

  // Kategori chip rengi
  Color _getCategoryChipColor(String category) {
    switch (category) {
      case 'Shopping':
        return AppColors.shopping;
      case 'Work':
        return AppColors.work;
      case 'Personal':
        return AppColors.personal;
      case 'Other':
        return AppColors.others;
      default:
        return AppColors.primary;
    }
  }

  // Not sayısını yükle
  Future<void> _loadNoteCount() async {
    int count = await DatabaseHelper.instance.getNotesCount();
    setState(() {
      noteCount = count;
    });
  }

  // Test: Dummy not ekle (mevcut konuma)
  Future<void> _addTestNote() async {
    VoiceNote testNote = VoiceNote(
      title: 'Test Notu ${noteCount + 1}',
      latitude: currentPosition.latitude,
      longitude: currentPosition.longitude,
      audioPath: '/test/audio.aac',
      category: ['Shopping', 'Work', 'Personal', 'Other'][noteCount % 4],
      radius: 100,
    );

    await DatabaseHelper.instance.create(testNote);
    await _loadNoteCount();
    await _loadMarkersFromDatabase();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Test notu eklendi! Toplam: $noteCount'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Future<void> _checkAndRequestPermissions() async {
    bool granted = await PermissionService.requestAllPermissions();
    setState(() {
      permissionsGranted = granted;
    });

    if (!granted) {
      _showPermissionDialog();
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('İzinler Gerekli'),
        content: const Text(
          'VoicePin\'in çalışması için konum, mikrofon ve bildirim izinleri gereklidir.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _checkAndRequestPermissions();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('İzin Ver'),
          ),
        ],
      ),
    );
  }

  // Harita oluşturulduğunda
  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  static const String _darkMapStyle = '''
[
  {"elementType": "geometry", "stylers": [{"color": "#242f3e"}]},
  {"elementType": "labels.text.fill", "stylers": [{"color": "#746855"}]},
  {"elementType": "labels.text.stroke", "stylers": [{"color": "#242f3e"}]},
  {"featureType": "administrative.locality", "elementType": "labels.text.fill", "stylers": [{"color": "#d59563"}]},
  {"featureType": "poi", "elementType": "labels.text.fill", "stylers": [{"color": "#d59563"}]},
  {"featureType": "poi.park", "elementType": "geometry", "stylers": [{"color": "#263c3f"}]},
  {"featureType": "poi.park", "elementType": "labels.text.fill", "stylers": [{"color": "#6b9a76"}]},
  {"featureType": "road", "elementType": "geometry", "stylers": [{"color": "#38414e"}]},
  {"featureType": "road", "elementType": "geometry.stroke", "stylers": [{"color": "#212a37"}]},
  {"featureType": "road", "elementType": "labels.text.fill", "stylers": [{"color": "#9ca5b3"}]},
  {"featureType": "road.highway", "elementType": "geometry", "stylers": [{"color": "#746855"}]},
  {"featureType": "road.highway", "elementType": "geometry.stroke", "stylers": [{"color": "#1f2835"}]},
  {"featureType": "road.highway", "elementType": "labels.text.fill", "stylers": [{"color": "#f3d19c"}]},
  {"featureType": "transit", "elementType": "geometry", "stylers": [{"color": "#2f3948"}]},
  {"featureType": "transit.station", "elementType": "labels.text.fill", "stylers": [{"color": "#d59563"}]},
  {"featureType": "water", "elementType": "geometry", "stylers": [{"color": "#17263c"}]},
  {"featureType": "water", "elementType": "labels.text.fill", "stylers": [{"color": "#515c6d"}]},
  {"featureType": "water", "elementType": "labels.text.stroke", "stylers": [{"color": "#17263c"}]}
]
''';

  void _onMapLongPress(LatLng position) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VoiceRecordScreen(
          latitude: position.latitude,
          longitude: position.longitude,
        ),
      ),
    );

    // Eğer not kaydedildiyse marker'ları güncelle
    if (result == true) {
      await _loadMarkersFromDatabase();
      await _loadNoteCount();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cardBgColor = AppColors.getCardBackground(context);
    final borderColor = AppColors.getBorderColor(context);
    final textPrimaryColor = AppColors.getTextPrimary(context);
    final textSecondaryColor = AppColors.getTextSecondary(context);
    final softShadows = AppColors.getSoftShadow(context);
    final primaryAccent = AppColors.getPrimaryAccent(context);
    final isDark = AppColors.isDark(context);

    return Scaffold(
      extendBody: true,
      body: isLoadingLocation
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : Stack(
              children: [
                // 1. Google Map
                GoogleMap(
                  onMapCreated: _onMapCreated,
                  onLongPress: _onMapLongPress,
                  onCameraMove: (CameraPosition position) {
                    _currentCameraPosition = position;
                  },
                  initialCameraPosition: _currentCameraPosition,
                  markers: markers,
                  circles: circles,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomGesturesEnabled: true,
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
                  compassEnabled: false,
                  mapType: MapType.normal,
                  style: isDark ? _darkMapStyle : null,
                ),

                // 2. Top Floating Header Bar (Glassmorphic Header with Contrast Border)
                SafeArea(
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color:
                            cardBgColor.withValues(alpha: isDark ? 0.96 : 0.94),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: borderColor,
                          width: 1.2,
                        ),
                        boxShadow: softShadows,
                      ),
                      child: Row(
                        children: [
                          // App Logo / Icon Badge
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.location_on_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),

                          // App Title & Note Count Badge
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'VoicePin',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: textPrimaryColor,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              Text(
                                '$noteCount Not Pinlendi',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: textSecondaryColor,
                                ),
                              ),
                            ],
                          ),

                          const Spacer(),

                          // 1. Test Notu Ekle Butonu
                          IconButton(
                            icon: Icon(
                              Icons.science_outlined,
                              color: textSecondaryColor,
                              size: 22,
                            ),
                            onPressed: _addTestNote,
                            tooltip: 'Test Notu Ekle',
                          ),

                          // 2. Hızlı Konum Butonu
                          IconButton(
                            icon: Icon(
                              Icons.my_location_rounded,
                              color: primaryAccent,
                              size: 22,
                            ),
                            onPressed: _getCurrentLocation,
                            tooltip: 'Konumuma Git',
                          ),
                          const SizedBox(width: 4),

                          // 3. Ses Kayıt Butonu (Yüzen Ada İçinde)
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: permissionsGranted
                                  ? () async {
                                      final result = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              VoiceRecordScreen(
                                            latitude: currentPosition.latitude,
                                            longitude:
                                                currentPosition.longitude,
                                          ),
                                        ),
                                      );

                                      if (result == true) {
                                        await _loadMarkersFromDatabase();
                                        await _loadNoteCount();
                                      }
                                    }
                                  : null,
                              borderRadius: BorderRadius.circular(14),
                              child: Ink(
                                padding: const EdgeInsets.all(9),
                                decoration: BoxDecoration(
                                  gradient: AppColors.primaryGradient,
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary
                                          .withValues(alpha: 0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.mic_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // 3. Sağ Alt Kısımda Yüzen Canlı Kategori Filtreleme Butonu
                Positioned(
                  bottom: 92,
                  right: 16,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _showCategoryFilterSheet,
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 11),
                        decoration: BoxDecoration(
                          color: selectedMapCategory != 'All'
                              ? _getCategoryColorVal(selectedMapCategory)
                              : cardBgColor.withValues(
                                  alpha: isDark ? 0.94 : 0.92),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: selectedMapCategory != 'All'
                                ? Colors.white.withValues(alpha: 0.6)
                                : borderColor,
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: selectedMapCategory != 'All'
                                  ? _getCategoryColorVal(selectedMapCategory)
                                      .withValues(alpha: 0.4)
                                  : Colors.black
                                      .withValues(alpha: isDark ? 0.4 : 0.12),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              selectedMapCategory != 'All'
                                  ? Icons.filter_alt_rounded
                                  : Icons.tune_rounded,
                              color: selectedMapCategory != 'All'
                                  ? Colors.white
                                  : primaryAccent,
                              size: 19,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              selectedMapCategory != 'All'
                                  ? _getCategoryLabel(selectedMapCategory)
                                  : 'Filtrele',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: selectedMapCategory != 'All'
                                    ? Colors.white
                                    : textPrimaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

      // Modern Floating Glassmorphic Bottom Navigation Dock
      bottomNavigationBar: SafeArea(
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          height: 64,
          decoration: BoxDecoration(
            color: isDark
                ? cardBgColor.withValues(alpha: 0.88)
                : cardBgColor.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: isDark
                  ? borderColor.withValues(alpha: 0.6)
                  : borderColor.withValues(alpha: 0.8),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.10),
                blurRadius: 24,
                offset: const Offset(0, 8),
                spreadRadius: 2,
              ),
              if (!isDark)
                BoxShadow(
                  color: primaryAccent.withValues(alpha: 0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildNavItem(0, Icons.map_rounded, 'Harita', cardBgColor,
                        borderColor, textSecondaryColor, primaryAccent, isDark),
                    _buildNavItem(
                        1,
                        Icons.space_dashboard_rounded,
                        'Notlarım',
                        cardBgColor,
                        borderColor,
                        textSecondaryColor,
                        primaryAccent,
                        isDark),
                    _buildNavItem(2, Icons.tune_rounded, 'Ayarlar', cardBgColor,
                        borderColor, textSecondaryColor, primaryAccent, isDark),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Modern Navigation Item Builder
  Widget _buildNavItem(
    int index,
    IconData icon,
    String label,
    Color cardBgColor,
    Color borderColor,
    Color textSecondaryColor,
    Color primaryAccent,
    bool isDark,
  ) {
    final bool isSelected = selectedIndex == index;
    final Color activeTextColor = primaryAccent;
    final Color inactiveColor = isDark
        ? Colors.white.withValues(alpha: 0.55)
        : textSecondaryColor.withValues(alpha: 0.75);

    return InkWell(
      onTap: () {
        if (index == selectedIndex) return;

        setState(() {
          selectedIndex = index;
        });

        if (index == 1) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const NotesListScreen(),
            ),
          ).then((_) {
            _loadMarkersFromDatabase();
            _loadNoteCount();
            setState(() {
              selectedIndex = 0;
            });
          });
        } else if (index == 2) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const SettingsScreen(),
            ),
          ).then((_) {
            _loadMarkersFromDatabase();
            _loadNoteCount();
            setState(() {
              selectedIndex = 0;
            });
          });
        }
      },
      borderRadius: BorderRadius.circular(20),
      splashColor: primaryAccent.withValues(alpha: 0.1),
      highlightColor: Colors.transparent,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark
                  ? primaryAccent.withValues(alpha: 0.18)
                  : primaryAccent.withValues(alpha: 0.12))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: isSelected
              ? Border.all(
                  color: primaryAccent.withValues(alpha: isDark ? 0.45 : 0.3),
                  width: 1.2,
                )
              : Border.all(color: Colors.transparent, width: 1.2),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: primaryAccent.withValues(alpha: isDark ? 0.25 : 0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              duration: const Duration(milliseconds: 200),
              scale: isSelected ? 1.1 : 1.0,
              child: Icon(
                icon,
                color: isSelected ? activeTextColor : inactiveColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 7),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? activeTextColor : inactiveColor,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 13.5,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    ThemeService.instance.themeModeNotifier.removeListener(_onThemeChanged);
    _mapController?.dispose();
    AudioPlayerService.instance.stop();
    LocationService.instance.stopTracking();
    super.dispose();
  }
}

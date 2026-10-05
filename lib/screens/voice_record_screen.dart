import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:voicepin/utils/app_colors.dart';
import 'package:voicepin/models/voice_note.dart';
import 'package:voicepin/services/database_helper.dart';
import 'package:voicepin/widgets/audio_waveform_visualizer.dart';

class VoiceRecordScreen extends StatefulWidget {
  final double latitude;
  final double longitude;

  const VoiceRecordScreen({
    super.key,
    required this.latitude,
    required this.longitude,
  });

  @override
  State<VoiceRecordScreen> createState() => _VoiceRecordScreenState();
}

class _VoiceRecordScreenState extends State<VoiceRecordScreen>
    with SingleTickerProviderStateMixin {
  FlutterSoundRecorder? _recorder;
  bool isRecording = false;
  bool isRecorderInitialized = false;
  String? audioPath;
  int recordingSeconds = 0;

  // Form için
  final TextEditingController _titleController = TextEditingController();
  String selectedCategory = 'Shopping';
  double selectedRadius = 100.0;

  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _initRecorder();
  }

  // Recorder'ı başlat
  Future<void> _initRecorder() async {
    _recorder = FlutterSoundRecorder();

    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mikrofon izni gerekli!'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    await _recorder!.openRecorder();
    setState(() {
      isRecorderInitialized = true;
    });
  }

  // Kayıt başlat
  Future<void> _startRecording() async {
    if (!isRecorderInitialized) return;

    try {
      final directory = await getApplicationDocumentsDirectory();
      audioPath =
          '${directory.path}/voice_${DateTime.now().millisecondsSinceEpoch}.aac';

      await _recorder!.startRecorder(
        toFile: audioPath,
        codec: Codec.aacADTS,
      );

      setState(() {
        isRecording = true;
        recordingSeconds = 0;
      });

      _pulseController.repeat(reverse: true);
      _startTimer();
    } catch (e) {
      debugPrint('Kayıt başlatılamadı: $e');
    }
  }

  // Süre sayacı
  void _startTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (isRecording && mounted) {
        setState(() {
          recordingSeconds++;
        });
        _startTimer();
      }
    });
  }

  // Kayıt durdur
  Future<void> _stopRecording() async {
    if (!isRecording) return;

    await _recorder!.stopRecorder();
    _pulseController.stop();

    setState(() {
      isRecording = false;
    });

    _showSaveDialog();
  }

  // Kaydet dialog'u
  void _showSaveDialog() {
    final textPrimaryColor = AppColors.getTextPrimary(context);
    final textSecondaryColor = AppColors.getTextSecondary(context);
    final isDark = AppColors.isDark(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              const Icon(Icons.bookmark_add_rounded,
                  color: AppColors.primary, size: 26),
              const SizedBox(width: 10),
              Text(
                'Ses Notu Kaydet',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: textPrimaryColor,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                // Başlık Input
                TextField(
                  controller: _titleController,
                  autofocus: true,
                  style: TextStyle(
                      fontWeight: FontWeight.w600, color: textPrimaryColor),
                  decoration: InputDecoration(
                    labelText: 'Not Başlığı',
                    labelStyle: TextStyle(color: textSecondaryColor),
                    hintText: 'Örn: Market alışveriş listesi',
                    hintStyle:
                        TextStyle(color: AppColors.getTextMuted(context)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide:
                          const BorderSide(color: AppColors.primary, width: 2),
                    ),
                    prefixIcon: const Icon(Icons.edit_note_rounded,
                        color: AppColors.primary),
                  ),
                ),
                const SizedBox(height: 20),

                // Kategori Seçici
                Text(
                  'Kategori',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: textSecondaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildCategoryRadio('Shopping', 'Alışveriş',
                        AppColors.shopping, setDialogState),
                    _buildCategoryRadio(
                        'Work', 'İş', AppColors.work, setDialogState),
                    _buildCategoryRadio('Personal', 'Kişisel',
                        AppColors.personal, setDialogState),
                    _buildCategoryRadio(
                        'Other', 'Diğer', AppColors.others, setDialogState),
                  ],
                ),
                const SizedBox(height: 20),

                // Yarıçap Slider
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Bildirim Yarıçapı',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: textSecondaryColor,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.primary.withValues(alpha: 0.25)
                            : AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${selectedRadius.toInt()} metre',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppColors.primaryLight
                              : AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: selectedRadius,
                  min: 10,
                  max: 500,
                  divisions: 49,
                  activeColor: AppColors.primary,
                  inactiveColor: isDark
                      ? AppColors.darkSurfaceSubtle
                      : AppColors.primaryLight,
                  onChanged: (value) {
                    setDialogState(() {
                      selectedRadius = value;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (audioPath != null) {
                  File(audioPath!).deleteSync();
                }
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: Text(
                'İptal',
                style: TextStyle(
                    color: textSecondaryColor, fontWeight: FontWeight.w600),
              ),
            ),
            ElevatedButton(
              onPressed: _saveNote,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Kaydet',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Dialog Kategori Radio Chip
  Widget _buildCategoryRadio(
    String value,
    String label,
    Color color,
    StateSetter setDialogState,
  ) {
    final bool isSelected = selectedCategory == value;

    return InkWell(
      onTap: () {
        setDialogState(() {
          selectedCategory = value;
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : color.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : color,
          ),
        ),
      ),
    );
  }

  // Notu veritabanına kaydet
  Future<void> _saveNote() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen not için bir başlık girin!'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    if (audioPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ses kaydı bulunamadı!'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    VoiceNote note = VoiceNote(
      title: _titleController.text.trim(),
      latitude: widget.latitude,
      longitude: widget.longitude,
      audioPath: audioPath!,
      category: selectedCategory,
      radius: selectedRadius,
    );

    await DatabaseHelper.instance.create(note);

    if (mounted) {
      Navigator.pop(context); // Dialog kapat
      Navigator.pop(context, true); // Ekran kapat ve güncelleme sinyali gönder

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ses notu haritaya eklendi!'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  // Süreyi formatlı göster
  String _formatDuration(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = AppColors.getBackgroundColor(context);
    final cardBgColor = AppColors.getCardBackground(context);
    final textPrimaryColor = AppColors.getTextPrimary(context);
    final textSecondaryColor = AppColors.getTextSecondary(context);
    final softShadows = AppColors.getSoftShadow(context);
    final isDark = AppColors.isDark(context);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          'Ses Kaydı Stüdyosu',
          style:
              TextStyle(fontWeight: FontWeight.bold, color: textPrimaryColor),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Konum Kartı
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                margin: const EdgeInsets.symmetric(horizontal: 32),
                decoration: BoxDecoration(
                  color: cardBgColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: softShadows,
                  border: Border.all(
                    color: textSecondaryColor.withValues(alpha: 0.1),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.primary.withValues(alpha: 0.2)
                            : AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.location_on_rounded,
                        color:
                            isDark ? AppColors.primaryLight : AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Kayıt Konumu',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: textPrimaryColor,
                          ),
                        ),
                        Text(
                          '${widget.latitude.toStringAsFixed(4)}, ${widget.longitude.toStringAsFixed(4)}',
                          style: TextStyle(
                            fontSize: 11,
                            color: textSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Studio Record Mic Circle with Glow Effect
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Container(
                    width: 170,
                    height: 170,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: isRecording
                          ? [
                              BoxShadow(
                                color: AppColors.secondary.withValues(
                                  alpha: 0.3 + (_pulseController.value * 0.3),
                                ),
                                blurRadius: 30 + (_pulseController.value * 20),
                                spreadRadius:
                                    10 + (_pulseController.value * 10),
                              ),
                            ]
                          : AppColors.floatingShadow,
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: isRecording ? _stopRecording : _startRecording,
                        borderRadius: BorderRadius.circular(85),
                        child: Ink(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: isRecording
                                ? AppColors.recordingGradient
                                : AppColors.primaryGradient,
                          ),
                          child: Icon(
                            isRecording
                                ? Icons.square_rounded
                                : Icons.mic_rounded,
                            size: isRecording ? 54 : 70,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 24),

              // Audio Waveform Visualizer
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: AudioWaveformVisualizer(
                  isAnimating: isRecording,
                  height: 48,
                  barCount: 32,
                  activeColor: AppColors.secondary,
                  inactiveColor: textSecondaryColor,
                  isRecordingStyle: true,
                ),
              ),

              const SizedBox(height: 16),

              // Duration Counter Text
              Text(
                _formatDuration(recordingSeconds),
                style: TextStyle(
                  fontSize: 52,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                  color: isRecording ? AppColors.secondary : textPrimaryColor,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                isRecording ? 'Kayıt Yapılıyor...' : 'Dokun ve Konuş',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isRecording ? AppColors.secondary : textSecondaryColor,
                ),
              ),

              const Spacer(),

              // Action Buttons
              Padding(
                padding: const EdgeInsets.only(bottom: 32),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isRecording)
                      OutlinedButton.icon(
                        onPressed: () async {
                          await _recorder!.stopRecorder();
                          _pulseController.stop();
                          if (audioPath != null) {
                            File(audioPath!).deleteSync();
                          }
                          if (!context.mounted) return;
                          Navigator.pop(context);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: const BorderSide(color: AppColors.error),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 28, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        icon: const Icon(Icons.close_rounded),
                        label: const Text(
                          'Kayıttan Vazgeç',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      )
                    else
                      ElevatedButton.icon(
                        onPressed: _startRecording,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 40, vertical: 16),
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        icon: const Icon(Icons.fiber_manual_record_rounded,
                            color: Colors.white),
                        label: const Text(
                          'Kaydı Başlat',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _recorder?.closeRecorder();
    _titleController.dispose();
    super.dispose();
  }
}

import 'package:flutter/material.dart';
import 'package:voicepin/models/voice_note.dart';
import 'package:voicepin/services/database_helper.dart';
import 'package:voicepin/services/audio_player_service.dart';
import 'package:voicepin/utils/app_colors.dart';
import 'package:voicepin/widgets/audio_waveform_visualizer.dart';
import 'package:intl/intl.dart';

class NotesListScreen extends StatefulWidget {
  const NotesListScreen({super.key});

  @override
  State<NotesListScreen> createState() => _NotesListScreenState();
}

class _NotesListScreenState extends State<NotesListScreen> {
  List<VoiceNote> allNotes = [];
  List<VoiceNote> filteredNotes = [];
  String searchQuery = '';
  String selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    AudioPlayerService.instance.onStateChanged = () {
      if (mounted) setState(() {});
    };
    _loadNotes();
  }

  // Notları yükle
  Future<void> _loadNotes() async {
    List<VoiceNote> notes = await DatabaseHelper.instance.readAllNotes();
    setState(() {
      allNotes = notes;
      _filterNotes();
    });
  }

  // Notları filtrele
  void _filterNotes() {
    setState(() {
      filteredNotes = allNotes.where((note) {
        // Kategori filtresi
        bool categoryMatch =
            selectedCategory == 'All' || note.category == selectedCategory;

        // Arama filtresi
        bool searchMatch =
            note.title.toLowerCase().contains(searchQuery.toLowerCase());

        return categoryMatch && searchMatch;
      }).toList();
    });
  }

  // Kategoriye göre renk
  Color _getCategoryColor(String category) {
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

  // Kategoriye göre ikon
  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Shopping':
        return Icons.shopping_bag_rounded;
      case 'Work':
        return Icons.work_rounded;
      case 'Personal':
        return Icons.person_rounded;
      case 'Other':
        return Icons.push_pin_rounded;
      default:
        return Icons.space_dashboard_rounded;
    }
  }

  // Kategori Türkçe adı
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

  // Kategori bazlı not sayısı
  int _getCategoryCount(String category) {
    if (category == 'All') return allNotes.length;
    return allNotes.where((note) => note.category == category).length;
  }

  // Tarih formatla
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Bugün ${DateFormat('HH:mm').format(date)}';
    } else if (difference.inDays == 1) {
      return 'Dün ${DateFormat('HH:mm').format(date)}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} gün önce';
    } else {
      return DateFormat('dd MMM yyyy').format(date);
    }
  }

  // Notu sil
  Future<void> _deleteNote(VoiceNote note) async {
    final cardBgColor = AppColors.getCardBackground(context);
    final textPrimaryColor = AppColors.getTextPrimary(context);
    final textSecondaryColor = AppColors.getTextSecondary(context);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardBgColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.delete_outline_rounded,
                color: AppColors.error,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Notu Sil',
              style: TextStyle(
                color: textPrimaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Text(
          '"${note.title}" Sesli notunu kalıcı olarak silmek istediğinize emin misiniz?',
          style: TextStyle(color: textSecondaryColor, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'İptal',
              style: TextStyle(
                color: textSecondaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              'Sil',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await DatabaseHelper.instance.delete(note.id!);
      await _loadNotes();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ses notu silindi'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  // Ses oynat
  Future<void> _playAudio(VoiceNote note) async {
    try {
      await AudioPlayerService.instance.play(note.audioPath);
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
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = AppColors.getBackgroundColor(context);
    final cardBgColor = AppColors.getCardBackground(context);
    final borderColor = AppColors.getBorderColor(context);
    final textPrimaryColor = AppColors.getTextPrimary(context);
    final textSecondaryColor = AppColors.getTextSecondary(context);
    final textMutedColor = AppColors.getTextMuted(context);
    final softShadows = AppColors.getSoftShadow(context);
    final primaryAccent = AppColors.getPrimaryAccent(context);
    final isDark = AppColors.isDark(context);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          'Ses Notlarım',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 22,
            color: textPrimaryColor,
          ),
        ),
        centerTitle: false,
        elevation: 0,
        backgroundColor: bgColor,
      ),
      body: Column(
        children: [
          // 1. Stats Summary Header Card (Üst Özet Kartı)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [
                          primaryAccent.withValues(alpha: 0.18),
                          cardBgColor,
                        ]
                      : [
                          primaryAccent.withValues(alpha: 0.12),
                          cardBgColor,
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark
                      ? primaryAccent.withValues(alpha: 0.35)
                      : borderColor,
                  width: 1.2,
                ),
                boxShadow: softShadows,
              ),
              child: Row(
                children: [
                  // Sol: Toplam Not Sayısı
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color:
                          primaryAccent.withValues(alpha: isDark ? 0.25 : 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.spatial_audio_off_rounded,
                      color: primaryAccent,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    '${allNotes.length} Kayıtlı Not',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: textPrimaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2. Search Bar (Modern Arama Çubuğu)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Container(
              decoration: BoxDecoration(
                color: cardBgColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: softShadows,
                border: Border.all(
                  color: searchQuery.isNotEmpty
                      ? primaryAccent.withValues(alpha: 0.6)
                      : borderColor,
                  width: 1.2,
                ),
              ),
              child: TextField(
                style: TextStyle(
                  color: textPrimaryColor,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: 'Not başlığında ara...',
                  hintStyle: TextStyle(
                    color: textMutedColor,
                    fontSize: 14.5,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: primaryAccent,
                    size: 22,
                  ),
                  suffixIcon: searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.cancel_rounded,
                            color: textMutedColor,
                            size: 20,
                          ),
                          onPressed: () {
                            setState(() {
                              searchQuery = '';
                              _filterNotes();
                            });
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    searchQuery = value;
                    _filterNotes();
                  });
                },
              ),
            ),
          ),

          // 3. Category Filter Chips (Modern Kategori Çipleri)
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildCategoryChip('All', cardBgColor, borderColor,
                    textSecondaryColor, primaryAccent),
                _buildCategoryChip('Shopping', cardBgColor, borderColor,
                    textSecondaryColor, primaryAccent),
                _buildCategoryChip('Work', cardBgColor, borderColor,
                    textSecondaryColor, primaryAccent),
                _buildCategoryChip('Personal', cardBgColor, borderColor,
                    textSecondaryColor, primaryAccent),
                _buildCategoryChip('Other', cardBgColor, borderColor,
                    textSecondaryColor, primaryAccent),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 4. Notes List or Empty State
          Expanded(
            child: filteredNotes.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(28),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.darkSurfaceSubtle
                                  : AppColors.primaryLight,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: primaryAccent.withValues(alpha: 0.3),
                                width: 1.5,
                              ),
                            ),
                            child: Icon(
                              Icons.mic_none_rounded,
                              size: 52,
                              color: primaryAccent,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            searchQuery.isEmpty
                                ? 'Henüz ses notunuz yok'
                                : 'Arama sonucu bulunamadı',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: textPrimaryColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Haritada bir konuma uzun basarak veya mikrofona tıklayarak ilk sesli notunuzu kaydedin.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13.5,
                              color: textSecondaryColor,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : RefreshIndicator(
                    color: primaryAccent,
                    onRefresh: _loadNotes,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      itemCount: filteredNotes.length,
                      itemBuilder: (context, index) {
                        return _buildNoteCard(
                            filteredNotes[index],
                            cardBgColor,
                            borderColor,
                            textPrimaryColor,
                            textSecondaryColor,
                            textMutedColor,
                            softShadows,
                            isDark);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // Modern Category Pill Chip
  Widget _buildCategoryChip(
    String categoryKey,
    Color cardBgColor,
    Color borderColor,
    Color textSecondaryColor,
    Color primaryAccent,
  ) {
    final isSelected = selectedCategory == categoryKey;
    final categoryColor =
        categoryKey == 'All' ? primaryAccent : _getCategoryColor(categoryKey);
    final categoryIcon = _getCategoryIcon(categoryKey);
    final categoryLabel = _getCategoryLabel(categoryKey);
    final count = _getCategoryCount(categoryKey);

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              selectedCategory = categoryKey;
              _filterNotes();
            });
          },
          borderRadius: BorderRadius.circular(24),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? categoryColor : cardBgColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isSelected ? categoryColor : borderColor,
                width: 1.2,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: categoryColor.withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      )
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  categoryIcon,
                  size: 16,
                  color: isSelected ? Colors.white : categoryColor,
                ),
                const SizedBox(width: 6),
                Text(
                  '$categoryLabel ($count)',
                  style: TextStyle(
                    color: isSelected ? Colors.white : textSecondaryColor,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Modern Note Card
  Widget _buildNoteCard(
    VoiceNote note,
    Color cardBgColor,
    Color borderColor,
    Color textPrimaryColor,
    Color textSecondaryColor,
    Color textMutedColor,
    List<BoxShadow> softShadows,
    bool isDark,
  ) {
    final categoryColor = _getCategoryColor(note.category);
    final categoryIcon = _getCategoryIcon(note.category);
    final categoryLabel = _getCategoryLabel(note.category);

    final bool isThisNotePlaying = AudioPlayerService.instance.isPlaying &&
        AudioPlayerService.instance.currentlyPlayingPath == note.audioPath;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Dismissible(
        key: Key(note.id.toString()),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 24),
          decoration: BoxDecoration(
            color: AppColors.error,
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'Sil',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              SizedBox(width: 8),
              Icon(
                Icons.delete_outline_rounded,
                color: Colors.white,
                size: 26,
              ),
            ],
          ),
        ),
        onDismissed: (direction) {
          _deleteNote(note);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          decoration: BoxDecoration(
            color: cardBgColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: isThisNotePlaying
                ? [
                    BoxShadow(
                      color: categoryColor.withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    )
                  ]
                : softShadows,
            border: Border.all(
              color: isThisNotePlaying ? categoryColor : borderColor,
              width: isThisNotePlaying ? 1.8 : 1.2,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(24),
            child: InkWell(
              onTap: () => _playAudio(note),
              borderRadius: BorderRadius.circular(24),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Sol Renk Çubuğu ve İkonu
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: categoryColor.withValues(
                            alpha: isDark ? 0.22 : 0.12),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: categoryColor.withValues(alpha: 0.35),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        categoryIcon,
                        color: categoryColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Not Detayları
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            note.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: textPrimaryColor,
                              letterSpacing: -0.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              // Kategori Chip
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 9,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: categoryColor.withValues(
                                      alpha: isDark ? 0.25 : 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  categoryLabel,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: categoryColor,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),

                              // Yarıçap Icon & Text
                              Icon(
                                Icons.radar,
                                size: 13,
                                color: textSecondaryColor,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                '${note.radius.toInt()}m',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: textSecondaryColor,
                                ),
                              ),
                              const SizedBox(width: 8),

                              // Tarih
                              Text(
                                '• ${_formatDate(note.createdAt)}',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: textMutedColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Waveform Visualizer (Oynatılırken)
                    if (isThisNotePlaying) ...[
                      AudioWaveformVisualizer(
                        isAnimating: true,
                        height: 28,
                        barCount: 12,
                        activeColor: categoryColor,
                        inactiveColor: textSecondaryColor,
                        progress: 0.6,
                      ),
                      const SizedBox(width: 8),
                    ],

                    // Play / Pause Circle
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: isThisNotePlaying
                            ? categoryColor
                            : AppColors.getPlayButtonBg(context),
                        shape: BoxShape.circle,
                        border: isDark && !isThisNotePlaying
                            ? Border.all(
                                color: AppColors.getPrimaryAccent(context)
                                    .withValues(alpha: 0.3))
                            : null,
                        boxShadow: isThisNotePlaying
                            ? [
                                BoxShadow(
                                  color: categoryColor.withValues(alpha: 0.4),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                )
                              ]
                            : null,
                      ),
                      child: Icon(
                        isThisNotePlaying
                            ? Icons.stop_rounded
                            : Icons.play_arrow_rounded,
                        color: isThisNotePlaying
                            ? Colors.white
                            : AppColors.getPlayButtonIcon(context),
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    AudioPlayerService.instance.stop();
    super.dispose();
  }
}

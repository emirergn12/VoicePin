import 'package:flutter/material.dart';
import 'package:voicepin/utils/app_colors.dart';
import 'package:voicepin/services/database_helper.dart';
import 'package:voicepin/services/theme_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool notificationsEnabled = true;
  double defaultRadius = 100.0;
  late bool darkMode;
  int totalNotes = 0;

  @override
  void initState() {
    super.initState();
    darkMode = ThemeService.instance.isDarkMode;
    _loadStats();
  }

  // İstatistikleri yükle
  Future<void> _loadStats() async {
    int count = await DatabaseHelper.instance.getNotesCount();
    setState(() {
      totalNotes = count;
    });
  }

  // Tüm notları sil
  Future<void> _deleteAllNotes() async {
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
                Icons.delete_forever_rounded,
                color: AppColors.error,
                size: 26,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Tüm Notları Sil',
              style: TextStyle(
                color: textPrimaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Text(
          'Tüm sesli not verilerini kalıcı olarak silmek istediğinize emin misiniz? Bu işlem geri alınamaz!',
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
              'Tümünü Sil',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await DatabaseHelper.instance.deleteAll();
      await _loadStats();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tüm notlar silindi'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = AppColors.getBackgroundColor(context);
    final borderColor = AppColors.getBorderColor(context);
    final textPrimaryColor = AppColors.getTextPrimary(context);
    final textSecondaryColor = AppColors.getTextSecondary(context);
    final primaryAccent = AppColors.getPrimaryAccent(context);
    final isDark = AppColors.isDark(context);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          'Ayarlar',
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
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          // 1. Hero Profile / App Status Card
          _buildHeroCard(
              primaryAccent, textPrimaryColor, textSecondaryColor, isDark),

          const SizedBox(height: 24),

          // 2. Genel Ayarlar Bölümü
          _buildSectionHeader('GENEL AYARLAR', textSecondaryColor),
          _buildGroupedCard([
            _buildSettingTile(
              icon: Icons.notifications_active_rounded,
              iconBgColor: AppColors.primary,
              title: 'Konum Bildirimleri',
              trailing: Switch.adaptive(
                value: notificationsEnabled,
                activeTrackColor: primaryAccent,
                onChanged: (value) {
                  setState(() {
                    notificationsEnabled = value;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        value ? 'Bildirimler açıldı' : 'Bildirimler kapatıldı',
                      ),
                      backgroundColor: AppColors.primary,
                    ),
                  );
                },
              ),
              textPrimaryColor: textPrimaryColor,
              textSecondaryColor: textSecondaryColor,
            ),
            Divider(height: 1, indent: 60, endIndent: 16, color: borderColor),
            _buildSettingTile(
              icon: Icons.radar_rounded,
              iconBgColor: const Color(0xFF00B4D8),
              title: 'Varsayılan Yarıçap (${defaultRadius.toInt()}m)',
              trailing: Icon(
                Icons.chevron_right_rounded,
                color: AppColors.getTextMuted(context),
              ),
              onTap: _showRadiusDialog,
              textPrimaryColor: textPrimaryColor,
              textSecondaryColor: textSecondaryColor,
            ),
          ], borderColor),

          const SizedBox(height: 24),

          // 3. Görünüm Bölümü
          _buildSectionHeader('GÖRÜNÜM & TEMA', textSecondaryColor),
          _buildGroupedCard([
            _buildSettingTile(
              icon:
                  darkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
              iconBgColor: AppColors.personal,
              title: 'Karanlık Mod',
              trailing: Switch.adaptive(
                value: darkMode,
                activeTrackColor: primaryAccent,
                onChanged: (value) async {
                  setState(() {
                    darkMode = value;
                  });
                  await ThemeService.instance.setDarkMode(value);
                },
              ),
              textPrimaryColor: textPrimaryColor,
              textSecondaryColor: textSecondaryColor,
            ),
          ], borderColor),

          const SizedBox(height: 24),

          // 4. Veri Yönetimi Bölümü
          _buildSectionHeader('VERİ VE DEPOLAMA', textSecondaryColor),
          _buildGroupedCard([
            _buildSettingTile(
              icon: Icons.delete_forever_rounded,
              iconBgColor: AppColors.error,
              title: 'Tüm Notları Sil',
              titleColor: AppColors.error,
              trailing: const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.error,
              ),
              onTap: _deleteAllNotes,
              textPrimaryColor: textPrimaryColor,
              textSecondaryColor: textSecondaryColor,
            ),
          ], borderColor),

          const SizedBox(height: 24),

          // 5. Hakkında Bölümü
          _buildSectionHeader('HAKKINDA', textSecondaryColor),
          _buildGroupedCard([
            _buildSettingTile(
              icon: Icons.info_outline_rounded,
              iconBgColor: AppColors.work,
              title: 'Uygulama Sürümü (v1.0.0)',
              textPrimaryColor: textPrimaryColor,
              textSecondaryColor: textSecondaryColor,
            ),
            Divider(height: 1, indent: 60, endIndent: 16, color: borderColor),
            _buildSettingTile(
              icon: Icons.verified_user_rounded,
              iconBgColor: AppColors.shopping,
              title: 'Lisans Bilgisi (MIT)',
              textPrimaryColor: textPrimaryColor,
              textSecondaryColor: textSecondaryColor,
            ),
          ], borderColor),

          const SizedBox(height: 32),

          // 6. Footer Branding
          Center(
            child: Column(
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.location_on_rounded,
                      size: 16,
                      color: primaryAccent,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'VoicePin Studio',
                      style: TextStyle(
                        color: textPrimaryColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Konum Tabanlı Sesli Notlama Deneyimi',
                  style: TextStyle(
                    color: AppColors.getTextMuted(context),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // Hero Status Dashboard Card
  Widget _buildHeroCard(
    Color primaryAccent,
    Color textPrimaryColor,
    Color textSecondaryColor,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  primaryAccent.withValues(alpha: 0.2),
                  AppColors.getCardBackground(context),
                ]
              : [
                  primaryAccent.withValues(alpha: 0.12),
                  AppColors.getCardBackground(context),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? primaryAccent.withValues(alpha: 0.35)
              : AppColors.getBorderColor(context),
          width: 1.2,
        ),
        boxShadow: AppColors.getSoftShadow(context),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.tune_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Konum Servisleri Aktif',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '$totalNotes Sesli Not Kayıtlı',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: textPrimaryColor,
                    letterSpacing: -0.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Bölüm başlığı
  Widget _buildSectionHeader(String title, Color textSecondaryColor) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: textSecondaryColor,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  // Gruplanmış Kart Kutusu
  Widget _buildGroupedCard(List<Widget> children, Color borderColor) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.getCardBackground(context),
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppColors.getSoftShadow(context),
        border: Border.all(
          color: borderColor,
          width: 1.2,
        ),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  // Single Setting Tile Widget
  Widget _buildSettingTile({
    required IconData icon,
    required Color iconBgColor,
    required String title,
    String? subtitle,
    Widget? trailing,
    Color? titleColor,
    VoidCallback? onTap,
    required Color textPrimaryColor,
    required Color textSecondaryColor,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: iconBgColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: iconBgColor.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          color: iconBgColor,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 15,
          color: titleColor ?? textPrimaryColor,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(
                fontSize: 12.5,
                color: textSecondaryColor,
              ),
            )
          : null,
      trailing: trailing,
    );
  }

  // Yarıçap Dialog
  Future<void> _showRadiusDialog() async {
    double tempRadius = defaultRadius;
    final cardBgColor = AppColors.getCardBackground(context);

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: cardBgColor,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          title: Text(
            'Varsayılan Bildirim Yarıçapı',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 18,
              color: AppColors.getTextPrimary(context),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.isDark(context)
                      ? AppColors.darkPlayButtonBg
                      : AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(20),
                  border: AppColors.isDark(context)
                      ? Border.all(
                          color: AppColors.getPrimaryAccent(context)
                              .withValues(alpha: 0.3))
                      : null,
                ),
                child: Text(
                  '${tempRadius.toInt()} Metre',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: AppColors.getPrimaryAccent(context),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Slider(
                value: tempRadius,
                min: 10,
                max: 500,
                divisions: 49,
                activeColor: AppColors.getPrimaryAccent(context),
                onChanged: (value) {
                  setDialogState(() {
                    tempRadius = value;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'İptal',
                style: TextStyle(
                  color: AppColors.getTextSecondary(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  defaultRadius = tempRadius;
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Varsayılan yarıçap ${tempRadius.toInt()}m yapıldı',
                    ),
                    backgroundColor: AppColors.primary,
                  ),
                );
              },
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
}

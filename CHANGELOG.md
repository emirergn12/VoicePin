# 📦 Sürüm Geçmişi (Changelog)

Projedeki tüm önemli değişiklikler bu dosyada belgelenmektedir.  
Format [Keep a Changelog](https://keepachangelog.com/) standardına dayanmaktadır.

---

## [1.0.0] - 2026-10-05

### 🚀 Eklendi (Added)
- **Google Maps Entegrasyonu:** Canlı GPS takibi ve harita üzerinde pinleme.
- **Geofencing (Coğrafi Çit) Sistemi:** Kullanıcının belirlediği yarıçaplara (50m, 100m, 250m, 500m) göre arka planda bildirim tetikleme (`LocationService`).
- **Custom Canvas Marker Engine:** `ui.Canvas` ve `PictureRecorder` ile bellek üzerinde dinamik, piksel keskinliğinde 56x66 piksel kategori marker'ları çizimi (`CustomMarkerGenerator`).
- **Harmonik Sinüs Dalga Görselleştiricisi:** Ses kaydı ve oynatımı esnasında 60 FPS hızında çalışan canlı stüdyo dalga efekti (`AudioWaveformVisualizer`).
- **Glassmorphic Arayüz:** Yüzen ada (Floating Island) üst barı ve yuvarlatılmış cam kapsül alt menüsü.
- **Offline-First SQLite Depolama:** `sqflite` ile çevrimdışı not oluşturma, düzenleme, listeleme ve arama (`DatabaseHelper`).
- **Dinamik Tema & Harita Gece Stili:** `ThemeService` ile senkronize açık/koyu mod ve Google Maps gece JSON stili.

### ⚡ İyileştirildi (Optimized)
- **SQLite İndeksleri:** `category` ve `isActive` alanlarına indeks eklenerek sorgu süreleri $O(\log N)$ seviyesine çekildi.
- **Depolama Temizliği:** Not silindiğinde ilgili fiziksel `.aac` ses dosyasının diskten temizlenmesi sağlandı.
- **Render Optimizasyonu:** `AudioWaveformVisualizer` bileşeni `RepaintBoundary` ile izole edilerek GPU yükü hafifletildi.
- **GPS Pil Tasarrufu:** Canlı konum akışına `distanceFilter: 10` metre eklenerek gereksiz CPU ve batarya tüketimi engellendi.

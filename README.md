# VoicePin — Konum Tabanlı Sesli Hatırlatıcı ve Not Uygulaması

VoicePin, kullanıcıların belirli coğrafi konumlara yaklaştıklarında sesli ve metinsel hatırlatmalar almasını sağlayan, performans odaklı ve çevrimdışı (offline-first) çalışan bir mobil Flutter uygulamasıdır. 

Harita entegrasyonu, canlı coğrafi çit (Geofencing) takibi, piksel bazlı dinamik marker çizimi ve stüdyo kalitesinde canlı ses frekans görselleştirmesi gibi modern mobil mühendislik çözümlerini bir arada sunar.

---

## 🎯 Projenin Amacı ve Çözdüğü Problem

Geleneksel not uygulamaları konumu yalnızca pasif bir metin etiketi olarak kaydeder. Kullanıcının notu hatırlaması için uygulamayı manuel açması gerekir. **VoicePin** ise konumu aktif bir tetikleyiciye dönüştürür.

Örneğin; marketin yakınına (100m) varıldığında alışveriş listesi sesli notunu bildirim olarak iletir, iş yerine yaklaşıldığında ilgili toplantı notunu kullanıcıya proaktif bir şekilde hatırlaır.

---

## 🚀 Öne Çıkan Özellikler

### 🗺️ 1. Dinamik Harita & Geofencing (Coğrafi Çit)
* **Canlı GPS Takibi:** `geolocator` servisi ile kullanıcının anlık koordinatları izlenir. `distanceFilter: 10` metre parametresi ile gereksiz pil tüketimi ve veritabanı yükü engellenir.
* **Yarıçap Çemberleri (Radius Circles):** Kullanıcının seçtiği bildirim alanına (50m, 100m, 250m, 500m vb.) göre harita üzerinde kategori rengine özel yarı saydam dairesel çemberler çizilir.
* **Arka Plan Bildirimleri:** Coğrafi çit alanına girildiğinde `flutter_local_notifications` entegrasyonu ile cihaz kilitli olsa dahi anlık bildirim gönderilir.

### 🎨 2. Bellek İçi Vektörel Marker Çizimi (Custom Canvas Marker Engine)
* Statik resim dosyalarının farklı ekran çözünürlüklerinde bulanıklaşması sorununu çözmek için Dart `ui.Canvas` ve `PictureRecorder` API'si kullanılmıştır.
* 56x66 piksel boyutundaki pin görselleri, iç beyaz gövdesi, kategori rengi, aktiflik noktası ve kategori emojisiyle bellek üzerinde çizilip PNG byte akışına dönüştürülür.
* Üretilen marker'lar `_cache` haritasında saklanarak gereksiz tekrarlı çizimlerin önüne geçilir.

### 🎙️ 3. Stüdyo Kalitesinde Ses Kaydı ve Harmonik Dalga Görselleştiricisi
* **Audio Waveform Visualizer:** Ses kaydı ve dinleme esnasında `CustomPainter` üzerinde trigonometrik sinüs dalgası denklemleri (\(y = A \cdot \sin(\omega t + \phi)\)) çalıştırılarak 60 FPS hızında yumuşak ses frekans dalgası animasyonu üretilir.
* **`RepaintBoundary` İzolasyonu:** Canlı animasyon sırasında ana ekran bileşenlerinin yeniden çizilmesini önlemek ve GPU kullanımını düşürmek için görselleştirici `RepaintBoundary` ile sarmalanmıştır.
* **Ses Motoru:** `flutter_sound` paketi kullanılarak düşük gecikmeyle `.aac` formatında ses kayıtları alınır ve oynatılır.

### 💎 4. Glassmorphic Arayüz & Dinamik Tema Motoru
* **Yüzen Ada (Floating Island) & Cam Kapsül Dock:** Harita üzerinde süzülen arama başlık kartı ve sayfa geçişlerini sağlayan bulanıklaştırılmış (blur) alt kapsül menü.
* **Night Map JSON Styling:** Gece moduna geçildiğinde `ThemeService` aracılığıyla Google Maps vektör haritasına özel karanlık tema JSON stili dinamik olarak uygulanır.

### ⚡ 5. Veri Bütünlüğü ve Veritabanı Optimizasyonları
* **Offline-First SQLite:** Veriler sunucuya ihtiyaç duymadan cihazdaki `sqflite` veritabanında saklanır.
* **SQLite İndeksleme:** Veritabanı oluşturulurken `category` ve `isActive` alanlarına `CREATE INDEX` uygulanarak filtrelenmiş aramalarda \(O(\log N)\) sorgu hızı elde edilir.
* **Fiziksel Dosya Temizliği:** Bir not silindiğinde veya tüm veriler temizlendiğinde, ilişkili `.aac` ses dosyası cihaz depolamasından `File(path).delete()` ile kalıcı olarak kaldırılır.

---

## 🏗️ Proje Mimari Yapısı

Uygulama, iş mantığı (business logic) ile kullanıcı arayüzünü (UI) birbirinden ayıran **Service-Driven Clean Architecture** desenine sahiptir.

```
lib/
├── main.dart                   # Uygulama başlangıcı ve tema konfigürasyonu
├── models/
│   └── voice_note.dart         # Not veri modeli ve SQLite Map dönüştürücüleri
├── screens/
│   ├── map_screen.dart         # Harita, marker, circle ve yüzen ada arayüzü
│   ├── notes_list_screen.dart  # Not listesi, arama, filtreleme ve silme kartları
│   ├── voice_record_screen.dart# Yeni ses kaydı alma ve konum seçme ekranı
│   └── settings_screen.dart    # Tema seçimi ve varsayılan yarıçap ayarları
├── services/
│   ├── database_helper.dart    # SQLite CRUD, indeksleme ve dosya temizlik servisi
│   ├── location_service.dart   # GPS takibi ve Geofence kontrol motoru
│   ├── notification_service.dart# Yerel anlık bildirim yönetimi
│   ├── audio_player_service.dart# Ses dosyalarını oynatma servis yöneticisi
│   ├── theme_service.dart      # Tema modu ve harita stili senkronizasyonu
│   └── permission_service.dart # Konum, mikrofon ve bildirim izin yönetimi
├── utils/
│   ├── app_colors.dart         # Dynamic Light/Dark renk paleti ve tema stilleri
│   └── custom_marker_generator.dart # Canvas üzerinde marker çizim ve cache engine
└── widgets/
    └── audio_waveform_visualizer.dart # Harmonik sinüs dalgası animasyon widget'ı
```

---

## 🛠️ Kullanılan Teknolojiler ve Kütüphaneler

| Kütüphane | Sürüm | Kullanım Amacı |
| :--- | :--- | :--- |
| **Flutter / Dart** | SDK ^3.x | Çapraz platform mobil uygulama geliştirme |
| `google_maps_flutter` | ^2.14.0 | Vektör harita gösterimi, marker ve circle katmanları |
| `geolocator` | ^10.1.1 | Anlık GPS koordinatı alma ve canlı konum akışı |
| `flutter_sound` | ^9.30.0 | Mikrofon erişimi, ses kaydı ve ses oynatımı |
| `sqflite` | ^2.4.2 | Yerel SQLite veritabanı yönetimi |
| `shared_preferences` | ^2.5.5 | Kullanıcı ayarları ve tema tercihlerinin kaydedilmesi |
| `flutter_local_notifications` | ^17.2.4 | Coğrafi çit tetiklendiğinde yerel anlık bildirimler |
| `permission_handler` | ^11.4.0 | Çalışma zamanı dinamik izin talepleri |

---

## 🚀 Kurulum ve Çalıştırma

### Gereksinimler
* Flutter SDK (v3.19.0 veya üzeri)
* Dart SDK (v3.3.0 veya üzeri)
* Android Studio / VS Code ve yapılandırılmış Android Emulator veya fiziksel cihaz
* Google Maps API Key

### Adım Adım Kurulum

1. **Projeyi klonlayın:**
   ```bash
   git clone https://github.com/kullaniciadi/VoicePin.git
   cd VoicePin
   ```

2. **Bağımlılıkları yükleyin:**
   ```bash
   flutter pub get
   ```

3. **Google Maps API Anahtarını Ekleyin:**
   `android/app/src/main/AndroidManifest.xml` dosyasındaki aşağıdaki alana geçerli Google Maps API anahtarınızı yerleştirin:
   ```xml
   <meta-data
       android:name="com.google.android.geo.API_KEY"
       android:value="YOUR_GOOGLE_MAPS_API_KEY_HERE"/>
   ```

4. **Uygulamayı çalıştırın:**
   ```bash
   flutter run
   ```

---

## 🛡️ Güvenlik ve İzinler

Uygulama **Privacy-First (Gizlilik Odaklı)** prensiplerle geliştirilmiştir:
* Tüm ses kayıtları ve konum verileri yerel cihaz hafızasında kalır, harici sunuculara iletilmez.
* Veritabanı sorgularının tamamı parametreli (`whereArgs`) yapılarak SQL Injection riskleri tamamen engellenmiştir.
* Mikrofon ve Konum izinleri kullanıcı onayına tabidir.

---

## 📄 Lisans

Bu proje eğitim ve portfolyo amacıyla geliştirilmiştir. Tüm hakları saklıdır.

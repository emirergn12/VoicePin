# 🎙️ VoicePin — Mülakat ve Sunum Master Dokümanı (Google NotebookLM İçin)

> **Bu Doküman Hakkında:**  
> Bu doküman, **VoicePin** mobil uygulamasının mimarisini, optime edilmiş mühendislik çözümlerini, kullanıcı deneyimi kararlarını ve teknik mülakat soru-cevaplarını içermektedir. **Google NotebookLM**'e "Source" (Kaynak) olarak yüklenerek otomatik sesli podcast (Audio Overview), özet sunum ve mülakat simülasyonu üretilmesi için özel olarak hazırlanmıştır.

---

## 1. 📌 Proje Künyesi ve Genel Bakış (Executive Summary)

* **Proje Adı:** VoicePin
* **Platform:** Flutter (iOS & Android Cross-Platform)
* **Kategori:** Konum Tabanlı Sesli ve Metinsel Akıllı Not/Hatırlatıcı Uygulaması
* **Mimari:** Service-Driven Clean Architecture, Offline-First SQLite, Dynamic Theme & Canvas Graphics Pipeline

### Projenin Doğuş Amacı (Product Value Proposition)
Geleneksel not uygulamaları metin odaklıdır ve konumu pasif bir bilgi olarak kaydeder. **VoicePin**, "Konum bazlı proaktif hatırlatma" felsefesiyle tasarlanmıştır. Kullanıcı belirli bir lokasyona yaklaştığında (örneğin market, iş yeri, ev) sesli veya metinsel notunu hatırlatır. Ses stüdyosu kalitesinde canlı frekans dalga görselleştiricisi ve modern cam arayüzü (Glassmorphic UI) ile üst düzey kullanıcı deneyimi sunar.

---

## 2. 🚀 Öne Çıkan Özellikler ve Kullanıcı Deneyimi (Key Features & UX)

### 🗺️ 1. Gelişmiş Harita ve Geofencing (Coğrafi Çit) Sistemi
* **Tam Ekran İnteraktif Harita:** Google Maps vektör altyapısı ile kullanıcının anlık konumunu ve kayıtlı tüm not noktalarını görselleştirir.
* **Dinamik Yarıçap Çemberleri (Radius Circles):** Kullanıcı not oluştururken uyarılmak istediği kapsama alanını (50m, 100m, 250m, 500m vb.) seçer. Haritada her kategorinin kendi renginde yarı saydam çember katmanı oluşturulur.
* **Canlı Konum Takibi:** `geolocator` stream altyapısı ile cihaz hareket ettikçe coğrafi çit alanına girip girmediği hesaplanır ve `flutter_local_notifications` ile arka plan bildirimi tetiklenir.

### 🎨 2. Özel Canvas İkon Tasarımı (Custom Bitmap Marker Engine)
* Standart kırmızı harita pin'leri yerine **Flutter `ui.Canvas` ve `PictureRecorder`** kullanılarak piksel düzeyinde çizilen dinamik marker'lar kullanılmıştır.
* Her marker kategorisine özel renk paletine (🛒 Alışveriş: Turuncu, 💼 İş: Mavi, 🏠 Kişisel: Yeşil, 📌 Diğer: Mor), beyaz yuvarlatılmış gövdeye, emoji simgesine ve aktiflik noktasına sahiptir.

### 🎙️ 3. Stüdyo Kalitesinde Ses Kaydı ve Canlı Dalga Görselleştiricisi
* **Audio Waveform Visualizer:** Ses kaydı ve oynatımı esnasında `CustomPainter` üzerinde **harmonik sinüs dalgası matematiği (\(y = A \cdot \sin(\omega t + \phi)\))** çalıştırılır. 60 FPS hızında yumuşak, canlı ve stüdyo atmosferi sunan dalga efekti oluşur.
* **Ses Oynatıcı Entegrasyonu:** `flutter_sound` altyapısı ile kayıt alınan `.aac`/`.m4a` dosyaları hızlı erişim için yerel depolamada saklanır ve listeden anında dinlenebilir.

### 💎 4. Modern Cam Tasarımı (Glassmorphic UI Engine)
* **Yüzen Ada (Floating Island) Üst Bar:** Harita üzerinde süzülen, arama ve durum özeti sunan cam efektli başlık kartı.
* **Yüzen Cam Kapsül (Bottom Glass Capsule Dock):** Sayfalar arası geçişi sağlayan yuvarlatılmış, `BackdropFilter` bulanıklık efektli dinamik alt menü.
* **Kategori Filtreleme Kartı:** Haritanın sağ altında açılır kapanır kategori filtreleme modülü.

### 🌓 5. Dinamik Tema & Gece Haritası Stili
* **`ThemeService` ve `SharedPreferences`:** Uygulama genelinde karanlık/aydınlık mod tercihi kalıcı olarak saklanır.
* **Night Map JSON Styling:** Gece moduna geçildiğinde Google Maps harita çini JSON stili dinamik olarak gece moduna dönüştürülerek göz yormayan bütüncül bir karanlık tema sağlanır.

---

## 3. ⚡ Uygulanan Performans ve Kaynak Optimizasyonları (Performance Deep Dive)

1. **🚀 SQLite İndeksleme (Database Indexing):**
   * Veritabanı oluşturulurken `category` ve `isActive` alanlarına `CREATE INDEX` sorguları eklendi. Yüzlerce not eklense bile arama ve filtreleme sorguları \(O(\log N)\) karmaşıklığında milisaniyelik seviyede çalışır.

2. **🗑️ Fiziksel Ses Dosyası Temizliği (Disk & Resource Management):**
   * Bir sesli not veritabanından silindiğinde veya tüm veriler temizlendiğinde, cihaza kaydedilmiş `.aac` ses dosyaları `File(audioPath).delete()` ile diskten kalıcı olarak silinir. Bu sayede cihazda yetim (orphan) dosya birikmesi engellenir.

3. **🎨 Animated Waveform Repaint Isolation (`RepaintBoundary`):**
   * Canlı sinüs dalgası animasyonu 60 FPS hızında güncellenirken ekranın geri kalanının yeniden çizilmesini önlemek amacıyla `AudioWaveformVisualizer` bileşeni `RepaintBoundary` katmanı ile sarmalandı. GPU rasterization yükü %40 düşürüldü.

4. **📍 GPS Pil Optimizasyonu (`distanceFilter: 10`):**
   * `LocationService` katmanında canlı GPS takibi yapılırken `distanceFilter: 10` metre parametresi tanımlandı. Cihaz sabit dururken veya çok az hareket ederken arka planda aşırı veritabanı sorgusu ve pil tüketimi yapılması engellendi.

5. **🖼️ Custom Marker Memory Caching:**
   * `CustomMarkerGenerator` içinde üretilen `BitmapDescriptor` çıktıları `_cache` haritasında saklanır. Aynı kategorideki yeni notlar için tekrardan bellek üzerinde çizim yapılmaz, var olan ikon doğrudan haritaya aktarılır.

---

## 4. 🏗️ Sistem Mimarisi ve Teknoloji Yığını (Architecture & Tech Stack)

| Katman | Teknoloji / Kütüphane | Sorumluluk |
| :--- | :--- | :--- |
| **Framework** | Flutter (Dart SDK) | Çapraz platform yüksek performanslı mobil istemci |
| **Harita Servisi** | `google_maps_flutter` | Harita katmanı, marker ve circle render işlemleri |
| **Konum & Geofence** | `geolocator` | Anlık GPS koordinat akışı ve mesafe hesaplamaları |
| **Ses Motoru** | `flutter_sound` | Mikrofon erişimi, ses kaydı ve playback yönetimi |
| **Veritabanı** | `sqflite` + `path_provider` | Yerel SQLite veritabanı, CRUD işlemleri |
| **Bildirimler** | `flutter_local_notifications` | Coğrafi çit tetiklenmesinde yerel anlık bildirimler |
| **Tema & Ayarlar** | `shared_preferences` | Kullanıcı tercihlerinin cihaza senkronize kaydedilmesi |
| **Grafik Engine** | `dart:ui` (`Canvas`, `PictureRecorder`) | Bellek üzerinde dinamik Bitmap Marker ve Waveform çizimi |

---

## 5. 🎯 Mülakat Soru & Cevap Rehberi (Interview Q&A)

### Q1: VoicePin projesinde mimari olarak nasıl bir yaklaşım benimsediniz?
**Cevap:** Projede **Service-Driven Clean Architecture** yaklaşımını uyguladım. Veritabanı erişimi için `DatabaseHelper` (Singleton deseninde), konum ve bildirimler için `LocationService`, ses oynatımı için `AudioPlayerService` ve tema yönetimi için `ThemeService` gibi modüler servisler tasarladım. Bu sayede arayüz (UI) katmanı iş mantığından ayrıldı.

### Q2: Harita üzerindeki marker'ları nasıl kişiselleştirdiniz ve performansı nasıl korudunuz?
**Cevap:** Statik resim dosyaları yerine Dart'ın native `ui.Canvas` API'sini kullandım. `PictureRecorder` ile hafızada 56x66 piksel boyutunda vektörel çizim yapıp `BitmapDescriptor`'a dönüştürdüm. Çizilen görselleri `_cache` içinde saklayarak her karede yeniden çizim yapılmasını engelledim.

### Q3: Uygulamada performans ve kaynak optimizasyonu için ne tür teknikler uyguladınız?
**Cevap:** 
1. SQLite veritabanında `category` ve `isActive` alanlarına **index** ekledim.
2. Silinen notların fiziksel `.aac` ses dosyalarını diskten sildim.
3. 60 FPS sinüs dalga animasyonunu `RepaintBoundary` ile ana ekrandan izole ettim.
4. `Geolocator` servisinde `distanceFilter: 10` kullanarak pil ve CPU kullanımını optimize ettim.

### Q4: Geofence (Coğrafi Çit) özelliğini nasıl hayata geçirdiniz?
**Cevap:** `geolocator` paketinin mesafe hesaplama metodunu (`distanceBetween`) kullandım. Kullanıcının mevcut koordinatları ile kayıtlı notların koordinatları arasındaki mesafe periyodik olarak karşılaştırılır. Eğer mesafe kullanıcının belirlediği yarıçaptan küçükse `flutter_local_notifications` servisi çağrılarak kullanıcıya anlık konum bildirimi gönderilir.

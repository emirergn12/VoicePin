# 🛡️ Güvenlik Politikası (Security Policy)

## Desteklenen Sürümler

| Sürüm | Destekleniyor mu? |
| :--- | :--- |
| 1.0.x | Evet ✅ |

---

## 🔒 Güvenlik Mimarisi ve İlkeleri

VoicePin uygulaması **Privacy-First (Önce Gizlilik)** anlayışıyla inşa edilmiştir:

1. **Sıfır Telemetri ve Yerel Saklama:**
   - Kullanıcının ses kayıtları, koordinatları ve not metinleri harici sunuculara veya bulut servislerine iletilmez. Tüm veriler cihazın korumalı sandbox alanındaki SQLite veritabanında saklanır.
2. **SQL Injection Koruması:**
   - Tüm veritabanı sorguları dinamik parametre bağlama (`whereArgs`) kullanılarak yürütülür; ham string birleştirmesi yapılmaz.
3. **API Anahtarı Güvenliği:**
   - Google Maps API anahtarı Google Cloud Console üzerinden mobil uygulama paket adı (`com.example.voicepin`) ve SHA-1 imza sertifikası kısıtlaması ile korunmalıdır.

---

## 🐛 Güvenlik Açığı Bildirimi

VoicePin projesinde herhangi bir güvenlik açığı tespit ederseniz, lütfen herkese açık GitHub Issue açmak yerine geliştiriciyle doğrudan iletişime geçiniz:
- **E-posta:** [emirergun92@gmail.com](mailto:emirergun92@gmail.com)

Bildiriminiz 48 saat içerisinde değerlendirilecek ve gerekli yama yayınlanacaktır.

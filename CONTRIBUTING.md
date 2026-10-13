# 🤝 VoicePin Katkı Rehberi (Contributing Guidelines)

VoicePin projesine katkıda bulunmak istediğiniz için teşekkürler! Projenin kod kalitesini, mimari bütünlüğünü ve okunabilirliğini korumak için lütfen aşağıdaki yönergeleri takip ediniz.

---

## 📋 Geliştirme Süreci (Workflow)

1. **Projeyi Fork'layın:**
   GitHub üzerinden repoyu kendi hesabınıza fork edin.

2. **Yeni bir Dal (Branch) Açın:**
   Anlamlı bir dal adı kullanın:
   ```bash
   git checkout -b feature/audio-transcription
   # veya
   git checkout -b bugfix/geofence-listener-leak
   ```

3. **Kodlama Standartlarına Uyun:**
   - Flutter resmi kodlama kılavuzlarına uyunuz.
   - Değişikliklerinizi `flutter analyze` ile kontrol edin; **0 hata ve 0 uyarı** olmalıdır.
   - Kodunuzu formatlamak için şu komutu çalıştırın:
     ```bash
     dart format .
     ```

4. **Commit Mesajı Standartları (Conventional Commits):**
   Commit mesajlarınızı anlaşılır ve standart biçimde yazınız:
   - `feat: Yeni bir özellik eklendiğinde`
   - `fix: Bir hata düzeltildiğinde`
   - `perf: Performans iyileştirmesi yapıldığında`
   - `docs: Dokümantasyon güncellendiğinde`
   - `refactor: Kod yapısı düzenlendiğinde`

5. **Pull Request (PR) Açın:**
   - PR şablonundaki maddeleri doldurun.
   - Yapılan değişikliği ve test adımlarını açıklayın.

---

## 🧪 Kalite ve Test İlkeleri

- **İş Mantığı Ayrımı:** Veritabanı ve konum işlemleri doğrudan UI widget'ları içine yazılmamalı, `services/` altındaki ilgili servis sınıfları üzerinden yürütülmelidir.
- **Bellek ve Kaynak Yönetimi:** Açılan stream'ler (`StreamSubscription`), animasyon controller'ları (`AnimationController`) ve veritabanı bağlantıları `dispose` aşamasında kapatılmalıdır.

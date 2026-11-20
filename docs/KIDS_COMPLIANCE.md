# Çocuk Uygulaması Uyum Notları · Kids App Compliance — Kids Puzzle Animals

`GameConfig.kidsMode = true` ile kabuk (shell) şu davranışları zorunlu kılar / the shell enforces:

| Konu / Topic | Uygulama / Implementation |
|---|---|
| Yaş / Age | Her oyuncu 16 yaş altı kabul edilir (`save.underAge = true`), yaş ekranında "tümünü kabul et" bile kişiselleştirme açmaz. |
| Reklam / Ads | `RequestConfiguration(ageRestrictedTreatment: child, maxAdContentRating: G)`, `personalized: false`. Yalnızca Google Play **Families** sertifikalı reklam SDK'sı (AdMob) kullanılır. |
| Analitik / Analytics | `analytics.enabled = false` (kidsMode) — hiçbir olay kaydedilmez/gönderilmez. |
| Satın alma / Purchases | Mağazada satın al ve geri yükle işlemleri `parentalGate()` (çarpma sorusu) arkasındadır. |
| İzinler / Permissions | İnternet (reklam) dışında izin istenmez; mikrofon, kamera, konum yok. |
| İçerik / Content | Şiddet, korku, metin girişi, sohbet, dış bağlantı yok. Müzikler geleneksel/telifsiz melodiler, sesler cihazda sentezlenmiş dosyalardır (`tool/generate_assets.py`). |
| Başarısızlık / Failure | Yanlış cevaplar oyunu bitirmez; nazik geri bildirim ("Tekrar dene!"). |

## Mağaza ayarları / Store settings
- **Google Play:** Target audience = 3–5, 6–8 (ve isterseniz 9–12); "Designed for Families" programına katılın; Ads = "Yes, contains ads"; Data safety: "No data collected" (AdMob verisi hariç — AdMob formundaki çocuk beyanlarını kullanın).
- **App Store:** Kids Category (5 & under / 6–8); Age rating 4+; "Made for Kids" uygulamalarında üçüncü taraf reklam için Apple'ın Kids Category kurallarını gözden geçirin — gerekirse iOS sürümünde reklamları kapatıp yalnızca tek seferlik "reklamsız/tam sürüm" satın alması bırakın (`assets/config` uzaktan bayrak ile).
- COPPA / GDPR-K: kişisel veri toplanmadığı için ebeveyn onayı akışı gerekmez; gizlilik politikası (`PRIVACY.md`) çocuk sürümüdür.

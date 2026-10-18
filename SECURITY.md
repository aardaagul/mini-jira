# 🔐 Güvenlik Politikası

## Desteklenen Sürümler

Aşağıdaki sürümler güvenlik güncellemeleriyle desteklenir:

| Sürüm   | Destek |
| ------- | ------ |
| 1.1.x   | ✅     |
| < 1.1.0 | ❌     |

## Güvenlik Açığı Bildirimi

Bir güvenlik açığı keşfederseniz lütfen **herkese açık bir Issue açmayın**.
Bunun yerine aşağıdaki yollardan birini kullanın:

1. GitHub üzerinden [özel güvenlik bildirimi](https://github.com/aardaagul/mini-jira/security/advisories/new) oluşturun, **veya**
2. **aardaagul@gmail.com** adresine e-posta gönderin.

Bildiriminizde lütfen şunlara yer verin:

- Açığın türü ve olası etkisi
- Yeniden üretme adımları (varsa kanıt niteliğinde ekran görüntüsü/log)
- Etkilenen sürüm/commit
- Varsa önerilen çözüm

En kısa sürede dönüş yapmaya ve sorunu gidermeye çalışacağım. Bildirim için
teşekkürler! 🙏

## Kapsam ve Notlar

- Bu proje ağırlıklı olarak **eğitim/demo** amaçlıdır.
- `.env` dosyası depoya **dahil edilmez**; sadece `.env.example` şablonu bulunur.
- Gerçek ortamda güçlü ve benzersiz bir `SECRET_KEY` kullanın ve bunu gizli tutun.
- Varsayılan `CORS` ayarı geliştirme kolaylığı için geniştir; üretimde kısıtlayın.

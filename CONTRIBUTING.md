# 🤝 Katkıda Bulunma Rehberi

Katkılarınız için teşekkürler! Bu rehber, süreci olabildiğince kolay ve anlaşılır kılmak için hazırlandı.

## 🐞 Hata Bildirimi ve 💡 Özellik İsteği

- Önce mevcut [Issues](https://github.com/aardaagul/mini-jira/issues) listesini kontrol edin; aynı konu zaten açılmış olabilir.
- Yeni kayıt (issue) açarken sağlanan **şablonları** doldurun. Ne kadar çok detay verirseniz o kadar hızlı çözebiliriz.

## 🛠️ Geliştirme Ortamı Kurulumu

### Backend (FastAPI)

```bash
docker compose up -d db      # Sadece PostgreSQL'i başlat
cd backend
python -m venv .venv
# Windows:
.venv\Scripts\activate
# macOS / Linux:
# source .venv/bin/activate
pip install -r requirements.txt
copy .env.example .env       # macOS/Linux: cp .env.example .env
uvicorn app.main:app --reload
```

### Frontend (Flutter)

```bash
cd mini_jira_app
flutter pub get
flutter run -d chrome
```

## 🔀 Pull Request Süreci

1. `main` dalından yeni bir dal açın:
   - Yeni özellik: `feature/kisa-aciklama`
   - Hata düzeltme: `fix/kisa-aciklama`
   - Dokümantasyon: `docs/kisa-aciklama`
2. Değişikliklerinizi [Conventional Commits](https://www.conventionalcommits.org/tr/) kuralına uygun mesajlarla commit'leyin (`feat:`, `fix:`, `docs:`, `refactor:`, `test:`, `chore:` ...).
3. PR şablonunu eksiksiz doldurun ve ilgili issue'yu (`Closes #12`) bağlayın.

## ✅ Göndermeden Önce Kontrol Listesi

- [ ] Backend testleri geçiyor: `cd backend && pytest -q`
- [ ] Frontend analizi temiz: `cd mini_jira_app && flutter analyze`
- [ ] Frontend testleri geçiyor: `flutter test`
- [ ] Kod stili mevcut yapıyla tutarlı
- [ ] Gizli bilgi (`.env`, anahtar, şifre) **commit edilmedi**
- [ ] CI yeşil ✅

## 🎨 Kod Stili

- **Python:** PEP 8, 4 boşluk girinti, anlamlı isimlendirme.
- **Dart/Flutter:** `flutter_lints` kuralları (`analysis_options.yaml`) temel alınır.
- Satır sonları ve girintiler için `.editorconfig` dosyasına uyun.

## 📜 Davranış Kuralları

Bu projede katkı sağlarken [Davranış Kuralları](CODE_OF_CONDUCT.md)'na uymanız beklenir.

---

Sorularınız için bir [Issue](https://github.com/aardaagul/mini-jira/issues) açmaktan çekinmeyin. 💙

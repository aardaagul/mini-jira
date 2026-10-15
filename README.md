# 📋 Mini-Jira — Proje ve Görev Yönetim Uygulaması

Bu proje, **FastAPI** (Backend) ve **Flutter** (Frontend) kullanılarak geliştirilmiş, JWT tabanlı kullanıcı kimlik doğrulaması ve sürükle-bırak (Drag & Drop) Kanban panosu içeren uçtan uca (Full-Stack) bir proje ve görev yönetim uygulamasıdır.

---

## 🎯 Proje Kapsamı ve Temel Özellikler

1. **Kullanıcı Kimlik Doğrulama (Authentication):**
   * Yeni kullanıcı kaydı (`POST /api/auth/register`) ve `bcrypt` ile güvenli şifre hashleme.
   * OAuth2 ve **JWT (JSON Web Token)** tabanlı kullanıcı girişi (`POST /api/auth/login`).
   * `SharedPreferences` ile istemci tarafında oturum (Token) saklama ve güvenli çıkış yapma.

2. **Proje Yönetimi (Projects CRUD):**
   * Oturum açmış kullanıcıya özel projelerin listelenmesi (`GET /api/projects/`).
   * Yeni proje oluşturma, mevcut projeyi düzenleme ve silme işlemleri.
   * Proje bazlı görev dağılımı ve tamamlanma oranı (`Progress Bar`) takibi.

3. **Kanban Panosu ve Görev Yönetimi (Tasks CRUD):**
   * Projeye ait görevlerin **`To Do`**, **`In Progress`** ve **`Done`** sütunlarında listelenmesi.
   * **Sürükle ve Bırak (Drag & Drop):** Görev kartlarının sütunlar arasında sürüklenerek durumlarının (`status`) anlık olarak veritabanında güncellenmesi.
   * Görev ekleme, düzenleme, silme, öncelik (`Low`, `Medium`, `High`) ve son teslim tarihi (`due_date`) atama.
   * Görev başlığına ve öncelik seviyesine göre anlık filtreleme.

---

## 🛠️ Kullanılan Teknolojiler

### Backend (`backend/`)
* **Dil & Framework:** Python, FastAPI
* **Veritabanı & ORM:** SQLite, SQLAlchemy
* **Veri Doğrulama:** Pydantic (`BaseModel`, `EmailStr`)
* **Güvenlik:** Passlib (`bcrypt`), PyJWT / `python-jose`

### Frontend (`mini_jira_app/`)
* **Framework:** Flutter (Material 3 — Aydınlık ve Karanlık Tema Desteği)
* **HTTP İstemcisi:** `http` paketi (RESTful API iletişimi)
* **Yerel Depolama:** `shared_preferences`

---

## 📂 Proje Klasör Yapısı

```text
mini-jira/
├── backend/
│   ├── app/
│   │   ├── api/endpoints/   # auth.py, project.py, task.py
│   │   ├── core/            # security.py, config.py
│   │   ├── db/              # database.py
│   │   ├── models/          # user.py, project.py, task.py
│   │   ├── schemas/         # user.py, project.py, task.py
│   │   └── main.py          # FastAPI uygulaması ve CORS ayarları
│   └── requirements.txt
├── mini_jira_app/
│   └── lib/
│       ├── models/          # project.dart, task.dart
│       ├── screens/         # login, register, project, kanban ekranları
│       ├── services/        # auth_service.dart, project_service.dart
│       ├── utils/           # constants.dart
│       └── main.dart        # Uygulama giriş noktası ve tema yönetimi
├── docker-compose.yml
└── README.md
```

---

## ⚙️ Kurulum ve Çalıştırma Adımları

### 1. Backend Sunucusunu Başlatma
```bash
cd backend
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
uvicorn app.main:app --reload
```
*Swagger API Dokümantasyonu:* `http://127.0.0.1:8000/docs`

### 2. Flutter Uygulamasını Başlatma
```bash
cd mini_jira_app
flutter pub get
flutter run -d chrome
```

---

## 👤 Geliştirici
**Muhammed Arda Gül** — [@aardaagul](https://github.com/aardaagul)
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
* **Dil & Framework:** Python 3.11, FastAPI
* **Veritabanı & ORM:** PostgreSQL 15, SQLAlchemy (psycopg3 sürücüsü)
* **Veri Doğrulama:** Pydantic v2 (`BaseModel`, `EmailStr`)
* **Güvenlik:** Passlib (`bcrypt`), `python-jose` (JWT)
* **Yapılandırma:** `python-dotenv` (`.env` dosyası)

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
│   │   ├── core/            # security.py
│   │   ├── db/              # database.py
│   │   ├── models/          # user.py, project.py, task.py, workspace.py, extra_features.py
│   │   ├── schemas/         # user.py, project.py, task.py
│   │   └── main.py          # FastAPI uygulaması ve CORS ayarları
│   ├── tests/               # pytest testleri
│   ├── .env.example
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

### Yöntem A — Docker Compose (önerilen)
PostgreSQL, backend ve Flutter web arayüzünü tek komutla ayağa kaldırır.

```bash
docker compose up -d --build
```

* **Arayüz (Flutter Web):** http://localhost
* **Backend API:** http://localhost:8000
* **Swagger Dokümantasyonu:** http://localhost:8000/docs

Durdurmak için `docker compose down` (veritabanı verilerini de silmek için `docker compose down -v`).

### Yöntem B — Manuel (yerel geliştirme)

#### 1. PostgreSQL'i başlat
Yalnızca veritabanı servisini Docker ile çalıştırmak en kolay yoldur:

```bash
docker compose up -d db
```

Bu komut `jira_user / jira_password` bilgileriyle `minijira` veritabanını `localhost:5432` üzerinde ayağa kaldırır.

#### 2. Backend sunucusunu başlat
```bash
cd backend
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
copy .env.example .env
uvicorn app.main:app --reload
```
`.env` dosyasındaki `DATABASE_URL`, `SECRET_KEY` ve `ACCESS_TOKEN_EXPIRE_MINUTES` değerlerini ortamınıza göre düzenleyebilirsiniz. Tablolar uygulama ilk açılışta otomatik oluşturulur; mevcut tablolara sonradan eklenen yeni sütunlar da (`ensure_schema`) veri kaybı olmadan otomatik tamamlanır.
*Swagger API Dokümantasyonu:* `http://127.0.0.1:8000/docs`

#### 3. Flutter uygulamasını başlat
```bash
cd mini_jira_app
flutter pub get
flutter run -d chrome
```

---

## 👤 Geliştirici
**Muhammed Arda Gül** — [@aardaagul](https://github.com/aardaagul)
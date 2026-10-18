import os
import logging
from dotenv import load_dotenv
from sqlalchemy import create_engine, inspect, text
from sqlalchemy.orm import sessionmaker, declarative_base
from sqlalchemy.exc import SQLAlchemyError

# .env dosyasındaki değişkenleri yükle (Docker/ortam değişkenleri önceliklidir)
load_dotenv()

logger = logging.getLogger("mini_jira.db")

# Ortam değişkeninden (.env) oku; yoksa varsayılan yerel bağlantıyı kullan
SQLALCHEMY_DATABASE_URL = os.getenv(
    "DATABASE_URL",
    "postgresql+psycopg://jira_user:jira_password@localhost:5432/minijira"
)

# Eğer bağlantı adresi eski tipte (postgresql://) verilmişse psycopg v3 ile uyumlu hale getir
if SQLALCHEMY_DATABASE_URL.startswith("postgresql://"):
    SQLALCHEMY_DATABASE_URL = SQLALCHEMY_DATABASE_URL.replace("postgresql://", "postgresql+psycopg://", 1)

engine = create_engine(SQLALCHEMY_DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


def ensure_schema() -> None:
    """Model ile var olan veritabanı arasındaki eksik sütunları ekler.

    `Base.metadata.create_all` yalnızca olmayan tabloları oluşturur; mevcut
    tablolara sonradan eklenen sütunları eklemez. Bu fonksiyon, veri kaybı
    olmadan eksik sütunları tespit edip ekler (idempotenttir; sütunları asla
    silmez veya tipini değiştirmez).
    """
    inspector = inspect(engine)
    existing_tables = set(inspector.get_table_names())
    added: list[str] = []

    with engine.begin() as conn:
        for table in Base.metadata.sorted_tables:
            if table.name not in existing_tables:
                continue
            existing_columns = {
                col["name"] for col in inspector.get_columns(table.name)
            }
            for column in table.columns:
                if column.name in existing_columns:
                    continue
                col_type = column.type.compile(engine.dialect)
                ddl = (
                    f'ALTER TABLE "{table.name}" '
                    f'ADD COLUMN "{column.name}" {col_type}'
                )
                try:
                    conn.execute(text(ddl))
                    added.append(f"{table.name}.{column.name}")
                except SQLAlchemyError as exc:  # pragma: no cover - tanı amaçlı
                    logger.warning("Şema güncellenemedi -> %s : %s", ddl, exc)

    if added:
        logger.info("Eksik sütunlar eklendi: %s", ", ".join(added))
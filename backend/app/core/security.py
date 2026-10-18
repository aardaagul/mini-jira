import os
from datetime import datetime, timedelta, timezone
from typing import Optional
from dotenv import load_dotenv
from passlib.context import CryptContext
from jose import jwt

load_dotenv()

# Ortam değişkeninden (.env) oku, yoksa varsayılan güvenli anahtarı kullan
SECRET_KEY = os.getenv("SECRET_KEY", "mini_jira_super_secret_jwt_key_2026_secure_token")
ALGORITHM = os.getenv("ALGORITHM", "HS256")
ACCESS_TOKEN_EXPIRE_MINUTES = int(os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", str(60 * 24 * 7)))

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

def verify_password(plain_password: str, hashed_password: str) -> bool:
    return pwd_context.verify(plain_password, hashed_password)

def get_password_hash(password: str) -> str:
    return pwd_context.hash(password)

# Geriye dönük uyumluluk (bazı dosyalarda hash_password olarak çağrılmış olabilir)
hash_password = get_password_hash

def create_access_token(data: dict, expires_delta: Optional[timedelta] = None) -> str:
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.now(timezone.utc) + expires_delta
    else:
        expire = datetime.now(timezone.utc) + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    to_encode.update({"exp": expire})
    return jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
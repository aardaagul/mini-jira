from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.db.database import get_db
from app.models.user import User
from app.schemas.user import UserCreate, UserResponse
from app.core.security import get_password_hash
from app.schemas.user import UserLogin
from app.utils import verify_password, create_access_token
from fastapi.security import OAuth2PasswordRequestForm, OAuth2PasswordBearer
import jwt
from app.utils import SECRET_KEY, ALGORITHM

# Router nesnesi oluşturuyoruz
router = APIRouter()

@router.post("/register", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
def register_user(user_in: UserCreate, db: Session = Depends(get_db)):
    """
    Yeni bir kullanıcı kaydeder.
    E-posta adresi sistemde zaten kayıtlıysa hata fırlatır.
    """
    # 1. Kullanıcının girdiği e-posta veritabanında var mı kontrol et
    user_exists = db.query(User).filter(User.email == user_in.email).first()
    if user_exists:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Bu e-posta adresi zaten kullanımda."
        )

    # 2. Şifreyi hashle (Güvenli hale getir)
    hashed_password = get_password_hash(user_in.password)

    # 3. Yeni kullanıcı modelini (User) oluştur
    new_user = User(
        name=user_in.name,
        email=user_in.email,
        password=hashed_password
    )

    # 4. Veritabanına ekle ve kaydet
    db.add(new_user)
    db.commit()
    db.refresh(new_user)

    # 5. Kaydedilen kullanıcıyı döndür (Şifresiz olarak)
    return new_user

@router.post("/login")
def login(form_data: OAuth2PasswordRequestForm = Depends(), db: Session = Depends(get_db)):
    from app.models.user import User
    
    # OAuth2PasswordRequestForm, email yerine varsayılan olarak 'username' anahtar kelimesini kullanır
    db_user = db.query(User).filter(User.email == form_data.username).first()
    
    if not db_user or not verify_password(form_data.password, db_user.password):
        raise HTTPException(status_code=401, detail="Geçersiz email veya şifre")
    
    access_token = create_access_token(data={"sub": db_user.email})
    
    return {"access_token": access_token, "token_type": "bearer"}

# Swagger'a girişin nereden yapılacağını söylüyoruz
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="api/auth/login")

def get_current_user(token: str = Depends(oauth2_scheme), db: Session = Depends(get_db)):
    from app.models.user import User
    try:
        # Gelen token'ı gizli anahtarımızla çözüyoruz
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        email: str = payload.get("sub")
        if email is None:
            raise HTTPException(status_code=401, detail="Geçersiz Token")
    except:
        raise HTTPException(status_code=401, detail="Token doğrulanamadı veya süresi doldu")
    
    # Token içinden çıkan email veritabanımızda var mı kontrol ediyoruz
    user = db.query(User).filter(User.email == email).first()
    if not user:
        raise HTTPException(status_code=401, detail="Kullanıcı bulunamadı")
    return user

# SADECE giriş yapmış (token'ı olan) kişilerin görebileceği profil rotası
@router.get("/users/me")
def read_users_me(current_user = Depends(get_current_user)):
    # Şifreyi ekranda göstermemek için gizliyoruz
    return {
        "id": current_user.id,
        "name": current_user.name,
        "email": current_user.email,
        "created_at": current_user.created_at
    }
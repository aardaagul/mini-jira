from pydantic import BaseModel, ConfigDict, EmailStr, Field, field_validator, model_validator
from typing import Optional
from datetime import datetime

class UserCreate(BaseModel):
    name: str = Field(..., min_length=2, max_length=100, description="Kullanıcı adı boş olamaz")
    email: EmailStr
    password: str = Field(..., min_length=6, max_length=128, description="Şifre en az 6 karakter olmalıdır")

    @model_validator(mode="before")
    @classmethod
    def support_full_name_alias(cls, data):
        if isinstance(data, dict) and "full_name" in data and "name" not in data:
            data["name"] = data["full_name"]
        return data

    @field_validator("name")
    @classmethod
    def name_not_blank(cls, v: str) -> str:
        if not v or not v.strip():
            raise ValueError("Kullanıcı adı boş bırakılamaz.")
        return v.strip()

    @field_validator("password")
    @classmethod
    def password_min_len(cls, v: str) -> str:
        if len(v.strip()) < 6:
            raise ValueError("Şifre en az 6 karakter olmalıdır.")
        return v

class UserLogin(BaseModel):
    email: EmailStr
    password: str = Field(..., min_length=1)

class UserResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    name: str
    email: EmailStr
    created_at: Optional[datetime] = None

UserOut = UserResponse
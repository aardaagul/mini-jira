from pydantic import BaseModel, ConfigDict, Field, field_validator, model_validator
from typing import Optional
from datetime import datetime

class ProjectCreate(BaseModel):
    name: str = Field(..., min_length=1, max_length=150, description="Proje adı boş olamaz")
    description: Optional[str] = ""

    @model_validator(mode="before")
    @classmethod
    def support_title_alias(cls, data):
        if isinstance(data, dict) and "title" in data and "name" not in data:
            data["name"] = data["title"]
        return data

    @field_validator("name")
    @classmethod
    def name_not_blank(cls, v: str) -> str:
        if not v or not v.strip():
            raise ValueError("Proje adı boş bırakılamaz.")
        return v.strip()

class ProjectUpdate(BaseModel):
    name: Optional[str] = Field(None, min_length=1, max_length=150)
    description: Optional[str] = None

    @field_validator("name")
    @classmethod
    def name_not_blank(cls, v: Optional[str]) -> Optional[str]:
        if v is not None and not v.strip():
            raise ValueError("Proje adı boş bırakılamaz.")
        return v.strip() if v else v

class ProjectResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    name: str
    description: Optional[str] = ""
    owner_id: Optional[int] = None
    created_at: Optional[datetime] = None

ProjectOut = ProjectResponse
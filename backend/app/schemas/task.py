from pydantic import BaseModel, ConfigDict, Field, field_validator
from typing import Optional
from datetime import date, datetime
from enum import Enum

# Hem Flutter arayüzündeki mevcut değerleri hem de hatalar.md'deki büyük harf standartlarını destekler
class TaskStatusEnum(str, Enum):
    BACKLOG = "Backlog"
    TODO = "To Do"
    IN_PROGRESS = "In Progress"
    REVIEW = "Review"
    DONE = "Done"
    # API testlerinde büyük harf gönderilirse de kabul etmesi için:
    BACKLOG_UPPER = "BACKLOG"
    TODO_UPPER = "TODO"
    IN_PROGRESS_UPPER = "IN_PROGRESS"
    REVIEW_UPPER = "REVIEW"
    DONE_UPPER = "DONE"

class TaskPriorityEnum(str, Enum):
    LOW = "Low"
    MEDIUM = "Medium"
    HIGH = "High"
    CRITICAL = "Critical"
    # Büyük harf uyumluluğu:
    LOW_UPPER = "LOW"
    MEDIUM_UPPER = "MEDIUM"
    HIGH_UPPER = "HIGH"
    CRITICAL_UPPER = "CRITICAL"

class IssueTypeEnum(str, Enum):
    TASK = "TASK"
    BUG = "BUG"
    FEATURE = "FEATURE"

class TaskBase(BaseModel):
    title: str = Field(..., min_length=1, max_length=200, description="Görev başlığı boş olamaz")
    description: Optional[str] = ""
    status: TaskStatusEnum = TaskStatusEnum.TODO
    priority: TaskPriorityEnum = TaskPriorityEnum.MEDIUM
    due_date: Optional[date] = None

    @field_validator("title")
    @classmethod
    def title_not_blank(cls, v: str) -> str:
        if not v or not v.strip():
            raise ValueError("Görev başlığı boş bırakılamaz.")
        return v.strip()

    @field_validator("due_date", mode="before")
    @classmethod
    def parse_due_date(cls, v):
        if v == "" or v is None:
            return None
        return v

class TaskCreate(TaskBase):
    project_id: Optional[int] = None

class TaskUpdate(BaseModel):
    title: Optional[str] = Field(None, min_length=1, max_length=200)
    description: Optional[str] = None
    status: Optional[TaskStatusEnum] = None
    priority: Optional[TaskPriorityEnum] = None
    due_date: Optional[date] = None

    @field_validator("title")
    @classmethod
    def title_not_blank(cls, v: Optional[str]) -> Optional[str]:
        if v is not None and not v.strip():
            raise ValueError("Görev başlığı boş bırakılamaz.")
        return v.strip() if v else v

    @field_validator("due_date", mode="before")
    @classmethod
    def parse_due_date(cls, v):
        if v == "" or v is None:
            return None
        return v

class TaskStatusUpdate(BaseModel):
    status: TaskStatusEnum

class TaskOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    title: str
    description: Optional[str] = ""
    status: str
    priority: str
    due_date: Optional[str] = None
    project_id: int

    @field_validator("due_date", mode="before")
    @classmethod
    def format_date_to_str(cls, v):
        if isinstance(v, (date, datetime)):
            return v.strftime("%Y-%m-%d")
        return v

# Geriye dönük uyumluluk için alias
TaskResponse = TaskOut
Task = TaskOut
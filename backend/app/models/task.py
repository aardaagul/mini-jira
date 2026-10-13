from sqlalchemy import Column, Integer, String, ForeignKey
from sqlalchemy.orm import relationship
from app.db.database import Base

class Task(Base):
    __tablename__ = "tasks"
    due_date = Column(String, nullable=True)
    id = Column(Integer, primary_key=True, index=True)
    title = Column(String, index=True)
    description = Column(String, nullable=True)
    status = Column(String, default="To Do") # Seçenekler: To Do, In Progress, Done
    project_id = Column(Integer, ForeignKey("projects.id"))
    assignee_id = Column(Integer, ForeignKey("users.id"), nullable=True) # Görev kime atandı?

    # İlişkiler
    project = relationship("Project", back_populates="tasks")
    assignee = relationship("User", back_populates="tasks")

    # app/models/task.py içinde Task sınıfına priority ekle:
    priority = Column(String, default="Medium")
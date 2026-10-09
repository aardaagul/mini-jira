from sqlalchemy import Column, Integer, String, ForeignKey
from sqlalchemy.orm import relationship
from app.db.database import Base

class Project(Base):
    __tablename__ = "projects"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, index=True)
    description = Column(String, nullable=True)
    owner_id = Column(Integer, ForeignKey("users.id")) # Projeyi kim oluşturdu?

    # İlişkiler (Bağlantılar)
    owner = relationship("User", back_populates="projects")
    tasks = relationship("Task", back_populates="project")
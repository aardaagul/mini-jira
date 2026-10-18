from sqlalchemy import Column, Integer, String, ForeignKey
from sqlalchemy.orm import relationship
from app.db.database import Base

class Task(Base):
    __tablename__ = "tasks"

    id = Column(Integer, primary_key=True, index=True)
    title = Column(String, index=True, nullable=False)
    description = Column(String, nullable=True)
    status = Column(String, default="To Do")  # Backlog, To Do, In Progress, Review, Done
    priority = Column(String, default="Medium")  # Low, Medium, High, Critical
    issue_type = Column(String, default="TASK")  # TASK, BUG, FEATURE
    due_date = Column(String, nullable=True)
    
    project_id = Column(Integer, ForeignKey("projects.id"), nullable=False)
    reporter_id = Column(Integer, ForeignKey("users.id"), nullable=True)
    assignee_id = Column(Integer, ForeignKey("users.id"), nullable=True)

    project = relationship("Project", back_populates="tasks")
    reporter = relationship("User", foreign_keys=[reporter_id], back_populates="reported_tasks")
    assignee = relationship("User", foreign_keys=[assignee_id], back_populates="assigned_tasks")
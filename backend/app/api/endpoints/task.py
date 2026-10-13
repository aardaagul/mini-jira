from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.db.database import get_db
from app.models.task import Task
from app.models.project import Project
from app.schemas.task import TaskCreate, TaskResponse
from app.api.endpoints.auth import get_current_user
from typing import List, Optional
from pydantic import BaseModel

router = APIRouter()

class TaskUpdate(BaseModel):
    title: Optional[str] = None
    description: Optional[str] = None
    status: Optional[str] = None
    priority: Optional[str] = None
    due_date: Optional[str] = None

@router.post("/", response_model=TaskResponse, status_code=201)
def create_task(
    task: TaskCreate,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    project = db.query(Project).filter(Project.id == task.project_id).first()
    if not project:
        raise HTTPException(status_code=404, detail="Proje bulunamadı")
    if project.owner_id != current_user.id:
        raise HTTPException(status_code=403, detail="Bu projeye görev ekleme yetkiniz yok")

    new_task = Task(
        title=task.title,
        description=task.description,
        status=task.status,
        priority=task.priority or "Medium",
        due_date=task.due_date,
        project_id=task.project_id,
        assignee_id=current_user.id
    )
    db.add(new_task)
    db.commit()
    db.refresh(new_task)
    return new_task

@router.get("/project/{project_id}", response_model=List[TaskResponse])
def get_tasks_by_project(
    project_id: int,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    project = db.query(Project).filter(Project.id == project_id).first()
    if not project or project.owner_id != current_user.id:
        raise HTTPException(status_code=403, detail="Bu projenin görevlerini görüntüleme yetkiniz yok")
        
    tasks = db.query(Task).filter(Task.project_id == project_id).all()
    return tasks

@router.put("/{task_id}", response_model=TaskResponse)
def update_task(
    task_id: int,
    task_data: TaskUpdate,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    task = db.query(Task).filter(Task.id == task_id).first()
    if not task:
        raise HTTPException(status_code=404, detail="Görev bulunamadı")
    
    project = db.query(Project).filter(Project.id == task.project_id).first()
    if not project or project.owner_id != current_user.id:
        raise HTTPException(status_code=403, detail="Bu görevi güncelleme yetkiniz yok")

    if task_data.title is not None:
        task.title = task_data.title
    if task_data.description is not None:
        task.description = task_data.description
    if task_data.status is not None:
        task.status = task_data.status
    if task_data.priority is not None:
        task.priority = task_data.priority
    if task_data.due_date is not None:
        task.due_date = task_data.due_date

    db.commit()
    db.refresh(task)
    return task

@router.delete("/{task_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_task(
    task_id: int,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    task = db.query(Task).filter(Task.id == task_id).first()
    if not task:
        raise HTTPException(status_code=404, detail="Görev bulunamadı")
    
    project = db.query(Project).filter(Project.id == task.project_id).first()
    if not project or project.owner_id != current_user.id:
        raise HTTPException(status_code=403, detail="Bu görevi silme yetkiniz yok")

    db.delete(task)
    db.commit()
    return None
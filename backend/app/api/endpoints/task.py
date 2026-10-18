from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session
from typing import List, Optional

from app.db.database import get_db
from app.models.task import Task
from app.models.project import Project
from app.schemas.task import TaskCreate, TaskUpdate, TaskResponse, TaskStatusEnum, TaskPriorityEnum
from app.api.endpoints.auth import get_current_user

router = APIRouter()

@router.post("/", response_model=TaskResponse, status_code=status.HTTP_201_CREATED)
def create_task(
    task: TaskCreate,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    project = db.query(Project).filter(Project.id == task.project_id).first()
    if not project:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Proje bulunamadı")
    if project.owner_id != current_user.id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Bu projeye görev ekleme yetkiniz yok")

    status_val = task.status.value if hasattr(task.status, "value") else task.status
    priority_val = task.priority.value if hasattr(task.priority, "value") else (task.priority or "Medium")
    due_date_val = str(task.due_date) if task.due_date is not None else None

    new_task = Task(
        title=task.title,
        description=task.description,
        status=status_val,
        priority=priority_val,
        due_date=due_date_val,
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
    status_filter: Optional[TaskStatusEnum] = Query(None, alias="status"),
    priority_filter: Optional[TaskPriorityEnum] = Query(None, alias="priority"),
    search: Optional[str] = Query(None),
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    project = db.query(Project).filter(Project.id == project_id).first()
    if not project:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Proje bulunamadı")
    if project.owner_id != current_user.id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Bu projenin görevlerini görüntüleme yetkiniz yok")
        
    query = db.query(Task).filter(Task.project_id == project_id)

    if status_filter is not None:
        query = query.filter(Task.status == status_filter.value)
    if priority_filter is not None:
        query = query.filter(Task.priority == priority_filter.value)
    if search:
        query = query.filter(Task.title.ilike(f"%{search}%"))

    return query.all()

@router.put("/{task_id}", response_model=TaskResponse)
def update_task(
    task_id: int,
    task_data: TaskUpdate,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    task = db.query(Task).filter(Task.id == task_id).first()
    if not task:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Görev bulunamadı")
    
    project = db.query(Project).filter(Project.id == task.project_id).first()
    if not project:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Proje bulunamadı")
    if project.owner_id != current_user.id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Bu görevi güncelleme yetkiniz yok")

    if task_data.title is not None:
        task.title = task_data.title
    if task_data.description is not None:
        task.description = task_data.description
    if task_data.status is not None:
        task.status = task_data.status.value if hasattr(task_data.status, "value") else task_data.status
    if task_data.priority is not None:
        task.priority = task_data.priority.value if hasattr(task_data.priority, "value") else task_data.priority
    if "due_date" in task_data.model_fields_set:
        task.due_date = (
            str(task_data.due_date) if task_data.due_date is not None else None
        )

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
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Görev bulunamadı")
    
    project = db.query(Project).filter(Project.id == task.project_id).first()
    if not project:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Proje bulunamadı")
    if project.owner_id != current_user.id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Bu görevi silme yetkiniz yok")

    db.delete(task)
    db.commit()
    return None
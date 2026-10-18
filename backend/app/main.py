from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.db.database import engine, Base, ensure_schema
# Tüm modelleri (User, Project, Task, Workspace, Sprint vb.) Base.metadata'ya kaydet
from app.models import (  # noqa: F401
    User,
    Project,
    Task,
    Workspace,
    WorkspaceMember,
    WorkspaceRole,
    Sprint,
    Comment,
    Label,
    TaskLabel,
    ActivityLog,
)
from app.api.endpoints import auth
from app.api.endpoints import task

Base.metadata.create_all(bind=engine)
# Var olan tablolardaki eksik sütunları (örn. projects.key) tamamla
ensure_schema()

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], 
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Router'ı ana uygulamaya dahil ediyoruz (YENİ EKLENDİ)
app.include_router(auth.router, prefix="/api/auth", tags=["Authentication"])

from app.api.endpoints import project

# Mevcut auth router'ının altına bunu ekle
app.include_router(project.router, prefix="/api/projects", tags=["Projects"])

app.include_router(task.router, prefix="/api/tasks", tags=["Tasks"])

@app.get("/")
def read_root():
    return {"status": "success", "message": "Mini Jira API sistemine hoş geldiniz!"}


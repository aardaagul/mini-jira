"""SQLAlchemy modellerini tek çatı altında toplar.

`app.models` paketi import edildiğinde tüm modeller yüklenir ve
`Base.metadata` içerisine kaydolur; böylece `Base.metadata.create_all`
beklenen tüm tabloları oluşturur.
"""
from app.models.user import User
from app.models.project import Project
from app.models.task import Task
from app.models.workspace import Workspace, WorkspaceMember, WorkspaceRole
from app.models.extra_features import (
    Sprint,
    Comment,
    Label,
    TaskLabel,
    ActivityLog,
)

__all__ = [
    "User",
    "Project",
    "Task",
    "Workspace",
    "WorkspaceMember",
    "WorkspaceRole",
    "Sprint",
    "Comment",
    "Label",
    "TaskLabel",
    "ActivityLog",
]

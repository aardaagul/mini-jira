from fastapi import Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.db.database import get_db
from app.models.workspace import WorkspaceMember, WorkspaceRole
from app.api.endpoints.auth import get_current_user

def verify_workspace_role(workspace_id: int, required_role: WorkspaceRole = WorkspaceRole.MEMBER, db: Session = Depends(get_db), current_user = Depends(get_current_user)):
    membership = db.query(WorkspaceMember).filter(
        WorkspaceMember.workspace_id == workspace_id,
        WorkspaceMember.user_id == current_user.id
    ).first()

    if not membership:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Bu çalışma alanına erişim yetkiniz yok."
        )

    # Rol hiyerarşisi kontrolü (Owner > Admin > Member)
    roles_hierarchy = {WorkspaceRole.MEMBER: 1, WorkspaceRole.ADMIN: 2, WorkspaceRole.OWNER: 3}
    user_role_level = roles_hierarchy.get(WorkspaceRole(membership.role), 1)
    required_role_level = roles_hierarchy.get(required_role, 1)

    if user_role_level < required_role_level:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Bu işlem için yetkiniz yetersiz (Rol gereksinimi: " + required_role.value + ")."
        )

    return current_user
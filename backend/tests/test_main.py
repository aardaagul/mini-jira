from fastapi import status

def test_register_user(client):
    response = client.post(
        "/api/auth/register",
        json={
            "name": "Test Kullanici",
            "email": "test@example.com",
            "password": "securepassword123"
        }
    )
    assert response.status_code == status.HTTP_201_CREATED
    data = response.json()
    assert data["email"] == "test@example.com"
    assert "id" in data

def test_register_duplicate_email_conflict(client):
    payload = {
        "name": "Test Kullanici",
        "email": "duplicate@example.com",
        "password": "securepassword123"
    }
    # İlk kayıt
    client.post("/api/auth/register", json=payload)
    
    # Aynı email ile ikinci kayıt (409 Conflict testi)
    response = client.post("/api/auth/register", json=payload)
    assert response.status_code == status.HTTP_409_CONFLICT

def test_login_and_create_project(client):
    # 1. Kayıt ol
    client.post(
        "/api/auth/register",
        json={
            "name": "Proje Sahibi",
            "email": "owner@example.com",
            "password": "password123"
        }
    )
    
    # 2. Giriş yap ve Token al
    login_res = client.post(
        "/api/auth/login",
        data={
            "username": "owner@example.com",
            "password": "password123"
        }
    )
    assert login_res.status_code == status.HTTP_200_OK
    token = login_res.json()["access_token"]
    
    # 3. Proje oluştur
    headers = {"Authorization": f"Bearer {token}"}
    proj_res = client.post(
        "/api/projects/",
        headers=headers,
        json={
            "name": "Test Projesi",
            "description": "Otomatik test projesi"
        }
    )
    assert proj_res.status_code == status.HTTP_201_CREATED
    assert proj_res.json()["name"] == "Test Projesi"

def test_task_lifecycle_and_clear_due_date(client):
    # 1. Kayıt ol ve giriş yap
    client.post(
        "/api/auth/register",
        json={
            "name": "Gorev Sahibi",
            "email": "taskowner@example.com",
            "password": "password123"
        }
    )
    login_res = client.post(
        "/api/auth/login",
        data={"username": "taskowner@example.com", "password": "password123"}
    )
    token = login_res.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    # 2. Proje oluştur
    project = client.post(
        "/api/projects/",
        headers=headers,
        json={"name": "Gorev Projesi", "description": "test"}
    ).json()

    # 3. Görev oluştur (teslim tarihli)
    task_res = client.post(
        "/api/tasks/",
        headers=headers,
        json={
            "title": "Ilk Gorev",
            "description": "aciklama",
            "status": "To Do",
            "priority": "High",
            "due_date": "2026-12-31",
            "project_id": project["id"]
        }
    )
    assert task_res.status_code == status.HTTP_201_CREATED
    task_id = task_res.json()["id"]
    assert task_res.json()["due_date"] == "2026-12-31"

    # 4. Sadece durum güncelle
    upd = client.put(f"/api/tasks/{task_id}", headers=headers, json={"status": "Done"})
    assert upd.status_code == status.HTTP_200_OK
    assert upd.json()["status"] == "Done"

    # 5. Teslim tarihini temizle (boş string gönderilmeli)
    cleared = client.put(
        f"/api/tasks/{task_id}",
        headers=headers,
        json={
            "title": "Ilk Gorev",
            "description": "aciklama",
            "status": "Done",
            "priority": "High",
            "due_date": ""
        }
    )
    assert cleared.status_code == status.HTTP_200_OK
    assert cleared.json()["due_date"] is None

    # 6. Görevi sil
    assert client.delete(f"/api/tasks/{task_id}", headers=headers).status_code == status.HTTP_204_NO_CONTENT

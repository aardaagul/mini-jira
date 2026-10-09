import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/project.dart';
import '../services/project_service.dart';
import 'kanban_screen.dart';
import 'login_screen.dart';

class ProjectScreen extends StatefulWidget {
  @override
  _ProjectScreenState createState() => _ProjectScreenState();
}

class _ProjectScreenState extends State<ProjectScreen> {
  final ProjectService _projectService = ProjectService();
  late Future<List<Project>> _projectsFuture;

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  void _loadProjects() {
    setState(() {
      _projectsFuture = _projectService.getProjects();
    });
  }

  Future<void> _logout() async {
    bool confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Çıkış Yap"),
        content: Text("Hesabınızdan çıkış yapmak istediğinize emin misiniz?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text("Vazgeç"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text("Çıkış Yap", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ) ?? false;

    if (confirm) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('jwt_token');

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
        (route) => false,
      );
    }
  }

  void _showAddProjectDialog() {
    final _nameController = TextEditingController();
    final _descController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Yeni Proje Oluştur"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Proje Adı',
                    hintText: 'Örn: Verilog İşlemci',
                  ),
                ),
                SizedBox(height: 12),
                TextField(
                  controller: _descController,
                  decoration: InputDecoration(
                    labelText: 'Açıklama',
                    hintText: 'Proje hakkında kısa bilgi',
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("İptal"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_nameController.text.trim().isNotEmpty) {
                  bool success = await _projectService.createProject(
                    name: _nameController.text.trim(),
                    description: _descController.text.trim(),
                  );
                  Navigator.pop(context);

                  if (success) {
                    _loadProjects();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Proje başarıyla oluşturuldu!")),
                    );
                  }
                }
              },
              child: Text("Oluştur"),
            ),
          ],
        );
      },
    );
  }

  void _showEditProjectDialog(Project project) {
    final _nameController = TextEditingController(text: project.title);
    final _descController = TextEditingController(text: project.description);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Projeyi Düzenle"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(labelText: 'Proje Adı'),
                ),
                SizedBox(height: 12),
                TextField(
                  controller: _descController,
                  decoration: InputDecoration(labelText: 'Açıklama'),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("İptal"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_nameController.text.trim().isNotEmpty) {
                  bool success = await _projectService.updateProject(
                    project.id,
                    _nameController.text.trim(),
                    _descController.text.trim(),
                  );
                  Navigator.pop(context);

                  if (success) {
                    _loadProjects();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Proje güncellendi!")),
                    );
                  }
                }
              },
              child: Text("Kaydet"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmDeleteProject(Project project) async {
    bool confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Projeyi Sil"),
        content: Text("'${project.title}' projesini ve bağlı tüm görevleri silmek istediğinize emin misiniz?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text("Vazgeç"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text("Sil", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ) ?? false;

    if (confirm) {
      bool deleted = await _projectService.deleteProject(project.id);
      if (deleted) {
        _loadProjects();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Proje silindi.")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Projelerim - Mini-Jira"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            tooltip: 'Çıkış Yap',
            onPressed: _logout,
          ),
        ],
      ),
      body: FutureBuilder<List<Project>>(
        future: _projectsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Bir hata oluştu: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text(
                "Henüz hiç projeniz yok.\nSağ alttaki '+' butonuna basarak yeni bir proje oluşturabilirsiniz!",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600], fontSize: 16),
              ),
            );
          }

          final projects = snapshot.data!;
          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: projects.length,
            itemBuilder: (context, index) {
              final project = projects[index];
              return Card(
                elevation: 3,
                margin: EdgeInsets.only(bottom: 16),
                child: ListTile(
                  title: Text(
                    project.title,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  subtitle: Text(project.description),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PopupMenuButton<String>(
                        icon: Icon(Icons.more_vert, color: Colors.grey[600]),
                        onSelected: (value) {
                          if (value == 'edit') {
                            _showEditProjectDialog(project);
                          } else if (value == 'delete') {
                            _confirmDeleteProject(project);
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit, size: 20, color: Colors.blue),
                                SizedBox(width: 8),
                                Text("Düzenle"),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, size: 20, color: Colors.red),
                                SizedBox(width: 8),
                                Text("Sil", style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                    ],
                  ),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => KanbanScreen(project: project),
                      ),
                    );
                    _loadProjects();
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddProjectDialog,
        child: Icon(Icons.add),
        tooltip: 'Yeni Proje Oluştur',
      ),
    );
  }
}
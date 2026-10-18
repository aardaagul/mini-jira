import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import '../models/project.dart';
import '../models/task.dart';
import '../services/project_service.dart';
import 'kanban_screen.dart';
import 'login_screen.dart';

class ProjectDashboardData {
  final List<Project> projects;
  final Map<int, List<Task>> tasksByProject;

  ProjectDashboardData({
    required this.projects,
    required this.tasksByProject,
  });
}

class ProjectScreen extends StatefulWidget {
  // use_key_in_widget_constructors çözümü
  const ProjectScreen({super.key}); 

  @override
  // library_private_types_in_public_api çözümü
  State<ProjectScreen> createState() => _ProjectScreenState(); 
}

class _ProjectScreenState extends State<ProjectScreen> {
  final ProjectService _projectService = ProjectService();
  late Future<ProjectDashboardData> _dashboardFuture;

  int _selectedNavIndex = 0;
  bool _isSidebarCollapsed = false;
  String _userEmail = 'kullanici@workspace.com';

  String _projectSearchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _loadProjects();
  }

  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('user_email');
    if (savedEmail != null && savedEmail.isNotEmpty && mounted) {
      setState(() {
        _userEmail = savedEmail;
      });
    }
  }

  void _loadProjects() {
    setState(() {
      _dashboardFuture = _fetchDashboardData();
    });
  }

  Future<ProjectDashboardData> _fetchDashboardData() async {
    final projects = await _projectService.getProjects();
    final Map<int, List<Task>> tasksMap = {};

    await Future.wait(projects.map((p) async {
      final tasks = await _projectService.getTasks(p.id);
      tasksMap[p.id] = tasks;
    }));

    return ProjectDashboardData(
      projects: projects,
      tasksByProject: tasksMap,
    );
  }

  Future<void> _logout() async {
    bool confirm = await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("Oturumu Kapat"),
            content: const Text(
                "Çalışma alanından çıkış yapmak istediğinize emin misiniz?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text("Vazgeç"),
              ),
              ElevatedButton(
                style:
                    ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text("Çıkış Yap"),
              ),
            ],
          ),
        ) ??
        false;

    if (confirm) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('jwt_token');

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  void _showAddProjectDialog() {
    final nameController = TextEditingController();
    final descController = TextEditingController();

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Yeni Proje Oluştur",
              style: TextStyle(fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Proje Adı',
                      hintText: 'Örn: RISC-V İşlemci Tasarımı',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descController,
                    decoration: const InputDecoration(
                      labelText: 'Proje Açıklaması',
                      hintText: 'Mimari hedefler ve modül kapsamı',
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("İptal"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isNotEmpty) {
                  bool success = await _projectService.createProject(
                    name: nameController.text.trim(),
                    description: descController.text.trim(),
                  );
                  // !mounted kontrolü eklendi
                  if (!mounted) return;
                  navigator.pop();

                  if (success) {
                    _loadProjects();
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text("Proje başarıyla oluşturuldu!"),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
              },
              child: const Text("Proje Oluştur"),
            ),
          ],
        );
      },
    );
  }

  void _showEditProjectDialog(Project project) {
    final nameController = TextEditingController(text: project.title);
    final descController = TextEditingController(text: project.description);

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Projeyi Düzenle",
              style: TextStyle(fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Proje Adı'),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descController,
                    decoration: const InputDecoration(labelText: 'Açıklama'),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("İptal"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isNotEmpty) {
                  bool success = await _projectService.updateProject(
                    project.id,
                    nameController.text.trim(),
                    descController.text.trim(),
                  );
                  // !mounted kontrolü eklendi
                  if (!mounted) return;
                  navigator.pop();

                  if (success) {
                    _loadProjects();
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text("Proje güncellendi!"),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
              },
              child: const Text("Değişiklikleri Kaydet"),
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
            title: const Text("Projeyi Sil"),
            content: Text(
              "'${project.title}' projesini ve içindeki tüm görevleri kalıcı olarak silmek istediğinize emin misiniz?",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text("Vazgeç"),
              ),
              ElevatedButton(
                style:
                    ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text("Kalıcı Olarak Sil"),
              ),
            ],
          ),
        ) ??
        false;

    if (confirm) {
      bool deleted = await _projectService.deleteProject(project.id);
      if (!mounted) return;
      if (deleted) {
        _loadProjects();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Proje silindi."),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final String userInitial =
        _userEmail.isNotEmpty ? _userEmail[0].toUpperCase() : 'U';
    final String displayName = _userEmail.split('@').first;

    return Scaffold(
      body: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            width: _isSidebarCollapsed ? 76 : 250,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              border: Border(
                right: BorderSide(
                  color: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFE2E8F0),
                  width: 1,
                ),
              ),
            ),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: _isSidebarCollapsed
                    ? CrossAxisAlignment.center
                    : CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      _isSidebarCollapsed ? 12 : 18,
                      16,
                      _isSidebarCollapsed ? 12 : 12,
                      16,
                    ),
                    child: Row(
                      mainAxisAlignment: _isSidebarCollapsed
                          ? MainAxisAlignment.center
                          : MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _isSidebarCollapsed = !_isSidebarCollapsed;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF4F46E5),
                                      Color(0xFF2563EB)
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.view_kanban_rounded,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                            ),
                            if (!_isSidebarCollapsed) ...[
                              const SizedBox(width: 12),
                              const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Mini-Jira",
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.4,
                                    ),
                                  ),
                                  Text(
                                    "WORKSPACE",
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF4F46E5),
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                        if (!_isSidebarCollapsed)
                          IconButton(
                            icon: const Icon(
                                Icons.keyboard_double_arrow_left_rounded,
                                size: 20),
                            tooltip: 'Menüyü Daralt',
                            onPressed: () {
                              setState(() => _isSidebarCollapsed = true);
                            },
                          ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  if (!_isSidebarCollapsed)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 6),
                      child: Text(
                        "MENÜ",
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                          color: isDark ? Colors.grey[500] : Colors.grey[500],
                        ),
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: IconButton(
                        icon: const Icon(
                            Icons.keyboard_double_arrow_right_rounded,
                            size: 20),
                        tooltip: 'Menüyü Genişlet',
                        onPressed: () {
                          setState(() => _isSidebarCollapsed = false);
                        },
                      ),
                    ),
                  _buildSidebarItem(
                    index: 0,
                    icon: Icons.folder_copy_outlined,
                    title: "Projelerim",
                    isDark: isDark,
                  ),
                  _buildSidebarItem(
                    index: 1,
                    icon: Icons.analytics_outlined,
                    title: "Analitik & Raporlar",
                    isDark: isDark,
                  ),
                  _buildSidebarItem(
                    index: 2,
                    icon: Icons.event_note_outlined,
                    title: "Teslim Tarihleri",
                    isDark: isDark,
                  ),
                  const Spacer(),
                  const Divider(height: 1),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      _isSidebarCollapsed ? 8 : 14,
                      12,
                      _isSidebarCollapsed ? 8 : 14,
                      4,
                    ),
                    child: Tooltip(
                      message: _userEmail,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: _isSidebarCollapsed ? 6 : 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF0F172A)
                              : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF334155)
                                : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: _isSidebarCollapsed
                              ? MainAxisAlignment.center
                              : MainAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: const Color(0xFF4F46E5),
                              child: Text(
                                userInitial,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            if (!_isSidebarCollapsed) ...[
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      displayName,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                    Text(
                                      _userEmail,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isDark
                                            ? Colors.grey[400]
                                            : Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Column(
                      children: [
                        _buildBottomActionItem(
                          icon: isDark
                              ? Icons.light_mode_outlined
                              : Icons.dark_mode_outlined,
                          title: isDark ? "Aydınlık Mod" : "Karanlık Mod",
                          onTap: toggleTheme,
                          isDark: isDark,
                        ),
                        const SizedBox(height: 4),
                        _buildBottomActionItem(
                          icon: Icons.logout_rounded,
                          title: "Oturumu Kapat",
                          color: Colors.redAccent,
                          onTap: _logout,
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Container(
                  height: 64,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    border: Border(
                      bottom: BorderSide(
                        color: isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFE2E8F0),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          _isSidebarCollapsed
                              ? Icons.menu_open_rounded
                              : Icons.menu_rounded,
                          size: 21,
                        ),
                        tooltip:
                            _isSidebarCollapsed ? 'Menüyü Aç' : 'Menüyü Kapat',
                        onPressed: () {
                          setState(
                              () => _isSidebarCollapsed = !_isSidebarCollapsed);
                        },
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _selectedNavIndex == 0
                            ? "Proje Yönetim Paneli"
                            : _selectedNavIndex == 1
                                ? "Proje Analitiği & İstatistikler"
                                : "Son Teslim Tarihi Takvimi",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.refresh_rounded, size: 20),
                        tooltip: 'Verileri Yenile',
                        onPressed: _loadProjects,
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: _showAddProjectDialog,
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text(
                          "Yeni Proje",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: FutureBuilder<ProjectDashboardData>(
                    future: _dashboardFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return Center(
                            child: Text("Bir hata oluştu: ${snapshot.error}"));
                      } else if (!snapshot.hasData ||
                          snapshot.data!.projects.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.folder_copy_outlined,
                                  size: 64, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              const Text(
                                "Henüz Hiç Proje Oluşturulmadı",
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                "İlk projenizi başlatmak için sağ üstteki 'Yeni Proje' butonuna tıklayın.",
                                style: TextStyle(color: Colors.grey[500]),
                              ),
                            ],
                          ),
                        );
                      }

                      final data = snapshot.data!;
                      if (_selectedNavIndex == 1) {
                        return _buildAnalyticsView(data, isDark);
                      } else if (_selectedNavIndex == 2) {
                        return _buildDeadlinesView(data, isDark);
                      }
                      return _buildProjectsView(data, isDark);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem({
    required int index,
    required IconData icon,
    required String title,
    required bool isDark,
  }) {
    final bool isSelected = _selectedNavIndex == index;
    const activeColor = Color(0xFF4F46E5);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      child: Tooltip(
        message: _isSidebarCollapsed ? title : '',
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => setState(() => _selectedNavIndex = index),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: _isSidebarCollapsed ? 0 : 14,
              vertical: 11,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? activeColor.withValues(alpha: 0.12)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: _isSidebarCollapsed
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.start,
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isSelected
                      ? activeColor
                      : (isDark ? Colors.grey[400] : Colors.grey[700]),
                ),
                if (!_isSidebarCollapsed) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected
                            ? activeColor
                            : (isDark ? Colors.grey[300] : Colors.grey[800]),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomActionItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required bool isDark,
    Color? color,
  }) {
    final effectiveColor =
        color ?? (isDark ? Colors.grey[300] : Colors.grey[800]);

    return Tooltip(
      message: _isSidebarCollapsed ? title : '',
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: _isSidebarCollapsed ? 0 : 14,
            vertical: 10,
          ),
          child: Row(
            mainAxisAlignment: _isSidebarCollapsed
                ? MainAxisAlignment.center
                : MainAxisAlignment.start,
            children: [
              Icon(icon, size: 20, color: effectiveColor),
              if (!_isSidebarCollapsed) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: effectiveColor,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProjectsView(ProjectDashboardData data, bool isDark) {
    final projects = data.projects;
    final tasksByProject = data.tasksByProject;

    int totalTasks = 0;
    int totalInProgress = 0;
    int totalDone = 0;
    tasksByProject.forEach((_, taskList) {
      totalTasks += taskList.length;
      totalInProgress +=
          taskList.where((t) => t.status == 'In Progress').length;
      totalDone += taskList.where((t) => t.status == 'Done').length;
    });
    final int overallPercent =
        totalTasks > 0 ? ((totalDone / totalTasks) * 100).toInt() : 0;

    final filteredProjects = projects.where((p) {
      if (_projectSearchQuery.isEmpty) return true;
      final query = _projectSearchQuery.toLowerCase().trim();
      final projectKey = 'prj-${p.id}';

      return projectKey.contains(query) ||
          p.id.toString() == query ||
          p.title.toLowerCase().contains(query) ||
          p.description.toLowerCase().contains(query);
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 12),
          child: Row(
            children: [
              Expanded(
                child: _buildKpiCard(
                  title: "AKTİF PROJELER",
                  value: "${projects.length}",
                  subtitle: "Çalışma alanında aktif",
                  icon: Icons.layers_outlined,
                  color: const Color(0xFF4F46E5),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildKpiCard(
                  title: "TOPLAM GÖREV",
                  value: "$totalTasks",
                  subtitle: "Tüm panolardaki kayıtlar",
                  icon: Icons.assignment_outlined,
                  color: const Color(0xFF0EA5E9),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildKpiCard(
                  title: "DEVAM EDEN",
                  value: "$totalInProgress",
                  subtitle: "Üzerinde çalışılanlar",
                  icon: Icons.timelapse_rounded,
                  color: const Color(0xFFF59E0B),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildKpiCard(
                  title: "TAMAMLANAN",
                  value: "%$overallPercent",
                  subtitle: "$totalDone / $totalTasks görev bitti",
                  icon: Icons.task_alt_rounded,
                  color: const Color(0xFF10B981),
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Tüm Projeler (${filteredProjects.length})",
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(
                width: 280,
                height: 38,
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Proje adı veya PRJ-1 ara...',
                    hintStyle: TextStyle(fontSize: 13),
                    prefixIcon: Icon(Icons.search_rounded, size: 18),
                    contentPadding:
                        EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                  ),
                  onChanged: (val) => setState(() => _projectSearchQuery = val),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(28, 8, 28, 24),
            itemCount: filteredProjects.length,
            itemBuilder: (context, index) {
              final project = filteredProjects[index];
              final projectTasks = tasksByProject[project.id] ?? [];
              final todoCount =
                  projectTasks.where((t) => t.status == 'To Do').length;
              final inProgressCount =
                  projectTasks.where((t) => t.status == 'In Progress').length;
              final doneCount =
                  projectTasks.where((t) => t.status == 'Done').length;
              final totalCount = projectTasks.length;
              final progress = totalCount > 0 ? (doneCount / totalCount) : 0.0;

              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                child: Card(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => KanbanScreen(project: project),
                        ),
                      );
                      _loadProjects();
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color:
                                      const Color(0xFF4F46E5).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: const Color(0xFF4F46E5)
                                        .withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Text(
                                  "PRJ-${project.id}",
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF4F46E5),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      project.title,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 17,
                                      ),
                                    ),
                                    if (project.description.isNotEmpty) ...[
                                      const SizedBox(height: 3),
                                      Text(
                                        project.description,
                                        style: TextStyle(
                                          color: isDark
                                              ? Colors.grey[400]
                                              : Colors.grey[600],
                                          fontSize: 13.5,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              PopupMenuButton<String>(
                                icon: const Icon(Icons.more_horiz_rounded),
                                onSelected: (value) {
                                  if (value == 'edit') {
                                    _showEditProjectDialog(project);
                                  } else if (value == 'delete') {
                                    _confirmDeleteProject(project);
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: Row(
                                      children: [
                                        Icon(Icons.edit_outlined,
                                            size: 18, color: Colors.blue),
                                        SizedBox(width: 8),
                                        Text("Projeyi Düzenle"),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete_outline,
                                            size: 18, color: Colors.redAccent),
                                        SizedBox(width: 8),
                                        Text("Projeyi Sil",
                                            style: TextStyle(
                                                color: Colors.redAccent)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF0F172A)
                                      : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.arrow_forward_rounded,
                                    size: 16),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Wrap(
                                spacing: 8,
                                children: [
                                  _buildStatusPill("To Do", todoCount,
                                      const Color(0xFFF59E0B), isDark),
                                  _buildStatusPill(
                                      "In Progress",
                                      inProgressCount,
                                      const Color(0xFF3B82F6),
                                      isDark),
                                  _buildStatusPill("Done", doneCount,
                                      const Color(0xFF10B981), isDark),
                                ],
                              ),
                              Text(
                                "%${(progress * 100).toInt()} Tamamlandı",
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? const Color(0xFF34D399)
                                      : const Color(0xFF059669),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 7,
                              backgroundColor: isDark
                                  ? const Color(0xFF0F172A)
                                  : const Color(0xFFE2E8F0),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                  Color(0xFF10B981)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAnalyticsView(ProjectDashboardData data, bool isDark) {
    final allTasks = data.tasksByProject.values.expand((list) => list).toList();
    final total = allTasks.length;

    final todoCount = allTasks.where((t) => t.status == 'To Do').length;
    final inProgressCount =
        allTasks.where((t) => t.status == 'In Progress').length;
    final doneCount = allTasks.where((t) => t.status == 'Done').length;

    final highCount = allTasks.where((t) => t.priority == 'High').length;
    final mediumCount = allTasks.where((t) => t.priority == 'Medium').length;
    final lowCount = allTasks.where((t) => t.priority == 'Low').length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Görev Durum Dağılımı",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 20),
                        _buildDistributionRow("To Do (Bekleyen)", todoCount,
                            total, const Color(0xFFF59E0B), isDark),
                        const SizedBox(height: 16),
                        _buildDistributionRow(
                            "In Progress (Geliştirilen)",
                            inProgressCount,
                            total,
                            const Color(0xFF3B82F6),
                            isDark),
                        const SizedBox(height: 16),
                        _buildDistributionRow("Done (Tamamlanan)", doneCount,
                            total, const Color(0xFF10B981), isDark),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Öncelik Seviyesi Analizi",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 20),
                        _buildDistributionRow("High (Yüksek Öncelik)",
                            highCount, total, const Color(0xFFEF4444), isDark),
                        const SizedBox(height: 16),
                        _buildDistributionRow(
                            "Medium (Orta Öncelik)",
                            mediumCount,
                            total,
                            const Color(0xFFF59E0B),
                            isDark),
                        const SizedBox(height: 16),
                        _buildDistributionRow("Low (Düşük Öncelik)", lowCount,
                            total, const Color(0xFF10B981), isDark),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDistributionRow(
      String label, int count, int total, Color color, bool isDark) {
    final double ratio = total > 0 ? (count / total) : 0.0;
    final int percent = (ratio * 100).toInt();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 13.5)),
            Text(
              "$count Görev (%$percent)",
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 13, color: color),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 8,
            backgroundColor:
                isDark ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _buildDeadlinesView(ProjectDashboardData data, bool isDark) {
    final List<Map<String, dynamic>> tasksWithDates = [];

    for (final project in data.projects) {
      final projectTasks = data.tasksByProject[project.id] ?? [];
      for (final task in projectTasks) {
        if (task.dueDate != null && task.dueDate!.isNotEmpty) {
          tasksWithDates.add({
            'project': project,
            'task': task,
          });
        }
      }
    }

    tasksWithDates.sort((a, b) {
      final Task tA = a['task'];
      final Task tB = b['task'];
      return (tA.dueDate ?? '').compareTo(tB.dueDate ?? '');
    });

    if (tasksWithDates.isEmpty) {
      return Center(
        child: Text(
          "Henüz son teslim tarihi atanmış bir görev bulunmuyor.",
          style: TextStyle(color: Colors.grey[500], fontSize: 15),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(28),
      itemCount: tasksWithDates.length,
      itemBuilder: (context, index) {
        final Project project = tasksWithDates[index]['project'];
        final Task task = tasksWithDates[index]['task'];

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            leading: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF4F46E5).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                "TSK-${task.id}",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Color(0xFF4F46E5),
                ),
              ),
            ),
            title: Text(task.title,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle:
                Text("Proje: ${project.title}  •  Durum: ${task.status}"),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.event_rounded,
                      size: 15, color: Colors.orange),
                  const SizedBox(width: 6),
                  Text(
                    task.dueDate!,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12.5,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
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
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: isDark ? Colors.grey[400] : Colors.grey[500],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: isDark ? Colors.grey[500] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusPill(
      String label, int count, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.16 : 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            "$label: $count",
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
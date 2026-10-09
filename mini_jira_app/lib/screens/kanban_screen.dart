import 'package:flutter/material.dart';
import '../models/project.dart';
import '../models/task.dart';
import '../services/project_service.dart';

class KanbanScreen extends StatefulWidget {
  final Project project;

  const KanbanScreen({Key? key, required this.project}) : super(key: key);

  @override
  _KanbanScreenState createState() => _KanbanScreenState();
}

class _KanbanScreenState extends State<KanbanScreen> {
  final ProjectService _projectService = ProjectService();
  late Future<List<Task>> _tasksFuture;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  void _loadTasks() {
    setState(() {
      _tasksFuture = _projectService.getTasks(widget.project.id);
    });
  }

  // Öncelik rengini belirleme
  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'High':
        return Colors.redAccent;
      case 'Low':
        return Colors.green;
      case 'Medium':
      default:
        return Colors.orange;
    }
  }

  Future<void> _handleTaskDropped(Task task, String newStatus) async {
    if (task.status == newStatus) return;

    bool success = await _projectService.updateTaskStatus(task.id, newStatus);
    if (success) {
      _loadTasks();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Görev güncellenirken hata oluştu.")),
      );
    }
  }

  // Yeni Görev Ekleme Modalı
  void _showAddTaskDialog() {
    final _titleController = TextEditingController();
    final _descController = TextEditingController();
    String _selectedStatus = 'To Do';
    String _selectedPriority = 'Medium';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text("Yeni Görev Ekle"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _titleController,
                      decoration: InputDecoration(labelText: 'Görev Başlığı'),
                    ),
                    SizedBox(height: 12),
                    TextField(
                      controller: _descController,
                      decoration: InputDecoration(labelText: 'Açıklama'),
                      maxLines: 3,
                    ),
                    SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _selectedPriority,
                      decoration: InputDecoration(labelText: 'Öncelik (Priority)'),
                      items: ['Low', 'Medium', 'High']
                          .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setDialogState(() => _selectedPriority = val);
                      },
                    ),
                    SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _selectedStatus,
                      decoration: InputDecoration(labelText: 'Durum'),
                      items: ['To Do', 'In Progress', 'Done']
                          .map((status) => DropdownMenuItem(value: status, child: Text(status)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setDialogState(() => _selectedStatus = val);
                      },
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
                    if (_titleController.text.trim().isNotEmpty) {
                      bool success = await _projectService.createTask(
                        title: _titleController.text.trim(),
                        description: _descController.text.trim(),
                        status: _selectedStatus,
                        priority: _selectedPriority,
                        projectId: widget.project.id,
                      );
                      Navigator.pop(context);
                      if (success) {
                        _loadTasks();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Görev başarıyla eklendi!")),
                        );
                      }
                    }
                  },
                  child: Text("Ekle"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Görev Düzenleme ve Silme Modalı
  void _showEditTaskDialog(Task task) {
    final _titleController = TextEditingController(text: task.title);
    final _descController = TextEditingController(text: task.description);
    String _selectedStatus = task.status;
    String _selectedPriority = task.priority;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Görevi Düzenle"),
                  IconButton(
                    icon: Icon(Icons.delete_outline, color: Colors.red),
                    tooltip: 'Görevi Sil',
                    onPressed: () async {
                      bool confirm = await showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: Text("Görevi Sil"),
                          content: Text("Bu görevi silmek istediğinize emin misiniz?"),
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
                        bool deleted = await _projectService.deleteTask(task.id);
                        Navigator.pop(context);
                        if (deleted) {
                          _loadTasks();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Görev silindi.")),
                          );
                        }
                      }
                    },
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _titleController,
                      decoration: InputDecoration(labelText: 'Görev Başlığı'),
                    ),
                    SizedBox(height: 12),
                    TextField(
                      controller: _descController,
                      decoration: InputDecoration(labelText: 'Açıklama'),
                      maxLines: 3,
                    ),
                    SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _selectedPriority,
                      decoration: InputDecoration(labelText: 'Öncelik (Priority)'),
                      items: ['Low', 'Medium', 'High']
                          .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setDialogState(() => _selectedPriority = val);
                      },
                    ),
                    SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _selectedStatus,
                      decoration: InputDecoration(labelText: 'Durum'),
                      items: ['To Do', 'In Progress', 'Done']
                          .map((status) => DropdownMenuItem(value: status, child: Text(status)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setDialogState(() => _selectedStatus = val);
                      },
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
                    if (_titleController.text.trim().isNotEmpty) {
                      bool success = await _projectService.updateTask(
                        taskId: task.id,
                        title: _titleController.text.trim(),
                        description: _descController.text.trim(),
                        status: _selectedStatus,
                        priority: _selectedPriority,
                      );
                      Navigator.pop(context);
                      if (success) {
                        _loadTasks();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Görev güncellendi!")),
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
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.project.title),
        centerTitle: true,
      ),
      body: FutureBuilder<List<Task>>(
        future: _tasksFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Hata: ${snapshot.error}"));
          }

          final tasks = snapshot.data ?? [];
          final todoTasks = tasks.where((t) => t.status == 'To Do').toList();
          final inProgressTasks = tasks.where((t) => t.status == 'In Progress').toList();
          final doneTasks = tasks.where((t) => t.status == 'Done').toList();

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildKanbanColumn("To Do", todoTasks, Colors.orange)),
                SizedBox(width: 16),
                Expanded(child: _buildKanbanColumn("In Progress", inProgressTasks, Colors.blue)),
                SizedBox(width: 16),
                Expanded(child: _buildKanbanColumn("Done", doneTasks, Colors.green)),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTaskDialog,
        child: Icon(Icons.add),
        tooltip: 'Yeni Görev Ekle',
      ),
    );
  }

  Widget _buildKanbanColumn(String title, List<Task> tasks, Color color) {
    return DragTarget<Task>(
      onWillAcceptWithDetails: (details) => details.data.status != title,
      onAcceptWithDetails: (details) {
        _handleTaskDropped(details.data, title);
      },
      builder: (context, candidateData, rejectedData) {
        bool isHovered = candidateData.isNotEmpty;
        return Container(
          decoration: BoxDecoration(
            color: isHovered ? color.withOpacity(0.08) : Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isHovered ? color : Colors.grey[300]!,
              width: isHovered ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(11)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color),
                    ),
                    Chip(
                      label: Text('${tasks.length}', style: TextStyle(fontWeight: FontWeight.bold)),
                      backgroundColor: Colors.white,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.all(8),
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    return Draggable<Task>(
                      data: task,
                      feedback: Material(
                        elevation: 6,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          width: 260,
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: color, width: 1.5),
                          ),
                          child: Text(
                            task.title,
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ),
                      ),
                      childWhenDragging: Opacity(
                        opacity: 0.3,
                        child: _buildTaskCard(task),
                      ),
                      child: _buildTaskCard(task),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTaskCard(Task task) {
    final priorityColor = _getPriorityColor(task.priority);

    return Card(
      elevation: 2,
      margin: EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => _showEditTaskDialog(task),
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      task.title,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                  Icon(Icons.edit_outlined, size: 16, color: Colors.grey[400]),
                ],
              ),
              if (task.description.isNotEmpty) ...[
                SizedBox(height: 6),
                Text(
                  task.description,
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
              ],
              SizedBox(height: 8),
              // Öncelik Rozeti (Badge)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: priorityColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: priorityColor.withOpacity(0.5), width: 1),
                ),
                child: Text(
                  task.priority,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: priorityColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}